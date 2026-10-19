import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/catalog/catalog.dart';
import '../../core/downloads/download_manager.dart';
import '../../core/providers.dart';
import '../../core/quran/models.dart';
import '../../design/dialogs.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import '../player/play_actions.dart';
import 'download_sheet.dart';

class ReciterScreen extends ConsumerStatefulWidget {
  const ReciterScreen({super.key, required this.reciterId});
  final int reciterId;

  @override
  ConsumerState<ReciterScreen> createState() => _ReciterScreenState();
}

class _ReciterScreenState extends ConsumerState<ReciterScreen> {
  int? _moshafIndex;
  final Set<int> _selected = {};
  bool get _selecting => _selected.isNotEmpty;

  /// Single surahs download immediately; larger batches are confirmed first
  /// with their exact size.
  Future<void> _download(Reciter reciter, Recitation r, List<int> surahs, {String? title}) async {
    var wifiOnly = ref.read(settingsProvider).wifiOnly;
    if (surahs.length > 1) {
      final choice = await confirmDownload(
        context,
        reciter: reciter,
        recitation: r,
        surahs: surahs,
        title: title ?? 'Download ${surahs.length} surahs',
      );
      if (choice == null || !mounted) return;
      wifiOnly = choice;
    }
    final n = await ref
        .read(downloadManagerProvider)
        .download(r, surahs, reciterName: reciter.name, wifiOnly: wifiOnly);
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(_selected.clear);
    showToast(
      context,
      n == 0 ? 'Already downloaded' : 'Downloading $n ${n == 1 ? 'surah' : 'surahs'} · ${reciter.name}',
    );
  }

  Future<void> _confirmDeleteAll(Recitation r, String name) async {
    final ok = await showAppDialog(
      context,
      icon: Icons.delete_outline_rounded,
      title: 'Delete downloads?',
      message:
          'All downloaded surahs of $name (${r.shortName}) will be removed from this phone. You can download them again anytime.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok) await ref.read(downloadManagerProvider).deleteRecitation(r.key);
  }

  /// Opens on the most complete Hafs Murattal recitation when there are several.
  static int _preferredIndex(Reciter reciter) {
    int score(Recitation m) =>
        (m.isHafs ? 4 : 0) + (m.style == 'Murattal' ? 2 : 0) + (m.hasTiming ? 1 : 0) + m.surahs.length * 10;
    var best = 0;
    for (var i = 1; i < reciter.recitations.length; i++) {
      if (score(reciter.recitations[i]) > score(reciter.recitations[best])) best = i;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final catalog = ref.watch(catalogProvider).value;
    final reciter = catalog?.reciter(widget.reciterId);
    if (reciter == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    _moshafIndex ??= _preferredIndex(reciter);
    final r = reciter.recitations[_moshafIndex!.clamp(0, reciter.recitations.length - 1)];
    final dl = ref.watch(downloadsProvider).value ?? const DownloadsState();
    final favs = ref.watch(favoritesProvider).value ?? const <int>{};
    final isDefault = ref.watch(settingsProvider).defaultRecitation == r.key;
    final np = ref.watch(nowPlayingProvider).value;
    final surahs = ref.watch(surahsProvider);
    final downloadedCount = dl.downloadedCount(r.key);
    final activeCount = dl.activeOf(r.key).where((a) => a.status != DlStatus.failed).length;
    final failedCount = dl.activeOf(r.key).length - activeCount;
    final allDone = downloadedCount >= r.surahs.length;

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_selected.clear);
      },
      child: Scaffold(
        appBar: AppBar(
          title: _selecting ? Text('${_selected.length} selected') : null,
          leading: _selecting
              ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(_selected.clear))
              : null,
          actions: [
            if (_selecting) ...[
              TextButton(
                onPressed: () => setState(() => _selected.addAll(r.surahs.where((s) => !dl.isDownloaded(r.key, s)))),
                child: const Text('Select all'),
              ),
            ] else ...[
              IconButton(
                onPressed: () => ref.read(favoritesProvider.notifier).toggle(reciter.id),
                icon: Icon(
                  favs.contains(reciter.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: favs.contains(reciter.id) ? c.danger : null,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  switch (v) {
                    case 'select':
                      setState(
                        () => _selected.add(
                          r.surahs.firstWhere((s) => !dl.isDownloaded(r.key, s), orElse: () => r.surahs.first),
                        ),
                      );
                    case 'juzamma':
                      _download(reciter, r, [
                        for (var s = 78; s <= 114; s++)
                          if (r.hasSurah(s)) s,
                      ], title: "Download Juz 'Amma");
                    case 'cancel':
                      await ref.read(downloadManagerProvider).cancelAll(r.key);
                    case 'retry':
                      await ref.read(downloadManagerProvider).retry(r, reciterName: reciter.name);
                    case 'delete':
                      await _confirmDeleteAll(r, reciter.name);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'select', child: Text('Select surahs to download')),
                  const PopupMenuItem(value: 'juzamma', child: Text("Download Juz 'Amma (78–114)")),
                  if (activeCount > 0) const PopupMenuItem(value: 'cancel', child: Text('Cancel downloads')),
                  if (failedCount > 0) const PopupMenuItem(value: 'retry', child: Text('Retry failed downloads')),
                  if (downloadedCount > 0) const PopupMenuItem(value: 'delete', child: Text('Delete downloads')),
                ],
              ),
            ],
          ],
        ),
        bottomNavigationBar: AnimatedSize(
          duration: Motion.standard,
          curve: Motion.emphasized,
          child: !_selecting
              ? const SizedBox(width: double.infinity)
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.md),
                    child: FilledButton.icon(
                      onPressed: () => _download(reciter, r, _selected.toList()..sort()),
                      icon: const Icon(Icons.download_rounded),
                      label: Text('Download ${_selected.length} ${_selected.length == 1 ? 'surah' : 'surahs'}'),
                    ),
                  ),
                ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  ReciterAvatar(id: reciter.id, nameAr: reciter.nameAr, size: 112),
                  const SizedBox(height: Space.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                    child: Text(reciter.name, textAlign: TextAlign.center, style: context.text.headlineSmall),
                  ),
                  Text(reciter.nameAr, style: context.text.bodyMedium?.copyWith(color: c.inkMuted)),
                  const SizedBox(height: Space.lg),
                  if (reciter.recitations.length > 1)
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                        children: [
                          for (var i = 0; i < reciter.recitations.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(reciter.recitations[i].shortName),
                                selected: i == _moshafIndex,
                                onSelected: (_) => setState(() {
                                  _moshafIndex = i;
                                  _selected.clear();
                                }),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Pill(r.shortName),
                  const SizedBox(height: Space.md),
                  Wrap(
                    spacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      Pill(r.isComplete ? 'Complete Quran' : '${r.surahs.length} surahs'),
                      if (isDefault) Pill('Default', color: c.goldText, icon: Icons.star_rounded),
                    ],
                  ),
                  const SizedBox(height: Space.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => playRecitation(context, ref, reciter, r, r.surahs.first, resume: true),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Play'),
                          ),
                        ),
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: allDone
                                ? null
                                : activeCount > 0
                                ? () => ref.read(downloadManagerProvider).cancelAll(r.key)
                                : () => _download(
                                    reciter,
                                    r,
                                    r.surahs,
                                    title: r.isComplete ? 'Download the whole Quran' : 'Download all surahs',
                                  ),
                            icon: Icon(
                              allDone
                                  ? Icons.download_done_rounded
                                  : activeCount > 0
                                  ? Icons.stop_rounded
                                  : Icons.download_rounded,
                            ),
                            label: Text(
                              allDone
                                  ? 'All offline'
                                  : activeCount > 0
                                  ? 'Stop ($activeCount)'
                                  : r.isComplete
                                  ? 'Whole Quran'
                                  : 'Download all',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (downloadedCount > 0 || activeCount > 0) ...[
                    const SizedBox(height: Space.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: downloadedCount / r.surahs.length,
                              minHeight: 4,
                              backgroundColor: c.divider,
                              color: c.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$downloadedCount of ${r.surahs.length} surahs on this device'
                            '${activeCount > 0 ? ' · $activeCount downloading' : ''}'
                            '${failedCount > 0 ? ' · $failedCount failed' : ''}',
                            style: context.text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: Space.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                    child: Text(
                      'Long-press surahs to select several for download.',
                      style: context.text.bodySmall?.copyWith(color: c.inkFaint),
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                ],
              ),
            ),
            // Rebuilds the rows while a surah is being prepared (spinner on it).
            ValueListenableBuilder<String?>(
              valueListenable: ref.read(playerProvider).preparing,
              builder: (context, preparing, _) => SliverList.builder(
                itemCount: 114,
                itemBuilder: (_, i) {
                  final s = surahs[i];
                  final available = r.hasSurah(s.id);
                  final isPlaying = np?.recitation.key == r.key && np?.surah == s.id;
                  final downloaded = dl.isDownloaded(r.key, s.id);
                  final selected = _selected.contains(s.id);
                  return _SurahRow(
                    surah: s,
                    available: available,
                    playing: isPlaying,
                    loading: preparing == '${r.key}|${s.id}',
                    selected: selected,
                    selecting: _selecting,
                    trailing: !available
                        ? Text('Not recorded', style: context.text.bodySmall?.copyWith(color: c.inkFaint))
                        : _selecting
                        ? Checkbox(
                            value: selected || downloaded,
                            onChanged: downloaded
                                ? null
                                : (v) => setState(() => v! ? _selected.add(s.id) : _selected.remove(s.id)),
                          )
                        : DownloadIndicator(
                            downloaded: downloaded,
                            active: dl.activeFor(r.key, s.id),
                            onDownload: () => _download(reciter, r, [s.id]),
                            onCancel: () => ref.read(downloadManagerProvider).cancel(r.key, s.id),
                            onDelete: () async {
                              final ok = await showAppDialog(
                                context,
                                icon: Icons.delete_outline_rounded,
                                title: 'Remove ${s.nameEn}?',
                                message: "This surah's audio will be deleted from your phone.",
                                confirmLabel: 'Remove',
                                cancelLabel: 'Keep',
                                destructive: true,
                              );
                              if (ok) ref.read(downloadManagerProvider).delete(r.key, s.id);
                            },
                          ),
                    onTap: !available
                        ? null
                        : _selecting
                        ? (downloaded
                              ? null
                              : () => setState(() => selected ? _selected.remove(s.id) : _selected.add(s.id)))
                        : () => playRecitation(context, ref, reciter, r, s.id),
                    onLongPress: !available || downloaded
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            setState(() => _selected.add(s.id));
                          },
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({
    required this.surah,
    required this.available,
    required this.playing,
    this.loading = false,
    required this.selected,
    required this.selecting,
    required this.trailing,
    this.onTap,
    this.onLongPress,
  });

  final Surah surah;
  final bool available, playing, selected, selecting;

  /// Tapped and starting: shown at once, so the tap is never in doubt.
  final bool loading;
  final Widget trailing;
  final VoidCallback? onTap, onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Opacity(
      opacity: available ? 1 : 0.45,
      child: Material(
        color: selected ? c.primarySoft : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: 8),
            child: Row(
              children: [
                StarMedallion(number: surah.id, size: 42, active: playing),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(surah.nameEn, style: context.text.titleMedium?.copyWith(color: playing ? c.primary : null)),
                      Text('${surah.meaning} · ${surah.ayahCount} ayahs', style: context.text.bodySmall),
                    ],
                  ),
                ),
                if (loading)
                  SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: c.primary))
                else if (playing)
                  Icon(Icons.graphic_eq_rounded, color: c.primary, size: 20),
                const SizedBox(width: 6),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
