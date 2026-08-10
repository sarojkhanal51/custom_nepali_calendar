/// Internal state holder for the calendar view.
library;

import 'package:flutter/foundation.dart';

import '../converters/date_converter.dart';
import '../localization/calendar_strings.dart';
import '../models/nepali_date.dart';
import '../models/nepali_date_range.dart';
import '../sheet/nepali_calendar_sheet.dart' show NepaliCalendarMode;

/// Holds what the calendar is currently showing and what the user has picked.
///
/// Internal: consuming apps drive the calendar through `showNepaliCalendar` and
/// read the result it returns, so this is never exported.
class CalendarController extends ChangeNotifier {
  /// Creates the state for one open calendar.
  CalendarController({
    required this.mode,
    NepaliDate? focusedDate,
    NepaliDate? initialDate,
    NepaliDateRange? initialRange,
    CalendarSystem system = CalendarSystem.bs,
    this.language = Language.english,
  }) : _focusedDate =
           focusedDate ??
           initialDate ??
           initialRange?.start ??
           DateConverter.todayBs(),
       _system = system,
       _selectedDate = mode == NepaliCalendarMode.single ? initialDate : null,
       _rangeStart = mode == NepaliCalendarMode.range
           ? initialRange?.start
           : null,
       _rangeEnd = mode == NepaliCalendarMode.range ? initialRange?.end : null;

  /// Whether taps collect one day or a start/end pair.
  final NepaliCalendarMode mode;

  /// The language every label is rendered in, fixed by the caller.
  final Language language;

  NepaliDate? _selectedDate;
  NepaliDate? _rangeStart;
  NepaliDate? _rangeEnd;

  NepaliDate _focusedDate;
  CalendarSystem _system;

  /// The day highlighted as "selected".
  ///
  /// In range mode this is the pending start while the range is incomplete, so
  /// the first tap is visibly acknowledged; once both ends exist the range band
  /// takes over and this is null.
  NepaliDate? get selectedDate {
    if (mode == NepaliCalendarMode.single) {
      return _selectedDate;
    }
    return _rangeEnd == null ? _rangeStart : null;
  }

  /// The completed range, or null while it is incomplete or in single mode.
  NepaliDateRange? get selectedRange {
    final NepaliDate? start = _rangeStart;
    final NepaliDate? end = _rangeEnd;
    if (mode == NepaliCalendarMode.single || start == null || end == null) {
      return null;
    }
    return NepaliDateRange(start: start, end: end).normalized;
  }

  /// The range start, set as soon as the first day is tapped.
  NepaliDate? get rangeStart => _rangeStart;

  /// The range end, set once the second day is tapped.
  NepaliDate? get rangeEnd => _rangeEnd;

  /// Any day inside the month currently on screen.
  NepaliDate get focusedDate => _focusedDate;

  /// The calendar system being displayed.
  CalendarSystem get system => _system;

  /// Applies a tap on [date], honouring [mode].
  ///
  /// In range mode the first tap starts a range, the second completes it, a tap
  /// before the current start becomes the new start, and a tap after a complete
  /// range starts a fresh one.
  void tapDate(NepaliDate date) {
    final NepaliDate? start = _rangeStart;
    if (mode == NepaliCalendarMode.single) {
      _selectedDate = date;
    } else if (start == null || _rangeEnd != null) {
      _rangeStart = date;
      _rangeEnd = null;
    } else if (date < start) {
      _rangeStart = date;
    } else {
      _rangeEnd = date;
    }
    _focusedDate = date;
    notifyListeners();
  }

  /// Shows the month containing [date] without changing the selection.
  void showMonthOf(NepaliDate date) {
    if (_focusedDate.isSameMonth(date)) {
      return;
    }
    _focusedDate = date;
    notifyListeners();
  }

  /// Moves the view one month forward.
  void nextMonth() => showMonthOf(_focusedDate.nextMonth);

  /// Moves the view one month back.
  void previousMonth() => showMonthOf(_focusedDate.previousMonth);

  /// Selects today and scrolls to its month.
  void goToToday() => tapDate(DateConverter.todayBs());

  /// Switches the displayed calendar system.
  void setSystem(CalendarSystem system) {
    if (_system == system) {
      return;
    }
    _system = system;
    notifyListeners();
  }
}
