// Regression tests for the "Today" action.
//
// Today used to be checked against the pager, which is month-granular, and then
// selected unconditionally — so any window opening later in the current month,
// and any selectableDates allow-list, left Today free to hand back a day the
// grid had already greyed out. These pin the fix: Today may navigate wherever
// it likes, but it may only *select* a day isDaySelectable agrees with.
//
// Unlike the rest of the suite these are anchored on the real today, because
// that is the thing under test.

import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';
import 'package:custom_nepali_calendar/src/view/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FilledButton _done(WidgetTester tester) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Done'));

InkWell _todayButton(WidgetTester tester) => tester.widget<InkWell>(
  find.ancestor(of: find.text('Today'), matching: find.byType(InkWell)).first,
);

/// Opens the sheet and returns the list it resolves into.
Future<List<NepaliCalendarSelection?>> _open(
  WidgetTester tester, {
  required NepaliDate startDate,
  NepaliDate? endDate,
  int? durationDays,
  List<NepaliDate>? selectableDates,
}) async {
  final List<NepaliCalendarSelection?> results = <NepaliCalendarSelection?>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => ElevatedButton(
            onPressed: () async => results.add(
              await showNepaliCalendar(
                context: context,
                theme: const NepaliCalendarTheme(),
                startDate: startDate,
                endDate: endDate,
                durationDays: durationDays,
                selectableDates: selectableDates == null
                    ? null
                    : <SelectableDates>[
                        SelectableDates(dates: selectableDates),
                      ],
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  final NepaliDate today = NepaliDate.now();

  group('the Today button', () {
    testWidgets('will not select a day before the window opens', (
      WidgetTester tester,
    ) async {
      final NepaliDate windowStart = today.addDays(3);
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        startDate: windowStart,
        durationDays: 30,
      );

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      expect(
        _done(tester).onPressed,
        isNull,
        reason: 'Today selected a day three days before the window opens',
      );

      // And the sheet still resolves to nothing rather than to that day.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(results.single, isNull);
    });

    testWidgets('will not select a day missing from selectableDates', (
      WidgetTester tester,
    ) async {
      // A day in today's month that is definitely not today, so the month is
      // reachable while the day itself is not selectable.
      final NepaliDate allowed = today.day == 1
          ? today.lastDayOfMonth
          : today.firstDayOfMonth;
      await _open(
        tester,
        startDate: today.firstDayOfMonth,
        endDate: today.lastDayOfMonth,
        selectableDates: <NepaliDate>[allowed],
      );

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      expect(
        _done(tester).onPressed,
        isNull,
        reason: 'Today bypassed the selectableDates allow-list',
      );
      final DayCell cell = tester.widget<DayCell>(
        find.byWidgetPredicate(
          (Widget w) => w is DayCell && w.day.bsDate == today,
        ),
      );
      expect(cell.day.isSelected, isFalse);
      expect(cell.day.isDisabled, isTrue);
    });

    testWidgets('still selects today when today is inside the window', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        startDate: today,
        durationDays: 30,
      );

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      expect(_done(tester).onPressed, isNotNull);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(results.single?.date, today);
    });

    testWidgets('still navigates to today when today is not selectable', (
      WidgetTester tester,
    ) async {
      // Window opens next month, so today's month sits before it: the button
      // has nowhere useful to go and renders disabled rather than inert.
      await _open(
        tester,
        startDate: today.nextMonth.firstDayOfMonth,
        durationDays: 60,
      );
      expect(_todayButton(tester).onTap, isNull);
    });

    testWidgets('is disabled when today is outside the window entirely', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        startDate: const NepaliDate(2081, 1, 1),
        endDate: const NepaliDate(2081, 12, 30),
      );
      expect(
        _todayButton(tester).onTap,
        isNull,
        reason: 'Today should not look live when it cannot do anything',
      );
    });
  });
}
