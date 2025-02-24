abstract class Point<A, B> {
  const Point(this.x, this.y);

  final A x;
  final B y;

  (double, double) toCoordinates();

  @override
  bool operator ==( other) {
    if (other is! Point) return false;
    return x == other.x && y == other.y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}

extension PointListExtension on List<Point> {
  List<Point> sortedByX() =>
      [...this]
        ..sort((a, b) => a.toCoordinates().$1.compareTo(b.toCoordinates().$1));
  List<Point> sortedByY() =>
      [...this]
        ..sort((a, b) => a.toCoordinates().$2.compareTo(b.toCoordinates().$2));
}
