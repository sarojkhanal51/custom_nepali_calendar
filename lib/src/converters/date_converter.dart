/// The standalone BS ⇄ AD conversion API.
library;

import '../data/bs_calendar_data.dart';
import '../models/nepali_date.dart';
import 'date_conversion_exception.dart';
import 'gregorian_calendar.dart';

/// Converts dates between Bikram Sambat and the Gregorian calendar.
///
/// This is a pure-logic API with no Flutter dependency, so it can be called from
/// anywhere — a repository, an isolate, a CLI — without rendering any UI:
///
/// ```dart
/// final NepaliDate bs = DateConverter.adToBs(DateTime(2024, 4, 13));
/// print(bs);                              // 2081-01-01
/// final DateTime ad = DateConverter.bsToAd(const NepaliDate(2081, 1, 1));
/// print(ad);                              // 2024-04-13 00:00:00.000
/// ```
///
/// ## How the conversion works
///
/// Both calendars are reduced to a single continuous day count:
///
/// 1. An anchor pair ties the two systems together —
///    **1 Baishakh 1970 BS = 13 April 1913 AD**.
/// 2. A BS date is turned into "days elapsed since the anchor" by summing whole
///    years and whole months out of [BsCalendarData.monthDays], then adding the
///    day of the month.
/// 3. That offset is added to the anchor's Julian Day Number
///    ([GregorianCalendar.toDayNumber]) to get the Gregorian date, and the same
///    steps run in reverse for the other direction.
///
/// Because everything is integer arithmetic on day numbers, conversion is exact
/// and round-tripping is lossless in both directions.
///
/// All members are static; this class is not meant to be instantiated.
abstract final class DateConverter {
  /// Julian Day Number of the anchor date (1 Baishakh [BsCalendarData.minYear]).
  static final int _anchorDayNumber = GregorianCalendar.toDayNumber(
    BsCalendarData.anchorAdYear,
    BsCalendarData.anchorAdMonth,
    BsCalendarData.anchorAdDay,
  );

  /// Cumulative day count from the anchor to 1 Baishakh of each supported year.
  ///
  /// Built once on first use so that converting a date is `O(12)` rather than
  /// `O(years)` — this matters when a screen converts hundreds of dates.
  static final List<int> _yearStartOffsets = _buildYearStartOffsets();

  static List<int> _buildYearStartOffsets() {
    final int count = BsCalendarData.maxYear - BsCalendarData.minYear + 1;
    final List<int> offsets = List<int>.filled(count + 1, 0);
    int running = 0;
    for (int i = 0; i < count; i++) {
      offsets[i] = running;
      running += BsCalendarData.daysInYear(BsCalendarData.minYear + i);
    }
    // One extra entry: the day after the last supported day, which makes range
    // checks a simple half-open interval test.
    offsets[count] = running;
    return offsets;
  }

  /// The earliest Bikram Sambat date that can be converted.
  static const NepaliDate minBsDate = NepaliDate.min;

  /// The latest Bikram Sambat date that can be converted.
  static NepaliDate get maxBsDate => NepaliDate.max;

  /// The earliest Gregorian date that can be converted.
  static DateTime get minAdDate => DateTime(
    BsCalendarData.anchorAdYear,
    BsCalendarData.anchorAdMonth,
    BsCalendarData.anchorAdDay,
  );

  /// The latest Gregorian date that can be converted.
  static DateTime get maxAdDate =>
      _dateTimeFromDayNumber(_anchorDayNumber + _yearStartOffsets.last - 1);

  /// Converts the Gregorian [adDate] to its Bikram Sambat equivalent.
  ///
  /// Any time component is ignored; the result is a calendar day. Throws a
  /// [DateConversionException] when [adDate] falls outside
  /// [minAdDate]..[maxAdDate].
  static NepaliDate adToBs(DateTime adDate) {
    final int dayNumber = GregorianCalendar.toDayNumber(
      adDate.year,
      adDate.month,
      adDate.day,
    );
    int offset = dayNumber - _anchorDayNumber;

    if (offset < 0 || offset >= _yearStartOffsets.last) {
      throw DateConversionException.outOfRange(
        date: _formatAd(adDate),
        supportedFrom: _formatAd(minAdDate),
        supportedTo: _formatAd(maxAdDate),
      );
    }

    // Binary search for the BS year whose span contains `offset`.
    int low = 0;
    int high = _yearStartOffsets.length - 2;
    while (low < high) {
      final int mid = (low + high + 1) ~/ 2;
      if (_yearStartOffsets[mid] <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }

    final int year = BsCalendarData.minYear + low;
    offset -= _yearStartOffsets[low];

    int month = 1;
    int daysInMonth = BsCalendarData.daysInMonth(year, month);
    while (offset >= daysInMonth) {
      offset -= daysInMonth;
      month++;
      daysInMonth = BsCalendarData.daysInMonth(year, month);
    }

    return NepaliDate(year, month, offset + 1);
  }

  /// Converts the Bikram Sambat [bsDate] to its Gregorian equivalent, at
  /// midnight local time.
  ///
  /// Throws a [DateConversionException] when [bsDate] is structurally invalid
  /// (bad month or day) or outside [minBsDate]..[maxBsDate].
  static DateTime bsToAd(NepaliDate bsDate) =>
      _dateTimeFromDayNumber(bsToDayNumber(bsDate));

  /// Converts [year]/[month]/[day] of the Gregorian calendar to Bikram Sambat.
  ///
  /// A convenience wrapper around [adToBs] for callers that hold loose integers.
  /// Throws a [DateConversionException] when the date is not a real Gregorian
  /// date or is out of range.
  static NepaliDate adPartsToBs(int year, int month, int day) {
    if (!GregorianCalendar.isValidDate(year, month, day)) {
      throw DateConversionException.invalidDate(
        '$year-$month-$day',
        'not a valid Gregorian date',
      );
    }
    return adToBs(DateTime(year, month, day));
  }

  /// Converts [year]/[month]/[day] of the Bikram Sambat calendar to Gregorian.
  ///
  /// Throws a [DateConversionException] when the date is invalid or out of range.
  static DateTime bsPartsToAd(int year, int month, int day) =>
      bsToAd(NepaliDate(year, month, day));

  /// The Julian Day Number of [bsDate].
  ///
  /// Exposed because it makes weekday and day-difference calculations on
  /// [NepaliDate] a single subtraction. Throws a [DateConversionException] when
  /// [bsDate] is invalid or out of range.
  static int bsToDayNumber(NepaliDate bsDate) {
    _validateBs(bsDate);
    int offset = _yearStartOffsets[bsDate.year - BsCalendarData.minYear];
    for (int m = 1; m < bsDate.month; m++) {
      offset += BsCalendarData.daysInMonth(bsDate.year, m);
    }
    offset += bsDate.day - 1;
    return _anchorDayNumber + offset;
  }

  /// Whether [bsDate] can be converted without throwing.
  static bool isConvertibleBs(NepaliDate bsDate) => bsDate.isValid;

  /// Whether [adDate] can be converted without throwing.
  static bool isConvertibleAd(DateTime adDate) {
    final int offset =
        GregorianCalendar.toDayNumber(adDate.year, adDate.month, adDate.day) -
        _anchorDayNumber;
    return offset >= 0 && offset < _yearStartOffsets.last;
  }

  /// Number of days in [month] (1-12) of the Bikram Sambat [year].
  ///
  /// Throws a [DateConversionException] when the year is unsupported or the
  /// month is out of bounds.
  static int daysInBsMonth(int year, int month) {
    if (!BsCalendarData.isSupportedYear(year)) {
      throw DateConversionException.outOfRange(
        date: year,
        supportedFrom: BsCalendarData.minYear,
        supportedTo: BsCalendarData.maxYear,
      );
    }
    if (month < 1 || month > BsCalendarData.monthsPerYear) {
      throw DateConversionException.invalidDate(
        '$year-$month',
        'month must be between 1 and 12',
      );
    }
    return BsCalendarData.daysInMonth(year, month);
  }

  /// Today's date in the Bikram Sambat calendar, in the device's local time zone.
  static NepaliDate todayBs() => adToBs(DateTime.now());

  static void _validateBs(NepaliDate bsDate) {
    if (!BsCalendarData.isSupportedYear(bsDate.year)) {
      throw DateConversionException.outOfRange(
        date: bsDate,
        supportedFrom: minBsDate,
        supportedTo: maxBsDate,
      );
    }
    if (bsDate.month < 1 || bsDate.month > BsCalendarData.monthsPerYear) {
      throw DateConversionException.invalidDate(
        bsDate,
        'month must be between 1 and 12',
      );
    }
    final int maxDay = BsCalendarData.daysInMonth(bsDate.year, bsDate.month);
    if (bsDate.day < 1 || bsDate.day > maxDay) {
      throw DateConversionException.invalidDate(
        bsDate,
        'month ${bsDate.month} of ${bsDate.year} BS has $maxDay days',
      );
    }
  }

  static DateTime _dateTimeFromDayNumber(int dayNumber) {
    final List<int> parts = GregorianCalendar.fromDayNumber(dayNumber);
    return DateTime(parts[0], parts[1], parts[2]);
  }

  static String _formatAd(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}'
      '-${date.day.toString().padLeft(2, '0')}';
}
