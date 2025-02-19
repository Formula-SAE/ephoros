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
    this.pointColor = const Color(0xFF000000),
    this.lineColor = const Color(0xFF000000),
    this.initialZoom = 1,
    this.minZoom = 0.1,
    this.maxZoom = 10,
    this.offset = Offset.zero,
    this.backgroundColor = const Color(0x04000000),
    this.gridColor = const Color(0x0A000000),
  });

  final List<Point> points;
  final TextStyle numbersTextStyle;
  final double xBaseSpacing;
  final double yBaseSpacing;
  final Color pointColor;
  final Color lineColor;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final Offset offset;
  final Color backgroundColor;
  final Color gridColor;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      LineChartRenderObject(
        points: points,
        numbersTextStyle: numbersTextStyle,
        xBaseSpacing: xBaseSpacing,
        yBaseSpacing: yBaseSpacing,
        pointColor: pointColor,
        lineColor: lineColor,
        initialZoom: initialZoom,
        minZoom: minZoom,
        maxZoom: maxZoom,
        offset: offset,
        backgroundColor: backgroundColor,
        gridColor: gridColor,
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
    required double initialZoom,
    required double minZoom,
    required double maxZoom,
    required Offset offset,
    required Color backgroundColor,
    required Color gridColor,
  }) : _points = points.sortedByX(),
       _numbersTextStyle = numbersTextStyle,
       _zoom = initialZoom,
       _xBaseSpacing = xBaseSpacing,
       _yBaseSpacing = yBaseSpacing,
       _pointColor = pointColor,
       _lineColor = lineColor,
       _offset = offset,
       _minZoom = minZoom,
       _maxZoom = maxZoom,
       _backgroundColor = backgroundColor,
       _gridColor = gridColor {
    _initRecognizers();
  }

  List<Point> _points;
  double _zoom;

  final TextStyle _numbersTextStyle;
  final double _xBaseSpacing;
  final double _yBaseSpacing;
  final Color _pointColor;
  final Color _lineColor;
  final double _minZoom;
  final double _maxZoom;
  final Color _backgroundColor;
  final Color _gridColor;

  late final PanGestureRecognizer _panGestureRecognizer;

  Offset _offset;

  List<Point> get points => _points;
  set points(List<Point> value) {
    final eq = ListEquality().equals;

    if (eq(_points, value)) return;

    _points = [...value]
      ..sort((a, b) => a.toCoordinates().$1.compareTo(b.toCoordinates().$1));
    markNeedsLayout();
  }

  double get zoom => _zoom;
  set zoom(double value) {
    if (_zoom == value) return;

    _zoom = value;
    markNeedsLayout();
  }

  Offset get offset => _offset;
  set offset(Offset value) {
    if (_offset == value) return;

    _offset = value;
    markNeedsLayout();
  }

  double get _xAxisOffset => size.height * 0.9;

  @override
  bool get sizedByParent => true;
  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      Size(constraints.maxWidth, constraints.maxHeight);

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintBackground(context, offset);
    _paintGrid(context, offset);
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
    } else if (event is PointerScrollEvent) {
      final delta = event.scrollDelta.dy / 100;
      _zoom += delta;

      if (_zoom < _minZoom) {
        _zoom = _minZoom;
      } else if (_zoom > _maxZoom) {
        _zoom = _maxZoom;
      }

      markNeedsPaint();
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
      if (!_shouldPaintPoint(offset, point)) continue;

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
        text: point.toCoordinates().$1.toString(),
        style: _numbersTextStyle,
      );

      paint.text = text;

      paint.layout();
      context.canvas.save();
      context.canvas.translate(
        offset.dx + point.toCoordinates().$1 - 8,
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

      if (!_shouldDrawLine(chartOffset, current, next)) {
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

  void _paintBackground(PaintingContext context, Offset offset) {
    final paint = Paint()..color = _backgroundColor;
    final path = Path();

    path.addRect(Rect.fromLTWH(offset.dx, offset.dy, size.width, _xAxisOffset));
    context.canvas.drawPath(path, paint);
  }

  void _paintGrid(PaintingContext context, Offset chartOffset) {
    final paint =
        Paint()
          ..color = _gridColor
          ..style = PaintingStyle.stroke;
    final path = Path();

    // Calculate the visible range based on offset and zoom
    final startX = _offset.dx;
    final endX = _offset.dx + size.width / (zoom * _xBaseSpacing);

    // Calculate the number of vertical lines needed
    final firstLineX = startX.floor();
    final lastLineX = endX.ceil();

    // Draw vertical lines
    for (int x = firstLineX; x <= lastLineX; x += 1) {
      final xPos = chartOffset.dx + (x - _offset.dx) * zoom * _xBaseSpacing;

      if (xPos < chartOffset.dx || xPos > chartOffset.dx + size.width) {
        continue;
      }

      path.moveTo(xPos, chartOffset.dy);
      path.lineTo(xPos, chartOffset.dy + _xAxisOffset);
    }

    // Draw horizontal lines
    final startY = _offset.dy;
    final endY = _offset.dy + _xAxisOffset / (zoom * _yBaseSpacing);

    final firstLineY = startY.floor();
    final lastLineY = endY.ceil();

    for (int y = firstLineY; y <= lastLineY; y += 1) {
      final yPos =
          chartOffset.dy +
          _xAxisOffset -
          (y - _offset.dy) * zoom * _yBaseSpacing;

      if (yPos < chartOffset.dy || yPos > chartOffset.dy + _xAxisOffset) {
        continue;
      }

      path.moveTo(chartOffset.dx, yPos);
      path.lineTo(chartOffset.dx + size.width, yPos);
    }

    context.canvas.drawPath(path, paint);
  }

  bool _shouldPaintPoint(Offset chartOffset, Point point) {
    final offset = _getPointOffset(chartOffset, point);

    final xInBounds =
        offset.dx >= chartOffset.dx && offset.dx <= chartOffset.dx + size.width;
    final yInBounds =
        offset.dy >= chartOffset.dy &&
        offset.dy <= chartOffset.dy + _xAxisOffset;
    return xInBounds && yInBounds;
  }

  bool _shouldDrawLine(Offset chartOffset, Point current, Point next) {
    final currentOffset = _getPointOffset(chartOffset, current);
    final nextOffset = _getPointOffset(chartOffset, next);

    final bothAreLeft =
        currentOffset.dx < chartOffset.dx && nextOffset.dx < chartOffset.dx;
    final bothAreRight =
        currentOffset.dx > chartOffset.dx + size.width &&
        nextOffset.dx > chartOffset.dx + size.width;
    final bothAreDown =
        currentOffset.dy > chartOffset.dy + _xAxisOffset &&
        nextOffset.dy > chartOffset.dy + _xAxisOffset;
    final bothAreTop =
        currentOffset.dy < chartOffset.dy && nextOffset.dy < chartOffset.dy;

    return !(bothAreLeft || bothAreRight || bothAreDown || bothAreTop);
  }

  Offset _getPointOffset(Offset chartOffset, Point point) => Offset(
    chartOffset.dx +
        (point.toCoordinates().$1 - _offset.dx) * zoom * _xBaseSpacing,
    chartOffset.dy +
        _xAxisOffset -
        (point.toCoordinates().$2 - _offset.dy) * zoom * _yBaseSpacing,
  );

  void _initRecognizers() {
    _panGestureRecognizer =
        PanGestureRecognizer()
          ..onUpdate = (details) {
            final xDelta = details.delta.dx;
            final yDelta = details.delta.dy;

            _offset = Offset(
              _offset.dx - xDelta / (zoom * _xBaseSpacing),
              _offset.dy + yDelta / (zoom * _yBaseSpacing),
            );

            markNeedsPaint();
          };
  }
}
