/// Xử lý văn bản trước khi dịch: nối dòng OCR bị ngắt, lọc dòng rác,
/// tách câu. Không phụ thuộc Flutter nên test được bằng unit test.
library;

final _sentenceEnd = RegExp(r'[.!?…:;。！？]["”’)\]]*$');
final _letter = RegExp(r'\p{L}', unicode: true);

/// Tỉ lệ ký tự là chữ cái trong [s] (bỏ khoảng trắng).
double letterRatio(String s) {
  final chars = s.replaceAll(RegExp(r'\s'), '');
  if (chars.isEmpty) return 0;
  return _letter.allMatches(chars).length / chars.length;
}

/// Dòng OCR có vẻ là rác (ký hiệu lộn xộn, 1 ký tự lẻ...).
bool isNoiseLine(String line) {
  final t = line.trim();
  if (t.isEmpty) return true;
  final letters = _letter.allMatches(t).length;
  if (letters == 0) return !RegExp(r'\d').hasMatch(t);
  if (t.length <= 2 && letters < 2) return true;
  final chars = t.replaceAll(RegExp(r'\s'), '');
  final alnum = RegExp(r'[\p{L}\p{N}]', unicode: true).allMatches(chars).length;
  return alnum / chars.length < 0.5;
}

/// Nối các dòng OCR bị ngắt giữa câu thành đoạn văn liền mạch.
/// - Dòng không kết thúc bằng dấu câu -> nối với dòng sau bằng dấu cách.
/// - "trans-" + "lation" -> "translation".
/// - Dòng trống giữ làm ngắt đoạn.
String reflowLines(List<String> lines) {
  final paragraphs = <String>[];
  final buf = StringBuffer();

  void flush() {
    final p = buf.toString().trim();
    if (p.isNotEmpty) paragraphs.add(p);
    buf.clear();
  }

  for (final raw in lines) {
    final line = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (line.isEmpty) {
      flush();
      continue;
    }
    final current = buf.toString();
    if (current.isEmpty) {
      buf.write(line);
    } else if (RegExp(r'\p{L}-$', unicode: true).hasMatch(current)) {
      // Từ bị ngắt bằng gạch nối cuối dòng.
      final joined = current.substring(0, current.length - 1) + line;
      buf
        ..clear()
        ..write(joined);
    } else {
      buf.write(' $line');
    }
    if (_sentenceEnd.hasMatch(line) && line.length < 40) {
      // Dòng ngắn kết thúc bằng dấu câu thường là tiêu đề/ý riêng.
      flush();
    }
  }
  flush();
  return paragraphs.join('\n');
}

/// Tách [text] thành các câu, giữ nguyên ngắt dòng dưới dạng phần tử "\n".
/// Dịch từng câu giúp model offline ít lỗi ngữ pháp hơn so với dịch cả khối
/// dài trộn nhiều câu.
List<String> splitSentences(String text) {
  final out = <String>[];
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isNotEmpty) {
      final matches = RegExp(r'[^.!?…。！？]+(?:[.!?…。！？]+["”’)\]]*|$)\s*')
          .allMatches(line);
      for (final m in matches) {
        final s = m[0]!.trim();
        if (s.isNotEmpty) out.add(s);
      }
    }
    if (i < lines.length - 1) out.add('\n');
  }
  return out;
}

// ---------------------------------------------------------------- đoán ngôn ngữ

/// Ký tự chỉ tiếng Việt mới có (nguyên âm có dấu kiểu Việt, đ, ơ, ư, ă).
final _viChars = RegExp(
  r'[ăâđêôơưạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ]',
  caseSensitive: false,
);
final _hiraKata = RegExp(r'[぀-ヿ]');
final _hangul = RegExp(r'[가-힯ᄀ-ᇿ]');
final _han = RegExp(r'[一-鿿]');

/// Từ phổ biến của từng ngôn ngữ (viết không dấu để bắt cả chữ gõ thiếu dấu).
const _stopwords = <String, Set<String>>{
  'vi': {
    'toi',
    'ban',
    'la',
    'va',
    'cua',
    'khong',
    'co',
    'nhung',
    'cac',
    'mot',
    'nay',
    'duoc',
    'cho',
    'voi',
    'nguoi',
    'chung',
    'ta',
    'di',
    'hom',
    'rat',
    'nhe',
    'roi',
    'thi',
    'se',
    'da',
    'dang',
    'chao',
    'xin',
    'minh',
  },
  'en': {
    'the',
    'and',
    'is',
    'are',
    'you',
    'to',
    'of',
    'in',
    'it',
    'that',
    'was',
    'for',
    'with',
    'this',
    'have',
    'not',
    'what',
    'do',
    'my',
    'your',
    'be',
  },
  'fr': {
    'le',
    'la',
    'les',
    'et',
    'est',
    'une',
    'des',
    'du',
    'je',
    'vous',
    'nous',
    'pas',
    'que',
    'qui',
    'dans',
    'pour',
    'avec',
    'sur',
    'au',
    'ce',
    'il',
  },
  'de': {
    'der',
    'die',
    'das',
    'und',
    'ist',
    'ich',
    'nicht',
    'ein',
    'eine',
    'zu',
    'mit',
    'sie',
    'es',
    'den',
    'auf',
    'für',
    'sind',
    'wir',
    'auch',
    'von',
  },
  'es': {
    'el',
    'los',
    'las',
    'y',
    'es',
    'que',
    'de',
    'en',
    'un',
    'una',
    'por',
    'con',
    'para',
    'no',
    'se',
    'su',
    'lo',
    'como',
    'pero',
    'muy',
    'yo',
  },
};

/// Đoán mã ngôn ngữ (vi, en, fr, de, es, ja, ko, zh) của [text].
/// Trả null nếu quá ngắn hoặc không chắc chắn. Không dùng thư viện ngoài.
String? detectLanguageCode(String text) {
  final t = text.trim();
  if (t.length < 6) return null;
  // Chữ Nhật có kana; chữ Hán không kana thì là tiếng Trung.
  if (_hiraKata.hasMatch(t)) return 'ja';
  if (_hangul.hasMatch(t)) return 'ko';
  if (_han.hasMatch(t)) return 'zh';

  final letters = _letter.allMatches(t).length;
  if (letters == 0) return null;
  if (_viChars.allMatches(t).length / letters > 0.03) return 'vi';

  final words = t
      .toLowerCase()
      .split(RegExp(r'[^\p{L}]+', unicode: true))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.length < 3) return null;
  String? best;
  var bestScore = 0, second = 0;
  _stopwords.forEach((lang, set) {
    final score = words.where(set.contains).length;
    if (score > bestScore) {
      second = bestScore;
      bestScore = score;
      best = lang;
    } else if (score > second) {
      second = score;
    }
  });
  // Cần ít nhất 2 từ khớp và hơn hẳn ngôn ngữ đứng thứ 2.
  if (bestScore < 2 || bestScore == second) return null;
  return best;
}

/// Ghép lại các câu đã dịch (ngược với [splitSentences]).
String joinSentences(List<String> parts) {
  final buf = StringBuffer();
  for (final p in parts) {
    if (p == '\n') {
      buf.write('\n');
    } else {
      final s = buf.toString();
      if (s.isNotEmpty && !s.endsWith('\n')) buf.write(' ');
      buf.write(p);
    }
  }
  return buf.toString();
}
