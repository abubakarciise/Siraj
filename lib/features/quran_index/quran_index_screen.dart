import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell.dart';
import '../../core/providers.dart';
import '../../design/dialogs.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';

class QuranIndexScreen extends ConsumerStatefulWidget {
  const QuranIndexScreen({super.key});

  @override
  ConsumerState<QuranIndexScreen> createState() => _QuranIndexScreenState();
}

class _QuranIndexScreenState extends ConsumerState<QuranIndexScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final last = ref.watch(lastReadProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: Text('Quran', style: context.text.headlineSmall),
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
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () => context.push('/search')),
          IconButton(
            tooltip: 'Go to page',
            icon: const Icon(Icons.tag_rounded),
            onPressed: () => _goToPage(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.sm),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
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
      ),
      body: AnimatedSwitcher(
        duration: Motion.quick,
        child: _tab == 0
            ? _SurahList(key: const ValueKey('s'), currentSurah: last?.ref.surah)
            : _JuzGrid(key: const ValueKey('j'), currentPage: last?.page),
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

class _SurahList extends ConsumerWidget {
  const _SurahList({super.key, this.currentSurah});
  final int? currentSurah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final surahs = ref.watch(surahsProvider);
    return ListView.builder(
      itemCount: surahs.length,
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (_, i) {
        final s = surahs[i];
        final current = s.id == currentSurah;
        return InkWell(
          onTap: () => context.openReader(s.pageStart, surah: s.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: 10),
            child: Row(children: [
              StarMedallion(number: s.id, active: current),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.nameEn, style: context.text.titleMedium?.copyWith(color: current ? c.primary : null)),
                  Text('${s.isMakki ? 'Makki' : 'Madani'} · ${s.ayahCount} ayahs · ${s.meaning}',
                      style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(s.nameAr, style: TextStyle(fontFamily: kQuranFont, fontSize: 21, color: c.ink, height: 1.4)),
                Text('p. ${s.pageStart}', style: context.text.bodySmall),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

class _JuzGrid extends ConsumerWidget {
  const _JuzGrid({super.key, this.currentPage});
  final int? currentPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final db = ref.watch(quranDbProvider);
    final juz = ref.watch(juzListProvider);
    return juz.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (list) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: Space.md,
          crossAxisSpacing: Space.md,
          childAspectRatio: 1.45,
        ),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final j = list[i];
          final nextPage = i + 1 < list.length ? list[i + 1].page : 605;
          final current = currentPage != null && currentPage! >= j.page && currentPage! < nextPage;
          return Material(
            color: current ? c.primarySoft : c.surface,
            borderRadius: BorderRadius.circular(Radii.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.lg),
              onTap: () => context.openReader(j.page),
              child: Container(
                padding: const EdgeInsets.all(Space.lg),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Radii.lg),
                  border: Border.all(color: current ? c.primary.withValues(alpha: 0.4) : c.divider),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('Juz ${j.number}', style: context.text.titleMedium),
                    const Spacer(),
                    StarMedallion(number: j.number, size: 30, active: current),
                  ]),
                  const Spacer(),
                  Text('${db.surah(j.start.surah).nameEn} ${j.start}', style: context.text.bodySmall),
                  Text('Page ${j.page}', style: context.text.bodySmall),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
