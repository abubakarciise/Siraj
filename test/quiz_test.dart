import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/memorize/quiz.dart';
import 'package:quran_app/core/quran/models.dart';

/// A small "surah" in the style of Ar-Rahman: one ayah repeats word for word.
List<Ayah> _scope() {
  const texts = [
    'ٱلرَّحۡمَٰنُ',
    'عَلَّمَ ٱلۡقُرۡءَانَ',
    'خَلَقَ ٱلۡإِنسَٰنَ',
    'عَلَّمَهُ ٱلۡبَيَانَ',
    'ٱلشَّمۡسُ وَٱلۡقَمَرُ بِحُسۡبَانٖ',
    'وَٱلنَّجۡمُ وَٱلشَّجَرُ يَسۡجُدَانِ',
    'فَبِأَيِّ ءَالَآءِ رَبِّكُمَا تُكَذِّبَانِ',
    'وَٱلسَّمَآءَ رَفَعَهَا وَوَضَعَ ٱلۡمِيزَانَ',
    'أَلَّا تَطۡغَوۡاْ فِي ٱلۡمِيزَانِ',
    'وَأَقِيمُواْ ٱلۡوَزۡنَ بِٱلۡقِسۡطِ وَلَا تُخۡسِرُواْ ٱلۡمِيزَانَ',
    'فَبِأَيِّ ءَالَآءِ رَبِّكُمَا تُكَذِّبَانِ',
    'وَٱلۡأَرۡضَ وَضَعَهَا لِلۡأَنَامِ فِيهَا فَٰكِهَةٞ وَٱلنَّخۡلُ ذَاتُ ٱلۡأَكۡمَامِ',
  ];
  return [
    for (var i = 0; i < texts.length; i++)
      Ayah(id: i + 1, ref: AyahRef(55, i + 1), page: 531, juz: 27, text: '${texts[i]} ${i + 1}'),
  ];
}

void main() {
  test('options are distinct and the answer is among them', () {
    for (var seed = 0; seed < 30; seed++) {
      final b = QuizBuilder(_scope(), random: Random(seed), surahName: (_) => 'Ar-Rahman');
      for (final q in b.build(20, QuizKind.values.toSet())) {
        if (!q.isChoice) continue;
        final norm = q.options.map(QuizBuilder.norm).toSet();
        expect(norm.length, q.options.length, reason: '${q.kind} has duplicate options');
        expect(q.answer, inInclusiveRange(0, q.options.length - 1));
      }
    }
  });

  test('a repeated ayah is never the prompt of next/previous', () {
    final b = QuizBuilder(_scope(), random: Random(1), surahName: (_) => 'Ar-Rahman');
    final repeated = QuizBuilder.norm('فَبِأَيِّ ءَالَآءِ رَبِّكُمَا تُكَذِّبَانِ');
    for (final q in b.build(60, {QuizKind.nextAyah, QuizKind.previousAyah})) {
      expect(QuizBuilder.norm(q.prompt), isNot(repeated));
    }
  });

  test('next ayah: the right option is the following ayah', () {
    final scope = _scope();
    final b = QuizBuilder(scope, random: Random(2), surahName: (_) => 'Ar-Rahman');
    for (final q in b.build(20, {QuizKind.nextAyah})) {
      final shown = scope.indexWhere((a) => a.ref == q.promptRef);
      expect(q.ayah.ref, scope[shown + 1].ref);
      expect(q.options[q.answer], startsWith(QuizBuilder.wordsOf(q.ayah).first));
    }
  });

  test('missing word: putting the answer back gives the ayah', () {
    final b = QuizBuilder(_scope(), random: Random(3), surahName: (_) => 'Ar-Rahman');
    for (final q in b.build(20, {QuizKind.missingWord})) {
      expect(q.prompt.replaceFirst(QuizBuilder.blank, q.options[q.answer]), q.ayah.plainText);
    }
  });

  test('arrange: shuffled order differs, the right order is accepted', () {
    final b = QuizBuilder(_scope(), random: Random(4), surahName: (_) => 'Ar-Rahman');
    for (final q in b.build(20, {QuizKind.arrange})) {
      expect(QuizBuilder.arrangedRight(q, q.shuffled), isFalse);
      expect(QuizBuilder.arrangedRight(q, List.generate(q.words.length, (i) => i)), isTrue);
    }
  });

  test('which surah needs more than one surah in scope', () {
    final b = QuizBuilder(_scope(), surahName: (_) => 'Ar-Rahman');
    expect(b.available(), isNot(contains(QuizKind.whichSurah)));
  });
}
