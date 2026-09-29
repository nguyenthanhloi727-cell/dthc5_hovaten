import 'time_parser.dart';

/// Hiểu các câu: "7 giờ 30 sáng", "bảy giờ rưỡi", "8 giờ kém 15",
/// "hai mươi mốt giờ", "9 giờ tối", "nửa đêm", "6h15".
class ViTimeParser extends TimeParser {
  const ViTimeParser();

  @override
  String get localeId => 'vi_VN';

  @override
  String get displayName => 'Tiếng Việt';

  @override
  List<String> get examples => const [
    '7 giờ 30 sáng',
    'bảy giờ rưỡi tối',
    '8 giờ kém 15',
    '21 giờ 5 phút',
  ];

  static const _words = {
    'không': 0,
    'một': 1,
    'mốt': 1,
    'hai': 2,
    'ba': 3,
    'bốn': 4,
    'tư': 4,
    'năm': 5,
    'lăm': 5,
    'sáu': 6,
    'bảy': 7,
    'bẩy': 7,
    'tám': 8,
    'chín': 9,
    'mười': 10,
  };

  static const _hourWord = r'(?:giờ|g(?=\s|$)|h(?=\s|$))';

  @override
  ParsedTime? parse(String input) {
    final s = collapseNumberWords(
      normalizeBasic(input),
      words: _words,
      tensMultiplier: 'mươi',
      minTens: 10,
    );

    final period = _period(s);

    Match? m;
    // 8 giờ kém 15
    m = RegExp('(\\d{1,2})\\s*$_hourWord?\\s*kém\\s*(\\d{1,2})').firstMatch(s);
    if (m != null) return minus(int.parse(m[1]!), int.parse(m[2]!), period);

    // 7 giờ rưỡi / 7 rưỡi
    m = RegExp('(\\d{1,2})\\s*$_hourWord?\\s*rưỡi').firstMatch(s);
    if (m != null) return buildTime(int.parse(m[1]!), 30, period);

    // 7 giờ 30 (phút) / 7:30 / 7 h 30
    m = RegExp('(\\d{1,2})\\s*(?:$_hourWord|:)\\s*(\\d{1,2})(?!\\d)')
        .firstMatch(s);
    if (m != null) return buildTime(int.parse(m[1]!), int.parse(m[2]!), period);

    // 7 giờ (đúng)
    m = RegExp('(\\d{1,2})\\s*$_hourWord').firstMatch(s);
    if (m != null) return buildTime(int.parse(m[1]!), 0, period);

    // "7 30 sáng" (engine nhận dạng bỏ chữ "giờ")
    m = RegExp(r'(?<!\d)(\d{1,2})\s+(\d{2})(?!\d)').firstMatch(s);
    if (m != null) return buildTime(int.parse(m[1]!), int.parse(m[2]!), period);

    // "6 sáng"
    m = RegExp(r'(?<!\d)(\d{1,2})\s*(?=sáng|trưa|chiều|tối|đêm|khuya)')
        .firstMatch(s);
    if (m != null) return buildTime(int.parse(m[1]!), 0, period);

    if (s.contains('nửa đêm')) return const ParsedTime(0, 0);
    if (s.contains('giữa trưa')) return const ParsedTime(12, 0);
    return null;
  }

  DayPeriod _period(String s) {
    if (s.contains('sáng')) return DayPeriod.am;
    if (s.contains('trưa')) return DayPeriod.noon;
    if (s.contains('chiều') || s.contains('tối')) return DayPeriod.pm;
    if (s.contains('đêm') || s.contains('khuya')) return DayPeriod.night;
    return DayPeriod.none;
  }
}
