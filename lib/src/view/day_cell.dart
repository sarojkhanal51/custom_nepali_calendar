/// One day cell of the month grid.
library;

import 'package:flutter/material.dart';

import '../localization/calendar_strings.dart';
import '../models/nepali_date.dart';
import '../theme/nepali_calendar_theme.dart';

/// Everything the grid knows about one cell.
///
/// A day is described in both calendars at once, which is what lets a cell show
/// a Bikram Sambat number with the Gregorian number underneath and lets the
/// selection survive a BS/AD switch.
@immutable
class CalendarDay {
  /// Creates a description of one grid cell.
  const CalendarDay({
    required this.bsDate,
    required this.adDate,
    required this.weekdayIndex,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.isDisabled,
    this.isRangeStart = false,
    this.isRangeEnd = false,
    this.isInRange = false,
    this.holidayColor,
    this.highlightColor,
  });

  /// The day in Bikram Sambat.
  final NepaliDate bsDate;

  /// The same day in the Gregorian calendar.
  final DateTime adDate;

  /// The weekday index, `0` = Sunday … `6` = Saturday.
  ///
  /// Passed in by the grid builder, which already derives it from the same
  /// day number used to compute [bsDate] and [adDate], rather than
  /// recomputed here from [bsDate].
  final int weekdayIndex;

  /// Whether this day belongs to the month on screen, as opposed to being a
  /// leading/trailing day borrowed from a neighbouring month.
  final bool isCurrentMonth;

  /// Whether this day is today.
  final bool isToday;

  /// Whether this day is the selected day (or a pending range start).
  final bool isSelected;

  /// Whether this day is outside the min/max bounds and cannot be picked.
  final bool isDisabled;

  /// Whether this day is the first day of a completed range.
  final bool isRangeStart;

  /// Whether this day is the last day of a completed range.
  final bool isRangeEnd;

  /// Whether this day lies inside a completed range, ends included.
  final bool isInRange;

  /// The color to paint the day number in, when this day is a caller-supplied
  /// holiday. Null when the day is not a holiday.
  final Color? holidayColor;

  /// The color this day is marked in, when it came from a `selectableDates`
  /// group that carries one. Null when the day is unmarked — or when it is
  /// disabled, since a day the window rules out is not on offer to mark.
  final Color? highlightColor;

  /// Whether this day is a Saturday — the Nepali weekend.
  bool get isWeekend => weekdayIndex == 6;

  /// The day number to show in [system].
  int dayNumber(CalendarSystem system) =>
      system == CalendarSystem.bs ? bsDate.day : adDate.day;
}

/// A tappable day: the number, plus selection, today and range decorations.
class DayCell extends StatelessWidget {
  /// Creates a day cell.
  const DayCell({
    required this.day,
    required this.system,
    required this.language,
    required this.theme,
    required this.showAlternateDate,
    this.onTap,
    super.key,
  });

  /// The day this cell represents.
  final CalendarDay day;

  /// The active calendar system, which decides the primary number.
  final CalendarSystem system;

  /// The active language, which decides the digits used.
  final Language language;

  /// Colors and metrics.
  final NepaliCalendarTheme theme;

  /// Whether to show the other calendar's day number underneath.
  final bool showAlternateDate;

  /// Called when the cell is tapped. A null callback renders the cell inert.
  final VoidCallback? onTap;

  /// How much of a marked day's color washes the cell behind the number.
  ///
  /// Low enough that the day number stays readable in that same color, and
  /// that the border rather than the fill is what carries the mark.
  static const double _highlightFillOpacity = 0.14;

  bool get _isEnd => day.isRangeStart || day.isRangeEnd;

  @override
  Widget build(BuildContext context) {
    final int primary = day.dayNumber(system);
    final int alternate = system == CalendarSystem.bs
        ? day.adDate.day
        : day.bsDate.day;

    final Widget cell = Semantics(
      button: onTap != null,
      selected: day.isSelected || _isEnd,
      enabled: !day.isDisabled,
      label: _semanticsLabel(),
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.all(theme.cellSpacing),
        child: Material(
          color: Colors.transparent,
          shape: _shapeBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: _shapeBorder(),
            child: DecoratedBox(
              decoration: _decoration(),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      NepaliNumerals.format(primary, language),
                      textAlign: TextAlign.center,
                      style: theme.resolvedDayTextStyle.copyWith(
                        color: _foregroundColor(),
                        fontWeight: day.isSelected || day.isToday || _isEnd
                            ? FontWeight.w700
                            : null,
                      ),
                    ),
                    if (showAlternateDate)
                      Text(
                        NepaliNumerals.format(alternate, language),
                        textAlign: TextAlign.center,
                        style: theme.resolvedDayTextStyle.copyWith(
                          fontSize:
                              (theme.resolvedDayTextStyle.fontSize ?? 15) *
                              0.62,
                          fontWeight: FontWeight.w400,
                          color: _alternateColor(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!day.isInRange) {
      return cell;
    }
    // The band sits behind the cell and bleeds to the cell edges so adjacent
    // days join into one continuous bar across the week.
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: theme.cellSpacing + 2),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color:
                    theme.rangeFillColor ??
                    theme.selectedDayColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(day.isRangeStart ? 999 : 0),
                  right: Radius.circular(day.isRangeEnd ? 999 : 0),
                ),
              ),
            ),
          ),
        ),
        cell,
      ],
    );
  }

  ShapeBorder _shapeBorder() => theme.dayCellShape == BoxShape.circle
      ? const CircleBorder()
      : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.borderRadius / 2),
        );

  Decoration _decoration() {
    final BorderRadius? radius = theme.dayCellShape == BoxShape.circle
        ? null
        : BorderRadius.circular(theme.borderRadius / 2);
    if (day.isSelected || _isEnd) {
      return BoxDecoration(
        color: theme.selectedDayColor,
        shape: theme.dayCellShape,
        borderRadius: radius,
      );
    }
    // A marked day: bright in the caller's color at the edge, light in the
    // middle, so it reads as on offer without competing with the selection.
    // Above today's ring deliberately — the caller asked for this color on
    // this day, and today is still legible through its bold number.
    final Color? highlight = day.highlightColor;
    if (highlight != null) {
      return BoxDecoration(
        color: highlight.withValues(alpha: _highlightFillOpacity),
        shape: theme.dayCellShape,
        borderRadius: radius,
        border: Border.all(color: highlight, width: 1.5),
      );
    }
    if (day.isToday) {
      return BoxDecoration(
        shape: theme.dayCellShape,
        borderRadius: radius,
        border: Border.all(color: theme.todayHighlightColor, width: 1.5),
      );
    }
    return BoxDecoration(shape: theme.dayCellShape, borderRadius: radius);
  }

  Color _foregroundColor() {
    if (day.isSelected || _isEnd) {
      return theme.selectedDayTextColor;
    }
    if (day.isDisabled || !day.isCurrentMonth) {
      return theme.disabledDayColor;
    }
    if (day.isToday) {
      return theme.todayHighlightColor;
    }
    if (day.holidayColor != null) {
      return day.holidayColor!;
    }
    // Below the holiday color on purpose: a marked day that is also a holiday
    // keeps its holiday number and shows the mark through border and fill, so
    // neither signal is lost on a day that carries both.
    if (day.highlightColor != null) {
      return day.highlightColor!;
    }
    if (day.isWeekend) {
      return theme.weekendColor;
    }
    return theme.textColor;
  }

  Color _alternateColor() {
    if (day.isSelected || _isEnd) {
      return theme.selectedDayTextColor.withValues(alpha: 0.85);
    }
    if (day.isDisabled || !day.isCurrentMonth) {
      return theme.disabledDayColor;
    }
    return theme.subtitleTextColor;
  }

  String _semanticsLabel() {
    if (system == CalendarSystem.bs) {
      return '${day.bsDate.format('EEEE, MMMM d, yyyy', language: language)} '
          '${CalendarSystem.bs.label(language)}';
    }
    final DateTime ad = day.adDate;
    return '${CalendarStrings.weekdayName(day.weekdayIndex, language)}, '
        '${CalendarStrings.monthName(ad.month, CalendarSystem.ad, language)} '
        '${NepaliNumerals.format(ad.day, language)}, '
        '${NepaliNumerals.format(ad.year, language)} '
        '${CalendarSystem.ad.label(language)}';
  }
}
