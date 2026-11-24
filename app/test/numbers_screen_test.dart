import 'package:arth/app/theme.dart';
import 'package:arth/features/tools/numbers_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A number's Hindi name is drawn as a bare Text, so finding it is enough to
/// know its card was laid out.
Finder _text(String s) => find.text(s);

/// The screen at a phone's width — the cards carry four names across, and an
/// overflow would only show at a real width, not the 800x600 test default.
///
/// A RenderFlex overflow fails a widget test on its own, so every pump below
/// is also the check that nothing overflowed.
Future<void> _open(WidgetTester t) async {
  await t.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: arthTheme(Brightness.light),
        home: const NumbersScreen(),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> _search(WidgetTester t, String q) async {
  await t.enterText(find.byType(TextField), q);
  await t.pumpAndSettle();
}

/// Brings the foot of the list into view. Six of the ten cards fit a phone,
/// so the last of a ten isn't built until it's scrolled to.
Future<void> _toFoot(WidgetTester t) async {
  await t.drag(find.byType(ListView).last, const Offset(0, -600));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('opens on the first ten, all four names to a number', (t) async {
    await _open(t);

    expect(_text('१'), findsOneWidget);
    expect(_text('एक'), findsOneWidget);
    expect(_text('ek'), findsOneWidget);
    expect(_text('one'), findsOneWidget);
    // The eleventh belongs to the next ten and is nowhere on this screen.
    expect(_text('ग्यारह'), findsNothing);

    await _toFoot(t);
    expect(_text('दस'), findsOneWidget);
    expect(_text('ten'), findsOneWidget);
    expect(_text('ग्यारह'), findsNothing);
  });

  testWidgets('carries the note that ties the ten together', (t) async {
    await _open(t);
    expect(_text('The ten the other ninety are built from.'), findsOneWidget);
  });

  testWidgets('a later ten replaces the one before it', (t) async {
    await _open(t);

    await t.tap(_text('31–40'));
    await t.pumpAndSettle();

    expect(_text('इकतीस'), findsOneWidget);
    expect(_text('thirty-one'), findsOneWidget);
    expect(_text('एक'), findsNothing);
    expect(_text('-tees runs through the thirties. Untaalees is one short of chaalees.'), findsOneWidget);

    await _toFoot(t);
    expect(_text('चालीस'), findsOneWidget);
  });

  testWidgets('search cuts across all hundred, and clearing puts the tens back', (t) async {
    await _open(t);

    await _search(t, 'ninety-nine');
    expect(_text('निन्यानवे'), findsOneWidget);
    expect(_text('एक'), findsNothing);
    // The decade strip steps aside while searching.
    expect(_text('1–10'), findsNothing);

    await _search(t, '');
    expect(_text('एक'), findsOneWidget);
    expect(_text('1–10'), findsOneWidget);
  });

  testWidgets('finds a number by its Hindi name, and by a Devanagari digit', (t) async {
    await _open(t);

    await _search(t, 'बयालीस');
    expect(_text('forty-two'), findsOneWidget);

    await _search(t, '४२');
    expect(_text('forty-two'), findsOneWidget);
  });

  testWidgets('says so when nothing matches', (t) async {
    await _open(t);
    await _search(t, 'zzz');

    expect(_text('No number by that name.'), findsOneWidget);
    expect(_text('एक'), findsNothing);
  });

  testWidgets('draws the longest names without overflowing', (t) async {
    await _open(t);

    // The nineties hold the longest of all hundred — निन्यानवे, chauraanave,
    // ninety-seven — and 100 adds a third digit to the left column.
    await _search(t, '9');
    await _toFoot(t);
    expect(_text('चौरानवे'), findsOneWidget);

    await _search(t, '100');
    expect(_text('१००'), findsOneWidget);
    expect(_text('सौ'), findsOneWidget);
    expect(_text('one hundred'), findsOneWidget);
  });
}
