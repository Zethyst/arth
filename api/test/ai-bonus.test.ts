// Rewarded ads, paid for in AI answers: what one ad buys, what the day's cap
// refuses, and that an earned answer gets past both the account's limit and
// the phone's.

import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import { buildApp } from '../src/app.js';
import { ApiError } from '../src/lib/errors.js';
import { memoryAccountStore } from '../src/services/accounts.js';
import { adsLeftToday, allowanceOf, dayOf, usageOf } from '../src/services/quota.js';
import type { TokenVerifier } from '../src/auth/verifier.js';
import { appOptions, FakeLLM } from './fakes.js';

const verifier: TokenVerifier = {
  async verify(token) {
    if (!token.startsWith('t:')) throw new ApiError('UNAUTHORIZED', 'bad token');
    return { uid: token.slice(2) };
  },
};
const as = (uid: string) => ({ authorization: `Bearer t:${uid}`, 'x-device-id': `phone-${uid}` });

const PP = 'It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.';
const answer = (i: number) => JSON.stringify({ senseIndex: 0, meaning: 'अविवाहित', note: `नोट ${i}` });

/** Free: 1 use, one ad buys 2 more, two ads a day. */
function setup(llm: FakeLLM) {
  const store = memoryAccountStore();
  const app = buildApp({
    ...appOptions(llm),
    accounts: { store, verifier, cloudinary: null },
    enforceQuota: true,
    limits: { free: 1, proMonthly: 3, adBonus: 2, adBonusPerDay: 2 },
  });
  return { app, store };
}

const context = (uid: string, sentence: string) => ({
  method: 'POST' as const,
  url: '/v1/context',
  headers: as(uid),
  payload: { word: 'single', sentence },
});

const watchAd = (uid: string) => ({ method: 'POST' as const, url: '/v1/me/ai-bonus', headers: as(uid) });

describe('earning AI answers with a rewarded ad', () => {
  test('one ad raises the allowance, and the earned answer is served', async () => {
    const llm = new FakeLLM({ context_result: [answer(1), answer(2)] });
    const { app } = setup(llm);

    // The one free answer, then the wall.
    assert.equal((await app.inject(context('ana', `${PP} 1`))).statusCode, 200);
    assert.equal((await app.inject(context('ana', `${PP} 2`))).statusCode, 402);

    const earned = await app.inject(watchAd('ana'));
    assert.equal(earned.statusCode, 200);
    const body = earned.json().data as { granted: number; usage: { used: number; limit: number; bonus?: number }; adsLeftToday: number };
    assert.equal(body.granted, 2);
    assert.equal(body.usage.limit, 3, '1 free + 2 earned');
    assert.equal(body.usage.used, 1);
    assert.equal(body.usage.bonus, 2);
    assert.equal(body.adsLeftToday, 1);

    // And the answer the reader came back for.
    const after = await app.inject(context('ana', `${PP} 2`));
    assert.equal(after.statusCode, 200);
    assert.equal(after.headers['x-ai-limit'], '3');
    assert.equal(after.headers['x-ai-used'], '2');
    await app.close();
  });

  test('the day has a cap, and a spent day is said so rather than failed', async () => {
    const { app } = setup(new FakeLLM({}));
    for (const expected of [2, 2]) {
      const r = await app.inject(watchAd('bina'));
      assert.equal((r.json().data as { granted: number }).granted, expected);
    }
    const third = await app.inject(watchAd('bina'));
    assert.equal(third.statusCode, 200, 'never an error: the ad was watched');
    const body = third.json().data as { granted: number; usage: { limit: number }; adsLeftToday: number };
    assert.equal(body.granted, 0);
    assert.equal(body.adsLeftToday, 0);
    assert.equal(body.usage.limit, 5, 'two ads only: 1 free + 2 + 2');
    await app.close();
  });

  test('a new day starts the ads again, without giving back the uses', async () => {
    const store = memoryAccountStore();
    await store.insertUser({
      uid: 'chandra',
      displayName: '',
      email: null,
      phone: null,
      photoUrl: null,
      bio: '',
      role: 'user',
      tier: 'free',
      grantTier: 'free',
      storeTier: 'free',
      aiTotal: 0,
      aiMonth: null,
      aiMonthUses: 0,
      aiBonus: 0,
      aiBonusDay: null,
      aiBonusDayCount: 0,
      reviewReminders: true,
      lastReviewNudgeAt: null,
      lowAiNoticeFor: null,
      banned: false,
      createdAt: 0,
      updatedAt: 0,
    });
    const limits = { free: 1, proMonthly: 3, adBonus: 2, adBonusPerDay: 2 };
    const monday = Date.UTC(2026, 10, 23, 9);
    const tuesday = Date.UTC(2026, 10, 24, 9);

    assert.ok(await store.grantAiBonus('chandra', dayOf(monday), 2, 2));
    assert.ok(await store.grantAiBonus('chandra', dayOf(monday), 2, 2));
    assert.equal(await store.grantAiBonus('chandra', dayOf(monday), 2, 2), null, "Monday's ads are spent");

    const mon = (await store.findUser('chandra'))!;
    assert.equal(adsLeftToday(mon, limits, monday), 0);
    assert.equal(adsLeftToday(mon, limits, tuesday), 2, 'a new day, two more ads');
    assert.equal(usageOf(mon, limits, tuesday).limit, 5, 'the uses earned on Monday stay');

    const tue = (await store.grantAiBonus('chandra', dayOf(tuesday), 2, 2))!;
    assert.deepEqual(allowanceOf(tue, limits), { period: 'lifetime', max: 7 });
  });

  test('turned off: no offer, and nothing to claim', async () => {
    const store = memoryAccountStore();
    const app = buildApp({
      ...appOptions(new FakeLLM({})),
      accounts: { store, verifier, cloudinary: null },
      enforceQuota: true,
      limits: { free: 1, proMonthly: 3, adBonus: 0, adBonusPerDay: 0 },
    });
    const me = await app.inject({ method: 'GET', url: '/v1/me', headers: as('dev') });
    assert.deepEqual((me.json().data as { adBonus: number; adsLeftToday: number }).adsLeftToday, 0);
    const claimed = await app.inject(watchAd('dev'));
    assert.equal((claimed.json().data as { granted: number; usage: { limit: number } }).granted, 0);
    assert.equal((claimed.json().data as { usage: { limit: number } }).usage.limit, 1);
    await app.close();
  });

  test('earned uses are not leaked onto the profile', async () => {
    const { app } = setup(new FakeLLM({}));
    await app.inject(watchAd('esha'));
    const me = (await app.inject({ method: 'GET', url: '/v1/me', headers: as('esha') })).json().data as Record<string, unknown>;
    for (const field of ['aiBonus', 'aiBonusDay', 'aiBonusDayCount', 'aiTotal']) {
      assert.equal(field in me, false, `${field} is bookkeeping, not profile`);
    }
    assert.equal((me.usage as { limit: number }).limit, 3);
    assert.equal(me.adsLeftToday, 1);
    assert.equal(me.adBonus, 2);
    await app.close();
  });
});
