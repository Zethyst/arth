/**
 * Loads the JSON Schemas from ../contracts/schemas and exposes compiled Ajv
 * validators. These are the same files the pipeline and the Dart codegen use;
 * nothing about the wire types is defined only in TypeScript.
 */
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { Ajv, type ValidateFunction, type ErrorObject } from "ajv";

/**
 * contracts/ sits at the repo root, beside api/. Walk up from this module so
 * the path works both from src/ (tsx) and from dist/src/ (compiled), or from
 * wherever CONTRACTS_DIR points.
 */
function findContractsDir(): string {
  if (process.env["CONTRACTS_DIR"]) return process.env["CONTRACTS_DIR"];
  let dir = dirname(fileURLToPath(import.meta.url));
  for (let i = 0; i < 6; i++) {
    const candidate = join(dir, "contracts");
    if (existsSync(join(candidate, "normalize.md"))) return candidate;
    dir = dirname(dir);
  }
  throw new Error("contracts/ directory not found; set CONTRACTS_DIR");
}

const contractsDir = findContractsDir() + "/";
const schemasDir = join(contractsDir, "schemas") + "/";

function load(name: string): Record<string, unknown> {
  return JSON.parse(readFileSync(join(schemasDir, name), "utf8")) as Record<
    string,
    unknown
  >;
}

export const schemas = {
  dictionaryEntry: load("dictionary-entry.json"),
  contextResult: load("context-result.json"),
  contextIndex: load("context-index.json"),
  entryGeneration: load("entry-generation.json"),
  translationResult: load("translation-result.json"),
  phraseMatch: load("phrase-match.json"),
  relatedPhrase: load("related-phrase.json"),
  idiom: load("idiom.json"),
  grammarNote: load("grammar-note.json"),
  passageSummary: load("passage-summary.json"),
  englishDraft: load("english-draft.json"),
  proofread: load("proofread.json"),
  coachTurn: load("coach-turn.json"),
  apiError: load("api-error.json"),
} as const;

/** System prompts shared with the pipeline, verbatim. */
export function promptText(
  name:
    | "context-system"
    | "translate-system"
    | "entry-system"
    | "grammar-system"
    | "summary-system"
    | "english-system"
    | "proofread-system"
    | "coach-system",
): string {
  return readFileSync(`${contractsDir}prompts/${name}.md`, "utf8").trim();
}

export type PromptExamples = {
  entry: { input: Record<string, unknown>; output: Record<string, unknown> }[];
  context: { input: Record<string, unknown>; output: ContextResult }[];
  translate: { input: Record<string, unknown>; output: TranslationResult }[];
};

let examples: PromptExamples | undefined;
export function promptExamples(): PromptExamples {
  examples ??= JSON.parse(
    readFileSync(`${contractsDir}prompt-examples.json`, "utf8"),
  ) as PromptExamples;
  return examples;
}

/**
 * Our JSON Schema, in the shape OpenAI's strict mode will accept.
 *
 * Two differences from the contract. The metadata keys are stripped, because
 * strict mode rejects them. And **every property is listed as required**,
 * because strict mode insists on it: a property our contract leaves optional
 * is made nullable instead, so the model has something legal to put there when
 * it has nothing to say. Without this the call is refused outright — which a
 * test against a fake provider never shows, because only the real API checks.
 */
export function schemaForModel(name: keyof typeof schemas): Record<string, unknown> {
  const { $schema: _s, $id: _i, title: _t, ...rest } = schemas[name] as Record<string, unknown>;
  return strictify(rest) as Record<string, unknown>;
}

function strictify(node: unknown): unknown {
  if (Array.isArray(node)) return node.map(strictify);
  if (node === null || typeof node !== 'object') return node;
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(node as Record<string, unknown>)) out[k] = strictify(v);

  const props = out['properties'];
  if (props && typeof props === 'object') {
    const names = Object.keys(props as Record<string, unknown>);
    const required = new Set((out['required'] as string[] | undefined) ?? []);
    for (const name of names) {
      if (required.has(name)) continue;
      // Optional in the contract, so it has to be nullable for the model.
      const prop = (props as Record<string, Record<string, unknown>>)[name]!;
      const type = prop['type'];
      if (typeof type === 'string' && type !== 'null') prop['type'] = [type, 'null'];
      else if (Array.isArray(type) && !type.includes('null')) prop['type'] = [...type, 'null'];
    }
    out['required'] = names;
  }
  return out;
}

/**
 * The other half of `schemaForModel`: strict mode made every optional property
 * required-but-nullable, so a model with nothing to say sends an explicit
 * `null`. No contract accepts null anywhere, and a null means absent, so the
 * validator has to see it absent — otherwise it rejects a perfectly good
 * answer and we pay for a retry that returns the same null. Nulls inside
 * arrays are left alone: there the length is meaningful.
 */
export function withoutNulls(node: unknown): unknown {
  if (Array.isArray(node)) return node.map(withoutNulls);
  if (node === null || typeof node !== "object") return node;
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(node as Record<string, unknown>)) {
    if (v === null) continue;
    out[k] = withoutNulls(v);
  }
  return out;
}

const ajv = new Ajv({ allErrors: true, strict: true });
for (const s of Object.values(schemas)) ajv.addSchema(s);

function compile<T>(name: keyof typeof schemas): ValidateFunction<T> {
  return ajv.getSchema<T>(
    schemas[name]["$id"] as string,
  ) as ValidateFunction<T>;
}

export const validate = {
  dictionaryEntry: compile<DictionaryEntry>("dictionaryEntry"),
  contextResult: compile<ContextResult>("contextResult"),
  contextIndex: compile<{ senseIndex: number }>("contextIndex"),
  entryGeneration: compile<EntryGeneration>("entryGeneration"),
  translationResult: compile<TranslationResult>("translationResult"),
  phraseMatch: compile<PhraseMatch>("phraseMatch"),
  idiom: compile<Idiom>("idiom"),
  relatedPhrase: compile<RelatedPhrase>("relatedPhrase"),
  grammarNote: compile<GrammarNote>("grammarNote"),
  passageSummary: compile<PassageSummary>("passageSummary"),
  englishDraft: compile<EnglishDraft>("englishDraft"),
  proofread: compile<Proofread>("proofread"),
  coachTurn: compile<CoachTurn>("coachTurn"),
};

export function formatErrors(errors: ErrorObject[] | null | undefined): string {
  return (errors ?? [])
    .map((e) => `${e.instancePath || "/"} ${e.message ?? ""}`)
    .join("; ");
}

// ---- TypeScript views of the contract types. Mirror contracts/schemas exactly. ----

export type BilingualPair = { en: string; hi: string };

export type Sense = {
  index: number;
  partOfSpeech: string;
  meaning: string;
  definition: string;
  /** Wiktionary's own label in Hindi (स्लैंग, पुराना…); '' for a plain sense. */
  styleLabel?: string;
  examples: BilingualPair[];
};

export type Form = { en: string; label: string; hi: string };

export type DictionaryEntry = {
  word: string;
  ipa: string;
  hindiPronunciation: string;
  senses: Sense[];
  synonyms: BilingualPair[];
  antonyms: BilingualPair[];
  forms: Form[];
  isPhrase: boolean;
};

export type ContextResult = {
  senseIndex: number;
  meaning: string;
  note: string;
};

export type TranslationResult = {
  source: string;
  hindi: string;
  simpleMeaning: string;
  difficultWords: BilingualPair[];
};

export type PhraseMatch = {
  phrase: string;
  lemma: string;
  start: number;
  tokenCount: number;
};

/** An idiom the app teaches (contracts/schemas/idiom.json). */
export type Idiom = {
  word: string;
  senseIndex: number;
  tags: string[];
  etymology: string;
  /** The phrase's rarest word's rank. A tie-breaker only; see `weight`. */
  freqRank: number;
  /** Languages the phrase is translated into: how well known it is. Orders the list. */
  weight: number;
  /** `phrasal` for a verb plus particles (give up); `idiom` otherwise. */
  kind: 'idiom' | 'phrasal';
};

/** How a sentence is built, in Hindi (contracts/schemas/grammar-note.json). */
export type GrammarNote = {
  source: string;
  /** One line naming the sentence's skeleton. */
  shape: string;
  points: { part: string; label: string; note: string }[];
};

/** What happened in a stretch of a book (contracts/schemas/passage-summary.json). */
export type PassageSummary = {
  summary: string;
  points: string[];
  people?: { name: string; who: string }[];
};

/** Hindi in, English out (contracts/schemas/english-draft.json). */
export type EnglishDraft = {
  english: string;
  vocab: BilingualPair[];
  alternatives: { tone: 'formal' | 'casual' | 'direct'; text: string }[];
};

/** The reader's English, corrected (contracts/schemas/proofread.json). */
export type Proofread = {
  corrected: string;
  fixes: { wrong: string; right: string; kind: 'spelling' | 'grammar' | 'wording'; why: string }[];
  alternatives: { tone: 'formal' | 'casual' | 'concise'; text: string }[];
};

/** One turn of a spoken practice conversation (contracts/schemas/coach-turn.json). */
export type CoachTurn = {
  reply: string;
  replyHindi: string;
  better?: { text: string; why: string } | undefined;
  closing?: boolean;
};

/** One idiom or phrasal verb built on a headword (contracts/schemas/related-phrase.json). */
export type RelatedPhrase = {
  phrase: string;
  kind: "phrasal" | "idiom";
  partOfSpeech: string;
  meaning: string;
};

/** The model's output for one headword: the Hindi layer only (contracts/schemas/entry-generation.json). */
export type EntryGeneration = {
  hindiPronunciation: string;
  senses: Sense[];
  synonyms: BilingualPair[];
  antonyms: BilingualPair[];
  forms: Form[];
};

/** What pipeline/03_extract.py produces per word and 08_stage.py stores. */
export type WiktionaryExtract = {
  word: string;
  ipa: string;
  isPhrase: boolean;
  senses: {
    index: number;
    partOfSpeech: string;
    styleLabel?: string;
    gloss: string;
    examples: string[];
  }[];
  synonyms: string[];
  antonyms: string[];
  forms: { en: string; label: string }[];
};
