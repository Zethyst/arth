// Classifying and ordering the idioms and phrasal verbs built on a word.
// Mirrors api/src/services/related-phrases.ts so a phrase answered from the
// on-device dictionary reads exactly like one answered by the API.

import 'package:arth/core/models/contracts.dart';

/// The particles that turn a verb into a phrasal verb. Deliberately the
/// closed set — "get up" is phrasal, "get married" is not.
const Set<String> kParticles = {
  'about', 'across', 'after', 'ahead', 'along', 'apart', 'around', 'aside', 'at',
  'away', 'back', 'behind', 'by', 'down', 'for', 'forward', 'in', 'into', 'of',
  'off', 'on', 'onto', 'out', 'over', 'past', 'round', 'through', 'to',
  'together', 'towards', 'under', 'up', 'upon', 'with',
};

/// A phrasal verb is the word itself plus particles and nothing else
/// ("get up", "get away with"); anything else that uses the word is an idiom
/// ("get cold feet", "get the hang of").
RelatedPhraseKind phraseKind(String lemma, String phrase) {
  final tokens = phrase.split(' ');
  if (tokens.isEmpty || tokens.first != lemma) return RelatedPhraseKind.idiom;
  return tokens.skip(1).every(kParticles.contains)
      ? RelatedPhraseKind.phrasal
      : RelatedPhraseKind.idiom;
}

/// Phrasal verbs before idioms, each group shortest first then alphabetical.
List<RelatedPhrase> sortPhrases(List<RelatedPhrase> items) {
  int weight(RelatedPhraseKind k) => k == RelatedPhraseKind.phrasal ? 0 : 1;
  return [...items]..sort((a, b) {
      final byKind = weight(a.kind).compareTo(weight(b.kind));
      if (byKind != 0) return byKind;
      final byLength = a.phrase.split(' ').length.compareTo(b.phrase.split(' ').length);
      return byLength != 0 ? byLength : a.phrase.compareTo(b.phrase);
    });
}
