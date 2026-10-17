import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';
import 'tokens.dart';

/// The living art behind each screen; each one shows what the screen is about.
enum ArtKind { home, quran, listen, hadith, daily, tasbih }

/// A screen's scene: a still picture drawn once (its own cached layer) and a
/// few moving things painted each frame, gently and without end, like rain.
/// Painting only (no rebuilds); it stops on hidden tabs (TickerMode), in the
/// background (no frames), and keeps still with "remove animations".
class SceneBackdrop extends StatefulWidget {
  const SceneBackdrop({super.key, required this.kind, required this.accent, required this.child});
  final ArtKind kind;
  final Color accent;
  final Widget child;

  @override
  State<SceneBackdrop> createState() => _SceneBackdropState();
}

class _SceneBackdropState extends State<SceneBackdrop> with SingleTickerProviderStateMixin {
  // One long loop; the scenes are written in seconds, so the motion is continuous.
  late final _clock = AnimationController(vsync: this, duration: const Duration(minutes: 10));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = c.isDark ? Color.lerp(widget.accent, Colors.white, 0.35)! : widget.accent;
    final scene = _Scene(widget.kind, ink, c.isDark);
    return ColoredBox(
      color: c.bg,
      child: Stack(children: [
        Positioned.fill(
          child: RepaintBoundary(child: CustomPaint(painter: _Still(scene))),
        ),
        Positioned.fill(
          child: RepaintBoundary(child: CustomPaint(painter: _Moving(scene, _clock))),
        ),
        widget.child,
      ]),
    );
  }
}

class _Still extends CustomPainter {
  _Still(this.scene);
  final _Scene scene;

  @override
  void paint(Canvas canvas, Size size) => scene.still(canvas, size);

  @override
  bool shouldRepaint(_Still old) => old.scene != scene;
}

class _Moving extends CustomPainter {
  _Moving(this.scene, this.clock) : super(repaint: clock);
  final _Scene scene;
  final AnimationController clock;

  @override
  void paint(Canvas canvas, Size size) {
    final seconds = (clock.lastElapsedDuration ?? Duration.zero).inMicroseconds / 1e6;
    scene.moving(canvas, size, seconds);
  }

  @override
  bool shouldRepaint(_Moving old) => old.scene != scene;
}

/// The scenes. Positions come from fixed seeds and the time, so nothing is
/// stored between frames and the motion loops for ever.
class _Scene {
  _Scene(this.kind, this.ink, this.dark);
  final ArtKind kind;
  final Color ink;
  final bool dark;

  @override
  bool operator ==(Object other) => other is _Scene && other.kind == kind && other.ink == ink && other.dark == dark;

  @override
  int get hashCode => Object.hash(kind, ink, dark);

  Paint _fill(double a) => Paint()..color = ink.withValues(alpha: a);
  Paint _line(double a, [double w = 1.3]) => Paint()
    ..color = ink.withValues(alpha: a)
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  void still(Canvas canvas, Size size) {
    switch (kind) {
      case ArtKind.home:
        _skyline(canvas, size);
      case ArtKind.quran:
        _rehal(canvas, size);
      case ArtKind.listen:
        break; // all of it moves
      case ArtKind.hadith:
        _books(canvas, size);
      case ArtKind.daily:
        _horizon(canvas, size);
      case ArtKind.tasbih:
        _rosette(canvas, size);
    }
  }

  void moving(Canvas canvas, Size size, double t) {
    switch (kind) {
      case ArtKind.home:
        _stars(canvas, size, t);
        _lanterns(canvas, size, t);
      case ArtKind.quran:
        _risingLight(canvas, size, t);
      case ArtKind.listen:
        _waves(canvas, size, t);
      case ArtKind.hadith:
        _letterRain(canvas, size, t);
      case ArtKind.daily:
        _sunAndClouds(canvas, size, t);
      case ArtKind.tasbih:
        _beadRain(canvas, size, t);
    }
  }

  // ---------------------------------------------------------------- Home --

  /// A mosque on the horizon: a great dome, two small ones and two minarets.
  void _skyline(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final base = h * 0.94;
    final p = _fill(dark ? 0.10 : 0.09);
    final path = Path()..addRect(Rect.fromLTRB(0, base, w, h));
    // Walls.
    path.addRect(Rect.fromLTRB(w * 0.18, base - h * 0.07, w * 0.82, base));
    // Great dome with its finial.
    final dc = Offset(w * 0.5, base - h * 0.07);
    final dr = w * 0.17;
    path.addPath(_dome(dc, dr, dr * 1.15), Offset.zero);
    path.addRect(Rect.fromCenter(center: dc - Offset(0, dr * 1.15 + 10), width: 2.5, height: 20));
    // Small domes.
    for (final x in [0.29, 0.71]) {
      path.addPath(_dome(Offset(w * x, base - h * 0.07), w * 0.07, w * 0.08), Offset.zero);
    }
    // Minarets.
    for (final x in [0.12, 0.88]) {
      final mx = w * x, top = base - h * 0.30;
      path.addRect(Rect.fromLTRB(mx - 9, top, mx + 9, base));
      path.addRect(Rect.fromLTRB(mx - 14, top + h * 0.06, mx + 14, top + h * 0.06 + 6)); // balcony
      path.addPath(
          Path()
            ..moveTo(mx - 9, top)
            ..lineTo(mx, top - 34)
            ..lineTo(mx + 9, top)
            ..close(),
          Offset.zero);
    }
    canvas.drawPath(path, p);
  }

  Path _dome(Offset base, double r, double height) => Path()
    ..moveTo(base.dx - r, base.dy)
    ..cubicTo(base.dx - r, base.dy - height * 0.75, base.dx - r * 0.25, base.dy - height * 0.85, base.dx,
        base.dy - height)
    ..cubicTo(base.dx + r * 0.25, base.dy - height * 0.85, base.dx + r, base.dy - height * 0.75, base.dx + r, base.dy)
    ..close();

  /// Stars that twinkle softly over the whole sky.
  void _stars(Canvas canvas, Size size, double t) {
    final rnd = math.Random(11);
    for (var i = 0; i < 46; i++) {
      final pos = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.75);
      final speed = 0.6 + rnd.nextDouble() * 1.2, phase = rnd.nextDouble() * 6.28;
      final glow = 0.5 + 0.5 * math.sin(t * speed + phase);
      final r = 1.2 + rnd.nextDouble() * 1.8;
      final p = _line((dark ? 0.12 : 0.14) + 0.18 * glow, 1.1);
      canvas.drawLine(pos - Offset(r * 2, 0), pos + Offset(r * 2, 0), p);
      canvas.drawLine(pos - Offset(0, r * 2), pos + Offset(0, r * 2), p);
    }
  }

  /// Three lanterns hanging from above, swaying, their light breathing.
  void _lanterns(Canvas canvas, Size size, double t) {
    for (final (x, len, phase) in [(0.14, 0.20, 0.0), (0.86, 0.26, 1.7), (0.66, 0.12, 3.1)]) {
      final pivot = Offset(size.width * x, 0);
      final angle = 0.07 * math.sin(t * 0.9 + phase);
      canvas.save();
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(angle);
      final l = size.height * len;
      canvas.drawLine(Offset.zero, Offset(0, l), _line(0.20, 1));
      final glow = 0.5 + 0.5 * math.sin(t * 1.3 + phase);
      canvas.drawCircle(Offset(0, l + 18), 30 + 6 * glow, _fill(0.05 + 0.04 * glow));
      // The lantern: cap, glass body, base.
      final body = Path()
        ..moveTo(-8, l + 4)
        ..lineTo(8, l + 4)
        ..lineTo(13, l + 16)
        ..lineTo(9, l + 32)
        ..lineTo(-9, l + 32)
        ..lineTo(-13, l + 16)
        ..close();
      canvas.drawPath(body, _fill(0.14));
      canvas.drawPath(body, _line(0.30, 1.2));
      canvas.drawLine(Offset(-5, l + 36), Offset(5, l + 36), _line(0.30, 2));
      canvas.restore();
    }
  }

  // --------------------------------------------------------------- Quran --

  /// An open Mushaf on its stand (rehal), low in the middle of the screen.
  void _rehal(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w / 2, h * 0.86);
    final s = w * 0.30;
    final line = _line(dark ? 0.18 : 0.20, 2);
    // The crossed legs of the stand.
    canvas.drawLine(c + Offset(-s, -s * 0.15), c + Offset(s * 0.7, s * 0.55), line);
    canvas.drawLine(c + Offset(s, -s * 0.15), c + Offset(-s * 0.7, s * 0.55), line);
    // Two open pages.
    final fill = _fill(0.07);
    for (final side in [-1.0, 1.0]) {
      final page = Path()
        ..moveTo(c.dx, c.dy - s * 0.05)
        ..quadraticBezierTo(c.dx + side * s * 0.5, c.dy - s * 0.32, c.dx + side * s, c.dy - s * 0.18)
        ..lineTo(c.dx + side * s, c.dy + s * 0.02)
        ..quadraticBezierTo(c.dx + side * s * 0.5, c.dy - s * 0.12, c.dx, c.dy + s * 0.15)
        ..close();
      canvas.drawPath(page, fill);
      canvas.drawPath(page, _line(0.22, 1.4));
      // Lines of text.
      for (var k = 1; k <= 4; k++) {
        final y = c.dy - s * 0.22 + k * s * 0.055;
        canvas.drawLine(Offset(c.dx + side * s * 0.15, y), Offset(c.dx + side * s * 0.85, y - s * 0.04),
            _line(0.12, 1));
      }
    }
  }

  /// Golden motes of light rising from the Mushaf, without end.
  void _risingLight(Canvas canvas, Size size, double t) {
    final rnd = math.Random(5);
    final h = size.height;
    final from = Offset(size.width / 2, h * 0.80);
    for (var i = 0; i < 42; i++) {
      final speed = 16 + rnd.nextDouble() * 26; // px per second
      final travel = h * (0.55 + rnd.nextDouble() * 0.35);
      final offset = rnd.nextDouble() * travel;
      final spread = (rnd.nextDouble() - 0.5) * size.width * 0.9;
      final phase = rnd.nextDouble() * 6.28;
      final k = ((t * speed + offset) % travel) / travel; // 0 at the book, 1 at the top
      final x = from.dx + spread * k + 10 * math.sin(t * 0.8 + phase);
      final y = from.dy - k * travel;
      final a = (1 - k) * math.min(1, k * 6) * (dark ? 0.32 : 0.36);
      canvas.drawCircle(Offset(x, y), 1.6 + 2.2 * (1 - k), _fill(a));
    }
  }

  // -------------------------------------------------------------- Listen --

  /// Sound: waves flowing across the screen and bars that rise and fall.
  void _waves(Canvas canvas, Size size, double t) {
    final w = size.width, h = size.height;
    for (final (yk, amp, len, speed, a) in [
      (0.52, 22.0, 260.0, 60.0, 0.16),
      (0.64, 30.0, 330.0, -45.0, 0.13),
      (0.76, 18.0, 210.0, 80.0, 0.18),
    ]) {
      final path = Path();
      for (var x = 0.0; x <= w; x += 6) {
        final y = h * yk + amp * math.sin((x + t * speed) / len * 2 * math.pi) * (0.6 + 0.4 * math.sin(t * 0.5 + yk * 9));
        x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(path, _line(a, 1.6));
    }
    // Equalizer along the bottom.
    const bars = 22;
    final bw = w / bars;
    for (var i = 0; i < bars; i++) {
      final v = 0.25 + 0.75 * (0.5 + 0.5 * math.sin(t * (2.0 + (i % 5) * 0.37) + i * 0.9)).abs();
      final bh = h * 0.12 * v;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(i * bw + bw * 0.22, h - bh, bw * 0.56, bh), const Radius.circular(3)),
        _fill(dark ? 0.10 : 0.09),
      );
    }
  }

  // -------------------------------------------------------------- Hadith --

  /// Books and a scroll at the bottom: the collections.
  void _books(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final base = h * 0.97;
    final fill = _fill(dark ? 0.09 : 0.08), line = _line(0.18, 1.3);
    // A stack of three books.
    final widths = [w * 0.34, w * 0.30, w * 0.26];
    var y = base;
    for (var i = 0; i < 3; i++) {
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08 + i * 6, y - 26, widths[i], 24), const Radius.circular(4));
      canvas.drawRRect(r, fill);
      canvas.drawRRect(r, line);
      canvas.drawLine(Offset(r.left + 10, r.top + 12), Offset(r.right - 10, r.top + 12), _line(0.14, 1));
      y -= 28;
    }
    // A scroll, rolled at both ends.
    final sx = w * 0.58, sy = base - 70, sw = w * 0.34;
    canvas.drawRect(Rect.fromLTWH(sx, sy, sw, 56), fill);
    canvas.drawRect(Rect.fromLTWH(sx, sy, sw, 56), line);
    for (final x in [sx, sx + sw]) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, sy + 28), width: 12, height: 70),
          const Radius.circular(6)), fill);
    }
    for (var k = 1; k <= 3; k++) {
      canvas.drawLine(Offset(sx + 12, sy + k * 14), Offset(sx + sw - 12, sy + k * 14), _line(0.12, 1));
    }
  }

  static const _letters = 'ابتثجحخدذرزسشصضطظعغفقكلمنهوي';
  final _glyphs = <String, TextPainter>{};

  TextPainter _glyph(String ch, double fontSize, double alpha) {
    final key = '$ch|${fontSize.round()}|${(alpha * 20).round()}';
    return _glyphs.putIfAbsent(key, () {
      final tp = TextPainter(
        text: TextSpan(
          text: ch,
          style: TextStyle(fontSize: fontSize, color: ink.withValues(alpha: alpha), fontFamily: kNaskhFont),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      return tp;
    });
  }

  /// Arabic letters falling slowly, like rain.
  void _letterRain(Canvas canvas, Size size, double t) {
    final rnd = math.Random(3);
    final h = size.height + 60;
    for (var i = 0; i < 30; i++) {
      final ch = _letters[rnd.nextInt(_letters.length)];
      final x = rnd.nextDouble() * size.width;
      final speed = 22 + rnd.nextDouble() * 30;
      final y0 = rnd.nextDouble() * h;
      final fs = 16 + rnd.nextDouble() * 16;
      final y = (y0 + t * speed) % h - 40;
      final tp = _glyph(ch, fs, dark ? 0.20 : 0.22);
      canvas.save();
      canvas.translate(x + 6 * math.sin(t * 0.7 + i), y);
      canvas.rotate(0.15 * math.sin(t * 0.5 + i * 1.3));
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  // --------------------------------------------------------------- Daily --

  /// The horizon with the path of the sun and the five prayers on it.
  void _horizon(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w / 2, h * 0.98);
    final r = w * 0.62;
    final dash = _line(0.18, 1.4);
    for (var a = math.pi; a < 2 * math.pi; a += 0.06) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, 0.03, false, dash);
    }
    for (var i = 0; i < 5; i++) {
      final a = math.pi + math.pi * (0.12 + i * 0.19);
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r, 5, _fill(0.22));
    }
    canvas.drawLine(Offset(0, h * 0.98), Offset(w, h * 0.98), _line(0.18, 1.4));
  }

  /// The sun walking its path, with clouds drifting by.
  void _sunAndClouds(Canvas canvas, Size size, double t) {
    final w = size.width, h = size.height;
    final c = Offset(w / 2, h * 0.98);
    final r = w * 0.62;
    // One crossing of the sky every 50 seconds.
    final k = (t % 50) / 50;
    final a = math.pi + math.pi * k;
    final sun = c + Offset(math.cos(a), math.sin(a)) * r;
    final fade = math.sin(math.pi * k); // rises and sets softly
    canvas.drawCircle(sun, 34, _fill(0.06 * fade));
    canvas.drawCircle(sun, 16, _fill(0.22 * fade));
    for (var i = 0; i < 8; i++) {
      final ra = i * math.pi / 4 + t * 0.3;
      final d = Offset(math.cos(ra), math.sin(ra));
      canvas.drawLine(sun + d * 22, sun + d * 30, _line(0.22 * fade, 1.6));
    }
    // Clouds.
    final rnd = math.Random(9);
    for (var i = 0; i < 5; i++) {
      final y = h * (0.12 + rnd.nextDouble() * 0.5);
      final speed = 8 + rnd.nextDouble() * 12;
      final s = 0.7 + rnd.nextDouble() * 0.7;
      final span = w + 200;
      final x = (rnd.nextDouble() * span + t * speed) % span - 100;
      final p = _fill(dark ? 0.08 : 0.09);
      for (final (dx, dy, rr) in [(0.0, 0.0, 20.0), (22.0, -10.0, 26.0), (48.0, 0.0, 20.0), (24.0, 6.0, 22.0)]) {
        canvas.drawCircle(Offset(x + dx * s, y + dy * s), rr * s, p);
      }
    }
  }

  // -------------------------------------------------------------- Tasbih --

  void _rosette(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final p = _line(0.10, 1);
    for (var r = 90.0; r < size.longestSide * 0.7; r += 70) {
      canvas.drawCircle(c, r, p);
    }
  }

  /// Prayer beads falling softly, like rain.
  void _beadRain(Canvas canvas, Size size, double t) {
    final rnd = math.Random(17);
    final h = size.height + 40;
    for (var i = 0; i < 36; i++) {
      final x = rnd.nextDouble() * size.width;
      final speed = 30 + rnd.nextDouble() * 40;
      final y = (rnd.nextDouble() * h + t * speed) % h - 20;
      final r = 3.0 + rnd.nextDouble() * 4;
      final sway = 8 * math.sin(t * 0.9 + i);
      canvas.drawCircle(Offset(x + sway, y), r, _fill(dark ? 0.20 : 0.22));
      canvas.drawCircle(Offset(x + sway - r * 0.3, y - r * 0.3), r * 0.35, _fill(0.25));
    }
  }
}
