/** Escape a user-supplied string for safe use inside a RegExp literal. */
export function escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
