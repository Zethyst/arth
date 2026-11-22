// A practice round over a word set: the right answer is there once, the
// wrong ones are never also right, and the hardest come first.

import 'package:arth/core/text/word_sets.dart';
import 'package:arth/data/local_store.dart';
import 'package:arth/features/wordsets/word_set_practice.dart';
import 'package:flutter_test/flutter_test.dart';

WordSetRow row(
  String word,
  String answer, {
  WordSetKind kind = WordSetKind.synonym,
  List<String> others = const [],
  int rank = 1000,
  int right = 0,
  int wrong = 0,
}) =>
    WordSetRow(
      kind: kind,
      word: word,
      answer: answer,
      others: others,
      hi: 'हिंदी-$answer',
      meaning: 'अर्थ-$word',
      freqRank: rank,
      rightCount: right,
      wrongCount: wrong,
    );

void main() {
  final many = [for (var i = 0; i < 30; i++) row('word$i', 'answer$i', rank: i)];

  test('every question has one right answer among three', () {
    final round = buildWordSetPractice(many, 7);
    expect(round, hasLength(kWordSetQuestions));
    for (final q in round) {
      expect(q.options, hasLength(kWordSetOptions));
      expect(q.options.toSet(), hasLength(kWordSetOptions), reason: 'no option twice');
      expect(q.correctOption, q.item.answer);
      expect(q.options.where((o) => o == q.item.answer), hasLength(1));
    }
  });

  test('the same seed asks the same round', () {
    final a = buildWordSetPractice(many, 11);
    final b = buildWordSetPractice(many, 11);
    expect([for (final q in a) q.item.id], [for (final q in b) q.item.id]);
    expect([for (final q in a) q.options], [for (final q in b) q.options]);
  });

  test('a word that would also be right is never offered as wrong', () {
    // "big" is asked for, and "large" and "huge" would do just as well.
    final set = [
      row('enormous', 'big', others: ['large', 'huge']),
      for (var i = 0; i < 20; i++) row('word$i', ['large', 'huge', 'answer$i'][i % 3], rank: i),
    ];
    for (var seed = 0; seed < 30; seed++) {
      for (final q in buildWordSetPractice(set, seed)) {
        if (q.item.word != 'enormous') continue;
        expect(q.options.where((o) => ['large', 'huge'].contains(o)), isEmpty);
      }
    }
  });

  test('what the reader keeps getting wrong is asked first', () {
    final set = [
      ...many,
      row('struggle', 'fight', rank: 9999, wrong: 4),
    ];
    final round = buildWordSetPractice(set, 3);
    expect(round.first.item.word, 'struggle');
  });

  test('a substitution asks with its description and hides the meaning', () {
    final set = [
      for (var i = 0; i < 10; i++)
        row('word$i', 'word$i', kind: WordSetKind.substitution, rank: i),
    ];
    final q = buildWordSetPractice(set, 5).first;
    expect(q.prompt, q.item.hi);
    expect(q.hint, isEmpty, reason: 'the meaning would give it away');
  });

  test('a synonym asks with the word and shows its meaning', () {
    final q = buildWordSetPractice(many, 5).first;
    expect(q.prompt, q.item.word);
    expect(q.hint, q.item.meaning);
  });

  test('too few words, no round', () {
    expect(buildWordSetPractice([row('a', 'b')], 1), isEmpty);
  });
}
