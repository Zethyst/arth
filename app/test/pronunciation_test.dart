import 'package:arth/app/theme.dart';
import 'package:arth/core/models/contracts.dart';
import 'package:arth/features/tools/pronunciation.dart';
import 'package:arth/features/tools/spell_check_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  _markFixes();
  group('what the recogniser heard', () {
    test('the word itself scores full marks', () {
      expect(pronunciationScore('thought', 'thought'), 100);
      expect(scoreSaid('thought', 'thought').how, SaidHow.clear);
    });

    test('capitals and punctuation are not the reader’s doing', () {
      expect(pronunciationScore('thought', 'Thought.'), 100);
      expect(pronunciationScore('all right', 'All right!'), 100);
    });

    test('a word split into two is still one attempt', () {
      // Recognisers do this constantly when asked for a single word.
      expect(pronunciationScore('about', 'a bout'), 100);
    });

    test('a near miss lands in the middle band', () {
      final r = scoreSaid('thought', 'taught');
      expect(r.how, SaidHow.nearly);
      expect(r.score, inInclusiveRange(kNearlyScore, kClearScore - 1));
    });

    test('a different word is off', () {
      expect(scoreSaid('thought', 'elephant').how, SaidHow.off);
    });

    test('silence is off, not a crash', () {
      expect(pronunciationScore('thought', ''), 0);
      expect(scoreSaid('thought', '').how, SaidHow.off);
    });

    test('a score is never negative, however wrong the attempt', () {
      expect(pronunciationScore('ox', 'incomprehensibility'), greaterThanOrEqualTo(0));
    });

    test('the bands are ordered, so a better attempt never scores worse', () {
      final exact = pronunciationScore('receive', 'receive');
      final near = pronunciationScore('receive', 'recieve');
      final far = pronunciationScore('receive', 'banana');
      expect(exact, greaterThan(near));
      expect(near, greaterThan(far));
    });
  });
}

/// The editor underlines each fix where it actually occurs, so the spans it
/// builds have to add back up to exactly what the writer typed.
void _markFixes() {
  const c = ArthColors.light;
  ProofreadFixes fix(String wrong, String right) => ProofreadFixes(
        wrong: wrong,
        right: right,
        kind: ProofreadFixesKind.spelling,
        why: 'वर्तनी।',
      );

  group('marking the fixes in the text', () {
    const typed = 'I recieved your mesage yesterday.';

    test('the spans join back into the original text', () {
      final spans = markFixes(typed, [fix('recieved', 'received'), fix('mesage', 'message')], c);
      expect(spans.map((s) => s.text).join(), typed);
    });

    test('the wrong words are the ones underlined', () {
      final spans = markFixes(typed, [fix('recieved', 'received')], c);
      final marked = [for (final s in spans) if (s.style?.decoration == TextDecoration.underline) s.text];
      expect(marked, ['recieved']);
    });

    test('a fix that is not in the text marks nothing', () {
      final spans = markFixes(typed, [fix('not here', 'something')], c);
      expect(spans.map((s) => s.text).join(), typed);
      expect(spans.any((s) => s.style?.decoration == TextDecoration.underline), isFalse);
    });

    test('the same word twice marks the one the fix is for, then the next', () {
      const twice = 'teh cat and teh dog';
      final spans = markFixes(twice, [fix('teh', 'the'), fix('teh', 'the')], c);
      expect(spans.map((s) => s.text).join(), twice);
      final marked = [for (final s in spans) if (s.style?.decoration == TextDecoration.underline) s.text];
      expect(marked, ['teh', 'teh']);
    });

    test('no fixes leaves the text in one piece', () {
      final spans = markFixes(typed, const [], c);
      expect(spans, hasLength(1));
      expect(spans.single.text, typed);
    });
  });
}
