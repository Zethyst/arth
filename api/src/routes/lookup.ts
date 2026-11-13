import { createHash } from 'node:crypto';
import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { ApiError, messages } from '../lib/errors.js';
import { ok } from '../lib/envelope.js';
import { schemas } from '../contracts.js';
import { resolveLemma, resolveLemmaKey } from '../services/lemma.js';
import { generateOnDemand, generateUnknown, isCoinable, morphologySuggestions, type OnDemandDeps } from '../services/ondemand.js';
import type { Store } from '../services/mongo-store.js';
import { cacheStats, type CacheStore } from '../cache/cache.js';
import { openGate, type AiGate } from '../auth/ai-gate.js';

const Query = z.object({
  word: z.string().trim().min(1).max(64),
});

export type LookupOptions = {
  store: Store;
  /** Absent in tests that don't exercise generation. */
  ondemand?: Omit<OnDemandDeps, 'staging' | 'spend'> & {
    spend: (request: { headers: Record<string, unknown>; ip: string }) => void;
  };
  /** Generating an entry is an AI use; looking up an existing one isn't. */
  gate?: AiGate;
  /** Remembers the words the model declined, so a second tap is free. */
  cache?: CacheStore;
};

/**
 * A word the model said it does not know. Kept for ever, like every other
 * cache entry: the verdict is about the word, not about the day. Load the
 * word properly through the pipeline and the entry wins — this is only
 * consulted after `entries` and `staged` have both missed.
 */
const declinedKey = (word: string) => createHash('sha256').update(`unknown:${word}`, 'utf8').digest('hex');

export const lookupRoutes: FastifyPluginAsync<LookupOptions> = async (app, { store, ondemand, gate = openGate, cache }) => {
  app.get(
    '/lookup',
    {
      schema: {
        response: {
          200: {
            type: 'object',
            required: ['ok', 'data'],
            properties: { ok: { const: true }, data: { $ref: schemas.dictionaryEntry['$id'] as string } },
          },
        },
      },
    },
    async (request, reply) => {
      const parsed = Query.safeParse(request.query);
      if (!parsed.success) throw new ApiError('BAD_REQUEST', messages.badRequest);

      const { word } = parsed.data;
      const resolved = await resolveLemma(store, word);
      if (resolved) {
        request.meta.lookup = { word, lemma: resolved.lemma, via: resolved.via };
        return ok(resolved.entry);
      }

      const key = word.toLowerCase();

      // Not generated yet. A staged Wiktionary lemma gets its Hindi layer now;
      // a word-shaped token nothing has staged — the compounds, the derived
      // words, the Indian English — gets written from scratch, which is the
      // only answer a reader of `decision-making` was ever going to get.
      if (ondemand) {
        const stagedLemma = await resolveLemmaKey(
          async (k) => (await store.findStaged(k)) !== null,
          (f) => store.findFormLemma(f),
          word,
        );
        // A token the model has already turned down is not worth asking
        // about a second time, for us or for the reader's allowance.
        const coinable = stagedLemma === null && isCoinable(key);
        const declined = coinable && (await cache?.get<true>(declinedKey(key))) === true;
        if (stagedLemma !== null || (coinable && !declined)) {
          const lemma = stagedLemma ?? key;
          const deps = { ...ondemand, staging: store, spend: () => ondemand.spend(request) };
          const use = await gate(request, reply);
          try {
            const out = stagedLemma !== null ? await generateOnDemand(deps, stagedLemma) : await generateUnknown(deps, key);
            if (out?.entry) {
              cacheStats.misses++;
              request.meta.lookup = { word, lemma: out.entry.word, via: stagedLemma !== null ? 'generated' : 'coined' };
              request.meta.tokens = out.usage;
              request.meta.model = out.model;
              return ok(out.entry);
            }
            // Either the lemma stopped being staged under us, or the model
            // does not know the token. Nothing was served, so nothing is owed.
            await use?.refund();
            if (out && stagedLemma === null) await cache?.set(declinedKey(key), 'unknown', true);
          } catch (err) {
            await use?.refund();
            if (err instanceof ApiError) throw err;
            request.log.error({ err, lemma }, 'ondemand generation failed');
          }
        }
      }

      // Genuinely unknown (or generation failed): offer bases the reader can open.
      const exists = async (c: string) =>
        (await resolveLemma(store, c)) !== null || (await store.findStaged(c)) !== null;
      const suggestions = await morphologySuggestions(key, exists);
      request.meta.lookup = { word, via: 'miss' };
      throw new ApiError('NOT_FOUND', messages.wordNotFound, { suggestions });
    },
  );
};
