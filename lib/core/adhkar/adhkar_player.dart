import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'adhkar.dart';

/// Plays a category of adhkar one after another from the recordings bundled
/// with the app (no internet needed). Each dhikr repeats as many times as it
/// is prescribed, or once if the listener prefers; [onRepetition] tells the
/// screen to count one down after each recitation. A dhikr without a
/// recording is the listener's turn: playback waits until they have counted
/// it on screen, then continues.
class AdhkarPlayer extends ChangeNotifier {
  AdhkarPlayer({this.beforeStart});

  /// Pauses other audio (the Quran player) before adhkar start.
  final Future<void> Function()? beforeStart;

  AudioPlayer? _player;
  int _session = 0;
  Completer<void>? _turn;

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

  AudioPlayer get _p => _player ??= AudioPlayer();

  bool isActive(String categoryId) => category?.id == categoryId;

  /// Starts at [from]; [remaining] gives how many recitations are left for a dhikr.
  Future<void> start(AdhkarCategory cat, int from, {required int Function(int index) remaining}) async {
    await beforeStart?.call();
    final session = ++_session;
    await _stopOutput();
    category = cat;
    index = from.clamp(0, cat.items.length - 1);
    _remaining = remaining;
    playing = true;
    notifyListeners();
    unawaited(_run(session));
  }

  Future<void> pause() async {
    _session++;
    playing = false;
    notifyListeners();
    await _stopOutput();
  }

  Future<void> resume() async {
    final cat = category, rem = _remaining;
    if (cat == null || rem == null) return;
    await start(cat, index, remaining: rem);
  }

  /// Plays [i] now (the listener tapped another card).
  Future<void> jumpTo(int i) async {
    final cat = category, rem = _remaining;
    if (cat == null || rem == null) return;
    await start(cat, i, remaining: rem);
  }

  Future<void> skip(int delta) async {
    final cat = category;
    if (cat == null) return;
    final next = (index + delta).clamp(0, cat.items.length - 1);
    if (playing) {
      await jumpTo(next);
    } else {
      index = next;
      notifyListeners();
    }
  }

  /// The listener counted the current dhikr themselves: carry on with what is
  /// left of it, or with the next dhikr when it is done.
  Future<void> counted() async {
    final cat = category, rem = _remaining;
    if (cat == null || rem == null || !playing) return;
    final turn = _turn;
    if (turn != null && !turn.isCompleted) {
      if (rem(index) == 0) turn.complete();
      return;
    }
    final last = cat.items.length - 1;
    if (rem(index) == 0 && index == last) {
      await stop();
      return;
    }
    await start(cat, rem(index) == 0 ? index + 1 : index, remaining: rem);
  }

  Future<void> stop() async {
    _session++;
    playing = false;
    category = null;
    notifyListeners();
    await _stopOutput();
  }

  void setOnce(bool v) {
    once = v;
    notifyListeners();
  }

  Future<void> _stopOutput() async {
    final turn = _turn;
    _turn = null;
    if (turn != null && !turn.isCompleted) turn.complete();
    waitingForReader = false;
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
        if (d.audioFile == null) {
          if (left > 0) {
            // No recording: the listener reads this one and taps to count it.
            waitingForReader = true;
            final turn = _turn = Completer<void>();
            notifyListeners();
            await turn.future;
            waitingForReader = false;
            if (session != _session) return;
          }
        } else {
          for (var r = 0; r < times; r++) {
            if (session != _session) return;
            await _p.setAudioSource(AudioSource.asset('assets/adhkar/audio/${d.audioFile}'));
            if (session != _session) return;
            unawaited(_p.play());
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
      if (session == _session) {
        playing = false;
        notifyListeners();
      }
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

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }
}
