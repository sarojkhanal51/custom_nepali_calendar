/// Turns a caller-supplied date allow-list into a fast membership check.
library;

import '../models/nepali_date.dart';

/// Converts [dates] to a [Set] for O(1) membership checks per cell, or
/// `null` when [dates] itself is `null` — meaning no restriction beyond the
/// window (`startDate`/`endDate`).
///
/// An empty list is deliberately **not** treated the same as `null`: it
/// becomes an empty set, so every day is disabled. A caller who computes an
/// allow-list from something that turned out empty (e.g. no slots available)
/// gets that reflected honestly, rather than silently falling back to
/// "everything is selectable."
Set<NepaliDate>? toSelectableDateSet(List<NepaliDate>? dates) =>
    dates == null ? null : Set<NepaliDate>.of(dates);
