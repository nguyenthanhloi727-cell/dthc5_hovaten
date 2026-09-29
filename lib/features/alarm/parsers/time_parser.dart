import 'en_time_parser.dart';
import 'fr_time_parser.dart';
import 'vi_time_parser.dart';

/// Giờ:phút đã hiểu được từ câu nói.
class ParsedTime {
  final int hour;
  final int minute;

  const ParsedTime(this.hour, this.minute);

  @override
  bool operator ==(Object other) =>
      other is ParsedTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Buổi trong ngày nói kèm giờ (sáng/chiều, am/pm...).
enum DayPeriod { none, am, noon, pm, night }

/// Parser giờ cho 1 ngôn ngữ. Mỗi ngôn ngữ có quy tắc đọc số và cách nói giờ
/// riêng nên được viết thành class riêng.
abstract class TimeParser {
  const TimeParser();

  /// Mã locale của speech_to_text, vd `vi_VN`.
  String get localeId;

  /// Tên hiển thị trong dropdown.
  String get displayName;

  /// Ví dụ câu nói để gợi ý cho người dùng.
  List<String> get examples;

  /// Trả về null nếu không hiểu được.
  ParsedTime? parse(String input);

  static const all = <TimeParser>[
    ViTimeParser(),
    EnTimeParser(),
    FrTimeParser(),
  ];

  static TimeParser forLocale(String localeId) =>
      all.firstWhere((p) => p.localeId == localeId, orElse: () => all.first);
}

/// Gộp các từ chỉ số liên tiếp thành chữ số, vd "hai mươi lăm" -> "25",
/// "twenty five" -> "25". Dùng chung cho các parser.
String collapseNumberWords(
  String text, {
  required Map<String, int> words,
  String? tensMultiplier,
  int minTens = 20,
}) {
  final tokens = text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  int? value(String t) => int.tryParse(t) ?? words[t];

  final out = <String>[];
  var i = 0;
  while (i < tokens.length) {
    var v = value(tokens[i]);
    if (v == null) {
      out.add(tokens[i]);
      i++;
      continue;
    }
    // "hai mươi" -> 20
    if (tensMultiplier != null &&
        v > 0 &&
        v < 10 &&
        i + 1 < tokens.length &&
        tokens[i + 1] == tensMultiplier) {
      v *= 10;
      i++;
    }
    // "hai mươi lăm" / "twenty five" / "dix sept" -> hàng chục + đơn vị
    if (v % 10 == 0 && v >= minTens && v < 100 && i + 1 < tokens.length) {
      final u = value(tokens[i + 1]);
      final nextIsMultiplier =
          i + 2 < tokens.length && tokens[i + 2] == tensMultiplier;
      if (u != null && u > 0 && u < 10 && !nextIsMultiplier) {
        v += u;
        i++;
      }
    }
    out.add('$v');
    i++;
  }
  return out.join(' ');
}

/// Chuẩn hóa chung: chữ thường, bỏ dấu câu (giữ ":"), tách "7h30" -> "7 h 30".
String normalizeBasic(String input) {
  var s = input.toLowerCase().trim();
  s = s.replaceAll(RegExp(r'[,!?;"“”]'), ' ');
  s = s.replaceAll(RegExp(r'\.(?!\d)'), ' ');
  s = s.replaceAllMapped(
    RegExp(r'(\d)\s*h\s*(\d)'),
    (m) => '${m[1]} h ${m[2]}',
  );
  s = s.replaceAllMapped(RegExp(r'(\d)h(?![a-z])'), (m) => '${m[1]} h');
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s.trim();
}

/// Đổi giờ 12h + buổi sang giờ 24h. Trả null nếu không hợp lệ.
ParsedTime? buildTime(int hour, int minute, DayPeriod period) {
  var h = hour;
  switch (period) {
    case DayPeriod.am:
      if (h == 12) h = 0;
    case DayPeriod.noon:
      if (h >= 1 && h <= 5) h += 12;
    case DayPeriod.pm:
      if (h < 12) h += 12;
    case DayPeriod.night:
      if (h == 12) {
        h = 0;
      } else if (h >= 6 && h < 12) {
        h += 12;
      }
    case DayPeriod.none:
      break;
  }
  if (h == 24 && minute == 0) h = 0;
  if (h < 0 || h > 23 || minute < 0 || minute > 59) return null;
  return ParsedTime(h, minute);
}

/// "8 giờ kém 15" -> 7:45
ParsedTime? minus(int hour, int minutesBefore, DayPeriod period) {
  if (minutesBefore <= 0 || minutesBefore >= 60) return null;
  // Áp dụng buổi cho giờ gốc rồi mới trừ, để "9 giờ kém 15 tối" = 20:45.
  final base = buildTime(hour, 0, period);
  if (base == null) return null;
  final t = (base.hour * 60 - minutesBefore + 24 * 60) % (24 * 60);
  return ParsedTime(t ~/ 60, t % 60);
}
