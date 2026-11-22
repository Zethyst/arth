// One quote as a picture to send: the book's dye and block print behind it,
// the words in the recap's own font, whose book it is and who shared it.
// Drawn by Flutter off screen (core/render/widget_image.dart) so Devanagari
// is shaped, and sent as a PNG through the share sheet.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:arth/app/providers.dart';
import 'package:arth/app/settings.dart';
import 'package:arth/app/strings.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/core/render/widget_image.dart';
import 'package:arth/data/local_store.dart';
import 'package:arth/features/cards/card_face.dart';
import 'package:arth/features/library/book_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// The card's size in points, and how many pixels each point becomes. 1080px
/// square: what the places these are sent to want.
const _side = 360.0;
const _pixelRatio = 3.0;

/// Builds the picture for [card] and opens the share sheet. [sharedBy] is the
/// reader whose recap it came from, when it isn't the sender's own.
/// [origin] is where the share sheet points from on an iPad.
Future<void> shareQuoteImage(
  BuildContext context,
  WidgetRef ref, {
  required Flashcard card,
  required String bookTitle,
  String? sharedBy,
  CardFont? font,
  Rect? origin,
}) async {
  final t = ref.read(stringsProvider);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final settings = ref.read(settingsProvider);
  File? file;
  try {
    final bytes = await buildQuoteImage(
      card: card,
      bookTitle: bookTitle,
      sharedBy: sharedBy,
      strings: t,
      scale: settings.hindiScale,
      font: font ?? settings.cardFont,
    );
    final dir = await getTemporaryDirectory();
    file = File('${dir.path}/arth-quote.png');
    await file.writeAsBytes(bytes, flush: true);
    // Anything at all, not only Exceptions: see deck_pdf.dart. A failure
    // nobody is told about reads as a button that does nothing.
    // ignore: avoid_catches_without_on_clauses
  } catch (e, stack) {
    debugPrint('quote image failed: $e\n$stack');
    file = null;
  }
  if (file == null) {
    messenger?.showSnackBar(SnackBar(content: Text(t.quoteImageFailed), persist: false));
    return;
  }
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path, mimeType: 'image/png')], sharePositionOrigin: origin),
  );
}

/// The picture itself, as PNG bytes.
Future<Uint8List> buildQuoteImage({
  required Flashcard card,
  required String bookTitle,
  required AppStrings strings,
  required double scale,
  required CardFont font,
  String? sharedBy,
}) async {
  final widget = _QuoteCard(card: card, bookTitle: bookTitle, sharedBy: sharedBy, strings: strings, scale: scale, font: font);
  // The fonts may still be coming: draw once to ask for them, wait a little,
  // then draw for real. A face that doesn't arrive falls back to one here.
  (await renderOffScreen(widget, width: _side, maxHeight: _side, pixelRatio: 1)).dispose();
  try {
    await GoogleFonts.pendingFonts().timeout(const Duration(seconds: 8));
  } on Exception catch (e) {
    debugPrint('quote image fonts: $e');
  }
  final image = await renderOffScreen(widget, width: _side, maxHeight: _side, pixelRatio: _pixelRatio);
  final png = await pngBytes(image);
  image.dispose();
  return png;
}

/// How big the quote is set: a long passage has to come down to fit the
/// square, a few words can be large.
double _quoteSize(String text) => switch (text.characters.length) {
      < 60 => 30,
      < 120 => 26,
      < 220 => 21,
      < 360 => 17,
      _ => 14,
    };

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.card,
    required this.bookTitle,
    required this.sharedBy,
    required this.strings,
    required this.scale,
    required this.font,
  });

  final Flashcard card;
  final String bookTitle;
  final String? sharedBy;
  final AppStrings strings;
  final double scale;
  final CardFont font;

  @override
  Widget build(BuildContext context) {
    final ink = coverInk(bookTitle);
    final onInk = Colors.white.withValues(alpha: 0.95);
    final soft = Colors.white.withValues(alpha: 0.72);
    final who = sharedBy;
    final text = card.kind == CardKind.quote ? '“${card.front}”' : card.front;
    return MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: arthTheme(Brightness.light),
          child: DefaultTextStyle(
            style: const TextStyle(),
            child: SizedBox.square(
              dimension: _side,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ink, Color.lerp(ink, Colors.black, 0.4)!],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(child: BlockPrintTexture(title: bookTitle, cell: 54, opacity: 0.07)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(34, 30, 34, 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                text,
                                style: cardStyle(
                                  card.front,
                                  font,
                                  color: onInk,
                                  scale: scale,
                                  size: _quoteSize(card.front),
                                  italic: card.kind == CardKind.quote,
                                ),
                                maxLines: 11,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(width: 44, height: 2, color: Colors.white.withValues(alpha: 0.35)),
                          const SizedBox(height: 12),
                          Text(bookTitle, style: EnglishText.title(onInk, size: 17), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (who != null && who.isNotEmpty)
                            Text(strings.sharedByLine(who), style: uiBody(hindi: strings.isHindi, color: soft, scale: scale, size: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 10),
                          Text('Made with Arth', style: EnglishText.label(soft, size: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
