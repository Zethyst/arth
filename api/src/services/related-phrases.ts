/**
 * The idioms and phrasal verbs that use a word — the "मुहावरे और वाक्यांश"
 * section of a word screen.
 *
 * A multi-word entry is already a full DictionaryEntry (`isPhrase: true`) with
 * its own Hindi senses, and the `phrases` collection maps every one of them
 * (plus their inflections) to its canonical form. So "the phrases of get" is
 * the set of phrase lemmas that use `get` as a whole token, resolved back to
 * their entries. Nothing is generated: this is the dictionary the reader
 * already has, linked up.
 */
import type { DictionaryEntry, RelatedPhrase } from '../contracts.js';

/**
 * The particles that turn a verb into a phrasal verb. Deliberately the closed
 * set — "get up" is phrasal, "get married" is not.
 */
export const PARTICLES: ReadonlySet<string> = new Set([
  'about', 'across', 'after', 'ahead', 'along', 'apart', 'around', 'aside', 'at',
  'away', 'back', 'behind', 'by', 'down', 'for', 'forward', 'in', 'into', 'of',
  'off', 'on', 'onto', 'out', 'over', 'past', 'round', 'through', 'to',
  'together', 'towards', 'under', 'up', 'upon', 'with',
]);

/** How a phrase is introduced to the reader. */
export type PhraseKind = RelatedPhrase['kind'];

/**
 * A phrasal verb is the word itself plus particles and nothing else
 * ("get up", "get away with"); anything else that uses the word is an idiom
 * ("get cold feet", "get the hang of").
 */
export function phraseKind(lemma: string, phrase: string): PhraseKind {
  const tokens = phrase.split(' ');
  if (tokens[0] !== lemma) return 'idiom';
  return tokens.slice(1).every((t) => PARTICLES.has(t)) ? 'phrasal' : 'idiom';
}

export type { RelatedPhrase };

export interface RelatedPhraseStore {
  /** Canonical phrase lemmas that use [lemma] as a whole token. */
  findPhrasesUsing(lemma: string, limit: number): Promise<string[]>;
  findEntry(id: string): Promise<DictionaryEntry | null>;
}

/** Phrasal verbs before idioms, each group shortest first then alphabetical. */
export function sortPhrases(items: RelatedPhrase[]): RelatedPhrase[] {
  const weight = (k: PhraseKind) => (k === 'phrasal' ? 0 : 1);
  return [...items].sort(
    (a, b) =>
      weight(a.kind) - weight(b.kind) ||
      a.phrase.split(' ').length - b.phrase.split(' ').length ||
      a.phrase.localeCompare(b.phrase),
  );
}

export async function relatedPhrases(store: RelatedPhraseStore, lemma: string, limit = 40): Promise<RelatedPhrase[]> {
  const key = lemma.trim().toLowerCase();
  if (!key || key.includes(' ')) return [];
  const lemmas = await store.findPhrasesUsing(key, limit);
  const out: RelatedPhrase[] = [];
  for (const phrase of lemmas) {
    const entry = await store.findEntry(phrase);
    const sense = entry?.senses[0];
    if (!sense) continue;
    out.push({ phrase, kind: phraseKind(key, phrase), partOfSpeech: sense.partOfSpeech, meaning: sense.meaning });
  }
  return sortPhrases(out);
}
