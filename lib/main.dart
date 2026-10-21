import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/payload.dart';
import 'app/router.dart';
import 'core/adhkar/adhkar.dart';
import 'core/audio/audio_handler.dart';
import 'core/audio/player_controller.dart';
import 'core/audio/timing.dart';
import 'core/downloads/download_manager.dart';
import 'core/hadith/hadith.dart';
import 'core/notifications/notifications.dart';
import 'core/prayer/prayer.dart';
import 'core/providers.dart';
import 'core/quran/quran_db.dart';
import 'core/reminders/reminders.dart';
import 'core/settings.dart';
import 'core/user/user_store.dart';
import 'l10n/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Texts shown before the first screen (notifications, the player) use the phone's language too.
  setL10nLocale(basicLocaleListResolution(
      WidgetsBinding.instance.platformDispatcher.locales, AppLocalizations.supportedLocales));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Phones stay in portrait (landscape leaves too little height for the
  // reader and player); tablets rotate freely.
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  if (view.physicalSize.shortestSide / view.devicePixelRatio < 600) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // Everything is on-device: no backend, no account.
  final (db, user, prefs, hadith) =
      await (QuranDb.open(), UserStore.open(), SharedPreferences.getInstance(), HadithRepository.open()).wait;

  final handler = await AudioService.init(
    builder: QuranAudioHandler.new,
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.quranapp.playback',
      androidNotificationChannelName: l10n.sirajPlayback,
      androidNotificationIcon: 'drawable/ic_stat_quran',
      // Paused audio can be swiped away from the notification shade.
      androidStopForegroundOnPause: true,
    ),
  );
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  final timing = TimingService();
  final downloads = DownloadManager(timing);
  await downloads.init();
  final player = PlayerController(handler, db, downloads, timing, user);

  final notifications = NotificationService(prefs);
  await notifications.init();
  final prayer = PrayerService(prefs, notifications);
  final reminders = ReminderService(
    prefs,
    notifications,
    ReminderComposer(db, hadith, AdhkarRepository.load(), () => AppSettings.load(prefs).translation),
  );
  // Keep the prayer and daily-reminder windows rolling; never block startup on it.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await prayer.reschedule().catchError((Object e) => debugPrint('Prayer reminders: $e'));
    await reminders.reschedule().catchError((Object e) => debugPrint('Daily reminders: $e'));
  });
  void route(String payload) => openPayload(appRouter, db, payload);

  notifications.taps.listen(route);
  if (notifications.launchPayload != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) => route(notifications.launchPayload!));
  }

  runApp(ProviderScope(
    overrides: [
      quranDbProvider.overrideWithValue(db),
      userStoreProvider.overrideWithValue(user),
      prefsProvider.overrideWithValue(prefs),
      timingProvider.overrideWithValue(timing),
      downloadManagerProvider.overrideWithValue(downloads),
      playerProvider.overrideWithValue(player),
      notificationsProvider.overrideWithValue(notifications),
      prayerServiceProvider.overrideWithValue(prayer),
      hadithRepoProvider.overrideWithValue(hadith),
      reminderServiceProvider.overrideWithValue(reminders),
    ],
    child: const QuranApp(),
  ));
}
