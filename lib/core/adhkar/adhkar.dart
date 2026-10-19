import 'dart:convert';

import 'package:flutter/services.dart';

/// Listening "Short", a dhikr said a hundred times plays this often; its card
/// keeps the rest of the count for the listener to finish by tapping (complete
/// recordings do the same: Alafasy recites the hundred-times adhkar once), and
/// the morning and evening adhkar stay near 20 minutes. "Full count" plays
/// every dhikr its whole count. Shorter counts (3, 7, 10, 33) always play in full.
const kListenCap = 10;
const kLongCount = 100;

class Dhikr {
  const Dhikr({required this.text, required this.count, this.virtue = '', this.quranRef, this.audioFile, this.audioMs = 0});
  final String text;
  final int count;
  final String virtue;

  /// Set when the dhikr is a Quran passage (rendered in the Mushaf font).
  final String? quranRef;

  /// A human recording cut to exactly this dhikr, bundled in
  /// assets/adhkar/audio/ (tool/build_adhkar_audio.py); null when there is none.
  final String? audioFile;

  /// Length of the recording (one recitation), 0 without one.
  final int audioMs;

  /// How many times the recording plays when listening to the whole category.
  int listenTimes({bool full = false}) => full || count < kLongCount ? count : kListenCap;

  factory Dhikr.fromJson(Map<String, dynamic> j, [Map<String, dynamic>? audio]) => Dhikr(
        text: j['text'] as String,
        count: (j['count'] as num).toInt().clamp(1, 1000),
        virtue: (j['virtue'] as String?) ?? '',
        quranRef: j['quran'] as String?,
        audioFile: audio?['file'] as String?,
        audioMs: (audio?['ms'] as num?)?.toInt() ?? 0,
      );
}

class AdhkarCategory {
  const AdhkarCategory({required this.id, required this.titleAr, required this.titleEn, required this.items});
  final String id, titleAr, titleEn;
  final List<Dhikr> items;

  int get totalCount => items.fold(0, (a, b) => a + b.count);

  /// How long listening to the whole category takes ("Short", or the full
  /// count): each recording as many times as it plays ([Dhikr.listenTimes]),
  /// with the player's pauses between (450 ms between repetitions, a second
  /// before the next dhikr). Adhkar without a recording are left out;
  /// [unrecorded] says how many.
  Duration listeningTime({bool full = false}) => Duration(
        milliseconds: items
            .where((d) => d.audioMs > 0)
            .fold(0, (t, d) => t + d.listenTimes(full: full) * (d.audioMs + 450) + 550),
      );

  int get unrecorded => items.where((d) => d.audioFile == null).length;
}

/// "12 min", "1 h 5 min", "45 s".
String formatListeningTime(Duration d) {
  if (d.inSeconds < 60) return '${d.inSeconds} s';
  final m = (d.inSeconds / 60).round();
  return m < 60 ? '$m min' : '${m ~/ 60} h ${m % 60} min';
}

/// Hisn al-Muslim adhkar bundled with the app (assets/adhkar/adhkar.json).
class AdhkarRepository {
  static Future<List<AdhkarCategory>> load() async {
    final j = jsonDecode(await rootBundle.loadString('assets/adhkar/adhkar.json')) as Map<String, dynamic>;
    Map<String, dynamic> audio = const {};
    try {
      audio = jsonDecode(await rootBundle.loadString('assets/adhkar/audio.json')) as Map<String, dynamic>;
    } catch (_) {}
    return [
      for (final c in j['categories'] as List)
        AdhkarCategory(
          id: c['id'] as String,
          titleAr: c['title_ar'] as String,
          titleEn: c['title_en'] as String,
          items: [
            for (final (i, item) in (c['items'] as List).indexed)
              Dhikr.fromJson(item as Map<String, dynamic>, _audioAt(audio[c['id']], i)),
          ],
        ),
    ];
  }

  static Map<String, dynamic>? _audioAt(dynamic list, int i) =>
      list is List && i < list.length ? list[i] as Map<String, dynamic>? : null;
}
