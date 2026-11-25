// The offer itself: "watch a short ad for N more answers".
//
// Shown only where the reader has just been refused an AI answer (the word
// and sentence cards) and on the Plans screen beside what they've used. It
// hides itself when the reader isn't signed in, isn't on the free plan, the
// server pays nothing for an ad, or the day's ads are spent — so nothing
// here promises something the server won't honour.

import 'package:arth/app/account_providers.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/features/ads/rewarded.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EarnAnswers extends ConsumerStatefulWidget {
  const EarnAnswers({this.dense = false, super.key});

  /// A text button rather than a full-width one, for the cards in the reader
  /// where it sits next to "See plans".
  final bool dense;

  @override
  ConsumerState<EarnAnswers> createState() => _EarnAnswersState();
}

class _EarnAnswersState extends ConsumerState<EarnAnswers> {
  bool _busy = false;

  Future<void> _watch() async {
    if (_busy) return;
    setState(() => _busy = true);
    final outcome = await ref.read(rewardedProvider).offer();
    if (!mounted) return;
    setState(() => _busy = false);
    final t = ref.read(stringsProvider);
    final said = switch (outcome) {
      Reward.earned => t.earnedAnswers(ref.read(accountProvider).valueOrNull?.adBonus ?? 0),
      Reward.spentForToday => t.earnAnswersDoneToday,
      Reward.none => t.earnAnswersNoAd,
      Reward.failed => t.somethingWrong,
    };
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(said), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(canEarnAnswersProvider)) return const SizedBox.shrink();
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final answers = ref.watch(accountProvider).valueOrNull?.adBonus ?? 0;
    final dense = widget.dense;
    // A row, not a `*Button.icon`: the label wraps. In Hindi it is half a
    // line longer, and the word card it sits in is narrow.
    final row = Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: _busy
              ? CircularProgressIndicator(strokeWidth: 2, color: c.accent)
              : Icon(Icons.play_circle_outline_rounded, size: 18, color: c.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _busy ? t.earnAnswersBusy : t.earnAnswers(answers),
            style: uiLabel(hindi: t.isHindi, color: dense ? c.accent : c.ink, scale: scale),
          ),
        ),
      ],
    );
    if (dense) {
      return InkWell(
        onTap: _busy ? null : _watch,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), child: row),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _busy ? null : _watch,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: c.ink, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        child: row,
      ),
    );
  }
}
