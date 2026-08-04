/// Flattens the caller's holiday list into a per-date color lookup.
library;

import 'package:flutter/material.dart';

import '../models/nepali_date.dart';
import '../models/nepali_holiday.dart';

/// Builds a `date -> color` map from [holidays].
///
/// When two holidays share a date, the one that appears later in [holidays]
/// wins. Internal: computed once per build and passed down so day cells do a
/// single map lookup instead of scanning the whole list.
Map<NepaliDate, Color> resolveHolidayColors(List<NepaliHoliday> holidays) {
  final Map<NepaliDate, Color> lookup = <NepaliDate, Color>{};
  for (final NepaliHoliday holiday in holidays) {
    for (final NepaliDate date in holiday.dates) {
      lookup[date] = holiday.color;
    }
  }
  return lookup;
}
