// Regression tests for initialSelection.
//
// A preselected value is a value the sheet can resolve to — Done is live the
// moment it opens — so it has to clear the same bar a tap does. It did not:
// a stale value replayed into a moved window arrived preselected, rendered
// disabled and selected at the same time, and was confirmable without the
// user touching anything.

import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';
import 'package:custom_nepali_calendar/src/view/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _cell(NepaliDate d) =>
    find.byWidgetPredicate((Widget w) => w is DayCell && w.day.bsDate == d);

DayCell _dayCell(WidgetTester t, NepaliDate d) => t.widget<DayCell>(_cell(d));

FilledButton _done(WidgetTester t) =>
    t.widget<FilledButton>(find.widgetWithText(FilledButton, 'Done'));

Future<List<NepaliCalendarSelection?>> _open(
  WidgetTester tester, {
  NepaliCalendarMode mode = NepaliCalendarMode.single,
  required NepaliDate startDate,
  NepaliDate? endDate,
  int? durationDays,
  List<NepaliDate>? selectableDates,
  NepaliCalendarSelection? initialSelection,
  bool showClearButton = false,
}) async {
  final List<NepaliCalendarSelection?> out = <NepaliCalendarSelection?>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => ElevatedButton(
            onPressed: () async => out.add(
              await showNepaliCalendar(
                context: context,
                theme: const NepaliCalendarTheme(),
                mode: mode,
                startDate: startDate,
                endDate: endDate,
                durationDays: durationDays,
                selectableDates: selectableDates == null
                    ? null
                    : <SelectableDates>[
                        SelectableDates(dates: selectableDates),
                      ],
                initialSelection: initialSelection,
                showClearButton: showClearButton,
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
  return out;
}

void main() {
  group('a stale initialSelection is ignored', () {
    testWidgets('the example-app pattern one day later', (
      WidgetTester t,
    ) async {
      // startDate: NepaliDate.now() + a value persisted from yesterday. The
      // window rolled forward overnight; the stored pick did not.
      final NepaliDate today = NepaliDate.now();
      final NepaliDate yesterday = today.subtractDays(1);
      final List<NepaliCalendarSelection?> out = await _open(
        t,
        startDate: today,
        durationDays: 90,
        initialSelection: NepaliCalendarSelection.single(yesterday),
      );

      expect(
        _done(t).onPressed,
        isNull,
        reason: 'a value from before the window was confirmable on open',
      );
      final DayCell cell = _dayCell(t, yesterday);
      expect(cell.day.isDisabled, isTrue);
      expect(
        cell.day.isSelected,
        isFalse,
        reason: 'a disabled day was also painted as selected',
      );

      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(out.single, isNull);
    });

    testWidgets('a value after the window closes', (WidgetTester t) async {
      const NepaliDate stale = NepaliDate(2081, 9, 3);
      await _open(
        t,
        startDate: const NepaliDate(2081, 1, 1),
        endDate: const NepaliDate(2081, 1, 30),
        initialSelection: const NepaliCalendarSelection.single(stale),
      );
      expect(_done(t).onPressed, isNull);
    });

    testWidgets('a value selectableDates excludes', (WidgetTester t) async {
      const NepaliDate stale = NepaliDate(2081, 1, 5);
      await _open(
        t,
        startDate: const NepaliDate(2081, 1, 1),
        endDate: const NepaliDate(2081, 1, 30),
        selectableDates: <NepaliDate>[const NepaliDate(2081, 1, 9)],
        initialSelection: const NepaliCalendarSelection.single(stale),
      );
      expect(_done(t).onPressed, isNull);
      expect(_dayCell(t, stale).day.isSelected, isFalse);
      expect(_dayCell(t, stale).day.isDisabled, isTrue);
    });

    testWidgets('a range with one end outside the window', (
      WidgetTester t,
    ) async {
      await _open(
        t,
        mode: NepaliCalendarMode.range,
        startDate: const NepaliDate(2081, 1, 10),
        endDate: const NepaliDate(2081, 1, 30),
        initialSelection: const NepaliCalendarSelection.range(
          NepaliDateRange(
            start: NepaliDate(2081, 1, 5), // before the window opens
            end: NepaliDate(2081, 1, 20),
          ),
        ),
      );
      expect(_done(t).onPressed, isNull);
    });
  });

  group('a valid initialSelection still works', () {
    testWidgets('a single value inside the window is preselected', (
      WidgetTester t,
    ) async {
      const NepaliDate d = NepaliDate(2081, 1, 15);
      final List<NepaliCalendarSelection?> out = await _open(
        t,
        startDate: const NepaliDate(2081, 1, 1),
        endDate: const NepaliDate(2081, 1, 30),
        initialSelection: const NepaliCalendarSelection.single(d),
      );
      expect(_dayCell(t, d).day.isSelected, isTrue);
      expect(_done(t).onPressed, isNotNull);
      await t.tap(find.text('Done'));
      await t.pumpAndSettle();
      expect(out.single?.date, d);
    });

    testWidgets('a value the allow-list permits is preselected', (
      WidgetTester t,
    ) async {
      const NepaliDate d = NepaliDate(2081, 1, 9);
      await _open(
        t,
        startDate: const NepaliDate(2081, 1, 1),
        endDate: const NepaliDate(2081, 1, 30),
        selectableDates: <NepaliDate>[d],
        initialSelection: const NepaliCalendarSelection.single(d),
      );
      expect(_dayCell(t, d).day.isSelected, isTrue);
      expect(_done(t).onPressed, isNotNull);
    });

    testWidgets('a range wholly inside the window is preselected', (
      WidgetTester t,
    ) async {
      const NepaliDateRange r = NepaliDateRange(
        start: NepaliDate(2081, 1, 12),
        end: NepaliDate(2081, 1, 20),
      );
      final List<NepaliCalendarSelection?> out = await _open(
        t,
        mode: NepaliCalendarMode.range,
        startDate: const NepaliDate(2081, 1, 10),
        endDate: const NepaliDate(2081, 1, 30),
        initialSelection: const NepaliCalendarSelection.range(r),
      );
      expect(_done(t).onPressed, isNotNull);
      await t.tap(find.text('Done'));
      await t.pumpAndSettle();
      expect(out.single?.range, r);
    });

    testWidgets('the sheet opens on the selection\'s month, not startDate\'s', (
      WidgetTester t,
    ) async {
      await _open(
        t,
        startDate: const NepaliDate(2081, 1, 1),
        endDate: const NepaliDate(2081, 12, 30),
        initialSelection: const NepaliCalendarSelection.single(
          NepaliDate(2081, 6, 12),
        ),
      );
      expect(find.text('Ashwin 2081'), findsOneWidget);
    });
  });

  group('a mode-mismatched initialSelection', () {
    testWidgets('offers no Clear button in range mode', (WidgetTester t) async {
      await _open(
        t,
        mode: NepaliCalendarMode.range,
        startDate: const NepaliDate(2081, 1, 1),
        endDate: const NepaliDate(2081, 1, 30),
        initialSelection: const NepaliCalendarSelection.single(
          NepaliDate(2081, 1, 12),
        ),
        showClearButton: true,
      );
      expect(
        find.text('Clear'),
        findsNothing,
        reason: 'Clear offered to erase a value the sheet never applied',
      );
      expect(_done(t).onPressed, isNull);
    });

    testWidgets('offers no Clear button in single mode', (
      WidgetTester t,
    ) async {
      await _open(
        t,
        startDate: const NepaliDate(2081, 1, 1),
        endDate: const NepaliDate(2081, 1, 30),
        initialSelection: const NepaliCalendarSelection.range(
          NepaliDateRange(
            start: NepaliDate(2081, 1, 12),
            end: NepaliDate(2081, 1, 20),
          ),
        ),
        showClearButton: true,
      );
      expect(find.text('Clear'), findsNothing);
      expect(_done(t).onPressed, isNull);
    });

    testWidgets(
      'a cleared selection handed back in is not treated as a value',
      (WidgetTester t) async {
        await _open(
          t,
          startDate: const NepaliDate(2081, 1, 1),
          endDate: const NepaliDate(2081, 1, 30),
          initialSelection: const NepaliCalendarSelection.cleared(),
          showClearButton: true,
        );
        expect(find.text('Clear'), findsNothing);
        expect(_done(t).onPressed, isNull);
      },
    );
  });

  group('CalendarStrings is reachable from the public library', () {
    // It documents itself as public API; it used not to be exported, so code
    // following its own dartdoc would not compile. This file imports only
    // package:custom_nepali_calendar/custom_nepali_calendar.dart.
    test('month and weekday names resolve through the public import', () {
      expect(
        CalendarStrings.monthName(1, CalendarSystem.bs, Language.english),
        'Baishakh',
      );
      expect(
        CalendarStrings.monthName(1, CalendarSystem.bs, Language.nepali),
        'बैशाख',
      );
      expect(CalendarStrings.weekdayName(6, Language.english), 'Saturday');
      expect(
        CalendarStrings.weekdayName(6, Language.english, short: true),
        'Sat',
      );
      expect(CalendarStrings.today(Language.nepali), 'आज');
      expect(CalendarStrings.bsMonthsEnglish, hasLength(12));
    });
  });
}
