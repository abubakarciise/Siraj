// Measures natural Madani line widths with the real Hafs font to calibrate
// kLineWidthPerFontSize. Run with:
//   flutter test test/mushaf_metrics_test.dart --dart-define=LINES_JSON=<path to exported lines.json>
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const path = String.fromEnvironment('LINES_JSON');

  test('line width / font size ratio', () async {
    if (path.isEmpty) return;
    final font = File('assets/fonts/UthmanicHafs.ttf').readAsBytesSync();
    await (FontLoader('Hafs')..addFont(Future.value(ByteData.sublistView(font)))).load();
    final pages = (jsonDecode(File(path).readAsStringSync()) as Map).cast<String, dynamic>();
    const fs = 100.0;
    final ratios = <double>[];
    for (final entry in pages.entries) {
      if (int.parse(entry.key) <= 2) continue;
      for (final line in entry.value as List) {
        final words = (line as List).cast<String>();
        var w = 0.0;
        for (final word in words) {
          w += (TextPainter(
            text: TextSpan(text: word, style: const TextStyle(fontFamily: 'Hafs', fontSize: fs)),
            textDirection: TextDirection.rtl,
          )..layout())
              .width;
        }
        w += fs * 0.2 * (words.length - 1);
        ratios.add(w / fs);
      }
    }
    ratios.sort();
    double pct(double p) => ratios[(ratios.length * p).floor().clamp(0, ratios.length - 1)];
    // ignore: avoid_print
    print('lines=${ratios.length} p50=${pct(.5)} p90=${pct(.9)} p99=${pct(.99)} max=${ratios.last}');
  });
}
