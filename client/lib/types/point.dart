typedef Point = (double x, double y);

extension PointListExtension on List<Point> {
  List<Point> sortedByX() => [...this]..sort((a, b) => a.$1.compareTo(b.$1));
  List<Point> sortedByY() => [...this]..sort((a, b) => a.$2.compareTo(b.$2));
}
