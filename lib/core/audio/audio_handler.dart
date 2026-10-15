import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Bridges just_audio to the OS media session (lock screen, notification,
/// headset buttons, Bluetooth, Android Auto / CarPlay controls).
class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  QuranAudioHandler() {
    player.playbackEventStream.listen((_) => _broadcast(), onError: (Object e, StackTrace st) {});
    player.playingStream.listen((_) => _broadcast());
    player.currentIndexStream.listen((i) {
      final q = queue.value;
      if (i != null && i < q.length) mediaItem.add(q[i]);
    });
    player.durationStream.listen((d) {
      final item = mediaItem.value;
      if (item != null && d != null && item.duration != d) {
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

  final player = AudioPlayer();

  Future<void> load(List<MediaItem> items, List<AudioSource> sources, {int index = 0, Duration? position}) async {
    queue.add(items);
    mediaItem.add(items[index]);
    await player.setAudioSources(sources, initialIndex: index, initialPosition: position, preload: true);
  }

  @override
  Future<void> play() => player.play();
  @override
  Future<void> pause() => player.pause();
  @override
  Future<void> seek(Duration position) => player.seek(position);
  @override
  Future<void> skipToNext() => player.seekToNext();
  @override
  Future<void> skipToPrevious() async {
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

  @override
  Future<void> stop() async {
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
        MediaControl.stop,
      ],
      systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
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
      queueIndex: player.currentIndex,
    ));
  }
}
