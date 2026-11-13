// The tap flow (Section 7), in order: phrase match (local, then API) →
// local lookup → API lookup. Context and translation are separate calls the
// UI fires in parallel with rendering.

import 'package:arth/core/models/contracts.dart';
import 'package:arth/core/text/phrase_windows.dart';
import 'package:arth/core/text/related_phrases.dart';
import 'package:arth/data/api_client.dart';
import 'package:arth/data/lemma.dart';
import 'package:arth/data/local_store.dart';

enum LookupSource { local, api }

sealed class LookupOutcome {
  const LookupOutcome();
}

class LookupFound extends LookupOutcome {
  const LookupFound({
    required this.entry,
    required this.lemma,
    required this.source,
    this.phrase,
  });

  final DictionaryEntry entry;
  final String lemma;
  final LookupSource source;

  /// Set when a multi-word phrase covered the tapped token.
  final PhraseMatch? phrase;
}

class LookupMissing extends LookupOutcome {
  const LookupMissing({
    required this.word,
    required this.suggestions,
    required this.offline,
    this.blockedCode,
  });

  final String word;
  final List<String> suggestions;

  /// True when the API could not be reached, so the miss may just be
  /// "not in the top 20k" rather than "not a word".
  final bool offline;

  /// `UNAUTHORIZED` / `QUOTA_EXCEEDED`: the word exists but its entry would
  /// have to be written by AI, which needs sign-in or allowance.
  final String? blockedCode;
}

class _LocalSource implements LemmaSource {
  _LocalSource(this.store);

  final LocalStore store;

  @override
  Future<DictionaryEntry?> entry(String word) => store.entry(word);

  @override
  Future<String?> formLemma(String form) => store.formLemma(form);
}

class DictionaryRepo {
  DictionaryRepo({required this.store, required this.api})
      : _local = _LocalSource(store);

  final LocalStore store;
  final ApiClient api;
  final _LocalSource _local;
  List<String>? _vocabulary;

  /// The entry for [word] from the phone's own dictionary, following forms
  /// (wives → wife), or null when this phone doesn't have it. Never asks the
  /// API: callers that want the network use [lookupWord].
  Future<DictionaryEntry?> localEntry(String word) async {
    final key = word.trim().toLowerCase();
    if (key.isEmpty) return null;
    return (await resolveLemma(_local, key))?.entry;
  }

  /// Full tap flow for the token at [index] within [tokens] (normalized keys).
  Future<LookupOutcome> lookupAt(List<String> tokens, int index) async {
    final key = tokens[index];
    if (key.isEmpty) {
      return const LookupMissing(word: '', suggestions: [], offline: false);
    }

    // 1. Phrase: local windows, longest first. One query fetches every stored
    // phrase that could match any of them, because a phrase with a slot in it
    // ("change one's mind") never matches a window literally and has to be
    // compared token by token.
    final windows = phraseWindows(tokens, index);
    final candidates = await store.phraseCandidates(candidateFirstTokens(windows));
    final literal = {for (final c in candidates) c.phrase: c.lemma};
    final patterns = [for (final c in candidates) if (isPhrasePattern(c.phrase)) c];
    for (final w in windows) {
      var lemma = literal[w.phrase];
      if (lemma == null) {
        for (final c in patterns) {
          if (patternMatches(c.phrase, w.tokens)) {
            lemma = c.lemma;
            break;
          }
        }
      }
      if (lemma == null) continue;
      final entry = await store.entry(lemma) ?? await _apiEntry(lemma);
      if (entry != null) {
        return LookupFound(
          entry: entry,
          lemma: lemma,
          source: LookupSource.local,
          phrase: PhraseMatch(
            phrase: w.phrase,
            lemma: lemma,
            start: w.start,
            tokenCount: w.tokenCount,
          ),
        );
      }
    }

    // 2. Local single word.
    final local = await resolveLemma(_local, key);
    if (local != null) {
      // A phrase the local table doesn't know might still exist on the server;
      // but the spec's order puts speed first: show the word now, and let the
      // server's phrase check ride along with /context (Phase 3).
      return LookupFound(
        entry: local.entry,
        lemma: local.lemma,
        source: LookupSource.local,
      );
    }

    // 3. API: phrase first, then word (which may be generated on demand).
    var offline = false;
    String? blocked;
    var serverSuggestions = const <String>[];
    try {
      if (windows.isNotEmpty) {
        final m = await api.matchPhrase(tokens: tokens, index: index);
        if (m != null) {
          final entry = await _apiEntry(m.lemma);
          if (entry != null) {
            return LookupFound(
              entry: entry,
              lemma: m.lemma,
              source: LookupSource.api,
              phrase: m,
            );
          }
        }
      }
      final r = await api.lookup(key);
      if (r.entry != null) {
        return LookupFound(
          entry: r.entry!,
          lemma: r.entry!.word,
          source: LookupSource.api,
        );
      }
      serverSuggestions = r.suggestions;
    } on ApiFailure catch (e) {
      offline = e.isOffline;
      if (aiBlockCodes.contains(e.code)) blocked = e.code;
    }

    return LookupMissing(
      word: key,
      suggestions: _merge(serverSuggestions, await suggestions(key)),
      offline: offline,
      blockedCode: blocked,
    );
  }

  /// Server suggestions (morphology: brimless → brim) first, then local
  /// spelling neighbours, deduplicated.
  static List<String> _merge(List<String> server, List<String> local) {
    final out = <String>[...server];
    for (final s in local) {
      if (!out.contains(s)) out.add(s);
    }
    return out.take(5).toList();
  }

  /// Direct headword lookup (dictionary screen, saved words).
  Future<LookupOutcome> lookupWord(String word) async {
    final key = word.trim().toLowerCase();
    final local = await resolveLemma(_local, key);
    if (local != null) {
      return LookupFound(
        entry: local.entry,
        lemma: local.lemma,
        source: LookupSource.local,
      );
    }
    var offline = false;
    String? blocked;
    var serverSuggestions = const <String>[];
    try {
      final r = await api.lookup(key);
      if (r.entry != null) {
        return LookupFound(
          entry: r.entry!,
          lemma: r.entry!.word,
          source: LookupSource.api,
        );
      }
      serverSuggestions = r.suggestions;
    } on ApiFailure catch (e) {
      offline = e.isOffline;
      if (aiBlockCodes.contains(e.code)) blocked = e.code;
    }
    return LookupMissing(
      word: key,
      suggestions: _merge(serverSuggestions, await suggestions(key)),
      offline: offline,
      blockedCode: blocked,
    );
  }

  /// The idioms and phrasal verbs built on [lemma], for its word screen.
  /// On-device first — nearly every phrase is in the seed — and the API only
  /// when this phone has no dictionary yet or knows no phrase for the word.
  /// Never an error: an empty list is the normal answer for most words.
  Future<List<RelatedPhrase>> phrasesFor(String lemma) async {
    final key = lemma.trim().toLowerCase();
    if (key.isEmpty || key.contains(' ')) return const [];
    final local = <RelatedPhrase>[];
    for (final phrase in await store.phrasesUsing(key)) {
      final entry = await store.entry(phrase);
      final sense = entry?.senses.firstOrNull;
      if (sense == null) continue;
      local.add(
        RelatedPhrase(
          phrase: phrase,
          kind: phraseKind(key, phrase),
          partOfSpeech: sense.partOfSpeech,
          meaning: sense.meaning,
        ),
      );
    }
    if (local.isNotEmpty) return sortPhrases(local);
    try {
      return sortPhrases(await api.phrasesOf(key));
    } on ApiFailure {
      return const [];
    }
  }

  Future<DictionaryEntry?> _apiEntry(String lemma) async {
    try {
      return (await api.lookup(lemma)).entry;
    } on ApiFailure {
      return null;
    }
  }

  Future<List<String>> suggestions(String word) async {
    _vocabulary ??= await store.allWords();
    return suggest(word, _vocabulary!);
  }

  /// Step 4 of the tap flow. Throws [ApiFailure]; callers keep the entry.
  Future<ContextResult> contextFor({
    required String word,
    required String sentence,
    bool prefetch = false,
  }) =>
      api.context(word: word, sentence: sentence, prefetch: prefetch);

  Stream<SseEvent> translate({required String text, String? context}) =>
      api.translate(text: text, context: context);
}
