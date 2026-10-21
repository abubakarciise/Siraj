import '../../l10n/l10n.dart';
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
      return AdhkarMoment('after_salah', l10n.afterSalah(s.label), afterPrayer: s);
    }
  }
  if (now.hour >= 3 && before(fajr)) return AdhkarMoment('waking', l10n.beforeFajr);
  if (!before(fajr) && before(sunrise)) return AdhkarMoment('morning', l10n.bestBeforeSunrise);
  if (!before(sunrise) && before(dhuhr)) {
    return isDone('morning')
        ? AdhkarMoment('tasbih', l10n.dhikrThroughDay)
        : AdhkarMoment('morning', l10n.stillTimeUntilDhuhr);
  }
  if (!before(dhuhr) && before(asr)) return AdhkarMoment('tasbih', l10n.dhikrThroughDay);
  if (!before(asr) && before(maghrib)) return AdhkarMoment('evening', l10n.bestBeforeMaghrib);
  if (!before(maghrib) && before(isha.add(const Duration(minutes: 40)))) {
    return isDone('evening')
        ? AdhkarMoment('quran_duas', l10n.duasOfQuran)
        : AdhkarMoment('evening', l10n.stillTimeTonight);
  }
  return AdhkarMoment('sleep', l10n.beforeYouSleep);
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

/// Names (in the app's language) and Arabic names of the adhkar [adhkarFor] can suggest.
Map<String, (String, String)> get adhkarNames => {
      'waking': (l10n.wakingUp, 'أذكار الاستيقاظ'),
      'morning': (l10n.morningAdhkar, 'أذكار الصباح'),
      'after_salah': (l10n.afterPrayer, 'أذكار بعد الصلاة'),
      'tasbih': (l10n.tasbihAndDhikr, 'التسبيح'),
      'evening': (l10n.eveningAdhkar, 'أذكار المساء'),
      'quran_duas': (l10n.duasOfQuran, 'أدعية قرآنية'),
      'sleep': (l10n.beforeSleep, 'أذكار النوم'),
    };
