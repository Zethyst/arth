// Which idioms a reader meets today, and how a practice round is built.
// Both are pure and seeded, so a day's ten are the same ten whenever the
// screen is rebuilt, and a quiz can be tested without a database.

import 'dart:math';

import 'package:arth/data/local_store.dart';

/// How many idioms a day's set holds.
const int kDailyIdioms = 10;

/// How many times a day's worth of candidates to draw from before shuffling.
const int kDailyPoolFactor = 4;

/// How many questions one practice round asks.
const int kPracticeQuestions = 8;

/// Options per question: the right meaning and two others.
const int kPracticeOptions = 3;

/// Words that carry no meaning on their own. A phrase built only from these
/// plus one content word ("at first", "by the way") reads as grammar; one
/// that uses two or more ("night owl", "spill the beans") reads as an idiom.
const Set<String> kFunctionWords = {
  'a', 'an', 'the', 'and', 'or', 'but', 'if', 'so', 'as', 'at', 'by', 'for',
  'from', 'in', 'into', 'of', 'off', 'on', 'out', 'to', 'up', 'with', 'be',
  'is', 'am', 'are', 'was', 'were', 'been', 'being', 'do', 'does', 'did',
  'have', 'has', 'had', 'will', 'would', 'shall', 'should', 'can', 'could',
  'may', 'might', 'must', 'not', 'no', 'nor', 'than', 'then', 'that', 'this',
  'these', 'those', 'there', 'here', 'it', 'its', 'he', 'she', 'they', 'them',
  'his', 'her', 'their', 'you', 'your', 'we', 'our', 'i', 'me', 'my', 'all',
  'any', 'some', 'such', 'very', 'too', 'just', 'only', 'own', 'same',
  'other', 'another', 'each', 'every', 'both', 'few', 'more', 'most', 'much',
  'many', 'what', 'which', 'who', 'whom', 'whose', 'when', 'where', 'why',
  'how', 'about', 'after', 'again', 'against', 'because', 'before', 'below',
  'between', 'down', 'during', 'once', 'over', 'under', 'while',
};

/// How many meaning-carrying words a phrase uses. "at first" scores 1 and is
/// grammar; "sour grapes" scores 2, and so does "eye for an eye" — repeats
/// count, because the repetition is the idiom.
int idiomaticity(String phrase) {
  var content = 0;
  for (final token in phrase.toLowerCase().split(' ')) {
    if (token.isNotEmpty && !kFunctionWords.contains(token)) content++;
  }
  return content;
}

/// The fewest meaning-carrying words a phrase can have and still be an idiom
/// worth teaching. One content word and the rest grammar ("at first", "by the
/// way", "on purpose") is a construction, not something a reader sets out to
/// learn.
const int kMinIdiomaticity = 2;

/// Whether this is something to teach rather than a piece of grammar.
///
/// A phrasal verb is exempt from the floor: "give up" and "take off" score 1,
/// because the particle is a function word, and that is exactly the shape the
/// floor exists to reject. They are not grammar — they are the thing the
/// reader asked to be taught — and they are marked as what they are.
bool isTeachable(IdiomRow i) =>
    i.kind == IdiomKind.phrasal || idiomaticity(i.phrase) >= kMinIdiomaticity;

/// Browse order: idioms before grammar, then best known first, then
/// alphabetical so the list never reorders itself between builds.
///
/// [IdiomRow.weight] leads because it is the only signal of whether a reader
/// will meet the phrase. freqRank cannot lead: it is the rank of the phrase's
/// *rarest word*, so it puts "keep good time" and "red face test" above
/// "spill the beans", and a list of two thousand idioms opens with
/// collocations. idiomaticity cannot lead either: it counts words, so over a
/// long list it just sorts the longest phrases to the top.
int compareForBrowsing(IdiomRow a, IdiomRow b) {
  final byTeachable = (isTeachable(b) ? 1 : 0).compareTo(isTeachable(a) ? 1 : 0);
  if (byTeachable != 0) return byTeachable;
  final byKnown = b.weight.compareTo(a.weight);
  if (byKnown != 0) return byKnown;
  final byRank = a.freqRank.compareTo(b.freqRank);
  return byRank != 0 ? byRank : a.phrase.compareTo(b.phrase);
}

/// A seed that changes once a day and is the same for everyone on that day.
int daySeed(DateTime day) => DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/ 86400000;

/// The idioms for [day], unseen ones first.
///
/// Deterministic: the same day always gives the same set, so leaving the
/// screen and coming back does not reshuffle the cards under the reader. As
/// idioms get seen they drop to the back, and once everything has been seen
/// the longest-ago ones come round again.
List<IdiomRow> dailySet(List<IdiomRow> all, DateTime day, {int count = kDailyIdioms}) {
  if (all.isEmpty) return const [];
  // The day's set is drawn from the best unseen idioms rather than the whole
  // list, then shuffled by the day's seed. Sorting alone would pin the same
  // ten in place for ever, since the order never changes; shuffling alone
  // would open with whatever grammar-ish phrase came up. Taking a few times
  // more candidates than needed gives both: good idioms, different each day.
  //
  // Grammar is left out of the draw entirely rather than sorted to the back:
  // with two thousand idioms the pool is a thin slice off the top, so a
  // phrase that reaches it at all would be shown as the day's idiom.
  final unseen = [for (final i in all) if (i.seenAt == null && isTeachable(i)) i]
    ..sort(compareForBrowsing);
  final pool = unseen.take(count * kDailyPoolFactor).toList()..shuffle(Random(daySeed(day)));
  final seen = [for (final i in all) if (i.seenAt != null && isTeachable(i)) i]
    ..sort((a, b) => a.seenAt!.compareTo(b.seenAt!));
  final out = <IdiomRow>[...pool.take(count)];
  for (final i in seen) {
    if (out.length >= count) break;
    out.add(i);
  }
  return out;
}

/// One multiple-choice question: the idiom, the meanings offered, and which
/// of them is right.
class IdiomQuestion {
  const IdiomQuestion({required this.idiom, required this.options, required this.answer});

  final IdiomRow idiom;

  /// The meanings on offer, in the order they are shown.
  final List<String> options;

  /// The index in [options] of [idiom]'s own meaning.
  final int answer;

  String get correctOption => options[answer];
}

/// Builds a practice round from [all].
///
/// A question's wrong answers are other idioms' meanings, which is what makes
/// the choice a real test: they read like plausible idiom meanings rather
/// than obvious filler. Idioms the reader has got wrong before are asked
/// first, then ones never practised.
List<IdiomQuestion> buildPractice(
  List<IdiomRow> all,
  int seed, {
  int count = kPracticeQuestions,
  int options = kPracticeOptions,
}) {
  // Fewer idioms than a question needs options: no honest quiz is possible.
  if (all.length < options) return const [];
  final random = Random(seed);
  // Quiz the idioms a reader actually meets. Everything ties at 0 right and 0
  // wrong until they have practised, so without a third key the order is just
  // the shuffle — a uniform draw over every idiom on the phone, which asked
  // about "milling machine" before "spill the beans". Grammar is left out for
  // the same reason it is left out of the day's ten.
  final teachable = [for (final i in all) if (isTeachable(i)) i];
  final from = teachable.length >= options ? teachable : all;
  final pool = [...from]
    ..shuffle(random)
    // Hardest first: more wrong answers than right, then never practised,
    // then the best known of the ones never practised.
    ..sort((a, b) {
      final aScore = a.wrongCount - a.rightCount;
      final bScore = b.wrongCount - b.rightCount;
      if (aScore != bScore) return bScore.compareTo(aScore);
      final aTries = a.rightCount + a.wrongCount;
      final bTries = b.rightCount + b.wrongCount;
      if (aTries != bTries) return aTries.compareTo(bTries);
      return b.weight.compareTo(a.weight);
    });

  final out = <IdiomQuestion>[];
  for (final idiom in pool.take(count)) {
    final wrong = <String>{};
    // Draw distractors at random, skipping any that happen to read the same
    // as the answer — two identical options would make the question unfair.
    for (var tries = 0; wrong.length < options - 1 && tries < from.length * 3; tries++) {
      final other = from[random.nextInt(from.length)];
      if (other.phrase == idiom.phrase || other.meaning == idiom.meaning) continue;
      wrong.add(other.meaning);
    }
    if (wrong.length < options - 1) continue;
    final shown = [idiom.meaning, ...wrong]..shuffle(random);
    out.add(IdiomQuestion(idiom: idiom, options: shown, answer: shown.indexOf(idiom.meaning)));
  }
  return out;
}
