import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';
import 'package:custom_nepali_calendar/src/view/calendar_header.dart';
import 'package:custom_nepali_calendar/src/view/calendar_switch.dart';
import 'package:custom_nepali_calendar/src/view/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sheet opens on [startDate]'s month, so bounding the tests to BS 2081 pins
/// the visible month to Baishakh 2081 (13 April – 13 May 2024) no matter when
/// the suite runs. 15 Baishakh 2081 BS = 27 April 2024 AD.
const NepaliDate _anchor = NepaliDate(2081, 1, 15);
const NepaliDate _yearStart = NepaliDate(2081, 1, 1);
const NepaliDate _yearEnd = NepaliDate(2081, 12, 31);
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
/// Bounds default to the BS 2081 window.
Future<List<NepaliCalendarSelection?>> _open(
  WidgetTester tester, {
  NepaliCalendarMode mode = NepaliCalendarMode.single,
  NepaliCalendarPresentation presentation =
      NepaliCalendarPresentation.bottomSheet,
  NepaliCalendarTheme theme = const NepaliCalendarTheme(),
  Brightness appBrightness = Brightness.light,
  Language language = Language.english,
  CalendarSystem initialSystem = CalendarSystem.bs,
  NepaliDate startDate = _yearStart,
  NepaliDate? endDate = _yearEnd,
  int? durationDays,
  bool showSystemSwitch = true,
  List<NepaliDate>? selectableDates,
  NepaliCalendarSelection? initialSelection,
  bool isDismissible = false,
  bool showClearButton = false,
  String? clearLabel,
  String? confirmLabel,
  String? cancelLabel,
}) async {
  final List<NepaliCalendarSelection?> results = <NepaliCalendarSelection?>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D28D9),
          brightness: appBrightness,
        ),
      ),
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async => results.add(
              await showNepaliCalendar(
                context: context,
                mode: mode,
                presentation: presentation,
                theme: theme,
                language: language,
                initialSystem: initialSystem,
                startDate: startDate,
                endDate: endDate,
                durationDays: durationDays,
                showSystemSwitch: showSystemSwitch,
                selectableDates: selectableDates,
                initialSelection: initialSelection,
                isDismissible: isDismissible,
                showClearButton: showClearButton,
                clearLabel: clearLabel,
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

    testWidgets(
      'reopening without passing initialSelection shows nothing selected',
      (WidgetTester tester) async {
        // Pick, confirm, and let the sheet close.
        await _open(tester);
        await _tapDay(tester, const NepaliDate(2081, 1, 20));
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);

        // Tap the same "open" button again, from the same host screen — no
        // remount involved. Nothing carries the previous pick back in unless
        // the caller explicitly threads it through as initialSelection (see
        // the "initialSelection" group below).
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(_confirmButton(tester).onPressed, isNull);
        expect(
          tester
              .widgetList<DayCell>(find.byType(DayCell))
              .every((DayCell cell) => !cell.day.isSelected),
          isTrue,
          reason: 'the previous pick is not preselected without opting in',
        );
      },
    );

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

    testWidgets('by default a tap outside does not dismiss the sheet', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(results, isEmpty, reason: 'the sheet should not have resolved');
    });

    testWidgets('isDismissible: true lets a tap outside resolve to null', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        isDismissible: true,
      );
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

    testWidgets(
      'reopening after picking a range and confirming shows no band',
      (WidgetTester tester) async {
        await _open(tester, mode: NepaliCalendarMode.range);
        await _tapDay(tester, const NepaliDate(2081, 1, 10));
        await _tapDay(tester, const NepaliDate(2081, 1, 16));
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(_confirmButton(tester).onPressed, isNull);
        expect(
          tester
              .widgetList<DayCell>(find.byType(DayCell))
              .every(
                (DayCell cell) =>
                    !cell.day.isSelected &&
                    !cell.day.isInRange &&
                    !cell.day.isRangeStart &&
                    !cell.day.isRangeEnd,
              ),
          isTrue,
          reason: 'the previous range is not preselected on reopen',
        );
      },
    );

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

  group('light and dark palettes', () {
    Color headerColor(WidgetTester tester) => tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(CalendarHeader),
            matching: find.byType(Container),
          ),
        )
        .first
        .color!;

    testWidgets('the passed theme is what gets painted', (
      WidgetTester tester,
    ) async {
      const NepaliCalendarTheme brand = NepaliCalendarTheme(
        primaryColor: Color(0xFF112233),
      );
      await _open(tester, theme: brand);
      expect(headerColor(tester), brand.primaryColor);
    });

    testWidgets('the dark preset paints dark whatever the app is doing', (
      WidgetTester tester,
    ) async {
      await _open(tester, theme: NepaliCalendarTheme.dark());
      expect(headerColor(tester), NepaliCalendarTheme.dark().primaryColor);
    });

    testWidgets('fromTheme follows a light app', (WidgetTester tester) async {
      final ThemeData app = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6D28D9)),
      );
      await _open(tester, theme: NepaliCalendarTheme.fromTheme(app));
      expect(headerColor(tester), app.colorScheme.primary);
    });

    testWidgets('the active switch segment stays legible in every preset', (
      WidgetTester tester,
    ) async {
      // The selected label is painted in primaryColor on top of the pill, so the
      // two must not collapse into each other — as they did when the pill fell
      // back to backgroundColor in the dark preset.
      for (final NepaliCalendarTheme palette in <NepaliCalendarTheme>[
        const NepaliCalendarTheme(),
        NepaliCalendarTheme.dark(),
      ]) {
        await _open(tester, theme: palette);

        final Color fill = tester
            .widgetList<AnimatedContainer>(
              find.descendant(
                of: find.byType(CalendarSwitch),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .map(
              (AnimatedContainer c) => (c.decoration! as BoxDecoration).color!,
            )
            .firstWhere((Color c) => c.a != 0);
        final Color label = tester.widget<Text>(find.text('BS')).style!.color!;

        expect(
          ThemeData.estimateBrightnessForColor(fill),
          isNot(ThemeData.estimateBrightnessForColor(label)),
          reason: 'active pill $fill and its label $label read the same',
        );

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('fromTheme follows a dark app', (WidgetTester tester) async {
      final ThemeData app = ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D28D9),
          brightness: Brightness.dark,
        ),
      );
      await _open(
        tester,
        theme: NepaliCalendarTheme.fromTheme(app),
        appBrightness: Brightness.dark,
      );
      expect(headerColor(tester), app.colorScheme.primary);
      // A dark scheme yields a dark surface, so the sheet reads as dark.
      expect(
        ThemeData.estimateBrightnessForColor(
          NepaliCalendarTheme.fromTheme(app).backgroundColor,
        ),
        Brightness.dark,
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

    testWidgets('Today stays on the right when the switch is hidden', (
      WidgetTester tester,
    ) async {
      await _open(tester, showSystemSwitch: false);

      final Rect header = tester.getRect(find.byType(CalendarHeader));
      expect(
        tester.getCenter(find.text('Today')).dx,
        greaterThan(header.center.dx),
        reason: 'Today slid to the leading edge with nothing to space against',
      );
    });

    testWidgets('with the switch shown, it leads and Today trails', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      final Rect header = tester.getRect(find.byType(CalendarHeader));
      expect(tester.getCenter(find.text('BS')).dx, lessThan(header.center.dx));
      expect(
        tester.getCenter(find.text('Today')).dx,
        greaterThan(header.center.dx),
      );
    });
  });

  group('the window: startDate, endDate, durationDays', () {
    testWidgets('it opens on startDate and offers nothing earlier', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        startDate: const NepaliDate(2081, 1, 10),
        endDate: const NepaliDate(2081, 1, 20),
      );

      expect(find.text('Baishakh 2081'), findsOneWidget);
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 9)).day.isDisabled,
        isTrue,
      );
      expect(_dayCell(tester, const NepaliDate(2081, 1, 9)).onTap, isNull);
      expect(_dayCell(tester, const NepaliDate(2081, 1, 10)).onTap, isNotNull);
      expect(_arrow(tester, next: false).onPressed, isNull);
    });

    testWidgets('endDate closes the window', (WidgetTester tester) async {
      await _open(
        tester,
        startDate: const NepaliDate(2081, 1, 10),
        endDate: const NepaliDate(2081, 1, 20),
      );

      expect(_dayCell(tester, const NepaliDate(2081, 1, 20)).onTap, isNotNull);
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 21)).day.isDisabled,
        isTrue,
      );
      expect(_arrow(tester, next: true).onPressed, isNull);
    });

    testWidgets('durationDays counts the start day', (
      WidgetTester tester,
    ) async {
      // 7 days from the 10th means the 10th through the 16th.
      await _open(
        tester,
        startDate: const NepaliDate(2081, 1, 10),
        endDate: null,
        durationDays: 7,
      );

      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 16)).day.isDisabled,
        isFalse,
      );
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 17)).day.isDisabled,
        isTrue,
      );
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 9)).day.isDisabled,
        isTrue,
      );
    });

    testWidgets('with neither, the window runs to the supported end', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        startDate: const NepaliDate(2081, 1, 10),
        endDate: null,
      );

      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 31)).day.isDisabled,
        isFalse,
      );
      expect(_arrow(tester, next: true).onPressed, isNotNull);
      expect(_arrow(tester, next: false).onPressed, isNull);
    });

    testWidgets('both ends of the window are pickable', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        startDate: const NepaliDate(2081, 1, 10),
        endDate: const NepaliDate(2081, 1, 20),
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
        startDate: const NepaliDate(2081, 1, 10),
        endDate: const NepaliDate(2081, 1, 20),
      );
      expect(_arrow(tester, next: true).onPressed, isNull);
      expect(_arrow(tester, next: false).onPressed, isNull);
    });

    testWidgets('the arrows stop at the window edges', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        startDate: const NepaliDate(2081, 1, 5),
        endDate: const NepaliDate(2081, 3, 5),
      );

      expect(find.text('Baishakh 2081'), findsOneWidget);
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('Ashar 2081'), findsOneWidget);
      expect(_arrow(tester, next: true).onPressed, isNull);
    });

    testWidgets('a range cannot be longer than the window', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        mode: NepaliCalendarMode.range,
        startDate: const NepaliDate(2081, 1, 10),
        endDate: null,
        durationDays: 7,
      );

      await _tapDay(tester, const NepaliDate(2081, 1, 10));
      // The 17th is on the page but past the window, so it cannot extend the
      // range beyond seven days.
      expect(_dayCell(tester, const NepaliDate(2081, 1, 17)).onTap, isNull);

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
        startDate: const NepaliDate(2081, 1, 10),
        endDate: null,
        durationDays: 7,
      );

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
        startDate: const NepaliDate(2081, 1, 10),
        endDate: null,
        durationDays: 7,
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

  group('the range edges', () {
    // A Gregorian month at either edge reaches past what the BS table covers:
    // April 1913 opens twelve days before 1 Baishakh 1970. Converting that month
    // to Bikram Sambat for the header used to throw mid-build, which froze the
    // calendar the moment the user switched to AD.
    testWidgets('switching to AD at the start of the range does not throw', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        startDate: NepaliDate.min,
        endDate: null,
        durationDays: 60,
      );

      await tester.tap(find.text('AD'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('April 1913'), findsOneWidget);
    });

    testWidgets('and switching back again does not throw', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        startDate: NepaliDate.min,
        endDate: null,
        durationDays: 60,
      );

      await tester.tap(find.text('AD'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BS'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Baishakh 1970'), findsOneWidget);
    });

    testWidgets('opening in AD at the start of the range does not throw', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        initialSystem: CalendarSystem.ad,
        startDate: NepaliDate.min,
        endDate: null,
        durationDays: 60,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the end of the range survives the switch too', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        startDate: NepaliDate.max.subtractDays(20),
        endDate: NepaliDate.max,
      );

      await tester.tap(find.text('AD'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('presentation', () {
    testWidgets('it is a bottom sheet by default', (WidgetTester tester) async {
      await _open(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('center shows a dialog instead', (WidgetTester tester) async {
      await _open(tester, presentation: NepaliCalendarPresentation.center);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      // The same calendar, with the same window.
      expect(find.text('Baishakh 2081'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('the centred dialog returns the same value', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        presentation: NepaliCalendarPresentation.center,
      );

      await _tapDay(tester, _anchor);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(results.single!.date, _anchor);
      expect(results.single!.dateTime, _anchorAd);
    });

    testWidgets('Cancel closes the centred dialog with null', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        presentation: NepaliCalendarPresentation.center,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(results.single, isNull);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('the centred dialog is modal by default too', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        presentation: NepaliCalendarPresentation.center,
      );

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(results, isEmpty);
    });

    testWidgets('range mode works in the centred dialog', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        mode: NepaliCalendarMode.range,
        presentation: NepaliCalendarPresentation.center,
      );

      await _tapDay(tester, const NepaliDate(2081, 1, 10));
      await _tapDay(tester, const NepaliDate(2081, 1, 16));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(results.single!.range!.lengthInDays, 7);
    });
  });

  group('the confirm button', () {
    testWidgets('its disabled colours come from the calendar palette', (
      WidgetTester tester,
    ) async {
      // A dark calendar inside a light app: Material's own disabled colours are
      // derived from the ambient scheme and would disappear against the sheet.
      final NepaliCalendarTheme dark = NepaliCalendarTheme.dark();
      await _open(tester, theme: dark);

      final ButtonStyle style = tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Done'))
          .style!;
      final Color? disabledFill = style.backgroundColor?.resolve(<WidgetState>{
        WidgetState.disabled,
      });
      final Color? disabledLabel = style.foregroundColor?.resolve(<WidgetState>{
        WidgetState.disabled,
      });

      expect(disabledFill, isNotNull);
      expect(disabledLabel, isNotNull);
      expect(disabledFill, isNot(dark.backgroundColor));
      expect(disabledLabel, isNot(dark.backgroundColor));
    });
  });

  group('labels', () {
    testWidgets('custom labels replace the defaults', (
      WidgetTester tester,
    ) async {
      await _open(tester, confirmLabel: 'Apply', cancelLabel: 'Back');
      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('the sheet is just header, grid and buttons', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      await _tapDay(tester, _anchor);

      // Nothing sits between the weekday grid and the buttons.
      expect(find.text('Select a date'), findsNothing);
      expect(find.text('15 Bai 2081'), findsNothing);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('selectableDates', () {
    testWidgets('only listed dates are enabled, everything else disabled', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        selectableDates: const <NepaliDate>[
          NepaliDate(2081, 1, 15),
          NepaliDate(2081, 1, 20),
        ],
      );

      expect(_dayCell(tester, _anchor).day.isDisabled, isFalse);
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 20)).day.isDisabled,
        isFalse,
      );
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 16)).day.isDisabled,
        isTrue,
      );

      await _tapDay(tester, const NepaliDate(2081, 1, 16));
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Done'))
            .onPressed,
        isNull,
        reason: '16 is not in selectableDates, so tapping it selects nothing',
      );
    });

    testWidgets('still intersects with the startDate/endDate window', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        startDate: const NepaliDate(2081, 1, 16),
        endDate: const NepaliDate(2081, 1, 25),
        // 15 is listed but outside the window; 20 is inside both.
        selectableDates: const <NepaliDate>[
          NepaliDate(2081, 1, 15),
          NepaliDate(2081, 1, 20),
        ],
      );

      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 15)).day.isDisabled,
        isTrue,
        reason: 'outside the startDate/endDate window',
      );
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 20)).day.isDisabled,
        isFalse,
      );
    });

    testWidgets('an empty list disables every day', (
      WidgetTester tester,
    ) async {
      await _open(tester, selectableDates: const <NepaliDate>[]);

      expect(_dayCell(tester, _anchor).day.isDisabled, isTrue);
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 20)).day.isDisabled,
        isTrue,
      );
    });

    testWidgets('null (the default) restricts nothing beyond the window', (
      WidgetTester tester,
    ) async {
      await _open(tester);

      expect(_dayCell(tester, _anchor).day.isDisabled, isFalse);
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 25)).day.isDisabled,
        isFalse,
      );
    });
  });

  group('initialSelection', () {
    testWidgets('single mode: preselects the date and opens its month', (
      WidgetTester tester,
    ) async {
      // Baishakh 2081 (startDate's month) is not this date's month.
      const NepaliDate previouslyPicked = NepaliDate(2081, 6, 5);
      await _open(
        tester,
        initialSelection: const NepaliCalendarSelection.single(
          previouslyPicked,
        ),
      );

      expect(find.textContaining('Ashoj 2081'), findsOneWidget);
      expect(_dayCell(tester, previouslyPicked).day.isSelected, isTrue);
      expect(_confirmButton(tester).onPressed, isNotNull);
    });

    testWidgets(
      'range mode: preselects both ends, banded, and opens on start',
      (WidgetTester tester) async {
        const NepaliDateRange previousRange = NepaliDateRange(
          start: NepaliDate(2081, 6, 5),
          end: NepaliDate(2081, 6, 10),
        );
        await _open(
          tester,
          mode: NepaliCalendarMode.range,
          initialSelection: const NepaliCalendarSelection.range(previousRange),
        );

        expect(find.textContaining('Ashoj 2081'), findsOneWidget);
        expect(_dayCell(tester, previousRange.start).day.isRangeStart, isTrue);
        expect(_dayCell(tester, previousRange.end).day.isRangeEnd, isTrue);
        expect(_confirmButton(tester).onPressed, isNotNull);
      },
    );

    testWidgets('re-confirming an unchanged preselection returns it back', (
      WidgetTester tester,
    ) async {
      const NepaliDate previouslyPicked = NepaliDate(2081, 1, 20);
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        initialSelection: const NepaliCalendarSelection.single(
          previouslyPicked,
        ),
      );

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(results.single?.date, previouslyPicked);
    });

    testWidgets('null (the default) is unaffected', (
      WidgetTester tester,
    ) async {
      await _open(tester);
      expect(_confirmButton(tester).onPressed, isNull);
    });
  });

  group('the Clear button', () {
    testWidgets('is hidden by default', (WidgetTester tester) async {
      await _open(tester);
      expect(find.text('Clear'), findsNothing);
    });

    testWidgets(
      'stays hidden on a blank open even when showClearButton is true',
      (WidgetTester tester) async {
        await _open(tester, showClearButton: true);
        expect(
          find.text('Clear'),
          findsNothing,
          reason: 'nothing selected yet, so nothing to clear',
        );
      },
    );

    testWidgets('shows once initialSelection seeds a selection', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        showClearButton: true,
        initialSelection: const NepaliCalendarSelection.single(
          NepaliDate(2081, 1, 20),
        ),
      );
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('stays hidden after tapping a day, without initialSelection', (
      WidgetTester tester,
    ) async {
      await _open(tester, showClearButton: true);
      expect(find.text('Clear'), findsNothing);

      // Picking a day in this session is not "removing a previous value" —
      // Cancel already covers undoing an in-progress pick.
      await _tapDay(tester, const NepaliDate(2081, 1, 20));
      expect(find.text('Clear'), findsNothing);
    });

    testWidgets('resolves to a distinct cleared selection, not null', (
      WidgetTester tester,
    ) async {
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        showClearButton: true,
        initialSelection: const NepaliCalendarSelection.single(
          NepaliDate(2081, 1, 20),
        ),
      );

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      final NepaliCalendarSelection selection = results.single!;
      expect(selection.isCleared, isTrue);
      expect(selection.date, isNull);
      expect(selection.range, isNull);
    });

    testWidgets(
      'overrides a same-session re-pick made on top of the initial value',
      (WidgetTester tester) async {
        final List<NepaliCalendarSelection?> results = await _open(
          tester,
          showClearButton: true,
          initialSelection: const NepaliCalendarSelection.single(
            NepaliDate(2081, 1, 15),
          ),
        );

        // Change the pick, then clear instead of confirming the new pick.
        await _tapDay(tester, const NepaliDate(2081, 1, 20));
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();

        final NepaliCalendarSelection selection = results.single!;
        expect(selection.isCleared, isTrue);
        expect(selection.date, isNull);
      },
    );

    testWidgets('clearLabel overrides the default text', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        showClearButton: true,
        clearLabel: 'Remove date',
        initialSelection: const NepaliCalendarSelection.single(
          NepaliDate(2081, 1, 20),
        ),
      );
      expect(find.text('Clear'), findsNothing);
      expect(find.text('Remove date'), findsOneWidget);
    });

    testWidgets('works in range mode too', (WidgetTester tester) async {
      const NepaliDateRange initialRange = NepaliDateRange(
        start: NepaliDate(2081, 1, 10),
        end: NepaliDate(2081, 1, 16),
      );
      final List<NepaliCalendarSelection?> results = await _open(
        tester,
        mode: NepaliCalendarMode.range,
        showClearButton: true,
        initialSelection: const NepaliCalendarSelection.range(initialRange),
      );

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      final NepaliCalendarSelection selection = results.single!;
      expect(selection.isCleared, isTrue);
      expect(selection.range, isNull);
    });
  });

  group('NepaliCalendarSelection.cleared value semantics', () {
    test('two cleared instances are equal', () {
      expect(
        const NepaliCalendarSelection.cleared(),
        const NepaliCalendarSelection.cleared(),
      );
      expect(
        const NepaliCalendarSelection.cleared().hashCode,
        const NepaliCalendarSelection.cleared().hashCode,
      );
    });

    test('a cleared selection is not equal to a picked one', () {
      expect(
        const NepaliCalendarSelection.cleared(),
        isNot(const NepaliCalendarSelection.single(NepaliDate(2081, 1, 1))),
      );
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
