// Synonyms, antonyms and one-word substitutions, picked out of the
// dictionary the phone already holds.
//
// Nothing here is new content: every entry carries its synonyms and antonyms
// with their Hindi, and every sense carries a Hindi definition. What this
// file does is decide which of them are worth learning, and in what order —
// the same job idiom_selection.dart does for idioms.
//
// One-word substitution is the exam-hall exercise: a description in Hindi,
// one English word that replaces it ("दोषी अपराधियों को रखने वाली सरकारी
// जेल" → penitentiary). The dictionary's definitions are already written as
// descriptions, so a substitution is a sense whose definition describes a
// thing rather than explaining how a word is used.

import 'package:arth/core/text/function_words.dart';

/// A word worth asking for: letters, possibly hyphenated, long enough to be
/// a word rather than a mark ("&", "'n") or an abbreviation.
final RegExp _properWord = RegExp(r'^[A-Za-z][A-Za-z-]{2,}$');

/// The three sets, beside idioms.
enum WordSetKind { synonym, antonym, substitution }

/// One thing to learn: a headword, the word that answers it, and the Hindi
/// that carries it.
class WordSetItem {
  const WordSetItem({
    required this.kind,
    required this.word,
    required this.answer,
    required this.others,
    required this.hi,
    required this.meaning,
    required this.freqRank,
  });

  final WordSetKind kind;

  /// The headword this came from, and what a browse list shows first. For a
  /// substitution it is also [answer]: the word the description is asking for.
  final String word;

  /// The word the reader has to produce.
  final String answer;

  /// The other words that would also be right — the rest of the entry's
  /// synonyms or antonyms. Kept so practice never offers one as a wrong
  /// answer, and so the browse list can show what else fits.
  final List<String> others;

  /// Hindi for [answer]; for a substitution, the description itself.
  final String hi;

  /// The headword's own Hindi meaning, to show beside it.
  final String meaning;

  /// The headword's place in English by frequency: the order these are
  /// taught in, commonest first.
  final int freqRank;

  /// Stable across rebuilds, so progress survives a new dictionary.
  String get id => '${kind.name}:$word';

  /// Every word that would be right, the asked-for one first.
  List<String> get allAnswers => [answer, ...others];
}

/// A definition that explains how a word is used rather than describing a
/// thing. "किसी जगह जाने की दिशा बताने के लिए इस्तेमाल होता है" is grammar,
/// not something a single word can be asked for.
final RegExp _usageNote = RegExp(
  'इस्तेमाल होता|इस्तेमाल किया जाता|इस्तेमाल करते|बताने के लिए|कहने के लिए|'
  'जताने के लिए|सूचित करने|संबोधित करने|का संक्षिप्त रूप|का छोटा रूप|वर्तनी',
);

/// The shapes a description takes: "…करने वाला", "जो…", "जिसमें…", "जहाँ…",
/// "…का डर", "…की कला". A definition with none of these is a bare gloss, not
/// a description worth asking for.
final RegExp _describes = RegExp(
  'वाला|वाली|वाले|^जो |जो |जिसे |जिसमें |जिसका |जिसकी |जिन्हें |जहाँ |ऐसा |ऐसी |ऐसे |'
  'का डर|का भय|का अध्ययन|की अवस्था|की स्थिति|की कला|की प्रथा|की रस्म',
);

/// Hindi for the parts of speech a substitution can be: a thing or a quality.
/// A verb's description ("तेज़ी से चलना") is not a one-word substitution.
const Set<String> _substitutionPos = {'संज्ञा', 'विशेषण'};

/// A description shorter than this is a gloss ("एक पक्षी"), not a definition
/// a reader could answer from.
const int kMinDescription = 30;

/// Words this common are not what the exercise is for: everybody already has
/// "water" and "happy". The teachable band starts after them.
const int kSubstitutionFromRank = 2500;

/// …and ends before the words nobody will meet, which make the list feel
/// like a dictionary dump rather than a lesson.
const int kSubstitutionToRank = 20000;

/// How far down an entry a substitution may be taken from. The description
/// has to be the word's own, not a corner of it: "compass" means the thing
/// that finds north, and a card asking for it from "the range of a voice"
/// teaches nobody.
const int kSubstitutionSenses = 2;

/// How much commoner than its headword an unrelated-looking answer has to
/// be before the item is dropped as belonging to another sense.
const int kOtherSenseGap = 4;

/// The most synonyms (or antonyms) one item carries.
const int kMaxOthers = 6;

/// The sets [entry] yields — at most one of each kind.
///
/// [rankOf] gives a word's place by frequency, or null when the phone has no
/// entry for it. It decides which synonym is the one to ask for: an entry
/// lists them in the order Wiktionary happened to, so "author" offers
/// "bookwright" before "writer".
List<WordSetItem> wordSetsFromEntry({
  required String word,
  required int freqRank,
  required Map<String, dynamic> entry,
  required int? Function(String word) rankOf,
}) {
  // A phrase has its own lessons: the idioms list teaches those.
  if (entry['isPhrase'] == true || word.contains(' ')) return const [];
  // Nobody sets out to learn a synonym for "the" — and Wiktionary's answer
  // when they do is a dialect spelling ("the" → "le", "and" → "&").
  final teachable = _properWord.hasMatch(word) && !kFunctionWords.contains(word.toLowerCase());
  final senses = (entry['senses'] as List<dynamic>?) ?? const [];
  final meaning = senses.isEmpty ? '' : ((senses.first as Map<String, dynamic>)['meaning'] as String? ?? '');
  final out = <WordSetItem>[];

  for (final (kind, key) in [(WordSetKind.synonym, 'synonyms'), (WordSetKind.antonym, 'antonyms')]) {
    if (!teachable) continue;
    final pairs = [
      for (final p in (entry[key] as List<dynamic>?) ?? const [])
        if (p is Map<String, dynamic>)
          if (_answerable(p['en'], word, rankOf)) (en: p['en']! as String, hi: p['hi'] as String? ?? ''),
    ];
    if (pairs.isEmpty) continue;
    // Which one to ask for. An entry's list covers all of its senses, so the
    // best-known word in it is often the answer to a sense the reader isn't
    // being shown: "await" lists "service", "time" lists "set". A pair whose
    // Hindi shares a word with the headword's own meaning is about the sense
    // on the card, so those come first; among equals, the best-known word,
    // because it is the one a reader has a chance of using.
    final shares = {for (final p in pairs) p.en: _sharesWord(p.hi, meaning)};
    final ranked = [...pairs]..sort((a, b) {
        final byShare = (shares[b.en]! ? 1 : 0).compareTo(shares[a.en]! ? 1 : 0);
        return byShare != 0 ? byShare : (rankOf(a.en) ?? 1 << 30).compareTo(rankOf(b.en) ?? 1 << 30);
      });
    final best = ranked.first;
    // Nothing in the list is about the sense on the card, and the word it
    // offers is far commoner than the headword: it answers some other sense
    // ("await" → "service"). Better no card than a wrong one.
    if (!shares[best.en]! && (rankOf(best.en) ?? freqRank) * kOtherSenseGap < freqRank) continue;
    out.add(
      WordSetItem(
        kind: kind,
        word: word,
        answer: best.en,
        others: [for (final p in ranked.skip(1).take(kMaxOthers - 1)) p.en],
        hi: best.hi,
        meaning: meaning,
        freqRank: freqRank,
      ),
    );
  }

  final description = teachable ? _substitutionFor(senses, freqRank) : null;
  if (description != null) {
    out.add(
      WordSetItem(
        kind: WordSetKind.substitution,
        word: word,
        answer: word,
        others: const [],
        hi: description.$1,
        meaning: description.$2,
        freqRank: freqRank,
      ),
    );
  }
  return out;
}

/// Whether two Hindi glosses name the same thing — any word in common,
/// ignoring the commas a gloss separates its readings with.
bool _sharesWord(String a, String b) {
  if (a.isEmpty || b.isEmpty) return false;
  final left = _glossWords(a);
  return _glossWords(b).any(left.contains);
}

/// The words a Hindi gloss is built with rather than the ones it means:
/// nearly every verb gloss ends in करना, so without these two glosses as
/// far apart as "इंतज़ार करना" and "सेवा करना" would count as the same.
const Set<String> _glossHelpers = {
  'करना', 'करने', 'किया', 'होना', 'होने', 'हुआ', 'हुई', 'जाना', 'जाने', 'देना',
  'लेना', 'रहना', 'वाला', 'वाली', 'वाले', 'का', 'की', 'के', 'को', 'में',
  'से', 'पर', 'और', 'या', 'है', 'हैं', 'था', 'थी', 'भी',
};

// 'एक', 'जो', 'यह' and 'वह' are not in that list: they look like grammar,
// but they are the whole meaning of "one", "which", "this" and "that".

Set<String> _glossWords(String gloss) => {
      for (final w in gloss.split(RegExp(r'[\s,;।]+')))
        if (w.length > 1 && !_glossHelpers.contains(w)) w,
    };

/// Whether [en] is a word this phone could teach and the reader could look
/// up afterwards: a proper word, not the headword again, and one the
/// dictionary actually holds. The last is what keeps dialect spellings and
/// one-off coinages out — they are in an entry's synonym list, but they are
/// not in the dictionary, so there is nothing to send a reader to.
bool _answerable(Object? en, String word, int? Function(String) rankOf) {
  if (en is! String || en == word || !_properWord.hasMatch(en)) return false;
  return rankOf(en) != null;
}

/// The sense of [senses] whose definition is a description one word could
/// replace, as (definition, meaning); null when the word has none.
(String, String)? _substitutionFor(List<dynamic> senses, int freqRank) {
  if (freqRank < kSubstitutionFromRank || freqRank > kSubstitutionToRank) return null;
  for (final s in senses.take(kSubstitutionSenses)) {
    if (s is! Map<String, dynamic>) continue;
    if (!_substitutionPos.contains(s['partOfSpeech'])) continue;
    final d = (s['definition'] as String? ?? '').trim();
    if (d.length < kMinDescription) continue;
    if (_usageNote.hasMatch(d)) continue;
    if (!_describes.hasMatch(d)) continue;
    return (d, s['meaning'] as String? ?? '');
  }
  return null;
}
