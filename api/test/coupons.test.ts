import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { buildApp } from '../src/app.js';
import { ApiError } from '../src/lib/errors.js';
import { memoryAccountStore } from '../src/services/accounts.js';
import {
  checkCoupon,
  claimCoupon,
  memoryCouponStore,
  normalizeCode,
  refusalFor,
  type Coupon,
} from '../src/services/coupons.js';
import type { TokenVerifier } from '../src/auth/verifier.js';
import { appOptions, FakeLLM } from './fakes.js';

const verifier: TokenVerifier = {
  async verify(token) {
    if (!token.startsWith('t:')) throw new ApiError('UNAUTHORIZED', 'bad token');
    return { uid: token.slice(2) };
  },
};
const as = (uid: string) => ({ authorization: `Bearer t:${uid}` });

const coupon = (over: Partial<Coupon> = {}): Coupon => ({
  code: 'MAYUR40',
  tier: 'pro',
  period: 'yearly',
  androidOfferTag: 'pro_yearly_40off',
  iosDiscountId: 'pro_yearly_40off',
  label: '40% off the first year',
  labelHi: 'पहले साल 40% छूट',
  maxRedemptions: null,
  redeemed: 0,
  uids: [],
  expiresAt: null,
  active: true,
  note: '',
  ...over,
});

describe('normalizeCode', () => {
  test('a code typed off a chat message still matches', () => {
    assert.equal(normalizeCode('mayur 40'), 'MAYUR40');
    assert.equal(normalizeCode(' Mayur-40 '), 'MAYUR40');
    assert.equal(normalizeCode('MAYUR40'), 'MAYUR40');
  });
  test('punctuation only is no code at all', () => {
    assert.equal(normalizeCode('--'), '');
  });
});

describe('refusalFor', () => {
  const now = 1_000_000;
  test('a plain live coupon is usable', () => {
    assert.equal(refusalFor(coupon(), 'ana', now), null);
  });
  test('switched off, past its end, or spent', () => {
    assert.equal(refusalFor(coupon({ active: false }), 'ana', now), 'inactive');
    assert.equal(refusalFor(coupon({ expiresAt: now - 1 }), 'ana', now), 'expired');
    assert.equal(refusalFor(coupon({ expiresAt: now }), 'ana', now), 'expired');
    assert.equal(refusalFor(coupon({ maxRedemptions: 2, redeemed: 2 }), 'ana', now), 'used-up');
  });
  test('still live on its last use and up to its end', () => {
    assert.equal(refusalFor(coupon({ maxRedemptions: 2, redeemed: 1 }), 'ana', now), null);
    assert.equal(refusalFor(coupon({ expiresAt: now + 1 }), 'ana', now), null);
  });
  test('a code locked to one reader refuses everyone else', () => {
    assert.equal(refusalFor(coupon({ uids: ['mayur'] }), 'ana', now), 'not-yours');
    assert.equal(refusalFor(coupon({ uids: ['mayur'] }), 'mayur', now), null);
  });
});

describe('checkCoupon', () => {
  test('spends nothing: checking twice still leaves the code unused', async () => {
    const store = memoryCouponStore([coupon({ maxRedemptions: 1 })]);
    assert.equal((await checkCoupon(store, 'mayur 40', 'ana')).ok, true);
    assert.equal((await checkCoupon(store, 'MAYUR40', 'ana')).ok, true);
    assert.equal(store.coupons.get('MAYUR40')!.redeemed, 0);
  });
  test('an unknown code is refused without saying more', async () => {
    const r = await checkCoupon(memoryCouponStore([coupon()]), 'NOPE', 'ana');
    assert.deepEqual(r, { ok: false, reason: 'unknown' });
  });
  test('a reader who already claimed it cannot use it again', async () => {
    const store = memoryCouponStore([coupon()]);
    await claimCoupon(store, 'MAYUR40', 'ana');
    assert.deepEqual(await checkCoupon(store, 'MAYUR40', 'ana'), { ok: false, reason: 'already-used' });
    assert.equal((await checkCoupon(store, 'MAYUR40', 'bob')).ok, true);
  });
});

describe('claimCoupon', () => {
  test('counts once however often the app retries', async () => {
    const store = memoryCouponStore([coupon()]);
    assert.equal((await claimCoupon(store, 'MAYUR40', 'ana')).ok, true);
    assert.equal((await claimCoupon(store, 'MAYUR40', 'ana')).ok, true);
    assert.equal(store.coupons.get('MAYUR40')!.redeemed, 1);
  });
  test('a purchase already made is recorded even past the end date', async () => {
    const store = memoryCouponStore([coupon({ expiresAt: 1 })]);
    assert.equal((await claimCoupon(store, 'MAYUR40', 'ana')).ok, true);
    assert.equal(store.coupons.get('MAYUR40')!.redeemed, 1);
  });
  test("but never for someone the code was not for", async () => {
    const store = memoryCouponStore([coupon({ uids: ['mayur'] })]);
    assert.deepEqual(await claimCoupon(store, 'MAYUR40', 'ana'), { ok: false, reason: 'not-yours' });
    assert.equal(store.coupons.get('MAYUR40')!.redeemed, 0);
  });
});

describe('POST /v1/coupons', () => {
  function setup(seed: Coupon[]) {
    const coupons = memoryCouponStore(seed);
    const app = buildApp({
      ...appOptions(new FakeLLM({})),
      accounts: { store: memoryAccountStore(), verifier, cloudinary: null },
      coupons,
    });
    return { app, coupons };
  }

  test('check returns the offer the app needs to buy at', async () => {
    const { app } = setup([coupon()]);
    const res = await app.inject({ method: 'POST', url: '/v1/coupons/check', headers: as('ana'), payload: { code: 'mayur 40' } });
    assert.equal(res.statusCode, 200);
    assert.deepEqual(res.json().data, {
      code: 'MAYUR40',
      tier: 'pro',
      period: 'yearly',
      androidOfferTag: 'pro_yearly_40off',
      iosDiscountId: 'pro_yearly_40off',
      label: '40% off the first year',
      labelHi: 'पहले साल 40% छूट',
    });
    await app.close();
  });

  test('a bad code is a 404 carrying the reason', async () => {
    const { app } = setup([coupon({ active: false })]);
    const res = await app.inject({ method: 'POST', url: '/v1/coupons/check', headers: as('ana'), payload: { code: 'MAYUR40' } });
    assert.equal(res.statusCode, 404);
    assert.equal(res.json().error.reason, 'inactive');
    await app.close();
  });

  test('signed out, a code is worth nothing', async () => {
    const { app } = setup([coupon()]);
    const res = await app.inject({ method: 'POST', url: '/v1/coupons/check', payload: { code: 'MAYUR40' } });
    assert.equal(res.statusCode, 401);
    await app.close();
  });

  test('claim records the purchase, and only then is the code spent', async () => {
    const { app, coupons } = setup([coupon({ maxRedemptions: 1 })]);
    await app.inject({ method: 'POST', url: '/v1/coupons/check', headers: as('ana'), payload: { code: 'MAYUR40' } });
    assert.equal(coupons.coupons.get('MAYUR40')!.redeemed, 0);
    const res = await app.inject({ method: 'POST', url: '/v1/coupons/claim', headers: as('ana'), payload: { code: 'MAYUR40' } });
    assert.equal(res.statusCode, 200);
    assert.equal(coupons.coupons.get('MAYUR40')!.redeemed, 1);
    const after = await app.inject({ method: 'POST', url: '/v1/coupons/check', headers: as('bob'), payload: { code: 'MAYUR40' } });
    assert.equal(after.json().error.reason, 'used-up');
    await app.close();
  });
});
