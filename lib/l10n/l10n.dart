import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// The app's texts in the current language. Each language is one file,
/// lib/l10n/app_<code>.arb; English (app_en.arb) is the main one.
///
/// In widgets: `context.l10n.settings` (rebuilds when the language changes).
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Names that come as a set: weekdays and Hijri months.
extension AppLocalizationsX on AppLocalizations {
  /// [day]: 1 = Monday … 7 = Sunday (DateTime.weekday).
  String weekday(int day) => [monday, tuesday, wednesday, thursday, friday, saturday, sunday][day - 1];
  String weekdayShort(int day) => [mon, tue, wed, thu, fri, sat, sun][day - 1];

  /// [month]: 1 = Muharram … 12 = Dhul Hijjah.
  String hijriMonth(int month) => [
        muharram, safar, rabiAlAwwal, rabiAlThani, jumadaAlUla, jumadaAlAkhirah,
        rajab, shaban, ramadan, shawwal, dhulQadah, dhulHijjah,
      ][month - 1];
}

/// The same texts for code that has no BuildContext: notifications,
/// reminders and labels made in lib/core. Kept in step with the app's
/// language by [setL10nLocale].
AppLocalizations get l10n => _current;
AppLocalizations _current = lookupAppLocalizations(const Locale('en'));

/// Switches [l10n] to [locale] (called when the app's language is set).
void setL10nLocale(Locale locale) => _current = lookupAppLocalizations(locale);
