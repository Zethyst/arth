// ignore_for_file: leading_newlines_in_multiline_strings — schema fixtures read as one statement per string.

import 'dart:convert';

import 'package:arth/core/text/phrase_windows.dart';
import 'package:arth/data/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The shape of an entry's JSON, which `allIdioms` decodes after the join.
String _entryJson(String phrase) => jsonEncode({
      'word': phrase,
      'ipa': '',
      'hindiPronunciation': '',
      'senses': [
        {
          'index': 0,
          'partOfSpeech': 'मुहावरा',
          'meaning': 'अर्थ',
          'definition': 'परिभाषा।',
          'examples': <Object>[],
        },
      ],
      'synonyms': <Object>[],
      'antonyms': <Object>[],
      'forms': <Object>[],
      'isPhrase': true,
    });

void main() {
  _matchingInText();
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  var n = 0;

  Future<LocalStore> fresh() async {
    final path = '${await factory.getDatabasesPath()}/idiom_store_${n++}.db';
    await factory.deleteDatabase(path);
    return LocalStore.openAt(path, factory: factory);
  }

  Future<void> seed(LocalStore store, List<(String, int, int)> rows) => store.upsertSeed(
        entries: [for (final (phrase, _, _) in rows) (phrase, 100, _entryJson(phrase))],
        forms: const [],
        phrases: const [],
        idioms: [for (final (phrase, rank, weight) in rows) (phrase, 0, '', '', rank, weight, 'idiom')],
      );

  group('idioms on the phone', () {
    test('a seed keeps the weight, and the best known comes back first', () async {
      final store = await fresh();
      await seed(store, [
        ('red face test', 2028, 0),
        ('crocodile tear', 900, 117),
        ('piece of cake', 1144, 68),
      ]);
      final all = await store.allIdioms();
      expect(all.map((i) => i.phrase), ['crocodile tear', 'piece of cake', 'red face test']);
      expect(all.first.weight, 117);
      expect(await store.idiomCount(), 3);
    });

    test('equal weights fall back to the rank, then the phrase', () async {
      final store = await fresh();
      await seed(store, [('b idiom', 50, 4), ('a idiom', 50, 4), ('rare idiom', 90, 4)]);
      final all = await store.allIdioms();
      expect(all.map((i) => i.phrase), ['a idiom', 'b idiom', 'rare idiom']);
    });

    test('a later seed replaces a row rather than doubling it', () async {
      final store = await fresh();
      await seed(store, [('night owl', 300, 5)]);
      await seed(store, [('night owl', 300, 67)]);
      final all = await store.allIdioms();
      expect(all, hasLength(1));
      expect(all.single.weight, 67);
    });
  });

  group('upgrading', () {
    // A version-11 database has the idioms table without `weight`. Adding the
    // column there must not collide with _createIdioms, which now builds the
    // table with it for anything older.
    Future<String> v11At(String name) async {
      final path = '${await factory.getDatabasesPath()}/$name.db';
      await factory.deleteDatabase(path);
      final db = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 11,
          onCreate: (db, _) async {
            await db.execute('''CREATE TABLE books (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, path TEXT NOT NULL UNIQUE,
              kind TEXT NOT NULL DEFAULT 'pdf', added_at INTEGER NOT NULL, page_count INTEGER, last_page INTEGER NOT NULL DEFAULT 1,
              last_opened_at INTEGER, progress REAL, finished_at INTEGER, content_key TEXT, archived INTEGER NOT NULL DEFAULT 0,
              category_group TEXT, category TEXT)''');
            await db.execute('''CREATE TABLE entries (word TEXT PRIMARY KEY, freq_rank INTEGER NOT NULL, json TEXT NOT NULL)''');
            await db.execute('''CREATE TABLE idioms (phrase TEXT PRIMARY KEY, sense_index INTEGER NOT NULL DEFAULT 0,
              tags TEXT NOT NULL DEFAULT '', etymology TEXT NOT NULL DEFAULT '', freq_rank INTEGER NOT NULL)''');
            await db.execute('CREATE INDEX idioms_rank ON idioms(freq_rank)');
            await db.execute('''CREATE TABLE idiom_progress (phrase TEXT PRIMARY KEY, saved INTEGER NOT NULL DEFAULT 0,
              seen_at INTEGER, right_count INTEGER NOT NULL DEFAULT 0, wrong_count INTEGER NOT NULL DEFAULT 0)''');
            await db.insert('entries', {'word': 'night owl', 'freq_rank': 300, 'json': _entryJson('night owl')});
            await db.insert('idioms', {'phrase': 'night owl', 'freq_rank': 300});
            await db.insert('idiom_progress', {'phrase': 'night owl', 'saved': 1});
          },
        ),
      );
      await db.close();
      return path;
    }

    test('a version-11 database keeps its idioms, weighing nothing until the next seed', () async {
      final path = await v11At('idiom_v11');
      final store = await LocalStore.openAt(path, factory: factory);
      final all = await store.allIdioms();
      expect(all.single.phrase, 'night owl');
      expect(all.single.weight, 0, reason: 'no weight has been sent yet');
      expect(all.single.saved, isTrue, reason: 'the reader keeps their own progress');
      await factory.deleteDatabase(path);
    });

    test('a seed after the upgrade fills the weight in', () async {
      final path = await v11At('idiom_v11_seeded');
      final store = await LocalStore.openAt(path, factory: factory);
      await seed(store, [('night owl', 300, 67)]);
      expect((await store.allIdioms()).single.weight, 67);
      await factory.deleteDatabase(path);
    });
  });
}

/// The reader taps a word inside an idiom: the store has to offer the phrase
/// as a candidate, and the matcher has to recognise it.
void _matchingInText() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  var n = 0;

  Future<LocalStore> withPhrases(List<String> phrases) async {
    final path = '${await factory.getDatabasesPath()}/phrase_match_${n++}.db';
    await factory.deleteDatabase(path);
    final store = await LocalStore.openAt(path, factory: factory);
    await store.upsertSeed(
      entries: [for (final p in phrases) (p, 100, _entryJson(p))],
      forms: const [],
      phrases: [
        for (final p in phrases) (p, p, p.split(' ').first, p.split(' ').length),
      ],
    );
    return store;
  }

  /// What DictionaryRepo.lookupAt does with the candidates, in miniature.
  String? match(List<({String phrase, String lemma})> candidates, List<String> tokens, int index) {
    final literal = {for (final c in candidates) c.phrase: c.lemma};
    final patterns = [for (final c in candidates) if (isPhrasePattern(c.phrase)) c];
    for (final w in phraseWindows(tokens, index)) {
      final hit = literal[w.phrase];
      if (hit != null) return hit;
      for (final c in patterns) {
        if (patternMatches(c.phrase, w.tokens)) return c.lemma;
      }
    }
    return null;
  }

  group('finding an idiom in a sentence', () {
    test('a seven-token idiom is reachable from a tap inside it', () async {
      final store = await withPhrases(['let the cat out of the bag']);
      const sentence = ['she', 'let', 'the', 'cat', 'out', 'of', 'the', 'bag'];
      final windows = phraseWindows(sentence, 3); // tapped `cat`
      final candidates = await store.phraseCandidates(candidateFirstTokens(windows));
      expect(match(candidates, sentence, 3), 'let the cat out of the bag');
    });

    test('an idiom with a slot is reachable, though it never appears literally', () async {
      final store = await withPhrases(["change one's mind"]);
      const sentence = ['he', 'might', 'change', 'his', 'mind', 'later'];
      final windows = phraseWindows(sentence, 2);
      final candidates = await store.phraseCandidates(candidateFirstTokens(windows));
      expect(match(candidates, sentence, 2), "change one's mind");
    });

    test('one query covers every window', () async {
      final store = await withPhrases(['let the cat out of the bag', 'in want of']);
      const sentence = ['she', 'let', 'the', 'cat', 'out', 'of', 'the', 'bag'];
      final candidates = await store.phraseCandidates(
        candidateFirstTokens(phraseWindows(sentence, 3)),
      );
      // Only phrases that could start a window come back, not the whole table.
      expect(candidates.map((c) => c.phrase), contains('let the cat out of the bag'));
      expect(candidates.map((c) => c.phrase), isNot(contains('in want of')));
    });

    test('a sentence that is not the idiom matches nothing', () async {
      final store = await withPhrases(["change one's mind"]);
      const sentence = ['he', 'might', 'change', 'his', 'shirt'];
      final candidates = await store.phraseCandidates(
        candidateFirstTokens(phraseWindows(sentence, 2)),
      );
      expect(match(candidates, sentence, 2), isNull);
    });
  });
}
