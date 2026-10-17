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

/// The tab's art behind its first page, over the whole screen. The page's
/// Scaffold must be transparent.
class TabBackdrop extends StatelessWidget {
  const TabBackdrop({super.key, required this.tab, required this.child});
  final AppTab tab;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = c.isDark ? Color.lerp(tab.accent, Colors.white, 0.35)! : tab.accent;
    return ColoredBox(
      color: c.bg,
      child: Stack(children: [
        // Its own layer: scrolling the page never repaints the art.
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _TabArt(tab, ink.withValues(alpha: c.isDark ? 0.10 : 0.12))),
          ),
        ),
        child,
      ]),
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
    ..strokeWidth = 1.2;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    switch (tab) {
      case AppTab.home:
        _starLattice(canvas, size);
      case AppTab.quran:
        _arcades(canvas, size);
      case AppTab.listen:
        _waves(canvas, size);
      case AppTab.hadith:
        _manuscript(canvas, size);
      case AppTab.daily:
        _sky(canvas, size);
    }
  }

  /// An eight-point star (two squares) at [c], radius [r].
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

  /// Home: a lattice of eight-point stars joined by diamonds, edge to edge.
  void _starLattice(Canvas canvas, Size size) {
    final p = _line;
    const cell = 96.0;
    for (var y = -cell / 2, row = 0; y < size.height + cell; y += cell, row++) {
      for (var x = (row.isOdd ? cell / 2 : 0.0) - cell / 2; x < size.width + cell; x += cell) {
        final c = Offset(x, y);
        _star(canvas, c, cell * 0.30, p);
        canvas.drawCircle(c, cell * 0.12, p);
        // A small diamond between neighbours.
        final d = c + const Offset(cell / 2, 0);
        final path = Path()
          ..moveTo(d.dx, d.dy - 7)
          ..lineTo(d.dx + 7, d.dy)
          ..lineTo(d.dx, d.dy + 7)
          ..lineTo(d.dx - 7, d.dy)
          ..close();
        canvas.drawPath(path, p);
      }
    }
  }

  /// Quran: rows of pointed mihrab arches with hanging lamps, top to bottom.
  void _arcades(Canvas canvas, Size size) {
    final p = _line;
    const w = 120.0, h = 180.0;
    for (var row = 0; row * h < size.height + h; row++) {
      final top = row * h;
      final shift = row.isOdd ? w / 2 : 0.0;
      for (var x0 = -w + shift; x0 < size.width + w; x0 += w) {
        final x1 = x0 + w * 0.84, mid = (x0 + x1) / 2;
        final spring = top + h * 0.45, apex = top + h * 0.10, base = top + h;
        for (final inset in [0.0, 7.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(x0 + inset, base)
              ..lineTo(x0 + inset, spring)
              ..quadraticBezierTo(x0 + inset, apex + inset + 30, mid, apex + inset)
              ..quadraticBezierTo(x1 - inset, apex + inset + 30, x1 - inset, spring)
              ..lineTo(x1 - inset, base),
            p,
          );
        }
        final lamp = Offset(mid, top + h * 0.40);
        canvas.drawLine(Offset(mid, apex + 7), lamp - const Offset(0, 7), p);
        canvas.drawCircle(lamp, 5, p);
      }
    }
  }

  /// Listen: sound rings spreading from the lower left over the whole screen.
  void _waves(Canvas canvas, Size size) {
    final p = _line;
    final c = Offset(-size.width * 0.15, size.height * 1.05);
    final far = (Offset(size.width, 0) - c).distance;
    var i = 0;
    for (var r = 40.0; r < far + 40; r += 46, i++) {
      canvas.drawCircle(c, r, p..strokeWidth = i % 3 == 0 ? 1.8 : 0.9);
    }
  }

  /// Hadith: a ruled manuscript page with a double margin and rosettes down it.
  void _manuscript(Canvas canvas, Size size) {
    final p = _line;
    final frame = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    canvas.drawRRect(RRect.fromRectAndRadius(frame, const Radius.circular(12)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(frame.deflate(6), const Radius.circular(8)), p..strokeWidth = 0.8);
    final margin = size.width - 44;
    canvas.drawLine(Offset(margin, 16), Offset(margin, size.height - 16), p);
    for (var y = 60.0; y < size.height - 24; y += 30) {
      canvas.drawLine(Offset(28, y), Offset(margin - 12, y), p..strokeWidth = 0.6);
    }
    p.strokeWidth = 1.0;
    for (var y = 90.0; y < size.height - 40; y += 210) {
      _star(canvas, Offset(margin + 17, y), 11, p);
      canvas.drawCircle(Offset(margin + 17, y), 4, p);
    }
  }

  /// Daily: a night sky of small stars over the whole screen, a crescent, and
  /// the sun's path with the five prayers along the bottom.
  void _sky(Canvas canvas, Size size) {
    final p = _line;
    final rnd = math.Random(7);
    final count = (size.width * size.height / 5200).round();
    for (var i = 0; i < count; i++) {
      final s = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      final l = 1.5 + rnd.nextDouble() * 3.5;
      canvas.drawLine(s - Offset(l, 0), s + Offset(l, 0), p);
      canvas.drawLine(s - Offset(0, l), s + Offset(0, l), p);
    }
    // Crescent at the top right.
    final m = Offset(size.width - 70, 120);
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addOval(Rect.fromCircle(center: m, radius: 34)),
          Path()..addOval(Rect.fromCircle(center: m + const Offset(14, -8), radius: 30))),
      p..strokeWidth = 1.4,
    );
    // The sun's path and the five prayers.
    final c = Offset(size.width / 2, size.height * 1.02);
    final r = size.width * 0.62;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), math.pi, math.pi, false, p);
    for (var i = 0; i < 5; i++) {
      final a = math.pi + math.pi * (0.12 + i * 0.19);
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r, 6, p..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_TabArt old) => old.tab != tab || old.color != color;
}
