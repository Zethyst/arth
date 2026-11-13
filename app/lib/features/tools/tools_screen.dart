// The Tools hub: the things that help a reader *produce* English rather than
// only take it in.
//
// Everything else in Arth is receptive — a book goes in, meanings come out.
// These three go the other way: say what you mean in Hindi and get English,
// have what you wrote put right, and hear whether a word came out as the word
// you intended. That is the half of a language a reader-only app never reaches.

import 'package:arth/app/feel.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    return Scaffold(
      appBar: AppBar(title: Text(t.toolsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            t.toolsSubtitle,
            style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 14),
          ),
          const SizedBox(height: 20),
          _ToolCard(
            icon: Icons.record_voice_over_rounded,
            title: t.coachTitle,
            help: t.coachHelp,
            tint: c.accent,
            onTap: () => context.push('/tools/coach'),
          ),
          _ToolCard(
            icon: Icons.translate_rounded,
            title: t.translatorTitle,
            help: t.translatorHelp,
            tint: c.accent,
            onTap: () => context.push('/tools/translate'),
          ),
          _ToolCard(
            icon: Icons.spellcheck_rounded,
            title: t.spellCheckTitle,
            help: t.spellCheckHelp,
            tint: c.marigold,
            onTap: () => context.push('/tools/spell'),
          ),
          _ToolCard(
            icon: Icons.mic_rounded,
            title: t.sayItRightTitle,
            help: t.sayItRightHelp,
            tint: c.ink,
            onTap: () => context.push('/tools/say'),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends ConsumerWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.help,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String help;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Pressable.card(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: tint),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                child: Icon(icon, color: tint, size: 28),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: uiHeading(hindi: t.isHindi, color: c.ink, scale: scale)),
                      const SizedBox(height: 4),
                      Text(help, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 13.5)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Center(child: Icon(Icons.chevron_right_rounded, color: c.inkMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
