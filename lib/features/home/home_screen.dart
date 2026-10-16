import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell.dart';
import '../../core/prayer/prayer.dart';
import '../../core/providers.dart';
import '../../core/quran/models.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import '../daily/adhkar_screen.dart' show adhkarDoneToday;
import '../daily/prayer_widgets.dart';
import '../player/play_actions.dart';

/// Home is the same every day, top to bottom: the next prayer, where you
/// left off, the adhkar for this time of day, one ayah, and practice.
/// Nothing on it is random.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
    final db = ref.watch(quranDbProvider);
    final last = ref.watch(lastReadProvider).value;
    final listening = ref.watch(lastListeningProvider).value;
    final catalog = ref.watch(catalogProvider).value;
    final aotd = ref.watch(ayahOfDayProvider).value;
    final hijri = ref.watch(hijriTodayProvider);
    final now = DateTime.now();
    final isFriday = now.weekday == DateTime.friday;

    final lastSurah = last == null ? null : db.surah(last.ref.surah);
    final progress = last == null || lastSurah == null
        ? 0.0
        : ((last.page - lastSurah.pageStart + 1) / (lastSurah.pageEnd - lastSurah.pageStart + 1)).clamp(0.0, 1.0);

    final listenRec = listening == null ? null : catalog?.recitation(listening.recitationKey);
    final listenReciter = listenRec == null ? null : catalog?.reciter(listenRec.reciterId);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(slivers: [
          // ---- Header ----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.xs, 0),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      '${_weekdays[now.weekday - 1]} · ${hijri.day} ${hijri.monthName} ${hijri.year}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(color: c.gold),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(_greeting(), maxLines: 1, style: context.text.headlineSmall),
                    ),
                  ]),
                ),
                IconButton(
                    tooltip: 'Search', icon: const Icon(Icons.search_rounded), onPressed: () => context.push('/search')),
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push('/settings'),
                ),
              ]),
            ),
          ),

          // ---- Next prayer, one line ----
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, 0),
            sliver: SliverToBoxAdapter(child: _NextPrayerStrip()),
          ),

          // ---- Continue reading ----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, 0),
              child: _HeroCard(
                overline: last == null ? 'START READING' : 'CONTINUE READING',
                title: lastSurah == null ? 'Al-Fatihah' : lastSurah.nameEn,
                subtitle: last == null ? 'Begin with the Opening' : 'Page ${last.page} · Ayah ${last.ref.ayah}',
                arabic: lastSurah?.nameAr ?? 'الفاتحة',
                progress: progress,
                onTap: () => context.openReader(last?.page ?? 1),
              ),
            ),
          ),

          // ---- Continue listening (only once there is something to continue) ----
          if (listening != null && listenRec != null && listenReciter != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, 0),
                child: _Row(
                  icon: Icons.headphones_rounded,
                  title: db.surah(listening.surah).nameEn,
                  subtitle: listenReciter.name,
                  trailing: Icon(Icons.play_circle_fill_rounded, color: c.primary, size: 36),
                  onTap: () => playRecitation(context, ref, listenReciter, listenRec, listening.surah, resume: true),
                ),
              ),
            ),

          // ---- Adhkar for this time of day ----
          const SliverToBoxAdapter(child: SectionTitle('Today')),
          const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: Space.gutter),
            sliver: SliverToBoxAdapter(child: _AdhkarNow()),
          ),
          if (isFriday)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, 0),
                child: _Row(
                  icon: Icons.menu_book_rounded,
                  title: "Surah Al-Kahf · Jumu'ah",
                  subtitle: 'The Sunnah of Friday',
                  trailing: Icon(Icons.chevron_right_rounded, color: c.inkMuted),
                  onTap: () => context.openReader(db.surah(18).pageStart, surah: 18),
                ),
              ),
            ),

          // ---- Ayah of the day ----
          if (aotd != null) ...[
            const SliverToBoxAdapter(child: SectionTitle('Ayah of the day')),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                child: Material(
                  color: c.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.lg),
                    side: BorderSide(color: c.divider),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Radii.lg),
                    onTap: () => context.openReader(aotd.page, ayah: aotd.ref.toString()),
                    child: Padding(
                      padding: const EdgeInsets.all(Space.xl),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text(
                          aotd.text,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: kQuranFont, fontSize: 24, height: 1.9, color: c.ink),
                        ),
                        const SizedBox(height: Space.md),
                        _AyahTranslation(surah: aotd.ref.surah, ayah: aotd.ref.ayah),
                        const SizedBox(height: Space.md),
                        Text('${db.surah(aotd.ref.surah).nameEn} ${aotd.ref}',
                            textAlign: TextAlign.center, style: context.text.labelSmall?.copyWith(color: c.gold)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ---- Practice ----
          const SliverToBoxAdapter(child: SectionTitle('Practice')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: _Row(
                icon: Icons.fact_check_outlined,
                title: 'Memorization test',
                subtitle: 'Next ayah, missing word, word order and more',
                trailing: Icon(Icons.chevron_right_rounded, color: c.inkMuted),
                onTap: () => context.push('/memorize'),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ]),
      ),
    );
  }
}

/// "Asr · 3:27 PM · in 2h 10m", tap for all prayer times.
class _NextPrayerStrip extends ConsumerWidget {
  const _NextPrayerStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final settings = ref.watch(prayerSettingsProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final next = settings.hasLocation ? ref.read(prayerServiceProvider).next(now) : null;
    return Material(
      color: c.surfaceAlt,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: () => context.push('/prayer'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
          child: Row(children: [
            Icon(Icons.mosque_outlined, size: 20, color: c.primary),
            const SizedBox(width: Space.md),
            if (next == null)
              Expanded(child: Text('Prayer times', style: context.text.titleMedium))
            else ...[
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: next.$1.en, style: context.text.titleMedium),
                    TextSpan(text: '  ${next.$1.ar}', style: context.text.bodyMedium?.copyWith(color: c.inkMuted)),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(formatTime(context, next.$2), style: context.text.titleMedium?.copyWith(color: c.primary)),
                Text('in ${formatCountdown(next.$2.difference(now))}', style: context.text.bodySmall),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

/// The adhkar for now: morning until Asr, evening until Isha, then before sleep.
class _AdhkarNow extends ConsumerWidget {
  const _AdhkarNow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final settings = ref.watch(prayerSettingsProvider);
    final now = DateTime.now();
    final day = ref.read(prayerServiceProvider).day(now, settings);
    final asr = day?.times[Salah.asr] ?? DateTime(now.year, now.month, now.day, 15);
    final isha = day?.times[Salah.isha] ?? DateTime(now.year, now.month, now.day, 20);
    final (id, title, arabic, icon) = now.hour >= 3 && now.isBefore(asr)
        ? ('morning', 'Morning adhkar', 'أذكار الصباح', Icons.wb_twilight_rounded)
        : now.isBefore(isha.add(const Duration(hours: 1))) && now.hour >= 3
            ? ('evening', 'Evening adhkar', 'أذكار المساء', Icons.nights_stay_outlined)
            : ('sleep', 'Before sleep', 'أذكار النوم', Icons.bedtime_outlined);
    final done = adhkarDoneToday(ref, id);
    final fg = c.onBrand;
    return Material(
      color: c.brand,
      borderRadius: BorderRadius.circular(Radii.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/adhkar/$id'),
        child: Stack(children: [
          Positioned.fill(child: GirihPattern(color: fg, cell: 44, opacity: 0.07)),
          Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, color: c.gold, size: 26),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: context.text.titleLarge?.copyWith(color: fg)),
                    Text(done ? 'Completed today · تقبّل الله' : arabic,
                        style: context.text.bodyMedium?.copyWith(color: fg.withValues(alpha: 0.8))),
                  ]),
                ),
                if (done) Icon(Icons.check_circle_rounded, color: c.gold),
              ]),
              const SizedBox(height: Space.lg),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: c.gold,
                      foregroundColor: c.brand,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: () => context.push('/adhkar/$id?listen=1'),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Listen'),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: fg,
                      side: BorderSide(color: fg.withValues(alpha: 0.4)),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: () => context.push('/adhkar/$id'),
                    icon: const Icon(Icons.menu_book_outlined, size: 20),
                    label: const Text('Read'),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// A calm list row in a bordered card.
class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.subtitle, required this.trailing, required this.onTap});
  final IconData icon;
  final String title, subtitle;
  final Widget trailing;
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
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(Radii.md)),
              child: Icon(icon, size: 20, color: c.primary),
            ),
            const SizedBox(width: Space.lg),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
              ]),
            ),
            const SizedBox(width: Space.sm),
            trailing,
          ]),
        ),
      ),
    );
  }
}

final _translationProvider = FutureProvider.autoDispose.family<String?, (int, int, String)>((ref, k) {
  final (surah, ayah, slug) = k;
  if (slug.isEmpty) return Future.value(null);
  return ref.watch(quranDbProvider).translation(AyahRef(surah, ayah), slug);
});

class _AyahTranslation extends ConsumerWidget {
  const _AyahTranslation({required this.surah, required this.ayah});
  final int surah, ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slug = ref.watch(settingsProvider).translation;
    final text = ref.watch(_translationProvider((surah, ayah, slug))).value;
    if (text == null) return const SizedBox();
    return Text(text, textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: context.colors.inkMuted));
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.overline,
    required this.title,
    required this.subtitle,
    required this.arabic,
    required this.progress,
    required this.onTap,
  });

  final String overline, title, subtitle, arabic;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xl), side: BorderSide(color: c.divider)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(overline, style: context.text.labelSmall?.copyWith(color: c.primary)),
                  const SizedBox(height: Space.xs),
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.headlineSmall),
                  Text(subtitle, style: context.text.bodyMedium?.copyWith(color: c.inkMuted)),
                ]),
              ),
              const SizedBox(width: Space.md),
              Text(arabic, style: TextStyle(fontFamily: kQuranFont, fontSize: 30, color: c.ink, height: 1.4)),
            ]),
            const SizedBox(height: Space.lg),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    color: c.primary,
                    backgroundColor: c.divider,
                  ),
                ),
              ),
              const SizedBox(width: Space.lg),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                onPressed: onTap,
                child: const Text('Open'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
