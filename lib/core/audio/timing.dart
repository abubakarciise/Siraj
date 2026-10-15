import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Ayah start/end offsets inside a surah audio file.
class SurahTiming {
  SurahTiming(List<(int ayah, int start, int end)> entries)
      : ayahs = Int32List.fromList([for (final e in entries) e.$1]),
        starts = Int32List.fromList([for (final e in entries) e.$2]),
        ends = Int32List.fromList([for (final e in entries) e.$3]);

  final Int32List ayahs, starts, ends;

  /// Ayah playing at [ms] (0 = isti'adha / basmala intro), via binary search.
  int ayahAt(int ms) {
    var lo = 0, hi = starts.length - 1, ans = 0;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (starts[mid] <= ms) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return starts.isEmpty ? 0 : ayahs[ans];
  }

  int? startOf(int ayah) {
    final i = ayahs.indexOf(ayah);
    return i < 0 ? null : starts[i];
  }

  int? endOf(int ayah) {
    final i = ayahs.indexOf(ayah);
    return i < 0 ? null : ends[i];
  }
}

/// Fetches mp3quran `ayat_timing` straight from the public API and keeps
/// it on the device so highlighting keeps working offline.
class TimingService {
  final _memory = <String, SurahTiming>{};
  final _inflight = <String, Future<SurahTiming?>>{};

  Future<File> _file(int readId, int surah) async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'timing', '$readId', '${surah.toString().padLeft(3, '0')}.json'));
  }

  SurahTiming? cached(int readId, int surah) => _memory['$readId:$surah'];

  Future<SurahTiming?> get(int readId, int surah) {
    final key = '$readId:$surah';
    final mem = _memory[key];
    if (mem != null) return Future.value(mem);
    return _inflight[key] ??= _load(readId, surah).whenComplete(() => _inflight.remove(key));
  }

  Future<SurahTiming?> _load(int readId, int surah) async {
    final key = '$readId:$surah';
    try {
      final file = await _file(readId, surah);
      String raw;
      if (file.existsSync()) {
        raw = await file.readAsString();
      } else {
        final res = await http
            .get(Uri.parse('https://mp3quran.net/api/v3/ayat_timing?surah=$surah&read=$readId'))
            .timeout(const Duration(seconds: 20));
        if (res.statusCode != 200) return null;
        raw = utf8.decode(res.bodyBytes);
        await file.create(recursive: true);
        await file.writeAsString(raw, flush: true);
      }
      final list = jsonDecode(raw) as List;
      if (list.isEmpty) return null;
      final timing = SurahTiming([
        for (final e in list)
          ((e['ayah'] as num).toInt(), (e['start_time'] as num).toInt(), (e['end_time'] as num).toInt()),
      ]);
      return _memory[key] = timing;
    } catch (e) {
      debugPrint('Timing $key unavailable: $e');
      return null;
    }
  }
}
