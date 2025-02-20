import "dart:async";

import "package:client/components/line_chart.dart";
import "package:client/types/point.dart";
import "package:flutter/material.dart";

class RealTimeLineChart extends StatefulWidget {
  const RealTimeLineChart({
    super.key,
    required this.pointStream,
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

  final Stream<Point> pointStream;
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
  State<RealTimeLineChart> createState() => _RealTimeLineChartState();
}

class _RealTimeLineChartState extends State<RealTimeLineChart> {
  List<Point> points = [];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.pointStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          points.add(snapshot.data!);
        }

        return LineChart(
          points: points,
          numbersTextStyle: widget.numbersTextStyle,
          xBaseSpacing: widget.xBaseSpacing,
          yBaseSpacing: widget.yBaseSpacing,
          pointColor: widget.pointColor,
          lineColor: widget.lineColor,
          initialZoom: widget.initialZoom,
          minZoom: widget.minZoom,
          maxZoom: widget.maxZoom,
          offset: widget.offset,
          backgroundColor: widget.backgroundColor,
          gridColor: widget.gridColor,
        );
      },
    );
  }
}
