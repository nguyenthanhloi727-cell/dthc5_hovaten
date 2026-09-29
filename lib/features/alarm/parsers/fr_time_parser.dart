import 'time_parser.dart';

/// Comprend : "7 h 30", "sept heures et demie", "huit heures moins le quart",
/// "dix-neuf heures quinze", "midi", "minuit", "7 heures du soir".
class FrTimeParser extends TimeParser {
  const FrTimeParser();

  @override
  String get localeId => 'fr_FR';

  @override
  String get displayName => 'Français';

  @override
  List<String> get examples => const [
    '7 h 30',
    'sept heures et demie',
    'huit heures moins le quart',
    'dix-neuf heures',
  ];

  static const _words = {
    'zéro': 0,
    'un': 1,
    'une': 1,
    'deux': 2,
    'trois': 3,
    'quatre': 4,
    'cinq': 5,
    'six': 6,
    'sept': 7,
    'huit': 8,
    'neuf': 9,
    'dix': 10,
    'onze': 11,
    'douze': 12,
    'treize': 13,
    'quatorze': 14,
    'quinze': 15,
    'seize': 16,
    'vingt': 20,
    'trente': 30,
    'quarante': 40,
    'cinquante': 50,
  };

  static const _hourWord = r'(?:heures?|h(?=\s|$))';

  @override
  ParsedTime? parse(String input) {
    var s = input.toLowerCase().replaceAll('’', "'").replaceAll('-', ' ');
    s = normalizeBasic(s).replaceAll("'", ' ');
    s = s
        .replaceAll('après midi', 'aprem')
        .replaceAll(RegExp(r'moins (?:le )?quart'), 'moins 15')
        .replaceAll(RegExp(r'et demie?'), '30')
        .replaceAll('et quart', '15')
        .replaceAll('midi', '12 heures')
        .replaceAll('minuit', '0 heures')
        .replaceAllMapped(
          RegExp(r'(vingt|trente|quarante|cinquante) et (un|une)\b'),
          (m) => '${m[1]} un',
        );
    s = collapseNumberWords(s, words: _words, minTens: 10);

    final period = _period(s);

    Match? m;
    m = RegExp('(\\d{1,2})\\s*$_hourWord\\s*moins\\s*(\\d{1,2})').firstMatch(s);
    if (m != null) return minus(int.parse(m[1]!), int.parse(m[2]!), period);

    m = RegExp('(\\d{1,2})\\s*(?:$_hourWord|:)\\s*(\\d{1,2})(?!\\d)')
        .firstMatch(s);
    if (m != null) return buildTime(int.parse(m[1]!), int.parse(m[2]!), period);

    m = RegExp('(\\d{1,2})\\s*$_hourWord').firstMatch(s);
    if (m != null) return buildTime(int.parse(m[1]!), 0, period);
    return null;
  }

  DayPeriod _period(String s) {
    if (s.contains('du matin')) return DayPeriod.am;
    if (s.contains('aprem') || s.contains('soir')) return DayPeriod.pm;
    if (s.contains('de la nuit')) return DayPeriod.night;
    return DayPeriod.none;
  }
}
