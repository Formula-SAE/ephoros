import "dart:ui";

import "package:client/types/point.dart";
import "package:collection/collection.dart";

abstract class Line<T extends Point> {
  const Line(this.points, {this.color = const Color(0xFF000000)});

  final List<T> points;
  final Color color;

  @override
  bool operator ==(Object other) {
    if (other is! Line<T>) return false;
    final listEquality = ListEquality<T>().equals;

    return listEquality(points, other.points) && color == other.color;
  }

  @override
  int get hashCode => Object.hash(points, color);
}
