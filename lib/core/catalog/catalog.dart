import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// One recorded mushaf (riwayah + style) by a reciter, e.g. "Hafs – Murattal".
class Recitation {
  const Recitation({
    required this.reciterId,
    required this.moshafId,
    required this.name,
    required this.nameAr,
    required this.server,
    required this.surahs,
    this.rewaya,
    this.timingReadId,
  });

  final int reciterId, moshafId;
  final String name, nameAr, server;
  final List<int> surahs;
  final int? rewaya;

  /// mp3quran `ayat_timing` read id, when ayah timing exists (enables highlighting).
  final int? timingReadId;

  String get key => '$reciterId-$moshafId';
  bool get hasTiming => timingReadId != null;
  bool get isComplete => surahs.length == 114;
  bool hasSurah(int s) => surahs.contains(s);
  String urlFor(int surah) => '$server${surah.toString().padLeft(3, '0')}.mp3';

  /// Riwayah label, e.g. "Hafs", "Warsh", "Qalon" (from "Rewayat Hafs A'n Assem - Murattal").
  String get riwayah {
    final first = name.split(' - ').first;
    if (first.startsWith('Almusshaf')) return 'Hafs';
    return first.replaceFirst(RegExp(r'^Rewayat\s+'), '').split(" A'n ").first.trim();
  }

  /// Style label, e.g. "Murattal", "Mujawwad", "Teaching".
  String get style {
    final n = name.toLowerCase();
    if (n.contains('mojawwad') || n.contains('mujawwad')) return 'Mujawwad';
    if (n.contains("mo'lim") || n.contains('muallim')) return 'Teaching';
    final parts = name.split(' - ');
    return parts.length > 1 ? parts.last.trim() : 'Murattal';
  }

  String get shortName => '$riwayah · $style';

  bool get isMujawwad => style == 'Mujawwad';
  bool get isHafs => riwayah == 'Hafs';

  factory Recitation.fromJson(int reciterId, Map<String, dynamic> j) => Recitation(
        reciterId: reciterId,
        moshafId: j['id'] as int,
        name: j['name'] as String,
        nameAr: (j['name_ar'] ?? j['name']) as String,
        server: j['server'] as String,
        surahs: (j['surahs'] as String).split(',').where((s) => s.trim().isNotEmpty).map(int.parse).toList()..sort(),
        rewaya: j['rewaya'] as int?,
        timingReadId: _wrongTiming.contains('$reciterId-${j['id']}') ? null : j['timing'] as int?,
      );

  /// mp3quran timing that belongs to another edition of the audio: checked
  /// against the recordings (surahs 67 and 78), the ayah starts fall in the
  /// middle of words. These play without timing (estimated follow-along).
  static const _wrongTiming = {'134-134', '135-135', '137-137', '125-288'};
}

class Reciter {
  const Reciter({required this.id, required this.name, required this.nameAr, required this.recitations});
  final int id;
  final String name, nameAr;
  final List<Recitation> recitations;

  bool get hasTiming => recitations.any((r) => r.hasTiming);
  Set<String> get riwayat => {for (final r in recitations) r.riwayah};

  factory Reciter.fromJson(Map<String, dynamic> j) {
    final id = j['id'] as int;
    return Reciter(
      id: id,
      name: (j['name'] as String).trim(),
      nameAr: (j['name_ar'] as String).trim(),
      recitations: [for (final m in j['moshaf'] as List) Recitation.fromJson(id, m as Map<String, dynamic>)],
    );
  }
}

class Catalog {
  Catalog(this.reciters) : _byKey = {for (final r in reciters) for (final m in r.recitations) m.key: m};
  final List<Reciter> reciters;
  final Map<String, Recitation> _byKey;

  Recitation? recitation(String key) => _byKey[key];
  Reciter? reciter(int id) => reciters.where((r) => r.id == id).firstOrNull;

  /// Reciters most listeners look for first. Each entry lists spelling
  /// variants, because the API's Latin transliterations vary.
  static const featuredNames = [
    ['alafasi', 'alafasy'],
    ['hussary', 'husary'],
    ['minshawi'],
    ['abdulbasit'],
    ['sudaes', 'sudais'],
    ['shuraim'],
    ['meaqli', 'muaiqly'],
    ['ghamdi'],
    ['yasseraldosari', 'yasseraldossari'],
    ['ajmy', 'ajmi'],
    ['shatri'],
    ['qatami'],
  ];

  List<Reciter> get featured {
    final out = <Reciter>[];
    for (final aliases in featuredNames) {
      final match = reciters.where((r) {
        final n = r.name.toLowerCase().replaceAll(RegExp('[^a-z]'), '');
        return aliases.any(n.contains);
      });
      if (match.isNotEmpty && !out.contains(match.first)) out.add(match.first);
    }
    return out;
  }
}

/// Bundled snapshot first (works offline on first launch); refreshed weekly
/// straight from the public mp3quran.net API, no backend of our own.
class CatalogRepository {
  static const _api = 'https://mp3quran.net/api/v3';
  static const _refreshEvery = Duration(days: 7);

  Future<File> _cacheFile() async => File(p.join((await getApplicationSupportDirectory()).path, 'catalog.json'));

  Future<Catalog> load() async {
    final file = await _cacheFile();
    String raw;
    if (file.existsSync()) {
      raw = await file.readAsString();
    } else {
      raw = await rootBundle.loadString('assets/catalog/reciters.json');
    }
    return compute(_parse, raw);
  }

  Future<bool> needsRefresh() async {
    final file = await _cacheFile();
    if (!file.existsSync()) return true;
    return DateTime.now().difference(file.lastModifiedSync()) > _refreshEvery;
  }

  /// Returns a fresh catalog or null when offline / the API failed.
  Future<Catalog?> refresh() async {
    try {
      Future<dynamic> get(String path) async {
        final res = await http.get(Uri.parse('$_api/$path')).timeout(const Duration(seconds: 20));
        if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
        return jsonDecode(utf8.decode(res.bodyBytes));
      }

      final results = await Future.wait([
        get('reciters?language=eng'),
        get('reciters?language=ar'),
        get('ayat_timing/reads'),
      ]);
      final raw = buildCatalogJson(results[0] as Map, results[1] as Map, results[2] as List);
      final catalog = await compute(_parse, raw);
      if (catalog.reciters.length < 50) return null; // sanity guard against a bad response
      await (await _cacheFile()).writeAsString(raw, flush: true);
      return catalog;
    } catch (e) {
      debugPrint('Catalog refresh failed: $e');
      return null;
    }
  }

  /// Mirrors tool/build_catalog.py so bundled and refreshed catalogs share a format.
  @visibleForTesting
  static String buildCatalogJson(Map en, Map ar, List timingReads) {
    String norm(String s) => s.endsWith('/') ? s : '$s/';
    final timing = {for (final t in timingReads) norm(t['folder_url'] as String): t['id'] as int};
    final arById = {for (final r in ar['reciters'] as List) r['id'] as int: r};
    final list = (en['reciters'] as List).cast<Map>().toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    final out = <Map<String, dynamic>>[];
    for (final r in list) {
      final arR = arById[r['id']] ?? r;
      final arMoshaf = {for (final m in arR['moshaf'] as List) m['id']: m};
      final moshafs = [
        for (final m in r['moshaf'] as List)
          {
            'id': m['id'],
            'name': m['name'],
            'name_ar': (arMoshaf[m['id']] ?? m)['name'],
            'server': norm(m['server'] as String),
            'rewaya': m['rewaya_id'],
            'type': m['moshaf_type'],
            'surahs': m['surah_list'],
            'timing': timing[norm(m['server'] as String)],
          },
      ];
      if (moshafs.isNotEmpty) {
        out.add({'id': r['id'], 'name': r['name'], 'name_ar': arR['name'], 'moshaf': moshafs});
      }
    }
    return jsonEncode({'reciters': out});
  }

  /// Only recitations with ayah timing are offered: every one follows along
  /// exactly. Reciters left without any recitation are dropped.
  static Catalog _parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final out = <Reciter>[];
    for (final r in j['reciters'] as List) {
      final full = Reciter.fromJson(r as Map<String, dynamic>);
      final timed = full.recitations.where((m) => m.hasTiming).toList();
      if (timed.isNotEmpty) {
        out.add(Reciter(id: full.id, name: full.name, nameAr: full.nameAr, recitations: timed));
      }
    }
    return Catalog(out);
  }
}
