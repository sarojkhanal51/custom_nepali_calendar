// A Nepali fiscal-year helper for showNepaliCalendar / HorizontalDateStrip.
//
// Not part of the custom_nepali_calendar package — this is plain Dart built
// entirely on its public API (NepaliDate's comparisons, lastDayOfMonth, and
// NepaliDate.now()). Copy it into your own app.
//
// The Nepali fiscal year runs 1 Shrawan through the last day of the
// following Ashadh, e.g. FY 2081/82 is 2081-04-01 .. 2082-03-(end). Its
// bounds can come from either side: computed locally from a BS year (see
// [NepaliFiscalYear.forStartYear]), or handed over by a server as BS
// "yyyy-MM-dd" strings (see [NepaliFiscalYear.parse]) — the "cap at today
// while it's the current fiscal year, otherwise show the full range"
// behavior ([window], [stripAnchor]) works identically either way, since it
// only ever depends on [start]/[end], never on how they were obtained.
//
// Picking a date with no fiscal year involved at all — e.g. "today" through
// some caller-chosen end date — needs none of this: just pass startDate/
// endDate straight to showNepaliCalendar or HorizontalDateStrip, as
// DemoScreen._pickDate/_pickRange already do.

import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';

/// One Nepali fiscal year, spanning [start] through [end].
class NepaliFiscalYear {
  /// Creates a fiscal year from explicit bounds.
  ///
  /// Prefer [NepaliFiscalYear.forStartYear] when computing one locally, or
  /// [NepaliFiscalYear.parse] when the bounds came from a server.
  const NepaliFiscalYear({required this.start, required this.end});

  /// The fiscal year starting 1 Shrawan of [startYear].
  factory NepaliFiscalYear.forStartYear(int startYear) => NepaliFiscalYear(
    start: NepaliDate(startYear, 4, 1),
    end: NepaliDate(startYear + 1, 3, 1).lastDayOfMonth,
  );

  /// The fiscal year that [date] falls in.
  ///
  /// Baishakh–Ashadh (months 1–3) belong to the FY that started the
  /// *previous* BS year; Shrawan onward (month 4+) starts a new one.
  factory NepaliFiscalYear.containing(NepaliDate date) =>
      NepaliFiscalYear.forStartYear(
        date.month >= 4 ? date.year : date.year - 1,
      );

  /// The fiscal year containing today.
  factory NepaliFiscalYear.current() =>
      NepaliFiscalYear.containing(NepaliDate.now());

  /// A fiscal year from a server response giving its bounds as Bikram
  /// Sambat `"yyyy-MM-dd"` strings — the same format `NepaliDate.toString()`
  /// produces.
  ///
  /// Throws a [FormatException] when either string isn't a real BS date in
  /// that form, or an [ArgumentError] when [end] is before [start].
  factory NepaliFiscalYear.parse({required String start, required String end}) {
    final NepaliDate parsedStart = _parseBsDate(start);
    final NepaliDate parsedEnd = _parseBsDate(end);
    if (parsedEnd < parsedStart) {
      throw ArgumentError('Fiscal year end ($end) is before start ($start).');
    }
    return NepaliFiscalYear(start: parsedStart, end: parsedEnd);
  }

  /// The first day of the fiscal year.
  final NepaliDate start;

  /// The last day of the fiscal year, regardless of whether it has happened
  /// yet.
  final NepaliDate end;

  /// The fiscal year immediately before this one.
  NepaliFiscalYear get previous =>
      NepaliFiscalYear.containing(start.subtractDays(1));

  /// Whether today falls inside this fiscal year.
  bool get isCurrent {
    final NepaliDate today = NepaliDate.now();
    return today >= start && today <= end;
  }

  /// The window to pass as `startDate`/`endDate` to `showNepaliCalendar` or
  /// `HorizontalDateStrip`: the full fiscal year once it has elapsed, or
  /// [start] through today while it is still running.
  ///
  /// Assumes this fiscal year has already started (`start <= today`) — don't
  /// build one for a year that hasn't begun yet.
  NepaliDateRange window() {
    final NepaliDate today = NepaliDate.now();
    return NepaliDateRange(start: start, end: end > today ? today : end);
  }

  /// Where a `HorizontalDateStrip` should anchor its `startDate`.
  ///
  /// The strip's `startDate` doubles as both the earliest selectable day and
  /// which day its visible chips start from, so anchoring a *current* fiscal
  /// year at [start] (often months ago) would show stale days by default.
  /// Anchoring at today instead means the strip's own calendar button can
  /// only browse forward from today to fiscal year end — browse the full
  /// fiscal year (including days before today) with `showNepaliCalendar`
  /// directly, using [start] and [window]'s end.
  NepaliDate stripAnchor() => isCurrent ? NepaliDate.now() : start;

  @override
  bool operator ==(Object other) =>
      other is NepaliFiscalYear && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '${start.year}/${(start.year + 1) % 100}';

  static NepaliDate _parseBsDate(String value) {
    final List<String> parts = value.split('-');
    if (parts.length != 3) {
      throw FormatException('Not a BS date in yyyy-MM-dd form: "$value"');
    }
    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      throw FormatException('Not a BS date in yyyy-MM-dd form: "$value"');
    }
    final NepaliDate date = NepaliDate(year, month, day);
    if (!date.isValid) {
      throw FormatException('Not a real Bikram Sambat date: "$value"');
    }
    return date;
  }
}
