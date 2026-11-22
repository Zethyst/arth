// What the dictionary yields as synonyms, antonyms and one-word
// substitutions — and, as much, what it must not: dialect spellings, grammar
// words, and answers that belong to some other sense of the headword.

import 'package:arth/core/text/word_sets.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> entry({
  List<Map<String, dynamic>> senses = const [],
  List<Map<String, String>> synonyms = const [],
  List<Map<String, String>> antonyms = const [],
  bool isPhrase = false,
}) =>
    <String, dynamic>{'senses': senses, 'synonyms': synonyms, 'antonyms': antonyms, 'isPhrase': isPhrase};

Map<String, dynamic> sense(String meaning, String definition, {String pos = 'संज्ञा'}) =>
    <String, dynamic>{'index': 0, 'partOfSpeech': pos, 'meaning': meaning, 'definition': definition, 'examples': const <Object>[]};

/// Every word is in the dictionary unless a test says otherwise.
int? everything(String w) => 5000;

List<WordSetItem> sets(
  String word,
  Map<String, dynamic> e, {
  int rank = 5000,
  int? Function(String)? rankOf,
}) =>
    wordSetsFromEntry(word: word, freqRank: rank, entry: e, rankOf: rankOf ?? everything);

void main() {
  test('a word gives up its synonyms and antonyms, best answer first', () {
    final out = sets(
      'brave',
      entry(
        senses: [sense('बहादुर', 'जो डर के बावजूद आगे बढ़े।', pos: 'विशेषण')],
        synonyms: [
          {'en': 'valiant', 'hi': 'वीर'},
          {'en': 'bold', 'hi': 'बहादुर'},
        ],
        antonyms: [
          {'en': 'cowardly', 'hi': 'डरपोक'},
        ],
      ),
      rankOf: (w) => {'valiant': 20000, 'bold': 3000}[w] ?? 5000,
    );
    final synonym = out.firstWhere((i) => i.kind == WordSetKind.synonym);
    // "bold" shares बहादुर with the headword's meaning: it is about this
    // sense, so it is the one asked for, and "valiant" is still right.
    expect(synonym.answer, 'bold');
    expect(synonym.others, ['valiant']);
    expect(synonym.allAnswers, ['bold', 'valiant']);
    expect(out.firstWhere((i) => i.kind == WordSetKind.antonym).answer, 'cowardly');
    expect(synonym.id, 'synonym:brave');
  });

  test('a grammar word is not a lesson', () {
    final out = sets('the', entry(synonyms: [{'en': 'le', 'hi': 'वह'}]));
    expect(out, isEmpty);
  });

  test('an answer the dictionary does not hold is no answer', () {
    // "bes" is in Wiktionary's list for "is" but in no dictionary a reader
    // could look it up in.
    final out = sets(
      'resolute',
      entry(synonyms: [{'en': 'bes', 'hi': 'दृढ़'}, {'en': 'firm', 'hi': 'दृढ़'}]),
      rankOf: (w) => w == 'firm' ? 4000 : null,
    );
    expect(out.single.answer, 'firm');
    expect(out.single.others, isEmpty);
  });

  test('an answer from another sense, far commoner than the word, is dropped', () {
    final out = sets(
      'await',
      entry(
        senses: [sense('इंतज़ार करना', 'किसी के आने का इंतज़ार करना।', pos: 'क्रिया')],
        synonyms: [{'en': 'service', 'hi': 'सेवा करना'}],
      ),
      rank: 10000,
      rankOf: (w) => 900,
    );
    expect(out.where((i) => i.kind == WordSetKind.synonym), isEmpty);
  });

  group('one-word substitution', () {
    final jail = entry(
      senses: [sense('जेल', 'दोषी अपराधियों को रखने वाली सरकारी जेल, ख़ासकर अमेरिका में।')],
    );

    test('a description becomes a card', () {
      final out = sets('penitentiary', jail, rank: 9000).single;
      expect(out.kind, WordSetKind.substitution);
      expect(out.answer, 'penitentiary');
      expect(out.hi, startsWith('दोषी अपराधियों'));
      expect(out.meaning, 'जेल');
    });

    test('words everybody has, and words nobody meets, are left out', () {
      expect(sets('penitentiary', jail, rank: 300), isEmpty);
      expect(sets('penitentiary', jail, rank: 90000), isEmpty);
    });

    test('a note about how a word is used is not a description', () {
      final out = sets(
        'of',
        entry(senses: [sense('का', 'किसी जगह का नाम बताने के लिए इस्तेमाल होता है।')]),
        rank: 9000,
      );
      expect(out, isEmpty);
    });

    test('a bare gloss is not a description', () {
      final out = sets('wren', entry(senses: [sense('छोटी चिड़िया', 'एक छोटी चिड़िया।')]), rank: 9000);
      expect(out, isEmpty);
    });

    test('a verb is not a one-word substitution', () {
      final out = sets(
        'saunter',
        entry(senses: [sense('टहलना', 'ऐसी धीमी चाल जो बिना जल्दबाजी के हो।', pos: 'क्रिया')]),
        rank: 9000,
      );
      expect(out, isEmpty);
    });

    test('a phrase is left to the idioms list', () {
      expect(sets('spill the beans', entry(isPhrase: true), rank: 9000), isEmpty);
    });
  });
}
