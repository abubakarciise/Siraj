import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../l10n/l10n.dart';
import '../audio/timing.dart';
import '../catalog/catalog.dart';

enum DlStatus { queued, running, paused, failed }

class ActiveDownload {
  const ActiveDownload(this.recitationKey, this.surah, this.status, this.progress);
  final String recitationKey;
  final int surah;
  final DlStatus status;
  final double progress;

  ActiveDownload copyWith({DlStatus? status, double? progress}) =>
      ActiveDownload(recitationKey, surah, status ?? this.status, progress ?? this.progress);
}

@immutable
class DownloadsState {
  const DownloadsState({this.downloaded = const {}, this.active = const {}});

  /// recitation key -> downloaded surah numbers (disk is the source of truth).
  final Map<String, Set<int>> downloaded;

  /// task id -> in-flight download.
  final Map<String, ActiveDownload> active;

  bool isDownloaded(String key, int surah) => downloaded[key]?.contains(surah) ?? false;
  ActiveDownload? activeFor(String key, int surah) => active[DownloadManager.taskId(key, surah)];
  int downloadedCount(String key) => downloaded[key]?.length ?? 0;
  List<ActiveDownload> activeOf(String key) => active.values.where((a) => a.recitationKey == key).toList();
}

/// Background, resumable audio downloads stored on the user's device.
///
/// Works per surah, for any selection of surahs, for a whole recitation, and
/// for any number of reciters at the same time. Survives app restarts.
class DownloadManager {
  DownloadManager(this._timing);

  final TimingService _timing;
  final _state = StreamController<DownloadsState>.broadcast();
  DownloadsState _current = const DownloadsState();
  late final String _audioRoot;
  final _readIdForKey = <String, int>{};
  StreamSubscription<TaskUpdate>? _sub;

  static const _group = 'audio';
  static String taskId(String key, int surah) => 'a|$key|$surah';

  DownloadsState get state => _current;
  Stream<DownloadsState> get stream => _state.stream;

  Future<void> init() async {
    _audioRoot = p.join((await getApplicationSupportDirectory()).path, 'audio');
    _current = DownloadsState(downloaded: await _scanDisk());
    final fd = FileDownloader();
    await fd.configure(globalConfig: [
      (Config.requestTimeout, const Duration(seconds: 60)),
      (Config.holdingQueue, (3, 3, null)),
    ]);
    fd.configureNotificationForGroup(
      _group,
      // {displayName}, {progress} and {networkSpeed} are filled in by the downloader.
      running: TaskNotification(l10n.downloadingName('{displayName}'), '{progress} · {networkSpeed}'),
      complete: TaskNotification(l10n.readyOfflineTitle, '{displayName}'),
      error: TaskNotification(l10n.downloadFailed, '{displayName}'),
      paused: TaskNotification(l10n.downloadPaused, '{displayName}'),
      progressBar: true,
      groupNotificationId: 'quran-audio',
    );
    _sub = fd.updates.listen(_onUpdate);
    await fd.start(); // trackTasks + resumeFromBackground + reschedule killed tasks

    // Restore in-flight tasks from the downloader's own database.
    final records = await fd.database.allRecords(group: _group);
    final active = <String, ActiveDownload>{};
    for (final r in records) {
      final parts = r.taskId.split('|');
      if (parts.length != 3 || r.status.isFinalState && r.status != TaskStatus.failed) continue;
      final status = switch (r.status) {
        TaskStatus.running => DlStatus.running,
        TaskStatus.paused => DlStatus.paused,
        TaskStatus.failed => DlStatus.failed,
        _ => DlStatus.queued,
      };
      active[r.taskId] = ActiveDownload(parts[1], int.parse(parts[2]), status, r.progress.clamp(0, 1));
    }
    _emit(DownloadsState(downloaded: _current.downloaded, active: active));
  }

  Future<void> dispose() async => _sub?.cancel();

  String localPath(String key, int surah) => p.join(_audioRoot, key, '${surah.toString().padLeft(3, '0')}.mp3');

  File? localFile(String key, int surah) {
    if (!_current.isDownloaded(key, surah)) return null;
    final f = File(localPath(key, surah));
    return f.existsSync() ? f : null;
  }

  /// Enqueue [surahs] of [r]; surahs already downloaded or in progress are skipped.
  Future<int> download(Recitation r, Iterable<int> surahs, {required String reciterName, bool wifiOnly = false}) async {
    final todo = [
      for (final s in surahs)
        if (r.hasSurah(s) && !_current.isDownloaded(r.key, s) && _current.activeFor(r.key, s)?.status != DlStatus.running) s,
    ];
    if (todo.isEmpty) return 0;
    if (r.timingReadId != null) _readIdForKey[r.key] = r.timingReadId!;
    final tasks = [
      for (final s in todo)
        DownloadTask(
          taskId: taskId(r.key, s),
          url: r.urlFor(s),
          baseDirectory: BaseDirectory.applicationSupport,
          directory: 'audio/${r.key}',
          filename: '${s.toString().padLeft(3, '0')}.mp3',
          group: _group,
          updates: Updates.statusAndProgress,
          requiresWiFi: wifiOnly,
          retries: 5,
          allowPause: true,
          priority: 0, // user initiated -> UIDT on Android 14+
          displayName: l10n.surahAndReciter(s, reciterName),
          metaData: '${r.timingReadId ?? ''}',
        ),
    ];
    final active = Map.of(_current.active);
    for (final t in tasks) {
      active[t.taskId] = ActiveDownload(r.key, int.parse(t.taskId.split('|')[2]), DlStatus.queued, 0);
    }
    _emit(DownloadsState(downloaded: _current.downloaded, active: active)); // instant "queued" feedback
    await _ensureNotificationPermission();
    await FileDownloader().enqueueAll(tasks);
    return tasks.length;
  }

  /// Asked once, in context (on the first download), so progress shows in the
  /// notification shade on Android 13+ and iOS. Downloads work either way.
  Future<void> _ensureNotificationPermission() async {
    final perms = FileDownloader().permissions;
    if (await perms.status(PermissionType.notifications) != PermissionStatus.granted) {
      await perms.request(PermissionType.notifications);
    }
  }

  Future<void> cancel(String key, int surah) => FileDownloader().cancelTasksWithIds([taskId(key, surah)]);

  Future<void> cancelAll(String key) async {
    final ids = _current.active.keys.where((id) => id.startsWith('a|$key|')).toList();
    await FileDownloader().cancelTasksWithIds(ids);
    final active = Map.of(_current.active)..removeWhere((id, _) => ids.contains(id));
    _emit(DownloadsState(downloaded: _current.downloaded, active: active));
  }

  Future<void> retry(Recitation r, {required String reciterName}) async {
    final failed = _current.active.values
        .where((a) => a.recitationKey == r.key && a.status == DlStatus.failed)
        .map((a) => a.surah)
        .toList();
    await download(r, failed, reciterName: reciterName);
  }

  Future<void> delete(String key, int surah) async {
    final f = File(localPath(key, surah));
    if (f.existsSync()) await f.delete();
    final downloaded = _copyDownloaded()..[key]?.remove(surah);
    _emit(DownloadsState(downloaded: downloaded, active: _current.active));
  }

  Future<void> deleteRecitation(String key) async {
    await cancelAll(key);
    final dir = Directory(p.join(_audioRoot, key));
    if (dir.existsSync()) await dir.delete(recursive: true);
    final downloaded = _copyDownloaded()..remove(key);
    _emit(DownloadsState(downloaded: downloaded, active: _current.active));
  }

  final _sizeCache = <String, int>{}; // "key|surah" -> bytes

  /// Exact download size of [surahs] (HEAD requests over one kept-alive
  /// connection, 40 at a time; sizes are remembered), or null offline.
  /// [progress] gets (checked, total) as answers arrive.
  Future<int?> estimateBytes(Recitation r, List<int> surahs, {void Function(int done, int total)? progress}) async {
    final todo = surahs.where((s) => r.hasSurah(s) && !_current.isDownloaded(r.key, s)).toList();
    var total = 0, done = 0;
    final client = http.Client();
    try {
      for (var i = 0; i < todo.length; i += 40) {
        final sizes = await Future.wait(todo.skip(i).take(40).map((s) async {
          final key = '${r.key}|$s';
          final known = _sizeCache[key];
          if (known != null) return known;
          final res = await client.head(Uri.parse(r.urlFor(s))).timeout(const Duration(seconds: 10));
          final n = int.tryParse(res.headers['content-length'] ?? '') ?? 0;
          if (n > 0) _sizeCache[key] = n;
          progress?.call(++done, todo.length);
          return n;
        }));
        total += sizes.fold(0, (a, b) => a + b);
      }
      return total;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  /// Bytes on disk per recitation key.
  Future<Map<String, int>> sizes() async {
    final out = <String, int>{};
    final root = Directory(_audioRoot);
    if (!root.existsSync()) return out;
    await for (final dir in root.list()) {
      if (dir is! Directory) continue;
      var total = 0;
      await for (final f in dir.list()) {
        if (f is File) total += await f.length();
      }
      out[p.basename(dir.path)] = total;
    }
    return out;
  }

  void _onUpdate(TaskUpdate u) {
    final parts = u.task.taskId.split('|');
    if (parts.length != 3 || parts[0] != 'a') return;
    final key = parts[1];
    final surah = int.parse(parts[2]);
    final active = Map.of(_current.active);
    final prev = active[u.task.taskId] ?? ActiveDownload(key, surah, DlStatus.queued, 0);
    switch (u) {
      case TaskProgressUpdate(:final progress):
        if (progress >= 0 && progress <= 1) {
          active[u.task.taskId] = prev.copyWith(status: DlStatus.running, progress: progress);
          _emit(DownloadsState(downloaded: _current.downloaded, active: active));
        }
      case TaskStatusUpdate(:final status):
        switch (status) {
          case TaskStatus.complete:
            active.remove(u.task.taskId);
            final downloaded = _copyDownloaded();
            (downloaded[key] ??= {}).add(surah);
            _emit(DownloadsState(downloaded: downloaded, active: active));
            // Keep highlighting offline: fetch this surah's timing alongside the audio.
            final readId = int.tryParse(u.task.metaData) ?? _readIdForKey[key];
            if (readId != null) unawaited(_timing.get(readId, surah));
          case TaskStatus.canceled:
          case TaskStatus.notFound:
            active.remove(u.task.taskId);
            _emit(DownloadsState(downloaded: _current.downloaded, active: active));
          case TaskStatus.failed:
            active[u.task.taskId] = prev.copyWith(status: DlStatus.failed);
            _emit(DownloadsState(downloaded: _current.downloaded, active: active));
          case TaskStatus.paused:
            active[u.task.taskId] = prev.copyWith(status: DlStatus.paused);
            _emit(DownloadsState(downloaded: _current.downloaded, active: active));
          case TaskStatus.running:
            active[u.task.taskId] = prev.copyWith(status: DlStatus.running);
            _emit(DownloadsState(downloaded: _current.downloaded, active: active));
          case TaskStatus.enqueued:
          case TaskStatus.waitingToRetry:
            active[u.task.taskId] = prev.copyWith(status: DlStatus.queued);
            _emit(DownloadsState(downloaded: _current.downloaded, active: active));
        }
    }
  }

  Future<Map<String, Set<int>>> _scanDisk() async {
    final out = <String, Set<int>>{};
    final root = Directory(_audioRoot);
    if (!root.existsSync()) return out;
    await for (final dir in root.list()) {
      if (dir is! Directory) continue;
      final set = <int>{};
      await for (final f in dir.list()) {
        final n = int.tryParse(p.basenameWithoutExtension(f.path));
        if (f is File && n != null && f.path.endsWith('.mp3') && await f.length() > 0) set.add(n);
      }
      if (set.isNotEmpty) out[p.basename(dir.path)] = set;
    }
    return out;
  }

  Map<String, Set<int>> _copyDownloaded() => {for (final e in _current.downloaded.entries) e.key: {...e.value}};

  void _emit(DownloadsState s) {
    _current = s;
    _state.add(s);
  }
}
