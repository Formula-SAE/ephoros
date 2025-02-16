import "dart:math" as math show pi;

import "package:client/types/point.dart";
import "package:flutter/rendering.dart" show BoxHitTestEntry;
import "package:flutter/widgets.dart";

class LineChart extends LeafRenderObjectWidget {
  const LineChart({super.key, required this.points});

  final List<Point> points;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      LineChartRenderObject(
        points: points,
        numbersTextStyle: TextStyle(
          fontSize: 12,
          color: const Color(0xFF000000),
        ),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant LineChartRenderObject renderObject,
  ) {
    super.updateRenderObject(context, renderObject);
  }
}

class LineChartRenderObject extends RenderBox {
  LineChartRenderObject({
    required List<Point> points,
    required TextStyle numbersTextStyle,
    double zoom = 1,
  }) : _points = [...points]..sort((a, b) => a.$1.compareTo(b.$1)),
       _numbersTextStyle = numbersTextStyle,
       _zoom = zoom,
       _minX = points.first.$1,
       _maxX = points.last.$1;

  List<Point> _points;
  final TextStyle _numbersTextStyle;
  double _zoom;
  final double _minX;
  final double _maxX;

  List<Point> get points => _points;
  set points(List<Point> value) {
    if (_points == value) return;

    _points = [...value]..sort((a, b) => a.$1.compareTo(b.$1));
    markNeedsLayout();
  }

  double get zoom => _zoom;
  set zoom(double value) {
    if (_zoom == value) return;

    _zoom = value;
    markNeedsLayout();
  }

  double get minX => _minX;
  double get maxX => _maxX;

  double get _yAxisOffset => size.height * 0.9;

  @override
  bool get sizedByParent => true;
  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    return Size(constraints.maxWidth, constraints.maxHeight);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintXAxis(context, offset);
    _paintPoints(context, offset);
    // _drawXAxisNumbers(context, offset);
    _drawLine(context, offset);
  }

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    //TODO: HANDLE EVENTS
    super.handleEvent(event, entry);
  }

  void _paintXAxis(PaintingContext context, Offset offset) {
    final paint =
        Paint()
          ..color = const Color(0xFF000000)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    final path = Path();
    final yOffset = offset.dy + _yAxisOffset;

    path.moveTo(offset.dx, yOffset);
    path.lineTo(offset.dx + size.width, yOffset);

    context.canvas.drawPath(path, paint);
  }

  void _paintPoints(PaintingContext context, Offset offset) {
    final paint = Paint()..color = const Color(0xFF000000);

    for (final point in points) {
      if (!_shouldPainPoint(point)) continue;

      context.canvas.drawCircle(
        Offset(
          offset.dx + point.$1 * zoom,
          offset.dy + _yAxisOffset - point.$2 * zoom,
        ),
        2.5,
        paint,
      );
    }
  }

  void _drawXAxisNumbers(PaintingContext context, Offset offset) {
    final paint = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (final point in points) {
      final text = TextSpan(
        text: point.$1.toString(),
        style: _numbersTextStyle,
      );

      paint.text = text;

      paint.layout();
      context.canvas.save();
      context.canvas.translate(
        offset.dx + point.$1 - 8,
        offset.dy + size.height,
      );
      context.canvas.rotate(-45 * math.pi / 180);

      paint.paint(context.canvas, Offset.zero);

      context.canvas.restore();
    }
  }

  void _drawLine(PaintingContext context, Offset offset) {
    if (points.length <= 1) return;

    final paint =
        Paint()
          ..color = const Color(0xFF000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final path = Path();
    path.moveTo(
      offset.dx + points[0].$1 * zoom,
      offset.dy + _yAxisOffset - points[0].$2 * zoom,
    );

    for (int i = 1; i < points.length; i++) {
      final next = points[i];

      if (!_shouldPainPoint(next)) continue;

      final offsetNext = Offset(
        offset.dx + next.$1 * zoom,
        offset.dy + _yAxisOffset - next.$2 * zoom,
      );

      path.lineTo(offsetNext.dx, offsetNext.dy);
    }

    context.canvas.drawPath(path, paint);
  }

  bool _shouldPainPoint(Point point) {
    return point.$1 >= minX && point.$1 <= maxX;
  }
}
