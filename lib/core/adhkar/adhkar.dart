import 'dart:convert';

import 'package:flutter/services.dart';

class Dhikr {
  const Dhikr({required this.text, required this.count, this.virtue = '', this.quranRef, this.audioFile});
  final String text;
  final int count;
  final String virtue;

  /// Set when the dhikr is a Quran passage (rendered in the Mushaf font).
  final String? quranRef;

  /// A human recording cut to exactly this dhikr, bundled in
  /// assets/adhkar/audio/ (tool/build_adhkar_audio.py); null when there is none.
  final String? audioFile;

  factory Dhikr.fromJson(Map<String, dynamic> j, [Map<String, dynamic>? audio]) => Dhikr(
        text: j['text'] as String,
        count: (j['count'] as num).toInt().clamp(1, 1000),
        virtue: (j['virtue'] as String?) ?? '',
        quranRef: j['quran'] as String?,
        audioFile: audio?['file'] as String?,
      );
}

class AdhkarCategory {
  const AdhkarCategory({required this.id, required this.titleAr, required this.titleEn, required this.items});
  final String id, titleAr, titleEn;
  final List<Dhikr> items;

  int get totalCount => items.fold(0, (a, b) => a + b.count);
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
