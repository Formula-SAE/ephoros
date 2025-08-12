import "dart:math";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

/// A widget that allows the user to add widgets to a container and
/// arrange them in a grid.
class Encapsulator extends StatelessWidget {
  const Encapsulator({required this.cubit, super.key});

  final EncapsulatorCubit cubit;

  @override
  Widget build(BuildContext context) => BlocProvider<EncapsulatorCubit>.value(
    value: cubit,
    child: Column(
      children: [
        Builder(
          builder: (context) => IconButton.filled(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => BlocProvider.value(
                value: context.read<EncapsulatorCubit>(),
                child: const _EncapsulatorDialog(),
              ),
            ),
            icon: const Icon(Icons.menu),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              context.read<EncapsulatorCubit>().updateConstraints(constraints);

              return BlocBuilder<EncapsulatorCubit, EncapsulatorState>(
                builder: (context, state) => Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Wrap(
                        spacing: context
                            .read<EncapsulatorCubit>()
                            .horizontalSpacing,
                        runSpacing: context
                            .read<EncapsulatorCubit>()
                            .verticalSpacing,
                        alignment: WrapAlignment.center,
                        children: state.children
                            .map((e) => e.build(context))
                            .toList(),
                      ),
                    ),
                    if (state.hasError)
                      AlertDialog(
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: context
                                  .read<EncapsulatorCubit>()
                                  .removeError,
                              icon: const Icon(Icons.close),
                            ),
                            Text(state.error!),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

/// Dialog that shows a list of available components to add to the encapsulator.
class _EncapsulatorDialog extends StatelessWidget {
  const _EncapsulatorDialog();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final width = min(screenWidth * 0.8, 1000.0);
    final height = min(screenHeight * 0.8, 400.0);

    return BlocListener<EncapsulatorCubit, EncapsulatorState>(
      listener: (context, state) {
        if (state.hasError) {
          Navigator.of(context).pop();
        }
      },
      child: Dialog(
        child: SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BlocBuilder<EncapsulatorCubit, EncapsulatorState>(
              builder: (context, state) => Column(
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
                    dropdownMenuEntries: state.availableChildren
                        .map((e) => DropdownMenuEntry(value: e, label: e.name))
                        .toList(),
                    onSelected: (value) {
                      if (value == null) return;
                      context.read<EncapsulatorCubit>().addChild(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.children.length,
                      itemBuilder: (context, index) =>
                          _EncapsulatorDialogListItem(
                            item: state.children[index],
                            onNameChanged: (value) {
                              if (value.isEmpty) return;
                              if (value == state.children[index].name) return;

                              context.read<EncapsulatorCubit>().updateChildName(
                                index,
                                value,
                              );
                            },
                            onRemove: () => context
                                .read<EncapsulatorCubit>()
                                .removeChild(index),
                          ),
                    ),
                  ),
                ],
              ),
            ),
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

@immutable
class EncapsulatorState {
  const EncapsulatorState({
    this.children = const [],
    this.availableChildren = const [],
    this.error,
    this.constraints = const BoxConstraints(),
  });

  final List<EncapsulatorItem> children;
  final List<EncapsulatorItem> availableChildren;
  final String? error;
  final BoxConstraints constraints;

  EncapsulatorState copyWith({
    List<EncapsulatorItem>? children,
    List<EncapsulatorItem>? availableChildren,
    BoxConstraints? constraints,
    String? error,
  }) => EncapsulatorState(
    children: children ?? this.children,
    availableChildren: availableChildren ?? this.availableChildren,
    constraints: constraints ?? this.constraints,
    error: error,
  );

  bool get hasError => error != null;
}

class EncapsulatorCubit extends Cubit<EncapsulatorState> {
  EncapsulatorCubit({
    this.horizontalSpacing = 16,
    this.verticalSpacing = 16,
    this.columns = 2,
    this.availableChildren = const [],
  }) : super(EncapsulatorState(availableChildren: availableChildren));

  final double horizontalSpacing;
  final double verticalSpacing;
  final int columns;
  final List<EncapsulatorItem> availableChildren;

  void addChild(EncapsulatorItem child) {
    emit(state.copyWith(error: null));

    final (newChildren, error) = _calculateChildrenConstraints(
      [...state.children, child],
      state.constraints.maxWidth,
      state.constraints.maxHeight,
      columns,
    );

    emit(state.copyWith(children: newChildren, error: error));
  }

  void removeChild(int index) {
    emit(state.copyWith(error: null));
    if (index < 0 || index >= state.children.length) return;

    final (newChildren, error) = _calculateChildrenConstraints(
      state.children.sublist(0, index) + state.children.sublist(index + 1),
      state.constraints.maxWidth,
      state.constraints.maxHeight,
      columns,
    );

    emit(state.copyWith(children: newChildren, error: error));
  }

  void updateConstraints(BoxConstraints constraints) {
    if (constraints == state.constraints) return;
    debugPrint(
      // ignore: lines_longer_than_80_chars
      "(Encapsulator) Updating constraints: ${constraints.maxWidth}, ${constraints.maxHeight}",
    );

    final (newChildren, error) = _calculateChildrenConstraints(
      state.children,
      constraints.maxWidth,
      constraints.maxHeight,
      columns,
    );

    emit(
      state.copyWith(
        children: newChildren,
        error: error,
        constraints: constraints,
      ),
    );
  }

  void removeError() {
    emit(state.copyWith(error: null));
  }

  void updateChildName(int index, String name) {
    if (index < 0 || index >= state.children.length) return;

    final newChildren = List<EncapsulatorItem>.from(state.children);
    newChildren[index] = newChildren[index].copyWith(name: name);

    emit(state.copyWith(children: newChildren));
  }

  (List<EncapsulatorItem> newChildren, String? error)
  _calculateChildrenConstraints(
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
        (containerMaxHeight - verticalSpacing * (actualRows - 1)) / actualRows;

    for (int row = 0; row < actualRows; row++) {
      final startIndex = row * columns;
      final endIndex = (startIndex + columns).clamp(0, children.length);
      final rowChildren = children.sublist(startIndex, endIndex);

      // The only case where we have an empty row is when we have no children
      // left. This means that all of the children have been added to the list.
      if (rowChildren.isEmpty) break;

      final childMaxWidth =
          (containerMaxWidth - horizontalSpacing * (rowChildren.length - 1)) /
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

        return (
          children.sublist(0, children.length - 1),
          // ignore: lines_longer_than_80_chars
          "Widget ${children.last.name} not added to encapsulator because it's too large for the container",
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

    return (newChildren, null);
  }
}
