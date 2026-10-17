import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../catalog/catalog.dart';
import '../downloads/download_manager.dart';
import '../quran/models.dart';
import '../quran/quran_db.dart';
import '../user/user_store.dart';
import 'audio_handler.dart';
import 'timing.dart';

enum RepeatKind { off, ayah, surah }

@immutable
class NowPlaying {
  const NowPlaying({
    required this.recitation,
    required this.reciter,
    required this.surah,
    required this.ayah,
    required this.playing,
    required this.buffering,
    required this.position,
    required this.duration,
    required this.speed,
    required this.repeat,
    required this.repeatTimes,
    required this.repeatDone,
    required this.sleepAt,
    required this.hasTiming,
    required this.hasNext,
    required this.hasPrevious,
    this.ayahProgress = 0,
  });

  final Recitation recitation;
  final Reciter reciter;
  final int surah;
  final AyahRef? ayah;
  final bool playing, buffering, hasTiming, hasNext, hasPrevious;
  final Duration position, duration;
  final double speed;
  final RepeatKind repeat;
  final int repeatTimes, repeatDone; // repeatTimes 0 = forever
  final DateTime? sleepAt;

  /// 0..1 progress through the current ayah (drives the live-text auto-scroll).
  final double ayahProgress;
}

/// App-level playback orchestration: queue building (local-first, offline aware),
/// ayah tracking from timing data, ayah repeat (hifz), sleep timer, resume.
class PlayerController {
  PlayerController(this._handler, this._db, this._downloads, this._timing, this._user, {this.artUri}) {
    // Dismissed from the notification: forget what was playing.
    _handler.onStoppedOutside = () {
      _savePosition(force: true);
      _clear();
    };
    final p = _handler.player;
    p.playerStateStream.listen((_) => _emit());
    p.currentIndexStream.listen((_) => _onItemChanged());
    // 20 updates a second, so the ayah highlight switches within a frame or
    // two of the reciter (the default stream ticks only every 200 ms).
    p.createPositionStream(minPeriod: const Duration(milliseconds: 50), maxPeriod: const Duration(milliseconds: 50))
        .listen(_onPosition);
    p.speedStream.listen((_) => _emit());
    p.loopModeStream.listen((_) => _emit());
  }

  final QuranAudioHandler _handler;
  final QuranDb _db;
  final DownloadManager _downloads;
  final TimingService _timing;
  final UserStore _user;

  final _controller = StreamController<NowPlaying?>.broadcast();
  NowPlaying? _now;
  Recitation? _recitation;
  Reciter? _reciter;
  List<int> _surahs = const [];
  SurahTiming? _surahTiming;
  AyahRef? _ayah;
  RepeatKind _repeat = RepeatKind.off;
  int _repeatTimes = 3, _repeatDone = 0;
  AyahRef? _repeatTarget;
  Timer? _sleepTimer;
  DateTime? _sleepAt;
  bool _sleepEndOfSurah = false;
  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);
  Set<String>? _vbr;

  /// Fires only when the playing ayah changes (drives highlight + page follow).
  final currentAyah = ValueNotifier<AyahRef?>(null);

  Stream<NowPlaying?> get stream => _controller.stream;
  NowPlaying? get now => _now;
  AudioPlayer get player => _handler.player;

  int get _currentSurah {
    final i = player.currentIndex ?? 0;
    return i < _surahs.length ? _surahs[i] : (_surahs.isEmpty ? 1 : _surahs.first);
  }

  /// Plays [recitation] from [surah] (optionally from [ayah]) and continues
  /// through the following surahs. Offline, only downloaded surahs are queued.
  Future<void> play(Recitation recitation, Reciter reciter, int surah, {int? ayah, bool resume = false}) async {
    final online = await hasInternet();
    var surahs = recitation.surahs.where((s) => s >= surah).toList();
    if (!online) surahs = surahs.where((s) => _downloads.localFile(recitation.key, s) != null).toList();
    if (surahs.isEmpty) throw const OfflineException();

    _recitation = recitation;
    _reciter = reciter;
    _surahs = surahs;
    _repeatTarget = null;
    _repeatDone = 0;

    Duration? start;
    // Load the ayah timing before the first word plays, so the highlight is
    // exact from the start instead of catching up once the timing arrives.
    final t = recitation.timingReadId == null
        ? null
        : await _timing
            .get(recitation.timingReadId!, surahs.first)
            .timeout(const Duration(seconds: 4), onTimeout: () => null);
    if (ayah != null && ayah > 1 && t != null && surahs.first == surah) {
      final ms = t.startOf(ayah);
      if (ms != null) start = Duration(milliseconds: ms);
    } else if (resume) {
      final ms = await _user.savedPosition(recitation.key, surahs.first);
      if (ms > 5000) start = Duration(milliseconds: ms - 2000);
    }

    // Variable-bitrate files without a seek table: Android would assume a
    // constant bitrate and land seconds off on every seek, so index them instead.
    _vbr ??= await _loadVbr();
    final options = recitation.hasTiming && _vbr!.contains(recitation.server) ? _accurateSeeking : null;
    final art = await artUri?.call();
    final items = <MediaItem>[];
    final sources = <AudioSource>[];
    for (final s in surahs) {
      final info = _db.surah(s);
      final item = MediaItem(
        id: '${recitation.key}|$s',
        title: '${info.nameEn} · ${info.nameAr}',
        artist: reciter.name,
        album: recitation.shortName,
        artUri: art,
        extras: {'key': recitation.key, 'surah': s},
      );
      final local = _downloads.localFile(recitation.key, s);
      items.add(item);
      sources.add(ProgressiveAudioSource(
        local != null ? Uri.file(local.path) : Uri.parse(recitation.urlFor(s)),
        tag: item,
        options: options,
      ));
    }
    await _handler.load(items, sources, position: start);
    await _onItemChanged();
    // Remember it at once (Home's "continue listening" reads this).
    await _savePosition(force: true);
    unawaited(_handler.play());
  }

  static const _accurateSeeking = ProgressiveAudioSourceOptions(
    androidExtractorOptions: AndroidExtractorOptions(
      constantBitrateSeekingEnabled: false,
      mp3Flags: AndroidExtractorOptions.flagMp3EnableIndexSeeking,
    ),
  );

  static Future<Set<String>> _loadVbr() async {
    try {
      return {...(jsonDecode(await rootBundle.loadString('assets/catalog/vbr.json')) as List).cast<String>()};
    } catch (_) {
      return const {};
    }
  }

  /// Player duration, or the end of the last ayah while an indexed VBR stream
  /// has not reported one yet.
  Duration get _duration {
    final d = player.duration;
    if (d != null && d > Duration.zero) return d;
    final t = _surahTiming;
    return t == null || t.ends.isEmpty ? Duration.zero : Duration(milliseconds: t.ends.last + 1500);
  }

  Future<void> toggle() => player.playing ? _handler.pause() : _handler.play();
  Future<void> pause() => _handler.pause();
  Future<void> seek(Duration d) => _handler.seek(d);
  Future<void> next() => _handler.skipToNext();
  Future<void> previous() => _handler.skipToPrevious();

  Future<void> stop() async {
    await _savePosition(force: true);
    _clear();
    await _handler.endSession();
  }

  void _clear() {
    if (_recitation == null) return;
    _recitation = null;
    _now = null;
    currentAyah.value = null;
    cancelSleep();
    _controller.add(null);
  }

  QuranAudioHandler get handler => _handler;

  /// Artwork for the Quran notification.
  final Future<Uri?> Function()? artUri;

  /// Jump to an ayah inside the current surah (needs timing data).
  Future<bool> seekToAyah(int ayah) async {
    final ms = _surahTiming?.startOf(ayah);
    if (ms == null) return false;
    await _handler.seek(Duration(milliseconds: ms));
    return true;
  }

  Future<void> nextAyah() async {
    final a = _ayah;
    if (a == null || !await seekToAyah(a.ayah + 1)) await next();
  }

  Future<void> previousAyah() async {
    final a = _ayah;
    if (a == null || a.ayah <= 1 || !await seekToAyah(a.ayah - 1)) await previous();
  }

  void setRepeat(RepeatKind kind, {int times = 3}) {
    _repeat = kind;
    _repeatTimes = times;
    _repeatDone = 0;
    _repeatTarget = kind == RepeatKind.ayah ? _ayah : null;
    _handler.setRepeatMode(kind == RepeatKind.surah ? AudioServiceRepeatMode.one : AudioServiceRepeatMode.none);
    _emit();
  }

  void setSleep(Duration? d, {bool endOfSurah = false}) {
    cancelSleep();
    _sleepEndOfSurah = endOfSurah;
    if (d != null) {
      _sleepAt = DateTime.now().add(d);
      _sleepTimer = Timer(d, _fadeOutAndPause);
    }
    _emit();
  }

  void cancelSleep() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepAt = null;
    _sleepEndOfSurah = false;
    _emit();
  }

  bool get sleepEndOfSurah => _sleepEndOfSurah;

  Future<void> _fadeOutAndPause() async {
    for (var v = 1.0; v > 0; v -= 0.1) {
      await player.setVolume(v);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    await _handler.pause();
    await player.setVolume(1);
    cancelSleep();
  }

  Future<void> _onItemChanged() async {
    final r = _recitation;
    if (r == null) return;
    final surah = _currentSurah;
    if (_sleepEndOfSurah && _now != null && _now!.surah != surah) {
      _sleepEndOfSurah = false;
      await _handler.pause();
    }
    _ayah = null;
    currentAyah.value = null;
    final readId = r.timingReadId;
    // Prefetched timing is used at once; otherwise it loads while the basmala plays.
    _surahTiming = readId == null ? null : _timing.cached(readId, surah);
    _emit();
    if (readId != null) {
      _surahTiming ??= await _timing.get(readId, surah);
      _onPosition(player.position);
      // The next surah's timing, ready before it starts.
      final i = _surahs.indexOf(surah);
      if (i >= 0 && i + 1 < _surahs.length) _timing.get(readId, _surahs[i + 1]).ignore();
    }
  }

  void _onPosition(Duration pos) {
    final t = _surahTiming;
    if (t != null) {
      final a = t.ayahAt(pos.inMilliseconds);
      final ref = a > 0 ? AyahRef(_currentSurah, a) : null;
      if (ref != _ayah) {
        // Ayah repeat (hifz): loop the target ayah N times before moving on.
        final target = _repeatTarget;
        if (_repeat == RepeatKind.ayah && target != null && _ayah == target && ref != target) {
          if (_repeatTimes == 0 || _repeatDone + 1 < _repeatTimes) {
            _repeatDone++;
            final start = t.startOf(target.ayah);
            if (start != null) {
              _handler.seek(Duration(milliseconds: start));
              _emit();
              return;
            }
          } else {
            _repeatDone = 0;
            _repeatTarget = ref; // continue: repeat the next ayah too
          }
        }
        if (_repeat == RepeatKind.ayah && _repeatTarget == null) _repeatTarget = ref;
        _ayah = ref;
        currentAyah.value = ref;
      }
    }
    _savePosition();
    _emit();
  }

  Future<void> _savePosition({bool force = false}) async {
    final r = _recitation;
    if (r == null) return;
    final now = DateTime.now();
    if (!force && now.difference(_lastSave) < const Duration(seconds: 5)) return;
    _lastSave = now;
    await _user.saveListening(r.key, _currentSurah, player.position.inMilliseconds);
  }

  DateTime _lastEmit = DateTime.fromMillisecondsSinceEpoch(0);

  void _emit() {
    final r = _recitation, rc = _reciter;
    if (r == null || rc == null) return;
    final now = DateTime.now();
    final ps = player.playerState;
    final idx = player.currentIndex ?? 0;
    final next = NowPlaying(
      recitation: r,
      reciter: rc,
      surah: _currentSurah,
      ayah: _ayah,
      playing: ps.playing && ps.processingState != ProcessingState.completed,
      buffering: ps.processingState == ProcessingState.loading || ps.processingState == ProcessingState.buffering,
      position: player.position,
      duration: _duration,
      speed: player.speed,
      repeat: _repeat,
      repeatTimes: _repeatTimes,
      repeatDone: _repeatDone,
      sleepAt: _sleepAt,
      hasTiming: _surahTiming != null,
      hasNext: idx < _surahs.length - 1,
      hasPrevious: idx > 0,
      ayahProgress: _ayahProgress(),
    );
    // Throttle pure position ticks to ~5 fps; state changes go through immediately.
    final prev = _now;
    final onlyPosition = prev != null &&
        prev.playing == next.playing &&
        prev.buffering == next.buffering &&
        prev.surah == next.surah &&
        prev.ayah == next.ayah &&
        prev.speed == next.speed &&
        prev.repeat == next.repeat &&
        prev.repeatDone == next.repeatDone &&
        prev.sleepAt == next.sleepAt &&
        prev.duration == next.duration &&
        prev.hasTiming == next.hasTiming;
    if (onlyPosition && now.difference(_lastEmit) < const Duration(milliseconds: 200)) return;
    _lastEmit = now;
    _now = next;
    _controller.add(next);
  }

  double _ayahProgress() {
    final t = _surahTiming, a = _ayah;
    if (t == null || a == null) return 0;
    final start = t.startOf(a.ayah), end = t.endOf(a.ayah);
    if (start == null || end == null || end <= start) return 0;
    return ((player.position.inMilliseconds - start) / (end - start)).clamp(0.0, 1.0);
  }

  static Future<bool> hasInternet() async {
    try {
      final r = await InternetAddress.lookup('cdn.mp3quran.net').timeout(const Duration(seconds: 3));
      return r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

class OfflineException implements Exception {
  const OfflineException();
  @override
  String toString() => 'No internet connection and nothing downloaded for this reciter.';
}
