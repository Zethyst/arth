// Today's idioms: ten a day, one card at a time.
//
// The front is the idiom and what it means; turning it over shows the phrase
// doing its job in a real sentence, with the Hindi underneath. Both sides
// come from the dictionary entry the idiom points at — nothing here is
// written by a model, and the whole screen works offline.

import 'dart:async';
import 'dart:math';

import 'package:arth/app/feel.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/data/local_store.dart';
import 'package:arth/features/idioms/idiom_providers.dart';
import 'package:arth/features/idioms/idiom_selection.dart';
import 'package:arth/features/idioms/idiom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class IdiomsScreen extends ConsumerStatefulWidget {
  const IdiomsScreen({super.key});

  @override
  ConsumerState<IdiomsScreen> createState() => _IdiomsScreenState();
}

class _IdiomsScreenState extends ConsumerState<IdiomsScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _flip =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  int _index = 0;
  bool _done = false;

  /// Frozen when the screen opens: marking a card seen rewrites the list, and
  /// a live set would shuffle the remaining cards out from under the reader.
  List<IdiomRow>? _set;

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  bool get _flipped => _flip.value >= 0.5;

  void _toggleFlip() {
    Haptics.choose();
    unawaited(_flipped ? _flip.reverse() : _flip.forward());
  }

  Future<void> _advance(IdiomRow idiom) async {
    final set = _set!;
    await ref.read(idiomsProvider.notifier).markSeen(idiom.phrase);
    if (!mounted) return;
    setState(() {
      _flip.value = 0;
      if (_index + 1 >= set.length) {
        _done = true;
      } else {
        _index++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    // The set is chosen once the dictionary has loaded, then frozen: marking
    // a card seen rewrites the list, and a live set would shuffle the cards
    // still to come out from under the reader.
    final loaded = ref.watch(idiomsProvider);
    if (_set == null && loaded.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(t.idiomsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final List<IdiomRow> set;
    final chosen = _set;
    if (chosen != null) {
      set = chosen;
    } else {
      set = dailySet(loaded.valueOrNull ?? const <IdiomRow>[], DateTime.now());
      _set = set;
    }

    if (set.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(t.idiomsTitle)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(t.idiomsEmpty, textAlign: TextAlign.center, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale))),
        ),
      );
    }

    if (_done) {
      return Scaffold(
        appBar: AppBar(title: Text(t.idiomsTitle)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(t.idiomDone, style: uiHeading(hindi: t.isHindi, color: c.ink, scale: scale)),
              const SizedBox(height: 8),
              Text(t.idiomDoneBlurb, textAlign: TextAlign.center, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => context.push('/idioms/all'), child: Text(t.idiomsSeeAll)),
              TextButton(onPressed: () => context.push('/idioms/practice'), child: Text(t.idiomsPractice)),
            ],
          ),
        ),
      );
    }

    final idiom = set[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(t.idiomsToday(set.length)),
        actions: [
          IconButton(
            tooltip: t.idiomsSeeAll,
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: () => context.push('/idioms/all'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            _Progress(at: _index + 1, of: set.length),
            const SizedBox(height: 16),
            Expanded(
              child: GestureDetector(
                onTap: _toggleFlip,
                child: AnimatedBuilder(
                  animation: _flip,
                  builder: (_, _) {
                    final angle = _flip.value * pi;
                    final back = angle > pi / 2;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateY(angle),
                      child: back
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(pi),
                              child: IdiomCardBack(idiom: idiom),
                            )
                          : IdiomCardFront(idiom: idiom),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => unawaited(_advance(idiom)),
                    child: Text(t.idiomSkip),
                  ),
                ),
                const SizedBox(width: 10),
                _SaveButton(idiom: idiom),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => unawaited(_advance(idiom)),
                    child: Text(t.idiomNext),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// How far through today's set the reader is.
class _Progress extends StatelessWidget {
  const _Progress({required this.at, required this.of});

  final int at;
  final int of;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        for (var i = 0; i < of; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i < at ? c.accent : c.rule,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SaveButton extends ConsumerWidget {
  const _SaveButton({required this.idiom});

  final IdiomRow idiom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    // The frozen set holds the row as it was; the live list knows if it has
    // been saved since.
    final saved = ref.watch(idiomProvider(idiom.phrase))?.saved ?? idiom.saved;
    return IconButton.filledTonal(
      tooltip: saved ? t.idiomSaved2 : t.idiomSave,
      icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: c.accent),
      onPressed: () {
        Haptics.commit();
        unawaited(ref.read(idiomsProvider.notifier).setSaved(idiom.phrase, saved: !saved));
      },
    );
  }
}
