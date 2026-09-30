// Đổi toàn bộ danh tính app sang 1 thành viên trong members.json.
//
//   dart run tool/switch_member.dart <mssv>
//   dart run tool/switch_member.dart <mssv> --no-clean   (bỏ qua flutter clean)
//
// Chỉ dùng dart:io nên chạy được mà không cần `flutter pub get`.
import 'dart:convert';
import 'dart:io';

import 'src/member_utils.dart';

const _membersFile = 'members.json';
const _currentOut = 'lib/config/current_member.dart';
const _teamOut = 'lib/config/team_members.dart';

late final Directory root;

void main(List<String> args) async {
  root = _findRoot();
  final positional = args.where((a) => !a.startsWith('--')).toList();
  final skipClean = args.contains('--no-clean');

  final data = jsonDecode(_read(_membersFile)) as Map<String, dynamic>;
  final members = (data['members'] as List).cast<Map<String, dynamic>>();

  if (positional.isEmpty) {
    stderr.writeln('Cách dùng: dart run tool/switch_member.dart <mssv>');
    _printMembers(members, data['current'] as String?);
    exit(64);
  }

  final mssv = positional.first.trim();
  final target = members.where((m) => m['mssv'] == mssv).firstOrNull;
  if (target == null) {
    stderr.writeln('Không tìm thấy MSSV "$mssv" trong $_membersFile.');
    _printMembers(members, data['current'] as String?);
    exit(1);
  }

  for (final key in ['ho_ten', 'mssv', 'sdt', 'email', 'lop', 'vai_tro']) {
    if ((target[key] ?? '').toString().trim().isEmpty) {
      stderr.writeln(
        'Thành viên $mssv thiếu trường "$key" trong $_membersFile.',
      );
      exit(1);
    }
  }

  final hoTen = target['ho_ten'] as String;
  final appName = slugify(hoTen);
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(appName)) {
    stderr.writeln(
      'Không sinh được tên app hợp lệ từ "$hoTen" (được "$appName").',
    );
    exit(1);
  }
  final appId = 'com.$appName.app';

  stdout.writeln('==> Đổi sang: $hoTen ($mssv)');
  stdout.writeln('    tên app      : $appName');
  stdout.writeln('    applicationId: $appId');

  final oldName = _renamePubspec(appName);
  _replaceImports(oldName, appName);
  _updateManifestLabel(appName);
  _updateGradle(appId);
  _moveMainActivity(appId);
  _updateIos(appName, appId);

  data['current'] = mssv;
  _write(_membersFile, '${const JsonEncoder.withIndent('  ').convert(data)}\n');
  _write(_currentOut, _genCurrent(target));
  _write(_teamOut, _genTeam(members));
  await Process.run(
    'dart',
    ['format', _currentOut, _teamOut],
    workingDirectory: root.path,
    runInShell: true,
  );
  stdout.writeln('  ✓ ghi $_currentOut, $_teamOut');

  if (!skipClean) {
    await _flutter(['clean']);
    await _flutter(['pub', 'get']);
  }

  final leaks = await _scanLeaks(members, target, oldName, appName);
  if (leaks.isEmpty) {
    stdout.writeln('\n✓ Không còn dấu vết thành viên khác trong project.');
  } else {
    stdout.writeln(
      '\n! Còn sót thông tin thành viên khác (${leaks.length} chỗ):',
    );
    leaks.forEach(stdout.writeln);
  }
  stdout.writeln('\nXong. Chạy lại app: flutter run');
}

// ---------------------------------------------------------------- các bước

String _renamePubspec(String appName) {
  var text = _read('pubspec.yaml');
  final m = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(text);
  if (m == null) throw StateError('pubspec.yaml không có dòng name:');
  final oldName = m.group(1)!;
  text = text.replaceRange(m.start, m.end, 'name: $appName');
  _write('pubspec.yaml', text);
  stdout.writeln('  ✓ pubspec.yaml: $oldName -> $appName');
  return oldName;
}

void _replaceImports(String oldName, String newName) {
  if (oldName == newName) return;
  var count = 0;
  for (final dir in ['lib', 'test', 'tool', 'integration_test']) {
    final d = Directory(_p(dir));
    if (!d.existsSync()) continue;
    for (final f in d.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final text = f.readAsStringSync();
      final updated = text.replaceAll('package:$oldName/', 'package:$newName/');
      if (updated != text) {
        f.writeAsStringSync(updated);
        count++;
      }
    }
  }
  stdout.writeln(
    '  ✓ import package:$oldName/ -> package:$newName/ ($count file)',
  );
}

void _updateManifestLabel(String label) {
  const path = 'android/app/src/main/AndroidManifest.xml';
  if (!File(_p(path)).existsSync()) return;
  final text = _read(path)
      .replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="$label"');
  _write(path, text);
  stdout.writeln('  ✓ android:label = $label');
}

void _updateGradle(String appId) {
  for (final path in [
    'android/app/build.gradle.kts',
    'android/app/build.gradle',
  ]) {
    if (!File(_p(path)).existsSync()) continue;
    final text = _read(path)
        .replaceAllMapped(
          RegExp(r'''(namespace\s*=?\s*)["'][^"']*["']'''),
          (m) => '${m[1]}"$appId"',
        )
        .replaceAllMapped(
          RegExp(r'''(applicationId\s*=?\s*)["'][^"']*["']'''),
          (m) => '${m[1]}"$appId"',
        );
    _write(path, text);
    stdout.writeln('  ✓ $path: namespace/applicationId = $appId');
  }
}

void _moveMainActivity(String appId) {
  final pkgPath = appId.split('.').join('/');
  for (final lang in ['java', 'kotlin']) {
    final srcRoot = Directory(_p('android/app/src/main/$lang'));
    if (!srcRoot.existsSync()) continue;
    final activities = srcRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (f) => RegExp(r'[\\/]MainActivity\.(java|kt)$').hasMatch(f.path),
        );
    for (final f in activities.toList()) {
      final ext = f.path.endsWith('.kt') ? 'kt' : 'java';
      final semi = ext == 'java' ? ';' : '';
      final content = f.readAsStringSync().replaceFirst(
        RegExp(r'^package\s+[\w.]+;?', multiLine: true),
        'package $appId$semi',
      );
      final dest = File('${srcRoot.path}/$pkgPath/MainActivity.$ext');
      if (_same(f, dest)) {
        dest.writeAsStringSync(content);
        continue;
      }
      dest.parent.createSync(recursive: true);
      dest.writeAsStringSync(content);
      final oldDir = f.parent;
      f.deleteSync();
      _removeEmptyDirs(oldDir, srcRoot);
    }
    stdout.writeln('  ✓ MainActivity -> $lang/$pkgPath/');
  }
}

void _updateIos(String appName, String appId) {
  const plist = 'ios/Runner/Info.plist';
  if (File(_p(plist)).existsSync()) {
    var text = _read(plist);
    for (final key in ['CFBundleDisplayName', 'CFBundleName']) {
      text = text.replaceAllMapped(
        RegExp('(<key>$key</key>\\s*<string>)[^<]*(</string>)'),
        (m) => '${m[1]}$appName${m[2]}',
      );
    }
    _write(plist, text);
    stdout.writeln('  ✓ iOS CFBundleDisplayName = $appName');
  }
  const pbx = 'ios/Runner.xcodeproj/project.pbxproj';
  if (File(_p(pbx)).existsSync()) {
    final text = _read(pbx).replaceAllMapped(
      RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]*?(\.RunnerTests)?;'),
      (m) => 'PRODUCT_BUNDLE_IDENTIFIER = $appId${m[1] ?? ''};',
    );
    _write(pbx, text);
    stdout.writeln('  ✓ iOS bundle id = $appId');
  }
}

// ---------------------------------------------------------------- sinh code

String _dartStr(Object? v) =>
    "'${(v ?? '').toString().replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$')}'";

String _memberLiteral(Map<String, dynamic> m, {String indent = '  '}) {
  final anh = (m['anh'] ?? '').toString();
  final hasPhoto = anh.isNotEmpty && File(_p(anh)).existsSync();
  return '''Member(
$indent  hoTen: ${_dartStr(m['ho_ten'])},
$indent  mssv: ${_dartStr(m['mssv'])},
$indent  sdt: ${_dartStr(m['sdt'])},
$indent  email: ${_dartStr(m['email'])},
$indent  lop: ${_dartStr(m['lop'])},
$indent  vaiTro: ${_dartStr(m['vai_tro'])},
$indent  anh: ${hasPhoto ? _dartStr(anh) : 'null'},
$indent)''';
}

const _header =
    '''// GENERATED bởi tool/switch_member.dart từ members.json — KHÔNG SỬA TAY.
// Muốn đổi: sửa members.json rồi chạy `dart run tool/switch_member.dart <mssv>`.
''';

String _genCurrent(Map<String, dynamic> m) =>
    '''$_header
import 'member.dart';

/// Thành viên đang "sở hữu" bản build này (tab Cá nhân, nút Gọi điện...).
const currentMember = ${_memberLiteral(m, indent: '')};
''';

String _genTeam(List<Map<String, dynamic>> members) =>
    '''$_header
import 'member.dart';

/// Toàn bộ thành viên nhóm (tab Nhóm), không phụ thuộc thành viên hiện tại.
const teamMembers = <Member>[
${members.map((m) => '  ${_memberLiteral(m, indent: '  ')},').join('\n')}
];
''';

// ---------------------------------------------------------------- kiểm tra sót

Future<List<String>> _scanLeaks(
  List<Map<String, dynamic>> members,
  Map<String, dynamic> current,
  String oldName,
  String newName,
) async {
  final terms = <String>{};
  for (final m in members) {
    if (identical(m, current)) continue;
    final name = (m['ho_ten'] as String).trim();
    final slug = slugify(name);
    terms.addAll([
      name.toLowerCase(),
      slug,
      slug.replaceAll('_', ''),
      m['mssv'].toString(),
      m['sdt'].toString().replaceAll(RegExp(r'\D'), ''),
      m['email'].toString().toLowerCase(),
    ]);
  }
  if (oldName != newName) terms.add(oldName.toLowerCase());
  terms.removeWhere((t) => t.length < 4);

  final tracked = await _gitVisibleFiles();
  const skipDirs = {
    'build',
    '.dart_tool',
    '.git',
    '.gradle',
    '.kotlin',
    '.cxx',
  };
  final skipFiles = {_membersFile, '$_membersFile.bak', _currentOut, _teamOut};
  final hits = <String>[];

  void walk(Directory d) {
    for (final e in d.listSync(followLinks: false)) {
      final rel = _rel(e.path);
      final base = rel.split('/').last;
      if (e is Directory) {
        if (!skipDirs.contains(base)) walk(e);
        continue;
      }
      if (e is! File || skipFiles.contains(rel)) continue;
      final ignored = tracked != null && !tracked.contains(rel);
      final tag = ignored ? ' [bị .gitignore, không nộp]' : '';
      String found(String s) =>
          terms.where(s.toLowerCase().contains).map((t) => '"$t"').join(', ');
      final inName = found(rel);
      if (inName.isNotEmpty) hits.add('  $rel (tên file chứa $inName)$tag');
      String text;
      try {
        text = e.readAsStringSync();
      } catch (_) {
        continue; // file nhị phân
      }
      final lines = text.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final f = found(lines[i]);
        if (f.isNotEmpty) hits.add('  $rel:${i + 1} chứa $f$tag');
      }
    }
  }

  walk(root);
  return hits;
}

/// Danh sách file git sẽ commit (tracked + untracked không bị ignore).
Future<Set<String>?> _gitVisibleFiles() async {
  try {
    final r = await Process.run(
      'git',
      ['ls-files', '-co', '--exclude-standard'],
      workingDirectory: root.path,
      runInShell: true,
    );
    if (r.exitCode != 0) return null;
    return (r.stdout as String)
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toSet();
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------- tiện ích

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

String _rel(String path) {
  final norm = path.replaceAll('\\', '/');
  final r = root.path.replaceAll('\\', '/');
  final s = norm.startsWith(r) ? norm.substring(r.length) : norm;
  return s.replaceFirst(RegExp(r'^/+'), '');
}

String _read(String rel) => File(_p(rel)).readAsStringSync();

void _write(String rel, String content) {
  final f = File(_p(rel));
  f.parent.createSync(recursive: true);
  f.writeAsStringSync(content);
}

bool _same(File a, File b) =>
    a.absolute.path.replaceAll('\\', '/').toLowerCase() ==
    b.absolute.path.replaceAll('\\', '/').toLowerCase();

void _removeEmptyDirs(Directory dir, Directory stopAt) {
  var d = dir;
  final stop = stopAt.absolute.path.replaceAll('\\', '/');
  while (d.absolute.path.replaceAll('\\', '/') != stop &&
      d.existsSync() &&
      d.listSync().isEmpty) {
    d.deleteSync();
    d = d.parent;
  }
}

Future<void> _flutter(List<String> args) async {
  stdout.writeln('  … flutter ${args.join(' ')}');
  final r = await Process.run(
    'flutter',
    args,
    workingDirectory: root.path,
    runInShell: true,
  );
  if (r.exitCode != 0) {
    stderr.writeln('  ! flutter ${args.join(' ')} lỗi (exit ${r.exitCode}):');
    stderr.writeln(r.stderr);
  }
}

void _printMembers(List<Map<String, dynamic>> members, String? current) {
  stderr.writeln('Các MSSV có trong $_membersFile:');
  for (final m in members) {
    final mark = m['mssv'] == current ? ' (hiện tại)' : '';
    stderr.writeln('  ${m['mssv']}  ${m['ho_ten']}$mark');
  }
}
