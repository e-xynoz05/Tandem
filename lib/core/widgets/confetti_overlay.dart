import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A single particle in the confetti plume.
class ConfettiParticle {
  ConfettiParticle({
    required this.color,
    required this.position,
    required this.velocity,
  });

  final Color color;
  Offset position;
  Offset velocity;
  double life = 1.0;
}

/// Lightweight confetti effect wrapper.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, required this.child});

  final Widget child;

  static void show(BuildContext context) {
    final state = context.findAncestorStateOfType<_ConfettiOverlayState>();
    state?.trigger();
  }

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        _updateParticles();
        setState(() {});
      });
  }

  void trigger() {
    _particles.clear();
    final colors = [
      const Color(0xFFFF7F6E), // Coral
      const Color(0xFFA43B2F), // Dark Coral
      const Color(0xFF1A1C1A), // Black
      Colors.white,
    ];

    // Create 20 particles as requested
    for (int i = 0; i < 20; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 2.0 + _random.nextDouble() * 4.0;
      _particles.add(
        ConfettiParticle(
          color: colors[_random.nextInt(colors.length)],
          position: Offset(
            MediaQuery.of(context).size.width / 2,
            MediaQuery.of(context).size.height / 2,
          ),
          velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        ),
      );
    }
    _controller.forward(from: 0);
  }

  void _updateParticles() {
    for (var p in _particles) {
      p.position += p.velocity;
      p.velocity += const Offset(0, 0.15); // gravity
      p.life -= 0.015;
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_controller.isAnimating)
          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(particles: _particles),
            ),
          ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles});

  final List<ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.life)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.position, 4.0 + (p.life * 4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
