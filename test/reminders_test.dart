import 'dart:math';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/audio/ayah_estimate.dart';
import 'package:quran_app/core/notifications/sounds.dart';
import 'package:quran_app/core/quran/models.dart';
import 'package:quran_app/core/reminders/reminders.dart';
import 'package:quran_app/core/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ReminderService.slots', () {
    final start = DateTime(2026, 10, 15, 0, 0);

    test('every N hours inside the active window only', () {
      const s = DailyReminderSettings(
        everyHours: 3,
        vary: false,
        from: TimeOfDay(hour: 7, minute: 0),
        until: TimeOfDay(hour: 22, minute: 0),
      );
      final today = ReminderService.slots(s, start, 0, Random(1));
      expect(today.map((t) => '${t.hour}:${t.minute}'), ['7:30', '10:30', '13:30', '16:30', '19:30']);
    });

    test('hourly reminders and a window that crosses midnight', () {
      const s = DailyReminderSettings(
        everyHours: 1,
        vary: false,
        from: TimeOfDay(hour: 20, minute: 0),
        until: TimeOfDay(hour: 1, minute: 0),
      );
      final today = ReminderService.slots(s, start, 0, Random(1));
      expect(today.first, DateTime(2026, 10, 15, 20, 30));
      expect(today.last, DateTime(2026, 10, 16, 0, 30));
      expect(today.length, 5);
    });

    test('varied times stay inside the window', () {
      const s = DailyReminderSettings(everyHours: 2, vary: true);
      final rnd = Random(3);
      for (var i = 0; i < 50; i++) {
        for (final t in ReminderService.slots(s, start, 6, rnd)) {
          final m = t.hour * 60 + t.minute;
          expect(m, inInclusiveRange(7 * 60, 22 * 60));
        }
      }
    });

    test('never in the past', () {
      final now = DateTime(2026, 10, 15, 15, 10);
      const s = DailyReminderSettings(everyHours: 1, vary: false);
      expect(ReminderService.slots(s, now, 0, Random(1)).every((t) => t.isAfter(now)), isTrue);
    });
  });

  group('ReminderComposer.occasions', () {
    test('Friday, and Thursday after sunset', () {
      expect(ReminderComposer.occasions(DateTime(2026, 10, 16, 11), 0), contains('friday'));
      expect(ReminderComposer.occasions(DateTime(2026, 10, 15, 19), 0), contains('friday'));
      expect(ReminderComposer.occasions(DateTime(2026, 10, 15, 11), 0), isNot(contains('friday')));
    });

    test('fasting reminder on Sunday and Wednesday evenings', () {
      expect(ReminderComposer.occasions(DateTime(2026, 10, 18, 19), 0), contains('mon_thu_eve'));
      expect(ReminderComposer.occasions(DateTime(2026, 10, 14, 19), 0), contains('mon_thu_eve'));
      expect(ReminderComposer.occasions(DateTime(2026, 10, 14, 9), 0), isNot(contains('mon_thu_eve')));
    });

    test('Hijri seasons', () {
      // 1 Ramadan 1447 ≈ 18 Feb 2026 (Umm al-Qura).
      final r = HijriDate.of(DateTime(2026, 3, 1));
      expect(r.month, 9);
      expect(ReminderComposer.occasions(DateTime(2026, 3, 1, 12), 0), contains('ramadan'));
      expect(ReminderComposer.occasions(DateTime(2026, 3, 15, 12), 0), contains('last_ten'));
      expect(ReminderComposer.occasions(DateTime(2026, 4, 1, 12), 0), contains('shawwal'));
    });

    test('time of day', () {
      expect(ReminderComposer.occasions(DateTime(2026, 10, 15, 6), 0), contains('morning'));
      expect(ReminderComposer.occasions(DateTime(2026, 10, 15, 22), 0), contains('sleep'));
    });
  });

  group('SurahPace', () {
    Ayah a(int n, String text) => Ayah(id: n, ref: AyahRef(2, n), page: 1, juz: 1, text: text);

    test('longer ayahs take longer and estimates are monotonic', () {
      final pace = SurahPace(2, [a(1, 'الم'), a(2, 'ذلك الكتاب لا ريب فيه هدى للمتقين'), a(3, 'الذين يؤمنون بالغيب')]);
      expect(pace.ayahAt(0.0), 0); // basmala intro
      var last = 0;
      for (var f = 0.0; f <= 1.0; f += 0.01) {
        final n = pace.ayahAt(f);
        expect(n, greaterThanOrEqualTo(last));
        last = n;
      }
      expect(pace.ayahAt(0.99), 3);
      expect(pace.startOf(2) - pace.startOf(1), lessThan(pace.startOf(3) - pace.startOf(2)));
    });

    test('Al-Fatihah has no separate basmala intro', () {
      final pace = SurahPace(1, [Ayah(id: 1, ref: const AyahRef(1, 1), page: 1, juz: 1, text: 'بسم الله الرحمن الرحيم')]);
      expect(pace.ayahAt(0), 1);
    });
  });

  group('NotificationSound', () {
    test('round-trips through its stored form', () {
      for (final s in [
        const NotificationSound.builtin('birds'),
        NotificationSound.systemDefault,
        NotificationSound.silent,
        const NotificationSound.device('content://media/internal/audio/media/31', 'Pixie Dust'),
      ]) {
        final back = NotificationSound.decode(s.encode(), NotificationSound.silent);
        expect(back, s);
        expect(back.label, s.label);
      }
    });

    test('sounds removed in 2.1 fall back to the default', () {
      expect(NotificationSound.decode('builtin:oud', const NotificationSound.builtin('tone')),
          const NotificationSound.builtin('tone'));
    });

    test('channel keys are stable and id-safe', () {
      const s = NotificationSound.device('content://media/internal/audio/media/31', 'x');
      expect(s.key, NotificationSound.decode(s.encode(), NotificationSound.silent).key);
      expect(RegExp(r'^[a-z0-9]+$').hasMatch(s.key), isTrue);
    });

    test('unknown values fall back', () {
      expect(NotificationSound.decode('builtin:nope', NotificationSound.silent), NotificationSound.silent);
      expect(NotificationSound.decode(null, const NotificationSound.builtin('chime')).value, 'chime');
    });
  });

  test('v1 theme preferences migrate to the new themes', () async {
    for (final (old, expected) in [(0, ThemePref.system), (1, ThemePref.light), (2, ThemePref.light), (3, ThemePref.dark), (4, ThemePref.midnight)]) {
      SharedPreferences.setMockInitialValues({'theme': old});
      expect(AppSettings.load(await SharedPreferences.getInstance()).theme, expected);
    }
  });
}
