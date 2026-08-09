/// Caches "today" in Bikram Sambat, refreshed only when the day actually
/// changes.
library;

import '../converters/date_converter.dart';
import '../models/nepali_date.dart';

/// Keeps a [NepaliDate] for "today" without recomputing it on every access.
///
/// A plain `late final` field goes stale if the widget stays alive across
/// local midnight; recomputing on every build is correct but wasteful for a
/// widget that rebuilds often. This checks the wall clock and only redoes the
/// BS conversion when the calendar day has actually advanced.
class TodayCache {
  NepaliDate _today = DateConverter.todayBs();
  DateTime _checkedAt = DateTime.now();

  /// Today's date in Bikram Sambat, refreshed at most once per real day.
  NepaliDate get today {
    final DateTime now = DateTime.now();
    if (now.year != _checkedAt.year ||
        now.month != _checkedAt.month ||
        now.day != _checkedAt.day) {
      _today = DateConverter.todayBs();
      _checkedAt = now;
    }
    return _today;
  }
}
