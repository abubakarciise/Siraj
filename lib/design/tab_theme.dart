
import 'package:flutter/material.dart';

import 'scenes.dart';
import 'theme.dart';
import 'tokens.dart';

export 'scenes.dart' show ArtKind, SceneBackdrop;

/// The five tabs; each has a background colour and a piece of art of its own,
/// so the user always feels where they are.
enum AppTab { home, quran, listen, hadith, daily }

extension AppTabX on AppTab {
  /// The hue each tab leans toward.
  Color get accent => switch (this) {
        AppTab.home => const Color(0xFF1F4E8C), // lapis
        AppTab.quran => const Color(0xFFB8892F), // parchment gold
        AppTab.listen => const Color(0xFF2A9D8F), // turquoise
        AppTab.hadith => const Color(0xFFB5653B), // warm sand
        AppTab.daily => const Color(0xFF5B5BA6), // dawn lavender
      };

  Color background(AppColors c) =>
      Color.lerp(c.bg, accent, c.isDark ? (c.bg.computeLuminance() < 0.005 ? 0.07 : 0.10) : 0.085)!;

  /// The tab's header and bottom bar: a deeper tint of its colour.
  Color header(AppColors c) =>
      Color.lerp(c.isDark ? c.surface : c.bg, accent, c.isDark ? (c.bg.computeLuminance() < 0.005 ? 0.16 : 0.22) : 0.20)!;
}

/// Gives a tab (and the pages opened inside it) its own colours.
class TabTheme extends StatelessWidget {
  const TabTheme({super.key, required this.tab, required this.child});
  final AppTab tab;
  final Widget child;

  static final _cache = <(AppColors, AppTab), ThemeData>{};

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = _cache.putIfAbsent((c, tab), () {
      if (_cache.length > 40) _cache.clear();
      final base = buildThemeFrom(c.withBg(tab.background(c)));
      return base.copyWith(appBarTheme: base.appBarTheme.copyWith(backgroundColor: tab.header(c)));
    });
    return Theme(data: theme, child: child);
  }
}

/// The tab's scene behind its first page (lib/design/scenes.dart). The
/// page's Scaffold must be transparent.
class TabBackdrop extends StatelessWidget {
  const TabBackdrop({super.key, required this.tab, required this.child});
  final AppTab tab;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SceneBackdrop(kind: ArtKind.values[tab.index], accent: tab.accent, child: child);
}
