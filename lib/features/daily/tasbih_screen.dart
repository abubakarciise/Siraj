import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import '../../l10n/l10n.dart';

const _phrases = [
  'سُبْحَانَ اللَّهِ',
  'الْحَمْدُ لِلَّهِ',
  'اللَّهُ أَكْبَرُ',
  'لَا إِلَهَ إِلَّا اللَّهُ',
  'أَسْتَغْفِرُ اللَّهَ',
  'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
  'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
  'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
];

/// The name of dhikr [i] of [_phrases], in the app's language.
String _phraseName(AppLocalizations l10n, int i) => [
      l10n.tasbihSubhanallah,
      l10n.tasbihAlhamdulillah,
      l10n.tasbihAllahuAkbar,
      l10n.tasbihLaIlaha,
      l10n.tasbihAstaghfirullah,
      l10n.tasbihSubhanallahiWaBihamdih,
      l10n.tasbihLaHawla,
      l10n.tasbihSalawat,
    ][i];

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
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ar = _phrases[_phrase], en = _phraseName(context.l10n, _phrase);
    final lit = _count % _round == 0 && _count > 0 && !_endless ? _round : _count % _round;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tasbihTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.yourTasbih,
            icon: const Icon(Icons.insights_rounded),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TasbihStatsScreen(log: _log)));
              if (mounted) setState(() => _today = _log.onDay(DateTime.now()));
            },
          ),
          IconButton(tooltip: context.l10n.startAgain, icon: const Icon(Icons.restart_alt_rounded), onPressed: _reset),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _tap,
          // Swipe sideways anywhere for the next or previous dhikr.
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v.abs() > 250) _select(_phrase + (v < 0 ? 1 : -1));
          },
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final size = math.min(box.maxWidth - 32, box.maxHeight - 8);
                    return Center(
                      child: SizedBox.square(
                        dimension: size,
                        child: AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, _) => CustomPaint(
                            painter: _MisbahaPainter(
                              beads: _round,
                              lit: lit,
                              pulse: _pulse.value,
                              dark: c.isDark,
                              string: c.inkFaint,
                            ),
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(size * 0.2),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: Motion.quick,
                                      child: FittedBox(
                                        key: ValueKey(_phrase),
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          ar,
                                          textDirection: TextDirection.rtl,
                                          style: TextStyle(
                                            fontFamily: kNaskhFont,
                                            fontSize: 30,
                                            color: c.primary,
                                            height: 1.6,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$_count',
                                      style: TextStyle(
                                        fontSize: size * 0.2,
                                        fontWeight: FontWeight.w300,
                                        color: c.ink,
                                        height: 1.1,
                                      ),
                                    ),
                                    Text(_endless ? context.l10n.tapAnywhere : context.l10n.ofRound(_round), style: context.text.bodySmall),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // The dhikr: previous, its name and place, next.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                child: Row(
                  children: [
                    _Arrow(
                      icon: Icons.chevron_left_rounded,
                      tooltip: context.l10n.previousDhikr,
                      onTap: () => _select(_phrase - 1),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          AnimatedSwitcher(
                            duration: Motion.quick,
                            child: Text(en, key: ValueKey(_phrase), style: context.text.titleMedium, maxLines: 1),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < _phrases.length; i++)
                                AnimatedContainer(
                                  duration: Motion.quick,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: i == _phrase ? 16 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: i == _phrase ? c.primary : c.divider,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _Arrow(icon: Icons.chevron_right_rounded, tooltip: context.l10n.nextDhikr, onTap: () => _select(_phrase + 1)),
                  ],
                ),
              ),
              const SizedBox(height: Space.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: false, label: Text('33')),
                      ButtonSegment(value: true, label: Text('∞')),
                    ],
                    selected: {_endless},
                    onSelectionChanged: (v) => setState(() {
                      _endless = v.first;
                      _count = _rounds = 0;
                    }),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.lg),
                child: Row(
                  children: [
                    // Without a limit there are no rounds, only the count.
                    if (!_endless) ...[
                      _Stat(label: context.l10n.roundsOf33, value: '$_rounds'),
                      const SizedBox(width: Space.md),
                    ],
                    _Stat(label: context.l10n.today, value: '$_today'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      IconButton.filledTonal(tooltip: tooltip, onPressed: onTap, iconSize: 28, icon: Icon(icon));
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Space.md),
        decoration: BoxDecoration(
          color: c.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(Radii.lg),
          border: cardBorder(c),
            boxShadow: cardShadow(c),
        ),
        child: Column(
          children: [
            Text(value, style: context.text.titleLarge),
            Text(label, style: context.text.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Your tasbih over time: today, the week, the month, the streak, and which dhikr.
class TasbihStatsScreen extends StatelessWidget {
  const TasbihStatsScreen({super.key, required this.log});
  final TasbihLog log;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = c.gold;
    final data = log.read();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int sumDays(int n) =>
        List.generate(n, (i) => log.onDay(today.subtract(Duration(days: i)), data)).fold(0, (a, b) => a + b);
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

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.yourTasbih)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.xxl),
        children: [
          // Streak
          Container(
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: Color.lerp(c.surface, accent, 0.12),
              borderRadius: BorderRadius.circular(Radii.xl),
              border: Border.all(color: accent.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                Icon(Icons.local_fire_department_rounded, color: accent, size: 40),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.daysInARow(streak), style: context.text.titleLarge),
                      Text(
                        streak == 0 ? context.l10n.streakStart : context.l10n.streakKeepGoing,
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              _Stat(label: context.l10n.today, value: '${log.onDay(today, data)}'),
              const SizedBox(width: Space.sm),
              _Stat(label: context.l10n.sevenDays, value: '${sumDays(7)}'),
            ],
          ),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              _Stat(label: context.l10n.thirtyDays, value: '${sumDays(30)}'),
              const SizedBox(width: Space.sm),
              _Stat(label: context.l10n.allTime, value: '$all'),
            ],
          ),
          _StatsTitle(context.l10n.thisWeek),
          Container(
            height: 180,
            padding: const EdgeInsets.fromLTRB(Space.md, Space.lg, Space.md, Space.sm),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: cardBorder(c),
            boxShadow: cardShadow(c),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (weekCounts[i] > 0)
                          FittedBox(child: Text('${weekCounts[i]}', style: context.text.labelSmall)),
                        const SizedBox(height: 4),
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: weekCounts.fold(0, math.max) == 0
                                ? 0.02
                                : math.max(0.02, weekCounts[i] / weekCounts.fold(0, math.max)),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: i == 6 ? c.primary : c.primary.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.weekdayShort(week[i].weekday),
                          style: context.text.labelSmall?.copyWith(color: i == 6 ? c.primary : c.inkMuted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _StatsTitle(context.l10n.last30Days),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final m in month)
                Builder(
                  builder: (_) {
                    final n = log.onDay(m, data);
                    final k = n == 0 ? 0.0 : math.min(1.0, 0.25 + n / 400);
                    return Tooltip(
                      message: '${m.day}/${m.month}: $n',
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: n == 0 ? c.surfaceAlt : c.primary.withValues(alpha: k),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          _StatsTitle(context.l10n.dhikrThisMonth),
          if (best == 0)
            Text(context.l10n.nothingYetThisMonth, style: context.text.bodyMedium?.copyWith(color: c.inkMuted))
          else
            for (var i = 0; i < _phrases.length; i++)
              if (byPhrase[i] > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(_phraseName(context.l10n, i), style: context.text.bodyLarge)),
                          Text('${byPhrase[i]}', style: context.text.titleSmall?.copyWith(color: c.primary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: byPhrase[i] / best,
                          minHeight: 6,
                          color: c.primary,
                          backgroundColor: c.surfaceAlt,
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}

class _StatsTitle extends StatelessWidget {
  const _StatsTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Space.xl, bottom: Space.md),
    child: Text(text, style: context.text.titleMedium),
  );
}

/// A ring of beads, an imam bead and a tassel at the bottom. [lit] beads are
/// gold; the newest glows as [pulse] goes from 0 to 1.
class _MisbahaPainter extends CustomPainter {
  _MisbahaPainter({
    required this.beads,
    required this.lit,
    required this.pulse,
    required this.dark,
    required this.string,
  });
  final int beads, lit;
  final double pulse;
  final bool dark;
  final Color string;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.40;
    // The string.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = string.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
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
            : dark
            ? [const Color(0xFF3F7A68), const Color(0xFF1B4A3E), const Color(0xFF0C261F)]
            // Emerald beads on the ivory page, turning gold as they are counted.
            : [const Color(0xFF5FA58E), const Color(0xFF0F5C4A), const Color(0xFF083A2E)],
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
  bool shouldRepaint(_MisbahaPainter old) =>
      old.lit != lit || old.pulse != pulse || old.beads != beads || old.dark != dark || old.string != string;
}
