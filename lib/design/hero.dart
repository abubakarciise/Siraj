import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tokens.dart';
import 'widgets.dart';

/// Which scene a screen's header shows: each screen has its own, so the user
/// always knows where they are.
enum HeroArt { home, quran, listen, hadith, daily }

/// The header of a main screen: the logo's emerald, a fine lattice, and the
/// screen's own scene drawn in gold lines on the right. Still; drawn once.
class HeroBackground extends StatelessWidget {
  const HeroBackground({super.key, required this.art});
  final HeroArt art;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(c.brand, Colors.white, c.isDark ? 0.02 : 0.06)!,
            Color.lerp(c.brand, Colors.black, c.isDark ? 0.30 : 0.22)!,
          ],
        ),
      ),
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _HeroPainter(art, Color.lerp(c.gold, Colors.white, 0.25)!, c.onBrand),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// A [SliverAppBar] for a main screen: tall with the screen's scene, folding
/// into the plain emerald bar while scrolling.
class HeroSliverAppBar extends StatelessWidget {
  const HeroSliverAppBar({super.key, required this.title, required this.art, this.actions, this.subtitle});
  final String title;
  final String? subtitle;
  final HeroArt art;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 168,
      actions: actions,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(Radii.xl))),
      clipBehavior: Clip.antiAlias,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: Space.gutter, bottom: 16, end: 150),
        title: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TabTitle(title),
          if (subtitle != null)
            Text(subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: c.onBrand.withValues(alpha: 0.75), fontWeight: FontWeight.w500)),
        ]),
        background: HeroBackground(art: art),
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter(this.art, this.gold, this.light);
  final HeroArt art;
  final Color gold, light;

  Paint _line(double a, [double w = 1.6]) => Paint()
    ..color = gold.withValues(alpha: a)
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint _fill(double a) => Paint()..color = gold.withValues(alpha: a);

  @override
  void paint(Canvas canvas, Size size) {
    // A fine lattice over the whole header.
    final lattice = Paint()
      ..color = light.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const cell = 44.0;
    for (var y = -cell / 2; y < size.height + cell; y += cell) {
      for (var x = -cell / 2; x < size.width + cell; x += cell) {
        canvas.drawPath(starPath(Offset(x, y), cell * 0.40), lattice);
      }
    }
    // The scene sits on the right, standing on the bottom edge.
    // Lower right, under the header's buttons and clear of the title.
    final bh = math.min(size.height * 0.58, 104.0);
    final bw = bh * 1.15;
    final box = Rect.fromLTWH(size.width - bw - 14, size.height - bh - 4, bw, bh);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    switch (art) {
      case HeroArt.home:
        _mosque(canvas, box);
      case HeroArt.quran:
        _mihrab(canvas, box);
      case HeroArt.listen:
        _sound(canvas, box);
      case HeroArt.hadith:
        _manuscript(canvas, box);
      case HeroArt.daily:
        _sunPath(canvas, box);
    }
    canvas.restore();
  }

  Path _arch(Rect r, {double springK = 0.42}) {
    final spring = r.top + r.height * springK;
    return Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left, spring)
      ..quadraticBezierTo(r.left, r.top + r.height * 0.08, r.center.dx, r.top)
      ..quadraticBezierTo(r.right, r.top + r.height * 0.08, r.right, spring)
      ..lineTo(r.right, r.bottom);
  }

  void _crescent(Canvas canvas, Offset c, double r) {
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      Path()..addOval(Rect.fromCircle(center: c + Offset(r * 0.45, -r * 0.25), radius: r * 0.85)),
    );
    canvas.drawPath(moon, _fill(0.75));
  }

  /// Home: a mosque at dusk, with a crescent above.
  void _mosque(Canvas canvas, Rect b) {
    final p = _line(0.70, 1.8);
    final base = b.bottom;
    final cx = b.center.dx;
    final w = b.width;
    // Walls and door.
    canvas.drawRect(Rect.fromLTRB(cx - w * 0.30, base - w * 0.20, cx + w * 0.30, base), p);
    canvas.drawPath(_arch(Rect.fromLTRB(cx - w * 0.06, base - w * 0.14, cx + w * 0.06, base), springK: 0.5), p);
    // Dome with finial.
    final dome = Path()
      ..moveTo(cx - w * 0.20, base - w * 0.20)
      ..cubicTo(cx - w * 0.21, base - w * 0.42, cx - w * 0.04, base - w * 0.46, cx, base - w * 0.50)
      ..cubicTo(cx + w * 0.04, base - w * 0.46, cx + w * 0.21, base - w * 0.42, cx + w * 0.20, base - w * 0.20);
    canvas.drawPath(dome, p);
    canvas.drawLine(Offset(cx, base - w * 0.50), Offset(cx, base - w * 0.58), p);
    _crescent(canvas, Offset(cx, base - w * 0.61), w * 0.025);
    // Minarets.
    for (final side in [-1.0, 1.0]) {
      final mx = cx + side * w * 0.40;
      canvas.drawRect(Rect.fromLTRB(mx - w * 0.035, base - w * 0.56, mx + w * 0.035, base), p);
      canvas.drawLine(Offset(mx - w * 0.06, base - w * 0.44), Offset(mx + w * 0.06, base - w * 0.44), p);
      canvas.drawPath(
          Path()
            ..moveTo(mx - w * 0.035, base - w * 0.56)
            ..lineTo(mx, base - w * 0.66)
            ..lineTo(mx + w * 0.035, base - w * 0.56),
          p);
    }
    // The moon and a few stars.
    _crescent(canvas, Offset(b.left + w * 0.12, b.top + w * 0.12), w * 0.07);
    for (final s in [Offset(b.left + w * 0.30, b.top + w * 0.06), Offset(b.right - w * 0.05, b.top + w * 0.18)]) {
      canvas.drawPath(starPath(s, 4), _fill(0.6));
    }
  }

  /// Quran: a mihrab arch with a hanging lamp over an open Mushaf on its stand.
  void _mihrab(Canvas canvas, Rect b) {
    final p = _line(0.70, 1.8);
    final w = b.width;
    final arch = Rect.fromLTRB(b.center.dx - w * 0.34, b.top + w * 0.02, b.center.dx + w * 0.34, b.bottom);
    canvas.drawPath(_arch(arch), p);
    canvas.drawPath(_arch(arch.deflate(w * 0.05)), _line(0.40, 1.2));
    // The lamp.
    final cx = b.center.dx;
    final lampTop = arch.top + w * 0.10;
    canvas.drawLine(Offset(cx, lampTop), Offset(cx, lampTop + w * 0.12), p);
    final lamp = Path()
      ..moveTo(cx - w * 0.05, lampTop + w * 0.12)
      ..lineTo(cx + w * 0.05, lampTop + w * 0.12)
      ..lineTo(cx + w * 0.08, lampTop + w * 0.18)
      ..lineTo(cx + w * 0.04, lampTop + w * 0.25)
      ..lineTo(cx - w * 0.04, lampTop + w * 0.25)
      ..lineTo(cx - w * 0.08, lampTop + w * 0.18)
      ..close();
    canvas.drawCircle(Offset(cx, lampTop + w * 0.19), w * 0.13, _fill(0.10));
    canvas.drawPath(lamp, _fill(0.25));
    canvas.drawPath(lamp, p);
    // The open Mushaf on its rehal.
    final by = b.bottom - w * 0.10;
    for (final side in [-1.0, 1.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(cx, by)
            ..quadraticBezierTo(cx + side * w * 0.10, by - w * 0.07, cx + side * w * 0.20, by - w * 0.03)
            ..lineTo(cx + side * w * 0.20, by + w * 0.02)
            ..quadraticBezierTo(cx + side * w * 0.10, by - w * 0.02, cx, by + w * 0.04),
          p);
    }
    canvas.drawLine(Offset(cx - w * 0.16, by + w * 0.03), Offset(cx + w * 0.10, b.bottom), p);
    canvas.drawLine(Offset(cx + w * 0.16, by + w * 0.03), Offset(cx - w * 0.10, b.bottom), p);
  }

  /// Listen: sound spreading from an arch, and a waveform beneath.
  void _sound(Canvas canvas, Rect b) {
    final w = b.width;
    final c = Offset(b.center.dx, b.bottom - w * 0.18);
    for (var i = 1; i <= 5; i++) {
      final r = w * 0.09 * i;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), math.pi * 1.15, math.pi * 0.70, false,
          _line(0.75 - i * 0.11, 1.8));
    }
    canvas.drawCircle(c, w * 0.04, _fill(0.75));
    // The waveform.
    final wave = Path();
    for (var x = 0.0; x <= w; x += 4) {
      final k = x / w;
      final amp = w * 0.05 * math.sin(k * math.pi) * (0.6 + 0.4 * math.sin(k * 23));
      final y = b.bottom - w * 0.05 + amp * math.sin(x / 7);
      x == 0 ? wave.moveTo(b.left + x, y) : wave.lineTo(b.left + x, y);
    }
    canvas.drawPath(wave, _line(0.55, 1.4));
  }

  /// Hadith: an open manuscript with lines of text, and a reed pen.
  void _manuscript(Canvas canvas, Rect b) {
    final p = _line(0.70, 1.8);
    final w = b.width;
    final cx = b.center.dx, by = b.bottom - w * 0.06;
    for (final side in [-1.0, 1.0]) {
      final page = Path()
        ..moveTo(cx, by)
        ..quadraticBezierTo(cx + side * w * 0.18, by - w * 0.10, cx + side * w * 0.36, by - w * 0.04)
        ..lineTo(cx + side * w * 0.36, by - w * 0.44)
        ..quadraticBezierTo(cx + side * w * 0.18, by - w * 0.50, cx, by - w * 0.40)
        ..close();
      canvas.drawPath(page, _fill(0.07));
      canvas.drawPath(page, p);
      for (var k = 1; k <= 5; k++) {
        final y = by - w * 0.40 + k * w * 0.065;
        canvas.drawLine(Offset(cx + side * w * 0.06, y), Offset(cx + side * w * 0.30, y - w * 0.02), _line(0.40, 1.2));
      }
    }
    // The reed pen (qalam), resting across.
    final pen = Path()
      ..moveTo(b.right - w * 0.02, b.top + w * 0.06)
      ..lineTo(cx + w * 0.12, by - w * 0.46)
      ..lineTo(cx + w * 0.10, by - w * 0.43)
      ..close();
    canvas.drawPath(pen, _fill(0.6));
    canvas.drawCircle(Offset(cx + w * 0.11, by - w * 0.44), 2.2, _fill(0.8));
  }

  /// Daily: the sun's path through the day, the five prayers on it, the moon.
  void _sunPath(Canvas canvas, Rect b) {
    final w = b.width;
    final c = Offset(b.center.dx, b.bottom);
    final r = w * 0.44;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), math.pi, math.pi, false, _line(0.55, 1.6));
    canvas.drawLine(Offset(b.left, b.bottom - 1), Offset(b.right, b.bottom - 1), _line(0.5, 1.4));
    for (var i = 0; i < 5; i++) {
      final a = math.pi + math.pi * (0.12 + i * 0.19);
      final pt = c + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawCircle(pt, i == 2 ? 7 : 4.5, _fill(i == 2 ? 0.85 : 0.6));
    }
    // Rays around the noon sun.
    final sun = c + Offset(math.cos(math.pi * 1.5), math.sin(math.pi * 1.5)) * r;
    for (var k = 0; k < 8; k++) {
      final a = k * math.pi / 4;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(sun + d * 11, sun + d * 17, _line(0.6, 1.6));
    }
    _crescent(canvas, Offset(b.right - w * 0.06, b.top + w * 0.08), w * 0.06);
  }

  @override
  bool shouldRepaint(_HeroPainter old) => old.art != art || old.gold != gold || old.light != light;
}
