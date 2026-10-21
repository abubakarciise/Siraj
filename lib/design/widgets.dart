import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/downloads/download_manager.dart';
import '../l10n/l10n.dart';
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

  // Within the logo's family only: emeralds and golds.
  static const _hues = [160.0, 38.0, 152.0, 166.0, 42.0, 156.0, 34.0, 162.0];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hue = _hues[id % _hues.length];
    final gold = hue < 90;
    final base = HSLColor.fromAHSL(1, hue, gold ? 0.42 : 0.55, c.isDark ? 0.26 : (gold ? 0.40 : 0.27)).toColor();
    final light = HSLColor.fromAHSL(1, hue, gold ? 0.45 : 0.45, c.isDark ? 0.34 : (gold ? 0.52 : 0.38)).toColor();
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
            child: GirihPattern(color: Colors.white, cell: size / 2.2, opacity: 0.09),
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
      tooltip = context.l10n.downloaded;
      onTap = onDelete;
      child = Icon(Icons.check_circle_rounded, key: const ValueKey('done'), color: c.primary, size: size * 0.66);
    } else if (active != null) {
      final a = active!;
      onTap = a.status == DlStatus.failed ? onDownload : onCancel;
      tooltip = switch (a.status) {
        DlStatus.failed => context.l10n.retry,
        DlStatus.paused => context.l10n.paused,
        DlStatus.queued => context.l10n.queued,
        DlStatus.running => context.l10n.downloading,
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
      tooltip = context.l10n.download;
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
        padding: EdgeInsets.fromLTRB(Space.gutter, Space.xxl + 4, trailing == null ? Space.gutter : Space.sm, Space.md),
        child: SizedBox(
          height: 32,
          child: Row(children: [
            Text(text, style: context.text.titleLarge?.copyWith(fontSize: 19)),
            const SizedBox(width: Space.md),
            // A gold rule fading out, as under a heading in a printed book.
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [context.colors.gold.withValues(alpha: 0.55), context.colors.gold.withValues(alpha: 0)]),
                ),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: Space.sm), trailing!],
          ]),
        ),
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

/// Cards: an ivory sheet edged with a fine gold hairline, lifted by a soft
/// warm shadow in light (shadows do not show in dark, the hairline does).
Border? cardBorder(AppColors c) => Border.all(color: c.divider);

List<BoxShadow>? cardShadow(AppColors c) => c.isDark
    ? null
    : const [BoxShadow(color: Color(0x148A6A2B), blurRadius: 20, offset: Offset(0, 8))];

BorderSide cardSide(AppColors c) => BorderSide(color: c.divider);

/// The app's card: an ivory sheet with a gold hairline and a soft warm shadow
/// (drawn outside the card, so it shows), a ripple when tapped, and optionally
/// an accent stripe down the leading edge.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(Space.lg),
    this.radius = 22,
    this.color,
    this.accent,
    this.width,
  });

  final Widget child;
  final VoidCallback? onTap, onLongPress;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// The card's fill, when not the ivory surface (e.g. [AppColors.emeraldTint]).
  final Color? color;

  /// A stripe down the leading edge.
  final Color? accent;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = BorderRadius.circular(radius);
    Widget body = Padding(padding: padding, child: child);
    if (accent != null) {
      body = Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(width: 3, color: accent),
        Expanded(child: body),
      ]);
      body = IntrinsicHeight(child: body);
    }
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: shape,
        border: cardBorder(c),
        boxShadow: cardShadow(c),
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(onTap: onTap, onLongPress: onLongPress, child: body),
        ),
      ),
    );
  }
}

/// An icon on an ivory tile edged in gold, like an illuminated initial.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, required this.color, this.size = 44});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = c.isDark ? Color.lerp(color, Colors.white, 0.35)! : color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color.lerp(c.surface, fg, c.isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(size * 0.31),
        border: Border.all(color: c.divider),
      ),
      child: Icon(icon, color: fg, size: size * 0.48),
    );
  }
}

/// The one rich surface of a screen: the logo's emerald, lighter at the top
/// left, with a single large, faint eight-point star rising from a corner.
/// Text on it uses [AppColors.onBrand]; gold marks labels and actions.
class BrandPanel extends StatelessWidget {
  const BrandPanel({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Space.xl),
    this.borderRadius = const BorderRadius.all(Radius.circular(Radii.xl)),
    this.ornament = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final bool ornament;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      color: c.brand,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: c.brandGradient),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              if (ornament)
                Positioned.fill(
                  child: IgnorePointer(child: CustomPaint(painter: _CornerStarPainter(c.goldOnBrand.withValues(alpha: 0.32)))),
                ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two nested eight-point stars and a ring, centred past the top-right
/// corner so only part of them shows.
class _CornerStarPainter extends CustomPainter {
  _CornerStarPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.shortestSide * 0.95, 190.0);
    final o = Offset(size.width - r * 0.28, r * 0.22);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(starPath(o, r), p);
    canvas.drawPath(starPath(o, r * 0.66), p);
    canvas.drawCircle(o, r * 0.80, p);
    canvas.drawCircle(o, r * 0.42, p);
  }

  @override
  bool shouldRepaint(_CornerStarPainter old) => old.color != color;
}


// ---------------------------------------------------------------------------
// Grouped settings (Settings, Reminders): a small gold header, then rows in
// one ivory card edged in gold, separated by hairlines.
// ---------------------------------------------------------------------------

/// A section's name above a group, small and in capitals.
class GroupHeader extends StatelessWidget {
  const GroupHeader(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.xs, Space.xl, Space.xs, Space.sm),
        child: Text(text.toUpperCase(), style: context.text.labelSmall?.copyWith(color: context.colors.goldText)),
      );
}

/// A rounded ivory card holding rows, separated by hairlines.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg), side: cardSide(c)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: 60, color: c.divider),
          children[i],
        ],
      ]),
    );
  }
}

/// A row in a group: an icon tile, a title, an optional line under it, and a
/// chevron (or [trailing]).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.sm, Space.md),
        child: Row(children: [
          IconBadge(icon, color: color, size: 36),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.text.titleMedium),
              if (value != null)
                Text(value!, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
            ]),
          ),
          trailing ?? Icon(Icons.chevron_right_rounded, color: c.inkFaint),
        ]),
      ),
    );
  }
}

/// A row in a group with a switch.
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.sm, Space.sm),
          child: Row(children: [
            IconBadge(icon, color: color, size: 36),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: context.text.titleMedium),
                if (subtitle != null) Text(subtitle!, style: context.text.bodySmall),
              ]),
            ),
            Switch(value: value, onChanged: onChanged),
          ]),
        ),
      );
}
