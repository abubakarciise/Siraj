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

/// The tab's first page, on the app's background.
class TabBackdrop extends StatelessWidget {
  const TabBackdrop({super.key, required this.tab, required this.child});
  final AppTab tab;
  final Widget child;

  @override
  Widget build(BuildContext context) => PageBackground(child: child);
}

/// The background of every page: a soft gradient from the header's emerald
/// into the page colour, warming with gold at the bottom; a fine star
/// lattice over all of it, like a watermark; and a large gold rosette in the
/// lower corner. Still (drawn once, in its own layer). Scaffolds inside are
/// made transparent so it shows through; cards stay solid.
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
    final rect = Offset.zero & size;
    // The gradient: emerald under the header, the page colour, a touch of gold.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.28, 0.75, 1],
          colors: [
            Color.lerp(c.bg, c.brand, c.isDark ? 0.42 : 0.16)!,
            c.bg,
            c.bg,
            Color.lerp(c.bg, c.gold, c.isDark ? 0.10 : 0.09)!,
          ],
        ).createShader(rect),
    );
    // The lattice: eight-point stars with small rings between, edge to edge.
    final lattice = Paint()
      ..color = c.primary.withValues(alpha: c.isDark ? 0.07 : 0.065)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const cell = 64.0;
    for (var y = -cell / 2, row = 0; y < size.height + cell; y += cell, row++) {
      for (var x = (row.isOdd ? cell / 2 : 0.0) - cell / 2; x < size.width + cell; x += cell) {
        _star(canvas, Offset(x, y), cell * 0.30, lattice);
        canvas.drawCircle(Offset(x + cell / 2, y), cell * 0.07, lattice);
      }
    }
    // The rosette: rings of stars, large and faint, in the lower corner.
    final rosette = Paint()
      ..color = c.gold.withValues(alpha: c.isDark ? 0.16 : 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final centre = Offset(size.width * 0.92, size.height * 0.86);
    final r = size.width * 0.42;
    for (final k in [1.0, 0.78, 0.56, 0.34]) {
      _star(canvas, centre, r * k, rosette);
      canvas.drawCircle(centre, r * k * 0.72, rosette);
    }
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      canvas.drawCircle(centre + Offset(math.cos(a), math.sin(a)) * r * 1.12, 4, rosette);
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
