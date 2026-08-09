/// A caller-defined holiday: what kind it is, which days it falls on, and the
/// color it should paint those days.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'nepali_date.dart';

/// One entry in the list an organization passes in to mark its holidays.
///
/// ```dart
/// const NepaliHoliday(
///   type: 'Public',
///   dates: <NepaliDate>[NepaliDate(2082, 1, 1)],
///   color: Color(0xFFC1272D),
/// )
/// ```
///
/// [type] is free-form — the package does not interpret it, so any scheme an
/// organization already uses (`'Public'`, `'Optional'`, `'Festival'`, ...) can
/// be passed straight through. Only [color] affects what is drawn: the day
/// number is painted in [color] wherever [dates] lands in the visible window.
@immutable
class NepaliHoliday {
  /// Creates a holiday entry.
  const NepaliHoliday({
    required this.type,
    required this.dates,
    required this.color,
  });

  /// The kind of holiday this is, e.g. `'Public'` or `'Festival'`.
  ///
  /// Not shown by the calendar; carried through purely for the caller's own
  /// bookkeeping.
  final String type;

  /// The days this holiday falls on.
  final List<NepaliDate> dates;

  /// The color used to paint [dates] in the calendar.
  final Color color;

  @override
  String toString() => 'NepaliHoliday($type, ${dates.length} date(s))';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NepaliHoliday &&
          other.type == type &&
          other.color == color &&
          listEquals(other.dates, dates));

  @override
  int get hashCode => Object.hash(type, color, Object.hashAll(dates));
}
