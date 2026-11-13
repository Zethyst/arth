// Practice: which meaning fits? The wrong answers are other idioms' meanings,
// so the choice is a real test rather than one plausible line among filler.
//
// Answers are recorded per idiom, and the next round asks the ones the reader
// has been getting wrong first.

import 'dart:async';

import 'package:arth/app/feel.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/features/idioms/idiom_providers.dart';
import 'package:arth/features/idioms/idiom_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class IdiomPracticeScreen extends ConsumerStatefulWidget {
  const IdiomPracticeScreen({super.key});

  @override
  ConsumerState<IdiomPracticeScreen> createState() => _IdiomPracticeScreenState();
}

class _IdiomPracticeScreenState extends ConsumerState<IdiomPracticeScreen> {
  late int _seed = DateTime.now().millisecondsSinceEpoch;
  List<IdiomQuestion>? _round;
  int _index = 0;
  int _right = 0;

  /// The option the reader picked, or null while the question is open.
  int? _picked;

  void _restart() {
    setState(() {
      _seed = DateTime.now().millisecondsSinceEpoch;
      _round = null;
      _index = 0;
      _right = 0;
      _picked = null;
    });
  }

  Future<void> _answer(IdiomQuestion q, int option) async {
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
    await ref.read(idiomsProvider.notifier).recordAnswer(q.idiom.phrase, correct: correct);
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
    final h = HindiText(scale);
    // The round is built once the dictionary has loaded, then frozen:
    // answering rewrites progress, and a live round would rebuild the
    // questions mid-quiz. Reading before the load finished is what made
    // practice claim there were too few idioms.
    final loaded = ref.watch(idiomsProvider);
    if (_round == null && loaded.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(t.idiomsPractice)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final List<IdiomQuestion> round;
    final built = _round;
    if (built != null) {
      round = built;
    } else {
      round = buildPractice(loaded.valueOrNull ?? const [], _seed);
      _round = round;
    }

    if (round.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(t.idiomsPractice)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(t.practiceTooFew, textAlign: TextAlign.center, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale))),
        ),
      );
    }

    if (_index >= round.length) {
      return Scaffold(
        appBar: AppBar(title: Text(t.idiomsPractice)),
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
    return Scaffold(
      appBar: AppBar(title: Text('${t.idiomsPractice}  ${t.idiomsProgress(_index + 1, round.length)}')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.practiceQuestion, style: uiHeading(hindi: t.isHindi, color: c.ink, scale: scale)),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: c.card,
                border: Border.all(color: c.ink, width: 2),
                boxShadow: [BoxShadow(color: c.shadow, offset: const Offset(5, 5))],
              ),
              child: Text(q.idiom.phrase, style: EnglishText.word(c.ink, size: 26)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  for (var i = 0; i < q.options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _Option(
                        label: String.fromCharCode(65 + i),
                        text: q.options[i],
                        style: h.body(c.ink),
                        state: _picked == null
                            ? _OptionState.open
                            : i == q.answer
                                ? _OptionState.right
                                : i == _picked
                                    ? _OptionState.wrong
                                    : _OptionState.dimmed,
                        onTap: () => unawaited(_answer(q, i)),
                      ),
                    ),
                ],
              ),
            ),
            if (_picked != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _next, child: Text(t.idiomNext)),
              ),
          ],
        ),
      ),
    );
  }
}

enum _OptionState { open, right, wrong, dimmed }

class _Option extends StatelessWidget {
  const _Option({required this.label, required this.text, required this.style, required this.state, required this.onTap});

  final String label;
  final String text;
  final TextStyle style;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (border, fill) = switch (state) {
      _OptionState.open => (c.ink, Colors.transparent),
      _OptionState.right => (c.accent, c.accent.withValues(alpha: 0.14)),
      _OptionState.wrong => (c.ink, c.inkMuted.withValues(alpha: 0.12)),
      _OptionState.dimmed => (c.rule, Colors.transparent),
    };
    return InkWell(
      onTap: state == _OptionState.open ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: fill, border: Border.all(color: border, width: 2)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: EnglishText.label(state == _OptionState.dimmed ? c.rule : c.accent)),
            const SizedBox(width: 14),
            Expanded(child: Text(text, style: style)),
            if (state == _OptionState.right) Icon(Icons.check_rounded, color: c.accent),
            if (state == _OptionState.wrong) Icon(Icons.close_rounded, color: c.inkMuted),
          ],
        ),
      ),
    );
  }
}
