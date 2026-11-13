/**
 * Discount codes.
 *
 * A coupon never names a price. Google Play and the App Store own prices, and
 * a server that handed out its own would be selling outside the store. What a
 * coupon does is point at a cheaper offer the stores already hold — a Play
 * base-plan offer tag, an App Store promotional-offer id — and decide who is
 * allowed to buy at it.
 *
 * So redeeming is two steps, and the split matters:
 *
 *   check  the reader types a code. We say yes or no and hand back the offer
 *          to show. Nothing is spent: a reader who types a code and then
 *          changes their mind has not used it up.
 *   claim  the store says the purchase went through. Only now does the
 *          redemption count, keyed by code and uid so a retry is free.
 */
import type { Tier } from './accounts.js';

export type CouponPeriod = 'monthly' | 'yearly';

export type Coupon = {
  code: string;
  tier: Exclude<Tier, 'free'>;
  /** Only this billing period, or null for both. */
  period: CouponPeriod | null;
  androidOfferTag: string;
  iosDiscountId: string;
  label: string;
  labelHi: string;
  maxRedemptions: number | null;
  redeemed: number;
  /** Readers who may use it; empty means anyone who has the code. */
  uids: string[];
  expiresAt: number | null;
  active: boolean;
  note: string;
};

/** What the app needs to show the code and buy at it. */
export type CouponOffer = {
  code: string;
  tier: Exclude<Tier, 'free'>;
  period: CouponPeriod | null;
  androidOfferTag: string;
  iosDiscountId: string;
  label: string;
  labelHi: string;
};

export type CouponRefusal = 'unknown' | 'inactive' | 'expired' | 'used-up' | 'not-yours' | 'already-used';
export type CouponCheck = { ok: true; offer: CouponOffer } | { ok: false; reason: CouponRefusal };

export interface CouponStore {
  findCoupon(code: string): Promise<Coupon | null>;
  hasRedeemed(code: string, uid: string): Promise<boolean>;
  /** Records the redemption and returns true the first time only. */
  redeem(code: string, uid: string, at: number): Promise<boolean>;
}

/**
 * The code as stored: upper case, and only letters and digits, so "mayur 20",
 * "Mayur-20" and "MAYUR20" are one code. Typing a coupon off a WhatsApp
 * message should not fail on a space.
 */
export function normalizeCode(raw: string): string {
  return raw.toUpperCase().replace(/[^A-Z0-9]/g, '');
}

export function offerOf(c: Coupon): CouponOffer {
  return {
    code: c.code,
    tier: c.tier,
    period: c.period,
    androidOfferTag: c.androidOfferTag,
    iosDiscountId: c.iosDiscountId,
    label: c.label,
    labelHi: c.labelHi,
  };
}

/** Why a coupon cannot be used right now, or null when it can. */
export function refusalFor(c: Coupon, uid: string, now: number): CouponRefusal | null {
  if (!c.active) return 'inactive';
  if (c.expiresAt !== null && c.expiresAt <= now) return 'expired';
  if (c.maxRedemptions !== null && c.redeemed >= c.maxRedemptions) return 'used-up';
  if (c.uids.length > 0 && !c.uids.includes(uid)) return 'not-yours';
  return null;
}

/** Step one: is this code good for this reader? Spends nothing. */
export async function checkCoupon(store: CouponStore, raw: string, uid: string, now = Date.now()): Promise<CouponCheck> {
  const code = normalizeCode(raw);
  if (!code) return { ok: false, reason: 'unknown' };
  const coupon = await store.findCoupon(code);
  if (!coupon) return { ok: false, reason: 'unknown' };
  const refusal = refusalFor(coupon, uid, now);
  if (refusal) return { ok: false, reason: refusal };
  if (await store.hasRedeemed(code, uid)) return { ok: false, reason: 'already-used' };
  return { ok: true, offer: offerOf(coupon) };
}

/**
 * Step two, after the store has taken the money: count it. Re-running this
 * for a purchase already claimed is a no-op, not a second redemption.
 */
export async function claimCoupon(store: CouponStore, raw: string, uid: string, now = Date.now()): Promise<CouponCheck> {
  const code = normalizeCode(raw);
  if (!code) return { ok: false, reason: 'unknown' };
  const coupon = await store.findCoupon(code);
  if (!coupon) return { ok: false, reason: 'unknown' };
  // Deliberately lenient about expiry and the cap here: the reader has
  // already paid at the discounted price, and refusing to record that would
  // only lose us the record. Ownership still holds.
  if (coupon.uids.length > 0 && !coupon.uids.includes(uid)) return { ok: false, reason: 'not-yours' };
  await store.redeem(code, uid, now);
  return { ok: true, offer: offerOf(coupon) };
}

/** For tests and for a server with no Mongo: codes held in a Map. */
export function memoryCouponStore(seed: Coupon[] = []): CouponStore & { coupons: Map<string, Coupon> } {
  const coupons = new Map(seed.map((c) => [normalizeCode(c.code), { ...c, code: normalizeCode(c.code) }]));
  const claims = new Set<string>();
  return {
    coupons,
    async findCoupon(code) {
      return coupons.get(code) ?? null;
    },
    async hasRedeemed(code, uid) {
      return claims.has(`${code}:${uid}`);
    },
    async redeem(code, uid) {
      const key = `${code}:${uid}`;
      if (claims.has(key)) return false;
      claims.add(key);
      const c = coupons.get(code);
      if (c) c.redeemed += 1;
      return true;
    },
  };
}
