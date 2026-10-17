import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/prayer/prayer.dart';
import '../../core/providers.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import 'adhkar_screen.dart';
import 'prayer_widgets.dart';

/// "Daily" tab: prayer times, adhkar, tasbih, qibla and reminders.
class DailyScreen extends ConsumerWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = ref.watch(prayerSettingsProvider);
    final now = DateTime.now();
    final service = ref.read(prayerServiceProvider);
    // Morning adhkar until Asr (or 3 pm without location), evening afterwards.
    final asr = service.day(now, s)?.times[Salah.asr] ?? DateTime(now.year, now.month, now.day, 15);
    final isMorning = now.isBefore(asr) && now.hour >= 3;
    final suggested = isMorning ? 'morning' : 'evening';
    final suggestedDone = adhkarDoneToday(ref, suggested);

    return Scaffold(
      backgroundColor: Colors.transparent, // the tab's art shows through (TabBackdrop)
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 104,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(start: Space.gutter, bottom: 14),
            title: TabTitle('Daily'),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: Space.gutter),
          sliver: SliverToBoxAdapter(child: PrayerCard()),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, 0),
            child: Material(
              color: c.brand,
              borderRadius: BorderRadius.circular(Radii.lg),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/adhkar/$suggested'),
                child: Stack(children: [
                  Positioned.fill(child: GirihPattern(color: c.onBrand, cell: 44, opacity: 0.08)),
                  Padding(
                    padding: const EdgeInsets.all(Space.xl),
                    child: Row(children: [
                      Icon(isMorning ? Icons.wb_twilight_rounded : Icons.nights_stay_outlined,
                          color: c.onBrand, size: 32),
                      const SizedBox(width: Space.lg),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(isMorning ? 'Morning adhkar' : 'Evening adhkar',
                              style: context.text.titleLarge?.copyWith(color: c.onBrand)),
                          Text(
                            suggestedDone
                                ? 'Completed today · تقبّل الله'
                                : (isMorning ? 'أذكار الصباح' : 'أذكار المساء'),
                            style: context.text.bodyMedium?.copyWith(color: c.onBrand.withValues(alpha: 0.85)),
                          ),
                        ]),
                      ),
                      Icon(suggestedDone ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                          color: c.onBrand),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SectionTitle('Essentials')),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              // 2 columns on phones, 3–4 on tablets; height follows the font size.
              maxCrossAxisExtent: 240,
              mainAxisSpacing: Space.md,
              crossAxisSpacing: Space.md,
              mainAxisExtent: 82 + context.ts(46),
            ),
            delegate: SliverChildListDelegate([
              _Tile(Icons.auto_stories_outlined, 'Adhkar', 'الأذكار', () => context.push('/adhkar')),
              _Tile(Icons.blur_circular_rounded, 'Tasbih', 'التسبيح', () => context.push('/tasbih')),
              _Tile(Icons.access_time_rounded, 'Prayer times', 'مواقيت الصلاة', () => context.push('/prayer')),
              _Tile(Icons.explore_outlined, 'Qibla', 'القبلة', () => context.push('/qibla')),
              _Tile(Icons.bedtime_outlined, 'Before sleep', 'أذكار النوم', () => context.push('/adhkar/sleep')),
              _Tile(Icons.mosque_outlined, 'After prayer', 'بعد الصلاة', () => context.push('/adhkar/after_salah')),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: SectionTitle('Reminders')),
        const SliverToBoxAdapter(child: _Reminders()),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.title, this.arabic, this.onTap);
  final IconData icon;
  final String title, arabic;
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
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(Radii.lg), border: Border.all(color: c.divider)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(Radii.sm)),
              child: Icon(icon, color: c.primary, size: 22),
            ),
            const Spacer(),
            Text(title, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(arabic, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

class _Reminders extends StatelessWidget {
  const _Reminders();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Everything about reminders lives on one screen; this is the way in.
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      leading: Icon(Icons.notifications_active_outlined, color: c.primary),
      title: const Text('Reminders'),
      subtitle: const Text('Morning and evening adhkar, prayer times, daily reminders'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push('/reminders'),
    );
  }
}
