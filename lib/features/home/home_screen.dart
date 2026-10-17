import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell.dart';
import '../../core/adhkar/adhkar.dart';
import '../../core/adhkar/adhkar_time.dart';
import '../../core/providers.dart';
import '../../design/tab_theme.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import '../daily/adhkar_screen.dart' show adhkarDoneToday, adhkarIcons;
import '../memorize/memorize_screens.dart' show quizHistoryProvider;

/// Home: a short header, the adhkar for this moment of the day, practice,
/// and every part of the app two to a row.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final db = ref.watch(quranDbProvider);
    final isFriday = DateTime.now().weekday == DateTime.friday;

    return Scaffold(
      backgroundColor: Colors.transparent, // the tab's art shows through (TabBackdrop)
      body: AnnotatedRegion(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
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
                      child: _WideTile(
                        icon: Icons.menu_book_rounded,
                        color: AppTab.quran.accent,
                        title: "Surah Al-Kahf · Jumu'ah",
                        subtitle: 'The Sunnah of Friday',
                        onTap: () => context.openReader(db.surah(18).pageStart, surah: 18),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SectionTitle('Memorize')),
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: Space.gutter),
                  sliver: SliverToBoxAdapter(child: _MemorizeCard()),
                ),
                const SliverToBoxAdapter(child: SectionTitle('Explore')),
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: Space.gutter),
                  sliver: SliverToBoxAdapter(child: _Explore()),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
            // The status bar keeps the header's green while the page scrolls under it.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.paddingOf(context).top,
              child: ColoredBox(color: c.brand),
            ),
          ],
        ),
      ),
    );
  }
}

/// A short green header: date, greeting, search and settings.
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
        child: Stack(
          children: [
            Positioned.fill(child: GirihPattern(color: fg, cell: 48, opacity: 0.06)),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.xs, Space.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_weekdays[now.weekday - 1]} · ${hijri.day} ${hijri.monthName} ${hijri.year}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall?.copyWith(color: c.gold),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              _greeting(),
                              maxLines: 1,
                              style: context.text.headlineSmall?.copyWith(color: fg),
                            ),
                          ),
                          Text(
                            'السلام عليكم ورحمة الله',
                            style: TextStyle(fontFamily: kNaskhFont, fontSize: 15, color: fg.withValues(alpha: 0.75)),
                          ),
                        ],
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

/// The adhkar for this moment, then today's main adhkar and whether they are done.
class _AdhkarNow extends ConsumerWidget {
  const _AdhkarNow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(clockProvider.select((v) => v.value?.minute)); // follows the clock
    ref.watch(adhkarProvider);
    ref.watch(prayerSettingsProvider);
    // Rebuilds as adhkar are counted, here or while listening.
    return ListenableBuilder(listenable: ref.watch(adhkarPlayerProvider), builder: (context, _) => _card(context, ref));
  }

  Widget _card(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final audio = ref.read(adhkarPlayerProvider);
    final settings = ref.read(prayerSettingsProvider);
    final now = DateTime.now();
    final doneAt = ref.read(prefsProvider).getInt('adhkar_done_at_after_salah');
    final moment = adhkarFor(
      now,
      ref.read(prayerServiceProvider).day(now, settings),
      done: (id) => adhkarDoneToday(ref, id),
      afterSalahDoneAt: doneAt == null ? null : DateTime.fromMillisecondsSinceEpoch(doneAt),
    );
    final id = moment.categoryId;
    final (title, arabic) = adhkarNames[id]!;
    final done = id != 'after_salah' && adhkarDoneToday(ref, id);
    final cat = ref.read(adhkarProvider).value?.where((x) => x.id == id).firstOrNull;
    final (counted, total) = cat == null ? (0, 0) : audio.progress(cat);
    final started = !done && counted > 0;
    // Dhikr through the day happens on the Tasbih screen.
    final tasbih = id == 'tasbih';
    final page = tasbih ? '/tasbih' : '/adhkar/$id';
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xl),
        side: BorderSide(color: c.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(Radii.lg),
              onTap: () => context.push(page),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
                    child: Icon(adhkarIcons[id] ?? Icons.auto_awesome_rounded, color: c.primary, size: 22),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(moment.reason.toUpperCase(), style: context.text.labelSmall?.copyWith(color: c.gold)),
                        Text(title, style: context.text.titleLarge),
                        Text(
                          done
                              ? 'Done today · تقبّل الله'
                              : [
                                  arabic,
                                  if (started) '$counted of $total',
                                  if (cat != null && cat.listeningTime > Duration.zero)
                                    '${formatListeningTime(cat.listeningTime)} to listen',
                                ].join(' · '),
                          style: context.text.bodyMedium?.copyWith(color: done ? c.primary : c.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  if (done) Icon(Icons.check_circle_rounded, color: c.primary),
                ],
              ),
            ),
            const SizedBox(height: Space.lg),
            if (tasbih)
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                onPressed: () => context.push('/tasbih'),
                icon: const Icon(Icons.blur_circular_rounded),
                label: const Text('Open Tasbih'),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                      onPressed: () => context.push('/adhkar/$id?listen=1'),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(started ? 'Continue' : 'Listen'),
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
                ],
              ),
            const SizedBox(height: Space.lg),
            Divider(color: c.divider, height: 1),
            const SizedBox(height: Space.md),
            // Today's main adhkar at a glance: a missed one stays visible.
            Row(
              children: [
                for (final (k, label) in const [
                  ('morning', 'Morning'),
                  ('evening', 'Evening'),
                  ('sleep', 'Sleep'),
                ]) ...[
                  if (k != 'morning') const SizedBox(width: Space.sm),
                  Expanded(
                    child: _DayChip(id: k, label: label, done: adhkarDoneToday(ref, k), current: k == id),
                  ),
                ],
              ],
            ),
          ],
        ),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: done ? c.primary : (current ? c.gold : c.inkFaint),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(color: done ? c.primary : c.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Practice the Quran: a card of its own, with the last result.
class _MemorizeCard extends ConsumerWidget {
  const _MemorizeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(quizHistoryProvider).firstOrNull;
    const ink = Color(0xFF3B2A12);
    return Material(
      borderRadius: BorderRadius.circular(Radii.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/memorize'),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF4E3BC), Color(0xFFE2C27F)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: GirihPattern(color: ink, cell: 40, opacity: 0.06)),
              Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: ink.withValues(alpha: 0.9), shape: BoxShape.circle),
                      child: const Icon(Icons.psychology_alt_rounded, color: Color(0xFFF4E3BC), size: 30),
                    ),
                    const SizedBox(width: Space.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Test your hifz',
                            style: context.text.titleLarge?.copyWith(color: ink, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            last == null
                                ? 'Surahs, juz or the whole Quran'
                                : 'Last: ${last.scope} · ${last.score}/${last.total}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodyMedium?.copyWith(color: ink.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: ink),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every main part of the app, two to a row.
class _Explore extends StatelessWidget {
  const _Explore();

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String, Color, VoidCallback)>[
      (Icons.menu_book_rounded, 'Quran', 'المصحف', AppTab.quran.accent, () => context.go('/quran')),
      (Icons.graphic_eq_rounded, 'Listen', 'التلاوات', AppTab.listen.accent, () => context.go('/listen')),
      (Icons.history_edu_rounded, 'Hadith', 'الحديث', AppTab.hadith.accent, () => context.go('/hadith')),
      (Icons.auto_awesome_rounded, 'Adhkar', 'الأذكار', AppTab.home.accent, () => context.push('/adhkar')),
      (Icons.mosque_rounded, 'Prayer times', 'مواقيت الصلاة', AppTab.daily.accent, () => context.push('/prayer')),
      (Icons.explore_rounded, 'Qibla', 'القبلة', const Color(0xFF8A5A9E), () => context.push('/qibla')),
      (Icons.blur_circular_rounded, 'Tasbih', 'التسبيح', const Color(0xFF2E4A7D), () => context.push('/tasbih')),
      (Icons.bookmarks_rounded, 'Saved', 'المحفوظات', const Color(0xFF7A6A3A), () => context.push('/library')),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 560 ? 4 : 2;
        const gap = Space.md;
        final w = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (icon, title, ar, color, onTap) in items)
              SizedBox(
                width: w,
                child: _ExploreTile(icon: icon, title: title, arabic: ar, color: color, onTap: onTap),
              ),
          ],
        );
      },
    );
  }
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({
    required this.icon,
    required this.title,
    required this.arabic,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title, arabic;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tint = c.isDark ? Color.lerp(color, Colors.white, 0.3)! : color;
    return Material(
      borderRadius: BorderRadius.circular(Radii.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(c.surface, tint, c.isDark ? 0.16 : 0.10)!, c.surface],
            ),
            border: Border.all(color: Color.lerp(c.divider, tint, 0.25)!),
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(Radii.md)),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                      Text(
                        arabic,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: kNaskhFont, fontSize: 14, color: c.inkMuted, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A full-width row card.
class _WideTile extends StatelessWidget {
  const _WideTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: c.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.md, Space.md),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: Space.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleMedium),
                    Text(subtitle, style: context.text.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
