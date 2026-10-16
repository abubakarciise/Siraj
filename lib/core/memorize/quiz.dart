import 'dart:math';

import '../quran/arabic.dart';
import '../quran/models.dart';

/// The kinds of memorization question. Each one exercises a different way a
/// hafiz recalls the Quran: what comes next, what came before, how an ayah
/// ends, an exact word, the order of words, where an ayah belongs, and
/// reciting from memory.
enum QuizKind { nextAyah, previousAyah, completeAyah, missingWord, arrange, whichSurah, recite }

extension QuizKindX on QuizKind {
  String get title => switch (this) {
        QuizKind.nextAyah => 'Next ayah',
        QuizKind.previousAyah => 'Previous ayah',
        QuizKind.completeAyah => 'Complete the ayah',
        QuizKind.missingWord => 'Missing word',
        QuizKind.arrange => 'Arrange the words',
        QuizKind.whichSurah => 'Which surah?',
        QuizKind.recite => 'Recite from memory',
      };

  String get description => switch (this) {
        QuizKind.nextAyah => 'See an ayah and choose the one that follows it',
        QuizKind.previousAyah => 'See an ayah and choose the one before it',
        QuizKind.completeAyah => 'Read the beginning and choose how the ayah ends',
        QuizKind.missingWord => 'One word is hidden; choose it from similar words',
        QuizKind.arrange => 'Tap the words in the right order',
        QuizKind.whichSurah => 'Choose the surah an ayah belongs to',
        QuizKind.recite => 'Recite the next ayah yourself, then reveal and check',
      };

  /// What the question asks, shown above the prompt.
  String get ask => switch (this) {
        QuizKind.nextAyah => 'Which ayah comes next?',
        QuizKind.previousAyah => 'Which ayah comes before this one?',
        QuizKind.completeAyah => 'How does this ayah end?',
        QuizKind.missingWord => 'Which word is missing?',
        QuizKind.arrange => 'Put the words in order',
        QuizKind.whichSurah => 'Which surah is this ayah from?',
        QuizKind.recite => 'Recite the next ayah from memory',
      };
}

class QuizQuestion {
  QuizQuestion({
    required this.kind,
    required this.ayah,
    required this.prompt,
    this.promptRef,
    this.options = const [],
    this.answer = 0,
    this.words = const [],
    this.shuffled = const [],
  });

  final QuizKind kind;

  /// The ayah the answer belongs to (opened in the Mushaf from the review).
  final Ayah ayah;

  /// Quran text shown to the user (may contain the blank marker).
  final String prompt;
  final AyahRef? promptRef;

  /// Multiple choice: the options and the index of the right one.
  final List<String> options;
  final int answer;

  /// Arrange: the words in order, and the order they are offered in.
  /// Recite: the words of the ayah to reveal.
  final List<String> words;
  final List<int> shuffled;

  bool get isChoice => options.isNotEmpty;
}

/// Builds questions from the ayahs of one surah or juz.
///
/// Rules that keep questions fair:
/// - a prompt is never an ayah that appears word-for-word elsewhere in the
///   scope (as in Ar-Rahman), so "what comes next" has one right answer;
/// - options are always distinct after removing diacritics;
/// - distractors come from the same scope, nearest ayahs first, because those
///   are the ones a memorizer actually confuses.
class QuizBuilder {
  QuizBuilder(this.ayahs, {Random? random, required this.surahName}) : rnd = random ?? Random() {
    for (final a in ayahs) {
      final key = norm(a.plainText);
      _count[key] = (_count[key] ?? 0) + 1;
    }
  }

  final List<Ayah> ayahs;
  final Random rnd;
  final String Function(int surah) surahName;
  final _count = <String, int>{};

  static const blank = '⟨ … ⟩';
  static const _optionWords = 9;

  static String norm(String s) => normalizeArabic(s).replaceAll(RegExp(r'[^ء-ي ]'), '').trim();

  static List<String> wordsOf(Ayah a) => a.plainText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  bool _unique(Ayah a) => _count[norm(a.plainText)] == 1;

  /// First words of an ayah, enough to tell it apart from the other options.
  static String _head(Ayah a, [int n = _optionWords]) {
    final w = wordsOf(a);
    return w.length <= n ? w.join(' ') : '${w.take(n).join(' ')} …';
  }

  Set<QuizKind> available() => {
        for (final k in QuizKind.values)
          if (_candidates(k).isNotEmpty) k,
      };

  List<int> _candidates(QuizKind kind) {
    final out = <int>[];
    for (var i = 0; i < ayahs.length; i++) {
      final a = ayahs[i];
      final w = wordsOf(a).length;
      final ok = switch (kind) {
        QuizKind.nextAyah => i + 1 < ayahs.length && ayahs[i + 1].ref.surah == a.ref.surah && _unique(a),
        QuizKind.previousAyah => i > 0 && ayahs[i - 1].ref.surah == a.ref.surah && _unique(a),
        QuizKind.completeAyah => w >= 6,
        QuizKind.missingWord => w >= 4,
        QuizKind.arrange => w >= 3,
        QuizKind.whichSurah => ayahs.first.ref.surah != ayahs.last.ref.surah && w >= 4 && _unique(a),
        QuizKind.recite => i > 0 && ayahs[i - 1].ref.surah == a.ref.surah && _unique(ayahs[i - 1]),
      };
      if (ok) out.add(i);
    }
    return out;
  }

  /// [count] questions of the given [kinds], spread over the scope.
  List<QuizQuestion> build(int count, Set<QuizKind> kinds) {
    final usable = kinds.intersection(available()).toList();
    if (usable.isEmpty) return const [];
    final out = <QuizQuestion>[];
    final used = <String>{};
    var guard = 0;
    while (out.length < count && guard++ < count * 30) {
      final kind = usable[rnd.nextInt(usable.length)];
      final cands = _candidates(kind);
      final i = cands[rnd.nextInt(cands.length)];
      final key = '${kind.name}:$i';
      if (used.contains(key) && used.length < cands.length * usable.length) continue;
      final q = _make(kind, i);
      if (q == null) continue;
      used.add(key);
      out.add(q);
    }
    return out;
  }

  QuizQuestion? _make(QuizKind kind, int i) => switch (kind) {
        QuizKind.nextAyah => _neighbour(i, i + 1, kind),
        QuizKind.previousAyah => _neighbour(i, i - 1, kind),
        QuizKind.completeAyah => _complete(i),
        QuizKind.missingWord => _missing(i),
        QuizKind.arrange => _arrange(i),
        QuizKind.whichSurah => _surah(i),
        QuizKind.recite => _recite(i),
      };

  /// Distractor indexes for ayah [target], nearest first.
  List<int> _nearby(int target, {Set<int> skip = const {}}) {
    final order = <int>[];
    for (var d = 1; d < ayahs.length; d++) {
      for (final j in [target + d, target - d]) {
        if (j >= 0 && j < ayahs.length && j != target && !skip.contains(j)) order.add(j);
      }
      if (order.length > 24) break;
    }
    // Keep the closest few, then mix in some from further away.
    final close = order.take(6).toList()..shuffle(rnd);
    final far = order.skip(6).toList()..shuffle(rnd);
    return [...close.take(2), ...far, ...close.skip(2)];
  }

  QuizQuestion? _choice(QuizKind kind, Ayah ayah, String prompt, AyahRef? ref, String correct, Iterable<String> pool) {
    final seen = {norm(correct)};
    final options = [correct];
    for (final o in pool) {
      if (options.length == 4) break;
      if (seen.add(norm(o))) options.add(o);
    }
    if (options.length < 3) return null;
    options.shuffle(rnd);
    return QuizQuestion(
      kind: kind,
      ayah: ayah,
      prompt: prompt,
      promptRef: ref,
      options: options,
      answer: options.indexOf(correct),
    );
  }

  QuizQuestion? _neighbour(int i, int target, QuizKind kind) {
    final shown = ayahs[i];
    final answer = ayahs[target];
    return _choice(
      kind,
      answer,
      shown.plainText,
      shown.ref,
      _head(answer),
      _nearby(target, skip: {i}).map((j) => _head(ayahs[j])),
    );
  }

  QuizQuestion? _complete(int i) {
    final a = ayahs[i];
    final w = wordsOf(a);
    final cut = (w.length * (0.4 + rnd.nextDouble() * 0.2)).round().clamp(2, w.length - 2);
    final ending = w.sublist(cut);
    final len = ending.length;
    String tail(Ayah b) {
      final bw = wordsOf(b);
      return bw.sublist(max(0, bw.length - len)).join(' ');
    }

    return _choice(
      QuizKind.completeAyah,
      a,
      '${w.take(cut).join(' ')} $blank',
      a.ref,
      ending.join(' '),
      _nearby(i).where((j) => wordsOf(ayahs[j]).length >= len).map((j) => tail(ayahs[j])),
    );
  }

  QuizQuestion? _missing(int i) {
    final a = ayahs[i];
    final w = wordsOf(a);
    final picks = [
      for (var k = 0; k < w.length; k++)
        if (norm(w[k]).replaceAll(' ', '').length >= 3) k,
    ];
    if (picks.isEmpty) return null;
    final k = picks[rnd.nextInt(picks.length)];
    final correct = w[k];
    final length = norm(correct).length;
    // Words of a similar length from the scope; same first letter first.
    final first = norm(correct).isEmpty ? '' : norm(correct)[0];
    final pool = <String>[];
    for (final j in _nearby(i)) {
      for (final x in wordsOf(ayahs[j])) {
        final n = norm(x);
        if ((n.length - length).abs() <= 1 && n.length >= 3) pool.add(x);
      }
      if (pool.length > 60) break;
    }
    pool.shuffle(rnd);
    pool.sort((x, y) => (norm(y).startsWith(first) ? 1 : 0) - (norm(x).startsWith(first) ? 1 : 0));
    final prompt = [for (var m = 0; m < w.length; m++) m == k ? blank : w[m]].join(' ');
    return _choice(QuizKind.missingWord, a, prompt, a.ref, correct, pool);
  }

  QuizQuestion? _arrange(int i) {
    final a = ayahs[i];
    final all = wordsOf(a);
    // Long ayahs: arrange the first part only (up to 7 words).
    final words = all.length <= 8 ? all : all.take(7).toList();
    final order = List.generate(words.length, (k) => k);
    for (var tries = 0; tries < 6; tries++) {
      order.shuffle(rnd);
      if (!_sameText(words, order)) break;
    }
    if (_sameText(words, order)) return null;
    return QuizQuestion(
      kind: QuizKind.arrange,
      ayah: a,
      prompt: words.length < all.length ? 'its first ${words.length} words' : '',
      promptRef: a.ref,
      words: words,
      shuffled: List.of(order),
    );
  }

  bool _sameText(List<String> words, List<int> order) =>
      [for (final k in order) norm(words[k])].join(' ') == words.map(norm).join(' ');

  /// Whether [picked] (indexes into [QuizQuestion.words]) spells the ayah;
  /// repeated words may be picked in either order.
  static bool arrangedRight(QuizQuestion q, List<int> picked) =>
      picked.length == q.words.length && [for (final k in picked) norm(q.words[k])].join(' ') == q.words.map(norm).join(' ');

  QuizQuestion? _surah(int i) {
    final a = ayahs[i];
    final surahs = {for (final x in ayahs) x.ref.surah}.toList()..shuffle(rnd);
    // Neighbouring surahs are the realistic confusion.
    final others = surahs.where((s) => s != a.ref.surah).toList()
      ..sort((x, y) => (x - a.ref.surah).abs() - (y - a.ref.surah).abs());
    return _choice(
      QuizKind.whichSurah,
      a,
      a.plainText,
      null,
      surahName(a.ref.surah),
      [...others.take(3), ...others.skip(3)].map(surahName),
    );
  }

  QuizQuestion? _recite(int i) {
    final before = ayahs[i - 1];
    final a = ayahs[i];
    return QuizQuestion(
      kind: QuizKind.recite,
      ayah: a,
      prompt: before.plainText,
      promptRef: before.ref,
      words: wordsOf(a),
    );
  }
}
