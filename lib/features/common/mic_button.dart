import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Nút micro "sống": khi đang nghe có các vòng sóng lan ra liên tục, và một
/// quầng sáng phình to theo âm lượng thật mà micro thu được.
class MicButton extends StatefulWidget {
  final bool listening;

  /// Âm lượng thô từ speech_to_text (Android khoảng -2..10 dB).
  final double soundLevel;
  final VoidCallback onPressed;
  final double size;

  const MicButton({
    super.key,
    required this.listening,
    required this.soundLevel,
    required this.onPressed,
    this.size = 88,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late final _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  double _level = 0; // đã chuẩn hoá & làm mượt, 0..1

  @override
  void didUpdateWidget(MicButton old) {
    super.didUpdateWidget(old);
    if (widget.listening && !_ripple.isAnimating) {
      _ripple.repeat();
    } else if (!widget.listening && _ripple.isAnimating) {
      _ripple
        ..stop()
        ..reset();
    }
    final target = widget.listening
        ? ((widget.soundLevel + 2) / 12).clamp(0.0, 1.0).toDouble()
        : 0.0;
    // Làm mượt: lên nhanh, xuống chậm cho giống VU meter.
    _level = target > _level ? target : _level * 0.6 + target * 0.4;
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = widget.listening ? Colors.red : scheme.primary;
    final box = widget.size * 2.2;
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vòng sóng lan toả.
          AnimatedBuilder(
            animation: _ripple,
            builder: (_, _) => CustomPaint(
              size: Size.square(box),
              painter: _RipplePainter(
                progress: widget.listening ? _ripple.value : null,
                color: active,
                baseRadius: widget.size / 2,
              ),
            ),
          ),
          // Quầng sáng theo âm lượng.
          AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: widget.size * (1 + 0.55 * _level),
            height: widget.size * (1 + 0.55 * _level),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active.withValues(alpha: widget.listening ? 0.22 : 0),
            ),
          ),
          Material(
            color: widget.listening ? Colors.red : scheme.primaryContainer,
            shape: const CircleBorder(),
            elevation: widget.listening ? 6 : 3,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onPressed,
              child: SizedBox.square(
                dimension: widget.size,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (c, a) =>
                      ScaleTransition(scale: a, child: c),
                  child: widget.listening
                      ? _Bars(key: const ValueKey('bars'), level: _level)
                      : Icon(
                          Icons.mic,
                          key: const ValueKey('mic'),
                          size: widget.size * 0.45,
                          color: scheme.onPrimaryContainer,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 5 vạch sóng âm nhảy theo âm lượng (hiện trong nút khi đang nghe).
class _Bars extends StatelessWidget {
  final double level;
  const _Bars({super.key, required this.level});

  static const _shape = [0.45, 0.75, 1.0, 0.75, 0.45];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final s in _shape)
          AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: 5,
            height: 8 + 30 * s * math.max(level, 0.12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double? progress;
  final Color color;
  final double baseRadius;

  _RipplePainter({
    required this.progress,
    required this.color,
    required this.baseRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress;
    if (p == null) return;
    final center = size.center(Offset.zero);
    final maxR = size.width / 2;
    for (var i = 0; i < 3; i++) {
      final t = (p + i / 3) % 1.0;
      final r = baseRadius + (maxR - baseRadius) * t;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = color.withValues(alpha: (1 - t) * 0.5);
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.progress != progress;
}
