import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  final double size;
  const GoogleLogo({super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: GoogleLogoPainter(), size: Size.square(size));
  }
}

class GoogleLogoPainter extends CustomPainter {
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  @override
  void paint(Canvas canvas, Size size) {
    final length = size.shortestSide;
    final arcThickness = length / 4.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (length / 2) - (arcThickness / 2);
    final bounds = Rect.fromCircle(center: center, radius: radius);

    void drawArc(double startAngle, double sweepAngle, Color color) {
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = arcThickness
        ..color = color;
      canvas.drawArc(bounds, startAngle, sweepAngle, false, arcPaint);
    }

    // Google Brand Colors:
    // Red: #EA4335, Yellow: #FBBC05, Green: #34A853, Blue: #4285F4
    drawArc(3.5, 1.9, const Color(0xFFEA4335));
    drawArc(2.5, 1.0, const Color(0xFFFBBC05));
    drawArc(0.9, 1.6, const Color(0xFF34A853));
    drawArc(-0.18, 1.1, const Color(0xFF4285F4));

    // Draw the horizontal bar of the 'G'
    canvas.drawRect(
      Rect.fromLTRB(
        center.dx,
        center.dy - (arcThickness / 2),
        center.dx + (length / 2),
        center.dy + (arcThickness / 2),
      ),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.fill,
    );
  }
}
