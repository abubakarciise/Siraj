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
      appBar: AppBar(
        title: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          const Text('Adhkar'),
          const SizedBox(width: Space.sm),
          Text('الأذكار', style: TextStyle(fontFamily: kNaskhFont, fontSize: 16, color: c.goldText)),
        ]),
      ),
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
            return AppCard(
              onTap: () => context.push('/adhkar/${cat.id}'),
              child: Row(children: [
                IconBadge(adhkarIcons[cat.id] ?? Icons.favorite_border, color: c.primary, size: 48),
                const SizedBox(width: Space.lg),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(cat.titleEn, style: context.text.titleLarge?.copyWith(fontSize: 18)),
                    Text(cat.titleAr,
                        style: TextStyle(fontFamily: kNaskhFont, fontSize: 16, height: 1.5, color: c.goldText)),
                    _ListenTime(cat, full: ref.read(adhkarPlayerProvider).full),
                  ]),
                ),
                if (done) Icon(Icons.check_circle_rounded, color: c.primary),
                Icon(Icons.chevron_right_rounded, color: c.inkFaint),
              ]),
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
  final _keys = <int, GlobalKey>{};
  bool? _celebrated; // null until the category loads: already done then = no toast
  late final AdhkarPlayer _audio = ref.read(adhkarPlayerProvider);
  int? _followed;
  late bool _autoListen = widget.autoListen;
  final _scroll = ScrollController();

  /// While listening the list follows the dhikr being recited; scrolling by
  /// hand pauses that until "Back to dhikr" (or the next dhikr), as the Quran
  /// player's "Back to ayah" does.
  bool _following = true;
  bool _userDragging = false;

  int _left(AdhkarCategory cat, int i) => _audio.left(cat, i);

  bool get _listening => _audio.category?.id == widget.categoryId;

  @override
  void initState() {
    super.initState();
    _audio.addListener(_onAudio);
  }

  @override
  void dispose() {
    // Listening carries on in the background (mini player, notification).
    _audio.removeListener(_onAudio);
    _scroll.dispose();
    super.dispose();
  }

  void _onAudio() {
    if (!mounted) return;
    setState(() {});
    final cat = ref.read(adhkarProvider).value?.where((x) => x.id == widget.categoryId).firstOrNull;
    if (cat != null) _checkComplete(cat);
    if (_listening && _audio.index != _followed) {
      // A new dhikr: follow the recitation again, even after scrolling away.
      _followed = _audio.index;
      _following = true;
      if (!_userDragging) _scrollTo(_audio.index);
    }
  }

  void _scrollTo(int i) {
    final ctx = _keys[i]?.currentContext;
    if (ctx != null && ctx.mounted) {
      Scrollable.ensureVisible(ctx, duration: Motion.gentle, curve: Motion.emphasized, alignment: 0.08);
      return;
    }
    // Far away, the card is not built yet: jump near it by the average card
    // height, then settle on it once it is.
    if (!_scroll.hasClients) return;
    final cat = ref.read(adhkarProvider).value?.where((x) => x.id == widget.categoryId).firstOrNull;
    if (cat == null) return;
    final pos = _scroll.position;
    final perCard = (pos.maxScrollExtent + pos.viewportDimension) / (cat.items.length + 1);
    _scroll.jumpTo(((i + 1) * perCard).clamp(0.0, pos.maxScrollExtent));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _keys[i]?.currentContext;
      if (c != null && c.mounted) {
        Scrollable.ensureVisible(c, duration: Motion.standard, curve: Motion.curve, alignment: 0.08);
      }
    });
  }

  void _backToDhikr() {
    setState(() => _following = true);
    _scrollTo(_audio.index);
  }

  void _listen(AdhkarCategory cat) {
    if (_audio.allDone(cat)) _celebrated = false;
    _celebrated ??= false;
    _followed = null;
    _following = true;
    _audio.onError = (e) {
      if (mounted) showToast(context, '$e');
    };
    _audio.start(cat);
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
    if (!_audio.countOne(cat, i)) return;
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
    _celebrated ??= all;
    if (all && _celebrated == false) {
      _celebrated = true;
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
    _celebrated ??= _audio.allDone(cat);
    if (_autoListen) {
      _autoListen = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _listen(cat);
      });
    }
    final total = cat.totalCount;
    final done = total - List.generate(cat.items.length, (i) => _left(cat, i)).fold(0, (a, b) => a + b);

    final recorded = cat.listeningTime() > Duration.zero;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cat.titleEn),
          // Arabic and English apart: in one string the order would jumble.
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(cat.titleAr, style: TextStyle(fontFamily: kNaskhFont, fontSize: 14, height: 1.4, color: c.goldText)),
            Text('  ·  ${cat.items.length} adhkar', style: context.text.bodySmall?.copyWith(color: c.goldText)),
          ]),
        ]),
        actions: [
          IconButton(
            tooltip: 'Start again',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () {
              _audio.reset(cat);
              setState(() => _celebrated = false);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: total == 0 ? 0 : done / total),
            duration: Motion.standard,
            builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 3, color: c.gold, backgroundColor: c.divider),
          ),
        ),
      ),
      body: Stack(children: [
      NotificationListener<ScrollNotification>(
        onNotification: (n) {
          // Only a drag by hand pauses the follow, never the list's own scrolling.
          if (n is ScrollStartNotification && n.dragDetails != null) _userDragging = true;
          if (n is ScrollEndNotification && _userDragging) {
            _userDragging = false;
            if (_listening && _following) setState(() => _following = false);
          }
          return false;
        },
        child: ListView.builder(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(
            Space.gutter, Space.md, Space.gutter, Space.xxxl + MediaQuery.paddingOf(context).bottom),
        itemCount: cat.items.length + 1,
        itemBuilder: (_, k) {
          if (k == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: Space.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (recorded) ...[
                  _ModeSwitch(
                    full: _audio.full,
                    shortTime: formatListeningTime(cat.listeningTime()),
                    fullTime: formatListeningTime(cat.listeningTime(full: true)),
                    onChanged: _audio.setFull,
                  ),
                  const SizedBox(height: Space.md),
                ],
                AnimatedSwitcher(
                  duration: Motion.quick,
                  child: _listening || !recorded
                      ? const SizedBox(width: double.infinity)
                      : _ListenCard(
                          onTap: () => _listen(cat),
                          full: _audio.full,
                          // Where reading or listening stopped (kept until "Start again").
                          resumeAt: done > 0 && done < total
                              ? List.generate(cat.items.length, (i) => i).firstWhere((i) => _left(cat, i) > 0) + 1
                              : null,
                        ),
                ),
              ]),
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
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: Space.md,
        child: Center(
          child: AnimatedSwitcher(
            duration: Motion.quick,
            child: !_listening || _following
                ? const SizedBox.shrink()
                : ActionChip(
                    avatar: Icon(Icons.my_location_rounded, size: 18, color: c.primary),
                    label: Text('Back to dhikr ${_audio.index + 1}'),
                    backgroundColor: c.surface,
                    side: BorderSide(color: c.divider),
                    elevation: 2,
                    shadowColor: const Color(0x338A6A2B),
                    onPressed: _backToDhikr,
                  ),
          ),
        ),
      ),
      ]),
      bottomNavigationBar: _listening ? _ListenBar(audio: _audio, category: cat) : null,
    );
  }
}

/// "Short" (a hundred-times dhikr plays ten times) or "Full count": how the
/// adhkar are recited while listening, each with how long it takes.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.full, required this.shortTime, required this.fullTime, required this.onChanged});
  final bool full;
  final String shortTime, fullTime;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget option(bool value, String label, String time) {
      final selected = full == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: Material(
            color: selected ? c.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(value);
              },
              child: SizedBox(
                height: 44,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$label · $time',
                      maxLines: 1,
                      style: context.text.labelLarge?.copyWith(
                        fontSize: 14,
                        color: selected ? c.goldOnBrand : c.inkMuted,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: c.divider),
      ),
      child: Row(children: [
        option(false, 'Short', shortTime),
        const SizedBox(width: 4),
        option(true, 'Full count', fullTime),
      ]),
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
      opacity: finished && !active ? 0.8 : 1,
      // The fill is on the box that casts the shadow, or the shadow shows
      // through the card and greys it.
      child: AnimatedContainer(
        duration: Motion.quick,
        decoration: BoxDecoration(
          color: active ? Color.lerp(c.surface, c.gold, c.isDark ? 0.10 : 0.07) : c.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: active ? c.primary : c.divider, width: active ? 2 : 1),
          boxShadow: finished ? null : cardShadow(c),
        ),
        child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(Space.xl, Space.lg, Space.xl, Space.xl),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                StarMedallion(number: index + 1, size: 34, active: active),
                if (active) ...[
                  const SizedBox(width: Space.sm),
                  Icon(Icons.graphic_eq_rounded, size: 20, color: c.primary),
                  const SizedBox(width: 4),
                  Text('RECITING', style: context.text.labelSmall?.copyWith(color: c.primary)),
                ],
                const Spacer(),
                if (dhikr.quranRef != null)
                  Pill('Quran ${dhikr.quranRef}', color: c.goldText)
                else if (dhikr.count > 1)
                  Pill('${dhikr.count} times', color: c.goldText),
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
                const SizedBox(height: Space.sm),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: Space.xxl, vertical: Space.sm),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      c.gold.withValues(alpha: 0),
                      c.gold.withValues(alpha: 0.6),
                      c.gold.withValues(alpha: 0),
                    ]),
                  ),
                ),
                Text(
                  dhikr.virtue,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall?.copyWith(height: 1.7),
                ),
              ],
              const SizedBox(height: Space.lg),
              Center(child: _Counter(left: left, count: dhikr.count)),
            ]),
          ),
        ),
        ),
      ),
    );
  }
}

/// The count of a dhikr: a large gold-ringed circle for a dhikr said several
/// times (the number left, filling as it is counted), a pill for one said once.
class _Counter extends StatelessWidget {
  const _Counter({required this.left, required this.count});
  final int left, count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final finished = left == 0;
    if (count == 1 || finished) {
      return AnimatedContainer(
        duration: Motion.quick,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          color: finished ? c.brand : c.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: finished ? c.brand : c.divider),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(finished ? Icons.check_rounded : Icons.touch_app_outlined,
              size: 18, color: finished ? c.goldOnBrand : c.primary),
          const SizedBox(width: 8),
          Text(finished ? 'Done' : 'Tap when read',
              style: context.text.labelLarge?.copyWith(color: finished ? c.onBrand : c.primary)),
        ]),
      );
    }
    final said = count - left;
    return SizedBox.square(
      dimension: 96,
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: said / count),
            duration: Motion.standard,
            builder: (_, v, _) => CircularProgressIndicator(
              value: v,
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
              color: c.gold,
              backgroundColor: c.divider,
            ),
          ),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(c.surface, c.gold, c.isDark ? 0.12 : 0.10),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$left', style: context.text.headlineSmall?.copyWith(color: c.primary, height: 1.1)),
            Text('of $count · tap', style: context.text.labelSmall?.copyWith(letterSpacing: 0, fontSize: 10)),
          ]),
        ),
      ]),
    );
  }
}

class _ListenCard extends StatelessWidget {
  const _ListenCard({required this.onTap, required this.full, this.resumeAt});
  final VoidCallback onTap;
  final bool full;

  /// The dhikr (1-based) to continue from, when some were already counted.
  final int? resumeAt;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return BrandPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(Space.lg),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: c.goldOnBrand, shape: BoxShape.circle),
          child: Icon(Icons.play_arrow_rounded, color: c.brand, size: 32),
        ),
        const SizedBox(width: Space.lg),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(resumeAt == null ? 'Listen' : 'Continue listening',
                style: context.text.titleLarge?.copyWith(color: c.onBrand)),
            Text(
              resumeAt == null
                  ? (full ? 'Each dhikr as many times as it is said' : 'A hundred-times dhikr plays ten times')
                  : 'From dhikr $resumeAt, where you stopped',
              style: context.text.bodySmall?.copyWith(color: c.onBrand.withValues(alpha: 0.78)),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Controls while listening: previous, play / pause, next, stop; the mode
/// ("Once each" / "Full count") is chosen above the adhkar.
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
                ? (audio.full ? 'Full count' : 'Short')
                : 'Paused';
    final onBar = c.onBrand;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.sm),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(colors: c.brandGradient),
            boxShadow: c.isDark ? null : const [BoxShadow(color: Color(0x400F4F40), blurRadius: 20, offset: Offset(0, 8))],
          ),
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.xs, Space.sm),
          child: Row(children: [
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dhikr ${i + 1} of ${category.items.length}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium?.copyWith(color: onBar)),
                Text(status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(color: c.goldOnBrand)),
              ]),
            ),
            IconButton(
              tooltip: 'Previous',
              color: onBar,
              disabledColor: onBar.withValues(alpha: 0.3),
              onPressed: i > 0 ? () => audio.skip(-1) : null,
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            Material(
              color: c.goldOnBrand,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: audio.playing ? audio.pause : audio.resume,
                child: SizedBox.square(
                  dimension: 54,
                  child: Center(
                    child: Icon(audio.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: c.brand, size: 30),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next',
              color: onBar,
              disabledColor: onBar.withValues(alpha: 0.3),
              onPressed: i < category.items.length - 1 ? () => audio.skip(1) : null,
              icon: const Icon(Icons.skip_next_rounded),
            ),
            IconButton(
              tooltip: 'Stop listening',
              onPressed: audio.stop,
              icon: Icon(Icons.close_rounded, color: onBar.withValues(alpha: 0.7)),
            ),
          ]),
        ),
      ),
    );
  }
}

/// "12 min of listening", with a note when some adhkar have no recording.
class _ListenTime extends StatelessWidget {
  const _ListenTime(this.cat, {required this.full});
  final AdhkarCategory cat;

  /// The listener's choice: "Full count" or "Short".
  final bool full;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = cat.listeningTime(full: full);
    if (t == Duration.zero) return const SizedBox.shrink();
    return Row(children: [
      Icon(Icons.headphones_rounded, size: 14, color: c.goldText),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          cat.unrecorded == 0
              ? '${formatListeningTime(t)} of listening'
              : '${formatListeningTime(t)} of listening · ${cat.unrecorded} to read',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelSmall?.copyWith(color: c.goldText, letterSpacing: 0.2),
        ),
      ),
    ]);
  }
}
