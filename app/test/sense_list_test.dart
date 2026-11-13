import 'package:arth/app/theme.dart';
import 'package:arth/core/models/contracts.dart';
import 'package:arth/features/dictionary/entry_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Sense _sense(int i, String pos, {String? styleLabel}) => Sense(
      index: i,
      partOfSpeech: pos,
      meaning: 'अर्थ $i',
      definition: 'परिभाषा $i।',
      styleLabel: styleLabel,
      examples: const [],
    );

Widget _app(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: ThemeData(extensions: const [ArthColors.light]),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

/// Every part-of-speech heading drawn, in order. A heading is a bare Text of
/// the part of speech; the per-sense tag is drawn inside a RichText instead.
List<String> _headings(WidgetTester t) => t
    .widgetList<Text>(find.byType(Text))
    .map((w) => w.data)
    .whereType<String>()
    .where((s) => s == 'संज्ञा' || s == 'क्रिया')
    .toList();

void main() {
  testWidgets('a short entry stays a flat list, with no headings', (t) async {
    final senses = [for (var i = 0; i < 5; i++) _sense(i, i < 3 ? 'क्रिया' : 'संज्ञा')];
    await t.pumpWidget(_app(SenseList(senses: senses)));
    expect(_headings(t), isEmpty);
  });

  testWidgets('a long entry spanning two parts of speech gets one heading each', (t) async {
    final senses = [for (var i = 0; i < 20; i++) _sense(i, i < 14 ? 'क्रिया' : 'संज्ञा')];
    await t.pumpWidget(_app(SenseList(senses: senses)));
    expect(_headings(t), ['क्रिया', 'संज्ञा']);
  });

  testWidgets('a long entry of one part of speech needs no headings', (t) async {
    final senses = [for (var i = 0; i < 20; i++) _sense(i, 'क्रिया')];
    await t.pumpWidget(_app(SenseList(senses: senses)));
    expect(_headings(t), isEmpty);
  });

  testWidgets('numbering is the sense index, so a grouped list names senses as /context does', (t) async {
    final senses = [for (var i = 0; i < 20; i++) _sense(i, i < 14 ? 'क्रिया' : 'संज्ञा')];
    await t.pumpWidget(_app(SenseList(senses: senses)));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('15'), findsOneWidget); // the first noun keeps its own number
    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('a pinned sense is lifted to the top and the list stays flat', (t) async {
    final senses = [for (var i = 0; i < 20; i++) _sense(i, i < 14 ? 'क्रिया' : 'संज्ञा')];
    await t.pumpWidget(_app(SenseList(senses: senses, pinnedIndex: 15)));
    expect(_headings(t), isEmpty);
    final first = t.widgetList<Text>(find.byType(Text)).map((w) => w.data).whereType<String>().first;
    expect(first, '16');
  });

  testWidgets('a style label shows beside a sense, and plain senses carry none', (t) async {
    await t.pumpWidget(_app(SenseList(senses: [_sense(0, 'क्रिया', styleLabel: 'स्लैंग'), _sense(1, 'क्रिया')])));
    final spans = t.widgetList<RichText>(find.byType(RichText)).map((w) => w.text.toPlainText()).toList();
    expect(spans.where((s) => s.contains('स्लैंग')), hasLength(1));
  });

  testWidgets('the tooltip still truncates to max', (t) async {
    final senses = [for (var i = 0; i < 20; i++) _sense(i, i < 14 ? 'क्रिया' : 'संज्ञा')];
    await t.pumpWidget(_app(SenseList(senses: senses, max: 3)));
    expect(_headings(t), isEmpty);
    expect(find.text('4'), findsNothing);
  });
}
