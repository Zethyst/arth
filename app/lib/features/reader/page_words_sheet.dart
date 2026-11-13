// The "Hard words on this page" sheet: every uncommon word on the page the
// reader is looking at, rarest first, each with its Hindi meaning already
// filled in from the on-device dictionary. Tapping one opens the same full
// entry a tap in the text would.
//
// Each word is a card rather than a list row, and carries how rare it is.
// The list is ordered by rarity and that was invisible: a reader saw a flat
// column of words with no way to tell which one was worth the effort.

import 'package:arth/app/feel.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/strings.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/core/models/contracts.dart';
import 'package:arth/data/dictionary_repo.dart';
import 'package:arth/features/reader/page_vocabulary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A word in the list, with whatever the dictionary already knows about it.
typedef PageWordRow = ({PageVocabularyWord word, DictionaryEntry? entry});

/// How rare a word is, for the band and label on its card. Everything in this
/// list is already rarer than [kAdvancedWordRank], so there is no common tier.
enum WordRarity { rare, veryRare, rarest }

/// A word the on-device dictionary has never heard of is rarer than every word
/// it has, since the slice it holds is the commonest 20,000.
WordRarity rarityOf(int? rank) => switch (rank) {
      null => WordRarity.rarest,
      final r when r > 15000 => WordRarity.veryRare,
      _ => WordRarity.rare,
    };

String rarityLabel(WordRarity r, AppStrings t) => switch (r) {
      WordRarity.rare => t.rarityRare,
      WordRarity.veryRare => t.rarityVeryRare,
      WordRarity.rarest => t.rarityRarest,
    };

Color rarityColor(WordRarity r, ArthColors c) => switch (r) {
      WordRarity.rare => c.inkMuted,
      WordRarity.veryRare => c.marigold,
      WordRarity.rarest => c.accent,
    };

Future<void> showPageWordsSheet(
  BuildContext context, {
  required List<PageWordRow> rows,
  required void Function(PageWordRow row) onTap,
}) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        maxChildSize: 0.92,
        builder: (ctx, scroll) => _PageWordsList(
          rows: rows,
          scroll: scroll,
          onTap: (r) {
            Navigator.pop(ctx);
            onTap(r);
          },
        ),
      ),
    );

class _PageWordsList extends ConsumerWidget {
  const _PageWordsList({required this.rows, required this.scroll, required this.onTap});

  final List<PageWordRow> rows;
  final ScrollController scroll;
  final void Function(PageWordRow row) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final h = HindiText(scale);
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      itemCount: rows.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) return _Header(rows: rows);
        final row = rows[i - 1];
        final meaning = row.entry?.senses.firstOrNull?.meaning;
        final rarity = rarityOf(row.word.rank);
        final band = rarityColor(rarity, c);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Pressable.card(
            depth: 3,
            onTap: () => onTap(row),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // How rare the word is, as a band down the card's edge: the
                  // list is ordered by it, so it should be possible to see it.
                  Container(width: 5, color: band),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              // The key, not the raw token: the page's punctuation came with it.
                              Expanded(child: Text(row.word.key, style: EnglishText.word(c.ink, size: 20))),
                              const SizedBox(width: 10),
                              Text(rarityLabel(rarity, t), style: uiLabel(hindi: t.isHindi, color: band, scale: scale)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (meaning == null)
                            Text(t.tapToLookUp, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 13))
                          else
                            Text(meaning, style: h.body(c.inkMuted)),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(child: Icon(Icons.chevron_right_rounded, color: c.inkMuted)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.rows});

  final List<PageWordRow> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The sheet drags open to full height; nothing said so.
        Center(
          child: Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            color: c.inkMuted.withValues(alpha: 0.35),
          ),
        ),
        Text(t.hardWords, style: uiHeading(hindi: t.isHindi, color: c.ink, scale: scale)),
        const SizedBox(height: 6),
        Text(
          rows.isEmpty ? t.hardWordsEmpty : t.hardWordsFound(rows.length),
          style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 13.5),
        ),
        const SizedBox(height: 14),
        // The same lac-red hairline a card's margin is ruled in.
        Container(height: 1.2, color: c.accent.withValues(alpha: 0.35)),
        const SizedBox(height: 14),
      ],
    );
  }
}

/// Fills in each word's entry from the dictionary, so the sheet can show the
/// meaning beside the word without a tap. Words the phone doesn't have stay
/// null and are looked up when opened.
Future<List<PageWordRow>> rowsFor(DictionaryRepo repo, List<PageVocabularyWord> words) async {
  final out = <PageWordRow>[];
  for (final w in words) {
    out.add((word: w, entry: await repo.localEntry(w.key)));
  }
  return out;
}
