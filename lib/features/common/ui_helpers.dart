import 'package:flutter/material.dart';

import 'native_bridge.dart';

/// Hiện lỗi dạng SnackBar; nếu [openSettings] thì có nút mở Cài đặt ứng dụng.
void showError(
  BuildContext context,
  String message, {
  bool openSettings = false,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
        action: openSettings
            ? SnackBarAction(
                label: 'Cài đặt',
                textColor: Colors.white,
                onPressed: NativeBridge.openAppSettings,
              )
            : null,
      ),
    );
}

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
