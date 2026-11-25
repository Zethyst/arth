// Word power: synonyms, antonyms and one-word substitutions.
//
// Three sets, one shape — a hub that counts them, a list to read, and a
// round of practice. They are not downloaded: every one is derived from the
// dictionary already on the phone (core/text/word_sets.dart), so all of this
// works offline and arrives with the words the reader already has.

import 'dart:async';

import 'package:arth/app/feel.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/strings.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/core/text/word_sets.dart';
import 'package:arth/data/local_store.dart';
import 'package:arth/features/ads/ad_footer.dart';
import 'package:arth/features/ads/interstitials.dart';
import 'package:arth/features/practice/practice_option.dart';
import 'package:arth/features/wordsets/word_set_practice.dart';
import 'package:arth/features/wordsets/word_set_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// `/words/<kind>` and `/words/<kind>/practice`.
WordSetKind wordSetKindFrom(String? name) =>
    WordSetKind.values.where((k) => k.name == name).firstOrNull ?? WordSetKind.synonym;

String wordSetTitle(WordSetKind kind, AppStrings t) => switch (kind) {
      WordSetKind.synonym => t.synonyms,
      WordSetKind.antonym => t.antonyms,
      WordSetKind.substitution => t.substitutionsTitle,
    };

String wordSetHelp(WordSetKind kind, AppStrings t) => switch (kind) {
      WordSetKind.synonym => t.synonymsHelp,
      WordSetKind.antonym => t.antonymsHelp,
      WordSetKind.substitution => t.substitutionsHelp,
    };

IconData wordSetIcon(WordSetKind kind) => switch (kind) {
      WordSetKind.synonym => Icons.join_full_rounded,
      WordSetKind.antonym => Icons.swap_horiz_rounded,
      WordSetKind.substitution => Icons.short_text_rounded,
    };

/// The hub: the three sets, how many of each, and the way into them.
class WordPowerScreen extends ConsumerWidget {
  const WordPowerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    return Scaffold(
      appBar: AppBar(title: Text(t.wordPowerTitle)),
      bottomNavigationBar: const AdFooter(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(t.wordPowerIntro, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 14)),
          const SizedBox(height: 18),
          for (final kind in WordSetKind.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _SetCard(kind: kind),
            ),
        ],
      ),
    );
  }
}

class _SetCard extends ConsumerWidget {
  const _SetCard({required this.kind});

  final WordSetKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final count = ref.watch(wordSetCountProvider(kind));
    final learnt = ref.watch(savedWordSetsProvider(kind)).length;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.ink, width: 2),
        boxShadow: [BoxShadow(color: c.shadow, offset: const Offset(5, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => unawaited(context.push('/words/${kind.name}')),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(wordSetIcon(kind), color: c.accent, size: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(wordSetTitle(kind, t), style: uiHeading(hindi: t.isHindi, color: c.ink, scale: scale)),
                        const SizedBox(height: 4),
                        Text(wordSetHelp(kind, t), style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 13.5)),
                        const SizedBox(height: 8),
                        Text(
                          count.when(
                            data: (n) => learnt > 0 ? '${t.wordSetCount(n)}  ·  ${t.wordSetSavedCount(learnt)}' : t.wordSetCount(n),
                            loading: () => t.wordSetBuilding,
                            error: (_, _) => '',
                          ),
                          style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(color: c.rule, height: 1),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => unawaited(context.push('/words/${kind.name}')),
                  icon: const Icon(Icons.list_rounded, size: 18),
                  label: Text(t.wordSetBrowse),
                ),
              ),
              Container(width: 1, height: 28, color: c.rule),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => unawaited(context.push('/words/${kind.name}/practice')),
                  icon: const Icon(Icons.school_rounded, size: 18),
                  label: Text(t.idiomsPractice),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Items of one kind matching [query] in either language, commonest first.
List<WordSetRow> filterWordSets(List<WordSetRow> all, String query, {bool savedOnly = false}) {
  final q = query.trim().toLowerCase();
  return [
    for (final i in all)
      if ((!savedOnly || i.saved) &&
          (q.isEmpty ||
              i.word.toLowerCase().contains(q) ||
              i.answer.toLowerCase().contains(q) ||
              i.hi.contains(q) ||
              i.meaning.contains(q)))
        i,
  ];
}

/// One set, in full, with a search box and a filter for the kept ones.
class WordSetBrowseScreen extends ConsumerStatefulWidget {
  const WordSetBrowseScreen({required this.kind, super.key});

  final WordSetKind kind;

  @override
  ConsumerState<WordSetBrowseScreen> createState() => _WordSetBrowseScreenState();
}

class _WordSetBrowseScreenState extends ConsumerState<WordSetBrowseScreen> {
  final _controller = TextEditingController();
  bool _savedOnly = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final loaded = ref.watch(wordSetsProvider(widget.kind));
    final all = loaded.valueOrNull ?? const <WordSetRow>[];
    final shown = filterWordSets(all, _controller.text, savedOnly: _savedOnly);
    return Scaffold(
      appBar: AppBar(
        title: Text(wordSetTitle(widget.kind, t)),
        actions: [
          IconButton(
            tooltip: t.idiomsPractice,
            icon: const Icon(Icons.school_rounded),
            onPressed: () => unawaited(context.push('/words/${widget.kind.name}/practice')),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              style: EnglishText.body(c.ink, size: 16),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: t.idiomsSearchHint,
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: t.idiomsClearSearch,
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    selected: _savedOnly,
                    label: Text(t.idiomsSaved),
                    onSelected: (v) => setState(() => _savedOnly = v),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${t.wordSetCount(shown.length)}  ·  ${t.idiomsBestKnownFirst}',
                  style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 13),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          Expanded(
            child: loaded.isLoading
                ? const Center(child: CircularProgressIndicator())
                : shown.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            all.isEmpty ? t.wordSetsEmpty : t.notFound,
                            textAlign: TextAlign.center,
                            style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale),
                          ),
                        ),
                      )
                    : ListView.builder(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: shown.length,
                        itemBuilder: (_, i) => WordSetTile(item: shown[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

/// One item in a list: the word (or the description), what answers it, and a
/// heart to keep it.
class WordSetTile extends ConsumerWidget {
  const WordSetTile({required this.item, super.key});

  final WordSetRow item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final substitution = item.kind == WordSetKind.substitution;
    return InkWell(
      // The word's own page is where the rest of it is: every sense, the
      // other synonyms, how it sounds.
      onTap: () => unawaited(context.push('/word/${Uri.encodeComponent(item.word)}')),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (substitution) ...[
                    Text(item.hi, style: HindiText(scale).body(c.ink)),
                    const SizedBox(height: 4),
                    Text(item.word, style: EnglishText.word(c.ink, size: 19)),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(child: Text(item.word, style: EnglishText.word(c.ink, size: 19))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            item.kind == WordSetKind.antonym ? Icons.swap_horiz_rounded : Icons.drag_handle_rounded,
                            size: 16,
                            color: c.inkMuted,
                          ),
                        ),
                        Flexible(child: Text(item.answer, style: EnglishText.word(c.accent, size: 19))),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.others.isEmpty ? item.hi : '${item.hi}  ·  ${item.others.join(', ')}',
                      style: HindiText(scale).small(c.inkMuted),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: item.saved ? t.idiomsSaved : t.save,
              icon: Icon(
                item.saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: item.saved ? c.accent : c.inkMuted,
                size: 20,
              ),
              onPressed: () {
                Haptics.choose();
                unawaited(ref.read(wordSetsProvider(item.kind).notifier).setSaved(item.id, saved: !item.saved));
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A round of eight: which word answers this?
class WordSetPracticeScreen extends ConsumerStatefulWidget {
  const WordSetPracticeScreen({required this.kind, super.key});

  final WordSetKind kind;

  @override
  ConsumerState<WordSetPracticeScreen> createState() => _WordSetPracticeScreenState();
}

class _WordSetPracticeScreenState extends ConsumerState<WordSetPracticeScreen> with AdBreakOnLeave<WordSetPracticeScreen> {
  late int _seed = DateTime.now().millisecondsSinceEpoch;
  List<WordSetQuestion>? _round;
  int _index = 0;
  int _right = 0;
  int? _picked;

  @override
  AdBreak get adBreak => AdBreak.finishedPractice;

  @override
  bool get adBreakEarned => _round != null && _round!.isNotEmpty && _index >= _round!.length;

  void _restart() => setState(() {
        _seed = DateTime.now().millisecondsSinceEpoch;
        _round = null;
        _index = 0;
        _right = 0;
        _picked = null;
      });

  Future<void> _answer(WordSetQuestion q, int option) async {
    if (_picked != null) return;
    final correct = option == q.answer;
    setState(() {
      _picked = option;
      if (correct) _right++;
    });
    if (correct) {
      Haptics.commit();
    } else {
      Haptics.choose();
    }
    await ref.read(wordSetsProvider(widget.kind).notifier).recordAnswer(q.item.id, correct: correct);
  }

  void _next() => setState(() {
        _picked = null;
        _index++;
      });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final title = '${wordSetTitle(widget.kind, t)} · ${t.idiomsPractice}';
    // Built once the set has loaded, then frozen: answering rewrites
    // progress, and a live round would rebuild the questions mid-quiz.
    final loaded = ref.watch(wordSetsProvider(widget.kind));
    if (_round == null && loaded.isLoading) {
      return Scaffold(appBar: AppBar(title: Text(title)), body: const Center(child: CircularProgressIndicator()));
    }
    final round = _round ??= buildWordSetPractice(loaded.valueOrNull ?? const [], _seed);

    if (round.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(t.practiceTooFewWords, textAlign: TextAlign.center, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale))),
        ),
      );
    }
    if (_index >= round.length) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t.practiceDone, style: uiHeading(hindi: t.isHindi, color: c.ink, scale: scale)),
              const SizedBox(height: 8),
              Text(t.practiceScore(_right, round.length), style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
              const SizedBox(height: 24),
              FilledButton(onPressed: _restart, child: Text(t.practiceAgain)),
              TextButton(onPressed: () => context.pop(), child: Text(t.back)),
            ],
          ),
        ),
      );
    }

    final q = round[_index];
    final ask = switch (widget.kind) {
      WordSetKind.synonym => t.askSynonym,
      WordSetKind.antonym => t.askAntonym,
      WordSetKind.substitution => t.askSubstitution,
    };
    final hindi = HindiText(scale);
    return Scaffold(
      appBar: AppBar(title: Text('$title  ${t.idiomsProgress(_index + 1, round.length)}')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ask, style: uiHeading(hindi: t.isHindi, color: c.ink, scale: scale)),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: c.card,
                border: Border.all(color: c.ink, width: 2),
                boxShadow: [BoxShadow(color: c.shadow, offset: const Offset(5, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (q.item.kind == WordSetKind.substitution)
                    Text(q.prompt, style: hindi.body(c.ink))
                  else
                    Text(q.prompt, style: EnglishText.word(c.ink, size: 26)),
                  if (q.hint.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(q.hint, style: hindi.small(c.inkMuted)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  for (var i = 0; i < q.options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PracticeOption(
                        label: String.fromCharCode(65 + i),
                        text: q.options[i],
                        style: EnglishText.body(c.ink, size: 17),
                        state: _picked == null
                            ? PracticeOptionState.open
                            : i == q.answer
                                ? PracticeOptionState.right
                                : i == _picked
                                    ? PracticeOptionState.wrong
                                    : PracticeOptionState.dimmed,
                        onTap: () => unawaited(_answer(q, i)),
                      ),
                    ),
                  // Once answered, what the right word means — the reason to
                  // have been asked at all.
                  if (_picked != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        decoration: BoxDecoration(border: Border(left: BorderSide(color: c.rule, width: 3))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(q.correctOption, style: EnglishText.word(c.ink, size: 18)),
                            const SizedBox(height: 4),
                            Text(
                              q.item.kind == WordSetKind.substitution ? q.item.meaning : q.item.hi,
                              style: hindi.body(c.inkMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_picked != null)
              SizedBox(width: double.infinity, child: FilledButton(onPressed: _next, child: Text(t.idiomNext))),
          ],
        ),
      ),
    );
  }
}
