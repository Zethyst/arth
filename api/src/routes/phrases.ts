import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { ApiError, messages } from '../lib/errors.js';
import { ok } from '../lib/envelope.js';
import { normalizeWord } from '../normalize.js';
import { matchPhrase, type PhraseStore } from '../services/phrases.js';
import { relatedPhrases, type RelatedPhraseStore } from '../services/related-phrases.js';

const Body = z.object({
  tokens: z.array(z.string().max(64)).min(1).max(32),
  index: z.number().int().min(0),
});

const OfQuery = z.object({ word: z.string().trim().min(1).max(64) });

export const phraseRoutes: FastifyPluginAsync<{ store: PhraseStore & RelatedPhraseStore }> = async (app, { store }) => {
  /** Pure DB, no LLM. Runs before /lookup on every tap. */
  app.post('/phrases/match', async (request) => {
    const parsed = Body.safeParse(request.body);
    if (!parsed.success || parsed.data.index >= parsed.data.tokens.length) {
      throw new ApiError('BAD_REQUEST', messages.badRequest);
    }
    const tokens = parsed.data.tokens.map(normalizeWord);
    const match = await matchPhrase(store, tokens, parsed.data.index);
    request.meta.phrase = match ? match.phrase : 'none';
    return ok(match);
  });

  /**
   * GET /v1/phrases/of?word=get — the idioms and phrasal verbs built on a
   * word, for its dictionary page. Pure DB, no LLM; an empty list is a normal
   * answer, not a 404.
   */
  app.get('/phrases/of', async (request) => {
    const parsed = OfQuery.safeParse(request.query);
    if (!parsed.success) throw new ApiError('BAD_REQUEST', messages.badRequest);
    const lemma = normalizeWord(parsed.data.word);
    const items = await relatedPhrases(store, lemma);
    return ok({ lemma, items });
  });
};
