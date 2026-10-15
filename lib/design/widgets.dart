import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/downloads/download_manager.dart';
import 'theme.dart';
import 'tokens.dart';

extension TextScaled on BuildContext {
  /// [size] scaled by the system font size, for boxes that hold text
  /// (horizontal carousels need a fixed height).
  double ts(double size) => MediaQuery.textScalerOf(this).scale(size);
}

/// Eight-pointed star (Rub el Hizb) path, used for medallions and ornaments.
Path starPath(Offset center, double r) {
  final path = Path();
  for (final rot in [0.0, math.pi / 4]) {
    final sq = Path();
    for (var i = 0; i < 4; i++) {
      final a = rot + i * math.pi / 2 - math.pi / 4;
      final pt = center + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? sq.moveTo(pt.dx, pt.dy) : sq.lineTo(pt.dx, pt.dy);
    }
    sq.close();
    path.addPath(sq, Offset.zero);
  }
  return path;
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.color, this.fill);
  final Color color;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 * 0.92;
    final p = starPath(c, r);
    if (fill != null) canvas.drawPath(p, Paint()..color = fill!);
    canvas.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color || old.fill != fill;
}

/// Number inside an eight-point star — surah/juz list leading element.
class StarMedallion extends StatelessWidget {
  const StarMedallion({super.key, required this.number, this.size = 44, this.active = false});
  final int number;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _StarPainter(active ? c.primary : c.gold.withValues(alpha: 0.7), active ? c.primarySoft : null),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              fontFamily: kUiFont,
              fontSize: size * (number > 99 ? 0.27 : 0.31),
              fontWeight: FontWeight.w600,
              color: active ? c.primary : c.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle geometric girih-style background (only on Home/player, never on the page).
class GirihPattern extends StatelessWidget {
  const GirihPattern({super.key, required this.color, this.cell = 46, this.opacity = 0.07});
  final Color color;
  final double cell, opacity;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GirihPainter(color.withValues(alpha: opacity), cell), size: Size.infinite);
}

class _GirihPainter extends CustomPainter {
  _GirihPainter(this.color, this.cell);
  final Color color;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var y = -cell / 2; y < size.height + cell; y += cell) {
      for (var x = -cell / 2; x < size.width + cell; x += cell) {
        canvas.drawPath(starPath(Offset(x, y), cell * 0.42), paint);
        canvas.drawCircle(Offset(x + cell / 2, y + cell / 2), cell * 0.08, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GirihPainter old) => old.color != color || old.cell != cell;
}

/// Deterministic, respectful generated art for reciters (no photos needed).
class ReciterAvatar extends StatelessWidget {
  const ReciterAvatar({super.key, required this.id, required this.nameAr, this.size = 52});
  final int id;
  final String nameAr;
  final double size;

  static const _hues = [160.0, 172.0, 190.0, 205.0, 28.0, 38.0, 145.0, 220.0, 12.0, 265.0];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hue = _hues[id % _hues.length];
    final base = HSLColor.fromAHSL(1, hue, 0.38, c.isDark ? 0.26 : 0.36).toColor();
    final light = HSLColor.fromAHSL(1, (hue + 18) % 360, 0.42, c.isDark ? 0.34 : 0.48).toColor();
    final letter = nameAr.replaceAll(RegExp(r'^(الشيخ|الشيخ|ال)\s*'), '').trim();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [light, base], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Transform.rotate(
            angle: (id % 8) * math.pi / 16,
            child: GirihPattern(color: Colors.white, cell: size / 2.2, opacity: 0.16),
          ),
          Center(
            child: Text(
              letter.isEmpty ? '' : letter.substring(0, 1),
              style: TextStyle(
                fontFamily: kUiFont,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.95),
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated download state button: idle → queued → progress ring → done / error.
class DownloadIndicator extends StatelessWidget {
  const DownloadIndicator({
    super.key,
    required this.downloaded,
    required this.active,
    required this.onDownload,
    this.onCancel,
    this.onDelete,
    this.size = 36,
  });

  final bool downloaded;
  final ActiveDownload? active;
  final VoidCallback onDownload;
  final VoidCallback? onCancel, onDelete;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Widget child;
    final String tooltip;
    VoidCallback? onTap;
    if (downloaded) {
      tooltip = 'Downloaded';
      onTap = onDelete;
      child = Icon(Icons.check_circle_rounded, key: const ValueKey('done'), color: c.primary, size: size * 0.66);
    } else if (active != null) {
      final a = active!;
      onTap = a.status == DlStatus.failed ? onDownload : onCancel;
      tooltip = switch (a.status) {
        DlStatus.failed => 'Retry',
        DlStatus.paused => 'Paused',
        DlStatus.queued => 'Queued',
        DlStatus.running => 'Downloading',
      };
      child = a.status == DlStatus.failed
          ? Icon(Icons.error_outline_rounded, key: const ValueKey('err'), color: c.danger, size: size * 0.62)
          : SizedBox.square(
              key: const ValueKey('prog'),
              dimension: size * 0.6,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: a.status == DlStatus.queued ? null : a.progress.clamp(0.02, 1.0),
                  strokeWidth: 2.4,
                  color: c.primary,
                  backgroundColor: c.divider,
                ),
                Icon(Icons.stop_rounded, size: size * 0.3, color: c.primary),
              ]),
            );
    } else {
      tooltip = 'Download';
      onTap = onDownload;
      child = Icon(Icons.download_rounded, key: const ValueKey('idle'), color: c.inkMuted, size: size * 0.62);
    }
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: size * 0.7,
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: AnimatedSwitcher(
              duration: Motion.quick,
              transitionBuilder: (w, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: w)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xxl, Space.gutter, Space.md),
        child: Row(children: [
          Expanded(child: Text(text, style: context.text.titleLarge)),
          if (trailing != null) trailing!,
        ]),
      );
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color, this.icon});
  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = color ?? c.inkMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: fg.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 3)],
        Text(label.toUpperCase(), style: context.text.labelSmall?.copyWith(color: fg, fontSize: 10)),
      ]),
    );
  }
}

String formatBytes(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}

String formatDuration(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 3)));
}

/// Title of a collapsing tab header: one line, shrinks instead of wrapping
/// (narrow screens, large system fonts).
class TabTitle extends StatelessWidget {
  const TabTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(text, maxLines: 1, style: Theme.of(context).textTheme.headlineSmall),
      );
}
