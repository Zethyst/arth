// Every idiom the phone holds, commonest first, with a search box and a
// filter for the ones the reader kept. Entirely offline.

import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/data/local_store.dart';
import 'package:arth/features/idioms/idiom_providers.dart';
import 'package:arth/features/idioms/idiom_selection.dart';
import 'package:arth/features/idioms/idiom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Idioms matching [query] in either language, best known first.
///
/// [kind] narrows to phrasal verbs or to figurative idioms; null is both,
/// which is the list a reader opens on.
List<IdiomRow> filterIdioms(
  List<IdiomRow> all,
  String query, {
  bool savedOnly = false,
  IdiomKind? kind,
}) {
  final q = query.trim().toLowerCase();
  return <IdiomRow>[
    for (final i in all)
      if ((!savedOnly || i.saved) &&
          (kind == null || i.kind == kind) &&
          (q.isEmpty || i.phrase.toLowerCase().contains(q) || i.meaning.contains(q) || i.sense.definition.contains(q)))
        i,
  ]..sort(compareForBrowsing);
}

class IdiomsBrowseScreen extends ConsumerStatefulWidget {
  const IdiomsBrowseScreen({super.key, this.savedOnly = false});

  final bool savedOnly;

  @override
  ConsumerState<IdiomsBrowseScreen> createState() => _IdiomsBrowseScreenState();
}

class _IdiomsBrowseScreenState extends ConsumerState<IdiomsBrowseScreen> {
  final _controller = TextEditingController();
  late bool _savedOnly = widget.savedOnly;
  bool _phrasalOnly = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final all = ref.watch(idiomsProvider).valueOrNull ?? const <IdiomRow>[];
    final shown = filterIdioms(
      all,
      _controller.text,
      savedOnly: _savedOnly,
      kind: _phrasalOnly ? IdiomKind.phrasal : null,
    );
    return Scaffold(
      appBar: AppBar(title: Text(t.idiomsTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              style: EnglishText.body(c.ink, size: 16),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: t.idiomsTitle,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(t.idiomCount(shown.length), style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 13)),
                const Spacer(),
                FilterChip(
                  selected: _phrasalOnly,
                  label: Text(t.phrasalVerbs),
                  onSelected: (v) => setState(() => _phrasalOnly = v),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _savedOnly,
                  label: Text(t.idiomsSaved),
                  onSelected: (v) => setState(() => _savedOnly = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        all.isEmpty ? t.idiomsEmpty : t.notFound,
                        textAlign: TextAlign.center,
                        style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (_, i) => IdiomTile(
                      idiom: shown[i],
                      onTap: () => context.push('/idiom/${Uri.encodeComponent(shown[i].phrase)}'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
