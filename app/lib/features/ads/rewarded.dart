// Rewarded ads: a Free reader out of AI answers can watch one ad for a few
// more, instead of only being shown the price list.
//
// This is the one ad format a reader asks for. It is never shown unasked,
// it arrives at the moment of most intent — the answer they wanted was just
// refused — and it pays several times what a banner does. The wall stays
// where it was for anyone who would rather not: the offer sits beside
// "See plans", not instead of it.
//
// The claim is the app's word that the reward was earned, so the server caps
// how many ads count in a day rather than trusting the count (see
// POST /me/ai-bonus). Ad units come from dart-defines; without them,
// Google's test units:
//   --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-xxxx/yyyy
//   --dart-define=ADMOB_REWARDED_IOS=ca-app-pub-xxxx/zzzz

import 'dart:async';
import 'dart:io';

import 'package:arth/app/account_providers.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/data/account.dart';
import 'package:arth/data/api_client.dart';
import 'package:arth/features/ads/ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const _unitAndroid = String.fromEnvironment('ADMOB_REWARDED_ANDROID', defaultValue: 'ca-app-pub-3940256099942544/5224354917');
const _unitIos = String.fromEnvironment('ADMOB_REWARDED_IOS', defaultValue: 'ca-app-pub-3940256099942544/1712485313');

/// How many rewarded ads this reader may still watch today, from /me and
/// then from each claim's answer — so the offer disappears when it's spent
/// without waiting for the next profile fetch.
final adsLeftProvider = NotifierProvider<AdsLeft, int>(AdsLeft.new);

class AdsLeft extends Notifier<int> {
  @override
  int build() => ref.watch(accountProvider).valueOrNull?.adsLeftToday ?? 0;

  // A method, not a setter: it's handed around as a callback.
  // ignore: use_setters_to_change_properties
  void report(int left) => state = left;
}

/// Whether to offer an ad for answers: a signed-in reader who sees ads, with
/// a server that pays for them and a day that isn't spent.
final canEarnAnswersProvider = Provider<bool>((ref) {
  if (!ref.watch(showAdsProvider)) return false;
  if (ref.watch(signedInUidProvider) == null) return false;
  if ((ref.watch(accountProvider).valueOrNull?.adBonus ?? 0) <= 0) return false;
  return ref.watch(adsLeftProvider) > 0;
});

/// What came of offering one.
enum Reward {
  /// Answers were added; the allowance is already updated.
  earned,

  /// The ad watched, but the day's ads were already spent.
  spentForToday,

  /// No ad to show, or the reader closed it before the reward.
  none,

  /// The ad was watched but the claim didn't reach the server.
  failed,
}

final rewardedProvider = Provider<Rewarded>((ref) {
  final r = Rewarded(ref);
  ref.onDispose(r.dispose);
  return r;
});

class Rewarded {
  Rewarded(this._ref) {
    _ref.listen<bool>(canEarnAnswersProvider, (_, can) {
      if (can) {
        _load();
      } else {
        unawaited(_ad?.dispose());
        _ad = null;
      }
    }, fireImmediately: true);
  }

  final Ref _ref;
  RewardedAd? _ad;
  bool _loading = false;
  bool _showing = false;

  /// True once an ad is in hand, so the button can say "watch" rather than
  /// offer something that isn't there.
  bool get ready => _ad != null;

  void _load() {
    if (_ad != null || _loading || kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    _loading = true;
    unawaited(
      RewardedAd.load(
        adUnitId: Platform.isIOS ? _unitIos : _unitAndroid,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _loading = false;
            _ad = ad;
          },
          onAdFailedToLoad: (error) {
            _loading = false;
            debugPrint('rewarded failed to load: $error');
          },
        ),
      ),
    );
  }

  /// Shows an ad and, if the reader earned the reward, claims the answers.
  ///
  /// Waits for the ad to be dismissed before claiming, so the allowance the
  /// reader comes back to is already the new one.
  Future<Reward> offer() async {
    final ad = _ad;
    if (ad == null || _showing) {
      _load();
      return Reward.none;
    }
    _ad = null;
    _showing = true;
    var earned = false;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shown) {
        _showing = false;
        unawaited(shown.dispose());
        if (!done.isCompleted) done.complete();
        _load();
      },
      onAdFailedToShowFullScreenContent: (failed, error) {
        _showing = false;
        debugPrint('rewarded failed to show: $error');
        unawaited(failed.dispose());
        if (!done.isCompleted) done.complete();
        _load();
      },
    );
    await ad.setImmersiveMode(true);
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    await done.future;
    if (!earned) return Reward.none;
    return _claim();
  }

  Future<Reward> _claim() async {
    final AdBonus bonus;
    try {
      bonus = await _ref.read(apiClientProvider).claimAdBonus();
    } on ApiFailure catch (e) {
      debugPrint('ad bonus not claimed: $e');
      return Reward.failed;
    }
    _ref.read(adsLeftProvider.notifier).report(bonus.adsLeftToday);
    final usage = bonus.usage;
    if (usage != null) _ref.read(usageProvider.notifier).report(usage);
    return bonus.granted > 0 ? Reward.earned : Reward.spentForToday;
  }

  void dispose() {
    unawaited(_ad?.dispose());
    _ad = null;
  }
}
