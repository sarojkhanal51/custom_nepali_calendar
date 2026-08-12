/// An inline row of days, with the full calendar one tap away.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/bs_calendar_data.dart';
import '../data/day_selectability.dart';
import '../data/holiday_lookup.dart';
import '../data/selectable_dates.dart';
import '../localization/calendar_strings.dart';
import '../models/nepali_date.dart';
import '../models/nepali_date_range.dart';
import '../models/nepali_holiday.dart';
import '../sheet/calendar_window.dart';
import '../sheet/nepali_calendar_sheet.dart';
import '../theme/nepali_calendar_theme.dart';
import '../util/today_cache.dart';

/// A short row of consecutive days — today and the next few — with a trailing
/// button that opens the full calendar for anything outside that range.
///
/// Unlike [showNepaliCalendar] this is a widget, not a call: it sits on your
/// screen permanently, so the selection is yours to hold and pass back in.
///
/// ```dart
/// HorizontalDateStrip(
///   theme: myCalendarTheme,
///   selectedDate: _date,
///   onDateSelected: (NepaliDate date) => setState(() => _date = date),
/// )
/// ```
///
/// Each day shows its weekday name above the date, Saturdays take the theme's
/// weekend colour, and the selected day is filled. Picking a date from the
/// calendar that falls outside the visible days re-anchors the strip so the
/// selection stays on screen.
class HorizontalDateStrip extends StatefulWidget {
  /// Creates a strip of [dayCount] consecutive days.
  const HorizontalDateStrip({
    required this.theme,
    required this.onDateSelected,
    required this.startDate,
    this.selectedDate,
    this.dayCount = 5,
    this.endDate,
    this.durationDays,
    this.language = Language.english,
    this.system = CalendarSystem.bs,
    this.holidays = const <NepaliHoliday>[],
    this.selectableDates,
    this.showCalendarButton = true,
    this.presentation = NepaliCalendarPresentation.bottomSheet,
    this.height = 60,
    super.key,
  }) : assert(dayCount > 0, 'dayCount must be at least 1'),
       assert(
         endDate == null || durationDays == null,
         'Give the window an endDate or a durationDays, not both.',
       );

  /// Colours, fonts and metrics — the same type the sheet takes.
  final NepaliCalendarTheme theme;

  /// Called with the day the user picked, from the strip or the calendar.
  final ValueChanged<NepaliDate> onDateSelected;

  /// The day to render as selected.
  ///
  /// Leave it null and the strip picks one for you: today when the strip covers
  /// it, otherwise [startDate]. That day is painted as selected and reported
  /// through [onDateSelected] once, so what is on screen and what the caller
  /// holds never disagree.
  final NepaliDate? selectedDate;

  /// How many days the strip shows. Defaults to five.
  final int dayCount;

  /// The first day of the strip, and the earliest day it offers.
  final NepaliDate startDate;

  /// The last day the strip and its calendar offer, or null for no end.
  final NepaliDate? endDate;

  /// The same limit as a count of days from [startDate], including it.
  ///
  /// Only one of [endDate] and [durationDays] may be given.
  final int? durationDays;

  /// Language of the weekday names and digits.
  final Language language;

  /// Which calendar the strip counts in.
  ///
  /// The chips show that calendar only — the Bikram Sambat date under
  /// [CalendarSystem.bs], the Gregorian one under [CalendarSystem.ad].
  final CalendarSystem system;

  /// Days painted in a caller-chosen color, e.g. an organization's holidays.
  ///
  /// Applied to both the strip's chips and the full calendar opened from it.
  final List<NepaliHoliday> holidays;

  /// When given, only these days are selectable — every other day inside the
  /// strip's window is disabled too, on the chips and in the calendar its
  /// button opens alike. Null means no restriction beyond the window.
  final List<NepaliDate>? selectableDates;

  /// Whether to show the trailing button that opens the full calendar.
  final bool showCalendarButton;

  /// Where that calendar appears — a bottom sheet, or centred on the screen.
  final NepaliCalendarPresentation presentation;

  /// Height of the strip, in logical pixels.
  ///
  /// The chips size themselves to fit whatever is given, so this is the one dial
  /// for making the row denser or roomier. Defaults to 60.
  final double height;

  @override
  State<HorizontalDateStrip> createState() => _HorizontalDateStripState();
}

class _HorizontalDateStripState extends State<HorizontalDateStrip> {
  late NepaliDate _anchor = widget.startDate;

  /// Today, once it has been reported, so the default fires only on first build.
  NepaliDate? _defaultedTo;

  /// "Today" without a fresh BS conversion on every build — the strip rebuilds
  /// on every tap, and the answer changes at most once a day.
  final TodayCache _todayCache = TodayCache();

  late Map<NepaliDate, Color> _holidayColors = resolveHolidayColors(
    widget.holidays,
  );
  late Set<NepaliDate>? _selectableDateSet = toSelectableDateSet(
    widget.selectableDates,
  );

  /// The resolved start/end window, held rather than recomputed.
  ///
  /// Resolving it converts dates, and both the per-chip disabled check and the
  /// default-selection check now ask for it, so a getter would put a handful
  /// of conversions on every build.
  late NepaliDateRange _window = _resolveWindow();

  NepaliDateRange _resolveWindow() => resolveCalendarWindow(
    startDate: widget.startDate,
    endDate: widget.endDate,
    durationDays: widget.durationDays,
  );

  @override
  void initState() {
    super.initState();
    _selectDefaultIfNothingSelected();
  }

  /// Reports a starting selection when the caller has none.
  ///
  /// Today when the strip covers it — the common case, where the strip starts
  /// today — and otherwise the first day on the strip, so something is always
  /// selected and the caller holds the same value the user can see.
  ///
  /// Only ever a day the caller would actually accept: a default that ignored
  /// `endDate`/`durationDays`/`selectableDates` would hand back a date the
  /// strip is simultaneously painting as disabled, which is the one thing the
  /// "what is on screen and what the caller holds never disagree" promise
  /// above rules out. When nothing on the strip qualifies, nothing is
  /// reported — an empty selection is honest, a forbidden one is not.
  void _selectDefaultIfNothingSelected() {
    if (widget.selectedDate != null) {
      return;
    }
    final NepaliDate today = _todayCache.today;
    final int offset = widget.startDate.differenceInDays(today);
    final bool stripCoversToday = offset >= 0 && offset < widget.dayCount;
    final NepaliDate? initial = <NepaliDate>[
      if (stripCoversToday) today,
      ..._days,
    ].where(_isSelectable).firstOrNull;
    if (initial == null) {
      return;
    }
    _defaultedTo = initial;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onDateSelected(initial);
      }
    });
  }

  /// Whether [date] passes both the window and the caller's allow-list.
  bool _isSelectable(NepaliDate date) => isDaySelectable(
    date,
    startDate: _window.start,
    endDate: _window.end,
    selectableDates: _selectableDateSet,
  );

  /// What to paint as selected: the caller's value, or the day defaulted to.
  NepaliDate? get _effectiveSelection => widget.selectedDate ?? _defaultedTo;

  @override
  void didUpdateWidget(HorizontalDateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startDate != oldWidget.startDate) {
      _anchor = widget.startDate;
    }
    if (!listEquals(widget.holidays, oldWidget.holidays)) {
      _holidayColors = resolveHolidayColors(widget.holidays);
    }
    if (!listEquals(widget.selectableDates, oldWidget.selectableDates)) {
      _selectableDateSet = toSelectableDateSet(widget.selectableDates);
    }
    if (widget.startDate != oldWidget.startDate ||
        widget.endDate != oldWidget.endDate ||
        widget.durationDays != oldWidget.durationDays) {
      _window = _resolveWindow();
    }
    _reAnchorIfSelectionIsOffStrip();
  }

  /// Slides the strip so a selection made elsewhere stays visible.
  void _reAnchorIfSelectionIsOffStrip() {
    final NepaliDate? selected = _effectiveSelection;
    if (selected == null) {
      return;
    }
    final int offset = _anchor.differenceInDays(selected);
    if (offset < 0 || offset >= widget.dayCount) {
      _anchor = selected;
    }
  }

  /// The strip's days, walked directly in Bikram Sambat rather than through
  /// repeated Gregorian round-trips — this scales with [widget.dayCount] and
  /// runs on every build.
  ///
  /// Stops early rather than throwing when the walk runs off the end of the
  /// month-length table: this is reached from [build], where an exception has
  /// nowhere to go and takes the host screen down with it. A strip anchored on
  /// the last representable day renders that one day.
  List<NepaliDate> get _days {
    final List<NepaliDate> result = <NepaliDate>[];
    int year = _anchor.year;
    int month = _anchor.month;
    int day = _anchor.day;
    for (int i = 0; i < widget.dayCount; i++) {
      result.add(NepaliDate(year, month, day));
      if (i == widget.dayCount - 1) {
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
          break;
        }
      }
    }
    return result;
  }

  Future<void> _openCalendar() async {
    final NepaliDate? current = _effectiveSelection;
    final NepaliCalendarSelection? selection = await showNepaliCalendar(
      context: context,
      theme: widget.theme,
      presentation: widget.presentation,
      language: widget.language,
      initialSystem: widget.system,
      startDate: widget.startDate,
      endDate: widget.endDate,
      durationDays: widget.durationDays,
      holidays: widget.holidays,
      selectableDates: widget.selectableDates,
      initialSelection: current == null
          ? null
          : NepaliCalendarSelection.single(current),
    );
    final NepaliDate? picked = selection?.date;
    // The host route can be popped or replaced while the sheet is open, which
    // disposes this strip out from under the await.
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      final int offset = _anchor.differenceInDays(picked);
      if (offset < 0 || offset >= widget.dayCount) {
        _anchor = picked;
      }
    });
    widget.onDateSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    _reAnchorIfSelectionIsOffStrip();
    final NepaliDate today = _todayCache.today;

    return SizedBox(
      height: widget.height,
      child: Row(
        children: <Widget>[
          for (final NepaliDate day in _days)
            Expanded(
              child: _DayChip(
                date: day,
                theme: widget.theme,
                language: widget.language,
                system: widget.system,
                isSelected: day == _effectiveSelection,
                isToday: day == today,
                isDisabled: !_isSelectable(day),
                holidayColor: _holidayColors[day],
                onTap: () => widget.onDateSelected(day),
              ),
            ),
          if (widget.showCalendarButton)
            _CalendarButton(theme: widget.theme, onTap: _openCalendar),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.date,
    required this.theme,
    required this.language,
    required this.system,
    required this.isSelected,
    required this.isToday,
    required this.isDisabled,
    this.holidayColor,
    required this.onTap,
  });

  final NepaliDate date;
  final NepaliCalendarTheme theme;
  final Language language;
  final CalendarSystem system;
  final bool isSelected;
  final bool isToday;
  final bool isDisabled;
  final Color? holidayColor;
  final VoidCallback onTap;

  /// The month this day belongs to, abbreviated.
  String _monthLabel() {
    final int month = system == CalendarSystem.bs
        ? date.month
        : date.toDateTime().month;
    return CalendarStrings.monthNameShort(month, system, language);
  }

  Color _secondaryColor() => isSelected
      ? theme.selectedDayTextColor.withValues(alpha: 0.85)
      : isDisabled
      ? theme.disabledDayColor
      : holidayColor != null
      ? holidayColor!
      : date.isSaturday
      ? theme.weekendColor
      : theme.weekdayHeaderColor;

  @override
  Widget build(BuildContext context) {
    final int dayNumber = system == CalendarSystem.bs
        ? date.day
        : date.toDateTime().day;
    final Color foreground = isSelected
        ? theme.selectedDayTextColor
        : isDisabled
        ? theme.disabledDayColor
        : holidayColor != null
        ? holidayColor!
        : date.isSaturday
        ? theme.weekendColor
        : theme.textColor;

    return Semantics(
      button: !isDisabled,
      selected: isSelected,
      label: date.format('EEEE, d MMMM yyyy', language: language),
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.all(theme.cellSpacing),
        child: Material(
          color: isSelected ? theme.selectedDayColor : Colors.transparent,
          borderRadius: BorderRadius.circular(theme.borderRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isDisabled ? null : onTap,
            // Scaled rather than fixed, so any height the caller asks for
            // lays out instead of overflowing.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // "Today" earns the caption on today's chip; every other day
                  // shows which month it belongs to, which is what changes as
                  // the strip crosses a month boundary.
                  _Caption(
                    text: isToday
                        ? CalendarStrings.today(language)
                        : _monthLabel(),
                    color: _secondaryColor(),
                    style: theme.resolvedWeekdayHeaderTextStyle,
                    scale: 0.78,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    NepaliNumerals.format(dayNumber, language),
                    maxLines: 1,
                    style: theme.resolvedDayTextStyle.copyWith(
                      color: foreground,
                      fontSize: (theme.resolvedDayTextStyle.fontSize ?? 15),
                      fontWeight: isSelected ? FontWeight.w700 : null,
                    ),
                  ),
                  const SizedBox(height: 1),
                  _Caption(
                    text: CalendarStrings.weekdayName(
                      date.weekdayIndex,
                      language,
                      short: true,
                    ),
                    color: _secondaryColor(),
                    style: theme.resolvedWeekdayHeaderTextStyle,
                    scale: 0.78,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One of the two small lines above and below the date.
class _Caption extends StatelessWidget {
  const _Caption({
    required this.text,
    required this.color,
    required this.style,
    required this.scale,
  });

  final String text;
  final Color color;
  final TextStyle style;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: style.copyWith(
        color: color,
        fontSize: (style.fontSize ?? 12) * scale,
      ),
    );
  }
}

class _CalendarButton extends StatelessWidget {
  const _CalendarButton({required this.theme, required this.onTap});

  final NepaliCalendarTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(theme.cellSpacing),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(theme.borderRadius),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Icon(
              Icons.calendar_month_outlined,
              size: 19,
              color: theme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
