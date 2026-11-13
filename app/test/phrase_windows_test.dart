import 'package:arth/core/text/phrase_windows.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tokens = ['a', 'single', 'man', 'in', 'possession', 'of', 'a', 'good'];

  test('longest windows first, all covering the index', () {
    final w = phraseWindows(tokens, 3, maxLen: 4); // "in"
    expect(w.first.tokenCount, 4);
    expect(w.map((x) => x.phrase).toList(), [
      'a single man in',
      'single man in possession',
      'man in possession of',
      'in possession of a',
      'single man in',
      'man in possession',
      'in possession of',
      'man in',
      'in possession',
    ]);
    for (final x in w) {
      expect(x.start <= 3 && x.start + x.tokenCount > 3, isTrue);
    }
  });

  test('clips at the edges', () {
    final w = phraseWindows(tokens, 0, maxLen: 4);
    expect(w.map((x) => x.phrase).toList(), [
      'a single man in',
      'a single man',
      'a single',
    ]);
    final last = phraseWindows(tokens, tokens.length - 1, maxLen: 4);
    expect(last.first.phrase, 'possession of a good');
    expect(last.last.phrase, 'a good');
  });

  test('skips windows containing an empty (punctuation-only) token', () {
    final w = phraseWindows(['in', 'want', '', 'of'], 1);
    expect(w.map((x) => x.phrase).toList(), ['in want']);
  });

  test('single token yields nothing', () {
    expect(phraseWindows(['alone'], 0), isEmpty);
  });

  group('reaching a long idiom', () {
    // At the old cap of four, a reader tapping `cat` here could only ever be
    // shown the entry for `cat`.
    const sentence = ['she', 'let', 'the', 'cat', 'out', 'of', 'the', 'bag'];

    test('the whole idiom is among the candidates', () {
      final w = phraseWindows(sentence, 3).map((x) => x.phrase);
      expect(w, contains('let the cat out of the bag'));
    });

    test('nothing longer than the cap is offered', () {
      final long = List.generate(30, (i) => 'w$i');
      for (final w in phraseWindows(long, 15)) {
        expect(w.tokenCount, lessThanOrEqualTo(kMaxPhraseTokens));
        expect(w.start <= 15 && w.start + w.tokenCount > 15, isTrue);
      }
    });
  });

  group('an idiom with a slot in it', () {
    test('the slot matches whatever the sentence put there', () {
      expect(patternMatches("change one's mind", ['change', 'his', 'mind']), isTrue);
      expect(patternMatches("change one's mind", ['change', 'her', 'mind']), isTrue);
      expect(patternMatches('serve someone right', ['serve', 'him', 'right']), isTrue);
    });

    test('the rest of the phrase still has to match', () {
      expect(patternMatches("change one's mind", ['change', 'his', 'shirt']), isFalse);
      expect(patternMatches("change one's mind", ['lose', 'his', 'mind']), isFalse);
      expect(patternMatches("change one's mind", ['change', 'mind']), isFalse);
    });

    test('a phrase without a slot is not a pattern', () {
      expect(isPhrasePattern('in want of'), isFalse);
      expect(isPhrasePattern("change one's mind"), isTrue);
    });

    test('a bare "one" is a numeral, not a slot', () {
      expect(isPhrasePattern('kill two birds with one stone'), isFalse);
    });

    test('the slots are offered as first tokens, for the few that open with one', () {
      // "someone's cup of tea" is stored under first_token "someone's".
      final first = candidateFirstTokens(phraseWindows(['his', 'cup', 'of', 'tea'], 1));
      expect(first, contains('his'));
      expect(first, contains("someone's"));
    });
  });
}
