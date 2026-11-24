// The admin dashboard: the wire shape it reads, the sum it puts at the top,
// and what it says when a network isn't connected or didn't answer.

import 'dart:convert';
import 'dart:typed_data';

import 'package:arth/app/providers.dart';
import 'package:arth/app/strings.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/data/account.dart';
import 'package:arth/data/api_client.dart';
import 'package:arth/data/metrics.dart';
import 'package:arth/features/admin/admin_screen.dart';
import 'package:arth/features/admin/dashboard_tab.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers every request with one body, and remembers what was asked.
class _Canned implements HttpClientAdapter {
  _Canned(this.body);

  final Map<String, Object?> body;
  final List<String> urls = [];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    urls.add(options.uri.toString());
    return ResponseBody.fromString(jsonEncode({'ok': true, 'data': body}), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Three days of ads, a plan snapshot, and five readers.
Map<String, Object?> metricsJson({
  Map<String, Object?>? ads,
  Map<String, Object?>? purchases,
  int days = 3,
}) => {
      'days': days,
      'currency': 'INR',
      'ads': ads ??
          {
            'state': 'ok',
            'currency': 'INR',
            'earnings': 240.5,
            'impressions': 12_000,
            'clicks': 96,
            'ecpm': 20.04,
            'days': [
              {'day': '2026-11-22', 'earnings': 0, 'impressions': 0},
              {'day': '2026-11-23', 'earnings': 100.25, 'impressions': 5000},
              {'day': '2026-11-24', 'earnings': 140.25, 'impressions': 7000},
            ],
          },
      'purchases': purchases ??
          {
            'state': 'ok',
            'currency': 'INR',
            'revenue': 759.5,
            'metrics': [
              {'id': 'mrr', 'name': 'MRR', 'value': 1200.0, 'unit': r'$', 'period': 'P0D'},
              {'id': 'active_subscriptions', 'name': 'Active Subscriptions', 'value': 14, 'unit': '#', 'period': 'P0D'},
            ],
          },
      'readers': {
        'total': 5,
        'new7': 4,
        'new30': 5,
        'paying': 2,
        'granted': 1,
        'banned': 1,
        'admins': 1,
        'tiers': {'free': 2, 'pro': 1, 'super': 2},
        'devices': {'total': 3, 'android': 2, 'ios': 1},
        'ai': {'month': 40, 'total': 310},
        'signups': [
          {'day': '2026-11-22', 'count': 1},
          {'day': '2026-11-23', 'count': 0},
          {'day': '2026-11-24', 'count': 3},
        ],
      },
      'community': {'decks': 7, 'comments': 19, 'openReports': 2},
    };

/// Pumps the tab and hands back the URLs it asks for, as it asks for them.
Future<List<String>> pumpDashboard(WidgetTester tester, Map<String, Object?> body) async {
  final adapter = _Canned(body);
  final client = ApiClient(dio: Dio(BaseOptions(baseUrl: 'http://fake/v1'))..httpClientAdapter = adapter);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(client)],
      child: MaterialApp(
        theme: arthTheme(Brightness.light),
        home: const Scaffold(body: DashboardTab()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return adapter.urls;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the wire shape', () {
    test('income from both networks, the readers behind it', () {
      final m = AdminMetrics.fromJson(metricsJson());
      expect(m.days, 3);
      expect(m.currency, 'INR');

      expect(m.ads.state, SourceState.ok);
      expect(m.ads.data!.earnings, 240.5);
      expect(m.ads.data!.days.map((d) => d.day), ['2026-11-22', '2026-11-23', '2026-11-24']);
      expect(m.purchases.data!.revenue, 759.5);
      expect(m.purchases.data!.metrics.first.isMoney, isTrue, reason: 'MRR is money');
      expect(m.purchases.data!.metrics.first.isNow, isTrue);
      expect(m.purchases.data!.metrics.last.isMoney, isFalse, reason: 'a count of subscriptions is not');

      // The headline: ads plus plans, with both counted.
      expect(m.income, 1000.0);
      expect(m.incomePartial, isFalse);
      expect(m.countsAds && m.countsPurchases, isTrue);

      expect(m.readers.tiers, {Tier.free: 2, Tier.pro: 1, Tier.superTier: 2});
      expect(m.readers.devices, (total: 3, android: 2, ios: 1));
      expect(m.readers.aiMonth, 40);
      expect(m.readers.signups.map((s) => s.count), [1, 0, 3]);
      expect(m.community.openReports, 2);
    });

    test('a source that is off, failing, or in another currency never fakes a total', () {
      final off = AdminMetrics.fromJson(metricsJson(ads: {'state': 'off'}));
      expect(off.ads.state, SourceState.off);
      expect(off.ads.data, isNull);
      expect(off.income, 759.5, reason: 'the plans are still real income');
      expect(off.incomePartial, isTrue, reason: 'but it is not all of it');

      final failed = AdminMetrics.fromJson(metricsJson(purchases: {'state': 'error', 'reason': 'RevenueCat 403'}));
      expect(failed.purchases.state, SourceState.error);
      expect(failed.purchases.error, 'RevenueCat 403');
      expect(failed.income, 240.5);
      expect(failed.incomePartial, isTrue);

      final neither = AdminMetrics.fromJson(metricsJson(ads: {'state': 'off'}, purchases: {'state': 'off'}));
      expect(neither.income, isNull);
      expect(neither.incomePartial, isFalse);

      // Two currencies can't be added, so the screen says so instead.
      final mixed = AdminMetrics.fromJson(
        metricsJson(purchases: {'state': 'ok', 'currency': 'USD', 'revenue': 9.0, 'metrics': <Object?>[]}),
      );
      expect(mixed.income, isNull);
      expect(mixed.purchases.data!.currency, 'USD');

      // Revenue the key couldn't read leaves the snapshot standing.
      final snapshot = AdminMetrics.fromJson(
        metricsJson(purchases: {'state': 'ok', 'currency': 'INR', 'revenue': null, 'metrics': <Object?>[]}),
      );
      expect(snapshot.purchases.state, SourceState.ok);
      expect(snapshot.countsPurchases, isFalse);
      expect(snapshot.income, 240.5);
    });

    test('a reader from an older server, with fields missing', () {
      final m = AdminMetrics.fromJson({'readers': <String, Object?>{}, 'community': <String, Object?>{}});
      expect(m.days, 30);
      expect(m.ads.state, SourceState.off);
      expect(m.readers.total, 0);
      expect(m.readers.tiers, {Tier.free: 0, Tier.pro: 0, Tier.superTier: 0});
      expect(m.readers.signups, isEmpty);
      expect(m.income, isNull);
    });
  });

  group('the screen', () {
    testWidgets('asks for a month, shows the income and the numbers under it', (tester) async {
      final urls = await pumpDashboard(tester, metricsJson(days: 30));
      expect(urls.single, contains('days=30'), reason: 'a month by default');

      const t = AppStrings.en;
      expect(find.text(t.incomeTitle), findsOneWidget);
      // ₹240.50 of ads and ₹759.50 of plans, as one number.
      expect(find.text('₹1,000'), findsOneWidget);
      expect(find.text(t.incomeFromBoth), findsOneWidget);
      expect(find.text('₹240.50'), findsOneWidget, reason: 'the ads panel');
      expect(find.text('₹759.50'), findsOneWidget, reason: 'the plans panel');
      expect(find.text('12,000'), findsOneWidget, reason: 'impressions');
      expect(find.text('MRR'), findsOneWidget);
      expect(find.text('₹1,200'), findsOneWidget);
      expect(find.text('Active Subscriptions'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text(t.notConnected), findsNothing);

      // Readers and community sit below the fold, with the tier split named.
      await tester.scrollUntilVisible(find.text('Free 2'), 240);
      expect(find.text('Super 2'), findsOneWidget);
      expect(find.text(t.signupsPerDay), findsOneWidget);
      await tester.scrollUntilVisible(find.text(t.openReports), 240);
      expect(find.text('19'), findsOneWidget, reason: 'comments');
      expect(find.text('7'), findsOneWidget, reason: 'recaps');
    });

    testWidgets('a different window is a different request', (tester) async {
      final urls = await pumpDashboard(tester, metricsJson());
      await tester.tap(find.text(AppStrings.en.rangeDays(90)));
      await tester.pumpAndSettle();
      expect(urls.length, 2);
      expect(urls.last, contains('days=90'));
    });

    testWidgets('the dashboard is the first of the four admin tabs', (tester) async {
      final client = ApiClient(dio: Dio(BaseOptions(baseUrl: 'http://fake/v1'))..httpClientAdapter = _Canned(metricsJson()));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(client)],
          child: MaterialApp(theme: arthTheme(Brightness.light), home: const AdminScreen()),
        ),
      );
      await tester.pumpAndSettle();
      const t = AppStrings.en;
      for (final tab in [t.adminDashboard, t.adminReports, t.adminReaders, t.adminBroadcast]) {
        expect(find.widgetWithText(Tab, tab), findsOneWidget);
      }
      expect(find.byType(DashboardTab), findsOneWidget, reason: 'it opens on the dashboard');
      expect(find.text(t.incomeTitle), findsOneWidget);
    });

    testWidgets('a network that is off, and one that failed, say which', (tester) async {
      await pumpDashboard(
        tester,
        metricsJson(ads: {'state': 'off'}, purchases: {'state': 'error', 'reason': 'RevenueCat 403'}),
      );
      const t = AppStrings.en;
      expect(find.text(t.notConnected), findsOneWidget);
      expect(find.text(t.sourceError), findsOneWidget);
      expect(find.text(t.adsNotConnected), findsOneWidget);
      expect(find.text(t.sourceFailed('RevenueCat 403')), findsOneWidget);
      expect(find.text(t.incomeNone), findsOneWidget, reason: 'no income to add up');
      expect(find.text('5'), findsWidgets, reason: 'the reader counts are still there');
    });
  });
}
