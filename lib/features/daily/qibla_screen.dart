import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import 'prayer_widgets.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  StreamSubscription<CompassEvent>? _sub;
  double? _heading;
  bool _noSensor = false, _aligned = false;

  @override
  void initState() {
    super.initState();
    final events = FlutterCompass.events;
    if (events == null) {
      _noSensor = true;
    } else {
      _sub = events.listen((e) {
        if (!mounted) return;
        if (e.heading == null) {
          setState(() => _noSensor = true);
          return;
        }
        setState(() => _heading = e.heading);
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _chooseLocation() => showLocationSheet(
        context,
        onGps: () async {
          await ref.read(prayerServiceProvider).locateQibla();
          if (mounted) setState(() {});
        },
        onCity: (city) async {
          await ref.read(prayerServiceProvider).setQiblaPlace(city);
          if (mounted) setState(() {});
        },
      );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final service = ref.read(prayerServiceProvider);
    final qibla = service.qiblaBearing();
    final place = service.qiblaPlace?.name;

    if (qibla == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Qibla · القبلة')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.gutter),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.explore_outlined, size: 56, color: c.primary),
              const SizedBox(height: Space.lg),
              Text('Where are you?', style: context.text.titleMedium),
              const SizedBox(height: Space.sm),
              Text('The Qibla direction depends on where you are. Your location stays on your phone.',
                  textAlign: TextAlign.center, style: context.text.bodySmall),
              const SizedBox(height: Space.lg),
              FilledButton.icon(
                onPressed: _chooseLocation,
                icon: const Icon(Icons.my_location_rounded),
                label: const Text('Set my location'),
              ),
            ]),
          ),
        ),
      );
    }

    final heading = _heading ?? 0;
    final diff = ((qibla - heading + 540) % 360) - 180; // -180..180
    final aligned = !_noSensor && _heading != null && diff.abs() < 3;
    if (aligned && !_aligned) HapticFeedback.mediumImpact();
    _aligned = aligned;

    return Scaffold(
      appBar: AppBar(title: const Text('Qibla · القبلة'), actions: [
        IconButton(tooltip: 'Change location', icon: const Icon(Icons.edit_location_alt_outlined), onPressed: _chooseLocation),
      ]),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.gutter),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.place_outlined, size: 16, color: c.inkMuted),
              const SizedBox(width: 4),
              Flexible(child: Text(place ?? 'My location', style: context.text.bodySmall, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: Space.sm),
            AnimatedSwitcher(
              duration: Motion.quick,
              child: Text(
                _noSensor
                    ? 'Qibla is ${qibla.toStringAsFixed(0)}° from North'
                    : aligned
                        ? 'You are facing the Qibla'
                        : 'Turn ${diff > 0 ? 'right' : 'left'} ${diff.abs().toStringAsFixed(0)}°',
                key: ValueKey('$aligned${diff.round()}'),
                style: context.text.headlineSmall?.copyWith(color: aligned ? c.primary : c.ink),
              ),
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(builder: (context, box) {
                  final size = math.min(box.maxWidth, box.maxHeight) * 0.9;
                  return Stack(alignment: Alignment.center, children: [
                    // Dial rotates against the phone heading so North stays north.
                    AnimatedRotation(
                      turns: -heading / 360,
                      duration: const Duration(milliseconds: 250),
                      child: SizedBox.square(
                        dimension: size,
                        child: CustomPaint(
                          painter: _DialPainter(
                            qibla: qibla,
                            ink: c.ink,
                            muted: c.inkFaint,
                            accent: aligned ? c.primary : c.gold,
                            face: c.surface,
                            ring: aligned ? c.primary : c.divider,
                          ),
                        ),
                      ),
                    ),
                    // Fixed marker: where the top of the phone points.
                    Positioned(
                      top: (box.maxHeight - size) / 2 - 6,
                      child: Icon(Icons.arrow_drop_down_rounded, size: 40, color: aligned ? c.primary : c.ink),
                    ),
                  ]);
                }),
              ),
            ),
            Text(
              _noSensor
                  ? 'This phone has no compass sensor. Use the angle above with a physical compass.'
                  : 'Hold your phone flat. If it seems off, move it in a figure-8 to calibrate.',
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ]),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.qibla,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.face,
    required this.ring,
  });

  final double qibla;
  final Color ink, muted, accent, face, ring;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(center, r, Paint()..color = face);
    canvas.drawCircle(
        center,
        r - 2,
        Paint()
          ..color = ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    for (var deg = 0; deg < 360; deg += 5) {
      final a = (deg - 90) * math.pi / 180;
      final major = deg % 30 == 0;
      final p1 = center + Offset(math.cos(a), math.sin(a)) * (r - 10);
      final p2 = center + Offset(math.cos(a), math.sin(a)) * (r - (major ? 24 : 16));
      canvas.drawLine(p1, p2, Paint()
        ..color = major ? ink : muted
        ..strokeWidth = major ? 2 : 1);
    }
    for (final (label, deg) in [('N', 0), ('E', 90), ('S', 180), ('W', 270)]) {
      final a = (deg - 90) * math.pi / 180;
      final tp = TextPainter(
        text: TextSpan(
            text: label,
            style: TextStyle(color: label == 'N' ? accent : ink, fontSize: 18, fontWeight: FontWeight.w700)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center + Offset(math.cos(a), math.sin(a)) * (r - 44) - Offset(tp.width / 2, tp.height / 2));
    }
    // Qibla needle with a Kaaba marker at its tip.
    final qa = (qibla - 90) * math.pi / 180;
    final dir = Offset(math.cos(qa), math.sin(qa));
    canvas.drawLine(center, center + dir * (r - 70), Paint()
      ..color = accent
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round);
    final tip = center + dir * (r - 70);
    final kaaba = Rect.fromCenter(center: tip, width: 30, height: 30);
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(qa + math.pi / 2);
    canvas.translate(-tip.dx, -tip.dy);
    canvas.drawRRect(RRect.fromRectAndRadius(kaaba, const Radius.circular(4)), Paint()..color = const Color(0xFF1B1B1B));
    canvas.drawRect(Rect.fromLTWH(kaaba.left, kaaba.top + 8, kaaba.width, 4), Paint()..color = const Color(0xFFD4B26A));
    canvas.restore();
    canvas.drawCircle(center, 8, Paint()..color = accent);
    canvas.drawPath(starPath(center, r * 0.18), Paint()
      ..color = muted
      ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.qibla != qibla || old.accent != accent || old.ring != ring;
}
