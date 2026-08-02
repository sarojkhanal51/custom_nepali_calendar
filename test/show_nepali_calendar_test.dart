import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';
import 'package:custom_nepali_calendar/src/view/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sheet opens on [startDate]'s month, so bounding the tests to BS 2081 pins
/// the visible month to Baishakh 2081 (13 April – 13 May 2024) no matter when
/// the suite runs. 15 Baishakh 2081 BS = 27 April 2024 AD.
const NepaliDate _anchor = NepaliDate(2081, 1, 15);
const NepaliDateRange _year2081 = NepaliDateRange(
  start: NepaliDate(2081, 1, 1),
  end: NepaliDate(2081, 12, 31),
);
final DateTime _anchorAd = DateTime(2024, 4, 27);

Finder _cellFor(NepaliDate date) => find.byWidgetPredicate(
  (Widget widget) => widget is DayCell && widget.day.bsDate == date,
);

DayCell _dayCell(WidgetTester tester, NepaliDate date) =>
    tester.widget<DayCell>(_cellFor(date));

FilledButton _confirmButton(WidgetTester tester, [String label = 'Done']) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

IconButton _arrow(WidgetTester tester, {required bool next}) =>
    tester.widget<IconButton>(
      find.widgetWithIcon(
        IconButton,
        next ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
      ),
    );

/// Opens the sheet from a button and records whatever it resolves to.
///
/// Bounds default to the BS 2081 window; pass `allowedRange: null` for the
/// unbounded case.
Future<List<NepaliCalendarSelection?>> _open(
  WidgetTester tester, {
  NepaliCalendarMode mode = NepaliCalendarMode.single,
  NepaliCalendarTheme theme = const NepaliCalendarTheme(),
  Language language = Language.english,
  CalendarSystem initialSystem = CalendarSystem.bs,
  NepaliDateRange? allowedRange = _year2081,
  int? maxDays,
  bool showSystemSwitch = true,
  String? title,
  String? confirmLabel,
  String? cancelLabel,
}) async {
  final List<NepaliCalendarSelection?> results = <NepaliCalendarSelection?>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async => results.add(
              await showNepaliCalendar(
                context: context,
                mode: mode,
                theme: theme,
                language: language,
                initialSystem: initialSystem,
                allowedRange: allowedRange,
                maxDays: maxDays,
                showSystemSwitch: showSystemSwitch,
                title: title,
                confirmLabel: confirmLabel,
                cancelLabel: cancelLabel,
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

/// Taps [date] and settles.
Future<void> _tapDay(WidgetTester tester, NepaliDate date) async {
  await tester.tap(_cellFor(date));
  await tester.pumpAndSettle();
}

void main() {
  group('single mode', () {
    testWidgets('opens in a bottom sheet with nothing selected', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Baishakh 2081'), findsOneWidget);
      expect(find.text('April / May 2024 AD'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(_confirmButton(tester).onPressed, isNull);
      expect(
        tester
            .widgetList<DayCell>(find.byType(DayCell))
            .every((DayCell cell) => !cell.day.isSelected),
        isTrue,
      );
    });

    testWidgets('picking a day enables Done, with no date readout', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _tapDay(tester, _anchor);

      expect(_dayCell(tester, _anchor).day.isSelected, isTrue);
      expect(_confirmButton(tester).onPressed, isNotNull);
      // The grid is the only place a date appears; nothing is echoed below it.
      expect(find.text('15 Bai 2081'), findsNothing);
      expect(
        find.textContaining('Baishakh 2081'),
        findsOneWidget,
      ); // header only
    });

    testWidgets('returns the picked day, and only date is set', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(tester);

      await _tapDay(tester, const NepaliDate(2081, 1, 20));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      final NepaliCalendarSelection selection = results.single!;
      expect(selection.mode, NepaliCalendarMode.single);
      expect(selection.date, const NepaliDate(2081, 1, 20));
      expect(selection.dateTime, DateTime(2024, 5, 2));
      expect(selection.range, isNull);
      expect(selection.dateTimeRange, isNull);
    });

    testWidgets('a second tap replaces the first', (WidgetTester tester) async {
      final List<NepaliCalendarSelection?> results = await _open(tester);

      await _tapDay(tester, const NepaliDate(2081, 1, 10));
      await _tapDay(tester, const NepaliDate(2081, 1, 20));
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 10)).day.isSelected,
        isFalse,
      );

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(results.single!.date, const NepaliDate(2081, 1, 20));
    });

    testWidgets('Cancel resolves to null', (WidgetTester tester) async {
      final List<NepaliCalendarSelection?> results = await _open(tester);
      await _tapDay(tester, _anchor);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(results.single, isNull);
    });

    testWidgets('tapping outside the sheet resolves to null', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(results.single, isNull);
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('range mode', () {
    testWidgets('two taps produce a range, and only range is set', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        mode: NepaliCalendarMode.range,
      );

      expect(_confirmButton(tester).onPressed, isNull);

      await _tapDay(tester, const NepaliDate(2081, 1, 10));
      // Incomplete: the start is highlighted but the result is not usable yet.
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 10)).day.isSelected,
        isTrue,
      );
      expect(_confirmButton(tester).onPressed, isNull);

      await _tapDay(tester, const NepaliDate(2081, 1, 16));
      expect(_confirmButton(tester).onPressed, isNotNull);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      final NepaliCalendarSelection selection = results.single!;
      expect(selection.mode, NepaliCalendarMode.range);
      expect(
        selection.range,
        const NepaliDateRange(
          start: NepaliDate(2081, 1, 10),
          end: NepaliDate(2081, 1, 16),
        ),
      );
      expect(selection.dateTimeRange?.start, DateTime(2024, 4, 22));
      expect(selection.date, isNull);
    });

    testWidgets('the days between the ends are banded', (
      WidgetTester tester,
    ) async {
      await _open(tester, mode: NepaliCalendarMode.range);
      await _tapDay(tester, const NepaliDate(2081, 1, 10));
      await _tapDay(tester, const NepaliDate(2081, 1, 16));

      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 10)).day.isRangeStart,
        isTrue,
      );
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 13)).day.isInRange,
        isTrue,
      );
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 13)).day.isRangeEnd,
        isFalse,
      );
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 16)).day.isRangeEnd,
        isTrue,
      );
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 17)).day.isInRange,
        isFalse,
      );
    });

    testWidgets('tapping before the start moves the start', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        mode: NepaliCalendarMode.range,
      );

      await _tapDay(tester, const NepaliDate(2081, 1, 20));
      await _tapDay(tester, const NepaliDate(2081, 1, 12));
      expect(_confirmButton(tester).onPressed, isNull);

      await _tapDay(tester, const NepaliDate(2081, 1, 14));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(
        results.single!.range,
        const NepaliDateRange(
          start: NepaliDate(2081, 1, 12),
          end: NepaliDate(2081, 1, 14),
        ),
      );
    });

    testWidgets('a third tap starts a fresh range', (
      WidgetTester tester,
    ) async {
      await _open(tester, mode: NepaliCalendarMode.range);
      await _tapDay(tester, const NepaliDate(2081, 1, 10));
      await _tapDay(tester, const NepaliDate(2081, 1, 16));
      await _tapDay(tester, const NepaliDate(2081, 1, 22));

      expect(_confirmButton(tester).onPressed, isNull);
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 13)).day.isInRange,
        isFalse,
      );
    });

    testWidgets('a single-day range is allowed', (WidgetTester tester) async {
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        mode: NepaliCalendarMode.range,
      );

      await _tapDay(tester, _anchor);
      await _tapDay(tester, _anchor);
      expect(_confirmButton(tester).onPressed, isNotNull);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      final NepaliDateRange range = results.single!.range!;
      expect(range.isSingleDay, isTrue);
      expect(range.toDateTimeRange().start, _anchorAd);
    });

    testWidgets('a range spanning two months keeps both ends', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        mode: NepaliCalendarMode.range,
      );

      await _tapDay(tester, const NepaliDate(2081, 1, 28));
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      await _tapDay(tester, const NepaliDate(2081, 2, 4));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(
        results.single!.range,
        const NepaliDateRange(
          start: NepaliDate(2081, 1, 28),
          end: NepaliDate(2081, 2, 4),
        ),
      );
    });
  });

  group('caller-supplied theme', () {
    const NepaliCalendarTheme theme = NepaliCalendarTheme(
      primaryColor: Color(0xFF112233),
      selectedDayColor: Color(0xFF445566),
      weekendColor: Color(0xFFAABBCC),
      backgroundColor: Color(0xFFF0F0F0),
    );

    testWidgets('primaryColor paints the header and the confirm button', (
      WidgetTester tester,
    ) async {
      await _open(tester, theme: theme);

      expect(
        tester
            .widgetList<Container>(find.byType(Container))
            .any((Container c) => c.color == theme.primaryColor),
        isTrue,
      );
      expect(
        _confirmButton(tester).style?.backgroundColor?.resolve(<WidgetState>{}),
        theme.primaryColor,
      );
    });

    testWidgets('selectedDayColor paints the selected day', (
      WidgetTester tester,
    ) async {
      await _open(tester, theme: theme);
      await _tapDay(tester, _anchor);

      final Iterable<DecoratedBox> boxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: _cellFor(_anchor),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        boxes.any(
          (DecoratedBox box) =>
              (box.decoration as BoxDecoration).color == theme.selectedDayColor,
        ),
        isTrue,
      );
    });

    testWidgets('weekendColor styles Saturday', (WidgetTester tester) async {
      await _open(tester, theme: theme);
      expect(
        tester.widget<Text>(find.text('Sat')).style?.color,
        theme.weekendColor,
      );
    });
  });

  group('language and calendar system', () {
    testWidgets('Nepali renders Devanagari everywhere', (
      WidgetTester tester,
    ) async {
      await _open(tester, language: Language.nepali);

      expect(find.text('बैशाख २०८१'), findsOneWidget);
      expect(find.text('आइत'), findsOneWidget);
      expect(find.text('शनि'), findsOneWidget);
      expect(find.text('ठीक छ'), findsOneWidget);
      expect(find.text('रद्द'), findsOneWidget);
      expect(find.text('15'), findsNothing);

      await _tapDay(tester, _anchor);
      expect(_dayCell(tester, _anchor).day.isSelected, isTrue);
      expect(find.text('१५ बैशाख २०८१'), findsNothing);
    });

    testWidgets('opening in AD mode shows Gregorian months', (
      WidgetTester tester,
    ) async {
      await _open(tester, initialSystem: CalendarSystem.ad);
      expect(find.text('April 2024'), findsOneWidget);
      expect(find.text('Chaitra 2080 / Baishakh 2081 BS'), findsOneWidget);
    });

    testWidgets('the BS/AD switch keeps the selected day', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(tester);
      await _tapDay(tester, _anchor);

      await tester.tap(find.text('AD'));
      await tester.pumpAndSettle();
      expect(find.text('April 2024'), findsOneWidget);
      expect(_dayCell(tester, _anchor).day.isSelected, isTrue);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      // Same physical day, still expressed in Bikram Sambat.
      expect(results.single!.date, _anchor);
      expect(results.single!.dateTime, _anchorAd);
    });

    testWidgets('there is no language switch in the sheet', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      expect(find.text('EN'), findsNothing);
      expect(find.text('ने'), findsNothing);
      expect(find.text('BS'), findsOneWidget);
      expect(find.text('AD'), findsOneWidget);
    });

    testWidgets('the BS/AD switch can be hidden', (WidgetTester tester) async {
      await _open(tester, showSystemSwitch: false);
      expect(find.text('BS'), findsNothing);
      expect(find.text('AD'), findsNothing);
      expect(find.text('Today'), findsOneWidget);
    });
  });

  group('startDate / endDate window', () {
    testWidgets('with no bounds the sheet opens on the current month', (
      WidgetTester tester,
    ) async {
      await _open(tester, allowedRange: null);

      final NepaliDate today = DateConverter.todayBs();
      expect(find.text(today.format('MMMM yyyy')), findsOneWidget);
      expect(_dayCell(tester, today).day.isDisabled, isFalse);
      expect(_dayCell(tester, today).day.isToday, isTrue);
      // The whole supported range stays reachable in both directions.
      expect(_arrow(tester, next: false).onPressed, isNotNull);
      expect(_arrow(tester, next: true).onPressed, isNotNull);
    });

    testWidgets("the sheet opens on the window's first month", (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        allowedRange: const NepaliDateRange(
          start: NepaliDate(2090, 5, 1),
          end: NepaliDate(2090, 7, 30),
        ),
      );
      expect(find.text('Bhadra 2090'), findsOneWidget);
    });

    testWidgets('days outside the window are greyed out and inert', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        allowedRange: const NepaliDateRange(
          start: NepaliDate(2081, 1, 10),
          end: NepaliDate(2081, 1, 20),
        ),
      );

      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 9)).day.isDisabled,
        isTrue,
      );
      expect(_dayCell(tester, const NepaliDate(2081, 1, 9)).onTap, isNull);
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 21)).day.isDisabled,
        isTrue,
      );
      expect(_dayCell(tester, const NepaliDate(2081, 1, 10)).onTap, isNotNull);
      expect(_dayCell(tester, const NepaliDate(2081, 1, 20)).onTap, isNotNull);
    });

    testWidgets('both ends of the window are pickable', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        allowedRange: const NepaliDateRange(
          start: NepaliDate(2081, 1, 10),
          end: NepaliDate(2081, 1, 20),
        ),
      );

      await _tapDay(tester, const NepaliDate(2081, 1, 20));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(results.single!.date, const NepaliDate(2081, 1, 20));
    });

    testWidgets('a one-month window disables both arrows', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        allowedRange: const NepaliDateRange(
          start: NepaliDate(2081, 1, 10),
          end: NepaliDate(2081, 1, 20),
        ),
      );
      expect(_arrow(tester, next: true).onPressed, isNull);
      expect(_arrow(tester, next: false).onPressed, isNull);
    });

    testWidgets('the arrows stop at the window edges', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        allowedRange: const NepaliDateRange(
          start: NepaliDate(2081, 1, 5),
          end: NepaliDate(2081, 3, 5),
        ),
      );

      expect(find.text('Baishakh 2081'), findsOneWidget);
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('Ashar 2081'), findsOneWidget);
      expect(_arrow(tester, next: true).onPressed, isNull);
    });

    testWidgets('a window wider than a month leaves the far side open', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        allowedRange: const NepaliDateRange(
          start: NepaliDate(2081, 1, 10),
          end: NepaliDate(2081, 6, 20),
        ),
      );
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 9)).day.isDisabled,
        isTrue,
      );
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 31)).day.isDisabled,
        isFalse,
      );
      expect(_arrow(tester, next: true).onPressed, isNotNull);
      expect(_arrow(tester, next: false).onPressed, isNull);
    });

    testWidgets('a range cannot cross the window edges', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        mode: NepaliCalendarMode.range,
        allowedRange: const NepaliDateRange(
          start: NepaliDate(2081, 1, 10),
          end: NepaliDate(2081, 1, 20),
        ),
      );

      expect(_cellFor(const NepaliDate(2081, 1, 25)), findsOneWidget);
      expect(_dayCell(tester, const NepaliDate(2081, 1, 25)).onTap, isNull);
    });
  });

  group('maxDays', () {
    testWidgets('on its own it counts forward from today', (
      WidgetTester tester,
    ) async {
      // Asserted relative to today so the test holds whenever it runs; the exact
      // boundary is pinned by the allowedRange cases below.
      await _open(tester, allowedRange: null, maxDays: 30);

      final NepaliDate today = DateConverter.todayBs();
      expect(find.text(today.format('MMMM yyyy')), findsOneWidget);
      expect(_dayCell(tester, today).day.isDisabled, isFalse);
      expect(_dayCell(tester, today).onTap, isNotNull);
      // The window starts today, so there is nothing earlier to navigate to.
      expect(_arrow(tester, next: false).onPressed, isNull);
    });

    testWidgets('combined with allowedRange, the tighter end wins', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        allowedRange: const NepaliDateRange(
          start: NepaliDate(2081, 1, 10),
          end: NepaliDate(2081, 12, 30),
        ),
        maxDays: 7,
      );

      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 16)).day.isDisabled,
        isFalse,
      );
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 17)).day.isDisabled,
        isTrue,
      );
      expect(_arrow(tester, next: true).onPressed, isNull);
    });

    testWidgets('a shorter allowedRange wins over a longer maxDays', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        allowedRange: const NepaliDateRange(
          start: NepaliDate(2081, 1, 10),
          end: NepaliDate(2081, 1, 14),
        ),
        maxDays: 30,
      );

      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 14)).day.isDisabled,
        isFalse,
      );
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 15)).day.isDisabled,
        isTrue,
      );
    });

    testWidgets('null means no limit at all', (WidgetTester tester) async {
      await _open(tester, allowedRange: null);

      final NepaliDate today = DateConverter.todayBs();
      expect(_dayCell(tester, today.addDays(20)).day.isDisabled, isFalse);
      expect(_arrow(tester, next: false).onPressed, isNotNull);
      expect(_arrow(tester, next: true).onPressed, isNotNull);
    });

    testWidgets('a range cannot be longer than the window', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        mode: NepaliCalendarMode.range,
        allowedRange: const NepaliDateRange(
          start: NepaliDate(2081, 1, 10),
          end: NepaliDate(2081, 12, 30),
        ),
        maxDays: 7,
      );

      await _tapDay(tester, const NepaliDate(2081, 1, 10));
      await _tapDay(tester, const NepaliDate(2081, 1, 16));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(results.single!.range!.lengthInDays, 7);
    });

    testWidgets('it applies in AD mode exactly as in BS mode', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        initialSystem: CalendarSystem.ad,
        allowedRange: const NepaliDateRange(
          start: NepaliDate(2081, 1, 10),
          end: NepaliDate(2081, 12, 30),
        ),
        maxDays: 7,
      );

      // Same days are blocked whichever calendar is on screen.
      expect(find.text('April 2024'), findsOneWidget);
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 9)).day.isDisabled,
        isTrue,
      );
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 16)).day.isDisabled,
        isFalse,
      );
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 17)).day.isDisabled,
        isTrue,
      );
    });

    testWidgets('the window survives a BS/AD switch', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        allowedRange: const NepaliDateRange(
          start: NepaliDate(2081, 1, 10),
          end: NepaliDate(2081, 12, 30),
        ),
        maxDays: 7,
      );

      await tester.tap(find.text('AD'));
      await tester.pumpAndSettle();
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 16)).day.isDisabled,
        isFalse,
      );
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 17)).day.isDisabled,
        isTrue,
      );
    });
  });

  group('labels', () {
    testWidgets('custom labels replace the defaults', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        title: 'Delivery date',
        confirmLabel: 'Apply',
        cancelLabel: 'Back',
      );
      expect(find.text('Delivery date'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('without a title the sheet is just grid and buttons', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _tapDay(tester, _anchor);

      // Everything between the weekday grid and the buttons is gone.
      expect(find.text('Select a date'), findsNothing);
      expect(find.text('15 Bai 2081'), findsNothing);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('layout', () {
    // Overflow surfaces as an exception in widget tests, so pumping the sheet at
    // real phone widths guards against clipped headers and cramped Devanagari.
    for (final double width in <double>[320, 390, 430]) {
      for (final Language language in Language.values) {
        testWidgets('fits ${width.toInt()}px wide in $language', (
          WidgetTester tester,
        ) async {
          tester.view.physicalSize = Size(width * 3, 900 * 3);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);

          await _open(
            tester,
            mode: NepaliCalendarMode.range,
            language: language,
          );
          await _tapDay(tester, const NepaliDate(2081, 1, 10));
          await _tapDay(tester, const NepaliDate(2081, 1, 16));

          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
