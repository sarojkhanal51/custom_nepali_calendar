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
  if (endDate != null && durationDays != null) {
    // Was an assert, so in release the two silently collapsed to endDate and
    // the caller's durationDays was dropped without a word. The neighbouring
    // ordering checks already throw for real; this one now matches them.
    throw ArgumentError(
      'Give the window an endDate or a durationDays, not both '
      '(got endDate: $endDate and durationDays: $durationDays).',
    );
  }
  if (endDate != null) {
    if (endDate < startDate) {
      throw ArgumentError.value(
        endDate,
        'endDate',
        'must not be before startDate ($startDate)',
      );
    }
    return NepaliDateRange(start: startDate, end: endDate);
  }
  if (durationDays != null && durationDays <= 0) {
    throw ArgumentError.value(
      durationDays,
      'durationDays',
      'must be greater than zero',
    );
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
