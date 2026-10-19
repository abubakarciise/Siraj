import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

const kUiFont = 'Plex';

/// Serif for titles (Ivory Manuscript).
const kTitleFont = 'Lora';
const kQuranFont = 'Hafs';

/// Classical Naskh for non-Quran Arabic (adhkar, duas); the Hafs font is Quran-only.
const kNaskhFont = 'Amiri';

/// Plex has no Latin transliteration letters (ḥ ṣ ṭ ḍ ẓ ʿ in "Muḥammad", "Ṣalāh"):
/// fall back to the system sans, then to Amiri, which ships with the app.
const kUiFallback = ['Roboto', 'sans-serif', kNaskhFont];

ThemeData buildTheme(AppThemeKind kind) => buildThemeFrom(AppColors.of(kind));

/// The phone's own bars: a see-through status bar (no grey scrim over the
/// page, as some phones draw by default) and the gesture/button strip in the
/// ivory of the app's bottom bar.
SystemUiOverlayStyle systemBars(AppColors c, {Color? bottom}) {
  final base = c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;
  return base.copyWith(
    statusBarColor: Colors.transparent,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: bottom ?? c.navBar,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: c.isDark ? Brightness.light : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}

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

  // Titles in the Lora serif, like a printed book; everything else in Plex.
  TextStyle serif(double size, double height, FontWeight w, Color color) => TextStyle(
        fontFamily: kTitleFont,
        fontFamilyFallback: const [kUiFont, kNaskhFont],
        fontSize: size,
        height: height / size,
        fontWeight: w,
        color: color,
      );

  final textTheme = TextTheme(
    displaySmall: serif(34, 42, FontWeight.w600, c.ink),
    headlineMedium: serif(30, 38, FontWeight.w600, c.ink),
    headlineSmall: serif(24, 32, FontWeight.w600, c.ink),
    titleLarge: serif(20, 28, FontWeight.w600, c.ink),
    titleMedium: s(16, 24, FontWeight.w600, c.ink),
    bodyLarge: s(16, 24, FontWeight.w400, c.ink),
    bodyMedium: s(14, 20, FontWeight.w400, c.ink),
    bodySmall: s(13, 18, FontWeight.w500, c.inkMuted),
    labelLarge: s(15, 20, FontWeight.w600, c.ink),
    labelSmall: s(11, 14, FontWeight.w700, c.inkMuted, 0.8),
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
            (st) => st.contains(WidgetState.selected) ? c.brand : c.surface),
        foregroundColor: WidgetStateProperty.resolveWith(
            (st) => st.contains(WidgetState.selected) ? c.onBrand : c.inkMuted),
        side: WidgetStateProperty.all(BorderSide(color: c.divider)),
        textStyle: WidgetStateProperty.all(s(13, 18, FontWeight.w600, c.ink)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary, linearTrackColor: c.divider),
    // Headers sit on the paper with dark serif titles; once content scrolls
    // under them they turn card-ivory. The bottom bar is ivory over a gold
    // hairline, the open tab in emerald on a soft gold pill.
    appBarTheme: AppBarTheme(
      backgroundColor: WidgetStateColor.resolveWith((st) => st.contains(WidgetState.scrolledUnder) ? c.surface : c.bar),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: c.onBar,
      iconTheme: IconThemeData(color: c.onBar),
      actionsIconTheme: IconThemeData(color: c.inkMuted),
      titleTextStyle: textTheme.titleLarge?.copyWith(color: c.onBar),
      systemOverlayStyle: systemBars(c),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.navBar,
      surfaceTintColor: Colors.transparent,
      indicatorColor: c.navPill,
      height: 66,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (st) => s(12, 16, st.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            st.contains(WidgetState.selected) ? c.navSelected : c.onNav),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (st) => IconThemeData(color: st.contains(WidgetState.selected) ? c.navSelected : c.onNav),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        minimumSize: const Size(0, 52),
        textStyle: textTheme.labelLarge,
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        minimumSize: const Size(0, 52),
        side: BorderSide(color: c.divider, width: 1.2),
        textStyle: textTheme.labelLarge,
        shape: const StadiumBorder(),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      selectedColor: c.brand,
      side: BorderSide(color: c.divider),
      // The label's colour follows the chip's state, for every kind of chip
      // (filter chips ignore secondaryLabelStyle): cream on the emerald of a
      // selected chip, muted ink otherwise.
      labelStyle: s(13, 18, FontWeight.w600, c.inkMuted).copyWith(
        color: WidgetStateColor.resolveWith((st) => st.contains(WidgetState.selected) ? c.onBrand : c.inkMuted),
      ),
      secondaryLabelStyle: s(13, 18, FontWeight.w600, c.onBrand),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      showCheckmark: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      hintStyle: s(15, 20, FontWeight.w400, c.inkFaint),
      prefixIconColor: c.inkMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.lg), borderSide: BorderSide(color: c.divider)),
      enabledBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.lg), borderSide: BorderSide(color: c.divider)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.lg), borderSide: BorderSide(color: c.primary, width: 1.4)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: c.gold.withValues(alpha: 0.5),
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
