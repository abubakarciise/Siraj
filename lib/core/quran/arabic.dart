final _marks = RegExp(r'[ؐ-ًؚ-ٰٟۖ-ۭـ]');
final _alef = RegExp('[أإآٱ]');
final _spaces = RegExp(r'\s+');
final _arabicChar = RegExp(r'[؀-ۿ]');

/// Must match tool/build_quran_db.py `normalize_arabic`.
String normalizeArabic(String s) => s
    .replaceAll(_marks, '')
    .replaceAll(_alef, 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي')
    .replaceAll(_spaces, ' ')
    .trim();

bool isArabic(String s) => _arabicChar.hasMatch(s);

const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

String toArabicDigits(int n) => n.toString().split('').map((d) => _arabicDigits[int.parse(d)]).join();
