import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/audio/timing.dart';
import 'package:quran_app/core/catalog/catalog.dart';
import 'package:quran_app/core/quran/arabic.dart';

void main() {
  group('normalizeArabic', () {
    test('strips diacritics and unifies letter variants', () {
      expect(normalizeArabic('ٱلرَّحۡمَٰنِ'), 'الرحمن');
      expect(normalizeArabic('إِيَّاكَ'), 'اياك');
      expect(normalizeArabic('رَحْمَةً'), 'رحمه');
      expect(normalizeArabic('عَلَىٰ'), 'علي');
    });
    test('arabic digits', () => expect(toArabicDigits(255), '٢٥٥'));
  });

  group('SurahTiming.ayahAt', () {
    final timing = SurahTiming([(0, 0, 2731), (1, 2731, 5720), (2, 5720, 10592), (3, 10592, 14000)]);

    test('boundaries', () {
      expect(timing.ayahAt(0), 0);
      expect(timing.ayahAt(2730), 0);
      expect(timing.ayahAt(2731), 1);
      expect(timing.ayahAt(10591), 2);
      expect(timing.ayahAt(99999), 3);
      expect(timing.startOf(2), 5720);
      expect(timing.startOf(9), isNull);
    });

    test('matches a linear scan for random positions', () {
      final rnd = Random(1);
      for (var i = 0; i < 2000; i++) {
        final ms = rnd.nextInt(15000);
        var expected = 0;
        for (var j = 0; j < timing.starts.length; j++) {
          if (timing.starts[j] <= ms) expected = timing.ayahs[j];
        }
        expect(timing.ayahAt(ms), expected);
      }
    });
  });

  group('catalog', () {
    final raw = File('assets/catalog/reciters.json').readAsStringSync();
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final catalog = Catalog([for (final r in j['reciters'] as List) Reciter.fromJson(r as Map<String, dynamic>)]);

    test('bundled snapshot has 100+ reciters with valid recitations', () {
      expect(catalog.reciters.length, greaterThan(100));
      for (final r in catalog.reciters) {
        for (final m in r.recitations) {
          expect(m.server, startsWith('https://'));
          expect(m.surahs, isNotEmpty);
          expect(m.surahs.every((s) => s >= 1 && s <= 114), isTrue);
        }
      }
    });

    test('urls and labels', () {
      final m = catalog.reciters.expand((r) => r.recitations).firstWhere((m) => m.isComplete);
      expect(m.urlFor(2), endsWith('/002.mp3'));
      expect(m.shortName, contains(' · '));
      expect(catalog.recitation(m.key), same(m));
    });

    test('featured reciters resolve', () {
      expect(catalog.featured.length, greaterThanOrEqualTo(10));
      expect(catalog.featured.first.name.toLowerCase(), contains('alafas'));
    });

    test('runtime refresh produces the same format as the build tool', () {
      final en = {
        'reciters': [
          {
            'id': 7,
            'name': 'Test Reciter',
            'moshaf': [
              {'id': 1, 'name': "Rewayat Warsh A'n Nafi' - Murattal", 'server': 'https://x/y', 'surah_list': '1,2', 'rewaya_id': 2, 'moshaf_type': 21},
            ],
          },
        ],
      };
      final ar = {
        'reciters': [
          {'id': 7, 'name': 'قارئ', 'moshaf': [{'id': 1, 'name': 'ورش'}]},
        ],
      };
      final out = jsonDecode(CatalogRepository.buildCatalogJson(en, ar, [
        {'id': 99, 'folder_url': 'https://x/y/'},
      ])) as Map<String, dynamic>;
      final r = Reciter.fromJson((out['reciters'] as List).first as Map<String, dynamic>);
      expect(r.nameAr, 'قارئ');
      expect(r.recitations.single.timingReadId, 99);
      expect(r.recitations.single.riwayah, 'Warsh');
      expect(r.recitations.single.urlFor(1), 'https://x/y/001.mp3');
    });
  });
}
