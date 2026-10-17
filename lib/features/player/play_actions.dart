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
/// When that reciter's surah is not on the phone and there is no internet,
/// a reciter who has it downloaded plays instead.
Future<void> playFromMushaf(BuildContext context, WidgetRef ref, int surah, {int? ayah}) async {
  var (reciter, recitation) = await defaultRecitation(ref);
  final downloads = ref.read(downloadManagerProvider);
  if (downloads.localFile(recitation.key, surah) == null && !await PlayerController.hasInternet()) {
    final local = await _downloadedRecitation(ref, surah);
    if (local != null) {
      (reciter, recitation) = local;
      if (context.mounted) showToast(context, "You're offline · playing ${reciter.name} (downloaded)");
    }
  }
  if (!context.mounted) return;
  await playRecitation(context, ref, reciter, recitation, surah, ayah: ayah);
}

/// A downloaded recitation that has [surah]: the one with the most surahs saved.
Future<(Reciter, Recitation)?> _downloadedRecitation(WidgetRef ref, int surah) async {
  final catalog = await ref.read(catalogProvider.future);
  final saved = ref.read(downloadManagerProvider).state.downloaded;
  (Reciter, Recitation)? best;
  var most = 0;
  for (final e in saved.entries) {
    if (!e.value.contains(surah)) continue;
    final m = catalog.recitation(e.key);
    final r = m == null ? null : catalog.reciter(m.reciterId);
    if (m != null && r != null && e.value.length > most) {
      best = (r, m);
      most = e.value.length;
    }
  }
  return best;
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
