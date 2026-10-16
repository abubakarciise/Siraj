import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'sounds.dart';

/// The three kinds of reminder; each has its own sound and Android channel.
enum ReminderKind { prayer, adhkar, daily }

extension ReminderKindX on ReminderKind {
  String get title => switch (this) {
        ReminderKind.prayer => 'Prayer times',
        ReminderKind.adhkar => 'Morning & evening adhkar',
        ReminderKind.daily => 'Daily reminders',
      };

  String get description => switch (this) {
        ReminderKind.prayer => 'A reminder when each prayer time begins',
        ReminderKind.adhkar => 'A reminder to read the morning and evening adhkar',
        ReminderKind.daily => 'An ayah, hadith, sunnah or dua through the day',
      };

  NotificationSound get defaultSound => switch (this) {
        ReminderKind.prayer => const NotificationSound.builtin('ocean'),
        ReminderKind.adhkar => const NotificationSound.builtin('birds'),
        ReminderKind.daily => const NotificationSound.builtin('stream'),
      };
}

/// Local (on-device) reminders: prayer times, adhkar, daily reminders. No server.
class NotificationService {
  NotificationService(this._prefs);
  final SharedPreferences _prefs;
  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String>.broadcast();

  /// Payloads like "adhkar:morning", "prayer", "ayah:2:255", "hadith:nawawi:1".
  Stream<String> get taps => _taps.stream;
  String? launchPayload;

  static const adhkarIds = (100, 120);
  static const dailyIds = (500, 700);
  static const prayerIds = (2000, 2100);
  static const testId = 9000;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
    } catch (e) {
      debugPrint('Timezone fallback: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_stat_quran'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) => _taps.add(r.payload ?? ''),
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) launchPayload = launch?.notificationResponse?.payload;
    await SoundService.installForIos();
    for (final k in ReminderKind.values) {
      await _ensureChannel(k);
    }
  }

  // ---- Sounds ----

  NotificationSound soundFor(ReminderKind kind) =>
      NotificationSound.decode(_prefs.getString('sound_${kind.name}'), kind.defaultSound);

  /// Saves the sound and creates its channel. Callers re-schedule afterwards so
  /// pending reminders move to the new channel.
  Future<void> setSound(ReminderKind kind, NotificationSound sound) async {
    await _prefs.setString('sound_${kind.name}', sound.encode());
    await _ensureChannel(kind);
  }

  String _channelId(ReminderKind kind) => '${kind.name}_${soundFor(kind).key}';

  Future<void> _ensureChannel(ReminderKind kind) async {
    final android = _android;
    if (android == null) return;
    final sound = soundFor(kind);
    final id = _channelId(kind);
    await android.createNotificationChannel(AndroidNotificationChannel(
      id,
      kind.title,
      description: '${kind.description} · ${sound.label}',
      importance: Importance.high,
      playSound: sound.plays,
      sound: switch (sound.kind) {
        SoundKind.builtin => RawResourceAndroidNotificationSound('snd_${sound.value}'),
        SoundKind.device => UriAndroidNotificationSound(sound.value),
        _ => null,
      },
      enableVibration: true,
      vibrationPattern: _vibration,
    ));
    // Remove channels for sounds no longer used (and the v1 channels, which
    // could have been created silent and can never be changed afterwards).
    final channels = await android.getNotificationChannels() ?? const [];
    for (final ch in channels) {
      final stale = (ch.id.startsWith('${kind.name}_') && ch.id != id) || ch.id == kind.name;
      if (stale) await android.deleteNotificationChannel(channelId: ch.id);
    }
  }

  /// Two soft pulses; the only signal when a reminder is set to vibration only.
  static final _vibration = Int64List.fromList([0, 250, 180, 250]);

  NotificationDetails _details(ReminderKind kind, {String? body}) {
    final sound = soundFor(kind);
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId(kind),
        kind.title,
        channelDescription: kind.description,
        importance: Importance.high,
        priority: Priority.high,
        playSound: sound.plays,
        sound: switch (sound.kind) {
          SoundKind.builtin => RawResourceAndroidNotificationSound('snd_${sound.value}'),
          SoundKind.device => UriAndroidNotificationSound(sound.value),
          _ => null,
        },
        enableVibration: true,
        vibrationPattern: _vibration,
        category: kind == ReminderKind.prayer ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
        styleInformation: body == null ? null : BigTextStyleInformation(body),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: sound.plays,
        sound: sound.kind == SoundKind.builtin ? '${sound.value}.wav' : null,
        interruptionLevel: kind == ReminderKind.prayer ? InterruptionLevel.timeSensitive : InterruptionLevel.active,
      ),
    );
  }

  // ---- Permissions ----

  Future<bool> requestPermission() async {
    if (_android != null) return await _android!.requestNotificationsPermission() ?? false;
    if (_ios != null) return await _ios!.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    return true;
  }

  /// Exact alarms make prayer reminders arrive on the minute (Android 12+ asks the user).
  Future<bool> ensureExactAlarms() async {
    final a = _android;
    if (a == null) return true;
    if (await a.canScheduleExactNotifications() ?? false) return true;
    await a.requestExactAlarmsPermission();
    return await a.canScheduleExactNotifications() ?? false;
  }

  Future<AndroidScheduleMode> _mode() async =>
      (await _android?.canScheduleExactNotifications() ?? true)
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

  // ---- Scheduling ----

  /// Repeats every day at [time].
  Future<void> scheduleDaily({
    required ReminderKind kind,
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
    required String payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: at,
      notificationDetails: _details(kind),
      androidScheduleMode: await _mode(),
      title: title,
      body: body,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleAt({
    required ReminderKind kind,
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!when.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: _details(kind, body: body),
      androidScheduleMode: await _mode(),
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Shows a sample right away so the user can hear the chosen sound.
  Future<void> showTest(ReminderKind kind) => _plugin.show(
        id: testId,
        title: switch (kind) {
          ReminderKind.prayer => 'Asr · العصر',
          ReminderKind.adhkar => 'أذكار المساء · Evening adhkar',
          ReminderKind.daily => 'Daily reminder',
        },
        body: switch (kind) {
          ReminderKind.prayer => 'It is time for Asr prayer',
          ReminderKind.adhkar => 'Time for your evening remembrance',
          ReminderKind.daily => '"Verily, in the remembrance of Allah do hearts find rest." (13:28)',
        },
        notificationDetails: _details(kind),
        payload: '',
      );

  Future<void> cancelRange((int, int) range) async {
    for (final p in await _plugin.pendingNotificationRequests()) {
      if (p.id >= range.$1 && p.id < range.$2) await _plugin.cancel(id: p.id);
    }
  }

  static bool get isIOS => Platform.isIOS;
}
