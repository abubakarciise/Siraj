import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/adhkar/adhkar.dart';
import '../../core/adhkar/adhkar_player.dart';
import '../../core/providers.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';

const adhkarIcons = {
  'morning': Icons.wb_twilight_rounded,
  'evening': Icons.nights_stay_outlined,
  'after_salah': Icons.mosque_outlined,
  'sleep': Icons.bedtime_outlined,
  'waking': Icons.wb_sunny_outlined,
  'tasbih': Icons.blur_circular_rounded,
  'quran_duas': Icons.menu_book_rounded,
  'prophets_duas': Icons.auto_awesome_outlined,
};

String _today() {
  final d = DateTime.now();
  return '${d.year}-${d.month}-${d.day}';
}

bool adhkarDoneToday(WidgetRef ref, String id) => ref.read(prefsProvider).getString('adhkar_done_$id') == _today();

class AdhkarListScreen extends ConsumerWidget {
  const AdhkarListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final cats = ref.watch(adhkarProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Adhkar · الأذكار')),
      body: cats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.xxxl),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: Space.md),
          itemBuilder: (_, i) {
            final cat = list[i];
            final done = adhkarDoneToday(ref, cat.id);
            return Material(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.lg),
              child: InkWell(
                borderRadius: BorderRadius.circular(Radii.lg),
                onTap: () => context.push('/adhkar/${cat.id}'),
                child: Container(
                  padding: const EdgeInsets.all(Space.lg),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Radii.lg), border: Border.all(color: c.divider)),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(Radii.md)),
                      child: Icon(adhkarIcons[cat.id] ?? Icons.favorite_border, color: c.primary),
                    ),
                    const SizedBox(width: Space.lg),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(cat.titleEn, style: context.text.titleMedium),
                        Text('${cat.titleAr} · ${cat.items.length} adhkar', style: context.text.bodySmall),
                      ]),
                    ),
                    if (done) Icon(Icons.check_circle_rounded, color: c.primary),
                    Icon(Icons.chevron_right_rounded, color: c.inkMuted),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Read adhkar one card at a time: tap a card to count, it advances when done.
class AdhkarScreen extends ConsumerStatefulWidget {
  const AdhkarScreen({super.key, required this.categoryId, this.autoListen = false});
  final String categoryId;

  /// Start listening as soon as the adhkar are loaded (the Listen button on Home).
  final bool autoListen;

  @override
  ConsumerState<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends ConsumerState<AdhkarScreen> {
  final _remaining = <int, int>{};
  final _keys = <int, GlobalKey>{};
  bool _celebrated = false;
  late final AdhkarPlayer _audio = ref.read(adhkarPlayerProvider);
  int? _followed;
  late bool _autoListen = widget.autoListen;

  int _left(AdhkarCategory cat, int i) => _remaining[i] ?? cat.items[i].count;

  bool get _listening => _audio.category?.id == widget.categoryId;

  @override
  void initState() {
    super.initState();
    _audio.addListener(_onAudio);
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudio);
    // Adhkar are listened to on this screen; leaving it ends the session.
    if (_listening) _audio.stop();
    super.dispose();
  }

  void _onAudio() {
    if (!mounted) return;
    setState(() {});
    if (_listening && _audio.index != _followed) {
      _followed = _audio.index;
      _scrollTo(_audio.index);
    }
  }

  void _scrollTo(int i) {
    final ctx = _keys[i]?.currentContext;
    if (ctx != null && ctx.mounted) {
      Scrollable.ensureVisible(ctx, duration: Motion.gentle, curve: Motion.emphasized, alignment: 0.08);
    }
  }

  void _listen(AdhkarCategory cat) {
    var from = List.generate(cat.items.length, (i) => i).firstWhere((i) => _left(cat, i) > 0, orElse: () => -1);
    if (from < 0) {
      // Everything was already counted: listen again from the start.
      setState(() {
        _remaining.clear();
        _celebrated = false;
      });
      from = 0;
    }
    _followed = null;
    _audio
      ..onRepetition = (i) {
        final left = _left(cat, i);
        if (left == 0 || !mounted) return;
        setState(() => _remaining[i] = left - 1);
        if (left - 1 == 0) _checkComplete(cat);
      }
      ..onError = (e) {
        if (mounted) showToast(context, '$e');
      };
    _audio.start(cat, from, remaining: (i) => _left(cat, i));
  }

  void _tap(AdhkarCategory cat, int i) {
    // While listening, a tap on another card plays that card; a tap on the
    // card being recited counts it, and listening carries on from there.
    if (_listening && _audio.playing && i != _audio.index) {
      HapticFeedback.selectionClick();
      _audio.jumpTo(i);
      return;
    }
    final left = _left(cat, i);
    if (left == 0) return;
    setState(() => _remaining[i] = left - 1);
    if (_listening && _audio.playing) _audio.counted();
    if (left - 1 == 0) {
      HapticFeedback.mediumImpact();
      final next = i + 1;
      if (next < cat.items.length && !_listening) {
        Future.delayed(const Duration(milliseconds: 280), () => _scrollTo(next));
      }
      _checkComplete(cat);
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _checkComplete(AdhkarCategory cat) {
    final all = List.generate(cat.items.length, (i) => _left(cat, i)).every((n) => n == 0);
    if (all && !_celebrated) {
      _celebrated = true;
      ref.read(prefsProvider).setString('adhkar_done_${cat.id}', _today());
      HapticFeedback.heavyImpact();
      showToast(context, 'Completed · تقبّل الله منا ومنكم');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final async = ref.watch(adhkarProvider);
    if (async.hasError) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Could not load adhkar\n${async.error}', textAlign: TextAlign.center)),
      );
    }
    final cat = async.value?.where((x) => x.id == widget.categoryId).firstOrNull;
    if (cat == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_autoListen) {
      _autoListen = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _listen(cat);
      });
    }
    final total = cat.totalCount;
    final done = total - List.generate(cat.items.length, (i) => _left(cat, i)).fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cat.titleEn, style: context.text.titleMedium),
          Text(cat.titleAr, style: context.text.bodySmall),
        ]),
        actions: [
          IconButton(
            tooltip: 'Start again',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () => setState(() {
              _remaining.clear();
              _celebrated = false;
            }),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: total == 0 ? 0 : done / total),
            duration: Motion.standard,
            builder: (_, v, _) =>
                LinearProgressIndicator(value: v, minHeight: 4, color: c.primary, backgroundColor: c.divider),
          ),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.fromLTRB(
            Space.gutter, Space.lg, Space.gutter, Space.xxxl + MediaQuery.paddingOf(context).bottom),
        itemCount: cat.items.length + 1,
        itemBuilder: (_, k) {
          if (k == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: Space.lg),
              child: AnimatedSwitcher(
                duration: Motion.quick,
                child: _listening ? const SizedBox(width: double.infinity) : _ListenCard(onTap: () => _listen(cat)),
              ),
            );
          }
          final i = k - 1;
          return Padding(
            key: _keys.putIfAbsent(i, GlobalKey.new),
            padding: const EdgeInsets.only(bottom: Space.md),
            child: _DhikrCard(
              dhikr: cat.items[i],
              index: i,
              left: _left(cat, i),
              active: _listening && _audio.index == i,
              onTap: () => _tap(cat, i),
            ),
          );
        },
      ),
      bottomNavigationBar: _listening ? _ListenBar(audio: _audio, category: cat) : null,
    );
  }
}

class _DhikrCard extends StatelessWidget {
  const _DhikrCard({
    required this.dhikr,
    required this.index,
    required this.left,
    required this.onTap,
    this.active = false,
  });
  final Dhikr dhikr;
  final int index, left;
  final VoidCallback onTap;

  /// Being recited right now.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final finished = left == 0;
    return AnimatedOpacity(
      duration: Motion.standard,
      opacity: finished && !active ? 0.55 : 1,
      child: Material(
        color: finished ? c.surfaceAlt : c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(Space.xl),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(
                color: active ? c.primary : (finished ? Colors.transparent : c.divider),
                width: active ? 2 : 1,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                StarMedallion(number: index + 1, size: 34),
                if (active) ...[
                  const SizedBox(width: Space.sm),
                  Icon(Icons.graphic_eq_rounded, size: 20, color: c.primary),
                ],
                const Spacer(),
                if (dhikr.quranRef != null) Pill('Quran ${dhikr.quranRef}', color: c.gold),
              ]),
              const SizedBox(height: Space.md),
              Text(
                dhikr.text,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: dhikr.quranRef != null
                    ? TextStyle(fontFamily: kQuranFont, fontSize: 23, height: 2.0, color: c.ink)
                    : TextStyle(fontFamily: kNaskhFont, fontSize: 24, height: 2.0, color: c.ink),
              ),
              if (dhikr.virtue.isNotEmpty) ...[
                const SizedBox(height: Space.md),
                Text(
                  dhikr.virtue,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall?.copyWith(height: 1.6),
                ),
              ],
              const SizedBox(height: Space.lg),
              Center(
                child: AnimatedContainer(
                  duration: Motion.quick,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: finished ? c.primary : c.primarySoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(finished ? Icons.check_rounded : Icons.touch_app_outlined,
                        size: 18, color: finished ? c.onPrimary : c.primary),
                    const SizedBox(width: 8),
                    Text(
                      finished ? 'Done' : dhikr.count == 1 ? 'Tap when read' : '$left of ${dhikr.count} left',
                      style: context.text.labelLarge?.copyWith(color: finished ? c.onPrimary : c.primary),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ListenCard extends StatelessWidget {
  const _ListenCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.primarySoft,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
              child: Icon(Icons.play_arrow_rounded, color: c.onPrimary, size: 28),
            ),
            const SizedBox(width: Space.lg),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Listen', style: context.text.titleMedium),
                Text('Recited one after another, each as many times as prescribed', style: context.text.bodySmall),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Controls while listening: previous, play / pause, next, once-each, stop.
class _ListenBar extends StatelessWidget {
  const _ListenBar({required this.audio, required this.category});
  final AdhkarPlayer audio;
  final AdhkarCategory category;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i = audio.index;
    final status = audio.waitingForReader
        ? 'Your turn: read, then tap'
        : audio.repetitions > 1
            ? 'Recitation ${(audio.repetition + (audio.playing ? 1 : 0)).clamp(1, audio.repetitions)} of ${audio.repetitions}'
            : audio.playing
                ? 'Reciting'
                : 'Paused';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.sm),
        child: Material(
          color: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.xl),
            side: BorderSide(color: c.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.sm, Space.sm),
            child: Row(children: [
              Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dhikr ${i + 1} of ${category.items.length}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                  Text(status, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () => audio.setOnce(!audio.once),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(audio.once ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          size: 18, color: c.primary),
                      const SizedBox(width: 4),
                      Text('Once each', style: context.text.bodySmall?.copyWith(color: c.ink)),
                    ]),
                  ),
                ]),
              ),
              IconButton(
                tooltip: 'Previous',
                onPressed: i > 0 ? () => audio.skip(-1) : null,
                icon: const Icon(Icons.skip_previous_rounded),
              ),
              Material(
                color: c.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: audio.playing ? audio.pause : audio.resume,
                  child: SizedBox.square(
                    dimension: 52,
                    child: Center(
                      child: Icon(audio.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: c.onPrimary, size: 30),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next',
                onPressed: i < category.items.length - 1 ? () => audio.skip(1) : null,
                icon: const Icon(Icons.skip_next_rounded),
              ),
              IconButton(
                tooltip: 'Stop listening',
                onPressed: audio.stop,
                icon: Icon(Icons.close_rounded, color: c.inkMuted),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
