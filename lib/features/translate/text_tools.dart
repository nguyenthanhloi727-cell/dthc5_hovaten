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
