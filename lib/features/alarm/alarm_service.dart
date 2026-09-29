import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';

/// Đặt báo thức THẬT vào app Đồng hồ của hệ thống qua
/// `android.intent.action.SET_ALARM` (cần quyền
/// `com.android.alarm.permission.SET_ALARM` trong AndroidManifest).
class AlarmService {
  static const _action = 'android.intent.action.SET_ALARM';

  /// Ném [UnsupportedError] nếu không có app Đồng hồ xử lý được intent.
  static Future<void> setAlarm({
    required int hour,
    required int minute,
    required String message,
    bool skipUi = false,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Chỉ hỗ trợ đặt báo thức trên Android.');
    }
    final intent = AndroidIntent(
      action: _action,
      arguments: <String, dynamic>{
        'android.intent.extra.alarm.HOUR': hour,
        'android.intent.extra.alarm.MINUTES': minute,
        'android.intent.extra.alarm.MESSAGE': message,
        'android.intent.extra.alarm.SKIP_UI': skipUi,
      },
    );
    final canResolve = await intent.canResolveActivity() ?? false;
    if (!canResolve) {
      throw UnsupportedError(
        'Máy không có app Đồng hồ hỗ trợ đặt báo thức (thường gặp trên emulator).',
      );
    }
    await intent.launch();
  }
}
