import "dart:math" as math show pi;

import "package:client/types/point.dart";
import "package:collection/collection.dart";
import "package:flutter/gestures.dart";
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
    renderObject.points = points;
  }
}

class LineChartRenderObject extends RenderBox {
  LineChartRenderObject({
    required List<Point> points,
    required TextStyle numbersTextStyle,
    double xBaseSpacing = 8,
    double yBaseSpacing = 2,
    double zoom = 1,
  }) : _points = points.sortedByX(),
       _numbersTextStyle = numbersTextStyle,
       _zoom = zoom,
       _minX = 0,
       _minY = 0,
       _xBaseSpacing = xBaseSpacing,
       _yBaseSpacing = yBaseSpacing {
    _initRecognizers();
  }

  List<Point> _points;
  final TextStyle _numbersTextStyle;
  double _zoom;
  final double _minX;
  late double _maxX;
  late double _maxY;
  final double _minY;
  final double _xBaseSpacing;
  final double _yBaseSpacing;

  late PanGestureRecognizer _panGestureRecognizer;

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

  double get _xAxisOffset => size.height * 0.9;

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
      debugPrint(event.toString());
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
    final paint = Paint()..color = const Color(0xFF000000);

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
          ..color = const Color(0xFF000000)
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

      if (current.$1 < _minX) {
        startX = chartOffset.dx;
        startY = getYByX(startX);
      } else if (current.$1 > _maxX) {
        startX = chartOffset.dx + size.width;
        startY = getYByX(startX);
      }

      if (current.$2 < _minY) {
        previousNotPainted = true;
        startY = chartOffset.dy + _xAxisOffset;
        startX = getXByY(startY);
      } else if (current.$2 > _maxY) {
        previousNotPainted = true;
        startY = chartOffset.dy;
        startX = getXByY(startY);
      }

      if (next.$1 < _minX) {
        endX = chartOffset.dx;
        endY = getYByX(endX);
      } else if (next.$1 > _maxX) {
        endX = chartOffset.dx + size.width;
        endY = getYByX(endX);
      }

      if (next.$2 < _minY) {
        previousNotPainted = true;
        endY = chartOffset.dy + _xAxisOffset;
        endX = getXByY(endY);
      } else if (next.$2 > _maxY) {
        previousNotPainted = true;
        endY = chartOffset.dy;
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
    final xInBounds = point.$1 >= minX && point.$1 <= maxX;
    final yInBounds = point.$2 >= minY && point.$2 <= maxY;
    return xInBounds && yInBounds;
  }

  bool _shouldDrawLine(Point current, Point next) {
    // Don't draw if both points are completely outside the same boundary
    final bothAreLeft = current.$1 < _minX && next.$1 < _minX;
    final bothAreRight = current.$1 > _maxX && next.$1 > _maxX;
    final bothAreDown = current.$2 < _minY && next.$2 < _minY;
    final bothAreTop = current.$2 > _maxY && next.$2 > _maxY;

    // Draw if at least one point is in bounds OR the line crosses the visible area
    return !(bothAreLeft || bothAreRight || bothAreDown || bothAreTop);
  }

  Offset _getPointOffset(Offset chartOffset, Point point) => Offset(
    chartOffset.dx + point.$1 * zoom * _xBaseSpacing,
    chartOffset.dy + _xAxisOffset - point.$2 * zoom * _yBaseSpacing,
  );

  void _updateBoundaries(List<Point> points) {
    //TODO: IMPLEMENT THIS
  }

  void _initRecognizers() {
    _panGestureRecognizer =
        PanGestureRecognizer()
          ..onStart = (details) {
            debugPrint(details.toString());
          }
          ..onUpdate = (details) {
            debugPrint(details.toString());
          };
  }
}
