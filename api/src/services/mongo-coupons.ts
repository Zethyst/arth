import { CouponModel, CouponRedemptionModel } from '../db/models/index.js';
import type { Coupon, CouponStore } from './coupons.js';

function toCoupon(doc: Record<string, unknown>): Coupon {
  return {
    code: doc._id as string,
    tier: doc.tier as Coupon['tier'],
    period: (doc.period as Coupon['period'] | undefined) ?? null,
    androidOfferTag: (doc.androidOfferTag as string) ?? '',
    iosDiscountId: (doc.iosDiscountId as string) ?? '',
    label: (doc.label as string) ?? '',
    labelHi: (doc.labelHi as string) ?? '',
    maxRedemptions: (doc.maxRedemptions as number | null) ?? null,
    redeemed: (doc.redeemed as number) ?? 0,
    uids: (doc.uids as string[] | undefined) ?? [],
    expiresAt: (doc.expiresAt as number | null) ?? null,
    active: (doc.active as boolean | undefined) ?? true,
    note: (doc.note as string) ?? '',
  };
}

export const mongoCouponStore: CouponStore = {
  async findCoupon(code) {
    const doc = await CouponModel.findById(code).lean();
    return doc ? toCoupon(doc) : null;
  },
  async hasRedeemed(code, uid) {
    return (await CouponRedemptionModel.exists({ _id: `${code}:${uid}` })) !== null;
  },
  /**
   * The insert is the lock: `_id` is `code:uid`, so a duplicate key means
   * this reader already claimed this code and the counter must not move
   * again, however many times the app retries.
   */
  async redeem(code, uid, at) {
    try {
      await CouponRedemptionModel.create({ _id: `${code}:${uid}`, code, uid, at });
    } catch (err) {
      if ((err as { code?: number }).code === 11000) return false;
      throw err;
    }
    await CouponModel.updateOne({ _id: code }, { $inc: { redeemed: 1 }, $set: { updatedAt: at } });
    return true;
  },
};
