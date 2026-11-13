/**
 * Candidate phrase windows around a tapped token, and the rule for matching an
 * idiom that has a slot in it. Mirrors app/lib/core/text/phrase_windows.dart.
 */

/**
 * The longest phrase that can be matched in running text.
 *
 * Was 4, which was enough for the 3,000 phrases the dictionary shipped with.
 * The idiom set is longer: "hit the nail on the head" is six tokens and "let
 * the cat out of the bag" is seven, and at four a reader tapping inside either
 * got the entry for `nail` or `cat`.
 */
export const MAX_PHRASE_TOKENS = 9;

/**
 * Tokens in a phrase that stand for whatever the sentence puts there, so they
 * match any single token: "change one's mind", "serve someone right".
 *
 * Bare "one" is deliberately absent. 02_select treats it as a placeholder when
 * deciding what may become a phrase, but in "kill two birds with one stone" it
 * is a numeral, and wildcarding it would match nonsense.
 */
export const SLOT_TOKENS: ReadonlySet<string> = new Set([
  "one's",
  'oneself',
  'someone',
  "someone's",
  'somebody',
  "somebody's",
  'something',
  'somewhere',
]);

/** Whether [phrase] has a slot, and so can never be matched literally. */
export function isPhrasePattern(phrase: string): boolean {
  return phrase.split(' ').some((t) => SLOT_TOKENS.has(t));
}

/** Whether `phrase` describes `tokens`, treating its slots as wildcards. */
export function patternMatches(phrase: string, tokens: string[]): boolean {
  const parts = phrase.split(' ');
  if (parts.length !== tokens.length) return false;
  return parts.every((p, i) => SLOT_TOKENS.has(p) || p === tokens[i]);
}

export type PhraseWindow = { start: number; tokenCount: number; phrase: string; tokens: string[] };

export function phraseWindows(
  tokens: string[],
  index: number,
  minLen = 2,
  maxLen = MAX_PHRASE_TOKENS,
): PhraseWindow[] {
  const out: PhraseWindow[] = [];
  for (let len = maxLen; len >= minLen; len--) {
    for (let start = index - len + 1; start <= index; start++) {
      if (start < 0 || start + len > tokens.length) continue;
      const slice = tokens.slice(start, start + len);
      if (slice.some((t) => t.length === 0)) continue;
      out.push({ start, tokenCount: len, phrase: slice.join(' '), tokens: slice });
    }
  }
  return out;
}

/**
 * The first tokens a stored phrase could have to match any of `windows`: each
 * window's own first token, plus the slots, for the handful of idioms that
 * open with one ("someone's cup of tea").
 */
export function candidateFirstTokens(windows: PhraseWindow[]): string[] {
  return [...new Set([...windows.map((w) => w.tokens[0]!), ...SLOT_TOKENS])];
}

export interface PhraseStore {
  findPhraseLemma(phrase: string): Promise<string | null>;
  /** Stored phrases of at most `maxTokens` whose first token is one of these. */
  findPhrasesByFirstToken(
    firstTokens: string[],
    maxTokens: number,
  ): Promise<{ phrase: string; lemma: string }[]>;
}

export async function matchPhrase(
  store: PhraseStore,
  tokens: string[],
  index: number,
): Promise<{ phrase: string; lemma: string; start: number; tokenCount: number } | null> {
  const windows = phraseWindows(tokens, index);
  if (windows.length === 0) return null;
  // One query for every window, rather than one per window: a nine-token
  // window set asks about 44 phrases, and a phrase with a slot in it never
  // matches a window literally and has to be compared token by token.
  const candidates = await store.findPhrasesByFirstToken(
    candidateFirstTokens(windows),
    MAX_PHRASE_TOKENS,
  );
  const literal = new Map(candidates.map((c) => [c.phrase, c.lemma]));
  const patterns = candidates.filter((c) => isPhrasePattern(c.phrase));
  for (const w of windows) {
    const lemma =
      literal.get(w.phrase) ?? patterns.find((c) => patternMatches(c.phrase, w.tokens))?.lemma;
    if (lemma) return { phrase: w.phrase, lemma, start: w.start, tokenCount: w.tokenCount };
  }
  return null;
}
