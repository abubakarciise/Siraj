import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'arabic.dart';
import 'models.dart';

/// Read-only access to the bundled Quran content database.
///
/// The asset is copied to app-support on first launch (or when the bundled
/// version changes) and opened read-only, so all reading works offline.
class QuranDb {
  QuranDb._(this._db, this.surahs);

  final Database _db;
  final List<Surah> surahs;
  final _pageCache = <int, MushafPage>{};

  static const _assetVersion = 3; // bump whenever assets/db/quran.db is rebuilt

  static Future<QuranDb> open() async {
    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, 'quran_v$_assetVersion.db');
    if (!File(path).existsSync()) {
      final bytes = await rootBundle.load('assets/db/quran.db');
      final tmp = File('$path.tmp');
      await tmp.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes), flush: true);
      await tmp.rename(path);
      // Clean up older copies.
      for (final f in dir.listSync().whereType<File>()) {
        if (p.basename(f.path).startsWith('quran_v') && f.path != path) f.deleteSync();
      }
    }
    final db = await openDatabase(path, readOnly: true, singleInstance: true);
    final rows = await db.query('surahs', orderBy: 'id');
    final surahs = [
      for (final r in rows)
        Surah(
          id: r['id'] as int,
          nameAr: r['name_ar'] as String,
          nameEn: r['name_en'] as String,
          meaning: r['meaning_en'] as String,
          isMakki: r['revelation'] == 'makkah',
          ayahCount: r['ayah_count'] as int,
          pageStart: r['page_start'] as int,
          pageEnd: r['page_end'] as int,
        ),
    ];
    return QuranDb._(db, surahs);
  }

  Surah surah(int id) => surahs[id - 1];

  Future<MushafPage> page(int number) async {
    final cached = _pageCache[number];
    if (cached != null) return cached;
    final lineRows = await _db.query('lines', where: 'page = ?', whereArgs: [number], orderBy: 'line');
    final wordRows = await _db.query('words', where: 'page = ?', whereArgs: [number], orderBy: 'line, idx');
    final byLine = <int, List<MushafWord>>{};
    for (final w in wordRows) {
      byLine.putIfAbsent(w['line'] as int, () => []).add(MushafWord(
            w['surah'] as int,
            w['ayah'] as int,
            w['text'] as String,
            (w['is_end'] as int) == 1,
          ));
    }
    final lines = [
      for (final l in lineRows)
        MushafLine(
          number: l['line'] as int,
          type: LineType.values[l['type'] as int],
          surah: l['surah'] as int?,
          words: byLine[l['line'] as int] ?? const [],
        ),
    ];
    final meta = await _db.rawQuery(
        'SELECT MIN(juz) AS juz, GROUP_CONCAT(DISTINCT surah) AS surahs FROM ayahs WHERE page = ?', [number]);
    final page = MushafPage(
      number: number,
      lines: lines,
      juz: meta.first['juz'] as int,
      surahs: (meta.first['surahs'] as String).split(',').map(int.parse).toList(),
    );
    if (_pageCache.length > 40) _pageCache.remove(_pageCache.keys.first);
    return _pageCache[number] = page;
  }

  Ayah _ayahFromRow(Map<String, Object?> r) => Ayah(
        id: r['id'] as int,
        ref: AyahRef(r['surah'] as int, r['ayah'] as int),
        page: r['page'] as int,
        juz: r['juz'] as int,
        text: r['text'] as String,
      );

  Future<Ayah> ayah(AyahRef ref) async {
    final rows = await _db.query('ayahs', where: 'surah = ? AND ayah = ?', whereArgs: [ref.surah, ref.ayah]);
    return _ayahFromRow(rows.first);
  }

  Future<Ayah> ayahById(int id) async => _ayahFromRow((await _db.query('ayahs', where: 'id = ?', whereArgs: [id])).first);

  Future<List<Ayah>> ayahsOfSurah(int surah) async =>
      (await _db.query('ayahs', where: 'surah = ?', whereArgs: [surah], orderBy: 'ayah')).map(_ayahFromRow).toList();

  Future<List<Ayah>> ayahsOfJuz(int juz) async =>
      (await _db.query('ayahs', where: 'juz = ?', whereArgs: [juz], orderBy: 'id')).map(_ayahFromRow).toList();

  Future<int> pageOf(AyahRef ref) async => (await ayah(ref)).page;

  /// All translations of one surah, keyed by ayah number.
  Future<Map<int, String>> translationsOfSurah(int surah, String slug) async {
    final rows = await _db.rawQuery(
      'SELECT a.ayah, t.text FROM translations t JOIN ayahs a ON a.id = t.ayah_id WHERE t.slug = ? AND a.surah = ?',
      [slug, surah],
    );
    return {for (final r in rows) r['ayah'] as int: r['text'] as String};
  }

  Future<String?> translation(AyahRef ref, String slug) async {
    final rows = await _db.rawQuery(
      'SELECT t.text FROM translations t JOIN ayahs a ON a.id = t.ayah_id WHERE t.slug = ? AND a.surah = ? AND a.ayah = ?',
      [slug, ref.surah, ref.ayah],
    );
    return rows.isEmpty ? null : rows.first['text'] as String;
  }

  Future<List<JuzInfo>> juzList() async {
    final rows = await _db.rawQuery(
        'SELECT juz, MIN(id) AS id FROM ayahs GROUP BY juz ORDER BY juz');
    final out = <JuzInfo>[];
    for (final r in rows) {
      final a = await ayahById(r['id'] as int);
      out.add(JuzInfo(r['juz'] as int, a.page, a.ref));
    }
    return out;
  }

  Future<List<SearchHit>> search(String query, {String translationSlug = 'en_sahih'}) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final hits = <SearchHit>[];
    if (isArabic(q)) {
      final norm = normalizeArabic(q);
      final rows = await _db.query('ayahs',
          where: 'text_search LIKE ?', whereArgs: ['%$norm%'], orderBy: 'id', limit: 100);
      for (final r in rows) {
        hits.add(SearchHit(ayah: _ayahFromRow(r), snippet: r['text'] as String, isTranslation: false));
      }
    } else {
      final rows = await _db.rawQuery(
        'SELECT a.*, t.text AS tr FROM translations t JOIN ayahs a ON a.id = t.ayah_id '
        'WHERE t.slug = ? AND t.text LIKE ? ORDER BY a.id LIMIT 100',
        [translationSlug, '%$q%'],
      );
      for (final r in rows) {
        hits.add(SearchHit(ayah: _ayahFromRow(r), snippet: r['tr'] as String, isTranslation: true));
      }
    }
    return hits;
  }

  /// A random short ayah (for reminders), with its translation when [slug] is set.
  Future<(Ayah, String?)?> randomAyah(Random rnd, String slug, {int maxLength = 220}) async {
    final count = Sqflite.firstIntValue(
            await _db.rawQuery('SELECT COUNT(*) FROM ayahs WHERE length(text) BETWEEN 40 AND ?', [maxLength])) ??
        0;
    if (count == 0) return null;
    final rows = await _db.rawQuery(
        'SELECT * FROM ayahs WHERE length(text) BETWEEN 40 AND ? ORDER BY id LIMIT 1 OFFSET ?',
        [maxLength, rnd.nextInt(count)]);
    if (rows.isEmpty) return null;
    final ayah = _ayahFromRow(rows.first);
    return (ayah, slug.isEmpty ? null : await translation(ayah.ref, slug));
  }

  /// Deterministic "ayah of the day" with no network.
  Future<Ayah> ayahOfTheDay(DateTime day) async {
    const curated = [
      2255, 2286, 3190, 13028, 39053, 94005, 65003, 2152, 29069, 20114, 21087, 3139, 17082, 14007, 2186,
      40060, 8046, 25063, 33041, 49013, 55013, 57004, 59022, 67002, 93005, 112001, 3008, 18010, 23118, 28024,
    ];
    final code = curated[(day.year * 372 + day.month * 31 + day.day) % curated.length];
    return ayah(AyahRef(code ~/ 1000, code % 1000));
  }
}
