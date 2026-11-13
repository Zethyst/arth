// "What happened here" — the page or chapter the reader has just been through,
// told back to them in Hindi.
//
// A reader who has followed every word can still lose the thread, and a reader
// coming back after a week has lost the names. This is what stops a book being
// abandoned halfway.

import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/core/models/contracts.dart';
import 'package:arth/data/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shorter than this and there is nothing to summarise; the server refuses it
/// too, and this way the reader is told rather than shown an error.
const int kMinSummaryChars = 200;

final FutureProviderFamily<PassageSummary, String> summaryProvider =
    FutureProvider.family<PassageSummary, String>(
  (ref, text) => ref.watch(apiClientProvider).summary(text: text),
);

Future<void> showSummarySheet(BuildContext context, {required String text}) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, scroll) => _SummaryBody(text: text, scroll: scroll),
      ),
    );

class _SummaryBody extends ConsumerWidget {
  const _SummaryBody({required this.text, required this.scroll});

  final String text;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final h = HindiText(scale);
    final summary = ref.watch(summaryProvider(text));
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
        Text(t.summaryTitle, style: uiHeading(hindi: t.isHindi, color: c.ink, scale: scale)),
        const SizedBox(height: 14),
        Container(height: 1.2, color: c.accent.withValues(alpha: 0.35)),
        const SizedBox(height: 16),
        summary.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(
            e is ApiFailure ? t.errorForFeature(e.code, e.message) : '$e',
            style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale),
          ),
          data: (s) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.summary, style: h.body(c.ink)),
              const SizedBox(height: 18),
              for (final p in s.points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 7, right: 10),
                        child: Container(width: 6, height: 6, color: c.accent),
                      ),
                      Expanded(child: Text(p, style: h.body(c.ink))),
                    ],
                  ),
                ),
              if ((s.people ?? const []).isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(t.summaryPeople, style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
                const SizedBox(height: 8),
                for (final p in s.people ?? const <PassageSummaryPeople>[])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: p.name, style: h.meaning(c.ink)),
                          TextSpan(text: '  ${p.who}', style: h.small(c.inkMuted)),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
