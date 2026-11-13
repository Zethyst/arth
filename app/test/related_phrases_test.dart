import 'package:arth/core/models/contracts.dart';
import 'package:arth/core/text/related_phrases.dart';
import 'package:flutter_test/flutter_test.dart';

RelatedPhrase _p(String phrase, RelatedPhraseKind kind) =>
    RelatedPhrase(phrase: phrase, kind: kind, partOfSpeech: 'क्रिया', meaning: 'अर्थ');

void main() {
  group('phraseKind', () {
    test('the word plus particles only is a phrasal verb', () {
      expect(phraseKind('get', 'get up'), RelatedPhraseKind.phrasal);
      expect(phraseKind('get', 'get away with'), RelatedPhraseKind.phrasal);
      expect(phraseKind('put', 'put up with'), RelatedPhraseKind.phrasal);
    });

    test('a content word, or the word not first, makes it an idiom', () {
      expect(phraseKind('get', 'get cold feet'), RelatedPhraseKind.idiom);
      expect(phraseKind('get', 'get married'), RelatedPhraseKind.idiom);
      expect(phraseKind('want', 'in want of'), RelatedPhraseKind.idiom);
    });
  });

  test('sortPhrases: phrasal verbs first, then shortest, then alphabetical', () {
    final out = sortPhrases([
      _p('get cold feet', RelatedPhraseKind.idiom),
      _p('get over', RelatedPhraseKind.phrasal),
      _p('get away with', RelatedPhraseKind.phrasal),
      _p('get by', RelatedPhraseKind.phrasal),
      _p('get the hang of', RelatedPhraseKind.idiom),
    ]).map((p) => p.phrase).toList();
    expect(out, [
      'get by',
      'get over',
      'get away with',
      'get cold feet',
      'get the hang of',
    ]);
  });
}
