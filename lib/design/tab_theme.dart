import 'package:flutter/material.dart';

import 'theme.dart';
import 'tokens.dart';

/// The five tabs; each has a background colour and a piece of art of its own,
/// so the user always feels where they are.
enum AppTab { home, quran, listen, hadith, daily }

extension AppTabX on AppTab {
  /// The hue each tab leans toward.
  Color get accent => switch (this) {
        AppTab.home => const Color(0xFF0F5C4A), // emerald
        AppTab.quran => const Color(0xFFB8892F), // parchment gold
        AppTab.listen => const Color(0xFF0F5C4A), // emerald
        AppTab.hadith => const Color(0xFF8A6A2B), // gold
        AppTab.daily => const Color(0xFF0F5C4A), // emerald
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

/// The tab's first page, on its own background.
class TabBackdrop extends StatelessWidget {
  const TabBackdrop({super.key, required this.tab, required this.child});
  final AppTab tab;
  final Widget child;

  @override
  Widget build(BuildContext context) => PageBackground(look: PageLook.values[tab.index], child: child);
}

/// Which page a background belongs to. Every page now shares one calm,
/// plain background (as the best Quran readers do); colour comes from each
/// screen's emerald hero instead of the page behind it.
enum PageLook { home, quran, listen, hadith, daily, tasbih, page }

/// The background of a page: the plain page colour. Scaffolds inside are made
/// transparent so it shows through; cards stay solid.
class PageBackground extends StatelessWidget {
  const PageBackground({super.key, this.look = PageLook.page, required this.child});
  final PageLook look;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: context.colors.bg,
      // Lists end above the phone's own bottom bar (drawn edge to edge, its
      // inset is otherwise lost to any list with padding of its own), while
      // the paper still runs behind it. Under the tabs this inset is already 0.
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Theme(
          data: theme.copyWith(scaffoldBackgroundColor: Colors.transparent),
          child: child,
        ),
      ),
    );
  }
}
