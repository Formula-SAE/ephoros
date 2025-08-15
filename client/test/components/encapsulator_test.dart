import "package:bloc_test/bloc_test.dart";
import "package:client/components/encapsulator.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("EncapsulatorCubit", () {
    blocTest<EncapsulatorCubit, EncapsulatorState>(
      "should emit initial state",
      build: () => EncapsulatorCubit(
        availableChildren: [
          const EncapsulatorItem(
            child: SizedBox(),
            constraints: BoxConstraints(),
            name: "child1",
          ),
          const EncapsulatorItem(
            child: SizedBox(),
            constraints: BoxConstraints(),
            name: "child2",
          ),
          const EncapsulatorItem(
            child: SizedBox(),
            constraints: BoxConstraints(),
            name: "child3",
          ),
        ],
      ),
      verify: (cubit) {
        expect(cubit.state, isA<EncapsulatorState>());
        expect(cubit.state.children, isEmpty);
        expect(cubit.state.availableChildren.length, 3);
        expect(cubit.state.constraints, isA<BoxConstraints>());
        expect(cubit.state.error, isNull);
      },
    );

    blocTest<EncapsulatorCubit, EncapsulatorState>(
      "should add a child when constraints allow it",
      build: () => EncapsulatorCubit(
        constraints: const BoxConstraints(maxWidth: 100, maxHeight: 100),
      ),
      act: (cubit) => cubit.addChild(
        const EncapsulatorItem(
          child: SizedBox(),
          constraints: BoxConstraints(minWidth: 100, minHeight: 100),
          name: "child2",
        ),
      ),
      expect: () => [
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 0),
        isA<EncapsulatorState>()
            .having((state) => state.children.length, "children length", 1)
            .having((state) => state.error, "error", isNull),
      ],
    );

    blocTest<EncapsulatorCubit, EncapsulatorState>(
      "should not add a child when constraints don't allow it and emit a [EncapsulatorState with an error]",
      build: () => EncapsulatorCubit(
        constraints: const BoxConstraints(maxWidth: 100, maxHeight: 100),
      ),
      act: (cubit) => cubit.addChild(
        const EncapsulatorItem(
          child: SizedBox(),
          constraints: BoxConstraints(minWidth: 200, minHeight: 100),
          name: "child2",
        ),
      ),
      expect: () => [
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 0),
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNotNull)
            .having((state) => state.children.length, "children length", 0),
      ],
    );

    blocTest<EncapsulatorCubit, EncapsulatorState>(
      "should not add a second child when the constraints don't allow it",
      build: () => EncapsulatorCubit(
        constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
      ),
      act: (cubit) {
        cubit.addChild(
          const EncapsulatorItem(
            child: SizedBox(),
            constraints: BoxConstraints(minWidth: 100, minHeight: 100),
            name: "child2",
          ),
        );
        cubit.addChild(
          const EncapsulatorItem(
            child: SizedBox(),
            constraints: BoxConstraints(minWidth: 150, minHeight: 100),
            name: "child2",
          ),
        );
      },
      expect: () => [
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 0),
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 1),
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 1),
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNotNull)
            .having((state) => state.children.length, "children length", 1),
      ],
    );

    blocTest<EncapsulatorCubit, EncapsulatorState>(
      "updating the constraints, should allow to add a second child",
      build: () => EncapsulatorCubit(
        constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
        //! Be careful about these
        verticalSpacing: 0,
        horizontalSpacing: 0,
      ),
      act: (cubit) {
        cubit.addChild(
          const EncapsulatorItem(
            child: SizedBox(),
            constraints: BoxConstraints(minWidth: 100, minHeight: 100),
            name: "child2",
          ),
        );
        cubit.addChild(
          const EncapsulatorItem(
            child: SizedBox(),
            constraints: BoxConstraints(minWidth: 150, minHeight: 100),
            name: "child2",
          ),
        );

        cubit.updateConstraints(
          const BoxConstraints(maxWidth: 300, maxHeight: 300),
        );
        cubit.addChild(
          const EncapsulatorItem(
            child: SizedBox(),
            constraints: BoxConstraints(minWidth: 150, minHeight: 100),
            name: "child2",
          ),
        );
      },
      expect: () => [
        // First child added
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 0),
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 1),

        // Second child added (failure)
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 1),
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNotNull)
            .having((state) => state.children.length, "children length", 1),

        // Constraints updated
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 1),

        // Second child added (success)
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 1),
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 2),
      ],
    );

    blocTest<EncapsulatorCubit, EncapsulatorState>(
      "should remove a child if exists",
      build: () => EncapsulatorCubit(
        constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
      ),
      act: (cubit) {
        cubit.addChild(
          const EncapsulatorItem(
            child: SizedBox(),
            constraints: BoxConstraints(minWidth: 100, minHeight: 100),
            name: "child2",
          ),
        );
        cubit.removeChild(0);
      },
      expect: () => [
        // First child added
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 0),
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 1),

        // First child removed
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 1),
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 0),
      ],
    );

    blocTest<EncapsulatorCubit, EncapsulatorState>(
      "should not remove a child if not exists",
      build: () => EncapsulatorCubit(
        constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
      ),
      act: (cubit) {
        cubit.addChild(
          const EncapsulatorItem(
            child: SizedBox(),
            constraints: BoxConstraints(minWidth: 100, minHeight: 100),
            name: "child2",
          ),
        );
        cubit.removeChild(1);
      },
      expect: () => [
        // First child added
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 0),
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 1),

        // Second child removed (failure)
        isA<EncapsulatorState>()
            .having((state) => state.error, "error", isNull)
            .having((state) => state.children.length, "children length", 1),
      ],
    );
  });
}
