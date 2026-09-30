import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Kết quả kiểm định chất lượng ảnh trước khi nhận dạng chữ.
class ImageQuality {
  /// Độ nét: phương sai Laplacian trên ảnh xám đã thu nhỏ. Càng cao càng nét.
  final double sharpness;

  /// Độ sáng trung bình 0..255.
  final double brightness;

  const ImageQuality(this.sharpness, this.brightness);

  static const sharpThreshold = 120.0;

  bool get isBlurry => sharpness < sharpThreshold;
  bool get isDark => brightness < 60;
  bool get isOverexposed => brightness > 225;
  bool get isGood => !isBlurry && !isDark && !isOverexposed;

  /// Giải mã ảnh (thu nhỏ về rộng 640px) bằng dart:ui rồi tính trong isolate
  /// riêng để không giật UI.
  static Future<ImageQuality?> analyze(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 640);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final w = image.width, h = image.height;
      image.dispose();
      if (data == null) return null;
      return await compute(_measure, (data.buffer.asUint8List(), w, h));
    } catch (_) {
      return null;
    }
  }
}

ImageQuality _measure((Uint8List, int, int) a) =>
    measureQuality(a.$1, a.$2, a.$3);

/// Tính độ nét + độ sáng từ ảnh RGBA [w]x[h]. Tách riêng để unit test được.
ImageQuality measureQuality(Uint8List rgba, int w, int h) {
  final lum = Float64List(w * h);
  var sum = 0.0;
  for (var i = 0; i < w * h; i++) {
    final p = i * 4;
    final v = 0.299 * rgba[p] + 0.587 * rgba[p + 1] + 0.114 * rgba[p + 2];
    lum[i] = v;
    sum += v;
  }
  // Laplacian 4 lân cận, phương sai tính theo Welford.
  var n = 0;
  var mean = 0.0, m2 = 0.0;
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final i = y * w + x;
      final lap =
          lum[i - 1] + lum[i + 1] + lum[i - w] + lum[i + w] - 4 * lum[i];
      n++;
      final d = lap - mean;
      mean += d / n;
      m2 += d * (lap - mean);
    }
  }
  final variance = n > 1 ? m2 / (n - 1) : 0.0;
  return ImageQuality(variance, sum / (w * h));
}
