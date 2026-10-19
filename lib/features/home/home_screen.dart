import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell.dart';
import '../../core/adhkar/adhkar.dart';
import '../../core/adhkar/adhkar_time.dart';
import '../../core/providers.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import '../daily/adhkar_screen.dart' show adhkarDoneToday;
import '../memorize/memorize_screens.dart' show quizHistoryProvider;

const _gold = Color(0xFF8A6A2B);

/// Home (Ivory Manuscript): a greeting on the paper, the adhkar for this
/// moment as the one emerald card, every part of the app as illuminated
/// tiles, and practice.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final db = ref.watch(quranDbProvider);
    final isFriday = DateTime.now().weekday == DateTime.friday;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnnotatedRegion(
        value: systemBars(c),
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _Header()),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, 0),
                  sliver: SliverToBoxAdapter(child: _AdhkarNow()),
                ),
                if (isFriday)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, 0),
                      child: _RowCard(
                        icon: Icons.menu_book_rounded,
                        color: _gold,
                        tinted: true,
                        title: "Surah Al-Kahf · Jumu'ah",
                        subtitle: 'The Sunnah of Friday',
                        onTap: () => context.openReader(db.surah(18).pageStart, surah: 18),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SectionTitle('Explore')),
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: Space.gutter),
                  sliver: SliverToBoxAdapter(child: _Explore()),
                ),
                const SliverToBoxAdapter(child: SectionTitle('Practise')),
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: Space.gutter),
                  sliver: SliverToBoxAdapter(child: _MemorizeCard()),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
            // The paper stays under the status bar while the page scrolls.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.paddingOf(context).top,
              child: ColoredBox(color: c.bg),
            ),
          ],
        ),
      ),
    );
  }
}

/// The day and Hijri date, a greeting in serif and the salaam, on the paper.
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
    final hijri = ref.watch(hijriTodayProvider);
    final now = DateTime.now();
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.md, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_weekdays[now.weekday - 1]} · ${hijri.day} ${hijri.monthName} ${hijri.year}'.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelSmall?.copyWith(color: c.goldText, fontSize: 12),
                  ),
                  const SizedBox(height: Space.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(_greeting(), maxLines: 1, style: context.text.headlineMedium),
                  ),
                  Text('السلام عليكم ورحمة الله',
                      style: TextStyle(fontFamily: kNaskhFont, fontSize: 18, height: 1.5, color: c.inkMuted)),
                ],
              ),
            ),
            _RoundButton(icon: Icons.search_rounded, tooltip: 'Search', onTap: () => context.push('/search')),
            const SizedBox(width: Space.sm),
            _RoundButton(icon: Icons.settings_outlined, tooltip: 'Settings', onTap: () => context.push('/settings')),
          ],
        ),
      ),
    );
  }
}

/// A round ivory button edged in gold.
class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: c.surface,
        shape: CircleBorder(side: BorderSide(color: c.divider)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(dimension: 44, child: Icon(icon, size: 21, color: c.ink)),
        ),
      ),
    );
  }
}

/// The adhkar for this moment, and whether they are done.
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
    final gold = c.goldOnBrand;
    final listen = cat != null && cat.listeningTime() > Duration.zero;
    return BrandPanel(
      onTap: () => context.push(page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(moment.reason.toUpperCase(), style: context.text.labelSmall?.copyWith(color: gold)),
                    const SizedBox(height: Space.xs),
                    Text(title, style: context.text.headlineSmall?.copyWith(color: c.onBrand)),
                    Text(
                      done ? 'Done today · تقبّل الله' : arabic,
                      style: TextStyle(
                          fontFamily: kNaskhFont, fontSize: 18, height: 1.5, color: c.onBrand.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
              if (done) Icon(Icons.check_circle_rounded, color: gold, size: 30),
            ],
          ),
          if (!done && listen) ...[
            const SizedBox(height: Space.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : counted / total,
                minHeight: 6,
                color: gold,
                backgroundColor: c.onBrand.withValues(alpha: 0.18),
              ),
            ),
            if (started) ...[
              const SizedBox(height: Space.xs),
              Text('$counted of $total read',
                  style: context.text.bodySmall?.copyWith(color: c.onBrand.withValues(alpha: 0.75))),
            ],
          ],
          const SizedBox(height: Space.lg),
          if (tasbih)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: gold, foregroundColor: c.brand, minimumSize: const Size.fromHeight(46)),
              onPressed: () => context.push('/tasbih'),
              icon: const Icon(Icons.blur_circular_rounded),
              label: const Text('Open Tasbih'),
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: gold, foregroundColor: c.brand, minimumSize: const Size.fromHeight(46)),
                    onPressed: () => context.push('/adhkar/$id?listen=1'),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(listen
                        ? '${started ? 'Continue' : 'Listen'} · ${formatListeningTime(cat.listeningTime(full: audio.full))}'
                        : (started ? 'Continue' : 'Listen')),
                  ),
                ),
                const SizedBox(width: Space.md),
                SizedBox(
                  width: 104,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.onBrand,
                      side: BorderSide(color: c.onBrand.withValues(alpha: 0.45)),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: () => context.push('/adhkar/$id'),
                    child: const Text('Read'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Practise the Quran: the memorization test, with the last result.
class _MemorizeCard extends ConsumerWidget {
  const _MemorizeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(quizHistoryProvider).firstOrNull;
    return _RowCard(
      icon: Icons.psychology_alt_rounded,
      color: _gold,
      tinted: true,
      title: 'Test your hifz',
      subtitle: last == null ? 'Surahs, juz or the whole Quran' : 'Last: ${last.scope} · ${last.score}/${last.total}',
      onTap: () => context.push('/memorize'),
    );
  }
}

/// Every main part of the app, four to a row: each an ivory tile edged in
/// gold with its Arabic name in calligraphy, like an illuminated initial.
class _Explore extends StatelessWidget {
  const _Explore();

  @override
  Widget build(BuildContext context) {
    final items = <(String, String, VoidCallback)>[
      ('قرآن', 'Quran', () => context.go('/quran')),
      ('تلاوة', 'Listen', () => context.go('/listen')),
      ('حديث', 'Hadith', () => context.go('/hadith')),
      ('أذكار', 'Adhkar', () => context.push('/adhkar')),
      ('صلاة', 'Prayer', () => context.push('/prayer')),
      ('قبلة', 'Qibla', () => context.push('/qibla')),
      ('تسبيح', 'Tasbih', () => context.push('/tasbih')),
      ('محفوظ', 'Saved', () => context.push('/library')),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 560 ? 8 : 4;
        final w = box.maxWidth / columns;
        return Wrap(
          runSpacing: Space.md,
          children: [
            for (final (ar, en, onTap) in items)
              SizedBox(width: w, child: _ExploreTile(arabic: ar, label: en, onTap: onTap)),
          ],
        );
      },
    );
  }
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({required this.arabic, required this.label, required this.onTap});
  final String arabic, label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.xs),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: c.divider),
                boxShadow: cardShadow(c),
              ),
              child: Text(arabic,
                  maxLines: 1,
                  style: TextStyle(fontFamily: kNaskhFont, fontSize: 21, height: 1.3, color: c.primary)),
            ),
            const SizedBox(height: Space.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  maxLines: 1, style: context.text.bodySmall?.copyWith(color: c.ink, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-width row card: an icon, a title and a line under it.
class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tinted = false,
  });
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;

  /// On a soft tint of its colour instead of ivory.
  final bool tinted;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        color: !tinted ? null : (color == _gold ? context.colors.goldTint : context.colors.emeraldTint),
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.md, Space.md),
        child: Row(
          children: [
            IconBadge(icon, color: color, size: 44),
            const SizedBox(width: Space.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleMedium),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.colors.inkFaint),
          ],
        ),
      );
}
