import type { FastifyReply, FastifyRequest } from 'fastify';
import { ApiError, messages } from '../lib/errors.js';
import { authenticate, type AccountDeps } from '../routes/account.js';
import { allowanceOf, hasRemaining, monthOf, usageOf, type Limits, type Usage } from '../services/quota.js';
import { maybeWarnLowAi } from '../push/notify.js';
import { deviceIdOf, withPhone } from './device.js';

/** A counted AI use; give it back if no AI answer was served. */
export type AiUse = { refund(): Promise<void> };

/**
 * Admits an AI request, or throws: UNAUTHORIZED when signed out,
 * QUOTA_EXCEEDED (with the usage) when the allowance is spent. Background
 * prefetch is admitted only while there's allowance left and is never
 * counted — the reader's tap on that word is what counts.
 *
 * `count: false` admits the same way without spending. It is for the request
 * that continues work already paid for: every turn after the first in one
 * coaching conversation is the same conversation, and charging each of them
 * made a twenty-minute roleplay cost a third of a Free reader's lifetime.
 * Allowance is still required — an empty account cannot carry on talking.
 *
 * Null when nothing was counted: prefetch, `count: false`, or accounts off
 * (no Firebase project configured: AI stays open, as before accounts existed).
 */
export type AiGate = (req: FastifyRequest, reply: FastifyReply, opts?: { count?: boolean }) => Promise<AiUse | null>;

export const openGate: AiGate = async () => null;

/**
 * Runs the work and settles the reader's AI use against what it actually
 * cost: refunded when it throws, and refunded when the answer came out of the
 * cache, because a cached answer cost nothing to produce.
 *
 * The gate still runs first. Admission is about who is asking; this is about
 * what the asking cost. /context and /translate have always done this by
 * hand; /english, /proofread, /grammar, /summary and /coach threw the use
 * away and so could never give it back — a failed call or a second look at a
 * paragraph already proofread was charged in full.
 */
export async function settle<T extends { cache: 'hit' | 'miss' }>(
  use: AiUse | null,
  work: () => Promise<T>,
): Promise<T> {
  let out: T;
  try {
    out = await work();
  } catch (err) {
    await use?.refund();
    throw err;
  }
  if (out.cache === 'hit') await use?.refund();
  return out;
}

export function aiGate(deps: AccountDeps, limits: Limits): AiGate {
  const maxAccounts = limits.freeAccountsPerDevice ?? 3;
  return async (req, reply, opts) => {
    const user = await authenticate(req, deps);
    const now = Date.now();
    const exceeded = (usage: Usage, extra: object = {}) => new ApiError('QUOTA_EXCEEDED', messages.quotaExceeded, { usage, ...extra });
    // The Free allowance is also per phone, so a new email doesn't reset it.
    // Uses earned from rewarded ads are in here, so they lift both caps —
    // an earned answer the phone's cap then refused would be a cheat.
    const allowance = allowanceOf(user, limits);
    const perPhone = allowance.period === 'lifetime' && user.role !== 'admin';
    const device = deviceIdOf(req);
    if (perPhone && device === null) throw new ApiError('BAD_REQUEST', messages.deviceRequired);

    if (req.headers['x-prefetch'] === '1' || opts?.count === false) {
      const phoneUsed = perPhone ? await deps.store.deviceAiUsed(device!) : 0;
      if (!hasRemaining(user, limits, now) || (perPhone && phoneUsed >= allowance.max)) {
        throw exceeded(withPhone(usageOf(user, limits, now), phoneUsed));
      }
      return null;
    }
    const month = monthOf(now);
    const counted = await deps.store.consumeAi(user.uid, month, allowance);
    if (!counted) throw exceeded(usageOf(user, limits, now));
    let usage = usageOf(counted, limits, now);
    if (perPhone) {
      const phone = await deps.store.consumeDeviceAi(device!, user.uid, allowance.max, maxAccounts);
      if (!phone.ok) {
        await deps.store.refundAi(user.uid, month);
        const shown = withPhone(usageOf(user, limits, now), phone.used);
        if (phone.reason === 'accounts') {
          throw new ApiError('QUOTA_EXCEEDED', messages.quotaPhoneAccounts, { usage: { ...shown, used: shown.limit ?? shown.used, phone: true }, reason: 'phone_accounts' });
        }
        throw exceeded(shown, { reason: 'phone' });
      }
      usage = withPhone(usage, phone.used);
    }
    // Off the request's path: a slow push never delays an answer.
    if (deps.pusher?.enabled) {
      void maybeWarnLowAi(deps.store, deps.pusher, counted, limits, now).catch((err: unknown) => req.log.warn({ err }, 'low-AI push failed'));
    }
    // The app keeps its "N left" current from these, without polling /me.
    reply.header('x-ai-used', String(usage.used));
    reply.header('x-ai-limit', usage.limit === null ? 'none' : String(usage.limit));
    reply.header('x-ai-period', usage.period);
    let refunded = false;
    return {
      async refund() {
        if (refunded) return;
        refunded = true;
        // The header went out counting this use; keep the app's "N left" true.
        if (!reply.raw.headersSent && usage.limit !== null) reply.header('x-ai-used', String(Math.max(0, usage.used - 1)));
        await deps.store.refundAi(user.uid, month);
        if (perPhone) await deps.store.refundDeviceAi(device!);
      },
    };
  };
}
