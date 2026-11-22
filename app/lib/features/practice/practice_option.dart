// One answer on a practice screen, whatever is being practised: idioms,
// synonyms, antonyms, one-word substitutions. The same shape and the same
// colours everywhere, so a right answer always looks like a right answer.

import 'package:arth/app/theme.dart';
import 'package:flutter/material.dart';

/// Where an option stands: open to be picked, the right one, the one picked
/// wrongly, or one of the rest once the question has been answered.
enum PracticeOptionState { open, right, wrong, dimmed }

class PracticeOption extends StatelessWidget {
  const PracticeOption({
    required this.label,
    required this.text,
    required this.style,
    required this.state,
    required this.onTap,
    super.key,
  });

  final String label;
  final String text;
  final TextStyle style;
  final PracticeOptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Green for the answer, lac red for the miss. It used to be the other way
    // round — the correct answer wore the app's red and the wrong one a
    // neutral grey, so a right answer looked like a mistake.
    final (border, fill, mark) = switch (state) {
      PracticeOptionState.open => (c.ink, Colors.transparent, c.accent),
      PracticeOptionState.right => (c.good, c.good.withValues(alpha: 0.14), c.good),
      PracticeOptionState.wrong => (c.accent, c.accent.withValues(alpha: 0.12), c.accent),
      PracticeOptionState.dimmed => (c.rule, Colors.transparent, c.rule),
    };
    return InkWell(
      onTap: state == PracticeOptionState.open ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: fill, border: Border.all(color: border, width: 2)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: EnglishText.label(mark)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(text, style: state == PracticeOptionState.dimmed ? style.copyWith(color: c.inkMuted) : style),
            ),
            if (state == PracticeOptionState.right) Icon(Icons.check_rounded, color: c.good),
            if (state == PracticeOptionState.wrong) Icon(Icons.close_rounded, color: c.accent),
          ],
        ),
      ),
    );
  }
}
