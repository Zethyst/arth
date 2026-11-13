/**
 * One model call that must come back as JSON our contract accepts.
 *
 * Shared by the services whose answer is a single object (/grammar, /summary,
 * /english, /proofread). Two things go wrong often enough to handle here: the
 * output budget is exhausted before any JSON appears, because hidden reasoning
 * tokens count against it; and the model returns JSON that does not satisfy
 * the schema, which it will usually fix if shown the error.
 */
import { formatErrors, withoutNulls } from '../contracts.js';
import { ApiError } from '../lib/errors.js';
import type { JsonRequest, JsonResult, LLMProvider, Usage } from './provider.js';
import { addUsage, zeroUsage } from './provider.js';

export type ValidatedDeps = {
  llm: LLMProvider;
  log: { warn: (obj: object, msg: string) => void };
};

export async function completeValidated<T>(
  deps: ValidatedDeps,
  req: JsonRequest,
  check: (x: unknown) => boolean,
  what: string,
): Promise<{ parsed: T; usage: Usage; model: string }> {
  let usage = zeroUsage;
  let first: JsonResult;
  try {
    first = await deps.llm.completeJson(req);
  } catch (err) {
    if (!(err instanceof ApiError && err.extra['finish'] === 'length')) throw err;
    deps.log.warn({ maxOutputTokens: req.maxOutputTokens }, `${what}: output budget exhausted, retrying with 2×`);
    first = await deps.llm.completeJson({ ...req, maxOutputTokens: req.maxOutputTokens * 2 });
  }
  usage = addUsage(usage, first.usage);
  const p1 = tryParse<T>(first.content, check);
  if (p1.ok) return { parsed: p1.value, usage, model: first.model };

  deps.log.warn({ error: p1.error }, `${what}: invalid model output, retrying once`);
  const second = await deps.llm.completeJson({
    ...req,
    messages: [
      ...req.messages,
      { role: 'assistant', content: first.content },
      { role: 'user', content: `That answer failed validation: ${p1.error}. Return the corrected JSON.` },
    ],
  });
  usage = addUsage(usage, second.usage);
  const p2 = tryParse<T>(second.content, check);
  if (p2.ok) return { parsed: p2.value, usage, model: second.model };
  throw new Error(`${what}: model output invalid twice: ${p2.error}`);
}

function tryParse<T>(
  content: string,
  check: (x: unknown) => boolean,
): { ok: true; value: T } | { ok: false; error: string } {
  let value: unknown;
  try {
    value = withoutNulls(JSON.parse(content));
  } catch (e) {
    return { ok: false, error: `not JSON: ${(e as Error).message}` };
  }
  if (!check(value)) {
    return { ok: false, error: formatErrors((check as { errors?: import('ajv').ErrorObject[] }).errors) };
  }
  return { ok: true, value: value as T };
}
