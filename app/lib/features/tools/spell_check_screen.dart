// Spell check: the reader's own English, put right.
//
// Every fix quotes the words it replaces, so each one can be underlined where
// it actually appears rather than listed somewhere below — a correction you
// have to hunt for in your own text teaches nothing. The reason is in Hindi,
// for the same reason.

import 'dart:async';

import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/core/models/contracts.dart';
import 'package:arth/data/api_client.dart';
import 'package:arth/features/tools/tool_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpellCheckScreen extends ConsumerStatefulWidget {
  const SpellCheckScreen({super.key});

  @override
  ConsumerState<SpellCheckScreen> createState() => _SpellCheckScreenState();
}

class _SpellCheckScreenState extends ConsumerState<SpellCheckScreen> {
  final _controller = TextEditingController();
  Proofread? _result;
  String? _checked;
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
      final out = await ref.read(apiClientProvider).proofread(text: text);
      if (!mounted) return;
      setState(() {
        _result = out;
        _checked = text;
      });
    } on ApiFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = ref.read(stringsProvider).errorForFeature(e.code, e.message));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ref.read(stringsProvider).copied), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final h = HindiText(scale);
    final result = _result;
    final checked = _checked;
    return Scaffold(
      appBar: AppBar(title: Text(t.spellCheckTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          if (result != null && checked != null)
            // What the reader wrote, with every fix marked where it happened.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(border: Border.all(color: c.ink, width: 1.5)),
              child: RichText(
                text: TextSpan(children: markFixes(checked, result.fixes, c)),
              ),
            )
          else
            TextField(
              controller: _controller,
              maxLines: 8,
              minLines: 3,
              textInputAction: TextInputAction.newline,
              style: EnglishText.body(c.ink, size: 16),
              decoration: InputDecoration(
                hintText: t.spellCheckHint,
                border: const OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 12),
          if (result == null)
            ToolRunButton(label: t.spellCheckGo, busy: _busy, onPressed: _run)
          else
            OutlinedButton(
              onPressed: () => setState(() {
                _result = null;
                _checked = null;
              }),
              child: Text(t.spellCheckGo),
            ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
          ],
          if (result != null) ...[
            const SizedBox(height: 20),
            if (result.fixes.isEmpty)
              Text(t.spellCheckClean, style: uiBody(hindi: t.isHindi, color: c.ink, scale: scale))
            else ...[
              Row(
                children: [
                  Text(t.correctedVersion, style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
                  const SizedBox(width: 10),
                  Text(
                    t.fixCount(result.fixes.length),
                    style: uiLabel(hindi: t.isHindi, color: c.accent, scale: scale),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ToolResultCard(
                text: result.corrected,
                onCopy: () => unawaited(_copy(result.corrected)),
                speakEnglish: true,
              ),
              const SizedBox(height: 18),
              for (final f in result.fixes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            f.wrong,
                            style: EnglishText.body(c.inkMuted).copyWith(
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: c.inkMuted),
                          const SizedBox(width: 8),
                          Flexible(child: Text(f.right, style: EnglishText.body(c.accent))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(f.why, style: h.small(c.inkMuted)),
                    ],
                  ),
                ),
            ],
            if (result.alternatives.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(t.otherWays, style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
              const SizedBox(height: 8),
              for (final a in result.alternatives)
                AlternativeRow(
                  tone: toneLabel(a.tone.name, t),
                  text: a.text,
                  onCopy: () => unawaited(_copy(a.text)),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

/// The reader's text split into spans, with each fix's words underlined where
/// they occur. Fixes are applied left to right and never overlap: a fix whose
/// words have already been passed is skipped rather than shifting the rest.
List<TextSpan> markFixes(String text, List<ProofreadFixes> fixes, ArthColors c) {
  final plain = EnglishText.body(c.ink, size: 16);
  final marked = plain.copyWith(
    decoration: TextDecoration.underline,
    decorationColor: c.accent,
    decorationStyle: TextDecorationStyle.wavy,
    decorationThickness: 2,
  );
  final spans = <TextSpan>[];
  var at = 0;
  for (final f in fixes) {
    final found = text.indexOf(f.wrong, at);
    if (found < 0) continue;
    if (found > at) spans.add(TextSpan(text: text.substring(at, found), style: plain));
    spans.add(TextSpan(text: f.wrong, style: marked));
    at = found + f.wrong.length;
  }
  if (at < text.length) spans.add(TextSpan(text: text.substring(at), style: plain));
  return spans;
}
