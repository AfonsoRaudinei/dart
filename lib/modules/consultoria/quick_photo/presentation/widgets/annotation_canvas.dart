import 'package:flutter/material.dart';

class AnnotationStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isCircle;

  const AnnotationStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.isCircle,
  });

  AnnotationStroke copyWith({List<Offset>? points}) {
    return AnnotationStroke(
      points: points ?? this.points,
      color: color,
      strokeWidth: strokeWidth,
      isCircle: isCircle,
    );
  }
}

class AnnotationCanvas extends StatefulWidget {
  final List<AnnotationStroke> strokes;
  final Color selectedColor;
  final bool isCircleMode;
  final ValueChanged<AnnotationStroke> onStrokeAdded;

  const AnnotationCanvas({
    super.key,
    required this.strokes,
    required this.selectedColor,
    required this.isCircleMode,
    required this.onStrokeAdded,
  });

  @override
  State<AnnotationCanvas> createState() => _AnnotationCanvasState();
}

class _AnnotationCanvasState extends State<AnnotationCanvas> {
  AnnotationStroke? _currentStroke;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) {
        setState(() {
          _currentStroke = AnnotationStroke(
            points: [details.localPosition],
            color: widget.selectedColor,
            strokeWidth: 3,
            isCircle: widget.isCircleMode,
          );
        });
      },
      onPanUpdate: (details) {
        final current = _currentStroke;
        if (current == null) return;
        setState(() {
          _currentStroke = current.copyWith(
            points: [...current.points, details.localPosition],
          );
        });
      },
      onPanEnd: (_) {
        final current = _currentStroke;
        if (current != null && current.points.length > 1) {
          widget.onStrokeAdded(current);
        }
        setState(() => _currentStroke = null);
      },
      child: CustomPaint(
        painter: AnnotationPainter(
          strokes: widget.strokes,
          currentStroke: _currentStroke,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class AnnotationPainter extends CustomPainter {
  final List<AnnotationStroke> strokes;
  final AnnotationStroke? currentStroke;

  const AnnotationPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in [
      ...strokes,
      if (currentStroke != null) currentStroke!,
    ]) {
      _paintStroke(canvas, stroke);
    }
  }

  void _paintStroke(Canvas canvas, AnnotationStroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (stroke.isCircle) {
      canvas.drawOval(
        Rect.fromPoints(stroke.points.first, stroke.points.last),
        paint,
      );
      return;
    }

    final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (final point in stroke.points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant AnnotationPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke;
  }
}
