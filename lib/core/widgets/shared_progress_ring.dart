import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Circular progress ring showing combined "Our Energy" for duo partners.
///
/// Renders as a thick arc with a coral gradient, with optional dual-avatar
/// centre display. Used on the Home Dashboard screen.
class SharedProgressRing extends StatelessWidget {
  const SharedProgressRing({
    super.key,
    required this.progress,
    this.size = 180,
    this.strokeWidth = 14,
    this.child,
  });

  /// Combined progress value between 0.0 and 1.0.
  final double progress;

  /// Outer diameter of the ring.
  final double size;

  /// Thickness of the ring stroke.
  final double strokeWidth;

  /// Widget to render at the centre (e.g. avatars or a label).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  progress: value,
                  strokeWidth: strokeWidth,
                  trackColor:
                      Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
                ),
              );
            },
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track (background circle)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Progress arc with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * math.pi * progress;
    const startAngle = -math.pi / 2; // 12 o'clock

    final paint = Paint()
      ..color = const Color(0xFFFF7F6E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress;
}
