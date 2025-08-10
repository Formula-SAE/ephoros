import "dart:math";

import "package:flutter/material.dart";

class MainTable extends StatelessWidget {
  MainTable({
    required this.data,
    this.rowHeight = 40,
    this.columnMinWidth = 100,
    this.columnMaxWidth = 250,
    this.labelStyle,
    this.valueStyle,
    (Color, Color)? backgroundColors,
    this.verticalSpacing = 2,
    this.horizontalSpacing = 2,
    super.key,
  }) : backgroundColors =
           backgroundColors ?? (Colors.grey.shade300, Colors.grey.shade500);

  final List<(String, num)> data;
  final double rowHeight;
  final double columnMinWidth;
  final double columnMaxWidth;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final (Color, Color) backgroundColors;
  final double verticalSpacing;
  final double horizontalSpacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      debugPrint("(MainTable) constraints: $constraints");
      debugPrint("(MainTable) data: ${data.length}");
      final columns = min(constraints.maxWidth ~/ columnMaxWidth, data.length);
      debugPrint("(MainTable) columns: $columns");

      final rows = <Widget>[];
      bool inverted = false;
      for (int i = 0; i < data.length; i += columns) {
        final row = Row(
          spacing: horizontalSpacing,
          children: data
              .sublist(i, min(i + columns, data.length))
              .map(
                (e) => Flexible(
                  child: MainTableElement(
                    data: e,
                    inverted: inverted,
                    labelStyle: labelStyle,
                    valueStyle: valueStyle,
                    backgroundColors: backgroundColors,
                  ),
                ),
              )
              .toList(),
        );

        for (int i = row.children.length; i < columns; i++) {
          row.children.add(const Flexible(child: SizedBox.shrink()));
        }
        rows.add(row);

        inverted = !inverted;
      }
      debugPrint("(MainTable) rows: ${rows.length}");

      return Column(spacing: verticalSpacing, children: rows);
    },
  );
}

class MainTableElement extends StatelessWidget {
  const MainTableElement({
    required this.data,
    required this.inverted,
    required this.backgroundColors,
    this.labelStyle,
    this.valueStyle,
    super.key,
  });

  final (String, num) data;
  final bool inverted;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final (Color, Color) backgroundColors;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: inverted ? backgroundColors.$1 : backgroundColors.$2,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(data.$1, style: labelStyle),
          Text(data.$2.toString(), style: valueStyle),
        ],
      ),
    ),
  );
}
