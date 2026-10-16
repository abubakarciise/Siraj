import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/audio/speech.dart';

void main() {
  test('short text is one chunk', () {
    expect(Speech.chunks('قال رسول الله ﷺ'), ['قال رسول الله ﷺ']);
    expect(Speech.chunks('   '), isEmpty);
  });

  test('long text splits on sentence ends and keeps every word', () {
    final sentence = List.filled(30, 'كلمة').join(' ');
    final text = List.filled(20, '$sentence.').join(' ');
    final chunks = Speech.chunks(text, max: 400);
    expect(chunks.every((c) => c.length <= 400), isTrue);
    expect(chunks.join(' ').split(' ').where((w) => w.isNotEmpty).length, text.split(' ').length);
  });
}
