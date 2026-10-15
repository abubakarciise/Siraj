import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/settings.dart';
import '../../design/dialogs.dart';
import '../../design/tokens.dart';
import '../reader/reader_screen.dart' show PaperPicker;

const kAppName = 'Siraj';
const kAppVersion = '2.0.0';
const kRepoUrl = 'github.com/Abuubakar-Ciise/Quiz-App';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final c = context.colors;
    final catalog = ref.watch(catalogProvider).value;
    final rec = s.defaultRecitation == null ? null : catalog?.recitation(s.defaultRecitation!);
    final reciter = rec == null ? null : catalog?.reciter(rec.reciterId);
    final daily = ref.watch(dailyRemindersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const _Header('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: Row(children: [
              for (final t in ThemePref.values) ...[
                if (t != ThemePref.values.first) const SizedBox(width: Space.sm),
                Expanded(
                  child: _ThemeCard(
                    pref: t,
                    selected: s.theme == t,
                    onTap: () => n.update((x) => x.copyWith(theme: t)),
                  ),
                ),
              ],
            ]),
          ),
          const _Header('Mushaf page colour'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Space.gutter),
            child: PaperPicker(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, 0),
            child: Text('"Theme" follows the app appearance. Also available from the palette button while reading.',
                style: context.text.bodySmall),
          ),
          const _Header('Reminders'),
          ListTile(
            leading: Icon(Icons.notifications_active_outlined, color: c.primary),
            title: const Text('Reminders & sounds'),
            subtitle: Text(daily.enabled
                ? 'Daily reminders every ${daily.everyHours == 1 ? 'hour' : '${daily.everyHours} hours'}'
                : 'Daily reminders are off · choose alert sounds'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/reminders'),
          ),
          const _Header('Reading'),
          SwitchListTile(
            title: const Text('Keep screen on while reading'),
            value: s.keepScreenOn,
            onChanged: (v) => n.update((x) => x.copyWith(keepScreenOn: v)),
          ),
          SwitchListTile(
            title: const Text('Follow recitation'),
            subtitle: const Text('Turn pages automatically with the audio'),
            value: s.followAudio,
            onChanged: (v) => n.update((x) => x.copyWith(followAudio: v)),
          ),
          ListTile(
            title: const Text('Translation'),
            subtitle: Text(switch (s.translation) {
              'en_sahih' => 'English · Saheeh International',
              'so_abduh' => 'Soomaali · Mahmud Muhammad Abduh',
              _ => 'Off',
            }),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showAppSheet(
              context,
              title: 'Translation',
              builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
                for (final (slug, label) in const [
                  ('en_sahih', 'English · Saheeh International'),
                  ('so_abduh', 'Soomaali · Mahmud Muhammad Abduh'),
                  ('', 'Off'),
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(label),
                    trailing: s.translation == slug ? Icon(Icons.check_rounded, color: c.primary) : null,
                    onTap: () {
                      n.update((x) => x.copyWith(translation: slug));
                      Navigator.pop(ctx);
                    },
                  ),
              ]),
            ),
          ),
          const _Header('Audio & downloads'),
          ListTile(
            title: const Text('Mushaf reciter'),
            subtitle: Text(reciter == null ? 'Automatic (featured reciter)' : '${reciter.name} · ${rec!.shortName}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showAppSheet(
              context,
              title: 'Mushaf reciter',
              builder: (_) => const Text(
                  'Open any reciter in the Listen tab and choose "Use for Mushaf playback" from the ⋮ menu.'),
            ),
          ),
          SwitchListTile(
            title: const Text('Download on Wi-Fi only'),
            subtitle: const Text('Saves mobile data. Downloads wait until Wi-Fi is available.'),
            value: s.wifiOnly,
            onChanged: (v) => n.update((x) => x.copyWith(wifiOnly: v)),
          ),
          const _Header('About'),
          ListTile(
            title: const Text('Sources & licenses'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showAppSheet(context, title: 'Sources & licenses', builder: (_) => const _Sources()),
          ),
          ListTile(
            title: const Text('Privacy'),
            subtitle: Text(
              'No account, no ads, no tracking. Your bookmarks, history and downloads stay on this device.',
              style: context.text.bodySmall?.copyWith(color: c.inkMuted),
            ),
          ),
          ListTile(
            title: const Text('Open source'),
            subtitle: const Text('Free forever. Code, issues and contributions: $kRepoUrl'),
          ),
          ListTile(
            title: const Text('Open-source licenses'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showLicensePage(
              context: context,
              applicationName: kAppName,
              applicationVersion: kAppVersion,
              applicationLegalese: 'Quran · Hadith · Daily guide. Free and open source.',
            ),
          ),
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
      ThemePref.system => 'Auto',
      ThemePref.light => 'Light',
      ThemePref.dark => 'Dark',
      ThemePref.midnight => 'Midnight',
    };
    return Semantics(
      button: true,
      selected: selected,
      label: '$label theme',
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

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xxl, Space.gutter, Space.sm),
        child: Text(text.toUpperCase(), style: context.text.labelSmall?.copyWith(color: context.colors.primary)),
      );
}

class _Sources extends StatelessWidget {
  const _Sources();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Quran text & font', 'King Fahd Glorious Quran Printing Complex (KFGQPC), Uthmanic Hafs v18.'),
      ('Mushaf page layout', 'KFGQPC Hafs 15-line layout, via Quran.com (Quran Foundation).'),
      ('Translations', 'Saheeh International; Mahmud Muhammad Abduh (Somali), via Quran.com.'),
      ('Recitations', 'MP3Quran.net: reciters, audio files and ayah timings. Audio streams and downloads directly from their servers.'),
      ('Adhkar', "Hisn al-Muslim by Sa'id bin Ali bin Wahf Al-Qahtani; Quran passages from the KFGQPC text."),
      ('Hadith', 'Arabic texts, English translations and grades from the hadith-api project by Fawaz Ahmed (public domain).'),
      ('Hijri calendar', 'Umm al-Qura calculation, adjustable for local moon sighting.'),
      ('Reminder sounds', 'Original sounds made for this app (tool/make_sounds.py).'),
      ('Prayer times & Qibla', 'Calculated on your phone with the open-source Adhan library.'),
      ('UI font', 'IBM Plex Sans Arabic (SIL Open Font License).'),
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
