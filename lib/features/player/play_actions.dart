import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/player_controller.dart';
import '../../core/catalog/catalog.dart';
import '../../core/providers.dart';
import '../../design/widgets.dart';

/// The reciter used when playing from the reader: the user's choice, otherwise
/// the first featured Hafs recitation that supports ayah highlighting.
Future<(Reciter, Recitation)> defaultRecitation(WidgetRef ref) async {
  final catalog = await ref.read(catalogProvider.future);
  final key = ref.read(settingsProvider).defaultRecitation;
  final chosen = key == null ? null : catalog.recitation(key);
  if (chosen != null) return (catalog.reciter(chosen.reciterId)!, chosen);
  for (final r in [...catalog.featured, ...catalog.reciters]) {
    for (final m in r.recitations) {
      if (m.isHafs && m.isComplete && m.hasTiming) return (r, m);
    }
  }
  final r = catalog.reciters.first;
  return (r, r.recitations.first);
}

/// Plays [surah] (optionally from [ayah]) with the default Mushaf reciter.
Future<void> playFromMushaf(BuildContext context, WidgetRef ref, int surah, {int? ayah}) async {
  final (reciter, recitation) = await defaultRecitation(ref);
  if (!context.mounted) return;
  await playRecitation(context, ref, reciter, recitation, surah, ayah: ayah);
}

Future<void> playRecitation(
  BuildContext context,
  WidgetRef ref,
  Reciter reciter,
  Recitation recitation,
  int surah, {
  int? ayah,
  bool resume = false,
}) async {
  try {
    await ref.read(playerProvider).play(recitation, reciter, surah, ayah: ayah, resume: resume);
  } on OfflineException {
    if (context.mounted) showToast(context, "You're offline. Download this surah to listen without internet.");
  } catch (e, st) {
    debugPrint('Playback failed: $e\n$st');
    if (context.mounted) showToast(context, 'Could not start playback. Check your connection and try again.');
  }
}
