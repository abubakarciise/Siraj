import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../audio/speech.dart';
import 'adhkar.dart';

/// Recordings are small (tens to hundreds of KB): kept after the first listen
/// so adhkar keep working offline. Downloads run one at a time in the
/// background; playback never waits for them (it streams meanwhile).
class AudioFileCache {
  AudioFileCache(this.folder);
  final String folder;
  Directory? _directory;
  Future<void> _queue = Future.value();
  final _queued = <String>{};

  Future<Directory> _dir() async {
    if (_directory != null) return _directory!;
    final d = Directory(p.join((await getApplicationSupportDirectory()).path, folder));
    if (!d.existsSync()) await d.create(recursive: true);
    return _directory = d;
  }

  static String _name(String url) {
    var h = 0x811c9dc5;
    for (final c in url.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0xffffffff;
    }
    return '${h.toRadixString(36)}${p.extension(Uri.parse(url).path)}';
  }

  /// The saved file, or null when it has not been downloaded yet.
  Future<File?> cached(String url) async {
    final file = File(p.join((await _dir()).path, _name(url)));
    return file.existsSync() && file.lengthSync() > 0 ? file : null;
  }

  /// Saves [url] for offline use, after the downloads already queued.
  void save(String url) {
    if (!_queued.add(url)) return;
    _queue = _queue.then((_) => _download(url)).catchError((Object e) {
      debugPrint('Adhkar audio download $url: $e');
      _queued.remove(url);
    });
  }

  Future<void> _download(String url) async {
    if (await cached(url) != null) return;
    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
    final file = File(p.join((await _dir()).path, _name(url)));
    final tmp = File('${file.path}.part');
    await tmp.writeAsBytes(res.bodyBytes, flush: true);
    await tmp.rename(file.path);
  }
}

class AdhkarOfflineException implements Exception {
  const AdhkarOfflineException();
  @override
  String toString() => 'Connect to the internet once to download these recitations.';
}

/// Plays a category of adhkar one after another. Each dhikr is repeated as
/// many times as it is prescribed (or once, if the listener prefers), and
/// [onRepetition] tells the screen to count one down after each recitation.
class AdhkarPlayer extends ChangeNotifier {
  AdhkarPlayer(this._speech, {this.beforeStart});

  final Speech _speech;

  /// Pauses other audio (the Quran player) before adhkar start.
  final Future<void> Function()? beforeStart;

  final _cache = AudioFileCache('adhkar_audio');
  AudioPlayer? _player;
  int _session = 0;

  AdhkarCategory? category;
  int index = 0;

  /// Recitations finished for the current dhikr in this session.
  int repetition = 0;
  int repetitions = 0;
  bool playing = false;
  bool loading = false;

  /// Recite each dhikr once instead of its prescribed count.
  bool once = false;

  void Function(int index)? onRepetition;
  void Function(Object error)? onError;
  int Function(int index)? _remaining;

  AudioPlayer get _p => _player ??= AudioPlayer();

  static const _exact = ProgressiveAudioSourceOptions(
    androidExtractorOptions: AndroidExtractorOptions(
      constantBitrateSeekingEnabled: false,
      mp3Flags: AndroidExtractorOptions.flagMp3EnableIndexSeeking,
    ),
  );

  bool isActive(String categoryId) => category?.id == categoryId && (playing || loading);

  /// Starts at [from]; [remaining] gives how many recitations are left for a dhikr.
  Future<void> start(AdhkarCategory cat, int from, {required int Function(int index) remaining}) async {
    await beforeStart?.call();
    final session = ++_session;
    await _stopOutput();
    category = cat;
    index = from;
    _remaining = remaining;
    playing = true;
    notifyListeners();
    unawaited(_run(session));
  }

  Future<void> pause() async {
    _session++;
    playing = false;
    loading = false;
    notifyListeners();
    await _stopOutput();
  }

  Future<void> resume() async {
    final cat = category, rem = _remaining;
    if (cat == null || rem == null) return;
    await start(cat, index, remaining: rem);
  }

  Future<void> skip(int delta) async {
    final cat = category, rem = _remaining;
    if (cat == null || rem == null) return;
    final next = (index + delta).clamp(0, cat.items.length - 1);
    if (playing) {
      await start(cat, next, remaining: rem);
    } else {
      index = next;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _session++;
    playing = false;
    loading = false;
    category = null;
    notifyListeners();
    await _stopOutput();
  }

  void setOnce(bool v) {
    once = v;
    notifyListeners();
  }

  Future<void> _stopOutput() async {
    await _speech.stop();
    await _player?.stop();
  }

  Future<void> _run(int session) async {
    final cat = category!;
    try {
      while (session == _session && index < cat.items.length) {
        final d = cat.items[index];
        final left = _remaining!(index);
        final times = once ? (left > 0 ? 1 : 0) : left;
        repetitions = times;
        repetition = 0;
        notifyListeners();
        _prefetch(cat, index + 1);
        for (var r = 0; r < times; r++) {
          if (session != _session) return;
          final ok = await _reciteOnce(d, session);
          if (!ok || session != _session) return;
          repetition = r + 1;
          onRepetition?.call(index);
          notifyListeners();
          await Future<void>.delayed(Duration(milliseconds: r < times - 1 ? 450 : 1000));
        }
        if (session != _session) return;
        if (index + 1 >= cat.items.length) break;
        index++;
        notifyListeners();
      }
      if (session == _session) {
        playing = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Adhkar audio: $e');
      if (session == _session) {
        playing = false;
        loading = false;
        notifyListeners();
        onError?.call(e is SocketException || e is TimeoutException || e is http.ClientException || e is PlayerException
            ? const AdhkarOfflineException()
            : e);
      }
    }
  }

  /// Saves the next dhikr's recording while this one plays.
  void _prefetch(AdhkarCategory cat, int next) {
    if (next >= cat.items.length) return;
    for (final part in cat.items[next].audio ?? const <AudioPart>[]) {
      _cache.save(part.url);
    }
  }

  /// One recitation of [d]: its recording, or the phone's voice when there is none.
  Future<bool> _reciteOnce(Dhikr d, int session) async {
    final parts = d.audio;
    if (parts == null || parts.isEmpty) {
      if (!await _speech.hasArabic()) return true; // nothing to play: move on
      try {
        await _speech.speak(d.text.replaceAll(RegExp(r'\[[^\]]*\]'), ''));
      } on SpeechException catch (e) {
        debugPrint('Adhkar voice: $e'); // the voice failed: move on to the next recording
      }
      return session == _session;
    }
    for (final part in parts) {
      loading = true;
      notifyListeners();
      final file = await _cache.cached(part.url);
      if (file == null) _cache.save(part.url);
      if (session != _session) return false;
      // Saved: play the file. Not yet: stream it while it is being saved.
      final child = ProgressiveAudioSource(file != null ? Uri.file(file.path) : Uri.parse(part.url), options: _exact);
      await _p.setAudioSource(
        part.start == null ? child : ClippingAudioSource(child: child, start: part.start, end: part.end),
      );
      loading = false;
      notifyListeners();
      if (session != _session) return false;
      unawaited(_p.play());
      await _p.processingStateStream.firstWhere(
        (s) => s == ProcessingState.completed || session != _session,
      );
      if (session != _session) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }
}
