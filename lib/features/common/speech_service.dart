import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Lỗi thân thiện để hiện cho người dùng.
class SpeechException implements Exception {
  final String message;

  /// true khi quyền mic bị chặn vĩnh viễn -> cần mở Cài đặt.
  final bool openSettings;

  const SpeechException(this.message, {this.openSettings = false});

  @override
  String toString() => message;
}

/// Bọc speech_to_text dùng chung cho Báo thức và Dịch.
///
/// speech_to_text chỉ nhận listener onError/onStatus ở lần initialize đầu
/// tiên, nên dùng 1 instance duy nhất và tự chuyển tiếp sự kiện cho màn hình
/// đang nghe.
class SpeechService {
  SpeechService._();
  static final instance = SpeechService._();

  final _speech = SpeechToText();
  bool _ready = false;
  List<String>? _localeIds;

  void Function(String message)? _onError;
  VoidCallback? _onDone;

  bool get isListening => _speech.isListening;

  Future<void> _ensureReady() async {
    final status = await Permission.microphone.request();
    if (status.isPermanentlyDenied || status.isRestricted) {
      throw const SpeechException(
        'Quyền micro đã bị chặn. Hãy bật lại trong Cài đặt ứng dụng.',
        openSettings: true,
      );
    }
    if (!status.isGranted) {
      throw const SpeechException(
        'Cần cấp quyền micro để nhận dạng giọng nói.',
      );
    }
    if (_ready) return;
    _ready = await _speech.initialize(
      onError: _handleError,
      onStatus: (s) {
        if (s == SpeechToText.doneStatus ||
            s == SpeechToText.notListeningStatus) {
          _onDone?.call();
        }
      },
    );
    if (!_ready) {
      throw const SpeechException(
        'Thiết bị không hỗ trợ nhận dạng giọng nói '
        '(emulator cần bật micro và có app Google).',
      );
    }
  }

  void _handleError(SpeechRecognitionError e) {
    final msg = switch (e.errorMsg) {
      'error_no_match' => 'Không nhận ra giọng nói, hãy nói lại rõ hơn.',
      'error_speech_timeout' => 'Không nghe thấy gì, hãy thử lại.',
      'error_network' ||
      'error_network_timeout' => 'Lỗi mạng khi nhận dạng giọng nói.',
      'error_audio_error' => 'Không thu được âm thanh từ micro.',
      'error_permission' ||
      'error_insufficient_permissions' => 'Chưa có quyền micro.',
      'error_language_not_supported' ||
      'error_language_unavailable' => 'Ngôn ngữ này chưa được hỗ trợ trên máy.',
      'error_busy' ||
      'error_server_disconnected' => 'Bộ nhận dạng đang bận, thử lại sau.',
      _ => 'Lỗi nhận dạng giọng nói: ${e.errorMsg}',
    };
    _onError?.call(msg);
    _onDone?.call();
  }

  /// Kiểm tra máy có gói ngôn ngữ này không (trả null nếu không biết).
  Future<bool?> supportsLocale(String localeId) async {
    try {
      await _ensureReady();
      _localeIds ??= (await _speech.locales()).map((l) => l.localeId).toList();
      if (_localeIds!.isEmpty) return null;
      final want = localeId.replaceAll('-', '_').toLowerCase();
      return _localeIds!.any(
        (id) => id.replaceAll('-', '_').toLowerCase() == want,
      );
    } catch (_) {
      return null;
    }
  }

  /// Bắt đầu nghe. [onResult] nhận text (cả kết quả tạm), [onError] nhận lỗi
  /// thân thiện, [onDone] khi phiên nghe kết thúc.
  Future<void> listen({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
    required void Function(String message) onError,
    required VoidCallback onDone,
  }) async {
    await _ensureReady();
    _onError = onError;
    _onDone = onDone;
    if (_speech.isListening) await _speech.stop();
    await _speech.listen(
      onResult: (SpeechRecognitionResult r) =>
          onResult(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() async {
    _onError = null;
    _onDone = null;
    if (_ready) await _speech.cancel();
  }
}
