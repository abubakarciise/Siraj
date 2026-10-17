import 'package:flutter/material.dart';

import 'theme.dart';
import 'tokens.dart';

/// The five tabs; each has a background tint of its own so the user always
/// feels where they are.
enum AppTab { home, quran, listen, hadith, daily }

extension AppTabX on AppTab {
  /// The hue each tab's background leans toward.
  Color get accent => switch (this) {
        AppTab.home => const Color(0xFF0F6B56), // emerald
        AppTab.quran => const Color(0xFFB8892F), // parchment gold
        AppTab.listen => const Color(0xFF2F7FA3), // calm teal-blue
        AppTab.hadith => const Color(0xFFB5653B), // warm sand
        AppTab.daily => const Color(0xFF5B5BA6), // dawn lavender
      };

  Color background(AppColors c) => Color.lerp(c.bg, accent, c.isDark ? (c.bg.computeLuminance() < 0.005 ? 0.07 : 0.10) : 0.085)!;
}

/// Gives a tab (and the pages opened inside it) its own background colour.
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
      return buildThemeFrom(c.withBg(tab.background(c)));
    });
    return Theme(data: theme, child: child);
  }
}
