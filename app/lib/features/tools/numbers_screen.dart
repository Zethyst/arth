// Numbers, one to a hundred.
//
// Hindi number names can't be assembled the way English's can: बयालीस is a
// word of its own, not चालीस plus दो, so 42 is of no use to anyone who hasn't
// met it. All hundred are therefore here in full — ten at a time, because ten
// is what a phone holds, with the ending that ties each ten together above it
// and a search field for the one number somebody came for.
//
// Each number carries its four names (42, ४२, बयालीस, forty-two) and both
// voices: the card says the Hindi, EN says the English.

import 'package:arth/app/feel.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/features/ads/ad_footer.dart';
import 'package:arth/features/tools/numbers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NumbersScreen extends ConsumerStatefulWidget {
  const NumbersScreen({super.key});

  @override
  ConsumerState<NumbersScreen> createState() => _NumbersScreenState();
}

class _NumbersScreenState extends ConsumerState<NumbersScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();

  /// Which ten is on screen: 0 for 1-10, 9 for 91-100.
  int _decade = 0;

  /// The search text, already through [foldQuery]; empty when not searching.
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onSearch(String raw) {
    final q = foldQuery(raw);
    // Typing a hyphen or a space changes the field but not the query.
    if (q == _query) return;
    setState(() => _query = q);
    _toTop();
  }

  void _pick(int decade) {
    if (_decade == decade) return;
    Haptics.choose();
    setState(() => _decade = decade);
    _toTop();
  }

  void _clear() {
    _search.clear();
    _onSearch('');
  }

  /// A new set of numbers starts at its first, not wherever the last one was
  /// left standing.
  void _toTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final searching = _query.isNotEmpty;
    // Searching cuts across all hundred; otherwise it's the chosen ten.
    final shown = searching
        ? [for (final n in kHindiNumbers) if (n.matches(_query)) n]
        : kHindiNumbers.sublist(_decade * 10, _decade * 10 + 10);
    return Scaffold(
      appBar: AppBar(title: Text(t.numbersTitle)),
      bottomNavigationBar: const AdFooter(),
      body: Column(
        // Everything on this screen is set against the left margin. Without
        // this the column centres whatever doesn't fill the width, which the
        // no-match line doesn't.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.numbersIntro, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 13.5)),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  onChanged: _onSearch,
                  textInputAction: TextInputAction.search,
                  style: EnglishText.body(c.ink, size: 16),
                  decoration: InputDecoration(
                    hintText: t.numbersSearchHint,
                    hintStyle: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 14.5),
                    isDense: true,
                    contentPadding: const EdgeInsets.fromLTRB(4, 14, 14, 14),
                    prefixIcon: Icon(Icons.search_rounded, color: c.inkMuted, size: 20),
                    prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 20),
                    suffixIcon: searching
                        ? IconButton(
                            tooltip: t.clearSearch,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.close_rounded, color: c.accent, size: 20),
                            onPressed: _clear,
                          )
                        : null,
                    suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 20),
                  ),
                ),
              ],
            ),
          ),
          if (!searching) _DecadeStrip(selected: _decade, onPick: _pick),
          Expanded(
            child: shown.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Text(t.numbersNoMatch, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    // One more than the numbers: the note sits above them and
                    // scrolls away with them.
                    itemCount: shown.length + 1,
                    itemBuilder: (_, i) => i == 0
                        ? _Note(
                            text: searching ? t.numbersFound(shown.length) : t.numbersDecadeNote(_decade),
                            quiet: searching,
                          )
                        : _NumberCard(n: shown[i - 1]),
                  ),
          ),
        ],
      ),
    );
  }
}

/// The tens, across the top. Ten numbers fit a screen; a hundred don't, and
/// a reader after the fifties shouldn't have to scroll past them.
class _DecadeStrip extends ConsumerWidget {
  const _DecadeStrip({required this.selected, required this.onPick});

  final int selected;
  final void Function(int decade) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 10,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ChoiceChip(
          label: Text(t.numbersRange(i * 10 + 1, i * 10 + 10)),
          selected: i == selected,
          showCheckmark: false,
          onSelected: (_) => onPick(i),
        ),
      ),
    );
  }
}

/// What ties a ten together, above the ten itself — or, while searching, how
/// many numbers answered.
class _Note extends ConsumerWidget {
  const _Note({required this.text, required this.quiet});

  final String text;

  /// A result count, which wants no box drawn around it.
  final bool quiet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    if (quiet) {
      return Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 12),
        child: Text(text, style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(color: c.card, border: Border.all(color: c.rule, width: 1.5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1, right: 10),
            child: Icon(Icons.lightbulb_outline_rounded, size: 18, color: c.marigold),
          ),
          Expanded(child: Text(text, style: uiBody(hindi: t.isHindi, color: c.ink, scale: scale, size: 13.5))),
        ],
      ),
    );
  }
}

/// One number: both digits on the left of the rule, both names to the right.
class _NumberCard extends ConsumerWidget {
  const _NumberCard({required this.n});

  final HindiNumber n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final tts = ref.watch(ttsProvider);
    final h = HindiText(scale);
    // A colour per ten, so arriving at the next ten looks like arriving. It
    // only ever paints the bar: marigold is too pale for small text on paper.
    final tint = switch (n.decade % 3) {
      0 => c.accent,
      1 => c.marigold,
      _ => c.ink,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Pressable.card(
        onTap: tts.hasHindi ? () => tts.speakHindi(n.hindi) : null,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: tint),
              SizedBox(
                width: 62,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${n.value}', style: EnglishText.word(c.ink, size: 27)),
                    Text(n.devanagari, style: h.small(c.inkMuted)),
                  ],
                ),
              ),
              Container(width: 1.5, color: c.rule),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(n.hindi, style: h.headline(c.ink))),
                          // Not a button: the whole card already says it.
                          if (tts.hasHindi)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(Icons.volume_up_rounded, size: 15, color: c.inkMuted),
                            ),
                        ],
                      ),
                      Text(n.roman, style: EnglishText.label(c.accent, size: 12.5)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(child: Text(n.english, style: EnglishText.body(c.ink, size: 14.5))),
                          if (tts.hasEnglish)
                            _SpeakEnglish(tooltip: t.listen, onTap: () => tts.speakEnglish(n.english)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The English name, said out loud. It carries a label because the card
/// itself speaks the Hindi, and two bare speakers would be a guess.
class _SpeakEnglish extends StatelessWidget {
  const _SpeakEnglish({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          Haptics.open();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            children: [
              Text('EN', style: EnglishText.label(c.accent, size: 11)),
              const SizedBox(width: 4),
              Icon(Icons.volume_up_rounded, size: 15, color: c.accent),
            ],
          ),
        ),
      ),
    );
  }
}
