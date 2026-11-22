// A quote leaves the app as a picture: a square PNG the sharing apps take,
// with the book's dye behind it and the words shaped by Flutter.

import 'package:arth/app/settings.dart';
import 'package:arth/app/strings.dart';
import 'package:arth/data/local_store.dart';
import 'package:arth/features/cards/quote_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Flashcard _card(CardKind kind, String front) => Flashcard(
      id: '1',
      kind: kind,
      front: front,
      bookTitle: 'The Lighthouse Keeper',
      createdAt: DateTime(2026, 9, 2),
      updatedAt: DateTime(2026, 9, 2),
    );

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('a quote becomes a square picture', (tester) async {
    final bytes = await tester.runAsync(
      () => buildQuoteImage(
        card: _card(CardKind.quote, 'He had lived in solitude for eleven years, keeping the lamp.'),
        bookTitle: 'The Lighthouse Keeper',
        sharedBy: 'Meera',
        strings: AppStrings.en,
        scale: 1,
        font: CardFont.montserrat,
      ),
    );
    expect(bytes!.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], reason: 'a PNG');
    // The IHDR width and height, big-endian, straight after the signature.
    int at(int i) => (bytes[i] << 24) | (bytes[i + 1] << 16) | (bytes[i + 2] << 8) | bytes[i + 3];
    expect(at(16), 1080);
    expect(at(20), 1080);
  });

  testWidgets('a long Hindi passage and a bare idea both fit the square', (tester) async {
    for (final (kind, text) in [
      (CardKind.idea, 'एकांत में रहना अपने आप को सुनना है। ' * 12),
      (CardKind.idea, 'Why the letter changes everything'),
    ]) {
      final bytes = await tester.runAsync(
        () => buildQuoteImage(
          card: _card(kind, text),
          bookTitle: 'Godaan',
          strings: AppStrings.hi,
          scale: 1,
          font: CardFont.bricolage,
        ),
      );
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(1000));
    }
    expect(tester.takeException(), isNull, reason: 'nothing overflowed the square');
  });
}
