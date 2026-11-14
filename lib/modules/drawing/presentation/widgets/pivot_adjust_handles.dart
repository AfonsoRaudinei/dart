import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Cruz com setas nas pontas — arrastar move o centro do pivô.
class PivotMoveCrossHandle extends StatelessWidget {
  const PivotMoveCrossHandle({super.key});

  static const double size = 72;

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PivotMoveCrossPainter()),
    );
  }
}

class _PivotMoveCrossPainter extends CustomPainter {
  const _PivotMoveCrossPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const arm = 26.0;
    const stroke = 3.0;
    const color = Color(0xFFFF9500);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final halo = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 14, halo);
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    const directions = <Offset>[
      Offset(0, -1),
      Offset(0, 1),
      Offset(-1, 0),
      Offset(1, 0),
    ];

    for (final dir in directions) {
      final end = center + dir * arm;
      canvas.drawLine(center, end, linePaint);
      _drawArrowHead(canvas, end, dir, color);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset tip, Offset dir, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final base = tip - dir * 10;
    final perp = Offset(-dir.dy, dir.dx) * 5;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + perp.dx, base.dy + perp.dy)
      ..lineTo(base.dx - perp.dx, base.dy - perp.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Alça na borda do círculo — arrastar altera o raio.
class PivotRadiusEdgeHandle extends StatelessWidget {
  const PivotRadiusEdgeHandle({super.key});

  static const double size = 40;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFF9500), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Transform.rotate(
          angle: math.pi / 4,
          child: const Icon(
            Icons.open_in_full,
            size: 18,
            color: Color(0xFFFF9500),
          ),
        ),
      ),
    );
  }
}