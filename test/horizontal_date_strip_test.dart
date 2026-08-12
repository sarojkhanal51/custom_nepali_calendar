import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';
import 'package:custom_nepali_calendar/src/view/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 15 Baishakh 2081 BS = 27 April 2024 AD.
const NepaliDate anchor = NepaliDate(2081, 1, 15);

/// The sheet's cell for [date] — unambiguous where a bare day number is not.
Finder _sheetCell(NepaliDate date) => find.byWidgetPredicate(
  (Widget widget) => widget is DayCell && widget.day.bsDate == date,
);

/// Pumps a strip and records every date it reports.
Future<List<NepaliDate>> _pump(
  WidgetTester tester, {
  NepaliDate? selectedDate,
  int dayCount = 5,
  NepaliDate startDate = anchor,
  NepaliDate? endDate,
  int? durationDays,
  List<NepaliDate>? selectableDates,
  Language language = Language.english,
  CalendarSystem system = CalendarSystem.bs,
  bool showCalendarButton = true,
  double height = 60,
  NepaliCalendarTheme theme = const NepaliCalendarTheme(),
}) async {
  final List<NepaliDate> picked = <NepaliDate>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return HorizontalDateStrip(
              theme: theme,
              selectedDate: selectedDate,
              dayCount: dayCount,
              startDate: startDate,
              endDate: endDate,
              durationDays: durationDays,
              selectableDates: selectableDates,
              language: language,
              system: system,
              showCalendarButton: showCalendarButton,
              height: height,
              onDateSelected: (NepaliDate date) {
                picked.add(date);
                setState(() => selectedDate = date);
              },
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return picked;
}

void main() {
  group('the strip', () {
    testWidgets('shows five consecutive days starting from firstDate', (
      WidgetTester tester,
    ) async {
      await _pump(tester, startDate: anchor);

      for (int day = 15; day <= 19; day++) {
        expect(find.text('$day'), findsOneWidget, reason: 'day $day missing');
      }
      expect(find.text('20'), findsNothing);
      expect(find.text('14'), findsNothing);
    });

    testWidgets('starts at startDate', (WidgetTester tester) async {
      final NepaliDate today = DateConverter.todayBs();
      await _pump(tester, startDate: today);
      expect(find.text('${today.day}'), findsOneWidget);
      expect(find.text('${today.addDays(4).day}'), findsOneWidget);
    });

    testWidgets('dayCount is configurable', (WidgetTester tester) async {
      await _pump(tester, startDate: anchor, dayCount: 3);
      expect(find.text('17'), findsOneWidget);
      expect(find.text('18'), findsNothing);
    });

    testWidgets('each day carries its weekday name underneath', (
      WidgetTester tester,
    ) async {
      await _pump(tester, startDate: anchor);
      // 1 Baishakh 2081 was a Saturday, so day 15 is too — and the strip runs
      // Sat, Sun, Mon, Tue, Wed from there.
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsNothing);
    });

    testWidgets('days that are not today are captioned with their month', (
      WidgetTester tester,
    ) async {
      await _pump(tester, startDate: anchor);
      // Five days inside Baishakh, so five identical captions.
      expect(find.text('Bai'), findsNWidgets(5));
      expect(find.text('Today'), findsNothing);
    });

    testWidgets('today is captioned Today, in the chosen language', (
      WidgetTester tester,
    ) async {
      final NepaliDate today = DateConverter.todayBs();
      await _pump(tester, startDate: today);
      expect(find.text('Today'), findsOneWidget);

      await _pump(tester, startDate: today, language: Language.nepali);
      expect(find.text('आज'), findsOneWidget);
    });

    testWidgets('the caption follows a month boundary', (
      WidgetTester tester,
    ) async {
      // Baishakh 2081 has 31 days, so this strip straddles into Jestha.
      await _pump(tester, startDate: const NepaliDate(2081, 1, 30));
      expect(find.text('Bai'), findsNWidgets(2));
      expect(find.text('Jes'), findsNWidgets(3));
    });

    testWidgets('AD mode captions with Gregorian months', (
      WidgetTester tester,
    ) async {
      // 15 Baishakh 2081 = 27 April 2024, so the strip crosses into May.
      await _pump(tester, startDate: anchor, system: CalendarSystem.ad);
      expect(find.text('Apr'), findsNWidgets(4));
      expect(find.text('May'), findsOneWidget);
    });

    testWidgets('the height is the caller\'s to set', (
      WidgetTester tester,
    ) async {
      await _pump(tester, startDate: anchor, height: 44);
      expect(tester.getSize(find.byType(HorizontalDateStrip)).height, 44);

      await _pump(tester, startDate: anchor, height: 96);
      expect(tester.getSize(find.byType(HorizontalDateStrip)).height, 96);
    });

    testWidgets('Nepali renders Devanagari names and digits', (
      WidgetTester tester,
    ) async {
      await _pump(tester, startDate: anchor, language: Language.nepali);
      expect(find.text('१५'), findsOneWidget);
      expect(find.text('शनि'), findsOneWidget);
      expect(find.text('15'), findsNothing);
    });

    testWidgets('BS mode shows no Gregorian date', (WidgetTester tester) async {
      // 15 Baishakh 2081 = 27 April 2024; only the BS side should be on screen.
      await _pump(tester, startDate: anchor);
      expect(find.text('27 Apr'), findsNothing);
      expect(find.text('27'), findsNothing);
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('AD mode shows no Bikram Sambat date', (
      WidgetTester tester,
    ) async {
      await _pump(tester, startDate: anchor, system: CalendarSystem.ad);
      expect(find.text('15 Bai'), findsNothing);
      expect(find.text('15'), findsNothing);
      expect(find.text('27'), findsOneWidget);
    });

    testWidgets('AD mode shows Gregorian day numbers', (
      WidgetTester tester,
    ) async {
      await _pump(tester, startDate: anchor, system: CalendarSystem.ad);
      // 15 Baishakh 2081 = 27 April 2024.
      expect(find.text('27'), findsOneWidget);
      expect(find.text('15'), findsNothing);
    });
  });

  group('selection', () {
    testWidgets('today starts out selected when the strip covers it', (
      WidgetTester tester,
    ) async {
      final NepaliDate today = DateConverter.todayBs();
      final List<NepaliDate> picked = await _pump(tester, startDate: today);

      expect(picked, <NepaliDate>[today], reason: 'reported exactly once');

      final Iterable<Material> filled = tester
          .widgetList<Material>(find.byType(Material))
          .where(
            (Material m) =>
                m.color == const NepaliCalendarTheme().selectedDayColor,
          );
      expect(filled, hasLength(1), reason: 'today should be painted selected');
    });

    testWidgets('an explicit selectedDate is left alone', (
      WidgetTester tester,
    ) async {
      final List<NepaliDate> picked = await _pump(
        tester,
        startDate: anchor,
        selectedDate: const NepaliDate(2081, 1, 17),
      );
      expect(picked, isEmpty, reason: 'nothing should be reported unasked');
    });

    testWidgets('a strip starting in the future defaults to its first day', (
      WidgetTester tester,
    ) async {
      final NepaliDate later = DateConverter.todayBs().addDays(40);
      final List<NepaliDate> picked = await _pump(tester, startDate: later);
      expect(picked, <NepaliDate>[later]);
    });

    testWidgets('a strip that does not cover today defaults to its first day', (
      WidgetTester tester,
    ) async {
      final List<NepaliDate> picked = await _pump(tester, startDate: anchor);
      expect(picked, <NepaliDate>[anchor]);
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('tapping a day reports it', (WidgetTester tester) async {
      final List<NepaliDate> picked = await _pump(tester, startDate: anchor);

      await tester.tap(find.text('17'));
      await tester.pumpAndSettle();

      // The strip's default is reported first, then the tap.
      expect(picked, <NepaliDate>[anchor, const NepaliDate(2081, 1, 17)]);
    });

    testWidgets('the selected day is filled with selectedDayColor', (
      WidgetTester tester,
    ) async {
      const NepaliCalendarTheme theme = NepaliCalendarTheme(
        selectedDayColor: Color(0xFF445566),
      );
      await _pump(
        tester,
        startDate: anchor,
        selectedDate: const NepaliDate(2081, 1, 17),
        theme: theme,
      );

      final Iterable<Material> filled = tester
          .widgetList<Material>(find.byType(Material))
          .where((Material m) => m.color == theme.selectedDayColor);
      expect(filled, hasLength(1));
    });

    testWidgets('days outside the window are disabled', (
      WidgetTester tester,
    ) async {
      final List<NepaliDate> picked = await _pump(
        tester,
        startDate: const NepaliDate(2081, 1, 16),
        endDate: const NepaliDate(2081, 1, 18),
      );
      // The strip starts at 16, so 15 is not on it at all; 19 is, but is past
      // the window's end.
      expect(find.text('19'), findsOneWidget);
      await tester.tap(find.text('19'));
      await tester.pumpAndSettle();
      expect(picked, <NepaliDate>[
        const NepaliDate(2081, 1, 16),
      ], reason: '19 is past endDate, so only the default was reported');

      await tester.tap(find.text('17'));
      await tester.pumpAndSettle();
      expect(picked.last, const NepaliDate(2081, 1, 17));
    });
  });

  group('selectableDates', () {
    testWidgets('only listed dates report a tap', (WidgetTester tester) async {
      final List<NepaliDate> picked = await _pump(
        tester,
        startDate: anchor,
        selectableDates: const <NepaliDate>[
          NepaliDate(2081, 1, 15),
          NepaliDate(2081, 1, 17),
        ],
      );

      await tester.tap(find.text('16'));
      await tester.pumpAndSettle();
      expect(picked, <NepaliDate>[
        anchor,
      ], reason: '16 is not in selectableDates, so tapping it did nothing');

      await tester.tap(find.text('17'));
      await tester.pumpAndSettle();
      expect(picked.last, const NepaliDate(2081, 1, 17));
    });

    testWidgets('carries into the calendar the button opens', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        startDate: anchor,
        selectableDates: const <NepaliDate>[
          NepaliDate(2081, 1, 15),
          NepaliDate(2081, 1, 20),
        ],
      );

      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<DayCell>(_sheetCell(const NepaliDate(2081, 1, 20)))
            .day
            .isDisabled,
        isFalse,
      );
      expect(
        tester
            .widget<DayCell>(_sheetCell(const NepaliDate(2081, 1, 16)))
            .day
            .isDisabled,
        isTrue,
      );
    });
  });

  group('the calendar button', () {
    testWidgets('opens the sheet and reports what was picked', (
      WidgetTester tester,
    ) async {
      // The sheet opens on startDate's month, so the target sits there too.
      const NepaliDate target = NepaliDate(2081, 1, 26);
      final List<NepaliDate> picked = await _pump(tester, startDate: anchor);

      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Baishakh 2081'), findsOneWidget);

      await tester.tap(_sheetCell(target));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // The strip's own default is reported first, then the pick.
      expect(picked, <NepaliDate>[anchor, target]);
    });

    testWidgets('reopening the calendar after a pick preselects it', (
      WidgetTester tester,
    ) async {
      const NepaliDate target = NepaliDate(2081, 1, 26);
      await _pump(tester, startDate: anchor);

      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      await tester.tap(_sheetCell(target));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // The strip now shows `target` selected — the caller's onDateSelected
      // fed it back in as selectedDate. Reopening the calendar button's
      // sheet passes that along as initialSelection, so it opens on
      // target's month with target already highlighted.
      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      expect(
        tester.widget<DayCell>(_sheetCell(target)).day.isSelected,
        isTrue,
        reason: "the sheet preselects the strip's current value",
      );
    });

    testWidgets('a date picked outside the strip re-anchors it', (
      WidgetTester tester,
    ) async {
      const NepaliDate target = NepaliDate(2081, 1, 26);
      await _pump(tester, startDate: anchor);
      expect(find.text('26'), findsNothing);

      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      await tester.tap(_sheetCell(target));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // The strip now starts at the picked day, so the selection is visible.
      expect(find.text('26'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('15'), findsNothing);
    });

    testWidgets('cancelling the sheet changes nothing', (
      WidgetTester tester,
    ) async {
      final List<NepaliDate> picked = await _pump(tester, startDate: anchor);

      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(picked, <NepaliDate>[anchor], reason: 'only the default');
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('it can be hidden', (WidgetTester tester) async {
      await _pump(tester, startDate: anchor, showCalendarButton: false);
      expect(find.byIcon(Icons.calendar_month_outlined), findsNothing);
    });

    testWidgets('the window is carried into the sheet', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        startDate: const NepaliDate(2081, 1, 10),
        endDate: const NepaliDate(2081, 1, 20),
      );

      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();
      // Only one month is reachable inside that window.
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
            )
            .onPressed,
        isNull,
      );
    });
  });

  // The strip reports a starting selection when the caller passes none. That
  // default used to ignore the window and the allow-list entirely, so the
  // caller ended up holding a date the strip was painting as disabled.
  group('the default selection', () {
    testWidgets('respects selectableDates', (WidgetTester tester) async {
      const NepaliDate allowed = NepaliDate(2081, 1, 17);
      final List<NepaliDate> picked = await _pump(
        tester,
        startDate: anchor,
        selectableDates: <NepaliDate>[allowed],
      );

      expect(picked, <NepaliDate>[allowed]);
    });

    testWidgets('respects the endDate window', (WidgetTester tester) async {
      // The strip shows 15..19 Baishakh but the window closes on the 15th.
      final List<NepaliDate> picked = await _pump(
        tester,
        startDate: anchor,
        durationDays: 1,
      );

      expect(picked, <NepaliDate>[anchor]);
    });

    testWidgets('reports nothing when no visible day is selectable', (
      WidgetTester tester,
    ) async {
      // The only allowed day is well past the five the strip renders.
      final List<NepaliDate> picked = await _pump(
        tester,
        startDate: anchor,
        selectableDates: <NepaliDate>[const NepaliDate(2081, 3, 1)],
      );

      expect(
        picked,
        isEmpty,
        reason: 'reported a day it was simultaneously painting as disabled',
      );
    });
  });

  group('the end of the supported range', () {
    testWidgets('renders instead of throwing out of build', (
      WidgetTester tester,
    ) async {
      await _pump(tester, startDate: NepaliDate.max);

      expect(tester.takeException(), isNull);
      // Only the final representable day is left to show.
      expect(find.text('${NepaliDate.max.day}'), findsOneWidget);
    });

    testWidgets('clamps a strip that straddles the last day', (
      WidgetTester tester,
    ) async {
      await _pump(tester, startDate: NepaliDate.max.subtractDays(2));

      expect(tester.takeException(), isNull);
      for (final NepaliDate day in <NepaliDate>[
        NepaliDate.max.subtractDays(2),
        NepaliDate.max.subtractDays(1),
        NepaliDate.max,
      ]) {
        expect(find.text('${day.day}'), findsOneWidget);
      }
    });
  });

  group('layout', () {
    for (final double width in <double>[320, 390, 430]) {
      for (final Language language in Language.values) {
        testWidgets('fits ${width.toInt()}px wide in $language', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = Size(width * 3, 900 * 3);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);

          await _pump(tester, startDate: anchor, language: language);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
