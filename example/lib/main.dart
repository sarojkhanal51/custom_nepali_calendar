// Demo of the custom_nepali_calendar package.
//
// Two ways in: showNepaliCalendar opens the picker in a bottom sheet, and
// HorizontalDateStrip puts a row of days straight on the screen. Both take the
// same theme and the same startDate / durationDays window.

import 'package:flutter/material.dart';
import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';

import 'fiscal_year.dart';

void main() => runApp(const ExampleApp());

/// Root of the demo app.
class ExampleApp extends StatelessWidget {
  /// Creates the demo app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'custom_nepali_calendar demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B7285)),
      ),
      home: const DemoScreen(),
    );
  }
}

/// The one and only demo screen.
class DemoScreen extends StatefulWidget {
  /// Creates the demo screen.
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  /// The colours this app wants the calendar to use.
  static const NepaliCalendarTheme _theme = NepaliCalendarTheme(
    primaryColor: Color(0xFF0B7285),
    selectedDayColor: Color(0xFFE8590C),
    todayHighlightColor: Color(0xFF0B7285),
    weekendColor: Color(0xFFE03131),
  );

  String _result = 'Nothing picked yet';
  String _fiscalResult = 'Nothing picked yet';
  Language _language = Language.english;
  NepaliDate? _stripDate;

  /// What _pickDate last resolved to — fed back in as initialSelection so
  /// reopening the sheet shows the same value already selected.
  NepaliCalendarSelection? _lastSingleSelection;

  /// Same idea as [_lastSingleSelection], for _pickRange.
  NepaliCalendarSelection? _lastRangeSelection;

  /// Pre-resolved rather than left null, so the strip doesn't fire its own
  /// default-selection report on first build — this demo section already
  /// knows what the sensible default is (NepaliFiscalYear.stripAnchor).
  late NepaliDate _fiscalStripDate = NepaliFiscalYear.current().stripAnchor();

  /// A couple of sample holidays, placed relative to today so they always
  /// land inside the 90-day window the demo offers.
  late final List<NepaliHoliday> _holidays = <NepaliHoliday>[
    NepaliHoliday(
      type: 'Public',
      dates: <NepaliDate>[NepaliDate.now().addDays(5)],
      color: const Color(0xFFC1272D),
    ),
    NepaliHoliday(
      type: 'Optional',
      dates: <NepaliDate>[NepaliDate.now().addDays(20)],
      color: const Color(0xFF2F9E44),
    ),
  ];

  Future<void> _pickDate() async {
    final NepaliCalendarSelection? selection = await showNepaliCalendar(
      context: context,
      theme: _theme,
      language: _language,
      // Today, and the ninety days after it.
      startDate: NepaliDate.now(),
      durationDays: 90,
      holidays: _holidays,
      // An optional field, so offer a way to explicitly remove a pick —
      // distinct from Cancel, which resolves to plain null and means
      // "leave whatever I already had."
      showClearButton: true,
      // Reopening shows whatever this field currently holds already
      // selected, instead of starting blank every time.
      initialSelection: _lastSingleSelection,
    );

    // Cancel means "leave whatever I already had" — _lastSingleSelection (and
    // the field it represents) stays untouched.
    if (selection == null) {
      setState(() => _result = 'Single: cancelled');
      return;
    }

    setState(() {
      _lastSingleSelection = selection;
      if (selection.isCleared) {
        _result = 'Single: cleared';
        return;
      }
      final NepaliDate date = selection.date!;
      _result =
          'Single\n'
          'BS: ${date.format('EEEE, d MMMM yyyy')}\n'
          'AD: ${selection.dateTime!.toIso8601String().split('T').first}';
    });
  }

  Future<void> _pickRange() async {
    final NepaliCalendarSelection? selection = await showNepaliCalendar(
      context: context,
      mode: NepaliCalendarMode.range,
      theme: _theme,
      language: _language,
      // The window the calendar offers: today plus the next 89 days.
      startDate: NepaliDate.now(),
      durationDays: 90,
      holidays: _holidays,
      // Same Clear + preselect pattern as _pickDate, for a range.
      showClearButton: true,
      initialSelection: _lastRangeSelection,
    );

    // Cancel means "leave whatever I already had" — _lastRangeSelection (and
    // the field it represents) stays untouched.
    if (selection == null) {
      setState(() => _result = 'Range: cancelled');
      return;
    }

    setState(() {
      _lastRangeSelection = selection;
      if (selection.isCleared) {
        _result = 'Range: cleared';
        return;
      }
      final NepaliDateRange range = selection.range!;
      _result =
          'Range (${range.lengthInDays} days)\n'
          'BS: ${range.start} → ${range.end}\n'
          'AD: ${range.toDateTimeRange().start.toIso8601String().split('T').first}'
          ' → '
          '${range.toDateTimeRange().end.toIso8601String().split('T').first}';
    });
  }

  /// Picks a date within [fy]: capped at today while it's still running,
  /// the full fiscal year once it has elapsed. See fiscal_year.dart.
  Future<void> _pickInFiscalYear(NepaliFiscalYear fy) async {
    final NepaliCalendarSelection? selection = await showNepaliCalendar(
      context: context,
      theme: _theme,
      language: _language,
      startDate: fy.start,
      endDate: fy.window().end,
    );

    setState(() {
      if (selection?.date == null) {
        _fiscalResult = 'FY $fy: cancelled';
        return;
      }
      final NepaliDate date = selection!.date!;
      _fiscalResult =
          'FY $fy (${fy.isCurrent ? 'current' : 'past'})\n'
          'Picked: ${date.format('EEEE, d MMMM yyyy')}\n'
          'Window: ${fy.start} → ${fy.window().end}';
    });
  }

  @override
  Widget build(BuildContext context) {
    // In a real app these two strings are exactly what your backend sends —
    // the fiscal year's start/end as BS "yyyy-MM-dd" strings. Simulated here
    // by formatting the locally-known current fiscal year the same way a
    // server would, then parsing it right back — the parsing step and the
    // today-locking behavior below are identical to the real flow.
    final NepaliFiscalYear localCurrent = NepaliFiscalYear.current();
    final NepaliFiscalYear currentFy = NepaliFiscalYear.parse(
      start: localCurrent.start.toString(),
      end: localCurrent.end.toString(),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('custom_nepali_calendar')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: const Text('Pick a date'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _pickRange,
                  icon: const Icon(Icons.date_range),
                  label: const Text('Pick a range'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Or pick inline',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                HorizontalDateStrip(
                  theme: _theme,
                  language: _language,
                  startDate: NepaliDate.now(),
                  durationDays: 60,
                  holidays: _holidays,
                  selectedDate: _stripDate,
                  onDateSelected: (NepaliDate date) => setState(() {
                    _stripDate = date;
                    _result =
                        'Strip\n'
                        'BS: ${date.format('EEEE, d MMMM yyyy')}\n'
                        'AD: ${date.toDateTime().toIso8601String().split('T').first}';
                  }),
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Fiscal year',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickInFiscalYear(currentFy),
                        child: const Text('Current FY'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickInFiscalYear(currentFy.previous),
                        child: const Text('Previous FY'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Anchored near today for the current FY, and at the fiscal
                // year's own start otherwise — see NepaliFiscalYear.stripAnchor.
                HorizontalDateStrip(
                  theme: _theme,
                  language: _language,
                  startDate: currentFy.stripAnchor(),
                  endDate: currentFy.window().end,
                  holidays: _holidays,
                  selectedDate: _fiscalStripDate,
                  onDateSelected: (NepaliDate date) => setState(() {
                    _fiscalStripDate = date;
                    _fiscalResult =
                        'FY strip\n'
                        'BS: ${date.format('EEEE, d MMMM yyyy')}\n'
                        'AD: ${date.toDateTime().toIso8601String().split('T').first}';
                  }),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(_fiscalResult),
                  ),
                ),
                const SizedBox(height: 24),
                SegmentedButton<Language>(
                  segments: const <ButtonSegment<Language>>[
                    ButtonSegment<Language>(
                      value: Language.english,
                      label: Text('English'),
                    ),
                    ButtonSegment<Language>(
                      value: Language.nepali,
                      label: Text('नेपाली'),
                    ),
                  ],
                  selected: <Language>{_language},
                  onSelectionChanged: (Set<Language> selection) =>
                      setState(() => _language = selection.first),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(_result),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
