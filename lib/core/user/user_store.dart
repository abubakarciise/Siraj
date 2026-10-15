import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../quran/models.dart';

class Bookmark {
  const Bookmark({required this.id, required this.ref, required this.page, required this.color, required this.createdAt});
  final int id;
  final AyahRef ref;
  final int page;
  final int color;
  final DateTime createdAt;
}

class LastRead {
  const LastRead(this.page, this.ref, this.at);
  final int page;
  final AyahRef ref;
  final DateTime at;
}

class ListeningState {
  const ListeningState({required this.recitationKey, required this.surah, required this.positionMs, required this.at});
  final String recitationKey;
  final int surah, positionMs;
  final DateTime at;
}

/// The user's own data (bookmarks, history, favorites), stored on-device only.
class UserStore {
  UserStore._(this._db);
  final Database _db;

  static Future<UserStore> open() async {
    final dir = await getApplicationSupportDirectory();
    final db = await openDatabase(
      p.join(dir.path, 'user.db'),
      version: 1,
      onCreate: (db, _) async {
        final b = db.batch()
          ..execute('CREATE TABLE bookmarks(id INTEGER PRIMARY KEY AUTOINCREMENT, surah INTEGER, ayah INTEGER, '
              'page INTEGER, color INTEGER, created_at INTEGER, UNIQUE(surah, ayah))')
          ..execute('CREATE TABLE reading_history(id INTEGER PRIMARY KEY AUTOINCREMENT, page INTEGER, surah INTEGER, '
              'ayah INTEGER, at INTEGER)')
          ..execute('CREATE TABLE listening_state(recitation TEXT, surah INTEGER, position_ms INTEGER, at INTEGER, '
              'PRIMARY KEY(recitation, surah))')
          ..execute('CREATE TABLE favorites(reciter_id INTEGER PRIMARY KEY, at INTEGER)');
        await b.commit(noResult: true);
      },
    );
    return UserStore._(db);
  }

  // ---- Bookmarks ----
  Future<List<Bookmark>> bookmarks() async => [
        for (final r in await _db.query('bookmarks', orderBy: 'created_at DESC'))
          Bookmark(
            id: r['id'] as int,
            ref: AyahRef(r['surah'] as int, r['ayah'] as int),
            page: r['page'] as int,
            color: r['color'] as int,
            createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
          ),
      ];

  Future<void> addBookmark(AyahRef ref, int page, {int color = 0}) => _db.insert(
        'bookmarks',
        {'surah': ref.surah, 'ayah': ref.ayah, 'page': page, 'color': color, 'created_at': _now()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> removeBookmark(AyahRef ref) =>
      _db.delete('bookmarks', where: 'surah = ? AND ayah = ?', whereArgs: [ref.surah, ref.ayah]);

  // ---- Reading history ----
  Future<void> recordRead(int page, AyahRef ref) async {
    final last = await lastRead();
    if (last != null && last.page == page) {
      await _db.update('reading_history', {'at': _now(), 'surah': ref.surah, 'ayah': ref.ayah},
          where: 'id = (SELECT MAX(id) FROM reading_history)');
      return;
    }
    await _db.insert('reading_history', {'page': page, 'surah': ref.surah, 'ayah': ref.ayah, 'at': _now()});
  }

  Future<LastRead?> lastRead() async {
    final rows = await _db.query('reading_history', orderBy: 'id DESC', limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return LastRead(r['page'] as int, AyahRef(r['surah'] as int, r['ayah'] as int),
        DateTime.fromMillisecondsSinceEpoch(r['at'] as int));
  }

  /// Distinct pages read per day, used for streak-free, private progress.
  Future<int> pagesReadOn(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final end = start + const Duration(days: 1).inMilliseconds;
    final r = await _db.rawQuery(
        'SELECT COUNT(DISTINCT page) AS n FROM reading_history WHERE at >= ? AND at < ?', [start, end]);
    return r.first['n'] as int;
  }

  // ---- Listening ----
  Future<void> saveListening(String recitation, int surah, int positionMs) => _db.insert(
        'listening_state',
        {'recitation': recitation, 'surah': surah, 'position_ms': positionMs, 'at': _now()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<ListeningState?> lastListening() async {
    final rows = await _db.query('listening_state', orderBy: 'at DESC', limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return ListeningState(
      recitationKey: r['recitation'] as String,
      surah: r['surah'] as int,
      positionMs: r['position_ms'] as int,
      at: DateTime.fromMillisecondsSinceEpoch(r['at'] as int),
    );
  }

  Future<int> savedPosition(String recitation, int surah) async {
    final rows = await _db.query('listening_state',
        where: 'recitation = ? AND surah = ?', whereArgs: [recitation, surah], limit: 1);
    return rows.isEmpty ? 0 : rows.first['position_ms'] as int;
  }

  // ---- Favorites ----
  Future<Set<int>> favorites() async =>
      {for (final r in await _db.query('favorites')) r['reciter_id'] as int};

  Future<void> setFavorite(int reciterId, bool fav) => fav
      ? _db.insert('favorites', {'reciter_id': reciterId, 'at': _now()}, conflictAlgorithm: ConflictAlgorithm.replace)
      : _db.delete('favorites', where: 'reciter_id = ?', whereArgs: [reciterId]);

  static int _now() => DateTime.now().millisecondsSinceEpoch;
}
