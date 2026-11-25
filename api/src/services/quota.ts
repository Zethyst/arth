/**
 * AI usage limits by tier. Only AI answers count — a meaning "in this
 * sentence" (/context), a sentence translation (/translate), and a
 * dictionary entry generated live (/lookup of a staged word). Words already
 * in the dictionary, on the device or the server, are free.
 *
 *   free   100 uses, lifetime
 *   pro    500 uses per calendar month (UTC)
 *   super  5,000 uses per calendar month (a fair-use cap)
 *
 * A use is reserved atomically before the work and refunded if the answer
 * didn't need AI after all (single-sense words) or failed.
 */
import type { Tier, User } from './accounts.js';

/**
 * [free] is also the most one phone gets on the Free plan, whichever
 * accounts use it, and [freeAccountsPerDevice] how many Free accounts may
 * share a phone's allowance: signing in with a fresh email doesn't reset it.
 */
export type Limits = {
  free: number;
  proMonthly: number;
  superMonthly?: number;
  freeAccountsPerDevice?: number;
  /** AI uses earned by watching one rewarded ad. */
  adBonus?: number;
  /** Rewarded ads that count in a day, so the allowance can't be farmed. */
  adBonusPerDay?: number;
};
export const defaultLimits: Limits = {
  free: 100,
  proMonthly: 500,
  superMonthly: 5000,
  freeAccountsPerDevice: 3,
  adBonus: 3,
  adBonusPerDay: 5,
};

/** How a tier is limited: a lifetime cap, a monthly cap, or none. */
export type Allowance = { period: 'lifetime'; max: number } | { period: 'month'; max: number } | { period: 'none' };

/**
 * [bonus] is uses earned by watching rewarded ads. It raises the cap rather
 * than discounting the count, so one number still answers "how many do I
 * have left" everywhere — including the per-phone Free cap, which the gate
 * takes from this same `max`.
 */
export function allowanceFor(tier: Tier, limits: Limits = defaultLimits, bonus = 0): Allowance {
  switch (tier) {
    case 'free':
      return { period: 'lifetime', max: limits.free + bonus };
    case 'pro':
      return { period: 'month', max: limits.proMonthly + bonus };
    case 'super':
      // Unset: unlimited (tests and older configs).
      return limits.superMonthly === undefined ? { period: 'none' } : { period: 'month', max: limits.superMonthly + bonus };
  }
}

/** [allowanceFor] with this reader's earned uses already in it. */
export const allowanceOf = (user: User, limits: Limits = defaultLimits): Allowance =>
  allowanceFor(user.tier, limits, user.aiBonus);

/** "2026-11-25": the UTC day a day's rewarded ads count in. */
export const dayOf = (now: number) => new Date(now).toISOString().slice(0, 10);

/** Rewarded ads this reader may still watch today. */
export function adsLeftToday(user: User, limits: Limits = defaultLimits, now = Date.now()): number {
  const perDay = limits.adBonusPerDay ?? 0;
  if (perDay === 0 || (limits.adBonus ?? 0) === 0) return 0;
  const watched = user.aiBonusDay === dayOf(now) ? user.aiBonusDayCount : 0;
  return Math.max(0, perDay - watched);
}

/** "2026-09": the UTC month a monthly allowance counts in. */
export const monthOf = (now: number) => new Date(now).toISOString().slice(0, 7);

/** Midnight UTC on the 1st of next month. */
export function nextMonthStart(now: number): number {
  const d = new Date(now);
  return Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 1);
}

/** What the app shows: used of limit, and when it resets. */
export type Usage = {
  used: number;
  /** Null when unlimited. */
  limit: number | null;
  period: Allowance['period'];
  /** Ms timestamp for a monthly allowance; null otherwise. */
  resetsAt: number | null;
  /** Set when the phone's Free allowance, not the account's, is the limit. */
  phone?: true;
  /** Uses earned by watching rewarded ads, already counted in [limit]. */
  bonus?: number;
};

export function usageOf(user: User, limits: Limits = defaultLimits, now = Date.now()): Usage {
  const a = allowanceOf(user, limits);
  const monthUses = user.aiMonth === monthOf(now) ? user.aiMonthUses : 0;
  const earned = user.aiBonus > 0 ? { bonus: user.aiBonus } : {};
  switch (a.period) {
    case 'lifetime':
      return { used: user.aiTotal, limit: a.max, period: 'lifetime', resetsAt: null, ...earned };
    case 'month':
      return { used: monthUses, limit: a.max, period: 'month', resetsAt: nextMonthStart(now), ...earned };
    case 'none':
      return { used: monthUses, limit: null, period: 'none', resetsAt: null };
  }
}

export function hasRemaining(user: User, limits: Limits = defaultLimits, now = Date.now()): boolean {
  const u = usageOf(user, limits, now);
  return u.limit === null || u.used < u.limit;
}
