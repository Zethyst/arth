// Translator: Hindi in, English out.
//
// The reverse of what the reader tooltip does. There the English is on the
// page and the Hindi is the answer; here the reader knows exactly what they
// mean and is missing only the English for it. The alternatives matter as much
// as the translation — the first English a learner is handed is rarely the one
// their situation wants, and being shown formal beside casual is how you learn
// that the choice exists.

import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/core/models/contracts.dart';
import 'package:arth/data/api_client.dart';
import 'package:arth/features/tools/tool_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TranslatorScreen extends ConsumerStatefulWidget {
  const TranslatorScreen({super.key});

  @override
  ConsumerState<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends ConsumerState<TranslatorScreen> {
  final _controller = TextEditingController();
  EnglishDraft? _draft;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final draft = await ref.read(apiClientProvider).toEnglish(text: text);
      if (!mounted) return;
      setState(() => _draft = draft);
    } on ApiFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = ref.read(stringsProvider).errorForFeature(e.code, e.message));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final h = HindiText(scale);
    final draft = _draft;
    return Scaffold(
      appBar: AppBar(title: Text(t.translatorTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          TextField(
            controller: _controller,
            maxLines: 4,
            minLines: 2,
            textInputAction: TextInputAction.newline,
            style: h.body(c.ink),
            decoration: InputDecoration(
              hintText: t.translatorHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ToolRunButton(label: t.translatorGo, busy: _busy, onPressed: _run),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
          ],
          if (draft != null) ...[
            const SizedBox(height: 20),
            ToolResultCard(
              text: draft.english,
              onCopy: () => _copy(draft.english),
              speakEnglish: true,
            ),
            if (draft.vocab.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(t.worthLearning, style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final v in draft.vocab) BilingualChip(en: v.en, hi: v.hi)],
              ),
            ],
            if (draft.alternatives.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(t.otherWays, style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
              const SizedBox(height: 8),
              for (final a in draft.alternatives)
                AlternativeRow(
                  tone: toneLabel(a.tone.name, t),
                  text: a.text,
                  onCopy: () => _copy(a.text),
                ),
            ],
          ],
        ],
      ),
    );
  }

  void _copy(String text) {
    unawaitedCopy(text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ref.read(stringsProvider).copied), duration: const Duration(seconds: 1)),
    );
  }
}

void unawaitedCopy(String text) => Clipboard.setData(ClipboardData(text: text));
