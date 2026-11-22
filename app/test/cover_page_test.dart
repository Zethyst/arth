// The cover page is painted, not built, so nothing lays it out for it: it has
// to draw at whatever size it is given — a phone's page, a page-shaped band in
// the scrolling layout, a landscape screen.

import 'dart:ui' as ui;

import 'package:arth/app/theme.dart';
import 'package:arth/features/reader/cover_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const colors = ArthColors.light;

  test('the cover draws at any size', () {
    for (final size in const [Size(390, 700), Size(612, 792), Size(840, 390), Size(60, 90), Size(1, 1)]) {
      final recorder = ui.PictureRecorder();
      paintCoverPage(Canvas(recorder), size, title: 'Godan', c: colors);
      expect(recorder.endRecording(), isNotNull, reason: '$size');
    }
  });

  test('a book with no title still gets a cover', () {
    final recorder = ui.PictureRecorder();
    paintCoverPage(Canvas(recorder), const Size(390, 700), title: '   ', c: colors);
    expect(recorder.endRecording(), isNotNull);
  });

  testWidgets('the cover page fills the space it is given', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: arthTheme(Brightness.light),
        home: const Scaffold(body: CoverPage(title: 'The Guide')),
      ),
    );
    expect(tester.getSize(find.byType(CoverPage)).isEmpty, isFalse);
  });

  testWidgets('a tap on the cover turns it', (tester) async {
    var turned = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: arthTheme(Brightness.light),
        home: Scaffold(body: CoverPage(title: 'The Guide', onTap: () => turned++)),
      ),
    );
    await tester.tap(find.byType(CoverPage));
    expect(turned, 1);
  });

  testWidgets('the cover sheet lets the reader through once it is away', (tester) async {
    Widget sheet({required bool showing}) => MaterialApp(
          theme: arthTheme(Brightness.light),
          home: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(child: GestureDetector(onTap: () {}, child: const ColoredBox(color: Colors.white))),
                Positioned.fill(child: CoverSheet(title: 'Godan', showing: showing, onOpen: () {})),
              ],
            ),
          ),
        );

    await tester.pumpWidget(sheet(showing: true));
    expect(tester.widget<IgnorePointer>(find.ancestor(of: find.byType(CoverPage), matching: find.byType(IgnorePointer)).first).ignoring, isFalse);

    await tester.pumpWidget(sheet(showing: false));
    await tester.pumpAndSettle();
    expect(tester.widget<IgnorePointer>(find.ancestor(of: find.byType(CoverPage), matching: find.byType(IgnorePointer)).first).ignoring, isTrue);
  });
}
