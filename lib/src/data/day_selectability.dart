/// The single definition of "can this day be picked".
library;

import '../models/nepali_date.dart';

/// Whether [date] satisfies every restriction the caller placed on the calendar.
///
/// A day is selectable when it sits inside the window ([startDate]..[endDate],
/// both inclusive, either end optional) *and* — when an allow-list is given —
/// appears in [selectableDates]. The two restrict independently: an allow-list
/// narrows the window rather than replacing it.
///
/// Internal, and deliberately the only place this rule is written down. The
/// month grid, the date strip and the header's "Today" action all ask this
/// question, and they used to answer it separately: the grid compared day
/// numbers while Today compared *months*, so a window opening later in the
/// current month left Today free to select a day the grid had greyed out. One
/// predicate, one answer.
bool isDaySelectable(
  NepaliDate date, {
  NepaliDate? startDate,
  NepaliDate? endDate,
  Set<NepaliDate>? selectableDates,
}) {
  if (startDate != null && date < startDate) {
    return false;
  }
  if (endDate != null && date > endDate) {
    return false;
  }
  return selectableDates == null || selectableDates.contains(date);
}
