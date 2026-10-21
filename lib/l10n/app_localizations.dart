import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Siraj'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @quran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quran;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @hadith.
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get hadith;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @muharram.
  ///
  /// In en, this message translates to:
  /// **'Muharram'**
  String get muharram;

  /// No description provided for @safar.
  ///
  /// In en, this message translates to:
  /// **'Safar'**
  String get safar;

  /// No description provided for @rabiAlAwwal.
  ///
  /// In en, this message translates to:
  /// **'Rabi al-Awwal'**
  String get rabiAlAwwal;

  /// No description provided for @rabiAlThani.
  ///
  /// In en, this message translates to:
  /// **'Rabi al-Thani'**
  String get rabiAlThani;

  /// No description provided for @jumadaAlUla.
  ///
  /// In en, this message translates to:
  /// **'Jumada al-Ula'**
  String get jumadaAlUla;

  /// No description provided for @jumadaAlAkhirah.
  ///
  /// In en, this message translates to:
  /// **'Jumada al-Akhirah'**
  String get jumadaAlAkhirah;

  /// No description provided for @rajab.
  ///
  /// In en, this message translates to:
  /// **'Rajab'**
  String get rajab;

  /// No description provided for @shaban.
  ///
  /// In en, this message translates to:
  /// **'Sha\'ban'**
  String get shaban;

  /// No description provided for @ramadan.
  ///
  /// In en, this message translates to:
  /// **'Ramadan'**
  String get ramadan;

  /// No description provided for @shawwal.
  ///
  /// In en, this message translates to:
  /// **'Shawwal'**
  String get shawwal;

  /// No description provided for @dhulQadah.
  ///
  /// In en, this message translates to:
  /// **'Dhul Qadah'**
  String get dhulQadah;

  /// No description provided for @dhulHijjah.
  ///
  /// In en, this message translates to:
  /// **'Dhul Hijjah'**
  String get dhulHijjah;

  /// No description provided for @homeDateLine.
  ///
  /// In en, this message translates to:
  /// **'{weekday} · {day} {month} {year}'**
  String homeDateLine(String weekday, int day, String month, int year);

  /// No description provided for @greetingNight.
  ///
  /// In en, this message translates to:
  /// **'Peaceful night'**
  String get greetingNight;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @kahfFriday.
  ///
  /// In en, this message translates to:
  /// **'Surah Al-Kahf · Jumu\'ah'**
  String get kahfFriday;

  /// No description provided for @kahfFridaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'The Sunnah of Friday'**
  String get kahfFridaySubtitle;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @practise.
  ///
  /// In en, this message translates to:
  /// **'Practise'**
  String get practise;

  /// No description provided for @doneTodayAccepted.
  ///
  /// In en, this message translates to:
  /// **'Done today · تقبّل الله'**
  String get doneTodayAccepted;

  /// No description provided for @countedOfTotalRead.
  ///
  /// In en, this message translates to:
  /// **'{counted} of {total} read'**
  String countedOfTotalRead(int counted, int total);

  /// No description provided for @openTasbih.
  ///
  /// In en, this message translates to:
  /// **'Open Tasbih'**
  String get openTasbih;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @actionWithTime.
  ///
  /// In en, this message translates to:
  /// **'{action} · {time}'**
  String actionWithTime(String action, String time);

  /// No description provided for @testYourHifz.
  ///
  /// In en, this message translates to:
  /// **'Test your hifz'**
  String get testYourHifz;

  /// No description provided for @testYourHifzSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Surahs, juz or the whole Quran'**
  String get testYourHifzSubtitle;

  /// No description provided for @lastQuizResult.
  ///
  /// In en, this message translates to:
  /// **'Last: {scope} · {score}/{total}'**
  String lastQuizResult(String scope, int score, int total);

  /// No description provided for @adhkar.
  ///
  /// In en, this message translates to:
  /// **'Adhkar'**
  String get adhkar;

  /// No description provided for @prayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get prayer;

  /// No description provided for @qibla.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get qibla;

  /// No description provided for @tasbih.
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get tasbih;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @queued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get queued;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @dhikrYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Dhikr {number} · your turn to read'**
  String dhikrYourTurn(int number);

  /// No description provided for @dhikrOf.
  ///
  /// In en, this message translates to:
  /// **'Dhikr {number} of {total}'**
  String dhikrOf(int number, int total);

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @completedTodayAccepted.
  ///
  /// In en, this message translates to:
  /// **'Completed today · تقبّل الله'**
  String get completedTodayAccepted;

  /// No description provided for @essentials.
  ///
  /// In en, this message translates to:
  /// **'Essentials'**
  String get essentials;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @remindersCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adhkar, prayer times and daily reminders'**
  String get remindersCardSubtitle;

  /// No description provided for @prayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get prayerTimes;

  /// No description provided for @beforeSleep.
  ///
  /// In en, this message translates to:
  /// **'Before sleep'**
  String get beforeSleep;

  /// No description provided for @afterPrayer.
  ///
  /// In en, this message translates to:
  /// **'After prayer'**
  String get afterPrayer;

  /// No description provided for @completedAccepted.
  ///
  /// In en, this message translates to:
  /// **'Completed · تقبّل الله منا ومنكم'**
  String get completedAccepted;

  /// No description provided for @couldNotLoadAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Could not load adhkar\n{error}'**
  String couldNotLoadAdhkar(String error);

  /// No description provided for @adhkarCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 dhikr} other{{count} adhkar}}'**
  String adhkarCount(int count);

  /// No description provided for @startAgain.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get startAgain;

  /// No description provided for @backToDhikr.
  ///
  /// In en, this message translates to:
  /// **'Back to dhikr {number}'**
  String backToDhikr(int number);

  /// No description provided for @modeWithTime.
  ///
  /// In en, this message translates to:
  /// **'{mode} · {time}'**
  String modeWithTime(String mode, String time);

  /// No description provided for @listenShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get listenShort;

  /// No description provided for @listenFullCount.
  ///
  /// In en, this message translates to:
  /// **'Full count'**
  String get listenFullCount;

  /// No description provided for @reciting.
  ///
  /// In en, this message translates to:
  /// **'RECITING'**
  String get reciting;

  /// No description provided for @quranReference.
  ///
  /// In en, this message translates to:
  /// **'Quran {reference}'**
  String quranReference(String reference);

  /// No description provided for @timesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time} other{{count} times}}'**
  String timesCount(int count);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @tapWhenRead.
  ///
  /// In en, this message translates to:
  /// **'Tap when read'**
  String get tapWhenRead;

  /// No description provided for @ofCountTap.
  ///
  /// In en, this message translates to:
  /// **'of {count} · tap'**
  String ofCountTap(int count);

  /// No description provided for @continueListening.
  ///
  /// In en, this message translates to:
  /// **'Continue listening'**
  String get continueListening;

  /// No description provided for @listenFullCountHint.
  ///
  /// In en, this message translates to:
  /// **'Each dhikr as many times as it is said'**
  String get listenFullCountHint;

  /// No description provided for @listenShortHint.
  ///
  /// In en, this message translates to:
  /// **'A hundred-times dhikr plays ten times'**
  String get listenShortHint;

  /// No description provided for @resumeFromDhikr.
  ///
  /// In en, this message translates to:
  /// **'From dhikr {number}, where you stopped'**
  String resumeFromDhikr(int number);

  /// No description provided for @yourTurnReadThenTap.
  ///
  /// In en, this message translates to:
  /// **'Your turn: read, then tap'**
  String get yourTurnReadThenTap;

  /// No description provided for @recitationOf.
  ///
  /// In en, this message translates to:
  /// **'Recitation {number} of {total}'**
  String recitationOf(int number, int total);

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @stopListening.
  ///
  /// In en, this message translates to:
  /// **'Stop listening'**
  String get stopListening;

  /// No description provided for @listeningTime.
  ///
  /// In en, this message translates to:
  /// **'{time} of listening'**
  String listeningTime(String time);

  /// No description provided for @listeningTimeToRead.
  ///
  /// In en, this message translates to:
  /// **'{time} of listening · {count} to read'**
  String listeningTimeToRead(String time, int count);

  /// No description provided for @countdownHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String countdownHoursMinutes(int hours, String minutes);

  /// No description provided for @countdownMinutesSeconds.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String countdownMinutesSeconds(int minutes, String seconds);

  /// No description provided for @countdownSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String countdownSeconds(int seconds);

  /// No description provided for @setLocationForPrayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Set your location to see prayer times and Qibla'**
  String get setLocationForPrayerTimes;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @prayerTimeNow.
  ///
  /// In en, this message translates to:
  /// **'PRAYER TIME · NOW'**
  String get prayerTimeNow;

  /// No description provided for @nextPrayer.
  ///
  /// In en, this message translates to:
  /// **'NEXT PRAYER'**
  String get nextPrayer;

  /// No description provided for @beganAgo.
  ///
  /// In en, this message translates to:
  /// **'began {time} ago'**
  String beganAgo(String time);

  /// No description provided for @inTime.
  ///
  /// In en, this message translates to:
  /// **'in {time}'**
  String inTime(String time);

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get yourLocation;

  /// No description provided for @locationUseNote.
  ///
  /// In en, this message translates to:
  /// **'Used only on your phone to calculate prayer times and the Qibla direction.'**
  String get locationUseNote;

  /// No description provided for @findingYou.
  ///
  /// In en, this message translates to:
  /// **'Finding you…'**
  String get findingYou;

  /// No description provided for @useMyCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get useMyCurrentLocation;

  /// No description provided for @orSearchCity.
  ///
  /// In en, this message translates to:
  /// **'Or search a city'**
  String get orSearchCity;

  /// No description provided for @locationErrorPickCity.
  ///
  /// In en, this message translates to:
  /// **'{error}. You can pick your city instead.'**
  String locationErrorPickCity(String error);

  /// No description provided for @calculationSettings.
  ///
  /// In en, this message translates to:
  /// **'Calculation settings'**
  String get calculationSettings;

  /// No description provided for @setYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Set your location'**
  String get setYourLocation;

  /// No description provided for @prayerTimesOffline.
  ///
  /// In en, this message translates to:
  /// **'Prayer times are calculated on your phone. No internet needed.'**
  String get prayerTimesOffline;

  /// No description provided for @chooseLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose location'**
  String get chooseLocation;

  /// No description provided for @nowLabel.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get nowLabel;

  /// No description provided for @nextLabel.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get nextLabel;

  /// No description provided for @labelWithArabic.
  ///
  /// In en, this message translates to:
  /// **'{label} · {arabic}'**
  String labelWithArabic(String label, String arabic);

  /// No description provided for @timeBeganAgo.
  ///
  /// In en, this message translates to:
  /// **'{time} · began {ago} ago'**
  String timeBeganAgo(String time, String ago);

  /// No description provided for @timeIn.
  ///
  /// In en, this message translates to:
  /// **'{time} · in {wait}'**
  String timeIn(String time, String wait);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @methodAndAsr.
  ///
  /// In en, this message translates to:
  /// **'{method} · Asr: {asr}'**
  String methodAndAsr(String method, String asr);

  /// No description provided for @asrHanafi.
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get asrHanafi;

  /// No description provided for @asrStandardLong.
  ///
  /// In en, this message translates to:
  /// **'Standard (Shafi, Maliki, Hanbali)'**
  String get asrStandardLong;

  /// No description provided for @calculation.
  ///
  /// In en, this message translates to:
  /// **'Calculation'**
  String get calculation;

  /// No description provided for @asrTime.
  ///
  /// In en, this message translates to:
  /// **'Asr time'**
  String get asrTime;

  /// No description provided for @asrStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get asrStandard;

  /// No description provided for @reminderOn.
  ///
  /// In en, this message translates to:
  /// **'Reminder on'**
  String get reminderOn;

  /// No description provided for @reminderOff.
  ///
  /// In en, this message translates to:
  /// **'Reminder off'**
  String get reminderOff;

  /// No description provided for @qiblaTitle.
  ///
  /// In en, this message translates to:
  /// **'Qibla · القبلة'**
  String get qiblaTitle;

  /// No description provided for @whereAreYou.
  ///
  /// In en, this message translates to:
  /// **'Where are you?'**
  String get whereAreYou;

  /// No description provided for @qiblaLocationNote.
  ///
  /// In en, this message translates to:
  /// **'The Qibla direction depends on where you are. Your location stays on your phone.'**
  String get qiblaLocationNote;

  /// No description provided for @setMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Set my location'**
  String get setMyLocation;

  /// No description provided for @changeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change location'**
  String get changeLocation;

  /// No description provided for @qiblaFromNorth.
  ///
  /// In en, this message translates to:
  /// **'Qibla is {degrees}° from North'**
  String qiblaFromNorth(String degrees);

  /// No description provided for @facingQibla.
  ///
  /// In en, this message translates to:
  /// **'You are facing the Qibla'**
  String get facingQibla;

  /// No description provided for @turnRight.
  ///
  /// In en, this message translates to:
  /// **'Turn right {degrees}°'**
  String turnRight(String degrees);

  /// No description provided for @turnLeft.
  ///
  /// In en, this message translates to:
  /// **'Turn left {degrees}°'**
  String turnLeft(String degrees);

  /// No description provided for @noCompassSensor.
  ///
  /// In en, this message translates to:
  /// **'This phone has no compass sensor. Use the angle above with a physical compass.'**
  String get noCompassSensor;

  /// No description provided for @calibrateCompass.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone flat. If it seems off, move it in a figure-8 to calibrate.'**
  String get calibrateCompass;

  /// No description provided for @tasbihSubhanallah.
  ///
  /// In en, this message translates to:
  /// **'SubhanAllah'**
  String get tasbihSubhanallah;

  /// No description provided for @tasbihAlhamdulillah.
  ///
  /// In en, this message translates to:
  /// **'Alhamdulillah'**
  String get tasbihAlhamdulillah;

  /// No description provided for @tasbihAllahuAkbar.
  ///
  /// In en, this message translates to:
  /// **'Allahu Akbar'**
  String get tasbihAllahuAkbar;

  /// No description provided for @tasbihLaIlaha.
  ///
  /// In en, this message translates to:
  /// **'La ilaha illa Allah'**
  String get tasbihLaIlaha;

  /// No description provided for @tasbihAstaghfirullah.
  ///
  /// In en, this message translates to:
  /// **'Astaghfirullah'**
  String get tasbihAstaghfirullah;

  /// No description provided for @tasbihSubhanallahiWaBihamdih.
  ///
  /// In en, this message translates to:
  /// **'SubhanAllahi wa bihamdih'**
  String get tasbihSubhanallahiWaBihamdih;

  /// No description provided for @tasbihLaHawla.
  ///
  /// In en, this message translates to:
  /// **'La hawla wa la quwwata'**
  String get tasbihLaHawla;

  /// No description provided for @tasbihSalawat.
  ///
  /// In en, this message translates to:
  /// **'Salawat'**
  String get tasbihSalawat;

  /// No description provided for @tasbihTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasbih · التسبيح'**
  String get tasbihTitle;

  /// No description provided for @yourTasbih.
  ///
  /// In en, this message translates to:
  /// **'Your tasbih'**
  String get yourTasbih;

  /// No description provided for @tapAnywhere.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere'**
  String get tapAnywhere;

  /// No description provided for @ofRound.
  ///
  /// In en, this message translates to:
  /// **'of {count}'**
  String ofRound(int count);

  /// No description provided for @previousDhikr.
  ///
  /// In en, this message translates to:
  /// **'Previous dhikr'**
  String get previousDhikr;

  /// No description provided for @nextDhikr.
  ///
  /// In en, this message translates to:
  /// **'Next dhikr'**
  String get nextDhikr;

  /// No description provided for @roundsOf33.
  ///
  /// In en, this message translates to:
  /// **'Rounds of 33'**
  String get roundsOf33;

  /// No description provided for @daysInARow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day in a row} other{{count} days in a row}}'**
  String daysInARow(int count);

  /// No description provided for @streakStart.
  ///
  /// In en, this message translates to:
  /// **'Start today: a few taps are enough'**
  String get streakStart;

  /// No description provided for @streakKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep it going, a little every day'**
  String get streakKeepGoing;

  /// No description provided for @sevenDays.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get sevenDays;

  /// No description provided for @thirtyDays.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get thirtyDays;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @dhikrThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Dhikr this month'**
  String get dhikrThisMonth;

  /// No description provided for @nothingYetThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet this month.'**
  String get nothingYetThisMonth;

  /// No description provided for @tagFriday.
  ///
  /// In en, this message translates to:
  /// **'Jumu\'ah'**
  String get tagFriday;

  /// No description provided for @tagMonThu.
  ///
  /// In en, this message translates to:
  /// **'Mondays & Thursdays'**
  String get tagMonThu;

  /// No description provided for @tagWhiteDays.
  ///
  /// In en, this message translates to:
  /// **'White Days'**
  String get tagWhiteDays;

  /// No description provided for @tagLastTen.
  ///
  /// In en, this message translates to:
  /// **'Last ten nights'**
  String get tagLastTen;

  /// No description provided for @tagArafah.
  ///
  /// In en, this message translates to:
  /// **'Arafah'**
  String get tagArafah;

  /// No description provided for @tagAshura.
  ///
  /// In en, this message translates to:
  /// **'Ashura'**
  String get tagAshura;

  /// No description provided for @tagMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get tagMorning;

  /// No description provided for @tagEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get tagEvening;

  /// No description provided for @tagNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get tagNight;

  /// No description provided for @fajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get fajr;

  /// No description provided for @searchHadith.
  ///
  /// In en, this message translates to:
  /// **'Search hadith'**
  String get searchHadith;

  /// No description provided for @savedHadith.
  ///
  /// In en, this message translates to:
  /// **'Saved hadith'**
  String get savedHadith;

  /// No description provided for @sunnahToPractise.
  ///
  /// In en, this message translates to:
  /// **'Sunnah to practise'**
  String get sunnahToPractise;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @collections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collections;

  /// No description provided for @hadithSourcesNote.
  ///
  /// In en, this message translates to:
  /// **'Texts and grades from the open hadith-api project (public domain). Large collections download once and then work offline.'**
  String get hadithSourcesNote;

  /// No description provided for @todayTag.
  ///
  /// In en, this message translates to:
  /// **'TODAY · {tag}'**
  String todayTag(String tag);

  /// No description provided for @sunnahLabel.
  ///
  /// In en, this message translates to:
  /// **'SUNNAH'**
  String get sunnahLabel;

  /// No description provided for @sizeMb.
  ///
  /// In en, this message translates to:
  /// **'{size} MB'**
  String sizeMb(int size);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @readyOffline.
  ///
  /// In en, this message translates to:
  /// **'{name} is ready offline'**
  String readyOffline(String name);

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeItem(String name);

  /// No description provided for @removeBookMessage.
  ///
  /// In en, this message translates to:
  /// **'It will be deleted from this device. You can download it again any time.'**
  String get removeBookMessage;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @hadithCountWithName.
  ///
  /// In en, this message translates to:
  /// **'{count} hadith · {name}'**
  String hadithCountWithName(int count, String name);

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @downloadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get downloadingEllipsis;

  /// No description provided for @downloadingPercent.
  ///
  /// In en, this message translates to:
  /// **'Downloading {percent}%'**
  String downloadingPercent(int percent);

  /// No description provided for @booksCountWithName.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 book} other{{count} books}} · {name}'**
  String booksCountWithName(int count, String name);

  /// No description provided for @searchIn.
  ///
  /// In en, this message translates to:
  /// **'Search {name}'**
  String searchIn(String name);

  /// No description provided for @hadithCount.
  ///
  /// In en, this message translates to:
  /// **'{count} hadith'**
  String hadithCount(int count);

  /// No description provided for @chapterHadithCount.
  ///
  /// In en, this message translates to:
  /// **'Chapter · {count} hadith'**
  String chapterHadithCount(int count);

  /// No description provided for @nothingInMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing in {name} matches \"{query}\"'**
  String nothingInMatches(String name, String query);

  /// No description provided for @searchHadithCountHint.
  ///
  /// In en, this message translates to:
  /// **'Search {count} hadith · word or number'**
  String searchHadithCountHint(int count);

  /// No description provided for @noHadithMatch.
  ///
  /// In en, this message translates to:
  /// **'No hadith match \"{query}\"'**
  String noHadithMatch(String query);

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @hadithResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hadith} other{{count} hadith}}'**
  String hadithResultCount(int count);

  /// No description provided for @bookAndNumber.
  ///
  /// In en, this message translates to:
  /// **'{book} {number}'**
  String bookAndNumber(String book, String number);

  /// No description provided for @downloadToReadOffline.
  ///
  /// In en, this message translates to:
  /// **'Download {book} in the Hadith tab to read this hadith offline.'**
  String downloadToReadOffline(String book);

  /// No description provided for @removeFromSaved.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get removeFromSaved;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @hadithCopied.
  ///
  /// In en, this message translates to:
  /// **'Hadith copied'**
  String get hadithCopied;

  /// No description provided for @grading.
  ///
  /// In en, this message translates to:
  /// **'GRADING'**
  String get grading;

  /// No description provided for @grade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get grade;

  /// No description provided for @sunnah.
  ///
  /// In en, this message translates to:
  /// **'Sunnah'**
  String get sunnah;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @searchHadithEnglishArabic.
  ///
  /// In en, this message translates to:
  /// **'Search hadith (English or Arabic)'**
  String get searchHadithEnglishArabic;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @searchEveryCollectionNote.
  ///
  /// In en, this message translates to:
  /// **'Searches every collection on this device. Download more collections in the Hadith tab.'**
  String get searchEveryCollectionNote;

  /// No description provided for @noHadithFound.
  ///
  /// In en, this message translates to:
  /// **'No hadith found'**
  String get noHadithFound;

  /// No description provided for @saveHadithHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark on any hadith to save it here.'**
  String get saveHadithHint;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @noBookmarksYet.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet.\nLong-press any ayah in the Mushaf to save it.'**
  String get noBookmarksYet;

  /// No description provided for @pageSavedOn.
  ///
  /// In en, this message translates to:
  /// **'Page {page} · saved {date}'**
  String pageSavedOn(int page, String date);

  /// No description provided for @listenOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'Listen offline anywhere.\nOpen any reciter and download one surah, a selection, or the whole Quran.'**
  String get listenOfflineHint;

  /// No description provided for @browseReciters.
  ///
  /// In en, this message translates to:
  /// **'Browse reciters'**
  String get browseReciters;

  /// No description provided for @sizeOnDevice.
  ///
  /// In en, this message translates to:
  /// **'{size} on this device'**
  String sizeOnDevice(String size);

  /// No description provided for @surahsAcrossRecitations.
  ///
  /// In en, this message translates to:
  /// **'{surahs} surahs across {recitations} recitations'**
  String surahsAcrossRecitations(int surahs, int recitations);

  /// No description provided for @countDownloading.
  ///
  /// In en, this message translates to:
  /// **' · {count} downloading'**
  String countDownloading(int count);

  /// No description provided for @recitationDownloadSummary.
  ///
  /// In en, this message translates to:
  /// **'{name} · {count}/{total} surahs · {size}'**
  String recitationDownloadSummary(
    String name,
    int count,
    int total,
    String size,
  );

  /// No description provided for @deleteDownloadsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete downloads?'**
  String get deleteDownloadsQuestion;

  /// No description provided for @freeSpaceMessage.
  ///
  /// In en, this message translates to:
  /// **'Free {size} by removing {name} from your phone.'**
  String freeSpaceMessage(String size, String name);

  /// No description provided for @thisReciter.
  ///
  /// In en, this message translates to:
  /// **'this reciter'**
  String get thisReciter;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @stopDownloading.
  ///
  /// In en, this message translates to:
  /// **'Stop downloading'**
  String get stopDownloading;

  /// No description provided for @deleteFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Delete from device'**
  String get deleteFromDevice;

  /// No description provided for @wholeQuran.
  ///
  /// In en, this message translates to:
  /// **'Whole Quran'**
  String get wholeQuran;

  /// No description provided for @juzNumber.
  ///
  /// In en, this message translates to:
  /// **'Juz {number}'**
  String juzNumber(String number);

  /// No description provided for @juzCount.
  ///
  /// In en, this message translates to:
  /// **'{count} juz'**
  String juzCount(int count);

  /// No description provided for @surahRange.
  ///
  /// In en, this message translates to:
  /// **'{surah} {from}–{to}'**
  String surahRange(String surah, int from, int to);

  /// No description provided for @surahsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 surah} other{{count} surahs}}'**
  String surahsCount(int count);

  /// No description provided for @chooseMoreAyahs.
  ///
  /// In en, this message translates to:
  /// **'Choose more ayahs or another question type'**
  String get chooseMoreAyahs;

  /// No description provided for @memorizationTest.
  ///
  /// In en, this message translates to:
  /// **'Memorization test'**
  String get memorizationTest;

  /// No description provided for @whatToTest.
  ///
  /// In en, this message translates to:
  /// **'What to test'**
  String get whatToTest;

  /// No description provided for @surahs.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get surahs;

  /// No description provided for @juz.
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get juz;

  /// No description provided for @ayahsTapForMore.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs · tap to choose more surahs'**
  String ayahsTapForMore(int count);

  /// No description provided for @ayahsRange.
  ///
  /// In en, this message translates to:
  /// **'Ayahs {from} – {to}'**
  String ayahsRange(int from, int to);

  /// No description provided for @wholeQuranQuizNote.
  ///
  /// In en, this message translates to:
  /// **'Questions from anywhere in the Quran: for those who have memorized all of it, or to see how much stays.'**
  String get wholeQuranQuizNote;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questions;

  /// No description provided for @howMany.
  ///
  /// In en, this message translates to:
  /// **'How many'**
  String get howMany;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @scoreOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{score} / {total}'**
  String scoreOfTotal(int score, int total);

  /// No description provided for @startScope.
  ///
  /// In en, this message translates to:
  /// **'Start · {scope}'**
  String startScope(String scope);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);

  /// No description provided for @chooseSurahs.
  ///
  /// In en, this message translates to:
  /// **'Choose surahs'**
  String get chooseSurahs;

  /// No description provided for @ayahsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ayah} other{{count} ayahs}}'**
  String ayahsCount(int count);

  /// No description provided for @chooseAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one'**
  String get chooseAtLeastOne;

  /// No description provided for @doneSelected.
  ///
  /// In en, this message translates to:
  /// **'Done · {count} selected'**
  String doneSelected(int count);

  /// No description provided for @questionOf.
  ///
  /// In en, this message translates to:
  /// **'{number} of {total}'**
  String questionOf(int number, int total);

  /// No description provided for @seeResults.
  ///
  /// In en, this message translates to:
  /// **'See results'**
  String get seeResults;

  /// No description provided for @nextWord.
  ///
  /// In en, this message translates to:
  /// **'Next word'**
  String get nextWord;

  /// No description provided for @showAyah.
  ///
  /// In en, this message translates to:
  /// **'Show ayah'**
  String get showAyah;

  /// No description provided for @iMadeMistakes.
  ///
  /// In en, this message translates to:
  /// **'I made mistakes'**
  String get iMadeMistakes;

  /// No description provided for @iHadItRight.
  ///
  /// In en, this message translates to:
  /// **'I had it right'**
  String get iHadItRight;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correct;

  /// No description provided for @rightAnswerHighlighted.
  ///
  /// In en, this message translates to:
  /// **'The right answer is highlighted'**
  String get rightAnswerHighlighted;

  /// No description provided for @reciteThenReveal.
  ///
  /// In en, this message translates to:
  /// **'Recite it, then reveal it word by word to check yourself.'**
  String get reciteThenReveal;

  /// No description provided for @wellDone.
  ///
  /// In en, this message translates to:
  /// **'Well done'**
  String get wellDone;

  /// No description provided for @keepRevisingAyah.
  ///
  /// In en, this message translates to:
  /// **'Keep revising this ayah'**
  String get keepRevisingAyah;

  /// No description provided for @resultPerfect.
  ///
  /// In en, this message translates to:
  /// **'ما شاء الله · Perfect'**
  String get resultPerfect;

  /// No description provided for @resultVeryGood.
  ///
  /// In en, this message translates to:
  /// **'Very good, keep revising'**
  String get resultVeryGood;

  /// No description provided for @resultGood.
  ///
  /// In en, this message translates to:
  /// **'Good effort, revise the ayahs below'**
  String get resultGood;

  /// No description provided for @resultRevise.
  ///
  /// In en, this message translates to:
  /// **'Revise these ayahs and try again'**
  String get resultRevise;

  /// No description provided for @ofTotal.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String ofTotal(int total);

  /// No description provided for @toRevise.
  ///
  /// In en, this message translates to:
  /// **'To revise'**
  String get toRevise;

  /// No description provided for @practiseMistakes.
  ///
  /// In en, this message translates to:
  /// **'Practise mistakes'**
  String get practiseMistakes;

  /// No description provided for @closePlayer.
  ///
  /// In en, this message translates to:
  /// **'Close player'**
  String get closePlayer;

  /// No description provided for @couldNotStartPlayback.
  ///
  /// In en, this message translates to:
  /// **'Could not start playback. Check your connection and try again.'**
  String get couldNotStartPlayback;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @openInMushaf.
  ///
  /// In en, this message translates to:
  /// **'Open in Mushaf'**
  String get openInMushaf;

  /// No description provided for @previousAyah.
  ///
  /// In en, this message translates to:
  /// **'Previous ayah'**
  String get previousAyah;

  /// No description provided for @previousSurah.
  ///
  /// In en, this message translates to:
  /// **'Previous surah'**
  String get previousSurah;

  /// No description provided for @nextAyah.
  ///
  /// In en, this message translates to:
  /// **'Next ayah'**
  String get nextAyah;

  /// No description provided for @nextSurah.
  ///
  /// In en, this message translates to:
  /// **'Next surah'**
  String get nextSurah;

  /// No description provided for @surah.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get surah;

  /// No description provided for @noAyahTimingNote.
  ///
  /// In en, this message translates to:
  /// **'This recitation has no ayah timing, so the ayah being recited cannot be highlighted. Reciters marked Ayah sync follow along exactly.'**
  String get noAyahTimingNote;

  /// No description provided for @backToCurrent.
  ///
  /// In en, this message translates to:
  /// **'Back to current'**
  String get backToCurrent;

  /// No description provided for @backToAyah.
  ///
  /// In en, this message translates to:
  /// **'Back to ayah {number}'**
  String backToAyah(int number);

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeatNote.
  ///
  /// In en, this message translates to:
  /// **'Memorization helper: repeat each ayah before moving on.'**
  String get repeatNote;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @eachAyah.
  ///
  /// In en, this message translates to:
  /// **'Each ayah'**
  String get eachAyah;

  /// No description provided for @ayahRepeatNeedsTiming.
  ///
  /// In en, this message translates to:
  /// **'Ayah repeat needs a reciter with ayah timing.'**
  String get ayahRepeatNeedsTiming;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimer;

  /// No description provided for @stopsAt.
  ///
  /// In en, this message translates to:
  /// **'Stops at {time}'**
  String stopsAt(String time);

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// No description provided for @endOfSurah.
  ///
  /// In en, this message translates to:
  /// **'End of surah'**
  String get endOfSurah;

  /// No description provided for @turnOff.
  ///
  /// In en, this message translates to:
  /// **'Turn off'**
  String get turnOff;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Surah, 2:255, الرحمن, mercy…'**
  String get searchHint;

  /// No description provided for @goTo.
  ///
  /// In en, this message translates to:
  /// **'Go to {surah} {reference}'**
  String goTo(String surah, String reference);

  /// No description provided for @meaningAndAyahs.
  ///
  /// In en, this message translates to:
  /// **'{meaning} · {count, plural, =1{1 ayah} other{{count} ayahs}}'**
  String meaningAndAyahs(String meaning, int count);

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @makki.
  ///
  /// In en, this message translates to:
  /// **'Makki'**
  String get makki;

  /// No description provided for @madani.
  ///
  /// In en, this message translates to:
  /// **'Madani'**
  String get madani;

  /// No description provided for @ayahCopied.
  ///
  /// In en, this message translates to:
  /// **'Ayah copied'**
  String get ayahCopied;

  /// No description provided for @pageNumber.
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String pageNumber(int number);

  /// No description provided for @bookmarksAndDownloads.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks & downloads'**
  String get bookmarksAndDownloads;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @goToPage.
  ///
  /// In en, this message translates to:
  /// **'Go to page'**
  String get goToPage;

  /// No description provided for @enterPageNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a page number from 1 to 604'**
  String get enterPageNumber;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @theOpening.
  ///
  /// In en, this message translates to:
  /// **'The Opening'**
  String get theOpening;

  /// No description provided for @pageAndAyah.
  ///
  /// In en, this message translates to:
  /// **'Page {page} · Ayah {ayah}'**
  String pageAndAyah(int page, int ayah);

  /// No description provided for @surahInfo.
  ///
  /// In en, this message translates to:
  /// **'{type} · {count, plural, =1{1 ayah} other{{count} ayahs}} · {meaning}'**
  String surahInfo(String type, int count, String meaning);

  /// No description provided for @juzNumberInt.
  ///
  /// In en, this message translates to:
  /// **'Juz {number}'**
  String juzNumberInt(int number);

  /// No description provided for @pageColour.
  ///
  /// In en, this message translates to:
  /// **'Page colour'**
  String get pageColour;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @juzAndPage.
  ///
  /// In en, this message translates to:
  /// **'Juz {juz} · Page {page}'**
  String juzAndPage(int juz, int page);

  /// No description provided for @onePage.
  ///
  /// In en, this message translates to:
  /// **'One page'**
  String get onePage;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {number} of {total}'**
  String pageOf(int number, int total);

  /// No description provided for @playThisPage.
  ///
  /// In en, this message translates to:
  /// **'Play this page'**
  String get playThisPage;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @paperTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get paperTheme;

  /// No description provided for @paperIvory.
  ///
  /// In en, this message translates to:
  /// **'Ivory'**
  String get paperIvory;

  /// No description provided for @paperWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get paperWhite;

  /// No description provided for @paperSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get paperSepia;

  /// No description provided for @paperDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get paperDark;

  /// No description provided for @paperBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get paperBlack;

  /// No description provided for @toDownload.
  ///
  /// In en, this message translates to:
  /// **'{count} to download'**
  String toDownload(int count);

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @unknownOffline.
  ///
  /// In en, this message translates to:
  /// **'Unknown (offline)'**
  String get unknownOffline;

  /// No description provided for @savedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedLabel;

  /// No description provided for @onThisPhone.
  ///
  /// In en, this message translates to:
  /// **'On this phone'**
  String get onThisPhone;

  /// No description provided for @downloadsBackgroundNote.
  ///
  /// In en, this message translates to:
  /// **'Downloads continue in the background, resume if interrupted, and play without internet once finished.'**
  String get downloadsBackgroundNote;

  /// No description provided for @wifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi only'**
  String get wifiOnly;

  /// No description provided for @wifiOnlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wait for Wi-Fi to save mobile data'**
  String get wifiOnlySubtitle;

  /// No description provided for @downloadWithSize.
  ///
  /// In en, this message translates to:
  /// **'Download · {size}'**
  String downloadWithSize(String size);

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating'**
  String get calculating;

  /// No description provided for @downloadSurahs.
  ///
  /// In en, this message translates to:
  /// **'Download {count, plural, =1{1 surah} other{{count} surahs}}'**
  String downloadSurahs(int count);

  /// No description provided for @alreadyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Already downloaded'**
  String get alreadyDownloaded;

  /// No description provided for @downloadingSurahs.
  ///
  /// In en, this message translates to:
  /// **'Downloading {count, plural, =1{1 surah} other{{count} surahs}} · {reciter}'**
  String downloadingSurahs(int count, String reciter);

  /// No description provided for @deleteAllDownloadsMessage.
  ///
  /// In en, this message translates to:
  /// **'All downloaded surahs of {name} ({recitation}) will be removed from this phone. You can download them again anytime.'**
  String deleteAllDownloadsMessage(String name, String recitation);

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @selectSurahsToDownload.
  ///
  /// In en, this message translates to:
  /// **'Select surahs to download'**
  String get selectSurahsToDownload;

  /// No description provided for @downloadJuzAmma.
  ///
  /// In en, this message translates to:
  /// **'Download Juz \'Amma (78–114)'**
  String get downloadJuzAmma;

  /// No description provided for @cancelDownloads.
  ///
  /// In en, this message translates to:
  /// **'Cancel downloads'**
  String get cancelDownloads;

  /// No description provided for @retryFailedDownloads.
  ///
  /// In en, this message translates to:
  /// **'Retry failed downloads'**
  String get retryFailedDownloads;

  /// No description provided for @deleteDownloads.
  ///
  /// In en, this message translates to:
  /// **'Delete downloads'**
  String get deleteDownloads;

  /// No description provided for @completeQuran.
  ///
  /// In en, this message translates to:
  /// **'Complete Quran'**
  String get completeQuran;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @downloadWholeQuran.
  ///
  /// In en, this message translates to:
  /// **'Download the whole Quran'**
  String get downloadWholeQuran;

  /// No description provided for @downloadAllSurahs.
  ///
  /// In en, this message translates to:
  /// **'Download all surahs'**
  String get downloadAllSurahs;

  /// No description provided for @allOffline.
  ///
  /// In en, this message translates to:
  /// **'All offline'**
  String get allOffline;

  /// No description provided for @stopCount.
  ///
  /// In en, this message translates to:
  /// **'Stop ({count})'**
  String stopCount(int count);

  /// No description provided for @downloadAll.
  ///
  /// In en, this message translates to:
  /// **'Download all'**
  String get downloadAll;

  /// No description provided for @longPressToSelect.
  ///
  /// In en, this message translates to:
  /// **'Long-press surahs to select several for download.'**
  String get longPressToSelect;

  /// No description provided for @notRecorded.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get notRecorded;

  /// No description provided for @removeSurahAudioMessage.
  ///
  /// In en, this message translates to:
  /// **'This surah\'s audio will be deleted from your phone.'**
  String get removeSurahAudioMessage;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @otherRiwayat.
  ///
  /// In en, this message translates to:
  /// **'Other riwayat'**
  String get otherRiwayat;

  /// No description provided for @mujawwad.
  ///
  /// In en, this message translates to:
  /// **'Mujawwad'**
  String get mujawwad;

  /// No description provided for @couldNotLoadReciters.
  ///
  /// In en, this message translates to:
  /// **'Could not load reciters\n{error}'**
  String couldNotLoadReciters(String error);

  /// No description provided for @searchRecitersHint.
  ///
  /// In en, this message translates to:
  /// **'Search {count} reciters · ابحث عن قارئ'**
  String searchRecitersHint(int count);

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @allReciters.
  ///
  /// In en, this message translates to:
  /// **'All reciters'**
  String get allReciters;

  /// No description provided for @recitersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reciter} other{{count} reciters}}'**
  String recitersCount(int count);

  /// No description provided for @nothingDownloadedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing downloaded yet. Open a reciter and tap download on any surah, or download the whole Quran.'**
  String get nothingDownloadedYet;

  /// No description provided for @favoritesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on a reciter to keep them here.'**
  String get favoritesHint;

  /// No description provided for @noRecitersMatch.
  ///
  /// In en, this message translates to:
  /// **'No reciters match your search.'**
  String get noRecitersMatch;

  /// No description provided for @mushaf.
  ///
  /// In en, this message translates to:
  /// **'Mushaf'**
  String get mushaf;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @countOffline.
  ///
  /// In en, this message translates to:
  /// **'{count} offline'**
  String countOffline(int count);

  /// No description provided for @playsInMushaf.
  ///
  /// In en, this message translates to:
  /// **'Plays in the Mushaf'**
  String get playsInMushaf;

  /// No description provided for @useForMushafPlayback.
  ///
  /// In en, this message translates to:
  /// **'Use for Mushaf playback'**
  String get useForMushafPlayback;

  /// No description provided for @willReciteInMushaf.
  ///
  /// In en, this message translates to:
  /// **'{name} will recite when you press play in the Mushaf'**
  String willReciteInMushaf(String name);

  /// No description provided for @remindersCardSubtitleShort.
  ///
  /// In en, this message translates to:
  /// **'Adhkar, prayer and daily reminders'**
  String get remindersCardSubtitleShort;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @mushafPageColour.
  ///
  /// In en, this message translates to:
  /// **'Mushaf page colour'**
  String get mushafPageColour;

  /// No description provided for @sameAsApp.
  ///
  /// In en, this message translates to:
  /// **'Same as the app'**
  String get sameAsApp;

  /// No description provided for @readingGroup.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get readingGroup;

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// No description provided for @turnPagesWithRecitation.
  ///
  /// In en, this message translates to:
  /// **'Turn pages with the recitation'**
  String get turnPagesWithRecitation;

  /// No description provided for @keepScreenOn.
  ///
  /// In en, this message translates to:
  /// **'Keep the screen on while reading'**
  String get keepScreenOn;

  /// No description provided for @listeningAndDownloads.
  ///
  /// In en, this message translates to:
  /// **'Listening & downloads'**
  String get listeningAndDownloads;

  /// No description provided for @downloadOnWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Download on Wi-Fi only'**
  String get downloadOnWifiOnly;

  /// No description provided for @downloadsAndBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Downloads & bookmarks'**
  String get downloadsAndBookmarks;

  /// No description provided for @remindersAndSound.
  ///
  /// In en, this message translates to:
  /// **'Reminders & sound'**
  String get remindersAndSound;

  /// No description provided for @dailyRemindersEvery.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders every {count, plural, =1{hour} other{{count} hours}}'**
  String dailyRemindersEvery(int count);

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About {appName}'**
  String aboutApp(String appName);

  /// No description provided for @versionFreeOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · free and open source'**
  String versionFreeOpenSource(String version);

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get themeMidnight;

  /// No description provided for @themeSemantics.
  ///
  /// In en, this message translates to:
  /// **'{theme} theme'**
  String themeSemantics(String theme);

  /// No description provided for @sourceQuranText.
  ///
  /// In en, this message translates to:
  /// **'Quran text & font'**
  String get sourceQuranText;

  /// No description provided for @sourceQuranTextDetail.
  ///
  /// In en, this message translates to:
  /// **'King Fahd Glorious Quran Printing Complex (KFGQPC), Uthmanic Hafs v18.'**
  String get sourceQuranTextDetail;

  /// No description provided for @sourceLayout.
  ///
  /// In en, this message translates to:
  /// **'Mushaf page layout'**
  String get sourceLayout;

  /// No description provided for @sourceLayoutDetail.
  ///
  /// In en, this message translates to:
  /// **'KFGQPC Hafs 15-line layout, via Quran.com (Quran Foundation).'**
  String get sourceLayoutDetail;

  /// No description provided for @sourceTranslations.
  ///
  /// In en, this message translates to:
  /// **'Translations'**
  String get sourceTranslations;

  /// No description provided for @sourceTranslationsDetail.
  ///
  /// In en, this message translates to:
  /// **'Saheeh International; Mahmud Muhammad Abduh (Somali), via Quran.com.'**
  String get sourceTranslationsDetail;

  /// No description provided for @sourceRecitations.
  ///
  /// In en, this message translates to:
  /// **'Recitations'**
  String get sourceRecitations;

  /// No description provided for @sourceRecitationsDetail.
  ///
  /// In en, this message translates to:
  /// **'MP3Quran.net: reciters, audio files and ayah timings. Audio streams and downloads directly from their servers.'**
  String get sourceRecitationsDetail;

  /// No description provided for @sourceAdhkarDetail.
  ///
  /// In en, this message translates to:
  /// **'Hisn al-Muslim by Sa\'id bin Ali bin Wahf Al-Qahtani; Quran passages from the KFGQPC text.'**
  String get sourceAdhkarDetail;

  /// No description provided for @sourceHadithDetail.
  ///
  /// In en, this message translates to:
  /// **'Arabic texts, English translations and grades from the hadith-api project by Fawaz Ahmed (public domain).'**
  String get sourceHadithDetail;

  /// No description provided for @sourceHijri.
  ///
  /// In en, this message translates to:
  /// **'Hijri calendar'**
  String get sourceHijri;

  /// No description provided for @sourceHijriDetail.
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura calculation, adjustable for local moon sighting.'**
  String get sourceHijriDetail;

  /// No description provided for @sourceAdhkarAudio.
  ///
  /// In en, this message translates to:
  /// **'Adhkar recordings'**
  String get sourceAdhkarAudio;

  /// No description provided for @sourceAdhkarAudioDetail.
  ///
  /// In en, this message translates to:
  /// **'hisnmuslim.com (Hisn al-Muslim) and, for Quranic adhkar, Mishary Alafasy via everyayah.com. Included in the app, so they play offline.'**
  String get sourceAdhkarAudioDetail;

  /// No description provided for @sourceAppIcon.
  ///
  /// In en, this message translates to:
  /// **'App icon'**
  String get sourceAppIcon;

  /// No description provided for @sourceAppIconDetail.
  ///
  /// In en, this message translates to:
  /// **'The name سراج in Amiri Bold (SIL Open Font License).'**
  String get sourceAppIconDetail;

  /// No description provided for @sourceReminderSound.
  ///
  /// In en, this message translates to:
  /// **'Reminder sound'**
  String get sourceReminderSound;

  /// No description provided for @sourceReminderSoundDetail.
  ///
  /// In en, this message translates to:
  /// **'Pixie Dust, from the Android Open Source Project (Apache 2.0).'**
  String get sourceReminderSoundDetail;

  /// No description provided for @sourcePrayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer times & Qibla'**
  String get sourcePrayer;

  /// No description provided for @sourcePrayerDetail.
  ///
  /// In en, this message translates to:
  /// **'Calculated on your phone with the open-source Adhan library.'**
  String get sourcePrayerDetail;

  /// No description provided for @sourceUiFont.
  ///
  /// In en, this message translates to:
  /// **'UI font'**
  String get sourceUiFont;

  /// No description provided for @sourceUiFontDetail.
  ///
  /// In en, this message translates to:
  /// **'IBM Plex Sans Arabic (SIL Open Font License).'**
  String get sourceUiFontDetail;

  /// No description provided for @aboutIntro.
  ///
  /// In en, this message translates to:
  /// **'Quran, Hadith and a daily guide. Version {version}.'**
  String aboutIntro(String version);

  /// No description provided for @aboutPrivacy.
  ///
  /// In en, this message translates to:
  /// **'No account, no ads, no tracking. Your bookmarks, history and downloads stay on this phone.'**
  String get aboutPrivacy;

  /// No description provided for @aboutOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Free and open source: {url}'**
  String aboutOpenSource(String url);

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sources;

  /// No description provided for @sourcesButton.
  ///
  /// In en, this message translates to:
  /// **'Sources of the texts and audio'**
  String get sourcesButton;

  /// No description provided for @licenseLegalese.
  ///
  /// In en, this message translates to:
  /// **'Quran · Hadith · Daily guide. Free and open source.'**
  String get licenseLegalese;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openSourceLicenses;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off'**
  String get notificationsOff;

  /// No description provided for @allowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications for Siraj in your phone settings to receive reminders.'**
  String get allowNotifications;

  /// No description provided for @dailyReminders.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders'**
  String get dailyReminders;

  /// No description provided for @dailyRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'An ayah, hadith, sunnah or dhikr through the day'**
  String get dailyRemindersSubtitle;

  /// No description provided for @dailyRemindersOn.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders are on'**
  String get dailyRemindersOn;

  /// No description provided for @varyTime.
  ///
  /// In en, this message translates to:
  /// **'Vary the time a little'**
  String get varyTime;

  /// No description provided for @varyTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Each reminder arrives a few minutes earlier or later'**
  String get varyTimeSubtitle;

  /// No description provided for @howOften.
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get howOften;

  /// No description provided for @everyHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every hour} other{Every {count} hours}}'**
  String everyHours(int count);

  /// No description provided for @activeHours.
  ///
  /// In en, this message translates to:
  /// **'Active hours'**
  String get activeHours;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @until.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get until;

  /// No description provided for @remindersPerDay.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reminder a day} other{{count} reminders a day}}. Nothing is sent outside these hours.'**
  String remindersPerDay(int count);

  /// No description provided for @whatToSend.
  ///
  /// In en, this message translates to:
  /// **'What to send · chosen at random'**
  String get whatToSend;

  /// No description provided for @remindersFollowDay.
  ///
  /// In en, this message translates to:
  /// **'Reminders follow the day: Surah Al-Kahf and salawat on Friday, a reminder the evening before the Monday and Thursday fasts, the White Days, Ramadan and its last ten nights, Dhul Hijjah, Arafah and Ashura, and adhkar in the morning, evening and before sleep.'**
  String get remindersFollowDay;

  /// No description provided for @previewReminder.
  ///
  /// In en, this message translates to:
  /// **'Preview a reminder'**
  String get previewReminder;

  /// No description provided for @morningEveningAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Morning & evening adhkar'**
  String get morningEveningAdhkar;

  /// No description provided for @prayerAndCalendar.
  ///
  /// In en, this message translates to:
  /// **'Prayer & calendar'**
  String get prayerAndCalendar;

  /// No description provided for @prayerTimeAlerts.
  ///
  /// In en, this message translates to:
  /// **'Prayer time alerts'**
  String get prayerTimeAlerts;

  /// No description provided for @choosePrayersAlert.
  ///
  /// In en, this message translates to:
  /// **'Choose which prayers alert you'**
  String get choosePrayersAlert;

  /// No description provided for @hijriDateAh.
  ///
  /// In en, this message translates to:
  /// **'{date} AH'**
  String hijriDateAh(String date);

  /// No description provided for @ummAlQuraNote.
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura calendar · adjust if your local moon sighting differs'**
  String get ummAlQuraNote;

  /// No description provided for @hijriAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Adjusted {offset} {days, plural, =1{day} other{days}}'**
  String hijriAdjusted(String offset, int days);

  /// No description provided for @oneDayEarlier.
  ///
  /// In en, this message translates to:
  /// **'One day earlier'**
  String get oneDayEarlier;

  /// No description provided for @oneDayLater.
  ///
  /// In en, this message translates to:
  /// **'One day later'**
  String get oneDayLater;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @sendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send a test notification'**
  String get sendTestNotification;

  /// No description provided for @seeAndHearReminder.
  ///
  /// In en, this message translates to:
  /// **'See and hear a reminder now'**
  String get seeAndHearReminder;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @rememberMeTranslation.
  ///
  /// In en, this message translates to:
  /// **'\"Remember Me; I will remember you.\" (2:152)'**
  String get rememberMeTranslation;

  /// No description provided for @adhkarReminders.
  ///
  /// In en, this message translates to:
  /// **'Adhkar reminders'**
  String get adhkarReminders;

  /// No description provided for @adhkarRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To read the morning and the evening adhkar, at the times you set'**
  String get adhkarRemindersSubtitle;

  /// No description provided for @morningAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Morning adhkar'**
  String get morningAdhkar;

  /// No description provided for @timeForMorningAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Time to read the morning adhkar'**
  String get timeForMorningAdhkar;

  /// No description provided for @eveningAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Evening adhkar'**
  String get eveningAdhkar;

  /// No description provided for @timeForEveningAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Time to read the evening adhkar'**
  String get timeForEveningAdhkar;

  /// No description provided for @pixieDust.
  ///
  /// In en, this message translates to:
  /// **'Pixie Dust'**
  String get pixieDust;

  /// No description provided for @pixieDustSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A soft, short chime · tap to hear it'**
  String get pixieDustSubtitle;

  /// No description provided for @phoneDefault.
  ///
  /// In en, this message translates to:
  /// **'Phone default'**
  String get phoneDefault;

  /// No description provided for @phoneDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your phone\'s notification sound'**
  String get phoneDefaultSubtitle;

  /// No description provided for @offlinePlayingDownloaded.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline · playing {reciter} (downloaded)'**
  String offlinePlayingDownloaded(String reciter);

  /// No description provided for @offlineDownloadSurah.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Download this surah to listen without internet.'**
  String get offlineDownloadSurah;

  /// No description provided for @downloadJuzAmmaTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Juz \'Amma'**
  String get downloadJuzAmmaTitle;

  /// No description provided for @startReading.
  ///
  /// In en, this message translates to:
  /// **'START READING'**
  String get startReading;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE READING'**
  String get continueReading;

  /// No description provided for @pageShort.
  ///
  /// In en, this message translates to:
  /// **'p. {page}'**
  String pageShort(int page);

  /// No description provided for @surahsOnDevice.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} surahs on this device'**
  String surahsOnDevice(int count, int total);

  /// No description provided for @countFailed.
  ///
  /// In en, this message translates to:
  /// **' · {count} failed'**
  String countFailed(int count);

  /// No description provided for @continueListeningCaps.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE LISTENING'**
  String get continueListeningCaps;

  /// No description provided for @ayahsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs'**
  String ayahsFound(String count);

  /// No description provided for @searchHitReference.
  ///
  /// In en, this message translates to:
  /// **'{surah} {reference} · page {page}'**
  String searchHitReference(String surah, String reference, int page);

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String durationSeconds(int seconds);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @dhikrYourTurnShort.
  ///
  /// In en, this message translates to:
  /// **'Dhikr {number} of {total} · your turn'**
  String dhikrYourTurnShort(int number, int total);

  /// No description provided for @afterSalah.
  ///
  /// In en, this message translates to:
  /// **'After {prayer}'**
  String afterSalah(String prayer);

  /// No description provided for @beforeFajr.
  ///
  /// In en, this message translates to:
  /// **'Before Fajr'**
  String get beforeFajr;

  /// No description provided for @bestBeforeSunrise.
  ///
  /// In en, this message translates to:
  /// **'Best before sunrise'**
  String get bestBeforeSunrise;

  /// No description provided for @dhikrThroughDay.
  ///
  /// In en, this message translates to:
  /// **'Dhikr through the day'**
  String get dhikrThroughDay;

  /// No description provided for @stillTimeUntilDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Still time · until Dhuhr'**
  String get stillTimeUntilDhuhr;

  /// No description provided for @bestBeforeMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Best before Maghrib'**
  String get bestBeforeMaghrib;

  /// No description provided for @duasOfQuran.
  ///
  /// In en, this message translates to:
  /// **'Duas of the Quran'**
  String get duasOfQuran;

  /// No description provided for @stillTimeTonight.
  ///
  /// In en, this message translates to:
  /// **'Still time · tonight'**
  String get stillTimeTonight;

  /// No description provided for @beforeYouSleep.
  ///
  /// In en, this message translates to:
  /// **'Before you sleep'**
  String get beforeYouSleep;

  /// No description provided for @wakingUp.
  ///
  /// In en, this message translates to:
  /// **'Waking up'**
  String get wakingUp;

  /// No description provided for @tasbihAndDhikr.
  ///
  /// In en, this message translates to:
  /// **'Tasbih & dhikr'**
  String get tasbihAndDhikr;

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @dhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get dhuhr;

  /// No description provided for @asr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get asr;

  /// No description provided for @maghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// No description provided for @isha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get isha;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @turnOnLocationServices.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services'**
  String get turnOnLocationServices;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied'**
  String get locationPermissionDenied;

  /// No description provided for @couldNotGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location'**
  String get couldNotGetLocation;

  /// No description provided for @morningAdhkarNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'أذكار الصباح · Morning adhkar'**
  String get morningAdhkarNotificationTitle;

  /// No description provided for @morningAdhkarNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Time to read the morning adhkar. Begin your day with the remembrance of Allah'**
  String get morningAdhkarNotificationBody;

  /// No description provided for @eveningAdhkarNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'أذكار المساء · Evening adhkar'**
  String get eveningAdhkarNotificationTitle;

  /// No description provided for @prayerNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'It is time for {prayer} prayer'**
  String prayerNotificationBody(String prayer);

  /// No description provided for @prayerNotificationBodyIn.
  ///
  /// In en, this message translates to:
  /// **'It is time for {prayer} prayer in {place}'**
  String prayerNotificationBodyIn(String prayer, String place);

  /// No description provided for @noInternetNothingDownloaded.
  ///
  /// In en, this message translates to:
  /// **'No internet connection and nothing downloaded for this reciter.'**
  String get noInternetNothingDownloaded;

  /// No description provided for @downloadingName.
  ///
  /// In en, this message translates to:
  /// **'Downloading {name}'**
  String downloadingName(String name);

  /// No description provided for @readyOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready offline'**
  String get readyOfflineTitle;

  /// No description provided for @downloadPaused.
  ///
  /// In en, this message translates to:
  /// **'Download paused'**
  String get downloadPaused;

  /// No description provided for @surahAndReciter.
  ///
  /// In en, this message translates to:
  /// **'Surah {number} · {reciter}'**
  String surahAndReciter(int number, String reciter);

  /// No description provided for @hadithDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed. Check your connection and try again.'**
  String get hadithDownloadFailed;

  /// No description provided for @quizNextAyah.
  ///
  /// In en, this message translates to:
  /// **'Next ayah'**
  String get quizNextAyah;

  /// No description provided for @quizPreviousAyah.
  ///
  /// In en, this message translates to:
  /// **'Previous ayah'**
  String get quizPreviousAyah;

  /// No description provided for @quizCompleteAyah.
  ///
  /// In en, this message translates to:
  /// **'Complete the ayah'**
  String get quizCompleteAyah;

  /// No description provided for @quizMissingWord.
  ///
  /// In en, this message translates to:
  /// **'Missing word'**
  String get quizMissingWord;

  /// No description provided for @quizWhichSurah.
  ///
  /// In en, this message translates to:
  /// **'Which surah?'**
  String get quizWhichSurah;

  /// No description provided for @quizRecite.
  ///
  /// In en, this message translates to:
  /// **'Recite from memory'**
  String get quizRecite;

  /// No description provided for @quizNextAyahDescription.
  ///
  /// In en, this message translates to:
  /// **'See an ayah and choose the one that follows it'**
  String get quizNextAyahDescription;

  /// No description provided for @quizPreviousAyahDescription.
  ///
  /// In en, this message translates to:
  /// **'See an ayah and choose the one before it'**
  String get quizPreviousAyahDescription;

  /// No description provided for @quizCompleteAyahDescription.
  ///
  /// In en, this message translates to:
  /// **'Read the beginning and choose how the ayah ends'**
  String get quizCompleteAyahDescription;

  /// No description provided for @quizMissingWordDescription.
  ///
  /// In en, this message translates to:
  /// **'One word is hidden; choose it from similar words'**
  String get quizMissingWordDescription;

  /// No description provided for @quizWhichSurahDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the surah an ayah belongs to'**
  String get quizWhichSurahDescription;

  /// No description provided for @quizReciteDescription.
  ///
  /// In en, this message translates to:
  /// **'Recite the next ayah yourself, then reveal and check'**
  String get quizReciteDescription;

  /// No description provided for @quizNextAyahAsk.
  ///
  /// In en, this message translates to:
  /// **'Which ayah comes next?'**
  String get quizNextAyahAsk;

  /// No description provided for @quizPreviousAyahAsk.
  ///
  /// In en, this message translates to:
  /// **'Which ayah comes before this one?'**
  String get quizPreviousAyahAsk;

  /// No description provided for @quizCompleteAyahAsk.
  ///
  /// In en, this message translates to:
  /// **'How does this ayah end?'**
  String get quizCompleteAyahAsk;

  /// No description provided for @quizMissingWordAsk.
  ///
  /// In en, this message translates to:
  /// **'Which word is missing?'**
  String get quizMissingWordAsk;

  /// No description provided for @quizWhichSurahAsk.
  ///
  /// In en, this message translates to:
  /// **'Which surah is this ayah from?'**
  String get quizWhichSurahAsk;

  /// No description provided for @quizReciteAsk.
  ///
  /// In en, this message translates to:
  /// **'Recite the next ayah from memory'**
  String get quizReciteAsk;

  /// No description provided for @channelPrayerDescription.
  ///
  /// In en, this message translates to:
  /// **'A reminder when each prayer time begins'**
  String get channelPrayerDescription;

  /// No description provided for @channelAdhkarDescription.
  ///
  /// In en, this message translates to:
  /// **'A reminder to read the morning and evening adhkar'**
  String get channelAdhkarDescription;

  /// No description provided for @channelDailyDescription.
  ///
  /// In en, this message translates to:
  /// **'An ayah, hadith, sunnah or dua through the day'**
  String get channelDailyDescription;

  /// No description provided for @testPrayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Asr · العصر'**
  String get testPrayerTitle;

  /// No description provided for @testDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get testDailyTitle;

  /// No description provided for @testAdhkarBody.
  ///
  /// In en, this message translates to:
  /// **'Time for your evening remembrance'**
  String get testAdhkarBody;

  /// No description provided for @testDailyBody.
  ///
  /// In en, this message translates to:
  /// **'\"Verily, in the remembrance of Allah do hearts find rest.\" (13:28)'**
  String get testDailyBody;

  /// No description provided for @sirajPlayback.
  ///
  /// In en, this message translates to:
  /// **'Siraj playback'**
  String get sirajPlayback;

  /// No description provided for @reminderAyah.
  ///
  /// In en, this message translates to:
  /// **'Ayah to reflect on'**
  String get reminderAyah;

  /// No description provided for @reminderSurah.
  ///
  /// In en, this message translates to:
  /// **'Surah to read'**
  String get reminderSurah;

  /// No description provided for @reminderDhikr.
  ///
  /// In en, this message translates to:
  /// **'Dhikr & dua'**
  String get reminderDhikr;

  /// No description provided for @hijriDateLabel.
  ///
  /// In en, this message translates to:
  /// **'{day} {month} {year}'**
  String hijriDateLabel(int day, String month, int year);

  /// No description provided for @suggestYaSin.
  ///
  /// In en, this message translates to:
  /// **'Read Surah Ya-Sin'**
  String get suggestYaSin;

  /// No description provided for @suggestArRahman.
  ///
  /// In en, this message translates to:
  /// **'Read Surah Ar-Rahman and reflect on the blessings of your Lord'**
  String get suggestArRahman;

  /// No description provided for @suggestAlWaqiah.
  ///
  /// In en, this message translates to:
  /// **'Read Surah Al-Waqi\'ah'**
  String get suggestAlWaqiah;

  /// No description provided for @suggestAlMulk.
  ///
  /// In en, this message translates to:
  /// **'Read Surah Al-Mulk tonight'**
  String get suggestAlMulk;

  /// No description provided for @suggestAsSajdah.
  ///
  /// In en, this message translates to:
  /// **'Read Surah As-Sajdah tonight'**
  String get suggestAsSajdah;

  /// No description provided for @suggestAlKahf.
  ///
  /// In en, this message translates to:
  /// **'Friday: read Surah Al-Kahf'**
  String get suggestAlKahf;

  /// No description provided for @suggestMaryam.
  ///
  /// In en, this message translates to:
  /// **'Read Surah Maryam'**
  String get suggestMaryam;

  /// No description provided for @suggestYusuf.
  ///
  /// In en, this message translates to:
  /// **'Read Surah Yusuf, \"the best of stories\"'**
  String get suggestYusuf;

  /// No description provided for @suggestAnNaba.
  ///
  /// In en, this message translates to:
  /// **'Read Surah An-Naba\''**
  String get suggestAnNaba;

  /// No description provided for @suggestAlFatihah.
  ///
  /// In en, this message translates to:
  /// **'Reflect on Al-Fatihah, the Mother of the Book'**
  String get suggestAlFatihah;

  /// No description provided for @suggestQuls.
  ///
  /// In en, this message translates to:
  /// **'Read Al-Ikhlas, Al-Falaq and An-Nas'**
  String get suggestQuls;

  /// No description provided for @suggestAlBaqarah.
  ///
  /// In en, this message translates to:
  /// **'Read the last two ayat of Al-Baqarah tonight'**
  String get suggestAlBaqarah;

  /// No description provided for @rememberAllah.
  ///
  /// In en, this message translates to:
  /// **'Remember Allah'**
  String get rememberAllah;

  /// No description provided for @rememberAllahBody.
  ///
  /// In en, this message translates to:
  /// **'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ · Glory be to Allah and praise be to Him'**
  String get rememberAllahBody;

  /// No description provided for @surahSuggestionBody.
  ///
  /// In en, this message translates to:
  /// **'{suggestion} ({count} ayat).'**
  String surahSuggestionBody(String suggestion, int count);

  /// No description provided for @reflectOn.
  ///
  /// In en, this message translates to:
  /// **'Reflect · {surah} {reference}'**
  String reflectOn(String surah, String reference);

  /// No description provided for @hadithReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Hadith · {book} {number}'**
  String hadithReminderTitle(String book, String number);

  /// No description provided for @sunnahReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Sunnah · {title}'**
  String sunnahReminderTitle(String title);

  /// No description provided for @sunnahFriday.
  ///
  /// In en, this message translates to:
  /// **'Sunnah · Jumu\'ah'**
  String get sunnahFriday;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
