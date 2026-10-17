import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Notification artwork. The media session needs a file, so the bundled
/// image is copied out once: Quran recitation and adhkar each have their own.
class Artwork {
  static final _cache = <String, Uri?>{};

  static Future<Uri?> quran() => _file('quran');
  static Future<Uri?> adhkar() => _file('adhkar');

  static Future<Uri?> _file(String name) async {
    if (_cache.containsKey(name)) return _cache[name];
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File(p.join(dir.path, 'art', '$name.png'));
      if (!file.existsSync()) {
        final data = await rootBundle.load('assets/art/$name.png');
        await file.create(recursive: true);
        await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
      }
      return _cache[name] = Uri.file(file.path);
    } catch (e) {
      debugPrint('Artwork $name: $e');
      return _cache[name] = null;
    }
  }
}
