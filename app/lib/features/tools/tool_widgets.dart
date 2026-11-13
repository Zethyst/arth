// The pieces the three tools share: the run button, the answer card, a
// bilingual chip, and a row for "another way to say it".

import 'package:arth/app/feel.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/strings.dart';
import 'package:arth/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The tone names the model may return, in the interface language.
String toneLabel(String tone, AppStrings t) => switch (tone) {
      'formal' => t.toneFormal,
      'casual' => t.toneCasual,
      'direct' => t.toneDirect,
      'concise' => t.toneConcise,
      _ => tone,
    };

class ToolRunButton extends StatelessWidget {
  const ToolRunButton({required this.label, required this.busy, required this.onPressed, super.key});

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(label),
      ),
    );
  }
}

/// The answer, on the card stock the rest of the app is drawn on.
class ToolResultCard extends ConsumerWidget {
  const ToolResultCard({
    required this.text,
    required this.onCopy,
    super.key,
    this.speakEnglish = false,
  });

  final String text;
  final VoidCallback onCopy;

  /// Show a speaker: the reader is about to say this out loud.
  final bool speakEnglish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final tts = ref.watch(ttsProvider);
    return HardShadow(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(text, style: EnglishText.body(c.ink, size: 18)),
            ),
            Row(
              children: [
                if (speakEnglish && tts.hasEnglish)
                  IconButton(
                    tooltip: t.listen,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.volume_up_rounded, color: c.accent, size: 20),
                    onPressed: () => tts.speakEnglish(text),
                  ),
                const Spacer(),
                IconButton(
                  tooltip: t.copy,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.copy_rounded, color: c.accent, size: 20),
                  onPressed: onCopy,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// An English word with the Hindi it stands for. Takes the two strings rather
/// than a model type: the generated classes nest one per schema, so the same
/// pair arrives under a different name from each tool.
class BilingualChip extends ConsumerWidget {
  const BilingualChip({required this.en, required this.hi, super.key});

  final String en;
  final String hi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final h = HindiText(ref.watch(settingsProvider).hindiScale);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(border: Border.all(color: c.ink, width: 1.5)),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: en, style: EnglishText.body(c.accent, size: 14)),
            TextSpan(text: '  $hi', style: h.small(c.ink)),
          ],
        ),
      ),
    );
  }
}

/// One of the other ways to say the same thing.
class AlternativeRow extends ConsumerWidget {
  const AlternativeRow({required this.tone, required this.text, required this.onCopy, super.key});

  final String tone;
  final String text;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3, right: 10),
            child: SizedBox(
              width: 74,
              child: Text(tone, style: uiLabel(hindi: t.isHindi, color: c.marigold, scale: scale)),
            ),
          ),
          Expanded(child: Text(text, style: EnglishText.body(c.ink))),
          InkWell(
            onTap: onCopy,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.copy_rounded, size: 16, color: c.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}
