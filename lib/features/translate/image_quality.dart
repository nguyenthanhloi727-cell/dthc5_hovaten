import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

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

  /// Tính trong isolate riêng để không giật UI.
  static Future<ImageQuality?> analyze(Uint8List bytes) =>
      compute(_analyze, bytes);
}

ImageQuality? _analyze(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  // Thu nhỏ về chiều rộng cố định để ngưỡng độ nét không phụ thuộc độ phân giải.
  final small = img.grayscale(img.copyResize(decoded, width: 640));
  final w = small.width, h = small.height;
  final lum = List<double>.filled(w * h, 0);
  var sum = 0.0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final v = small.getPixel(x, y).r.toDouble();
      lum[y * w + x] = v;
      sum += v;
    }
  }
  // Laplacian 4 lân cận.
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
