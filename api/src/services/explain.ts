/**
 * The two things a reader needs once the words have stopped being the problem:
 * how a sentence is built, and what just happened in the passage.
 *
 * Both take a stretch of the book and return one validated JSON object, cached
 * forever by content hash. They share a file because they are the same
 * operation on a passage with a different prompt and schema; `/translate`
 * streams because a sentence's Hindi is wanted word by word, while these are
 * read whole and gain nothing from arriving in pieces.
 */
import { createHash } from 'node:crypto';
import type { CacheStore } from '../cache/cache.js';
import type { Config } from '../config.js';
import {
  promptText,
  schemaForModel,
  validate,
  type GrammarNote,
  type PassageSummary,
} from '../contracts.js';
import type { JsonRequest, LLMProvider, Usage } from '../llm/provider.js';
import { zeroUsage } from '../llm/provider.js';
import { completeValidated } from '../llm/validated.js';
import { normalizeSentence } from '../normalize.js';

const sha = (s: string) => createHash('sha256').update(s, 'utf8').digest('hex');

export const grammarKey = (sentence: string, context?: string) =>
  sha(`grammar:${normalizeSentence(sentence)}|${normalizeSentence(context ?? '')}`);
export const summaryKey = (passage: string) => sha(`summary:${normalizeSentence(passage)}`);

export type ExplainOutcome<T> = {
  result: T;
  cache: 'hit' | 'miss';
  usage: Usage;
  model?: string;
};

export type ExplainDeps = {
  config: Pick<
    Config,
    'LLM_GRAMMAR_MODEL' | 'LLM_SUMMARY_MODEL' | 'LLM_TEMPERATURE' | 'LLM_GRAMMAR_MAX_TOKENS' | 'LLM_SUMMARY_MAX_TOKENS'
  >;
  llm: LLMProvider;
  cache: CacheStore;
  log: { warn: (obj: object, msg: string) => void };
  /** Called just before a model call; throw to refuse (rate limit). */
  spend?: () => void;
};

/** Why this sentence is built the way it is, in Hindi. */
export async function explainGrammar(
  deps: ExplainDeps,
  sentence: string,
  context?: string,
): Promise<ExplainOutcome<GrammarNote>> {
  const source = normalizeSentence(sentence);
  const key = grammarKey(source, context);
  const cached = await deps.cache.get<GrammarNote>(key);
  if (cached) return { result: cached, cache: 'hit', usage: zeroUsage };

  deps.spend?.();
  const req: JsonRequest = {
    model: deps.config.LLM_GRAMMAR_MODEL,
    messages: [
      { role: 'system', content: promptText('grammar-system') },
      {
        role: 'user',
        content: JSON.stringify({ sentence: source, ...(context ? { context: normalizeSentence(context) } : {}) }),
      },
    ],
    schemaName: 'grammar_note',
    schema: schemaForModel('grammarNote'),
    maxOutputTokens: deps.config.LLM_GRAMMAR_MAX_TOKENS,
    ...(deps.config.LLM_TEMPERATURE === undefined ? {} : { temperature: deps.config.LLM_TEMPERATURE }),
  };

  const { parsed, usage, model } = await completeValidated<GrammarNote>(
    deps,
    req,
    validate.grammarNote,
    'grammar',
  );
  // The model is told to echo the sentence; trust our own copy of it.
  const result: GrammarNote = { ...parsed, source };
  await deps.cache.set(key, 'grammar', result);
  return { result, cache: 'miss', usage, model };
}

/** What happened in this stretch of the book, in Hindi. */
export async function summarizePassage(
  deps: ExplainDeps,
  passage: string,
): Promise<ExplainOutcome<PassageSummary>> {
  const source = normalizeSentence(passage);
  const key = summaryKey(source);
  const cached = await deps.cache.get<PassageSummary>(key);
  if (cached) return { result: cached, cache: 'hit', usage: zeroUsage };

  deps.spend?.();
  const req: JsonRequest = {
    model: deps.config.LLM_SUMMARY_MODEL,
    messages: [
      { role: 'system', content: promptText('summary-system') },
      { role: 'user', content: JSON.stringify({ passage: source }) },
    ],
    schemaName: 'passage_summary',
    schema: schemaForModel('passageSummary'),
    maxOutputTokens: deps.config.LLM_SUMMARY_MAX_TOKENS,
    ...(deps.config.LLM_TEMPERATURE === undefined ? {} : { temperature: deps.config.LLM_TEMPERATURE }),
  };

  const { parsed, usage, model } = await completeValidated<PassageSummary>(
    deps,
    req,
    validate.passageSummary,
    'summary',
  );
  await deps.cache.set(key, 'summary', parsed);
  return { result: parsed, cache: 'miss', usage, model };
}
