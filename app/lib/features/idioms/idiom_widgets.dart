// The two faces of an idiom card, and the row used in lists. Everything is
// drawn from the dictionary entry the idiom points at, at its idiomatic
// sense — which is not always the entry's first.
//
// An idiom card is the same index card a flashcard is drawn on (card_face.dart):
// ruled paper, a lac-red margin and a coloured edge along the top. It has no
// book to take that colour from, so it takes one from the phrase itself, the
// way a deck takes one from its title.

import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/data/local_store.dart';
import 'package:arth/features/cards/card_face.dart';
import 'package:arth/features/library/book_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The card the reader meets first: the phrase and what it means.
class IdiomCardFront extends ConsumerWidget {
  const IdiomCardFront({required this.idiom, super.key});

  final IdiomRow idiom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final h = HindiText(settings.hindiScale);
    return _CardShell(
      phrase: idiom.phrase,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IdiomTagRow(tags: idiom.tags),
          const Spacer(),
          Text(idiom.phrase, style: EnglishText.word(c.ink, size: 32)),
          const SizedBox(height: 12),
          Text(idiom.sense.definition, style: h.body(c.ink)),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.flip_to_back_rounded, size: 16, color: c.inkMuted),
              const SizedBox(width: 8),
              Text(t.idiomTapToTurn, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: settings.hindiScale, size: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

/// The other side: the phrase doing its job in a sentence.
class IdiomCardBack extends ConsumerWidget {
  const IdiomCardBack({required this.idiom, super.key});

  final IdiomRow idiom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final h = HindiText(settings.hindiScale);
    final examples = idiom.examples;
    return _CardShell(
      phrase: idiom.phrase,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(idiom.phrase, style: EnglishText.word(c.ink)),
          const SizedBox(height: 4),
          Text(idiom.meaning, style: h.headline(c.ink)),
          const SizedBox(height: 16),
          if (examples.isEmpty)
            Text(idiom.sense.definition, style: h.body(c.ink))
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.idiomInUse, style: uiLabel(hindi: t.isHindi, color: c.accent, scale: settings.hindiScale)),
                    const SizedBox(height: 8),
                    for (final ex in examples)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Container(
                          padding: const EdgeInsets.only(left: 12),
                          decoration: BoxDecoration(border: Border(left: BorderSide(color: c.marigold, width: 3))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ex.en, style: EnglishText.body(c.ink, size: 16)),
                              const SizedBox(height: 4),
                              Text(ex.hi, style: h.small(c.inkMuted)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              Icon(Icons.flip_to_front_rounded, size: 16, color: c.inkMuted),
              const SizedBox(width: 8),
              Text(t.idiomTapToTurnBack, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: settings.hindiScale, size: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.phrase, required this.child});

  /// Which idiom this is: it picks the colour of the card's top edge.
  final String phrase;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      // The top rule is the card's own edge, so the first line clears it.
      child: IndexCard(
        ink: coverInk(phrase),
        padding: const EdgeInsets.fromLTRB(28, 26, 22, 22),
        child: child,
      ),
    );
  }
}

/// Register labels (स्लैंग, पुराना, ब्रिटिश…). Nothing is drawn for a phrase
/// that carries none, which is most of them.
class IdiomTagRow extends ConsumerWidget {
  const IdiomTagRow({required this.tags, super.key});

  final List<String> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    final h = HindiText(ref.watch(settingsProvider).hindiScale);
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: c.marigold.withValues(alpha: 0.18),
              border: Border.all(color: c.ink, width: 1.5),
            ),
            child: Text(tag, style: h.small(c.ink)),
          ),
      ],
    );
  }
}

/// One idiom in a list: the phrase, its Hindi meaning, and whether it's kept.
class IdiomTile extends ConsumerWidget {
  const IdiomTile({required this.idiom, required this.onTap, super.key});

  final IdiomRow idiom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final h = HindiText(ref.watch(settingsProvider).hindiScale);
    return ListTile(
      onTap: onTap,
      title: Text(idiom.phrase, style: EnglishText.body(c.ink, size: 17)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(idiom.meaning, style: h.small(c.inkMuted)),
      ),
      trailing: idiom.saved ? Icon(Icons.favorite_rounded, size: 18, color: c.accent) : null,
    );
  }
}
