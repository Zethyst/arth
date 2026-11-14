// "How is Arth treating you?" — five stars, and then the one thing that
// actually helps a small app: words in the store listing.
//
// The stars are ours rather than the platform's because the platform's own
// sheets are rationed and silent about it: Apple shows its prompt at most a
// few times a year and may show nothing at all, and Play's quota is
// undocumented. A button the reader just pressed must do something, so ours
// always appears, and tapping a star opens the place where a review is
// actually typed.
//
// Both ends are offered to everyone. A reader who taps one star still gets
// the store link, and a reader who taps five still gets the way to complain:
// a prompt that quietly routes unhappy readers away from the store is the
// kind of thing both stores take a dim view of, and it makes the rating a
// lie.

import 'dart:async';
import 'dart:io';

import 'package:arth/app/account_providers.dart';
import 'package:arth/app/feel.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/features/about/about_screen.dart' show kWhatsAppNumber;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

/// The Play listing's package, which is also the iOS bundle id.
const String kAndroidPackage = 'com.zethyst.arth';

/// The App Store's numeric id, which only exists once the app is there:
/// `--dart-define=ARTH_APP_STORE_ID=1234567890`. Empty until then, and the
/// iOS path falls back to Apple's own sheet.
const String kAppStoreId = String.fromEnvironment('ARTH_APP_STORE_ID');

/// A day streak this long means the reader has come back on purpose.
const int kRateMinStreak = 3;

/// …or this much reading in total, for someone who reads in long sittings
/// rather than every day.
const Duration kRateMinReading = Duration(minutes: 45);

/// A reader who says "not now" is not asked again for this long. Four months
/// is long enough that the second ask feels like a different app version.
const Duration kRateAskAgainAfter = Duration(days: 120);

/// Where the reader has got to with the question.
enum RatingState {
  /// Never asked, or asked and put off.
  open,

  /// Rated, or asked not to be asked again. Never ask once this is set.
  settled,
}

const String _kStateKey = 'rating_state';
const String _kAskedAtKey = 'rating_asked_at';

/// Whether now is a good moment to ask. Pure, so the rules can be read in one
/// place and tested without a database or a screen.
bool shouldAskForRating({
  required RatingState state,
  required DateTime? lastAskedAt,
  required int streakDays,
  required int totalReadingMs,
  required DateTime now,
}) {
  if (state == RatingState.settled) return false;
  if (lastAskedAt != null && now.difference(lastAskedAt) < kRateAskAgainAfter) return false;
  return streakDays >= kRateMinStreak || totalReadingMs >= kRateMinReading.inMilliseconds;
}

/// Asks, if [shouldAskForRating] says so. Call it at a calm moment — closing
/// a book, not opening one — and let it decide; it reads the database only
/// after the cheap checks pass.
Future<void> maybeAskForRating(BuildContext context, WidgetRef ref) async {
  final store = ref.read(localStoreProvider);
  final settled = await store.get(_kStateKey) == 'settled';
  final askedAt = DateTime.tryParse(await store.get(_kAskedAtKey) ?? '');
  final now = DateTime.now();
  if (settled || (askedAt != null && now.difference(askedAt) < kRateAskAgainAfter)) return;
  final stats = await store.readingStats();
  if (!shouldAskForRating(
    state: RatingState.open,
    lastAskedAt: askedAt,
    streakDays: stats.streak,
    totalReadingMs: stats.totalMs,
    now: now,
  )) {
    return;
  }
  if (!context.mounted) return;
  await showRatingSheet(context, ref);
}

/// The sheet itself, also reachable from You → Rate Arth. Records the ask so
/// the automatic one doesn't follow it around.
Future<void> showRatingSheet(BuildContext context, WidgetRef ref) async {
  final store = ref.read(localStoreProvider);
  await store.set(_kAskedAtKey, DateTime.now().toIso8601String());
  ref.read(analyticsProvider).track('Rating Asked', const <String, Object>{});
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => const _RatingSheet(),
  );
}

/// Opens where a review is written, and says whether it got there.
///
/// `requestReview` is deliberately the fallback and not the first choice: it
/// is the quota-limited one, it can return having shown nothing, and on
/// Android it is not shown at all to a sideloaded build.
Future<bool> openWriteReview() async {
  if (Platform.isIOS) {
    // `action=write-review` opens the composer itself, not just the listing.
    if (kAppStoreId.isNotEmpty) {
      return openExternally(Uri.parse('https://apps.apple.com/app/id$kAppStoreId?action=write-review'));
    }
    try {
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return false;
      await review.requestReview();
      return true;
    } on Exception {
      return false;
    }
  }
  // Android: the Play listing, which is where the stars and the box to type
  // in live. `market:` goes straight to the installed Play app; the web
  // address is the way in on a phone that hasn't got one, and it has to be
  // tried even after `market:` has thrown.
  if (await openExternally(Uri.parse('market://details?id=$kAndroidPackage'))) return true;
  return openExternally(Uri.parse('https://play.google.com/store/apps/details?id=$kAndroidPackage'));
}

/// `launchUrl`, with "nothing on this phone opens that" as an answer rather
/// than an exception — which is what it is, every time, for `market:` on an
/// emulator without the Play Store.
Future<bool> openExternally(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception {
    return false;
  }
}

class _RatingSheet extends ConsumerStatefulWidget {
  const _RatingSheet();

  @override
  ConsumerState<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends ConsumerState<_RatingSheet> {
  /// 0 until a star is tapped; then 1–5 and the sheet moves on.
  int _stars = 0;

  Future<void> _settle() => ref.read(localStoreProvider).set(_kStateKey, 'settled');

  void _pick(int stars) {
    Haptics.commit();
    setState(() => _stars = stars);
    ref.read(analyticsProvider).track('Rated', <String, Object>{'stars': stars});
  }

  /// Closes the sheet and says so if the door wouldn't open. The messenger is
  /// taken before the pop: afterwards this context is defunct and there is
  /// nothing above it to show a SnackBar on.
  Future<void> _leaveFor(Future<bool> Function() open) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failed = ref.read(stringsProvider).linkFailed;
    await _settle();
    final opened = await open();
    if (!mounted) return;
    Navigator.pop(context);
    if (!opened) messenger?.showSnackBar(SnackBar(content: Text(failed)));
  }

  Future<void> _review() => _leaveFor(openWriteReview);

  Future<void> _tellUs() => _leaveFor(() {
        final t = ref.read(stringsProvider);
        return openExternally(Uri.https('wa.me', '/$kWhatsAppNumber', {'text': t.rateFeedbackHello}));
      });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final happy = _stars >= 4;
    final asked = _stars > 0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              !asked
                  ? t.rateTitle
                  : happy
                      ? t.rateThanks
                      : t.rateSorryTitle,
              style: uiHeading(hindi: t.isHindi, color: c.ink, scale: scale),
            ),
            const SizedBox(height: 8),
            Text(
              !asked
                  ? t.rateSubtitle
                  : happy
                      ? t.rateWriteWhy
                      : t.rateSorryWhy,
              style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale),
            ),
            const SizedBox(height: 16),
            _Stars(value: _stars, onPick: _pick),
            const SizedBox(height: 20),
            if (asked) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => unawaited(happy ? _review() : _tellUs()),
                  child: Text(happy ? t.rateWriteCta : t.rateTellUs),
                ),
              ),
              // The other door, open either way: five stars and still
              // something to say, or one star and still willing to write it.
              TextButton(
                onPressed: () => unawaited(happy ? _tellUs() : _review()),
                style: TextButton.styleFrom(foregroundColor: c.inkMuted),
                child: Text(
                  happy ? t.rateTellUs : t.rateInStore,
                  style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale),
                ),
              ),
            ] else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: c.inkMuted),
                  child: Text(t.rateNotNow, style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Five stars, filled up to [value]. Big enough to hit with a thumb.
class _Stars extends StatelessWidget {
  const _Stars({required this.value, required this.onPick});

  final int value;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var star = 1; star <= 5; star++)
          IconButton(
            onPressed: () => onPick(star),
            iconSize: 40,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            tooltip: '$star',
            icon: Icon(
              star <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              color: star <= value ? c.marigold : c.inkMuted,
            ),
          ),
      ],
    );
  }
}
