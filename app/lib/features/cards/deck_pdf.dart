// A book's cards as a PDF to share or print. Each card is drawn by Flutter
// off screen — so Hindi is shaped and the app's fonts are used — captured as
// a picture, and laid out on A4 pages (core/pdf/image_pdf.dart). Always the
// light theme: it's meant for paper.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:arth/app/providers.dart';
import 'package:arth/app/settings.dart';
import 'package:arth/app/strings.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/core/pdf/image_pdf.dart';
import 'package:arth/core/render/widget_image.dart';
import 'package:arth/data/local_store.dart';
import 'package:arth/features/cards/card_face.dart';
import 'package:arth/features/library/book_cover.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _margin = 40.0;
const _gap = 10.0;
const double _contentWidth = a4Width - 2 * _margin;

/// Render resolution: pixels per point. Sharp in print, and a few hundred
/// KB per card once compressed.
const _pixelRatio = 2.0;

/// Builds the PDF for [cards] of [bookTitle] and opens the share sheet.
/// [origin] is where the share sheet points from on an iPad.
Future<void> exportDeckPdf(BuildContext context, WidgetRef ref, {required String bookTitle, required List<Flashcard> cards, Rect? origin}) =>
    _exportPdf(
      context,
      ref,
      bookTitle: bookTitle,
      suffix: 'cards',
      subject: ref.read(stringsProvider).pdfSubject(bookTitle),
      origin: origin,
      build: (t, settings) => buildDeckPdf(bookTitle: bookTitle, cards: cards, strings: t, scale: settings.hindiScale, font: settings.cardFont),
    );

/// A book's saved words as a PDF to share or print.
Future<void> exportWordsPdf(BuildContext context, WidgetRef ref, {required String bookTitle, required List<SavedWord> words, Rect? origin}) => _exportPdf(
      context,
      ref,
      bookTitle: bookTitle,
      suffix: 'words',
      subject: ref.read(stringsProvider).pdfWordsSubject(bookTitle),
      origin: origin,
      build: (t, settings) => buildWordsPdf(bookTitle: bookTitle, words: words, strings: t, scale: settings.hindiScale),
    );

Future<void> _exportPdf(
  BuildContext context,
  WidgetRef ref, {
  required String bookTitle,
  required String suffix,
  required String subject,
  required Future<Uint8List> Function(AppStrings t, Settings settings) build,
  Rect? origin,
}) async {
  final t = ref.read(stringsProvider);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
              const SizedBox(width: 18),
              Expanded(child: Text(t.preparingPdf)),
            ],
          ),
        ),
      ),
    ),
  );
  final name = bookTitle.replaceAll(RegExp(r'[\\/:*?"<>|]+'), ' ').trim();
  final fileName = '${name.isEmpty ? 'Arth' : name} - $suffix.pdf';
  Uint8List? bytes;
  File? file;
  try {
    final settings = ref.read(settingsProvider);
    bytes = await build(t, settings);
    final dir = await getTemporaryDirectory();
    file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    // Anything at all, not only Exceptions: drawing and compressing a long
    // document can fail in ways that aren't — running the phone out of
    // memory, for one — and a failure nobody is told about, under a dialog
    // that can't be dismissed, reads as an app that has stopped working.
    // ignore: avoid_catches_without_on_clauses
  } catch (e, stack) {
    debugPrint('pdf export failed: $e\n$stack');
    bytes = null;
    file = null;
  } finally {
    navigator.pop();
  }
  if (bytes == null || file == null) {
    messenger?.showSnackBar(SnackBar(content: Text(t.pdfFailed)));
    return;
  }
  if (!context.mounted) return;
  // Sharing is one way out of the app; a file the reader keeps is another,
  // and the one they ask for when they go looking in Downloads.
  final choice = await _askSaveOrShare(context, ref, t);
  if (choice == null) return;
  if (choice == _PdfDestination.share) {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')], subject: subject, sharePositionOrigin: origin),
    );
    return;
  }
  try {
    final to = await FilePicker.saveFile(fileName: fileName, bytes: bytes, mimeType: 'application/pdf');
    if (to != null) messenger?.showSnackBar(SnackBar(content: Text(t.pdfSaved)));
  } on Exception catch (e) {
    debugPrint('pdf save failed: $e');
    messenger?.showSnackBar(SnackBar(content: Text(t.pdfSaveFailed)));
  }
}

enum _PdfDestination { save, share }

/// Where the finished PDF should go. Null if the reader dismissed the sheet.
Future<_PdfDestination?> _askSaveOrShare(BuildContext context, WidgetRef ref, AppStrings t) => showModalBottomSheet<_PdfDestination>(
      context: context,
      useSafeArea: true,
      builder: (ctx) {
        final c = ctx.colors;
        final scale = ref.read(settingsProvider).hindiScale;
        Widget option(_PdfDestination value, IconData icon, String label, String hint) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              leading: Icon(icon, color: c.accent),
              title: Text(label, style: uiLabel(hindi: t.isHindi, color: c.ink, scale: scale).copyWith(fontSize: 16)),
              subtitle: Text(hint, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 13.5)),
              onTap: () => Navigator.pop(ctx, value),
            );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(t.pdfReady, style: uiHeading(hindi: t.isHindi, color: c.ink, scale: scale)),
                ),
                option(_PdfDestination.save, Icons.download_rounded, t.pdfSave, t.pdfSaveHint),
                option(_PdfDestination.share, Icons.ios_share_rounded, t.pdfShare, t.pdfShareHint),
              ],
            ),
          ),
        );
      },
    );

/// The PDF itself: a title block, then every card in reading order.
Future<Uint8List> buildDeckPdf({
  required String bookTitle,
  required List<Flashcard> cards,
  required AppStrings strings,
  required double scale,
  CardFont font = CardFont.montserrat,
}) async {
  Widget page(Widget child) => _PrintFrame(strings: strings, child: child);
  final header = page(_Header(bookTitle: bookTitle, countLabel: strings.cardCount(cards.length), strings: strings));
  final tiles = [for (final card in cards) page(_PrintCard(card: card, strings: strings, scale: scale, font: font))];
  return _layoutPdf(bookTitle: bookTitle, header: header, tiles: tiles);
}

/// The PDF of a book's saved words: a title block, then each word with its
/// meaning and the sentence it was met in.
Future<Uint8List> buildWordsPdf({
  required String bookTitle,
  required List<SavedWord> words,
  required AppStrings strings,
  required double scale,
}) {
  Widget page(Widget child) => _PrintFrame(strings: strings, child: child);
  return _layoutPdf(
    bookTitle: bookTitle,
    header: page(_Header(bookTitle: bookTitle, countLabel: strings.wordCount(words.length), strings: strings)),
    tiles: [for (final w in words) page(_PrintWord(word: w, scale: scale))],
  );
}

Future<Uint8List> _layoutPdf({required String bookTitle, required Widget header, required List<Widget> tiles}) async {
  // Styles ask Google Fonts for their files on first use: draw once to ask,
  // wait for them, then draw for real. A face that is still on its way over
  // a slow connection is worth a few seconds and no more — the document is
  // worth more than the font, and the faces on the phone stand in for it.
  await _capture(header);
  if (tiles.isNotEmpty) await _capture(tiles.first);
  try {
    await GoogleFonts.pendingFonts().timeout(const Duration(seconds: 8));
  } on Exception catch (e) {
    debugPrint('pdf fonts: $e');
  }

  final pages = <PdfPageSpec>[];
  var y = double.infinity;
  const bottom = a4Height - _margin - 12; // room for the footer
  void place(PdfImage img) {
    var w = _contentWidth;
    var h = img.height / _pixelRatio;
    const full = bottom - _margin;
    if (h > full) {
      // Taller than a page (a very long note): shrink to fit.
      w *= full / h;
      h = full;
    }
    if (y + h > bottom) {
      pages.add(PdfPageSpec(footer: 'Made with Arth'));
      y = _margin;
    }
    pages.last.placements.add((image: img, x: _margin, y: y, w: w, h: h));
    y += h + _gap;
  }

  place(await _capture(header));
  y += 8;
  for (final tile in tiles) {
    place(await _capture(tile));
  }
  final numbered = [
    for (final (i, p) in pages.indexed) PdfPageSpec(footer: 'Made with Arth   |   ${i + 1} / ${pages.length}')..placements.addAll(p.placements),
  ];
  return buildImagePdf(numbered, title: bookTitle);
}

/// Draws [widget] off screen, [_contentWidth] points wide and as tall as it
/// needs, and returns its pixels flattened onto white.
Future<PdfImage> _capture(Widget widget) async {
  final image = await renderOffScreen(widget, width: _contentWidth, pixelRatio: _pixelRatio);
  final out = PdfImage(width: image.width, height: image.height, rgb: await rgbBytes(image));
  image.dispose();
  return out;
}

/// What a widget needs to draw with no app around it.
class _PrintFrame extends StatelessWidget {
  const _PrintFrame({required this.strings, required this.child});

  final AppStrings strings;
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Theme(
            data: arthTheme(Brightness.light),
            child: DefaultTextStyle(
              style: const TextStyle(),
              // Unbounded height, as in a list: a Column takes only what it needs.
              child: UnconstrainedBox(
                alignment: Alignment.topLeft,
                constrainedAxis: Axis.horizontal,
                child: SizedBox(width: _contentWidth, child: child),
              ),
            ),
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.bookTitle, required this.countLabel, required this.strings});

  final String bookTitle;
  final String countLabel;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CoverArt(title: bookTitle, width: 58, elevation: 0),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bookTitle, style: EnglishText.title(c.ink, size: 26)),
                const SizedBox(height: 4),
                Text(
                  '$countLabel  ·  ${now.day}/${now.month}/${now.year}',
                  style: uiBody(hindi: strings.isHindi, color: c.inkMuted, size: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A card in full: nothing cut short, as it's the only copy on paper.
class _PrintCard extends StatelessWidget {
  const _PrintCard({required this.card, required this.strings, required this.scale, required this.font});

  final Flashcard card;
  final AppStrings strings;
  final double scale;
  final CardFont font;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = kindColor(card.kind, c);
    final front = switch (card.kind) {
      CardKind.quote => Text('“${card.front}”', style: cardStyle(card.front, font, color: c.ink, scale: scale, italic: true)),
      CardKind.word => Text(card.front, style: cardStyle(card.front, font, color: c.ink, scale: scale, size: 21, weight: FontWeight.w600)),
      CardKind.idea => Text(card.front, style: cardStyle(card.front, font, color: c.ink, scale: scale, weight: FontWeight.w600)),
    };
    final context_ = card.context;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.rule),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(color: ink, borderRadius: const BorderRadius.horizontal(left: Radius.circular(12))),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(kindIcon(card.kind), size: 14, color: ink),
                        const SizedBox(width: 6),
                        Text(kindLabel(card.kind, strings), style: uiLabel(hindi: strings.isHindi, color: c.inkMuted).copyWith(fontSize: 12)),
                        const SizedBox(width: 12),
                        if (card.location != null)
                          Expanded(
                            child: Text(card.location!, style: EnglishText.label(c.inkMuted, size: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    front,
                    if (card.back.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(card.back, style: cardStyle(card.back, font, color: c.ink, scale: scale, size: 15)),
                    ],
                    if (card.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(border: Border(left: BorderSide(color: c.marigold, width: 2))),
                        child: Text(card.note, style: cardStyle(card.note, font, color: c.inkMuted, scale: scale, size: 14, italic: true)),
                      ),
                    ],
                    if (context_ != null && context_.isNotEmpty && card.kind != CardKind.quote && context_ != card.front) ...[
                      const SizedBox(height: 8),
                      Text(context_, style: EnglishText.italic(c.inkMuted, size: 12.5)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A saved word in full: the word, its meaning, the sentence it came from.
class _PrintWord extends StatelessWidget {
  const _PrintWord({required this.word, required this.scale});

  final SavedWord word;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sentence = word.sentence;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(word.lemma, style: EnglishText.word(c.ink, size: 20)),
          if (word.meaning.isNotEmpty) Text(word.meaning, style: HindiText(scale).meaning(c.ink)),
          if (sentence != null && sentence.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(sentence, style: EnglishText.italic(c.inkMuted, size: 12.5)),
          ],
        ],
      ),
    );
  }
}
