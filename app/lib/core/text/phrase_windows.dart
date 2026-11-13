// Candidate phrase windows around a tapped token, and the rule for matching
// an idiom that has a slot in it.
//
// Mirrors the server's /phrases/match rule: windows of 2–[kMaxPhraseTokens]
// tokens that include the tapped index, longest first, then leftmost. The
// caller checks each candidate against a store (local SQLite or the API) and
// takes the first hit.

/// The longest phrase that can be matched in running text.
///
/// Was 4, which was enough for the 3,000 phrases the dictionary shipped with.
/// The idiom set is longer: "hit the nail on the head" is six tokens and "let
/// the cat out of the bag" is seven, and at four a reader tapping inside
/// either got the entry for `nail` or `cat`. Nine covers all but four of the
/// idioms we hold, and the cost is a longer IN clause on one indexed query.
const int kMaxPhraseTokens = 9;

/// Tokens in a phrase that stand for whatever the sentence puts there, so
/// they match any single token: "change one's mind", "serve someone right".
///
/// Bare "one" is deliberately absent. 02_select treats it as a placeholder
/// when deciding what may become a phrase, but in "kill two birds with one
/// stone" it is a numeral, and wildcarding it would match nonsense.
const Set<String> kSlotTokens = {
  "one's",
  'oneself',
  'someone',
  "someone's",
  'somebody',
  "somebody's",
  'something',
  'somewhere',
};

/// Whether [phrase] has a slot, and so can never be matched literally.
bool isPhrasePattern(String phrase) {
  for (final token in phrase.split(' ')) {
    if (kSlotTokens.contains(token)) return true;
  }
  return false;
}

/// Whether [phrase] describes [tokens], treating its slots as wildcards.
///
/// Both sides are already normalized, so this is an exact comparison at every
/// position that is not a slot.
bool patternMatches(String phrase, List<String> tokens) {
  final parts = phrase.split(' ');
  if (parts.length != tokens.length) return false;
  for (var i = 0; i < parts.length; i++) {
    if (kSlotTokens.contains(parts[i])) continue;
    if (parts[i] != tokens[i]) return false;
  }
  return true;
}

class PhraseWindow {
  const PhraseWindow({
    required this.start,
    required this.tokenCount,
    required this.phrase,
  });

  final int start;
  final int tokenCount;

  /// Space-joined tokens — the `phrases._id` key.
  final String phrase;

  /// The tokens themselves, for matching against a pattern.
  List<String> get tokens => phrase.split(' ');
}

/// All windows of [minLen]..[maxLen] tokens covering [index], longest first.
List<PhraseWindow> phraseWindows(
  List<String> tokens,
  int index, {
  int minLen = 2,
  int maxLen = kMaxPhraseTokens,
}) {
  final out = <PhraseWindow>[];
  for (var len = maxLen; len >= minLen; len--) {
    for (var start = index - len + 1; start <= index; start++) {
      if (start < 0 || start + len > tokens.length) continue;
      final slice = tokens.sublist(start, start + len);
      if (slice.any((t) => t.isEmpty)) continue;
      out.add(
        PhraseWindow(start: start, tokenCount: len, phrase: slice.join(' ')),
      );
    }
  }
  return out;
}

/// The first tokens a stored phrase could have to match any of [windows]:
/// each window's own first token, plus the slots, for the handful of idioms
/// that open with one ("someone's cup of tea").
Set<String> candidateFirstTokens(List<PhraseWindow> windows) => {
      for (final w in windows) w.tokens.first,
      ...kSlotTokens,
    };
