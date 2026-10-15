import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/catalog/catalog.dart';
import '../../core/providers.dart';
import '../../core/quran/arabic.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';

enum _Filter { all, favorites, downloaded, highlight, warsh, mujawwad }

const _filterLabels = {
  _Filter.all: 'All',
  _Filter.favorites: 'Favorites',
  _Filter.downloaded: 'Downloaded',
  _Filter.highlight: 'Ayah sync',
  _Filter.warsh: 'Other riwayat',
  _Filter.mujawwad: 'Mujawwad',
};

class RecitersScreen extends ConsumerStatefulWidget {
  const RecitersScreen({super.key});

  @override
  ConsumerState<RecitersScreen> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends ConsumerState<RecitersScreen> {
  String _query = '';
  _Filter _filter = _Filter.all;

  List<Reciter> _apply(Catalog catalog, Set<int> favs, Map<String, Set<int>> downloaded) {
    final q = _query.trim().toLowerCase();
    final qAr = normalizeArabic(_query);
    return catalog.reciters.where((r) {
      if (q.isNotEmpty) {
        final latin = r.name.toLowerCase();
        final hit = latin.contains(q) ||
            latin.replaceAll(RegExp(r'[^a-z]'), '').contains(q.replaceAll(RegExp(r'[^a-z]'), '')) ||
            (qAr.isNotEmpty && normalizeArabic(r.nameAr).contains(qAr));
        if (!hit) return false;
      }
      return switch (_filter) {
        _Filter.all => true,
        _Filter.favorites => favs.contains(r.id),
        _Filter.downloaded => r.recitations.any((m) => (downloaded[m.key]?.isNotEmpty ?? false)),
        _Filter.highlight => r.hasTiming,
        _Filter.warsh => r.recitations.any((m) => !m.isHafs),
        _Filter.mujawwad => r.recitations.any((m) => m.isMujawwad),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final favs = ref.watch(favoritesProvider).value ?? const <int>{};
    final downloaded = ref.watch(downloadsProvider).value?.downloaded ?? const {};

    return Scaffold(
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load reciters\n$e', textAlign: TextAlign.center)),
        data: (cat) {
          final list = _apply(cat, favs, downloaded);
          final showFeatured = _query.isEmpty && _filter == _Filter.all;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 104,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(start: Space.gutter, bottom: 14),
                  title: TabTitle('Listen'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.md),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Search ${cat.reciters.length} reciters · ابحث عن قارئ',
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                    children: [
                      for (final f in _Filter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_filterLabels[f]!),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (showFeatured) ...[
                const SliverToBoxAdapter(child: SectionTitle('Featured')),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 92 + context.ts(58),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                      itemCount: cat.featured.length,
                      separatorBuilder: (_, _) => const SizedBox(width: Space.lg),
                      itemBuilder: (_, i) {
                        final r = cat.featured[i];
                        return GestureDetector(
                          onTap: () => context.go('/listen/reciter/${r.id}'),
                          child: SizedBox(
                            width: 92,
                            child: Column(children: [
                              ReciterAvatar(id: r.id, nameAr: r.nameAr, size: 84),
                              const SizedBox(height: 8),
                              Text(r.name,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.bodySmall?.copyWith(color: context.colors.ink)),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: SectionTitle(showFeatured ? 'All reciters' : '${list.length} reciters'),
              ),
              if (list.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(Space.xxxl),
                    child: Text(
                      _filter == _Filter.downloaded
                          ? 'Nothing downloaded yet. Open a reciter and tap download on any surah, or download the whole Quran.'
                          : _filter == _Filter.favorites
                              ? 'Tap the heart on a reciter to keep them here.'
                              : 'No reciters match your search.',
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium?.copyWith(color: context.colors.inkMuted),
                    ),
                  ),
                ),
              SliverList.builder(
                itemCount: list.length,
                itemBuilder: (_, i) => _ReciterTile(
                  reciter: list[i],
                  favorite: favs.contains(list[i].id),
                  downloadedSurahs: list[i].recitations.fold(0, (n, m) => n + (downloaded[m.key]?.length ?? 0)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _ReciterTile extends ConsumerWidget {
  const _ReciterTile({required this.reciter, required this.favorite, required this.downloadedSurahs});
  final Reciter reciter;
  final bool favorite;
  final int downloadedSurahs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return InkWell(
      onTap: () => context.go('/listen/reciter/${reciter.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: 10),
        child: Row(children: [
          ReciterAvatar(id: reciter.id, nameAr: reciter.nameAr, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(reciter.name, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(reciter.nameAr, style: context.text.bodySmall, maxLines: 1),
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 4, children: [
                for (final r in reciter.riwayat.take(3)) Pill(r),
                if (reciter.hasTiming) Pill('Ayah sync', color: c.primary, icon: Icons.graphic_eq_rounded),
                if (downloadedSurahs > 0)
                  Pill(downloadedSurahs >= 114 ? 'Offline' : '$downloadedSurahs offline',
                      color: c.gold, icon: Icons.download_done_rounded),
              ]),
            ]),
          ),
          IconButton(
            onPressed: () => ref.read(favoritesProvider.notifier).toggle(reciter.id),
            icon: AnimatedSwitcher(
              duration: Motion.quick,
              transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
              child: Icon(
                favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey(favorite),
                color: favorite ? c.danger : c.inkFaint,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
