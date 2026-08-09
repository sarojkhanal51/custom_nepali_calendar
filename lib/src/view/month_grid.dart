/// The Sun..Sat row and one page of day cells.
library;

import 'package:flutter/material.dart';

import '../converters/date_converter.dart';
import '../converters/gregorian_calendar.dart';
import '../localization/calendar_strings.dart';
import '../models/nepali_date.dart';
import '../models/nepali_date_range.dart';
import '../theme/nepali_calendar_theme.dart';
import 'day_cell.dart';

/// Number of columns in the grid — one per weekday.
const int daysPerWeek = 7;

/// Builds the cells of one month page, Sunday-first.
///
/// Both calendar systems go through the same code path: the month's first day is
/// reduced to a day number, the grid walks forward one day at a time, and each
/// day number is expanded back into a BS/AD pair. That is why leading and
/// trailing days are correct even when a BS month straddles two Gregorian months.
///
/// [startDate] and [endDate] mark days outside the caller's window as disabled.
///
/// A `null` entry renders an empty cell, which happens only at the very edges of
/// the range the BS table can represent.
List<CalendarDay?> buildMonthDays({
  required int year,
  required int month,
  required CalendarSystem system,
  required NepaliDate today,
  required int weekCount,
  NepaliDate? selectedDate,
  NepaliDate? rangeStart,
  NepaliDate? rangeEnd,
  NepaliDate? startDate,
  NepaliDate? endDate,
  Map<NepaliDate, Color>? holidayColors,
}) {
  final int firstDayNumber = system == CalendarSystem.bs
      ? DateConverter.bsToDayNumber(NepaliDate(year, month, 1))
      : GregorianCalendar.toDayNumber(year, month, 1);
  final int startDayNumber =
      firstDayNumber -
      GregorianCalendar.dayNumberToWeekdayIndex(firstDayNumber);

  final int? minDayNumber = startDate == null
      ? null
      : DateConverter.bsToDayNumber(startDate);
  final int? maxDayNumber = endDate == null
      ? null
      : DateConverter.bsToDayNumber(endDate);

  // A range needs both ends before the in-between band can be drawn.
  final NepaliDateRange? range = rangeStart != null && rangeEnd != null
      ? NepaliDateRange(start: rangeStart, end: rangeEnd).normalized
      : null;

  final List<CalendarDay?> days = <CalendarDay?>[];
  for (int i = 0; i < weekCount * daysPerWeek; i++) {
    final int dayNumber = startDayNumber + i;
    final List<int> parts = GregorianCalendar.fromDayNumber(dayNumber);
    final DateTime adDate = DateTime(parts[0], parts[1], parts[2]);

    if (!DateConverter.isConvertibleAd(adDate)) {
      days.add(null);
      continue;
    }

    final NepaliDate bsDate = DateConverter.adToBs(adDate);
    days.add(
      CalendarDay(
        bsDate: bsDate,
        adDate: adDate,
        weekdayIndex: GregorianCalendar.dayNumberToWeekdayIndex(dayNumber),
        isCurrentMonth: system == CalendarSystem.bs
            ? bsDate.year == year && bsDate.month == month
            : adDate.year == year && adDate.month == month,
        isToday: bsDate == today,
        isSelected: selectedDate != null && bsDate == selectedDate,
        isDisabled:
            (minDayNumber != null && dayNumber < minDayNumber) ||
            (maxDayNumber != null && dayNumber > maxDayNumber),
        isRangeStart: range != null && bsDate == range.start,
        isRangeEnd: range != null && bsDate == range.end,
        isInRange: range != null && range.contains(bsDate),
        holidayColor: holidayColors?[bsDate],
      ),
    );
  }
  return days;
}

/// The `Sun Mon Tue …` row above the grid.
class WeekdayHeaderRow extends StatelessWidget {
  /// Creates the weekday header row.
  const WeekdayHeaderRow({
    required this.language,
    required this.theme,
    super.key,
  });

  /// Language used for the labels.
  final Language language;

  /// Colors and metrics.
  final NepaliCalendarTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.weekdayHeaderBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          for (int index = 0; index < daysPerWeek; index++)
            Expanded(
              child: Text(
                CalendarStrings.weekdayName(index, language, short: true),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: theme.resolvedWeekdayHeaderTextStyle.copyWith(
                  color: index == 6
                      ? theme.weekendColor
                      : theme.weekdayHeaderColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One page of the calendar: a grid of [CalendarDay] cells.
class MonthGrid extends StatelessWidget {
  /// Creates a month page.
  const MonthGrid({
    required this.days,
    required this.system,
    required this.language,
    required this.theme,
    required this.rowHeight,
    required this.showAlternateDate,
    required this.onDayTapped,
    super.key,
  });

  /// The cells to render, in reading order; `null` renders an empty cell.
  final List<CalendarDay?> days;

  /// The active calendar system.
  final CalendarSystem system;

  /// The active language.
  final Language language;

  /// Colors and metrics.
  final NepaliCalendarTheme theme;

  /// Height of one week row.
  final double rowHeight;

  /// Whether each cell shows the other calendar's day number.
  final bool showAlternateDate;

  /// Called when a selectable day is tapped.
  final ValueChanged<CalendarDay> onDayTapped;

  @override
  Widget build(BuildContext context) {
    final int rows = (days.length / daysPerWeek).ceil();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int row = 0; row < rows; row++)
          SizedBox(
            height: rowHeight,
            child: Row(
              children: <Widget>[
                for (int column = 0; column < daysPerWeek; column++)
                  Expanded(child: _buildCell(row * daysPerWeek + column)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCell(int index) {
    final CalendarDay? day = index < days.length ? days[index] : null;
    if (day == null) {
      return const SizedBox.shrink();
    }
    return DayCell(
      day: day,
      system: system,
      language: language,
      theme: theme,
      showAlternateDate: showAlternateDate,
      onTap: day.isDisabled ? null : () => onDayTapped(day),
    );
  }
}
