/// The Bikram Sambat date model.
library;

import '../converters/date_conversion_exception.dart';
import '../converters/date_converter.dart';
import '../converters/gregorian_calendar.dart';
import '../data/bs_calendar_data.dart';
import '../localization/calendar_strings.dart';

/// An immutable Bikram Sambat (Nepali) calendar date.
///
/// A [NepaliDate] is a plain year/month/day triple with no time component — it
/// represents a calendar day, not an instant. Construction never throws, so a
/// date can be built and then checked with [isValid]; the conversion API is what
/// rejects unsupported values.
///
/// ```dart
/// const NepaliDate newYear = NepaliDate(2081, 1, 1);
/// print(newYear);                       // 2081-01-01
/// print(newYear.toDateTime());          // 2024-04-13 00:00:00.000
/// print(newYear.format('MMMM d, yyyy', language: Language.nepali)); // बैशाख १, २०८१
/// ```
class NepaliDate implements Comparable<NepaliDate> {
  /// Creates a Bikram Sambat date from its [year], [month] (1-12) and [day].
  ///
  /// The values are stored as given; use [isValid] to check them.
  const NepaliDate(this.year, this.month, this.day);

  /// The Bikram Sambat date corresponding to the Gregorian [dateTime].
  ///
  /// Any time component is discarded. Throws a [DateConversionException] when
  /// [dateTime] is outside the supported range.
  factory NepaliDate.fromDateTime(DateTime dateTime) =>
      DateConverter.adToBs(dateTime);

  /// The Bikram Sambat date for the current day in the device's local time zone.
  factory NepaliDate.now() => DateConverter.adToBs(DateTime.now());

  /// The Bikram Sambat year, e.g. `2081`.
  final int year;

  /// The Bikram Sambat month, `1` (Baishakh) to `12` (Chaitra).
  final int month;

  /// The day of the month, starting at `1`.
  final int day;

  /// The earliest date this package can represent.
  static const NepaliDate min = NepaliDate(BsCalendarData.minYear, 1, 1);

  /// The latest date this package can represent.
  static NepaliDate get max => NepaliDate(
    BsCalendarData.maxYear,
    BsCalendarData.monthsPerYear,
    BsCalendarData.daysInMonth(
      BsCalendarData.maxYear,
      BsCalendarData.monthsPerYear,
    ),
  );

  /// Whether this is a real Bikram Sambat date within the supported range.
  ///
  /// Returns `false` for a month outside 1..12, a day outside the actual length
  /// of that month, or a year the month-length table does not cover.
  bool get isValid {
    if (!BsCalendarData.isSupportedYear(year)) {
      return false;
    }
    if (month < 1 || month > BsCalendarData.monthsPerYear) {
      return false;
    }
    return day >= 1 && day <= BsCalendarData.daysInMonth(year, month);
  }

  /// Number of days in this date's month.
  ///
  /// Throws an [ArgumentError] when [year] is outside the supported range.
  int get daysInMonth => BsCalendarData.daysInMonth(year, month);

  /// Number of days in this date's year.
  ///
  /// Throws an [ArgumentError] when [year] is outside the supported range.
  int get daysInYear => BsCalendarData.daysInYear(year);

  /// The weekday as `0` = Sunday … `6` = Saturday.
  ///
  /// This Sunday-based index matches how Nepali calendars lay out their grid and
  /// is what indexes into [CalendarStrings.weekdayName].
  int get weekdayIndex => GregorianCalendar.dayNumberToWeekdayIndex(
    DateConverter.bsToDayNumber(this),
  );

  /// The weekday as `1` = Sunday … `7` = Saturday.
  ///
  /// Note this is *not* the same numbering as [DateTime.weekday], which is
  /// Monday-based; Nepali weeks begin on Sunday. Use [weekdayIndex] for
  /// zero-based work.
  int get weekday => weekdayIndex + 1;

  /// Whether this date is a Saturday — the weekend in Nepal.
  bool get isSaturday => weekdayIndex == 6;

  /// The day of the year, `1` for 1 Baishakh.
  int get dayOfYear {
    int total = day;
    for (int m = 1; m < month; m++) {
      total += BsCalendarData.daysInMonth(year, m);
    }
    return total;
  }

  /// The equivalent Gregorian date, at midnight local time.
  ///
  /// Throws a [DateConversionException] when this date is invalid or outside the
  /// supported range.
  DateTime toDateTime() => DateConverter.bsToAd(this);

  /// This date shifted by [days] (which may be negative).
  ///
  /// Throws a [DateConversionException] when the result leaves the supported
  /// range.
  NepaliDate addDays(int days) =>
      DateConverter.adToBs(GregorianCalendar.addDays(toDateTime(), days));

  /// This date shifted by [days] backwards.
  ///
  /// Throws a [DateConversionException] when the result leaves the supported
  /// range.
  NepaliDate subtractDays(int days) => addDays(-days);

  /// The number of days from this date to [other] (negative when [other] is
  /// earlier).
  int differenceInDays(NepaliDate other) =>
      DateConverter.bsToDayNumber(other) - DateConverter.bsToDayNumber(this);

  /// The first day of this date's month.
  NepaliDate get firstDayOfMonth => NepaliDate(year, month, 1);

  /// The last day of this date's month.
  NepaliDate get lastDayOfMonth =>
      NepaliDate(year, month, BsCalendarData.daysInMonth(year, month));

  /// The same day number in the next month, clamped to that month's length.
  ///
  /// Rolls over to Baishakh of the following year after Chaitra.
  NepaliDate get nextMonth => _shiftMonth(1);

  /// The same day number in the previous month, clamped to that month's length.
  ///
  /// Rolls back to Chaitra of the previous year before Baishakh.
  NepaliDate get previousMonth => _shiftMonth(-1);

  NepaliDate _shiftMonth(int delta) {
    final int zeroBased = (year * 12 + (month - 1)) + delta;
    final int newYear = zeroBased ~/ 12;
    final int newMonth = zeroBased % 12 + 1;
    if (!BsCalendarData.isSupportedYear(newYear)) {
      throw DateConversionException.outOfRange(
        date: '$newYear-${newMonth.toString().padLeft(2, '0')}',
        supportedFrom: BsCalendarData.minYear,
        supportedTo: BsCalendarData.maxYear,
      );
    }
    final int maxDay = BsCalendarData.daysInMonth(newYear, newMonth);
    return NepaliDate(newYear, newMonth, day > maxDay ? maxDay : day);
  }

  /// A copy of this date with the given fields replaced.
  NepaliDate copyWith({int? year, int? month, int? day}) =>
      NepaliDate(year ?? this.year, month ?? this.month, day ?? this.day);

  /// Whether this date is the same calendar day as [other].
  bool isSameDay(NepaliDate other) =>
      year == other.year && month == other.month && day == other.day;

  /// Whether this date falls in the same month and year as [other].
  bool isSameMonth(NepaliDate other) =>
      year == other.year && month == other.month;

  /// The localized month name for this date.
  String monthName(Language language) =>
      CalendarStrings.monthName(month, CalendarSystem.bs, language);

  /// The localized weekday name for this date.
  ///
  /// Pass `short: true` for the abbreviated form.
  String weekdayName(Language language, {bool short = false}) =>
      CalendarStrings.weekdayName(weekdayIndex, language, short: short);

  /// Formats this date against a [pattern], localized for [language].
  ///
  /// Supported tokens:
  ///
  /// | Token  | Meaning                          | Example (2081-01-05) |
  /// |--------|----------------------------------|----------------------|
  /// | `yyyy` | 4-digit year                     | `2081`               |
  /// | `yy`   | 2-digit year                     | `81`                 |
  /// | `MMMM` | full month name                  | `Baishakh`           |
  /// | `MMM`  | short month name (first 3 chars) | `Bai`                |
  /// | `MM`   | zero-padded month number         | `01`                  |
  /// | `M`    | month number                     | `1`                  |
  /// | `dd`   | zero-padded day                  | `05`                 |
  /// | `d`    | day                              | `5`                  |
  /// | `EEEE` | full weekday name                | `Friday`             |
  /// | `EEE`  | short weekday name               | `Fri`                |
  ///
  /// Any other character is emitted verbatim, and text between single quotes is
  /// treated as a literal (`"'day' d"` renders `day 5`). In
  /// [Language.nepali] every digit is rendered in Devanagari.
  String format(String pattern, {Language language = Language.english}) {
    final StringBuffer out = StringBuffer();
    int i = 0;
    while (i < pattern.length) {
      final String char = pattern[i];

      if (char == "'") {
        final int close = pattern.indexOf("'", i + 1);
        if (close == -1) {
          out.write(pattern.substring(i + 1));
          break;
        }
        // Two consecutive quotes stand for a literal quote character.
        out.write(close == i + 1 ? "'" : pattern.substring(i + 1, close));
        i = close + 1;
        continue;
      }

      if (char == 'y' || char == 'M' || char == 'd' || char == 'E') {
        int run = 1;
        while (i + run < pattern.length && pattern[i + run] == char) {
          run++;
        }
        out.write(_formatToken(char, run, language));
        i += run;
        continue;
      }

      out.write(char);
      i++;
    }
    return out.toString();
  }

  String _formatToken(String char, int run, Language language) {
    switch (char) {
      case 'y':
        if (run == 2) {
          return NepaliNumerals.format(year % 100, language, padTo: 2);
        }
        return NepaliNumerals.format(year, language, padTo: run);
      case 'M':
        if (run >= 4) {
          return monthName(language);
        }
        if (run == 3) {
          final String name = monthName(language);
          // Devanagari month names are short already, and slicing them by code
          // unit would cut a vowel mark off its consonant, so only the Latin
          // names are abbreviated.
          if (language.isNepali || name.length <= 3) {
            return name;
          }
          return name.substring(0, 3);
        }
        return NepaliNumerals.format(month, language, padTo: run);
      case 'd':
        return NepaliNumerals.format(day, language, padTo: run);
      case 'E':
        return weekdayName(language, short: run <= 3);
      default:
        return '';
    }
  }

  /// The ISO-like textual form `yyyy-MM-dd`, always in Latin digits.
  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}'
      '-${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(NepaliDate other) {
    if (year != other.year) {
      return year.compareTo(other.year);
    }
    if (month != other.month) {
      return month.compareTo(other.month);
    }
    return day.compareTo(other.day);
  }

  /// Whether this date is strictly before [other].
  bool operator <(NepaliDate other) => compareTo(other) < 0;

  /// Whether this date is before or the same day as [other].
  bool operator <=(NepaliDate other) => compareTo(other) <= 0;

  /// Whether this date is strictly after [other].
  bool operator >(NepaliDate other) => compareTo(other) > 0;

  /// Whether this date is after or the same day as [other].
  bool operator >=(NepaliDate other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is NepaliDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}
