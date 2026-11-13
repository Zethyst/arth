/**
 * On-demand generation, in two flavours, for the two ways a tap can miss.
 *
 * `generateOnDemand` writes the Hindi layer for a lemma that is staged
 * (Wiktionary senses present, no entry yet), built the first time a reader
 * taps it. Same prompt, gold examples, schema and cross-checks as
 * pipeline/04_generate.py, so an on-demand entry is indistinguishable from a
 * batch one.
 *
 * `generateUnknown` is the backstop under that: a token nothing has staged
 * either, which is where the compounds live — `decision-making`,
 * `rank-and-file`, `well-meaning`. There is no extract to translate, so the
 * model writes the senses too, and is told to return nothing at all rather
 * than invent a meaning for a name or a scanning error.
 *
 * Both upsert into `entries` for ever; a concurrent tap on the same word
 * shares the in-flight promise instead of paying twice.
 */
import type { Config } from '../config.js';
import {
  formatErrors,
  promptExamples,
  promptText,
  schemaForModel,
  validate,
  withoutNulls,
  type DictionaryEntry,
  type EntryGeneration,
  type UnknownEntry,
  type WiktionaryExtract,
} from '../contracts.js';
import type { ChatMessage, JsonRequest, LLMProvider, Usage } from '../llm/provider.js';
import { addUsage, zeroUsage } from '../llm/provider.js';

export interface StagingStore {
  findStaged(lemma: string): Promise<{ extract: WiktionaryExtract; freqRank: number } | null>;
  saveGenerated(entry: DictionaryEntry, meta: { freqRank: number; model: string; tier: EntryTier }): Promise<void>;
}

export type OnDemandDeps = {
  config: Pick<Config, 'LLM_ENTRY_MODEL' | 'LLM_TEMPERATURE' | 'LLM_ENTRY_MAX_TOKENS'>;
  llm: LLMProvider;
  staging: StagingStore;
  log: { warn: (obj: object, msg: string) => void; info: (obj: object, msg: string) => void };
  /** Called just before a model call; throw to refuse (rate limit). */
  spend?: () => void;
};

export type OnDemandOutcome = { entry: DictionaryEntry; usage: Usage; model: string; attempts: number };

/** Like OnDemandOutcome, but a null entry: the model did not recognise the token. */
export type UnknownOutcome = { entry: DictionaryEntry | null; usage: Usage; model: string; attempts: number };

/** How an entry got written. `coined` had no Wiktionary behind it. */
export type EntryTier = 'ondemand' | 'coined';

/**
 * The freqRank a coined entry is filed under. The seed is every entry below
 * `maxRank`, so a rank past every real one is downloaded by no phone and
 * evicts no word from the slice — right for an entry no pipeline has checked,
 * and the reason a coined word still costs a round trip on the next phone.
 */
export const COINED_RANK = 9_000_000;

const DEVANAGARI = /[\u0900-\u097F]/; // Devanagari block
const ENGLISH_WORD = /[A-Za-z]{3,}/;

function userMessage(x: WiktionaryExtract): string {
  return JSON.stringify({
    word: x.word,
    ipa: x.ipa,
    isPhrase: x.isPhrase,
    senses: x.senses.map((s) => ({ index: s.index, partOfSpeech: s.partOfSpeech, gloss: s.gloss, examples: s.examples })),
    synonyms: x.synonyms,
    antonyms: x.antonyms,
    forms: x.forms.map((f) => ({ en: f.en, label: f.label })),
  });
}

function prefix(): ChatMessage[] {
  const msgs: ChatMessage[] = [{ role: 'system', content: promptText('entry-system') }];
  for (const ex of promptExamples().entry) {
    msgs.push({ role: 'user', content: JSON.stringify(ex.input) });
    msgs.push({ role: 'assistant', content: JSON.stringify(ex.output) });
  }
  return msgs;
}

function checkHindi(path: string, value: string, errors: string[], allowLatin = false): void {
  if (!value.trim()) errors.push(`${path}: empty`);
  else if (!DEVANAGARI.test(value)) errors.push(`${path}: no Devanagari`);
  else if (!allowLatin && ENGLISH_WORD.test(value)) errors.push(`${path}: English word in Hindi field`);
}

/** Port of pipeline/arth_pipeline/generate.py::parse_generation. */
export function parseGeneration(x: WiktionaryExtract, content: string): { ok: true; entry: DictionaryEntry } | { ok: false; error: string } {
  let raw: unknown;
  try {
    raw = withoutNulls(JSON.parse(content));
  } catch (e) {
    return { ok: false, error: `not JSON: ${(e as Error).message}` };
  }
  if (!validate.entryGeneration(raw)) return { ok: false, error: `schema: ${formatErrors(validate.entryGeneration.errors)}` };
  const gen = raw as EntryGeneration;
  const errors: string[] = [];
  if (gen.senses.length !== x.senses.length) errors.push(`senses: expected ${x.senses.length}, got ${gen.senses.length}`);
  gen.senses.forEach((s, i) => {
    const exp = x.senses[i];
    if (!exp) return;
    if (s.index !== exp.index) errors.push(`senses[${i}].index: expected ${exp.index}, got ${s.index}`);
    s.partOfSpeech = exp.partOfSpeech; // our mapping, not the model's
    // Wiktionary's label, carried straight through: never the model's to write.
    if (exp.styleLabel) s.styleLabel = exp.styleLabel;
    checkHindi(`senses[${i}].meaning`, s.meaning, errors);
    checkHindi(`senses[${i}].definition`, s.definition, errors);
    s.examples.forEach((ex, j) => {
      checkHindi(`senses[${i}].examples[${j}].hi`, ex.hi, errors, true);
      if (!ex.en.trim()) errors.push(`senses[${i}].examples[${j}].en: empty`);
    });
  });
  for (const key of ['synonyms', 'antonyms'] as const) {
    const got = gen[key].map((p) => p.en);
    if (JSON.stringify(got) !== JSON.stringify(x[key])) errors.push(`${key}: en list must be exactly ${JSON.stringify(x[key])}`);
    gen[key].forEach((p, j) => checkHindi(`${key}[${j}].hi`, p.hi, errors, true));
  }
  const gotForms = gen.forms.map((f) => [f.en, f.label]);
  const expForms = x.forms.map((f) => [f.en, f.label]);
  if (JSON.stringify(gotForms) !== JSON.stringify(expForms)) errors.push('forms: (en, label) pairs must match the input');
  gen.forms.forEach((f, j) => checkHindi(`forms[${j}].hi`, f.hi, errors, true));
  checkHindi('hindiPronunciation', gen.hindiPronunciation, errors);
  if (errors.length) return { ok: false, error: errors.slice(0, 8).join('; ') };

  const entry: DictionaryEntry = {
    word: x.word,
    ipa: x.ipa,
    hindiPronunciation: gen.hindiPronunciation,
    senses: gen.senses,
    synonyms: gen.synonyms,
    antonyms: gen.antonyms,
    forms: gen.forms,
    isPhrase: x.isPhrase,
  };
  if (!validate.dictionaryEntry(entry)) return { ok: false, error: `entry: ${formatErrors(validate.dictionaryEntry.errors)}` };
  return { ok: true, entry };
}

const inFlight = new Map<string, Promise<OnDemandOutcome | null>>();

/** Generate, validate (one retry), store. Null when the lemma isn't staged. */
export function generateOnDemand(deps: OnDemandDeps, lemma: string): Promise<OnDemandOutcome | null> {
  const existing = inFlight.get(lemma);
  if (existing) return existing;
  const p = run(deps, lemma).finally(() => inFlight.delete(lemma));
  inFlight.set(lemma, p);
  return p;
}

type Parsed<T> = { ok: true; value: T } | { ok: false; error: string };

/**
 * One model call whose answer has to parse. A model that broke the contract
 * usually mends it when shown what it broke, and the second call is cheaper
 * than serving the reader nothing — but there is no third: twice wrong means
 * the prompt is wrong, not the weather.
 */
async function withOneRetry<T>(
  deps: OnDemandDeps,
  base: JsonRequest,
  parse: (content: string) => Parsed<T>,
  what: string,
  hint: string,
): Promise<{ value: T; usage: Usage; model: string; attempts: number }> {
  const first = await deps.llm.completeJson(base);
  let usage = addUsage(zeroUsage, first.usage);
  const p1 = parse(first.content);
  if (p1.ok) return { value: p1.value, usage, model: first.model, attempts: 1 };

  deps.log.warn({ word: what, error: p1.error }, 'ondemand: invalid output, retrying once');
  const second = await deps.llm.completeJson({
    ...base,
    messages: [
      ...base.messages,
      { role: 'assistant', content: first.content },
      { role: 'user', content: `That answer failed validation: ${p1.error}. ${hint}` },
    ],
  });
  usage = addUsage(usage, second.usage);
  const p2 = parse(second.content);
  if (!p2.ok) throw new Error(`ondemand: invalid twice for ${what}: ${p2.error}`);
  return { value: p2.value, usage, model: second.model, attempts: 2 };
}

async function run(deps: OnDemandDeps, lemma: string): Promise<OnDemandOutcome | null> {
  const staged = await deps.staging.findStaged(lemma);
  if (!staged) return null;
  const x = staged.extract;
  deps.spend?.();
  const model = deps.config.LLM_ENTRY_MODEL;
  const base: JsonRequest = {
    model,
    messages: [...prefix(), { role: 'user', content: userMessage(x) }],
    schemaName: 'entry_generation',
    schema: schemaForModel('entryGeneration'),
    maxOutputTokens: deps.config.LLM_ENTRY_MAX_TOKENS,
    ...(deps.config.LLM_TEMPERATURE === undefined ? {} : { temperature: deps.config.LLM_TEMPERATURE }),
  };
  const started = Date.now();
  const out = await withOneRetry(
    deps,
    base,
    (content) => {
      const r = parseGeneration(x, content);
      return r.ok ? { ok: true, value: r.entry } : r;
    },
    lemma,
    'Return the corrected JSON for the same word. Keep every sense, in order, with the same index and partOfSpeech; keep every en value exactly as given.',
  );
  await deps.staging.saveGenerated(out.value, { freqRank: staged.freqRank, model: out.model, tier: 'ondemand' });
  deps.log.info({ lemma, ms: Date.now() - started, usage: out.usage, attempts: out.attempts }, 'ondemand: generated');
  return { entry: out.value, usage: out.usage, model: out.model, attempts: out.attempts };
}

/**
 * A token worth paying a model call for.
 *
 * A reader taps whatever is under their thumb: page numbers, running heads,
 * initials, and whatever the scanner made of a smudge. Letters only, with an
 * inner hyphen or apostrophe allowed, is the cheapest filter that keeps every
 * real compound and turns away most of the rest; the model itself turns away
 * the names and the misreadings that get through.
 */
const WRITABLE = /^[a-z][a-z'\u2019-]*[a-z]$/;

export function isCoinable(word: string): boolean {
  const w = word.trim().toLowerCase();
  return w.length >= 4 && w.length <= 40 && WRITABLE.test(w);
}

/** Port of parseGeneration for an entry with no Wiktionary behind it. */
export function parseUnknown(word: string, content: string): Parsed<DictionaryEntry | null> {
  let raw: unknown;
  try {
    raw = withoutNulls(JSON.parse(content));
  } catch (e) {
    return { ok: false, error: `not JSON: ${(e as Error).message}` };
  }
  if (!validate.unknownEntry(raw)) return { ok: false, error: `schema: ${formatErrors(validate.unknownEntry.errors)}` };
  const gen = raw as UnknownEntry;
  // The model's way of saying it has never met this token. Not an error:
  // the one answer we would rather have than a confident invention.
  if (gen.senses.length === 0) return { ok: true, value: null };

  const errors: string[] = [];
  gen.senses.forEach((s, i) => {
    if (s.index !== i) errors.push(`senses[${i}].index: expected ${i}, got ${s.index}`);
    checkHindi(`senses[${i}].partOfSpeech`, s.partOfSpeech, errors);
    checkHindi(`senses[${i}].meaning`, s.meaning, errors);
    checkHindi(`senses[${i}].definition`, s.definition, errors);
    if (s.examples.length === 0) errors.push(`senses[${i}].examples: write one`);
    s.examples.forEach((ex, j) => {
      checkHindi(`senses[${i}].examples[${j}].hi`, ex.hi, errors, true);
      if (!ex.en.trim()) errors.push(`senses[${i}].examples[${j}].en: empty`);
    });
  });
  for (const key of ['synonyms', 'antonyms'] as const) {
    gen[key].forEach((pair, j) => {
      if (!pair.en.trim()) errors.push(`${key}[${j}].en: empty`);
      checkHindi(`${key}[${j}].hi`, pair.hi, errors, true);
    });
  }
  gen.forms.forEach((f, j) => {
    if (!f.en.trim()) errors.push(`forms[${j}].en: empty`);
    checkHindi(`forms[${j}].label`, f.label, errors, true);
    checkHindi(`forms[${j}].hi`, f.hi, errors, true);
  });
  if (errors.length) return { ok: false, error: errors.slice(0, 8).join('; ') };

  const entry: DictionaryEntry = {
    word,
    ipa: gen.ipa,
    hindiPronunciation: gen.hindiPronunciation,
    senses: gen.senses,
    synonyms: gen.synonyms,
    antonyms: gen.antonyms,
    forms: gen.forms,
    isPhrase: word.includes(' '),
  };
  if (!validate.dictionaryEntry(entry)) return { ok: false, error: `entry: ${formatErrors(validate.dictionaryEntry.errors)}` };
  return { ok: true, value: entry };
}

const coining = new Map<string, Promise<UnknownOutcome>>();

/**
 * Write the entry for a word nothing has staged. `entry: null` is the model
 * declining the token; the caller refunds the reader's AI use and answers the
 * ordinary 404.
 */
export function generateUnknown(deps: OnDemandDeps, word: string): Promise<UnknownOutcome> {
  const existing = coining.get(word);
  if (existing) return existing;
  const p = coin(deps, word).finally(() => coining.delete(word));
  coining.set(word, p);
  return p;
}

async function coin(deps: OnDemandDeps, word: string): Promise<UnknownOutcome> {
  deps.spend?.();
  const base: JsonRequest = {
    model: deps.config.LLM_ENTRY_MODEL,
    messages: [
      { role: 'system', content: promptText('unknown-system') },
      { role: 'user', content: JSON.stringify({ word }) },
    ],
    schemaName: 'unknown_entry',
    schema: schemaForModel('unknownEntry'),
    maxOutputTokens: deps.config.LLM_ENTRY_MAX_TOKENS,
    ...(deps.config.LLM_TEMPERATURE === undefined ? {} : { temperature: deps.config.LLM_TEMPERATURE }),
  };
  const started = Date.now();
  const out = await withOneRetry(
    deps,
    base,
    (content) => parseUnknown(word, content),
    word,
    'Return the corrected JSON for the same word, or an empty senses array if you do not recognise it.',
  );
  if (out.value) await deps.staging.saveGenerated(out.value, { freqRank: COINED_RANK, model: out.model, tier: 'coined' });
  deps.log.info(
    { word, ms: Date.now() - started, usage: out.usage, attempts: out.attempts, known: out.value !== null },
    'ondemand: coined',
  );
  return { entry: out.value, usage: out.usage, model: out.model, attempts: out.attempts };
}

/**
 * Morphology fallback for the "Did you mean" list: strip common affixes and
 * keep the bases that resolve. brimless → brim, bespattered → bespatter (via
 * forms), tremulously → tremulous.
 */
const SUFFIXES = ['ly', 'ness', 'less', 'ful', 'ish', 'ment', 'able', 'ible', 'ously', 'ing', 'ed', 'es', 's', 'er', 'est', 'ish'];
const PREFIXES = ['be', 'un', 're', 'dis', 'mis', 'over', 'under'];

function stems(word: string): string[] {
  const out: string[] = [];
  for (const sfx of SUFFIXES) {
    if (word.endsWith(sfx) && word.length - sfx.length >= 3) {
      const stem = word.slice(0, -sfx.length);
      out.push(stem, `${stem}e`); // tremul-ous-ly → tremulous; bak-ing → bake
      if (stem.length > 3 && stem[stem.length - 1] === stem[stem.length - 2]) out.push(stem.slice(0, -1)); // stopp-ed → stop
      if (stem.endsWith('i')) out.push(`${stem.slice(0, -1)}y`); // happi-ly → happy
    }
  }
  for (const pfx of PREFIXES) {
    if (word.startsWith(pfx) && word.length - pfx.length >= 3) out.push(word.slice(pfx.length));
  }
  return out;
}

export async function morphologySuggestions(
  word: string,
  exists: (candidate: string) => Promise<boolean>,
  limit = 3,
): Promise<string[]> {
  const out: string[] = [];
  const seen = new Set<string>([word]);
  // Two affixes deep at most: un-kind-ness → kind.
  const first = stems(word);
  const queue = [...first, ...first.flatMap(stems)];
  for (const c of queue) {
    if (out.length >= limit) break;
    if (c.length < 3 || seen.has(c)) continue;
    seen.add(c);
    if (await exists(c)) out.push(c);
  }
  return out;
}
