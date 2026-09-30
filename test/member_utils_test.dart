import 'package:flutter_test/flutter_test.dart';

import '../tool/src/member_utils.dart';

void main() {
  test('slugify bỏ dấu, chữ thường, nối bằng _', () {
    expect(slugify('Nguyễn Văn A'), 'nguyen_van_a');
    expect(slugify('  Đặng Thị Ánh Tuyết '), 'dang_thi_anh_tuyet');
    expect(slugify('Lê Ỷ'), 'le_y');
  });

  test('normalizeHoTen viết hoa chữ đầu', () {
    expect(normalizeHoTen('  nguyễn   văn  a '), 'Nguyễn Văn A');
    expect(normalizeHoTen('đỗ ĐỨC'), 'Đỗ Đức');
  });

  group('checkHoTen', () {
    test('hợp lệ', () => expect(checkHoTen('Nguyễn Văn A'), isNull));
    test('thiếu tên', () => expect(checkHoTen('Nguyễn'), isNotNull));
    test('có số', () => expect(checkHoTen('Nguyen Van 1'), isNotNull));
    test(
      'lỗi font',
      () => expect(checkHoTen('Nguy?n V?n A'), contains('lỗi font')),
    );
  });

  test('checkMssv', () {
    expect(checkMssv('2280600123'), isNull);
    expect(checkMssv('DH52012345'), isNull);
    expect(checkMssv('22 80'), isNotNull);
    expect(checkMssv('12'), isNotNull);
  });

  test('checkSdt', () {
    expect(checkSdt('0912345678'), isNull);
    expect(checkSdt('0912 345 678'), isNull);
    expect(checkSdt('0912.345.678'), isNull);
    expect(checkSdt('+84912345678'), isNull);
    expect(checkSdt('12345'), isNotNull);
    expect(checkSdt('09123abc78'), isNotNull);
  });

  test('checkEmail', () {
    expect(checkEmail('a.b+c@gmail.com'), isNull);
    expect(checkEmail('sv@hutech.edu.vn'), isNull);
    expect(checkEmail('abc@'), isNotNull);
    expect(checkEmail('abc'), isNotNull);
  });

  test('normalizeSdt bỏ dấu chấm/gạch', () {
    expect(normalizeSdt(' 0912.345-678 '), '0912345678');
  });
}
