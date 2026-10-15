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
  ('لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ', 'La hawla wa la quwwata illa billah'),
  ('اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ', 'Salawat'),
];

class TasbihScreen extends ConsumerStatefulWidget {
  const TasbihScreen({super.key});

  @override
  ConsumerState<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends ConsumerState<TasbihScreen> with SingleTickerProviderStateMixin {
  int _phrase = 0, _count = 0, _rounds = 0, _target = 33;
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));

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

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (ar, en) = _phrases[_phrase];
    final progress = _target == 0 ? 0.0 : _count / _target;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasbih · التسبيح'),
        actions: [
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () => setState(() => _count = _rounds = 0),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              itemCount: _phrases.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(_phrases[i].$2),
                selected: i == _phrase,
                onSelected: (_) => setState(() {
                  _phrase = i;
                  _count = _rounds = 0;
                }),
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          Wrap(spacing: 8, children: [
            for (final t in [33, 99, 100, 0])
              ChoiceChip(
                label: Text(t == 0 ? '∞' : '$t'),
                selected: _target == t,
                onSelected: (_) => setState(() {
                  _target = t;
                  _count = _rounds = 0;
                }),
              ),
          ]),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _tap,
              child: Center(
                child: LayoutBuilder(builder: (context, box) {
                  final size = math.min(box.maxWidth, box.maxHeight) * 0.82;
                  return AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, child) =>
                        Transform.scale(scale: 1 - 0.03 * math.sin(_pulse.value * math.pi), child: child),
                    child: SizedBox.square(
                      dimension: size,
                      child: Stack(alignment: Alignment.center, children: [
                        SizedBox.expand(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(end: progress),
                            duration: Motion.quick,
                            builder: (_, v, _) => CircularProgressIndicator(
                              value: _target == 0 ? 1 : v,
                              strokeWidth: 10,
                              strokeCap: StrokeCap.round,
                              color: c.primary,
                              backgroundColor: c.primarySoft,
                            ),
                          ),
                        ),
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(ar,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: kNaskhFont, fontSize: 28, color: c.ink, height: 1.6)),
                          const SizedBox(height: Space.sm),
                          Text('$_count', style: context.text.displaySmall?.copyWith(fontSize: 64, height: 1.1)),
                          Text(_target == 0 ? 'Tap anywhere' : 'of $_target', style: context.text.bodySmall),
                        ]),
                      ]),
                    ),
                  );
                }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xl),
            child: Text('Rounds: $_rounds  ·  Today: $_todayTotal', style: context.text.bodyMedium),
          ),
        ]),
      ),
    );
  }
}
