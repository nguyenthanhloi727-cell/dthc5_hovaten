import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import 'text_tools.dart';

/// Ngôn ngữ hỗ trợ trong tab Dịch.
class AppLanguage {
  final TranslateLanguage ml;
  final String name;

  /// Locale cho speech_to_text.
  final String speechLocale;

  const AppLanguage(this.ml, this.name, this.speechLocale);

  /// Mã BCP-47 (vd "vi") - cũng là tên model ML Kit.
  String get code => ml.bcpCode;

  static const all = <AppLanguage>[
    AppLanguage(TranslateLanguage.vietnamese, 'Tiếng Việt', 'vi_VN'),
    AppLanguage(TranslateLanguage.english, 'Tiếng Anh', 'en_US'),
    AppLanguage(TranslateLanguage.french, 'Tiếng Pháp', 'fr_FR'),
    AppLanguage(TranslateLanguage.german, 'Tiếng Đức', 'de_DE'),
    AppLanguage(TranslateLanguage.spanish, 'Tiếng Tây Ban Nha', 'es_ES'),
    AppLanguage(TranslateLanguage.japanese, 'Tiếng Nhật', 'ja_JP'),
    AppLanguage(TranslateLanguage.korean, 'Tiếng Hàn', 'ko_KR'),
    AppLanguage(TranslateLanguage.chinese, 'Tiếng Trung', 'zh_CN'),
  ];
}

enum ModelStatus { unknown, checking, downloading, ready, error }

/// Trạng thái dùng chung giữa các tab Dịch: cặp ngôn ngữ, model offline,
/// translator ML Kit.
class TranslationController extends ChangeNotifier {
  final _models = OnDeviceTranslatorModelManager();
  final _langId = LanguageIdentifier(confidenceThreshold: 0.5);

  AppLanguage source = AppLanguage.all[1]; // Anh
  AppLanguage target = AppLanguage.all[0]; // Việt

  ModelStatus status = ModelStatus.unknown;
  String statusText = 'Chưa kiểm tra model';

  /// Tiến trình tải model: số model đã xong / tổng số cần tải.
  int stepDone = 0;
  int stepTotal = 0;

  OnDeviceTranslator? _translator;
  Future<bool>? _ensuring;
  bool _disposed = false;

  bool get isBusy =>
      status == ModelStatus.checking || status == ModelStatus.downloading;

  void setSource(AppLanguage l) => _setPair(l, target);
  void setTarget(AppLanguage l) => _setPair(source, l);
  void swap() => _setPair(target, source);

  void _setPair(AppLanguage s, AppLanguage t) {
    if (s == source && t == target) return;
    source = s;
    target = t;
    _translator?.close();
    _translator = null;
    status = ModelStatus.unknown;
    statusText = 'Chưa kiểm tra model';
    _notify();
    ensureModels();
  }

  /// Kiểm tra và tự tải model offline cho cặp ngôn ngữ hiện tại.
  Future<bool> ensureModels() {
    return _ensuring ??= _doEnsure().whenComplete(() => _ensuring = null);
  }

  Future<bool> _doEnsure() async {
    final pair = (source, target);
    status = ModelStatus.checking;
    statusText = 'Đang kiểm tra model offline...';
    stepDone = 0;
    stepTotal = 0;
    _notify();
    try {
      final langs = {source, target}.toList();
      final missing = <AppLanguage>[];
      for (final l in langs) {
        if (!await _models.isModelDownloaded(l.code)) missing.add(l);
      }
      stepTotal = missing.length;
      for (final l in missing) {
        status = ModelStatus.downloading;
        statusText =
            'Đang tải model ${l.name} (${stepDone + 1}/$stepTotal, ~30MB, lần đầu)...';
        _notify();
        final ok = await _models.downloadModel(l.code, isWifiRequired: false);
        if (!ok) {
          throw PlatformException(code: 'download', message: 'Tải thất bại');
        }
        stepDone++;
        _notify();
      }
      // Người dùng đổi cặp ngôn ngữ trong lúc tải -> kiểm tra lại cặp mới.
      if (pair != (source, target)) return await _doEnsure();
      status = ModelStatus.ready;
      statusText =
          'Model ${source.name} → ${target.name} đã sẵn sàng (offline)';
      _notify();
      return true;
    } on MissingPluginException {
      status = ModelStatus.error;
      statusText = 'ML Kit chỉ chạy trên Android/iOS.';
    } on PlatformException catch (e) {
      status = ModelStatus.error;
      statusText =
          'Chưa tải được model dịch (${e.message ?? e.code}). '
          'Kiểm tra kết nối mạng rồi thử lại.';
    } catch (e) {
      status = ModelStatus.error;
      statusText = 'Lỗi model dịch: $e';
    }
    _notify();
    return false;
  }

  /// Dịch [text]; ném [StateError] với thông báo dễ hiểu nếu chưa có model.
  Future<String> translate(String text) async {
    final input = text.trim();
    if (input.isEmpty) return '';
    if (source == target) return input;
    if (!await ensureModels()) {
      throw StateError(statusText);
    }
    final translator = _translator ??= OnDeviceTranslator(
      sourceLanguage: source.ml,
      targetLanguage: target.ml,
    );
    try {
      // Dịch từng câu: model offline dịch câu ngắn chính xác hơn nhiều so với
      // cả khối văn bản dài, và giữ nguyên ngắt dòng.
      final parts = splitSentences(input);
      final out = <String>[];
      for (final p in parts) {
        out.add(p == '\n' ? p : await translator.translateText(p));
      }
      return joinSentences(out);
    } on PlatformException catch (e) {
      throw StateError('Dịch thất bại: ${e.message ?? e.code}');
    }
  }

  /// Nhận diện ngôn ngữ của [text] (ML Kit Language ID, offline).
  /// Trả null nếu không chắc chắn hoặc không thuộc danh sách hỗ trợ.
  Future<AppLanguage?> detectLanguage(String text) async {
    final t = text.trim();
    if (t.length < 8) return null;
    try {
      final tag = await _langId.identifyLanguage(t);
      if (tag == _langId.undeterminedLanguageCode) return null;
      return AppLanguage.all
          .where((l) => l.code == tag || tag.startsWith('${l.code}-'))
          .firstOrNull;
    } catch (_) {
      return null;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _translator?.close();
    _langId.close();
    super.dispose();
  }
}
