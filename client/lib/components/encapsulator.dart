import "dart:math";

import "package:flutter/material.dart";

/// A widget that allows the user to add widgets to a container and
/// arrange them in a grid.
class Encapsulator extends StatefulWidget {
  const Encapsulator({
    required this.availableChildren,
    this.horizontalSpacing = 16,
    this.verticalSpacing = 16,
    this.initialColumns = 2,
    super.key,
  });

  final List<EncapsulatorItem> availableChildren;
  final double horizontalSpacing;
  final double verticalSpacing;
  final int initialColumns;

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
    _columns = widget.initialColumns;
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton.filled(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => _EncapsulatorDialog(
                availableChildren: widget.availableChildren,
                actualChildren: _children,
                onSelected: (value) => setState(() {
                  if (value != null) {
                    _children = [..._children, value];
                  }
                }),
                onRemove: (index) {
                  setState(() => _children.removeAt(index));
                },
                onNameChanged: (index, name) => setState(() {
                  _children[index] = _children[index].copyWith(name: name);
                }),
              ),
            ),
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _children = _calculateChildrenConstraints(
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

  /// Takes the [children] and updates their constraints based on:
  /// - The [containerMaxWidth] and [containerMaxHeight]
  /// - The [columns]
  /// - The number of children in each row
  /// - The [widget.horizontalSpacing] and [widget.verticalSpacing]
  /// - The number of rows
  ///
  /// Returns a new list of [EncapsulatorItem] with the updated constraints.
  List<EncapsulatorItem> _calculateChildrenConstraints(
    List<EncapsulatorItem> children,
    double containerMaxWidth,
    double containerMaxHeight,
    int columns,
  ) {
    final newChildren = <EncapsulatorItem>[];
    final actualRows = max((children.length / columns).ceil(), 1);
    debugPrint(
      // ignore: lines_longer_than_80_chars
      "(Encapsulator) Calculating layout: rows = $actualRows, columns = $columns",
    );

    final childMaxHeight =
        (containerMaxHeight - widget.verticalSpacing * (actualRows - 1)) /
        actualRows;

    for (int row = 0; row < actualRows; row++) {
      final startIndex = row * columns;
      final endIndex = (startIndex + columns).clamp(0, children.length);
      final rowChildren = children.sublist(startIndex, endIndex);

      // The only case where we have an empty row is when we have no children
      // left. This means that all of the children have been added to the list.
      if (rowChildren.isEmpty) break;

      final childMaxWidth =
          (containerMaxWidth -
              widget.horizontalSpacing * (rowChildren.length - 1)) /
          rowChildren.length;

      for (final child in rowChildren) {
        // If a child's constraints are small enough for the container,
        // we can add it to the row.
        if (child.constraints.minWidth <= childMaxWidth &&
            child.constraints.minHeight <= childMaxHeight) {
          continue;
        }

        // If a child's constraints are too large for the container,
        // we need to remove the last added child
        // (because it breaks the layout).
        debugPrint(
          // ignore: lines_longer_than_80_chars
          "(Encapsulator) Row $row: child ${children.last.name} has constraints that are too large for the container",
        );

        _error =
            // ignore: lines_longer_than_80_chars
            "Widget ${children.last.name} not added to encapsulator because it's too large for the container";

        // Recalculate constraints without the last child and
        // with the original container constraints.
        return _calculateChildrenConstraints(
          children.sublist(0, children.length - 1).toList(),
          containerMaxWidth,
          containerMaxHeight,
          columns,
        );
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

/// Dialog that shows a list of available components to add to the encapsulator.
class _EncapsulatorDialog extends StatefulWidget {
  const _EncapsulatorDialog({
    required this.availableChildren,
    required this.actualChildren,
    required this.onSelected,
    required this.onRemove,
    required this.onNameChanged,
  });

  final List<EncapsulatorItem> availableChildren;
  final List<EncapsulatorItem> actualChildren;
  final void Function(EncapsulatorItem?) onSelected;
  final void Function(int) onRemove;
  final void Function(int index, String name) onNameChanged;

  @override
  State<_EncapsulatorDialog> createState() => _EncapsulatorDialogState();
}

class _EncapsulatorDialogState extends State<_EncapsulatorDialog> {
  List<EncapsulatorItem> _actualChildren = [];

  @override
  void initState() {
    super.initState();
    _actualChildren = List.from(widget.actualChildren);
  }

  @override
  void didUpdateWidget(_EncapsulatorDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actualChildren != widget.actualChildren) {
      _actualChildren = List.from(widget.actualChildren);
    }
  }

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
                dropdownMenuEntries: widget.availableChildren
                    .map((e) => DropdownMenuEntry(value: e, label: e.name))
                    .toList(),
                onSelected: (value) {
                  if (value == null) return;
                  setState(() => _actualChildren.add(value));
                  widget.onSelected(value);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _actualChildren.length,
                  itemBuilder: (context, index) => _EncapsulatorDialogListItem(
                    item: _actualChildren[index],
                    onNameChanged: (value) {
                      if (value.isEmpty) return;
                      if (value == _actualChildren[index].name) return;

                      widget.onNameChanged(index, value);
                      setState(
                        () => _actualChildren[index] = _actualChildren[index]
                            .copyWith(name: value),
                      );
                    },
                    onRemove: () {
                      widget.onRemove(index);
                      setState(() => _actualChildren.removeAt(index));
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EncapsulatorDialogListItem extends StatelessWidget {
  _EncapsulatorDialogListItem({
    required this.item,
    required this.onNameChanged,
    required this.onRemove,
  }) : controller = TextEditingController(text: item.name);

  final EncapsulatorItem item;
  final TextEditingController controller;
  final void Function(String name) onNameChanged;
  final void Function() onRemove;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: TextField(controller: controller)),
      IconButton(
        onPressed: () => onNameChanged(controller.text),
        icon: const Icon(Icons.check),
        color: Colors.deepPurple,
      ),
      IconButton(
        onPressed: onRemove,
        icon: const Icon(Icons.delete),
        color: Colors.red,
      ),
    ],
  );
}

/// A widget that can be added to the encapsulator.
///
/// It contains the widget to add, its constraints, and a name.
///
/// The constraints are used to calculate the layout of the encapsulator.
///
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
