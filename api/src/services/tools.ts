/**
 * The writing tools: Hindi in and English out, and English the reader wrote
 * put right.
 *
 * Both are the reverse of what the rest of the app does. The dictionary and
 * /translate help somebody *read* English; these two are the first things here
 * that help them produce it, which is the half of a language a reader-only app
 * never reaches.
 *
 * One validated JSON object each, cached forever by content hash.
 */
import { createHash } from 'node:crypto';
import type { CacheStore } from '../cache/cache.js';
import type { Config } from '../config.js';
import { promptText, schemaForModel, validate, type EnglishDraft, type Proofread } from '../contracts.js';
import type { JsonRequest, LLMProvider, Usage } from '../llm/provider.js';
import { zeroUsage } from '../llm/provider.js';
import { completeValidated } from '../llm/validated.js';
import { normalizeSentence } from '../normalize.js';

const sha = (s: string) => createHash('sha256').update(s, 'utf8').digest('hex');

export const englishKey = (hindi: string) => sha(`english:${normalizeSentence(hindi)}`);
export const proofreadKey = (text: string) => sha(`proofread:${normalizeSentence(text)}`);

export type ToolOutcome<T> = { result: T; cache: 'hit' | 'miss'; usage: Usage; model?: string };

export type ToolDeps = {
  config: Pick<
    Config,
    'LLM_TOOLS_MODEL' | 'LLM_TEMPERATURE' | 'LLM_ENGLISH_MAX_TOKENS' | 'LLM_PROOFREAD_MAX_TOKENS'
  >;
  llm: LLMProvider;
  cache: CacheStore;
  log: { warn: (obj: object, msg: string) => void };
  spend?: () => void;
};

/** What the reader wants to say, in English. */
export async function toEnglish(deps: ToolDeps, hindi: string): Promise<ToolOutcome<EnglishDraft>> {
  const source = normalizeSentence(hindi);
  const key = englishKey(source);
  const cached = await deps.cache.get<EnglishDraft>(key);
  if (cached) return { result: cached, cache: 'hit', usage: zeroUsage };

  deps.spend?.();
  const req: JsonRequest = {
    model: deps.config.LLM_TOOLS_MODEL,
    messages: [
      { role: 'system', content: promptText('english-system') },
      { role: 'user', content: JSON.stringify({ hindi: source }) },
    ],
    schemaName: 'english_draft',
    schema: schemaForModel('englishDraft'),
    maxOutputTokens: deps.config.LLM_ENGLISH_MAX_TOKENS,
    ...(deps.config.LLM_TEMPERATURE === undefined ? {} : { temperature: deps.config.LLM_TEMPERATURE }),
  };
  const { parsed, usage, model } = await completeValidated<EnglishDraft>(
    deps,
    req,
    validate.englishDraft,
    'english',
  );
  await deps.cache.set(key, 'english', parsed);
  return { result: parsed, cache: 'miss', usage, model };
}

/** The reader's English, corrected, with each fix named so it can be shown in place. */
export async function proofread(deps: ToolDeps, text: string): Promise<ToolOutcome<Proofread>> {
  // Not normalizeSentence: the writer's own spacing and line breaks are what
  // the editor underlines into, so the text has to come back as they typed it.
  const source = text.trim();
  const key = proofreadKey(source);
  const cached = await deps.cache.get<Proofread>(key);
  if (cached) return { result: cached, cache: 'hit', usage: zeroUsage };

  deps.spend?.();
  const req: JsonRequest = {
    model: deps.config.LLM_TOOLS_MODEL,
    messages: [
      { role: 'system', content: promptText('proofread-system') },
      { role: 'user', content: JSON.stringify({ text: source }) },
    ],
    schemaName: 'proofread',
    schema: schemaForModel('proofread'),
    maxOutputTokens: deps.config.LLM_PROOFREAD_MAX_TOKENS,
    ...(deps.config.LLM_TEMPERATURE === undefined ? {} : { temperature: deps.config.LLM_TEMPERATURE }),
  };
  const { parsed, usage, model } = await completeValidated<Proofread>(
    deps,
    req,
    validate.proofread,
    'proofread',
  );
  // A fix the editor cannot find in the text would underline nothing, so drop
  // any whose `wrong` the model paraphrased instead of copying.
  const fixes = parsed.fixes.filter((f) => source.includes(f.wrong));
  if (fixes.length !== parsed.fixes.length) {
    deps.log.warn(
      { dropped: parsed.fixes.length - fixes.length },
      'proofread: fix did not quote the text, dropped',
    );
  }
  const result: Proofread = { ...parsed, fixes };
  await deps.cache.set(key, 'proofread', result);
  return { result, cache: 'miss', usage, model };
}
