import "dart:math" as math show pi;

import "package:client/types/point.dart";
import "package:collection/collection.dart";
import "package:flutter/gestures.dart";
import "package:flutter/rendering.dart" show BoxHitTestEntry;
import "package:flutter/widgets.dart";

class LineChart extends LeafRenderObjectWidget {
  const LineChart({
    super.key,
    required this.points,
    this.numbersTextStyle = const TextStyle(
      fontSize: 12,
      color: Color(0xFF000000),
    ),
    this.xBaseSpacing = 8,
    this.yBaseSpacing = 2,
    this.minX,
    this.maxX,
    this.minY,
    this.maxY,
    this.pointColor = const Color(0xFF000000),
    this.lineColor = const Color(0xFF000000),
  });

  final List<Point> points;
  final TextStyle numbersTextStyle;
  final double xBaseSpacing;
  final double yBaseSpacing;
  final double? minX;
  final double? maxX;
  final double? minY;
  final double? maxY;
  final Color pointColor;
  final Color lineColor;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      LineChartRenderObject(
        points: points,
        numbersTextStyle: numbersTextStyle,
        xBaseSpacing: xBaseSpacing,
        yBaseSpacing: yBaseSpacing,
        pointColor: pointColor,
        lineColor: lineColor,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant LineChartRenderObject renderObject,
  ) {
    renderObject.points = points;
  }
}

class LineChartRenderObject extends RenderBox {
  LineChartRenderObject({
    required List<Point> points,
    required TextStyle numbersTextStyle,
    required double xBaseSpacing,
    required double yBaseSpacing,
    required Color pointColor,
    required Color lineColor,
    double zoom = 1,
    double minX = 0,
    double? maxX,
    double minY = 0,
    double? maxY,
  }) : _points = points.sortedByX(),
       _numbersTextStyle = numbersTextStyle,
       _zoom = zoom,
       _minX = 0,
       _minY = 0,
       _xBaseSpacing = xBaseSpacing,
       _yBaseSpacing = yBaseSpacing,
       _pointColor = pointColor,
       _lineColor = lineColor,
       _xOffset = 0.0,
       _yOffset = 0.0 {
    _initRecognizers();

    if (maxX != null) {
      _maxX = maxX;
    }

    if (maxY != null) {
      _maxY = maxY;
    }
  }

  List<Point> _points;
  double _zoom;

  final TextStyle _numbersTextStyle;
  final double _minX;
  final double _minY;
  final double _xBaseSpacing;
  final double _yBaseSpacing;
  final Color _pointColor;
  final Color _lineColor;

  late double _maxX;
  late double _maxY;
  late final PanGestureRecognizer _panGestureRecognizer;

  double _xOffset;
  double _yOffset;

  List<Point> get points => _points;
  set points(List<Point> value) {
    final eq = ListEquality().equals;

    if (eq(_points, value)) return;

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
  double get minY => _minY;
  double get maxY => _maxY;

  double get _xAxisOffset => size.height * 1;

  @override
  bool get sizedByParent => true;
  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    _maxX = constraints.maxWidth / zoom / _xBaseSpacing;
    _maxY = constraints.maxHeight / zoom / _yBaseSpacing;
    debugPrint("maxX: $_maxX, maxY: $_maxY");

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
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));

    if (event is PointerDownEvent) {
      _panGestureRecognizer.addPointer(event);
    }
  }

  void _paintXAxis(PaintingContext context, Offset offset) {
    final paint =
        Paint()
          ..color = const Color(0xFF000000)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    final path = Path();
    final yOffset = offset.dy + _xAxisOffset;

    path.moveTo(offset.dx, yOffset);
    path.lineTo(offset.dx + size.width, yOffset);

    context.canvas.drawPath(path, paint);
  }

  void _paintPoints(PaintingContext context, Offset offset) {
    final paint = Paint()..color = _pointColor;

    for (final point in points) {
      if (!_shouldPaintPoint(point)) continue;

      context.canvas.drawCircle(_getPointOffset(offset, point), 2.5, paint);
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

  void _drawLine(PaintingContext context, Offset chartOffset) {
    if (points.length <= 1) return;

    final paint =
        Paint()
          ..color = _lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final path = Path();

    bool started = false;
    bool previousNotPainted = false;

    for (int i = 0; i < _points.length - 1; i++) {
      final current = _points[i];
      final next = _points[i + 1];

      if (!_shouldDrawLine(current, next)) {
        continue;
      }

      final currentOffset = _getPointOffset(chartOffset, current);
      final nextOffset = _getPointOffset(chartOffset, next);

      double startX = currentOffset.dx;
      double startY = currentOffset.dy;
      double endX = nextOffset.dx;
      double endY = nextOffset.dy;

      final slope = (startY - endY) / (startX - endX);
      final intercept = startY - slope * startX;

      double getYByX(double x) => slope * x + intercept;
      double getXByY(double y) => (y - intercept) / slope;

      if (startX < chartOffset.dx) {
        startX = chartOffset.dx;
        startY = getYByX(startX);
      } else if (startX > chartOffset.dx + size.width) {
        startX = chartOffset.dx + size.width;
        startY = getYByX(startX);
      }

      if (startY < chartOffset.dy) {
        previousNotPainted = true;
        startY = chartOffset.dy;
        startX = getXByY(startY);
      } else if (startY > chartOffset.dy + _xAxisOffset) {
        previousNotPainted = true;
        startY = chartOffset.dy + _xAxisOffset;
        startX = getXByY(startY);
      }

      if (endX < chartOffset.dx) {
        endX = chartOffset.dx;
        endY = getYByX(endX);
      } else if (endX > chartOffset.dx + size.width) {
        endX = chartOffset.dx + size.width;
        endY = getYByX(endX);
      }

      if (endY < chartOffset.dy) {
        previousNotPainted = true;
        endY = chartOffset.dy;
        endX = getXByY(endY);
      } else if (endY > chartOffset.dy + _xAxisOffset) {
        previousNotPainted = true;
        endY = chartOffset.dy + _xAxisOffset;
        endX = getXByY(endY);
      }

      if (!started || previousNotPainted) {
        path.moveTo(startX, startY);
        started = true;
      }

      path.lineTo(endX, endY);
      previousNotPainted = false;
    }
    context.canvas.drawPath(path, paint);
  }

  bool _shouldPaintPoint(Point point) {
    final adjustedX = point.$1 - _xOffset;
    final adjustedY = point.$2 - _yOffset;

    final xInBounds = adjustedX >= minX && adjustedX <= maxX;
    final yInBounds = adjustedY >= minY && adjustedY <= maxY;
    return xInBounds && yInBounds;
  }

  bool _shouldDrawLine(Point current, Point next) {
    final currentAdjustedX = current.$1 - _xOffset;
    final nextAdjustedX = next.$1 - _xOffset;
    final currentAdjustedY = current.$2 - _yOffset;
    final nextAdjustedY = next.$2 - _yOffset;

    final bothAreLeft = currentAdjustedX < _minX && nextAdjustedX < _minX;
    final bothAreRight = currentAdjustedX > _maxX && nextAdjustedX > _maxX;
    final bothAreDown = currentAdjustedY < _minY && nextAdjustedY < _minY;
    final bothAreTop = currentAdjustedY > _maxY && nextAdjustedY > _maxY;

    return !(bothAreLeft || bothAreRight || bothAreDown || bothAreTop);
  }

  Offset _getPointOffset(Offset chartOffset, Point point) => Offset(
    chartOffset.dx + (point.$1 - _xOffset) * zoom * _xBaseSpacing,
    chartOffset.dy +
        _xAxisOffset -
        (point.$2 - _yOffset) * zoom * _yBaseSpacing,
  );

  void _updateBoundaries(List<Point> points) {
    //TODO: IMPLEMENT THIS
  }

  void _initRecognizers() {
    _panGestureRecognizer =
        PanGestureRecognizer()
          ..onUpdate = (details) {
            final xDelta = details.delta.dx;
            final yDelta = details.delta.dy;

            _xOffset -= xDelta / (zoom * _xBaseSpacing);
            _yOffset += yDelta / (zoom * _yBaseSpacing);

            markNeedsPaint();
          };
  }
}
