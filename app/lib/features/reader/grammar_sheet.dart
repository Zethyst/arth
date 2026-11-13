// "How is this sentence built?" — the grammar of a selected sentence, in Hindi.
//
// The translation beside it says what the sentence means. This says how it
// works, which is the wall a reader hits once the words have stopped being the
// problem: why "had been", what "that" points at, where the verb sits.

import 'package:arth/app/feel.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/core/models/contracts.dart';
import 'package:arth/data/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The note for one sentence. Keyed by the sentence, so the same selection
/// does not pay twice while the sheet is open.
final FutureProviderFamily<GrammarNote, ({String text, String? context})> grammarProvider =
    FutureProvider.family<GrammarNote, ({String text, String? context})>(
  (ref, q) => ref.watch(apiClientProvider).grammar(text: q.text, context: q.context),
);

Future<void> showGrammarSheet(
  BuildContext context, {
  required String text,
  String? sentenceContext,
}) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.92,
        builder: (_, scroll) => _GrammarBody(
          text: text,
          sentenceContext: sentenceContext,
          scroll: scroll,
        ),
      ),
    );

class _GrammarBody extends ConsumerWidget {
  const _GrammarBody({required this.text, required this.sentenceContext, required this.scroll});

  final String text;
  final String? sentenceContext;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final h = HindiText(scale);
    final note = ref.watch(grammarProvider((text: text, context: sentenceContext)));
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Center(
          child: Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            color: c.inkMuted.withValues(alpha: 0.35),
          ),
        ),
        Text(t.grammarTitle, style: uiHeading(hindi: t.isHindi, color: c.ink, scale: scale)),
        const SizedBox(height: 8),
        Text(text, style: EnglishText.italic(c.inkMuted, size: 14)),
        const SizedBox(height: 14),
        Container(height: 1.2, color: c.accent.withValues(alpha: 0.35)),
        const SizedBox(height: 16),
        note.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(
            e is ApiFailure ? t.errorForFeature(e.code, e.message) : '$e',
            style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale),
          ),
          data: (n) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The skeleton first: a reader wants the shape before the detail.
              HardShadow(
                depth: 3,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(n.shape, style: h.meaning(c.ink)),
                ),
              ),
              const SizedBox(height: 18),
              for (final p in n.points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(child: Text(p.part, style: EnglishText.body(c.accent, size: 16))),
                          const SizedBox(width: 10),
                          Text(p.label, style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          border: Border(left: BorderSide(color: c.marigold, width: 3)),
                        ),
                        child: Text(p.note, style: h.body(c.ink)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
