import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell.dart';
import '../../core/adhkar/adhkar_time.dart';
import '../../core/prayer/prayer.dart';
import '../../core/providers.dart';
import '../../design/tab_theme.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import '../daily/adhkar_screen.dart' show adhkarDoneToday;
import '../daily/prayer_widgets.dart';

/// Home is a calm starting point: the date and next prayer, the adhkar for
/// this moment of the day (and whether today's are done), and a way into
/// every part of the app.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(quranDbProvider);
    final isFriday = DateTime.now().weekday == DateTime.friday;

    final c = context.colors;
    return Scaffold(
      body: AnnotatedRegion(
        value: SystemUiOverlayStyle.light,
        child: Stack(children: [
          CustomScrollView(slivers: [
          const SliverToBoxAdapter(child: _Header()),
          const SliverToBoxAdapter(child: SectionTitle('Today')),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: Space.gutter),
            sliver: SliverToBoxAdapter(child: _AdhkarNow()),
          ),
          if (isFriday)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, 0),
                child: _KahfRow(onTap: () => context.openReader(db.surah(18).pageStart, surah: 18)),
              ),
            ),
          const SliverToBoxAdapter(child: SectionTitle('Explore')),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: Space.gutter),
            sliver: SliverToBoxAdapter(child: _Explore()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ]),
          // The status bar keeps the header's green while the page scrolls under it.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.paddingOf(context).top,
            child: ColoredBox(color: c.brand),
          ),
        ]),
      ),
    );
  }
}

/// The green header: date, greeting, next prayer.
class _Header extends ConsumerWidget {
  const _Header();

  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Peaceful night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final fg = c.onBrand;
    final hijri = ref.watch(hijriTodayProvider);
    final now = DateTime.now();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(Radii.xl)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.brand, Color.lerp(c.brand, Colors.black, c.isDark ? 0.25 : 0.18)!],
          ),
        ),
        child: Stack(children: [
          Positioned.fill(child: GirihPattern(color: fg, cell: 48, opacity: 0.06)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.xs, Space.xl),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      '${_weekdays[now.weekday - 1]} · ${hijri.day} ${hijri.monthName} ${hijri.year}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(color: c.gold),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Search',
                    icon: Icon(Icons.search_rounded, color: fg),
                    onPressed: () => context.push('/search'),
                  ),
                  IconButton(
                    tooltip: 'Settings',
                    icon: Icon(Icons.settings_outlined, color: fg),
                    onPressed: () => context.push('/settings'),
                  ),
                ]),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(_greeting(), maxLines: 1, style: context.text.headlineSmall?.copyWith(color: fg)),
                ),
                Text('السلام عليكم ورحمة الله', style: TextStyle(fontFamily: kNaskhFont, fontSize: 16, color: fg.withValues(alpha: 0.75))),
                const SizedBox(height: Space.md),
                const _NextPrayer(),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// "Dhuhr 12:06 PM · in 2h 10m", tap for all prayer times.
class _NextPrayer extends ConsumerWidget {
  const _NextPrayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final fg = c.onBrand;
    final settings = ref.watch(prayerSettingsProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final next = settings.hasLocation ? ref.read(prayerServiceProvider).next(now) : null;
    return Padding(
      padding: const EdgeInsets.only(right: Space.md),
      child: Material(
        color: fg.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: fg.withValues(alpha: 0.14)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: () => context.push('/prayer'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
            child: Row(children: [
              Icon(Icons.mosque_outlined, size: 20, color: c.gold),
              const SizedBox(width: Space.md),
              Expanded(
                child: next == null
                    ? Text('Prayer times', style: context.text.titleMedium?.copyWith(color: fg))
                    : Text.rich(
                        TextSpan(children: [
                          TextSpan(text: next.$1.en, style: context.text.titleMedium?.copyWith(color: fg)),
                          TextSpan(
                            text: '  ${next.$1.ar}',
                            style: context.text.bodyMedium?.copyWith(color: fg.withValues(alpha: 0.7)),
                          ),
                        ]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              if (next != null)
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(formatTime(context, next.$2), style: context.text.titleMedium?.copyWith(color: fg)),
                  Text('in ${formatCountdown(next.$2.difference(now))}',
                      style: context.text.bodySmall?.copyWith(color: fg.withValues(alpha: 0.75))),
                ]),
            ]),
          ),
        ),
      ),
    );
  }
}

const _adhkarInfo = {
  'waking': ('Waking up', 'أذكار الاستيقاظ', Icons.wb_sunny_outlined),
  'morning': ('Morning adhkar', 'أذكار الصباح', Icons.wb_twilight_rounded),
  'after_salah': ('After prayer', 'أذكار بعد الصلاة', Icons.mosque_outlined),
  'evening': ('Evening adhkar', 'أذكار المساء', Icons.nights_stay_outlined),
  'sleep': ('Before sleep', 'أذكار النوم', Icons.bedtime_outlined),
};

/// The adhkar for this moment, then today's main adhkar and whether they are done.
class _AdhkarNow extends ConsumerWidget {
  const _AdhkarNow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    ref.watch(clockProvider.select((v) => v.value?.minute)); // follows the clock
    final settings = ref.watch(prayerSettingsProvider);
    final now = DateTime.now();
    final moment = adhkarFor(now, ref.read(prayerServiceProvider).day(now, settings));
    final id = moment.categoryId;
    final (title, arabic, icon) = _adhkarInfo[id]!;
    final done = adhkarDoneToday(ref, id);
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xl), side: BorderSide(color: c.divider)),
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            borderRadius: BorderRadius.circular(Radii.lg),
            onTap: () => context.push('/adhkar/$id'),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
                child: Icon(icon, color: c.primary, size: 22),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(moment.reason.toUpperCase(), style: context.text.labelSmall?.copyWith(color: c.gold)),
                  Text(title, style: context.text.titleLarge),
                  Text(done ? 'Done today · تقبّل الله' : arabic,
                      style: context.text.bodyMedium?.copyWith(color: done ? c.primary : c.inkMuted)),
                ]),
              ),
              if (done) Icon(Icons.check_circle_rounded, color: c.primary),
            ]),
          ),
          const SizedBox(height: Space.lg),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                onPressed: () => context.push('/adhkar/$id?listen=1'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Listen'),
              ),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                onPressed: () => context.push('/adhkar/$id'),
                icon: const Icon(Icons.menu_book_outlined, size: 20),
                label: const Text('Read'),
              ),
            ),
          ]),
          const SizedBox(height: Space.lg),
          Divider(color: c.divider, height: 1),
          const SizedBox(height: Space.md),
          // Today's main adhkar at a glance: a missed one stays visible.
          Row(children: [
            for (final (k, label) in const [('morning', 'Morning'), ('evening', 'Evening'), ('sleep', 'Sleep')]) ...[
              if (k != 'morning') const SizedBox(width: Space.sm),
              Expanded(child: _DayChip(id: k, label: label, done: adhkarDoneToday(ref, k), current: k == id)),
            ],
          ]),
        ]),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.id, required this.label, required this.done, required this.current});
  final String id, label;
  final bool done, current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: done ? c.primarySoft : c.surfaceAlt,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () => context.push('/adhkar/$id'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 16, color: done ? c.primary : (current ? c.gold : c.inkFaint)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(color: done ? c.primary : c.ink)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _KahfRow extends StatelessWidget {
  const _KahfRow({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg), side: BorderSide(color: c.divider)),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.md, Space.md),
          child: Row(children: [
            Icon(Icons.menu_book_rounded, color: AppTab.quran.accent),
            const SizedBox(width: Space.lg),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Surah Al-Kahf · Jumu'ah", style: context.text.titleMedium),
                Text('The Sunnah of Friday', style: context.text.bodySmall),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: c.inkMuted),
          ]),
        ),
      ),
    );
  }
}

/// Every part of the app, one tap away.
class _Explore extends StatelessWidget {
  const _Explore();

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, Color, VoidCallback)>[
      (Icons.menu_book_rounded, 'Quran', AppTab.quran.accent, () => context.go('/quran')),
      (Icons.headphones_rounded, 'Listen', AppTab.listen.accent, () => context.go('/listen')),
      (Icons.auto_stories_rounded, 'Hadith', AppTab.hadith.accent, () => context.go('/hadith')),
      (Icons.favorite_border_rounded, 'Adhkar', AppTab.home.accent, () => context.push('/adhkar')),
      (Icons.access_time_rounded, 'Prayer', AppTab.daily.accent, () => context.push('/prayer')),
      (Icons.explore_outlined, 'Qibla', AppTab.daily.accent, () => context.push('/qibla')),
      (Icons.blur_circular_rounded, 'Tasbih', AppTab.home.accent, () => context.push('/tasbih')),
      (Icons.fact_check_outlined, 'Memorize', AppTab.quran.accent, () => context.push('/memorize')),
    ];
    return LayoutBuilder(builder: (context, box) {
      final columns = box.maxWidth >= 560 ? 8 : 4;
      const gap = Space.md;
      final w = (box.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final (icon, label, color, onTap) in items)
          SizedBox(width: w, child: _ExploreTile(icon: icon, label: label, color: color, onTap: onTap)),
      ]);
    });
  }
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = c.isDark ? Color.lerp(color, Colors.white, 0.35)! : color;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg), side: BorderSide(color: c.divider)),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.md, horizontal: 4),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: tint.withValues(alpha: c.isDark ? 0.18 : 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: tint, size: 22),
            ),
            const SizedBox(height: Space.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, style: context.text.labelLarge?.copyWith(color: c.ink)),
            ),
          ]),
        ),
      ),
    );
  }
}
