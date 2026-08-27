import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';
import 'package:custom_nepali_calendar/src/view/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The window every test here opens on: BS 2081, which starts 13 April 2024.
const NepaliDate _start = NepaliDate(2081, 1, 1);
const NepaliDate _end = NepaliDate(2081, 12, 30);

/// The first day of the month the grid is currently showing.
///
/// Read off the cells rather than any internal state, so these tests describe
/// what a user sees.
NepaliDate _visibleMonth(WidgetTester tester) {
  final Iterable<DayCell> cells = tester
      .widgetList<DayCell>(find.byType(DayCell))
      .where((DayCell cell) => cell.day.isCurrentMonth);
  return cells.first.day.bsDate;
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showNepaliCalendar(
              context: context,
              theme: const NepaliCalendarTheme(),
              startDate: _start,
              endDate: _end,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _nextMonth(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.chevron_right_rounded));
  await tester.pumpAndSettle();
}

void main() {
  group('switching calendar system', () {
    testWidgets('keeps the month that is on screen', (
      WidgetTester tester,
    ) async {
      await _openSheet(tester);
      await _nextMonth(tester);
      expect(_visibleMonth(tester), const NepaliDate(2081, 2, 1));

      await tester.tap(find.text('AD'));
      await tester.pumpAndSettle();

      // Jestha 2081 opens in May 2024, so that is the month AD lands on.
      expect(_visibleMonth(tester).toDateTime(), DateTime(2024, 5, 1));
    });

    testWidgets('returns to the same BS month on the way back', (
      WidgetTester tester,
    ) async {
      await _openSheet(tester);
      await _nextMonth(tester);
      final NepaliDate before = _visibleMonth(tester);

      await tester.tap(find.text('AD'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BS'));
      await tester.pumpAndSettle();

      expect(
        _visibleMonth(tester),
        before,
        reason:
            'a BS month and the AD month it opens in do not share a first '
            'day, so a round trip must not drift a month backwards',
      );
    });

    testWidgets('does not keep scrolling when a month animation was running', (
      WidgetTester tester,
    ) async {
      await _openSheet(tester);
      final NepaliDate before = _visibleMonth(tester);

      // Switch while the chevron's animation is still in flight, before it
      // has travelled far enough to count as a different page.
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(find.text('AD'));
      await tester.pumpAndSettle();

      final NepaliDate landed = _visibleMonth(tester);
      expect(
        landed.toDateTime().month,
        before.toDateTime().month,
        reason:
            'the unfinished scroll must not carry over onto the new page '
            'controller and slide the calendar a month on by itself',
      );

      // And it must stay there: a drift shows up as movement after settling.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(_visibleMonth(tester), landed);
    });

    testWidgets('does not keep scrolling when a fling was in flight', (
      WidgetTester tester,
    ) async {
      await _openSheet(tester);
      final NepaliDate before = _visibleMonth(tester);

      await tester.fling(find.byType(PageView), const Offset(-300, 0), 800);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.text('AD'));
      await tester.pumpAndSettle();

      final NepaliDate landed = _visibleMonth(tester);
      expect(landed.toDateTime().month, before.toDateTime().month);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(_visibleMonth(tester), landed);
    });

    testWidgets('survives rapid back-and-forth taps', (
      WidgetTester tester,
    ) async {
      await _openSheet(tester);
      await tester.tap(find.text('AD'));
      await tester.pump(const Duration(milliseconds: 8));
      await tester.tap(find.text('BS'));
      await tester.pump(const Duration(milliseconds: 8));
      await tester.tap(find.text('AD'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_visibleMonth(tester).toDateTime(), DateTime(2024, 4, 1));
    });

    testWidgets('leaves the selection alone', (WidgetTester tester) async {
      await _openSheet(tester);
      await tester.tap(
        find.byWidgetPredicate(
          (Widget w) =>
              w is DayCell && w.day.bsDate == const NepaliDate(2081, 1, 15),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('AD'));
      await tester.pumpAndSettle();

      final DayCell selected = tester
          .widgetList<DayCell>(find.byType(DayCell))
          .firstWhere((DayCell c) => c.day.isSelected);
      expect(selected.day.bsDate, const NepaliDate(2081, 1, 15));
      expect(selected.day.adDate, DateTime(2024, 4, 27));
    });
  });
}
