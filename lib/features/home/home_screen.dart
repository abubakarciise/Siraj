import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/payload.dart';
import '../../app/shell.dart';
import '../../core/providers.dart';
import '../../core/quran/models.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import '../daily/prayer_widgets.dart';
import '../player/play_actions.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
    final remindersOn = ref.watch(dailyRemindersProvider.select((s) => s.enabled));
    final isFriday = DateTime.now().weekday == DateTime.friday;
    final quick = isFriday ? [18, 36, 67, 55, 56] : [36, 18, 67, 55, 56];

    final lastSurah = last == null ? null : db.surah(last.ref.surah);
    final progress = last == null || lastSurah == null
        ? 0.0
        : ((last.page - lastSurah.pageStart + 1) / (lastSurah.pageEnd - lastSurah.pageStart + 1)).clamp(0.0, 1.0);

    final listenRec = listening == null ? null : catalog?.recitation(listening.recitationKey);
    final listenReciter = listenRec == null ? null : catalog?.reciter(listenRec.reciterId);

    return Scaffold(
      // Keep scrolled content out from under the status bar.
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.xs, 0),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${hijri.day} ${hijri.monthName} ${hijri.year} AH',
                        style: context.text.labelSmall?.copyWith(color: c.gold)),
                    const SizedBox(height: Space.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(_greeting(), maxLines: 1, style: context.text.displaySmall),
                    ),
                    const SizedBox(height: 2),
                    Text('السلام عليكم ورحمة الله',
                        style: TextStyle(fontFamily: kNaskhFont, fontSize: 16, color: c.inkMuted, height: 1.5)),
                  ]),
                ),
                IconButton(
                    tooltip: 'Search', icon: const Icon(Icons.search_rounded), onPressed: () => context.push('/search')),
                IconButton(
                  tooltip: 'Bookmarks & downloads',
                  icon: const Icon(Icons.bookmarks_outlined),
                  onPressed: () => context.push('/library'),
                ),
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => context.push('/settings'),
                ),
              ]),
            ),
          ),

          const SliverPadding(
            padding: EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.gutter, 0),
            sliver: SliverToBoxAdapter(child: PrayerCard()),
          ),

          // ---- Continue reading (hero card) ----
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

          // ---- Continue listening + hadith ----
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, 0),
              child: Row(children: [
                Expanded(
                  child: _SmallCard(
                    icon: Icons.headphones_rounded,
                    overline: listenReciter == null ? 'LISTEN' : 'CONTINUE LISTENING',
                    title: listening == null ? 'Choose a reciter' : db.surah(listening.surah).nameEn,
                    subtitle: listenReciter?.name ?? '240+ reciters',
                    onTap: () {
                      if (listenRec != null && listenReciter != null && listening != null) {
                        playRecitation(context, ref, listenReciter, listenRec, listening.surah, resume: true);
                      } else {
                        context.go('/listen');
                      }
                    },
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: _SmallCard(
                    icon: Icons.auto_stories_rounded,
                    overline: 'HADITH & SUNNAH',
                    title: 'Collections',
                    subtitle: 'Bukhari, Muslim, 40 Nawawi…',
                    onTap: () => context.go('/hadith'),
                  ),
                ),
              ]),
            ),
          ),

          // ---- For you today: follows the day, the Hijri date and the hour ----
          const SliverToBoxAdapter(child: SectionTitle('For you today')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: Column(children: [
                const _ForYouCard(),
                if (!remindersOn) ...[
                  const SizedBox(height: Space.md),
                  _RemindersPrompt(onTap: () => context.push('/reminders')),
                ],
              ]),
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
                  borderRadius: BorderRadius.circular(Radii.lg),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Radii.lg),
                    onTap: () => context.openReader(aotd.page, ayah: aotd.ref.toString()),
                    child: Container(
                      padding: const EdgeInsets.all(Space.xl),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Radii.lg),
                        border: Border.all(color: c.divider),
                      ),
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
                            style: context.text.labelSmall?.copyWith(color: c.gold)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ---- Quick access ----
          SliverToBoxAdapter(child: SectionTitle(isFriday ? "Jumu'ah · Quick access" : 'Quick access')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 24 + context.ts(68),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                itemCount: quick.length,
                separatorBuilder: (_, _) => const SizedBox(width: Space.md),
                itemBuilder: (_, i) {
                  final s = db.surah(quick[i]);
                  return Material(
                    color: i == 0 && isFriday ? c.primarySoft : c.surfaceAlt,
                    borderRadius: BorderRadius.circular(Radii.lg),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(Radii.lg),
                      onTap: () => context.openReader(s.pageStart, surah: s.id),
                      child: Container(
                        width: 128,
                        padding: const EdgeInsets.all(Space.md),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.nameAr,
                              style: TextStyle(fontFamily: kQuranFont, fontSize: 20, color: c.ink, height: 1.3)),
                          const Spacer(),
                          Text(s.nameEn, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                          Text('${s.ayahCount} ayahs', maxLines: 1, style: context.text.bodySmall),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ]),
      ),
    );
  }
}

/// A reminder chosen for this moment, with the same logic as notifications.
class _ForYouCard extends ConsumerWidget {
  const _ForYouCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final r = ref.watch(reminderNowProvider).value;
    if (r == null) return const SizedBox(height: 120);
    final arabicFirst = RegExp(r'^[؀-ۿ]').hasMatch(r.body);
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: () => openPayload(GoRouter.of(context), ref.read(quranDbProvider), r.payload),
        child: Container(
          padding: const EdgeInsets.all(Space.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: c.divider),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: c.gold),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text((r.label ?? 'Reminder').toUpperCase(),
                    style: context.text.labelSmall?.copyWith(color: c.gold)),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Another one',
                icon: Icon(Icons.refresh_rounded, size: 20, color: c.inkMuted),
                onPressed: () => ref.invalidate(reminderNowProvider),
              ),
            ]),
            Text(r.title.replaceFirst(RegExp(r'^(Sunnah|Reflect|Hadith) · '), ''), style: context.text.titleMedium),
            const SizedBox(height: Space.sm),
            Text(
              r.body,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              textDirection: arabicFirst ? TextDirection.rtl : null,
              style: arabicFirst
                  ? TextStyle(fontFamily: kNaskhFont, fontSize: 18, height: 1.8, color: c.ink)
                  : context.text.bodyMedium?.copyWith(color: c.inkMuted, height: 1.55),
            ),
          ]),
        ),
      ),
    );
  }
}

class _RemindersPrompt extends StatelessWidget {
  const _RemindersPrompt({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.primarySoft,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(children: [
            Icon(Icons.notifications_active_outlined, color: c.primary),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Get reminders through the day', style: context.text.titleMedium),
                Text('Every 1–8 hours, only in the hours you choose', style: context.text.bodySmall),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: c.primary),
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
    final fg = c.onBrand;
    return Material(
      color: c.brand,
      borderRadius: BorderRadius.circular(Radii.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(children: [
          Positioned.fill(child: GirihPattern(color: fg, cell: 52, opacity: 0.09)),
          Positioned(
            right: -10,
            top: 8,
            child: Text(arabic,
                style: TextStyle(fontFamily: kQuranFont, fontSize: 64, color: fg.withValues(alpha: 0.14), height: 1.2)),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.xxl),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(overline, style: context.text.labelSmall?.copyWith(color: fg.withValues(alpha: 0.8))),
              const SizedBox(height: Space.sm),
              Text(title, style: context.text.headlineSmall?.copyWith(color: fg)),
              Text(subtitle, style: context.text.bodyMedium?.copyWith(color: fg.withValues(alpha: 0.85))),
              const SizedBox(height: Space.xl),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      color: c.gold,
                      backgroundColor: fg.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                const SizedBox(width: Space.lg),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: c.gold, borderRadius: BorderRadius.circular(99)),
                  child: Row(children: [
                    Text('Open', style: context.text.labelLarge?.copyWith(color: c.brand)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: c.brand),
                  ]),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SmallCard extends StatelessWidget {
  const _SmallCard({
    required this.icon,
    required this.overline,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String overline, title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: onTap,
        child: Container(
          // Grows with large system fonts instead of overflowing.
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(Radii.lg), border: Border.all(color: c.divider)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(Radii.sm)),
              child: Icon(icon, size: 18, color: c.primary),
            ),
            const SizedBox(height: Space.lg),
            Text(overline, style: context.text.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(title, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(subtitle, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}
