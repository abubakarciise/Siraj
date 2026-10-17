/// Immutable content models backed by assets/db/quran.db.
library;

class Surah {
  const Surah({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.meaning,
    required this.isMakki,
    required this.ayahCount,
    required this.pageStart,
    required this.pageEnd,
  });

  final int id;
  final String nameAr, nameEn, meaning;
  final bool isMakki;
  final int ayahCount, pageStart, pageEnd;

  bool get hasBasmala => id != 1 && id != 9;
}

class AyahRef {
  const AyahRef(this.surah, this.ayah);
  final int surah, ayah;

  @override
  bool operator ==(Object other) => other is AyahRef && other.surah == surah && other.ayah == ayah;
  @override
  int get hashCode => surah * 1000 + ayah;
  @override
  String toString() => '$surah:$ayah';
}

class Ayah {
  const Ayah({required this.id, required this.ref, required this.page, required this.juz, required this.text});
  final int id;
  final AyahRef ref;
  final int page, juz;

  /// KFGQPC Hafs text including the ayah-number glyph at the end.
  final String text;

  /// Text without the trailing ayah number (for share / copy / headers).
  String get plainText => text.replaceAll(RegExp(r'[ \s]*[٠-٩]+$'), '');
}

class MushafWord {
  const MushafWord(this.surah, this.ayah, this.text, this.isEnd);
  final int surah, ayah;
  final String text;
  final bool isEnd;
  AyahRef get ref => AyahRef(surah, ayah);
}

enum LineType { ayah, surahHeader, basmala }

class MushafLine {
  const MushafLine({required this.number, required this.type, this.surah, this.words = const []});
  final int number;
  final LineType type;
  final int? surah;
  final List<MushafWord> words;
}

class MushafPage {
  const MushafPage({required this.number, required this.lines, required this.juz, required this.surahs});
  final int number;
  final List<MushafLine> lines;
  final int juz;
  final List<int> surahs;

  AyahRef get firstAyah {
    for (final l in lines) {
      if (l.words.isNotEmpty) return l.words.first.ref;
    }
    return const AyahRef(1, 1);
  }

  /// First ayah of [surah] on this page; on a page where a surah begins
  /// mid-page, this skips the end of the previous surah.
  AyahRef firstAyahOf(int surah) {
    for (final l in lines) {
      for (final w in l.words) {
        if (w.surah == surah) return w.ref;
      }
    }
    return firstAyah;
  }
}

class JuzInfo {
  const JuzInfo(this.number, this.page, this.start);
  final int number, page;
  final AyahRef start;
}

class SearchHit {
  const SearchHit({required this.ayah, required this.snippet, required this.isTranslation});
  final Ayah ayah;
  final String snippet;
  final bool isTranslation;
}

const kTotalPages = 604;
