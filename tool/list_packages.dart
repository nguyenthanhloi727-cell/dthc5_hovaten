// Sinh bảng package (markdown) từ pubspec.yaml + pubspec.lock rồi ghi đè vào
// giữa 2 marker <!-- PACKAGES:START --> và <!-- PACKAGES:END --> trong
// README.md. Chạy lại bao nhiêu lần cũng được.
//
//   dart run tool/list_packages.dart
import 'dart:io';

const _start = '<!-- PACKAGES:START -->';
const _end = '<!-- PACKAGES:END -->';

/// Package dùng cho tính năng nào (map thủ công, sửa khi thêm package).
const _usage = <String, String>{
  'flutter': 'Framework',
  'cupertino_icons': 'Icon kiểu iOS (mặc định của Flutter)',
  'url_launcher': '2. Gọi điện (`tel:`), mở YouTube, gửi email',
  'speech_to_text': '3. Báo thức bằng giọng nói · 4b. Dịch giọng nói',
  'google_mlkit_translation': '4. Dịch offline (tải model lần đầu)',
  'google_mlkit_text_recognition': '4c. Lấy chữ từ ảnh · 5. Dịch realtime',
  'image_picker': '4c. Chụp ảnh / chọn ảnh từ thư viện',
  'camera': '5. Dịch realtime (image stream)',
  'flutter_test': 'Unit test + widget test',
  'flutter_lints': 'Bộ luật `flutter analyze`',
};

void main() {
  final pubspec = File('pubspec.yaml');
  final lock = File('pubspec.lock');
  final readme = File('README.md');
  if (!pubspec.existsSync() || !lock.existsSync()) {
    stderr.writeln('Chạy ở thư mục gốc project, sau khi `flutter pub get`.');
    exit(1);
  }

  final deps = _readSection(pubspec.readAsLinesSync(), 'dependencies');
  final devDeps = _readSection(pubspec.readAsLinesSync(), 'dev_dependencies');
  final versions = _readLockVersions(lock.readAsLinesSync());

  final rows = StringBuffer()
    ..writeln('| Package | Version (pubspec.lock) | Dùng cho | Loại |')
    ..writeln('|---|---|---|---|');
  void add(String name, String kind) {
    final version = versions[name] ?? 'SDK';
    final link = version == 'SDK'
        ? '`$name`'
        : '[`$name`](https://pub.dev/packages/$name)';
    final usage =
        _usage[name] ??
        '_(chưa ghi — thêm vào `_usage` trong tool/list_packages.dart)_';
    rows.writeln('| $link | $version | $usage | $kind |');
  }

  for (final d in deps) {
    add(d, 'dependency');
  }
  for (final d in devDeps) {
    add(d, 'dev_dependency');
  }

  final block =
      '$_start\n'
      '<!-- Sinh tự động bởi `dart run tool/list_packages.dart`, đừng sửa tay. -->\n'
      '${rows.toString().trimRight()}\n'
      '$_end';

  var text = readme.existsSync() ? readme.readAsStringSync() : '';
  final s = text.indexOf(_start), e = text.indexOf(_end);
  if (s >= 0 && e > s) {
    text = text.replaceRange(s, e + _end.length, block);
  } else {
    text = '${text.trimRight()}\n\n## Package sử dụng\n\n$block\n';
  }
  readme.writeAsStringSync(text);
  stdout.writeln(rows);
  stdout.writeln(
    '✓ Đã cập nhật bảng package trong README.md '
    '(${deps.length} dependency, ${devDeps.length} dev_dependency).',
  );
}

/// Tên các package trực tiếp trong mục [section] của pubspec.yaml.
List<String> _readSection(List<String> lines, String section) {
  final out = <String>[];
  var inside = false;
  for (final raw in lines) {
    final line = raw.replaceFirst(RegExp(r'\s+#.*$'), '');
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
    if (!line.startsWith(' ')) {
      inside = line.startsWith('$section:');
      continue;
    }
    // Chỉ lấy key thụt đúng 2 dấu cách (package), bỏ `sdk: flutter`...
    final m = RegExp(r'^  ([a-zA-Z0-9_]+):').firstMatch(line);
    if (inside && m != null) out.add(m[1]!);
  }
  return out;
}

/// name -> version từ pubspec.lock.
Map<String, String> _readLockVersions(List<String> lines) {
  final out = <String, String>{};
  final sdk = <String>{};
  String? current;
  for (final line in lines) {
    final pkg = RegExp(r'^  ([a-zA-Z0-9_]+):\s*$').firstMatch(line);
    if (pkg != null) {
      current = pkg[1];
      continue;
    }
    final ver = RegExp(r'^    version: "([^"]+)"').firstMatch(line);
    if (ver != null && current != null) out[current] = ver[1]!;
    if (current != null && line.trim() == 'source: sdk') sdk.add(current);
  }
  // Package đi kèm Flutter SDK (flutter, flutter_test) không có trên pub.dev.
  sdk.forEach(out.remove);
  return out;
}
