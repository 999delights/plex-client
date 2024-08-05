import 'package:flutter/material.dart';
import 'dart:math';

class FireworksPainter extends CustomPainter {
  final Animation<double> animation;
  final Paint _paint;

  FireworksPainter(this.animation)
      : _paint = Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.fill
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true,
        super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final double progress = animation.value;
    final int numParticles = 30;
    final double radius = 5.0;
    final Random random = Random();

    // Horizontal and vertical spread factors
    final double horizontalSpreadFactor = 1.5; // For horizontal spread
    final double verticalSpreadFactor = 0.5;  // For vertical spread

    for (int i = 0; i < numParticles; i++) {
      final double angle = random.nextDouble() * 2 * pi;
      final double distance = random.nextDouble() * progress * 100;
      
      // Apply spread factors to x and y
      final double x = size.width / 2 + distance * horizontalSpreadFactor * cos(angle);
      final double y = size.height / 2 + distance * verticalSpreadFactor * sin(angle);

      _paint.color = Colors.primaries[random.nextInt(Colors.primaries.length)].withOpacity(1 - progress);
      canvas.drawCircle(Offset(x, y), radius, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}