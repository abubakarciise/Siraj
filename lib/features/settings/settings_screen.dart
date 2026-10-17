import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/settings.dart';
import '../../design/dialogs.dart';
import '../../design/tokens.dart';
import '../reader/reader_screen.dart' show PaperPicker, MushafPaperX;

const kAppName = 'Siraj';
const kAppVersion = '2.6.0';
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
      _ => 'Off',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, 40),
        children: [
          // ---- Appearance: what the app looks like, at a glance ----
          const _Header('Appearance'),
          Row(children: [
            for (final t in ThemePref.values) ...[
              if (t != ThemePref.values.first) const SizedBox(width: Space.sm),
              Expanded(
                child: _ThemeCard(pref: t, selected: s.theme == t, onTap: () => n.update((x) => x.copyWith(theme: t))),
              ),
            ],
          ]),
          const SizedBox(height: Space.md),
          _Group(children: [
            _Row(
              icon: Icons.palette_rounded,
              color: const Color(0xFFB8892F),
              title: 'Mushaf page colour',
              value: s.paper == MushafPaper.auto ? 'Same as the app' : s.paper.label,
              onTap: () => showAppSheet(context, title: 'Mushaf page colour', builder: (_) => const PaperPicker()),
            ),
          ]),

          // ---- Reading ----
          const _Header('Reading'),
          _Group(children: [
            _Row(
              icon: Icons.translate_rounded,
              color: const Color(0xFF2F7FA3),
              title: 'Translation',
              value: translation,
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
                      trailing: s.translation == slug ? Icon(Icons.check_rounded, color: ctx.colors.primary) : null,
                      onTap: () {
                        n.update((x) => x.copyWith(translation: slug));
                        Navigator.pop(ctx);
                      },
                    ),
                ]),
              ),
            ),
            _Switch(
              icon: Icons.auto_stories_rounded,
              color: const Color(0xFF0F6B56),
              title: 'Turn pages with the recitation',
              value: s.followAudio,
              onChanged: (v) => n.update((x) => x.copyWith(followAudio: v)),
            ),
            _Switch(
              icon: Icons.light_mode_rounded,
              color: const Color(0xFFC98A1A),
              title: 'Keep the screen on while reading',
              value: s.keepScreenOn,
              onChanged: (v) => n.update((x) => x.copyWith(keepScreenOn: v)),
            ),
          ]),

          // ---- Listening ----
          const _Header('Listening & downloads'),
          _Group(children: [
            _Switch(
              icon: Icons.wifi_rounded,
              color: const Color(0xFF5B5BA6),
              title: 'Download on Wi-Fi only',
              value: s.wifiOnly,
              onChanged: (v) => n.update((x) => x.copyWith(wifiOnly: v)),
            ),
            _Row(
              icon: Icons.download_done_rounded,
              color: const Color(0xFF3E7C59),
              title: 'Downloads & bookmarks',
              onTap: () => context.push('/library'),
            ),
          ]),

          // ---- Reminders ----
          const _Header('Reminders'),
          _Group(children: [
            _Row(
              icon: Icons.notifications_active_rounded,
              color: const Color(0xFFB5653B),
              title: 'Reminders & sound',
              value: daily.enabled
                  ? 'Daily reminders every ${daily.everyHours == 1 ? 'hour' : '${daily.everyHours} hours'}'
                  : 'Adhkar, prayer and daily reminders',
              onTap: () => context.push('/reminders'),
            ),
            _Row(
              icon: Icons.mosque_rounded,
              color: const Color(0xFF0E5A49),
              title: 'Prayer times',
              onTap: () => context.push('/prayer'),
            ),
          ]),

          // ---- About ----
          const _Header('About'),
          _Group(children: [
            _Row(
              icon: Icons.info_rounded,
              color: const Color(0xFF6B6B6B),
              title: 'About $kAppName',
              value: 'Version $kAppVersion · free and open source',
              onTap: () => showAppSheet(context, title: kAppName, builder: (_) => const _About()),
            ),
          ]),
        ],
      ),
    );
  }
}

/// A rounded card holding rows, separated by hairlines.
class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg), side: BorderSide(color: c.divider)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: 60, color: c.divider),
          children[i],
        ],
      ]),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon(this.icon, this.color);
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 19, color: Colors.white),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.color, required this.title, this.value, required this.onTap});
  final IconData icon;
  final Color color;
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.sm, Space.md),
        child: Row(children: [
          _Icon(icon, color),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.text.titleMedium),
              if (value != null)
                Text(value!, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: c.inkFaint),
        ]),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.icon, required this.color, required this.title, required this.value, required this.onChanged});
  final IconData icon;
  final Color color;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.sm, Space.sm),
          child: Row(children: [
            _Icon(icon, color),
            const SizedBox(width: Space.md),
            Expanded(child: Text(title, style: context.text.titleMedium)),
            Switch(value: value, onChanged: onChanged),
          ]),
        ),
      );
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
        padding: const EdgeInsets.fromLTRB(Space.xs, Space.xl, Space.xs, Space.sm),
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
      ('Adhkar recordings', 'hisnmuslim.com (Hisn al-Muslim) and, for Quranic adhkar, Mishary Alafasy via everyayah.com. Included in the app, so they play offline.'),
      ('App icon', 'The name سراج in Amiri Bold (SIL Open Font License).'),
      ('Reminder sound', 'Pixie Dust, from the Android Open Source Project (Apache 2.0).'),
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

class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Quran, Hadith and a daily guide. Version $kAppVersion.', style: context.text.bodyLarge),
      const SizedBox(height: Space.md),
      Text('No account, no ads, no tracking. Your bookmarks, history and downloads stay on this phone.',
          style: context.text.bodyMedium?.copyWith(color: c.inkMuted)),
      const SizedBox(height: Space.md),
      Text('Free and open source: $kRepoUrl', style: context.text.bodyMedium?.copyWith(color: c.inkMuted)),
      const SizedBox(height: Space.lg),
      OutlinedButton(
        onPressed: () => showAppSheet(context, title: 'Sources', builder: (_) => const _Sources()),
        child: const Text('Sources of the texts and audio'),
      ),
      const SizedBox(height: Space.sm),
      OutlinedButton(
        onPressed: () => showLicensePage(
          context: context,
          applicationName: kAppName,
          applicationVersion: kAppVersion,
          applicationLegalese: 'Quran · Hadith · Daily guide. Free and open source.',
        ),
        child: const Text('Open-source licenses'),
      ),
    ]);
  }
}
