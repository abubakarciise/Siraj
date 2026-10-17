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
        AppTab.listen => const Color(0xFF2F7FA3), // calm teal-blue
        AppTab.hadith => const Color(0xFFB5653B), // warm sand
        AppTab.daily => const Color(0xFF5B5BA6), // dawn lavender
      };

  Color background(AppColors c) =>
      Color.lerp(c.bg, accent, c.isDark ? (c.bg.computeLuminance() < 0.005 ? 0.07 : 0.10) : 0.085)!;
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

/// The tab's art behind its first page. The page's Scaffold must be transparent.
class TabBackdrop extends StatelessWidget {
  const TabBackdrop({super.key, required this.tab, required this.child});
  final AppTab tab;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = c.isDark ? Color.lerp(tab.accent, Colors.white, 0.35)! : tab.accent;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.bg),
      child: CustomPaint(
        painter: _TabArt(tab, ink.withValues(alpha: c.isDark ? 0.14 : 0.16)),
        child: child,
      ),
    );
  }
}

class _TabArt extends CustomPainter {
  _TabArt(this.tab, this.color);
  final AppTab tab;
  final Color color;

  Paint get _line => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;

  @override
  void paint(Canvas canvas, Size size) {
    switch (tab) {
      case AppTab.home:
        _rosette(canvas, Offset(size.width * 0.92, size.height * 0.78), size.width * 0.62);
      case AppTab.quran:
        _arches(canvas, size);
      case AppTab.listen:
        _waves(canvas, size);
      case AppTab.hadith:
        _manuscript(canvas, size);
      case AppTab.daily:
        _sunPath(canvas, size);
    }
  }

  /// An eight-point star rosette, rings of stars around it.
  void _rosette(Canvas canvas, Offset c, double r) {
    final p = _line;
    for (final k in [1.0, 0.72, 0.46]) {
      final rr = r * k;
      for (final rot in [0.0, math.pi / 4]) {
        final path = Path();
        for (var i = 0; i < 4; i++) {
          final a = rot + i * math.pi / 2 - math.pi / 4;
          final pt = c + Offset(math.cos(a), math.sin(a)) * rr;
          i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
        }
        path.close();
        canvas.drawPath(path, p);
      }
      canvas.drawCircle(c, rr * 0.71, p);
    }
  }

  /// Pointed mihrab arches standing along the bottom, like a mosque wall.
  void _arches(Canvas canvas, Size size) {
    final p = _line;
    final w = size.width / 3;
    for (var i = 0; i < 4; i++) {
      final x0 = -w / 2 + i * w, x1 = x0 + w * 0.86;
      final base = size.height;
      final spring = size.height * 0.62;
      final apex = size.height * 0.46;
      for (final inset in [0.0, w * 0.08]) {
        final path = Path()
          ..moveTo(x0 + inset, base)
          ..lineTo(x0 + inset, spring)
          ..quadraticBezierTo(x0 + inset, apex + (spring - apex) * 0.3, (x0 + x1) / 2, apex + inset)
          ..quadraticBezierTo(x1 - inset, apex + (spring - apex) * 0.3, x1 - inset, spring)
          ..lineTo(x1 - inset, base);
        canvas.drawPath(path, p);
      }
      // A hanging lamp in each arch.
      final lamp = Offset((x0 + x1) / 2, size.height * 0.58);
      canvas.drawLine(Offset(lamp.dx, apex + w * 0.08), lamp - const Offset(0, 8), p);
      canvas.drawCircle(lamp, 6, p);
    }
  }

  /// Sound rings from the bottom-left corner.
  void _waves(Canvas canvas, Size size) {
    final p = _line;
    final c = Offset(size.width * 0.05, size.height * 0.98);
    for (var i = 1; i <= 9; i++) {
      canvas.drawCircle(c, i * size.width * 0.12, p..strokeWidth = i.isEven ? 1.0 : 1.8);
    }
  }

  /// A manuscript page: a double frame with ruled lines in the lower half.
  void _manuscript(Canvas canvas, Size size) {
    final p = _line;
    final r = Rect.fromLTRB(14, size.height * 0.45, size.width - 14, size.height - 14);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(7), const Radius.circular(6)), p..strokeWidth = 0.8);
    for (var y = r.top + 40; y < r.bottom - 20; y += 26) {
      canvas.drawLine(Offset(r.left + 28, y), Offset(r.right - 28, y), p..strokeWidth = 0.8);
    }
    // A rosette in the margin, as in old manuscripts.
    _rosette(canvas, Offset(r.right - 4, r.top + 4), 26);
  }

  /// The sun's path through the day with the five prayer points, and stars.
  void _sunPath(Canvas canvas, Size size) {
    final p = _line;
    final c = Offset(size.width / 2, size.height * 1.02);
    final r = size.width * 0.62;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), math.pi, math.pi, false, p);
    for (var i = 0; i < 5; i++) {
      final a = math.pi + math.pi * (0.12 + i * 0.19);
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r, 7, p..style = PaintingStyle.fill);
    }
    p.style = PaintingStyle.stroke;
    final rnd = math.Random(7);
    for (var i = 0; i < 18; i++) {
      final s = Offset(rnd.nextDouble() * size.width, size.height * (0.5 + rnd.nextDouble() * 0.25));
      final l = 2.0 + rnd.nextDouble() * 3;
      canvas.drawLine(s - Offset(l, 0), s + Offset(l, 0), p);
      canvas.drawLine(s - Offset(0, l), s + Offset(0, l), p);
    }
  }

  @override
  bool shouldRepaint(_TabArt old) => old.tab != tab || old.color != color;
}
