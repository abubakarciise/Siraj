import 'package:go_router/go_router.dart';

import '../core/quran/quran_db.dart';
import '../core/reminders/reminders.dart';

/// Opens what a reminder points to. Payloads: `adhkar:<id>`, `prayer`,
/// `ayah:<s>:<a>`, `surah:<n>`, `hadith:<book>:<number>`, `sunnah:<index>`.
Future<void> openPayload(GoRouter router, QuranDb db, String payload) async {
  final i = payload.indexOf(':');
  final kind = i < 0 ? payload : payload.substring(0, i);
  final rest = i < 0 ? '' : payload.substring(i + 1);
  switch (kind) {
    case 'adhkar':
      router.push('/adhkar/$rest');
    case 'prayer':
      router.push('/prayer');
    case 'ayah':
      final a = rest.toAyahRef();
      if (a != null) router.push('/read/${await db.pageOf(a)}?ayah=$a&surah=${a.surah}');
    case 'surah':
      final s = int.tryParse(rest);
      if (s != null && s >= 1 && s <= 114) router.push('/read/${db.surah(s).pageStart}?surah=$s');
    case 'hadith':
      router.push('/hadith/${rest.replaceFirst(':', '/n/')}');
    case 'sunnah':
      router.push('/sunnah/$rest');
  }
}
