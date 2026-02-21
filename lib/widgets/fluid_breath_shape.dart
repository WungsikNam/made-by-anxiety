import 'dart:math' as math;
import 'package:flutter/material.dart';

class FluidBreathShape extends StatefulWidget {
  final Animation<double> animation;
  final Color fluidColor;

  const FluidBreathShape({
    super.key,
    required this.animation,
    required this.fluidColor,
  });

  @override
  State<FluidBreathShape> createState() => _FluidBreathShapeState();
}

class _FluidBreathShapeState extends State<FluidBreathShape> with SingleTickerProviderStateMixin {
  late AnimationController _wobbleController;

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.animation, _wobbleController]),
      builder: (context, child) {
        final scale = widget.animation.value;
        final pulse = math.sin(_wobbleController.value * math.pi * 2);
        
        // Use a perfectly fixed size container so the Stack above it never changes size,
        // thereby preventing layout shifts (bouncing fonts).
        return CustomPaint(
          size: const Size(280, 280),
          painter: _EclipsePainter(
            scale: scale,
            pulse: pulse,
            color: widget.fluidColor,
          ),
        );
      },
    );
  }
}

class _EclipsePainter extends CustomPainter {
  final double scale;
  final double pulse;
  final Color color;

  _EclipsePainter({required this.scale, required this.pulse, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * scale;
    
    // "Dreamy" ethereal glow: much wider, softer, and more dynamic
    final double pulseScale = 1.0 + (0.1 * pulse); // Aura physically expands slightly with pulse
    final double maxGlowOpacity = (0.16 + 0.06 * pulse).clamp(0.0, 1.0);
    
    // Deep Outer Fog (Massive spread, very low opacity)
    const int deepSteps = 16;
    for (int i = deepSteps; i >= 1; i--) {
      final double stepOpacity = (maxGlowOpacity * 0.3 / i).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = color.withOpacity(stepOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 + (i * 9.0 * pulseScale);
      canvas.drawCircle(center, radius, paint);
    }

    // Intense Inner Aura (Closer to the ring, higher opacity)
    const int innerSteps = 8;
    for (int i = innerSteps; i >= 1; i--) {
      final double stepOpacity = (maxGlowOpacity / (i * 0.4)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = color.withOpacity(stepOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + (i * 3.5);
      canvas.drawCircle(center, radius, paint);
    }
    
    // Core Eclipse Ring - Layered for a "luminous neon" effect
    final coreBlur = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
      
    final coreSolid = Paint()
      ..color = color.withOpacity(1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, radius, coreBlur);
    canvas.drawCircle(center, radius, coreSolid);
  }

  @override
  bool shouldRepaint(covariant _EclipsePainter oldDelegate) {
    return oldDelegate.scale != scale || oldDelegate.pulse != pulse || oldDelegate.color != color;
  }
}
