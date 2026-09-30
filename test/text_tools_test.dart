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

  group('detectLanguageCode', () {
    final cases = {
      'Xin chào các bạn, hôm nay trời đẹp quá': 'vi',
      'xin chao cac ban, hom nay troi dep qua nen chung ta di choi nhe': 'vi',
      'I went to the market and it was very crowded': 'en',
      'Je ne sais pas ce que vous voulez dans la vie': 'fr',
      'Ich weiß nicht, was das ist und wer sie sind': 'de',
      'Yo no sé lo que es, pero es muy bonito para mí': 'es',
      'こんにちは、元気ですか': 'ja',
      '안녕하세요 반갑습니다': 'ko',
      '你好，今天天气很好': 'zh',
      'ok': null,
      '12345 67890': null,
    };
    cases.forEach((text, lang) {
      test('"$text" -> $lang', () => expect(detectLanguageCode(text), lang));
    });
  });

  test('letterRatio', () {
    expect(letterRatio('abc'), 1);
    expect(letterRatio('a1'), 0.5);
    expect(letterRatio('   '), 0);
  });
}
