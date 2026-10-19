import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/quran/arabic.dart';
import '../../core/quran/models.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';

const _basmala = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ';

/// Natural line width / font size for the KFGQPC Hafs font is ~16 (median)
/// and up to ~22 (see test/mushaf_metrics_test.dart). The font size is chosen
/// per page from its widest line so all lines on a page share one size.
const _minWidthRatio = 15.5;
const _gapRatio = 0.2;
const _probeSize = 100.0;

/// Word widths at [_probeSize], per page. Measured once, then reused for every
/// screen size and theme.
final _probeCache = <int, List<List<double>>>{};

List<List<double>> _probe(MushafPage page) => _probeCache[page.number] ??= [
      for (final line in page.lines)
        [for (final w in line.words) _measure(w.text, _probeSize)],
    ];

double _measure(String text, double size) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontFamily: kQuranFont, fontSize: size, height: 1)),
    textDirection: TextDirection.rtl,
    maxLines: 1,
  )..layout();
  final w = tp.width;
  tp.dispose();
  return w;
}

double _pageWidthRatio(MushafPage page) {
  var maxRatio = _minWidthRatio;
  for (final widths in _probe(page)) {
    if (widths.isEmpty) continue;
    final w = widths.fold<double>(0, (a, b) => a + b) + _probeSize * _gapRatio * (widths.length - 1);
    maxRatio = math.max(maxRatio, w / _probeSize);
  }
  return maxRatio;
}

/// A fully laid-out line: one TextPainter per word, positioned right-to-left.
class _Line {
  _Line(this.line, this.rect, this.fontSize, this.painters, this.lefts);
  final MushafLine line;
  final Rect rect;
  final double fontSize;
  final List<TextPainter> painters;

  /// Word x positions relative to [rect.left].
  final List<double> lefts;
}

class _PageLayout {
  _PageLayout(this.lines, this.frame);
  final List<_Line> lines;

  /// Decorative frame of the two opening pages.
  final RRect? frame;

  AyahRef? hit(Offset p) {
    for (final l in lines) {
      if (l.line.type != LineType.ayah || p.dy < l.rect.top || p.dy > l.rect.bottom) continue;
      AyahRef? nearest;
      var best = double.infinity;
      for (var i = 0; i < l.painters.length; i++) {
        final x0 = l.rect.left + l.lefts[i], x1 = x0 + l.painters[i].width;
        final d = p.dx < x0 ? x0 - p.dx : (p.dx > x1 ? p.dx - x1 : 0.0);
        if (d < best) {
          best = d;
          nearest = l.line.words[i].ref;
        }
      }
      return nearest;
    }
    return null;
  }
}

/// Recently laid-out pages. Swiping back and forth, theme repaints and audio
/// highlight changes never re-measure text.
final _layoutCache = <String, _PageLayout>{}; // insertion-ordered: LRU

_PageLayout _layoutFor(MushafPage page, Size size, AppColors c, String Function(int) surahNames) {
  final key = '${page.number}|${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)}|'
      '${c.ink.toARGB32()}|${c.ayahMark.toARGB32()}';
  final hit = _layoutCache.remove(key);
  if (hit != null) return _layoutCache[key] = hit;
  final layout = _build(page, size, c, surahNames);
  _layoutCache[key] = layout;
  while (_layoutCache.length > 14) {
    // Not disposed: an evicted layout may still be on screen for a frame.
    _layoutCache.remove(_layoutCache.keys.first);
  }
  return layout;
}

TextPainter _painter(String text, double size, Color color) => TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontFamily: kQuranFont, fontSize: size, color: color, height: 1)),
      textDirection: TextDirection.rtl,
      maxLines: 1,
    )..layout();

_PageLayout _build(MushafPage page, Size size, AppColors c, String Function(int) surahNames) {
  final opening = page.number <= 2;
  final double lineH, innerW, left, fontSize;
  double top;
  RRect? frame;
  if (opening) {
    innerW = size.width * 0.74;
    lineH = math.min(size.height / 11, 64.0);
    fontSize = math.min(innerW / 13.2, lineH * 0.6);
    final frameH = lineH * page.lines.length + lineH * 1.2;
    final frameRect = Rect.fromCenter(center: size.center(Offset.zero), width: size.width * 0.9, height: frameH);
    frame = RRect.fromRectAndRadius(frameRect, Radius.circular(size.width * 0.07));
    left = (size.width - innerW) / 2;
    top = frameRect.top + lineH * 0.6;
  } else {
    innerW = size.width;
    lineH = size.height / 15;
    fontSize = math.min(size.width / _pageWidthRatio(page), lineH * 0.62);
    left = 0;
    top = 0;
  }

  final probe = _probe(page);
  final lines = <_Line>[];
  for (var li = 0; li < page.lines.length; li++) {
    final line = page.lines[li];
    final rect = Rect.fromLTWH(left, top, innerW, lineH);
    top += lineH;
    switch (line.type) {
      case LineType.surahHeader:
        final tp = _painter('سُورَةُ ${surahNames(line.surah!)}', fontSize * 0.92, c.ink);
        lines.add(_Line(line, rect, fontSize, [tp], [(innerW - tp.width) / 2]));
      case LineType.basmala:
        final tp = _painter(_basmala, fontSize, c.ink);
        lines.add(_Line(line, rect, fontSize, [tp], [(innerW - tp.width) / 2]));
      case LineType.ayah:
        final words = line.words;
        var fs = fontSize;
        var widths = [for (final w in probe[li]) w * fs / _probeSize];
        var natural = widths.fold<double>(0, (a, b) => a + b) + fs * _gapRatio * (words.length - 1);
        if (natural > innerW) {
          // Squeeze rare over-long lines instead of overflowing.
          fs *= innerW / natural * 0.995;
        }
        final painters = [
          for (final w in words) _painter(w.text, fs, w.isEnd ? c.ayahMark : c.ink),
        ];
        widths = [for (final p in painters) p.width];
        final textW = widths.fold<double>(0, (a, b) => a + b);
        natural = textW + fs * _gapRatio * (words.length - 1);
        final center = opening || natural < innerW * 0.72 || words.length == 1;
        final gap = center ? fs * _gapRatio : (innerW - textW) / math.max(1, words.length - 1);
        var x = center ? (innerW - natural) / 2 : 0.0;
        final lefts = <double>[];
        for (final w in widths) {
          lefts.add(innerW - x - w); // RTL: first word at the right edge
          x += w + gap;
        }
        lines.add(_Line(line, rect, fs, painters, lefts));
    }
  }
  return _PageLayout(lines, frame);
}

/// Renders one Madani Mushaf page from the KFGQPC 15-line layout:
/// every line is justified word-by-word, so line breaks match the printed Mushaf.
///
/// The text is laid out once per page/size/theme and painted in a single
/// layer; the recitation highlight lives on its own layer, so following the
/// audio repaints a few rectangles instead of rebuilding ~150 text widgets.
class MushafPageView extends StatelessWidget {
  const MushafPageView({
    super.key,
    required this.page,
    required this.surahNames,
    this.playing,
    this.selected,
    this.onAyahTap,
    this.onAyahLongPress,
  });

  final MushafPage page;
  final String Function(int surah) surahNames;
  final AyahRef? playing, selected;
  final void Function(AyahRef)? onAyahTap, onAyahLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(builder: (context, box) {
      final size = box.biggest;
      final layout = _layoutFor(page, size, c, surahNames);
      return Semantics(
        label: 'Page ${page.number}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: onAyahTap == null
              ? null
              : (d) {
                  final a = layout.hit(d.localPosition);
                  if (a != null) onAyahTap!(a);
                },
          onLongPressStart: onAyahLongPress == null
              ? null
              : (d) {
                  final a = layout.hit(d.localPosition);
                  if (a != null) onAyahLongPress!(a);
                },
          child: Stack(fit: StackFit.expand, children: [
            AnimatedSwitcher(
              duration: Motion.quick,
              child: CustomPaint(
                key: ValueKey((playing, selected)),
                size: size,
                painter: _HighlightPainter(layout, playing, selected, c.ayahHighlight, c.selection),
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(size: size, painter: _TextPainter(layout, c)),
            ),
          ]),
        ),
      );
    });
  }
}

class _TextPainter extends CustomPainter {
  _TextPainter(this.layout, this.c);
  final _PageLayout layout;
  final AppColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = layout.frame;
    if (frame != null) {
      // A faint gold wash inside the frame, warm like the page itself.
      canvas.drawRRect(frame, Paint()..color = c.gold.withValues(alpha: c.isDark ? 0.05 : 0.04));
      canvas.drawRRect(
        frame,
        Paint()
          ..color = c.gold.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
    for (final l in layout.lines) {
      if (l.line.type == LineType.surahHeader) _paintHeaderFrame(canvas, l.rect);
      for (var i = 0; i < l.painters.length; i++) {
        final p = l.painters[i];
        p.paint(canvas, Offset(l.rect.left + l.lefts[i], l.rect.center.dy - p.height / 2));
      }
    }
  }

  void _paintHeaderFrame(Canvas canvas, Rect line) {
    final rect = line.deflate(line.height * 0.1);
    final r = RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2));
    canvas.drawRRect(r, Paint()..color = c.gold.withValues(alpha: c.isDark ? 0.14 : 0.12));
    final stroke = Paint()
      ..color = c.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(r, stroke);
    canvas.drawRRect(r.deflate(3), stroke..strokeWidth = 0.6);
    final starR = rect.height * 0.26;
    for (final x in [rect.left + rect.height * 0.62, rect.right - rect.height * 0.62]) {
      canvas.drawPath(starPath(Offset(x, rect.center.dy), starR), stroke..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(_TextPainter old) => old.layout != layout || old.c != c;
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter(this.layout, this.playing, this.selected, this.playColor, this.selectColor);
  final _PageLayout layout;
  final AyahRef? playing, selected;
  final Color playColor, selectColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (ref, color) in [(selected, selectColor), (playing, playColor)]) {
      if (ref == null) continue;
      final paint = Paint()..color = color;
      for (final l in layout.lines) {
        double? lo, hi;
        for (var i = 0; i < l.painters.length && l.line.type == LineType.ayah; i++) {
          if (l.line.words[i].ref != ref) continue;
          final x = l.rect.left + l.lefts[i];
          lo = math.min(lo ?? double.infinity, x);
          hi = math.max(hi ?? 0, x + l.painters[i].width);
        }
        if (lo == null || hi == null) continue;
        final pad = l.fontSize * 0.12;
        canvas.drawRRect(
          RRect.fromLTRBR(lo - pad, l.rect.top + l.rect.height * 0.08, hi + pad, l.rect.bottom - l.rect.height * 0.04,
              const Radius.circular(Radii.sm)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HighlightPainter old) =>
      old.layout != layout || old.playing != playing || old.selected != selected || old.playColor != playColor;
}

/// Small header shown above a page: surah name and juz.
String pageHeaderLabel(MushafPage page, String Function(int) surahName) =>
    '${surahName(page.surahs.last)}  ·  الجزء ${toArabicDigits(page.juz)}';
