import 'package:arth/core/models/contracts.dart';
import 'package:arth/data/local_store.dart';
import 'package:arth/features/idioms/idiom_selection.dart';
import 'package:arth/features/idioms/idioms_browse_screen.dart';
import 'package:flutter_test/flutter_test.dart';

IdiomRow _idiom(
  String phrase, {
  int senseIndex = 0,
  DateTime? seenAt,
  bool saved = false,
  int right = 0,
  int wrong = 0,
  List<String> tags = const [],
  int weight = 0,
  int freqRank = 100,
  IdiomKind kind = IdiomKind.idiom,
}) =>
    IdiomRow(
      phrase: phrase,
      senseIndex: senseIndex,
      tags: tags,
      etymology: '',
      freqRank: freqRank,
      weight: weight,
      kind: kind,
      saved: saved,
      seenAt: seenAt,
      rightCount: right,
      wrongCount: wrong,
      entry: DictionaryEntry(
        word: phrase,
        ipa: '',
        hindiPronunciation: '',
        senses: [
          for (var i = 0; i <= senseIndex; i++)
            Sense(
              index: i,
              partOfSpeech: 'मुहावरा',
              meaning: i == senseIndex ? 'अर्थ $phrase' : 'शाब्दिक $phrase',
              definition: 'परिभाषा $phrase।',
              examples: const [],
            ),
        ],
        synonyms: const [],
        antonyms: const [],
        forms: const [],
        isPhrase: true,
      ),
    );

void main() {
  group('IdiomRow', () {
    test('the meaning is the idiomatic sense, not always the first', () {
      expect(_idiom('peanut butter', senseIndex: 1).meaning, 'अर्थ peanut butter');
      expect(_idiom('peanut butter', senseIndex: 1).sense.index, 1);
    });

    test('an entry shorter than the pointer falls back rather than crashing', () {
      final row = _idiom('x');
      final broken = IdiomRow(
        phrase: 'x',
        senseIndex: 9,
        tags: const [],
        etymology: '',
        freqRank: 1,
        weight: 0,
        kind: IdiomKind.idiom,
        entry: row.entry,
      );
      expect(broken.sense.index, 0);
    });
  });

  group('dailySet', () {
    final all = [for (var i = 0; i < 40; i++) _idiom('idiom $i')];

    test('the same day gives the same ten, however often it is asked', () {
      final day = DateTime(2026, 11, 12);
      expect(dailySet(all, day).map((i) => i.phrase), dailySet(all, day).map((i) => i.phrase));
      expect(dailySet(all, day), hasLength(kDailyIdioms));
    });

    test('a different day gives a different ten', () {
      final a = dailySet(all, DateTime(2026, 11, 12)).map((i) => i.phrase).toSet();
      final b = dailySet(all, DateTime(2026, 11, 13)).map((i) => i.phrase).toSet();
      expect(a, isNot(b));
    });

    test("the day's ten come from the best known unseen, not the whole list", () {
      // Well-known idioms fill the pool the day's ten is drawn from, so none
      // of the obscure ones get in however many of them there are.
      final mixed = [
        for (var i = 0; i < 400; i++) _idiom('obscure phrase $i'),
        for (var i = 0; i < kDailyIdioms * kDailyPoolFactor; i++)
          _idiom('known idiom $i', weight: 50),
      ];
      final set = dailySet(mixed, DateTime(2026, 11, 12));
      expect(set.every((i) => i.phrase.startsWith('known')), isTrue);
    });

    test('grammar is never the idiom of the day, however well known', () {
      // "by the way" is translated into more languages than any real idiom
      // here, so leaving it in the draw would make it today's card.
      final mixed = [
        _idiom('by the way', weight: 127),
        _idiom('at last', weight: 96),
        for (var i = 0; i < 30; i++) _idiom('night owl $i', weight: 5),
      ];
      final set = dailySet(mixed, DateTime(2026, 11, 12));
      expect(set.map((i) => i.phrase), everyElement(startsWith('night owl')));
    });

    test('unseen idioms come before ones already met', () {
      final seen = DateTime(2026);
      final mixed = [
        for (var i = 0; i < 6; i++) _idiom('seen $i', seenAt: seen),
        for (var i = 0; i < 4; i++) _idiom('fresh $i'),
      ];
      final set = dailySet(mixed, DateTime(2026, 11, 12));
      expect(set.take(4).map((i) => i.phrase.startsWith('fresh')), everyElement(isTrue));
    });

    test('once everything has been seen the longest-ago ones come round again', () {
      final old = _idiom('night owl', seenAt: DateTime(2020));
      final recent = _idiom('spill the beans', seenAt: DateTime(2026, 11));
      expect(dailySet([recent, old], DateTime(2026, 11, 12)).first.phrase, 'night owl');
    });

    test('grammar met while browsing does not come back as a daily card', () {
      final rows = [
        _idiom('by the way', seenAt: DateTime(2020)),
        _idiom('night owl', seenAt: DateTime(2026, 11)),
      ];
      expect(dailySet(rows, DateTime(2026, 11, 12)).map((i) => i.phrase), ['night owl']);
    });

    test('an empty dictionary gives an empty set', () {
      expect(dailySet(const [], DateTime(2026, 11, 12)), isEmpty);
    });

    test('fewer idioms than a set wants gives all of them', () {
      final few = [_idiom('night owl'), _idiom('spill the beans')];
      expect(dailySet(few, DateTime(2026, 11, 12)), hasLength(2));
    });
  });

  group('buildPractice', () {
    final all = [for (var i = 0; i < 20; i++) _idiom('idiom $i')];

    test('every question offers the right answer among its options', () {
      for (final q in buildPractice(all, 7)) {
        expect(q.options, hasLength(kPracticeOptions));
        expect(q.correctOption, q.idiom.meaning);
        expect(q.options.toSet(), hasLength(kPracticeOptions), reason: 'no repeated options');
      }
    });

    test('a round is as long as asked, and the same seed rebuilds it', () {
      expect(buildPractice(all, 7), hasLength(kPracticeQuestions));
      expect(
        buildPractice(all, 7).map((q) => q.idiom.phrase),
        buildPractice(all, 7).map((q) => q.idiom.phrase),
      );
    });

    test('idioms the reader keeps getting wrong are asked first', () {
      final pool = [
        for (var i = 0; i < 10; i++) _idiom('easy idiom $i', right: 5),
        _idiom('hard idiom', wrong: 4),
      ];
      expect(buildPractice(pool, 1).first.idiom.phrase, 'hard idiom');
    });

    test('among idioms never practised, the best known is asked first', () {
      // All tie at 0 right and 0 wrong, so without weight this is a coin toss
      // across every idiom on the phone.
      final pool = [
        for (var i = 0; i < 40; i++) _idiom('obscure idiom $i'),
        _idiom('spill the beans', weight: 68),
      ];
      expect(buildPractice(pool, 7).first.idiom.phrase, 'spill the beans');
    });

    test('grammar is not quizzed while there are idioms to ask about', () {
      final pool = [
        _idiom('by the way', weight: 127),
        for (var i = 0; i < 10; i++) _idiom('night owl $i'),
      ];
      final asked = buildPractice(pool, 3).map((q) => q.idiom.phrase);
      expect(asked, isNot(contains('by the way')));
    });

    test('too few idioms for a fair question gives no round at all', () {
      expect(buildPractice([_idiom('a'), _idiom('b')], 1), isEmpty);
    });
  });

  _ordering();
  _phrasalVerbs();

  group('filterIdioms', () {
    final all = [_idiom('night owl', saved: true), _idiom('spill the beans')];

    test('matches the English phrase', () {
      expect(filterIdioms(all, 'owl').map((i) => i.phrase), ['night owl']);
    });

    test('matches the Hindi meaning', () {
      expect(filterIdioms(all, 'अर्थ spill').map((i) => i.phrase), ['spill the beans']);
    });

    test('an empty query keeps everything, in order', () {
      expect(filterIdioms(all, '  '), hasLength(2));
    });

    test('saved-only narrows to what the reader kept', () {
      expect(filterIdioms(all, '', savedOnly: true).map((i) => i.phrase), ['night owl']);
    });
  });
}

void _ordering() {
  group('idiomaticity', () {
    test('counts the words that carry meaning on their own', () {
      expect(idiomaticity('night owl'), 2);
      expect(idiomaticity('spill the beans'), 2);
      expect(idiomaticity('cast pearls before swine'), 3);
    });

    test('a phrase that is mostly grammar scores low', () {
      expect(idiomaticity('at first'), 1);
      expect(idiomaticity('by the way'), 1);
      expect(idiomaticity('no way'), 1);
    });

    test('a repeated word counts again, because the repetition is the idiom', () {
      expect(idiomaticity('eye for an eye'), 2);
      expect(idiomaticity('from time to time'), 2);
      expect(idiomaticity('neck and neck'), 2);
    });

    test('the floor admits an idiom and rejects a construction', () {
      expect(isTeachable(_idiom('spill the beans')), isTrue);
      expect(isTeachable(_idiom('eye for an eye')), isTrue);
      expect(isTeachable(_idiom('at first')), isFalse);
      expect(isTeachable(_idiom('on purpose')), isFalse);
    });
  });

  test('browse order puts real idioms ahead of grammar', () {
    final rows = [
      _idiom('at first', weight: 73),
      _idiom('spill the beans', weight: 68),
      _idiom('by the way', weight: 127),
      _idiom('night owl', weight: 67),
    ]..sort(compareForBrowsing);
    // Both constructions are better translated than either idiom, and both
    // still sort below them.
    expect(rows.take(2).map((i) => i.phrase).toSet(), {'spill the beans', 'night owl'});
  });

  test('among idioms, the best known comes first', () {
    final rows = [
      _idiom('red face test'),
      _idiom('piece of cake', weight: 68),
      _idiom('crocodile tear', weight: 117),
    ]..sort(compareForBrowsing);
    expect(
      rows.map((i) => i.phrase),
      ['crocodile tear', 'piece of cake', 'red face test'],
    );
  });

  test('the rank of the rarest word does not decide the order', () {
    // "keep good time" is built from commoner words than "spill the beans",
    // so ordering by freqRank would put the collocation first.
    final rows = [
      _idiom('keep good time', weight: 2, freqRank: 206),
      _idiom('spill the beans', weight: 68, freqRank: 3140),
    ]..sort(compareForBrowsing);
    expect(rows.first.phrase, 'spill the beans');
  });

  test('a phone whose seed predates weight still orders sensibly', () {
    // Every weight is 0 until the next seed, and freqRank breaks the tie.
    final rows = [
      _idiom('zebra crossing', freqRank: 900),
      _idiom('night owl', freqRank: 300),
      _idiom('at first', freqRank: 10),
    ]..sort(compareForBrowsing);
    expect(rows.map((i) => i.phrase), ['night owl', 'zebra crossing', 'at first']);
  });

  test('today’s set is drawn only from the idioms, not the grammar', () {
    // Each of these uses one meaning-carrying word; the idiom uses two.
    final all = [
      for (final p in ['at first', 'by the way', 'no way', 'at last', 'in the know'])
        _idiom(p),
      _idiom('spill the beans'),
    ];
    expect(dailySet(all, DateTime(2026, 11, 12)).map((i) => i.phrase), ['spill the beans']);
  });
}

void _phrasalVerbs() {
  group('phrasal verbs on the idioms screen', () {
    // "give up" scores 1 on idiomaticity, because "up" is a function word —
    // exactly the shape the floor rejects. It is not grammar, though.
    test('a phrasal verb is taught even though it scores below the floor', () {
      final pv = _idiom('give up', kind: IdiomKind.phrasal);
      expect(idiomaticity('give up'), lessThan(kMinIdiomaticity));
      expect(isTeachable(pv), isTrue);
    });

    test('the same shape without the marking is still grammar', () {
      expect(isTeachable(_idiom('at first')), isFalse);
    });

    test('a phrasal verb can be the idiom of the day', () {
      final all = [
        _idiom('by the way', weight: 127),
        _idiom('give up', weight: 40, kind: IdiomKind.phrasal),
      ];
      expect(dailySet(all, DateTime(2026, 11, 13)).map((i) => i.phrase), ['give up']);
    });

    test('browse can be narrowed to them, or show both', () {
      final all = [
        _idiom('spill the beans', weight: 68),
        _idiom('give up', weight: 40, kind: IdiomKind.phrasal),
      ];
      expect(filterIdioms(all, '', kind: IdiomKind.phrasal).map((i) => i.phrase), ['give up']);
      expect(filterIdioms(all, '', kind: IdiomKind.idiom).map((i) => i.phrase), ['spill the beans']);
      expect(filterIdioms(all, ''), hasLength(2));
    });
  });
}
