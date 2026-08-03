/// The month view rendered inside the sheet.
library;

import 'package:flutter/material.dart';

import '../converters/date_converter.dart';
import '../data/bs_calendar_data.dart';
import '../localization/calendar_strings.dart';
import '../models/nepali_date.dart';
import '../models/nepali_date_range.dart';
import '../theme/nepali_calendar_theme.dart';
import 'calendar_controller.dart';
import 'calendar_header.dart';
import 'day_cell.dart';
import 'month_grid.dart';

/// A swipeable month grid driven by a [CalendarController].
///
/// Internal to the package: `showNepaliCalendar` builds one of these inside the
/// bottom sheet. Six week rows are always drawn so the height never changes
/// while swiping between months.
class CalendarView extends StatefulWidget {
  /// Creates the month view.
  const CalendarView({
    required this.controller,
    required this.theme,
    this.allowedRange,
    this.showSystemSwitch = true,
    this.showAlternateDate = true,
    this.rowHeight = 48,
    super.key,
  });

  /// Selection, visible month, system and language.
  final CalendarController controller;

  /// Colors, fonts and metrics.
  final NepaliCalendarTheme theme;

  /// The window the calendar offers, or null for the whole supported range.
  final NepaliDateRange? allowedRange;

  /// Whether the BS/AD switch is shown in the header.
  final bool showSystemSwitch;

  /// Whether each cell shows the other calendar's day number underneath.
  final bool showAlternateDate;

  /// Height of one week row, in logical pixels.
  final double rowHeight;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  static const int _weekRows = 6;

  late PageController _pageController;
  late _MonthPager _pager;
  late CalendarSystem _system;
  late final NepaliDate _today = DateConverter.todayBs();

  @override
  void initState() {
    super.initState();
    _system = widget.controller.system;
    _pager = _buildPager();
    _pageController = PageController(
      initialPage: _pager.pageOf(widget.controller.focusedDate),
    );
    widget.controller.addListener(_handleControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerUpdate);
    _pageController.dispose();
    super.dispose();
  }

  void _handleControllerUpdate() {
    if (!mounted) {
      return;
    }
    final CalendarSystem system = widget.controller.system;
    final bool systemChanged = system != _system;
    setState(() {
      _system = system;
      if (systemChanged) {
        // Page indices mean different months in each system, so the pager and
        // its controller are rebuilt around the month currently in view.
        _pager = _buildPager();
        final PageController old = _pageController;
        _pageController = PageController(
          initialPage: _pager.pageOf(widget.controller.focusedDate),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      }
    });
    if (!systemChanged) {
      _syncPageToFocusedMonth();
    }
  }

  _MonthPager _buildPager() => _MonthPager(
    system: _system,
    startDate: widget.allowedRange?.start,
    endDate: widget.allowedRange?.end,
  );

  void _syncPageToFocusedMonth() {
    if (!_pageController.hasClients) {
      return;
    }
    final int target = _pager.pageOf(widget.controller.focusedDate);
    if (_pageController.page?.round() == target) {
      return;
    }
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _movePage(int delta) {
    if (!_pageController.hasClients) {
      return;
    }
    final int target = (_pageController.page?.round() ?? 0) + delta;
    if (target < 0 || target >= _pager.pageCount) {
      return;
    }
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  String _title(_MonthRef ref) =>
      '${CalendarStrings.monthName(ref.month, _system, widget.controller.language)} '
      '${NepaliNumerals.format(ref.year, widget.controller.language)}';

  /// The visible month expressed in the other calendar, e.g. `Apr / May 2024`.
  String _subtitle(_MonthRef ref) {
    final Language language = widget.controller.language;
    final CalendarSystem other = _system.opposite;
    final _MonthRef start;
    final _MonthRef end;

    if (_system == CalendarSystem.bs) {
      final DateTime first = DateConverter.bsPartsToAd(ref.year, ref.month, 1);
      final DateTime last = DateConverter.bsPartsToAd(
        ref.year,
        ref.month,
        BsCalendarData.daysInMonth(ref.year, ref.month),
      );
      start = _MonthRef(first.year, first.month);
      end = _MonthRef(last.year, last.month);
    } else {
      final NepaliDate first = _bsWithinRange(DateTime(ref.year, ref.month, 1));
      final NepaliDate last = _bsWithinRange(
        DateTime(ref.year, ref.month + 1, 0),
      );
      start = _MonthRef(first.year, first.month);
      end = _MonthRef(last.year, last.month);
    }

    final String startName = CalendarStrings.monthName(
      start.month,
      other,
      language,
    );
    final String endName = CalendarStrings.monthName(
      end.month,
      other,
      language,
    );
    final String startYear = NepaliNumerals.format(start.year, language);
    final String suffix = other.label(language);

    if (start == end) {
      return '$startName $startYear $suffix';
    }
    if (start.year == end.year) {
      return '$startName / $endName $startYear $suffix';
    }
    return '$startName $startYear / $endName '
        '${NepaliNumerals.format(end.year, language)} $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final CalendarController controller = widget.controller;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListenableBuilder(
          listenable: _pageController,
          builder: (BuildContext context, Widget? child) {
            final int page = _pageController.hasClients
                ? (_pageController.page?.round() ?? _pageController.initialPage)
                : _pageController.initialPage;
            final _MonthRef ref = _pager.monthRefOf(page);
            return CalendarHeader(
              title: _title(ref),
              subtitle: _subtitle(ref),
              system: _system,
              language: controller.language,
              theme: widget.theme,
              canGoPrevious: page > 0,
              canGoNext: page < _pager.pageCount - 1,
              onPrevious: () => _movePage(-1),
              onNext: () => _movePage(1),
              onSystemChanged: controller.setSystem,
              onToday: () {
                if (_pager.contains(DateConverter.todayBs())) {
                  controller.goToToday();
                }
              },
              showSystemSwitch: widget.showSystemSwitch,
            );
          },
        ),
        WeekdayHeaderRow(language: controller.language, theme: widget.theme),
        SizedBox(
          height: widget.rowHeight * _weekRows,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pager.pageCount,
            onPageChanged: (int page) =>
                controller.showMonthOf(_pager.monthStartOf(page)),
            itemBuilder: (BuildContext context, int page) {
              final _MonthRef ref = _pager.monthRefOf(page);
              return MonthGrid(
                days: buildMonthDays(
                  year: ref.year,
                  month: ref.month,
                  system: _system,
                  today: _today,
                  weekCount: _weekRows,
                  selectedDate: controller.selectedDate,
                  rangeStart: controller.rangeStart,
                  rangeEnd: controller.rangeEnd,
                  startDate: widget.allowedRange?.start,
                  endDate: widget.allowedRange?.end,
                ),
                system: _system,
                language: controller.language,
                theme: widget.theme,
                rowHeight: widget.rowHeight,
                showAlternateDate: widget.showAlternateDate,
                onDayTapped: (CalendarDay day) =>
                    controller.tapDate(day.bsDate),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Converts [ad] to Bikram Sambat, clamped into the supported range.
///
/// A Gregorian month at either edge of the range reaches past what the BS table
/// covers — April 1913 opens twelve days before 1 Baishakh 1970 — so the month's
/// own first day is not always convertible. Clamping keeps the header and the
/// pager working there instead of throwing mid-build.
NepaliDate _bsWithinRange(DateTime ad) {
  if (ad.isBefore(DateConverter.minAdDate)) {
    return NepaliDate.min;
  }
  if (ad.isAfter(DateConverter.maxAdDate)) {
    return NepaliDate.max;
  }
  return DateConverter.adToBs(ad);
}

/// A year/month pair in whichever calendar system is active.
@immutable
class _MonthRef {
  const _MonthRef(this.year, this.month);

  final int year;
  final int month;

  @override
  bool operator ==(Object other) =>
      other is _MonthRef && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

/// Maps [PageView] indices to calendar months for the active system.
///
/// Months are numbered continuously as `year * 12 + (month - 1)`, so page
/// arithmetic is plain integer arithmetic. The first and last page come from the
/// intersection of the caller's bounds with the range the BS table can represent.
class _MonthPager {
  _MonthPager({
    required this.system,
    required NepaliDate? startDate,
    required NepaliDate? endDate,
  }) {
    // Whatever the caller asked for, intersected with what the BS table covers.
    final NepaliDate low = startDate == null || startDate < NepaliDate.min
        ? NepaliDate.min
        : startDate;
    final NepaliDate high = endDate == null || endDate > NepaliDate.max
        ? NepaliDate.max
        : endDate;
    if (system == CalendarSystem.bs) {
      _first = low.year * 12 + (low.month - 1);
      _last = high.year * 12 + (high.month - 1);
    } else {
      final DateTime lowAd = low.toDateTime();
      final DateTime highAd = high.toDateTime();
      _first = lowAd.year * 12 + (lowAd.month - 1);
      _last = highAd.year * 12 + (highAd.month - 1);
    }
  }

  final CalendarSystem system;
  late final int _first;
  late final int _last;

  /// Number of swipeable pages.
  int get pageCount => _last - _first + 1;

  /// The page showing the month of [date], clamped into range.
  int pageOf(NepaliDate date) =>
      _monthIndexOf(date).clamp(_first, _last) - _first;

  /// Whether the month of [date] is reachable.
  bool contains(NepaliDate date) {
    final int index = _monthIndexOf(date);
    return index >= _first && index <= _last;
  }

  /// The active-system year/month shown on [page].
  _MonthRef monthRefOf(int page) {
    final int index = (_first + page).clamp(_first, _last);
    return _MonthRef(index ~/ 12, index % 12 + 1);
  }

  /// The first day of the month shown on [page], in Bikram Sambat.
  NepaliDate monthStartOf(int page) {
    final _MonthRef ref = monthRefOf(page);
    return system == CalendarSystem.bs
        ? NepaliDate(ref.year, ref.month, 1)
        : _bsWithinRange(DateTime(ref.year, ref.month, 1));
  }

  int _monthIndexOf(NepaliDate date) {
    if (system == CalendarSystem.bs) {
      return date.year * 12 + (date.month - 1);
    }
    final DateTime ad = date.toDateTime();
    return ad.year * 12 + (ad.month - 1);
  }
}
