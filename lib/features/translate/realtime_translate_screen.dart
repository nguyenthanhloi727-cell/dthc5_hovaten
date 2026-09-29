import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

import 'translate_widgets.dart';
import 'translation_controller.dart';

/// 5. (Điểm cộng) Dịch realtime: image stream của camera -> nhận dạng chữ
/// ~1 lần/giây (bỏ frame khi đang xử lý) -> dịch -> vẽ bản dịch đè lên preview.
class RealtimeTranslateScreen extends StatefulWidget {
  final TranslationController controller;

  const RealtimeTranslateScreen({super.key, required this.controller});

  @override
  State<RealtimeTranslateScreen> createState() =>
      _RealtimeTranslateScreenState();
}

class _Overlay {
  final Rect box;
  final String text;
  const _Overlay(this.box, this.text);
}

class _RealtimeTranslateScreenState extends State<RealtimeTranslateScreen>
    with WidgetsBindingObserver {
  static const _interval = Duration(milliseconds: 1000);
  static const _maxBlocks = 12;

  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _cache = <String, String>{};

  CameraController? _camera;
  String? _error;
  bool _permanentlyDenied = false;
  bool _busy = false;
  DateTime _lastRun = DateTime.fromMillisecondsSinceEpoch(0);

  Size? _imageSize; // kích thước ảnh đã xoay đứng
  List<_Overlay> _overlays = const [];

  TranslationController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl.addListener(_onPairChanged);
    _ctrl.ensureModels();
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.removeListener(_onPairChanged);
    _stopCamera();
    _recognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed &&
        _camera == null &&
        _error == null) {
      _start();
    }
  }

  String _pairKey = '';
  void _onPairChanged() {
    final key = '${_ctrl.source.code}-${_ctrl.target.code}';
    if (key != _pairKey) {
      _pairKey = key;
      _cache.clear();
      if (mounted) setState(() => _overlays = const []);
    }
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _permanentlyDenied = false;
    });
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      setState(() {
        _permanentlyDenied = status.isPermanentlyDenied || status.isRestricted;
        _error = 'Cần quyền camera để dịch realtime.';
      });
      return;
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('no_camera', 'Máy không có camera');
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final cam = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await cam.initialize();
      if (!mounted) {
        await cam.dispose();
        return;
      }
      _camera = cam;
      await cam.startImageStream((img) => _onFrame(img, back));
      setState(() {});
    } on CameraException catch (e) {
      if (!mounted) return;
      final denied = e.code.contains('Denied') || e.code.contains('denied');
      setState(() {
        _permanentlyDenied = denied;
        _error = denied
            ? 'Quyền camera bị từ chối.'
            : 'Không mở được camera: ${e.description ?? e.code}';
      });
    }
  }

  Future<void> _stopCamera() async {
    final cam = _camera;
    _camera = null;
    if (cam == null) return;
    try {
      if (cam.value.isStreamingImages) await cam.stopImageStream();
    } catch (_) {}
    await cam.dispose();
  }

  /// Throttle ~1 lần/giây và bỏ frame khi đang xử lý frame trước.
  Future<void> _onFrame(CameraImage img, CameraDescription desc) async {
    final now = DateTime.now();
    if (_busy || now.difference(_lastRun) < _interval) return;
    _busy = true;
    _lastRun = now;
    try {
      final input = _toInputImage(img, desc);
      if (input == null) return;
      final result = await _recognizer.processImage(input);
      final rotated = desc.sensorOrientation % 180 == 90;
      final size = rotated
          ? Size(img.height.toDouble(), img.width.toDouble())
          : Size(img.width.toDouble(), img.height.toDouble());

      final overlays = <_Overlay>[];
      if (_ctrl.status == ModelStatus.ready) {
        for (final block in result.blocks.take(_maxBlocks)) {
          final src = block.text.replaceAll('\n', ' ').trim();
          if (src.length < 2) continue;
          final translated = _cache[src] ??= await _ctrl.translate(src);
          overlays.add(_Overlay(block.boundingBox, translated));
        }
      }
      if (mounted) {
        setState(() {
          _imageSize = size;
          _overlays = overlays;
        });
      }
    } catch (e) {
      debugPrint('Realtime OCR lỗi: $e');
    } finally {
      _busy = false;
    }
  }

  InputImage? _toInputImage(CameraImage img, CameraDescription desc) {
    final rotation = InputImageRotationValue.fromRawValue(
      desc.sensorOrientation,
    );
    final format = InputImageFormatValue.fromRawValue(img.format.raw as int);
    if (rotation == null || format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (img.planes.length != 1) return null;
    final plane = img.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(img.width.toDouble(), img.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cam = _camera;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Dịch realtime')),
      body: Column(
        children: [
          ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                LanguageBar(controller: _ctrl),
                ModelStatusBar(controller: _ctrl),
              ],
            ),
          ),
          Expanded(
            child: _error != null
                ? _ErrorView(
                    message: _error!,
                    openSettings: _permanentlyDenied,
                    onRetry: _start,
                  )
                : cam == null || !cam.value.isInitialized
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Stack(
                      children: [
                        CameraPreview(cam),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _OverlayPainter(_overlays, _imageSize),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Container(
            width: double.infinity,
            color: Colors.black87,
            padding: const EdgeInsets.all(8),
            child: const Text(
              'Hướng camera vào chữ in (Latin). Cập nhật ~1 lần/giây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final bool openSettings;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.openSettings,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            if (openSettings)
              const FilledButton(
                onPressed: openAppSettings,
                child: Text('Mở Cài đặt'),
              )
            else
              FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final List<_Overlay> overlays;
  final Size? imageSize;

  _OverlayPainter(this.overlays, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final img = imageSize;
    if (img == null || overlays.isEmpty) return;
    final sx = size.width / img.width;
    final sy = size.height / img.height;
    final bg = Paint()..color = Colors.black.withValues(alpha: 0.72);
    for (final o in overlays) {
      final r = Rect.fromLTRB(
        o.box.left * sx,
        o.box.top * sy,
        o.box.right * sx,
        o.box.bottom * sy,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: o.text,
          style: TextStyle(
            color: Colors.yellowAccent,
            fontSize: (r.height / 2).clamp(10, 22).toDouble(),
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 4,
        ellipsis: '…',
      )..layout(maxWidth: r.width.clamp(40, size.width).toDouble());
      final box = Rect.fromLTWH(
        r.left,
        r.top,
        math.max(tp.width, r.width) + 6,
        math.max(tp.height, r.height) + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(4)),
        bg,
      );
      tp.paint(canvas, Offset(r.left + 3, r.top + 2));
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      !listEquals(old.overlays, overlays) || old.imageSize != imageSize;
}
