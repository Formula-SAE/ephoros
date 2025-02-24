import "package:client/components/chart_base.dart";
import "package:client/types/line.dart";
import "package:client/types/point.dart";
import "package:client/types/threshold_line.dart";
import "package:flutter/widgets.dart";

class LineChart<T extends Point> extends LeafRenderObjectWidget {
  const LineChart({
    super.key,
    required this.lines,
    this.numbersTextStyle = const TextStyle(
      fontSize: 12,
      color: Color(0xFF000000),
    ),
    this.xBaseSpacing = 8,
    this.yBaseSpacing = 2,
    this.initialZoom = 1,
    this.minZoom = 0.1,
    this.maxZoom = 10,
    this.offset = Offset.zero,
    this.backgroundColor = const Color(0x04000000),
    this.gridColor = const Color(0x0A000000),
    this.thresholds = const [],
  });

  final List<Line> lines;
  final TextStyle numbersTextStyle;
  final double xBaseSpacing;
  final double yBaseSpacing;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final Offset offset;
  final Color backgroundColor;
  final Color gridColor;
  final List<ThresholdLine> thresholds;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      LineChartRenderObject(
        lines: lines,
        numbersTextStyle: numbersTextStyle,
        xBaseSpacing: xBaseSpacing,
        yBaseSpacing: yBaseSpacing,
        initialZoom: initialZoom,
        minZoom: minZoom,
        maxZoom: maxZoom,
        offset: offset,
        backgroundColor: backgroundColor,
        gridColor: gridColor,
        thresholds: thresholds,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant LineChartRenderObject renderObject,
  ) {
    renderObject.lines = lines;
  }
}

class LineChartRenderObject<T extends Point> extends ChartBaseRenderObject {
  LineChartRenderObject({
    required List<Line<T>> lines,
    required TextStyle numbersTextStyle,
    required super.xBaseSpacing,
    required super.yBaseSpacing,
    required super.initialZoom,
    required super.minZoom,
    required super.maxZoom,
    required super.offset,
    required super.backgroundColor,
    required Color gridColor,
    required List<ThresholdLine> thresholds,
  }) : _lines = lines,
       _gridColor = gridColor,
       _thresholds = thresholds;

  List<Line<T>> _lines;

  final Color _gridColor;
  final List<ThresholdLine> _thresholds;

  List<Line<T>> get lines => _lines;
  set lines(List<Line<T>> value) {
    if (_lines == value) return;

    _lines = [...value];
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintGrid(context, offset);
    _paintThresholds(context, offset);
    for (final line in lines) {
      _paintPoints(context, offset, line);
      _drawLine(context, offset, line);
    }
    super.paint(context, offset);
  }

  void _paintPoints(PaintingContext context, Offset offset, Line line) {
    final paint = Paint()..color = line.color;

    for (final point in line.points.sortedByX()) {
      if (!_shouldPaintPoint(offset, point)) continue;

      context.canvas.drawCircle(_getPointOffset(offset, point), 2.5, paint);
    }
  }

  void _drawLine(PaintingContext context, Offset chartOffset, Line line) {
    if (line.points.length <= 1) return;

    final paint =
        Paint()
          ..color = line.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final path = Path();

    bool started = false;
    bool previousNotPainted = false;

    for (int i = 0; i < line.points.length - 1; i++) {
      final current = line.points[i];
      final next = line.points[i + 1];

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

      if (startX < yAxisOffset(chartOffset)) {
        startX = yAxisOffset(chartOffset);
        startY = getYByX(startX);
      } else if (startX > chartOffset.dx + size.width) {
        startX = chartOffset.dx + size.width;
        startY = getYByX(startX);
      }

      if (startY < chartOffset.dy) {
        previousNotPainted = true;
        startY = chartOffset.dy;
        startX = getXByY(startY);
      } else if (startY > xAxisOffset(chartOffset)) {
        previousNotPainted = true;
        startY = xAxisOffset(chartOffset);
        startX = getXByY(startY);
      }

      if (endX < yAxisOffset(chartOffset)) {
        endX = yAxisOffset(chartOffset);
        endY = getYByX(endX);
      } else if (endX > chartOffset.dx + size.width) {
        endX = chartOffset.dx + size.width;
        endY = getYByX(endX);
      }

      if (endY < chartOffset.dy) {
        previousNotPainted = true;
        endY = chartOffset.dy;
        endX = getXByY(endY);
      } else if (endY > xAxisOffset(chartOffset)) {
        previousNotPainted = true;
        endY = xAxisOffset(chartOffset);
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

  void _paintGrid(PaintingContext context, Offset chartOffset) {
    final paint =
        Paint()
          ..color = _gridColor
          ..style = PaintingStyle.stroke;
    final path = Path();

    final startX = offset.dx;
    final endX = offset.dx + (size.width) / (zoom * xBaseSpacing);

    final firstLineX = startX.floor();
    final lastLineX = endX.ceil();

    for (int x = firstLineX; x <= lastLineX; x += 1) {
      final xPos = chartOffset.dx + (x - offset.dx) * zoom * xBaseSpacing;

      if (xPos < yAxisOffset(chartOffset) ||
          xPos > chartOffset.dx + size.width) {
        continue;
      }

      path.moveTo(xPos, chartOffset.dy);
      path.lineTo(xPos, xAxisOffset(chartOffset));
    }

    final startY = offset.dy;
    final endY = xAxisOffset(chartOffset) / (zoom * yBaseSpacing);

    final firstLineY = startY.floor();
    final lastLineY = endY.ceil();

    for (int y = firstLineY; y <= lastLineY; y += 1) {
      final yPos =
          xAxisOffset(chartOffset) - (y - offset.dy) * zoom * yBaseSpacing;

      if (yPos < chartOffset.dy || yPos > xAxisOffset(chartOffset)) {
        continue;
      }

      path.moveTo(yAxisOffset(chartOffset), yPos);
      path.lineTo(chartOffset.dx + size.width, yPos);
    }

    context.canvas.drawPath(path, paint);
  }

  void _paintThresholds(PaintingContext context, Offset chartOffset) {
    for (final threshold in _thresholds) {
      final paint =
          Paint()
            ..color = threshold.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;

      final path = Path();
      final y =
          xAxisOffset(chartOffset) -
          (threshold.value - offset.dy) * zoom * yBaseSpacing;

      if (y < chartOffset.dy || y > xAxisOffset(chartOffset)) {
        continue;
      }

      const double dashLength = 10;
      const double gapLength = 5;

      double currentX = yAxisOffset(chartOffset);
      final endX = chartOffset.dx + size.width;

      while (currentX < endX) {
        path.moveTo(currentX, y);
        path.lineTo(currentX + dashLength, y);

        currentX += dashLength + gapLength;
      }

      context.canvas.drawPath(path, paint);
    }
  }

  bool _shouldPaintPoint(Offset chartOffset, Point point) {
    final offset = _getPointOffset(chartOffset, point);

    final xInBounds =
        offset.dx >= yAxisOffset(chartOffset) &&
        offset.dx <= chartOffset.dx + size.width;
    final yInBounds =
        offset.dy >= chartOffset.dy && offset.dy <= xAxisOffset(chartOffset);
    return xInBounds && yInBounds;
  }

  bool _shouldDrawLine(Offset chartOffset, Point current, Point next) {
    final currentOffset = _getPointOffset(chartOffset, current);
    final nextOffset = _getPointOffset(chartOffset, next);

    final bothAreLeft =
        currentOffset.dx < yAxisOffset(chartOffset) &&
        nextOffset.dx < yAxisOffset(chartOffset);
    final bothAreRight =
        currentOffset.dx > chartOffset.dx + size.width &&
        nextOffset.dx > chartOffset.dx + size.width;
    final bothAreDown =
        currentOffset.dy > xAxisOffset(chartOffset) &&
        nextOffset.dy > xAxisOffset(chartOffset);
    final bothAreTop =
        currentOffset.dy < chartOffset.dy && nextOffset.dy < chartOffset.dy;

    return !(bothAreLeft || bothAreRight || bothAreDown || bothAreTop);
  }

  Offset _getPointOffset(Offset chartOffset, Point point) => Offset(
    chartOffset.dx +
        (point.toCoordinates().$1 - offset.dx) * zoom * xBaseSpacing,
    xAxisOffset(chartOffset) -
        (point.toCoordinates().$2 - offset.dy) * zoom * yBaseSpacing,
  );
}
