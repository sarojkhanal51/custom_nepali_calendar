/// Shared resolution of the caller's start / end / duration triple.
library;

import '../converters/date_conversion_exception.dart';
import '../models/nepali_date.dart';
import '../models/nepali_date_range.dart';

/// Turns the caller's bounds into the one window a calendar offers.
///
/// [startDate] is where the window opens. It closes at [endDate] when given, or
/// [durationDays] days later — a count that includes the start, so
/// `durationDays: 90` means the start plus the next 89. With neither, the window
/// runs to the end of the supported range.
///
/// Internal: shared by the bottom sheet and the date strip so the two agree on
/// what is selectable.
NepaliDateRange resolveCalendarWindow({
  required NepaliDate startDate,
  NepaliDate? endDate,
  int? durationDays,
}) {
  if (endDate != null) {
    return NepaliDateRange(start: startDate, end: endDate);
  }
  if (durationDays == null) {
    return NepaliDateRange(start: startDate, end: NepaliDate.max);
  }
  NepaliDate end;
  try {
    end = startDate.addDays(durationDays - 1);
  } on DateConversionException {
    end = NepaliDate.max;
  }
  return NepaliDateRange(start: startDate, end: end);
}
