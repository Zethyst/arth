// The idioms the phone holds, and the reader's own progress through them.
//
// There are a few hundred, all offline, so the whole list is read once and
// every screen filters it in memory. An action that changes progress
// (saving, seeing, answering) rewrites the row and invalidates the list, so
// every screen showing it updates at once.

import 'dart:async';

import 'package:arth/app/providers.dart';
import 'package:arth/data/local_store.dart';
import 'package:arth/features/idioms/idiom_selection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every idiom on the phone, commonest first.
final AsyncNotifierProvider<IdiomsNotifier, List<IdiomRow>> idiomsProvider =
    AsyncNotifierProvider<IdiomsNotifier, List<IdiomRow>>(IdiomsNotifier.new);

class IdiomsNotifier extends AsyncNotifier<List<IdiomRow>> {
  @override
  Future<List<IdiomRow>> build() => ref.watch(localStoreProvider).allIdioms();

  LocalStore get _store => ref.read(localStoreProvider);

  Future<void> setSaved(String phrase, {required bool saved}) async {
    await _store.setIdiomSaved(phrase, saved: saved);
    ref.invalidateSelf();
  }

  Future<void> markSeen(String phrase) async {
    await _store.markIdiomSeen(phrase);
    ref.invalidateSelf();
  }

  Future<void> recordAnswer(String phrase, {required bool correct}) async {
    await _store.recordIdiomAnswer(phrase, correct: correct);
    ref.invalidateSelf();
  }
}

/// Today's set, in the reader's own local day.
final AutoDisposeProvider<List<IdiomRow>> dailyIdiomsProvider = Provider.autoDispose<List<IdiomRow>>((ref) {
  final all = ref.watch(idiomsProvider).valueOrNull ?? const <IdiomRow>[];
  return dailySet(all, DateTime.now());
});

/// The idioms the reader kept.
final AutoDisposeProvider<List<IdiomRow>> savedIdiomsProvider = Provider.autoDispose<List<IdiomRow>>((ref) {
  final all = ref.watch(idiomsProvider).valueOrNull ?? const <IdiomRow>[];
  return [for (final i in all) if (i.saved) i];
});

/// One idiom by its phrase, for the detail screen.
final AutoDisposeProviderFamily<IdiomRow?, String> idiomProvider =
    Provider.autoDispose.family<IdiomRow?, String>((ref, phrase) {
  final all = ref.watch(idiomsProvider).valueOrNull ?? const <IdiomRow>[];
  for (final i in all) {
    if (i.phrase == phrase) return i;
  }
  return null;
});
