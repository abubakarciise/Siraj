import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';

/// Persistent player bar. Tap or swipe up to expand, swipe down to stop.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final np = ref.watch(nowPlayingProvider).value;
    final db = ref.watch(quranDbProvider);
    return AnimatedSize(
      duration: Motion.standard,
      curve: Motion.emphasized,
      child: np == null
          ? const SizedBox(width: double.infinity)
          : GestureDetector(
              onTap: () => context.push('/player'),
              onVerticalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v < -200) context.push('/player');
                if (v > 300) ref.read(playerProvider).stop();
              },
              child: Container(
                height: 64,
                margin: embedded ? EdgeInsets.zero : const EdgeInsets.fromLTRB(8, 0, 8, 6),
                decoration: BoxDecoration(
                  color: embedded ? Colors.transparent : c.surface,
                  borderRadius: BorderRadius.circular(embedded ? 0 : Radii.lg),
                  border: embedded ? null : Border.all(color: c.divider),
                  boxShadow: embedded
                      ? null
                      : [BoxShadow(color: Colors.black.withValues(alpha: c.isDark ? 0.3 : 0.06), blurRadius: 24, offset: const Offset(0, 6))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(children: [
                  Row(children: [
                    const SizedBox(width: 10),
                    Hero(tag: 'player-art', child: ReciterAvatar(id: np.reciter.id, nameAr: np.reciter.nameAr, size: 42)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${db.surah(np.surah).nameEn}${np.ayah != null ? ' · ${np.ayah!.ayah}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleMedium,
                          ),
                          Text(np.reciter.name,
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: ref.read(playerProvider).toggle,
                      icon: np.buffering && !np.playing
                          ? SizedBox.square(
                              dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: c.primary))
                          : AnimatedSwitcher(
                              duration: Motion.quick,
                              child: Icon(np.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  key: ValueKey(np.playing), size: 30, color: c.ink),
                            ),
                    ),
                    IconButton(
                      tooltip: 'Close player',
                      onPressed: ref.read(playerProvider).stop,
                      icon: Icon(Icons.close_rounded, color: c.inkMuted),
                    ),
                    const SizedBox(width: 2),
                  ]),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: LinearProgressIndicator(
                      value: np.duration.inMilliseconds == 0
                          ? 0
                          : (np.position.inMilliseconds / np.duration.inMilliseconds).clamp(0.0, 1.0),
                      minHeight: 2,
                      backgroundColor: Colors.transparent,
                      color: c.primary,
                    ),
                  ),
                ]),
              ),
            ),
    );
  }
}
