import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A sound bundled with the app (tool/make_sounds.py).
class BuiltinSound {
  const BuiltinSound(this.id, this.name, this.description);
  final String id, name, description;
}

const kBuiltinSounds = [
  BuiltinSound('chime', 'Soft chime', 'Two gentle bell notes'),
  BuiltinSound('call', 'Gentle call', 'A calm five-note bell melody'),
  BuiltinSound('bell', 'Crystal bell', 'One clear, ringing bell'),
  BuiltinSound('oud', 'Oud', 'A short phrase in maqam Hijaz'),
  BuiltinSound('harp', 'Harp', 'A rising arpeggio'),
  BuiltinSound('dawn', 'Dawn', 'A warm, slowly rising chord'),
  BuiltinSound('drop', 'Water drop', 'Short and discreet'),
];

/// What a reminder sounds like. Stored as a short string:
/// `builtin:<id>`, `default`, `silent`, or `uri:<content uri>|<title>` (Android).
@immutable
class NotificationSound {
  const NotificationSound._(this.kind, [this.value = '', this.title = '']);
  const NotificationSound.builtin(String id) : this._(SoundKind.builtin, id);
  const NotificationSound.device(String uri, String title) : this._(SoundKind.device, uri, title);
  static const systemDefault = NotificationSound._(SoundKind.systemDefault);
  static const silent = NotificationSound._(SoundKind.silent);

  final SoundKind kind;

  /// Builtin id or device content URI.
  final String value;
  final String title;

  bool get plays => kind != SoundKind.silent;

  String get label => switch (kind) {
        SoundKind.builtin => kBuiltinSounds.firstWhere((s) => s.id == value, orElse: () => kBuiltinSounds.first).name,
        SoundKind.device => title.isEmpty ? 'Phone sound' : title,
        SoundKind.systemDefault => 'Phone default',
        SoundKind.silent => 'Silent',
      };

  /// Stable, channel-id-safe key (an Android channel's sound can never change).
  String get key => switch (kind) {
        SoundKind.builtin => value,
        SoundKind.device => 'u${_fnv(value)}',
        SoundKind.systemDefault => 'default',
        SoundKind.silent => 'silent',
      };

  String encode() => switch (kind) {
        SoundKind.builtin => 'builtin:$value',
        SoundKind.device => 'uri:$value|$title',
        SoundKind.systemDefault => 'default',
        SoundKind.silent => 'silent',
      };

  static NotificationSound decode(String? s, NotificationSound fallback) {
    if (s == null) return fallback;
    if (s == 'default') return systemDefault;
    if (s == 'silent') return silent;
    if (s.startsWith('builtin:')) {
      final id = s.substring(8);
      return kBuiltinSounds.any((b) => b.id == id) ? NotificationSound.builtin(id) : fallback;
    }
    if (s.startsWith('uri:')) {
      final rest = s.substring(4);
      final bar = rest.lastIndexOf('|');
      return bar < 0 ? NotificationSound.device(rest, '') : NotificationSound.device(rest.substring(0, bar), rest.substring(bar + 1));
    }
    return fallback;
  }

  @override
  bool operator ==(Object other) => other is NotificationSound && other.kind == kind && other.value == value;
  @override
  int get hashCode => Object.hash(kind, value);

  static String _fnv(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(36);
  }
}

enum SoundKind { builtin, device, systemDefault, silent }

/// Previews sounds and, on Android, opens the phone's own sound picker.
class SoundService {
  static const _channel = MethodChannel('siraj/sounds');
  AudioPlayer? _player;

  static bool get canPickDeviceSound => Platform.isAndroid;

  Future<void> preview(NotificationSound s) async {
    await stop();
    switch (s.kind) {
      case SoundKind.builtin:
        final player = _player ??= AudioPlayer(handleInterruptions: false, handleAudioSessionActivation: false);
        await player.setAsset('assets/sounds/${s.value}.wav');
        await player.play();
      case SoundKind.device:
        await _channel.invokeMethod('preview', {'uri': s.value});
      case SoundKind.systemDefault:
        if (Platform.isAndroid) {
          await _channel.invokeMethod('preview', {'uri': 'content://settings/system/notification_sound'});
        }
      case SoundKind.silent:
        break;
    }
  }

  Future<void> stop() async {
    await _player?.stop();
    if (Platform.isAndroid) await _channel.invokeMethod('stop');
  }

  /// Opens the Android sound picker; null when cancelled.
  Future<NotificationSound?> pickDeviceSound({String title = 'Reminder sound', String? current}) async {
    final r = await _channel.invokeMapMethod<String, String>('pick', {'title': title, 'current': current});
    if (r == null || r['uri'] == null) return null;
    return NotificationSound.device(r['uri']!, r['title'] ?? 'Phone sound');
  }

  /// iOS plays custom notification sounds from Library/Sounds.
  static Future<void> installForIos() async {
    if (!Platform.isIOS) return;
    try {
      final dir = Directory(p.join((await getLibraryDirectory()).path, 'Sounds'));
      await dir.create(recursive: true);
      for (final s in kBuiltinSounds) {
        final f = File(p.join(dir.path, '${s.id}.wav'));
        if (f.existsSync()) continue;
        final data = await rootBundle.load('assets/sounds/${s.id}.wav');
        await f.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      }
    } catch (e) {
      debugPrint('Sound install failed: $e');
    }
  }

  void dispose() => _player?.dispose();
}
