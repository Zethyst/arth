// One idiom in full: what it means, it doing its job in a sentence, how it is
// marked, and — where Wiktionary records one — where it came from.

import 'dart:async';

import 'package:arth/app/feel.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/features/dictionary/entry_widgets.dart';
import 'package:arth/features/idioms/idiom_providers.dart';
import 'package:arth/features/idioms/idiom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class IdiomScreen extends ConsumerWidget {
  const IdiomScreen({required this.phrase, super.key});

  final String phrase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final scale = settings.hindiScale;
    final h = HindiText(scale);
    final idiom = ref.watch(idiomProvider(phrase));

    if (idiom == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.idiomsTitle)),
        body: Center(child: Text(t.notFound, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.idiomsTitle),
        actions: [
          IconButton(
            tooltip: idiom.saved ? t.idiomSaved2 : t.idiomSave,
            icon: Icon(idiom.saved ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: c.accent),
            onPressed: () {
              Haptics.commit();
              unawaited(ref.read(idiomsProvider.notifier).setSaved(idiom.phrase, saved: !idiom.saved));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(idiom.phrase, style: EnglishText.word(c.ink, size: 30)),
            const SizedBox(height: 10),
            IdiomTagRow(tags: idiom.tags),
            const SizedBox(height: 14),
            Text(idiom.meaning, style: h.headline(c.ink)),
            const SizedBox(height: 6),
            Text(idiom.sense.definition, style: h.body(c.ink)),
            if (idiom.examples.isNotEmpty) ...[
              SectionLabel(t.idiomInUse),
              for (final ex in idiom.examples)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(border: Border(left: BorderSide(color: c.marigold, width: 3))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ex.en, style: EnglishText.body(c.ink, size: 16)),
                        const SizedBox(height: 4),
                        Text(ex.hi, style: h.small(c.inkMuted)),
                      ],
                    ),
                  ),
                ),
            ],
            SectionLabel(t.idiomStory),
            Text(
              idiom.etymology.isEmpty ? t.idiomStoryNone : idiom.etymology,
              style: idiom.etymology.isEmpty
                  ? uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale)
                  : EnglishText.body(c.ink),
            ),
            const SizedBox(height: 20),
            // The whole entry, including the senses this idiom is not about.
            TextButton.icon(
              onPressed: () => context.push('/word/${Uri.encodeComponent(idiom.phrase)}'),
              icon: Icon(Icons.menu_book_outlined, color: c.accent),
              label: Text(t.seeFullEntry, style: uiLabel(hindi: t.isHindi, color: c.accent, scale: scale)),
            ),
            const SizedBox(height: 16),
            Text(t.attribution, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 12.5)),
          ],
        ),
      ),
    );
  }
}
