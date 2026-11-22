// Drawing a widget off screen, with no app around it. It is how the app
// turns its own cards into pictures — a PDF page (features/cards/deck_pdf)
// or one quote to send (features/cards/quote_image) — because Flutter shapes
// Devanagari properly and the drawing libraries that make files do not.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Draws [widget] [width] points wide and as tall as it needs, at
/// [pixelRatio] device pixels per point, and returns the picture. The caller
/// disposes it.
///
/// Nothing of the app is above the widget: it brings its own Directionality,
/// MediaQuery and Theme, and it is laid out against a loose height, so a
/// Column takes only the room it asks for — up to [maxHeight].
///
/// Fonts that Google Fonts is still fetching are not waited for here: draw
/// once to ask for them, await `GoogleFonts.pendingFonts()`, then draw for
/// real.
Future<ui.Image> renderOffScreen(
  Widget widget, {
  required double width,
  required double pixelRatio,
  double maxHeight = 4000,
}) async {
  final boundary = RenderRepaintBoundary();
  final view = ui.PlatformDispatcher.instance.implicitView!;
  final renderView = RenderView(
    view: view,
    child: RenderPositionedBox(alignment: Alignment.topLeft, child: boundary),
    configuration: ViewConfiguration(
      logicalConstraints: BoxConstraints.tight(Size(width, maxHeight)),
      devicePixelRatio: pixelRatio,
    ),
  );
  final pipeline = PipelineOwner()..rootNode = renderView;
  renderView.prepareInitialFrame();
  final build = BuildOwner(focusManager: FocusManager());
  final root = RenderObjectToWidgetAdapter<RenderBox>(container: boundary, child: widget).attachToRenderTree(build);
  build
    ..buildScope(root)
    ..finalizeTree();
  pipeline
    ..flushLayout()
    ..flushCompositingBits()
    ..flushPaint();
  return boundary.toImage(pixelRatio: pixelRatio);
}

/// [image]'s pixels as width × height × 3 bytes, top row first, flattened
/// onto white: what a PDF places.
Future<Uint8List> rgbBytes(ui.Image image) async {
  final rgba = (await image.toByteData())!.buffer.asUint8List();
  final rgb = Uint8List(image.width * image.height * 3);
  for (var i = 0, j = 0; i < rgba.length; i += 4, j += 3) {
    // Premultiplied RGBA over white.
    final a = 255 - rgba[i + 3];
    rgb[j] = rgba[i] + a;
    rgb[j + 1] = rgba[i + 1] + a;
    rgb[j + 2] = rgba[i + 2] + a;
  }
  return rgb;
}

/// [image] as a PNG: what a share sheet takes.
Future<Uint8List> pngBytes(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
