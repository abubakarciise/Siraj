import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Home is the same every day: a header with the date, the next prayer and
/// where you left off (reading and listening), then the adhkar for this time
/// of day, practice, and one ayah. Nothing on it is random.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final db = ref.watch(quranDbProvider);
    final aotd = ref.watch(ayahOfDayProvider).value;
    final isFriday = DateTime.now().weekday == DateTime.friday;

    return Scaffold(
      body: AnnotatedRegion(
        value: SystemUiOverlayStyle.light,
        child: CustomScrollView(slivers: [
          const SliverToBoxAdapter(child: _Header()),

          // ---- Today: the adhkar for now ----
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
                  onTap: () => context.openReader(db.surah(18).pageStart, surah: 18),
                ),
              ),
            ),

          // ---- Practice ----
          const SliverToBoxAdapter(child: SectionTitle('Practice')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            sliver: SliverToBoxAdapter(
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(
                    child: _Tile(
                      icon: Icons.fact_check_outlined,
                      title: 'Memorize',
                      subtitle: 'Test yourself',
                      onTap: () => context.push('/memorize'),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: _Tile(
                      icon: Icons.blur_circular_rounded,
                      title: 'Tasbih',
                      subtitle: 'Count dhikr',
                      onTap: () => context.push('/tasbih'),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: _Tile(
                      icon: Icons.explore_outlined,
                      title: 'Qibla',
                      subtitle: 'Compass',
                      onTap: () => context.push('/qibla'),
                    ),
                  ),
                ]),
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
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ]),
      ),
    );
  }
}

/// The green header: date, greeting, next prayer, and two "continue" tiles.
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
    final db = ref.watch(quranDbProvider);
    final hijri = ref.watch(hijriTodayProvider);
    final last = ref.watch(lastReadProvider).value;
    final listening = ref.watch(lastListeningProvider).value;
    final catalog = ref.watch(catalogProvider).value;
    final now = DateTime.now();

    final lastSurah = last == null ? null : db.surah(last.ref.surah);
    final progress = last == null || lastSurah == null
        ? 0.0
        : ((last.page - lastSurah.pageStart + 1) / (lastSurah.pageEnd - lastSurah.pageStart + 1)).clamp(0.0, 1.0);
    final listenRec = listening == null ? null : catalog?.recitation(listening.recitationKey);
    final listenReciter = listenRec == null ? null : catalog?.reciter(listenRec.reciterId);

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
                const SizedBox(height: Space.xs),
                const _NextPrayer(),
                const SizedBox(height: Space.lg),
                Padding(
                  padding: const EdgeInsets.only(right: Space.md),
                  child: IntrinsicHeight(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Expanded(
                        child: _ResumeTile(
                          icon: Icons.menu_book_rounded,
                          label: last == null ? 'Start reading' : 'Continue reading',
                          title: lastSurah?.nameEn ?? 'Al-Fatihah',
                          detail: last == null ? 'The Opening' : 'Page ${last.page}',
                          progress: progress,
                          onTap: () => context.openReader(last?.page ?? 1),
                        ),
                      ),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: listening == null || listenRec == null || listenReciter == null
                            ? _ResumeTile(
                                icon: Icons.headphones_rounded,
                                label: 'Listen',
                                title: 'Choose a reciter',
                                detail: '240+ reciters',
                                onTap: () => context.go('/listen'),
                              )
                            : _ResumeTile(
                                icon: Icons.play_arrow_rounded,
                                label: 'Continue listening',
                                title: db.surah(listening.surah).nameEn,
                                detail: listenReciter.name,
                                onTap: () =>
                                    playRecitation(context, ref, listenReciter, listenRec, listening.surah, resume: true),
                              ),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

/// "Fajr · 5:01 AM · in 5h 18m", tap for all prayer times.
class _NextPrayer extends ConsumerWidget {
  const _NextPrayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final fg = c.onBrand;
    final settings = ref.watch(prayerSettingsProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final next = settings.hasLocation ? ref.read(prayerServiceProvider).next(now) : null;
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.md),
      onTap: () => context.push('/prayer'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(Icons.mosque_outlined, size: 18, color: c.gold),
          const SizedBox(width: Space.sm),
          Flexible(
            child: Text(
              next == null
                  ? 'Prayer times'
                  : '${next.$1.en} ${formatTime(context, next.$2)} · in ${formatCountdown(next.$2.difference(now))}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium?.copyWith(color: fg.withValues(alpha: 0.9)),
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: fg.withValues(alpha: 0.6)),
        ]),
      ),
    );
  }
}

/// A translucent tile inside the header.
class _ResumeTile extends StatelessWidget {
  const _ResumeTile({
    required this.icon,
    required this.label,
    required this.title,
    required this.detail,
    required this.onTap,
    this.progress,
  });

  final IconData icon;
  final String label, title, detail;
  final double? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = c.onBrand;
    return Material(
      color: fg.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: fg.withValues(alpha: 0.14)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: c.gold, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: c.brand),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelSmall?.copyWith(color: fg.withValues(alpha: 0.8))),
              ),
            ]),
            const SizedBox(height: Space.sm),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium?.copyWith(color: fg)),
            Text(detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(color: fg.withValues(alpha: 0.75))),
            if (progress != null) ...[
              const SizedBox(height: Space.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  color: c.gold,
                  backgroundColor: fg.withValues(alpha: 0.18),
                ),
              ),
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
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xl), side: BorderSide(color: c.divider)),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.xl),
        onTap: () => context.push('/adhkar/$id'),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
                child: Icon(icon, color: c.primary, size: 22),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: context.text.titleLarge),
                  Text(done ? 'Completed today · تقبّل الله' : arabic,
                      style: context.text.bodyMedium?.copyWith(color: done ? c.primary : c.inkMuted)),
                ]),
              ),
              if (done) Icon(Icons.check_circle_rounded, color: c.primary),
            ]),
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
          ]),
        ),
      ),
    );
  }
}

/// A small square tool tile.
class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title, subtitle;
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
          padding: const EdgeInsets.all(Space.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(Radii.md)),
              child: Icon(icon, size: 20, color: c.primary),
            ),
            const SizedBox(height: Space.md),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
          ]),
        ),
      ),
    );
  }
}

/// A calm list row in a bordered card.
class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title, subtitle;
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
            Icon(Icons.chevron_right_rounded, color: c.inkMuted),
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
