package com.nguyen_thanh_loi.app;

import android.content.Intent;
import android.net.Uri;
import android.provider.AlarmClock;
import android.provider.Settings;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    // Kênh gọi từ Dart: lib/features/common/native_bridge.dart
    private static final String CHANNEL = "app/native";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "setAlarm": {
                            // Đặt báo thức vào app Đồng hồ của hệ thống
                            // (cần quyền com.android.alarm.permission.SET_ALARM).
                            Integer hour = call.argument("hour");
                            Integer minutes = call.argument("minutes");
                            String message = call.argument("message");
                            if (hour == null || minutes == null) {
                                result.error("BAD_ARGS", "Thiếu giờ/phút", null);
                                return;
                            }
                            Intent intent = new Intent(AlarmClock.ACTION_SET_ALARM)
                                    .putExtra(AlarmClock.EXTRA_HOUR, (int) hour)
                                    .putExtra(AlarmClock.EXTRA_MINUTES, (int) minutes)
                                    .putExtra(AlarmClock.EXTRA_MESSAGE, message);
                            if (intent.resolveActivity(getPackageManager()) == null) {
                                result.error("NO_CLOCK_APP", "Không có app Đồng hồ", null);
                                return;
                            }
                            startActivity(intent);
                            result.success(true);
                            break;
                        }
                        case "openAppSettings": {
                            // Mở trang Cài đặt của app để người dùng bật lại quyền.
                            Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                    Uri.fromParts("package", getPackageName(), null));
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                            startActivity(intent);
                            result.success(true);
                            break;
                        }
                        case "filesDir":
                            // Thư mục riêng của app (lưu ảnh đại diện tự chọn).
                            result.success(getFilesDir().getAbsolutePath());
                            break;
                        default:
                            result.notImplemented();
                    }
                });
    }
}
