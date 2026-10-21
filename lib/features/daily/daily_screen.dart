import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/adhkar/adhkar_time.dart';
import '../../core/providers.dart';
import '../../design/hero.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import '../../l10n/l10n.dart';
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
    ref.watch(clockProvider.select((v) => v.value?.minute));
    // The same adhkar as on Home, following the time of day and the prayers.
    final doneAt = ref.read(prefsProvider).getInt('adhkar_done_at_after_salah');
    final moment = adhkarFor(
      now,
      service.day(now, s),
      done: (id) => adhkarDoneToday(ref, id),
      afterSalahDoneAt: doneAt == null ? null : DateTime.fromMillisecondsSinceEpoch(doneAt),
    );
    final suggested = moment.categoryId;
    final (title, arabic) = adhkarNames[suggested]!;
    final suggestedDone = suggested != 'after_salah' && adhkarDoneToday(ref, suggested);

    return Scaffold(
      backgroundColor: Colors.transparent, // the tab's art shows through (TabBackdrop)
      body: CustomScrollView(
        slivers: [
          HeroSliverAppBar(title: context.l10n.daily, subtitle: 'اليوم', art: HeroArt.daily),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.gutter, 0),
            sliver: SliverToBoxAdapter(child: PrayerCard()),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, 0),
              child: BrandPanel(
                onTap: () => context.push(suggested == 'tasbih' ? '/tasbih' : '/adhkar/$suggested'),
                padding: const EdgeInsets.all(Space.lg),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: c.onBrand.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: Icon(adhkarIcons[suggested] ?? Icons.auto_awesome_rounded, color: c.goldOnBrand, size: 26),
                    ),
                    const SizedBox(width: Space.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(moment.reason.toUpperCase(), style: context.text.labelSmall?.copyWith(color: c.goldOnBrand)),
                          Text(title, style: context.text.titleLarge?.copyWith(color: c.onBrand)),
                          Text(
                            suggestedDone ? context.l10n.completedTodayAccepted : arabic,
                            style: context.text.bodyMedium?.copyWith(color: c.onBrand.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      suggestedDone ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                      color: suggestedDone ? c.goldOnBrand : c.onBrand,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SectionTitle(context.l10n.essentials)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                // 2 columns on phones, 3–4 on tablets; height follows the font size.
                maxCrossAxisExtent: 240,
                mainAxisSpacing: Space.md,
                crossAxisSpacing: Space.md,
                mainAxisExtent: 86 + context.ts(46),
              ),
              delegate: SliverChildListDelegate([
                _Tile(Icons.auto_stories_rounded, context.l10n.adhkar, 'الأذكار', const Color(0xFF0F5C4A), () => context.push('/adhkar')),
                _Tile(Icons.blur_circular_rounded, context.l10n.tasbih, 'التسبيح', const Color(0xFF8A6A2B), () => context.push('/tasbih')),
                _Tile(Icons.access_time_filled_rounded, context.l10n.prayerTimes, 'مواقيت الصلاة', const Color(0xFF8A6A2B), () => context.push('/prayer')),
                _Tile(Icons.explore_rounded, context.l10n.qibla, 'القبلة', const Color(0xFF0F5C4A), () => context.push('/qibla')),
                _Tile(Icons.bedtime_rounded, context.l10n.beforeSleep, 'أذكار النوم', const Color(0xFF0F5C4A), () => context.push('/adhkar/sleep')),
                _Tile(Icons.mosque_rounded, context.l10n.afterPrayer, 'بعد الصلاة', const Color(0xFF8A6A2B), () => context.push('/adhkar/after_salah')),
              ]),
            ),
          ),
          SliverToBoxAdapter(child: SectionTitle(context.l10n.reminders)),
          const SliverToBoxAdapter(child: _Reminders()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.title, this.arabic, this.color, this.onTap);
  final IconData icon;
  final String title, arabic;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      onTap: onTap,
      color: color == const Color(0xFF8A6A2B) ? c.goldTint : c.emeraldTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon, color: color, size: 44),
          const Spacer(),
          Text(title, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(arabic,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: kNaskhFont, fontSize: 14, height: 1.4, color: c.inkMuted)),
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      child: AppCard(
        onTap: () => context.push('/reminders'),
        color: c.goldTint,
        child: Row(children: [
          IconBadge(Icons.notifications_active_rounded, color: c.gold, size: 44),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.l10n.reminders, style: context.text.titleMedium),
              Text(context.l10n.remindersCardSubtitle, style: context.text.bodySmall),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: c.inkMuted),
        ]),
      ),
    );
  }
}
