import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../common/ui_helpers.dart';
import 'translate_widgets.dart';
import 'translation_controller.dart';

/// 4c. Chụp / chọn ảnh -> nhận dạng chữ (ML Kit) -> sửa text gốc -> dịch.
class ImageTranslateTab extends StatefulWidget {
  final TranslationController controller;

  const ImageTranslateTab({super.key, required this.controller});

  @override
  State<ImageTranslateTab> createState() => _ImageTranslateTabState();
}

class _ImageTranslateTabState extends State<ImageTranslateTab>
    with AutomaticKeepAliveClientMixin, TranslateRunner {
  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _ocrText = TextEditingController();
  File? _image;
  bool _recognizing = false;

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
        maxWidth: 2000,
        imageQuality: 90,
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
      result = null;
      error = null;
    });
    try {
      final recognized = await _recognizer.processImage(
        InputImage.fromFilePath(file.path),
      );
      if (!mounted) return;
      final text = recognized.text.trim();
      setState(() => _ocrText.text = text);
      if (text.isEmpty) showInfo(context, 'Không tìm thấy chữ trong ảnh.');
    } catch (e) {
      if (mounted) showError(context, 'Nhận dạng chữ thất bại: $e');
    } finally {
      if (mounted) setState(() => _recognizing = false);
    }
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
        const SizedBox(height: 12),
        if (_image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_image!, height: 200, fit: BoxFit.contain),
          ),
        if (_recognizing) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const Text('Đang nhận dạng chữ...'),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _ocrText,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Chữ nhận dạng được (sửa trước khi dịch)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: translating || _recognizing
              ? null
              : () => runTranslate(_ocrText.text),
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
