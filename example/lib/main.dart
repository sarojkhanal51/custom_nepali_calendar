// Demo of the custom_nepali_calendar package.
//
// The package has one entry point: showNepaliCalendar. This screen calls it
// twice — once for a single date, once for a range — with a caller-supplied
// theme, and shows what comes back.

import 'package:flutter/material.dart';
import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';

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
  Language _language = Language.english;

  Future<void> _pickDate() async {
    final NepaliCalendarSelection? selection = await showNepaliCalendar(
      context: context,
      theme: _theme,
      language: _language,
      // Today, and the ninety days after it.
      startDate: NepaliDate.now(),
      durationDays: 90,
    );

    setState(() {
      if (selection?.date == null) {
        _result = 'Single: cancelled';
        return;
      }
      final NepaliDate date = selection!.date!;
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
    );

    setState(() {
      final NepaliDateRange? range = selection?.range;
      if (range == null) {
        _result = 'Range: cancelled';
        return;
      }
      _result =
          'Range (${range.lengthInDays} days)\n'
          'BS: ${range.start} → ${range.end}\n'
          'AD: ${range.toDateTimeRange().start.toIso8601String().split('T').first}'
          ' → '
          '${range.toDateTimeRange().end.toIso8601String().split('T').first}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('custom_nepali_calendar')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
