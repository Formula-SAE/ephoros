import "dart:async";

import "package:client/components/line_chart.dart";
import "package:client/types/line.dart";
import "package:client/types/threshold_line.dart";
import "package:flutter/material.dart";

class RealTimeLineChart extends StatelessWidget {
  const RealTimeLineChart({
    super.key,
    required this.linesStream,
    this.numbersTextStyle = const TextStyle(
      fontSize: 12,
      color: Color(0xFF000000),
    ),
    this.xBaseSpacing = 8,
    this.yBaseSpacing = 2,
    this.pointColor = const Color(0xFF000000),
    this.initialZoom = 1,
    this.minZoom = 0.1,
    this.maxZoom = 10,
    this.offset = Offset.zero,
    this.backgroundColor = const Color(0x04000000),
    this.gridColor = const Color(0x0A000000),
    this.thresholds = const [],
  });

  final Stream<List<Line>> linesStream;
  final TextStyle numbersTextStyle;
  final double xBaseSpacing;
  final double yBaseSpacing;
  final Color pointColor;
  final double initialZoom;
  final double minZoom;
  final double maxZoom;
  final Offset offset;
  final Color backgroundColor;
  final Color gridColor;
  final List<ThresholdLine> thresholds;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: linesStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return LineChart(
            lines: snapshot.data!,
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
        }
        return const SizedBox.shrink();
      },
    );
  }
}
