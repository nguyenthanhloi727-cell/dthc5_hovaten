import 'time_parser.dart';

/// Understands: "7:30 pm", "seven thirty am", "half past seven",
/// "quarter to eight", "ten past six", "7 o'clock", "noon", "midnight".
class EnTimeParser extends TimeParser {
  const EnTimeParser();

  @override
  String get localeId => 'en_US';

  @override
  String get displayName => 'English';

  @override
  List<String> get examples => const [
    '7:30 pm',
    'half past seven',
    'quarter to eight',
    'six fifteen am',
  ];

  static const _words = {
    'zero': 0,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
  };

  @override
  ParsedTime? parse(String input) {
    var s = input.toLowerCase().replaceAll('-', ' ');
    s = s.replaceAllMapped(
      RegExp(r'(\d|\b)\s*([ap])\.?\s?m\b\.?'),
      (m) => '${m[1]} ${m[2]}m ',
    );
    s = collapseNumberWords(normalizeBasic(s), words: _words);
    s = s.replaceAll(RegExp(r"o'?\s?clock"), 'oclock');

    final period = _period(s);

    Match? m;
    m = RegExp(r'half past (\d{1,2})').firstMatch(s);
    if (m != null) return buildTime(int.parse(m[1]!), 30, period);

    m = RegExp(r'quarter past (\d{1,2})').firstMatch(s);
    if (m != null) return buildTime(int.parse(m[1]!), 15, period);

    m = RegExp(r'quarter to (\d{1,2})').firstMatch(s);
    if (m != null) return minus(int.parse(m[1]!), 15, period);

    m = RegExp(r'(\d{1,2}) (?:minutes? )?past (\d{1,2})').firstMatch(s);
    if (m != null) return buildTime(int.parse(m[2]!), int.parse(m[1]!), period);

    m = RegExp(r'(\d{1,2}) (?:minutes? )?to (\d{1,2})').firstMatch(s);
    if (m != null) return minus(int.parse(m[2]!), int.parse(m[1]!), period);

    // seven oh five
    m = RegExp(r'(\d{1,2}) (?:oh|o) (\d)(?!\d)').firstMatch(s);
    if (m != null) return buildTime(int.parse(m[1]!), int.parse(m[2]!), period);

    // 7:30 / seven thirty
    m = RegExp(r'(?<!\d)(\d{1,2})\s*[: ]\s*(\d{2})(?!\d)').firstMatch(s);
    if (m != null) return buildTime(int.parse(m[1]!), int.parse(m[2]!), period);

    if (RegExp(r'\bnoon\b|\bmidday\b').hasMatch(s)) {
      return const ParsedTime(12, 0);
    }
    if (s.contains('midnight')) return const ParsedTime(0, 0);

    // 7 o'clock / 7 pm / "at 7"
    m = RegExp(r'(?<!\d)(\d{1,2})(?!\d)').firstMatch(s);
    if (m != null) return buildTime(int.parse(m[1]!), 0, period);
    return null;
  }

  DayPeriod _period(String s) {
    if (RegExp(r'\bam\b|morning').hasMatch(s)) return DayPeriod.am;
    if (RegExp(r'\bpm\b|afternoon|evening|tonight').hasMatch(s)) {
      return DayPeriod.pm;
    }
    if (s.contains('at night')) return DayPeriod.night;
    return DayPeriod.none;
  }
}
