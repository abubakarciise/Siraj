import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/features/daily/tasbih_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('tasbih counts are kept by day and by dhikr', () async {
    SharedPreferences.setMockInitialValues({});
    final log = TasbihLog(await SharedPreferences.getInstance());
    final day = DateTime(2026, 10, 17, 9);
    for (var i = 0; i < 33; i++) {
      log.add(0, at: day);
    }
    log.add(4, at: day);
    log.add(4, at: DateTime(2026, 10, 16, 22));
    expect(log.onDay(DateTime(2026, 10, 17)), 34);
    expect(log.onDay(DateTime(2026, 10, 16)), 1);
    expect(log.read()['2026-10-17'], {'0': 33, '4': 1});
  });
}
