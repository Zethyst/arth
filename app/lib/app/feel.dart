// How the app answers a touch: haptics, motion timings, and a pressable
// surface that gives under the finger.
//
// Haptics have a small vocabulary so they mean something:
//   choose   — picking one of several (a tab, a chip, a colour)       selection tick
//   open     — opening something (a word, a book, a card)             light tap
//   commit   — keeping something (save a card, bookmark, "got it")    medium tap
//   finish   — finishing a book                                       medium, then heavy
// All of it is off when the reader turns haptics off in the You tab.
//
// Motion is short and answers an action; the one orchestrated moment is
// the library's covers settling in. Everything respects the system's
// reduce-motion setting.

import 'dart:async';

import 'package:arth/app/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class Haptics {
  /// Mirrors the setting; set by the app when settings load or change.
  static bool enabled = true;

  static void choose() {
    if (enabled) unawaited(HapticFeedback.selectionClick());
  }

  static void open() {
    if (enabled) unawaited(HapticFeedback.lightImpact());
  }

  static void commit() {
    if (enabled) unawaited(HapticFeedback.mediumImpact());
  }

  static Future<void> finish() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 110));
    await HapticFeedback.heavyImpact();
  }
}

/// A soft, continuous texture under a page being turned: a light hum while
/// the curl is on screen, stronger while the page moves fast, easing off when
/// it slows. iOS plays it with Core Haptics (AppDelegate.swift). Android
/// can't hum smoothly, so phones with crisp haptic primitives get a soft
/// tick every so far the page travels, faster as it speeds up, like paper
/// texture (MainActivity.kt); other phones only feel the page land.
abstract final class PageHaptics {
  static const _channel = MethodChannel('arth/haptics');

  static bool _on = false;
  static Timer? _timer;
  static final Stopwatch _clock = Stopwatch();
  static double? _last;
  static Duration _lastAt = Duration.zero;
  static double _width = 1;
  static double _speed = 0;
  static double _sent = -1;
  static double _travel = 0;
  static Duration _tickAt = Duration.zero;

  /// Whether this Android phone plays crisp ticks; null until asked.
  static bool? _ticks;

  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  /// The curl has appeared at [position] on a page [width] wide.
  static void start(double position, {required double width}) {
    if (!Haptics.enabled || _on) return;
    _on = true;
    _width = width <= 0 ? 1 : width;
    _last = position;
    _speed = 0;
    _sent = -1;
    _travel = 0;
    _clock
      ..reset()
      ..start();
    _lastAt = Duration.zero;
    _tickAt = Duration.zero;
    if (!_ios) {
      if (_ticks == null && defaultTargetPlatform == TargetPlatform.android) unawaited(_askTicks());
      return;
    }
    unawaited(_invoke('pageStart'));
    _send();
    // Moves stop coming while the finger rests: let the hum ease back down.
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _speed *= 0.86;
      _send();
    });
  }

  /// The page's fold is now at [position].
  static void move(double position) {
    final last = _last;
    if (!_on || last == null) return;
    final now = _clock.elapsed;
    final dt = (now - _lastAt).inMicroseconds / 1e6;
    final d = (position - last).abs();
    _last = position;
    _lastAt = now;
    if (dt <= 0) return;
    // Page widths a second, smoothed so the hum doesn't flutter.
    final v = (d / _width) / dt;
    _speed = _speed * 0.6 + v * 0.4;
    if (_ios) {
      _send();
      return;
    }
    if (_ticks != true) return;
    _travel += d;
    // A tick every twelfth of the page, never closer than the motor can
    // keep distinct.
    if (_travel < _width / 12 || now - _tickAt < const Duration(milliseconds: 22)) return;
    _travel = 0;
    _tickAt = now;
    unawaited(_invoke('pageTick', {'scale': 0.35 + 0.5 * (_speed / 3).clamp(0.0, 1.0)}));
  }

  /// The page has come to rest; [landed] when it was turned over.
  static void stop({bool landed = false}) {
    if (!_on) return;
    _on = false;
    _timer?.cancel();
    _timer = null;
    _clock.stop();
    _last = null;
    if (_ios) unawaited(_invoke('pageStop'));
    if (landed && Haptics.enabled) unawaited(HapticFeedback.lightImpact());
  }

  static void _send() {
    // A floor while the curl is up, rising with speed (about 3 widths a
    // second is full).
    final intensity = (0.22 + 0.6 * (_speed / 3).clamp(0.0, 1.0)).clamp(0.0, 1.0);
    if ((intensity - _sent).abs() < 0.02) return;
    _sent = intensity;
    unawaited(_invoke('pageUpdate', {'intensity': intensity, 'sharpness': 0.12 + 0.25 * (intensity - 0.22) / 0.6}));
  }

  static Future<void> _askTicks() async {
    try {
      _ticks = await _channel.invokeMethod<bool>('pageTicks') ?? false;
    } on PlatformException {
      _ticks = false;
    } on MissingPluginException {
      _ticks = false;
    }
  }

  static Future<void> _invoke(String method, [Map<String, Object>? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on PlatformException {
      // No haptics engine (an older phone): the page turns as before.
    } on MissingPluginException {
      // Not wired up on this platform.
    }
  }
}

/// Durations and curves, named for what they do.
abstract final class Motion {
  /// A control answering a press.
  static const press = Duration(milliseconds: 110);

  /// Something small appearing or changing state (a chip, a ribbon).
  static const quick = Duration(milliseconds: 180);

  /// A surface arriving (a card, a sheet's content, a page).
  static const settle = Duration(milliseconds: 320);

  /// The library's covers, one after another.
  static const stagger = Duration(milliseconds: 55);

  /// Decelerates hard: arrivals.
  static const Curve arrive = Cubic(0.05, 0.7, 0.1, 1);

  /// Symmetric, for state changes.
  static const Curve change = Curves.easeInOutCubic;

  /// Whether to skip decorative motion (the system's reduce-motion setting).
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d], or nothing when motion is reduced.
  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}

/// An outlined face on a hard, unblurred shadow [depth] down and to the
/// right. The shadow sits inside the widget's own bounds so clipping parents
/// don't cut it, and the overall size never changes. [pressed] pushes the
/// face into the shadow, leaving a sliver of it.
class HardShadow extends StatelessWidget {
  const HardShadow({required this.child, super.key, this.pressed = false, this.depth = 5, this.color, this.border, this.shadow});

  final Widget child;
  final bool pressed;
  final double depth;

  /// Face fill; the card colour by default.
  final Color? color;

  /// Outline; ink by default.
  final Color? border;

  /// Shadow; the theme's shadow by default.
  final Color? shadow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sink = pressed && depth > 1 ? depth - 1 : 0.0;
    // passthrough: a tight width (a full-width button) stretches the face too,
    // not just the shadow behind it.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (depth > 0)
          Positioned(
            left: depth,
            top: depth,
            right: 0,
            bottom: 0,
            child: ColoredBox(color: shadow ?? c.shadow),
          ),
        AnimatedPadding(
          padding: EdgeInsets.fromLTRB(sink, sink, depth - sink, depth - sink),
          duration: Motion.of(context, Motion.press),
          curve: Motion.change,
          child: Container(
            decoration: BoxDecoration(
              color: color ?? c.card,
              border: Border.all(color: border ?? c.ink, width: 2),
            ),
            clipBehavior: Clip.hardEdge,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// A surface that sinks a little under the finger and springs back, with
/// an optional haptic. Wrap tiles and cards that open something.
class Pressable extends StatefulWidget {
  const Pressable({required this.child, super.key, this.onTap, this.onLongPress, this.haptic = Haptics.open, this.scale = 0.97}) : depth = null, color = null;

  /// An outlined card on a [HardShadow] that the finger pushes it into.
  const Pressable.card({required this.child, super.key, this.onTap, this.onLongPress, this.haptic = Haptics.open, double this.depth = 5, this.color})
    : scale = 1;

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Played on tap; null for none.
  final void Function()? haptic;

  /// How far it sinks.
  final double scale;

  /// Shadow depth, for [Pressable.card]; null for a plain surface.
  final double? depth;

  /// Card fill, for [Pressable.card].
  final Color? color;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap == null
          ? null
          : () {
              widget.haptic?.call();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              _set(false);
              Haptics.commit();
              widget.onLongPress!();
            },
      child: widget.depth != null
          ? HardShadow(pressed: _down, depth: widget.depth!, color: widget.color, child: widget.child)
          : AnimatedScale(
              scale: _down ? widget.scale : 1,
              duration: Motion.of(context, Motion.press),
              curve: Motion.change,
              child: widget.child,
            ),
    );
  }
}

/// A child that fades and rises into place [delay] after it first builds —
/// used once, for the library's covers. Instant with reduced motion.
class SettleIn extends StatefulWidget {
  const SettleIn({required this.child, super.key, this.delay = Duration.zero, this.from = const Offset(0, 0.04), this.fromScale = 1.03});

  final Widget child;
  final Duration delay;

  /// Starting offset, as a fraction of the child's size.
  final Offset from;
  final double fromScale;

  @override
  State<SettleIn> createState() => _SettleInState();
}

class _SettleInState extends State<SettleIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.settle);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Motion.arrive);
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted || _timer != null) return;
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) unawaited(_c.forward());
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _t,
        child: widget.child,
        builder: (_, child) => Opacity(
          opacity: _t.value,
          child: FractionalTranslation(
            translation: Offset.lerp(widget.from, Offset.zero, _t.value)!,
            child: Transform.scale(scale: 1 + (widget.fromScale - 1) * (1 - _t.value), child: child),
          ),
        ),
      );
}

/// How far through a book: a marigold bar that fills to [value] when it
/// first appears and glides when the value changes.
class ReadingBar extends StatelessWidget {
  const ReadingBar({required this.value, super.key, this.height = 4});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRect(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: Motion.of(context, const Duration(milliseconds: 700)),
        curve: Motion.arrive,
        builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: height, color: c.marigold, backgroundColor: c.rule),
      ),
    );
  }
}
