import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { openGate, type AiGate } from '../auth/ai-gate.js';
import { cacheStats } from '../cache/cache.js';
import { ApiError, messages } from '../lib/errors.js';
import { ok } from '../lib/envelope.js';
import { coachReply, isScenario, SCENARIOS, type CoachDeps } from '../services/coach.js';
import type { LlmSpend } from './context.js';

const Body = z.object({
  scenario: z.string().trim().min(1).max(32),
  /**
   * What has been said so far. Bounded: a conversation long enough to exceed
   * this has had its practice, and the prompt grows with every turn.
   */
  turns: z
    .array(
      z.object({
        role: z.enum(['coach', 'learner']),
        text: z.string().trim().min(1).max(600),
      }),
    )
    .max(40)
    .default([]),
  /** The learner's latest sentence; empty only for the scene's opening. */
  said: z.string().trim().max(600).default(''),
});

export const coachRoutes: FastifyPluginAsync<{ deps: CoachDeps; spend: LlmSpend; gate?: AiGate }> = async (
  app,
  { deps, spend, gate = openGate },
) => {
  /** The scenes on offer. No model, no account — the app needs it to draw the list. */
  app.get('/coach/scenarios', async () => ok({ scenarios: Object.keys(SCENARIOS) }));

  /** POST /v1/coach — the coach's next turn, and a correction if one is due. */
  app.post('/coach', async (request, reply) => {
    const parsed = Body.safeParse(request.body);
    if (!parsed.success || !isScenario(parsed.data.scenario)) {
      throw new ApiError('BAD_REQUEST', messages.badRequest);
    }
    await gate(request, reply);
    const out = await coachReply(
      { ...deps, spend: () => spend(request) },
      parsed.data.scenario,
      parsed.data.turns,
      parsed.data.said,
    );
    if (out.cache === 'hit') cacheStats.hits++;
    else cacheStats.misses++;
    request.meta.cache = out.cache;
    request.meta.tokens = out.usage;
    if (out.model) request.meta.model = out.model;
    return ok(out.result);
  });
};
