import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';

const _phrases = [
  ('سُبْحَانَ اللَّهِ', 'SubhanAllah'),
  ('الْحَمْدُ لِلَّهِ', 'Alhamdulillah'),
  ('اللَّهُ أَكْبَرُ', 'Allahu Akbar'),
  ('لَا إِلَهَ إِلَّا اللَّهُ', 'La ilaha illa Allah'),
  ('أَسْتَغْفِرُ اللَّهَ', 'Astaghfirullah'),
  ('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ', 'SubhanAllahi wa bihamdih'),
  ('لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ', 'La hawla wa la quwwata'),
  ('اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ', 'Salawat'),
];

const _night = Color(0xFF0E1B33);
const _nightDeep = Color(0xFF060C1A);
const _gold = Color(0xFFE2BC6E);

/// A misbaha: a ring of beads that light up one by one. Tap anywhere to count.
class TasbihScreen extends ConsumerStatefulWidget {
  const TasbihScreen({super.key});

  @override
  ConsumerState<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends ConsumerState<TasbihScreen> with SingleTickerProviderStateMixin {
  int _phrase = 0, _count = 0, _rounds = 0, _target = 33;
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));

  String get _todayKey {
    final d = DateTime.now();
    return 'tasbih_total_${d.year}-${d.month}-${d.day}';
  }

  int get _todayTotal => ref.read(prefsProvider).getInt(_todayKey) ?? 0;

  void _tap() {
    setState(() {
      _count++;
      if (_target > 0 && _count >= _target) {
        _count = 0;
        _rounds++;
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    });
    ref.read(prefsProvider).setInt(_todayKey, _todayTotal + 1);
    _pulse.forward(from: 0);
  }

  void _reset() => setState(() => _count = _rounds = 0);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (ar, en) = _phrases[_phrase];
    // A misbaha has 33 beads; with 99 or 100 the ring goes round three times.
    final beads = _target == 0 ? 33 : (_target <= 33 ? _target : 33);
    final lit = _target == 0 ? _count % 33 : (_count % beads);
    return Scaffold(
      backgroundColor: _nightDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Tasbih · التسبيح', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(tooltip: 'Start again', icon: const Icon(Icons.restart_alt_rounded), onPressed: _reset),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.2), radius: 1.1, colors: [_night, _nightDeep]),
        ),
        child: SafeArea(
          child: Column(children: [
            const SizedBox(height: Space.sm),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                itemCount: _phrases.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _Chip(
                  label: _phrases[i].$2,
                  selected: i == _phrase,
                  onTap: () => setState(() {
                    _phrase = i;
                    _count = _rounds = 0;
                  }),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _tap,
                child: LayoutBuilder(builder: (context, box) {
                  final size = math.min(box.maxWidth - 32, box.maxHeight - 24);
                  return Center(
                    child: SizedBox.square(
                      dimension: size,
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, _) => CustomPaint(
                          painter: _MisbahaPainter(beads: beads, lit: lit, pulse: _pulse.value),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(size * 0.2),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(ar,
                                      textDirection: TextDirection.rtl,
                                      style: const TextStyle(
                                          fontFamily: kNaskhFont, fontSize: 30, color: _gold, height: 1.6)),
                                ),
                                Text('$_count',
                                    style: TextStyle(
                                        fontSize: size * 0.2,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white,
                                        height: 1.1)),
                                Text(_target == 0 ? 'Tap anywhere' : 'of $_target',
                                    style: const TextStyle(color: Colors.white60, fontSize: 14)),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: Row(children: [
                for (final t in [33, 99, 100, 0]) ...[
                  Expanded(
                    child: _Chip(
                      label: t == 0 ? '∞' : '$t',
                      selected: _target == t,
                      onTap: () => setState(() {
                        _target = t;
                        _count = _rounds = 0;
                      }),
                    ),
                  ),
                  if (t != 0) const SizedBox(width: 8),
                ],
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, Space.xl),
              child: Row(children: [
                _Stat(label: 'Rounds', value: '$_rounds'),
                const SizedBox(width: Space.md),
                _Stat(label: 'Today', value: '$_todayTotal'),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? _gold : Colors.white.withValues(alpha: 0.07),
        shape: StadiumBorder(side: BorderSide(color: selected ? _gold : Colors.white24)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Center(
              widthFactor: 1,
              child: Text(label,
                  style: TextStyle(
                      color: selected ? _nightDeep : Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Space.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ]),
        ),
      );
}

/// A ring of beads, an imam bead and a tassel at the bottom. [lit] beads are
/// gold; the newest glows as [pulse] goes from 0 to 1.
class _MisbahaPainter extends CustomPainter {
  _MisbahaPainter({required this.beads, required this.lit, required this.pulse});
  final int beads, lit;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.40;
    // The string.
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    // Leave a gap at the bottom for the imam bead.
    const gap = 0.55; // radians
    final step = (2 * math.pi - gap) / math.max(1, beads - 1);
    final beadR = math.min(size.width * 0.032, (r * step) / 2.3);
    for (var i = 0; i < beads; i++) {
      // Bead 0 at the bottom-left of the gap, going clockwise up and around.
      final a = math.pi / 2 + gap / 2 + i * step;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      final on = i < lit;
      final newest = i == lit - 1;
      if (newest && pulse < 1) {
        canvas.drawCircle(p, beadR * (1.8 + pulse), Paint()..color = _gold.withValues(alpha: 0.25 * (1 - pulse)));
      }
      final shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        colors: on
            ? [const Color(0xFFFFF0C8), _gold, const Color(0xFF9A7230)]
            : [const Color(0xFF4A5A7C), const Color(0xFF26324D), const Color(0xFF151D30)],
        stops: const [0, 0.55, 1],
      ).createShader(Rect.fromCircle(center: p, radius: beadR));
      canvas.drawCircle(p, beadR * (newest ? 1 + 0.15 * (1 - pulse) : 1), Paint()..shader = shader);
    }
    // Imam bead and tassel.
    final top = c + Offset(0, r);
    final imam = top + Offset(0, beadR * 1.6);
    canvas.drawCircle(
      imam,
      beadR * 1.35,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFFFF0C8), _gold, Color(0xFF8A6428)],
        ).createShader(Rect.fromCircle(center: imam, radius: beadR * 1.35)),
    );
    final tassel = Paint()
      ..color = _gold.withValues(alpha: 0.85)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var k = -3; k <= 3; k++) {
      final from = imam + Offset(0, beadR * 1.3);
      canvas.drawLine(from, from + Offset(k * beadR * 0.28, beadR * 3.2), tassel);
    }
  }

  @override
  bool shouldRepaint(_MisbahaPainter old) => old.lit != lit || old.pulse != pulse || old.beads != beads;
}
