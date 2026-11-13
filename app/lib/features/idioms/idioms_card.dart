// The idioms section on the Dictionary tab: today's set at a glance, with
// the three ways in — the day's cards, the whole list, and practice.

import 'package:arth/app/feel.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/data/local_store.dart';
import 'package:arth/features/dictionary/entry_widgets.dart';
import 'package:arth/features/idioms/idiom_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class IdiomsCard extends ConsumerWidget {
  const IdiomsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final scale = settings.hindiScale;
    final h = HindiText(scale);
    final all = ref.watch(idiomsProvider).valueOrNull ?? const <IdiomRow>[];
    // Nothing to show until the dictionary has been downloaded.
    if (all.isEmpty) return const SizedBox.shrink();
    final today = ref.watch(dailyIdiomsProvider);
    final first = today.isEmpty ? null : today.first;
    final left = today.where((i) => i.seenAt == null).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(t.idiomsTitle),
        Pressable.card(
          onTap: () => context.push('/idioms'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(t.idiomsToday(today.length), style: uiLabel(hindi: t.isHindi, color: c.accent, scale: scale)),
                    const Spacer(),
                    if (left > 0)
                      Text(t.idiomsProgress(today.length - left, today.length),
                          style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 12.5)),
                  ],
                ),
                const SizedBox(height: 10),
                if (first != null) ...[
                  Text(first.phrase, style: EnglishText.word(c.ink, size: 26)),
                  const SizedBox(height: 4),
                  Text(first.meaning, style: h.body(c.inkMuted)),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => context.push('/idioms/all'),
                      style: TextButton.styleFrom(foregroundColor: c.accent, visualDensity: VisualDensity.compact),
                      child: Text(t.idiomsSeeAll, style: uiLabel(hindi: t.isHindi, color: c.accent, scale: scale).copyWith(fontSize: 13)),
                    ),
                    TextButton(
                      onPressed: () => context.push('/idioms/practice'),
                      style: TextButton.styleFrom(foregroundColor: c.accent, visualDensity: VisualDensity.compact),
                      child: Text(t.idiomsPractice, style: uiLabel(hindi: t.isHindi, color: c.accent, scale: scale).copyWith(fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
