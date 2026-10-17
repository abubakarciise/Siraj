import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../app/shell.dart';
import '../../core/audio/player_controller.dart';
import '../../core/providers.dart';
import '../../design/dialogs.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final np = ref.watch(nowPlayingProvider).value;
    final pc = ref.read(playerProvider);
    if (np == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && context.canPop()) context.pop();
      });
      return Scaffold(backgroundColor: c.bg);
    }
    final db = ref.watch(quranDbProvider);
    final surah = db.surah(np.surah);
    final durMs = np.duration.inMilliseconds.toDouble();
    final posMs = (_drag ?? np.position.inMilliseconds.toDouble()).clamp(0.0, durMs <= 0 ? 1.0 : durMs);

    return GestureDetector(
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 600) context.pop();
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: Stack(children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [c.primarySoft.withValues(alpha: c.isDark ? 0.55 : 0.7), c.bg],
                  stops: const [0, 0.35],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                child: Row(children: [
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: Space.xs),
                  Hero(
                    tag: 'player-art',
                    child: ReciterAvatar(id: np.reciter.id, nameAr: np.reciter.nameAr, size: 44),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${surah.nameEn} · ${surah.nameAr}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                      Text('${np.reciter.name} · ${np.recitation.shortName}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                    ]),
                  ),
                  IconButton(
                    tooltip: 'Open in Mushaf',
                    icon: const Icon(Icons.menu_book_rounded),
                    onPressed: () async {
                      final page = np.ayah != null ? await db.pageOf(np.ayah!) : surah.pageStart;
                      if (context.mounted) {
                        context.pop();
                        // No selection: the live recitation highlight already marks the ayah.
                        context.openReader(page, surah: surah.id);
                      }
                    },
                  ),
                ]),
              ),
              // The whole surah, following the recitation when it has ayah timing.
              Expanded(child: SurahFollowAlong(key: ValueKey('${np.recitation.key}|${np.surah}'), surah: np.surah)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.xxl),
                child: Column(children: [
                  Slider(
                    value: posMs,
                    max: durMs <= 0 ? 1 : durMs,
                    onChanged: durMs <= 0 ? null : (v) => setState(() => _drag = v),
                    onChangeEnd: (v) {
                      pc.seek(Duration(milliseconds: v.round()));
                      setState(() => _drag = null);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      Text(formatDuration(Duration(milliseconds: posMs.round())), style: context.text.bodySmall),
                      const Spacer(),
                      Text(formatDuration(np.duration), style: context.text.bodySmall),
                    ]),
                  ),
                  const SizedBox(height: Space.sm),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    _RepeatButton(np: np),
                    IconButton(
                      iconSize: 34,
                      tooltip: np.hasTiming ? 'Previous ayah' : 'Previous surah',
                      onPressed: np.hasTiming ? pc.previousAyah : pc.previous,
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                    _PlayButton(np: np, onTap: pc.toggle),
                    IconButton(
                      iconSize: 34,
                      tooltip: np.hasTiming ? 'Next ayah' : 'Next surah',
                      onPressed: np.hasTiming ? pc.nextAyah : (np.hasNext ? pc.next : null),
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                    _SleepButton(np: np),
                  ]),
                  const SizedBox(height: Space.xs),
                  // Shrinks on narrow screens / large fonts instead of overflowing.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      TextButton.icon(
                        onPressed: np.hasPrevious ? pc.previous : null,
                        icon: const Icon(Icons.first_page_rounded, size: 20),
                        label: const Text('Surah'),
                      ),
                      TextButton.icon(
                        onPressed: np.hasNext ? pc.next : null,
                        icon: const Icon(Icons.last_page_rounded, size: 20),
                        label: const Text('Surah'),
                      ),
                      IconButton(
                        tooltip: 'Stop',
                        onPressed: () async {
                          await pc.stop();
                          if (context.mounted && context.canPop()) context.pop();
                        },
                        icon: Icon(Icons.stop_circle_outlined, color: c.inkMuted),
                      ),
                    ]),
                  ),
                  const SizedBox(height: Space.sm),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// The surah as a scrolling text that follows the reciter: the current ayah is
/// highlighted and kept in view, from the recitation's ayah timing (without
/// timing the text is shown to read along, with nothing highlighted). Tap an
/// ayah to jump to it; scrolling by hand pauses the follow until "Back to ayah".
class SurahFollowAlong extends ConsumerStatefulWidget {
  const SurahFollowAlong({super.key, required this.surah});
  final int surah;

  @override
  ConsumerState<SurahFollowAlong> createState() => _SurahFollowAlongState();
}

class _SurahFollowAlongState extends ConsumerState<SurahFollowAlong> {
  final _items = ItemScrollController();

  /// Where the ayah being recited sits: its top a little above the middle, so
  /// the ayah itself is in the centre of the screen.
  static const _centre = 0.32;
  bool _following = true;
  bool _userDragging = false;
  int? _shown;

  bool get _hasBasmala => widget.surah != 1 && widget.surah != 9;

  /// List index of [ayah] (0 = basmala row when the surah has one).
  int _indexOf(int ayah) => _hasBasmala ? ayah : math.max(0, ayah - 1);

  /// The ayah being recited (0 = the opening basmala), from the recitation's
  /// ayah timing. Without timing nothing is highlighted: a guess from ayah
  /// lengths was right only about a quarter of the time.
  int? _current(NowPlaying? np) {
    if (np == null || np.surah != widget.surah || !np.hasTiming) return null;
    return np.ayah?.ayah ?? 0;
  }

  void _scrollTo(int ayah, {bool jump = false}) {
    if (!_items.isAttached) return;
    final index = _indexOf(ayah);
    if (jump) {
      _items.jumpTo(index: index, alignment: _centre);
    } else {
      _items.scrollTo(index: index, alignment: _centre, duration: Motion.standard, curve: Motion.curve);
    }
  }

  Future<void> _seekTo(int ayah) async {
    final pc = ref.read(playerProvider);
    final np = ref.read(nowPlayingProvider).value;
    if (np == null) return;
    if (!np.hasTiming) return;
    setState(() => _following = true);
    await pc.seekToAyah(ayah);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ayahs = ref.watch(surahAyahsProvider(widget.surah)).value;
    final translations = ref.watch(surahTranslationProvider(widget.surah)).value ?? const {};
    if (ayahs == null) return const Center(child: CircularProgressIndicator());
    // Rebuild only when the current ayah changes, not on every position tick.
    final ayah = ref.watch(nowPlayingProvider.select((v) => _current(v.value)));
    final timed = ref.watch(nowPlayingProvider.select((v) => v.value?.recitation.hasTiming ?? true));

    if (ayah != null && ayah != _shown) {
      // A new ayah: follow the reciter again, even after scrolling away by hand
      // (the "Back to ayah" button stays while reading elsewhere until then).
      final first = _shown == null;
      _shown = ayah;
      _following = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_userDragging) _scrollTo(ayah, jump: first);
      });
    }

    final count = ayahs.length + (_hasBasmala ? 1 : 0);
    return Column(children: [
      if (!timed)
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, 0),
          child: Row(children: [
            Icon(Icons.info_outline_rounded, size: 16, color: c.inkMuted),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                'This recitation has no ayah timing, so the ayah being recited cannot be highlighted. '
                'Reciters marked Ayah sync follow along exactly.',
                style: context.text.bodySmall,
              ),
            ),
          ]),
        ),
      Expanded(child: Stack(children: [
      NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollStartNotification && n.dragDetails != null) _userDragging = true;
          if (n is ScrollEndNotification && _userDragging) {
            _userDragging = false;
            if (_following) setState(() => _following = false);
          }
          return false;
        },
        child: ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
            stops: [0, 0.06, 0.9, 1],
          ).createShader(r),
          blendMode: BlendMode.dstIn,
          child: ScrollablePositionedList.builder(
            itemScrollController: _items,
            initialScrollIndex: ayah == null ? 0 : _indexOf(ayah),
            initialAlignment: _centre,
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.gutter, 160),
            itemCount: count,
            itemBuilder: (context, i) {
              if (_hasBasmala && i == 0) {
                return _FollowRow(
                  active: ayah == 0,
                  onTap: () => _seekTo(1),
                  child: Text('بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontFamily: kQuranFont, fontSize: 24, height: 1.8, color: c.ink)),
                );
              }
              final a = ayahs[i - (_hasBasmala ? 1 : 0)];
              final active = a.ref.ayah == ayah;
              final tr = translations[a.ref.ayah];
              return _FollowRow(
                active: active,
                onTap: () => _seekTo(a.ref.ayah),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(
                    a.text,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kQuranFont,
                      fontSize: 25,
                      height: 1.9,
                      color: active || !timed ? c.ink : c.ink.withValues(alpha: 0.55),
                    ),
                  ),
                  if (tr != null) ...[
                    const SizedBox(height: Space.sm),
                    Text(tr,
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium?.copyWith(color: active || !timed ? c.inkMuted : c.inkFaint, height: 1.5)),
                  ],
                ]),
              );
            },
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: Space.md,
        child: Center(
          child: AnimatedSwitcher(
            duration: Motion.quick,
            child: _following || ayah == null
                ? const SizedBox.shrink()
                : ActionChip(
                    avatar: Icon(Icons.my_location_rounded, size: 18, color: c.primary),
                    label: Text(ayah == 0 ? 'Back to current' : 'Back to ayah $ayah'),
                    backgroundColor: c.surface,
                    side: BorderSide(color: c.divider),
                    onPressed: () {
                      setState(() => _following = true);
                      _scrollTo(ayah);
                    },
                  ),
          ),
        ),
      ),
      ])),
    ]);
  }
}

class _FollowRow extends StatelessWidget {
  const _FollowRow({required this.active, required this.onTap, required this.child});
  final bool active;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.quick,
            curve: Motion.curve,
            padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.md),
            decoration: BoxDecoration(
              color: active ? c.primarySoft.withValues(alpha: c.isDark ? 0.55 : 0.75) : Colors.transparent,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: active ? c.primary.withValues(alpha: 0.35) : Colors.transparent),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.np, required this.onTap});
  final NowPlaying np;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 76,
          child: Center(
            child: np.buffering && !np.playing
                ? SizedBox.square(dimension: 28, child: CircularProgressIndicator(color: c.onPrimary, strokeWidth: 3))
                : AnimatedSwitcher(
                    duration: Motion.quick,
                    transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
                    child: Icon(np.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        key: ValueKey(np.playing), color: c.onPrimary, size: 40),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RepeatButton extends ConsumerWidget {
  const _RepeatButton({required this.np});
  final NowPlaying np;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final active = np.repeat != RepeatKind.off;
    return IconButton(
      tooltip: 'Repeat',
      onPressed: () => showAppSheet(context, title: 'Repeat', builder: (_) => _RepeatSheet(np: np)),
      icon: Badge(
        isLabelVisible: np.repeat == RepeatKind.ayah,
        backgroundColor: c.primary,
        label: Text(np.repeatTimes == 0 ? '∞' : '${np.repeatDone + 1}/${np.repeatTimes}'),
        child: Icon(np.repeat == RepeatKind.surah ? Icons.repeat_one_rounded : Icons.repeat_rounded,
            color: active ? c.primary : c.inkMuted),
      ),
    );
  }
}

class _RepeatSheet extends ConsumerStatefulWidget {
  const _RepeatSheet({required this.np});
  final NowPlaying np;

  @override
  ConsumerState<_RepeatSheet> createState() => _RepeatSheetState();
}

class _RepeatSheetState extends ConsumerState<_RepeatSheet> {
  late RepeatKind _kind = widget.np.repeat;
  late int _times = widget.np.repeatTimes == 0 ? 3 : widget.np.repeatTimes;

  @override
  Widget build(BuildContext context) {
    final pc = ref.read(playerProvider);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Memorization helper: repeat each ayah before moving on.', style: context.text.bodySmall),
      const SizedBox(height: Space.lg),
      SegmentedButton<RepeatKind>(
        segments: [
          const ButtonSegment(value: RepeatKind.off, label: Text('Off')),
          ButtonSegment(value: RepeatKind.ayah, label: const Text('Each ayah'), enabled: widget.np.hasTiming),
          const ButtonSegment(value: RepeatKind.surah, label: Text('Surah')),
        ],
        selected: {_kind},
        onSelectionChanged: (s) => setState(() => _kind = s.first),
      ),
      if (!widget.np.hasTiming)
        Padding(
          padding: const EdgeInsets.only(top: Space.sm),
          child: Text('Ayah repeat needs a reciter with ayah timing.', style: context.text.bodySmall),
        ),
      if (_kind == RepeatKind.ayah) ...[
        const SizedBox(height: Space.lg),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in [2, 3, 5, 7, 10, 0])
            ChoiceChip(
              label: Text(t == 0 ? '∞' : '$t×'),
              selected: _times == t,
              onSelected: (_) => setState(() => _times = t),
            ),
        ]),
      ],
      const SizedBox(height: Space.xl),
      FilledButton(
        onPressed: () {
          pc.setRepeat(_kind, times: _times);
          Navigator.pop(context);
        },
        child: const Text('Apply'),
      ),
    ]);
  }
}

class _SleepButton extends ConsumerWidget {
  const _SleepButton({required this.np});
  final NowPlaying np;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final pc = ref.read(playerProvider);
    final active = np.sleepAt != null || pc.sleepEndOfSurah;
    return IconButton(
      tooltip: 'Sleep timer',
      icon: Icon(Icons.bedtime_outlined, color: active ? c.primary : c.inkMuted),
      onPressed: () => showAppSheet(
        context,
        title: 'Sleep timer',
        builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (np.sleepAt != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: Text('Stops at ${TimeOfDay.fromDateTime(np.sleepAt!).format(context)}',
                  style: context.text.bodySmall),
            ),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in [5, 15, 30, 45, 60])
              ActionChip(
                label: Text('$m min'),
                onPressed: () {
                  pc.setSleep(Duration(minutes: m));
                  Navigator.pop(ctx);
                },
              ),
            ActionChip(
              label: const Text('End of surah'),
              onPressed: () {
                pc.setSleep(null, endOfSurah: true);
                Navigator.pop(ctx);
              },
            ),
            if (active)
              ActionChip(
                label: const Text('Turn off'),
                onPressed: () {
                  pc.cancelSleep();
                  Navigator.pop(ctx);
                },
              ),
          ]),
        ]),
      ),
    );
  }
}
