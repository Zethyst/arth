// What the admin dashboard shows (GET /v1/admin/metrics): income from ads and
// from plans bought in the stores, and the readers behind it.
//
// Each income source is read live from the network that holds the money, so a
// source can be off (no keys on the server) or failing. Those are different
// from "earned nothing", and the screen says which it is rather than printing
// a zero.

import 'package:arth/data/account.dart';

enum SourceState { off, ok, error }

/// One income source: its numbers, or why there are none.
class IncomeSource<T> {
  const IncomeSource(this.state, {this.data, this.error});

  factory IncomeSource.fromJson(Map<String, dynamic>? j, T Function(Map<String, dynamic>) parse) {
    if (j == null) return IncomeSource<T>(SourceState.off);
    return switch (j['state'] as String?) {
      'ok' => IncomeSource<T>(SourceState.ok, data: parse(j)),
      'error' => IncomeSource<T>(SourceState.error, error: j['reason'] as String?),
      _ => IncomeSource<T>(SourceState.off),
    };
  }

  final SourceState state;
  final T? data;

  /// Short, for an admin's eyes: 'AdMob 403', 'RevenueCat 500'.
  final String? error;
}

/// One day of ad earnings, by UTC date ('2026-11-24').
class DayEarning {
  const DayEarning({required this.day, required this.earnings, required this.impressions});

  factory DayEarning.fromJson(Map<String, dynamic> j) => DayEarning(
        day: j['day'] as String,
        earnings: (j['earnings'] as num?)?.toDouble() ?? 0,
        impressions: (j['impressions'] as num?)?.toInt() ?? 0,
      );

  final String day;
  final double earnings;
  final int impressions;
}

/// AdMob over the window: what it paid, and how it got there.
class AdIncome {
  const AdIncome({required this.currency, required this.earnings, required this.impressions, required this.clicks, required this.ecpm, required this.days});

  factory AdIncome.fromJson(Map<String, dynamic> j) => AdIncome(
        currency: (j['currency'] as String?) ?? '',
        earnings: (j['earnings'] as num?)?.toDouble() ?? 0,
        impressions: (j['impressions'] as num?)?.toInt() ?? 0,
        clicks: (j['clicks'] as num?)?.toInt() ?? 0,
        ecpm: (j['ecpm'] as num?)?.toDouble() ?? 0,
        days: [for (final d in (j['days'] as List<dynamic>?) ?? const []) DayEarning.fromJson(d as Map<String, dynamic>)],
      );

  final String currency;
  final double earnings;
  final int impressions;
  final int clicks;

  /// Earnings per thousand impressions, as AdMob counts it.
  final double ecpm;
  final List<DayEarning> days;
}

/// A headline number from RevenueCat, named as RevenueCat names it.
class PurchaseMetric {
  const PurchaseMetric({required this.id, required this.name, required this.value, required this.unit, required this.period});

  factory PurchaseMetric.fromJson(Map<String, dynamic> j) => PurchaseMetric(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? (j['id'] as String),
        value: (j['value'] as num?)?.toDouble() ?? 0,
        unit: (j['unit'] as String?) ?? '',
        period: (j['period'] as String?) ?? '',
      );

  final String id;
  final String name;
  final double value;

  /// RevenueCat's own label for the unit; not dependable, so [isMoney] decides.
  final String unit;

  /// 'P0D' (right now) or 'P28D' (the last 28 days).
  final String period;

  /// Whether to print this as money. The API documents no reliable unit for
  /// money, so it goes by the metric's id — which RevenueCat does document.
  bool get isMoney => id.contains('revenue') || id.contains('mrr') || id.contains('arr') || id.contains('arpu');

  /// True for a number that is a snapshot rather than a sum over 28 days.
  bool get isNow => period == 'P0D';
}

/// Plans bought in the stores, over the window and right now.
class PurchaseIncome {
  const PurchaseIncome({required this.currency, required this.revenue, required this.metrics});

  factory PurchaseIncome.fromJson(Map<String, dynamic> j) => PurchaseIncome(
        currency: (j['currency'] as String?) ?? '',
        revenue: (j['revenue'] as num?)?.toDouble(),
        metrics: [for (final m in (j['metrics'] as List<dynamic>?) ?? const []) PurchaseMetric.fromJson(m as Map<String, dynamic>)],
      );

  final String currency;

  /// Revenue over the window; null when the key couldn't read it.
  final double? revenue;
  final List<PurchaseMetric> metrics;
}

/// Readers, their plans, their phones and their AI use.
class ReaderCounts {
  const ReaderCounts({
    required this.total,
    required this.new7,
    required this.new30,
    required this.paying,
    required this.granted,
    required this.banned,
    required this.admins,
    required this.tiers,
    required this.devices,
    required this.aiMonth,
    required this.aiTotal,
    required this.signups,
  });

  factory ReaderCounts.fromJson(Map<String, dynamic> j) {
    final tiers = (j['tiers'] as Map<String, dynamic>?) ?? const {};
    final devices = (j['devices'] as Map<String, dynamic>?) ?? const {};
    final ai = (j['ai'] as Map<String, dynamic>?) ?? const {};
    int at(Map<String, dynamic> m, String k) => (m[k] as num?)?.toInt() ?? 0;
    return ReaderCounts(
      total: at(j, 'total'),
      new7: at(j, 'new7'),
      new30: at(j, 'new30'),
      paying: at(j, 'paying'),
      granted: at(j, 'granted'),
      banned: at(j, 'banned'),
      admins: at(j, 'admins'),
      tiers: {Tier.free: at(tiers, 'free'), Tier.pro: at(tiers, 'pro'), Tier.superTier: at(tiers, 'super')},
      devices: (total: at(devices, 'total'), android: at(devices, 'android'), ios: at(devices, 'ios')),
      aiMonth: at(ai, 'month'),
      aiTotal: at(ai, 'total'),
      signups: [
        for (final s in (j['signups'] as List<dynamic>?) ?? const [])
          (day: (s as Map<String, dynamic>)['day'] as String, count: (s['count'] as num?)?.toInt() ?? 0),
      ],
    );
  }

  final int total;
  final int new7;
  final int new30;

  /// Readers on a plan they bought: the ones paying now.
  final int paying;

  /// Readers an admin put on a plan.
  final int granted;
  final int banned;
  final int admins;
  final Map<Tier, int> tiers;
  final ({int total, int android, int ios}) devices;

  /// AI uses this calendar month across everyone, and ever.
  final int aiMonth;
  final int aiTotal;

  /// New readers per day over the window, oldest first.
  final List<({String day, int count})> signups;
}

/// What the community holds: live recaps, live comments, reports waiting.
class CommunityCounts {
  const CommunityCounts({required this.decks, required this.comments, required this.openReports});

  factory CommunityCounts.fromJson(Map<String, dynamic> j) => CommunityCounts(
        decks: (j['decks'] as num?)?.toInt() ?? 0,
        comments: (j['comments'] as num?)?.toInt() ?? 0,
        openReports: (j['openReports'] as num?)?.toInt() ?? 0,
      );

  final int decks;
  final int comments;
  final int openReports;
}

class AdminMetrics {
  const AdminMetrics({
    required this.days,
    required this.currency,
    required this.ads,
    required this.purchases,
    required this.readers,
    required this.community,
  });

  factory AdminMetrics.fromJson(Map<String, dynamic> j) => AdminMetrics(
        days: (j['days'] as num?)?.toInt() ?? 30,
        currency: (j['currency'] as String?) ?? '',
        ads: IncomeSource<AdIncome>.fromJson(j['ads'] as Map<String, dynamic>?, AdIncome.fromJson),
        purchases: IncomeSource<PurchaseIncome>.fromJson(j['purchases'] as Map<String, dynamic>?, PurchaseIncome.fromJson),
        readers: ReaderCounts.fromJson((j['readers'] as Map<String, dynamic>?) ?? const {}),
        community: CommunityCounts.fromJson((j['community'] as Map<String, dynamic>?) ?? const {}),
      );

  /// How many days the window covers.
  final int days;

  /// The currency both sources were asked for, so the two can be added up.
  final String currency;
  final IncomeSource<AdIncome> ads;
  final IncomeSource<PurchaseIncome> purchases;
  final ReaderCounts readers;
  final CommunityCounts community;

  double? get _adEarnings => ads.data?.earnings;
  double? get _revenue => purchases.data?.revenue;

  /// Whether the two sources answered in currencies that can be added.
  bool get _sameCurrency {
    final a = ads.data?.currency;
    final p = purchases.data?.currency;
    return a == null || p == null || _revenue == null || a == p;
  }

  /// Income over the window: ads plus plans, as far as both answered. Null when
  /// neither did, or when they came back in currencies that can't be added.
  double? get income {
    if (_adEarnings == null && _revenue == null) return null;
    if (!_sameCurrency) return null;
    return (_adEarnings ?? 0) + (_revenue ?? 0);
  }

  /// True when [income] leaves a source out — so the screen can say so.
  bool get incomePartial => income != null && (_adEarnings == null || _revenue == null);

  bool get countsAds => _adEarnings != null;
  bool get countsPurchases => _revenue != null;
}
