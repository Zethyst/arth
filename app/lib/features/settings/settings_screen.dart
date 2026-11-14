import 'dart:async';

import 'package:arth/app/account_providers.dart';
import 'package:arth/app/feel.dart';
import 'package:arth/app/providers.dart';
import 'package:arth/app/theme.dart';
import 'package:arth/data/seed_loader.dart';
import 'package:arth/features/account/account_card.dart';
import 'package:arth/features/account/ai_lookup_gate.dart';
import 'package:arth/features/rating/rate_app.dart';
import 'package:arth/features/seed/seed_screen.dart';
import 'package:arth/features/settings/settings_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Runs the same delta the app runs once a day, on demand, and stamps the
/// clock so the automatic one doesn't immediately repeat it. A failure needs
/// no message here: the caption under the progress bar already says why.
Future<void> _checkDictionaryNow(BuildContext context, WidgetRef ref) async {
  final t = ref.read(stringsProvider);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final r = await ref.read(seedProvider.notifier).run();
  if (r.phase != SeedPhase.done) return;
  await ref.read(localStoreProvider).set('seed_checked_at', DateTime.now().toIso8601String());
  messenger?.showSnackBar(SnackBar(content: Text(t.dictionaryChecked)));
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = ref.watch(settingsProvider);
    final t = ref.watch(stringsProvider);
    final n = ref.read(settingsProvider.notifier);
    final count = ref.watch(localEntryCountProvider).valueOrNull;
    final seed = ref.watch(seedProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
          children: [
            // Masthead: the monogram is the one loud thing on the page.
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(width: 14),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.settingsTitle,
                        style: uiTitle(
                          hindi: t.isHindi,
                          color: c.ink,
                          scale: s.hindiScale,
                        ),
                      ),
                      Text(
                        t.settingsIntro,
                        style: uiBody(
                          hindi: t.isHindi,
                          color: c.inkMuted,
                          scale: s.hindiScale,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const AccountCard(),
            if (ref.watch(accountProvider).valueOrNull?.isAdmin ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ListTile(
                  onTap: () => context.push('/admin'),
                  shape: RoundedRectangleBorder(side: BorderSide(color: c.ink, width: 2)),
                  tileColor: c.card,
                  leading: Icon(Icons.admin_panel_settings_outlined, color: c.accent),
                  title: Text(t.adminTitle, style: uiLabel(hindi: t.isHindi, color: c.ink, scale: s.hindiScale).copyWith(fontSize: 15)),
                  subtitle: Text(t.adminOpen, style: uiBody(hindi: t.isHindi, color: c.inkMuted, scale: s.hindiScale, size: 13)),
                  trailing: Icon(Icons.chevron_right_rounded, color: c.inkMuted),
                ),
              ),

            SettingsHeading(t.language),
            const LanguageTiles(),

            SettingsHeading(t.theme),
            const AppearancePicker(),

            SettingsHeading(t.tooltipDetail),
            const TooltipDetailControl(),

            SettingsHeading(t.hindiSize),
            const HindiSizeControl(),

            SettingsHeading(t.cardFont),
            const CardFontPicker(),
            SettingsCaption(t.cardFontHelp),

            const SizedBox(height: 26),
            Divider(color: c.rule),
            const SizedBox(height: 6),
            SettingsSwitch(
              title: t.tts,
              value: s.ttsEnabled,
              onChanged: (v) => n.update((s) => s.copyWith(ttsEnabled: v)),
            ),
            SettingsSwitch(
              title: t.haptics,
              value: s.haptics,
              onChanged: (v) => n.update((s) => s.copyWith(haptics: v)),
            ),
            SettingsSwitch(
              title: t.aiLookup,
              subtitle: t.aiLookupHelp,
              value: s.aiLookup,
              onChanged: (v) => unawaited(setAiLookup(context, ref, on: v)),
            ),
            SettingsSwitch(
              title: t.prefetch,
              subtitle: t.prefetchHelp,
              value: s.prefetch,
              onChanged: (v) => n.update((s) => s.copyWith(prefetch: v)),
            ),
            const CardReminderControls(),
            SettingsSwitch(
              title: t.usageStats,
              subtitle: t.usageStatsHelp,
              value: s.usageStats,
              onChanged: (v) => n.update((s) => s.copyWith(usageStats: v)),
            ),

            SettingsHeading(t.sectionDictionary),
            Row(
              children: [
                Expanded(
                  child: Text(
                    count == null ? '…' : t.wordsOnDevice(count),
                    style: uiBody(
                      hindi: t.isHindi,
                      color: c.ink,
                      scale: s.hindiScale,
                      size: 16.5,
                    ),
                  ),
                ),
                // The daily refresh is enough for almost everyone, but a
                // reader who has just been told about a new word, or whose
                // idioms haven't arrived, needs a way to ask now rather than
                // wait out a window they cannot see.
                TextButton(
                  onPressed: seed.phase == SeedPhase.downloading ? null : () => unawaited(_checkDictionaryNow(context, ref)),
                  style: TextButton.styleFrom(foregroundColor: c.accent, visualDensity: VisualDensity.compact),
                  child: Text(t.checkNow, style: uiLabel(hindi: t.isHindi, color: c.accent, scale: s.hindiScale)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (seed.phase == SeedPhase.downloading)
              ClipRRect(
                child: LinearProgressIndicator(
                  value: seed.fraction,
                  minHeight: 6,
                  color: c.marigold,
                  backgroundColor: c.rule,
                ),
              ),
            if (seed.phase == SeedPhase.failed || seed.retrying)
              SettingsCaption(seedStatusText(t, seed)),

            const SizedBox(height: 28),
            // The sheet asks on its own after a few days' reading; this is
            // for the reader who goes looking for it in between.
            Pressable.card(
              depth: 4,
              onTap: () => unawaited(showRatingSheet(context, ref)),
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.rateMenu,
                          style: uiBody(
                            hindi: t.isHindi,
                            color: c.ink,
                            scale: s.hindiScale,
                            size: 16.5,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.star_outline_rounded,
                        color: c.accent,
                        size: 20,
                      ),
                    ],
                  ),
                ),
            ),
            const SizedBox(height: 12),
            Pressable.card(
              depth: 4,
              onTap: () => context.push('/about'),
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.about,
                          style: uiBody(
                            hindi: t.isHindi,
                            color: c.ink,
                            scale: s.hindiScale,
                            size: 16.5,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: c.accent,
                        size: 20,
                      ),
                    ],
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }
}
