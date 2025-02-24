import "package:flutter/gestures.dart";
import "package:flutter/rendering.dart";
import "package:flutter/widgets.dart";

abstract class ChartBaseRenderObject extends RenderBox {
  ChartBaseRenderObject({
    required this.xBaseSpacing,
    required this.yBaseSpacing,
    required double initialZoom,
    required this.minZoom,
    required this.maxZoom,
    required Offset offset,
    required Color backgroundColor,
  }) : _zoom = initialZoom,
       _offset = offset,
       _backgroundColor = backgroundColor {
    _panGestureRecognizer =
        PanGestureRecognizer()
          ..onUpdate = (details) {
            final xDelta = details.delta.dx;
            final yDelta = details.delta.dy;

            _offset = Offset(
              _offset.dx - xDelta / (zoom * xBaseSpacing),
              _offset.dy + yDelta / (zoom * yBaseSpacing),
            );

            markNeedsPaint();
          };
  }

  double _zoom;
  Offset _offset;

  final double xBaseSpacing;
  final double yBaseSpacing;
  final double minZoom;
  final double maxZoom;
  final Color _backgroundColor;

  late final PanGestureRecognizer _panGestureRecognizer;

  double get zoom => _zoom;
  set zoom(double value) {
    if (_zoom == value) return;

    _zoom = value;
    markNeedsPaint();
  }

  Offset get offset => _offset;
  set offset(Offset value) {
    if (_offset == value) return;

    _offset = value;
    markNeedsPaint();
  }

  double xAxisOffset(Offset chartOffset) => chartOffset.dy + size.height * 0.9;
  double yAxisOffset(Offset chartOffset) => chartOffset.dx + size.width * 0.1;
  Paint get _axisPaint =>
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF000000);

  @override
  bool get sizedByParent => true;
  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      Size(constraints.maxWidth, constraints.maxHeight);

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));

    if (event is PointerDownEvent) {
      _panGestureRecognizer.addPointer(event);
    } else if (event is PointerScrollEvent) {
      final delta = event.scrollDelta.dy / 100;
      _zoom += delta;

      if (_zoom < minZoom) {
        _zoom = minZoom;
      } else if (_zoom > maxZoom) {
        _zoom = maxZoom;
      }

      markNeedsPaint();
    }
  }
  @override
  bool hitTestSelf(Offset position) => true;

  @mustCallSuper
  @override
  void paint(PaintingContext context, Offset offset) {
    _paintBackground(context, offset);
    _paintXAxis(context, offset);
    _paintYAxis(context, offset);
  }

  void _paintXAxis(PaintingContext context, Offset chartOffset) {
    final path = Path();

    path.moveTo(yAxisOffset(chartOffset), xAxisOffset(chartOffset));
    path.lineTo(chartOffset.dx + size.width, xAxisOffset(chartOffset));

    context.canvas.drawPath(path, _axisPaint);
  }

  void _paintYAxis(PaintingContext context, Offset chartOffset) {
    final path = Path();

    path.moveTo(yAxisOffset(chartOffset), chartOffset.dy);
    path.lineTo(yAxisOffset(chartOffset), xAxisOffset(chartOffset));

    context.canvas.drawPath(path, _axisPaint);
  }

  void _paintBackground(PaintingContext context, Offset chartOffset) {
    final paint = Paint()..color = _backgroundColor;
    final path = Path();

    path.addRect(
      Rect.fromLTWH(
        yAxisOffset(chartOffset),
        chartOffset.dy,
        chartOffset.dx + size.width - yAxisOffset(chartOffset),
        xAxisOffset(chartOffset) - chartOffset.dy,
      ),
    );
    context.canvas.drawPath(path, paint);
  }
}
