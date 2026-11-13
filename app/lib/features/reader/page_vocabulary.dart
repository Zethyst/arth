// "Hard words on this page": the uncommon vocabulary of the page in front of
// the reader, gathered in one list instead of found by tapping around.
//
// Entirely offline. Which words are hard is decided by `freqRank`, the same
// frequency the reader already uses to decide when a word is worth an AI
// answer (`kAiOnRequestRank`), so the list and the tooltip agree about what
// counts as common.

import 'package:arth/core/text/page_text_index.dart';
import 'package:arth/data/local_store.dart';
import 'package:arth/features/reader/reader_controller.dart';

/// Words ranked at or below this are everyday English and never listed.
/// Shared with the reader's AI threshold on purpose: a word common enough
/// that the reader is not offered an AI answer is not "advanced vocabulary".
const int kAdvancedWordRank = kAiOnRequestRank;

/// A word that is below this length is a preposition or an abbreviation, not
/// vocabulary worth studying.
const int kMinAdvancedWordLength = 4;

/// At most this many, so the sheet stays a list and not a second book.
const int kMaxPageWords = 40;

/// One uncommon word found on the page.
class PageVocabularyWord {
  const PageVocabularyWord({
    required this.key,
    required this.text,
    required this.source,
    required this.wordIndex,
    required this.rank,
  });

  /// The dictionary key (normalized, lowercase).
  final String key;

  /// The token as it is printed on the page, punctuation and all. The list
  /// shows [key] instead; this is what a caller needs to find it in the text.
  final String text;

  /// Which of the scanned indexes it came from. A PDF or a photographed page
  /// is one index; an EPUB screen is one per visible paragraph.
  final int source;

  /// Where it sits in that index, for the sentence it is in.
  final int wordIndex;

  /// Its frequency rank, or null when the on-device dictionary has never
  /// heard of it.
  final int? rank;

  /// Rarest first.
  ///
  /// A word the phone's dictionary doesn't have is rarer than every word it
  /// does — the on-device slice is the commonest 20,000 — so those come
  /// first, not last. Sorting them to the bottom put `obsequious` and
  /// `perspicacity` below `refreshments`, which is the opposite of what this
  /// list is for.
  static int compare(PageVocabularyWord a, PageVocabularyWord b) {
    if (a.rank == null && b.rank == null) return a.key.compareTo(b.key);
    if (a.rank == null) return -1;
    if (b.rank == null) return 1;
    return b.rank!.compareTo(a.rank!);
  }
}

final RegExp _leadingPunct = RegExp(r'^[^\p{L}\p{N}]+', unicode: true);

/// Capitalised away from the start of a sentence: a name, not a hard word.
bool looksLikeName(String token) {
  final t = token.replaceFirst(_leadingPunct, '');
  if (t.isEmpty) return false;
  final c = t[0];
  return c.toUpperCase() == c && c.toLowerCase() != c;
}

/// The tokens on a page that are even worth a rank lookup: long enough, a
/// real word, not a name, and each key only once. Pure, so the rules can be
/// tested without a dictionary.
List<PageWord> advancedCandidates(PageTextIndex index) {
  final sentenceStarts = {for (final s in index.sentences) s.firstWord};
  final seen = <String>{};
  final out = <PageWord>[];
  for (final w in index.words) {
    final key = w.key;
    if (key.length < kMinAdvancedWordLength) continue;
    // A key with a digit or an inner mark is a page number or a citation.
    if (!_isWordy(key)) continue;
    if (looksLikeName(w.text) && !sentenceStarts.contains(w.index)) continue;
    if (!seen.add(key)) continue;
    out.add(w);
  }
  return out;
}

/// Keys that are capitalised every single time they appear on the page.
///
/// On its own that proves nothing — a word can simply open the only sentence
/// it is in. Paired with "the dictionary has never heard of it" it is a
/// name: that pair is what tells "Elizabeth" from "Printed".
Set<String> alwaysCapitalised(PageTextIndex index) {
  final all = <String, bool>{};
  for (final w in index.words) {
    all[w.key] = (all[w.key] ?? true) && looksLikeName(w.text);
  }
  return {for (final e in all.entries) if (e.value) e.key};
}

bool _isWordy(String key) {
  for (final r in key.runes) {
    final c = String.fromCharCode(r);
    final isLetter = c.toLowerCase() != c.toUpperCase();
    if (!isLetter && c != '-' && c != "'") return false;
  }
  return true;
}

/// Looks up every candidate's rank across [pages] and keeps the uncommon
/// ones, rarest first. A word that appears in more than one of the pages is
/// listed once, pointing at where it first appeared.
Future<List<PageVocabularyWord>> scanPageVocabulary(
  List<PageTextIndex> pages,
  LocalStore store, {
  int threshold = kAdvancedWordRank,
  int max = kMaxPageWords,
}) async {
  final out = <PageVocabularyWord>[];
  final seen = <String>{};
  for (var source = 0; source < pages.length; source++) {
    final names = alwaysCapitalised(pages[source]);
    for (final w in advancedCandidates(pages[source])) {
      if (!seen.add(w.key)) continue;
      final rank = await store.rankOf(w.key);
      if (rank != null && rank <= threshold) continue;
      // No rank and never once lower-case: a character or a place, which is
      // not vocabulary however rare it looks.
      if (rank == null && names.contains(w.key)) continue;
      out.add(PageVocabularyWord(key: w.key, text: w.text, source: source, wordIndex: w.index, rank: rank));
    }
  }
  out.sort(PageVocabularyWord.compare);
  return out.length <= max ? out : out.sublist(0, max);
}
