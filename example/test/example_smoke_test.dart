import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:custom_nepali_calendar_example/main.dart';

void main() {
  testWidgets('picking a date shows both calendars in the result', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    // The strip reports its own default on first build, so the result card is
    // already populated before anything is tapped.
    expect(find.textContaining('Strip'), findsOneWidget);

    await tester.tap(find.text('Pick a date'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);

    // Nothing is preselected, so confirm is disabled until a day is picked.
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Done'))
          .onPressed,
      isNull,
    );
    // "Today" appears on the strip's chip too, so aim at the sheet's button.
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Today'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.textContaining('Single'), findsOneWidget);
    expect(find.textContaining('BS:'), findsOneWidget);
    expect(find.textContaining('AD:'), findsOneWidget);
  });

  testWidgets('cancelling the range sheet is reported', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pick a range'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Range: cancelled'), findsOneWidget);
  });

  testWidgets('the language toggle switches the sheet to Nepali', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    // The demo page is taller than the 800x600 test window and the language
    // toggle sits at the very end of it, so it has to be scrolled to first.
    await tester.ensureVisible(find.text('नेपाली'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('नेपाली'));
    await tester.pumpAndSettle();

    // Scrolling to the toggle left the button off the top of the window.
    await tester.ensureVisible(find.text('Pick a date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pick a date'));
    await tester.pumpAndSettle();
    expect(find.text('ठीक छ'), findsOneWidget);
    expect(find.text('रद्द'), findsOneWidget);
  });
}
