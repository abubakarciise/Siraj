// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Siraj';

  @override
  String get home => 'Home';

  @override
  String get quran => 'Quran';

  @override
  String get listen => 'Listen';

  @override
  String get hadith => 'Hadith';

  @override
  String get daily => 'Daily';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String get muharram => 'Muharram';

  @override
  String get safar => 'Safar';

  @override
  String get rabiAlAwwal => 'Rabi al-Awwal';

  @override
  String get rabiAlThani => 'Rabi al-Thani';

  @override
  String get jumadaAlUla => 'Jumada al-Ula';

  @override
  String get jumadaAlAkhirah => 'Jumada al-Akhirah';

  @override
  String get rajab => 'Rajab';

  @override
  String get shaban => 'Sha\'ban';

  @override
  String get ramadan => 'Ramadan';

  @override
  String get shawwal => 'Shawwal';

  @override
  String get dhulQadah => 'Dhul Qadah';

  @override
  String get dhulHijjah => 'Dhul Hijjah';

  @override
  String homeDateLine(String weekday, int day, String month, int year) {
    return '$weekday · $day $month $year';
  }

  @override
  String get greetingNight => 'Peaceful night';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get search => 'Search';

  @override
  String get settings => 'Settings';

  @override
  String get kahfFriday => 'Surah Al-Kahf · Jumu\'ah';

  @override
  String get kahfFridaySubtitle => 'The Sunnah of Friday';

  @override
  String get explore => 'Explore';

  @override
  String get practise => 'Practise';

  @override
  String get doneTodayAccepted => 'Done today · تقبّل الله';

  @override
  String countedOfTotalRead(int counted, int total) {
    return '$counted of $total read';
  }

  @override
  String get openTasbih => 'Open Tasbih';

  @override
  String get continueAction => 'Continue';

  @override
  String get read => 'Read';

  @override
  String actionWithTime(String action, String time) {
    return '$action · $time';
  }

  @override
  String get testYourHifz => 'Test your hifz';

  @override
  String get testYourHifzSubtitle => 'Surahs, juz or the whole Quran';

  @override
  String lastQuizResult(String scope, int score, int total) {
    return 'Last: $scope · $score/$total';
  }

  @override
  String get adhkar => 'Adhkar';

  @override
  String get prayer => 'Prayer';

  @override
  String get qibla => 'Qibla';

  @override
  String get tasbih => 'Tasbih';

  @override
  String get saved => 'Saved';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get retry => 'Retry';

  @override
  String get paused => 'Paused';

  @override
  String get queued => 'Queued';

  @override
  String get downloading => 'Downloading';

  @override
  String get download => 'Download';

  @override
  String dhikrYourTurn(int number) {
    return 'Dhikr $number · your turn to read';
  }

  @override
  String dhikrOf(int number, int total) {
    return 'Dhikr $number of $total';
  }

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Play';

  @override
  String get stop => 'Stop';

  @override
  String get completedTodayAccepted => 'Completed today · تقبّل الله';

  @override
  String get essentials => 'Essentials';

  @override
  String get reminders => 'Reminders';

  @override
  String get remindersCardSubtitle =>
      'Adhkar, prayer times and daily reminders';

  @override
  String get prayerTimes => 'Prayer times';

  @override
  String get beforeSleep => 'Before sleep';

  @override
  String get afterPrayer => 'After prayer';

  @override
  String get completedAccepted => 'Completed · تقبّل الله منا ومنكم';

  @override
  String couldNotLoadAdhkar(String error) {
    return 'Could not load adhkar\n$error';
  }

  @override
  String adhkarCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adhkar',
      one: '1 dhikr',
    );
    return '$_temp0';
  }

  @override
  String get startAgain => 'Start again';

  @override
  String backToDhikr(int number) {
    return 'Back to dhikr $number';
  }

  @override
  String modeWithTime(String mode, String time) {
    return '$mode · $time';
  }

  @override
  String get listenShort => 'Short';

  @override
  String get listenFullCount => 'Full count';

  @override
  String get reciting => 'RECITING';

  @override
  String quranReference(String reference) {
    return 'Quran $reference';
  }

  @override
  String timesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String get done => 'Done';

  @override
  String get tapWhenRead => 'Tap when read';

  @override
  String ofCountTap(int count) {
    return 'of $count · tap';
  }

  @override
  String get continueListening => 'Continue listening';

  @override
  String get listenFullCountHint => 'Each dhikr as many times as it is said';

  @override
  String get listenShortHint => 'A hundred-times dhikr plays ten times';

  @override
  String resumeFromDhikr(int number) {
    return 'From dhikr $number, where you stopped';
  }

  @override
  String get yourTurnReadThenTap => 'Your turn: read, then tap';

  @override
  String recitationOf(int number, int total) {
    return 'Recitation $number of $total';
  }

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get stopListening => 'Stop listening';

  @override
  String listeningTime(String time) {
    return '$time of listening';
  }

  @override
  String listeningTimeToRead(String time, int count) {
    return '$time of listening · $count to read';
  }

  @override
  String countdownHoursMinutes(int hours, String minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String countdownMinutesSeconds(int minutes, String seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String countdownSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get setLocationForPrayerTimes =>
      'Set your location to see prayer times and Qibla';

  @override
  String get myLocation => 'My location';

  @override
  String get prayerTimeNow => 'PRAYER TIME · NOW';

  @override
  String get nextPrayer => 'NEXT PRAYER';

  @override
  String beganAgo(String time) {
    return 'began $time ago';
  }

  @override
  String inTime(String time) {
    return 'in $time';
  }

  @override
  String get yourLocation => 'Your location';

  @override
  String get locationUseNote =>
      'Used only on your phone to calculate prayer times and the Qibla direction.';

  @override
  String get findingYou => 'Finding you…';

  @override
  String get useMyCurrentLocation => 'Use my current location';

  @override
  String get orSearchCity => 'Or search a city';

  @override
  String locationErrorPickCity(String error) {
    return '$error. You can pick your city instead.';
  }

  @override
  String get calculationSettings => 'Calculation settings';

  @override
  String get setYourLocation => 'Set your location';

  @override
  String get prayerTimesOffline =>
      'Prayer times are calculated on your phone. No internet needed.';

  @override
  String get chooseLocation => 'Choose location';

  @override
  String get nowLabel => 'NOW';

  @override
  String get nextLabel => 'NEXT';

  @override
  String labelWithArabic(String label, String arabic) {
    return '$label · $arabic';
  }

  @override
  String timeBeganAgo(String time, String ago) {
    return '$time · began $ago ago';
  }

  @override
  String timeIn(String time, String wait) {
    return '$time · in $wait';
  }

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String methodAndAsr(String method, String asr) {
    return '$method · Asr: $asr';
  }

  @override
  String get asrHanafi => 'Hanafi';

  @override
  String get asrStandardLong => 'Standard (Shafi, Maliki, Hanbali)';

  @override
  String get calculation => 'Calculation';

  @override
  String get asrTime => 'Asr time';

  @override
  String get asrStandard => 'Standard';

  @override
  String get reminderOn => 'Reminder on';

  @override
  String get reminderOff => 'Reminder off';

  @override
  String get qiblaTitle => 'Qibla · القبلة';

  @override
  String get whereAreYou => 'Where are you?';

  @override
  String get qiblaLocationNote =>
      'The Qibla direction depends on where you are. Your location stays on your phone.';

  @override
  String get setMyLocation => 'Set my location';

  @override
  String get changeLocation => 'Change location';

  @override
  String qiblaFromNorth(String degrees) {
    return 'Qibla is $degrees° from North';
  }

  @override
  String get facingQibla => 'You are facing the Qibla';

  @override
  String turnRight(String degrees) {
    return 'Turn right $degrees°';
  }

  @override
  String turnLeft(String degrees) {
    return 'Turn left $degrees°';
  }

  @override
  String get noCompassSensor =>
      'This phone has no compass sensor. Use the angle above with a physical compass.';

  @override
  String get calibrateCompass =>
      'Hold your phone flat. If it seems off, move it in a figure-8 to calibrate.';

  @override
  String get tasbihSubhanallah => 'SubhanAllah';

  @override
  String get tasbihAlhamdulillah => 'Alhamdulillah';

  @override
  String get tasbihAllahuAkbar => 'Allahu Akbar';

  @override
  String get tasbihLaIlaha => 'La ilaha illa Allah';

  @override
  String get tasbihAstaghfirullah => 'Astaghfirullah';

  @override
  String get tasbihSubhanallahiWaBihamdih => 'SubhanAllahi wa bihamdih';

  @override
  String get tasbihLaHawla => 'La hawla wa la quwwata';

  @override
  String get tasbihSalawat => 'Salawat';

  @override
  String get tasbihTitle => 'Tasbih · التسبيح';

  @override
  String get yourTasbih => 'Your tasbih';

  @override
  String get tapAnywhere => 'Tap anywhere';

  @override
  String ofRound(int count) {
    return 'of $count';
  }

  @override
  String get previousDhikr => 'Previous dhikr';

  @override
  String get nextDhikr => 'Next dhikr';

  @override
  String get roundsOf33 => 'Rounds of 33';

  @override
  String daysInARow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days in a row',
      one: '1 day in a row',
    );
    return '$_temp0';
  }

  @override
  String get streakStart => 'Start today: a few taps are enough';

  @override
  String get streakKeepGoing => 'Keep it going, a little every day';

  @override
  String get sevenDays => '7 days';

  @override
  String get thirtyDays => '30 days';

  @override
  String get allTime => 'All time';

  @override
  String get thisWeek => 'This week';

  @override
  String get last30Days => 'Last 30 days';

  @override
  String get dhikrThisMonth => 'Dhikr this month';

  @override
  String get nothingYetThisMonth => 'Nothing yet this month.';

  @override
  String get tagFriday => 'Jumu\'ah';

  @override
  String get tagMonThu => 'Mondays & Thursdays';

  @override
  String get tagWhiteDays => 'White Days';

  @override
  String get tagLastTen => 'Last ten nights';

  @override
  String get tagArafah => 'Arafah';

  @override
  String get tagAshura => 'Ashura';

  @override
  String get tagMorning => 'Morning';

  @override
  String get tagEvening => 'Evening';

  @override
  String get tagNight => 'Night';

  @override
  String get fajr => 'Fajr';

  @override
  String get searchHadith => 'Search hadith';

  @override
  String get savedHadith => 'Saved hadith';

  @override
  String get sunnahToPractise => 'Sunnah to practise';

  @override
  String get seeAll => 'See all';

  @override
  String get collections => 'Collections';

  @override
  String get hadithSourcesNote =>
      'Texts and grades from the open hadith-api project (public domain). Large collections download once and then work offline.';

  @override
  String todayTag(String tag) {
    return 'TODAY · $tag';
  }

  @override
  String get sunnahLabel => 'SUNNAH';

  @override
  String sizeMb(int size) {
    return '$size MB';
  }

  @override
  String get downloadFailed => 'Download failed';

  @override
  String readyOffline(String name) {
    return '$name is ready offline';
  }

  @override
  String removeItem(String name) {
    return 'Remove $name?';
  }

  @override
  String get removeBookMessage =>
      'It will be deleted from this device. You can download it again any time.';

  @override
  String get remove => 'Remove';

  @override
  String hadithCountWithName(int count, String name) {
    return '$count hadith · $name';
  }

  @override
  String get saving => 'Saving…';

  @override
  String get downloadingEllipsis => 'Downloading…';

  @override
  String downloadingPercent(int percent) {
    return 'Downloading $percent%';
  }

  @override
  String booksCountWithName(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count books',
      one: '1 book',
    );
    return '$_temp0 · $name';
  }

  @override
  String searchIn(String name) {
    return 'Search $name';
  }

  @override
  String hadithCount(int count) {
    return '$count hadith';
  }

  @override
  String chapterHadithCount(int count) {
    return 'Chapter · $count hadith';
  }

  @override
  String nothingInMatches(String name, String query) {
    return 'Nothing in $name matches \"$query\"';
  }

  @override
  String searchHadithCountHint(int count) {
    return 'Search $count hadith · word or number';
  }

  @override
  String noHadithMatch(String query) {
    return 'No hadith match \"$query\"';
  }

  @override
  String get clear => 'Clear';

  @override
  String hadithResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hadith',
      one: '1 hadith',
    );
    return '$_temp0';
  }

  @override
  String bookAndNumber(String book, String number) {
    return '$book $number';
  }

  @override
  String downloadToReadOffline(String book) {
    return 'Download $book in the Hadith tab to read this hadith offline.';
  }

  @override
  String get removeFromSaved => 'Remove from saved';

  @override
  String get save => 'Save';

  @override
  String get copy => 'Copy';

  @override
  String get hadithCopied => 'Hadith copied';

  @override
  String get grading => 'GRADING';

  @override
  String get grade => 'Grade';

  @override
  String get sunnah => 'Sunnah';

  @override
  String get copied => 'Copied';

  @override
  String get searchHadithEnglishArabic => 'Search hadith (English or Arabic)';

  @override
  String get all => 'All';

  @override
  String get searchEveryCollectionNote =>
      'Searches every collection on this device. Download more collections in the Hadith tab.';

  @override
  String get noHadithFound => 'No hadith found';

  @override
  String get saveHadithHint =>
      'Tap the bookmark on any hadith to save it here.';

  @override
  String get library => 'Library';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get downloads => 'Downloads';

  @override
  String get noBookmarksYet =>
      'No bookmarks yet.\nLong-press any ayah in the Mushaf to save it.';

  @override
  String pageSavedOn(int page, String date) {
    return 'Page $page · saved $date';
  }

  @override
  String get listenOfflineHint =>
      'Listen offline anywhere.\nOpen any reciter and download one surah, a selection, or the whole Quran.';

  @override
  String get browseReciters => 'Browse reciters';

  @override
  String sizeOnDevice(String size) {
    return '$size on this device';
  }

  @override
  String surahsAcrossRecitations(int surahs, int recitations) {
    return '$surahs surahs across $recitations recitations';
  }

  @override
  String countDownloading(int count) {
    return ' · $count downloading';
  }

  @override
  String recitationDownloadSummary(
    String name,
    int count,
    int total,
    String size,
  ) {
    return '$name · $count/$total surahs · $size';
  }

  @override
  String get deleteDownloadsQuestion => 'Delete downloads?';

  @override
  String freeSpaceMessage(String size, String name) {
    return 'Free $size by removing $name from your phone.';
  }

  @override
  String get thisReciter => 'this reciter';

  @override
  String get delete => 'Delete';

  @override
  String get stopDownloading => 'Stop downloading';

  @override
  String get deleteFromDevice => 'Delete from device';

  @override
  String get wholeQuran => 'Whole Quran';

  @override
  String juzNumber(String number) {
    return 'Juz $number';
  }

  @override
  String juzCount(int count) {
    return '$count juz';
  }

  @override
  String surahRange(String surah, int from, int to) {
    return '$surah $from–$to';
  }

  @override
  String surahsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count surahs',
      one: '1 surah',
    );
    return '$_temp0';
  }

  @override
  String get chooseMoreAyahs => 'Choose more ayahs or another question type';

  @override
  String get memorizationTest => 'Memorization test';

  @override
  String get whatToTest => 'What to test';

  @override
  String get surahs => 'Surahs';

  @override
  String get juz => 'Juz';

  @override
  String ayahsTapForMore(int count) {
    return '$count ayahs · tap to choose more surahs';
  }

  @override
  String ayahsRange(int from, int to) {
    return 'Ayahs $from – $to';
  }

  @override
  String get wholeQuranQuizNote =>
      'Questions from anywhere in the Quran: for those who have memorized all of it, or to see how much stays.';

  @override
  String get questions => 'Questions';

  @override
  String get howMany => 'How many';

  @override
  String get recent => 'Recent';

  @override
  String scoreOfTotal(int score, int total) {
    return '$score / $total';
  }

  @override
  String startScope(String scope) {
    return 'Start · $scope';
  }

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get chooseSurahs => 'Choose surahs';

  @override
  String ayahsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return '$_temp0';
  }

  @override
  String get chooseAtLeastOne => 'Choose at least one';

  @override
  String doneSelected(int count) {
    return 'Done · $count selected';
  }

  @override
  String questionOf(int number, int total) {
    return '$number of $total';
  }

  @override
  String get seeResults => 'See results';

  @override
  String get nextWord => 'Next word';

  @override
  String get showAyah => 'Show ayah';

  @override
  String get iMadeMistakes => 'I made mistakes';

  @override
  String get iHadItRight => 'I had it right';

  @override
  String get correct => 'Correct';

  @override
  String get rightAnswerHighlighted => 'The right answer is highlighted';

  @override
  String get reciteThenReveal =>
      'Recite it, then reveal it word by word to check yourself.';

  @override
  String get wellDone => 'Well done';

  @override
  String get keepRevisingAyah => 'Keep revising this ayah';

  @override
  String get resultPerfect => 'ما شاء الله · Perfect';

  @override
  String get resultVeryGood => 'Very good, keep revising';

  @override
  String get resultGood => 'Good effort, revise the ayahs below';

  @override
  String get resultRevise => 'Revise these ayahs and try again';

  @override
  String ofTotal(int total) {
    return 'of $total';
  }

  @override
  String get toRevise => 'To revise';

  @override
  String get practiseMistakes => 'Practise mistakes';

  @override
  String get closePlayer => 'Close player';

  @override
  String get couldNotStartPlayback =>
      'Could not start playback. Check your connection and try again.';

  @override
  String get close => 'Close';

  @override
  String get openInMushaf => 'Open in Mushaf';

  @override
  String get previousAyah => 'Previous ayah';

  @override
  String get previousSurah => 'Previous surah';

  @override
  String get nextAyah => 'Next ayah';

  @override
  String get nextSurah => 'Next surah';

  @override
  String get surah => 'Surah';

  @override
  String get noAyahTimingNote =>
      'This recitation has no ayah timing, so the ayah being recited cannot be highlighted. Reciters marked Ayah sync follow along exactly.';

  @override
  String get backToCurrent => 'Back to current';

  @override
  String backToAyah(int number) {
    return 'Back to ayah $number';
  }

  @override
  String get repeat => 'Repeat';

  @override
  String get repeatNote =>
      'Memorization helper: repeat each ayah before moving on.';

  @override
  String get off => 'Off';

  @override
  String get eachAyah => 'Each ayah';

  @override
  String get ayahRepeatNeedsTiming =>
      'Ayah repeat needs a reciter with ayah timing.';

  @override
  String get apply => 'Apply';

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String stopsAt(String time) {
    return 'Stops at $time';
  }

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get endOfSurah => 'End of surah';

  @override
  String get turnOff => 'Turn off';

  @override
  String get searchHint => 'Surah, 2:255, الرحمن, mercy…';

  @override
  String goTo(String surah, String reference) {
    return 'Go to $surah $reference';
  }

  @override
  String meaningAndAyahs(String meaning, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return '$meaning · $_temp0';
  }

  @override
  String get noResults => 'No results';

  @override
  String get makki => 'Makki';

  @override
  String get madani => 'Madani';

  @override
  String get ayahCopied => 'Ayah copied';

  @override
  String pageNumber(int number) {
    return 'Page $number';
  }

  @override
  String get bookmarksAndDownloads => 'Bookmarks & downloads';

  @override
  String get more => 'More';

  @override
  String get goToPage => 'Go to page';

  @override
  String get enterPageNumber => 'Enter a page number from 1 to 604';

  @override
  String get open => 'Open';

  @override
  String get theOpening => 'The Opening';

  @override
  String pageAndAyah(int page, int ayah) {
    return 'Page $page · Ayah $ayah';
  }

  @override
  String surahInfo(String type, int count, String meaning) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return '$type · $_temp0 · $meaning';
  }

  @override
  String juzNumberInt(int number) {
    return 'Juz $number';
  }

  @override
  String get pageColour => 'Page colour';

  @override
  String get back => 'Back';

  @override
  String juzAndPage(int juz, int page) {
    return 'Juz $juz · Page $page';
  }

  @override
  String get onePage => 'One page';

  @override
  String pageOf(int number, int total) {
    return 'Page $number of $total';
  }

  @override
  String get playThisPage => 'Play this page';

  @override
  String get resume => 'Resume';

  @override
  String get paperTheme => 'Theme';

  @override
  String get paperIvory => 'Ivory';

  @override
  String get paperWhite => 'White';

  @override
  String get paperSepia => 'Sepia';

  @override
  String get paperDark => 'Dark';

  @override
  String get paperBlack => 'Black';

  @override
  String toDownload(int count) {
    return '$count to download';
  }

  @override
  String get size => 'Size';

  @override
  String get unknownOffline => 'Unknown (offline)';

  @override
  String get savedLabel => 'Saved';

  @override
  String get onThisPhone => 'On this phone';

  @override
  String get downloadsBackgroundNote =>
      'Downloads continue in the background, resume if interrupted, and play without internet once finished.';

  @override
  String get wifiOnly => 'Wi-Fi only';

  @override
  String get wifiOnlySubtitle => 'Wait for Wi-Fi to save mobile data';

  @override
  String downloadWithSize(String size) {
    return 'Download · $size';
  }

  @override
  String get notNow => 'Not now';

  @override
  String get calculating => 'Calculating';

  @override
  String downloadSurahs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count surahs',
      one: '1 surah',
    );
    return 'Download $_temp0';
  }

  @override
  String get alreadyDownloaded => 'Already downloaded';

  @override
  String downloadingSurahs(int count, String reciter) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count surahs',
      one: '1 surah',
    );
    return 'Downloading $_temp0 · $reciter';
  }

  @override
  String deleteAllDownloadsMessage(String name, String recitation) {
    return 'All downloaded surahs of $name ($recitation) will be removed from this phone. You can download them again anytime.';
  }

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get selectAll => 'Select all';

  @override
  String get selectSurahsToDownload => 'Select surahs to download';

  @override
  String get downloadJuzAmma => 'Download Juz \'Amma (78–114)';

  @override
  String get cancelDownloads => 'Cancel downloads';

  @override
  String get retryFailedDownloads => 'Retry failed downloads';

  @override
  String get deleteDownloads => 'Delete downloads';

  @override
  String get completeQuran => 'Complete Quran';

  @override
  String get defaultLabel => 'Default';

  @override
  String get downloadWholeQuran => 'Download the whole Quran';

  @override
  String get downloadAllSurahs => 'Download all surahs';

  @override
  String get allOffline => 'All offline';

  @override
  String stopCount(int count) {
    return 'Stop ($count)';
  }

  @override
  String get downloadAll => 'Download all';

  @override
  String get longPressToSelect =>
      'Long-press surahs to select several for download.';

  @override
  String get notRecorded => 'Not recorded';

  @override
  String get removeSurahAudioMessage =>
      'This surah\'s audio will be deleted from your phone.';

  @override
  String get keep => 'Keep';

  @override
  String get favorites => 'Favorites';

  @override
  String get otherRiwayat => 'Other riwayat';

  @override
  String get mujawwad => 'Mujawwad';

  @override
  String couldNotLoadReciters(String error) {
    return 'Could not load reciters\n$error';
  }

  @override
  String searchRecitersHint(int count) {
    return 'Search $count reciters · ابحث عن قارئ';
  }

  @override
  String get featured => 'Featured';

  @override
  String get allReciters => 'All reciters';

  @override
  String recitersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reciters',
      one: '1 reciter',
    );
    return '$_temp0';
  }

  @override
  String get nothingDownloadedYet =>
      'Nothing downloaded yet. Open a reciter and tap download on any surah, or download the whole Quran.';

  @override
  String get favoritesHint => 'Tap the heart on a reciter to keep them here.';

  @override
  String get noRecitersMatch => 'No reciters match your search.';

  @override
  String get mushaf => 'Mushaf';

  @override
  String get offline => 'Offline';

  @override
  String countOffline(int count) {
    return '$count offline';
  }

  @override
  String get playsInMushaf => 'Plays in the Mushaf';

  @override
  String get useForMushafPlayback => 'Use for Mushaf playback';

  @override
  String willReciteInMushaf(String name) {
    return '$name will recite when you press play in the Mushaf';
  }

  @override
  String get remindersCardSubtitleShort => 'Adhkar, prayer and daily reminders';

  @override
  String get appearance => 'Appearance';

  @override
  String get mushafPageColour => 'Mushaf page colour';

  @override
  String get sameAsApp => 'Same as the app';

  @override
  String get readingGroup => 'Reading';

  @override
  String get translation => 'Translation';

  @override
  String get turnPagesWithRecitation => 'Turn pages with the recitation';

  @override
  String get keepScreenOn => 'Keep the screen on while reading';

  @override
  String get listeningAndDownloads => 'Listening & downloads';

  @override
  String get downloadOnWifiOnly => 'Download on Wi-Fi only';

  @override
  String get downloadsAndBookmarks => 'Downloads & bookmarks';

  @override
  String get remindersAndSound => 'Reminders & sound';

  @override
  String dailyRemindersEvery(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: 'hour',
    );
    return 'Daily reminders every $_temp0';
  }

  @override
  String get about => 'About';

  @override
  String aboutApp(String appName) {
    return 'About $appName';
  }

  @override
  String versionFreeOpenSource(String version) {
    return 'Version $version · free and open source';
  }

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeMidnight => 'Midnight';

  @override
  String themeSemantics(String theme) {
    return '$theme theme';
  }

  @override
  String get sourceQuranText => 'Quran text & font';

  @override
  String get sourceQuranTextDetail =>
      'King Fahd Glorious Quran Printing Complex (KFGQPC), Uthmanic Hafs v18.';

  @override
  String get sourceLayout => 'Mushaf page layout';

  @override
  String get sourceLayoutDetail =>
      'KFGQPC Hafs 15-line layout, via Quran.com (Quran Foundation).';

  @override
  String get sourceTranslations => 'Translations';

  @override
  String get sourceTranslationsDetail =>
      'Saheeh International; Mahmud Muhammad Abduh (Somali), via Quran.com.';

  @override
  String get sourceRecitations => 'Recitations';

  @override
  String get sourceRecitationsDetail =>
      'MP3Quran.net: reciters, audio files and ayah timings. Audio streams and downloads directly from their servers.';

  @override
  String get sourceAdhkarDetail =>
      'Hisn al-Muslim by Sa\'id bin Ali bin Wahf Al-Qahtani; Quran passages from the KFGQPC text.';

  @override
  String get sourceHadithDetail =>
      'Arabic texts, English translations and grades from the hadith-api project by Fawaz Ahmed (public domain).';

  @override
  String get sourceHijri => 'Hijri calendar';

  @override
  String get sourceHijriDetail =>
      'Umm al-Qura calculation, adjustable for local moon sighting.';

  @override
  String get sourceAdhkarAudio => 'Adhkar recordings';

  @override
  String get sourceAdhkarAudioDetail =>
      'hisnmuslim.com (Hisn al-Muslim) and, for Quranic adhkar, Mishary Alafasy via everyayah.com. Included in the app, so they play offline.';

  @override
  String get sourceAppIcon => 'App icon';

  @override
  String get sourceAppIconDetail =>
      'The name سراج in Amiri Bold (SIL Open Font License).';

  @override
  String get sourceReminderSound => 'Reminder sound';

  @override
  String get sourceReminderSoundDetail =>
      'Pixie Dust, from the Android Open Source Project (Apache 2.0).';

  @override
  String get sourcePrayer => 'Prayer times & Qibla';

  @override
  String get sourcePrayerDetail =>
      'Calculated on your phone with the open-source Adhan library.';

  @override
  String get sourceUiFont => 'UI font';

  @override
  String get sourceUiFontDetail =>
      'IBM Plex Sans Arabic (SIL Open Font License).';

  @override
  String aboutIntro(String version) {
    return 'Quran, Hadith and a daily guide. Version $version.';
  }

  @override
  String get aboutPrivacy =>
      'No account, no ads, no tracking. Your bookmarks, history and downloads stay on this phone.';

  @override
  String aboutOpenSource(String url) {
    return 'Free and open source: $url';
  }

  @override
  String get sources => 'Sources';

  @override
  String get sourcesButton => 'Sources of the texts and audio';

  @override
  String get licenseLegalese =>
      'Quran · Hadith · Daily guide. Free and open source.';

  @override
  String get openSourceLicenses => 'Open-source licenses';

  @override
  String get notificationsOff => 'Notifications are off';

  @override
  String get allowNotifications =>
      'Allow notifications for Siraj in your phone settings to receive reminders.';

  @override
  String get dailyReminders => 'Daily reminders';

  @override
  String get dailyRemindersSubtitle =>
      'An ayah, hadith, sunnah or dhikr through the day';

  @override
  String get dailyRemindersOn => 'Daily reminders are on';

  @override
  String get varyTime => 'Vary the time a little';

  @override
  String get varyTimeSubtitle =>
      'Each reminder arrives a few minutes earlier or later';

  @override
  String get howOften => 'How often';

  @override
  String everyHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count hours',
      one: 'Every hour',
    );
    return '$_temp0';
  }

  @override
  String get activeHours => 'Active hours';

  @override
  String get from => 'From';

  @override
  String get until => 'Until';

  @override
  String remindersPerDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders a day',
      one: '1 reminder a day',
    );
    return '$_temp0. Nothing is sent outside these hours.';
  }

  @override
  String get whatToSend => 'What to send · chosen at random';

  @override
  String get remindersFollowDay =>
      'Reminders follow the day: Surah Al-Kahf and salawat on Friday, a reminder the evening before the Monday and Thursday fasts, the White Days, Ramadan and its last ten nights, Dhul Hijjah, Arafah and Ashura, and adhkar in the morning, evening and before sleep.';

  @override
  String get previewReminder => 'Preview a reminder';

  @override
  String get morningEveningAdhkar => 'Morning & evening adhkar';

  @override
  String get prayerAndCalendar => 'Prayer & calendar';

  @override
  String get prayerTimeAlerts => 'Prayer time alerts';

  @override
  String get choosePrayersAlert => 'Choose which prayers alert you';

  @override
  String hijriDateAh(String date) {
    return '$date AH';
  }

  @override
  String get ummAlQuraNote =>
      'Umm al-Qura calendar · adjust if your local moon sighting differs';

  @override
  String hijriAdjusted(String offset, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return 'Adjusted $offset $_temp0';
  }

  @override
  String get oneDayEarlier => 'One day earlier';

  @override
  String get oneDayLater => 'One day later';

  @override
  String get sound => 'Sound';

  @override
  String get sendTestNotification => 'Send a test notification';

  @override
  String get seeAndHearReminder => 'See and hear a reminder now';

  @override
  String get reminder => 'Reminder';

  @override
  String get rememberMeTranslation =>
      '\"Remember Me; I will remember you.\" (2:152)';

  @override
  String get adhkarReminders => 'Adhkar reminders';

  @override
  String get adhkarRemindersSubtitle =>
      'To read the morning and the evening adhkar, at the times you set';

  @override
  String get morningAdhkar => 'Morning adhkar';

  @override
  String get timeForMorningAdhkar => 'Time to read the morning adhkar';

  @override
  String get eveningAdhkar => 'Evening adhkar';

  @override
  String get timeForEveningAdhkar => 'Time to read the evening adhkar';

  @override
  String get pixieDust => 'Pixie Dust';

  @override
  String get pixieDustSubtitle => 'A soft, short chime · tap to hear it';

  @override
  String get phoneDefault => 'Phone default';

  @override
  String get phoneDefaultSubtitle => 'Your phone\'s notification sound';

  @override
  String offlinePlayingDownloaded(String reciter) {
    return 'You\'re offline · playing $reciter (downloaded)';
  }

  @override
  String get offlineDownloadSurah =>
      'You\'re offline. Download this surah to listen without internet.';

  @override
  String get downloadJuzAmmaTitle => 'Download Juz \'Amma';

  @override
  String get startReading => 'START READING';

  @override
  String get continueReading => 'CONTINUE READING';

  @override
  String pageShort(int page) {
    return 'p. $page';
  }

  @override
  String surahsOnDevice(int count, int total) {
    return '$count of $total surahs on this device';
  }

  @override
  String countFailed(int count) {
    return ' · $count failed';
  }

  @override
  String get continueListeningCaps => 'CONTINUE LISTENING';

  @override
  String ayahsFound(String count) {
    return '$count ayahs';
  }

  @override
  String searchHitReference(String surah, String reference, int page) {
    return '$surah $reference · page $page';
  }

  @override
  String durationSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String dhikrYourTurnShort(int number, int total) {
    return 'Dhikr $number of $total · your turn';
  }

  @override
  String afterSalah(String prayer) {
    return 'After $prayer';
  }

  @override
  String get beforeFajr => 'Before Fajr';

  @override
  String get bestBeforeSunrise => 'Best before sunrise';

  @override
  String get dhikrThroughDay => 'Dhikr through the day';

  @override
  String get stillTimeUntilDhuhr => 'Still time · until Dhuhr';

  @override
  String get bestBeforeMaghrib => 'Best before Maghrib';

  @override
  String get duasOfQuran => 'Duas of the Quran';

  @override
  String get stillTimeTonight => 'Still time · tonight';

  @override
  String get beforeYouSleep => 'Before you sleep';

  @override
  String get wakingUp => 'Waking up';

  @override
  String get tasbihAndDhikr => 'Tasbih & dhikr';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get currentLocation => 'Current location';

  @override
  String get turnOnLocationServices => 'Turn on location services';

  @override
  String get locationPermissionDenied => 'Location permission was denied';

  @override
  String get couldNotGetLocation => 'Could not get your location';

  @override
  String get morningAdhkarNotificationTitle => 'أذكار الصباح · Morning adhkar';

  @override
  String get morningAdhkarNotificationBody =>
      'Time to read the morning adhkar. Begin your day with the remembrance of Allah';

  @override
  String get eveningAdhkarNotificationTitle => 'أذكار المساء · Evening adhkar';

  @override
  String prayerNotificationBody(String prayer) {
    return 'It is time for $prayer prayer';
  }

  @override
  String prayerNotificationBodyIn(String prayer, String place) {
    return 'It is time for $prayer prayer in $place';
  }

  @override
  String get noInternetNothingDownloaded =>
      'No internet connection and nothing downloaded for this reciter.';

  @override
  String downloadingName(String name) {
    return 'Downloading $name';
  }

  @override
  String get readyOfflineTitle => 'Ready offline';

  @override
  String get downloadPaused => 'Download paused';

  @override
  String surahAndReciter(int number, String reciter) {
    return 'Surah $number · $reciter';
  }

  @override
  String get hadithDownloadFailed =>
      'Download failed. Check your connection and try again.';

  @override
  String get quizNextAyah => 'Next ayah';

  @override
  String get quizPreviousAyah => 'Previous ayah';

  @override
  String get quizCompleteAyah => 'Complete the ayah';

  @override
  String get quizMissingWord => 'Missing word';

  @override
  String get quizWhichSurah => 'Which surah?';

  @override
  String get quizRecite => 'Recite from memory';

  @override
  String get quizNextAyahDescription =>
      'See an ayah and choose the one that follows it';

  @override
  String get quizPreviousAyahDescription =>
      'See an ayah and choose the one before it';

  @override
  String get quizCompleteAyahDescription =>
      'Read the beginning and choose how the ayah ends';

  @override
  String get quizMissingWordDescription =>
      'One word is hidden; choose it from similar words';

  @override
  String get quizWhichSurahDescription => 'Choose the surah an ayah belongs to';

  @override
  String get quizReciteDescription =>
      'Recite the next ayah yourself, then reveal and check';

  @override
  String get quizNextAyahAsk => 'Which ayah comes next?';

  @override
  String get quizPreviousAyahAsk => 'Which ayah comes before this one?';

  @override
  String get quizCompleteAyahAsk => 'How does this ayah end?';

  @override
  String get quizMissingWordAsk => 'Which word is missing?';

  @override
  String get quizWhichSurahAsk => 'Which surah is this ayah from?';

  @override
  String get quizReciteAsk => 'Recite the next ayah from memory';

  @override
  String get channelPrayerDescription =>
      'A reminder when each prayer time begins';

  @override
  String get channelAdhkarDescription =>
      'A reminder to read the morning and evening adhkar';

  @override
  String get channelDailyDescription =>
      'An ayah, hadith, sunnah or dua through the day';

  @override
  String get testPrayerTitle => 'Asr · العصر';

  @override
  String get testDailyTitle => 'Daily reminder';

  @override
  String get testAdhkarBody => 'Time for your evening remembrance';

  @override
  String get testDailyBody =>
      '\"Verily, in the remembrance of Allah do hearts find rest.\" (13:28)';

  @override
  String get sirajPlayback => 'Siraj playback';

  @override
  String get reminderAyah => 'Ayah to reflect on';

  @override
  String get reminderSurah => 'Surah to read';

  @override
  String get reminderDhikr => 'Dhikr & dua';

  @override
  String hijriDateLabel(int day, String month, int year) {
    return '$day $month $year';
  }

  @override
  String get suggestYaSin => 'Read Surah Ya-Sin';

  @override
  String get suggestArRahman =>
      'Read Surah Ar-Rahman and reflect on the blessings of your Lord';

  @override
  String get suggestAlWaqiah => 'Read Surah Al-Waqi\'ah';

  @override
  String get suggestAlMulk => 'Read Surah Al-Mulk tonight';

  @override
  String get suggestAsSajdah => 'Read Surah As-Sajdah tonight';

  @override
  String get suggestAlKahf => 'Friday: read Surah Al-Kahf';

  @override
  String get suggestMaryam => 'Read Surah Maryam';

  @override
  String get suggestYusuf => 'Read Surah Yusuf, \"the best of stories\"';

  @override
  String get suggestAnNaba => 'Read Surah An-Naba\'';

  @override
  String get suggestAlFatihah =>
      'Reflect on Al-Fatihah, the Mother of the Book';

  @override
  String get suggestQuls => 'Read Al-Ikhlas, Al-Falaq and An-Nas';

  @override
  String get suggestAlBaqarah => 'Read the last two ayat of Al-Baqarah tonight';

  @override
  String get rememberAllah => 'Remember Allah';

  @override
  String get rememberAllahBody =>
      'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ · Glory be to Allah and praise be to Him';

  @override
  String surahSuggestionBody(String suggestion, int count) {
    return '$suggestion ($count ayat).';
  }

  @override
  String reflectOn(String surah, String reference) {
    return 'Reflect · $surah $reference';
  }

  @override
  String hadithReminderTitle(String book, String number) {
    return 'Hadith · $book $number';
  }

  @override
  String sunnahReminderTitle(String title) {
    return 'Sunnah · $title';
  }

  @override
  String get sunnahFriday => 'Sunnah · Jumu\'ah';
}
