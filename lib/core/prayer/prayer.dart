import 'dart:convert';
import 'dart:math' as math;

import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notifications/notifications.dart';

enum Salah { fajr, sunrise, dhuhr, asr, maghrib, isha }

extension SalahX on Salah {
  String get en => switch (this) {
        Salah.fajr => 'Fajr',
        Salah.sunrise => 'Sunrise',
        Salah.dhuhr => 'Dhuhr',
        Salah.asr => 'Asr',
        Salah.maghrib => 'Maghrib',
        Salah.isha => 'Isha',
      };
  String get ar => switch (this) {
        Salah.fajr => 'الفجر',
        Salah.sunrise => 'الشروق',
        Salah.dhuhr => 'الظهر',
        Salah.asr => 'العصر',
        Salah.maghrib => 'المغرب',
        Salah.isha => 'العشاء',
      };
  bool get isPrayer => this != Salah.sunrise;
}

class City {
  const City(this.name, this.lat, this.lng, [this.method = adhan.CalculationMethod.muslim_world_league]);
  final String name;
  final double lat, lng;
  final adhan.CalculationMethod method;
}

/// Offline city list: used for manual selection, naming GPS fixes, and
/// suggesting the locally customary calculation method.
const kCities = [
  City('Mogadishu', 2.0469, 45.3182),
  City('Hargeisa', 9.5600, 44.0650),
  City('Kismayo', -0.3582, 42.5454),
  City('Garowe', 8.4054, 48.4845),
  City('Bosaso', 11.2842, 49.1816),
  City('Baidoa', 3.1167, 43.6500),
  City('Djibouti', 11.5880, 43.1450),
  City('Nairobi', -1.2864, 36.8172),
  City('Addis Ababa', 9.0300, 38.7400),
  City('Khartoum', 15.5007, 32.5599, adhan.CalculationMethod.egyptian),
  City('Makkah', 21.4225, 39.8262, adhan.CalculationMethod.umm_al_qura),
  City('Madinah', 24.4672, 39.6111, adhan.CalculationMethod.umm_al_qura),
  City('Riyadh', 24.7136, 46.6753, adhan.CalculationMethod.umm_al_qura),
  City('Jeddah', 21.4858, 39.1925, adhan.CalculationMethod.umm_al_qura),
  City('Dubai', 25.2048, 55.2708, adhan.CalculationMethod.dubai),
  City('Doha', 25.2854, 51.5310, adhan.CalculationMethod.qatar),
  City('Kuwait City', 29.3759, 47.9774, adhan.CalculationMethod.kuwait),
  City('Cairo', 30.0444, 31.2357, adhan.CalculationMethod.egyptian),
  City('Amman', 31.9454, 35.9284),
  City('Istanbul', 41.0082, 28.9784, adhan.CalculationMethod.turkey),
  City('Karachi', 24.8607, 67.0011, adhan.CalculationMethod.karachi),
  City('Lahore', 31.5204, 74.3587, adhan.CalculationMethod.karachi),
  City('Dhaka', 23.8103, 90.4125, adhan.CalculationMethod.karachi),
  City('Jakarta', -6.2088, 106.8456, adhan.CalculationMethod.singapore),
  City('Kuala Lumpur', 3.1390, 101.6869, adhan.CalculationMethod.singapore),
  City('Lagos', 6.5244, 3.3792),
  City('Casablanca', 33.5731, -7.5898),
  City('Johannesburg', -26.2041, 28.0473),
  City('London', 51.5074, -0.1278),
  City('Birmingham', 52.4862, -1.8904),
  City('Paris', 48.8566, 2.3522),
  City('Amsterdam', 52.3676, 4.9041),
  City('Berlin', 52.5200, 13.4050),
  City('Oslo', 59.9139, 10.7522),
  City('Stockholm', 59.3293, 18.0686),
  City('Toronto', 43.6532, -79.3832, adhan.CalculationMethod.north_america),
  City('New York', 40.7128, -74.0060, adhan.CalculationMethod.north_america),
  City('Minneapolis', 44.9778, -93.2650, adhan.CalculationMethod.north_america),
  City('Columbus', 39.9612, -82.9988, adhan.CalculationMethod.north_america),
  City('Sydney', -33.8688, 151.2093),
  City('Melbourne', -37.8136, 144.9631),
];

const kMethodNames = {
  adhan.CalculationMethod.muslim_world_league: 'Muslim World League',
  adhan.CalculationMethod.umm_al_qura: 'Umm al-Qura (Makkah)',
  adhan.CalculationMethod.egyptian: 'Egyptian General Authority',
  adhan.CalculationMethod.karachi: 'University of Islamic Sciences, Karachi',
  adhan.CalculationMethod.north_america: 'ISNA (North America)',
  adhan.CalculationMethod.dubai: 'Dubai',
  adhan.CalculationMethod.qatar: 'Qatar',
  adhan.CalculationMethod.kuwait: 'Kuwait',
  adhan.CalculationMethod.turkey: 'Diyanet (Turkey)',
  adhan.CalculationMethod.singapore: 'Singapore / Southeast Asia',
  adhan.CalculationMethod.moon_sighting_committee: 'Moonsighting Committee',
};

class PrayerSettings {
  const PrayerSettings({
    this.lat,
    this.lng,
    this.place,
    this.method = adhan.CalculationMethod.muslim_world_league,
    this.hanafi = false,
    this.notify = const {Salah.fajr, Salah.dhuhr, Salah.asr, Salah.maghrib, Salah.isha},
    this.adhkarReminders = true,
    this.morning = const TimeOfDay(hour: 6, minute: 30),
    this.evening = const TimeOfDay(hour: 17, minute: 0),
  });

  final double? lat, lng;
  final String? place;
  final adhan.CalculationMethod method;
  final bool hanafi, adhkarReminders;
  final Set<Salah> notify;
  final TimeOfDay morning, evening;

  bool get hasLocation => lat != null && lng != null;

  PrayerSettings copyWith({
    double? lat,
    double? lng,
    String? place,
    adhan.CalculationMethod? method,
    bool? hanafi,
    Set<Salah>? notify,
    bool? adhkarReminders,
    TimeOfDay? morning,
    TimeOfDay? evening,
  }) =>
      PrayerSettings(
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        place: place ?? this.place,
        method: method ?? this.method,
        hanafi: hanafi ?? this.hanafi,
        notify: notify ?? this.notify,
        adhkarReminders: adhkarReminders ?? this.adhkarReminders,
        morning: morning ?? this.morning,
        evening: evening ?? this.evening,
      );

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'place': place,
        'method': method.name,
        'hanafi': hanafi,
        'notify': [for (final s in notify) s.name],
        'adhkar': adhkarReminders,
        'morning': morning.hour * 60 + morning.minute,
        'evening': evening.hour * 60 + evening.minute,
      };

  static PrayerSettings fromJson(Map<String, dynamic> j) {
    TimeOfDay t(int m) => TimeOfDay(hour: m ~/ 60, minute: m % 60);
    return PrayerSettings(
      lat: (j['lat'] as num?)?.toDouble(),
      lng: (j['lng'] as num?)?.toDouble(),
      place: j['place'] as String?,
      method: adhan.CalculationMethod.values.firstWhere((m) => m.name == j['method'],
          orElse: () => adhan.CalculationMethod.muslim_world_league),
      hanafi: j['hanafi'] as bool? ?? false,
      notify: {for (final n in (j['notify'] as List? ?? const [])) Salah.values.byName(n as String)},
      adhkarReminders: j['adhkar'] as bool? ?? true,
      morning: t(j['morning'] as int? ?? 390),
      evening: t(j['evening'] as int? ?? 1020),
    );
  }
}

class PrayerDay {
  const PrayerDay(this.date, this.times);
  final DateTime date;
  final Map<Salah, DateTime> times;

  /// Next prayer (not sunrise) after [now] on this day, or null after Isha.
  (Salah, DateTime)? nextAfter(DateTime now) {
    for (final s in Salah.values) {
      if (s.isPrayer && times[s]!.isAfter(now)) return (s, times[s]!);
    }
    return null;
  }

  Salah? currentAt(DateTime now) {
    Salah? cur;
    for (final s in Salah.values) {
      if (!times[s]!.isAfter(now)) cur = s;
    }
    return cur;
  }
}

/// Prayer times calculated on the phone (Adhan library), with GPS or a
/// chosen city, and local notifications scheduled a week ahead.
class PrayerService {
  PrayerService(this._prefs, this._notifications);
  final SharedPreferences _prefs;
  final NotificationService _notifications;

  /// Location is fixed to Makkah (Umm al-Qura); other preferences are the user's.
  static const _makkah = City('Makkah', 21.4225, 39.8262, adhan.CalculationMethod.umm_al_qura);

  PrayerSettings get settings {
    final raw = _prefs.getString('prayer_settings');
    final s = raw == null ? const PrayerSettings() : PrayerSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return s.copyWith(lat: _makkah.lat, lng: _makkah.lng, place: _makkah.name, method: _makkah.method);
  }

  Future<void> save(PrayerSettings s) async {
    await _prefs.setString('prayer_settings', jsonEncode(s.toJson()));
    await reschedule(s);
  }

  PrayerDay? day(DateTime date, [PrayerSettings? s]) {
    s ??= settings;
    if (!s.hasLocation) return null;
    final params = s.method.getParameters()..madhab = s.hanafi ? adhan.Madhab.hanafi : adhan.Madhab.shafi;
    if (s.lat!.abs() > 48) params.highLatitudeRule = adhan.HighLatitudeRule.seventh_of_the_night;
    final pt = adhan.PrayerTimes(adhan.Coordinates(s.lat!, s.lng!), adhan.DateComponents.from(date), params);
    return PrayerDay(DateTime(date.year, date.month, date.day), {
      Salah.fajr: pt.fajr.toLocal(),
      Salah.sunrise: pt.sunrise.toLocal(),
      Salah.dhuhr: pt.dhuhr.toLocal(),
      Salah.asr: pt.asr.toLocal(),
      Salah.maghrib: pt.maghrib.toLocal(),
      Salah.isha: pt.isha.toLocal(),
    });
  }

  /// The next prayer from now, looking into tomorrow after Isha.
  (Salah, DateTime)? next(DateTime now) {
    final today = day(now);
    if (today == null) return null;
    return today.nextAfter(now) ?? day(now.add(const Duration(days: 1)))!.nextAfter(DateTime(now.year, now.month, now.day));
  }

  /// Where the phone is, for the Qibla (prayer times stay on Makkah).
  City? get qiblaPlace {
    final raw = _prefs.getString('qibla_location');
    if (raw == null) return null;
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return City(j['place'] as String, (j['lat'] as num).toDouble(), (j['lng'] as num).toDouble());
  }

  Future<void> setQiblaPlace(City c) =>
      _prefs.setString('qibla_location', jsonEncode({'place': c.name, 'lat': c.lat, 'lng': c.lng}));

  double? qiblaBearing() {
    final c = qiblaPlace;
    return c == null ? null : adhan.Qibla(adhan.Coordinates(c.lat, c.lng)).direction;
  }

  /// GPS fix for the Qibla, saved as the Qibla location.
  Future<City> locateQibla() async {
    final pos = await _position();
    final near = nearestCity(pos.latitude, pos.longitude);
    final c = City(near.$2 < 60 ? near.$1.name : 'Current location', pos.latitude, pos.longitude);
    await setQiblaPlace(c);
    return c;
  }

  Future<Position> _position() async {
    if (!await Geolocator.isLocationServiceEnabled()) throw const LocationException('Turn on location services');
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      throw const LocationException('Location permission was denied');
    }
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 15)),
      );
    } catch (_) {
      pos = await Geolocator.getLastKnownPosition();
    }
    if (pos == null) throw const LocationException('Could not get your location');
    return pos;
  }

  /// One GPS fix (coarse accuracy is enough for prayer times).
  Future<PrayerSettings> locate() async {
    final pos = await _position();
    final near = nearestCity(pos.latitude, pos.longitude);
    final s = settings.copyWith(
      lat: pos.latitude,
      lng: pos.longitude,
      place: near.$2 < 60 ? near.$1.name : 'Current location',
      method: settings.hasLocation ? settings.method : near.$1.method,
    );
    await save(s);
    return s;
  }

  Future<PrayerSettings> chooseCity(City c) async {
    final s = settings.copyWith(lat: c.lat, lng: c.lng, place: c.name, method: c.method);
    await save(s);
    return s;
  }

  static (City, double) nearestCity(double lat, double lng) {
    var best = kCities.first;
    var bestKm = double.infinity;
    for (final c in kCities) {
      final km = _haversineKm(lat, lng, c.lat, c.lng);
      if (km < bestKm) {
        best = c;
        bestKm = km;
      }
    }
    return (best, bestKm);
  }

  static double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  /// Re-plans all reminders: adhkar daily, prayers for the next 7 days.
  /// Called on every app start so the prayer window keeps rolling forward.
  Future<void> reschedule([PrayerSettings? s]) async {
    s ??= settings;
    await _notifications.cancelRange(NotificationService.adhkarIds);
    if (s.adhkarReminders) {
      await _notifications.scheduleDaily(
        kind: ReminderKind.adhkar,
        id: NotificationService.adhkarIds.$1,
        time: s.morning,
        title: 'أذكار الصباح · Morning adhkar',
        body: 'Time to read the morning adhkar. Begin your day with the remembrance of Allah',
        payload: 'adhkar:morning',
      );
      await _notifications.scheduleDaily(
        kind: ReminderKind.adhkar,
        id: NotificationService.adhkarIds.$1 + 1,
        time: s.evening,
        title: 'أذكار المساء · Evening adhkar',
        body: 'Time to read the evening adhkar',
        payload: 'adhkar:evening',
      );
    }
    await _notifications.cancelRange(NotificationService.prayerIds);
    if (!s.hasLocation || s.notify.isEmpty) return;
    final now = DateTime.now();
    var id = NotificationService.prayerIds.$1;
    for (var d = 0; d < 7; d++) {
      final pd = day(now.add(Duration(days: d)), s)!;
      for (final salah in Salah.values) {
        if (!salah.isPrayer || !s.notify.contains(salah)) continue;
        await _notifications.scheduleAt(
          kind: ReminderKind.prayer,
          id: id++,
          when: pd.times[salah]!,
          title: '${salah.en} · ${salah.ar}',
          body: 'It is time for ${salah.en} prayer${s.place == null ? '' : ' in ${s.place}'}',
          payload: 'prayer',
        );
      }
    }
  }
}

class LocationException implements Exception {
  const LocationException(this.message);
  final String message;
  @override
  String toString() => message;
}
