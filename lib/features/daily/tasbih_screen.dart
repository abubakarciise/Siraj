import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// A misbaha has 33 beads: one round.
const _round = 33;

/// Every count, by day and by dhikr: {"2026-10-17": {"0": 99, "4": 100}}.
class TasbihLog {
  TasbihLog(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'tasbih_log';

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, Map<String, int>> read() {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return {};
      return {
        for (final e in (jsonDecode(raw) as Map<String, dynamic>).entries)
          e.key: {for (final p in (e.value as Map<String, dynamic>).entries) p.key: p.value as int},
      };
    } catch (_) {
      return {};
    }
  }

  void add(int phrase, {DateTime? at}) {
    final log = read();
    final day = log.putIfAbsent(dayKey(at ?? DateTime.now()), () => {});
    day['$phrase'] = (day['$phrase'] ?? 0) + 1;
    _prefs.setString(_key, jsonEncode(log));
  }

  int onDay(DateTime d, [Map<String, Map<String, int>>? log]) =>
      ((log ?? read())[dayKey(d)]?.values ?? const <int>[]).fold(0, (a, b) => a + b);
}

/// A misbaha: a ring of beads that light up one by one. Tap anywhere to count;
/// swipe sideways (or use the arrows) for another dhikr.
class TasbihScreen extends ConsumerStatefulWidget {
  const TasbihScreen({super.key});

  @override
  ConsumerState<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends ConsumerState<TasbihScreen> with SingleTickerProviderStateMixin {
  int _phrase = 0, _count = 0, _rounds = 0;
  bool _endless = false; // false: rounds of 33; true: ∞, counting on
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  late final _log = TasbihLog(ref.read(prefsProvider));
  final _chipKeys = List.generate(_phrases.length, (_) => GlobalKey());
  late int _today = _log.onDay(DateTime.now());

  void _tap() {
    setState(() {
      _count++;
      _today++;
      if (_count % _round == 0) {
        _rounds++;
        if (!_endless) _count = 0;
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    });
    _log.add(_phrase);
    _pulse.forward(from: 0);
  }

  void _reset() => setState(() => _count = _rounds = 0);

  void _select(int i) {
    final next = (i + _phrases.length) % _phrases.length;
    if (next == _phrase) return;
    HapticFeedback.selectionClick();
    setState(() {
      _phrase = next;
      _count = _rounds = 0;
    });
    // Keep the chosen dhikr in view in the row at the top.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _chipKeys[next].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, alignment: 0.5, duration: Motion.standard, curve: Motion.curve);
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (ar, _) = _phrases[_phrase];
    final lit = _count % _round == 0 && _count > 0 && !_endless ? _round : _count % _round;
    return Scaffold(
      backgroundColor: _nightDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Tasbih · التسبيح',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            tooltip: 'Your tasbih',
            icon: const Icon(Icons.insights_rounded),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TasbihStatsScreen(log: _log)));
              if (mounted) setState(() => _today = _log.onDay(DateTime.now()));
            },
          ),
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                child: Row(children: [
                  for (var i = 0; i < _phrases.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _Chip(key: _chipKeys[i], label: _phrases[i].$2, selected: i == _phrase, onTap: () => _select(i)),
                  ],
                ]),
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _tap,
                // Swipe sideways for the next or previous dhikr.
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v.abs() > 250) _select(_phrase + (v < 0 ? 1 : -1));
                },
                child: LayoutBuilder(builder: (context, box) {
                  final size = math.min(box.maxWidth - 32, box.maxHeight - 24);
                  return Center(
                    child: SizedBox.square(
                      dimension: size,
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (_, _) => CustomPaint(
                          painter: _MisbahaPainter(beads: _round, lit: lit, pulse: _pulse.value),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(size * 0.17),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                Row(children: [
                                  _Arrow(icon: Icons.chevron_left_rounded, onTap: () => _select(_phrase - 1)),
                                  Expanded(
                                    child: AnimatedSwitcher(
                                      duration: Motion.quick,
                                      child: FittedBox(
                                        key: ValueKey(_phrase),
                                        fit: BoxFit.scaleDown,
                                        child: Text(ar,
                                            textDirection: TextDirection.rtl,
                                            style: const TextStyle(
                                                fontFamily: kNaskhFont, fontSize: 30, color: _gold, height: 1.6)),
                                      ),
                                    ),
                                  ),
                                  _Arrow(icon: Icons.chevron_right_rounded, onTap: () => _select(_phrase + 1)),
                                ]),
                                Text('$_count',
                                    style: TextStyle(
                                        fontSize: size * 0.2,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white,
                                        height: 1.1)),
                                Text(_endless ? 'Tap anywhere' : 'of $_round',
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
                Expanded(
                  child: _Chip(
                    label: '33',
                    selected: !_endless,
                    onTap: () => setState(() {
                      _endless = false;
                      _count = _rounds = 0;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Chip(
                    label: '∞',
                    selected: _endless,
                    onTap: () => setState(() {
                      _endless = true;
                      _count = _rounds = 0;
                    }),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, Space.xl),
              child: Row(children: [
                _Stat(label: 'Rounds of 33', value: '$_rounds'),
                const SizedBox(width: Space.md),
                _Stat(label: 'Today', value: '$_today'),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, color: Colors.white54, size: 28),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.label, required this.selected, required this.onTap});
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

/// Your tasbih over time: today, the week, the month, the streak, and which dhikr.
class TasbihStatsScreen extends StatelessWidget {
  const TasbihStatsScreen({super.key, required this.log});
  final TasbihLog log;

  @override
  Widget build(BuildContext context) {
    final data = log.read();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int sumDays(int n) => List.generate(n, (i) => log.onDay(today.subtract(Duration(days: i)), data)).fold(0, (a, b) => a + b);
    final all = data.values.expand((d) => d.values).fold(0, (a, b) => a + b);
    // Streak: days in a row with tasbih, up to today (or yesterday, if not yet today).
    var streak = 0;
    var d = log.onDay(today, data) > 0 ? today : today.subtract(const Duration(days: 1));
    while (log.onDay(d, data) > 0) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    final week = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final weekCounts = [for (final w in week) log.onDay(w, data)];
    final month = List.generate(30, (i) => today.subtract(Duration(days: 29 - i)));
    final byPhrase = List.filled(_phrases.length, 0);
    for (final m in month) {
      for (final e in (data[TasbihLog.dayKey(m)] ?? const <String, int>{}).entries) {
        final k = int.tryParse(e.key);
        if (k != null && k < byPhrase.length) byPhrase[k] += e.value;
      }
    }
    final best = byPhrase.fold(0, math.max);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      backgroundColor: _nightDeep,
      appBar: AppBar(
        backgroundColor: _nightDeep,
        foregroundColor: Colors.white,
        title: const Text('Your tasbih', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.xxl), children: [
        // Streak
        Container(
          padding: const EdgeInsets.all(Space.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF2A2210), Color(0xFF14110A)]),
            borderRadius: BorderRadius.circular(Radii.xl),
            border: Border.all(color: _gold.withValues(alpha: 0.35)),
          ),
          child: Row(children: [
            const Icon(Icons.local_fire_department_rounded, color: _gold, size: 40),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(streak == 1 ? '1 day in a row' : '$streak days in a row',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                Text(streak == 0 ? 'Start today: a few taps are enough' : 'Keep it going, a little every day',
                    style: const TextStyle(color: Colors.white60)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: Space.md),
        Row(children: [
          _Stat(label: 'Today', value: '${log.onDay(today, data)}'),
          const SizedBox(width: Space.sm),
          _Stat(label: '7 days', value: '${sumDays(7)}'),
        ]),
        const SizedBox(height: Space.sm),
        Row(children: [
          _Stat(label: '30 days', value: '${sumDays(30)}'),
          const SizedBox(width: Space.sm),
          _Stat(label: 'All time', value: '$all'),
        ]),
        const _StatsTitle('This week'),
        Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(Space.md, Space.lg, Space.md, Space.sm),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (weekCounts[i] > 0)
                    FittedBox(
                      child: Text('${weekCounts[i]}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: weekCounts.fold(0, math.max) == 0
                          ? 0.02
                          : math.max(0.02, weekCounts[i] / weekCounts.fold(0, math.max)),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: i == 6 ? _gold : _gold.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(days[week[i].weekday - 1],
                      style: TextStyle(color: i == 6 ? _gold : Colors.white60, fontSize: 12)),
                ]),
              ),
          ]),
        ),
        const _StatsTitle('Last 30 days'),
        Wrap(spacing: 5, runSpacing: 5, children: [
          for (final m in month)
            Builder(builder: (_) {
              final n = log.onDay(m, data);
              final k = n == 0 ? 0.0 : math.min(1.0, 0.25 + n / 400);
              return Tooltip(
                message: '${m.day}/${m.month}: $n',
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: n == 0 ? Colors.white.withValues(alpha: 0.06) : _gold.withValues(alpha: k),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            }),
        ]),
        const _StatsTitle('Dhikr this month'),
        if (best == 0)
          const Text('Nothing yet this month.', style: TextStyle(color: Colors.white60))
        else
          for (var i = 0; i < _phrases.length; i++)
            if (byPhrase[i] > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.md),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(child: Text(_phrases[i].$2, style: const TextStyle(color: Colors.white))),
                    Text('${byPhrase[i]}', style: const TextStyle(color: _gold, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: byPhrase[i] / best,
                      minHeight: 6,
                      color: _gold,
                      backgroundColor: Colors.white10,
                    ),
                  ),
                ]),
              ),
      ]),
    );
  }
}

class _StatsTitle extends StatelessWidget {
  const _StatsTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Space.xl, bottom: Space.md),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
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
