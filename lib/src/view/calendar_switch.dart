/// The BS/AD toggle shown in the header.
library;

import 'package:flutter/material.dart';

import '../localization/calendar_strings.dart';
import '../theme/nepali_calendar_theme.dart';

/// A two-segment toggle between the Bikram Sambat and Gregorian calendars.
///
/// Purely presentational: it reports the requested system through [onChanged]
/// and the parent decides what to do with it.
class CalendarSwitch extends StatelessWidget {
  /// Creates a BS/AD toggle.
  const CalendarSwitch({
    required this.system,
    required this.language,
    required this.theme,
    required this.onChanged,
    super.key,
  });

  /// The currently active calendar system.
  final CalendarSystem system;

  /// Language used for the segment labels.
  final Language language;

  /// Colors and metrics.
  final NepaliCalendarTheme theme;

  /// Called with the newly requested system.
  final ValueChanged<CalendarSystem> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.switchInactiveColor,
        borderRadius: BorderRadius.circular(theme.borderRadius),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final CalendarSystem option in CalendarSystem.values)
            _Segment(
              label: option.label(language),
              isActive: option == system,
              theme: theme,
              onTap: () => onChanged(option),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isActive,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final NepaliCalendarTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The switch sits on the header, and the active label is painted in
    // primaryColor — so the pill behind it has to contrast with the header, not
    // with the sheet body. headerTextColor is the colour already chosen to be
    // legible there, which keeps the pair readable in light and dark alike.
    final Color activeBackground =
        theme.switchActiveColor ?? theme.headerTextColor;
    return Semantics(
      button: true,
      selected: isActive,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? activeBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(theme.borderRadius),
          ),
          child: Text(
            label,
            style: theme.applyFont(
              TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? theme.primaryColor : theme.headerTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
