import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../adhkar/adhkar.dart';
import '../hadith/hadith.dart';
import '../notifications/notifications.dart';
import '../quran/models.dart';
import '../quran/quran_db.dart';

/// What daily reminders may contain.
enum ReminderContent { ayah, surah, hadith, sunnah, dhikr }

extension ReminderContentX on ReminderContent {
  String get label => switch (this) {
        ReminderContent.ayah => 'Ayah to reflect on',
        ReminderContent.surah => 'Surah to read',
        ReminderContent.hadith => 'Hadith',
        ReminderContent.sunnah => 'Sunnah to practise',
        ReminderContent.dhikr => 'Dhikr & dua',
      };
}

class DailyReminderSettings {
  const DailyReminderSettings({
    this.enabled = false,
    this.everyHours = 3,
    this.vary = true,
    this.from = const TimeOfDay(hour: 7, minute: 0),
    this.until = const TimeOfDay(hour: 22, minute: 0),
    this.content = const {...ReminderContent.values},
    this.hijriOffset = 0,
  });

  final bool enabled;

  /// 1, 2, 3, 4, 6 or 8.
  final int everyHours;

  /// Shift each reminder by a few random minutes so they feel less mechanical.
  final bool vary;

  /// Active hours; nothing is sent outside them.
  final TimeOfDay from, until;
  final Set<ReminderContent> content;

  /// Days added to the calculated (Umm al-Qura) Hijri date, for local moon sighting.
  final int hijriOffset;

  static const intervals = [1, 2, 3, 4, 6, 8];

  DailyReminderSettings copyWith({
    bool? enabled,
    int? everyHours,
    bool? vary,
    TimeOfDay? from,
    TimeOfDay? until,
    Set<ReminderContent>? content,
    int? hijriOffset,
  }) =>
      DailyReminderSettings(
        enabled: enabled ?? this.enabled,
        everyHours: everyHours ?? this.everyHours,
        vary: vary ?? this.vary,
        from: from ?? this.from,
        until: until ?? this.until,
        content: content ?? this.content,
        hijriOffset: hijriOffset ?? this.hijriOffset,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'every': everyHours,
        'vary': vary,
        'from': from.hour * 60 + from.minute,
        'until': until.hour * 60 + until.minute,
        'content': [for (final c in content) c.name],
        'hijri': hijriOffset,
      };

  static DailyReminderSettings fromJson(Map<String, dynamic> j) {
    TimeOfDay t(int m) => TimeOfDay(hour: m ~/ 60, minute: m % 60);
    return DailyReminderSettings(
      enabled: j['enabled'] as bool? ?? false,
      everyHours: j['every'] as int? ?? 3,
      vary: j['vary'] as bool? ?? true,
      from: t(j['from'] as int? ?? 420),
      until: t(j['until'] as int? ?? 1320),
      content: {
        for (final n in (j['content'] as List? ?? const []))
          if (ReminderContent.values.asNameMap()[n] case final c?) c,
      },
      hijriOffset: j['hijri'] as int? ?? 0,
    );
  }
}

/// One reminder, ready to show.
class Reminder {
  const Reminder({required this.title, required this.body, required this.payload, this.label});
  final String title, body, payload;

  /// Small heading for in-app cards ("Sunnah · Friday").
  final String? label;
}

const _hijriMonths = [
  'Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani', 'Jumada al-Ula', 'Jumada al-Akhirah', //
  'Rajab', "Sha'ban", 'Ramadan', 'Shawwal', 'Dhul Qadah', 'Dhul Hijjah',
];

const _hijriMonthsAr = [
  'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', //
  'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
];

class HijriDate {
  const HijriDate(this.year, this.month, this.day);
  final int year, month, day;

  String get monthName => _hijriMonths[month - 1];
  String get monthNameAr => _hijriMonthsAr[month - 1];
  String get label => '$day $monthName $year';

  /// The Islamic day begins at sunset; [evening] counts toward the next date.
  static HijriDate of(DateTime t, {int offset = 0, bool evening = false}) {
    final shifted = t.add(Duration(days: offset + (evening && t.hour >= 18 ? 1 : 0)));
    final h = HijriCalendar.fromDate(DateTime(shifted.year, shifted.month, shifted.day));
    return HijriDate(h.hYear, h.hMonth, h.hDay);
  }
}

/// Surahs suggested for reading, with plain, factual prompts.
const _surahSuggestions = [
  (36, 'Read Surah Ya-Sin', null),
  (55, 'Read Surah Ar-Rahman and reflect on the blessings of your Lord', null),
  (56, "Read Surah Al-Waqi'ah", null),
  (67, 'Read Surah Al-Mulk tonight', 'sleep'),
  (32, 'Read Surah As-Sajdah tonight', 'sleep'),
  (18, 'Friday: read Surah Al-Kahf', 'friday'),
  (19, 'Read Surah Maryam', null),
  (12, 'Read Surah Yusuf, "the best of stories"', null),
  (78, "Read Surah An-Naba'", null),
  (1, 'Reflect on Al-Fatihah, the Mother of the Book', null),
  (112, 'Read Al-Ikhlas, Al-Falaq and An-Nas', 'evening'),
  (2, 'Read the last two ayat of Al-Baqarah tonight', 'sleep'),
];

/// Picks reminder content that suits the moment: the day of the week, the
/// Hijri date (White Days, Ramadan, Dhul Hijjah, Ashura…), and the time of day.
class ReminderComposer {
  ReminderComposer(this._quran, this._hadith, this._adhkar, this._translation);
  final QuranDb _quran;
  final HadithRepository _hadith;
  final Future<List<AdhkarCategory>> _adhkar;

  /// The user's translation slug ('' = none).
  final String Function() _translation;

  /// Occasion tags that apply at [t].
  static Set<String> occasions(DateTime t, int hijriOffset) {
    final tags = <String>{};
    final h = HijriDate.of(t, offset: hijriOffset);
    final eve = HijriDate.of(t, offset: hijriOffset, evening: true); // the coming Islamic day after sunset
    final hour = t.hour;
    final wd = t.weekday;
    if (wd == DateTime.friday || (wd == DateTime.thursday && hour >= 18)) tags.add('friday');
    if ((wd == DateTime.sunday || wd == DateTime.wednesday) && hour >= 16) tags.add('mon_thu_eve');
    if ((h.day >= 12 && h.day <= 15) && h.month != 9) tags.add('white_days');
    if (h.month == 9 || eve.month == 9) tags.add('ramadan');
    if ((h.month == 9 && h.day >= 20) || (eve.month == 9 && eve.day >= 21)) tags.add('last_ten');
    if (h.month == 10 && h.day > 1) tags.add('shawwal');
    if (h.month == 12 && h.day <= 9) tags.add('dhul_hijjah');
    if (h.month == 12 && (h.day == 8 && hour >= 16 || h.day == 9)) tags.add('arafah');
    if (h.month == 1 && h.day >= 8 && h.day <= 10) tags.add('ashura');
    if (hour < 10) tags.addAll(['morning', 'fajr']);
    if (hour >= 16 && hour < 20) tags.add('evening');
    if (hour >= 21 || hour < 3) tags.addAll(['sleep', 'night']);
    return tags;
  }

  Future<Reminder> compose(DateTime t, DailyReminderSettings s, Random rnd) async {
    final tags = occasions(t, s.hijriOffset);
    final types = s.content.isEmpty ? {...ReminderContent.values} : s.content;

    // Occasions come first about half of the time, so special days are noticed
    // without every reminder being the same.
    if (rnd.nextDouble() < 0.5) {
      final seasonal = tags.difference({'morning', 'fajr', 'evening', 'night'});
      final special = [
        if (types.contains(ReminderContent.sunnah))
          for (final (i, item) in _hadith.sunnah.indexed)
            if (item.tags.any(seasonal.contains)) (i, item),
      ];
      if (special.isNotEmpty) {
        final (i, item) = special[rnd.nextInt(special.length)];
        return _sunnahReminder(i, item, tags);
      }
      if (types.contains(ReminderContent.surah)) {
        final fitting = _surahSuggestions.where((x) => x.$3 != null && tags.contains(x.$3)).toList();
        if (fitting.isNotEmpty) return _surahReminder(fitting[rnd.nextInt(fitting.length)]);
      }
    }

    final list = types.toList()..shuffle(rnd);
    for (final type in list) {
      final r = switch (type) {
        ReminderContent.ayah => await _ayahReminder(rnd),
        ReminderContent.surah => _surahReminder(_pickSurah(tags, rnd)),
        ReminderContent.hadith => await _hadithReminder(rnd),
        ReminderContent.sunnah => _pickSunnah(tags, rnd),
        ReminderContent.dhikr => _dhikrReminder(await _adhkar, tags, rnd),
      };
      if (r != null) return r;
    }
    return const Reminder(
      title: 'Remember Allah',
      body: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ · Glory be to Allah and praise be to Him',
      payload: 'adhkar:tasbih',
    );
  }

  (int, String, String?) _pickSurah(Set<String> tags, Random rnd) {
    final pool = _surahSuggestions.where((x) => x.$3 == null || tags.contains(x.$3)).toList();
    return pool[rnd.nextInt(pool.length)];
  }

  Reminder _surahReminder((int, String, String?) s) {
    final surah = _quran.surah(s.$1);
    return Reminder(
      title: '${surah.nameAr} · ${surah.nameEn}',
      body: '${s.$2} (${surah.ayahCount} ayat).',
      payload: 'surah:${s.$1}',
      label: 'Surah to read',
    );
  }

  Future<Reminder?> _ayahReminder(Random rnd) async {
    final a = await _quran.randomAyah(rnd, _translation());
    if (a == null) return null;
    final (ayah, translation) = a;
    final surah = _quran.surah(ayah.ref.surah);
    return Reminder(
      title: 'Reflect · ${surah.nameEn} ${ayah.ref}',
      body: '${ayah.plainText}${translation == null ? '' : '\n$translation'}',
      payload: 'ayah:${ayah.ref}',
      label: 'Ayah to reflect on',
    );
  }

  Future<Reminder?> _hadithReminder(Random rnd) async {
    final h = await _hadith.random(rnd);
    if (h == null) return null;
    final books = {for (final b in await _hadith.books()) b.id: b.nameEn};
    return Reminder(
      title: 'Hadith · ${books[h.book] ?? h.book} ${h.numberLabel}',
      body: h.english,
      payload: 'hadith:${h.book}:${h.numberLabel}',
      label: 'Hadith',
    );
  }

  Reminder? _pickSunnah(Set<String> tags, Random rnd) {
    final items = _hadith.sunnah.indexed
        .where((e) => e.$2.tags.contains('general') || e.$2.tags.any(tags.contains))
        .toList();
    if (items.isEmpty) return null;
    final (i, item) = items[rnd.nextInt(items.length)];
    return _sunnahReminder(i, item, tags);
  }

  Reminder _sunnahReminder(int index, SunnahItem item, Set<String> tags) => Reminder(
        title: 'Sunnah · ${item.title}',
        body: item.english,
        payload: 'sunnah:$index',
        label: tags.contains('friday') && item.tags.contains('friday') ? "Sunnah · Jumu'ah" : 'Sunnah to practise',
      );

  Reminder? _dhikrReminder(List<AdhkarCategory> adhkar, Set<String> tags, Random rnd) {
    final id = tags.contains('morning')
        ? 'morning'
        : tags.contains('evening')
            ? 'evening'
            : tags.contains('sleep')
                ? 'sleep'
                : (['tasbih', 'quran_duas', 'prophets_duas', 'tasbih']..shuffle(rnd)).first;
    final cat = adhkar.where((c) => c.id == id).firstOrNull;
    if (cat == null || cat.items.isEmpty) return null;
    final short = cat.items.where((d) => d.text.length < 320).toList();
    final d = (short.isEmpty ? cat.items : short)[rnd.nextInt(short.isEmpty ? cat.items.length : short.length)];
    return Reminder(
      title: '${cat.titleAr} · ${cat.titleEn}',
      body: '${d.text}${d.count > 1 ? '  (×${d.count})' : ''}',
      payload: 'adhkar:$id',
      label: 'Dhikr & dua',
    );
  }
}

/// Schedules the daily reminders ahead of time with pre-chosen content.
/// Re-planned on every app start and whenever the settings change.
class ReminderService {
  ReminderService(this._prefs, this._notifications, this.composer);
  final SharedPreferences _prefs;
  final NotificationService _notifications;
  final ReminderComposer composer;

  DailyReminderSettings get settings {
    final raw = _prefs.getString('daily_reminders');
    if (raw == null) return const DailyReminderSettings();
    final s = DailyReminderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    return s.content.isEmpty ? s.copyWith(content: {...ReminderContent.values}) : s;
  }

  Future<void> save(DailyReminderSettings s) async {
    await _prefs.setString('daily_reminders', jsonEncode(s.toJson()));
    await reschedule(s);
  }

  /// Reminder times from [start] for [days] days.
  static List<DateTime> slots(DailyReminderSettings s, DateTime start, int days, Random rnd) {
    final out = <DateTime>[];
    final from = s.from.hour * 60 + s.from.minute;
    var until = s.until.hour * 60 + s.until.minute;
    if (until <= from) until += 24 * 60; // active window crosses midnight
    final step = s.everyHours * 60;
    final day0 = DateTime(start.year, start.month, start.day);
    for (var d = 0; d <= days; d++) {
      // First reminder 30 minutes after the window opens, then every N hours.
      final first = min<int>(30, step ~/ 2);
      for (var m = from + first; m <= until; m += step) {
        var minute = m;
        if (s.vary) {
          final spread = max<int>(5, step ~/ 5);
          minute = (m + rnd.nextInt(spread * 2 + 1) - spread).clamp(from, until);
        }
        final t = day0.add(Duration(days: d, minutes: minute));
        if (t.isAfter(start.add(const Duration(minutes: 2)))) out.add(t);
      }
    }
    return out;
  }

  Future<void> reschedule([DailyReminderSettings? s]) async {
    s ??= settings;
    await _notifications.cancelRange(NotificationService.dailyIds);
    if (!s.enabled) return;
    final now = DateTime.now();
    final rnd = Random(now.millisecondsSinceEpoch);
    // iOS keeps at most 64 pending notifications app-wide (prayer times use ~35).
    final cap = Platform.isIOS ? 24 : (NotificationService.dailyIds.$2 - NotificationService.dailyIds.$1);
    final times = slots(s, now, 7, rnd).take(cap).toList();
    var id = NotificationService.dailyIds.$1;
    for (final t in times) {
      final r = await composer.compose(t, s, rnd);
      await _notifications.scheduleAt(
        kind: ReminderKind.daily,
        id: id++,
        when: t,
        title: r.title,
        body: r.body,
        payload: r.payload,
      );
    }
  }
}

extension AyahRefParse on String {
  AyahRef? toAyahRef() {
    final parts = split(':');
    if (parts.length != 2) return null;
    final s = int.tryParse(parts[0]), a = int.tryParse(parts[1]);
    return s == null || a == null ? null : AyahRef(s, a);
  }
}
