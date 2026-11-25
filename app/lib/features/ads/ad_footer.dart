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

import 'package:arth/app/theme.dart';
import 'package:arth/features/ads/ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdFooter extends ConsumerWidget {
  const AdFooter({this.below, super.key});

  /// A bar this screen already had at the bottom (a comment composer). The
  /// banner sits above it, and that bar keeps handling the safe area.
  final Widget? below;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final below = this.below;
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
        child: const Center(child: AdBanner()),
      ),
    );
    if (below == null) return banner;
    return Column(mainAxisSize: MainAxisSize.min, children: [banner, below]);
  }
}
