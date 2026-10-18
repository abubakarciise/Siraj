import 'package:flutter/material.dart';

/// Spacing, radius and motion tokens (docs/03_UX_UI_DESIGN.md §5–6).
abstract final class Space {
  static const double xs = 4, sm = 8, md = 12, lg = 16, xl = 20, xxl = 24, xxxl = 32;
  static const double gutter = 20;
}

abstract final class Radii {
  static const double sm = 8, md = 14, lg = 20, xl = 28;
}

abstract final class Motion {
  static const quick = Duration(milliseconds: 200);
  static const standard = Duration(milliseconds: 320);
  static const gentle = Duration(milliseconds: 480);
  static const curve = Curves.easeOutCubic;
  static const emphasized = Curves.easeInOutCubicEmphasized;
}

/// App-wide appearance. Light merges the old Paper and Sepia themes; Dark is a
/// warm graphite (no green cast, off-white text); Midnight is true black for
/// OLED screens with dimmed text so it never glares at night.
enum AppThemeKind { light, dark, midnight }

/// Colour of the Mushaf page only (the rest of the app keeps its theme).
enum MushafPaper { auto, ivory, white, sepia, dark, black }

/// Semantic color tokens; never hardcode colors in widgets.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.pageBg,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.primary,
    required this.primarySoft,
    required this.onPrimary,
    required this.brand,
    required this.onBrand,
    required this.gold,
    required this.divider,
    required this.danger,
    required this.isDark,
  });

  final Color bg, surface, surfaceAlt, pageBg, ink, inkMuted, inkFaint;
  final Color primary, primarySoft, onPrimary, gold, divider, danger;

  /// Deep, calm fill for hero cards (always readable with [onBrand]).
  final Color brand, onBrand;
  final bool isDark;

  Color get ayahHighlight => primary.withValues(alpha: isDark ? 0.20 : 0.13);
  Color get selection => gold.withValues(alpha: isDark ? 0.24 : 0.18);

  /// Headers and the bottom bar: a warm sand from the logo's gold, so they
  /// stand apart from the pages' backgrounds.
  Color get bar => Color.lerp(surface, gold, isDark ? 0.14 : 0.24)!;

  /// The line under a header and over the bottom bar.
  Color get barLine => Color.lerp(divider, gold, 0.35)!;

  /// Ayah-end ornaments and numbers on the Mushaf page.
  Color get ayahMark => Color.lerp(ink, gold, 0.55)!;

  static const light = AppColors(
    bg: Color(0xFFF1F5F3), // a cool off-white, faintly green
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE7EEEA),
    pageBg: Color(0xFFFBF7EE),
    ink: Color(0xFF14201B),
    inkMuted: Color(0xFF56635D),
    inkFaint: Color(0xFF96A39D),
    primary: Color(0xFF0F6B56),
    primarySoft: Color(0xFFDFEDE6),
    onPrimary: Color(0xFFFFFFFF),
    brand: Color(0xFF0E5A49),
    onBrand: Color(0xFFFFFCF6),
    gold: Color(0xFFA8813A),
    divider: Color(0xFFDDE6E1),
    danger: Color(0xFFB3402F),
    isDark: false,
  );

  static const dark = AppColors(
    bg: Color(0xFF0D1412), // green-black
    surface: Color(0xFF16201C),
    surfaceAlt: Color(0xFF1F2B26),
    pageBg: Color(0xFF17181B),
    ink: Color(0xFFE6ECE9),
    inkMuted: Color(0xFFA0ACA7),
    inkFaint: Color(0xFF66736D),
    primary: Color(0xFF7CC6AC),
    primarySoft: Color(0xFF203530),
    onPrimary: Color(0xFF0B1D17),
    brand: Color(0xFF1C3A32),
    onBrand: Color(0xFFEDE8DC),
    gold: Color(0xFFD5B26C),
    divider: Color(0xFF26332E),
    danger: Color(0xFFEF7B6B),
    isDark: true,
  );

  static const midnight = AppColors(
    bg: Color(0xFF000000),
    surface: Color(0xFF0B100E),
    surfaceAlt: Color(0xFF141B18),
    pageBg: Color(0xFF000000),
    ink: Color(0xFFD8D3C7),
    inkMuted: Color(0xFF99948A),
    inkFaint: Color(0xFF5E5A54),
    primary: Color(0xFF6DBB9F),
    primarySoft: Color(0xFF14261F),
    onPrimary: Color(0xFF07140F),
    brand: Color(0xFF112620),
    onBrand: Color(0xFFDCD7CB),
    gold: Color(0xFFC6A45E),
    divider: Color(0xFF1A2320),
    danger: Color(0xFFE8705F),
    isDark: true,
  );

  static AppColors of(AppThemeKind kind) => switch (kind) {
        AppThemeKind.light => light,
        AppThemeKind.dark => dark,
        AppThemeKind.midnight => midnight,
      };

  /// The app colours with the Mushaf page re-tinted for [paper].
  AppColors withPaper(MushafPaper paper) => switch (paper) {
        MushafPaper.auto => _paper(this, pageBg, ink),
        MushafPaper.ivory => _paper(light, const Color(0xFFFBF7EE), const Color(0xFF1F1C17)),
        MushafPaper.white => _paper(light, const Color(0xFFFFFFFF), const Color(0xFF111111)),
        MushafPaper.sepia => _paper(light, const Color(0xFFF3E7CE), const Color(0xFF3A2D1C),
            muted: const Color(0xFF6F5D44), gold: const Color(0xFF9A7230)),
        MushafPaper.dark => _paper(dark, dark.pageBg, dark.ink),
        MushafPaper.black => _paper(midnight, const Color(0xFF000000), midnight.ink),
      };

  /// Colours for the reader: bars, sheets and chips take the page colour itself
  /// (separated by hairlines), so nothing floats over the Mushaf in another tone.
  AppColors _paper(AppColors base, Color page, Color text, {Color? muted, Color? gold}) => AppColors(
        bg: page,
        surface: page,
        surfaceAlt: Color.lerp(page, text, base.isDark ? 0.10 : 0.06)!,
        pageBg: page,
        ink: text,
        inkMuted: muted ?? base.inkMuted,
        inkFaint: base.inkFaint,
        primary: base.primary,
        primarySoft: Color.lerp(page, base.primary, base.isDark ? 0.22 : 0.14)!,
        onPrimary: base.onPrimary,
        brand: base.brand,
        onBrand: base.onBrand,
        gold: gold ?? base.gold,
        divider: Color.lerp(page, text, base.isDark ? 0.16 : 0.12)!,
        danger: base.danger,
        isDark: base.isDark,
      );

  /// The same colours on another background (each tab has its own tint).
  AppColors withBg(Color background) => AppColors(
        bg: background,
        surface: surface,
        surfaceAlt: Color.lerp(surfaceAlt, background, 0.35)!,
        pageBg: pageBg,
        ink: ink,
        inkMuted: inkMuted,
        inkFaint: inkFaint,
        primary: primary,
        primarySoft: primarySoft,
        onPrimary: onPrimary,
        brand: brand,
        onBrand: onBrand,
        gold: gold,
        divider: divider,
        danger: danger,
        isDark: isDark,
      );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      pageBg: l(pageBg, other.pageBg),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      inkFaint: l(inkFaint, other.inkFaint),
      primary: l(primary, other.primary),
      primarySoft: l(primarySoft, other.primarySoft),
      onPrimary: l(onPrimary, other.onPrimary),
      brand: l(brand, other.brand),
      onBrand: l(onBrand, other.onBrand),
      gold: l(gold, other.gold),
      divider: l(divider, other.divider),
      danger: l(danger, other.danger),
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension AppThemeX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  TextTheme get text => Theme.of(this).textTheme;

  /// Title and subtitle in a header.
  TextStyle? get headerTitle => text.titleMedium;
  TextStyle? get headerSub => text.bodySmall;
}
