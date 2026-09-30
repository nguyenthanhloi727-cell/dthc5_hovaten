// TOOL ĐỔI THÔNG TIN NGƯỜI NỘP BÀI
//
// Hỏi lần lượt từng trường (họ tên, MSSV, SĐT, email, lớp, vai trò, ảnh,
// tên/email git), kiểm tra hợp lệ, rồi thay toàn bộ danh tính app:
//   members.json -> lib/config/*.dart, tên app, applicationId, MainActivity...
// Cuối cùng chạy `flutter analyze` để chắc chắn không lỗi.
//
// Cách chạy:
//   doi_thong_tin.bat                                   (Windows, bấm đúp)
//   dart run tool/doi_thong_tin.dart                     (hỏi từng trường)
//   dart run tool/doi_thong_tin.dart --file thong_tin.json   (không hỏi)
import 'dart:convert';
import 'dart:io';

import 'src/member_utils.dart';

const _membersFile = 'members.json';
const _photoDir = 'assets/members';

late final Directory root;

Future<void> main(List<String> args) async {
  root = _findRoot();
  final fileIdx = args.indexOf('--file');
  final answers = fileIdx >= 0 && fileIdx + 1 < args.length
      ? _loadAnswers(args[fileIdx + 1])
      : null;

  final data = jsonDecode(_read(_membersFile)) as Map<String, dynamic>;
  final members = (data['members'] as List).cast<Map<String, dynamic>>();
  final currentMssv = data['current'] as String?;

  _title('ĐỔI THÔNG TIN NGƯỜI NỘP BÀI');
  _printTeam(members, currentMssv);

  // ------------------------------------------------ 1. người nộp bài
  final Map<String, dynamic> me;
  final String? photoSrc;
  if (answers != null) {
    final n = answers['nguoi_nop'] as Map<String, dynamic>;
    final errors = _validateAll(n);
    if (errors.isNotEmpty) {
      stderr.writeln('File thông tin có lỗi:');
      for (var e in errors) {
        stderr.writeln('  - $e');
      }
      exit(1);
    }
    me = _normalize(n);
    photoSrc = (n['anh_file'] as String?)?.trim();
  } else {
    stdout.writeln(
      '\nNhập thông tin NGƯỜI NỘP BÀI. Enter = giữ giá trị trong [ ].',
    );
    final mssv = _ask('MSSV', current: currentMssv, check: checkMssv);
    final existing = members.where((m) => m['mssv'] == mssv).firstOrNull;
    stdout.writeln(
      existing != null
          ? '  → Đã có trong nhóm: ${existing['ho_ten']}. Sửa nếu cần.'
          : '  → MSSV mới, sẽ thêm vào danh sách nhóm.',
    );
    me = {'mssv': mssv, ..._askMember(existing ?? {}, skipMssv: true)};
    me['anh'] = _existingPhoto(mssv) ?? '$_photoDir/$mssv.jpg';
    photoSrc = _askPhoto(mssv);
  }
  if (photoSrc != null && photoSrc.isNotEmpty) {
    final err = _checkPhoto(photoSrc);
    if (err != null) {
      stderr.writeln(err);
      exit(1);
    }
  }

  // ------------------------------------------------ 2. git (chỉ repo này)
  String? gitName, gitEmail;
  final hasGit = Directory(_p('.git')).existsSync();
  if (hasGit) {
    if (answers != null) {
      final g = answers['git'] as Map<String, dynamic>?;
      gitName = (g?['name'] as String?)?.trim();
      gitEmail = (g?['email'] as String?)?.trim();
    } else if (_yes(
      '\nĐặt tên/email git cho repo này (commit sẽ mang tên bạn)?',
      true,
    )) {
      gitName = _ask(
        '  Tên git (tên tài khoản GitHub của bạn)',
        current: removeDiacritics(me['ho_ten'] as String)
            .split(' ')
            .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
            .join(''),
        check: checkNotEmpty,
      );
      gitEmail = _ask(
        '  Email git (email GitHub)',
        current: me['email'] as String,
        check: checkEmail,
      );
    }
  }

  // ------------------------------------------------ 3. danh sách nhóm
  final idx = members.indexWhere((m) => m['mssv'] == me['mssv']);
  if (idx >= 0) {
    members[idx] = {...members[idx], ...me};
  } else {
    members.add(me);
  }
  if (answers == null &&
      _yes('\nSửa danh sách thành viên khác trong nhóm?', false)) {
    _editTeam(members, me['mssv'] as String);
  }

  // ------------------------------------------------ 4. dọn file IDE cũ
  final ideFiles = _ideFiles();
  var cleanIde = false;
  if (ideFiles.isNotEmpty) {
    cleanIde = answers != null
        ? (answers['xoa_file_ide'] as bool? ?? true)
        : _yes(
            '\nXoá ${ideFiles.length} file cấu hình IDE cũ (.idea, *.iml — chứa tên app cũ, '
            'Android Studio sẽ tự tạo lại)?',
            true,
          );
  }

  // ------------------------------------------------ 5. xác nhận
  _title('KIỂM TRA LẠI');
  final appName = slugify(me['ho_ten'] as String);
  _row('Họ tên', me['ho_ten']);
  _row('MSSV', me['mssv']);
  _row('SĐT', me['sdt']);
  _row('Email', me['email']);
  _row('Lớp', me['lop']);
  _row('Vai trò', me['vai_tro']);
  _row(
    'Ảnh',
    photoSrc == null || photoSrc.isEmpty
        ? (File(_p(me['anh'] as String)).existsSync()
              ? me['anh']
              : '(không có → hiện chữ cái đầu)')
        : '$photoSrc → ${me['anh']}',
  );
  _row('Tên app', appName);
  _row('applicationId', 'com.$appName.app');
  if (gitName != null) _row('Git', '$gitName <$gitEmail>');
  _row('Số thành viên nhóm', members.length);
  if (answers == null && !_yes('\nÁp dụng các thay đổi trên?', false)) {
    stdout.writeln('Đã huỷ, không thay đổi gì.');
    exit(0);
  }

  // ------------------------------------------------ 6. áp dụng
  _title('ĐANG ÁP DỤNG');
  File(_p(_membersFile)).copySync(_p('$_membersFile.bak'));
  stdout.writeln('  ✓ sao lưu members.json → members.json.bak');

  if (photoSrc != null && photoSrc.isNotEmpty) {
    _installPhoto(photoSrc, me);
  }
  data['current'] = me['mssv'];
  data['members'] = members;
  _write(_membersFile, '${const JsonEncoder.withIndent('  ').convert(data)}\n');
  stdout.writeln('  ✓ ghi members.json');

  if (gitName != null && gitName.isNotEmpty) {
    await _run('git', ['config', 'user.name', gitName], quiet: true);
    if (gitEmail != null && gitEmail.isNotEmpty) {
      await _run('git', ['config', 'user.email', gitEmail], quiet: true);
    }
    stdout.writeln('  ✓ git config (chỉ repo này): $gitName <$gitEmail>');
  }

  if (cleanIde) {
    for (final e in ideFiles) {
      e.deleteSync(recursive: true);
    }
    stdout.writeln('  ✓ xoá file IDE cũ');
  }

  stdout.writeln(
    '\n--- Đổi tên app, applicationId, MainActivity, sinh lib/config ---',
  );
  final switchCode = await _run('dart', [
    'run',
    'tool/switch_member.dart',
    me['mssv'] as String,
  ]);
  if (switchCode != 0) {
    _fail('switch_member.dart lỗi (exit $switchCode).');
  }

  stdout.writeln('\n--- Kiểm tra code: flutter analyze ---');
  final analyze = await Process.run(
    'flutter',
    ['analyze', '--no-fatal-infos'],
    workingDirectory: root.path,
    runInShell: true,
  );
  final out = '${analyze.stdout}';
  final errorLines = out
      .split('\n')
      .where((l) => l.contains(' error '))
      .toList();
  if (errorLines.isNotEmpty) {
    errorLines.forEach(stdout.writeln);
    _fail('flutter analyze có ${errorLines.length} lỗi.');
  }
  stdout.writeln('  ✓ flutter analyze: không có lỗi');

  _title('XONG');
  stdout.writeln(
    'App giờ mang tên "$appName" (com.$appName.app) của ${me['ho_ten']}.',
  );
  stdout.writeln('Tiếp theo:');
  stdout.writeln(
    '  1. flutter run   → kiểm tra tên app, tab Cá nhân, nút gọi điện.',
  );
  stdout.writeln(
    '  2. git add -A && git commit -m "chore: switch to ${me['mssv']}"',
  );
  stdout.writeln(
    '  3. Nộp repo riêng: xem mục "Nộp bài riêng" trong README.md.',
  );
  stdout.writeln('Hoàn tác: copy members.json.bak đè members.json rồi chạy');
  stdout.writeln('  dart run tool/switch_member.dart $currentMssv');
}

// ---------------------------------------------------------------- hỏi đáp

Map<String, dynamic> _askMember(
  Map<String, dynamic> m, {
  bool skipMssv = false,
}) {
  final out = <String, dynamic>{};
  if (!skipMssv) {
    out['mssv'] = _ask('MSSV', current: m['mssv'] as String?, check: checkMssv);
  }
  out['ho_ten'] = normalizeHoTen(
    _ask(
      'Họ và tên (có dấu)',
      current: m['ho_ten'] as String?,
      check: checkHoTen,
    ),
  );
  out['sdt'] = normalizeSdt(
    _ask('Số điện thoại', current: m['sdt'] as String?, check: checkSdt),
  );
  out['email'] = _ask(
    'Email',
    current: m['email'] as String?,
    check: checkEmail,
  ).trim();
  out['lop'] = _ask(
    'Lớp',
    current: m['lop'] as String?,
    check: checkNotEmpty,
  ).trim();
  out['vai_tro'] = _ask(
    'Vai trò',
    current: (m['vai_tro'] as String?) ?? 'Thành viên',
    check: checkNotEmpty,
  ).trim();
  return out;
}

String? _askPhoto(String mssv) {
  final existing = _existingPhoto(mssv);
  stdout.writeln(
    existing != null
        ? 'Ảnh hiện có: $existing'
        : 'Chưa có ảnh (tab Nhóm sẽ hiện chữ cái đầu).',
  );
  while (true) {
    final p = _ask(
      'Đường dẫn file ảnh .jpg/.png (Enter = bỏ qua)',
      current: '',
      optional: true,
    ).replaceAll('"', '').trim();
    if (p.isEmpty) return null;
    final err = _checkPhoto(p);
    if (err == null) return p;
    stdout.writeln('  ✗ $err');
  }
}

void _editTeam(List<Map<String, dynamic>> members, String meMssv) {
  while (true) {
    _printTeam(members, meMssv);
    stdout.write('[t] thêm  [s <số>] sửa  [x <số>] xoá  [Enter] xong: ');
    final cmd = (stdin.readLineSync(encoding: utf8) ?? '').trim().toLowerCase();
    if (cmd.isEmpty) return;
    final parts = cmd.split(RegExp(r'\s+'));
    final n = parts.length > 1 ? int.tryParse(parts[1]) : null;
    if (parts[0] == 't') {
      final m = _askMember({});
      m['anh'] = '$_photoDir/${m['mssv']}.jpg';
      if (members.any((e) => e['mssv'] == m['mssv'])) {
        stdout.writeln('  ✗ MSSV ${m['mssv']} đã có.');
      } else {
        members.add(m);
        final photo = _askPhoto(m['mssv'] as String);
        if (photo != null) _installPhoto(photo, m);
      }
    } else if ((parts[0] == 's' || parts[0] == 'x') &&
        n != null &&
        n >= 1 &&
        n <= members.length) {
      final m = members[n - 1];
      if (m['mssv'] == meMssv) {
        stdout.writeln('  ✗ Đây là người nộp bài, đã sửa ở bước trước.');
      } else if (parts[0] == 'x') {
        if (_yes('  Xoá ${m['ho_ten']}?', false)) {
          members.removeAt(n - 1);
          final photo = _existingPhoto(m['mssv'] as String);
          if (photo != null) File(_p(photo)).deleteSync();
        }
      } else {
        final updated = _askMember(m);
        final oldMssv = m['mssv'] as String;
        updated['anh'] =
            _existingPhoto(updated['mssv'] as String) ??
            '$_photoDir/${updated['mssv']}.jpg';
        if (updated['mssv'] != oldMssv &&
            members.any((e) => e['mssv'] == updated['mssv'])) {
          stdout.writeln('  ✗ MSSV ${updated['mssv']} đã có.');
          continue;
        }
        // Đổi MSSV thì đổi tên file ảnh theo.
        final oldPhoto = _existingPhoto(oldMssv);
        if (oldPhoto != null && updated['mssv'] != oldMssv) {
          final ext = oldPhoto.split('.').last;
          final newPath = '$_photoDir/${updated['mssv']}.$ext';
          File(_p(oldPhoto)).renameSync(_p(newPath));
          updated['anh'] = newPath;
        }
        members[n - 1] = updated;
        final photo = _askPhoto(updated['mssv'] as String);
        if (photo != null) _installPhoto(photo, updated);
      }
    } else {
      stdout.writeln('  ✗ Lệnh không hợp lệ.');
    }
  }
}

String _ask(
  String label, {
  String? current,
  String? Function(String)? check,
  bool optional = false,
}) {
  while (true) {
    final hint = current != null && current.isNotEmpty ? ' [$current]' : '';
    stdout.write('$label$hint: ');
    final line = stdin.readLineSync(encoding: utf8);
    if (line == null) _fail('Không đọc được bàn phím (stdin đã đóng).');
    var v = line.trim();
    if (v.isEmpty) {
      if (optional) return '';
      v = current ?? '';
    }
    final err = check?.call(v);
    if (err == null) return v;
    stdout.writeln('  ✗ $err');
  }
}

bool _yes(String q, bool def) {
  stdout.write('$q ${def ? '[Y/n]' : '[y/N]'}: ');
  final a = (stdin.readLineSync(encoding: utf8) ?? '').trim().toLowerCase();
  if (a.isEmpty) return def;
  return a == 'y' || a == 'yes' || a == 'c' || a == 'co' || a == 'có';
}

// ---------------------------------------------------------------- --file

Map<String, dynamic> _loadAnswers(String path) {
  final f = File(path).existsSync() ? File(path) : File(_p(path));
  if (!f.existsSync()) _fail('Không thấy file $path');
  try {
    return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  } on FormatException catch (e) {
    _fail('File $path không phải JSON hợp lệ: ${e.message}');
  }
}

List<String> _validateAll(Map<String, dynamic> n) {
  final errors = <String>[];
  void c(String key, String? Function(String) check) {
    final v = (n[key] ?? '').toString();
    final e = check(v);
    if (e != null) errors.add('$key: $e');
  }

  c('ho_ten', checkHoTen);
  c('mssv', checkMssv);
  c('sdt', checkSdt);
  c('email', checkEmail);
  c('lop', checkNotEmpty);
  c('vai_tro', checkNotEmpty);
  return errors;
}

Map<String, dynamic> _normalize(Map<String, dynamic> n) {
  final mssv = (n['mssv'] as String).trim();
  return {
    'ho_ten': normalizeHoTen(n['ho_ten'] as String),
    'mssv': mssv,
    'sdt': normalizeSdt(n['sdt'] as String),
    'email': (n['email'] as String).trim(),
    'lop': (n['lop'] as String).trim(),
    'vai_tro': (n['vai_tro'] as String).trim(),
    'anh': _existingPhoto(mssv) ?? '$_photoDir/$mssv.jpg',
  };
}

// ---------------------------------------------------------------- ảnh

String? _checkPhoto(String path) {
  final f = File(path);
  if (!f.existsSync()) return 'Không thấy file ảnh: $path';
  final ext = path.split('.').last.toLowerCase();
  if (!['jpg', 'jpeg', 'png'].contains(ext)) {
    return 'Ảnh phải là .jpg, .jpeg hoặc .png';
  }
  if (f.lengthSync() > 5 * 1024 * 1024) {
    return 'Ảnh lớn hơn 5MB, hãy chọn ảnh nhỏ hơn.';
  }
  return null;
}

/// Copy ảnh vào `assets/members/<mssv>.<ext>`, xoá ảnh cũ khác đuôi.
void _installPhoto(String src, Map<String, dynamic> m) {
  final mssv = m['mssv'] as String;
  var ext = src.split('.').last.toLowerCase();
  if (ext == 'jpeg') ext = 'jpg';
  final old = _existingPhoto(mssv);
  final dest = '$_photoDir/$mssv.$ext';
  Directory(_p(_photoDir)).createSync(recursive: true);
  File(src).copySync(_p(dest));
  if (old != null && old != dest) File(_p(old)).deleteSync();
  m['anh'] = dest;
  stdout.writeln('  ✓ ảnh → $dest');
}

String? _existingPhoto(String mssv) {
  for (final ext in ['jpg', 'png']) {
    final p = '$_photoDir/$mssv.$ext';
    if (File(_p(p)).existsSync()) return p;
  }
  return null;
}

// ---------------------------------------------------------------- tiện ích

List<FileSystemEntity> _ideFiles() => [
  if (Directory(_p('.idea')).existsSync()) Directory(_p('.idea')),
  ...root.listSync().whereType<File>().where((f) => f.path.endsWith('.iml')),
  if (Directory(_p('android')).existsSync())
    ...Directory(_p('android'))
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.iml')),
];

void _printTeam(List<Map<String, dynamic>> members, String? current) {
  stdout.writeln('\nDanh sách nhóm (members.json):');
  for (var i = 0; i < members.length; i++) {
    final m = members[i];
    final mark = m['mssv'] == current ? '  ← người nộp' : '';
    stdout.writeln(
      '  ${i + 1}. ${m['mssv']}  ${m['ho_ten']}  (${m['vai_tro']})$mark',
    );
  }
}

void _title(String t) {
  stdout.writeln('\n${'=' * 60}\n  $t\n${'=' * 60}');
}

void _row(String k, Object? v) => stdout.writeln('  ${k.padRight(20)}: $v');

Never _fail(String msg) {
  stderr.writeln('\n✗ $msg');
  exit(1);
}

Future<int> _run(String cmd, List<String> args, {bool quiet = false}) async {
  final p = await Process.start(
    cmd,
    args,
    workingDirectory: root.path,
    runInShell: true,
    mode: quiet ? ProcessStartMode.normal : ProcessStartMode.inheritStdio,
  );
  if (quiet) {
    await p.stdout.drain<void>();
    await p.stderr.drain<void>();
  }
  return p.exitCode;
}

Directory _findRoot() {
  var d = Directory.current.absolute;
  while (true) {
    if (File('${d.path}/$_membersFile').existsSync() &&
        File('${d.path}/pubspec.yaml').existsSync()) {
      return d;
    }
    final parent = d.parent;
    if (parent.path == d.path) {
      stderr.writeln(
        'Không tìm thấy $_membersFile — hãy chạy trong thư mục project.',
      );
      exit(1);
    }
    d = parent;
  }
}

String _p(String rel) => '${root.path}/$rel';
String _read(String rel) => File(_p(rel)).readAsStringSync();
void _write(String rel, String content) =>
    File(_p(rel)).writeAsStringSync(content);
