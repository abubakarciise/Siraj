import 'dart:async';

import 'package:flutter/foundation.dart';

import '../audio/speech.dart';
import 'hadith.dart';

/// Reads hadith aloud one after another with the phone's voice, in Arabic or
/// in English. No human recordings exist for each hadith of the collections.
class HadithReader extends ChangeNotifier {
  HadithReader(this._speech, {this.beforeStart});

  final Speech _speech;

  /// Pauses other audio (the Quran player) first.
  final Future<void> Function()? beforeStart;

  int _session = 0;

  /// Identifies the list being read (a chapter, or a single hadith).
  String? listKey;
  List<Hadith> _items = const [];
  int index = 0;
  bool playing = false;
  String language = 'ar';

  /// Called when the phone cannot read (e.g. its Arabic voice is not installed).
  void Function(Object error)? onError;

  Hadith? get current => index < _items.length ? _items[index] : null;
  int get length => _items.length;

  bool isReading(String key) => listKey == key;

  /// Whether the phone can read Arabic aloud.
  Future<bool> hasArabic() => _speech.hasArabic();

  Future<void> start(String key, List<Hadith> items, int from, {String? language}) async {
    await beforeStart?.call();
    final session = ++_session;
    await _speech.stop();
    listKey = key;
    _items = items;
    index = from.clamp(0, items.length - 1);
    if (language != null) this.language = language;
    playing = true;
    notifyListeners();
    unawaited(_run(session));
  }

  Future<void> pause() async {
    _session++;
    playing = false;
    notifyListeners();
    await _speech.stop();
  }

  Future<void> resume() async {
    if (listKey == null || _items.isEmpty) return;
    await start(listKey!, _items, index);
  }

  Future<void> skip(int delta) async {
    if (listKey == null) return;
    final next = (index + delta).clamp(0, _items.length - 1);
    if (playing) {
      await start(listKey!, _items, next);
    } else {
      index = next;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String lang) async {
    language = lang;
    notifyListeners();
    if (playing) await start(listKey!, _items, index);
  }

  Future<void> stop() async {
    _session++;
    playing = false;
    listKey = null;
    notifyListeners();
    await _speech.stop();
  }

  Future<void> _run(int session) async {
    try {
      while (session == _session && index < _items.length) {
        final h = _items[index];
        final text = language == 'ar' ? h.arabic : h.english;
        if (text.trim().isNotEmpty) await _speech.speak(text, language: language == 'ar' ? 'ar' : 'en-US');
        if (session != _session) return;
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (session != _session) return;
        if (index + 1 >= _items.length) break;
        index++;
        notifyListeners();
      }
      if (session == _session) {
        playing = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Hadith reading: $e');
      if (session == _session) {
        playing = false;
        notifyListeners();
        onError?.call(e);
      }
    }
  }
}
