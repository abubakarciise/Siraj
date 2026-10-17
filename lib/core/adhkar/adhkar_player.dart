import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../audio/audio_handler.dart';
import 'adhkar.dart';

/// Plays a category of adhkar one after another from the recordings bundled
/// with the app (no internet needed), through the same media session as the
/// Quran, so it has its own notification and lock-screen controls.
///
/// Each dhikr repeats as many times as it is prescribed, or once if the
/// listener prefers; [onRepetition] tells the screen to count one down after
/// each recitation. A dhikr without a recording is the listener's turn:
/// playback waits until they have counted it on screen, then continues.
class AdhkarPlayer extends ChangeNotifier implements ExternalPlayback {
  AdhkarPlayer({required this.handler, this.beforeStart, this.artUri});

  final QuranAudioHandler handler;

  /// Stops the Quran player before adhkar start.
  final Future<void> Function()? beforeStart;

  /// Artwork shown in the notification for adhkar.
  final Future<Uri?> Function()? artUri;

  int _session = 0;
  Completer<void>? _turn;
  Completer<void>? _resumed;
  Uri? _art;

  AdhkarCategory? category;
  int index = 0;

  /// Recitations finished for the current dhikr in this session.
  int repetition = 0;
  int repetitions = 0;
  bool playing = false;

  /// The current dhikr has no recording: waiting for the listener to read it.
  bool waitingForReader = false;

  /// Recite each dhikr once instead of its prescribed count.
  bool once = false;

  void Function(int index)? onRepetition;
  void Function(Object error)? onError;
  int Function(int index)? _remaining;

  AudioPlayer get _p => handler.player;

  bool isActive(String categoryId) => category?.id == categoryId;

  /// Starts at [from]; [remaining] gives how many recitations are left for a dhikr.
  Future<void> start(AdhkarCategory cat, int from, {required int Function(int index) remaining}) async {
    final session = ++_session;
    if (category == null) await beforeStart?.call();
    _art ??= await artUri?.call();
    await _stopOutput();
    if (session != _session) return;
    handler.external = this;
    category = cat;
    index = from.clamp(0, cat.items.length - 1);
    _remaining = remaining;
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
    final cat = category, rem = _remaining;
    if (cat == null || rem == null || playing) return;
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
    final cat = category, rem = _remaining;
    if (cat == null || rem == null) return;
    await start(cat, i, remaining: rem);
  }

  Future<void> skip(int delta) async {
    final cat = category;
    if (cat == null) return;
    await jumpTo((index + delta).clamp(0, cat.items.length - 1));
  }

  /// The listener counted the current dhikr themselves: carry on with what is
  /// left of it, or with the next dhikr when it is done.
  Future<void> counted() async {
    final cat = category, rem = _remaining;
    if (cat == null || rem == null) return;
    final turn = _turn;
    if (turn != null && !turn.isCompleted) {
      if (rem(index) == 0) turn.complete();
      return;
    }
    if (rem(index) == 0 && index == cat.items.length - 1) {
      await stop();
      return;
    }
    await start(cat, rem(index) == 0 ? index + 1 : index, remaining: rem);
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
      artUri: _art,
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
        final left = _remaining!(index);
        final times = once ? (left > 0 ? 1 : 0) : left;
        repetitions = times;
        repetition = 0;
        if (d.audioFile == null) {
          if (left > 0) {
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
            onRepetition?.call(index);
            notifyListeners();
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
