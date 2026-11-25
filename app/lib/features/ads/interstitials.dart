// Full-screen ads for the free tier, at natural breaks only: leaving a book
// after real reading, finishing a Replay / Practice session, leaving a
// coaching conversation, or closing a tool that has already answered. Never
// on launch, never mid-reading, never between a tap and the answer it asked
// for, and at most one every few minutes.
//
// More breaks is not more ads: [AdPacing] allows one every [AdPacing.minGap]
// however many breaks happen. What they buy is that the allowed one is
// actually reached — a reader who only ever uses the tools used to hit no
// break at all.
//
// One ad is kept loaded so it appears instantly at the break; after it's
// shown (or fails) the next one loads. Ad units come from dart-defines;
// without them, Google's test units:
//   --dart-define=ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-xxxx/yyyy
//   --dart-define=ADMOB_INTERSTITIAL_IOS=ca-app-pub-xxxx/zzzz

import 'dart:async';
import 'dart:io';

import 'package:arth/features/ads/ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const _unitAndroid = String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID', defaultValue: 'ca-app-pub-3940256099942544/1033173712');
const _unitIos = String.fromEnvironment('ADMOB_INTERSTITIAL_IOS', defaultValue: 'ca-app-pub-3940256099942544/4411468910');

/// Where a break happened.
enum AdBreak {
  /// Left a book (only counts after [AdPacing.minReading] of reading).
  closedBook,

  /// Finished a Replay or Practice session.
  finishedReview,

  /// Finished a round of idiom or word-power practice.
  finishedPractice,

  /// Left a coaching conversation the reader actually spoke in.
  finishedCoach,

  /// Closed a tool that had answered at least once. Fired on the way out,
  /// never over the answer: an ad between "Translate" and the translation is
  /// the one placement AdMob calls unexpected, and the one a learner would
  /// not forgive.
  leftTool,
}

/// When a full-screen ad may show. Pure, so it can be tested with a clock.
class AdPacing {
  AdPacing({required this.appStartedAt});

  /// No ad in the first minutes after the app opens.
  static const graceAfterLaunch = Duration(minutes: 2);

  /// At most one ad per this long.
  static const minGap = Duration(minutes: 6);

  /// A book opened and closed quickly (looking something up) isn't a break.
  static const minReading = Duration(minutes: 2);

  final DateTime appStartedAt;
  DateTime? lastShownAt;

  bool allows(AdBreak at, {required DateTime now, Duration? readFor}) {
    if (now.difference(appStartedAt) < graceAfterLaunch) return false;
    final last = lastShownAt;
    if (last != null && now.difference(last) < minGap) return false;
    if (at == AdBreak.closedBook && (readFor == null || readFor < minReading)) return false;
    return true;
  }
}

final interstitialsProvider = Provider<Interstitials>((ref) {
  final i = Interstitials(ref);
  ref.onDispose(i.dispose);
  return i;
});

class Interstitials {
  Interstitials(this._ref) {
    // Load once ads are allowed for this reader; drop the ad if they stop
    // being (an upgrade to Pro mid-session).
    _ref.listen<bool>(showAdsProvider, (_, show) {
      if (show) {
        _load();
      } else {
        unawaited(_ad?.dispose());
        _ad = null;
      }
    }, fireImmediately: true);
  }

  final Ref _ref;
  final pacing = AdPacing(appStartedAt: DateTime.now());
  InterstitialAd? _ad;
  bool _loading = false;
  bool _showing = false;

  void _load() {
    if (_ad != null || _loading || kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    _loading = true;
    unawaited(
      InterstitialAd.load(
        adUnitId: Platform.isIOS ? _unitIos : _unitAndroid,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loading = false;
            _ad = ad;
          },
          onAdFailedToLoad: (error) {
            _loading = false;
            debugPrint('interstitial failed to load: $error');
          },
        ),
      ),
    );
  }

  /// A break happened: shows the preloaded ad if this reader sees ads and
  /// the pacing allows. [readFor] is how long the book was open.
  void onBreak(AdBreak at, {Duration? readFor}) {
    final ad = _ad;
    final now = DateTime.now();
    if (ad == null || _showing || !_ref.read(showAdsProvider) || !pacing.allows(at, now: now, readFor: readFor)) return;
    _ad = null;
    _showing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => pacing.lastShownAt = DateTime.now(),
      onAdDismissedFullScreenContent: (shown) {
        _showing = false;
        unawaited(shown.dispose());
        _load();
      },
      onAdFailedToShowFullScreenContent: (failed, error) {
        _showing = false;
        debugPrint('interstitial failed to show: $error');
        unawaited(failed.dispose());
        _load();
      },
    );
    unawaited(ad.show());
  }

  void dispose() {
    unawaited(_ad?.dispose());
    _ad = null;
  }
}

/// For screens whose break is the reader leaving: a finished round of
/// practice, a coaching conversation they spoke in, a tool that answered.
///
/// The ad lands over whatever they went back to, which is the point — it is
/// never between the reader and something they asked for. [adBreakEarned] is
/// read while the state still exists, so it can look at the screen's own
/// fields; a visit that earned nothing fires nothing.
mixin AdBreakOnLeave<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Which break leaving this screen is.
  AdBreak get adBreak;

  /// Whether this visit amounted to anything.
  bool get adBreakEarned;

  late final Interstitials _onLeave;

  @override
  void initState() {
    super.initState();
    // Captured now: `ref` can't be used once the widget is disposing.
    _onLeave = ref.read(interstitialsProvider);
  }

  @override
  void dispose() {
    final earned = adBreakEarned;
    final at = adBreak;
    final interstitials = _onLeave;
    super.dispose();
    if (earned) scheduleMicrotask(() => interstitials.onBreak(at));
  }
}

/// For the readers: when the reader closes, that's a break — if the book
/// was open long enough to count as reading.
mixin AdBreakOnClose<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final DateTime _openedAt = DateTime.now();
  late final Interstitials _interstitials;

  @override
  void initState() {
    super.initState();
    // Captured now: `ref` can't be used once the widget is disposing.
    _interstitials = ref.read(interstitialsProvider);
  }

  @override
  void dispose() {
    final readFor = DateTime.now().difference(_openedAt);
    final interstitials = _interstitials;
    super.dispose();
    // After the reader is gone, over the screen the reader returns to.
    scheduleMicrotask(() => interstitials.onBreak(AdBreak.closedBook, readFor: readFor));
  }
}
