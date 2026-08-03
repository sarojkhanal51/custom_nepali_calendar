/// The header above the grid: month title, arrows and the BS/AD switch.
library;

import 'package:flutter/material.dart';

import '../localization/calendar_strings.dart';
import '../theme/nepali_calendar_theme.dart';
import 'calendar_switch.dart';

/// Month title, navigation arrows, and the optional switches.
class CalendarHeader extends StatelessWidget {
  /// Creates the header.
  const CalendarHeader({
    required this.title,
    required this.subtitle,
    required this.system,
    required this.language,
    required this.theme,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onSystemChanged,
    required this.onToday,
    required this.showSystemSwitch,
    super.key,
  });

  /// The month and year on screen, e.g. `Baishakh 2081` or `बैशाख २०८१`.
  final String title;

  /// The same month in the other calendar, e.g. `April / May 2024 AD`.
  final String subtitle;

  /// The active calendar system.
  final CalendarSystem system;

  /// The active language.
  final Language language;

  /// Colors and metrics.
  final NepaliCalendarTheme theme;

  /// Whether an earlier month is reachable.
  final bool canGoPrevious;

  /// Whether a later month is reachable.
  final bool canGoNext;

  /// Moves to the previous month.
  final VoidCallback onPrevious;

  /// Moves to the next month.
  final VoidCallback onNext;

  /// Switches the calendar system.
  final ValueChanged<CalendarSystem> onSystemChanged;

  /// Jumps to today and selects it.
  final VoidCallback onToday;

  /// Whether the BS/AD switch is visible.
  final bool showSystemSwitch;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.primaryColor,
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              _NavButton(
                icon: Icons.chevron_left_rounded,
                tooltip: CalendarStrings.previousMonth(language),
                color: theme.headerTextColor,
                onPressed: canGoPrevious ? onPrevious : null,
              ),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.resolvedHeaderTextStyle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: theme.applyFont(
                        TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.headerTextColor.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _NavButton(
                icon: Icons.chevron_right_rounded,
                tooltip: CalendarStrings.nextMonth(language),
                color: theme.headerTextColor,
                onPressed: canGoNext ? onNext : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            // A Wrap rather than a Row: on a narrow phone the Nepali labels
            // ("वि.सं.", "आज") are wide enough that one line could overflow, so
            // the controls move onto a second line instead. With the BS/AD
            // switch hidden there is nothing to space against, so Today is
            // pinned to the trailing edge rather than sliding to the leading one.
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: showSystemSwitch
                  ? WrapAlignment.spaceBetween
                  : WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                if (showSystemSwitch)
                  CalendarSwitch(
                    system: system,
                    language: language,
                    theme: theme,
                    onChanged: onSystemChanged,
                  ),
                _TodayButton(
                  label: CalendarStrings.today(language),
                  theme: theme,
                  onPressed: onToday,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 28),
      color: color,
      disabledColor: color.withValues(alpha: 0.3),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _TodayButton extends StatelessWidget {
  const _TodayButton({
    required this.label,
    required this.theme,
    required this.onPressed,
  });

  final String label;
  final NepaliCalendarTheme theme;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(theme.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(theme.borderRadius),
          border: Border.all(
            color: theme.headerTextColor.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: theme.applyFont(
            TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.headerTextColor,
            ),
          ),
        ),
      ),
    );
  }
}
