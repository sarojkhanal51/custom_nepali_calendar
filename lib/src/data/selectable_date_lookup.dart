/// Flattens the caller's selectable-date groups into the two things the
/// widgets actually ask for: what may be picked, and what color it is marked in.
library;

import 'package:flutter/material.dart';

import '../models/nepali_date.dart';
import '../models/selectable_dates.dart';

/// The resolved form of a `selectableDates` list.
///
/// Internal: computed once per build and passed down, so a day cell does two
/// map/set lookups instead of scanning every group.
@immutable
class SelectableDateLookup {
  /// Wraps an already-computed allow-list and color map.
  const SelectableDateLookup({required this.allowed, required this.colors});

  /// No restriction and no marks — what a `null` list resolves to.
  static const SelectableDateLookup unrestricted = SelectableDateLookup(
    allowed: null,
    colors: <NepaliDate, Color>{},
  );

  /// The days that may be picked, or null when the caller placed no
  /// restriction beyond the window.
  final Set<NepaliDate>? allowed;

  /// The color each marked day is drawn in. Days from a group with no color
  /// are absent, which is what leaves them looking ordinary.
  final Map<NepaliDate, Color> colors;
}

/// Resolves [groups] into an allow-list and a `date -> color` map.
///
/// A `null` list means "no restriction beyond the window" and marks nothing.
///
/// An empty list is deliberately **not** treated the same as `null`: it
/// resolves to an empty allow-list, so every day is disabled. A caller who
/// computes groups from something that turned out empty (e.g. no slots
/// available) gets that reflected honestly, rather than silently falling back
/// to "everything is selectable."
///
/// When two groups share a date, the one that appears later in [groups] wins
/// its color — the same last-one-wins rule holidays use. A date listed in a
/// colored group and an uncolored one keeps whichever came last, so the two
/// orderings say different things rather than one silently outranking the
/// other.
SelectableDateLookup resolveSelectableDates(List<SelectableDates>? groups) {
  if (groups == null) {
    return SelectableDateLookup.unrestricted;
  }
  final Set<NepaliDate> allowed = <NepaliDate>{};
  final Map<NepaliDate, Color> colors = <NepaliDate, Color>{};
  for (final SelectableDates group in groups) {
    for (final NepaliDate date in group.dates) {
      allowed.add(date);
      if (group.color == null) {
        colors.remove(date);
      } else {
        colors[date] = group.color!;
      }
    }
  }
  return SelectableDateLookup(allowed: allowed, colors: colors);
}
