import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';
import 'package:custom_nepali_calendar/src/data/selectable_date_lookup.dart';
import 'package:custom_nepali_calendar/src/view/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 15 Baishakh 2081 BS = 27 April 2024 AD — the pair every cross-calendar
/// assertion below leans on.
const NepaliDate _anchor = NepaliDate(2081, 1, 15);
final DateTime _anchorAd = DateTime(2024, 4, 27);
const NepaliDate _yearStart = NepaliDate(2081, 1, 1);
const NepaliDate _yearEnd = NepaliDate(2081, 12, 31);

const Color _green = Color(0xFF2F9E44);
const Color _red = Color(0xFFC1272D);
const NepaliCalendarTheme _theme = NepaliCalendarTheme();

Finder _cellFor(NepaliDate date) => find.byWidgetPredicate(
  (Widget widget) => widget is DayCell && widget.day.bsDate == date,
);

DayCell _dayCell(WidgetTester tester, NepaliDate date) =>
    tester.widget<DayCell>(_cellFor(date));

/// The decoration actually painted behind [date]'s number.
BoxDecoration _cellDecoration(WidgetTester tester, NepaliDate date) =>
    tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: _cellFor(date),
                matching: find.byType(DecoratedBox),
              ),
            )
            .first
            .decoration
        as BoxDecoration;

/// Opens the sheet with [groups] and returns whatever it resolves to.
Future<List<NepaliCalendarSelection?>> _open(
  WidgetTester tester, {
  List<SelectableDates>? groups,
  CalendarSystem initialSystem = CalendarSystem.bs,
  NepaliDate startDate = _yearStart,
  NepaliDate? endDate = _yearEnd,
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
                theme: _theme,
                initialSystem: initialSystem,
                startDate: startDate,
                endDate: endDate,
                selectableDates: groups,
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

/// Pumps a strip carrying [groups].
Future<List<NepaliDate>> _pumpStrip(
  WidgetTester tester, {
  List<SelectableDates>? groups,
  NepaliDate? selectedDate,
  NepaliDate startDate = _anchor,
}) async {
  final List<NepaliDate> picked = <NepaliDate>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return HorizontalDateStrip(
              theme: _theme,
              selectedDate: selectedDate,
              startDate: startDate,
              selectableDates: groups,
              showCalendarButton: false,
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

/// The chip [Material] whose surface is [color], if any.
Iterable<Material> _chipsPainted(WidgetTester tester, Color color) => tester
    .widgetList<Material>(find.byType(Material))
    .where((Material m) => m.color == color);

void main() {
  group('SelectableDates', () {
    test('takes Bikram Sambat days as given', () {
      const SelectableDates group = SelectableDates(
        dates: <NepaliDate>[_anchor],
        color: _green,
      );
      expect(group.dates, <NepaliDate>[_anchor]);
      expect(group.color, _green);
    });

    test('fromDateTimes converts Gregorian days to the same BS days', () {
      final SelectableDates group = SelectableDates.fromDateTimes(
        dates: <DateTime>[_anchorAd, DateTime(2024, 4, 28)],
        color: _red,
      );
      expect(group.dates, <NepaliDate>[_anchor, const NepaliDate(2081, 1, 16)]);
      expect(group.color, _red);
    });

    test('fromDateTimes discards the time component', () {
      final SelectableDates group = SelectableDates.fromDateTimes(
        dates: <DateTime>[DateTime(2024, 4, 27, 23, 59, 59)],
      );
      expect(group.dates, <NepaliDate>[_anchor]);
      expect(group.color, isNull);
    });

    test('fromDateTimes rejects a day outside the supported range', () {
      expect(
        () => SelectableDates.fromDateTimes(dates: <DateTime>[DateTime(1800)]),
        throwsA(isA<DateConversionException>()),
      );
    });

    test('color is optional, so a group can restrict without marking', () {
      const SelectableDates group = SelectableDates(
        dates: <NepaliDate>[_anchor],
      );
      expect(group.color, isNull);
    });

    test('value equality covers both dates and color', () {
      const SelectableDates a = SelectableDates(
        dates: <NepaliDate>[_anchor],
        color: _green,
      );
      const SelectableDates b = SelectableDates(
        dates: <NepaliDate>[_anchor],
        color: _green,
      );
      const SelectableDates differentColor = SelectableDates(
        dates: <NepaliDate>[_anchor],
        color: _red,
      );
      const SelectableDates differentDates = SelectableDates(
        dates: <NepaliDate>[NepaliDate(2081, 1, 16)],
        color: _green,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(differentColor));
      expect(a, isNot(differentDates));
    });

    test('toString names the size and the color', () {
      expect(
        const SelectableDates(
          dates: <NepaliDate>[_anchor],
          color: _green,
        ).toString(),
        contains('1 date(s)'),
      );
      expect(
        const SelectableDates(dates: <NepaliDate>[_anchor]).toString(),
        'SelectableDates(1 date(s))',
      );
    });
  });

  group('resolveSelectableDates', () {
    test('null means no restriction and nothing marked', () {
      final SelectableDateLookup lookup = resolveSelectableDates(null);
      expect(lookup.allowed, isNull);
      expect(lookup.colors, isEmpty);
    });

    test('an empty list disables every day rather than allowing all', () {
      final SelectableDateLookup lookup = resolveSelectableDates(
        const <SelectableDates>[],
      );
      expect(lookup.allowed, isEmpty);
      expect(lookup.allowed, isNotNull);
    });

    test('groups union into one allow-list, each keeping its color', () {
      final SelectableDateLookup lookup = resolveSelectableDates(
        const <SelectableDates>[
          SelectableDates(dates: <NepaliDate>[_anchor], color: _green),
          SelectableDates(
            dates: <NepaliDate>[NepaliDate(2081, 1, 16)],
            color: _red,
          ),
        ],
      );
      expect(lookup.allowed, <NepaliDate>{
        _anchor,
        const NepaliDate(2081, 1, 16),
      });
      expect(lookup.colors[_anchor], _green);
      expect(lookup.colors[const NepaliDate(2081, 1, 16)], _red);
    });

    test('a day in two colored groups takes the later color', () {
      final SelectableDateLookup lookup = resolveSelectableDates(
        const <SelectableDates>[
          SelectableDates(dates: <NepaliDate>[_anchor], color: _green),
          SelectableDates(dates: <NepaliDate>[_anchor], color: _red),
        ],
      );
      expect(lookup.colors[_anchor], _red);
    });

    test('a later uncolored group unmarks a day an earlier one colored', () {
      final SelectableDateLookup lookup = resolveSelectableDates(
        const <SelectableDates>[
          SelectableDates(dates: <NepaliDate>[_anchor], color: _green),
          SelectableDates(dates: <NepaliDate>[_anchor]),
        ],
      );
      expect(lookup.allowed, contains(_anchor));
      expect(lookup.colors, isEmpty);
    });

    test('an uncolored group restricts without marking', () {
      final SelectableDateLookup lookup = resolveSelectableDates(
        const <SelectableDates>[
          SelectableDates(dates: <NepaliDate>[_anchor]),
        ],
      );
      expect(lookup.allowed, <NepaliDate>{_anchor});
      expect(lookup.colors, isEmpty);
    });
  });

  group('the sheet marks a colored day', () {
    testWidgets('with a bright border and a light fill of that color', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        groups: const <SelectableDates>[
          SelectableDates(dates: <NepaliDate>[_anchor], color: _green),
        ],
      );

      expect(_dayCell(tester, _anchor).day.highlightColor, _green);
      final BoxDecoration decoration = _cellDecoration(tester, _anchor);
      expect(decoration.border, isA<Border>());
      expect((decoration.border! as Border).top.color, _green);
      expect(decoration.color, _green.withValues(alpha: 0.14));
      expect(
        decoration.color,
        isNot(_green),
        reason: 'the fill is a wash, not the full color',
      );
    });

    testWidgets('and paints its number in the same color', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        groups: const <SelectableDates>[
          SelectableDates(dates: <NepaliDate>[_anchor], color: _green),
        ],
      );

      final Text number = tester.widget<Text>(
        find.descendant(of: _cellFor(_anchor), matching: find.text('15')),
      );
      expect(number.style?.color, _green);
    });

    testWidgets('leaving an uncolored group unmarked', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        groups: const <SelectableDates>[
          SelectableDates(dates: <NepaliDate>[_anchor]),
        ],
      );

      expect(_dayCell(tester, _anchor).day.highlightColor, isNull);
      expect(_cellDecoration(tester, _anchor).border, isNull);
      expect(_cellDecoration(tester, _anchor).color, isNull);
    });

    testWidgets('and marking nothing the window already ruled out', (
      WidgetTester tester,
    ) async {
      // The group offers a day the window closes before.
      await _open(
        tester,
        startDate: _yearStart,
        endDate: const NepaliDate(2081, 1, 10),
        groups: const <SelectableDates>[
          SelectableDates(dates: <NepaliDate>[_anchor], color: _green),
        ],
      );

      final DayCell cell = _dayCell(tester, _anchor);
      expect(cell.day.isDisabled, isTrue);
      expect(
        cell.day.highlightColor,
        isNull,
        reason: 'a day that cannot be picked is not on offer to mark',
      );
      expect(_cellDecoration(tester, _anchor).border, isNull);
    });

    testWidgets('one group per color, each marking its own days', (
      WidgetTester tester,
    ) async {
      const NepaliDate second = NepaliDate(2081, 1, 16);
      await _open(
        tester,
        groups: const <SelectableDates>[
          SelectableDates(dates: <NepaliDate>[_anchor], color: _green),
          SelectableDates(dates: <NepaliDate>[second], color: _red),
        ],
      );

      expect(_dayCell(tester, _anchor).day.highlightColor, _green);
      expect(_dayCell(tester, second).day.highlightColor, _red);
      expect(
        (_cellDecoration(tester, _anchor).border! as Border).top.color,
        _green,
      );
      expect(
        (_cellDecoration(tester, second).border! as Border).top.color,
        _red,
      );
    });
  });

  group('selection outranks the mark', () {
    testWidgets('a marked day picked shows the theme selected color', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        groups: const <SelectableDates>[
          SelectableDates(dates: <NepaliDate>[_anchor], color: _green),
        ],
      );

      await tester.tap(_cellFor(_anchor));
      await tester.pumpAndSettle();

      final BoxDecoration decoration = _cellDecoration(tester, _anchor);
      expect(decoration.color, _theme.selectedDayColor);
      expect(
        decoration.border,
        isNull,
        reason: 'the selected fill replaces the mark rather than stacking',
      );
      final Text number = tester.widget<Text>(
        find.descendant(of: _cellFor(_anchor), matching: find.text('15')),
      );
      expect(number.style?.color, _theme.selectedDayTextColor);
    });

    testWidgets('and the mark comes back when the pick moves away', (
      WidgetTester tester,
    ) async {
      const NepaliDate second = NepaliDate(2081, 1, 16);
      await _open(
        tester,
        groups: const <SelectableDates>[
          SelectableDates(dates: <NepaliDate>[_anchor, second], color: _green),
        ],
      );

      await tester.tap(_cellFor(_anchor));
      await tester.pumpAndSettle();
      await tester.tap(_cellFor(second));
      await tester.pumpAndSettle();

      expect(_cellDecoration(tester, second).color, _theme.selectedDayColor);
      expect(
        (_cellDecoration(tester, _anchor).border! as Border).top.color,
        _green,
        reason: 'the day it left is marked again, not left blank',
      );
    });
  });

  group('both calendars', () {
    testWidgets('a BS group marks the same day while the sheet shows AD', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        initialSystem: CalendarSystem.ad,
        groups: const <SelectableDates>[
          SelectableDates(dates: <NepaliDate>[_anchor], color: _green),
        ],
      );

      final DayCell cell = _dayCell(tester, _anchor);
      expect(cell.day.adDate, _anchorAd);
      expect(cell.day.highlightColor, _green);
      expect(
        (_cellDecoration(tester, _anchor).border! as Border).top.color,
        _green,
      );
    });

    testWidgets('a Gregorian group marks the matching BS day', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        groups: <SelectableDates>[
          SelectableDates.fromDateTimes(
            dates: <DateTime>[_anchorAd],
            color: _red,
          ),
        ],
      );

      expect(_dayCell(tester, _anchor).day.highlightColor, _red);
      expect(
        _dayCell(tester, const NepaliDate(2081, 1, 16)).day.isDisabled,
        isTrue,
        reason: 'a Gregorian group restricts exactly like a BS one',
      );
    });

    testWidgets('the mark survives a live BS/AD switch', (
      WidgetTester tester,
    ) async {
      await _open(
        tester,
        groups: const <SelectableDates>[
          SelectableDates(dates: <NepaliDate>[_anchor], color: _green),
        ],
      );
      expect(_dayCell(tester, _anchor).day.highlightColor, _green);

      await tester.tap(find.text('AD'));
      await tester.pumpAndSettle();

      expect(
        _dayCell(tester, _anchor).day.highlightColor,
        _green,
        reason: 'the mark follows the day, not the calendar it is shown in',
      );
    });
  });

  group('the strip', () {
    testWidgets('marks a colored day with a border and a light fill', (
      WidgetTester tester,
    ) async {
      await _pumpStrip(
        tester,
        selectedDate: const NepaliDate(2081, 1, 16),
        groups: const <SelectableDates>[
          SelectableDates(
            dates: <NepaliDate>[_anchor, NepaliDate(2081, 1, 16)],
            color: _green,
          ),
        ],
      );

      final Iterable<Material> marked = _chipsPainted(
        tester,
        _green.withValues(alpha: 0.14),
      );
      expect(marked, hasLength(1), reason: 'only the unselected marked day');
      final RoundedRectangleBorder shape =
          marked.first.shape! as RoundedRectangleBorder;
      expect(shape.side.color, _green);
      expect(shape.side.width, 1.5);
    });

    testWidgets('paints a selected day in the theme color instead', (
      WidgetTester tester,
    ) async {
      await _pumpStrip(
        tester,
        selectedDate: _anchor,
        groups: const <SelectableDates>[
          SelectableDates(dates: <NepaliDate>[_anchor], color: _green),
        ],
      );

      expect(_chipsPainted(tester, _theme.selectedDayColor), hasLength(1));
      expect(_chipsPainted(tester, _green.withValues(alpha: 0.14)), isEmpty);
    });

    testWidgets('never marks a day that is not on the strip', (
      WidgetTester tester,
    ) async {
      await _pumpStrip(
        tester,
        selectedDate: _anchor,
        groups: <SelectableDates>[
          SelectableDates.fromDateTimes(
            dates: <DateTime>[_anchorAd.add(const Duration(days: 90))],
            color: _red,
          ),
        ],
      );

      expect(_chipsPainted(tester, _red.withValues(alpha: 0.14)), isEmpty);
    });
  });
}
