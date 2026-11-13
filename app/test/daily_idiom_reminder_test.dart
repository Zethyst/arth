// When the day's idiom arrives, and which one it is.
import 'package:arth/core/models/contracts.dart';
import 'package:arth/data/daily_idiom_reminder.dart';
import 'package:arth/data/local_store.dart';
import 'package:arth/features/idioms/idiom_selection.dart';
import 'package:flutter_test/flutter_test.dart';

IdiomRow _idiom(String phrase, {int weight = 10}) => IdiomRow(
      phrase: phrase,
      senseIndex: 0,
      tags: const [],
      etymology: '',
      freqRank: 100,
      weight: weight,
      kind: IdiomKind.idiom,
      entry: DictionaryEntry(
        word: phrase,
        ipa: '',
        hindiPronunciation: '',
        senses: [
          Sense(
            index: 0,
            partOfSpeech: 'मुहावरा',
            meaning: 'अर्थ $phrase',
            definition: 'परिभाषा।',
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
  final idioms = [for (var i = 0; i < 60; i++) _idiom('idiom number $i', weight: 60 - i)];

  test('the first one is after now, not in the past', () {
    final now = DateTime(2026, 11, 13, 21, 30); // past the 20:00 slot
    final slots = planDailyIdioms(idioms: idioms, now: now);
    expect(slots.first.at, DateTime(2026, 11, 14, 20));
    for (final s in slots) {
      expect(s.at.isAfter(now), isTrue);
    }
  });

  test('today still counts if the hour has not come round yet', () {
    final slots = planDailyIdioms(idioms: idioms, now: DateTime(2026, 11, 13, 9));
    expect(slots.first.at, DateTime(2026, 11, 13, 20));
  });

  test('one a day, at the chosen hour', () {
    // 07:00 has already gone by at 09:00, so the run starts tomorrow.
    final slots = planDailyIdioms(idioms: idioms, now: DateTime(2026, 11, 13, 9), hour: 7, days: 5);
    expect(slots, hasLength(5));
    expect(slots.map((s) => s.at.hour).toSet(), {7});
    expect(slots.map((s) => s.at.day), [14, 15, 16, 17, 18]);
  });

  test('it is the same idiom the Today screen opens with', () {
    final day = DateTime(2026, 11, 14, 20);
    final slots = planDailyIdioms(idioms: idioms, now: DateTime(2026, 11, 13, 21));
    expect(slots.first.idiom.phrase, dailySet(idioms, day).first.phrase);
  });

  test('a different day brings a different idiom', () {
    final slots = planDailyIdioms(idioms: idioms, now: DateTime(2026, 11, 13, 9), days: 3);
    expect(slots.map((s) => s.idiom.phrase).toSet(), hasLength(greaterThan(1)));
  });

  test('a phone with no idioms schedules nothing', () {
    expect(planDailyIdioms(idioms: const [], now: DateTime(2026, 11, 13)), isEmpty);
  });

  test('a fortnight is planned, so the plugin is never overrun', () {
    final slots = planDailyIdioms(idioms: idioms, now: DateTime(2026, 11, 13, 9));
    expect(slots, hasLength(kIdiomDaysAhead));
    expect(kIdiomDaysAhead, lessThan(64), reason: 'iOS caps pending notifications at 64');
  });
}
