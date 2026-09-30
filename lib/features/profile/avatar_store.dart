import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';

import '../common/native_bridge.dart';

/// Lưu ảnh đại diện người dùng tự chọn vào thư mục riêng của app, để mở lại
/// app vẫn còn. Không có ảnh tự chọn thì tab Cá nhân dùng ảnh trong
/// assets/members/ (hoặc chữ cái đầu).
class AvatarStore {
  AvatarStore._();

  static const _fileName = 'avatar.jpg';

  static Future<File?> _file() async {
    final dir = await NativeBridge.filesDir();
    return dir == null ? null : File('$dir/$_fileName');
  }

  /// Ảnh đã lưu, null nếu chưa có.
  static Future<File?> load() async {
    final f = await _file();
    return f != null && f.existsSync() ? f : null;
  }

  /// Chép ảnh vừa chọn vào bộ nhớ app, trả về file đã lưu.
  static Future<File> save(XFile picked) async {
    final f = await _file();
    if (f == null) throw StateError('Không lưu được ảnh trên thiết bị này.');
    await f.writeAsBytes(await picked.readAsBytes(), flush: true);
    // Xoá ảnh cũ khỏi cache để Image.file hiện ảnh mới.
    await FileImage(f).evict();
    return f;
  }

  static Future<void> clear() async {
    final f = await _file();
    if (f != null && f.existsSync()) {
      await FileImage(f).evict();
      await f.delete();
    }
  }
}
