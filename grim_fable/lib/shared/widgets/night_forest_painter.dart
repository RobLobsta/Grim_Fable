import 'package:flutter/material.dart';

class NightForestPainter extends CustomPainter {
  final Color treeColor;

  NightForestPainter({this.treeColor = const Color(0xFF050B14)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = treeColor
      ..style = PaintingStyle.fill;

    // Draw background trees (smaller, slightly lighter or just more towards center)
    _drawTree(canvas, paint, Offset(size.width * 0.25, size.height), size.height * 0.5, size.width * 0.25);
    _drawTree(canvas, paint, Offset(size.width * 0.75, size.height), size.height * 0.55, size.width * 0.28);

    // Draw main trees on the left
    _drawTree(canvas, paint, Offset(size.width * 0.05, size.height), size.height * 0.85, size.width * 0.5);
    _drawTree(canvas, paint, Offset(size.width * -0.1, size.height), size.height * 0.95, size.width * 0.6);
    _drawTree(canvas, paint, Offset(size.width * 0.15, size.height), size.height * 0.65, size.width * 0.35);

    // Draw main trees on the right
    _drawTree(canvas, paint, Offset(size.width * 0.95, size.height), size.height * 0.8, size.width * 0.45);
    _drawTree(canvas, paint, Offset(size.width * 1.1, size.height), size.height * 0.9, size.width * 0.55);
    _drawTree(canvas, paint, Offset(size.width * 0.8, size.height), size.height * 0.7, size.width * 0.4);
  }

  void _drawTree(Canvas canvas, Paint paint, Offset base, double height, double width) {
    final path = Path();

    int tiers = 7;
    for (int i = 0; i < tiers; i++) {
      double t = i / (tiers - 1); // 0 to 1
      double tierWidth = width * (1 - t * 0.9);
      double tierHeight = height * 0.2;
      double tierBottomY = base.dy - (height * t * 0.8);
      double tierTopY = tierBottomY - tierHeight;

      if (i == tiers - 1) {
        // Topmost point
        path.moveTo(base.dx, tierTopY);
      } else {
        path.moveTo(base.dx, tierTopY + tierHeight * 0.3); // Slight overlap
      }

      // Left branch with a bit of "droop"
      path.quadraticBezierTo(
        base.dx - tierWidth * 0.4, tierBottomY - tierHeight * 0.1,
        base.dx - tierWidth * 0.5, tierBottomY
      );

      // Bottom edge of the tier - wavy/rounded
      path.quadraticBezierTo(
        base.dx - tierWidth * 0.25, tierBottomY - tierHeight * 0.05,
        base.dx, tierBottomY
      );
      path.quadraticBezierTo(
        base.dx + tierWidth * 0.25, tierBottomY - tierHeight * 0.05,
        base.dx + tierWidth * 0.5, tierBottomY
      );

      // Right branch back up
      path.quadraticBezierTo(
        base.dx + tierWidth * 0.4, tierBottomY - tierHeight * 0.1,
        base.dx, tierTopY
      );

      path.close();
    }

    // Draw trunk
    final trunkWidth = width * 0.15;
    final trunkHeight = height * 0.1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(base.dx, base.dy - trunkHeight / 2),
          width: trunkWidth,
          height: trunkHeight,
        ),
        const Radius.circular(4),
      ),
      paint,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
