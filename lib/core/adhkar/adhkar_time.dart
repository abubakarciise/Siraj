import '../prayer/prayer.dart';

/// Which adhkar suit this moment of the day.
class AdhkarMoment {
  const AdhkarMoment(this.categoryId, this.reason, {this.afterPrayer});

  /// An id in assets/adhkar/adhkar.json: waking, morning, after_salah, tasbih,
  /// evening, quran_duas, sleep.
  final String categoryId;

  /// Why now, e.g. "Best before sunrise" or "After Dhuhr".
  final String reason;
  final Salah? afterPrayer;
}

/// The adhkar for [now], following the prayer times of [day] and the times
/// the scholars give (al-Nawawi, Ibn al-Qayyim, Ibn Hajar):
/// - morning adhkar from Fajr until sunrise, and, if missed, until Dhuhr;
/// - evening adhkar from Asr until Maghrib, and, if missed, into the night;
/// - the adhkar after each prayer once it has been prayed (the adhan, the wait
///   for the iqama and the prayer: [prayedAfter]) for 30 minutes, unless
///   they were completed after that prayer ([afterSalahDoneAt]);
/// - at night, the adhkar before sleep; before Fajr, waking up.
/// Between those (midday, or once the morning or evening adhkar are done)
/// it suggests general dhikr and the duas of the Quran.
/// [done] tells whether a category was completed today.
AdhkarMoment adhkarFor(DateTime now, PrayerDay? day, {bool Function(String id)? done, DateTime? afterSalahDoneAt}) {
  bool isDone(String id) => done?.call(id) ?? false;
  DateTime at(Salah s, int h, int m) => day?.times[s] ?? DateTime(now.year, now.month, now.day, h, m);
  final fajr = at(Salah.fajr, 5, 0);
  final sunrise = at(Salah.sunrise, 6, 15);
  final dhuhr = at(Salah.dhuhr, 12, 30);
  final asr = at(Salah.asr, 15, 30);
  final maghrib = at(Salah.maghrib, 18, 15);
  final isha = at(Salah.isha, 19, 45);
  bool before(DateTime t) => now.isBefore(t);

  for (final (s, t) in [
    (Salah.fajr, fajr),
    (Salah.dhuhr, dhuhr),
    (Salah.asr, asr),
    (Salah.maghrib, maghrib),
    (Salah.isha, isha),
  ]) {
    final from = t.add(prayedAfter[s]!);
    final doneHere = afterSalahDoneAt != null && afterSalahDoneAt.isAfter(t);
    if (!before(from) && before(from.add(const Duration(minutes: 30))) && !doneHere) {
      return AdhkarMoment('after_salah', 'After ${s.en}', afterPrayer: s);
    }
  }
  if (now.hour >= 3 && before(fajr)) return const AdhkarMoment('waking', 'Before Fajr');
  if (!before(fajr) && before(sunrise)) return const AdhkarMoment('morning', 'Best before sunrise');
  if (!before(sunrise) && before(dhuhr)) {
    return isDone('morning')
        ? const AdhkarMoment('tasbih', 'Dhikr through the day')
        : const AdhkarMoment('morning', 'Still time · until Dhuhr');
  }
  if (!before(dhuhr) && before(asr)) return const AdhkarMoment('tasbih', 'Dhikr through the day');
  if (!before(asr) && before(maghrib)) return const AdhkarMoment('evening', 'Best before Maghrib');
  if (!before(maghrib) && before(isha.add(const Duration(minutes: 40)))) {
    return isDone('evening')
        ? const AdhkarMoment('quran_duas', 'Duas of the Quran')
        : const AdhkarMoment('evening', 'Still time · tonight');
  }
  return const AdhkarMoment('sleep', 'Before you sleep');
}

/// From the adhan until the prayer is usually over: the wait for the iqama
/// (shorter for Maghrib) and the prayer itself.
const prayedAfter = {
  Salah.fajr: Duration(minutes: 30),
  Salah.dhuhr: Duration(minutes: 25),
  Salah.asr: Duration(minutes: 25),
  Salah.maghrib: Duration(minutes: 15),
  Salah.isha: Duration(minutes: 25),
};

/// English and Arabic names of the adhkar [adhkarFor] can suggest.
const adhkarNames = {
  'waking': ('Waking up', 'أذكار الاستيقاظ'),
  'morning': ('Morning adhkar', 'أذكار الصباح'),
  'after_salah': ('After prayer', 'أذكار بعد الصلاة'),
  'tasbih': ('Tasbih & dhikr', 'التسبيح'),
  'evening': ('Evening adhkar', 'أذكار المساء'),
  'quran_duas': ('Duas of the Quran', 'أدعية قرآنية'),
  'sleep': ('Before sleep', 'أذكار النوم'),
};
