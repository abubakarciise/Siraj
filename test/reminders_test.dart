import 'dart:math';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
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

  test('v1 theme preferences migrate to the new themes', () async {
    for (final (old, expected) in [(0, ThemePref.system), (1, ThemePref.light), (2, ThemePref.light), (3, ThemePref.dark), (4, ThemePref.midnight)]) {
      SharedPreferences.setMockInitialValues({'theme': old});
      expect(AppSettings.load(await SharedPreferences.getInstance()).theme, expected);
    }
  });
}
