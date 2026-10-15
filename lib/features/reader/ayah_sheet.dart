import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/quran/models.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import '../player/play_actions.dart';

final _ayahDetailProvider = FutureProvider.autoDispose.family<(Ayah, String?, bool), AyahRef>((ref, a) async {
  final db = ref.watch(quranDbProvider);
  final slug = ref.watch(settingsProvider).translation;
  final ayah = await db.ayah(a);
  final tr = slug.isEmpty ? null : await db.translation(a, slug);
  final bookmarked = (await ref.watch(bookmarksProvider.future)).any((b) => b.ref == a);
  return (ayah, tr, bookmarked);
});

Future<void> showAyahSheet(BuildContext context, AyahRef ref) => showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AyahSheet(ayahRef: ref),
    );

class _AyahSheet extends ConsumerWidget {
  const _AyahSheet({required this.ayahRef});
  final AyahRef ayahRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final surah = ref.watch(quranDbProvider).surah(ayahRef.surah);
    final detail = ref.watch(_ayahDetailProvider(ayahRef));
    final mq = MediaQuery.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.88),
      child: detail.when(
        loading: () => const SizedBox(height: 240, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => SizedBox(height: 120, child: Center(child: Text('$e'))),
        data: (d) {
          final (ayah, translation, bookmarked) = d;
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.md),
              child: Row(children: [
                Expanded(
                  child: Text('${surah.nameEn} ${ayahRef.surah}:${ayahRef.ayah}', style: context.text.titleMedium),
                ),
                Pill(surah.isMakki ? 'Makki' : 'Madani'),
              ]),
            ),
            // Long ayahs scroll; the actions below stay visible.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.lg),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(
                    ayah.text,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: kQuranFont, fontSize: 26, height: 1.9, color: c.ink),
                  ),
                  if (translation != null) ...[
                    const SizedBox(height: Space.md),
                    Text(translation, style: context.text.bodyLarge?.copyWith(color: c.inkMuted)),
                  ],
                ]),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.divider))),
              child: Padding(
                padding: EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.md + mq.padding.bottom),
                child: Row(children: [
                  Expanded(
                    flex: 2,
                    child: _Action(Icons.play_arrow_rounded, 'Play', primary: true, onTap: () {
                      final nav = Navigator.of(context);
                      playFromMushaf(context, ref, ayahRef.surah, ayah: ayahRef.ayah).whenComplete(nav.pop);
                    }),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: _Action(bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, null,
                        onTap: () async {
                      final store = ref.read(userStoreProvider);
                      bookmarked ? await store.removeBookmark(ayahRef) : await store.addBookmark(ayahRef, ayah.page);
                      HapticFeedback.lightImpact();
                      ref.invalidate(bookmarksProvider);
                    }),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: _Action(Icons.copy_rounded, null, onTap: () {
                      Clipboard.setData(ClipboardData(
                          text: '${ayah.plainText}\n\n${translation ?? ''}\n— ${surah.nameEn} ${ayahRef.surah}:${ayahRef.ayah}'
                              .trim()));
                      Navigator.pop(context);
                      showToast(context, 'Ayah copied');
                    }),
                  ),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, {required this.onTap, this.primary = false});
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: primary ? c.primary : c.surfaceAlt,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 22, color: primary ? c.onPrimary : c.ink),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(label!, style: context.text.labelLarge?.copyWith(color: primary ? c.onPrimary : c.ink)),
            ],
          ]),
        ),
      ),
    );
  }
}
