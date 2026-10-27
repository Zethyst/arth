// Dictionary tab: search (a dropdown of suggestions as you type: recent
// lookups, words on the device, close spellings; full lookup on submit),
// recent lookups, and a word of the day.

import 'dart:async';

import 'package:arth/app/account_providers.dart';
import 'package:arth/app/feel.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/core/models/contracts.dart';
import 'package:arth/data/dictionary_repo.dart';
import 'package:arth/features/dictionary/entry_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final wordOfTheDayProvider = FutureProvider<DictionaryEntry?>((ref) async {
  final store = ref.watch(localStoreProvider);
  final words = await store.searchWords('', limit: 5000);
  if (words.isEmpty) return null;
  // Deterministic per day, skewed away from the very top (function words).
  final day = DateTime.now().difference(DateTime(2026)).inDays;
  final pool = words.length > 800 ? words.sublist(800) : words;
  return store.entry(pool[day % pool.length]);
});

class DictionaryScreen extends ConsumerStatefulWidget {
  const DictionaryScreen({super.key});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  bool _busy = false;

  /// Nothing on the device starts with what's typed (shown under the field).
  bool _noMatches = false;

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// The dropdown under the search field: recent lookups that fit, words that
  /// start with what's typed (commonest first), and when those run short,
  /// close spellings. Each with its first Hindi meaning.
  Future<List<_Suggestion>> _suggestionsFor(String typed) async {
    final q = typed.trim().toLowerCase();
    if (q.isEmpty) {
      _setNoMatches(false);
      return const [];
    }
    final store = ref.read(localStoreProvider);
    final recent = [
      for (final w in ref.read(recentLookupsProvider).valueOrNull ?? const <String>[])
        if (w.toLowerCase().startsWith(q)) w,
    ].take(3).toList();
    final prefix = [
      for (final w in await store.searchWords(q, limit: 10))
        if (!recent.contains(w)) w,
    ];
    var close = const <String>[];
    if (recent.length + prefix.length < 3 && q.length >= 3) {
      close = [
        for (final w in await ref.read(dictionaryRepoProvider).suggestions(q))
          if (!recent.contains(w) && !prefix.contains(w)) w,
      ].take(4).toList();
    }
    _setNoMatches(recent.isEmpty && prefix.isEmpty);
    Future<_Suggestion> withMeaning(String w, _SuggestionKind kind) async {
      final entry = await store.entry(w);
      return (word: w, meaning: entry?.senses.firstOrNull?.meaning, kind: kind);
    }

    return Future.wait([
      for (final w in recent) withMeaning(w, _SuggestionKind.recent),
      for (final w in prefix) withMeaning(w, _SuggestionKind.match),
      for (final w in close) withMeaning(w, _SuggestionKind.didYouMean),
    ]);
  }

  void _setNoMatches(bool v) {
    if (v == _noMatches) return;
    scheduleMicrotask(() {
      if (mounted) setState(() => _noMatches = v);
    });
  }

  Future<void> _forgetRecent(String word) async {
    final t = ref.read(stringsProvider);
    final c = context.colors;
    final scale = ref.read(settingsProvider).hindiScale;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text(t.removeRecent, style: uiHeading(hindi: t.isHindi, color: c.ink, scale: scale)),
        content: Text(word, style: EnglishText.body(c.ink)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.no)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.delete)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(localStoreProvider).removeRecentLookup(word);
    ref.invalidate(recentLookupsProvider);
  }

  Future<void> _open(String word) async {
    setState(() => _busy = true);
    final outcome = await ref.read(dictionaryRepoProvider).lookupWord(word);
    ref.read(analyticsProvider).track('Word Looked Up', {
      'from': 'dictionary',
      'found': outcome is LookupFound,
      if (outcome is LookupFound) 'source': outcome.source.name,
    });
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case LookupFound(:final lemma):
        unawaited(ref.read(localStoreProvider).addRecentLookup(lemma));
        ref.invalidate(recentLookupsProvider);
        unawaited(context.push('/word/$lemma'));
      case LookupMissing(:final suggestions, :final offline):
        final t = ref.read(stringsProvider);
        final scale = ref.read(settingsProvider).hindiScale;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              offline
                  ? t.offline
                  : suggestions.isEmpty
                      ? t.notFound
                      : '${t.notFound} ${t.didYouMean}: ${suggestions.join(', ')}',
              style: uiBody(hindi: t.isHindi, color: context.colors.paper, scale: scale, size: 13.5),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final settings = ref.watch(settingsProvider);
    final h = HindiText(settings.hindiScale);
    final t = ref.watch(stringsProvider);
    final recent = ref.watch(recentLookupsProvider).valueOrNull ?? const [];
    final wotd = ref.watch(wordOfTheDayProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            Text(t.dictionaryTitle, style: uiTitle(hindi: t.isHindi, color: c.ink, scale: settings.hindiScale)),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (ctx, box) => RawAutocomplete<_Suggestion>(
                textEditingController: _text,
                focusNode: _focus,
                displayStringForOption: (o) => o.word,
                optionsBuilder: (v) => _suggestionsFor(v.text),
                onSelected: (o) {
                  _focus.unfocus();
                  unawaited(_open(o.word));
                },
                optionsViewBuilder: (ctx, onSelected, options) => _SuggestionList(
                  width: box.maxWidth,
                  query: _text.text.trim().toLowerCase(),
                  options: options.toList(),
                  onSelected: onSelected,
                ),
                fieldViewBuilder: (ctx, controller, focus, onSubmit) => TextField(
                  controller: controller,
                  focusNode: focus,
                  style: EnglishText.word(c.ink, size: 26),
                  autocorrect: false,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: t.searchHint,
                    hintStyle: t.isHindi ? h.body(c.inkMuted).copyWith(fontSize: 20) : EnglishText.body(c.inkMuted, size: 20),
                    prefixIcon: Icon(Icons.search_rounded, color: c.inkMuted),
                    suffixIcon: _busy
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : controller.text.isEmpty
                            ? null
                            : IconButton(
                                icon: Icon(Icons.close_rounded, color: c.inkMuted),
                                onPressed: () {
                                  controller.clear();
                                  setState(() => _noMatches = false);
                                },
                              ),
                  ),
                  // Rebuild for the clear button and the empty-state sections.
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (v) {
                    if (v.trim().isEmpty) return;
                    focus.unfocus();
                    unawaited(_open(v));
                  },
                ),
              ),
            ),
            if (_noMatches && _text.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(t.notOnDevice, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: settings.hindiScale, size: 13)),
            ],
            if (_text.text.isEmpty) ...[
              if (recent.isNotEmpty) ...[
                SectionLabel(t.recent),
                for (final w in recent) _WordRow(word: w, onTap: () => _open(w), onLongPress: () => _forgetRecent(w)),
              ],
              if (wotd != null) ...[
                SectionLabel(t.wordOfTheDay),
                Pressable.card(
                  onTap: () => context.push('/word/${wotd.word}'),
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(wotd.word, style: EnglishText.word(c.accent, size: 32)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (wotd.ipa.isNotEmpty) Text('/${wotd.ipa}/', style: EnglishText.ipa(c.inkMuted)),
                              Text(wotd.senses.first.partOfSpeech, style: h.small(c.inkMuted)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SenseList(senses: wotd.senses, max: 1),
                        ],
                      ),
                    ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({required this.word, required this.onTap, this.onLongPress});

  final String word;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.rule))),
        child: Text(word, style: EnglishText.body(c.ink, size: 20)),
      ),
    );
  }
}

enum _SuggestionKind { recent, match, didYouMean }

typedef _Suggestion = ({String word, String? meaning, _SuggestionKind kind});

/// The dropdown: one row per suggestion, the typed part of the word in bold.
class _SuggestionList extends ConsumerWidget {
  const _SuggestionList({required this.width, required this.query, required this.options, required this.onSelected});

  final double width;
  final String query;
  final List<_Suggestion> options;
  final AutocompleteOnSelected<_Suggestion> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final h = HindiText(ref.watch(settingsProvider).hindiScale);
    final firstClose = options.indexWhere((o) => o.kind == _SuggestionKind.didYouMean);
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Material(
          color: c.card,
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width, maxHeight: MediaQuery.sizeOf(context).height * 0.45),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6),
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (_, i) {
                final o = options[i];
                final starts = o.word.toLowerCase().startsWith(query) && o.kind != _SuggestionKind.didYouMean;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (i == firstClose)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                        child: Text(t.didYouMean, style: uiLabel(hindi: t.isHindi, color: c.inkMuted)),
                      ),
                    InkWell(
                      onTap: () => onSelected(o),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              switch (o.kind) {
                                _SuggestionKind.recent => Icons.history_rounded,
                                _SuggestionKind.match => Icons.search_rounded,
                                _SuggestionKind.didYouMean => Icons.spellcheck_rounded,
                              },
                              size: 18,
                              color: c.inkMuted,
                            ),
                            const SizedBox(width: 12),
                            Text.rich(
                              TextSpan(
                                style: EnglishText.body(c.ink, size: 18),
                                children: starts
                                    ? [
                                        TextSpan(text: o.word.substring(0, query.length), style: const TextStyle(fontWeight: FontWeight.w700)),
                                        TextSpan(text: o.word.substring(query.length)),
                                      ]
                                    : [TextSpan(text: o.word)],
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (o.meaning != null)
                              Expanded(
                                child: Text(
                                  o.meaning!,
                                  style: h.small(c.inkMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
