
import 'package:flutter/material.dart';

import 'theme.dart';
import 'tokens.dart';

/// The five tabs; each has a background colour and a piece of art of its own,
/// so the user always feels where they are.
enum AppTab { home, quran, listen, hadith, daily }

extension AppTabX on AppTab {
  /// The hue each tab leans toward.
  Color get accent => switch (this) {
        AppTab.home => const Color(0xFF0F6B56), // emerald
        AppTab.quran => const Color(0xFFB8892F), // parchment gold
        AppTab.listen => const Color(0xFF2A8F7F), // teal
        AppTab.hadith => const Color(0xFFA8733A), // bronze
        AppTab.daily => const Color(0xFF3C8D6B), // sea green
      };

  /// Every tab shares one background: the accent only colours its icons.
  Color background(AppColors c) => c.bg;
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
      return buildThemeFrom(c.withBg(tab.background(c)));
    });
    return Theme(data: theme, child: child);
  }
}

/// The tab's first page: the shared background, with the emerald header's
/// light fading softly down into it, so header and page read as one piece.
/// The page's Scaffold must be transparent.
class TabBackdrop extends StatelessWidget {
  const TabBackdrop({super.key, required this.tab, required this.child});
  final AppTab tab;
  final Widget child;

  @override
  Widget build(BuildContext context) => HeaderGlow(child: child);
}

/// The background with a soft emerald glow under the header.
class HeaderGlow extends StatelessWidget {
  const HeaderGlow({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.32, 1],
          colors: [
            Color.lerp(c.bg, c.brand, c.isDark ? 0.35 : 0.14)!,
            c.bg,
            c.bg,
          ],
        ),
      ),
      child: child,
    );
  }
}
