// Hàm dùng chung cho tool/switch_member.dart và tool/doi_thong_tin.dart.
// Chỉ dùng thư viện chuẩn của Dart để chạy được mà không cần Flutter.

const _viMap = {
  'àáạảãâầấậẩẫăằắặẳẵ': 'a',
  'èéẹẻẽêềếệểễ': 'e',
  'ìíịỉĩ': 'i',
  'òóọỏõôồốộổỗơờớợởỡ': 'o',
  'ùúụủũưừứựửữ': 'u',
  'ỳýỵỷỹ': 'y',
  'đ': 'd',
};

/// "Nguyễn Văn Á" -> "nguyen van a"
String removeDiacritics(String s) {
  final buf = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    var out = ch;
    for (final e in _viMap.entries) {
      if (e.key.contains(ch)) {
        out = e.value;
        break;
      }
    }
    buf.write(out);
  }
  // Loại dấu tổ hợp (khi chuỗi ở dạng NFD).
  return buf.toString().replaceAll(RegExp('[̀-ͯ]'), '');
}

/// "Nguyễn Văn A" -> "nguyen_van_a" (tên app theo luật lớp).
String slugify(String hoTen) =>
    removeDiacritics(hoTen)
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

/// Từ khoá Java/Dart không được dùng làm 1 đoạn của package name.
const _reserved = {
  'abstract',
  'assert',
  'boolean',
  'break',
  'byte',
  'case',
  'catch',
  'char',
  'class',
  'const',
  'continue',
  'default',
  'do',
  'double',
  'else',
  'enum',
  'extends',
  'final',
  'finally',
  'float',
  'for',
  'goto',
  'if',
  'implements',
  'import',
  'instanceof',
  'int',
  'interface',
  'long',
  'native',
  'new',
  'package',
  'private',
  'protected',
  'public',
  'return',
  'short',
  'static',
  'super',
  'switch',
  'synchronized',
  'this',
  'throw',
  'throws',
  'transient',
  'try',
  'void',
  'volatile',
  'while',
  'true',
  'false',
  'null',
};

// ---------------------------------------------------------------- kiểm tra
// Mỗi hàm trả null nếu hợp lệ, ngược lại trả câu báo lỗi tiếng Việt.

String? checkHoTen(String v) {
  final t = v.trim();
  if (t.contains('�') || t.contains('?')) {
    return 'Tên bị lỗi font (dấu ?). Terminal không gõ được tiếng Việt: '
        'chạy doi_thong_tin.bat hoặc dùng --file (xem tool/README.md).';
  }
  if (!RegExp(r'^[\p{L} ]+$', unicode: true).hasMatch(t)) {
    return 'Họ tên chỉ gồm chữ cái và dấu cách.';
  }
  if (t.split(RegExp(r'\s+')).length < 2) return 'Nhập đầy đủ họ và tên.';
  final slug = slugify(t);
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(slug)) {
    return 'Không tạo được tên app từ họ tên này (được "$slug").';
  }
  if (_reserved.contains(slug)) return 'Tên app "$slug" trùng từ khoá Java.';
  return null;
}

String? checkMssv(String v) => RegExp(r'^[A-Za-z0-9]{4,15}$').hasMatch(v.trim())
    ? null
    : 'MSSV chỉ gồm chữ/số, 4–15 ký tự, không dấu cách.';

String? checkSdt(String v) {
  final digits = v.replaceAll(RegExp(r'[\s.\-]'), '');
  return RegExp(r'^(\+84|0)\d{9,10}$').hasMatch(digits)
      ? null
      : 'SĐT dạng 0xxxxxxxxx hoặc +84xxxxxxxxx (10–11 số).';
}

String? checkEmail(String v) =>
    RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(v.trim())
    ? null
    : 'Email không hợp lệ.';

String? checkNotEmpty(String v) =>
    v.trim().isEmpty ? 'Không được để trống.' : null;

/// Chuẩn hoá SĐT để lưu: bỏ dấu chấm/gạch, giữ dấu cách người dùng nhập.
String normalizeSdt(String v) => v.trim().replaceAll(RegExp(r'[.\-]'), '');

/// Chuẩn hoá họ tên: viết hoa chữ cái đầu mỗi từ, bỏ khoảng trắng thừa.
String normalizeHoTen(String v) => v
    .trim()
    .split(RegExp(r'\s+'))
    .map(
      (w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase(),
    )
    .join(' ');
