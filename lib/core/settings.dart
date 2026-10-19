import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design/tokens.dart';

enum ThemePref { system, light, dark, midnight }

@immutable
class AppSettings {
  const AppSettings({
    this.theme = ThemePref.system,
    this.paper = MushafPaper.auto,
    this.translation = '', // off until chosen in Settings
    this.wifiOnly = false,
    this.keepScreenOn = true,
    this.followAudio = true,
    this.defaultRecitation,
    this.onboarded = false,
  });

  final ThemePref theme;

  /// Mushaf page colour, independent of the app theme.
  final MushafPaper paper;

  /// Translation slug shown in the ayah sheet ('' = none).
  final String translation;
  final bool wifiOnly, keepScreenOn, followAudio, onboarded;
  final String? defaultRecitation;

  AppThemeKind resolve(bool platformDark) => switch (theme) {
        ThemePref.system => platformDark ? AppThemeKind.dark : AppThemeKind.light,
        ThemePref.light => AppThemeKind.light,
        ThemePref.dark => AppThemeKind.dark,
        ThemePref.midnight => AppThemeKind.midnight,
      };

  AppSettings copyWith({
    ThemePref? theme,
    MushafPaper? paper,
    String? translation,
    bool? wifiOnly,
    bool? keepScreenOn,
    bool? followAudio,
    String? defaultRecitation,
    bool? onboarded,
  }) =>
      AppSettings(
        theme: theme ?? this.theme,
        paper: paper ?? this.paper,
        translation: translation ?? this.translation,
        wifiOnly: wifiOnly ?? this.wifiOnly,
        keepScreenOn: keepScreenOn ?? this.keepScreenOn,
        followAudio: followAudio ?? this.followAudio,
        defaultRecitation: defaultRecitation ?? this.defaultRecitation,
        onboarded: onboarded ?? this.onboarded,
      );

  static AppSettings load(SharedPreferences p) => AppSettings(
        theme: _theme(p),
        paper: MushafPaper.values.asNameMap()[p.getString('paper')] ?? MushafPaper.auto,
        translation: p.getString('translation') ?? '',
        wifiOnly: p.getBool('wifiOnly') ?? false,
        keepScreenOn: p.getBool('keepScreenOn') ?? true,
        followAudio: p.getBool('followAudio') ?? true,
        defaultRecitation: p.getString('defaultRecitation'),
        onboarded: p.getBool('onboarded') ?? false,
      );

  /// v1 stored an index into (system, paper, sepia, night, amoled).
  static ThemePref _theme(SharedPreferences p) {
    final name = p.getString('theme2');
    if (name != null) return ThemePref.values.asNameMap()[name] ?? ThemePref.system;
    return switch (p.getInt('theme') ?? 0) {
      1 || 2 => ThemePref.light,
      3 => ThemePref.dark,
      4 => ThemePref.midnight,
      _ => ThemePref.system,
    };
  }

  Future<void> save(SharedPreferences p) async {
    await p.setString('theme2', theme.name);
    await p.setString('paper', paper.name);
    await p.setString('translation', translation);
    await p.setBool('wifiOnly', wifiOnly);
    await p.setBool('keepScreenOn', keepScreenOn);
    await p.setBool('followAudio', followAudio);
    if (defaultRecitation != null) await p.setString('defaultRecitation', defaultRecitation!);
    await p.setBool('onboarded', onboarded);
  }
}
