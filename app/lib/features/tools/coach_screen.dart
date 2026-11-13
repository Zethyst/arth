// Speaking practice: a short role-play the learner talks their way through.
//
// Press to talk, not a live call. The phone's recogniser needs a pause to
// finalise and the model needs a second to answer, so a turn is two to four
// seconds — honest about that rather than pretending to be a phone call that
// keeps stalling.
//
// What the recogniser heard is always shown before it is sent, and can be
// edited. On-device recognition of Indian-accented English mishears often
// enough that a coach correcting a sentence the learner never said would be
// worse than no coach at all.

import 'dart:async';

import 'package:arth/app/feel.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/strings.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/core/models/contracts.dart';
import 'package:arth/data/api_client.dart';
import 'package:arth/features/tools/coach_session.dart';
import 'package:arth/features/tools/listening.dart';
import 'package:arth/features/tools/say_it_right_screen.dart' show listeningProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

String sceneLabel(CoachScene s, AppStrings t) => switch (s) {
      CoachScene.interview => t.sceneInterview,
      CoachScene.shop => t.sceneShop,
      CoachScene.doctor => t.sceneDoctor,
      CoachScene.introductions => t.sceneIntroductions,
    };

IconData sceneIcon(CoachScene s) => switch (s) {
      CoachScene.interview => Icons.work_outline_rounded,
      CoachScene.shop => Icons.shopping_bag_outlined,
      CoachScene.doctor => Icons.medical_services_outlined,
      CoachScene.introductions => Icons.waving_hand_outlined,
    };

/// Pick a scene.
class CoachPickScreen extends ConsumerWidget {
  const CoachPickScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    return Scaffold(
      appBar: AppBar(title: Text(t.coachTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(t.coachHelp, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 14)),
          const SizedBox(height: 20),
          Text(t.coachPick, style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
          const SizedBox(height: 10),
          for (final s in CoachScene.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Pressable.card(
                depth: 3,
                onTap: () => context.push('/tools/coach/${s.name}'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(sceneIcon(s), color: c.accent),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          sceneLabel(s, t),
                          style: uiHeading(hindi: t.isHindi, color: c.ink, scale: scale),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: c.inkMuted),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The conversation itself.
class CoachCallScreen extends ConsumerStatefulWidget {
  const CoachCallScreen({required this.scene, super.key});

  final CoachScene scene;

  @override
  ConsumerState<CoachCallScreen> createState() => _CoachCallScreenState();
}

class _CoachCallScreenState extends ConsumerState<CoachCallScreen> {
  late final CoachSession _session = CoachSession(widget.scene);
  final _draft = TextEditingController();
  final _scroll = ScrollController();
  String? _error;
  ListenBlock? _blocked;

  @override
  void initState() {
    super.initState();
    unawaited(_openScene());
  }

  @override
  void dispose() {
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openScene() => _ask(said: '');

  /// One round trip: send what the learner said, take the coach's answer.
  Future<void> _ask({required String said}) async {
    setState(() => _error = null);
    try {
      final turn = await ref.read(apiClientProvider).coach(
            scenario: widget.scene.name,
            turns: _session.history,
            said: said,
          );
      if (!mounted) return;
      setState(() => said.isEmpty ? _session.addCoach(turn) : _session.applyReply(turn));
      _speak(turn.reply);
      _toBottom();
    } on ApiFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ref.read(stringsProvider).errorForFeature(e.code, e.message);
        // A failed send must not strand the learner mid-turn.
        if (_session.stage == CoachStage.waiting) _session.stage = CoachStage.theirTurn;
        if (_session.stage == CoachStage.opening) _session.stage = CoachStage.theirTurn;
      });
    }
  }

  void _speak(String text) {
    final tts = ref.read(ttsProvider);
    if (tts.hasEnglish) unawaited(tts.speakCoach(text));
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          unawaited(_scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: Motion.of(context, Motion.quick),
            curve: Motion.arrive,
          ));
        }
      });

  Future<void> _listen() async {
    final speech = ref.read(listeningProvider);
    if (!await speech.init()) {
      if (!mounted) return;
      setState(() => _blocked = speech.blocked ?? ListenBlock.unavailable);
      return;
    }
    Haptics.choose();
    setState(() => _session.stage = CoachStage.listening);
    // A sentence takes longer than a word, and a learner searching for one
    // takes longer still.
    final heard = await speech.listenOnce(limit: const Duration(seconds: 12));
    if (!mounted) return;
    setState(() {
      _session.heard(heard);
      _draft.text = _session.draft;
    });
  }

  Future<void> _send() async {
    final text = _draft.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _session.addLearner(text));
    _toBottom();
    await _ask(said: text);
  }

  void _end() {
    setState(() => _session.end());
    _toBottom();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    return Scaffold(
      appBar: AppBar(
        title: Text(sceneLabel(widget.scene, t)),
        actions: [
          if (_session.stage != CoachStage.ended)
            TextButton(onPressed: _end, child: Text(t.coachEnd)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                for (final line in _session.lines) _Line(line: line),
                if (_session.stage == CoachStage.opening || _session.stage == CoachStage.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_session.stage == CoachStage.ended) _Ended(session: _session, scene: widget.scene),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: uiBody(hindi: t.isHindi, color: c.accent, scale: scale)),
                  ),
                if (_blocked != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _blocked == ListenBlock.denied ? t.micDenied : t.micUnavailable,
                      style: uiBody(hindi: t.isHindi, color: c.accent, scale: scale),
                    ),
                  ),
              ],
            ),
          ),
          if (_session.stage != CoachStage.ended) _Bar(
            stage: _session.stage,
            draft: _draft,
            onListen: _listen,
            onSend: _send,
            onRetry: _listen,
          ),
        ],
      ),
    );
  }
}

/// One line of the conversation.
class _Line extends ConsumerWidget {
  const _Line({required this.line});

  final CoachLine line;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final h = HindiText(scale);
    final tts = ref.watch(ttsProvider);
    final mine = line.speaker == Speaker.learner;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: mine ? c.accent.withValues(alpha: 0.12) : c.card,
              border: Border.all(color: mine ? c.accent : c.ink, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.text, style: EnglishText.body(c.ink, size: 16)),
                if (line.hindi != null) ...[
                  const SizedBox(height: 4),
                  Text(line.hindi!, style: h.small(c.inkMuted)),
                ],
              ],
            ),
          ),
          if (!mine && tts.hasEnglish)
            TextButton.icon(
              onPressed: () => tts.speakCoach(line.text),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              icon: Icon(Icons.volume_up_rounded, size: 16, color: c.inkMuted),
              label: Text(t.listen, style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
            ),
          if (line.better != null) _Better(better: line.better!),
        ],
      ),
    );
  }
}

/// The correction, under the line it corrects.
class _Better extends ConsumerWidget {
  const _Better({required this.better});

  final CoachTurnBetter better;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final h = HindiText(scale);
    final tts = ref.watch(ttsProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: c.marigold, width: 3)),
          color: c.marigold.withValues(alpha: 0.10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.coachBetter, style: uiLabel(hindi: t.isHindi, color: c.marigold, scale: scale)),
            const SizedBox(height: 4),
            Text(better.text, style: EnglishText.body(c.ink, size: 16)),
            const SizedBox(height: 4),
            Text(better.why, style: h.small(c.inkMuted)),
            if (tts.hasEnglish)
              TextButton.icon(
                onPressed: () => tts.speakEnglish(better.text),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                icon: Icon(Icons.volume_up_rounded, size: 16, color: c.inkMuted),
                label: Text(t.listen, style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
              ),
          ],
        ),
      ),
    );
  }
}

/// The microphone, and the check of what it heard.
class _Bar extends ConsumerWidget {
  const _Bar({
    required this.stage,
    required this.draft,
    required this.onListen,
    required this.onSend,
    required this.onRetry,
  });

  final CoachStage stage;
  final TextEditingController draft;
  final VoidCallback onListen;
  final VoidCallback onSend;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.ink))),
      child: switch (stage) {
        // Shown before it is sent, and editable: the recogniser mishears, and
        // being corrected for a word you never said teaches the wrong thing.
        CoachStage.checking => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.coachCheckHeard, style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
              const SizedBox(height: 8),
              TextField(
                controller: draft,
                maxLines: 3,
                minLines: 1,
                style: EnglishText.body(c.ink, size: 16),
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: onRetry, child: Text(t.coachRetry))),
                  const SizedBox(width: 10),
                  Expanded(child: FilledButton(onPressed: onSend, child: Text(t.coachSend))),
                ],
              ),
            ],
          ),
        CoachStage.listening => Row(
            children: [
              Icon(Icons.mic_rounded, color: c.accent),
              const SizedBox(width: 12),
              Text(t.listening, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
            ],
          ),
        _ => SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: stage == CoachStage.theirTurn ? onListen : null,
              icon: const Icon(Icons.mic_rounded),
              label: Text(t.coachStartTalking),
            ),
          ),
      },
    );
  }
}

/// What the call came to.
class _Ended extends ConsumerWidget {
  const _Ended({required this.session, required this.scene});

  final CoachSession session;
  final CoachScene scene;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final h = HindiText(scale);
    final polish = session.toPolish;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1.2, color: c.accent.withValues(alpha: 0.35)),
          const SizedBox(height: 16),
          Text(t.coachEnded, style: uiHeading(hindi: t.isHindi, color: c.ink, scale: scale)),
          const SizedBox(height: 6),
          Text(
            '${t.coachRepliesCount(session.replies)}  ·  ${t.coachPolishCount(polish.length)}',
            style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 13.5),
          ),
          const SizedBox(height: 18),
          if (polish.isEmpty)
            Text(t.coachNothingToPolish, style: uiBody(hindi: t.isHindi, color: c.ink, scale: scale))
          else ...[
            Text(t.coachSayAgain, style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
            const SizedBox(height: 10),
            for (final line in polish)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.text,
                      style: EnglishText.body(c.inkMuted)
                          .copyWith(decoration: TextDecoration.lineThrough),
                    ),
                    const SizedBox(height: 2),
                    Text(line.better!.text, style: EnglishText.body(c.ink, size: 16)),
                    Text(line.better!.why, style: h.small(c.inkMuted)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.pushReplacement('/tools/coach/${scene.name}'),
              child: Text(t.coachAgain),
            ),
          ),
        ],
      ),
    );
  }
}
