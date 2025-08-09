import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  const AppLogo({
    super.key,
    this.size = 100,
    this.backgroundColor = Colors.black,
    this.foregroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.15),
        boxShadow: [
          BoxShadow(
            color: foregroundColor.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(
        painter: AIRobotPainter(foregroundColor),
        size: Size(size, size),
      ),
    );
  }
}

class AIRobotPainter extends CustomPainter {
  final Color color;

  AIRobotPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.012
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFF00FFFF)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final headRadius = size.width * 0.16;

    // Robot head (circle)
    canvas.drawCircle(
      Offset(center.dx, center.dy - size.height * 0.04),
      headRadius,
      paint,
    );

    // Eyes
    final eyeRadius = size.width * 0.024;
    final eyeY = center.dy - size.height * 0.07;
    
    // Left eye
    canvas.drawCircle(
      Offset(center.dx - size.width * 0.05, eyeY),
      eyeRadius,
      fillPaint,
    );
    
    // Right eye
    canvas.drawCircle(
      Offset(center.dx + size.width * 0.05, eyeY),
      eyeRadius,
      fillPaint,
    );

    // Eye pupils with glow
    final pupilRadius = size.width * 0.012;
    canvas.drawCircle(
      Offset(center.dx - size.width * 0.05, eyeY),
      pupilRadius,
      Paint()..color = backgroundColor,
    );
    canvas.drawCircle(
      Offset(center.dx + size.width * 0.05, eyeY),
      pupilRadius,
      Paint()..color = backgroundColor,
    );

    // Glowing pupils
    canvas.drawCircle(
      Offset(center.dx - size.width * 0.05, eyeY),
      size.width * 0.006,
      glowPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + size.width * 0.05, eyeY),
      size.width * 0.006,
      glowPaint,
    );

    // Mouth (speaker grille)
    final mouthY = center.dy - size.height * 0.01;
    final mouthWidth = size.width * 0.08;
    final lineHeight = size.width * 0.006;
    
    for (int i = 0; i < 3; i++) {
      final y = mouthY + i * size.width * 0.014;
      final width = mouthWidth - i * size.width * 0.01;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx, y),
            width: width,
            height: lineHeight,
          ),
          Radius.circular(lineHeight / 2),
        ),
        fillPaint,
      );
    }

    // Antenna
    canvas.drawLine(
      Offset(center.dx, center.dy - size.height * 0.2),
      Offset(center.dx, center.dy - size.height * 0.24),
      paint,
    );
    
    canvas.drawCircle(
      Offset(center.dx, center.dy - size.height * 0.245),
      size.width * 0.016,
      fillPaint,
    );
    
    canvas.drawCircle(
      Offset(center.dx, center.dy - size.height * 0.245),
      size.width * 0.008,
      glowPaint,
    );

    // Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + size.height * 0.12),
        width: size.width * 0.24,
        height: size.width * 0.16,
      ),
      Radius.circular(size.width * 0.03),
    );
    canvas.drawRRect(bodyRect, paint);

    // Chest panel
    final chestRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + size.height * 0.12),
        width: size.width * 0.16,
        height: size.width * 0.08,
      ),
      Radius.circular(size.width * 0.016),
    );
    canvas.drawRRect(chestRect, paint);

    // Control buttons
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(
          center.dx - size.width * 0.04 + i * size.width * 0.04,
          center.dy + size.height * 0.12,
        ),
        size.width * 0.012,
        fillPaint,
      );
    }

    // Arms
    final armWidth = size.width * 0.08;
    final armHeight = size.width * 0.03;
    final armY = center.dy + size.height * 0.08;
    
    // Left arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          center.dx - size.width * 0.2,
          armY - armHeight / 2,
          armWidth,
          armHeight,
        ),
        Radius.circular(armHeight / 2),
      ),
      paint,
    );
    
    // Right arm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          center.dx + size.width * 0.12,
          armY - armHeight / 2,
          armWidth,
          armHeight,
        ),
        Radius.circular(armHeight / 2),
      ),
      paint,
    );

    // Hands
    canvas.drawCircle(
      Offset(center.dx - size.width * 0.235, armY),
      size.width * 0.024,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + size.width * 0.235, armY),
      size.width * 0.024,
      paint,
    );

    // AI Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'AI',
        style: TextStyle(
          color: color,
          fontSize: size.width * 0.07,
          fontWeight: FontWeight.bold,
          fontFamily: 'Arial',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy + size.height * 0.28,
      ),
    );

    // Circuit pattern (decorative)
    final circuitPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = size.width * 0.002;

    // Corner circuits
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.1),
      Offset(size.width * 0.2, size.height * 0.2),
      circuitPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.9, size.height * 0.1),
      Offset(size.width * 0.8, size.height * 0.2),
      circuitPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.9),
      Offset(size.width * 0.2, size.height * 0.8),
      circuitPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.9, size.height * 0.9),
      Offset(size.width * 0.8, size.height * 0.8),
      circuitPaint,
    );

    // Circuit nodes
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.15),
      size.width * 0.006,
      Paint()..color = color.withOpacity(0.3),
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      size.width * 0.006,
      Paint()..color = color.withOpacity(0.3),
    );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.85),
      size.width * 0.006,
      Paint()..color = color.withOpacity(0.3),
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.85),
      size.width * 0.006,
      Paint()..color = color.withOpacity(0.3),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}