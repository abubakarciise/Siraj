import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

const kUiFont = 'Plex';
const kQuranFont = 'Hafs';

/// Classical Naskh for non-Quran Arabic (adhkar, duas); the Hafs font is Quran-only.
const kNaskhFont = 'Amiri';

/// Plex has no Latin transliteration letters (ḥ ṣ ṭ ḍ ẓ ʿ in "Muḥammad", "Ṣalāh"):
/// fall back to the system sans, then to Amiri, which ships with the app.
const kUiFallback = ['Roboto', 'sans-serif', kNaskhFont];

ThemeData buildTheme(AppThemeKind kind) => buildThemeFrom(AppColors.of(kind));

ThemeData buildThemeFrom(AppColors c) {
  final brightness = c.isDark ? Brightness.dark : Brightness.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.primary,
    onPrimary: c.onPrimary,
    secondary: c.gold,
    onSecondary: c.onPrimary,
    error: c.danger,
    onError: Colors.white,
    surface: c.surface,
    onSurface: c.ink,
    surfaceContainerHighest: c.surfaceAlt,
    outline: c.divider,
    outlineVariant: c.divider,
  );

  TextStyle s(double size, double height, FontWeight w, Color color, [double ls = 0]) => TextStyle(
        fontFamily: kUiFont,
        fontFamilyFallback: kUiFallback,
        fontSize: size,
        height: height / size,
        fontWeight: w,
        color: color,
        letterSpacing: ls,
      );

  final textTheme = TextTheme(
    displaySmall: s(34, 40, FontWeight.w700, c.ink, -0.5),
    headlineSmall: s(24, 30, FontWeight.w700, c.ink, -0.2),
    titleLarge: s(20, 26, FontWeight.w600, c.ink),
    titleMedium: s(16, 24, FontWeight.w600, c.ink),
    bodyLarge: s(16, 24, FontWeight.w400, c.ink),
    bodyMedium: s(14, 20, FontWeight.w400, c.ink),
    bodySmall: s(13, 18, FontWeight.w500, c.inkMuted),
    labelLarge: s(15, 20, FontWeight.w600, c.ink),
    labelSmall: s(11, 14, FontWeight.w600, c.inkMuted, 0.6),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    fontFamily: kUiFont,
    fontFamilyFallback: kUiFallback,
    textTheme: textTheme,
    extensions: [c],
    splashFactory: InkSparkle.splashFactory,
    dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
    iconTheme: IconThemeData(color: c.ink),
    listTileTheme: ListTileThemeData(
      iconColor: c.inkMuted,
      textColor: c.ink,
      subtitleTextStyle: textTheme.bodySmall,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
            (st) => st.contains(WidgetState.selected) ? c.primarySoft : Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith(
            (st) => st.contains(WidgetState.selected) ? c.primary : c.inkMuted),
        side: WidgetStateProperty.all(BorderSide(color: c.divider)),
        textStyle: WidgetStateProperty.all(s(13, 18, FontWeight.w600, c.ink)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary, linearTrackColor: c.divider),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: c.ink,
      titleTextStyle: textTheme.titleLarge,
      systemOverlayStyle: c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.primarySoft,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (st) => s(12, 16, FontWeight.w600, st.contains(WidgetState.selected) ? c.primary : c.inkMuted),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (st) => IconThemeData(color: st.contains(WidgetState.selected) ? c.primary : c.inkMuted),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        minimumSize: const Size(0, 52),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        minimumSize: const Size(0, 52),
        side: BorderSide(color: c.divider),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surfaceAlt,
      selectedColor: c.primarySoft,
      side: BorderSide.none,
      labelStyle: s(13, 18, FontWeight.w600, c.ink),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      showCheckmark: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceAlt,
      hintStyle: s(15, 20, FontWeight.w400, c.inkFaint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.md), borderSide: BorderSide.none),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.divider,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl))),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: c.primary,
      inactiveTrackColor: c.divider,
      thumbColor: c.primary,
      overlayColor: c.primary.withValues(alpha: 0.12),
      trackHeight: 3,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.ink,
      contentTextStyle: s(14, 20, FontWeight.w500, c.bg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? c.onPrimary : c.inkFaint),
      trackColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? c.primary : c.surfaceAlt),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xl)),
      dialBackgroundColor: c.surfaceAlt,
      dialHandColor: c.primary,
      hourMinuteColor: WidgetStateColor.resolveWith((st) => st.contains(WidgetState.selected) ? c.primarySoft : c.surfaceAlt),
      hourMinuteTextColor: WidgetStateColor.resolveWith((st) => st.contains(WidgetState.selected) ? c.primary : c.ink),
      dayPeriodColor: c.primarySoft,
      dayPeriodTextColor: c.ink,
      entryModeIconColor: c.inkMuted,
      helpTextStyle: textTheme.labelSmall,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xl)),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: c.inkMuted),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}
