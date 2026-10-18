import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assist_interiors_dashboard/core/widgets/quick_fade_dropdown.dart';

void main() {
  group('QuickFadeDropdown Component Tests', () {
    testWidgets('Renders properly and displays initial value', (
      WidgetTester tester,
    ) async {
      String? selectedValue = 'Item 1';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return QuickFadeDropdown<String>(
                  value: selectedValue,
                  items: const [
                    DropdownMenuItem(value: 'Item 1', child: Text('Item 1')),
                    DropdownMenuItem(value: 'Item 2', child: Text('Item 2')),
                    DropdownMenuItem(value: 'Item 3', child: Text('Item 3')),
                  ],
                  onChanged: (val) {
                    setState(() => selectedValue = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets(
      'Tapping dropdown fades in menu quickly and selection updates value',
      (WidgetTester tester) async {
        String? selectedValue = 'Option A';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return QuickFadeDropdown<String>(
                    value: selectedValue,
                    items: const [
                      DropdownMenuItem(
                        value: 'Option A',
                        child: Text('Option A'),
                      ),
                      DropdownMenuItem(
                        value: 'Option B',
                        child: Text('Option B'),
                      ),
                      DropdownMenuItem(
                        value: 'Option C',
                        child: Text('Option C'),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => selectedValue = val);
                    },
                  );
                },
              ),
            ),
          ),
        );

        // Tap dropdown to open
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();

        // Verify menu items are visible in popup
        expect(find.text('Option B'), findsOneWidget);
        expect(find.text('Option C'), findsOneWidget);

        // Tap Option B
        await tester.tap(find.text('Option B'));
        await tester.pumpAndSettle();

        // Verify value updated and menu closed
        expect(selectedValue, 'Option B');
        expect(find.text('Option C'), findsNothing);
      },
    );

    testWidgets(
      'Dismisses active TextField keyboard focus before opening dropdown',
      (WidgetTester tester) async {
        String? selectedValue = 'Alpha';
        final focusNode = FocusNode();
        final textController = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  TextField(
                    focusNode: focusNode,
                    controller: textController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  QuickFadeDropdown<String>(
                    value: selectedValue,
                    items: const [
                      DropdownMenuItem(value: 'Alpha', child: Text('Alpha')),
                      DropdownMenuItem(value: 'Beta', child: Text('Beta')),
                    ],
                    onChanged: (val) => selectedValue = val,
                  ),
                ],
              ),
            ),
          ),
        );

        // Focus the text field
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(focusNode.hasFocus, isTrue);

        // Now tap the dropdown
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();

        // Focus on text field MUST be dismissed
        expect(focusNode.hasFocus, isFalse);

        // Menu must be open and selectable
        expect(find.text('Beta'), findsOneWidget);
        await tester.tap(find.text('Beta'));
        await tester.pumpAndSettle();

        expect(selectedValue, 'Beta');
      },
    );

    testWidgets('Tapping outside dismisses popup menu cleanly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickFadeDropdown<String>(
              value: '1',
              items: const [
                DropdownMenuItem(value: '1', child: Text('Entry 1')),
                DropdownMenuItem(value: '2', child: Text('Entry 2')),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('Entry 2'), findsOneWidget);

      // Tap at top left outside the popup
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      // Popup must be dismissed
      expect(find.text('Entry 2'), findsNothing);
    });

    testWidgets(
      'Dropdown popup box strictly takes up only as much width as the input field itself',
      (WidgetTester tester) async {
        const double customFieldWidth = 220.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: customFieldWidth,
                  child: QuickFadeDropdown<String>(
                    value: '1',
                    items: const [
                      DropdownMenuItem(value: '1', child: Text('Option 1')),
                      DropdownMenuItem(value: '2', child: Text('Option 2')),
                    ],
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );

        // Verify the closed input field width
        final fieldSize = tester.getSize(
          find.byType(DropdownButtonFormField<String>),
        );
        expect(fieldSize.width, customFieldWidth);

        // Open the dropdown
        await tester.tap(
          find.byType(DropdownButtonFormField<String>),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Verify the opened dropdown menu list view width matches the input field exactly
        final popupListSize = tester.getSize(find.byType(ListView));
        expect(popupListSize.width, customFieldWidth);
      },
    );

    testWidgets(
      'Dropdown near screen right edge preserves input field width rather than expanding full screen',
      (WidgetTester tester) async {
        const double columnWidth = 180.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  const Spacer(),
                  SizedBox(
                    width: columnWidth,
                    child: QuickFadeDropdown<String>(
                      value: 'A',
                      items: const [
                        DropdownMenuItem(value: 'A', child: Text('Choice A')),
                        DropdownMenuItem(value: 'B', child: Text('Choice B')),
                      ],
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final fieldSize = tester.getSize(
          find.byType(DropdownButtonFormField<String>),
        );
        expect(fieldSize.width, columnWidth);

        // Open the dropdown
        await tester.tap(
          find.byType(DropdownButtonFormField<String>),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // The popup list must NOT blow up to screen width; it must remain equal to columnWidth
        final popupListSize = tester.getSize(find.byType(ListView));
        expect(popupListSize.width, columnWidth);
      },
    );
  });
}
