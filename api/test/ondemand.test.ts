import { test, describe, after } from 'node:test';
import assert from 'node:assert/strict';
import { buildApp } from '../src/app.js';
import { promptExamples, validate, type WiktionaryExtract } from '../src/contracts.js';
import { isCoinable, morphologySuggestions, parseGeneration, parseUnknown } from '../src/services/ondemand.js';
import { appOptions, FakeLLM } from './fakes.js';

// The gold example for "fortune" is exactly what 08_stage.py stores, and its
// output is a valid generation — so it doubles as the fixture here.
const gold = promptExamples().entry.find((e) => e.input['word'] === 'fortune')!;
const extract = gold.input as unknown as WiktionaryExtract;
const good = JSON.stringify(gold.output);

describe('parseGeneration', () => {
  test('accepts the gold output and merges the Wiktionary side', () => {
    const r = parseGeneration(extract, good);
    assert.ok(r.ok);
    if (r.ok) {
      assert.equal(r.entry.word, 'fortune');
      assert.equal(r.entry.ipa, extract.ipa);
      assert.ok(validate.dictionaryEntry(r.entry));
    }
  });
  test('rejects a dropped sense, an English word in Hindi prose, a changed synonym', () => {
    const drop = JSON.parse(good);
    drop.senses.pop();
    assert.match((parseGeneration(extract, JSON.stringify(drop)) as { error: string }).error, /expected 3/);
    const english = JSON.parse(good);
    english.senses[0].definition = 'बहुत सारा money';
    assert.match((parseGeneration(extract, JSON.stringify(english)) as { error: string }).error, /English word/);
    const syn = JSON.parse(good);
    syn.synonyms[0].en = 'money';
    assert.match((parseGeneration(extract, JSON.stringify(syn)) as { error: string }).error, /synonyms/);
    assert.match((parseGeneration(extract, '{') as { error: string }).error, /not JSON/);
  });
});

describe('GET /v1/lookup with staging', () => {
  test('a staged lemma is generated on first lookup, stored, and served from entries after', async () => {
    const staged = { tremulous: { ...extract, word: 'tremulous' } };
    const out = { ...gold.output };
    const llm = new FakeLLM({ entry_generation: [JSON.stringify(out)] });
    const app = buildApp(appOptions(llm, {}, staged));
    after(() => app.close());

    const r1 = await app.inject({ method: 'GET', url: '/v1/lookup?word=Tremulous' });
    assert.equal(r1.statusCode, 200);
    assert.equal(r1.json().data.word, 'tremulous');
    assert.ok(validate.dictionaryEntry(r1.json().data));
    assert.equal(llm.requests.length, 1);
    assert.equal(llm.requests[0]!.model, 'fake-entry');
    assert.equal(llm.requests[0]!.schemaName, 'entry_generation');
    assert.equal(JSON.parse(llm.requests[0]!.messages.at(-1)!.content).word, 'tremulous');

    const r2 = await app.inject({ method: 'GET', url: '/v1/lookup?word=tremulous' });
    assert.equal(r2.statusCode, 200);
    assert.equal(llm.requests.length, 1, 'second lookup is a plain entry read');
  });

  test('an inflected form of a staged lemma resolves through forms', async () => {
    const staged = { bespatter: { ...extract, word: 'bespatter' } };
    const llm = new FakeLLM({ entry_generation: [JSON.stringify(gold.output)] });
    const opts = appOptions(llm, {}, staged);
    const store = opts.store;
    const origForm = store.findFormLemma.bind(store);
    store.findFormLemma = async (f) => (f === 'bespattered' ? 'bespatter' : origForm(f));
    const app = buildApp(opts);
    after(() => app.close());
    const r = await app.inject({ method: 'GET', url: '/v1/lookup?word=bespattered' });
    assert.equal(r.statusCode, 200);
    assert.equal(r.json().data.word, 'bespatter');
  });

  test('invalid output is retried once with the error appended', async () => {
    const bad = JSON.parse(good);
    bad.senses.pop();
    const llm = new FakeLLM({ entry_generation: [JSON.stringify(bad), good] });
    const app = buildApp(appOptions(llm, {}, { brim: { ...extract, word: 'brim' } }));
    after(() => app.close());
    const r = await app.inject({ method: 'GET', url: '/v1/lookup?word=brim' });
    assert.equal(r.statusCode, 200);
    assert.equal(llm.requests.length, 2);
    assert.match(llm.requests[1]!.messages.at(-1)!.content, /failed validation/);
  });

  test('generation spends the LLM budget; when exhausted → 429, not a bad entry', async () => {
    const llm = new FakeLLM({ entry_generation: [good, good] });
    const app = buildApp({ ...appOptions(llm, {}, { a1: { ...extract, word: 'a1' }, a2: { ...extract, word: 'a2' } }), rateLimits: { lookups: 100, llm: 1, prefetch: 1 } });
    after(() => app.close());
    const h = { 'x-device-id': 'dev-G' };
    assert.equal((await app.inject({ method: 'GET', url: '/v1/lookup?word=a1', headers: h })).statusCode, 200);
    assert.equal((await app.inject({ method: 'GET', url: '/v1/lookup?word=a2', headers: h })).statusCode, 429);
  });

  test('unknown word → 404 with morphology suggestions that exist', async () => {
    const app = buildApp(appOptions(new FakeLLM({}), {}, { brim: { ...extract, word: 'brim' } }));
    after(() => app.close());
    const r = await app.inject({ method: 'GET', url: '/v1/lookup?word=brimless' });
    assert.equal(r.statusCode, 404);
    assert.deepEqual(r.json().error.suggestions, ['brim']);
    const r2 = await app.inject({ method: 'GET', url: '/v1/lookup?word=fortunes' });
    assert.equal(r2.statusCode, 200, 'seed form resolves before morphology');
  });
});

describe('morphologySuggestions', () => {
  const vocab = new Set(['tremulous', 'happy', 'stop', 'bake', 'brim', 'spatter', 'kind']);
  const exists = async (c: string) => vocab.has(c);
  test('suffixes, doubled consonants, -i → -y, prefixes', async () => {
    assert.deepEqual(await morphologySuggestions('tremulously', exists), ['tremulous']);
    assert.deepEqual(await morphologySuggestions('happily', exists), ['happy']);
    assert.deepEqual(await morphologySuggestions('stopped', exists), ['stop']);
    assert.deepEqual(await morphologySuggestions('baking', exists), ['bake']);
    assert.deepEqual(await morphologySuggestions('brimless', exists), ['brim']);
    assert.deepEqual(await morphologySuggestions('unkindness', exists), ['kind']);
    assert.deepEqual(await morphologySuggestions('xyzzy', exists), []);
  });
});

// ---- Words nothing has staged: the model writes the whole entry. ----

const coined = {
  ipa: 'dɪˈsɪʒənˌmeɪkɪŋ',
  hindiPronunciation: 'डिसिज़न-मेकिंग',
  senses: [
    {
      index: 0,
      partOfSpeech: 'संज्ञा',
      meaning: 'निर्णय लेना',
      definition: 'किसी बात पर सोच-समझकर फ़ैसला करने का काम।',
      examples: [{ en: 'Decision-making takes time.', hi: 'फ़ैसला करने में समय लगता है।' }],
    },
  ],
  synonyms: [{ en: 'judgement', hi: 'फ़ैसला' }],
  antonyms: [],
  forms: [],
};
const declined = { ipa: '', hindiPronunciation: '', senses: [], synonyms: [], antonyms: [], forms: [] };

describe('parseUnknown', () => {
  test('builds a whole DictionaryEntry out of the model’s answer', () => {
    const r = parseUnknown('decision-making', JSON.stringify(coined));
    assert.ok(r.ok);
    if (r.ok && r.value) {
      assert.equal(r.value.word, 'decision-making');
      assert.equal(r.value.isPhrase, false, 'a hyphen is not a space');
      assert.equal(r.value.ipa, coined.ipa);
      assert.ok(validate.dictionaryEntry(r.value));
    }
  });

  test('an empty senses array is "I don’t know it", not an error', () => {
    const r = parseUnknown('mehtras', JSON.stringify(declined));
    assert.ok(r.ok);
    assert.equal(r.ok && r.value, null);
  });

  test('rejects English in Hindi prose, a misnumbered sense, a nameless synonym', () => {
    const english = structuredClone(coined);
    english.senses[0]!.definition = 'फ़ैसला करने का process।';
    assert.match((parseUnknown('x', JSON.stringify(english)) as { error: string }).error, /English word/);
    const renumbered = structuredClone(coined);
    renumbered.senses[0]!.index = 1;
    assert.match((parseUnknown('x', JSON.stringify(renumbered)) as { error: string }).error, /expected 0/);
    const syn = structuredClone(coined);
    syn.synonyms[0]!.en = ' ';
    assert.match((parseUnknown('x', JSON.stringify(syn)) as { error: string }).error, /synonyms\[0\]\.en/);
    assert.match((parseUnknown('x', '{') as { error: string }).error, /not JSON/);
  });
});

describe('isCoinable', () => {
  test('keeps compounds and contractions, turns away what a thumb hit by mistake', () => {
    for (const w of ['decision-making', 'rank-and-file', "o'clock", 'unrepentantly', 'Prepone']) {
      assert.equal(isCoinable(w), true, w);
    }
    for (const w of ['xiv', 'p-3', '1984', 'e.g.', 'th', 'word-', '', 'two words']) {
      assert.equal(isCoinable(w), false, w);
    }
  });
});

describe('GET /v1/lookup with nothing staged', () => {
  test('writes the entry, serves it, and never pays for it again', async () => {
    const llm = new FakeLLM({ unknown_entry: [JSON.stringify(coined)] });
    const app = buildApp(appOptions(llm));
    after(() => app.close());

    const r1 = await app.inject({ method: 'GET', url: '/v1/lookup?word=decision-making' });
    assert.equal(r1.statusCode, 200);
    assert.equal(r1.json().data.word, 'decision-making');
    assert.equal(r1.json().data.senses[0].meaning, 'निर्णय लेना');
    assert.ok(validate.dictionaryEntry(r1.json().data));
    assert.equal(llm.requests.length, 1);
    assert.equal(llm.requests[0]!.schemaName, 'unknown_entry');
    assert.equal(JSON.parse(llm.requests[0]!.messages.at(-1)!.content).word, 'decision-making');

    const r2 = await app.inject({ method: 'GET', url: '/v1/lookup?word=Decision-Making' });
    assert.equal(r2.statusCode, 200);
    assert.equal(llm.requests.length, 1, 'the second reader reads it out of entries');
  });

  test('a token the model declines is a plain 404, asked about only once', async () => {
    const llm = new FakeLLM({ unknown_entry: [JSON.stringify(declined)] });
    const app = buildApp(appOptions(llm));
    after(() => app.close());

    const r1 = await app.inject({ method: 'GET', url: '/v1/lookup?word=mehtras' });
    assert.equal(r1.statusCode, 404);
    assert.equal(r1.json().error.code, 'NOT_FOUND');

    const r2 = await app.inject({ method: 'GET', url: '/v1/lookup?word=mehtras' });
    assert.equal(r2.statusCode, 404);
    assert.equal(llm.requests.length, 1, 'the refusal is remembered');
  });

  test('a token that is not word-shaped costs nothing to refuse', async () => {
    const llm = new FakeLLM({});
    const app = buildApp(appOptions(llm));
    after(() => app.close());
    const r = await app.inject({ method: 'GET', url: '/v1/lookup?word=xiv' });
    assert.equal(r.statusCode, 404);
    assert.equal(llm.requests.length, 0);
  });

  test('a staged lemma still goes the staged way', async () => {
    const llm = new FakeLLM({ entry_generation: [good] });
    const app = buildApp(appOptions(llm, {}, { tremulous: { ...extract, word: 'tremulous' } }));
    after(() => app.close());
    const r = await app.inject({ method: 'GET', url: '/v1/lookup?word=tremulous' });
    assert.equal(r.statusCode, 200);
    assert.equal(llm.requests[0]!.schemaName, 'entry_generation');
  });
});
