/**
 * What Arth earns: ads (Google AdMob) and plans bought in the app stores
 * (RevenueCat). Both are read live from the network that holds the money —
 * no earnings are stored here, so the dashboard can't drift from the payout
 * reports — and both are optional. Unconfigured, they report `enabled: false`
 * and the dashboard says "not connected" rather than showing a zero.
 *
 * Earnings are asked for in one currency ([Income.currency], INCOME_CURRENCY)
 * so the two can be added up. Each network still reports the currency it
 * actually used; the dashboard adds the two only when they match.
 */
import { windowDays } from '../lib/days.js';

/** One day of ad earnings, keyed by its UTC date ("2026-11-24"). */
export type DayEarning = { day: string; earnings: number; impressions: number };

export type AdIncome = {
  currency: string;
  earnings: number;
  impressions: number;
  clicks: number;
  /** Earnings per thousand impressions — AdMob's eCPM. */
  ecpm: number;
  /** Oldest day first, with a zero for days that earned nothing. */
  days: DayEarning[];
};

export interface AdNetwork {
  readonly enabled: boolean;
  /** Earnings for the [days] days ending today. */
  report(days: number, currency: string): Promise<AdIncome>;
}

/** A headline number as RevenueCat names it (MRR, active subscriptions…). */
export type PurchaseMetric = { id: string; name: string; value: number; unit: string; period: string };

export type PurchaseIncome = {
  currency: string;
  /** Revenue over the window asked for; null if RevenueCat wouldn't give it. */
  revenue: number | null;
  metrics: PurchaseMetric[];
};

export interface PurchaseNetwork {
  readonly enabled: boolean;
  income(days: number, currency: string): Promise<PurchaseIncome>;
}

/** Both sources plus the currency to ask them for. */
export type Income = { ads: AdNetwork; purchases: PurchaseNetwork; currency: string };

export const disabledAds: AdNetwork = {
  enabled: false,
  async report() {
    throw new Error('AdMob is not configured');
  },
};

export const disabledPurchaseMetrics: PurchaseNetwork = {
  enabled: false,
  async income() {
    throw new Error('RevenueCat metrics are not configured');
  },
};

/** Nothing connected: the dashboard shows the reader numbers only. */
export const noIncome: Income = { ads: disabledAds, purchases: disabledPurchaseMetrics, currency: 'INR' };

const parts = (key: string) => {
  const [year, month, day] = key.split('-').map(Number);
  return { year: year!, month: month!, day: day! };
};

// ---- AdMob ----

export type AdMobConfig = { publisherId: string; clientId: string; clientSecret: string; refreshToken: string };

/** The rows AdMob streams back: a header, then a row per day, then a footer. */
type NetworkReportResponse = Array<{
  header?: { localizationSettings?: { currencyCode?: string } };
  row?: {
    dimensionValues?: { DATE?: { value?: string } };
    metricValues?: Record<string, { microsValue?: string; integerValue?: string; doubleValue?: number }>;
  };
}>;

const micros = (v?: { microsValue?: string }) => (v?.microsValue ? Number(v.microsValue) / 1_000_000 : 0);
const whole = (v?: { integerValue?: string }) => (v?.integerValue ? Number(v.integerValue) : 0);

/**
 * AdMob's reporting API. It has no service accounts: the earnings belong to a
 * Google account, so this needs that account's OAuth refresh token (scope
 * https://www.googleapis.com/auth/admob.readonly). See "The admin dashboard" in the README.
 */
export function admobNetwork(config: AdMobConfig, fetchImpl: typeof fetch = fetch, now = () => Date.now()): AdNetwork {
  // One access token lasts an hour; a dashboard refresh shouldn't buy a new one.
  let token: { value: string; until: number } | null = null;

  const accessToken = async () => {
    if (token && token.until > now() + 30_000) return token.value;
    const res = await fetchImpl('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: config.clientId,
        client_secret: config.clientSecret,
        refresh_token: config.refreshToken,
        grant_type: 'refresh_token',
      }).toString(),
    });
    if (!res.ok) throw new Error(`Google OAuth ${res.status}`);
    const body = (await res.json()) as { access_token?: string; expires_in?: number };
    if (!body.access_token) throw new Error('Google OAuth returned no access token');
    token = { value: body.access_token, until: now() + (body.expires_in ?? 3600) * 1000 };
    return token.value;
  };

  return {
    enabled: true,
    async report(days, currency) {
      const window = windowDays(now(), days);
      const res = await fetchImpl(`https://admob.googleapis.com/v1/accounts/${encodeURIComponent(config.publisherId)}/networkReport:generate`, {
        method: 'POST',
        headers: { authorization: `Bearer ${await accessToken()}`, 'content-type': 'application/json' },
        body: JSON.stringify({
          reportSpec: {
            dateRange: { startDate: parts(window[0]!), endDate: parts(window[window.length - 1]!) },
            dimensions: ['DATE'],
            metrics: ['ESTIMATED_EARNINGS', 'IMPRESSIONS', 'CLICKS'],
            localizationSettings: { currencyCode: currency },
          },
        }),
      });
      if (!res.ok) throw new Error(`AdMob ${res.status}`);
      const body = (await res.json()) as NetworkReportResponse;

      const byDay = new Map<string, DayEarning>(window.map((day) => [day, { day, earnings: 0, impressions: 0 }]));
      let earnings = 0;
      let impressions = 0;
      let clicks = 0;
      let reported = currency;
      for (const part of Array.isArray(body) ? body : []) {
        if (part.header?.localizationSettings?.currencyCode) reported = part.header.localizationSettings.currencyCode;
        const row = part.row;
        if (!row) continue;
        const m = row.metricValues ?? {};
        const dayEarnings = micros(m.ESTIMATED_EARNINGS);
        const dayImpressions = whole(m.IMPRESSIONS);
        earnings += dayEarnings;
        impressions += dayImpressions;
        clicks += whole(m.CLICKS);
        // AdMob's DATE dimension is "20261124".
        const raw = row.dimensionValues?.DATE?.value ?? '';
        const key = raw.length === 8 ? `${raw.slice(0, 4)}-${raw.slice(4, 6)}-${raw.slice(6)}` : raw;
        const slot = byDay.get(key);
        if (slot) byDay.set(key, { day: key, earnings: slot.earnings + dayEarnings, impressions: slot.impressions + dayImpressions });
      }
      return {
        currency: reported,
        earnings,
        impressions,
        clicks,
        ecpm: impressions > 0 ? (earnings / impressions) * 1000 : 0,
        days: [...byDay.values()],
      };
    },
  };
}

// ---- RevenueCat ----

export type RevenueCatMetricsConfig = { projectId: string; secretKey: string };

type OverviewResponse = {
  currency?: string;
  metrics?: Array<{ id?: string; name?: string; value?: number; unit?: string; period?: string }>;
};

type RevenueResponse = { value?: number; currency?: string };

/**
 * RevenueCat's Charts & Metrics API (v2). The key needs the
 * `charts_metrics:overview:read` permission, and a v1 secret key will not do:
 * REVENUECAT_SECRET_KEY (which reads one buyer's entitlements) is a different
 * key from REVENUECAT_METRICS_KEY.
 *
 * `metrics/overview` is a snapshot with no date range, so the ids and names it
 * returns are passed through as they arrive rather than being mapped to fields
 * here — RevenueCat can add a metric without this needing a change. The window
 * the dashboard asked for comes from `metrics/revenue`, which does take dates.
 */
export function revenueCatMetrics(config: RevenueCatMetricsConfig, fetchImpl: typeof fetch = fetch, now = () => Date.now()): PurchaseNetwork {
  const base = `https://api.revenuecat.com/v2/projects/${encodeURIComponent(config.projectId)}`;
  const get = async (path: string) => {
    const res = await fetchImpl(`${base}${path}`, { headers: { authorization: `Bearer ${config.secretKey}`, accept: 'application/json' } });
    if (!res.ok) throw new Error(`RevenueCat ${res.status}`);
    return res.json();
  };

  return {
    enabled: true,
    async income(days, currency) {
      const window = windowDays(now(), days);
      const overview = (await get(`/metrics/overview?currency=${encodeURIComponent(currency)}`)) as OverviewResponse;
      // The revenue of a window is a second call, and a key may carry the
      // overview permission without it: the snapshot alone is still worth showing.
      const revenue = await get(
        `/metrics/revenue?start_date=${window[0]}&end_date=${window[window.length - 1]}&currency=${encodeURIComponent(currency)}`,
      ).then(
        (r) => (r as RevenueResponse).value ?? null,
        () => null,
      );
      return {
        currency: overview.currency ?? currency,
        revenue,
        metrics: (overview.metrics ?? []).flatMap((m) =>
          m.id && typeof m.value === 'number'
            ? [{ id: m.id, name: m.name ?? m.id, value: m.value, unit: m.unit ?? '', period: m.period ?? '' }]
            : [],
        ),
      };
    },
  };
}
