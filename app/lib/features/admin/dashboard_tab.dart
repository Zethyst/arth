// The admin dashboard: what Arth earns, and who it earns it from.
//
// Income has two halves and the server reads each one live — ads from AdMob,
// plans from RevenueCat (api/src/billing/income.ts). Either can be off (no keys
// on the server) or failing, and those are not the same as earning nothing, so
// each panel says which it is instead of printing a zero. The reader and
// community counts underneath are ours, straight out of Mongo.

import 'dart:async';
import 'dart:math' as math;

import 'package:arth/app/feel.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/strings.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/data/account.dart';
import 'package:arth/data/api_client.dart';
import 'package:arth/data/metrics.dart';
import 'package:arth/features/account/account_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// The windows an admin can ask for. A month is the default: long enough for a
/// weekly rhythm to show, short enough that AdMob answers quickly.
const _ranges = [7, 30, 90];

/// Money in the currency the server asked both networks for. Paise matter on a
/// slow day and are noise on a good one, so they show only on small amounts.
String money(double value, String currency) => NumberFormat.simpleCurrency(
      locale: currency == 'INR' ? 'en_IN' : null,
      name: currency.isEmpty ? null : currency,
      decimalDigits: value.abs() >= 1000 ? 0 : 2,
    ).format(value);

String count(int n) => NumberFormat.decimalPattern('en_IN').format(n);

/// 'Nov 24' for a '2026-11-24' day key, for the ends of a chart.
String _shortDay(String key) {
  final at = DateTime.tryParse(key);
  return at == null ? key : DateFormat('d MMM').format(at);
}

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  AdminMetrics? _metrics;
  String? _error;
  int _days = 30;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final metrics = await ref.read(apiClientProvider).adminMetrics(days: _days);
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _error = null;
        });
      }
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = ref.read(stringsProvider).errorFor(e.code, e.message));
    }
  }

  void _pick(int days) {
    if (days == _days) return;
    Haptics.choose();
    setState(() {
      _days = days;
      _metrics = null;
      _error = null;
    });
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = ref.watch(stringsProvider);
    final scale = ref.watch(settingsProvider).hindiScale;
    final m = _metrics;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final days in _ranges)
                ChoiceChip(
                  label: Text(t.rangeDays(days)),
                  selected: _days == days,
                  showCheckmark: false,
                  onSelected: (_) => _pick(days),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (m == null)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : Text(_error!, textAlign: TextAlign.center, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
              ),
            )
          else ...[
            _Income(m: m, t: t, scale: scale),
            const SizedBox(height: 14),
            _Ads(m: m, t: t, scale: scale),
            const SizedBox(height: 14),
            _Plans(m: m, t: t, scale: scale),
            const SizedBox(height: 14),
            _Readers(m: m, t: t, scale: scale),
            const SizedBox(height: 14),
            _Community(m: m, t: t, scale: scale),
          ],
        ],
      ),
    );
  }
}

/// The headline: ads plus plans over the window, and what that number counts.
class _Income extends StatelessWidget {
  const _Income({required this.m, required this.t, required this.scale});

  final AdminMetrics m;
  final AppStrings t;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final income = m.income;
    final from = switch ((m.countsAds, m.countsPurchases)) {
      (true, true) => t.incomeFromBoth,
      (true, false) => t.incomeFromAds,
      (false, true) => t.incomeFromPlans,
      _ => null,
    };
    return _Panel(
      accent: true,
      title: t.incomeTitle,
      trailing: Text(t.lastDays(m.days), style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
      children: [
        if (income == null)
          Text(
            m.ads.data == null && m.purchases.data == null ? t.incomeNone : t.incomeMixedCurrency,
            style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale),
          )
        else ...[
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(money(income, m.ads.data?.currency ?? m.purchases.data?.currency ?? m.currency), style: EnglishText.title(c.ink, size: 40)),
          ),
          const SizedBox(height: 4),
          // Accent when a source is missing from the sum: the number is real,
          // but it isn't the whole of the income.
          if (from != null) Text(from, style: uiLabel(hindi: t.isHindi, color: m.incomePartial ? c.accent : c.inkMuted, scale: scale)),
        ],
      ],
    );
  }
}

/// AdMob: what the ads paid, and the shape of the days behind it.
class _Ads extends StatelessWidget {
  const _Ads({required this.m, required this.t, required this.scale});

  final AdminMetrics m;
  final AppStrings t;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ads = m.ads.data;
    return _Panel(
      title: t.adsCard,
      icon: Icons.ondemand_video_outlined,
      trailing: _SourceBadge(state: m.ads.state, t: t, scale: scale),
      children: [
        if (ads == null)
          _Unavailable(source: m.ads, note: t.adsNotConnected, t: t, scale: scale)
        else ...[
          Text(money(ads.earnings, ads.currency), style: EnglishText.title(c.ink, size: 30)),
          const SizedBox(height: 12),
          _Bars(
            values: [for (final d in ads.days) d.earnings],
            labels: [for (final d in ads.days) d.day],
            caption: t.perDay,
            t: t,
            scale: scale,
            format: (v) => money(v, ads.currency),
          ),
          const SizedBox(height: 12),
          _Stats(
            t: t,
            scale: scale,
            stats: [
              (label: t.impressions, value: count(ads.impressions)),
              (label: t.clicks, value: count(ads.clicks)),
              (label: t.ecpm, value: money(ads.ecpm, ads.currency)),
            ],
          ),
        ],
      ],
    );
  }
}

/// RevenueCat: the window's revenue, then every headline metric it reports.
class _Plans extends StatelessWidget {
  const _Plans({required this.m, required this.t, required this.scale});

  final AdminMetrics m;
  final AppStrings t;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final plans = m.purchases.data;
    return _Panel(
      title: t.plansCard,
      icon: Icons.workspace_premium_outlined,
      trailing: _SourceBadge(state: m.purchases.state, t: t, scale: scale),
      children: [
        if (plans == null)
          _Unavailable(source: m.purchases, note: t.plansNotConnected, t: t, scale: scale)
        else ...[
          if (plans.revenue == null)
            Text(t.revenueUnavailable, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale))
          else ...[
            Text(money(plans.revenue!, plans.currency), style: EnglishText.title(c.ink, size: 30)),
            Text('${t.revenueWindow} · ${t.lastDays(m.days)}', style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale)),
          ],
          // Whatever RevenueCat names, in its own words: a metric it adds later
          // shows up here without the app needing a change.
          for (final metric in plans.metrics) ...[
            Divider(color: c.rule, height: 22),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(metric.name, style: EnglishText.label(c.ink)),
                      Text(metric.isNow ? t.rightNow : t.last28Days, style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale).copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                Text(
                  metric.isMoney ? money(metric.value, plans.currency) : count(metric.value.round()),
                  style: EnglishText.heading(c.ink, size: 18),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

/// Who the readers are: how many, on what plan, and how much AI they use.
class _Readers extends StatelessWidget {
  const _Readers({required this.m, required this.t, required this.scale});

  final AdminMetrics m;
  final AppStrings t;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = m.readers;
    final newInWindow = m.days <= 7 ? r.new7 : r.new30;
    return _Panel(
      title: t.adminReaders,
      icon: Icons.groups_outlined,
      children: [
        Text(count(r.total), style: EnglishText.title(c.ink, size: 30)),
        const SizedBox(height: 10),
        _Stats(
          t: t,
          scale: scale,
          stats: [
            (label: '${t.newReaders} · ${t.lastDays(m.days <= 7 ? 7 : 30)}', value: count(newInWindow)),
            (label: t.payingReaders, value: count(r.paying)),
            (label: t.grantedPlans, value: count(r.granted)),
            (label: t.bannedBadge, value: count(r.banned)),
            (label: t.phones, value: count(r.devices.total)),
            (label: t.androidIos, value: '${count(r.devices.android)} / ${count(r.devices.ios)}'),
            (label: t.aiThisMonth, value: count(r.aiMonth)),
            (label: t.aiEver, value: count(r.aiTotal)),
          ],
        ),
        const SizedBox(height: 14),
        _TierSplit(tiers: r.tiers, t: t, scale: scale),
        const SizedBox(height: 14),
        _Bars(
          values: [for (final s in r.signups) s.count.toDouble()],
          labels: [for (final s in r.signups) s.day],
          caption: t.signupsPerDay,
          t: t,
          scale: scale,
          format: (v) => count(v.round()),
        ),
      ],
    );
  }
}

class _Community extends StatelessWidget {
  const _Community({required this.m, required this.t, required this.scale});

  final AdminMetrics m;
  final AppStrings t;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final community = m.community;
    return _Panel(
      title: t.communityTitle,
      icon: Icons.forum_outlined,
      children: [
        _Stats(
          t: t,
          scale: scale,
          stats: [
            (label: t.recaps, value: count(community.decks)),
            (label: t.comments, value: count(community.comments)),
            (label: t.openReports, value: count(community.openReports)),
          ],
        ),
      ],
    );
  }
}

// ---- pieces ----

/// A bordered card, like the rest of the app's surfaces.
class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.children, this.icon, this.trailing, this.accent = false});

  final String title;
  final List<Widget> children;
  final IconData? icon;
  final Widget? trailing;

  /// The income headline wears the accent border; the rest are plain.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: accent ? c.accent : c.ink, width: 2),
        boxShadow: [BoxShadow(color: c.shadow, offset: const Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: c.inkMuted), const SizedBox(width: 6)],
              Expanded(child: Text(title, style: EnglishText.caps(c.inkMuted, size: 12))),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

/// 'Not connected' or 'Failed', for a source that gave no numbers.
class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.state, required this.t, required this.scale});

  final SourceState state;
  final AppStrings t;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (state == SourceState.ok) return const SizedBox.shrink();
    final off = state == SourceState.off;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: (off ? c.inkMuted : c.accent).withValues(alpha: 0.12), border: Border.all(color: c.ink, width: 1.5)),
      child: Text(off ? t.notConnected : t.sourceError, style: uiLabel(hindi: t.isHindi, color: off ? c.inkMuted : c.accent, scale: scale).copyWith(fontSize: 11)),
    );
  }
}

/// Why a panel has no numbers: nothing configured, or the network refused.
class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.source, required this.note, required this.t, required this.scale});

  final IncomeSource<dynamic> source;
  final String note;
  final AppStrings t;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final failed = source.state == SourceState.error;
    return Text(
      failed ? t.sourceFailed(source.error ?? '') : note,
      style: uiBody(hindi: t.isHindi, color: failed ? c.accent : c.inkMuted, scale: scale, size: 14),
    );
  }
}

/// Label-and-number rows, two to a line when there's room.
class _Stats extends StatelessWidget {
  const _Stats({required this.stats, required this.t, required this.scale});

  final List<({String label, String value})> stats;
  final AppStrings t;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (_, box) {
        final width = (box.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            for (final stat in stats)
              SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stat.value, style: EnglishText.heading(c.ink, size: 18)),
                    Text(stat.label, style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale).copyWith(fontSize: 11), maxLines: 2),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Free / Pro / Super as one bar, so the mix reads at a glance.
class _TierSplit extends StatelessWidget {
  const _TierSplit({required this.tiers, required this.t, required this.scale});

  final Map<Tier, int> tiers;
  final AppStrings t;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = tiers.values.fold(0, (sum, n) => sum + n);
    final colors = {Tier.free: c.inkMuted, Tier.pro: c.marigold, Tier.superTier: c.accent};
    if (total == 0) return Text(t.noneYet, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 14));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(border: Border.all(color: c.ink, width: 1.5)),
          height: 16,
          child: Row(
            // A ColoredBox has no height of its own; centred, the fills vanish.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final tier in Tier.values)
                if ((tiers[tier] ?? 0) > 0) Expanded(flex: tiers[tier]!, child: ColoredBox(color: colors[tier]!)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final tier in Tier.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 9, height: 9, color: colors[tier]),
                  const SizedBox(width: 5),
                  Text('${tierLabel(tier, t)} ${count(tiers[tier] ?? 0)}', style: uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale).copyWith(fontSize: 11)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// One bar per day, oldest on the left, with the busiest day for scale.
class _Bars extends StatelessWidget {
  const _Bars({required this.values, required this.labels, required this.caption, required this.format, required this.t, required this.scale});

  final List<double> values;
  final List<String> labels;
  final String caption;
  final String Function(double) format;
  final AppStrings t;
  final double scale;

  static const _height = 64.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = uiLabel(hindi: t.isHindi, color: c.inkMuted, scale: scale).copyWith(fontSize: 11);
    final peak = values.fold<double>(0, math.max);
    if (values.isEmpty) return const SizedBox.shrink();
    // Ninety days on a phone leaves ~3px a bar: the gaps have to shrink with it.
    final gap = values.length > 45 ? 0.5 : (values.length > 14 ? 1.0 : 2.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(caption, style: label)),
            if (peak > 0) Text(format(peak), style: label),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: _height,
          child: peak <= 0
              ? Align(alignment: Alignment.centerLeft, child: Text(t.noneYet, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: scale, size: 14)))
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final value in values)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: gap),
                          // A zero day keeps a sliver, so the days stay countable.
                          child: Container(height: math.max(2, (value / peak) * _height), color: value > 0 ? c.accent : c.rule),
                        ),
                      ),
                  ],
                ),
        ),
        Container(height: 1.5, color: c.ink),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_shortDay(labels.first), style: label),
            Text(_shortDay(labels.last), style: label),
          ],
        ),
      ],
    );
  }
}
