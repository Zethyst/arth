// Scoring a spoken word against the word that was asked for.
//
// The phone's own speech recogniser does the listening; all this decides is
// how close what it heard is to what the reader was meant to say. That is a
// deliberately modest claim: a recogniser reports *words*, not sounds, so this
// can tell a reader that "thought" came out as "taught" — which is exactly the
// mistake worth catching — but it cannot hear a thickened vowel in a word it
// got right. The needle is honest about what it measures.

import 'package:arth/data/lemma.dart';

/// How a spoken attempt is reported back.
enum SaidHow {
  /// Heard as the word asked for.
  clear,

  /// Heard as something close — a sound or two away.
  nearly,

  /// Heard as a different word, or not heard at all.
  off,
}

/// At or above this a word counts as [SaidHow.clear].
const int kClearScore = 85;

/// At or above this it counts as [SaidHow.nearly]; below, [SaidHow.off].
const int kNearlyScore = 55;

/// What the reader was told, and how it went.
typedef SaidResult = ({int score, SaidHow how, String heard});

/// Letters only, lower case: the recogniser punctuates and capitalises as it
/// pleases, and none of that is the reader's doing. Spaces go too, so a word
/// the recogniser split in two ("a bout" for "about") is still one attempt.
String spokenKey(String s) {
  final buf = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final c = ch.codeUnitAt(0);
    if ((c >= 97 && c <= 122) || ch == "'") buf.write(ch);
  }
  return buf.toString();
}

/// How close [heard] is to [target], 0–100.
int pronunciationScore(String target, String heard) {
  final want = spokenKey(target);
  final got = spokenKey(heard);
  if (want.isEmpty || got.isEmpty) return 0;
  if (want == got) return 100;
  final distance = levenshtein(want, got);
  final longest = want.length > got.length ? want.length : got.length;
  final score = ((1 - distance / longest) * 100).round();
  return score < 0 ? 0 : score;
}

/// The score, and which of the three bands it falls in.
SaidResult scoreSaid(String target, String heard) {
  final score = pronunciationScore(target, heard);
  final how = score >= kClearScore
      ? SaidHow.clear
      : score >= kNearlyScore
          ? SaidHow.nearly
          : SaidHow.off;
  return (score: score, how: how, heard: heard.trim());
}
