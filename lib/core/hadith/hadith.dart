import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../l10n/l10n.dart';
import '../quran/arabic.dart';

class HadithBook {
  const HadithBook({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.author,
    required this.count,
    required this.bundled,
    required this.available,
  });

  final String id, nameEn, nameAr, author;
  final int count;

  /// Ships inside the app (the 40-hadith collections).
  final bool bundled;

  /// Readable offline right now (bundled or downloaded).
  final bool available;
}

class HadithSection {
  const HadithSection(this.book, this.number, this.title, this.count, this.first);
  final String book;
  final int number, count;
  final String title;
  final num? first;
}

class HadithGrade {
  const HadithGrade(this.by, this.grade);
  final String by, grade;
}

class Hadith {
  const Hadith({
    required this.book,
    required this.number,
    required this.section,
    required this.arabic,
    required this.english,
    this.grades = const [],
  });

  final String book;
  final num number;
  final int section;
  final String arabic, english;
  final List<HadithGrade> grades;

  /// "402" or "402.2" (a few collections number sub-narrations).
  String get numberLabel => number == number.truncate() ? '${number.toInt()}' : '$number';

  String get key => '$book:$numberLabel';

  /// English text with "Narrated X:" split off.
  (String?, String) get narratorAndBody {
    final m = RegExp(r'^((?:Narrated|On the authority of) [^:]{2,90}:|.{0,90}? (?:narrated|reported)(?: that)?\s*:)\s*')
        .firstMatch(english);
    if (m == null) return (null, english);
    return (m.group(1)!.replaceAll(RegExp(r'\s*:$'), ''), english.substring(m.end));
  }

  static List<HadithGrade> parseGrades(String? json) => json == null
      ? const []
      : [for (final g in jsonDecode(json) as List) HadithGrade(g['by'] as String, g['grade'] as String)];
}

/// A curated Sunnah practice with its source hadith (assets/hadith/sunnah.json).
class SunnahItem {
  const SunnahItem({
    required this.title,
    required this.tags,
    required this.book,
    required this.number,
    required this.english,
    required this.arabic,
    required this.grade,
  });

  final String title, book, english, arabic;
  final num number;
  final Set<String> tags;
  final String? grade;
}

enum HadithDlStage { downloading, saving, done, failed }

class HadithDownload {
  const HadithDownload(this.book, this.stage, this.progress, [this.error]);
  final String book;
  final HadithDlStage stage;
  final double progress;
  final String? error;
}

/// Hadith collections, stored on the device.
///
/// The catalog and the 40-hadith books ship with the app; the large
/// collections (Bukhari, Muslim, the Sunan, Muwatta) download once from the
/// public-domain hadith-api on jsDelivr and then work offline.
class HadithRepository {
  HadithRepository._(this._db, this.sunnah);

  final Database _db;
  final List<SunnahItem> sunnah;
  final _downloads = StreamController<HadithDownload>.broadcast();
  final _active = <String, HadithDownload>{};

  static const _assetVersion = 2;
  static const _cdn = 'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';

  Stream<HadithDownload> get downloads => _downloads.stream;
  Map<String, HadithDownload> get active => Map.unmodifiable(_active);

  static Future<HadithRepository> open() async {
    final dir = await getApplicationSupportDirectory();
    final db = await openDatabase(
      p.join(dir.path, 'hadith.db'),
      version: 1,
      onCreate: (db, _) async {
        final b = db.batch()
          ..execute('CREATE TABLE books(id TEXT PRIMARY KEY, ord INTEGER, name_en TEXT, name_ar TEXT, author TEXT, '
              'hadith_count INTEGER, bundled INTEGER, downloaded_at INTEGER)')
          ..execute('CREATE TABLE sections(book TEXT, number INTEGER, title TEXT, first REAL, last REAL, '
              'count INTEGER, PRIMARY KEY(book, number))')
          ..execute('CREATE TABLE hadiths(book TEXT, number REAL, section INTEGER, arabic TEXT, english TEXT, '
              'grades TEXT, ar_search TEXT, PRIMARY KEY(book, number))')
          ..execute('CREATE INDEX hadith_section ON hadiths(book, section)')
          ..execute('CREATE TABLE bookmarks(book TEXT, number REAL, at INTEGER, PRIMARY KEY(book, number))');
        await b.commit(noResult: true);
      },
    );
    final prefsVersion = (await db.rawQuery('PRAGMA user_version')).first.values.first as int;
    if (prefsVersion < 100 + _assetVersion) await _importBundled(db, dir.path);
    final raw = jsonDecode(await rootBundle.loadString('assets/hadith/sunnah.json')) as Map<String, dynamic>;
    final sunnah = [
      for (final s in raw['items'] as List)
        SunnahItem(
          title: s['title'] as String,
          tags: {...(s['tags'] as List).cast<String>()},
          book: s['book'] as String,
          number: s['number'] as num,
          english: s['en'] as String,
          arabic: s['ar'] as String,
          grade: (s['grades'] as List).isEmpty ? null : (s['grades'] as List).first['grade'] as String,
        ),
    ];
    return HadithRepository._(db, sunnah);
  }

  /// Copies the catalog and the bundled books from assets/db/hadith.db.
  static Future<void> _importBundled(Database db, String dir) async {
    final tmp = p.join(dir, 'hadith_asset.db');
    final bytes = await rootBundle.load('assets/db/hadith.db');
    await File(tmp).writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes), flush: true);
    final src = await openDatabase(tmp, readOnly: true, singleInstance: false);
    try {
      final books = await src.query('books');
      final sections = await src.query('sections');
      final hadiths = await src.query('hadiths');
      await db.transaction((tx) async {
        final b = tx.batch();
        for (final r in books) {
          b.rawInsert(
            'INSERT INTO books(id, ord, name_en, name_ar, author, hadith_count, bundled) VALUES (?,?,?,?,?,?,?) '
            'ON CONFLICT(id) DO UPDATE SET ord=excluded.ord, name_en=excluded.name_en, name_ar=excluded.name_ar, '
            'author=excluded.author, hadith_count=excluded.hadith_count, bundled=excluded.bundled',
            [r['id'], r['ord'], r['name_en'], r['name_ar'], r['author'], r['hadith_count'], r['bundled']],
          );
        }
        for (final r in sections) {
          b.insert('sections', r, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (final r in hadiths) {
          b.insert('hadiths', {...r, 'ar_search': normalizeArabic(r['arabic'] as String? ?? '')},
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        // Collections no longer in the catalog are removed with their bookmarks.
        final ids = [for (final r in books) r['id']];
        final keep = 'NOT IN (${List.filled(ids.length, '?').join(',')})';
        b.delete('books', where: 'id $keep', whereArgs: ids);
        for (final t in ['sections', 'hadiths', 'bookmarks']) {
          b.delete(t, where: 'book $keep', whereArgs: ids);
        }
        b.execute('PRAGMA user_version = ${100 + _assetVersion}');
        await b.commit(noResult: true);
      });
    } finally {
      await src.close();
      await File(tmp).delete();
    }
  }

  // ---- Reading ----

  Future<List<HadithBook>> books() async => [
        for (final r in await _db.query('books', orderBy: 'ord'))
          HadithBook(
            id: r['id'] as String,
            nameEn: r['name_en'] as String,
            nameAr: r['name_ar'] as String,
            author: r['author'] as String,
            count: r['hadith_count'] as int,
            bundled: r['bundled'] == 1,
            available: r['bundled'] == 1 || r['downloaded_at'] != null,
          ),
      ];

  Future<List<HadithSection>> sections(String book) async => [
        for (final r in await _db.query('sections', where: 'book = ?', whereArgs: [book], orderBy: 'number'))
          HadithSection(book, r['number'] as int, r['title'] as String, r['count'] as int, r['first'] as num?),
      ];

  Hadith _row(Map<String, Object?> r) => Hadith(
        book: r['book'] as String,
        number: r['number'] as num,
        section: r['section'] as int,
        arabic: r['arabic'] as String? ?? '',
        english: r['english'] as String? ?? '',
        grades: Hadith.parseGrades(r['grades'] as String?),
      );

  Future<List<Hadith>> hadiths(String book, {int? section}) async => [
        for (final r in await _db.query('hadiths',
            where: section == null ? 'book = ?' : 'book = ? AND section = ?',
            whereArgs: section == null ? [book] : [book, section],
            orderBy: 'number'))
          _row(r),
      ];

  Future<Hadith?> hadith(String book, num number) async {
    final rows = await _db.query('hadiths', where: 'book = ? AND number = ?', whereArgs: [book, number], limit: 1);
    return rows.isEmpty ? null : _row(rows.first);
  }

  Future<List<Hadith>> search(String query, {String? book}) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final arabic = isArabic(q);
    final where = [arabic ? 'ar_search LIKE ?' : 'english LIKE ?', if (book != null) 'book = ?'].join(' AND ');
    final rows = await _db.query('hadiths',
        where: where,
        whereArgs: [arabic ? '%${normalizeArabic(q)}%' : '%$q%', if (book != null) book],
        orderBy: 'book, number',
        limit: 150);
    return rows.map(_row).toList();
  }

  /// A random, reasonably short hadith from what is available offline.
  Future<Hadith?> random(Random rnd, {int maxLength = 420}) async {
    final count = Sqflite.firstIntValue(
            await _db.rawQuery('SELECT COUNT(*) FROM hadiths WHERE length(english) BETWEEN 40 AND ?', [maxLength])) ??
        0;
    if (count == 0) return null;
    final rows = await _db.rawQuery(
        'SELECT * FROM hadiths WHERE length(english) BETWEEN 40 AND ? LIMIT 1 OFFSET ?', [maxLength, rnd.nextInt(count)]);
    return rows.isEmpty ? null : _row(rows.first);
  }

  /// The same hadith all day, changing daily (from the bundled 40-hadith books).
  Future<Hadith?> ofTheDay(DateTime day) async {
    // Hadith that need a teacher's context are left out of the context-free daily card.
    final rows = await _db.query('hadiths',
        where: "book IN ('nawawi','qudsi') AND NOT (book = 'nawawi' AND number IN (8, 14)) AND length(english) < 900 AND length(arabic) < 800",
        orderBy: 'book, number');
    if (rows.isEmpty) return null;
    final index = (day.year * 372 + day.month * 31 + day.day) % rows.length;
    return _row(rows[index]);
  }

  // ---- Bookmarks ----

  Future<List<Hadith>> bookmarks() async => [
        for (final r in await _db.rawQuery(
            'SELECT h.* FROM bookmarks b JOIN hadiths h ON h.book = b.book AND h.number = b.number ORDER BY b.at DESC'))
          _row(r),
      ];

  Future<bool> isBookmarked(Hadith h) async =>
      (await _db.query('bookmarks', where: 'book = ? AND number = ?', whereArgs: [h.book, h.number])).isNotEmpty;

  Future<void> setBookmark(Hadith h, bool on) => on
      ? _db.insert('bookmarks', {'book': h.book, 'number': h.number, 'at': DateTime.now().millisecondsSinceEpoch},
          conflictAlgorithm: ConflictAlgorithm.replace)
      : _db.delete('bookmarks', where: 'book = ? AND number = ?', whereArgs: [h.book, h.number]);

  // ---- Downloads ----

  /// Downloads Arabic + English text of [book] (~2–10 MB) and stores it.
  Future<void> download(String book) async {
    if (_active.containsKey(book)) return;
    void emit(HadithDownload d) {
      d.stage == HadithDlStage.done || d.stage == HadithDlStage.failed ? _active.remove(book) : _active[book] = d;
      _downloads.add(d);
    }

    emit(HadithDownload(book, HadithDlStage.downloading, 0));
    try {
      final parts = <double>[0, 0];
      void progress(int i, double v) {
        parts[i] = v;
        emit(HadithDownload(book, HadithDlStage.downloading, (parts[0] + parts[1]) / 2));
      }

      final (eng, ara) = await (
        _fetch('eng-$book', (v) => progress(0, v)),
        _fetch('ara-$book', (v) => progress(1, v)),
      ).wait;
      emit(HadithDownload(book, HadithDlStage.saving, 1));
      final rows = await compute(_mergeEditions, (eng, ara));
      await _db.transaction((tx) async {
        await tx.delete('hadiths', where: 'book = ?', whereArgs: [book]);
        var batch = tx.batch();
        for (var i = 0; i < rows.length; i++) {
          batch.insert('hadiths', {'book': book, ...rows[i]});
          if (i % 500 == 499) {
            await batch.commit(noResult: true);
            batch = tx.batch();
          }
        }
        await batch.commit(noResult: true);
        await tx.update('books', {'downloaded_at': DateTime.now().millisecondsSinceEpoch},
            where: 'id = ?', whereArgs: [book]);
      });
      emit(HadithDownload(book, HadithDlStage.done, 1));
    } catch (e) {
      debugPrint('Hadith download $book failed: $e');
      emit(HadithDownload(book, HadithDlStage.failed, 0, l10n.hadithDownloadFailed));
    }
  }

  Future<void> remove(String book) async {
    await _db.transaction((tx) async {
      await tx.delete('hadiths', where: 'book = ?', whereArgs: [book]);
      await tx.delete('bookmarks', where: 'book = ?', whereArgs: [book]);
      await tx.update('books', {'downloaded_at': null}, where: 'id = ?', whereArgs: [book]);
    });
  }

  Future<String> _fetch(String edition, void Function(double) onProgress) async {
    final client = http.Client();
    try {
      for (final suffix in ['.min.json', '.json']) {
        final res = await client.send(http.Request('GET', Uri.parse('$_cdn/$edition$suffix')));
        if (res.statusCode != 200) continue;
        final total = res.contentLength ?? 0;
        final bytes = <int>[];
        await for (final chunk in res.stream.timeout(const Duration(seconds: 30))) {
          bytes.addAll(chunk);
          if (total > 0) onProgress(bytes.length / total);
        }
        onProgress(1);
        return utf8.decode(bytes);
      }
      throw HttpException('Could not download $edition');
    } finally {
      client.close();
    }
  }
}

/// Runs in an isolate: joins the English and Arabic editions by hadith number.
List<Map<String, Object?>> _mergeEditions((String, String) editions) {
  String clean(Object? s) => (s as String? ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  final eng = jsonDecode(editions.$1) as Map<String, dynamic>;
  final ara = jsonDecode(editions.$2) as Map<String, dynamic>;
  final arabic = {for (final h in ara['hadiths'] as List) h['hadithnumber'] as num: clean(h['text'])};
  final rows = <Map<String, Object?>>[];
  for (final h in eng['hadiths'] as List) {
    final n = h['hadithnumber'] as num;
    final en = clean(h['text']), ar = arabic[n] ?? '';
    if (en.isEmpty && ar.isEmpty) continue;
    final grades = [
      for (final g in (h['grades'] as List? ?? const [])) {'by': g['name'], 'grade': g['grade']},
    ];
    rows.add({
      'number': n,
      'section': (h['reference'] as Map)['book'] as int,
      'arabic': ar,
      'english': en,
      'grades': grades.isEmpty ? null : jsonEncode(grades),
      'ar_search': normalizeArabic(ar),
    });
  }
  return rows;
}
