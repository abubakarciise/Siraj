import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Another kind of audio (adhkar) that borrows the media session: the lock
/// screen and notification controls are routed to it while it plays.
abstract class ExternalPlayback {
  Future<void> play();
  Future<void> pause();
  Future<void> next();
  Future<void> previous();
  Future<void> stop();
}

/// Bridges just_audio to the OS media session (lock screen, notification,
/// headset buttons, Bluetooth, Android Auto / CarPlay controls).
class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  QuranAudioHandler() {
    player.playbackEventStream.listen((_) => _broadcast(), onError: (Object e, StackTrace st) {});
    player.playingStream.listen((playing) {
      _broadcast();
      // Paused for a while: end the session so the notification goes away.
      _idle?.cancel();
      if (!playing && player.processingState != ProcessingState.idle) {
        _idle = Timer(const Duration(minutes: 10), stop);
      }
    });
    player.currentIndexStream.listen((i) {
      final q = queue.value;
      if (external == null && i != null && i < q.length) mediaItem.add(q[i]);
    });
    player.durationStream.listen((d) {
      final item = mediaItem.value;
      if (external == null && item != null && d != null && item.duration != d) {
        final updated = item.copyWith(duration: d);
        mediaItem.add(updated);
        final q = [...queue.value];
        final i = q.indexWhere((m) => m.id == item.id);
        if (i >= 0) {
          q[i] = updated;
          queue.add(q);
        }
      }
    });
  }

  // Starts after 0.8 s of audio is buffered (Android waits for 2.5 s by
  // default), so a tapped surah is heard sooner; it then keeps buffering ahead.
  final player = AudioPlayer(
    audioLoadConfiguration: const AudioLoadConfiguration(
      androidLoadControl: AndroidLoadControl(
        bufferForPlaybackDuration: Duration(milliseconds: 800),
        bufferForPlaybackAfterRebufferDuration: Duration(seconds: 2),
      ),
    ),
  );
  Timer? _idle;

  /// "Close" on the notification: Android 13+ media controls do not show Stop.
  static final _close = MediaControl.custom(androidIcon: 'drawable/ic_media_close', label: 'Close', name: 'close');

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'close') await stop();
  }

  /// Set while adhkar (or other non-Quran audio) owns the session.
  ExternalPlayback? external;

  /// Called when playback is stopped from outside the app (the notification
  /// was dismissed, or Stop pressed on it), so the app can clear its state.
  void Function()? onStoppedOutside;

  /// Starts Quran playback; any adhkar session ends first.
  Future<void> load(List<MediaItem> items, List<AudioSource> sources, {int index = 0, Duration? position}) async {
    final ext = external;
    external = null;
    await ext?.stop();
    queue.add(items);
    mediaItem.add(items[index]);
    await player.setAudioSources(sources, initialIndex: index, initialPosition: position, preload: true);
  }

  @override
  Future<void> play() => external?.play() ?? player.play();
  @override
  Future<void> pause() => external?.pause() ?? player.pause();
  @override
  Future<void> seek(Duration position) => player.seek(position);
  @override
  Future<void> skipToNext() => external?.next() ?? player.seekToNext();
  @override
  Future<void> skipToPrevious() async {
    if (external != null) return external!.previous();
    if (player.position > const Duration(seconds: 3) || !player.hasPrevious) {
      await player.seek(Duration.zero);
    } else {
      await player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) => player.seek(Duration.zero, index: index);
  @override
  Future<void> setSpeed(double speed) => player.setSpeed(speed);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await player.setLoopMode(switch (repeatMode) {
      AudioServiceRepeatMode.one => LoopMode.one,
      AudioServiceRepeatMode.all || AudioServiceRepeatMode.group => LoopMode.all,
      AudioServiceRepeatMode.none => LoopMode.off,
    });
    _broadcast();
  }

  /// Stop from the notification / lock screen: ends whatever is playing.
  @override
  Future<void> stop() async {
    final ext = external;
    if (ext != null) {
      external = null;
      await ext.stop();
    } else {
      onStoppedOutside?.call();
    }
    await endSession();
  }

  /// Swiping the (paused) notification away ends playback too.
  @override
  Future<void> onNotificationDeleted() => stop();

  /// The app was closed (swiped away from recent apps): stop everything,
  /// Quran or adhkar, and remove the notification.
  @override
  Future<void> onTaskRemoved() => stop();

  /// Stops audio and removes the notification, without calling back.
  Future<void> endSession() async {
    _idle?.cancel();
    await player.stop();
    await super.stop();
  }

  void _broadcast() {
    final playing = player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        _close,
      ],
      systemActions: external != null
          ? const {}
          : const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      repeatMode: switch (player.loopMode) {
        LoopMode.one => AudioServiceRepeatMode.one,
        LoopMode.all => AudioServiceRepeatMode.all,
        LoopMode.off => AudioServiceRepeatMode.none,
      },
      playing: playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: external != null ? null : player.currentIndex,
    ));
  }
}
