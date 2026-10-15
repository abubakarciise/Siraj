import '../quran/arabic.dart';
import '../quran/models.dart';

/// Estimates which ayah is being recited when a recitation has no timing
/// data: recitation time is roughly proportional to the number of letters,
/// plus a short pause after each ayah and the opening basmala.
class SurahPace {
  SurahPace(int surah, List<Ayah> ayahs) {
    final intro = surah == 1 || surah == 9 ? 0.0 : 28.0;
    var total = intro;
    final ends = <double>[];
    for (final a in ayahs) {
      total += normalizeArabic(a.plainText).replaceAll(' ', '').length + 5;
      ends.add(total);
    }
    _introEnd = total == 0 ? 0 : intro / total;
    _ends = [for (final e in ends) total == 0 ? 0 : e / total];
  }

  late final double _introEnd;
  late final List<double> _ends;

  /// Ayah number at [fraction] (0..1) of the audio; 0 while in the basmala intro.
  int ayahAt(double fraction) {
    if (fraction < _introEnd) return 0;
    var lo = 0, hi = _ends.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_ends[mid] <= fraction) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo + 1;
  }

  /// Fraction of the audio where [ayah] starts.
  double startOf(int ayah) => ayah <= 1 ? _introEnd : _ends[ayah - 2];
}
