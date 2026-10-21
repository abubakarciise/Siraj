import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shell.dart';
import '../../core/memorize/quiz.dart';
import '../../core/providers.dart';
import '../../core/quran/models.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import '../../l10n/l10n.dart';

/// A finished test, kept on the device to show progress.
class QuizResult {
  const QuizResult(this.scope, this.score, this.total, this.at);
  final String scope;
  final int score, total;
  final DateTime at;

  Map<String, dynamic> toJson() => {'scope': scope, 'score': score, 'total': total, 'at': at.millisecondsSinceEpoch};
  static QuizResult fromJson(Map<String, dynamic> j) => QuizResult(
      j['scope'] as String, j['score'] as int, j['total'] as int, DateTime.fromMillisecondsSinceEpoch(j['at'] as int));
}

final quizHistoryProvider = NotifierProvider<QuizHistory, List<QuizResult>>(QuizHistory.new);

class QuizHistory extends Notifier<List<QuizResult>> {
  static const _key = 'memorize_history';

  @override
  List<QuizResult> build() {
    final raw = ref.read(prefsProvider).getString(_key);
    if (raw == null) return const [];
    try {
      return [for (final j in jsonDecode(raw) as List) QuizResult.fromJson(j as Map<String, dynamic>)];
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(QuizResult r) async {
    state = [r, ...state].take(20).toList();
    await ref.read(prefsProvider).setString(_key, jsonEncode([for (final x in state) x.toJson()]));
  }
}

enum _ScopeType { surahs, juz, quran }

/// Choose what to test (surahs, juz or the whole Quran), then start.
class MemorizeScreen extends ConsumerStatefulWidget {
  const MemorizeScreen({super.key});

  @override
  ConsumerState<MemorizeScreen> createState() => _MemorizeScreenState();
}

class _MemorizeScreenState extends ConsumerState<MemorizeScreen> {
  _ScopeType _type = _ScopeType.surahs;
  late final _surahs = <int>{ref.read(lastReadProvider).value?.ref.surah ?? 67};
  final _juz = <int>{30};
  RangeValues? _range;
  int _count = 10;
  final _kinds = {QuizKind.nextAyah, QuizKind.completeAyah, QuizKind.missingWord, QuizKind.recite};
  bool _busy = false;

  Future<void> _pickSurahs() async {
    final picked = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _SurahPicker(initial: _surahs),
    );
    if (picked != null && picked.isNotEmpty) {
      setState(() {
        _surahs
          ..clear()
          ..addAll(picked);
        _range = null;
      });
    }
  }

  String _scopeLabel() {
    final db = ref.read(quranDbProvider);
    switch (_type) {
      case _ScopeType.quran:
        return context.l10n.wholeQuran;
      case _ScopeType.juz:
        final j = _juz.toList()..sort();
        return j.length <= 3 ? context.l10n.juzNumber(j.join(', ')) : context.l10n.juzCount(j.length);
      case _ScopeType.surahs:
        final s = _surahs.toList()..sort();
        if (s.length == 1) {
          final surah = db.surah(s.first);
          final r = _range;
          return r == null || (r.start.round() == 1 && r.end.round() == surah.ayahCount)
              ? surah.nameEn
              : context.l10n.surahRange(surah.nameEn, r.start.round(), r.end.round());
        }
        return s.length <= 2 ? s.map((x) => db.surah(x).nameEn).join(', ') : context.l10n.surahsCount(s.length);
    }
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    final db = ref.read(quranDbProvider);
    List<Ayah> ayahs;
    switch (_type) {
      case _ScopeType.quran:
        ayahs = await db.allAyahs();
      case _ScopeType.juz:
        ayahs = [for (final j in _juz.toList()..sort()) ...await db.ayahsOfJuz(j)];
      case _ScopeType.surahs:
        final ids = _surahs.toList()..sort();
        ayahs = [for (final s in ids) ...await db.ayahsOfSurah(s)];
        final r = _range;
        if (ids.length == 1 && r != null) ayahs = ayahs.sublist(r.start.round() - 1, r.end.round());
    }
    final builder = QuizBuilder(ayahs, surahName: (s) => db.surah(s).nameEn);
    final questions = builder.build(_count, _kinds);
    if (!mounted) return;
    setState(() => _busy = false);
    if (questions.isEmpty) {
      showToast(context, context.l10n.chooseMoreAyahs);
      return;
    }
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => QuizScreen(scope: _scopeLabel(), questions: questions)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final db = ref.watch(quranDbProvider);
    final history = ref.watch(quizHistoryProvider);
    final single = _type == _ScopeType.surahs && _surahs.length == 1 ? db.surah(_surahs.first) : null;
    final range = single == null ? null : (_range ?? RangeValues(1, single.ayahCount.toDouble()));
    final multi = _type != _ScopeType.surahs || _surahs.length > 1;

    return Scaffold(
      body: CustomScrollView(slivers: [
        // A header like every other screen's: the title on the paper, its
        // Arabic name beside it in gold.
        SliverAppBar(
          pinned: true,
          title: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Flexible(child: Text(context.l10n.memorizationTest, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: Space.sm),
            Text('اختبار الحفظ', style: TextStyle(fontFamily: kNaskhFont, fontSize: 16, color: context.colors.goldText)),
          ]),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, 120),
          sliver: SliverList.list(children: [
            _Label(context.l10n.whatToTest),
            Row(children: [
              for (final (t, icon, label) in [
                (_ScopeType.surahs, Icons.list_alt_rounded, context.l10n.surahs),
                (_ScopeType.juz, Icons.grid_view_rounded, context.l10n.juz),
                (_ScopeType.quran, Icons.menu_book_rounded, context.l10n.wholeQuran),
              ]) ...[
                if (t != _ScopeType.surahs) const SizedBox(width: Space.sm),
                Expanded(
                  child: _ScopeCard(
                    icon: icon,
                    label: label,
                    selected: _type == t,
                    onTap: () => setState(() {
                      _type = t;
                      if (!multi) _kinds.remove(QuizKind.whichSurah);
                    }),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: Space.md),
            if (_type == _ScopeType.surahs) ...[
              _Box(
                onTap: _pickSurahs,
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(single?.nameEn ?? context.l10n.surahsCount(_surahs.length), style: context.text.titleMedium),
                      Text(
                        single != null
                            ? context.l10n.ayahsTapForMore(single.ayahCount)
                            : (_surahs.toList()..sort()).map((s) => db.surah(s).nameEn).join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall,
                      ),
                    ]),
                  ),
                  if (single != null)
                    Text(single.nameAr, style: TextStyle(fontFamily: kQuranFont, fontSize: 24, color: c.ink)),
                  const SizedBox(width: Space.sm),
                  Icon(Icons.edit_rounded, color: c.inkMuted, size: 20),
                ]),
              ),
              if (single != null && single.ayahCount > 3) ...[
                const SizedBox(height: Space.md),
                Text(context.l10n.ayahsRange(range!.start.round(), range.end.round()), style: context.text.titleSmall),
                RangeSlider(
                  values: range,
                  min: 1,
                  max: single.ayahCount.toDouble(),
                  divisions: single.ayahCount - 1,
                  labels: RangeLabels('${range.start.round()}', '${range.end.round()}'),
                  onChanged: (v) {
                    if (v.end - v.start >= 2) setState(() => _range = v);
                  },
                ),
              ],
            ],
            if (_type == _ScopeType.juz)
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (var i = 1; i <= 30; i++)
                  SizedBox(
                    width: 52,
                    child: FilterChip(
                      showCheckmark: false,
                      label: SizedBox(width: double.infinity, child: Text('$i', textAlign: TextAlign.center)),
                      selected: _juz.contains(i),
                      onSelected: (on) => setState(() {
                        if (on) {
                          _juz.add(i);
                        } else if (_juz.length > 1) {
                          _juz.remove(i);
                        }
                      }),
                    ),
                  ),
              ]),
            if (_type == _ScopeType.quran)
              Text(context.l10n.wholeQuranQuizNote,
                  style: context.text.bodyMedium?.copyWith(color: c.inkMuted)),
            _Label(context.l10n.questions),
            for (final k in QuizKind.values)
              if (k != QuizKind.whichSurah || multi)
                _KindTile(
                  kind: k,
                  selected: _kinds.contains(k),
                  onTap: () => setState(() {
                    if (_kinds.contains(k)) {
                      if (_kinds.length > 1) _kinds.remove(k);
                    } else {
                      _kinds.add(k);
                    }
                  }),
                ),
            _Label(context.l10n.howMany),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 10, label: Text('10')),
                ButtonSegment(value: 20, label: Text('20')),
                ButtonSegment(value: 30, label: Text('30')),
              ],
              selected: {_count},
              onSelectionChanged: (v) => setState(() => _count = v.first),
            ),
            if (history.isNotEmpty) ...[
              _Label(context.l10n.recent),
              for (final r in history.take(5))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: r.score * 10 >= r.total * 8 ? c.primarySoft : c.surfaceAlt,
                    child: Text('${(100 * r.score / r.total).round()}',
                        style: context.text.labelLarge?.copyWith(color: c.primary)),
                  ),
                  title: Text(r.scope),
                  subtitle: Text(_ago(r.at)),
                  trailing: Text(context.l10n.scoreOfTotal(r.score, r.total), style: context.text.titleMedium),
                ),
            ],
          ]),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.md),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            onPressed: _busy ? null : _start,
            icon: _busy
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.play_arrow_rounded),
            label: Text(context.l10n.startScope(_scopeLabel()), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 2) return l10n.justNow;
    if (d.inHours < 1) return l10n.minutesAgo(d.inMinutes);
    if (d.inDays < 1) return l10n.hoursAgo(d.inHours);
    if (d.inDays == 1) return l10n.yesterday;
    return l10n.daysAgo(d.inDays);
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Space.xl, bottom: Space.sm),
        child: Text(text.toUpperCase(), style: context.text.labelSmall?.copyWith(color: context.colors.primary)),
      );
}

class _ScopeCard extends StatelessWidget {
  const _ScopeCard({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.primary : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: selected ? c.primary : c.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.md),
          child: Column(children: [
            Icon(icon, color: selected ? c.onPrimary : c.primary),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: context.text.labelLarge?.copyWith(color: selected ? c.onPrimary : c.ink)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _KindTile extends StatelessWidget {
  const _KindTile({required this.kind, required this.selected, required this.onTap});
  final QuizKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final icon = switch (kind) {
      QuizKind.nextAyah => Icons.arrow_back_rounded, // Arabic reads right to left: next is to the left
      QuizKind.previousAyah => Icons.arrow_forward_rounded,
      QuizKind.completeAyah => Icons.short_text_rounded,
      QuizKind.missingWord => Icons.space_bar_rounded,
      QuizKind.whichSurah => Icons.travel_explore_rounded,
      QuizKind.recite => Icons.record_voice_over_rounded,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Material(
        color: selected ? c.primarySoft : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: selected ? c.primary.withValues(alpha: 0.4) : c.divider),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Space.md),
            child: Row(children: [
              Icon(icon, color: selected ? c.primary : c.inkMuted),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(kind.title, style: context.text.titleMedium),
                  Text(kind.description, style: context.text.bodySmall),
                ]),
              ),
              Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: selected ? c.primary : c.inkFaint),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Choose one or more surahs, with search.
class _SurahPicker extends ConsumerStatefulWidget {
  const _SurahPicker({required this.initial});
  final Set<int> initial;

  @override
  ConsumerState<_SurahPicker> createState() => _SurahPickerState();
}

class _SurahPickerState extends ConsumerState<_SurahPicker> {
  late final _picked = {...widget.initial};
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final surahs = ref.watch(quranDbProvider).surahs.where((s) {
      if (_q.isEmpty) return true;
      return s.nameEn.toLowerCase().contains(_q.toLowerCase()) || s.nameAr.contains(_q) || '${s.id}' == _q;
    }).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.sm),
          child: Row(children: [
            Expanded(child: Text(context.l10n.chooseSurahs, style: context.text.titleLarge)),
            TextButton(onPressed: () => setState(_picked.clear), child: Text(context.l10n.clear)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          child: TextField(
            onChanged: (v) => setState(() => _q = v.trim()),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: context.l10n.search),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: surahs.length,
            itemBuilder: (_, i) {
              final s = surahs[i];
              return CheckboxListTile(
                value: _picked.contains(s.id),
                onChanged: (on) => setState(() => on == true ? _picked.add(s.id) : _picked.remove(s.id)),
                secondary: SizedBox(width: 30, child: Text('${s.id}', style: context.text.bodySmall)),
                title: Text(s.nameEn),
                subtitle: Text(context.l10n.ayahsCount(s.ayahCount)),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.md),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: c.primary),
              onPressed: _picked.isEmpty ? null : () => Navigator.pop(context, _picked),
              child: Text(_picked.isEmpty ? context.l10n.chooseAtLeastOne : context.l10n.doneSelected(_picked.length)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg), side: cardSide(c)),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.lg),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(Space.lg), child: child),
      ),
    );
  }
}

// =============================================================================
// The test
// =============================================================================

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.scope, required this.questions});
  final String scope;
  final List<QuizQuestion> questions;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _index = 0;
  final _correct = <int, bool>{};
  int? _chosen;
  int _revealed = 0;
  bool _finished = false;

  QuizQuestion get _q => widget.questions[_index];
  bool get _answered => _correct.containsKey(_index);

  void _answer(bool right) {
    HapticFeedback.selectionClick();
    setState(() => _correct[_index] = right);
  }

  Future<void> _next() async {
    if (_index + 1 < widget.questions.length) {
      setState(() {
        _index++;
        _chosen = null;
        _revealed = 0;
      });
      return;
    }
    final score = _correct.values.where((v) => v).length;
    await ref.read(quizHistoryProvider.notifier).add(QuizResult(widget.scope, score, widget.questions.length, DateTime.now()));
    setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return _Results(scope: widget.scope, questions: widget.questions, correct: _correct);
    final c = context.colors;
    final db = ref.watch(quranDbProvider);
    final total = widget.questions.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scope),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_index + (_answered ? 1 : 0)) / total,
            minHeight: 4,
            color: c.primary,
            backgroundColor: c.divider,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.gutter, Space.xl),
              children: [
                Row(children: [
                  Text(context.l10n.questionOf(_index + 1, total), style: context.text.labelSmall),
                  const Spacer(),
                  Pill(_q.kind.title, color: c.primary),
                ]),
                const SizedBox(height: Space.md),
                Text(_q.kind.ask, style: context.text.titleLarge),
                const SizedBox(height: Space.lg),
                if (_q.prompt.isNotEmpty || _q.kind != QuizKind.missingWord)
                  _QuranCard(
                    text: _q.prompt,
                    label: _q.promptRef == null ? null : '${db.surah(_q.promptRef!.surah).nameEn} ${_q.promptRef}',
                  ),
                const SizedBox(height: Space.lg),
                if (_q.isChoice) ..._choices(context),
                if (_q.kind == QuizKind.recite) _recite(context),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.md),
            child: _bottomButton(context),
          ),
        ]),
      ),
    );
  }

  Widget _bottomButton(BuildContext context) {
    final last = _index + 1 == widget.questions.length;
    if (_answered) {
      return FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: _next,
        child: Text(last ? context.l10n.seeResults : context.l10n.next),
      );
    }
    if (_q.kind == QuizKind.recite) {
      if (_revealed < _q.words.length) {
        return Row(children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: () => setState(() => _revealed++),
              child: Text(context.l10n.nextWord),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: () => setState(() => _revealed = _q.words.length),
              child: Text(context.l10n.showAyah),
            ),
          ),
        ]);
      }
      return Row(children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => _answer(false),
            child: Text(context.l10n.iMadeMistakes),
          ),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => _answer(true),
            child: Text(context.l10n.iHadItRight),
          ),
        ),
      ]);
    }
    return const SizedBox(height: 52);
  }

  List<Widget> _choices(BuildContext context) {
    final c = context.colors;
    final quran = _q.kind != QuizKind.whichSurah;
    return [
      for (var i = 0; i < _q.options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: Space.md),
          child: _OptionCard(
            text: _q.options[i],
            quran: quran,
            state: !_answered
                ? _OptionState.idle
                : i == _q.answer
                    ? _OptionState.right
                    : i == _chosen
                        ? _OptionState.wrong
                        : _OptionState.faded,
            onTap: _answered
                ? null
                : () {
                    _chosen = i;
                    _answer(i == _q.answer);
                  },
          ),
        ),
      if (_answered)
        Text(
          _correct[_index]! ? context.l10n.correct : context.l10n.rightAnswerHighlighted,
          textAlign: TextAlign.center,
          style: context.text.titleMedium?.copyWith(color: _correct[_index]! ? c.primary : c.danger),
        ),
    ];
  }

  Widget _recite(BuildContext context) {
    final c = context.colors;
    final q = _q;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(context.l10n.reciteThenReveal, style: context.text.bodySmall),
      const SizedBox(height: Space.sm),
      Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: cardBorder(c),
            boxShadow: cardShadow(c),
        ),
        child: _revealed == 0
            ? Center(child: Icon(Icons.visibility_off_outlined, color: c.inkFaint))
            : Text(
                q.words.take(_revealed).join(' '),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: kQuranFont, fontSize: 25, height: 1.9, color: c.ink),
              ),
      ),
      if (_answered)
        Padding(
          padding: const EdgeInsets.only(top: Space.lg),
          child: Text(
            _correct[_index]! ? context.l10n.wellDone : context.l10n.keepRevisingAyah,
            textAlign: TextAlign.center,
            style: context.text.titleMedium?.copyWith(color: _correct[_index]! ? c.primary : c.inkMuted),
          ),
        ),
    ]);
  }
}

class _QuranCard extends StatelessWidget {
  const _QuranCard({required this.text, this.label});
  final String text;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final parts = text.split(QuizBuilder.blank);
    final style = TextStyle(fontFamily: kQuranFont, fontSize: 25, height: 1.9, color: c.ink);
    return Container(
      padding: const EdgeInsets.all(Space.xl),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: cardBorder(c),
            boxShadow: cardShadow(c),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text.rich(
          TextSpan(children: [
            for (var i = 0; i < parts.length; i++) ...[
              TextSpan(text: parts[i]),
              if (i < parts.length - 1)
                TextSpan(
                  text: ' ـــــ ',
                  style: style.copyWith(color: c.primary, fontWeight: FontWeight.bold),
                ),
            ],
          ]),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: style,
        ),
        if (label != null) ...[
          const SizedBox(height: Space.sm),
          Text(label!, textAlign: TextAlign.center, style: context.text.labelSmall?.copyWith(color: c.goldText)),
        ],
      ]),
    );
  }
}

enum _OptionState { idle, right, wrong, faded }

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.text, required this.quran, required this.state, this.onTap});
  final String text;
  final bool quran;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, border) = switch (state) {
      _OptionState.idle => (c.surface, c.divider),
      _OptionState.right => (c.primarySoft, c.primary),
      _OptionState.wrong => (c.danger.withValues(alpha: 0.1), c.danger),
      _OptionState.faded => (c.surface, c.divider),
    };
    return AnimatedOpacity(
      duration: Motion.quick,
      opacity: state == _OptionState.faded ? 0.5 : 1,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: border, width: state == _OptionState.idle ? 1 : 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
            child: Row(children: [
              if (state == _OptionState.right) Icon(Icons.check_circle_rounded, color: c.primary),
              if (state == _OptionState.wrong) Icon(Icons.cancel_rounded, color: c.danger),
              Expanded(
                child: Text(
                  text,
                  textDirection: quran ? TextDirection.rtl : null,
                  textAlign: TextAlign.center,
                  style: quran
                      ? TextStyle(fontFamily: kQuranFont, fontSize: 22, height: 1.8, color: c.ink)
                      : context.text.titleMedium,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.scope, required this.questions, required this.correct});
  final String scope;
  final List<QuizQuestion> questions;
  final Map<int, bool> correct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final db = ref.watch(quranDbProvider);
    final score = correct.values.where((v) => v).length;
    final total = questions.length;
    final wrong = [for (var i = 0; i < total; i++) if (correct[i] != true) questions[i]];
    final ratio = total == 0 ? 0.0 : score / total;
    final message = ratio == 1
        ? context.l10n.resultPerfect
        : ratio >= 0.8
            ? context.l10n.resultVeryGood
            : ratio >= 0.5
                ? context.l10n.resultGood
                : context.l10n.resultRevise;
    return Scaffold(
      appBar: AppBar(title: Text(scope), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.xl, Space.gutter, 120),
        children: [
          Center(
            child: SizedBox.square(
              dimension: 148,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: ratio,
                    strokeWidth: 10,
                    color: c.primary,
                    backgroundColor: c.divider,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$score', style: context.text.displaySmall),
                  Text(context.l10n.ofTotal(total), style: context.text.bodySmall),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: Space.lg),
          Text(message, textAlign: TextAlign.center, style: context.text.titleMedium),
          if (wrong.isNotEmpty) ...[
            const SizedBox(height: Space.xxl),
            Text(context.l10n.toRevise, style: context.text.titleMedium),
            const SizedBox(height: Space.sm),
            for (final q in wrong)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.md),
                child: Material(
                  color: c.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.lg), side: cardSide(c)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Radii.lg),
                    onTap: () async {
                      final page = await db.pageOf(q.ayah.ref);
                      if (context.mounted) context.openReader(page, ayah: q.ayah.ref.toString());
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(Space.lg),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(children: [
                          Text('${db.surah(q.ayah.ref.surah).nameEn} ${q.ayah.ref}',
                              style: context.text.labelSmall?.copyWith(color: c.goldText)),
                          const Spacer(),
                          Text(q.kind.title, style: context.text.labelSmall),
                        ]),
                        const SizedBox(height: Space.sm),
                        Text(
                          q.ayah.plainText,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: kQuranFont, fontSize: 22, height: 1.8, color: c.ink),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.md),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.done),
              ),
            ),
            if (wrong.isNotEmpty) ...[
              const SizedBox(width: Space.md),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => QuizScreen(scope: scope, questions: [...wrong]..shuffle()),
                  )),
                  child: Text(context.l10n.practiseMistakes),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
