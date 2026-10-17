import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/adhkar/adhkar_time.dart';
import 'package:quran_app/core/prayer/prayer.dart';

void main() {
  final day = PrayerDay(DateTime(2026, 10, 17), {
    Salah.fajr: DateTime(2026, 10, 17, 4, 50),
    Salah.sunrise: DateTime(2026, 10, 17, 6, 5),
    Salah.dhuhr: DateTime(2026, 10, 17, 12, 0),
    Salah.asr: DateTime(2026, 10, 17, 15, 20),
    Salah.maghrib: DateTime(2026, 10, 17, 17, 55),
    Salah.isha: DateTime(2026, 10, 17, 19, 10),
  });
  String at(int h, int m, [Set<String> done = const {}]) =>
      adhkarFor(DateTime(2026, 10, 17, h, m), day, done: done.contains).categoryId;

  test('follows the day', () {
    expect(at(4, 0), 'waking');
    expect(at(5, 0), 'after_salah'); // just after Fajr
    expect(at(5, 30), 'morning'); // best time, before sunrise
    expect(at(9, 0), 'morning'); // still time, if not read yet
    expect(at(12, 10), 'after_salah'); // after Dhuhr
    expect(at(13, 0), 'tasbih');
    expect(at(16, 0), 'evening');
    expect(at(18, 10), 'after_salah'); // after Maghrib
    expect(at(18, 40), 'evening'); // still time, if not read yet
    expect(at(21, 0), 'sleep');
    expect(at(1, 0), 'sleep');
  });

  test('moves on once the morning or evening adhkar are done', () {
    expect(at(9, 0, {'morning'}), 'tasbih');
    expect(at(18, 40, {'evening'}), 'quran_duas');
  });

  test('names the prayer it follows', () {
    expect(adhkarFor(DateTime(2026, 10, 17, 12, 10), day).afterPrayer, Salah.dhuhr);
  });

  test('works without prayer times', () {
    expect(adhkarFor(DateTime(2026, 10, 17, 5, 30), null).categoryId, 'morning');
  });
}
