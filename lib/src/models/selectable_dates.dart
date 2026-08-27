/// A caller-defined group of pickable days and the color that marks them.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../converters/date_conversion_exception.dart';
import 'nepali_date.dart';

/// One entry in the list a caller passes as `selectableDates`: the days that
/// may be picked, and — optionally — the color those days are marked in.
///
/// ```dart
/// selectableDates: <SelectableDates>[
///   const SelectableDates(
///     dates: <NepaliDate>[NepaliDate(2082, 5, 3), NepaliDate(2082, 5, 4)],
///     color: Color(0xFFC1272D),
///   ),
///   SelectableDates.fromDateTimes(
///     dates: <DateTime>[DateTime(2025, 8, 25)],
///     color: const Color(0xFF2F9E44),
///   ),
/// ]
/// ```
///
/// Days can be given in either calendar. The default constructor takes Bikram
/// Sambat [NepaliDate]s; [SelectableDates.fromDateTimes] takes Gregorian
/// `DateTime`s and converts them. Both end up as the same BS days internally,
/// so a group built either way highlights correctly whether the calendar is
/// showing BS or AD — including across a live switch between the two.
///
/// A group's [color], when given, marks its days: a bright border in [color]
/// with a light wash of it behind the number, so an available day reads as
/// available at a glance. A group with no [color] restricts what can be picked
/// without changing how those days look.
///
/// Selection always wins over the mark. The moment the user taps one of these
/// days it is painted in the theme's selected color like any other pick, so
/// "what is selected" is never ambiguous.
@immutable
class SelectableDates {
  /// Creates a group of selectable Bikram Sambat days, optionally marked in
  /// [color].
  const SelectableDates({required this.dates, this.color});

  /// Creates a group from Gregorian [dates], converted to Bikram Sambat.
  ///
  /// For callers holding `DateTime`s — appointment slots out of a backend,
  /// say — so the list does not have to be converted by hand. Any time
  /// component is discarded; only the calendar day matters.
  ///
  /// Throws a [DateConversionException] when a date falls outside the range
  /// the package supports (AD 1913–2143).
  factory SelectableDates.fromDateTimes({
    required List<DateTime> dates,
    Color? color,
  }) => SelectableDates(
    dates: dates.map(NepaliDate.fromDateTime).toList(growable: false),
    color: color,
  );

  /// The days this group makes selectable.
  final List<NepaliDate> dates;

  /// The color [dates] are marked in, or null to leave them looking ordinary.
  ///
  /// Drawn as a bright border around the day with a light fill of the same
  /// color behind it. Never drawn on a day the window already disabled, and
  /// always given up to the theme's selected color once the day is picked.
  final Color? color;

  @override
  String toString() =>
      'SelectableDates(${dates.length} date(s)'
      '${color == null ? '' : ', $color'})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SelectableDates &&
          other.color == color &&
          listEquals(other.dates, dates));

  @override
  int get hashCode => Object.hash(color, Object.hashAll(dates));
}
