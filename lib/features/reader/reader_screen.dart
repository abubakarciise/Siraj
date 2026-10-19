import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/providers.dart';
import '../../core/quran/arabic.dart';
import '../../core/quran/models.dart';
import '../../design/dialogs.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../player/play_actions.dart';
import 'ayah_sheet.dart';
import 'mushaf_page.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.initialPage, this.highlight, this.surah});
  final int initialPage;
  final AyahRef? highlight;

  /// The surah the user chose; the page scrubber is scoped to it.
  final int? surah;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final PageController _pages = PageController(initialPage: widget.initialPage - 1);
  late int _page = widget.initialPage;
  late AyahRef? _selected = widget.highlight;
  bool _chrome = true;
  (AppColors, MushafPaper)? _themeKey;
  ThemeData? _theme;
  Timer? _hideTimer;
  DateTime _lastUserSwipe = DateTime.fromMillisecondsSinceEpoch(0);
  late final _player = ref.read(playerProvider);
  late int _surah = widget.surah ?? widget.highlight?.surah ?? _surahAt(widget.initialPage, forward: true);

  /// Surah shown on [page]; on pages shared by two surahs, the one the reader
  /// is moving into (forward: the later one starting here; backward: the earlier).
  int _surahAt(int page, {required bool forward}) {
    final all = ref.read(quranDbProvider).surahs.where((x) => x.pageStart <= page && x.pageEnd >= page).toList();
    if (all.isEmpty) return 1;
    return forward ? all.firstWhere((x) => x.pageStart == page, orElse: () => all.first).id : all.last.id;
  }

  void _onPage(int page) {
    final forward = page > _page;
    final current = ref.read(quranDbProvider).surah(_surah);
    final stillInside = page >= current.pageStart && page <= current.pageEnd;
    final next = stillInside ? _surah : _surahAt(page, forward: forward);
    setState(() {
      _page = page;
      _surah = next;
      _selected = null;
    });
    _record(page);
    _prefetch(page);
  }

  /// Loads the neighbouring pages before they are swiped in.
  void _prefetch(int page) {
    for (final p in [page - 2, page - 1, page + 1, page + 2]) {
      if (p >= 1 && p <= kTotalPages) ref.read(mushafPageProvider(p).future).ignore();
    }
  }

  void _goToSurah(int id) {
    final target = ref.read(quranDbProvider).surah(id);
    setState(() => _surah = id);
    _pages.animateToPage(target.pageStart - 1, duration: Motion.standard, curve: Motion.emphasized);
    _scheduleHide();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _scheduleHide();
    _player.currentAyah.addListener(_followAudio);
    if (ref.read(settingsProvider).keepScreenOn) WakelockPlus.enable();
    _record(_page);
    _prefetch(_page);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _player.currentAyah.removeListener(_followAudio);
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pages.dispose();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _chrome) setState(() => _chrome = false);
    });
  }

  void _toggleChrome() {
    setState(() => _chrome = !_chrome);
    if (_chrome) _scheduleHide();
  }

  /// Auto-turn to the page of the ayah being recited, unless the user is browsing.
  Future<void> _followAudio() async {
    final a = _player.currentAyah.value;
    if (a == null || !ref.read(settingsProvider).followAudio) return;
    if (DateTime.now().difference(_lastUserSwipe) < const Duration(seconds: 6)) return;
    final page = await ref.read(quranDbProvider).pageOf(a);
    if (mounted && page != _page && _pages.hasClients) {
      _pages.animateToPage(page - 1, duration: Motion.standard, curve: Motion.emphasized);
    }
  }

  Future<void> _record(int page) async {
    final p = await ref.read(mushafPageProvider(page).future);
    await ref.read(userStoreProvider).recordRead(page, p.firstAyah);
    ref.invalidate(lastReadProvider);
  }

  void _jumpTo(int page) => _pages.jumpToPage(page - 1);

  @override
  Widget build(BuildContext context) {
    final paper = ref.watch(settingsProvider.select((s) => s.paper));
    final base = context.colors;
    // The page colour can differ from the app theme; everything inside the
    // reader (bars, sheets launched from here) follows the page.
    if (_themeKey?.$1 != base || _themeKey?.$2 != paper) {
      _themeKey = (base, paper);
      _theme = buildThemeFrom(base.withPaper(paper));
    }
    return Theme(data: _theme!, child: Builder(builder: _buildReader));
  }

  Widget _buildReader(BuildContext context) {
    final c = context.colors;
    final db = ref.watch(quranDbProvider);
    // Only whether something is playing: position ticks must not rebuild the pages.
    final hasPlayer = ref.watch(nowPlayingProvider.select((v) => v.value != null));
    final pageData = ref.watch(mushafPageProvider(_page)).value;
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion(
      value: systemBars(c, bottom: c.pageBg),
      child: Scaffold(
        backgroundColor: c.pageBg,
        body: Stack(
          children: [
            // ---- Pages (RTL: next page comes from the left, like a printed Mushaf) ----
            Positioned.fill(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: NotificationListener<UserScrollNotification>(
                  onNotification: (_) {
                    _lastUserSwipe = DateTime.now();
                    return false;
                  },
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: kTotalPages,
                    allowImplicitScrolling: true,
                    onPageChanged: (i) => _onPage(i + 1),
                    itemBuilder: (context, i) => _PageFrame(
                      key: ValueKey(i),
                      pageNumber: i + 1,
                      onTap: _toggleChrome,
                      selected: _selected,
                      onLongPress: (a) async {
                        HapticFeedback.mediumImpact();
                        setState(() => _selected = a);
                        await showAyahSheet(context, a);
                        if (mounted) setState(() => _selected = null);
                      },
                    ),
                  ),
                ),
              ),
            ),

            // ---- Top bar: in the page colour, so it reads as part of the page ----
            AnimatedPositioned(
              duration: Motion.standard,
              curve: Motion.emphasized,
              top: _chrome ? 0 : -(top + 96),
              left: 0,
              right: 0,
              child: _ReaderTopBar(
                surah: db.surah(_surah),
                juz: pageData?.juz,
                page: _page,
                onPaper: () {
                  _scheduleHide();
                  showAppSheet(context, title: 'Page colour', builder: (_) => const PaperPicker());
                },
              ),
            ),

            // ---- Bottom dock: surah, page slider, play, now playing ----
            AnimatedPositioned(
              duration: Motion.standard,
              curve: Motion.emphasized,
              bottom: _chrome ? 0 : -360,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.sm),
                  child: _ReaderDock(
                    surah: db.surah(_surah),
                    page: _page,
                    showNowPlaying: hasPlayer,
                    onPrevSurah: _surah > 1 ? () => _goToSurah(_surah - 1) : null,
                    onNextSurah: _surah < 114 ? () => _goToSurah(_surah + 1) : null,
                    onSeek: (p) {
                      _scheduleHide();
                      _jumpTo(p);
                    },
                    onPlayPage: pageData == null
                        ? null
                        : () {
                            _scheduleHide();
                            // The surah shown in the dock, not the end of the one before it.
                            final a = pageData.firstAyahOf(_surah);
                            playFromMushaf(context, ref, a.surah, ayah: a.ayah);
                          },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageFrame extends ConsumerWidget {
  const _PageFrame({
    super.key,
    required this.pageNumber,
    required this.onTap,
    required this.onLongPress,
    this.selected,
  });
  final int pageNumber;
  final VoidCallback onTap;
  final void Function(AyahRef) onLongPress;
  final AyahRef? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final db = ref.watch(quranDbProvider);
    final page = ref.watch(mushafPageProvider(pageNumber));
    final pad = MediaQuery.paddingOf(context);
    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, pad.top + 10, 14, pad.bottom + 8),
          child: page.when(
            loading: () => const SizedBox(),
            error: (e, _) => Center(child: Text('$e')),
            data: (p) => Column(
              children: [
                // Running header (surah · juz), like the printed Mushaf.
                SizedBox(
                  height: 22,
                  child: Row(
                    children: [
                      Text(
                        db.surah(p.surahs.last).nameAr,
                        style: TextStyle(fontFamily: kQuranFont, fontSize: 15, color: c.inkMuted, height: 1),
                      ),
                      const Spacer(),
                      Text(
                        'الجزء ${toArabicDigits(p.juz)}',
                        style: TextStyle(fontFamily: kUiFont, fontSize: 13, color: c.inkMuted, height: 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ValueListenableBuilder<AyahRef?>(
                    valueListenable: ref.read(playerProvider).currentAyah,
                    builder: (_, playingAyah, _) => MushafPageView(
                      page: p,
                      surahNames: (s) => db.surah(s).nameAr,
                      playing: playingAyah,
                      selected: selected,
                      onAyahLongPress: onLongPress,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 22,
                  child: Center(
                    child: Text(
                      toArabicDigits(pageNumber),
                      style: TextStyle(fontFamily: kQuranFont, fontSize: 16, color: c.inkMuted, height: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReaderTopBar extends StatelessWidget {
  const _ReaderTopBar({required this.surah, required this.juz, required this.page, required this.onPaper});
  final Surah surah;
  final int? juz;
  final int page;
  final VoidCallback onPaper;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.pageBg, border: Border(bottom: BorderSide(color: c.divider))),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
          child: Row(
            children: [
              IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(surah.nameEn, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                    Text(juz == null ? 'Page $page' : 'Juz $juz · Page $page', maxLines: 1, style: context.text.bodySmall),
                  ],
                ),
              ),
              IconButton(tooltip: 'Page colour', icon: const Icon(Icons.palette_outlined), onPressed: onPaper),
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search_rounded),
                onPressed: () => context.push('/search'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One calm card in the page colour: surah navigation, a page slider scoped
/// to the surah, play / pause, and what is playing.
class _ReaderDock extends StatelessWidget {
  const _ReaderDock({
    required this.surah,
    required this.page,
    required this.showNowPlaying,
    required this.onSeek,
    required this.onPlayPage,
    this.onPrevSurah,
    this.onNextSurah,
  });

  final Surah surah;
  final int page;
  final bool showNowPlaying;
  final ValueChanged<int> onSeek;
  final VoidCallback? onPlayPage, onPrevSurah, onNextSurah;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = surah.pageEnd - surah.pageStart + 1;
    final index = (page - surah.pageStart + 1).clamp(1, total);
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xl),
        side: BorderSide(color: c.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.xs, Space.sm, Space.sm, Space.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous surah',
                  onPressed: onPrevSurah,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(surah.nameEn, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                      Text(total == 1 ? 'One page' : 'Page $index of $total', maxLines: 1, style: context.text.bodySmall),
                    ],
                  ),
                ),
                IconButton(tooltip: 'Next surah', onPressed: onNextSurah, icon: const Icon(Icons.chevron_right_rounded)),
                const SizedBox(width: Space.xs),
                _PlayButton(onPlayPage: onPlayPage),
              ],
            ),
            if (total > 1)
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  inactiveTrackColor: c.divider,
                ),
                child: SizedBox(
                  height: 28,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Slider(
                      value: page.clamp(surah.pageStart, surah.pageEnd).toDouble(),
                      min: surah.pageStart.toDouble(),
                      max: surah.pageEnd.toDouble(),
                      divisions: total - 1,
                      onChanged: (v) => onSeek(v.round()),
                    ),
                  ),
                ),
              ),
            if (showNowPlaying) const _NowPlayingLine(),
          ],
        ),
      ),
    );
  }
}

/// Plays this page, or pauses / resumes what is already playing.
class _PlayButton extends ConsumerWidget {
  const _PlayButton({required this.onPlayPage});
  final VoidCallback? onPlayPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final state = ref.watch(
      nowPlayingProvider.select((v) => v.value == null ? null : (v.value!.playing, v.value!.buffering)),
    );
    final playing = state?.$1 ?? false;
    final buffering = (state?.$2 ?? false) && !playing;
    return Semantics(
      button: true,
      label: state == null ? 'Play this page' : (playing ? 'Pause' : 'Resume'),
      child: Material(
        color: c.primary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: state == null ? onPlayPage : ref.read(playerProvider).toggle,
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: buffering
                  ? SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: c.onPrimary))
                  : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: c.onPrimary, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

/// What is playing, inside the dock: tap for the full player, x to stop.
class _NowPlayingLine extends ConsumerWidget {
  const _NowPlayingLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final np = ref.watch(nowPlayingProvider).value;
    if (np == null) return const SizedBox.shrink();
    final db = ref.watch(quranDbProvider);
    final progress = np.duration.inMilliseconds == 0
        ? 0.0
        : (np.position.inMilliseconds / np.duration.inMilliseconds).clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.xs, 0),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            color: c.primary,
            backgroundColor: c.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(Radii.md),
          onTap: () => context.push('/player'),
          child: Padding(
            padding: const EdgeInsets.only(left: Space.md),
            child: Row(
              children: [
                Icon(Icons.graphic_eq_rounded, size: 18, color: c.primary),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    '${db.surah(np.surah).nameEn}${np.ayah != null ? ' · ${np.ayah!.ayah}' : ''} · ${np.reciter.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(color: c.ink),
                  ),
                ),
                IconButton(
                  tooltip: 'Stop',
                  visualDensity: VisualDensity.compact,
                  onPressed: ref.read(playerProvider).stop,
                  icon: Icon(Icons.close_rounded, size: 20, color: c.inkMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Mushaf page colour choices, shown from the reader and from Settings.
class PaperPicker extends ConsumerWidget {
  const PaperPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final current = settings.paper;
    final app = AppColors.of(settings.resolve(MediaQuery.platformBrightnessOf(context) == Brightness.dark));
    return Wrap(
      spacing: 10,
      runSpacing: Space.md,
      children: [
        for (final p in MushafPaper.values)
          _Swatch(
            paper: p,
            colors: app.withPaper(p),
            selected: current == p,
            onTap: () => ref.read(settingsProvider.notifier).update((s) => s.copyWith(paper: p)),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.paper, required this.colors, required this.selected, required this.onTap});
  final MushafPaper paper;
  final AppColors colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      label: paper.label,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Motion.quick,
              width: 52,
              height: 72,
              decoration: BoxDecoration(
                color: colors.pageBg,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: selected ? c.primary : c.divider, width: selected ? 2.5 : 1),
              ),
              alignment: Alignment.center,
              child: Text(
                'بِسۡمِ',
                style: TextStyle(fontFamily: kQuranFont, fontSize: 19, color: colors.ink, height: 1.2),
              ),
            ),
            const SizedBox(height: 6),
            Text(paper.label, style: context.text.bodySmall?.copyWith(color: selected ? c.primary : c.inkMuted)),
          ],
        ),
      ),
    );
  }
}

extension MushafPaperX on MushafPaper {
  String get label => switch (this) {
    MushafPaper.auto => 'Theme',
    MushafPaper.ivory => 'Ivory',
    MushafPaper.white => 'White',
    MushafPaper.sepia => 'Sepia',
    MushafPaper.dark => 'Dark',
    MushafPaper.black => 'Black',
  };
}
