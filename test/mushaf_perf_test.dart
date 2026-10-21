// Rebuild cost of a Mushaf page while audio moves the highlight.
// Run:  flutter test test/mushaf_perf_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/quran/models.dart';
import 'package:quran_app/design/theme.dart';
import 'package:quran_app/design/tokens.dart';
import 'package:quran_app/features/reader/mushaf_page.dart';
import 'package:quran_app/l10n/app_localizations.dart';

void main() {
  final fixture = jsonDecode(File('test/fixtures/pages.json').readAsStringSync()) as Map<String, dynamic>;
  final names = (fixture['names'] as Map).map((k, v) => MapEntry(int.parse(k as String), v as String));
  final j = fixture['pages']['3'] as Map<String, dynamic>;
  final page = MushafPage(
    number: 3,
    juz: j['juz'] as int,
    surahs: (j['surahs'] as List).cast<int>(),
    lines: [
      for (final l in j['lines'] as List)
        MushafLine(
          number: l['line'] as int,
          type: LineType.values[l['type'] as int],
          surah: l['surah'] as int?,
          words: [
            for (final w in l['words'] as List) MushafWord(w[0] as int, w[1] as int, w[2] as String, (w[3] as int) == 1),
          ],
        ),
    ],
  );

  testWidgets('highlight changes do not re-measure text', (tester) async {
    final bytes = File('assets/fonts/UthmanicHafs.ttf').readAsBytesSync();
    await (FontLoader('Hafs')..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    Future<void> pump(AyahRef playing) => tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          theme: buildTheme(AppThemeKind.light),
          home: Scaffold(body: MushafPageView(page: page, surahNames: (s) => names[s]!, playing: playing)),
        ));

    final cold = Stopwatch()..start();
    await pump(const AyahRef(2, 6));
    cold.stop();

    final warm = Stopwatch()..start();
    for (var i = 0; i < 100; i++) {
      await pump(AyahRef(2, 6 + i % 10));
    }
    warm.stop();
    final perRebuild = warm.elapsedMicroseconds / 100 / 1000;
    // ignore: avoid_print
    print('first layout ${cold.elapsedMilliseconds} ms; highlight rebuild ${perRebuild.toStringAsFixed(2)} ms');
    expect(perRebuild, lessThan(cold.elapsedMilliseconds));

    // What v1 did on every rebuild: measure every word with a TextPainter, twice
    // (page font ratio + per-line justification).
    final words = [for (final l in page.lines) ...l.words];
    final old = Stopwatch()..start();
    for (var i = 0; i < 20; i++) {
      for (var pass = 0; pass < 2; pass++) {
        for (final w in words) {
          (TextPainter(
            text: TextSpan(text: w.text, style: const TextStyle(fontFamily: 'Hafs', fontSize: 24)),
            textDirection: TextDirection.rtl,
          )..layout())
              .dispose();
        }
      }
    }
    old.stop();
    // ignore: avoid_print
    print('v1 re-measure per rebuild: ${(old.elapsedMicroseconds / 20 / 1000).toStringAsFixed(2)} ms '
        'for ${words.length} words (x3 pages visible while swiping)');
  });
}
