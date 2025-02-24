import "dart:ui";

import "package:client/types/point.dart";

abstract class Line<T extends Point> {
  const Line(this.points, {this.color = const Color(0xFF000000)});

  final List<T> points;
  final Color color;
}
