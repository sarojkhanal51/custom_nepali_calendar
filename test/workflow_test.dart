// End-to-end workflows and adversarial edges.
//
// The other widget tests check pieces; these drive the journeys a real user
// takes — pick a range, flip the calendar system halfway through, back out,
// reopen with what you got last time — plus the inputs a real app eventually
// supplies by accident: empty allow-lists, degenerate windows, holidays on
// nonsense dates, and a host route that disappears mid-sheet.

import 'dart:async';

import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';
import 'package:custom_nepali_calendar/src/view/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const NepaliDate _start = NepaliDate(2081, 1, 1);
const NepaliDate _end = NepaliDate(2081, 12, 30);

Finder _cell(NepaliDate d) =>
    find.byWidgetPredicate((Widget w) => w is DayCell && w.day.bsDate == d);

DayCell _dayCell(WidgetTester t, NepaliDate d) => t.widget<DayCell>(_cell(d));

FilledButton _done(WidgetTester t) =>
    t.widget<FilledButton>(find.widgetWithText(FilledButton, 'Done'));

IconButton _arrow(WidgetTester t, {required bool next}) => t.widget<IconButton>(
  find.widgetWithIcon(
    IconButton,
    next ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
  ),
);

Future<List<NepaliCalendarSelection?>> _open(
  WidgetTester tester, {
  NepaliCalendarMode mode = NepaliCalendarMode.single,
  NepaliDate startDate = _start,
  NepaliDate? endDate = _end,
  int? durationDays,
  List<NepaliDate>? selectableDates,
  List<NepaliHoliday> holidays = const <NepaliHoliday>[],
  NepaliCalendarSelection? initialSelection,
  bool showClearButton = false,
  bool isDismissible = false,
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
                holidays: holidays,
                initialSelection: initialSelection,
                showClearButton: showClearButton,
                isDismissible: isDismissible,
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
  group('range selection', () {
    testWidgets('start then end confirms that range', (WidgetTester t) async {
      final List<NepaliCalendarSelection?> out = await _open(
        t,
        mode: NepaliCalendarMode.range,
      );
      await t.tap(_cell(const NepaliDate(2081, 1, 5)));
      await t.pumpAndSettle();
      expect(
        _done(t).onPressed,
        isNull,
        reason: 'half a range was confirmable',
      );
      await t.tap(_cell(const NepaliDate(2081, 1, 10)));
      await t.pumpAndSettle();
      await t.tap(find.text('Done'));
      await t.pumpAndSettle();
      expect(
        out.single?.range,
        const NepaliDateRange(
          start: NepaliDate(2081, 1, 5),
          end: NepaliDate(2081, 1, 10),
        ),
      );
    });

    testWidgets('the same day twice is a one-day range', (
      WidgetTester t,
    ) async {
      const NepaliDate d = NepaliDate(2081, 1, 5);
      final List<NepaliCalendarSelection?> out = await _open(
        t,
        mode: NepaliCalendarMode.range,
      );
      await t.tap(_cell(d));
      await t.pumpAndSettle();
      await t.tap(_cell(d));
      await t.pumpAndSettle();
      await t.tap(find.text('Done'));
      await t.pumpAndSettle();
      expect(out.single?.range?.lengthInDays, 1);
      expect(out.single?.range?.isSingleDay, isTrue);
    });

    testWidgets('a tap before the pending start re-anchors it', (
      WidgetTester t,
    ) async {
      final List<NepaliCalendarSelection?> out = await _open(
        t,
        mode: NepaliCalendarMode.range,
      );
      await t.tap(_cell(const NepaliDate(2081, 1, 20)));
      await t.pumpAndSettle();
      await t.tap(_cell(const NepaliDate(2081, 1, 10)));
      await t.pumpAndSettle();
      expect(_done(t).onPressed, isNull, reason: 'range completed backwards');
      await t.tap(_cell(const NepaliDate(2081, 1, 25)));
      await t.pumpAndSettle();
      await t.tap(find.text('Done'));
      await t.pumpAndSettle();
      expect(out.single?.range?.start, const NepaliDate(2081, 1, 10));
      expect(out.single?.range?.end, const NepaliDate(2081, 1, 25));
    });

    testWidgets('a third tap starts a fresh range', (WidgetTester t) async {
      await _open(t, mode: NepaliCalendarMode.range);
      await t.tap(_cell(const NepaliDate(2081, 1, 5)));
      await t.pumpAndSettle();
      await t.tap(_cell(const NepaliDate(2081, 1, 10)));
      await t.pumpAndSettle();
      await t.tap(_cell(const NepaliDate(2081, 1, 15)));
      await t.pumpAndSettle();
      expect(_done(t).onPressed, isNull);
    });
  });

  group('switching calendar system mid-selection', () {
    testWidgets('a single selection survives a round trip through AD', (
      WidgetTester t,
    ) async {
      const NepaliDate picked = NepaliDate(2081, 1, 15);
      final List<NepaliCalendarSelection?> out = await _open(t);
      await t.tap(_cell(picked));
      await t.pumpAndSettle();
      await t.tap(find.text('AD'));
      await t.pumpAndSettle();
      expect(_dayCell(t, picked).day.isSelected, isTrue);
      await t.tap(find.text('BS'));
      await t.pumpAndSettle();
      expect(_dayCell(t, picked).day.isSelected, isTrue);
      await t.tap(find.text('Done'));
      await t.pumpAndSettle();
      expect(out.single?.date, picked);
    });

    testWidgets('a pending range start survives, and completes from AD', (
      WidgetTester t,
    ) async {
      await _open(t, mode: NepaliCalendarMode.range);
      await t.tap(_cell(const NepaliDate(2081, 1, 5)));
      await t.pumpAndSettle();
      await t.tap(find.text('AD'));
      await t.pumpAndSettle();
      expect(_dayCell(t, const NepaliDate(2081, 1, 5)).day.isSelected, isTrue);
      await t.tap(_cell(const NepaliDate(2081, 1, 12)));
      await t.pumpAndSettle();
      expect(_done(t).onPressed, isNotNull);
    });

    testWidgets('the window still applies after switching', (
      WidgetTester t,
    ) async {
      await _open(
        t,
        startDate: const NepaliDate(2081, 1, 10),
        endDate: const NepaliDate(2081, 1, 20),
      );
      await t.tap(find.text('AD'));
      await t.pumpAndSettle();
      expect(_dayCell(t, const NepaliDate(2081, 1, 5)).day.isDisabled, isTrue);
    });
  });

  group('leaving the sheet', () {
    testWidgets('Cancel resolves to null even after picking', (
      WidgetTester t,
    ) async {
      final List<NepaliCalendarSelection?> out = await _open(t);
      await t.tap(_cell(const NepaliDate(2081, 1, 15)));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(out.single, isNull);
    });

    testWidgets('double-tapping Done resolves once and spares the host route', (
      WidgetTester t,
    ) async {
      final List<NepaliCalendarSelection?> out = await _open(t);
      await t.tap(_cell(const NepaliDate(2081, 1, 15)));
      await t.pumpAndSettle();
      await t.tap(find.text('Done'), warnIfMissed: false);
      await t.tap(find.text('Done'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(out, hasLength(1));
      expect(
        find.text('open'),
        findsOneWidget,
        reason: 'the host route was popped along with the sheet',
      );
    });

    testWidgets('double-tapping Cancel spares the host route', (
      WidgetTester t,
    ) async {
      final List<NepaliCalendarSelection?> out = await _open(t);
      await t.tap(find.text('Cancel'), warnIfMissed: false);
      await t.tap(find.text('Cancel'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(out, hasLength(1));
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('a barrier tap is ignored when not dismissible', (
      WidgetTester t,
    ) async {
      final List<NepaliCalendarSelection?> out = await _open(t);
      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();
      expect(find.text('Done'), findsOneWidget);
      expect(out, isEmpty);
    });
  });

  group('degenerate windows', () {
    testWidgets('a one-day window', (WidgetTester t) async {
      const NepaliDate only = NepaliDate(2081, 5, 15);
      final List<NepaliCalendarSelection?> out = await _open(
        t,
        startDate: only,
        endDate: only,
      );
      await t.tap(_cell(only));
      await t.pumpAndSettle();
      await t.tap(find.text('Done'));
      await t.pumpAndSettle();
      expect(out.single?.date, only);
    });

    testWidgets('an empty selectableDates list disables every day', (
      WidgetTester t,
    ) async {
      await _open(t, selectableDates: const <NepaliDate>[]);
      final Iterable<DayCell> cells = t.widgetList<DayCell>(
        find.byType(DayCell),
      );
      expect(cells, isNotEmpty);
      expect(cells.every((DayCell c) => c.day.isDisabled), isTrue);
      expect(_done(t).onPressed, isNull);
    });

    testWidgets(
      'an allow-list entirely outside the window leaves nothing open',
      (WidgetTester t) async {
        await _open(
          t,
          startDate: const NepaliDate(2081, 1, 1),
          endDate: const NepaliDate(2081, 1, 30),
          selectableDates: <NepaliDate>[const NepaliDate(2082, 5, 5)],
        );
        expect(_done(t).onPressed, isNull);
      },
    );

    testWidgets('duplicate allow-list entries are harmless', (
      WidgetTester t,
    ) async {
      const NepaliDate d = NepaliDate(2081, 1, 9);
      await _open(t, selectableDates: <NepaliDate>[d, d, d]);
      expect(_dayCell(t, d).day.isDisabled, isFalse);
    });

    testWidgets('at the bottom of the supported range the back arrow is dead', (
      WidgetTester t,
    ) async {
      await _open(
        t,
        startDate: NepaliDate.min,
        endDate: null,
        durationDays: 40,
      );
      expect(t.takeException(), isNull);
      expect(_arrow(t, next: false).onPressed, isNull);
    });

    testWidgets('at the top of the supported range the forward arrow is dead', (
      WidgetTester t,
    ) async {
      await _open(
        t,
        startDate: NepaliDate.max.subtractDays(10),
        endDate: NepaliDate.max,
      );
      expect(t.takeException(), isNull);
      expect(_arrow(t, next: true).onPressed, isNull);
      await t.tap(_cell(NepaliDate.max));
      await t.pumpAndSettle();
      expect(_done(t).onPressed, isNotNull);
    });

    testWidgets('a day before startDate is inert', (WidgetTester t) async {
      await _open(t, startDate: const NepaliDate(2081, 1, 10));
      await t.tap(_cell(const NepaliDate(2081, 1, 5)), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(_done(t).onPressed, isNull);
    });

    testWidgets('leading days borrowed from the previous month are inert', (
      WidgetTester t,
    ) async {
      await _open(t, startDate: _start);
      const NepaliDate leading = NepaliDate(2080, 12, 30);
      expect(_dayCell(t, leading).day.isDisabled, isTrue);
      expect(_dayCell(t, leading).day.isCurrentMonth, isFalse);
    });
  });

  group('holidays', () {
    testWidgets('the later entry wins a contested day', (WidgetTester t) async {
      const NepaliDate d = NepaliDate(2081, 1, 15);
      await _open(
        t,
        holidays: const <NepaliHoliday>[
          NepaliHoliday(
            type: 'A',
            dates: <NepaliDate>[d],
            color: Color(0xFF111111),
          ),
          NepaliHoliday(
            type: 'B',
            dates: <NepaliDate>[d],
            color: Color(0xFF222222),
          ),
        ],
      );
      expect(_dayCell(t, d).day.holidayColor, const Color(0xFF222222));
    });

    testWidgets('a holiday cannot make a disabled day pickable', (
      WidgetTester t,
    ) async {
      const NepaliDate outside = NepaliDate(2081, 1, 2);
      await _open(
        t,
        startDate: const NepaliDate(2081, 1, 10),
        holidays: const <NepaliHoliday>[
          NepaliHoliday(
            type: 'Public',
            dates: <NepaliDate>[outside],
            color: Color(0xFFC1272D),
          ),
        ],
      );
      expect(_dayCell(t, outside).day.isDisabled, isTrue);
    });

    testWidgets('invalid and empty holiday dates do not crash', (
      WidgetTester t,
    ) async {
      await _open(
        t,
        holidays: const <NepaliHoliday>[
          NepaliHoliday(
            type: 'Bogus',
            dates: <NepaliDate>[
              NepaliDate(2081, 13, 40),
              NepaliDate(9999, 1, 1),
            ],
            color: Color(0xFFC1272D),
          ),
          NepaliHoliday(
            type: 'Empty',
            dates: <NepaliDate>[],
            color: Color(0xFF000000),
          ),
        ],
      );
      expect(t.takeException(), isNull);
    });
  });

  group('Clear', () {
    testWidgets('resolves to isCleared with no date', (WidgetTester t) async {
      final List<NepaliCalendarSelection?> out = await _open(
        t,
        initialSelection: const NepaliCalendarSelection.single(
          NepaliDate(2081, 1, 15),
        ),
        showClearButton: true,
      );
      await t.tap(find.text('Clear'));
      await t.pumpAndSettle();
      expect(out.single?.isCleared, isTrue);
      expect(out.single?.date, isNull);
      expect(out.single?.range, isNull);
    });

    testWidgets('is hidden without an initialSelection, even after a pick', (
      WidgetTester t,
    ) async {
      await _open(t, showClearButton: true);
      expect(find.text('Clear'), findsNothing);
      await t.tap(_cell(const NepaliDate(2081, 1, 15)));
      await t.pumpAndSettle();
      expect(find.text('Clear'), findsNothing);
    });
  });

  group('lifecycle', () {
    testWidgets('the host stack can be replaced under an open sheet', (
      WidgetTester t,
    ) async {
      final GlobalKey<NavigatorState> nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext c) => ElevatedButton(
                onPressed: () => showNepaliCalendar(
                  context: c,
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
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      // Deliberately not awaited: the point is to yank the stack out from
      // under the open sheet and then pump, not to wait for the push.
      unawaited(
        nav.currentState!.pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('replaced')),
          ),
          (Route<dynamic> r) => false,
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text('replaced'), findsOneWidget);
    });

    testWidgets('rapid paging in both directions mid-animation', (
      WidgetTester t,
    ) async {
      await _open(t);
      for (int i = 0; i < 6; i++) {
        await t.tap(find.byIcon(Icons.chevron_right_rounded));
        await t.pump(const Duration(milliseconds: 20));
      }
      for (int i = 0; i < 6; i++) {
        await t.tap(find.byIcon(Icons.chevron_left_rounded));
        await t.pump(const Duration(milliseconds: 20));
      }
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('spamming the BS/AD switch', (WidgetTester t) async {
      await _open(t);
      for (int i = 0; i < 8; i++) {
        await t.tap(find.text(i.isEven ? 'AD' : 'BS'));
        await t.pump(const Duration(milliseconds: 10));
      }
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('switching system while a page animation is in flight', (
      WidgetTester t,
    ) async {
      await _open(t);
      await t.tap(find.byIcon(Icons.chevron_right_rounded));
      await t.pump(const Duration(milliseconds: 60));
      await t.tap(find.text('AD'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  });

  group('the strip and the sheet together', () {
    testWidgets(
      'a pick in the sheet re-anchors the strip and reaches the caller',
      (WidgetTester t) async {
        final List<NepaliDate> reported = <NepaliDate>[];
        NepaliDate? held;
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (BuildContext c, StateSetter setState) =>
                    HorizontalDateStrip(
                      theme: const NepaliCalendarTheme(),
                      startDate: _start,
                      endDate: _end,
                      selectedDate: held,
                      onDateSelected: (NepaliDate d) {
                        reported.add(d);
                        setState(() => held = d);
                      },
                    ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(reported, <NepaliDate>[_start]);

        await t.tap(find.byIcon(Icons.calendar_month_outlined));
        await t.pumpAndSettle();
        expect(
          _dayCell(t, held!).day.isSelected,
          isTrue,
          reason: 'the sheet did not open on the strip\'s current value',
        );

        await t.tap(find.byIcon(Icons.chevron_right_rounded));
        await t.pumpAndSettle();
        await t.tap(_cell(const NepaliDate(2081, 2, 14)));
        await t.pumpAndSettle();
        await t.tap(find.text('Done'));
        await t.pumpAndSettle();

        expect(held, const NepaliDate(2081, 2, 14));
        expect(
          find.text('14'),
          findsWidgets,
          reason: 'the strip did not re-anchor',
        );
      },
    );

    testWidgets('the strip reports once and does not re-fire on rebuild', (
      WidgetTester t,
    ) async {
      final List<NepaliDate> got = <NepaliDate>[];
      late StateSetter setOuter;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext c, StateSetter s) {
                setOuter = s;
                return HorizontalDateStrip(
                  theme: const NepaliCalendarTheme(),
                  startDate: const NepaliDate(2081, 1, 15),
                  onDateSelected: got.add,
                );
              },
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(got, hasLength(1));
      setOuter(() {});
      await t.pumpAndSettle();
      setOuter(() {});
      await t.pumpAndSettle();
      expect(got, hasLength(1), reason: 'the default selection re-fired');
    });
  });

  group('layout and accessibility stress', () {
    testWidgets('the sheet survives 2x text scale at 320px in Nepali', (
      WidgetTester t,
    ) async {
      t.view.physicalSize = const Size(320 * 3, 640 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: Builder(
                builder: (BuildContext c) => ElevatedButton(
                  onPressed: () => showNepaliCalendar(
                    context: c,
                    theme: const NepaliCalendarTheme(),
                    startDate: _start,
                    endDate: _end,
                    language: Language.nepali,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('a dense 40-day strip on a narrow phone does not overflow', (
      WidgetTester t,
    ) async {
      t.view.physicalSize = const Size(320 * 3, 640 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorizontalDateStrip(
              theme: const NepaliCalendarTheme(),
              startDate: _start,
              dayCount: 40,
              height: 30,
              onDateSelected: (_) {},
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('a day cell announces its full date and enabled state', (
      WidgetTester t,
    ) async {
      final SemanticsHandle handle = t.ensureSemantics();
      await _open(t);
      expect(
        t.getSemantics(_cell(const NepaliDate(2081, 1, 15))).label,
        'Saturday, Baishakh 15, 2081 BS',
      );
      handle.dispose();
    });
  });
}
