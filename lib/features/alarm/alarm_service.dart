import 'dart:io';

import 'package:flutter/services.dart';

import '../common/native_bridge.dart';

/// Đặt báo thức THẬT vào app Đồng hồ của hệ thống qua
/// `android.intent.action.SET_ALARM` (xem MainActivity.java, cần quyền
/// `com.android.alarm.permission.SET_ALARM` trong AndroidManifest).
class AlarmService {
  /// Ném [UnsupportedError] nếu không có app Đồng hồ xử lý được intent.
  static Future<void> setAlarm({
    required int hour,
    required int minute,
    required String message,
  }) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Chỉ hỗ trợ đặt báo thức trên Android.');
    }
    try {
      await NativeBridge.setAlarm(
        hour: hour,
        minutes: minute,
        message: message,
      );
    } on PlatformException catch (e) {
      if (e.code == 'NO_CLOCK_APP') {
        throw UnsupportedError(
          'Máy không có app Đồng hồ hỗ trợ đặt báo thức (thường gặp trên emulator).',
        );
      }
      rethrow;
    }
  }
}
