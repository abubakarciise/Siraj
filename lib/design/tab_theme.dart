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

/// The tab's first page, on its own background.
class TabBackdrop extends StatelessWidget {
  const TabBackdrop({super.key, required this.tab, required this.child});
  final AppTab tab;
  final Widget child;

  @override
  Widget build(BuildContext context) => PageBackground(look: PageLook.values[tab.index], child: child);
}

/// Which background a page has: one for each main screen, and a lighter one
/// for every other page.
enum PageLook { home, quran, listen, hadith, daily, tasbih, page }

/// The background of a page: soft washes of emerald, gold and mint across the
/// whole screen, placed differently for each screen, and one large faint
/// ornament of its own (a rosette, an arch, rings, stars, the sun's arc).
/// Still: drawn once, in its own layer. Scaffolds inside are made
/// transparent so it shows through; cards stay solid.
class PageBackground extends StatelessWidget {
  const PageBackground({super.key, this.look = PageLook.page, required this.child});
  final PageLook look;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    return Stack(children: [
      Positioned.fill(
        child: RepaintBoundary(child: CustomPaint(painter: _PagePainter(c, look))),
      ),
      Theme(
        data: theme.copyWith(scaffoldBackgroundColor: Colors.transparent),
        child: child,
      ),
    ]);
  }
}

class _PagePainter extends CustomPainter {
  _PagePainter(this.c, this.look);
  final AppColors c;
  final PageLook look;

  static const _mint = Color(0xFF7FC8A9);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = c.bg);
    final emerald = c.primary, gold = c.gold;
    // (where, radius as a share of the width, colour, strength): every corner
    // has colour, so no part of the screen is left plain.
    final washes = switch (look) {
      PageLook.home => [
          (const Offset(1.0, 0.0), 0.95, emerald, 0.20),
          (const Offset(0.0, 0.0), 0.70, gold, 0.14),
          (const Offset(0.0, 0.55), 0.80, gold, 0.16),
          (const Offset(0.9, 1.0), 0.90, _mint, 0.20),
        ],
      PageLook.quran => [
          (const Offset(0.0, 0.0), 0.95, gold, 0.22),
          (const Offset(1.0, 0.0), 0.65, emerald, 0.14),
          (const Offset(1.0, 0.55), 0.85, emerald, 0.18),
          (const Offset(0.3, 1.0), 0.85, _mint, 0.18),
        ],
      PageLook.listen => [
          (const Offset(0.5, -0.05), 1.0, emerald, 0.20),
          (const Offset(0.0, 0.0), 0.75, _mint, 0.20),
          (const Offset(1.0, 0.0), 0.65, gold, 0.16),
          (const Offset(1.0, 0.85), 0.85, gold, 0.18),
          (const Offset(0.0, 0.7), 0.70, _mint, 0.18),
        ],
      PageLook.hadith => [
          (const Offset(1.0, 0.05), 0.95, gold, 0.24),
          (const Offset(0.0, 0.0), 0.70, _mint, 0.18),
          (const Offset(0.0, 0.75), 0.90, emerald, 0.18),
          (const Offset(1.0, 1.0), 0.75, gold, 0.16),
        ],
      PageLook.daily => [
          (const Offset(0.5, -0.08), 1.10, gold, 0.26),
          (const Offset(0.0, 0.35), 0.65, _mint, 0.18),
          (const Offset(1.0, 0.6), 0.75, _mint, 0.18),
          (const Offset(0.1, 1.0), 0.90, emerald, 0.18),
        ],
      PageLook.tasbih => [
          (const Offset(0.5, 0.42), 1.00, emerald, 0.16),
          (const Offset(0.0, 0.0), 0.70, gold, 0.18),
          (const Offset(1.0, 0.0), 0.60, _mint, 0.18),
          (const Offset(0.0, 1.0), 0.65, _mint, 0.18),
          (const Offset(1.0, 1.0), 0.75, gold, 0.18),
        ],
      PageLook.page => [
          (const Offset(1.0, 0.0), 0.85, emerald, 0.15),
          (const Offset(0.0, 0.0), 0.55, _mint, 0.14),
          (const Offset(0.0, 1.0), 0.85, gold, 0.14),
        ],
    };
    final k = c.isDark ? 0.8 : 1.0;
    for (final (at, r, color, strength) in washes) {
      final centre = Offset(at.dx * w, at.dy * h);
      final radius = r * w;
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [
            color.withValues(alpha: strength * k),
            color.withValues(alpha: strength * k * 0.45),
            color.withValues(alpha: 0),
          ], stops: const [0, 0.5, 1])
              .createShader(Rect.fromCircle(center: centre, radius: radius)),
      );
    }
    // The screen's own ornament, large and faint, spreading over the screen.
    final line = Paint()
      ..color = (c.isDark ? c.gold : c.primary).withValues(alpha: c.isDark ? 0.12 : 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    void rings(Offset o, double step, int n) {
      for (var i = 1; i <= n; i++) {
        canvas.drawCircle(o, step * i, line);
      }
    }

    switch (look) {
      case PageLook.home:
        final o = Offset(w * 0.86, h * 0.30);
        for (final f in [1.0, 0.74, 0.48]) {
          _star(canvas, o, w * 0.42 * f, line);
          canvas.drawCircle(o, w * 0.42 * f * 0.72, line);
        }
        rings(Offset(0, h), w * 0.15, 5);
      case PageLook.quran:
        for (final f in [1.0, 0.88]) {
          final r = Rect.fromCenter(center: Offset(w * 0.5, h * 0.78), width: w * 0.86 * f, height: h * 0.56 * f);
          final spring = r.top + r.height * 0.38;
          canvas.drawPath(
              Path()
                ..moveTo(r.left, h + 4)
                ..lineTo(r.left, spring)
                ..quadraticBezierTo(r.left, r.top + r.height * 0.06, r.center.dx, r.top)
                ..quadraticBezierTo(r.right, r.top + r.height * 0.06, r.right, spring)
                ..lineTo(r.right, h + 4),
              line);
        }
        rings(Offset.zero, w * 0.14, 5);
      case PageLook.listen:
        rings(Offset(0, h), w * 0.16, 7);
        rings(Offset(w, 0), w * 0.13, 5);
      case PageLook.hadith:
        // A great rosette opening from the top-right corner.
        final o = Offset(w, 0);
        for (var i = 1; i <= 5; i++) {
          _star(canvas, o, w * 0.20 * i, line);
          canvas.drawCircle(o, w * 0.20 * i * 0.72, line);
        }
        for (var i = 0; i < 3; i++) {
          _star(canvas, Offset(w * 0.10, h * (0.55 + i * 0.16)), w * 0.07, line);
        }
      case PageLook.daily:
        // The sun at the top, its rings and rays.
        final o = Offset(w * 0.5, 0);
        rings(o, w * 0.20, 7);
        for (var i = 0; i < 16; i++) {
          final a = i * math.pi / 8;
          final d = Offset(math.cos(a), math.sin(a));
          if (d.dy < 0) continue;
          canvas.drawLine(o + d * w * 0.24, o + d * w * 0.34, line);
        }
      case PageLook.tasbih:
        // Rings of beads around the misbaha.
        final o = Offset(w * 0.5, h * 0.40);
        final bead = Paint()..color = line.color;
        for (final (r, n) in [(0.56, 33), (0.74, 33), (0.92, 33)]) {
          for (var i = 0; i < n; i++) {
            final a = 2 * math.pi * i / n;
            canvas.drawCircle(o + Offset(math.cos(a), math.sin(a)) * w * r, 3.2, bead);
          }
        }
      case PageLook.page:
        rings(Offset(w, h), w * 0.15, 6);
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
  bool shouldRepaint(_PagePainter old) => old.c != c || old.look != look;
}
