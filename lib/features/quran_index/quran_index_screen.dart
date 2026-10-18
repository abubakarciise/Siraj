import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell.dart';
import '../../core/providers.dart';
import '../../design/dialogs.dart';
import '../../design/theme.dart';
import '../../design/hero.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';

/// The Quran tab: where you left off, quick picks, then every surah and juz.
class QuranIndexScreen extends ConsumerStatefulWidget {
  const QuranIndexScreen({super.key});

  @override
  ConsumerState<QuranIndexScreen> createState() => _QuranIndexScreenState();
}

class _QuranIndexScreenState extends ConsumerState<QuranIndexScreen> {
  int _tab = 0;

  /// Surahs most often opened on their own.

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final last = ref.watch(lastReadProvider).value;
    return Scaffold(
      backgroundColor: Colors.transparent, // the tab's art shows through (TabBackdrop)
      body: CustomScrollView(
        slivers: [
          HeroSliverAppBar(
            title: 'Quran',
            subtitle: 'القرآن الكريم',
            art: HeroArt.quran,
            actions: [
              IconButton(
                tooltip: 'Memorization test',
                icon: const Icon(Icons.fact_check_outlined),
                onPressed: () => context.push('/memorize'),
              ),
              IconButton(
                tooltip: 'Bookmarks & downloads',
                icon: const Icon(Icons.bookmarks_outlined),
                onPressed: () => context.push('/library'),
              ),
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search_rounded),
                onPressed: () => context.push('/search'),
              ),
              IconButton(
                tooltip: 'Go to page',
                icon: const Icon(Icons.tag_rounded),
                onPressed: () => _goToPage(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.gutter, 0),
              child: _ContinueCard(),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SwitchHeader(
              color: c.bg,
              height: 64,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.sm),
                // Full width: two wide, easy targets.
                child: SegmentedButton<int>(
                  expandedInsets: EdgeInsets.zero,
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Surah')),
                    ButtonSegment(value: 1, label: Text('Juz')),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ),
            ),
          ),
          if (_tab == 0) _SurahList(currentSurah: last?.ref.surah) else _JuzGrid(currentPage: last?.page),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Future<void> _goToPage(BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showAppDialog(
      context,
      icon: Icons.menu_book_rounded,
      title: 'Go to page',
      message: 'Enter a page number from 1 to 604',
      confirmLabel: 'Open',
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: context.text.headlineSmall,
        decoration: const InputDecoration(hintText: '1 – 604'),
        onSubmitted: (_) => Navigator.of(context, rootNavigator: true).pop(true),
      ),
    );
    final page = int.tryParse(controller.text.trim());
    if (ok && page != null && page >= 1 && page <= 604 && context.mounted) context.openReader(page);
  }
}

class _SwitchHeader extends SliverPersistentHeaderDelegate {
  _SwitchHeader({required this.child, required this.color, required this.height});
  final Widget child;
  final Color color;
  final double height;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => ColoredBox(
    color: color,
    child: Center(child: child),
  );

  @override
  bool shouldRebuild(_SwitchHeader old) => old.child != child || old.color != color;
}

/// Where the reader left off, with progress through the surah.
class _ContinueCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final db = ref.watch(quranDbProvider);
    final last = ref.watch(lastReadProvider).value;
    final surah = db.surah(last?.ref.surah ?? 1);
    final progress = last == null
        ? 0.0
        : ((last.page - surah.pageStart + 1) / (surah.pageEnd - surah.pageStart + 1)).clamp(0.0, 1.0);
    return Material(
      color: c.brand,
      borderRadius: BorderRadius.circular(Radii.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.openReader(last?.page ?? 1),
        child: Stack(
          children: [
            Positioned.fill(child: GirihPattern(color: c.onBrand, cell: 46, opacity: 0.07)),
            Padding(
              padding: const EdgeInsets.all(Space.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              last == null ? 'START READING' : 'CONTINUE READING',
                              style: context.text.labelSmall?.copyWith(color: c.gold),
                            ),
                            const SizedBox(height: Space.xs),
                            Text(
                              surah.nameEn,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.headlineSmall?.copyWith(color: c.onBrand),
                            ),
                            Text(
                              last == null ? 'The Opening' : 'Page ${last.page} · Ayah ${last.ref.ayah}',
                              style: context.text.bodyMedium?.copyWith(color: c.onBrand.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        surah.nameAr,
                        style: TextStyle(fontFamily: kQuranFont, fontSize: 30, color: c.onBrand, height: 1.4),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.lg),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            color: c.gold,
                            backgroundColor: c.onBrand.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      const SizedBox(width: Space.lg),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: c.gold,
                          foregroundColor: c.brand,
                          minimumSize: const Size(0, 40),
                        ),
                        onPressed: () => context.openReader(last?.page ?? 1),
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: Text(last == null ? 'Open' : 'Continue'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahList extends ConsumerWidget {
  const _SurahList({this.currentSurah});
  final int? currentSurah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final surahs = ref.watch(surahsProvider);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      sliver: SliverList.builder(
        itemCount: surahs.length,
        itemBuilder: (_, i) {
          final s = surahs[i];
          final current = s.id == currentSurah;
          final first = i == 0, last = i == surahs.length - 1;
          // One calm card: the rows join, with fine lines between them.
          final radius = BorderRadius.vertical(
            top: first ? const Radius.circular(Radii.lg) : Radius.zero,
            bottom: last ? const Radius.circular(Radii.lg) : Radius.zero,
          );
          return Container(
            decoration: BoxDecoration(
              color: current ? c.primarySoft : c.surface,
              borderRadius: radius,
              border: c.isDark ? Border.all(color: c.divider, width: 0.5) : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: radius,
                onTap: () => context.openReader(s.pageStart, surah: s.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: 12),
                  decoration: BoxDecoration(
                    border: last ? null : Border(bottom: BorderSide(color: c.divider.withValues(alpha: 0.7))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: current ? c.primary : c.primarySoft,
                        ),
                        child: Text(
                          '${s.id}',
                          style: context.text.labelLarge?.copyWith(color: current ? c.onPrimary : c.primary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.nameEn, style: context.text.titleMedium),
                            Text(
                              '${s.isMakki ? 'Makki' : 'Madani'} · ${s.ayahCount} ayahs · ${s.meaning}',
                              style: context.text.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            s.nameAr,
                            style: TextStyle(fontFamily: kQuranFont, fontSize: 21, color: c.ink, height: 1.4),
                          ),
                          Text('p. ${s.pageStart}', style: context.text.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _JuzGrid extends ConsumerWidget {
  const _JuzGrid({this.currentPage});
  final int? currentPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final db = ref.watch(quranDbProvider);
    final list = ref.watch(juzListProvider).value;
    if (list == null) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(Space.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xs, Space.gutter, 0),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          mainAxisSpacing: Space.md,
          crossAxisSpacing: Space.md,
          mainAxisExtent: 60 + context.ts(56),
        ),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final j = list[i];
          final nextPage = i + 1 < list.length ? list[i + 1].page : 605;
          final current = currentPage != null && currentPage! >= j.page && currentPage! < nextPage;
          return Material(
            elevation: c.isDark ? 0 : 1.5,
            shadowColor: const Color(0x55103A2F),
            color: current ? c.primarySoft : c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.lg),
              side: current ? BorderSide(color: c.primary.withValues(alpha: 0.4)) : cardSide(c),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.lg),
              onTap: () => context.openReader(j.page),
              child: Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Juz ${j.number}', style: context.text.titleMedium),
                        const Spacer(),
                        StarMedallion(number: j.number, size: 30, active: current),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${db.surah(j.start.surah).nameEn} ${j.start}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall,
                    ),
                    Text('Page ${j.page}', style: context.text.bodySmall),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
