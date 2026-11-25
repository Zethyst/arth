// A banner for the screens that aren't tabs.
//
// The shell carries its own banner above the navigation bar (app/router.dart),
// so only the four tabs ever showed one. Everything pushed on top of them —
// the tools, the idiom and word lists, a shared recap, the habit and archive
// screens — had no ad at all, which is most of where a learner actually
// spends their time.
//
// It goes in `Scaffold.bottomNavigationBar` rather than at the end of the
// body: the Scaffold then keeps it below the content, lifts it with the
// keyboard, and leaves the body's own scrolling alone.
//
// Deliberately not here: the readers (a banner under a page of a book is the
// one thing Arth promises not to do), /plans (an ad on the screen that sells
// their removal), sign-in, the profile and admin screens, and Say It Right,
// whose record button must not have a tappable ad next to it.

import 'dart:async';

import 'package:arth/app/theme.dart';
import 'package:arth/features/ads/ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How many [AdFooter]s are on screen. The shell's banner stands down while
/// one is (app/router.dart): a screen pushed over the tabs hides that banner
/// anyway, so keeping it alive would load two ads for the one the reader can
/// see — a wasted request, and an impression for an ad nobody looked at.
final adFootersProvider = NotifierProvider<AdFooters, int>(AdFooters.new);

class AdFooters extends Notifier<int> {
  @override
  int build() => 0;

  void arrived() => state++;

  void left() => state--;
}

class AdFooter extends ConsumerStatefulWidget {
  const AdFooter({this.below, super.key});

  /// A bar this screen already had at the bottom (a comment composer). The
  /// banner sits above it, and that bar keeps handling the safe area.
  final Widget? below;

  @override
  ConsumerState<AdFooter> createState() => _AdFooterState();
}

class _AdFooterState extends ConsumerState<AdFooter> {
  late final AdFooters _footers;

  @override
  void initState() {
    super.initState();
    // Off this frame: the count is read while the tree is being built.
    _footers = ref.read(adFootersProvider.notifier);
    scheduleMicrotask(_footers.arrived);
  }

  @override
  void dispose() {
    final footers = _footers;
    super.dispose();
    scheduleMicrotask(footers.left);
  }

  @override
  Widget build(BuildContext context) {
    final below = widget.below;
    if (!ref.watch(showAdsProvider)) return below ?? const SizedBox.shrink();
    final c = context.colors;
    final banner = DecoratedBox(
      decoration: BoxDecoration(
        color: c.paper,
        border: Border(top: BorderSide(color: c.rule)),
      ),
      child: SafeArea(
        top: false,
        // The bar underneath, if there is one, is the bottom of the screen.
        bottom: below == null,
        // heightFactor: a bare Center fills what it is offered, and the
        // bottomNavigationBar slot offers the whole screen — the footer then
        // covers the page and the ad floats in the middle of it.
        child: const Center(heightFactor: 1, child: AdBanner()),
      ),
    );
    if (below == null) return banner;
    return Column(mainAxisSize: MainAxisSize.min, children: [banner, below]);
  }
}
