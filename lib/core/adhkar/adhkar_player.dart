import 'dart:async';
import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/audio_handler.dart';
import 'adhkar.dart';

/// Plays a category of adhkar one after another from the recordings bundled
/// with the app (no internet needed), through the same media session as the
/// Quran, so it has its own notification and lock-screen controls.
///
/// Each dhikr repeats as many times as it is prescribed (up to [kListenCap];
/// the listener finishes a hundred-times dhikr by tapping), or once if the
/// listener prefers; each recitation counts one down on the screen. A dhikr without a recording is the listener's turn:
/// playback waits until they have counted it on screen, then continues.
class AdhkarPlayer extends ChangeNotifier implements ExternalPlayback {
  AdhkarPlayer({required this.handler, this.beforeStart, this.onCompleted, this.prefs, this.scopeOf});

  /// A category was counted to the end today (saved as done).
  final void Function(AdhkarCategory category)? onCompleted;

  /// Where progress is kept, so reading and listening continue where they
  /// stopped, even after the app was closed.
  final SharedPreferences? prefs;

  /// How long a category's count lasts: today, or (after prayer) this prayer.
  final String Function(String categoryId)? scopeOf;

  // ---- Counters: how many recitations are left, per category ----
  final _counts = <String, Map<int, int>>{};
  final _scopes = <String, String>{};

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Map<int, int> _of(String id) {
    final scope = scopeOf?.call(id) ?? _today();
    if (_scopes[id] != scope) {
      _scopes[id] = scope;
      _counts[id] = _load(id, scope);
    }
    return _counts[id]!;
  }

  Map<int, int> _load(String id, String scope) {
    try {
      final raw = prefs?.getString('adhkar_progress_$id');
      if (raw == null) return {};
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['scope'] != scope) return {};
      return {for (final e in (j['left'] as Map<String, dynamic>).entries) int.parse(e.key): e.value as int};
    } catch (_) {
      return {};
    }
  }

  void _save(String id) => prefs?.setString(
        'adhkar_progress_$id',
        jsonEncode({
          'scope': _scopes[id],
          'left': {for (final e in _of(id).entries) '${e.key}': e.value},
        }),
      );

  /// (recitations counted, all recitations) of [cat] in its current scope.
  (int, int) progress(AdhkarCategory cat) {
    final total = cat.totalCount;
    final remaining = List.generate(cat.items.length, (i) => left(cat, i)).fold(0, (a, b) => a + b);
    return (total - remaining, total);
  }

  int left(AdhkarCategory cat, int i) => _of(cat.id)[i] ?? cat.items[i].count;

  bool allDone(AdhkarCategory cat) => List.generate(cat.items.length, (i) => left(cat, i)).every((n) => n == 0);

  /// Counts one recitation of dhikr [i]; false when it was already done.
  bool countOne(AdhkarCategory cat, int i) {
    final l = left(cat, i);
    if (l == 0) return false;
    _of(cat.id)[i] = l - 1;
    _save(cat.id);
    if (l == 1 && allDone(cat)) onCompleted?.call(cat);
    notifyListeners();
    return true;
  }

  /// Starts the category's count again.
  void reset(AdhkarCategory cat) {
    _of(cat.id).clear();
    _save(cat.id);
    notifyListeners();
  }

  final QuranAudioHandler handler;

  /// Stops the Quran player before adhkar start.
  final Future<void> Function()? beforeStart;

  int _session = 0;
  Completer<void>? _turn;
  Completer<void>? _resumed;

  AdhkarCategory? category;
  int index = 0;

  /// Recitations finished for the current dhikr in this session.
  int repetition = 0;
  int repetitions = 0;
  bool playing = false;

  /// The current dhikr has no recording: waiting for the listener to read it.
  bool waitingForReader = false;

  /// Recite each dhikr once instead of its prescribed count ("Once each");
  /// the listener's choice, remembered.
  late bool once = prefs?.getBool('adhkar_listen_once') ?? false;

  void Function(Object error)? onError;

  AudioPlayer get _p => handler.player;

  bool isActive(String categoryId) => category?.id == categoryId;

  /// Starts listening at dhikr [from] (the first one not yet counted when null).
  Future<void> start(AdhkarCategory cat, [int? from]) async {
    if (from == null) {
      from = List.generate(cat.items.length, (i) => i).firstWhere((i) => left(cat, i) > 0, orElse: () => -1);
      if (from < 0) {
        reset(cat); // everything was counted: listen again from the start
        from = 0;
      }
    }
    final session = ++_session;
    if (category == null) await beforeStart?.call();
    await _stopOutput();
    if (session != _session) return;
    handler.external = this;
    category = cat;
    index = from.clamp(0, cat.items.length - 1);
    playing = true;
    _publish();
    notifyListeners();
    unawaited(_run(session));
  }

  @override
  Future<void> play() => resume();

  @override
  Future<void> pause() async {
    if (!playing) return;
    playing = false;
    notifyListeners();
    if (!waitingForReader) await _p.pause();
  }

  Future<void> resume() async {
    final cat = category;
    if (cat == null || playing) return;
    playing = true;
    notifyListeners();
    final r = _resumed;
    if (r != null && !r.isCompleted) {
      r.complete();
    } else if (!waitingForReader) {
      await _p.play();
    }
  }

  @override
  Future<void> next() => skip(1);

  @override
  Future<void> previous() => skip(-1);

  /// Plays [i] now (the listener tapped another card).
  Future<void> jumpTo(int i) async {
    final cat = category;
    if (cat == null) return;
    await start(cat, i);
  }

  Future<void> skip(int delta) async {
    final cat = category;
    if (cat == null) return;
    await jumpTo((index + delta).clamp(0, cat.items.length - 1));
  }

  /// The listener counted the current dhikr themselves: carry on with what is
  /// left of it, or with the next dhikr when it is done.
  Future<void> counted() async {
    final cat = category;
    if (cat == null) return;
    final turn = _turn;
    if (turn != null && !turn.isCompleted) {
      if (left(cat, index) == 0) turn.complete();
      return;
    }
    if (left(cat, index) == 0 && index == cat.items.length - 1) {
      await stop();
      return;
    }
    await start(cat, left(cat, index) == 0 ? index + 1 : index);
  }

  @override
  Future<void> stop() async {
    _session++;
    playing = false;
    category = null;
    notifyListeners();
    _release();
    if (identical(handler.external, this)) handler.external = null;
    await handler.endSession();
  }

  void setOnce(bool v) {
    once = v;
    prefs?.setBool('adhkar_listen_once', v);
    notifyListeners();
  }

  void _release() {
    for (final c in [_turn, _resumed]) {
      if (c != null && !c.isCompleted) c.complete();
    }
    _turn = null;
    _resumed = null;
    waitingForReader = false;
  }

  Future<void> _stopOutput() async {
    _release();
    await _p.stop();
  }

  /// What the notification and lock screen show.
  void _publish() {
    final cat = category;
    if (cat == null) return;
    final count = repetitions > 1 ? ' · ${(repetition + 1).clamp(1, repetitions)}/$repetitions' : '';
    handler.mediaItem.add(MediaItem(
      id: 'adhkar:${cat.id}:$index',
      title: '${cat.titleEn} · ${cat.titleAr}',
      artist: waitingForReader ? 'Dhikr ${index + 1} of ${cat.items.length} · your turn' : 'Dhikr ${index + 1} of ${cat.items.length}$count',
      album: 'Adhkar',
    ));
  }

  /// Waits while paused; false when the session ended meanwhile.
  Future<bool> _whilePaused(int session) async {
    while (!playing && session == _session) {
      final r = _resumed = Completer<void>();
      await r.future;
    }
    return session == _session;
  }

  Future<void> _run(int session) async {
    final cat = category!;
    try {
      while (session == _session && index < cat.items.length) {
        final d = cat.items[index];
        final remaining = left(cat, index);
        // What the cap leaves of a long count stays on the card to tap.
        final played = d.count - remaining;
        final times = once ? (remaining > 0 ? 1 : 0) : (d.listenTimes - played).clamp(0, remaining);
        repetitions = times;
        repetition = 0;
        if (d.audioFile == null) {
          if (remaining > 0) {
            // No recording: the listener reads this one and taps to count it.
            waitingForReader = true;
            _publish();
            notifyListeners();
            final turn = _turn = Completer<void>();
            await turn.future;
            waitingForReader = false;
            if (session != _session) return;
          }
        } else {
          for (var r = 0; r < times; r++) {
            if (!await _whilePaused(session)) return;
            _publish();
            notifyListeners();
            await _p.setAudioSource(AudioSource.asset('assets/adhkar/audio/${d.audioFile}'));
            if (session != _session) return;
            if (playing) unawaited(_p.play()); // paused meanwhile: resume() starts it
            await _p.processingStateStream.firstWhere(
              (s) => s == ProcessingState.completed || session != _session,
            );
            if (session != _session) return;
            repetition = r + 1;
            countOne(cat, index);
            await Future<void>.delayed(Duration(milliseconds: r < times - 1 ? 450 : 1000));
          }
        }
        if (session != _session) return;
        if (index + 1 >= cat.items.length) break;
        index++;
        notifyListeners();
      }
      if (session == _session) await stop();
    } catch (e) {
      debugPrint('Adhkar audio: $e');
      if (session == _session) {
        playing = false;
        waitingForReader = false;
        notifyListeners();
        onError?.call(e);
      }
    }
  }
}
