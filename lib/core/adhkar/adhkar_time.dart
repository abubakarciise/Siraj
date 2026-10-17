import '../prayer/prayer.dart';

/// Which adhkar suit this moment of the day.
class AdhkarMoment {
  const AdhkarMoment(this.categoryId, this.reason, {this.afterPrayer});

  /// An id in assets/adhkar/adhkar.json: waking, morning, after_salah, evening, sleep.
  final String categoryId;

  /// Why now, e.g. "Until Asr" or "After Dhuhr".
  final String reason;
  final Salah? afterPrayer;
}

/// The adhkar for [now], following the prayer times of [day]:
/// waking before Fajr, after each prayer for half an hour, morning until Asr,
/// evening until an hour after Isha, then before sleep.
AdhkarMoment adhkarFor(DateTime now, PrayerDay? day) {
  DateTime at(Salah s, int h, int m) => day?.times[s] ?? DateTime(now.year, now.month, now.day, h, m);
  final fajr = at(Salah.fajr, 5, 0);
  final asr = at(Salah.asr, 15, 30);
  final isha = at(Salah.isha, 19, 45);

  for (final (s, h, m) in const [
    (Salah.fajr, 5, 0),
    (Salah.dhuhr, 12, 30),
    (Salah.asr, 15, 30),
    (Salah.maghrib, 18, 15),
    (Salah.isha, 19, 45),
  ]) {
    final t = at(s, h, m);
    if (!now.isBefore(t) && now.isBefore(t.add(const Duration(minutes: 30)))) {
      return AdhkarMoment('after_salah', 'After ${s.en}', afterPrayer: s);
    }
  }
  if (now.hour >= 3 && now.isBefore(fajr)) return const AdhkarMoment('waking', 'Before Fajr');
  if (!now.isBefore(fajr) && now.isBefore(asr)) return const AdhkarMoment('morning', 'Until Asr');
  if (!now.isBefore(asr) && now.isBefore(isha.add(const Duration(hours: 1)))) {
    return const AdhkarMoment('evening', 'Until night');
  }
  return const AdhkarMoment('sleep', 'Tonight');
}
