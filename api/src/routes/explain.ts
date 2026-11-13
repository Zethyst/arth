import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { openGate, type AiGate } from '../auth/ai-gate.js';
import { cacheStats } from '../cache/cache.js';
import { ApiError, messages } from '../lib/errors.js';
import { ok } from '../lib/envelope.js';
import { explainGrammar, summarizePassage, type ExplainDeps } from '../services/explain.js';
import type { LlmSpend } from './context.js';

const GrammarBody = z.object({
  text: z.string().trim().min(1).max(2000),
  context: z.string().trim().max(2000).optional(),
});

/** A chapter, not a sentence: long enough to be worth summarising, bounded so one tap cannot cost a fortune. */
const SummaryBody = z.object({
  text: z.string().trim().min(200).max(20000),
});

export const explainRoutes: FastifyPluginAsync<{
  deps: ExplainDeps;
  spend: LlmSpend;
  gate?: AiGate;
}> = async (app, { deps, spend, gate = openGate }) => {
  /**
   * POST /v1/grammar — how this sentence is built, in Hindi. The translation
   * says what it means; this says how it works.
   */
  app.post('/grammar', async (request, reply) => {
    const parsed = GrammarBody.safeParse(request.body);
    if (!parsed.success) throw new ApiError('BAD_REQUEST', messages.badRequest);
    await gate(request, reply);
    const out = await explainGrammar(
      { ...deps, spend: () => spend(request) },
      parsed.data.text,
      parsed.data.context,
    );
    if (out.cache === 'hit') cacheStats.hits++;
    else cacheStats.misses++;
    request.meta.cache = out.cache;
    request.meta.tokens = out.usage;
    if (out.model) request.meta.model = out.model;
    return ok(out.result);
  });

  /** POST /v1/summary — what happened in this stretch of the book, in Hindi. */
  app.post('/summary', async (request, reply) => {
    const parsed = SummaryBody.safeParse(request.body);
    if (!parsed.success) throw new ApiError('BAD_REQUEST', messages.badRequest);
    await gate(request, reply);
    const out = await summarizePassage({ ...deps, spend: () => spend(request) }, parsed.data.text);
    if (out.cache === 'hit') cacheStats.hits++;
    else cacheStats.misses++;
    request.meta.cache = out.cache;
    request.meta.tokens = out.usage;
    if (out.model) request.meta.model = out.model;
    return ok(out.result);
  });
};
