import { test, describe, after } from "node:test";
import assert from "node:assert/strict";
import {
  phraseWindows,
  matchPhrase,
  patternMatches,
  isPhrasePattern,
  MAX_PHRASE_TOKENS,
} from "../src/services/phrases.js";
import { phraseKind, sortPhrases } from "../src/services/related-phrases.js";
import { buildApp } from "../src/app.js";
import { appOptions, memStore, FakeLLM } from "./fakes.js";

describe("phraseWindows", () => {
  const tokens = ["a", "single", "man", "in", "possession", "of", "a", "good"];
  test("longest first, all covering the index, leftmost first within a length", () => {
    const w = phraseWindows(tokens, 3, 2, 4).map((x) => x.phrase);
    assert.deepEqual(w, [
      "a single man in",
      "single man in possession",
      "man in possession of",
      "in possession of a",
      "single man in",
      "man in possession",
      "in possession of",
      "man in",
      "in possession",
    ]);
  });

  test("edges and empty tokens", () => {
    assert.deepEqual(
      phraseWindows(tokens, 0, 2, 4).map((x) => x.phrase),
      ["a single man in", "a single man", "a single"],
    );
    assert.deepEqual(
      phraseWindows(["in", "want", "", "of"], 1).map((x) => x.phrase),
      ["in want"],
    );
    assert.deepEqual(phraseWindows(["x"], 0), []);
  });

  test("the default reaches a seven-token idiom", () => {
    // "let the cat out of the bag": at the old cap of four, tapping `cat`
    // could only ever find the entry for `cat`.
    const sentence = ["he", "let", "the", "cat", "out", "of", "the", "bag"];
    const w = phraseWindows(sentence, 3).map((x) => x.phrase);
    assert.ok(
      w.includes("let the cat out of the bag"),
      "the whole idiom is a candidate",
    );
    assert.equal(w[0], "he let the cat out of the bag", "longest first");
  });

  test("every window covers the tapped token and respects the cap", () => {
    const sentence = Array.from({ length: 20 }, (_, i) => `w${i}`);
    for (const w of phraseWindows(sentence, 10)) {
      assert.ok(
        w.start <= 10 && 10 < w.start + w.tokenCount,
        `${w.phrase} covers the tap`,
      );
      assert.ok(w.tokenCount >= 2 && w.tokenCount <= MAX_PHRASE_TOKENS);
    }
  });
});

describe("an idiom with a slot in it", () => {
  // "change one's mind" never appears literally: the sentence says "his".
  test("a slot matches whatever the sentence put there", () => {
    assert.ok(patternMatches("change one's mind", ["change", "his", "mind"]));
    assert.ok(patternMatches("change one's mind", ["change", "her", "mind"]));
    assert.ok(patternMatches("serve someone right", ["serve", "him", "right"]));
  });

  test("the rest of the phrase still has to match", () => {
    assert.equal(
      patternMatches("change one's mind", ["change", "his", "shirt"]),
      false,
    );
    assert.equal(
      patternMatches("change one's mind", ["lose", "his", "mind"]),
      false,
    );
    assert.equal(
      patternMatches("change one's mind", ["change", "mind"]),
      false,
    );
  });

  test("a phrase without a slot is not a pattern", () => {
    assert.equal(isPhrasePattern("in want of"), false);
    assert.ok(isPhrasePattern("change one's mind"));
  });

  test('a bare "one" is a numeral, not a slot', () => {
    // "kill two birds with one stone" — wildcarding `one` would match
    // "with any stone", which is not the idiom.
    assert.equal(isPhrasePattern("kill two birds with one stone"), false);
  });
});

describe("matchPhrase", () => {
  /** memStore's phrases plus the two shapes the old matcher could not reach. */
  function storeWith(extra: Record<string, string>) {
    const base = memStore();
    const all = new Map(Object.entries(extra));
    return {
      ...base,
      async findPhraseLemma(p: string) {
        return all.get(p) ?? base.findPhraseLemma(p);
      },
      async findPhrasesByFirstToken(firstTokens: string[], maxTokens: number) {
        const want = new Set(firstTokens);
        const mine = [...all].filter(
          ([phrase]) =>
            phrase.split(" ").length <= maxTokens &&
            want.has(phrase.split(" ")[0]!),
        );
        return [
          ...(await base.findPhrasesByFirstToken(firstTokens, maxTokens)),
          ...mine.map(([phrase, lemma]) => ({ phrase, lemma })),
        ];
      },
    };
  }

  test("a seven-token idiom is found from a tap inside it", async () => {
    const store = storeWith({
      "let the cat out of the bag": "let the cat out of the bag",
    });
    const sentence = [
      "she",
      "let",
      "the",
      "cat",
      "out",
      "of",
      "the",
      "bag",
      "early",
    ];
    const m = await matchPhrase(store, sentence, 3); // tapped `cat`
    assert.equal(m?.lemma, "let the cat out of the bag");
    assert.equal(m?.tokenCount, 7);
    assert.equal(m?.start, 1);
  });

  test("an idiom with a slot is found around the word the sentence used", async () => {
    const store = storeWith({ "change one's mind": "change one's mind" });
    const m = await matchPhrase(
      store,
      ["he", "might", "change", "his", "mind"],
      2,
    );
    assert.equal(m?.lemma, "change one's mind");
    assert.equal(
      m?.phrase,
      "change his mind",
      "the window keeps the words on the page",
    );
    assert.equal(m?.tokenCount, 3);
  });

  test("a slot does not match across a phrase that is not there", async () => {
    const store = storeWith({ "change one's mind": "change one's mind" });
    assert.equal(
      await matchPhrase(store, ["he", "will", "change", "his", "shirt"], 2),
      null,
    );
  });

  test("longest match wins", async () => {
    const store = memStore();
    const m = await matchPhrase(
      store,
      ["must", "be", "in", "want", "of", "a", "wife"],
      3,
    );
    assert.deepEqual(m, {
      phrase: "in want of",
      lemma: "in want of",
      start: 2,
      tokenCount: 3,
    });
  });
  test("no phrase → null", async () => {
    assert.equal(
      await matchPhrase(memStore(), ["a", "good", "fortune"], 1),
      null,
    );
  });
});

describe("POST /v1/phrases/match", () => {
  const app = buildApp(appOptions(new FakeLLM({})));
  after(() => app.close());
  test("normalizes tokens and returns the contract shape", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/phrases/match",
      payload: { tokens: ["Man", "in", "Possession,", "of", "a"], index: 2 },
    });
    assert.equal(res.statusCode, 200);
    assert.deepEqual(res.json().data, {
      phrase: "in possession of",
      lemma: "in possession of",
      start: 1,
      tokenCount: 3,
    });
  });
  test("miss → data null (not an error)", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/phrases/match",
      payload: { tokens: ["x", "y"], index: 0 },
    });
    assert.equal(res.statusCode, 200);
    assert.equal(res.json().data, null);
  });
  test("index out of range → 400", async () => {
    const res = await app.inject({
      method: "POST",
      url: "/v1/phrases/match",
      payload: { tokens: ["x"], index: 4 },
    });
    assert.equal(res.statusCode, 400);
  });
});

describe("phraseKind", () => {
  test("particles only → phrasal verb", () => {
    assert.equal(phraseKind("get", "get up"), "phrasal");
    assert.equal(phraseKind("get", "get away with"), "phrasal");
    assert.equal(phraseKind("put", "put up with"), "phrasal");
  });
  test("a content word, or the lemma not first → idiom", () => {
    assert.equal(phraseKind("get", "get cold feet"), "idiom");
    assert.equal(phraseKind("get", "get married"), "idiom");
    assert.equal(phraseKind("want", "in want of"), "idiom");
  });
});

describe("sortPhrases", () => {
  test("phrasal verbs first, then by length, then alphabetical", () => {
    const p = (phrase: string, kind: "phrasal" | "idiom") => ({
      phrase,
      kind,
      partOfSpeech: "क्रिया",
      meaning: "म",
    });
    const out = sortPhrases([
      p("get cold feet", "idiom"),
      p("get over", "phrasal"),
      p("get away with", "phrasal"),
      p("get by", "phrasal"),
    ]).map((x) => x.phrase);
    assert.deepEqual(out, [
      "get by",
      "get over",
      "get away with",
      "get cold feet",
    ]);
  });
});

describe("GET /v1/phrases/of", () => {
  const app = buildApp(appOptions(new FakeLLM({})));
  after(() => app.close());
  test("the phrases built on a word, with their first Hindi meaning", async () => {
    const res = await app.inject({
      method: "GET",
      url: "/v1/phrases/of?word=Want",
    });
    assert.equal(res.statusCode, 200);
    const { lemma, items } = res.json().data as {
      lemma: string;
      items: { phrase: string; kind: string; meaning: string }[];
    };
    assert.equal(lemma, "want");
    assert.deepEqual(
      items.map((i) => i.phrase),
      ["in want of"],
    );
    assert.equal(items[0]!.kind, "idiom");
    assert.ok(items[0]!.meaning.length > 0);
  });
  test("a word no phrase uses → an empty list, not a 404", async () => {
    const res = await app.inject({
      method: "GET",
      url: "/v1/phrases/of?word=fortune",
    });
    assert.equal(res.statusCode, 200);
    assert.deepEqual(res.json().data.items, []);
  });
  test("a phrase is not asked about itself", async () => {
    const res = await app.inject({
      method: "GET",
      url: "/v1/phrases/of?word=in%20want%20of",
    });
    assert.equal(res.statusCode, 200);
    assert.deepEqual(res.json().data.items, []);
  });
});
