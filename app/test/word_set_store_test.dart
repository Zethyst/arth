// The word sets as the phone keeps them: derived from the entries already
// here, rebuilt when the dictionary changes, and progress that survives a
// rebuild.

import 'dart:convert';

import 'package:arth/core/text/word_sets.dart';
import 'package:arth/data/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

String entryJson({
  required String meaning,
  required String definition,
  List<Map<String, String>> synonyms = const [],
  List<Map<String, String>> antonyms = const [],
}) =>
    jsonEncode({
      'word': 'x',
      'ipa': '',
      'hindiPronunciation': '',
      'senses': [
        <String, dynamic>{'index': 0, 'partOfSpeech': 'संज्ञा', 'meaning': meaning, 'definition': definition, 'examples': const <Object>[]},
      ],
      'synonyms': synonyms,
      'antonyms': antonyms,
      'forms': const <Object>[],
      'isPhrase': false,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  var n = 0;

  Future<LocalStore> fresh() async {
    final path = '${await databaseFactoryFfi.getDatabasesPath()}/word_sets_${n++}.db';
    await databaseFactoryFfi.deleteDatabase(path);
    return LocalStore.openAt(path, factory: databaseFactoryFfi);
  }

  Future<LocalStore> seeded() async {
    final store = await fresh();
    await store.upsertSeed(
      entries: [
        (
          'brave',
          4000,
          entryJson(
            meaning: 'बहादुर',
            definition: 'जो डर के बावजूद आगे बढ़े और पीछे न हटे।',
            synonyms: [{'en': 'bold', 'hi': 'बहादुर'}],
            antonyms: [{'en': 'timid', 'hi': 'डरपोक'}],
          )
        ),
        ('bold', 3000, entryJson(meaning: 'निडर', definition: 'जो डरता न हो।')),
        ('timid', 6000, entryJson(meaning: 'डरपोक', definition: 'जो आसानी से डर जाए।')),
        (
          'penitentiary',
          9000,
          entryJson(meaning: 'जेल', definition: 'दोषी अपराधियों को रखने वाली सरकारी जेल।')
        ),
      ],
      forms: const [],
      phrases: const [],
    );
    await store.rebuildWordSets();
    return store;
  }

  test('the sets are derived from the entries, with nothing downloaded', () async {
    final store = await seeded();
    final synonyms = await store.wordSets(WordSetKind.synonym);
    expect(synonyms.single.word, 'brave');
    expect(synonyms.single.answer, 'bold');
    expect((await store.wordSets(WordSetKind.antonym)).single.answer, 'timid');
    final subs = await store.wordSets(WordSetKind.substitution);
    expect([for (final s in subs) s.word], contains('penitentiary'));
    expect(await store.wordSetCount(WordSetKind.synonym), 1);
  });

  test("progress is the reader's own and survives a rebuild", () async {
    final store = await seeded();
    const id = 'synonym:brave';
    await store.setWordSetSaved(id, saved: true);
    await store.recordWordSetAnswer(id, correct: true);
    await store.recordWordSetAnswer(id, correct: false);
    await store.markWordSetSeen(id, at: 1700);

    await store.rebuildWordSets();

    final row = (await store.wordSets(WordSetKind.synonym)).single;
    expect(row.saved, isTrue);
    expect(row.rightCount, 1);
    expect(row.wrongCount, 1);
    expect(row.seenAt, DateTime.fromMillisecondsSinceEpoch(1700));
  });

  test('a phone whose dictionary came before the sets gets them on upgrade', () async {
    // Every phone in the field: a v13 database, full of entries, with no
    // word_sets table. Opening it must derive the sets from what is there —
    // the reader does not download the dictionary again.
    final path = '${await databaseFactoryFfi.getDatabasesPath()}/word_sets_v13.db';
    await databaseFactoryFfi.deleteDatabase(path);
    final v13 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 13,
        onCreate: (db, _) async {
          await db.execute('CREATE TABLE entries (word TEXT PRIMARY KEY, freq_rank INTEGER NOT NULL, json TEXT NOT NULL)');
          await db.insert('entries', {
            'word': 'penitentiary',
            'freq_rank': 9000,
            'json': entryJson(meaning: 'जेल', definition: 'दोषी अपराधियों को रखने वाली सरकारी जेल।'),
          });
          await db.insert('entries', {
            'word': 'brave',
            'freq_rank': 4000,
            'json': entryJson(
              meaning: 'बहादुर',
              definition: 'जो डर के बावजूद आगे बढ़े।',
              synonyms: [{'en': 'bold', 'hi': 'बहादुर'}],
            ),
          });
          await db.insert('entries', {'word': 'bold', 'freq_rank': 3000, 'json': entryJson(meaning: 'निडर', definition: 'जो डरता न हो।')});
        },
      ),
    );
    await v13.close();

    final store = await LocalStore.openAt(path, factory: databaseFactoryFfi);
    expect((await store.wordSets(WordSetKind.synonym)).single.answer, 'bold');
    expect((await store.wordSets(WordSetKind.substitution)).single.word, 'penitentiary');
    await databaseFactoryFfi.deleteDatabase(path);
  });
}
