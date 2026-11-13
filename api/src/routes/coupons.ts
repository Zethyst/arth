/**
 * POST /v1/coupons/check  { code }  — is this code good for me, and what
 *                                     offer does it unlock? Spends nothing.
 * POST /v1/coupons/claim  { code }  — the store took the money; count it.
 *
 * Both need sign-in: a coupon belongs to a reader, not to a phone. Neither
 * route sets a price — see services/coupons.ts for why.
 */
import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { ok } from '../lib/envelope.js';
import { ApiError } from '../lib/errors.js';
import { authenticate, type AccountDeps } from './account.js';
import { checkCoupon, claimCoupon, type CouponRefusal, type CouponStore } from '../services/coupons.js';

export type CouponDeps = AccountDeps & { coupons: CouponStore };

const Body = z.object({ code: z.string().trim().min(1).max(40) });

/** Hindi, shown verbatim: the reader sees exactly why a code did not work. */
const refusalMessage: Record<CouponRefusal, string> = {
  unknown: 'यह कोड सही नहीं है।',
  inactive: 'यह कोड अब चालू नहीं है।',
  expired: 'इस कोड की अवधि खत्म हो चुकी है।',
  'used-up': 'यह कोड पूरा इस्तेमाल हो चुका है।',
  'not-yours': 'यह कोड इस खाते के लिए नहीं है।',
  'already-used': 'आप यह कोड पहले इस्तेमाल कर चुके हैं।',
};

export const couponRoutes: FastifyPluginAsync<CouponDeps> = async (app, deps) => {
  app.post('/coupons/check', async (req) => {
    const user = await authenticate(req, deps);
    const parsed = Body.safeParse(req.body);
    if (!parsed.success) throw new ApiError('BAD_REQUEST', refusalMessage.unknown);
    const result = await checkCoupon(deps.coupons, parsed.data.code, user.uid);
    if (!result.ok) throw new ApiError('NOT_FOUND', refusalMessage[result.reason], { reason: result.reason });
    req.log.info({ uid: user.uid, code: result.offer.code }, 'coupon accepted');
    return ok(result.offer);
  });

  app.post('/coupons/claim', async (req) => {
    const user = await authenticate(req, deps);
    const parsed = Body.safeParse(req.body);
    if (!parsed.success) throw new ApiError('BAD_REQUEST', refusalMessage.unknown);
    const result = await claimCoupon(deps.coupons, parsed.data.code, user.uid);
    if (!result.ok) throw new ApiError('NOT_FOUND', refusalMessage[result.reason], { reason: result.reason });
    req.log.info({ uid: user.uid, code: result.offer.code }, 'coupon claimed');
    return ok(result.offer);
  });
};
