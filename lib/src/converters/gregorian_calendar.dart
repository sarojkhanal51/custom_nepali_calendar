/// Pure-integer Gregorian (AD) calendar arithmetic.
///
/// Everything in this file is implemented from first principles with integer
/// maths — leap years from the 4/100/400 rule, and weekday/day-count from the
/// Julian Day Number (JDN) of a date. No third-party date library is used and
/// `DateTime` is never used to *compute* anything; it only appears at the public
/// API boundary as a data carrier.
library;

/// Gregorian calendar maths built from scratch.
///
/// The core primitive is [toDayNumber] / [fromDayNumber], a bijection between a
/// `(year, month, day)` triple and a continuous day count (the Julian Day
/// Number). Once dates are day numbers, "how many days between", "what weekday
/// is this" and "add N days" all collapse to integer arithmetic.
///
/// All members are static; this class is not meant to be instantiated.
abstract final class GregorianCalendar {
  /// Days in each month of a non-leap year, Jan..Dec.
  static const List<int> _daysInMonthCommon = <int>[
    31,
    28,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ];

  /// Whether [year] is a Gregorian leap year.
  ///
  /// A year is a leap year when it is divisible by 4, except centuries, which
  /// must also be divisible by 400. So 2024 and 2000 are leap years while 1900
  /// and 2100 are not.
  static bool isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  /// Number of days in [month] (1-12) of [year].
  ///
  /// Throws an [ArgumentError] when [month] is outside 1..12.
  static int daysInMonth(int year, int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(
        month,
        'month',
        'AD month must be between 1 and 12',
      );
    }
    if (month == 2 && isLeapYear(year)) {
      return 29;
    }
    return _daysInMonthCommon[month - 1];
  }

  /// Number of days in [year] (365 or 366).
  static int daysInYear(int year) => isLeapYear(year) ? 366 : 365;

  /// Whether `year-month-day` is a real calendar date.
  static bool isValidDate(int year, int month, int day) {
    if (month < 1 || month > 12) {
      return false;
    }
    return day >= 1 && day <= daysInMonth(year, month);
  }

  /// Converts a proleptic Gregorian date to its Julian Day Number.
  ///
  /// This is the standard Fliegel–Van Flandern algorithm. It uses only integer
  /// arithmetic and is valid for any year, including negative ones.
  static int toDayNumber(int year, int month, int day) {
    final int a = (14 - month) ~/ 12;
    final int y = year + 4800 - a;
    final int m = month + 12 * a - 3;
    return day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }

  /// Converts a Julian Day Number back to a proleptic Gregorian date.
  ///
  /// Returns a 3-element list `[year, month, day]`. This is the exact inverse of
  /// [toDayNumber].
  static List<int> fromDayNumber(int dayNumber) {
    final int a = dayNumber + 32044;
    final int b = (4 * a + 3) ~/ 146097;
    final int c = a - 146097 * b ~/ 4;
    final int d = (4 * c + 3) ~/ 1461;
    final int e = c - 1461 * d ~/ 4;
    final int m = (5 * e + 2) ~/ 153;

    final int day = e - (153 * m + 2) ~/ 5 + 1;
    final int month = m + 3 - 12 * (m ~/ 10);
    final int year = 100 * b + d - 4800 + m ~/ 10;
    return <int>[year, month, day];
  }

  /// Weekday of `year-month-day` as `0` = Sunday … `6` = Saturday.
  ///
  /// Derived from the Julian Day Number: JDN 0 was a Monday, so
  /// `(jdn + 1) % 7` yields a Sunday-based index. Nepali calendars start the
  /// week on Sunday, which is why this is the index used to lay out the grid.
  static int weekdayIndex(int year, int month, int day) =>
      dayNumberToWeekdayIndex(toDayNumber(year, month, day));

  /// Weekday of a [dayNumber] as `0` = Sunday … `6` = Saturday.
  static int dayNumberToWeekdayIndex(int dayNumber) => (dayNumber + 1) % 7;

  /// Number of whole days from [from] to [to] (negative when [to] is earlier).
  ///
  /// The time-of-day component of both arguments is ignored, so this is a pure
  /// calendar-day difference and is immune to daylight-saving shifts (which is
  /// exactly why `DateTime.difference` is not used here).
  static int daysBetween(DateTime from, DateTime to) =>
      toDayNumber(to.year, to.month, to.day) -
      toDayNumber(from.year, from.month, from.day);

  /// Returns [date] with its time component removed.
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Adds [days] calendar days to [date], returning a date-only [DateTime].
  ///
  /// Unlike `DateTime.add(Duration(days: n))` this cannot drift by an hour
  /// across a daylight-saving boundary, because the arithmetic happens on day
  /// numbers rather than on absolute time.
  static DateTime addDays(DateTime date, int days) {
    final List<int> parts = fromDayNumber(
      toDayNumber(date.year, date.month, date.day) + days,
    );
    return DateTime(parts[0], parts[1], parts[2]);
  }
}
