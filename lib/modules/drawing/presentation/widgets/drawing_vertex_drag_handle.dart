import 'package:flutter/material.dart';

/// Handle de arraste estilo GPS Fields (pingo d'água + setas 4 direções).
///
/// Azul semi-transparente — usado no arraste de vértices em desenho e edição.
class DrawingVertexDragHandle extends StatelessWidget {
  const DrawingVertexDragHandle({
    super.key,
    this.size = 52,
    this.color = const Color(0x990078D7),
    this.arrowColor = Colors.white,
  });

  final double size;
  final Color color;
  final Color arrowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TeardropHandlePainter(
          fill: color,
          arrow: arrowColor,
        ),
      ),
    );
  }
}

class _TeardropHandlePainter extends CustomPainter {
  const _TeardropHandlePainter({
    required this.fill,
    required this.arrow,
  });

  final Color fill;
  final Color arrow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final tipY = h * 0.92;
    final bodyCenter = Offset(w / 2, h * 0.38);
    final bodyRadius = w * 0.38;

    final path = Path()
      ..moveTo(w / 2, tipY)
      ..quadraticBezierTo(w * 0.08, h * 0.62, bodyCenter.dx - bodyRadius * 0.85, bodyCenter.dy)
      ..arcToPoint(
        Offset(bodyCenter.dx + bodyRadius * 0.85, bodyCenter.dy),
        radius: Radius.circular(bodyRadius),
        clockwise: true,
      )
      ..quadraticBezierTo(w * 0.92, h * 0.62, w / 2, tipY)
      ..close();

    final paint = Paint()
      ..color = fill
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawPath(path, paint);

    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;
    canvas.drawPath(path, border);

    // Cruz de setas (mover) no corpo do pingo
    final arrowPaint = Paint()
      ..color = arrow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final cx = bodyCenter.dx;
    final cy = bodyCenter.dy;
    final arm = bodyRadius * 0.42;
    final head = arm * 0.35;

    // Eixos
    canvas.drawLine(Offset(cx, cy - arm), Offset(cx, cy + arm), arrowPaint);
    canvas.drawLine(Offset(cx - arm, cy), Offset(cx + arm, cy), arrowPaint);

    // Pontas
    final tipPaint = Paint()
      ..color = arrow
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    void drawArrowHead(Offset tip, Offset left, Offset right) {
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(left.dx, left.dy)
          ..lineTo(right.dx, right.dy)
          ..close(),
        tipPaint,
      );
    }

    drawArrowHead(
      Offset(cx, cy - arm),
      Offset(cx - head, cy - arm + head),
      Offset(cx + head, cy - arm + head),
    );
    drawArrowHead(
      Offset(cx, cy + arm),
      Offset(cx - head, cy + arm - head),
      Offset(cx + head, cy + arm - head),
    );
    drawArrowHead(
      Offset(cx - arm, cy),
      Offset(cx - arm + head, cy - head),
      Offset(cx - arm + head, cy + head),
    );
    drawArrowHead(
      Offset(cx + arm, cy),
      Offset(cx + arm - head, cy - head),
      Offset(cx + arm - head, cy + head),
    );
  }

  @override
  bool shouldRepaint(covariant _TeardropHandlePainter oldDelegate) {
    return oldDelegate.fill != fill || oldDelegate.arrow != arrow;
  }
}
