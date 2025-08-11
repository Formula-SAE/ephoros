import "dart:math";

import "package:flutter/material.dart";

class Encapsulator extends StatefulWidget {
  const Encapsulator({
    required this.possibleChildren,
    this.horizontalSpacing = 16,
    this.verticalSpacing = 16,
    this.columns = 2,
    super.key,
  });

  final List<EncapsulatorItem> possibleChildren;
  final double horizontalSpacing;
  final double verticalSpacing;
  final int columns;

  @override
  State<Encapsulator> createState() => _EncapsulatorState();
}

class _EncapsulatorState extends State<Encapsulator> {
  List<EncapsulatorItem> _children = [];
  String? _error;
  late int _columns;

  @override
  void initState() {
    super.initState();
    _children = [];
    _columns = widget.columns;
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filled(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => _EncapsulatorDialog(
                possibleChildren: widget.possibleChildren,
                onSelected: (value) => setState(() {
                  if (value != null) {
                    _children = [..._children, value];
                  }
                  Navigator.of(context).pop();
                }),
              ),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _children = _calculateChildren(
              _children,
              constraints.maxWidth,
              constraints.maxHeight,
              _columns,
            );

            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Wrap(
                    spacing: widget.horizontalSpacing,
                    runSpacing: widget.verticalSpacing,
                    alignment: WrapAlignment.center,
                    children: _children.map((e) => e.build(context)).toList(),
                  ),
                ),
                if (_error != null)
                  AlertDialog(
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _error = null),
                          icon: const Icon(Icons.close),
                        ),
                        Text(_error!),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ],
  );

  List<EncapsulatorItem> _calculateChildren(
    List<EncapsulatorItem> children,
    double containerMaxWidth,
    double containerMaxHeight,
    int columns,
  ) {
    final newChildren = <EncapsulatorItem>[];
    final actualRows = (children.length / columns).ceil();
    debugPrint(
      "(Encapsulator) Calculating layout: rows = $actualRows, columns = $columns",
    );

    final childMaxHeight = actualRows > 1
        ? (containerMaxHeight - widget.verticalSpacing * (actualRows - 1)) /
              actualRows
        : containerMaxHeight;

    for (int row = 0; row < actualRows; row++) {
      final startIndex = row * columns;
      final endIndex = (startIndex + columns).clamp(0, children.length);
      final rowChildren = children.sublist(startIndex, endIndex);

      final childMaxWidth = rowChildren.length > 1
          ? (containerMaxWidth -
                    widget.horizontalSpacing * (rowChildren.length - 1)) /
                rowChildren.length
          : containerMaxWidth;

      for (int i = 0; i < rowChildren.length; i++) {
        final child = rowChildren[i];
        if (child.constraints.minWidth > childMaxWidth ||
            child.constraints.minHeight > childMaxHeight) {
          debugPrint(
            // ignore: lines_longer_than_80_chars
            "(Encapsulator) Row $row: child ${child.name} has constraints that are too large for the container",
          );

          _error =
              // ignore: lines_longer_than_80_chars
              "Widget ${child.name} not added to encapsulator because it's too large for the container";
          return _calculateChildren(
            children.sublist(0, children.length - 1).toList(),
            containerMaxWidth,
            containerMaxHeight,
            columns,
          );
        }
      }

      debugPrint(
        // ignore: lines_longer_than_80_chars
        "(Encapsulator) Row $row: childMaxWidth: $childMaxWidth, childMaxHeight: $childMaxHeight, children: ${rowChildren.length}",
      );

      newChildren.addAll(
        rowChildren.map(
          (e) => e.copyWith(maxHeight: childMaxHeight, maxWidth: childMaxWidth),
        ),
      );
    }

    return newChildren;
  }
}

class _EncapsulatorDialog extends StatelessWidget {
  const _EncapsulatorDialog({
    required this.possibleChildren,
    required this.onSelected,
  });

  final List<EncapsulatorItem> possibleChildren;
  final void Function(EncapsulatorItem?) onSelected;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final width = min(screenWidth * 0.8, 1000.0);
    final height = min(screenHeight * 0.8, 400.0);

    return Dialog(
      child: SizedBox(
        width: width,
        height: height,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownMenu(
                inputDecorationTheme: InputDecorationTheme(
                  border: WidgetStateInputBorder.resolveWith(
                    (states) => const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.deepPurple,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                ),
                menuStyle: MenuStyle(
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.transparent),
                    ),
                  ),
                  elevation: const WidgetStatePropertyAll(2),
                ),
                width: double.infinity,
                dropdownMenuEntries: possibleChildren
                    .map((e) => DropdownMenuEntry(value: e, label: e.name))
                    .toList(),
                onSelected: onSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@immutable
class EncapsulatorItem {
  const EncapsulatorItem({
    required this.child,
    required this.constraints,
    required this.name,
  });

  final Widget child;
  final BoxConstraints constraints;
  final String name;

  EncapsulatorItem copyWith({
    Widget? child,
    double? maxWidth,
    double? maxHeight,
    double? minWidth,
    double? minHeight,
    String? name,
  }) => EncapsulatorItem(
    child: child ?? this.child,
    constraints: BoxConstraints(
      maxHeight: maxHeight ?? constraints.maxHeight,
      maxWidth: maxWidth ?? constraints.maxWidth,
      minHeight: minHeight ?? constraints.minHeight,
      minWidth: minWidth ?? constraints.minWidth,
    ),
    name: name ?? this.name,
  );

  Widget build(BuildContext context) =>
      ConstrainedBox(constraints: constraints, child: child);
}
