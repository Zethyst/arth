// ignore_for_file: leading_newlines_in_multiline_strings — schema fixtures read as one statement per string.

// Searching the dictionary the other way round: Hindi in, English out.
import 'dart:convert';

import 'package:arth/data/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

String _entry(String word, List<String> meanings) => jsonEncode({
      'word': word,
      'ipa': '',
      'hindiPronunciation': '',
      'senses': [
        for (var i = 0; i < meanings.length; i++)
          {
            'index': i,
            'partOfSpeech': 'संज्ञा',
            'meaning': meanings[i],
            'definition': 'कोई लंबी परिभाषा, जिसमें करना और होना जैसे आम शब्द आते हैं।',
            'examples': <Object>[],
          },
      ],
      'synonyms': <Object>[],
      'antonyms': <Object>[],
      'forms': <Object>[],
      'isPhrase': false,
    });

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  var n = 0;

  Future<LocalStore> withEntries(List<(String, int, List<String>)> rows) async {
    final path = '${await factory.getDatabasesPath()}/meaning_${n++}.db';
    await factory.deleteDatabase(path);
    final store = await LocalStore.openAt(path, factory: factory);
    await store.upsertSeed(
      entries: [for (final (w, rank, m) in rows) (w, rank, _entry(w, m))],
      forms: const [],
      phrases: const [],
    );
    return store;
  }

  group('what gets indexed', () {
    test('each word of a meaning is a term', () {
      final terms = meaningTerms(_entry('curry favor', ['खुशामद करना']));
      expect(terms, containsAll(<String>['खुशामद', 'करना']));
    });

    test('the danda and commas separate terms', () {
      final terms = meaningTerms(_entry('x', ['पता चलना, सामने आना।']));
      expect(terms, containsAll(<String>['पता', 'चलना', 'सामने', 'आना']));
    });

    test('only the first few senses are indexed', () {
      final many = [for (var i = 0; i < 25; i++) 'अर्थ$i'];
      final terms = meaningTerms(_entry('get', many));
      expect(terms, contains('अर्थ0'));
      expect(terms, contains('अर्थ${kIndexedSenses - 1}'));
      expect(terms, isNot(contains('अर्थ$kIndexedSenses')));
    });

    test('the long definition is not indexed, only the short meaning', () {
      // Otherwise every entry would answer to "करना".
      final terms = meaningTerms(_entry('x', ['लाइन तोड़ना']));
      expect(terms, isNot(contains('परिभाषा')));
      expect(terms, isNot(contains('होना')));
    });

    test('a single character is too short to index', () {
      expect(meaningTerms(_entry('x', ['क नया'])), isNot(contains('क')));
    });

    test('malformed JSON yields nothing rather than throwing', () {
      expect(meaningTerms('{not json'), isEmpty);
    });
  });

  group('a phone that already had the dictionary', () {
    // The index is built from entries that are already on the phone, so
    // nobody has to download 70 MB again to get the other search direction.
    test('upgrading from v12 backfills the index from what is there', () async {
      final path = '${await factory.getDatabasesPath()}/meaning_upgrade.db';
      await factory.deleteDatabase(path);
      final v12 = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 12,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE entries (word TEXT PRIMARY KEY, freq_rank INTEGER NOT NULL, json TEXT NOT NULL)',
            );
            // A real v12 database carries the idioms tables too.
            await db.execute('''CREATE TABLE idioms (phrase TEXT PRIMARY KEY, sense_index INTEGER NOT NULL DEFAULT 0,
              tags TEXT NOT NULL DEFAULT '', etymology TEXT NOT NULL DEFAULT '', freq_rank INTEGER NOT NULL,
              weight INTEGER NOT NULL DEFAULT 0)''');
            await db.execute('''CREATE TABLE idiom_progress (phrase TEXT PRIMARY KEY, saved INTEGER NOT NULL DEFAULT 0,
              seen_at INTEGER, right_count INTEGER NOT NULL DEFAULT 0, wrong_count INTEGER NOT NULL DEFAULT 0)''');
            await db.insert('entries', {
              'word': 'curry favor',
              'freq_rank': 300,
              'json': _entry('curry favor', ['खुशामद करना']),
            });
          },
        ),
      );
      await v12.close();
      final store = await LocalStore.openAt(path, factory: factory);
      expect(await store.searchMeanings('खुशामद'), ['curry favor']);
      await factory.deleteDatabase(path);
    });
  });

  group('searching in Hindi', () {
    test('finds the English word from its Hindi meaning', () async {
      final store = await withEntries([
        ('curry favor', 300, ['खुशामद करना']),
        ('night owl', 400, ['रात में जागने वाला']),
      ]);
      expect(await store.searchMeanings('खुशामद'), ['curry favor']);
      expect(await store.searchMeanings('रात'), ['night owl']);
    });

    test('matches on a prefix, as the reader types', () async {
      final store = await withEntries([('curry favor', 300, ['खुशामद करना'])]);
      expect(await store.searchMeanings('खुशा'), ['curry favor']);
    });

    test('the commonest word comes first', () async {
      final store = await withEntries([
        ('rare word', 9000, ['पता चलना']),
        ('common word', 100, ['पता लगाना']),
      ]);
      expect(await store.searchMeanings('पता'), ['common word', 'rare word']);
    });

    test('a word is listed once however many senses match', () async {
      final store = await withEntries([
        ('get', 50, ['पाना', 'पा लेना', 'पाना शुरू करना']),
      ]);
      expect(await store.searchMeanings('पा'), ['get']);
    });

    test('one character searches nothing, to keep the dropdown sane', () async {
      final store = await withEntries([('curry favor', 300, ['खुशामद करना'])]);
      expect(await store.searchMeanings('ख'), isEmpty);
    });

    test('a meaning nobody wrote finds nothing', () async {
      final store = await withEntries([('curry favor', 300, ['खुशामद करना'])]);
      expect(await store.searchMeanings('बिल्ली'), isEmpty);
    });
  });
}
