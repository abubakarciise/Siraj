import 'dart:convert';

import 'package:flutter/services.dart';

/// One piece of a recording: a whole file, or the [start]..[end] cut of it.
class AudioPart {
  const AudioPart(this.url, [this.start, this.end]);
  final String url;
  final Duration? start, end;

  factory AudioPart.fromJson(Map<String, dynamic> j) => AudioPart(
        j['url'] as String,
        j['start'] == null ? null : Duration(milliseconds: j['start'] as int),
        j['end'] == null ? null : Duration(milliseconds: j['end'] as int),
      );
}

class Dhikr {
  const Dhikr({required this.text, required this.count, this.virtue = '', this.quranRef, this.audio});
  final String text;
  final int count;
  final String virtue;

  /// Set when the dhikr is a Quran passage (rendered in the Mushaf font).
  final String? quranRef;

  /// A human recording cut to exactly this dhikr (tool/build_adhkar_audio.py);
  /// null when there is none (the phone's voice reads it instead).
  final List<AudioPart>? audio;

  factory Dhikr.fromJson(Map<String, dynamic> j, [Map<String, dynamic>? audio]) => Dhikr(
        text: j['text'] as String,
        count: (j['count'] as num).toInt().clamp(1, 1000),
        virtue: (j['virtue'] as String?) ?? '',
        quranRef: j['quran'] as String?,
        audio: audio == null
            ? null
            : [for (final p in audio['parts'] as List) AudioPart.fromJson(p as Map<String, dynamic>)],
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
