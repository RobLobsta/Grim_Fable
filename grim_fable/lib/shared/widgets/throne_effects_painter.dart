import 'dart:math';
import 'package:flutter/material.dart';

class ThroneEffectsPainter extends CustomPainter {
  final double pulseValue;
  final double infamyFactor;

  ThroneEffectsPainter({
    required this.pulseValue,
    required this.infamyFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (infamyFactor <= 0) return;

    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    // Divine Pulse effect (expanding rings from center)
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = max(size.width, size.height) * 0.8;

    // Number of rings depends on infamy
    int ringCount = (3 + (infamyFactor * 5)).toInt();

    for (int i = 0; i < ringCount; i++) {
      double phase = (pulseValue + (i / ringCount)) % 1.0;
      double radius = phase * maxRadius;
      double opacity = (1.0 - phase) * 0.15 * infamyFactor;

      paint.color = const Color(0xFF4A0000).withValues(alpha: opacity);
      canvas.drawCircle(center, radius, paint);
    }

    // Independent Shadow effect (random dark wisps at the edges)
    final random = Random(42);
    int wispCount = (10 + (infamyFactor * 30)).toInt();

    for (int i = 0; i < wispCount; i++) {
      double angle = random.nextDouble() * 2 * pi;
      double dist = (0.7 + random.nextDouble() * 0.3) * max(size.width, size.height) / 2;
      Offset wispPos = center + Offset(cos(angle) * dist, sin(angle) * dist);

      double wispSize = (20 + random.nextDouble() * 40) * (1 + infamyFactor);
      double wispOpacity = (0.1 + random.nextDouble() * 0.2) * infamyFactor;

      paint.color = Colors.black.withValues(alpha: wispOpacity);
      canvas.drawCircle(wispPos, wispSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ThroneEffectsPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue || oldDelegate.infamyFactor != infamyFactor;
  }
}
