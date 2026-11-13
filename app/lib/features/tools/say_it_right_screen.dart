// Say It Right: hear a word, say it back, see how close you got.
//
// The words come from the reader's own saved vocabulary where there is any,
// and from the commonest part of the dictionary otherwise — practising words
// you have actually met beats practising a list. Recognition is the phone's
// own, so this costs nothing to run and works without an account.

import 'dart:async';
import 'dart:math';

import 'package:arth/app/feel.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/features/tools/listening.dart';
import 'package:arth/features/tools/pronunciation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Provider<ListeningService> listeningProvider = Provider<ListeningService>((_) => ListeningService());

/// Words to practise: the reader's own saved words first, then common ones.
final FutureProvider<List<String>> practiceWordsProvider = FutureProvider<List<String>>((ref) async {
  final store = ref.watch(localStoreProvider);
  final saved = [for (final v in await store.lifetimeVocabulary()) v.lemma];
  // Single words only: the recogniser is asked for one thing at a time, and
  // a phrase would be scored on the whole string.
  final mine = [for (final w in saved) if (!w.contains(' ') && w.length > 2) w];
  if (mine.length >= 10) return mine;
  final common = await store.searchWords('', limit: 400);
  final rest = [for (final w in common) if (!w.contains(' ') && w.length > 3) w];
  return [...mine, ...rest];
});

class SayItRightScreen extends ConsumerStatefulWidget {
  const SayItRightScreen({super.key});

  @override
  ConsumerState<SayItRightScreen> createState() => _SayItRightScreenState();
}

class _SayItRightScreenState extends ConsumerState<SayItRightScreen> {
  final _random = Random();
  String? _word;
  SaidResult? _result;
  String _partial = '';
  bool _listening = false;
  ListenBlock? _blocked;

  void _pick(List<String> words) {
    if (words.isEmpty) return;
    setState(() {
      _word = words[_random.nextInt(words.length)];
      _result = null;
      _partial = '';
    });
  }

  Future<void> _listen() async {
    final word = _word;
    if (word == null || _listening) return;
    final speech = ref.read(listeningProvider);
    if (!await speech.init()) {
      if (!mounted) return;
      setState(() => _blocked = speech.blocked ?? ListenBlock.unavailable);
      return;
    }
    Haptics.choose();
    setState(() {
      _listening = true;
      _result = null;
      _partial = '';
    });
    final heard = await speech.listenOnce(onPartial: (p) {
      if (mounted) setState(() => _partial = p);
    });
    if (!mounted) return;
    final scored = scoreSaid(word, heard);
    setState(() {
      _listening = false;
      _result = scored;
    });
    if (scored.how == SaidHow.clear) Haptics.commit();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final tts = ref.watch(ttsProvider);
    final words = ref.watch(practiceWordsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.sayItRightTitle)),
      body: words.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$e', style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            // A phone that has not downloaded the dictionary has nothing to
            // practise; spinning for ever is not an answer.
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  t.noWordsToPractise,
                  textAlign: TextAlign.center,
                  style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale),
                ),
              ),
            );
          }
          if (_word == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _pick(list));
            return const Center(child: CircularProgressIndicator());
          }
          final word = _word!;
          final result = _result;
          final blocked = _blocked;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              if (blocked != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    blocked == ListenBlock.denied ? t.micDenied : t.micUnavailable,
                    style: uiBody(hindi: t.isHindi, color: c.accent, scale: scale),
                  ),
                ),
              HardShadow(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: Column(
                    children: [
                      Text(word, style: EnglishText.word(c.ink, size: 34), textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      if (tts.hasEnglish)
                        TextButton.icon(
                          onPressed: () => tts.speakEnglish(word),
                          icon: Icon(Icons.volume_up_rounded, size: 18, color: c.accent),
                          label: Text(t.listen, style: uiLabel(hindi: t.isHindi, color: c.accent, scale: scale)),
                        ),
                      const SizedBox(height: 18),
                      if (result != null) _Needle(result: result),
                      if (_listening)
                        Text(
                          _partial.isEmpty ? t.listening : _partial,
                          style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Pressable(
                  onTap: _listen,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _listening ? c.accent : c.card,
                      border: Border.all(color: c.ink, width: 2),
                    ),
                    child: Icon(
                      Icons.mic_rounded,
                      size: 36,
                      color: _listening ? c.paper : c.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _listening ? t.listening : t.tapToSpeak,
                  style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (result != null)
                    Expanded(
                      child: OutlinedButton(onPressed: _listen, child: Text(t.sayAgain)),
                    ),
                  if (result != null) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(onPressed: () => _pick(list), child: Text(t.nextWord)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The score, and what it means in a word.
class _Needle extends ConsumerWidget {
  const _Needle({required this.result});

  final SaidResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final (label, tint) = switch (result.how) {
      // Green is not in the palette; the app's own marks are ink, marigold
      // and lac red, which is the same three-step scale.
      SaidHow.clear => (t.saidClear, c.ink),
      SaidHow.nearly => (t.saidNearly, c.marigold),
      SaidHow.off => (t.saidOff, c.accent),
    };
    return Column(
      children: [
        Text('${result.score}', style: EnglishText.word(tint, size: 40)),
        Text(label, style: uiLabel(hindi: t.isHindi, color: tint, scale: scale)),
        const SizedBox(height: 10),
        ClipRRect(
          child: LinearProgressIndicator(
            value: result.score / 100,
            minHeight: 8,
            color: tint,
            backgroundColor: c.rule,
          ),
        ),
        if (result.how != SaidHow.clear && result.heard.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            result.heard.isEmpty ? t.heardNothing : t.heardInstead(result.heard),
            style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 13),
            textAlign: TextAlign.center,
          ),
        ],
        if (result.heard.isEmpty) ...[
          const SizedBox(height: 10),
          Text(
            t.heardNothing,
            style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
