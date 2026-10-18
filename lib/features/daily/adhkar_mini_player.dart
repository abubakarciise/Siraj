import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../design/tokens.dart';
import 'adhkar_screen.dart' show adhkarIcons;

/// Adhkar playing in the background: shown above the tabs, like the Quran
/// mini player but in the night-blue of the adhkar notification.
class AdhkarMiniPlayer extends ConsumerWidget {
  const AdhkarMiniPlayer({super.key});

  static const _night = Color(0xFF0B3D32); // deep emerald, as the logo

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(adhkarPlayerProvider);
    return ListenableBuilder(
      listenable: audio,
      builder: (context, _) {
        final c = context.colors;
        final cat = audio.category;
        return AnimatedSize(
          duration: Motion.standard,
          curve: Motion.emphasized,
          child: cat == null
              ? const SizedBox(width: double.infinity)
              : GestureDetector(
                  onTap: () => context.push('/adhkar/${cat.id}'),
                  child: Container(
                    height: 64,
                    margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                    decoration: BoxDecoration(
                      color: _night,
                      borderRadius: BorderRadius.circular(Radii.lg),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(children: [
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: c.gold.withValues(alpha: 0.18), shape: BoxShape.circle),
                        child: Icon(adhkarIcons[cat.id] ?? Icons.favorite_border, color: c.gold, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cat.titleEn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.titleMedium?.copyWith(color: Colors.white)),
                            Text(
                              audio.waitingForReader
                                  ? 'Dhikr ${audio.index + 1} · your turn to read'
                                  : 'Dhikr ${audio.index + 1} of ${cat.items.length}',
                              maxLines: 1,
                              style: context.text.bodySmall?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: audio.playing ? 'Pause' : 'Play',
                        onPressed: audio.playing ? audio.pause : audio.resume,
                        icon: Icon(audio.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 30, color: Colors.white),
                      ),
                      IconButton(
                        tooltip: 'Stop',
                        onPressed: audio.stop,
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      ),
                      const SizedBox(width: 2),
                    ]),
                  ),
                ),
        );
      },
    );
  }
}
