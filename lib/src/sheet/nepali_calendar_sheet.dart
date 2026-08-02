/// The package's public entry point: open the calendar in a bottom sheet.
library;

import 'package:flutter/material.dart';

import '../converters/date_conversion_exception.dart';
import '../converters/date_converter.dart';
import '../localization/calendar_strings.dart';
import '../models/nepali_date.dart';
import '../models/nepali_date_range.dart';
import '../theme/nepali_calendar_theme.dart';
import '../view/calendar_controller.dart';
import '../view/calendar_view.dart';

/// Whether the calendar collects a single day or a start/end pair.
enum NepaliCalendarMode {
  /// One tap picks one day.
  single,

  /// The first tap sets the range start, the second sets the end.
  range;

  /// Whether this is [NepaliCalendarMode.range].
  bool get isRange => this == NepaliCalendarMode.range;
}

/// What the user picked, returned by [showNepaliCalendar].
///
/// Exactly one of [date] and [range] is set, matching the [NepaliCalendarMode]
/// the sheet was opened with:
///
/// ```dart
/// final selection = await showNepaliCalendar(context: context);
/// selection?.date;   // set when opened in single mode
/// selection?.range;  // set when opened in range mode
/// ```
@immutable
class NepaliCalendarSelection {
  /// A single-day result.
  const NepaliCalendarSelection.single(NepaliDate this.date) : range = null;

  /// A range result.
  const NepaliCalendarSelection.range(NepaliDateRange this.range) : date = null;

  /// The picked day, set only in [NepaliCalendarMode.single].
  final NepaliDate? date;

  /// The picked range, set only in [NepaliCalendarMode.range].
  final NepaliDateRange? range;

  /// The mode this selection came from.
  NepaliCalendarMode get mode =>
      range == null ? NepaliCalendarMode.single : NepaliCalendarMode.range;

  /// The picked day as a Gregorian [DateTime], or null in range mode.
  DateTime? get dateTime => date?.toDateTime();

  /// The picked range as a Gregorian [DateTimeRange], or null in single mode.
  DateTimeRange? get dateTimeRange => range?.toDateTimeRange();

  @override
  String toString() => 'NepaliCalendarSelection(${date ?? range})';

  @override
  bool operator ==(Object other) =>
      other is NepaliCalendarSelection &&
      other.date == date &&
      other.range == range;

  @override
  int get hashCode => Object.hash(date, range);
}

/// Opens the Nepali calendar in a modal bottom sheet and returns what was picked.
///
/// Resolves to `null` when the sheet is dismissed — Cancel, a swipe down, the
/// back gesture, or a tap outside — so a null check is all the handling needed.
///
/// ```dart
/// final selection = await showNepaliCalendar(
///   context: context,
///   mode: NepaliCalendarMode.range,          // or .single (the default)
///   theme: const NepaliCalendarTheme(
///     primaryColor: Color(0xFF0B7285),       // header + active switch
///     selectedDayColor: Color(0xFFE8590C),
///     weekendColor: Color(0xFFE03131),       // Saturday
///   ),
///   allowedRange: NepaliDateRange(               // optional window; omit for
///     start: NepaliDate.now(),                   // the whole supported range
///     end: NepaliDate.now().addDays(365),
///   ),
///   maxDays: 90,                                 // …or say it as a length
/// );
///
/// if (selection != null) {
///   final NepaliDateRange? range = selection.range;   // range mode
///   final NepaliDate? day = selection.date;           // single mode
/// }
/// ```
///
/// In [NepaliCalendarMode.range] the first tap sets the start and the second the
/// end; the days between are banded, and the confirm button stays disabled until
/// both ends exist.
///
/// * [theme] carries every colour the sheet paints with — see
///   [NepaliCalendarTheme], which has usable defaults for anything left out.
/// * Nothing is preselected. The sheet opens on [allowedRange]'s first month, or
///   on the current month when unbounded, and confirm stays disabled until the
///   user picks.
/// * [allowedRange] is the window the calendar offers: days outside it are
///   greyed out and the arrows stop at its first and last month. Omit it for the
///   whole supported range (BS 1970-2199). Build one from Gregorian dates with
///   `NepaliDateRange.fromDateTimes(start: ..., end: ...)`.
/// * [maxDays] expresses the same window as a length instead of an end date:
///   counted from [allowedRange]'s first day, or from today when no range is
///   given, so `maxDays: 90` on its own means "today and the next 89 days".
///   Given both, the tighter end wins. It applies in both modes, and a range can
///   never be longer than the window it is picked from.
/// * [language] picks English or Nepali labels, and [initialSystem] picks the
///   calendar the sheet opens in. The user can switch Bikram Sambat/Gregorian
///   from the header unless [showSystemSwitch] is false; the language is fixed by
///   the caller and is not switchable in the sheet.
/// * [title] adds an optional caption above the buttons — nothing is shown there
///   otherwise. [confirmLabel] and [cancelLabel] override the button text.
Future<NepaliCalendarSelection?> showNepaliCalendar({
  required BuildContext context,
  NepaliCalendarMode mode = NepaliCalendarMode.single,
  NepaliCalendarTheme theme = const NepaliCalendarTheme(),
  Language language = Language.english,
  CalendarSystem initialSystem = CalendarSystem.bs,
  NepaliDateRange? allowedRange,
  int? maxDays,
  bool showSystemSwitch = true,
  bool isDismissible = true,
  String? title,
  String? confirmLabel,
  String? cancelLabel,
  double maxWidth = 480,
}) {
  assert(
    allowedRange == null || allowedRange.isValid,
    'allowedRange must be two real dates with start on or before end.',
  );
  assert(maxDays == null || maxDays > 0, 'maxDays must be greater than zero.');
  return showModalBottomSheet<NepaliCalendarSelection>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: theme.backgroundColor,
    constraints: BoxConstraints(maxWidth: maxWidth),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(theme.borderRadius + 8),
      ),
    ),
    builder: (BuildContext context) => _CalendarSheet(
      mode: mode,
      theme: theme,
      language: language,
      initialSystem: initialSystem,
      allowedRange: _resolveWindow(allowedRange, maxDays),
      showSystemSwitch: showSystemSwitch,
      title: title,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
}

/// Combines [allowedRange] and [maxDays] into the one window the calendar shows.
///
/// [maxDays] is a length, counted from the window's first day — or from today
/// when there is no window — so `maxDays: 90` on its own means "today and the
/// next 89 days". When both are given the tighter end wins; when neither is, the
/// calendar offers its whole supported range.
NepaliDateRange? _resolveWindow(NepaliDateRange? allowedRange, int? maxDays) {
  if (maxDays == null) {
    return allowedRange;
  }
  final NepaliDate start = allowedRange?.start ?? DateConverter.todayBs();
  NepaliDate capEnd;
  try {
    capEnd = start.addDays(maxDays - 1);
  } on DateConversionException {
    capEnd = NepaliDate.max;
  }
  final NepaliDate? windowEnd = allowedRange?.end;
  final NepaliDate end = windowEnd != null && windowEnd < capEnd
      ? windowEnd
      : capEnd;
  return NepaliDateRange(start: start, end: end);
}

class _CalendarSheet extends StatefulWidget {
  const _CalendarSheet({
    required this.mode,
    required this.theme,
    required this.language,
    required this.initialSystem,
    required this.allowedRange,
    required this.showSystemSwitch,
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  final NepaliCalendarMode mode;
  final NepaliCalendarTheme theme;
  final Language language;
  final CalendarSystem initialSystem;
  final NepaliDateRange? allowedRange;
  final bool showSystemSwitch;
  final String? title;
  final String? confirmLabel;
  final String? cancelLabel;

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  // Nothing is preselected: the sheet opens on the window's first month (or on
  // today when unbounded) and the user picks from there.
  late final CalendarController _controller = CalendarController(
    mode: widget.mode,
    focusedDate: widget.allowedRange?.start,
    system: widget.initialSystem,
    language: widget.language,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The result to pop, or null while the selection is not usable yet.
  NepaliCalendarSelection? get _result {
    if (widget.mode.isRange) {
      final NepaliDateRange? range = _controller.selectedRange;
      return range == null ? null : NepaliCalendarSelection.range(range);
    }
    final NepaliDate? date = _controller.selectedDate;
    return date == null ? null : NepaliCalendarSelection.single(date);
  }

  @override
  Widget build(BuildContext context) {
    final NepaliCalendarTheme theme = widget.theme;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.subtitleTextColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          CalendarView(
            controller: _controller,
            theme: theme,
            allowedRange: widget.allowedRange,
            showSystemSwitch: widget.showSystemSwitch,
          ),
          ListenableBuilder(
            listenable: _controller,
            builder: (BuildContext context, Widget? child) {
              final NepaliCalendarSelection? result = _result;
              final bool nepali = _controller.language.isNepali;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (widget.title != null) ...<Widget>[
                      Text(
                        widget.title!,
                        textAlign: TextAlign.center,
                        style: theme.applyFont(
                          TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.textColor,
                              side: BorderSide(color: theme.dividerColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              widget.cancelLabel ??
                                  (nepali ? 'रद्द' : 'Cancel'),
                              style: theme.applyFont(const TextStyle()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: result == null
                                ? null
                                : () => Navigator.of(context).pop(result),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: theme.headerTextColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              widget.confirmLabel ??
                                  (nepali ? 'ठीक छ' : 'Done'),
                              style: theme.applyFont(const TextStyle()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
