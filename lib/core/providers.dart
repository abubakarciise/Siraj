import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'adhkar/adhkar.dart';
import 'adhkar/adhkar_player.dart';
import 'audio/player_controller.dart';
import 'audio/timing.dart';
import 'catalog/catalog.dart';
import 'downloads/download_manager.dart';
import 'hadith/hadith.dart';
import 'notifications/notifications.dart';
import 'prayer/prayer.dart';
import 'quran/models.dart';
import 'quran/quran_db.dart';
import 'reminders/reminders.dart';
import 'settings.dart';
import 'user/user_store.dart';

// ---- Singletons created in bootstrap (overridden in main.dart) ----
final quranDbProvider = Provider<QuranDb>((ref) => throw UnimplementedError());
final userStoreProvider = Provider<UserStore>((ref) => throw UnimplementedError());
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());
final timingProvider = Provider<TimingService>((ref) => throw UnimplementedError());
final downloadManagerProvider = Provider<DownloadManager>((ref) => throw UnimplementedError());
final playerProvider = Provider<PlayerController>((ref) => throw UnimplementedError());

// ---- Settings ----
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => AppSettings.load(ref.watch(prefsProvider));

  void update(AppSettings Function(AppSettings) change) {
    state = change(state);
    state.save(ref.read(prefsProvider));
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// ---- Content ----
final surahsProvider = Provider<List<Surah>>((ref) => ref.watch(quranDbProvider).surahs);

final mushafPageProvider = FutureProvider.family<MushafPage, int>((ref, page) => ref.watch(quranDbProvider).page(page));

final surahAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, s) => ref.watch(quranDbProvider).ayahsOfSurah(s));

final surahTranslationProvider = FutureProvider.family<Map<int, String>, int>((ref, s) {
  final slug = ref.watch(settingsProvider.select((x) => x.translation));
  return slug.isEmpty ? Future.value(const {}) : ref.watch(quranDbProvider).translationsOfSurah(s, slug);
});

final juzListProvider = FutureProvider<List<JuzInfo>>((ref) => ref.watch(quranDbProvider).juzList());

final ayahOfDayProvider = FutureProvider<Ayah>((ref) => ref.watch(quranDbProvider).ayahOfTheDay(DateTime.now()));

// ---- Catalog: bundled snapshot, then refreshed from mp3quran.net when stale ----
class CatalogNotifier extends AsyncNotifier<Catalog> {
  final _repo = CatalogRepository();

  @override
  Future<Catalog> build() async {
    final catalog = await _repo.load();
    _refreshIfStale();
    return catalog;
  }

  Future<void> _refreshIfStale() async {
    if (!await _repo.needsRefresh()) return;
    final fresh = await _repo.refresh();
    if (fresh != null) state = AsyncData(fresh);
  }
}

final catalogProvider = AsyncNotifierProvider<CatalogNotifier, Catalog>(CatalogNotifier.new);

// ---- User data ----
class FavoritesNotifier extends AsyncNotifier<Set<int>> {
  @override
  Future<Set<int>> build() => ref.watch(userStoreProvider).favorites();

  Future<void> toggle(int reciterId) async {
    final current = {...(state.value ?? <int>{})};
    final fav = !current.contains(reciterId);
    fav ? current.add(reciterId) : current.remove(reciterId);
    state = AsyncData(current);
    await ref.read(userStoreProvider).setFavorite(reciterId, fav);
  }
}

final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, Set<int>>(FavoritesNotifier.new);

final bookmarksProvider = FutureProvider<List<Bookmark>>((ref) => ref.watch(userStoreProvider).bookmarks());
final lastReadProvider = FutureProvider<LastRead?>((ref) => ref.watch(userStoreProvider).lastRead());
final lastListeningProvider = FutureProvider<ListeningState?>((ref) {
  // Read again whenever another recitation or surah starts playing.
  ref.watch(nowPlayingProvider.select((v) => (v.value?.recitation.key, v.value?.surah)));
  return ref.watch(userStoreProvider).lastListening();
});

// ---- Live streams ----
final downloadsProvider = StreamProvider<DownloadsState>((ref) async* {
  final dm = ref.watch(downloadManagerProvider);
  yield dm.state;
  yield* dm.stream;
});

final nowPlayingProvider = StreamProvider<NowPlaying?>((ref) async* {
  final pc = ref.watch(playerProvider);
  yield pc.now;
  yield* pc.stream;
});

// ---- Daily essentials: prayer times, adhkar, tasbih ----
final notificationsProvider = Provider<NotificationService>((ref) => throw UnimplementedError());
final prayerServiceProvider = Provider<PrayerService>((ref) => throw UnimplementedError());

class PrayerSettingsNotifier extends Notifier<PrayerSettings> {
  @override
  PrayerSettings build() => ref.watch(prayerServiceProvider).settings;

  Future<void> update(PrayerSettings s) async {
    state = s;
    await ref.read(prayerServiceProvider).save(s);
  }

  Future<void> locate() async => state = await ref.read(prayerServiceProvider).locate();
  Future<void> chooseCity(City c) async => state = await ref.read(prayerServiceProvider).chooseCity(c);
}

final prayerSettingsProvider = NotifierProvider<PrayerSettingsNotifier, PrayerSettings>(PrayerSettingsNotifier.new);

/// Ticks every second for countdowns (only while something listens).
final clockProvider = StreamProvider.autoDispose<DateTime>(
  (ref) => Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
);

final adhkarProvider = FutureProvider<List<AdhkarCategory>>((ref) => AdhkarRepository.load());

final adhkarPlayerProvider = Provider<AdhkarPlayer>((ref) {
  final quran = ref.read(playerProvider);
  final player = AdhkarPlayer(
    handler: quran.handler,
    beforeStart: quran.stop,
    onCompleted: (cat) {
      final d = DateTime.now();
      final prefs = ref.read(prefsProvider);
      prefs.setString('adhkar_done_${cat.id}', '${d.year}-${d.month}-${d.day}');
      // After prayer: which prayer it was done for (the time it was completed).
      if (cat.id == 'after_salah') prefs.setInt('adhkar_done_at_after_salah', d.millisecondsSinceEpoch);
    },
    prefs: ref.read(prefsProvider),
    // The adhkar after prayer are counted afresh for each prayer; the rest each day.
    scopeOf: (id) {
      final d = DateTime.now();
      final day = '${d.year}-${d.month}-${d.day}';
      if (id != 'after_salah') return day;
      final prayer = ref.read(prayerServiceProvider).day(d)?.currentAt(d);
      return '$day-${prayer?.name}';
    },
  );
  ref.onDispose(player.dispose);
  return player;
});

// ---- Hadith ----
final hadithRepoProvider = Provider<HadithRepository>((ref) => throw UnimplementedError());

final hadithBooksProvider = StreamProvider<List<HadithBook>>((ref) async* {
  final repo = ref.watch(hadithRepoProvider);
  yield await repo.books();
  await for (final d in repo.downloads) {
    if (d.stage == HadithDlStage.done) yield await repo.books();
  }
});

/// In-flight hadith book downloads, keyed by book id.
final hadithDownloadsProvider = StreamProvider<Map<String, HadithDownload>>((ref) async* {
  final repo = ref.watch(hadithRepoProvider);
  yield repo.active;
  await for (final _ in repo.downloads) {
    yield repo.active;
  }
});

final hadithSectionsProvider =
    FutureProvider.family<List<HadithSection>, String>((ref, book) => ref.watch(hadithRepoProvider).sections(book));

final hadithListProvider = FutureProvider.family<List<Hadith>, (String, int?)>(
    (ref, k) => ref.watch(hadithRepoProvider).hadiths(k.$1, section: k.$2));

final hadithProvider = FutureProvider.family<Hadith?, (String, num)>(
    (ref, k) => ref.watch(hadithRepoProvider).hadith(k.$1, k.$2));

final hadithBookmarksProvider = FutureProvider<List<Hadith>>((ref) => ref.watch(hadithRepoProvider).bookmarks());

// ---- Daily reminders ----
final reminderServiceProvider = Provider<ReminderService>((ref) => throw UnimplementedError());
class DailyRemindersNotifier extends Notifier<DailyReminderSettings> {
  @override
  DailyReminderSettings build() => ref.watch(reminderServiceProvider).settings;

  Future<void> update(DailyReminderSettings s) async {
    state = s;
    await ref.read(reminderServiceProvider).save(s);
  }
}

final dailyRemindersProvider =
    NotifierProvider<DailyRemindersNotifier, DailyReminderSettings>(DailyRemindersNotifier.new);

/// Today's Hijri date (with the user's moon-sighting adjustment).
final hijriTodayProvider = Provider<HijriDate>((ref) {
  final offset = ref.watch(dailyRemindersProvider.select((s) => s.hijriOffset));
  return HijriDate.of(DateTime.now(), offset: offset, evening: true);
});

/// A reminder chosen for right now, shown on Home ("For you today").
final reminderNowProvider = FutureProvider.autoDispose<Reminder>((ref) {
  final s = ref.watch(dailyRemindersProvider);
  final now = DateTime.now();
  // Stable within the hour, so the card doesn't change on every rebuild.
  final seed = now.year * 1000000 + now.month * 10000 + now.day * 100 + now.hour;
  return ref.watch(reminderServiceProvider).composer.compose(now, s, Random(seed));
});
