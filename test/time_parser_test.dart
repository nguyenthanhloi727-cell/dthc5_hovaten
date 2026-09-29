import 'package:flutter_test/flutter_test.dart';
import 'package:nguyen_thanh_loi/features/alarm/parsers/en_time_parser.dart';
import 'package:nguyen_thanh_loi/features/alarm/parsers/fr_time_parser.dart';
import 'package:nguyen_thanh_loi/features/alarm/parsers/time_parser.dart';
import 'package:nguyen_thanh_loi/features/alarm/parsers/vi_time_parser.dart';

void expectCases(TimeParser p, Map<String, String?> cases) {
  cases.forEach((input, expected) {
    test('"$input" -> $expected', () {
      expect(p.parse(input)?.toString(), expected);
    });
  });
}

void main() {
  group('Tiếng Việt', () {
    expectCases(const ViTimeParser(), {
      '7 giờ 30 sáng': '07:30',
      'bảy giờ rưỡi': '07:30',
      'bảy giờ rưỡi tối': '19:30',
      'đặt báo thức lúc 6 giờ sáng mai': '06:00',
      '8 giờ kém 15': '07:45',
      'tám giờ kém mười lăm': '07:45',
      '9 giờ kém 15 tối': '20:45',
      'hai mươi mốt giờ': '21:00',
      'mười chín giờ ba mươi lăm phút': '19:35',
      'mười hai giờ trưa': '12:00',
      '1 giờ trưa': '13:00',
      '3 giờ chiều': '15:00',
      '11 giờ đêm': '23:00',
      '2 giờ đêm': '02:00',
      '12 giờ đêm': '00:00',
      'nửa đêm': '00:00',
      '6h15': '06:15',
      '7:05 tối': '19:05',
      '7 30 sáng': '07:30',
      'năm giờ năm phút': '05:05',
      '6 sáng': '06:00',
      'xin chào': null,
      '25 giờ': null,
    });
  });

  group('English', () {
    expectCases(const EnTimeParser(), {
      '7:30 pm': '19:30',
      '7:30 p.m.': '19:30',
      'Wake me up at 6 a.m.': '06:00',
      'half past seven': '07:30',
      'half past seven in the evening': '19:30',
      'quarter past six': '06:15',
      'quarter to eight': '07:45',
      'ten to eight pm': '19:50',
      'twenty past nine': '09:20',
      'seven thirty': '07:30',
      'seven thirty five am': '07:35',
      'seven oh five': '07:05',
      'twelve thirty am': '00:30',
      "7 o'clock": '07:00',
      'nineteen hundred': '19:00',
      'noon': '12:00',
      'midnight': '00:00',
      '11 at night': '23:00',
      'hello there': null,
    });
  });

  group('Français', () {
    expectCases(const FrTimeParser(), {
      '7 h 30': '07:30',
      '7h30': '07:30',
      'sept heures et demie': '07:30',
      'sept heures et quart': '07:15',
      'huit heures moins le quart': '07:45',
      'huit heures moins dix': '07:50',
      'dix-neuf heures': '19:00',
      'vingt et une heures quinze': '21:15',
      'sept heures du soir': '19:00',
      "trois heures de l'après-midi": '15:00',
      'six heures du matin': '06:00',
      'midi': '12:00',
      'midi et demi': '12:30',
      'minuit': '00:00',
      'une heure': '01:00',
      'bonjour': null,
    });
  });

  test('forLocale trả về parser đúng ngôn ngữ', () {
    expect(TimeParser.forLocale('en_US'), isA<EnTimeParser>());
    expect(TimeParser.forLocale('fr_FR'), isA<FrTimeParser>());
    expect(TimeParser.forLocale('xx'), isA<ViTimeParser>());
  });
}
