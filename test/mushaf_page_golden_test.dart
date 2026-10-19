// Golden tests for Mushaf page rendering.
// Regenerate after intentional layout changes:  flutter test --update-goldens test/mushaf_page_golden_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/quran/models.dart';
import 'package:quran_app/design/theme.dart';
import 'package:quran_app/design/tokens.dart';
import 'package:quran_app/features/reader/mushaf_page.dart';

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

void main() {
  final fixture = jsonDecode(File('test/fixtures/pages.json').readAsStringSync()) as Map<String, dynamic>;
  final names = (fixture['names'] as Map).map((k, v) => MapEntry(int.parse(k as String), v as String));

  MushafPage pageFrom(int n) {
    final j = fixture['pages']['$n'] as Map<String, dynamic>;
    return MushafPage(
      number: n,
      juz: j['juz'] as int,
      surahs: (j['surahs'] as List).cast<int>(),
      lines: [
        for (final l in j['lines'] as List)
          MushafLine(
            number: l['line'] as int,
            type: LineType.values[l['type'] as int],
            surah: l['surah'] as int?,
            words: [
              for (final w in l['words'] as List)
                MushafWord(w[0] as int, w[1] as int, w[2] as String, (w[3] as int) == 1),
            ],
          ),
      ],
    );
  }

  setUpAll(() async {
    await _loadFont('Hafs', 'assets/fonts/UthmanicHafs.ttf');
    await _loadFont('Plex', 'assets/fonts/IBMPlexSansArabic-Regular.ttf');
  });

  for (final (page, theme, playing) in [
    (1, AppThemeKind.light, null),
    (2, AppThemeKind.light, null),
    (3, AppThemeKind.light, const AyahRef(2, 10)),
    (50, AppThemeKind.dark, null),
    (187, AppThemeKind.midnight, null),
    (293, AppThemeKind.light, const AyahRef(18, 1)),
    (604, AppThemeKind.dark, const AyahRef(113, 3)),
  ]) {
    testWidgets('page $page (${theme.name})', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(theme),
        home: Builder(
          builder: (context) => Scaffold(
            backgroundColor: context.colors.pageBg,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 38, 14, 38),
                child: MushafPageView(page: pageFrom(page), surahNames: (s) => names[s]!, playing: playing),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/page_$page.png'));
    });
  }
}
