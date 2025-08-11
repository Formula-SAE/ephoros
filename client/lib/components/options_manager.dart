import "dart:math";

import "package:flutter/material.dart";

typedef UpdateOptions<O> = void Function(O newOptions);

@immutable
abstract class Options {
  const Options();

  Options copyWith();
}

abstract class OptionsManager<O extends Options> extends StatefulWidget {
  const OptionsManager({
    required this.initialOptions,
    required this.builder,
    this.onOptionsChanged,
    super.key,
  });

  final O initialOptions;
  final ValueChanged<O>? onOptionsChanged;
  final Widget Function(BuildContext context, O options) builder;

  Widget? get top => null;
  double get maxDialogWidth => 1000;
  double get maxDialogHeight => 500;

  Widget buildWithOptions(
    BuildContext context,
    O options,
    UpdateOptions<O> updateOptions,
  );

  @override
  State<OptionsManager<O>> createState() => _OptionsManagerState<O>();
}

class _OptionsManagerState<O extends Options> extends State<OptionsManager<O>> {
  late O _options = widget.initialOptions;

  void _update(O newOptions) {
    setState(() => _options = newOptions);
    widget.onOptionsChanged?.call(newOptions);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final dialogWidth = min(screenWidth * .8, widget.maxDialogWidth);
    final dialogHeight = min(screenHeight * .8, widget.maxDialogHeight);

    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF3f0971),
            ),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => Dialog(
                insetPadding: EdgeInsets.symmetric(
                  horizontal: (screenWidth - dialogWidth) / 2,
                  vertical: (screenHeight - dialogHeight) / 2,
                ),
                backgroundColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          DefaultTextStyle(
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                            child: widget.top ?? const SizedBox.shrink(),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: Navigator.of(context).pop,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      widget.buildWithOptions(context, _options, _update),
                    ],
                  ),
                ),
              ),
            ),
            icon: const Icon(Icons.menu),
          ),
        ),
        widget.builder(context, _options),
      ],
    );
  }
}
