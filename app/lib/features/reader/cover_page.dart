// The book's cover, as the page before page 1. Opening a book you haven't
// read starts here, and turning back from the first page comes back to it.
//
// The cover is the one the library found for the title (Open Library, see
// data/covers.dart), resting on the book's own dye; a book with no cover
// found gets the printed one the library draws, with its title.
//
// It is painted rather than built out of widgets, because the page curl turns
// a picture of the page it is leaving: the same drawing has to go both to the
// screen and onto a canvas.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:arth/app/feel.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/data/covers.dart';
import 'package:arth/features/library/book_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The downloaded cover for a title, decoded: the readers need the image
/// itself, not an Image widget, to paint it.
// ignore: specify_nonobvious_property_types
final coverArtProvider = FutureProvider.autoDispose.family<ui.Image?, String>((ref, title) async {
  final file = await ref.watch(coverFileProvider(title).future);
  if (file == null) return null;
  try {
    final codec = await ui.instantiateImageCodec(await file.readAsBytes());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  } on Exception {
    return null; // the printed cover stands in
  }
});

/// The cover filling [size]: the title's dye and block print, with the real
/// cover resting on it, or the printed label and the title.
void paintCoverPage(Canvas canvas, Size size, {required String title, required ArthColors c, ui.Image? photo}) {
  final unit = size.shortestSide;
  final ink = coverInk(title);
  canvas.drawRect(Offset.zero & size, Paint()..color = ink);
  BlockPrintPainter(motif: motifOf(title), color: c.paper.withValues(alpha: 0.16), cell: unit * 0.2).paint(canvas, size);

  // The printed cover's border rule, inset from the edge.
  final inset = unit * 0.06;
  final frame = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);
  canvas.drawRect(
    frame,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, unit * 0.005)
      ..color = c.paper.withValues(alpha: 0.4),
  );

  if (photo != null) {
    // The real cover, resting on the dye with the app's hard shadow.
    final aspect = photo.width / photo.height;
    var height = frame.height * 0.78;
    var width = height * aspect;
    if (width > frame.width * 0.84) {
      width = frame.width * 0.84;
      height = width / aspect;
    }
    final rest = Rect.fromCenter(center: frame.center, width: width, height: height);
    final drop = unit * 0.014;
    canvas.drawRect(rest.shift(Offset(drop, drop)), Paint()..color = Colors.black.withValues(alpha: 0.32));
    paintImage(canvas: canvas, rect: rest, image: photo, fit: BoxFit.cover);
    canvas.drawRect(
      rest,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, unit * 0.006)
        ..color = c.ink,
    );
    return;
  }

  // No cover found: the label the library prints, and the title under it.
  final label = math.min(frame.width * 0.42, frame.height * 0.26);
  final centre = Offset(frame.center.dx, frame.top + frame.height * 0.32);
  canvas
    ..drawCircle(centre, label / 2, Paint()..color = c.card)
    ..drawCircle(
      centre,
      label / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, unit * 0.006)
        ..color = ink.withValues(alpha: 0.35),
    );
  final initial = title.trim().isEmpty ? '?' : title.trim().characters.first.toUpperCase();
  _print(
    canvas,
    initial,
    EnglishText.word(ink, size: label * 0.4).copyWith(height: 1),
    box: Rect.fromCenter(center: centre, width: label, height: label),
    middle: true,
  );
  _print(
    canvas,
    title,
    EnglishText.title(c.paper, size: unit * 0.085),
    box: Rect.fromLTRB(frame.left + frame.width * 0.08, centre.dy + label * 0.62, frame.right - frame.width * 0.08, frame.bottom),
    middle: false,
    maxLines: 4,
  );
}

/// [text] in [box], centred across it and (when [middle]) down it.
void _print(Canvas canvas, String text, TextStyle style, {required Rect box, required bool middle, int maxLines = 1}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
    ellipsis: '…',
  )..layout(maxWidth: box.width);
  painter
    ..paint(canvas, Offset(box.left + (box.width - painter.width) / 2, middle ? box.center.dy - painter.height / 2 : box.top))
    ..dispose();
}

/// The cover page itself. [onTap] turns it, where a tap turns pages.
class CoverPage extends StatelessWidget {
  const CoverPage({required this.title, super.key, this.photo, this.onTap});

  final String title;

  /// The real cover, if one was found.
  final ui.Image? photo;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final page = CustomPaint(painter: _CoverPagePainter(title: title, photo: photo, c: context.colors), size: Size.infinite);
    if (onTap == null) return page;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: page);
  }
}

class _CoverPagePainter extends CustomPainter {
  _CoverPagePainter({required this.title, required this.photo, required this.c});

  final String title;
  final ui.Image? photo;
  final ArthColors c;

  @override
  void paint(Canvas canvas, Size size) => paintCoverPage(canvas, size, title: title, c: c, photo: photo);

  @override
  bool shouldRepaint(_CoverPagePainter old) => old.title != title || old.photo != photo || old.c != c;
}

/// The cover over a reader that scrolls rather than turning pages: it slides
/// off to the left when the reader starts, and comes back on a swipe back at
/// the start of the book. A tap or a swipe left opens the book.
class CoverSheet extends StatelessWidget {
  const CoverSheet({required this.title, required this.showing, required this.onOpen, super.key, this.photo});

  final String title;
  final bool showing;
  final VoidCallback onOpen;
  final ui.Image? photo;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: !showing,
        child: AnimatedSlide(
          offset: Offset(showing ? 0 : -1.06, 0),
          duration: Motion.of(context, Motion.settle),
          curve: Motion.arrive,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpen,
            onHorizontalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) < -120) onOpen();
            },
            child: CoverPage(title: title, photo: photo),
          ),
        ),
      );
}

/// A swipe back at the start of the book, for [CoverSheet]: the pointers are
/// watched rather than claimed, so the reader below keeps its own gestures
/// (its own swipe has nowhere left to go there).
class CoverSwipeBack extends StatefulWidget {
  const CoverSwipeBack({required this.enabled, required this.onBack, required this.child, super.key});

  final bool enabled;
  final VoidCallback onBack;
  final Widget child;

  @override
  State<CoverSwipeBack> createState() => _CoverSwipeBackState();
}

class _CoverSwipeBackState extends State<CoverSwipeBack> {
  static const _reach = 72.0;

  int? _pointer;
  Offset _down = Offset.zero;
  Duration _downAt = Duration.zero;
  bool _done = false;

  void _onDown(PointerDownEvent e) {
    if (_pointer != null) {
      _pointer = null; // a second finger: a pinch, not a swipe
      return;
    }
    _pointer = e.pointer;
    _down = e.position;
    _downAt = e.timeStamp;
    _done = false;
  }

  void _onMove(PointerMoveEvent e) {
    if (e.pointer != _pointer || _done || !widget.enabled) return;
    final total = e.position - _down;
    // Rightwards, mostly sideways, and soon after landing: a drag that starts
    // later is a text selection.
    if (total.dx < _reach || total.dx < total.dy.abs() * 1.6) return;
    if (e.timeStamp - _downAt > const Duration(milliseconds: 600)) return;
    _done = true;
    Haptics.choose();
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: (e) => _pointer = e.pointer == _pointer ? null : _pointer,
        onPointerCancel: (e) => _pointer = e.pointer == _pointer ? null : _pointer,
        child: widget.child,
      );
}
