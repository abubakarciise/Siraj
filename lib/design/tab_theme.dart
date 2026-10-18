import 'dart:math' as math;


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
        AppTab.listen => const Color(0xFF0F6B56), // emerald
        AppTab.hadith => const Color(0xFFA8813A), // gold
        AppTab.daily => const Color(0xFF0F6B56), // emerald
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

/// The tab's first page, on the app's background.
class TabBackdrop extends StatelessWidget {
  const TabBackdrop({super.key, required this.tab, required this.child});
  final AppTab tab;
  final Widget child;

  @override
  Widget build(BuildContext context) => PageBackground(child: child);
}

/// The background of every page: the page colour with a very faint star
/// lattice, like a watermark. Still (drawn once, in its own layer). Scaffolds
/// inside are made transparent so it shows through; cards stay solid.
class PageBackground extends StatelessWidget {
  const PageBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    return Stack(children: [
      Positioned.fill(
        child: RepaintBoundary(child: CustomPaint(painter: _PagePainter(c))),
      ),
      Theme(
        data: theme.copyWith(scaffoldBackgroundColor: Colors.transparent),
        child: child,
      ),
    ]);
  }
}

class _PagePainter extends CustomPainter {
  _PagePainter(this.c);
  final AppColors c;

  @override
  void paint(Canvas canvas, Size size) {
    // Calm under the content: the page colour and a very faint lattice; each
    // screen's own design is in its header.
    canvas.drawRect(Offset.zero & size, Paint()..color = c.bg);
    final lattice = Paint()
      ..color = c.primary.withValues(alpha: c.isDark ? 0.05 : 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const cell = 64.0;
    for (var y = -cell / 2, row = 0; y < size.height + cell; y += cell, row++) {
      for (var x = (row.isOdd ? cell / 2 : 0.0) - cell / 2; x < size.width + cell; x += cell) {
        _star(canvas, Offset(x, y), cell * 0.30, lattice);
        canvas.drawCircle(Offset(x + cell / 2, y), cell * 0.07, lattice);
      }
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint p) {
    for (final rot in [0.0, math.pi / 4]) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = rot + i * math.pi / 2 + math.pi / 4;
        final pt = c + Offset(math.cos(a), math.sin(a)) * r;
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_PagePainter old) => old.c != c;
}
