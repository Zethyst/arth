/**
 * GET /v1/admin/metrics — the admin dashboard. Income comes from AdMob and
 * RevenueCat (faked here at the fetch boundary, with the shapes those APIs
 * document); the reader and community counts come from our own store.
 */
import { test, describe } from 'node:test';
import assert from 'node:assert/strict';
import { buildApp } from '../src/app.js';
import { ApiError } from '../src/lib/errors.js';
import { memoryAccountStore } from '../src/services/accounts.js';
import { memoryCommunityStore } from '../src/services/community.js';
import type { TokenVerifier } from '../src/auth/verifier.js';
import { admobNetwork, disabledAds, disabledPurchaseMetrics, revenueCatMetrics } from '../src/billing/income.js';
import { windowDays } from '../src/lib/days.js';
import { appOptions, FakeLLM } from './fakes.js';

const verifier: TokenVerifier = {
  async verify(token) {
    if (!token.startsWith('t:')) throw new ApiError('UNAUTHORIZED', 'bad');
    const uid = token.slice(2);
    return { uid, name: uid[0]!.toUpperCase() + uid.slice(1) };
  },
};
const as = (uid: string) => ({ authorization: `Bearer t:${uid}` });

/** Fixed "now", so the day keys in the assertions don't move. */
const NOW = Date.UTC(2026, 10, 24, 9, 30);
const DAY = 86_400_000;
const now = () => NOW;

/** A fetch that answers the URLs it knows and records what it was asked. */
function fakeFetch(routes: Array<[RegExp, (url: string, init?: RequestInit) => { status?: number; body: unknown }]>) {
  const calls: string[] = [];
  const impl = (async (input: string | URL | Request, init?: RequestInit) => {
    const url = String(input);
    calls.push(url);
    const match = routes.find(([re]) => re.test(url));
    if (!match) return new Response('not stubbed', { status: 404 });
    const { status = 200, body } = match[1](url, init);
    return new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });
  }) as unknown as typeof fetch;
  return { impl, calls };
}

const oauth: [RegExp, () => { body: unknown }] = [/oauth2\.googleapis\.com/, () => ({ body: { access_token: 'at-1', expires_in: 3600 } })];

/** AdMob streams a header, a row per day, then a footer. */
const admobRows = (rows: Array<[string, number, number, number]>) => [
  { header: { localizationSettings: { currencyCode: 'INR' } } },
  ...rows.map(([day, earnings, impressions, clicks]) => ({
    row: {
      dimensionValues: { DATE: { value: day } },
      metricValues: {
        ESTIMATED_EARNINGS: { microsValue: String(Math.round(earnings * 1_000_000)) },
        IMPRESSIONS: { integerValue: String(impressions) },
        CLICKS: { integerValue: String(clicks) },
      },
    },
  })),
  { footer: {} },
];

async function setup(income: Parameters<typeof buildApp>[0]['income']) {
  const store = memoryAccountStore();
  const community = memoryCommunityStore();
  const app = buildApp({ ...appOptions(new FakeLLM({})), accounts: { store, verifier, cloudinary: null }, community, ...(income ? { income } : {}) });
  for (const uid of ['admin', 'buyer', 'granted', 'free', 'old']) await app.inject({ method: 'GET', url: '/v1/me', headers: as(uid) });
  await store.updateUser('admin', { role: 'admin' });
  // A buyer, a reader an admin put on a plan, a Free reader who has spent some
  // of their allowance, and one who signed in long before this window.
  await store.updateUser('buyer', { tier: 'super', storeTier: 'super', grantTier: 'free', createdAt: NOW - 2 * DAY });
  await store.updateUser('granted', { tier: 'pro', grantTier: 'pro', storeTier: 'free', createdAt: NOW - 2 * DAY });
  await store.updateUser('free', { aiTotal: 12, aiMonth: '2026-11', aiMonthUses: 5, banned: true, createdAt: NOW - DAY });
  await store.updateUser('old', { createdAt: NOW - 200 * DAY });
  await store.addPushDevice('buyer', { token: `tok-buyer-${'x'.repeat(20)}`, platform: 'android', lang: 'en', updatedAt: 0 });
  await store.addPushDevice('free', { token: `tok-free-${'x'.repeat(20)}`, platform: 'ios', lang: 'hi', updatedAt: 0 });
  return { app, store, community };
}

describe('GET /v1/admin/metrics', () => {
  test('income from both networks, and the readers behind it', async () => {
    const window = windowDays(NOW, 7);
    const ads = fakeFetch([
      oauth,
      [
        /networkReport:generate/,
        () => ({
          body: admobRows([
            [window[6]!.replaceAll('-', ''), 6.5, 1000, 12],
            [window[5]!.replaceAll('-', ''), 3.5, 400, 4],
          ]),
        }),
      ],
    ]);
    const purchases = fakeFetch([
      [
        /metrics\/overview/,
        () => ({
          body: {
            object: 'overview_metrics',
            currency: 'INR',
            metrics: [
              { object: 'overview_metric', id: 'mrr', name: 'MRR', description: '', unit: '$', period: 'P0D', value: 450.5, last_updated_at: NOW },
              { object: 'overview_metric', id: 'active_subscriptions', name: 'Active Subscriptions', description: '', unit: '#', period: 'P0D', value: 9 },
              { id: 'broken' },
            ],
          },
        }),
      ],
      [/metrics\/revenue/, () => ({ body: { object: 'revenue_metric', value: 1299.5, currency: 'INR', revenue_type: 'revenue' } })],
    ]);
    const { app } = await setup({
      currency: 'INR',
      ads: admobNetwork({ publisherId: 'pub-1', clientId: 'cid', clientSecret: 'secret', refreshToken: 'rt' }, ads.impl, now),
      purchases: revenueCatMetrics({ projectId: 'proj1', secretKey: 'sk_v2' }, purchases.impl, now),
    });

    const res = await app.inject({ method: 'GET', url: '/v1/admin/metrics?days=7', headers: as('admin') });
    assert.equal(res.statusCode, 200, res.body);
    const d = res.json().data;

    assert.equal(d.days, 7);
    assert.equal(d.currency, 'INR');

    // Ads: the totals, the eCPM derived from them, and one point per day.
    assert.equal(d.ads.state, 'ok');
    assert.equal(d.ads.currency, 'INR');
    assert.equal(d.ads.earnings, 10);
    assert.equal(d.ads.impressions, 1400);
    assert.equal(d.ads.clicks, 16);
    assert.ok(Math.abs(d.ads.ecpm - (10 / 1400) * 1000) < 1e-9);
    assert.equal(d.ads.days.length, 7);
    assert.deepEqual(
      d.ads.days.map((x: { day: string }) => x.day),
      window,
      'oldest day first, UTC',
    );
    assert.deepEqual(d.ads.days.at(-1), { day: window[6], earnings: 6.5, impressions: 1000 });
    assert.deepEqual(d.ads.days[0], { day: window[0], earnings: 0, impressions: 0 }, 'a day with no earnings is a zero, not a gap');
    // The report asked for the window and the currency the dashboard adds up in.
    assert.ok(ads.calls.some((u) => u.includes('accounts/pub-1/networkReport:generate')));

    // Purchases: the window's revenue, and every headline metric as RevenueCat named it.
    assert.equal(d.purchases.state, 'ok');
    assert.equal(d.purchases.revenue, 1299.5);
    assert.deepEqual(d.purchases.metrics, [
      { id: 'mrr', name: 'MRR', value: 450.5, unit: '$', period: 'P0D' },
      { id: 'active_subscriptions', name: 'Active Subscriptions', value: 9, unit: '#', period: 'P0D' },
    ]);
    assert.ok(purchases.calls.some((u) => u.includes(`start_date=${window[0]}&end_date=${window[6]}`)));
    assert.ok(purchases.calls.every((u) => u.includes('currency=INR')));

    // Readers: five signed in, one banned, one paying, one on a granted plan.
    assert.equal(d.readers.total, 5);
    assert.equal(d.readers.paying, 1);
    assert.equal(d.readers.granted, 1);
    assert.equal(d.readers.banned, 1);
    assert.equal(d.readers.admins, 1);
    assert.deepEqual(d.readers.tiers, { free: 3, pro: 1, super: 1 });
    assert.deepEqual(d.readers.devices, { total: 2, android: 1, ios: 1 });
    assert.deepEqual(d.readers.ai, { month: 5, total: 12 });
    assert.equal(d.readers.new7, 4, 'the reader from 200 days ago is not new');
    assert.equal(d.readers.signups.length, 7);
    assert.equal(
      d.readers.signups.reduce((n: number, s: { count: number }) => n + s.count, 0),
      4,
    );
    assert.deepEqual(d.community, { decks: 0, comments: 0, openReports: 0 });
    await app.close();
  });

  test('a network that is off, or failing, costs only its own panel', async () => {
    const purchases = fakeFetch([[/metrics\/overview/, () => ({ status: 403, body: { message: 'no permission' } })]]);
    const { app } = await setup({
      currency: 'INR',
      ads: disabledAds,
      purchases: revenueCatMetrics({ projectId: 'proj1', secretKey: 'sk_v2' }, purchases.impl, now),
    });
    const d = (await app.inject({ method: 'GET', url: '/v1/admin/metrics', headers: as('admin') })).json().data;
    assert.equal(d.days, 30, 'a month by default');
    assert.deepEqual(d.ads, { state: 'off' });
    assert.equal(d.purchases.state, 'error');
    assert.match(d.purchases.reason, /403/);
    assert.equal(d.readers.total, 5, 'our own numbers are there either way');
    await app.close();
  });

  test('revenue the key cannot read leaves the snapshot standing', async () => {
    const purchases = fakeFetch([
      [/metrics\/overview/, () => ({ body: { currency: 'USD', metrics: [{ id: 'active_trials', name: 'Active Trials', value: 3, unit: '$', period: 'P0D' }] } })],
      [/metrics\/revenue/, () => ({ status: 403, body: {} })],
    ]);
    const { app } = await setup({
      currency: 'INR',
      ads: disabledAds,
      purchases: revenueCatMetrics({ projectId: 'proj1', secretKey: 'sk_v2' }, purchases.impl, now),
    });
    const d = (await app.inject({ method: 'GET', url: '/v1/admin/metrics?days=1', headers: as('admin') })).json().data;
    assert.equal(d.purchases.state, 'ok');
    assert.equal(d.purchases.revenue, null);
    assert.equal(d.purchases.currency, 'USD', 'the currency RevenueCat actually answered in');
    assert.equal(d.purchases.metrics.length, 1);
    await app.close();
  });

  test('nothing connected: the panels say so, and 1–90 days is the range', async () => {
    const { app } = await setup(undefined);
    const d = (await app.inject({ method: 'GET', url: '/v1/admin/metrics', headers: as('admin') })).json().data;
    assert.deepEqual(d.ads, { state: 'off' });
    assert.deepEqual(d.purchases, { state: 'off' });
    assert.equal(d.currency, 'INR');
    assert.equal((await app.inject({ method: 'GET', url: '/v1/admin/metrics?days=0', headers: as('admin') })).statusCode, 400);
    assert.equal((await app.inject({ method: 'GET', url: '/v1/admin/metrics?days=91', headers: as('admin') })).statusCode, 400);
    assert.equal((await app.inject({ method: 'GET', url: '/v1/admin/metrics?days=90', headers: as('admin') })).statusCode, 200);
    await app.close();
  });

  test('only an admin sees it', async () => {
    const { app } = await setup({ currency: 'INR', ads: disabledAds, purchases: disabledPurchaseMetrics });
    assert.equal((await app.inject({ method: 'GET', url: '/v1/admin/metrics' })).statusCode, 401);
    assert.equal((await app.inject({ method: 'GET', url: '/v1/admin/metrics', headers: as('buyer') })).statusCode, 403);
    await app.close();
  });

  test('an access token is bought once, not per report', async () => {
    const ads = fakeFetch([oauth, [/networkReport:generate/, () => ({ body: admobRows([]) })]]);
    const network = admobNetwork({ publisherId: 'pub-1', clientId: 'cid', clientSecret: 'secret', refreshToken: 'rt' }, ads.impl, now);
    await network.report(7, 'INR');
    await network.report(30, 'INR');
    assert.equal(ads.calls.filter((u) => u.includes('oauth2')).length, 1);
    assert.equal(ads.calls.filter((u) => u.includes('networkReport')).length, 2);
  });
});
