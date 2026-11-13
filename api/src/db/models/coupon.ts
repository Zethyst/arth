import { Schema, model, type InferSchemaType } from 'mongoose';

/**
 * A discount code a reader types on the Plans screen. It never sets a price
 * itself — the stores do that. A coupon only names the cheaper offer the
 * stores already hold, and says who may use it:
 *
 *   androidOfferTag  a tag on a Google Play base-plan offer; the app buys the
 *                    SubscriptionOption carrying it.
 *   iosDiscountId    an App Store promotional-offer identifier; the app asks
 *                    RevenueCat to sign it and buys the package with it.
 *
 * `_id` is the code as typed, upper-cased and stripped of spaces, so lookups
 * are a covered primary-key hit and "mayur 20" and "Mayur-20" are the same
 * code.
 */
const couponSchema = new Schema(
  {
    _id: { type: String, required: true },
    tier: { type: String, enum: ['pro', 'super'], required: true },
    /** Restrict to one billing period, or leave null for both. */
    period: { type: String, enum: ['monthly', 'yearly'], default: null },
    androidOfferTag: { type: String, default: '' },
    iosDiscountId: { type: String, default: '' },
    /** Shown to the reader once the code is accepted, in both languages. */
    label: { type: String, default: '' },
    labelHi: { type: String, default: '' },
    /** null = unlimited. Counted on claim (after a purchase), not on check. */
    maxRedemptions: { type: Number, default: null },
    redeemed: { type: Number, default: 0 },
    /** Readers who may use it at all; empty = anyone with the code. */
    uids: { type: [String], default: [] },
    expiresAt: { type: Number, default: null },
    active: { type: Boolean, default: true },
    /** Why this code exists — for whoever reads the collection later. */
    note: { type: String, default: '' },
    createdAt: { type: Number, required: true },
    updatedAt: { type: Number, required: true },
  },
  { versionKey: false, collection: 'coupons' },
);

export type CouponDoc = InferSchemaType<typeof couponSchema>;
export const CouponModel = model('Coupon', couponSchema);

/**
 * One reader's use of one code. `_id` is `code:uid`, so a second claim for the
 * same pair is an upsert that changes nothing and the count stays honest even
 * if the app retries.
 */
const couponRedemptionSchema = new Schema(
  {
    _id: { type: String, required: true },
    code: { type: String, required: true },
    uid: { type: String, required: true },
    at: { type: Number, required: true },
  },
  { versionKey: false, collection: 'couponRedemptions' },
);
couponRedemptionSchema.index({ code: 1 });
couponRedemptionSchema.index({ uid: 1 });

export type CouponRedemptionDoc = InferSchemaType<typeof couponRedemptionSchema>;
export const CouponRedemptionModel = model('CouponRedemption', couponRedemptionSchema);
