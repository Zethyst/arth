// How a practice round over synonyms, antonyms or one-word substitutions is
// built. Pure and seeded, like idiom_selection.dart: a round can be tested
// without a database, and answering does not reshuffle the questions.
//
// All three sets ask the same shape of question — a prompt, and three
// English words of which one is right — so one builder serves them all. What
// changes is the prompt: a word for a synonym or an antonym, a description
// for a substitution.

import 'dart:math';

import 'package:arth/core/text/word_sets.dart';
import 'package:arth/data/local_store.dart';

/// How many questions one round asks.
const int kWordSetQuestions = 8;

/// Options per question: the right word and two others.
const int kWordSetOptions = 3;

class WordSetQuestion {
  const WordSetQuestion({required this.item, required this.options, required this.answer});

  final WordSetRow item;

  /// The words on offer, in the order they are shown.
  final List<String> options;

  /// The index in [options] of the right one.
  final int answer;

  String get correctOption => options[answer];

  /// What the reader is asked about: the headword, or the description that
  /// one word has to replace.
  String get prompt => item.kind == WordSetKind.substitution ? item.hi : item.word;

  /// The line under the prompt: the headword's Hindi for a synonym or an
  /// antonym, nothing for a substitution — its description is the prompt,
  /// and its meaning would give the answer away.
  String get hint => item.kind == WordSetKind.substitution ? '' : item.meaning;
}

/// A round over [all], hardest first.
///
/// A wrong answer is never one of [WordSetRow.others] — every one of those
/// would also have been right — nor a word that reads the same as the
/// answer.
List<WordSetQuestion> buildWordSetPractice(
  List<WordSetRow> all,
  int seed, {
  int count = kWordSetQuestions,
  int options = kWordSetOptions,
}) {
  if (all.length < options) return const [];
  final random = Random(seed);
  final pool = [...all]
    ..shuffle(random)
    // More wrong than right first, then never practised, then the best known
    // of those — the same order the idioms round uses, with frequency
    // standing in for an idiom's weight.
    ..sort((a, b) {
      final aScore = a.wrongCount - a.rightCount;
      final bScore = b.wrongCount - b.rightCount;
      if (aScore != bScore) return bScore.compareTo(aScore);
      final aTries = a.rightCount + a.wrongCount;
      final bTries = b.rightCount + b.wrongCount;
      if (aTries != bTries) return aTries.compareTo(bTries);
      return a.freqRank.compareTo(b.freqRank);
    });

  final out = <WordSetQuestion>[];
  for (final item in pool.take(count)) {
    final right = item.answer;
    final alsoRight = {...item.allAnswers, item.word};
    final wrong = <String>{};
    for (var tries = 0; wrong.length < options - 1 && tries < all.length * 3; tries++) {
      final other = all[random.nextInt(all.length)];
      if (alsoRight.contains(other.answer) || other.answer == right) continue;
      wrong.add(other.answer);
    }
    if (wrong.length < options - 1) continue;
    final shown = [right, ...wrong]..shuffle(random);
    out.add(WordSetQuestion(item: item, options: shown, answer: shown.indexOf(right)));
  }
  return out;
}
