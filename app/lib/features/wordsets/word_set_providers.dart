// The synonyms, antonyms and one-word substitutions the phone holds, and the
// reader's progress through them.
//
// They are derived from the dictionary rather than downloaded, so the list
// is built the first time a reader opens them and again whenever a seed
// brings new words (dictionaryVersionProvider). Each set is a few thousand
// rows, read once and filtered in memory, as the idioms are.

import 'package:arth/app/providers.dart';
import 'package:arth/core/text/word_sets.dart';
import 'package:arth/data/local_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every item of one kind, commonest first.
final AsyncNotifierProviderFamily<WordSetNotifier, List<WordSetRow>, WordSetKind> wordSetsProvider =
    AsyncNotifierProvider.family<WordSetNotifier, List<WordSetRow>, WordSetKind>(WordSetNotifier.new);

class WordSetNotifier extends FamilyAsyncNotifier<List<WordSetRow>, WordSetKind> {
  @override
  Future<List<WordSetRow>> build(WordSetKind kind) async {
    // A new dictionary means new words to learn from.
    ref.watch(dictionaryVersionProvider);
    final store = ref.watch(localStoreProvider);
    final rows = await store.wordSets(kind);
    // Nothing yet: either this phone's dictionary arrived before these
    // existed, or a seed has just brought words that were never derived.
    // Deriving is a read of what is already here — under a second — so it
    // happens where the reader is already waiting for a list.
    if (rows.isEmpty && await store.entryCount() > 0) {
      await store.rebuildWordSets();
      return store.wordSets(kind);
    }
    return rows;
  }

  LocalStore get _store => ref.read(localStoreProvider);

  Future<void> setSaved(String id, {required bool saved}) async {
    await _store.setWordSetSaved(id, saved: saved);
    ref.invalidateSelf();
  }

  Future<void> markSeen(String id) async {
    await _store.markWordSetSeen(id);
    ref.invalidateSelf();
  }

  Future<void> recordAnswer(String id, {required bool correct}) async {
    await _store.recordWordSetAnswer(id, correct: correct);
    ref.invalidateSelf();
  }
}

/// The items of one kind the reader kept.
final AutoDisposeProviderFamily<List<WordSetRow>, WordSetKind> savedWordSetsProvider =
    Provider.autoDispose.family<List<WordSetRow>, WordSetKind>((ref, kind) {
  final all = ref.watch(wordSetsProvider(kind)).valueOrNull ?? const <WordSetRow>[];
  return [for (final i in all) if (i.saved) i];
});

/// How many of each kind the phone has, for the cards that lead to them.
final AutoDisposeFutureProviderFamily<int, WordSetKind> wordSetCountProvider =
    FutureProvider.autoDispose.family<int, WordSetKind>((ref, kind) async {
  final rows = await ref.watch(wordSetsProvider(kind).future);
  return rows.length;
});
