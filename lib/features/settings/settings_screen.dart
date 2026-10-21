import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/settings.dart';
import '../../design/dialogs.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import '../../l10n/l10n.dart';
import '../reader/reader_screen.dart' show PaperPicker, MushafPaperX;

const kAppName = 'Siraj';
const kAppVersion = '2.17.0';
const kRepoUrl = 'github.com/Abuubakar-Ciise/Siraj';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final daily = ref.watch(dailyRemindersProvider);
    final translation = switch (s.translation) {
      'en_sahih' => 'English · Saheeh International',
      'so_abduh' => 'Soomaali · Mahmud Muhammad Abduh',
      _ => context.l10n.off,
    };

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, 40),
        children: [
          // ---- Appearance: what the app looks like, at a glance ----
          GroupHeader(context.l10n.appearance),
          Row(children: [
            for (final t in ThemePref.values) ...[
              if (t != ThemePref.values.first) const SizedBox(width: Space.sm),
              Expanded(
                child: _ThemeCard(pref: t, selected: s.theme == t, onTap: () => n.update((x) => x.copyWith(theme: t))),
              ),
            ],
          ]),
          const SizedBox(height: Space.md),
          SettingsGroup(children: [
            SettingsRow(
              icon: Icons.palette_rounded,
              color: const Color(0xFF8A6A2B),
              title: context.l10n.mushafPageColour,
              value: s.paper == MushafPaper.auto ? context.l10n.sameAsApp : s.paper.label,
              onTap: () => showAppSheet(context, title: context.l10n.mushafPageColour, builder: (_) => const PaperPicker()),
            ),
          ]),

          // ---- Reading ----
          GroupHeader(context.l10n.readingGroup),
          SettingsGroup(children: [
            SettingsRow(
              icon: Icons.translate_rounded,
              color: const Color(0xFF0F5C4A),
              title: context.l10n.translation,
              value: translation,
              onTap: () => showAppSheet(
                context,
                title: context.l10n.translation,
                builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
                  for (final (slug, label) in [
                    ('en_sahih', 'English · Saheeh International'),
                    ('so_abduh', 'Soomaali · Mahmud Muhammad Abduh'),
                    ('', context.l10n.off),
                  ])
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(label),
                      trailing: s.translation == slug ? Icon(Icons.check_rounded, color: ctx.colors.primary) : null,
                      onTap: () {
                        n.update((x) => x.copyWith(translation: slug));
                        Navigator.pop(ctx);
                      },
                    ),
                ]),
              ),
            ),
            SettingsSwitch(
              icon: Icons.auto_stories_rounded,
              color: const Color(0xFF8A6A2B),
              title: context.l10n.turnPagesWithRecitation,
              value: s.followAudio,
              onChanged: (v) => n.update((x) => x.copyWith(followAudio: v)),
            ),
            SettingsSwitch(
              icon: Icons.light_mode_rounded,
              color: const Color(0xFF0F5C4A),
              title: context.l10n.keepScreenOn,
              value: s.keepScreenOn,
              onChanged: (v) => n.update((x) => x.copyWith(keepScreenOn: v)),
            ),
          ]),

          // ---- Listening ----
          GroupHeader(context.l10n.listeningAndDownloads),
          SettingsGroup(children: [
            SettingsSwitch(
              icon: Icons.wifi_rounded,
              color: const Color(0xFF8A6A2B),
              title: context.l10n.downloadOnWifiOnly,
              value: s.wifiOnly,
              onChanged: (v) => n.update((x) => x.copyWith(wifiOnly: v)),
            ),
            SettingsRow(
              icon: Icons.download_done_rounded,
              color: const Color(0xFF0F5C4A),
              title: context.l10n.downloadsAndBookmarks,
              onTap: () => context.push('/library'),
            ),
          ]),

          // ---- Reminders ----
          GroupHeader(context.l10n.reminders),
          SettingsGroup(children: [
            SettingsRow(
              icon: Icons.notifications_active_rounded,
              color: const Color(0xFF8A6A2B),
              title: context.l10n.remindersAndSound,
              value: daily.enabled
                  ? context.l10n.dailyRemindersEvery(daily.everyHours)
                  : context.l10n.remindersCardSubtitleShort,
              onTap: () => context.push('/reminders'),
            ),
            SettingsRow(
              icon: Icons.mosque_rounded,
              color: const Color(0xFF0F5C4A),
              title: context.l10n.prayerTimes,
              onTap: () => context.push('/prayer'),
            ),
          ]),

          // ---- About ----
          GroupHeader(context.l10n.about),
          SettingsGroup(children: [
            SettingsRow(
              icon: Icons.info_rounded,
              color: const Color(0xFF56635D),
              title: context.l10n.aboutApp(kAppName),
              value: context.l10n.versionFreeOpenSource(kAppVersion),
              onTap: () => showAppSheet(context, title: kAppName, builder: (_) => const _About()),
            ),
          ]),
        ],
      ),
    );
  }
}





/// A miniature of the app in each appearance.
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.pref, required this.selected, required this.onTap});
  final ThemePref pref;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final platformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final preview = AppColors.of(const AppSettings().copyWith(theme: pref).resolve(platformDark));
    final label = switch (pref) {
      ThemePref.system => context.l10n.themeAuto,
      ThemePref.light => context.l10n.themeLight,
      ThemePref.dark => context.l10n.themeDark,
      ThemePref.midnight => context.l10n.themeMidnight,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.themeSemantics(label),
      child: GestureDetector(
        onTap: onTap,
        child: Column(children: [
          AnimatedContainer(
            duration: Motion.quick,
            height: 104,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: preview.bg,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: selected ? c.primary : c.divider, width: selected ? 2.5 : 1),
            ),
            child: pref == ThemePref.system
                ? Row(children: [
                    Expanded(child: _Mini(colors: AppColors.light)),
                    const SizedBox(width: 4),
                    Expanded(child: _Mini(colors: AppColors.dark)),
                  ])
                : _Mini(colors: preview),
          ),
          const SizedBox(height: 6),
          Text(label, style: context.text.bodySmall?.copyWith(color: selected ? c.primary : c.inkMuted)),
        ]),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.colors});
  final AppColors colors;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(6)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(height: 26, decoration: BoxDecoration(color: colors.brand, borderRadius: BorderRadius.circular(5))),
          const SizedBox(height: 5),
          Container(height: 6, width: 30, color: colors.ink.withValues(alpha: 0.8)),
          const SizedBox(height: 4),
          Container(height: 5, color: colors.inkMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 4),
          Container(height: 5, color: colors.inkMuted.withValues(alpha: 0.5)),
          const Spacer(),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: 10,
              width: 24,
              decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(5)),
            ),
          ),
        ]),
      );
}


class _Sources extends StatelessWidget {
  const _Sources();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (l10n.sourceQuranText, l10n.sourceQuranTextDetail),
      (l10n.sourceLayout, l10n.sourceLayoutDetail),
      (l10n.sourceTranslations, l10n.sourceTranslationsDetail),
      (l10n.sourceRecitations, l10n.sourceRecitationsDetail),
      (l10n.adhkar, l10n.sourceAdhkarDetail),
      (l10n.hadith, l10n.sourceHadithDetail),
      (l10n.sourceHijri, l10n.sourceHijriDetail),
      (l10n.sourceAdhkarAudio, l10n.sourceAdhkarAudioDetail),
      (l10n.sourceAppIcon, l10n.sourceAppIconDetail),
      (l10n.sourceReminderSound, l10n.sourceReminderSoundDetail),
      (l10n.sourcePrayer, l10n.sourcePrayerDetail),
      (l10n.sourceUiFont, l10n.sourceUiFontDetail),
    ];
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final (t, d) in items) ...[
        Text(t, style: context.text.titleMedium),
        Text(d, style: context.text.bodyMedium?.copyWith(color: context.colors.inkMuted)),
        const SizedBox(height: Space.md),
      ],
    ]);
  }
}

class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(context.l10n.aboutIntro(kAppVersion), style: context.text.bodyLarge),
      const SizedBox(height: Space.md),
      Text(context.l10n.aboutPrivacy,
          style: context.text.bodyMedium?.copyWith(color: c.inkMuted)),
      const SizedBox(height: Space.md),
      Text(context.l10n.aboutOpenSource(kRepoUrl), style: context.text.bodyMedium?.copyWith(color: c.inkMuted)),
      const SizedBox(height: Space.lg),
      OutlinedButton(
        onPressed: () => showAppSheet(context, title: context.l10n.sources, builder: (_) => const _Sources()),
        child: Text(context.l10n.sourcesButton),
      ),
      const SizedBox(height: Space.sm),
      OutlinedButton(
        onPressed: () => showLicensePage(
          context: context,
          applicationName: kAppName,
          applicationVersion: kAppVersion,
          applicationLegalese: context.l10n.licenseLegalese,
        ),
        child: Text(context.l10n.openSourceLicenses),
      ),
    ]);
  }
}
