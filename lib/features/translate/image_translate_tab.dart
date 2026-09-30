import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../common/ui_helpers.dart';
import 'image_quality.dart';
import 'text_tools.dart';
import 'translate_widgets.dart';
import 'translation_controller.dart';

/// 4c. Chụp / chọn ảnh -> kiểm định chất lượng -> nhận dạng chữ (ML Kit)
/// -> lọc dòng rác + nối dòng -> sửa text gốc -> dịch.
class ImageTranslateTab extends StatefulWidget {
  final TranslationController controller;

  const ImageTranslateTab({super.key, required this.controller});

  @override
  State<ImageTranslateTab> createState() => _ImageTranslateTabState();
}

/// Kết quả kiểm định 1 ảnh.
class _Report {
  final ImageQuality? quality;
  final double? ocrConfidence; // 0..1, null nếu máy không trả về
  final int keptLines;
  final int droppedLines;
  final AppLanguage? detected;

  const _Report({
    required this.quality,
    required this.ocrConfidence,
    required this.keptLines,
    required this.droppedLines,
    required this.detected,
  });

  bool get lowConfidence => ocrConfidence != null && ocrConfidence! < 0.7;
  bool get shouldRetake =>
      keptLines == 0 || lowConfidence || (quality != null && !quality!.isGood);
}

class _ImageTranslateTabState extends State<ImageTranslateTab>
    with AutomaticKeepAliveClientMixin, TranslateRunner {
  /// Dòng có độ tin cậy dưới ngưỡng này bị coi là nhận dạng sai.
  static const _minLineConfidence = 0.5;

  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _ocrText = TextEditingController();
  File? _image;
  bool _recognizing = false;
  _Report? _report;

  // Giữ lại để bật/tắt "hiện cả dòng tin cậy thấp" mà không cần OCR lại.
  RecognizedText? _recognized;
  bool _showAll = false;

  @override
  TranslationController get controller => widget.controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _recognizer.close();
    _ocrText.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    XFile? file;
    try {
      file = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        imageQuality: 95,
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      final denied = e.code.contains('access_denied');
      showError(
        context,
        denied
            ? (source == ImageSource.camera
                  ? 'Chưa có quyền camera. Hãy cấp quyền trong Cài đặt.'
                  : 'Chưa có quyền đọc ảnh. Hãy cấp quyền trong Cài đặt.')
            : 'Không mở được ${source == ImageSource.camera ? 'camera' : 'thư viện ảnh'}: ${e.message}',
        openSettings: denied,
      );
      return;
    }
    if (file == null) return; // người dùng hủy
    setState(() {
      _image = File(file!.path);
      _recognizing = true;
      _ocrText.clear();
      _report = null;
      _recognized = null;
      result = null;
      error = null;
      mismatch = null;
    });
    try {
      final bytes = await file.readAsBytes();
      final results = await Future.wait([
        ImageQuality.analyze(bytes),
        _recognizer.processImage(InputImage.fromFilePath(file.path)),
      ]);
      final quality = results[0] as ImageQuality?;
      _recognized = results[1] as RecognizedText;
      final (text, kept, dropped, conf) = _buildText(_recognized!, _showAll);
      final detected = await controller.detectLanguage(text);
      if (!mounted) return;
      setState(() {
        _ocrText.text = text;
        _report = _Report(
          quality: quality,
          ocrConfidence: conf,
          keptLines: kept,
          droppedLines: dropped,
          detected: detected,
        );
      });
      // Chữ trong ảnh khác ngôn ngữ nguồn đang chọn -> tự đổi để dịch đúng.
      if (detected != null && detected != controller.source) {
        if (detected == controller.target) controller.swap();
        controller.setSource(detected);
        if (mounted) {
          showInfo(
            context,
            'Chữ trong ảnh là ${detected.name} → đã đổi ngôn ngữ nguồn.',
          );
        }
      }
    } catch (e) {
      if (mounted) showError(context, 'Nhận dạng chữ thất bại: $e');
    } finally {
      if (mounted) setState(() => _recognizing = false);
    }
  }

  /// Lọc dòng rác / tin cậy thấp rồi nối dòng trong từng khối chữ.
  (String, int, int, double?) _buildText(RecognizedText r, bool keepAll) {
    var kept = 0, dropped = 0;
    var confSum = 0.0, confCount = 0;
    final blocks = <String>[];
    for (final block in r.blocks) {
      final lines = <String>[];
      for (final line in block.lines) {
        final c = line.confidence;
        if (c != null) {
          confSum += c;
          confCount++;
        }
        final bad =
            isNoiseLine(line.text) || (c != null && c < _minLineConfidence);
        if (bad && !keepAll) {
          dropped++;
        } else {
          kept++;
          lines.add(line.text);
        }
      }
      final text = reflowLines(lines);
      if (text.isNotEmpty) blocks.add(text);
    }
    return (
      blocks.join('\n'),
      kept,
      dropped,
      confCount == 0 ? null : confSum / confCount,
    );
  }

  void _toggleShowAll(bool v) {
    final r = _recognized;
    setState(() => _showAll = v);
    if (r == null) return;
    final (text, kept, dropped, conf) = _buildText(r, v);
    setState(() {
      _ocrText.text = text;
      final old = _report!;
      _report = _Report(
        quality: old.quality,
        ocrConfidence: conf,
        keptLines: kept,
        droppedLines: dropped,
        detected: old.detected,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _recognizing
                    ? null
                    : () => _pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera),
                label: const Text('Chụp ảnh'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _recognizing
                    ? null
                    : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Chọn ảnh'),
              ),
            ),
          ],
        ),
        if (_image == null) ...[const SizedBox(height: 12), const _Tips()],
        const SizedBox(height: 12),
        if (_image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_image!, height: 200, fit: BoxFit.contain),
          ),
        if (_recognizing) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const Text('Đang kiểm định ảnh và nhận dạng chữ...'),
        ],
        if (_report != null) ...[
          const SizedBox(height: 12),
          _QualityCard(
            report: _report!,
            source: controller.source,
            showAll: _showAll,
            onShowAll: _toggleShowAll,
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _ocrText,
          minLines: 3,
          maxLines: 10,
          decoration: const InputDecoration(
            labelText: 'Chữ nhận dạng được (sửa trước khi dịch)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: translating || _recognizing
              ? null
              : () => runTranslate(_ocrText.text, autoSwitch: true),
          icon: const Icon(Icons.translate),
          label: const Text('Dịch'),
        ),
        const SizedBox(height: 8),
        TranslationResultCard(
          result: result,
          error: error,
          loading: translating,
        ),
      ],
    );
  }
}

class _Tips extends StatelessWidget {
  const _Tips();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Mẹo chụp để nhận dạng chính xác:\n'
          '• Chạm vào màn hình camera để lấy nét vào chữ, giữ máy yên.\n'
          '• Đủ sáng, không bị bóng hoặc lóa.\n'
          '• Chụp thẳng, chữ chiếm phần lớn khung hình.\n'
          '• Chữ in rõ nét cho kết quả tốt hơn chữ viết tay.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

/// Thẻ "Kiểm định ảnh": độ nét, độ sáng, độ tin cậy OCR, dòng đã lọc, ngôn ngữ.
class _QualityCard extends StatelessWidget {
  final _Report report;
  final AppLanguage source;
  final bool showAll;
  final ValueChanged<bool> onShowAll;

  const _QualityCard({
    required this.report,
    required this.source,
    required this.showAll,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final q = report.quality;
    final conf = report.ocrConfidence;
    final retake = report.shouldRetake;
    return Card(
      color: retake ? Colors.orange.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              dense: true,
              leading: Icon(
                retake ? Icons.report_problem : Icons.verified,
                color: retake ? Colors.orange : Colors.green,
              ),
              title: Text(
                retake ? 'Ảnh chưa đạt — nên chụp lại' : 'Ảnh đạt chất lượng',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: retake
                  ? const Text('Kết quả dịch có thể sai. Xem mẹo chụp ở trên.')
                  : null,
            ),
            if (q != null) ...[
              _check(
                ok: !q.isBlurry,
                label: 'Độ nét',
                value: q.isBlurry
                    ? 'Mờ (${q.sharpness.toStringAsFixed(0)}) — giữ máy yên, chạm lấy nét'
                    : 'Rõ (${q.sharpness.toStringAsFixed(0)})',
              ),
              _check(
                ok: !q.isDark && !q.isOverexposed,
                label: 'Độ sáng',
                value: q.isDark
                    ? 'Quá tối'
                    : q.isOverexposed
                    ? 'Quá chói'
                    : 'Tốt',
              ),
            ],
            _check(
              ok: !report.lowConfidence && report.keptLines > 0,
              label: 'Độ tin cậy nhận dạng',
              value: report.keptLines == 0
                  ? 'Không tìm thấy chữ'
                  : conf == null
                  ? 'Không có số liệu'
                  : '${(conf * 100).toStringAsFixed(0)}%',
            ),
            _check(
              ok: true,
              label: 'Dòng chữ',
              value:
                  '${report.keptLines} giữ lại'
                  '${report.droppedLines > 0 ? ', ${report.droppedLines} dòng rác đã lọc' : ''}',
            ),
            _check(
              ok: report.detected == null || report.detected == source,
              label: 'Ngôn ngữ phát hiện',
              value: report.detected?.name ?? 'Không xác định',
            ),
            if (report.droppedLines > 0 || showAll)
              SwitchListTile(
                dense: true,
                title: const Text('Hiện cả dòng tin cậy thấp'),
                value: showAll,
                onChanged: onShowAll,
              ),
          ],
        ),
      ),
    );
  }

  Widget _check({
    required bool ok,
    required String label,
    required String value,
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(
        ok ? Icons.check_circle : Icons.warning_amber,
        size: 20,
        color: ok ? Colors.green : Colors.orange,
      ),
      title: Text(label),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Text(value, textAlign: TextAlign.right),
      ),
    );
  }
}
