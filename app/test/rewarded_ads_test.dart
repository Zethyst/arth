// Watching an ad for AI answers: the wire shape of a claim, when the offer
// is allowed to appear at all, and that a paying reader's screen is left
// exactly as it was.

import 'dart:convert';
import 'dart:typed_data';

import 'package:arth/app/account_providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/data/account.dart';
import 'package:arth/data/api_client.dart';
import 'package:arth/features/ads/ad_footer.dart';
import 'package:arth/features/ads/ads.dart';
import 'package:arth/features/ads/interstitials.dart';
import 'package:arth/features/ads/rewarded.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with one body, and remembers what was asked.
class _Canned implements HttpClientAdapter {
  _Canned(this.body);

  final Map<String, Object?> body;
  final List<String> calls = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add('${options.method} ${options.uri.path}');
    return ResponseBody.fromString(jsonEncode({'ok': true, 'data': body}), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// An account as /me describes it, with whatever the test cares about.
Account account({int adBonus = 3, int adsLeftToday = 5, Tier tier = Tier.free}) => Account(
      uid: 'u',
      displayName: 'Reader',
      bio: '',
      isAdmin: false,
      tier: tier,
      adBonus: adBonus,
      adsLeftToday: adsLeftToday,
      usage: const Usage(used: 100, limit: 100, monthly: false),
    );

class _FixedAccount extends AccountNotifier {
  _FixedAccount(this.value);

  final Account? value;

  @override
  Future<Account?> build() async => value;
}

/// A container with the profile already loaded: the offer depends on it, and
/// an unresolved profile is not a free reader.
Future<ProviderContainer> container({Account? who, bool showAds = true}) async {
  final c = ProviderContainer(
    overrides: [
      showAdsProvider.overrideWithValue(showAds),
      signedInUidProvider.overrideWithValue(who == null ? null : 'u'),
      accountProvider.overrideWith(() => _FixedAccount(who)),
    ],
  );
  addTearDown(c.dispose);
  await c.read(accountProvider.future);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the claim', () {
    test('posts to the bonus endpoint and reads what it bought', () async {
      final adapter = _Canned({
        'granted': 3,
        'adBonus': 3,
        'adsLeftToday': 4,
        'usage': {'used': 100, 'limit': 103, 'period': 'lifetime', 'resetsAt': null, 'bonus': 3},
      });
      final client = ApiClient(dio: Dio(BaseOptions(baseUrl: 'http://fake/v1'))..httpClientAdapter = adapter);
      final bonus = await client.claimAdBonus();
      expect(adapter.calls.single, 'POST /v1/me/ai-bonus');
      expect(bonus.granted, 3);
      expect(bonus.adsLeftToday, 4);
      expect(bonus.usage!.limit, 103, reason: '100 free + 3 earned');
      expect(bonus.usage!.bonus, 3);
      expect(bonus.usage!.exhausted, isFalse, reason: 'the three earned are there to spend');
    });

    test('a day already spent is an answer, not a failure', () async {
      final adapter = _Canned({
        'granted': 0,
        'adBonus': 3,
        'adsLeftToday': 0,
        'usage': {'used': 100, 'limit': 115, 'period': 'lifetime', 'resetsAt': null, 'bonus': 15},
      });
      final client = ApiClient(dio: Dio(BaseOptions(baseUrl: 'http://fake/v1'))..httpClientAdapter = adapter);
      final bonus = await client.claimAdBonus();
      expect(bonus.granted, 0);
      expect(bonus.adsLeftToday, 0);
    });

    test('a server with no offer, and an older one that says nothing', () {
      expect(Account.fromJson({'uid': 'u', 'tier': 'free'}).adBonus, 0);
      expect(Account.fromJson({'uid': 'u', 'tier': 'free'}).adsLeftToday, 0);
      expect(const Usage(used: 1, limit: 100, monthly: false).bonus, 0);
    });
  });

  group('when the offer appears', () {
    test('a signed-in free reader with ads left today', () async {
      expect((await container(who: account())).read(canEarnAnswersProvider), isTrue);
    });

    test('never signed out, never for a reader who sees no ads', () async {
      expect((await container()).read(canEarnAnswersProvider), isFalse); // signed out
      expect((await container(who: account(), showAds: false)).read(canEarnAnswersProvider), isFalse);
    });

    test('never when the server pays nothing, or the day is spent', () async {
      expect((await container(who: account(adBonus: 0))).read(canEarnAnswersProvider), isFalse);
      expect((await container(who: account(adsLeftToday: 0))).read(canEarnAnswersProvider), isFalse);
    });

    test('the day’s count comes from the account, then from each claim', () async {
      final c = await container(who: account());
      expect(c.read(adsLeftProvider), 5);
      c.read(adsLeftProvider.notifier).report(0);
      expect(c.read(adsLeftProvider), 0);
      expect(c.read(canEarnAnswersProvider), isFalse, reason: 'the offer goes away at once');
    });
  });

  group('the banner footer', () {
    Future<void> pump(WidgetTester tester, {required bool showAds, Widget? below}) => tester.pumpWidget(
          ProviderScope(
            overrides: [showAdsProvider.overrideWithValue(showAds)],
            child: MaterialApp(
              theme: arthTheme(Brightness.light),
              home: Scaffold(
                body: const Text('the screen'),
                bottomNavigationBar: AdFooter(below: below),
              ),
            ),
          ),
        );

    testWidgets('it is as tall as the ad, not as tall as the screen', (tester) async {
      await pump(tester, showAds: true);
      // A bare Center fills what the bottomNavigationBar slot offers, which
      // is the whole screen: the footer then covers the page.
      expect(tester.getSize(find.byType(AdFooter)).height, lessThan(100));
      expect(find.text('the screen'), findsOneWidget);
    });

    testWidgets('a paying reader gets nothing, and keeps the bar they had', (tester) async {
      await pump(tester, showAds: false);
      expect(find.byType(AdBanner), findsNothing);

      await pump(tester, showAds: false, below: const Text('write a comment'));
      expect(find.text('write a comment'), findsOneWidget);
      expect(find.byType(AdBanner), findsNothing);
    });
  });

  group('the new breaks', () {
    final start = DateTime(2026, 11, 25, 10);
    DateTime at(int minutes) => start.add(Duration(minutes: minutes));

    test('practice, coaching and tools need no reading time, only the pacing', () {
      for (final b in [AdBreak.finishedPractice, AdBreak.finishedCoach, AdBreak.leftTool]) {
        final p = AdPacing(appStartedAt: start);
        expect(p.allows(b, now: at(1)), isFalse, reason: 'not in the launch grace');
        expect(p.allows(b, now: at(5)), isTrue, reason: '$b is its own break');
        p.lastShownAt = at(5);
        expect(p.allows(b, now: at(9)), isFalse, reason: 'one ad per six minutes, whatever the break');
        expect(p.allows(b, now: at(12)), isTrue);
      }
    });

    test('more breaks is not more ads: one slot, more ways to reach it', () {
      final p = AdPacing(appStartedAt: start)..lastShownAt = at(10);
      for (final b in AdBreak.values) {
        expect(p.allows(b, now: at(13), readFor: const Duration(minutes: 9)), isFalse);
      }
    });
  });
}
