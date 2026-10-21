import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell.dart';
import '../../core/downloads/download_manager.dart';
import '../../core/providers.dart';
import '../../design/dialogs.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import '../../l10n/l10n.dart';

final _sizesProvider = FutureProvider.autoDispose<Map<String, int>>((ref) {
  ref.watch(downloadsProvider.select((s) => s.value?.downloaded));
  return ref.read(downloadManagerProvider).sizes();
});

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TabTitle(context.l10n.library),
        actions: [IconButton(icon: Icon(Icons.settings_outlined), onPressed: () => context.push('/settings'))],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(56),
          child: Padding(
            padding: EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.sm),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 0, label: Text(context.l10n.bookmarks), icon: Icon(Icons.bookmark_rounded)),
                  ButtonSegment(value: 1, label: Text(context.l10n.downloads), icon: Icon(Icons.download_done_rounded)),
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
        child: _tab == 0 ? const _Bookmarks(key: ValueKey('b')) : const _Downloads(key: ValueKey('d')),
      ),
    );
  }
}

class _Bookmarks extends ConsumerWidget {
  const _Bookmarks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final db = ref.watch(quranDbProvider);
    final bookmarks = ref.watch(bookmarksProvider).value ?? const [];
    if (bookmarks.isEmpty) {
      return _Empty(
        icon: Icons.bookmark_border_rounded,
        text: context.l10n.noBookmarksYet,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: bookmarks.length,
      separatorBuilder: (_, _) => const Divider(indent: Space.gutter, endIndent: Space.gutter),
      itemBuilder: (_, i) {
        final b = bookmarks[i];
        final s = db.surah(b.ref.surah);
        return Dismissible(
          key: ValueKey('bm${b.ref}'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: c.danger,
            alignment: AlignmentDirectional.centerEnd,
            padding: const EdgeInsets.only(right: Space.xxl),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          onDismissed: (_) async {
            await ref.read(userStoreProvider).removeBookmark(b.ref);
            ref.invalidate(bookmarksProvider);
          },
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: 4),
            leading: Icon(Icons.bookmark_rounded, color: c.gold),
            title: Text('${s.nameEn} ${b.ref}'),
            subtitle: Text(context.l10n.pageSavedOn(b.page, MaterialLocalizations.of(context).formatShortDate(b.createdAt))),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.openReader(b.page, ayah: b.ref.toString()),
          ),
        );
      },
    );
  }
}

class _Downloads extends ConsumerWidget {
  const _Downloads({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final catalog = ref.watch(catalogProvider).value;
    final dl = ref.watch(downloadsProvider).value ?? const DownloadsState();
    final sizes = ref.watch(_sizesProvider).value ?? const {};
    final keys = {...dl.downloaded.keys, ...dl.active.values.map((a) => a.recitationKey)}.toList();
    if (keys.isEmpty || catalog == null) {
      return _Empty(
        icon: Icons.cloud_download_outlined,
        text: context.l10n.listenOfflineHint,
        action: FilledButton(onPressed: () => context.go('/listen'), child: Text(context.l10n.browseReciters)),
      );
    }
    final total = sizes.values.fold<int>(0, (a, b) => a + b);
    final active = dl.active.values.where((a) => a.status != DlStatus.failed).length;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.sm),
          child: Container(
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(Radii.lg)),
            child: Row(children: [
              Icon(Icons.sd_storage_rounded, color: c.primary),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(context.l10n.sizeOnDevice(formatBytes(total)), style: context.text.titleMedium),
                  Text(
                    context.l10n.surahsAcrossRecitations(
                            dl.downloaded.values.fold<int>(0, (a, b) => a + b.length), dl.downloaded.length) +
                        (active > 0 ? context.l10n.countDownloading(active) : ''),
                    style: context.text.bodySmall,
                  ),
                ]),
              ),
            ]),
          ),
        ),
        for (final key in keys)
          Builder(builder: (context) {
            final rec = catalog.recitation(key);
            final reciter = rec == null ? null : catalog.reciter(rec.reciterId);
            final count = dl.downloadedCount(key);
            final running = dl.activeOf(key);
            final avg = running.isEmpty ? 0.0 : running.fold<double>(0, (a, b) => a + b.progress) / running.length;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: 6),
              leading: ReciterAvatar(id: reciter?.id ?? 0, nameAr: reciter?.nameAr ?? '', size: 48),
              title: Text(reciter?.name ?? key, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.l10n.recitationDownloadSummary(
                    rec?.shortName ?? '', count, rec?.surahs.length ?? 114, formatBytes(sizes[key] ?? 0))),
                if (running.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ((count + avg * running.length) / (count + running.length)).clamp(0.0, 1.0),
                      minHeight: 3,
                      color: c.primary,
                      backgroundColor: c.divider,
                    ),
                  ),
                ],
              ]),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  final dm = ref.read(downloadManagerProvider);
                  if (v == 'cancel') await dm.cancelAll(key);
                  if (v == 'delete' && context.mounted) {
                    final ok = await showAppDialog(
                      context,
                      icon: Icons.delete_outline_rounded,
                      title: context.l10n.deleteDownloadsQuestion,
                      message: context.l10n.freeSpaceMessage(
                          formatBytes(sizes[key] ?? 0), reciter?.name ?? context.l10n.thisReciter),
                      confirmLabel: context.l10n.delete,
                      destructive: true,
                    );
                    if (ok) await dm.deleteRecitation(key);
                  }
                },
                itemBuilder: (_) => [
                  if (running.isNotEmpty) PopupMenuItem(value: 'cancel', child: Text(context.l10n.stopDownloading)),
                  if (count > 0) PopupMenuItem(value: 'delete', child: Text(context.l10n.deleteFromDevice)),
                ],
              ),
              onTap: reciter == null ? null : () => context.go('/listen/reciter/${reciter.id}'),
            );
          }),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: c.primary),
          ),
          const SizedBox(height: Space.xl),
          Text(text, textAlign: TextAlign.center, style: context.text.bodyLarge?.copyWith(color: c.inkMuted)),
          if (action != null) ...[const SizedBox(height: Space.xl), action!],
        ]),
      ),
    );
  }
}
