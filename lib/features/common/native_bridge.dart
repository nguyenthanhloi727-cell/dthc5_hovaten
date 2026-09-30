import 'package:flutter/services.dart';

/// Gọi code Android trong MainActivity.java qua MethodChannel "app/native".
class NativeBridge {
  NativeBridge._();

  static const _channel = MethodChannel('app/native');

  /// Gửi intent android.intent.action.SET_ALARM (extras HOUR, MINUTES,
  /// MESSAGE) sang app Đồng hồ. Ném [PlatformException] code
  /// `NO_CLOCK_APP` nếu máy không có app Đồng hồ.
  static Future<void> setAlarm({
    required int hour,
    required int minutes,
    required String message,
  }) => _channel.invokeMethod('setAlarm', {
    'hour': hour,
    'minutes': minutes,
    'message': message,
  });

  /// Thư mục lưu trữ riêng của app (Context.getFilesDir), null nếu không
  /// chạy trên Android.
  static Future<String?> filesDir() async {
    try {
      return await _channel.invokeMethod<String>('filesDir');
    } on MissingPluginException {
      return null;
    }
  }

  /// Mở trang Cài đặt của app (để bật lại quyền micro/camera).
  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } on MissingPluginException {
      // Không chạy trên Android (vd widget test) -> bỏ qua.
    }
  }
}
