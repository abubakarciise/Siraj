import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/shell.dart';
import '../../core/memorize/quiz.dart';
import '../../core/providers.dart';
import '../../core/quran/arabic.dart';
import '../../core/quran/models.dart';
import '../../design/dialogs.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';

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

enum _ScopeType { surah, juz }

/// Choose what to test, then start.
class MemorizeScreen extends ConsumerStatefulWidget {
  const MemorizeScreen({super.key});

  @override
  ConsumerState<MemorizeScreen> createState() => _MemorizeScreenState();
}

class _MemorizeScreenState extends ConsumerState<MemorizeScreen> {
  _ScopeType _type = _ScopeType.surah;
  late int _surah = ref.read(lastReadProvider).value?.ref.surah ?? 67;
  int _juz = 30;
  RangeValues? _range;
  int _count = 10;
  final _kinds = {
    QuizKind.nextAyah,
    QuizKind.completeAyah,
    QuizKind.missingWord,
    QuizKind.arrange,
    QuizKind.recite,
  };
  bool _busy = false;

  Future<void> _pickSurah() async {
    final db = ref.read(quranDbProvider);
    final id = await showAppSheet<int>(
      context,
      title: 'Choose a surah',
      builder: (ctx) => SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.6,
        child: ListView.builder(
          itemCount: 114,
          itemBuilder: (_, i) {
            final s = db.surahs[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(width: 32, child: Text('${s.id}', style: ctx.text.bodySmall)),
              title: Text(s.nameEn),
              subtitle: Text('${s.ayahCount} ayahs'),
              trailing: Text(s.nameAr, style: TextStyle(fontFamily: kQuranFont, fontSize: 20, color: ctx.colors.ink)),
              selected: s.id == _surah,
              onTap: () => Navigator.pop(ctx, s.id),
            );
          },
        ),
      ),
    );
    if (id != null) {
      setState(() {
        _surah = id;
        _range = null;
      });
    }
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    final db = ref.read(quranDbProvider);
    List<Ayah> ayahs;
    String scope;
    if (_type == _ScopeType.surah) {
      final all = await db.ayahsOfSurah(_surah);
      final r = _range ?? RangeValues(1, all.length.toDouble());
      ayahs = all.sublist(r.start.round() - 1, r.end.round());
      final s = db.surah(_surah);
      scope = r.start.round() == 1 && r.end.round() == all.length
          ? s.nameEn
          : '${s.nameEn} ${r.start.round()}–${r.end.round()}';
    } else {
      ayahs = await db.ayahsOfJuz(_juz);
      scope = 'Juz $_juz';
    }
    final builder = QuizBuilder(ayahs, surahName: (s) => db.surah(s).nameEn);
    final questions = builder.build(_count, _kinds);
    if (!mounted) return;
    setState(() => _busy = false);
    if (questions.isEmpty) {
      showToast(context, 'Choose more ayahs or another question type');
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuizScreen(scope: scope, questions: questions)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final db = ref.watch(quranDbProvider);
    final surah = db.surah(_surah);
    final range = _range ?? RangeValues(1, surah.ayahCount.toDouble());
    final history = ref.watch(quizHistoryProvider);
    final kinds = _type == _ScopeType.surah ? QuizKind.values.where((k) => k != QuizKind.whichSurah) : QuizKind.values;

    return Scaffold(
      appBar: AppBar(title: const Text('Memorization test')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, 120),
        children: [
          Text('Test what you have memorized, one question at a time.', style: context.text.bodyMedium?.copyWith(color: c.inkMuted)),
          const SizedBox(height: Space.xl),
          SegmentedButton<_ScopeType>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _ScopeType.surah, label: Text('Surah')),
              ButtonSegment(value: _ScopeType.juz, label: Text('Juz')),
            ],
            selected: {_type},
            onSelectionChanged: (v) => setState(() {
              _type = v.first;
              _kinds.remove(QuizKind.whichSurah);
            }),
          ),
          const SizedBox(height: Space.md),
          if (_type == _ScopeType.surah) ...[
            _Box(
              onTap: _pickSurah,
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(surah.nameEn, style: context.text.titleMedium),
                    Text('${surah.ayahCount} ayahs', style: context.text.bodySmall),
                  ]),
                ),
                Text(surah.nameAr, style: TextStyle(fontFamily: kQuranFont, fontSize: 24, color: c.ink)),
                const SizedBox(width: Space.sm),
                Icon(Icons.expand_more_rounded, color: c.inkMuted),
              ]),
            ),
            if (surah.ayahCount > 3) ...[
              const SizedBox(height: Space.md),
              Text('Ayahs ${range.start.round()} – ${range.end.round()}', style: context.text.titleMedium),
              RangeSlider(
                values: range,
                min: 1,
                max: surah.ayahCount.toDouble(),
                divisions: surah.ayahCount - 1,
                labels: RangeLabels('${range.start.round()}', '${range.end.round()}'),
                onChanged: (v) {
                  if (v.end - v.start >= 2) setState(() => _range = v);
                },
              ),
            ],
          ] else
            _Box(
              onTap: () async {
                final j = await showAppSheet<int>(
                  context,
                  title: 'Choose a juz',
                  builder: (ctx) => Wrap(spacing: 8, runSpacing: 8, children: [
                    for (var i = 1; i <= 30; i++)
                      ChoiceChip(label: Text('$i'), selected: i == _juz, onSelected: (_) => Navigator.pop(ctx, i)),
                  ]),
                );
                if (j != null) setState(() => _juz = j);
              },
              child: Row(children: [
                Expanded(child: Text('Juz $_juz', style: context.text.titleMedium)),
                Text('الجزء ${toArabicDigits(_juz)}', style: TextStyle(fontFamily: kNaskhFont, fontSize: 18, color: c.ink)),
                const SizedBox(width: Space.sm),
                Icon(Icons.expand_more_rounded, color: c.inkMuted),
              ]),
            ),
          const SizedBox(height: Space.xl),
          Text('Questions', style: context.text.titleMedium),
          const SizedBox(height: Space.sm),
          for (final k in kinds)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _kinds.contains(k),
              title: Text(k.title),
              subtitle: Text(k.description),
              onChanged: (v) => setState(() {
                if (v == true) {
                  _kinds.add(k);
                } else if (_kinds.length > 1) {
                  _kinds.remove(k);
                }
              }),
            ),
          const SizedBox(height: Space.md),
          Row(children: [
            Expanded(child: Text('How many', style: context.text.titleMedium)),
            for (final n in const [10, 20, 30]) ...[
              const SizedBox(width: Space.sm),
              ChoiceChip(label: Text('$n'), selected: _count == n, onSelected: (_) => setState(() => _count = n)),
            ],
          ]),
          if (history.isNotEmpty) ...[
            const SizedBox(height: Space.xxl),
            Text('Recent', style: context.text.titleMedium),
            for (final r in history.take(5))
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(r.scope),
                subtitle: Text(_ago(r.at)),
                trailing: Text('${r.score} / ${r.total}',
                    style: context.text.titleMedium?.copyWith(color: r.score * 10 >= r.total * 8 ? c.primary : c.ink)),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.md),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: _busy ? null : _start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Start test'),
          ),
        ),
      ),
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 2) return 'Just now';
    if (d.inHours < 1) return '${d.inMinutes} minutes ago';
    if (d.inDays < 1) return '${d.inHours} hours ago';
    if (d.inDays == 1) return 'Yesterday';
    return '${d.inDays} days ago';
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg), side: BorderSide(color: c.divider)),
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
  final _picked = <int>[];
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
        _picked.clear();
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
                  Text('${_index + 1} of $total', style: context.text.labelSmall),
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
                    plain: _q.kind == QuizKind.arrange,
                  ),
                const SizedBox(height: Space.lg),
                if (_q.isChoice) ..._choices(context),
                if (_q.kind == QuizKind.arrange) _arrange(context),
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
        child: Text(last ? 'See results' : 'Next'),
      );
    }
    if (_q.kind == QuizKind.arrange) {
      return FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: _picked.length == _q.words.length ? () => _answer(QuizBuilder.arrangedRight(_q, _picked)) : null,
        child: const Text('Check'),
      );
    }
    if (_q.kind == QuizKind.recite) {
      if (_revealed < _q.words.length) {
        return Row(children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: () => setState(() => _revealed++),
              child: const Text('Next word'),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              onPressed: () => setState(() => _revealed = _q.words.length),
              child: const Text('Show ayah'),
            ),
          ),
        ]);
      }
      return Row(children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => _answer(false),
            child: const Text('I made mistakes'),
          ),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => _answer(true),
            child: const Text('I had it right'),
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
          _correct[_index]! ? 'Correct' : 'The right answer is highlighted',
          textAlign: TextAlign.center,
          style: context.text.titleMedium?.copyWith(color: _correct[_index]! ? c.primary : c.danger),
        ),
    ];
  }

  Widget _arrange(BuildContext context) {
    final c = context.colors;
    final q = _q;
    Widget chip(int k, {required bool picked}) => Padding(
          padding: const EdgeInsets.all(4),
          child: Material(
            color: picked ? c.primarySoft : c.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md), side: BorderSide(color: c.divider)),
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.md),
              onTap: _answered
                  ? null
                  : () => setState(() => picked ? _picked.remove(k) : _picked.add(k)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(q.words[k], style: TextStyle(fontFamily: kQuranFont, fontSize: 24, height: 1.6, color: c.ink)),
              ),
            ),
          ),
        );
    final right = _answered && _correct[_index]!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: !_answered ? c.divider : (right ? c.primary : c.danger), width: _answered ? 2 : 1),
        ),
        child: _picked.isEmpty
            ? Center(child: Text('Tap the words below in order', style: context.text.bodySmall))
            : Directionality(
                textDirection: TextDirection.rtl,
                child: Wrap(children: [for (final k in _picked) chip(k, picked: true)]),
              ),
      ),
      const SizedBox(height: Space.lg),
      Directionality(
        textDirection: TextDirection.rtl,
        child: Wrap(
          alignment: WrapAlignment.center,
          children: [for (final k in q.shuffled) if (!_picked.contains(k)) chip(k, picked: false)],
        ),
      ),
      if (_answered && !right) ...[
        const SizedBox(height: Space.lg),
        Text('The ayah', style: context.text.labelSmall),
        const SizedBox(height: Space.xs),
        _QuranCard(text: q.words.join(' ')),
      ],
      if (_answered && right)
        Padding(
          padding: const EdgeInsets.only(top: Space.lg),
          child: Text('Correct', textAlign: TextAlign.center, style: context.text.titleMedium?.copyWith(color: c.primary)),
        ),
    ]);
  }

  Widget _recite(BuildContext context) {
    final c = context.colors;
    final q = _q;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Recite it, then reveal it word by word to check yourself.', style: context.text.bodySmall),
      const SizedBox(height: Space.sm),
      Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: c.divider),
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
            _correct[_index]! ? 'Well done' : 'Keep revising this ayah',
            textAlign: TextAlign.center,
            style: context.text.titleMedium?.copyWith(color: _correct[_index]! ? c.primary : c.inkMuted),
          ),
        ),
    ]);
  }
}

class _QuranCard extends StatelessWidget {
  const _QuranCard({required this.text, this.label, this.plain = false});
  final String text;
  final String? label;

  /// Arrange questions show a short instruction, not Quran text.
  final bool plain;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (plain) {
      // Arrange: which ayah, and whether only its beginning is asked.
      final parts = [if (label != null) label!, if (text.isNotEmpty) text];
      return Text(parts.join(' · '), style: context.text.bodyMedium?.copyWith(color: c.inkMuted));
    }
    final parts = text.split(QuizBuilder.blank);
    final style = TextStyle(fontFamily: kQuranFont, fontSize: 25, height: 1.9, color: c.ink);
    return Container(
      padding: const EdgeInsets.all(Space.xl),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: c.divider),
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
          Text(label!, textAlign: TextAlign.center, style: context.text.labelSmall?.copyWith(color: c.gold)),
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
        ? 'ما شاء الله · Perfect'
        : ratio >= 0.8
            ? 'Very good, keep revising'
            : ratio >= 0.5
                ? 'Good effort, revise the ayahs below'
                : 'Revise these ayahs and try again';
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
                  Text('of $total', style: context.text.bodySmall),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: Space.lg),
          Text(message, textAlign: TextAlign.center, style: context.text.titleMedium),
          if (wrong.isNotEmpty) ...[
            const SizedBox(height: Space.xxl),
            Text('To revise', style: context.text.titleMedium),
            const SizedBox(height: Space.sm),
            for (final q in wrong)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.md),
                child: Material(
                  color: c.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.lg), side: BorderSide(color: c.divider)),
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
                              style: context.text.labelSmall?.copyWith(color: c.gold)),
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
                child: const Text('Done'),
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
                  child: const Text('Practise mistakes'),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
