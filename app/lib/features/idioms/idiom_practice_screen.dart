// Practice: which meaning fits? The wrong answers are other idioms' meanings,
// so the choice is a real test rather than one plausible line among filler.
//
// Answers are recorded per idiom, and the next round asks the ones the reader
// has been getting wrong first.

import 'dart:async';

import 'package:arth/app/feel.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/data/local_store.dart';
import 'package:arth/features/idioms/idiom_providers.dart';
import 'package:arth/features/idioms/idiom_selection.dart';
import 'package:arth/features/practice/practice_option.dart';
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
                      child: PracticeOption(
                        label: String.fromCharCode(65 + i),
                        text: q.options[i],
                        style: h.body(c.ink),
                        state: _picked == null
                            ? PracticeOptionState.open
                            : i == q.answer
                                ? PracticeOptionState.right
                                : i == _picked
                                    ? PracticeOptionState.wrong
                                    : PracticeOptionState.dimmed,
                        onTap: () => unawaited(_answer(q, i)),
                      ),
                    ),
                  // The screen was blank below the options once answered, at
                  // the one moment the reader is looking hardest. A sentence
                  // using the idiom is what they came for.
                  if (_picked != null) _Example(idiom: q.idiom, hindi: h),
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

/// The idiom in a sentence, shown once the question has been answered. Its
/// own sense's example, so it matches the meaning that was just the answer;
/// nothing at all when that sense never had one.
class _Example extends StatelessWidget {
  const _Example({required this.idiom, required this.hindi});

  final IdiomRow idiom;
  final HindiText hindi;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final senses = idiom.entry.senses;
    if (idiom.senseIndex < 0 || idiom.senseIndex >= senses.length) return const SizedBox.shrink();
    final example = senses[idiom.senseIndex].examples.firstOrNull;
    if (example == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(border: Border(left: BorderSide(color: c.rule, width: 3))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(example.en, style: EnglishText.body(c.ink).copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 4),
            Text(example.hi, style: hindi.body(c.inkMuted)),
          ],
        ),
      ),
    );
  }
}
