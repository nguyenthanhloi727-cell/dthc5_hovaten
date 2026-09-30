import 'package:flutter_test/flutter_test.dart';
import 'package:nguyen_thanh_loi/features/translate/text_tools.dart';

void main() {
  group('reflowLines', () {
    test('nối dòng bị ngắt giữa câu', () {
      expect(
        reflowLines(['The quick brown fox', 'jumps over the lazy', 'dog.']),
        'The quick brown fox jumps over the lazy dog.',
      );
    });

    test('nối từ bị ngắt bằng gạch nối', () {
      expect(
        reflowLines(['This is a trans-', 'lation test.']),
        'This is a translation test.',
      );
    });

    test('dòng trống là ngắt đoạn, tiêu đề ngắn đứng riêng', () {
      expect(
        reflowLines(['Warning:', 'Do not touch the', 'machine.', '', 'Thanks']),
        'Warning:\nDo not touch the machine.\nThanks',
      );
    });
  });

  group('isNoiseLine', () {
    test('lọc ký hiệu lộn xộn', () {
      expect(isNoiseLine('|/_=~'), isTrue);
      expect(isNoiseLine('l'), isTrue);
      expect(isNoiseLine(r'#@%& a'), isTrue);
    });
    test('giữ dòng có chữ hoặc số', () {
      expect(isNoiseLine('Xin chào các bạn'), isFalse);
      expect(isNoiseLine('2026'), isFalse);
      expect(isNoiseLine('Tel: 0900 000'), isFalse);
    });
  });

  group('splitSentences / joinSentences', () {
    test('tách câu và giữ ngắt dòng', () {
      final parts = splitSentences('Hello there. How are you?\nFine!');
      expect(parts, ['Hello there.', 'How are you?', '\n', 'Fine!']);
      expect(joinSentences(parts), 'Hello there. How are you?\nFine!');
    });

    test('câu không có dấu chấm cuối', () {
      expect(splitSentences('no punctuation here'), ['no punctuation here']);
    });

    test('dấu ba chấm và ngoặc kép', () {
      expect(splitSentences('Wait... "Really?" Yes.'), [
        'Wait...',
        '"Really?"',
        'Yes.',
      ]);
    });
  });

  test('letterRatio', () {
    expect(letterRatio('abc'), 1);
    expect(letterRatio('a1'), 0.5);
    expect(letterRatio('   '), 0);
  });
}
