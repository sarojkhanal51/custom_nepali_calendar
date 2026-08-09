/// A start/end pair of Bikram Sambat dates.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;

import '../converters/date_conversion_exception.dart';
import '../data/bs_calendar_data.dart';
import 'nepali_date.dart';

/// An inclusive range of Bikram Sambat days, `start` through `end`.
///
/// Both ends are part of the range, so a range whose start and end are the same
/// day has a [lengthInDays] of `1` — which is what a user picking "just today"
/// in a range picker expects.
///
/// ```dart
/// const range = NepaliDateRange(
///   start: NepaliDate(2081, 1, 15),
///   end: NepaliDate(2081, 1, 20),
/// );
/// range.lengthInDays;      // 6
/// range.toDateTimeRange(); // 2024-04-27 .. 2024-05-02
/// ```
@immutable
class NepaliDateRange {
  /// Creates a range from [start] to [end].
  ///
  /// The values are stored as given; use [isValid] to check that they are real
  /// dates in the right order, or [normalized] to swap reversed ends.
  const NepaliDateRange({required this.start, required this.end});

  /// A range covering the single day [date].
  const NepaliDateRange.singleDay(NepaliDate date) : start = date, end = date;

  /// The range equivalent to the Gregorian [start] and [end].
  ///
  /// Throws a [DateConversionException] when either end is outside the
  /// supported range.
  NepaliDateRange.fromDateTimes({
    required DateTime start,
    required DateTime end,
  }) : start = NepaliDate.fromDateTime(start),
       end = NepaliDate.fromDateTime(end);

  /// The first day of the range, inclusive.
  final NepaliDate start;

  /// The last day of the range, inclusive.
  final NepaliDate end;

  /// Whether both ends are real dates and [start] is not after [end].
  bool get isValid => start.isValid && end.isValid && start <= end;

  /// Whether the range covers exactly one day.
  bool get isSingleDay => start == end;

  /// Number of days covered, counting both ends (never less than `1` for a
  /// valid range).
  int get lengthInDays => start.differenceInDays(end) + 1;

  /// This range with its ends swapped if they were the wrong way round.
  NepaliDateRange get normalized =>
      start <= end ? this : NepaliDateRange(start: end, end: start);

  /// Whether [date] falls inside the range, inclusive of both ends.
  bool contains(NepaliDate date) => date >= start && date <= end;

  /// Every day in the range, in order.
  ///
  /// Materializes one [NepaliDate] per day, so prefer [contains] for membership
  /// tests over long spans. Empty when [start] is after [end].
  ///
  /// Walks Bikram Sambat year/month/day directly rather than repeatedly
  /// converting through the Gregorian calendar, so this stays cheap even for
  /// a multi-year range.
  List<NepaliDate> get days {
    if (start > end) {
      return const <NepaliDate>[];
    }
    final List<NepaliDate> result = <NepaliDate>[];
    int year = start.year;
    int month = start.month;
    int day = start.day;
    while (true) {
      final NepaliDate cursor = NepaliDate(year, month, day);
      result.add(cursor);
      if (cursor >= end) {
        break;
      }
      day++;
      if (day > BsCalendarData.daysInMonth(year, month)) {
        day = 1;
        month++;
        if (month > BsCalendarData.monthsPerYear) {
          month = 1;
          year++;
        }
        if (!BsCalendarData.isSupportedYear(year)) {
          throw DateConversionException.outOfRange(
            date: '$year-${month.toString().padLeft(2, '0')}',
            supportedFrom: BsCalendarData.minYear,
            supportedTo: BsCalendarData.maxYear,
          );
        }
      }
    }
    return result;
  }

  /// The equivalent Gregorian range.
  ///
  /// Throws a [DateConversionException] when either end cannot be converted.
  DateTimeRange toDateTimeRange() =>
      DateTimeRange(start: start.toDateTime(), end: end.toDateTime());

  /// A copy of this range with the given ends replaced.
  NepaliDateRange copyWith({NepaliDate? start, NepaliDate? end}) =>
      NepaliDateRange(start: start ?? this.start, end: end ?? this.end);

  @override
  String toString() => '$start – $end';

  @override
  bool operator ==(Object other) =>
      other is NepaliDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
