/**
 * UTC days, for the admin dashboard's windows. Everything the dashboard shows
 * per day — ad earnings, new readers — is keyed by a UTC date so the two line
 * up on one chart, whatever timezone the admin's phone is in.
 */

const DAY = 86_400_000;

/** UTC midnight, [back] days before [now]. */
export const dayStart = (now: number, back = 0) => {
  const d = new Date(now);
  return Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()) - back * DAY;
};

/** "2026-11-24" for a moment. */
export const dayKey = (ms: number) => new Date(ms).toISOString().slice(0, 10);

/** "2026-11": the calendar month the AI allowance counts in. */
export const monthKey = (ms: number) => new Date(ms).toISOString().slice(0, 7);

/** The [days] UTC days ending on [now]'s day, oldest first. */
export const windowDays = (now: number, days: number): string[] =>
  Array.from({ length: days }, (_, i) => dayKey(dayStart(now, days - 1 - i)));
