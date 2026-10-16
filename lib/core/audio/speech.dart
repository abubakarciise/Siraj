import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SpeechException implements Exception {
  const SpeechException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The phone's own text-to-speech, used to read hadith aloud (no human
/// recordings exist per hadith) and adhkar that have no recording.
class Speech {
  final _tts = FlutterTts();
  bool _ready = false;
  final _installed = <String, bool>{};
  Completer<void>? _utterance;
  bool _stopped = false;

  /// Speaking rate, 0.3 (slow) .. 0.6 (brisk).
  double rate = 0.42;

  bool get stopped => _stopped;

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    // Completion is tracked here (not with awaitSpeakCompletion) so an engine
    // error ends the wait instead of leaving it hanging.
    await _tts.awaitSpeakCompletion(false);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() => _finish());
    _tts.setCancelHandler(() => _finish());
    _tts.setErrorHandler((msg) => _finish(SpeechException('$msg')));
  }

  void _finish([Object? error]) {
    final u = _utterance;
    _utterance = null;
    if (u == null || u.isCompleted) return;
    error == null ? u.complete() : u.completeError(error);
  }

  /// Whether a voice for [language] is installed and ready (Google's Arabic
  /// voice may be listed but still need its data downloaded).
  Future<bool> isReady(String language) async {
    final cached = _installed[language];
    if (cached != null) return cached;
    var ok = false;
    try {
      await _init();
      final available = await _tts.isLanguageAvailable(language);
      ok = available == true || available == 1;
      if (ok && Platform.isAndroid) {
        final installed = await _tts.isLanguageInstalled(language);
        ok = installed == true || installed == 1;
      }
    } catch (e) {
      debugPrint('TTS unavailable: $e');
      ok = false;
    }
    return _installed[language] = ok;
  }

  Future<bool> hasArabic() => isReady('ar');

  /// Speaks [text] and completes when it has been read, or [stop] is called.
  /// Throws [SpeechException] when the phone cannot speak it.
  Future<void> speak(String text, {String language = 'ar'}) async {
    _stopped = false;
    await _init();
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(rate);
    for (final chunk in chunks(text)) {
      if (_stopped) return;
      final u = _utterance = Completer<void>();
      try {
        final started = await _tts.speak(chunk);
        if (started != 1 && started != true) throw const SpeechException('The phone could not start speaking');
        // Generous ceiling: about 8 characters a second at the slowest rate.
        await u.future.timeout(Duration(seconds: 15 + chunk.length ~/ 8), onTimeout: () {
          throw const SpeechException('The phone stopped speaking');
        });
      } on SpeechException {
        _utterance = null;
        _installed[language == 'ar' ? 'ar' : language] = false; // ask again next time
        rethrow;
      }
    }
  }

  Future<void> stop() async {
    _stopped = true;
    _finish();
    await _tts.stop();
  }

  /// Android limits one utterance to about 4000 characters: split on sentence
  /// ends (Arabic and Latin punctuation), keeping chunks well under that.
  @visibleForTesting
  static List<String> chunks(String text, {int max = 1500}) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= max) return clean.isEmpty ? const [] : [clean];
    final sentences = clean.split(RegExp(r'(?<=[.،؛!?؟:])\s'));
    final out = <String>[];
    var buf = StringBuffer();
    for (final s in sentences) {
      if (buf.length + s.length + 1 > max && buf.isNotEmpty) {
        out.add(buf.toString().trim());
        buf = StringBuffer();
      }
      if (s.length > max) {
        for (var i = 0; i < s.length; i += max) {
          out.add(s.substring(i, i + max > s.length ? s.length : i + max));
        }
      } else {
        buf.write('$s ');
      }
    }
    if (buf.isNotEmpty) out.add(buf.toString().trim());
    return out;
  }
}
