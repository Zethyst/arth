import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { openGate, type AiGate } from '../auth/ai-gate.js';
import { cacheStats } from '../cache/cache.js';
import { ApiError, messages } from '../lib/errors.js';
import { ok } from '../lib/envelope.js';
import { proofread, toEnglish, type ToolDeps } from '../services/tools.js';
import type { LlmSpend } from './context.js';

const Body = z.object({ text: z.string().trim().min(1).max(2000) });

export const toolRoutes: FastifyPluginAsync<{ deps: ToolDeps; spend: LlmSpend; gate?: AiGate }> = async (
  app,
  { deps, spend, gate = openGate },
) => {
  /** POST /v1/english — Hindi in, English out, with other ways to say it. */
  app.post('/english', async (request, reply) => {
    const parsed = Body.safeParse(request.body);
    if (!parsed.success) throw new ApiError('BAD_REQUEST', messages.badRequest);
    await gate(request, reply);
    const out = await toEnglish({ ...deps, spend: () => spend(request) }, parsed.data.text);
    if (out.cache === 'hit') cacheStats.hits++;
    else cacheStats.misses++;
    request.meta.cache = out.cache;
    request.meta.tokens = out.usage;
    if (out.model) request.meta.model = out.model;
    return ok(out.result);
  });

  /** POST /v1/proofread — the reader's English, put right. */
  app.post('/proofread', async (request, reply) => {
    const parsed = Body.safeParse(request.body);
    if (!parsed.success) throw new ApiError('BAD_REQUEST', messages.badRequest);
    await gate(request, reply);
    const out = await proofread({ ...deps, spend: () => spend(request) }, parsed.data.text);
    if (out.cache === 'hit') cacheStats.hits++;
    else cacheStats.misses++;
    request.meta.cache = out.cache;
    request.meta.tokens = out.usage;
    if (out.model) request.meta.model = out.model;
    return ok(out.result);
  });
};
