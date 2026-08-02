/// Visual configuration for the calendar widget.
library;

import 'package:flutter/material.dart';

/// Colors, typography and metrics used to paint the calendar.
///
/// Every field has a sensible default, so `const NepaliCalendarTheme()` already
/// looks right and the widget works with zero configuration. Pass only the
/// fields you want to override:
///
/// ```dart
/// NepaliCalendar(
///   theme: const NepaliCalendarTheme(
///     primaryColor: Color(0xFF0B7285),
///     selectedDayColor: Color(0xFFE8590C),
///   ),
/// )
/// ```
///
/// To match the host app automatically, use [NepaliCalendarTheme.fromTheme],
/// which derives every color from the ambient Material [ColorScheme].
@immutable
class NepaliCalendarTheme {
  /// Creates a theme; every parameter is optional.
  const NepaliCalendarTheme({
    this.primaryColor = const Color(0xFFC1272D),
    this.selectedDayColor = const Color(0xFF003893),
    this.selectedDayTextColor = Colors.white,
    this.todayHighlightColor = const Color(0xFF2F9E44),
    this.weekendColor = const Color(0xFFC1272D),
    this.textColor = const Color(0xFF1D2939),
    this.subtitleTextColor = const Color(0xFF98A2B3),
    this.headerTextColor = Colors.white,
    this.backgroundColor = Colors.white,
    this.disabledDayColor = const Color(0xFFD0D5DD),
    this.weekdayHeaderColor = const Color(0xFF667085),
    this.weekdayHeaderBackgroundColor = const Color(0xFFF9FAFB),
    this.dividerColor = const Color(0xFFEAECF0),
    this.rangeFillColor,
    this.switchActiveColor,
    this.switchInactiveColor = const Color(0x33FFFFFF),
    this.fontFamily,
    this.fontPackage,
    this.headerTextStyle,
    this.dayTextStyle,
    this.weekdayHeaderTextStyle,
    this.borderRadius = 12,
    this.dayCellShape = BoxShape.circle,
    this.cellSpacing = 2,
    this.showGridDividers = false,
  });

  /// Derives a theme from the ambient Material [ThemeData].
  ///
  /// Useful when the calendar should follow the host app's color scheme —
  /// including its light/dark mode — without hand-picking colors.
  factory NepaliCalendarTheme.fromTheme(ThemeData theme) {
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = scheme.brightness == Brightness.dark;
    return NepaliCalendarTheme(
      primaryColor: scheme.primary,
      selectedDayColor: scheme.primary,
      selectedDayTextColor: scheme.onPrimary,
      todayHighlightColor: scheme.tertiary,
      weekendColor: scheme.error,
      textColor: scheme.onSurface,
      subtitleTextColor: scheme.onSurfaceVariant.withValues(alpha: 0.7),
      headerTextColor: scheme.onPrimary,
      backgroundColor: scheme.surface,
      disabledDayColor: scheme.onSurface.withValues(alpha: 0.28),
      weekdayHeaderColor: scheme.onSurfaceVariant,
      weekdayHeaderBackgroundColor: isDark
          ? scheme.surfaceContainerHighest.withValues(alpha: 0.4)
          : scheme.surfaceContainerHighest,
      dividerColor: scheme.outlineVariant,
      fontFamily: theme.textTheme.bodyMedium?.fontFamily,
    );
  }

  /// A dark-friendly preset.
  factory NepaliCalendarTheme.dark() => const NepaliCalendarTheme(
    primaryColor: Color(0xFF1F2937),
    selectedDayColor: Color(0xFF4C8DFF),
    todayHighlightColor: Color(0xFF51CF66),
    weekendColor: Color(0xFFFF8787),
    textColor: Color(0xFFE5E7EB),
    subtitleTextColor: Color(0xFF6B7280),
    backgroundColor: Color(0xFF111827),
    disabledDayColor: Color(0xFF4B5563),
    weekdayHeaderColor: Color(0xFF9CA3AF),
    weekdayHeaderBackgroundColor: Color(0xFF1B2432),
    dividerColor: Color(0xFF374151),
  );

  /// Header background and the active state of the BS/AD switch.
  final Color primaryColor;

  /// Background of the currently selected day cell.
  final Color selectedDayColor;

  /// Text color inside the selected day cell.
  final Color selectedDayTextColor;

  /// Ring (and text, when unselected) marking today.
  final Color todayHighlightColor;

  /// Color applied to Saturdays — the Nepali weekend.
  final Color weekendColor;

  /// Default day-number color.
  final Color textColor;

  /// Color of the smaller secondary date shown inside each cell.
  final Color subtitleTextColor;

  /// Text and icon color used on top of [primaryColor] in the header.
  final Color headerTextColor;

  /// Background of the whole calendar surface.
  final Color backgroundColor;

  /// Color for days outside `startDate`/`endDate` or outside the shown month.
  final Color disabledDayColor;

  /// Text color of the Sun..Sat row.
  final Color weekdayHeaderColor;

  /// Background of the Sun..Sat row.
  final Color weekdayHeaderBackgroundColor;

  /// Color of the hairlines drawn when [showGridDividers] is `true`.
  final Color dividerColor;

  /// Fill behind the days between a range's start and end.
  ///
  /// Defaults to [selectedDayColor] at 14% opacity, which reads as a tint of the
  /// selection colour without competing with it.
  final Color? rangeFillColor;

  /// Background of the selected segment of the BS/AD switch.
  ///
  /// Defaults to [backgroundColor] when null.
  final Color? switchActiveColor;

  /// Background of the unselected segment of the BS/AD switch.
  final Color switchInactiveColor;

  /// Font family applied to every text element in the calendar.
  ///
  /// Both Android and iOS ship a Devanagari-capable system font, so Nepali text
  /// renders correctly with `null`. Set this when the host app bundles its own
  /// Devanagari font (e.g. `'Mukta'`) and the calendar should match it. If the
  /// font lives in another package, also set [fontPackage].
  final String? fontFamily;

  /// The package that [fontFamily] is declared in, if it is not the host app.
  ///
  /// Leave `null` when the font is declared in the app's own `pubspec.yaml`.
  final String? fontPackage;

  /// Overrides the month/year title style in the header.
  final TextStyle? headerTextStyle;

  /// Overrides the day-number style in each cell.
  final TextStyle? dayTextStyle;

  /// Overrides the Sun..Sat row style.
  final TextStyle? weekdayHeaderTextStyle;

  /// Corner radius of the calendar surface and the switch.
  final double borderRadius;

  /// Whether the selection/today decoration is a circle or a rounded square.
  final BoxShape dayCellShape;

  /// Gap between day cells, in logical pixels.
  final double cellSpacing;

  /// Whether to draw hairlines between grid cells.
  final bool showGridDividers;

  /// Applies [fontFamily]/[fontPackage] to [style] unless it names its own font.
  ///
  /// The package prefix is only attached when a family is actually present,
  /// because `package` without `fontFamily` is meaningless.
  TextStyle applyFont(TextStyle style) {
    if (style.fontFamily != null || fontFamily == null) {
      return style;
    }
    return style.copyWith(fontFamily: fontFamily, package: fontPackage);
  }

  /// The base text style for this theme, with the theme font applied.
  TextStyle get baseTextStyle => applyFont(TextStyle(color: textColor));

  /// The resolved style for the header title.
  TextStyle get resolvedHeaderTextStyle => applyFont(
    const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
    ).copyWith(color: headerTextColor).merge(headerTextStyle),
  );

  /// The resolved style for the Sun..Sat row.
  TextStyle get resolvedWeekdayHeaderTextStyle => applyFont(
    const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ).merge(weekdayHeaderTextStyle),
  );

  /// The resolved style for a day number.
  TextStyle get resolvedDayTextStyle => applyFont(
    const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ).merge(dayTextStyle),
  );

  /// A copy of this theme with the given fields replaced.
  NepaliCalendarTheme copyWith({
    Color? primaryColor,
    Color? selectedDayColor,
    Color? selectedDayTextColor,
    Color? todayHighlightColor,
    Color? weekendColor,
    Color? textColor,
    Color? subtitleTextColor,
    Color? headerTextColor,
    Color? backgroundColor,
    Color? disabledDayColor,
    Color? weekdayHeaderColor,
    Color? weekdayHeaderBackgroundColor,
    Color? dividerColor,
    Color? rangeFillColor,
    Color? switchActiveColor,
    Color? switchInactiveColor,
    String? fontFamily,
    String? fontPackage,
    TextStyle? headerTextStyle,
    TextStyle? dayTextStyle,
    TextStyle? weekdayHeaderTextStyle,
    double? borderRadius,
    BoxShape? dayCellShape,
    double? cellSpacing,
    bool? showGridDividers,
  }) {
    return NepaliCalendarTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      selectedDayColor: selectedDayColor ?? this.selectedDayColor,
      selectedDayTextColor: selectedDayTextColor ?? this.selectedDayTextColor,
      todayHighlightColor: todayHighlightColor ?? this.todayHighlightColor,
      weekendColor: weekendColor ?? this.weekendColor,
      textColor: textColor ?? this.textColor,
      subtitleTextColor: subtitleTextColor ?? this.subtitleTextColor,
      headerTextColor: headerTextColor ?? this.headerTextColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      disabledDayColor: disabledDayColor ?? this.disabledDayColor,
      weekdayHeaderColor: weekdayHeaderColor ?? this.weekdayHeaderColor,
      weekdayHeaderBackgroundColor:
          weekdayHeaderBackgroundColor ?? this.weekdayHeaderBackgroundColor,
      dividerColor: dividerColor ?? this.dividerColor,
      rangeFillColor: rangeFillColor ?? this.rangeFillColor,
      switchActiveColor: switchActiveColor ?? this.switchActiveColor,
      switchInactiveColor: switchInactiveColor ?? this.switchInactiveColor,
      fontFamily: fontFamily ?? this.fontFamily,
      fontPackage: fontPackage ?? this.fontPackage,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      dayTextStyle: dayTextStyle ?? this.dayTextStyle,
      weekdayHeaderTextStyle:
          weekdayHeaderTextStyle ?? this.weekdayHeaderTextStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      dayCellShape: dayCellShape ?? this.dayCellShape,
      cellSpacing: cellSpacing ?? this.cellSpacing,
      showGridDividers: showGridDividers ?? this.showGridDividers,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NepaliCalendarTheme &&
      other.primaryColor == primaryColor &&
      other.selectedDayColor == selectedDayColor &&
      other.selectedDayTextColor == selectedDayTextColor &&
      other.todayHighlightColor == todayHighlightColor &&
      other.weekendColor == weekendColor &&
      other.textColor == textColor &&
      other.subtitleTextColor == subtitleTextColor &&
      other.headerTextColor == headerTextColor &&
      other.backgroundColor == backgroundColor &&
      other.disabledDayColor == disabledDayColor &&
      other.weekdayHeaderColor == weekdayHeaderColor &&
      other.weekdayHeaderBackgroundColor == weekdayHeaderBackgroundColor &&
      other.dividerColor == dividerColor &&
      other.rangeFillColor == rangeFillColor &&
      other.switchActiveColor == switchActiveColor &&
      other.switchInactiveColor == switchInactiveColor &&
      other.fontFamily == fontFamily &&
      other.fontPackage == fontPackage &&
      other.headerTextStyle == headerTextStyle &&
      other.dayTextStyle == dayTextStyle &&
      other.weekdayHeaderTextStyle == weekdayHeaderTextStyle &&
      other.borderRadius == borderRadius &&
      other.dayCellShape == dayCellShape &&
      other.cellSpacing == cellSpacing &&
      other.showGridDividers == showGridDividers;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    primaryColor,
    selectedDayColor,
    selectedDayTextColor,
    todayHighlightColor,
    weekendColor,
    textColor,
    subtitleTextColor,
    headerTextColor,
    backgroundColor,
    disabledDayColor,
    weekdayHeaderColor,
    weekdayHeaderBackgroundColor,
    dividerColor,
    rangeFillColor,
    switchActiveColor,
    switchInactiveColor,
    fontFamily,
    fontPackage,
    headerTextStyle,
    dayTextStyle,
    weekdayHeaderTextStyle,
    borderRadius,
    dayCellShape,
    cellSpacing,
    showGridDividers,
  ]);
}
