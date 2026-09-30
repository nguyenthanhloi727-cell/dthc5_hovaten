import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nguyen_thanh_loi/features/translate/image_quality.dart';

/// Tạo ảnh RGBA xám từ hàm độ sáng theo toạ độ.
Uint8List gray(int w, int h, int Function(int x, int y) f) {
  final out = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = (y * w + x) * 4;
      final v = f(x, y).clamp(0, 255);
      out[p] = out[p + 1] = out[p + 2] = v;
      out[p + 3] = 255;
    }
  }
  return out;
}

void main() {
  test('ảnh sọc đen trắng sắc nét -> không mờ', () {
    final q = measureQuality(
      gray(64, 64, (x, _) => x.isEven ? 0 : 255),
      64,
      64,
    );
    expect(q.isBlurry, isFalse);
  });

  test('ảnh chuyển màu mượt (như bị nhoè) -> mờ', () {
    final q = measureQuality(gray(64, 64, (x, _) => x * 4), 64, 64);
    expect(q.isBlurry, isTrue);
  });

  test('độ sáng', () {
    expect(measureQuality(gray(8, 8, (_, _) => 10), 8, 8).isDark, isTrue);
    expect(
      measureQuality(gray(8, 8, (_, _) => 250), 8, 8).isOverexposed,
      isTrue,
    );
    expect(measureQuality(gray(8, 8, (_, _) => 128), 8, 8).isDark, isFalse);
  });
}
