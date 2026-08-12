# custom_nepali_calendar

A Nepali (Bikram Sambat) date picker that opens in a **bottom sheet**. The calling
app passes its **theme colours** and whether it wants a **single date or a range**,
and gets the picked value back.

Written from scratch — **no third-party dependencies**, no platform channels, no
native code. Pure Dart and the Flutter SDK, so it runs anywhere Flutter runs.

<img src="https://raw.githubusercontent.com/sarojkhanal51/custom_nepali_calendar/develop/doc/screenshots/single_sheet.png" width="200" alt="Single-date picker open in a bottom sheet"> <img src="https://raw.githubusercontent.com/sarojkhanal51/custom_nepali_calendar/develop/doc/screenshots/range_sheet.png" width="200" alt="Range picker open in a bottom sheet"> <img src="https://raw.githubusercontent.com/sarojkhanal51/custom_nepali_calendar/develop/doc/screenshots/single_center.png" width="200" alt="Single-date picker open as a centred dialog"> <img src="https://raw.githubusercontent.com/sarojkhanal51/custom_nepali_calendar/develop/doc/screenshots/range_center.png" width="200" alt="Range picker open as a centred dialog">

## Features

Everything below is in the code — nothing aspirational.

**Picking**

- ✅ Opens in a modal bottom sheet, or a centred dialog — one function call
- ✅ Single date **or** date range selection
- ✅ Range band drawn across the days between the two ends
- ✅ Confirm stays disabled until the selection is complete
- ✅ Modal by default: a stray tap outside cannot discard a half-finished range
- ✅ "Today" shortcut in the header
- ✅ Month swipe and previous/next arrows
- ✅ Selectable window via `startDate` with `endDate` or `durationDays`
- ✅ Build any window from plain `NepaliDate` comparisons — e.g. a Nepali
  fiscal year capped at today while it's current, fully open once it's past
  (recipe below)
- ✅ `selectableDates`: restrict to an exact list of days — e.g. fixed
  appointment slots — on top of the window, sheet and strip alike
- ✅ Optional Clear button (`showClearButton`) that resolves distinctly from
  Cancel, so removing a value and backing out are never confused
- ✅ `initialSelection` reopens the sheet with a previous pick already
  selected, on the right month — off by default
- ✅ `HorizontalDateStrip`: an inline row of days with the calendar one tap away
- ✅ `holidays`: mark caller-supplied dates in their own colour, sheet and strip alike
- ✅ Custom Cancel/Done labels

**Nepali calendar**

- ✅ Full Bikram Sambat support, BS 1970–2199 (AD 1913–2143)
- ✅ Live BS ⇄ AD switch that keeps the selection through the change
- ✅ Both calendars in every cell — the BS day with its AD day underneath
- ✅ Today's date highlighted, in either calendar
- ✅ Saturday highlighted as the Nepali weekend
- ✅ Previous/next month days shown around the edges of the grid
- ✅ Verified against known Nepali New Year dates, with every day in range
  round-tripping losslessly

**Language**

- ✅ Bilingual (Nepali/English), chosen by the caller
- ✅ Devanagari numerals (१, २, ३) with Nepali month and weekday names
- ✅ Language is independent of the calendar system — all four combinations work

**Styling**

- ✅ Every colour, font and metric comes from `NepaliCalendarTheme`
- ✅ Light and dark: follow your app's `ColorScheme` with `fromTheme`, or use the
  built-in `dark()` preset
- ✅ Circle or rounded-square day cells, custom radius, spacing and grid lines
- ✅ Bring your own Devanagari font via `fontFamily` / `fontPackage`
- ✅ Width capped on tablets with `maxWidth`

**Dates as values**

- ✅ Standalone BS ⇄ AD conversion with no UI involved — `DateConverter`
- ✅ `NepaliDate` with validation, weekday, day arithmetic, comparison operators
  and pattern formatting in either language
- ✅ `NepaliDateRange` with length, containment and Gregorian `DateTimeRange`
  interop
- ✅ `NepaliNumerals` for Devanagari ⇄ Latin digits anywhere in your app

**Under the hood**

- ✅ Zero dependencies — pure Dart, no platform channels, every Flutter platform
- ✅ Screen-reader labels on every day cell
- ✅ Fixed six-week grid, so the sheet never changes height while swiping
- ✅ Rebuilds only recompute what actually changed — tapping a day or
  swiping a month doesn't re-render cells that didn't change
- ✅ 234 tests covering conversion, the widget and the layout

## Install

```console
flutter pub add custom_nepali_calendar
```

or in `pubspec.yaml`:

```yaml
dependencies:
  custom_nepali_calendar: ^3.0.0
```

## Use

```dart
import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';

// 1. A single date
final selection = await showNepaliCalendar(
  context: context,
  theme: const NepaliCalendarTheme(
    primaryColor: Color(0xFF0B7285),      // header + active switch segment
    selectedDayColor: Color(0xFFE8590C),
    weekendColor: Color(0xFFE03131),      // Saturday
  ),
);

if (selection != null) {
  final NepaliDate date = selection.date!;
  print(date);                 // 2083-04-14   Bikram Sambat
  print(selection.dateTime);   // 2026-07-30   Gregorian DateTime
}
```

```dart
// 2. A date range — same call, different mode
final selection = await showNepaliCalendar(
  context: context,
  mode: NepaliCalendarMode.range,
  theme: myCalendarTheme,
);

if (selection != null) {
  final NepaliDateRange range = selection.range!;
  print('${range.start} → ${range.end}');   // 2083-04-10 → 2083-04-20
  print(range.lengthInDays);                // 11, both ends counted
  print(selection.dateTimeRange);           // Gregorian DateTimeRange
}
```

### Where it appears

The same calendar, framed two ways — a sheet from the bottom edge, or a dialog in
the middle of the screen:

```dart
// the default
presentation: NepaliCalendarPresentation.bottomSheet,

// centred
presentation: NepaliCalendarPresentation.center,
```

Both return the same value, honour `isDismissible`, and work in single and range
mode. The centred one drops the drag handle, since there is no drag to hint at.

### An inline strip of days

For a row that lives on the screen rather than a sheet — today and the next few
days, with the full calendar one tap away:

<img src="https://raw.githubusercontent.com/sarojkhanal51/custom_nepali_calendar/develop/doc/screenshots/horizontal_strip.png" width="480" alt="HorizontalDateStrip: an inline row of days, with the full calendar one tap away">

```dart
HorizontalDateStrip(
  theme: NepaliCalendarTheme.fromTheme(Theme.of(context)),
  startDate: NepaliDate.now(),
  durationDays: 60,                 // optional window, same as the sheet
  selectedDate: _date,
  onDateSelected: (NepaliDate date) => setState(() => _date = date),
)
```

Each chip shows **Today** or its month above the date and the weekday below. The
trailing button opens `showNepaliCalendar` carrying the same theme, language,
window, `holidays` and `selectableDates` — and the strip's current day as
`initialSelection`, so the sheet opens already showing it selected. Pick a day
outside the strip and it re-anchors so the selection stays visible.

It selects a day on first build — today when the strip covers it, otherwise
`startDate` — and reports it through `onDateSelected`, so what is on screen and
what you hold never disagree.

| Parameter | Default | |
|---|---|---|
| `theme` | **required** | same `NepaliCalendarTheme` the sheet takes |
| `onDateSelected` | **required** | fires on tap, on a calendar pick, and once on first build |
| `startDate` | **required** | first day on the strip, earliest day offered |
| `selectedDate` | `null` | which day is filled |
| `dayCount` | `5` | how many days |
| `endDate` / `durationDays` | `null` | where the window closes — at most one |
| `language` | `.english` | |
| `system` | `.bs` | the chips show that calendar only |
| `holidays` | `[]` | dates painted in their own colour, also passed to the calendar it opens |
| `selectableDates` | `null` | only these days pickable, also passed to the calendar it opens |
| `showCalendarButton` | `true` | the trailing button |
| `height` | `60` | chips scale to fit |

`showNepaliCalendar` resolves to **`null`** when the user dismisses the sheet
(Cancel, swipe down, back gesture, tap outside), so a null check is the only error
handling needed. In range mode the first tap sets the start and the second the
end; the days between are banded and the confirm button stays disabled until both
ends exist.

The sheet shows a BS/AD toggle and nothing else — the language is whatever the
caller passed and cannot be changed from inside the sheet. It opens with the
strip's current day already selected (see `initialSelection` further down), so confirm
starts enabled rather than disabled. Below the grid there are only Cancel and
Done — no date readout, no title, no Clear button (that's opt-in on
`showNepaliCalendar` directly, not wired up here): the calendar is the whole
sheet.

### Limiting the calendar: `startDate`, `endDate`, `durationDays`

`startDate` is required — it is where the calendar opens and the earliest day it
offers. Where the window *closes* is optional, and you say it one of two ways:

```dart
// From today, for the next 90 days (the count includes today).
await showNepaliCalendar(
  context: context,
  theme: myTheme,
  startDate: NepaliDate.now(),
  durationDays: 90,
);

// From today until a fixed date.
await showNepaliCalendar(
  context: context,
  theme: myTheme,
  startDate: NepaliDate.now(),
  endDate: const NepaliDate(2084, 12, 30),
);

// From today, with no end — everything the package supports.
await showNepaliCalendar(
  context: context,
  theme: myTheme,
  startDate: NepaliDate.now(),
);

// The whole supported range, back to BS 1970.
await showNepaliCalendar(
  context: context,
  theme: myTheme,
  startDate: NepaliDate.min,
);
```

* `endDate` and `durationDays` are two ways of saying the same thing, so pass at
  most one — an assertion catches both.
* `durationDays` **counts the start day**, so `durationDays: 90` means the start
  plus the next 89.
* Days outside the window are greyed out and untappable, and the month arrows
  stop at its first and last month — so a picked range can never be longer than
  the window.
* Holding Gregorian dates? `NepaliDate.fromDateTime(myDateTime)`.

### Restricting to specific dates

`selectableDates` narrows the window further, down to an exact list — every
other day is disabled, even ones inside `startDate`/`endDate`. Good for a
fixed set of available slots, e.g. appointment availability from a server:

```dart
await showNepaliCalendar(
  context: context,
  theme: myTheme,
  startDate: NepaliDate.now(),
  endDate: NepaliDate.now().addDays(30),
  selectableDates: <NepaliDate>[
    const NepaliDate(2083, 4, 3),
    const NepaliDate(2083, 4, 7),
    const NepaliDate(2083, 4, 12),
  ],
);
```

A day must satisfy **both** the window and the list to be pickable — pass
just `selectableDates` with an unbounded window (no `endDate`/`durationDays`)
if the list alone should decide. `HorizontalDateStrip` takes the same
parameter and forwards it into the calendar its button opens, same as
`holidays`. The parameter takes `NepaliDate` values, not strings — parse any
server-supplied dates yourself first, same as the fiscal-year recipe below.

### Nepali fiscal year windows

The Nepali fiscal year runs 1 Shrawan through the last day of the following
Ashadh — e.g. FY 2081/82 is `2081-04-01` .. `2082-03-(end)`. There's no
dedicated API for this: `startDate`/`endDate` plus `NepaliDate`'s existing
comparison operators are all it takes to lock the *current* fiscal year to
today (nothing in the future is pickable) while leaving a *past* one fully
open, since today naturally isn't relevant to it anymore:

```dart
final NepaliDate start = const NepaliDate(2081, 4, 1);   // from your data
final NepaliDate fullEnd = const NepaliDate(2082, 3, 1).lastDayOfMonth;
final NepaliDate today = NepaliDate.now();

await showNepaliCalendar(
  context: context,
  theme: myTheme,
  startDate: start,
  // The full fiscal year once it has elapsed, or start..today while it's
  // still running.
  endDate: fullEnd > today ? today : fullEnd,
);
```

If the fiscal year's bounds come from your backend as BS `"yyyy-MM-dd"`
strings, parse them the same way `NepaliDate.toString()` formats them —
`NepaliDate(int.parse(y), int.parse(m), int.parse(d))` — then apply the same
`end > today ? today : end` cap.

`example/lib/fiscal_year.dart` wraps this in a small `NepaliFiscalYear` class
(`.current()`, `.forStartYear(year)`, `.parse(start: ..., end: ...)`,
`.window()`, `.isCurrent`) ready to copy into your app — it isn't part of the
package's public API, since a picker library shouldn't need an opinion on
what a fiscal year is; it's just built from what's already public here.

### Marking holidays

Pass an organization's holiday list and each date in it is painted in its own
colour, wherever it falls in the visible window:

```dart
await showNepaliCalendar(
  context: context,
  theme: myTheme,
  startDate: NepaliDate.now(),
  holidays: <NepaliHoliday>[
    NepaliHoliday(
      type: 'Public',
      dates: <NepaliDate>[const NepaliDate(2083, 1, 1)],   // Nepali New Year
      color: const Color(0xFFC1272D),
    ),
    NepaliHoliday(
      type: 'Optional',
      dates: <NepaliDate>[const NepaliDate(2083, 2, 15)],
      color: const Color(0xFF0B7285),
    ),
  ],
);
```

`type` is free-form — the package never reads it, so any scheme you already use
carries straight through. `HorizontalDateStrip` takes the same `holidays`
parameter and forwards it to the calendar its button opens, so the strip and
the sheet always agree.

### Letting the user clear a pick

For an optional date field, `showClearButton: true` allows a Clear button —
off by default, so nothing changes unless you ask for it. It only actually
appears when the sheet opens on a value the field already holds, via
`initialSelection` (below) — not just because the user tapped a day in this
session; Cancel already covers undoing an in-progress pick, so Clear stays
specifically for removing a value carried over from last time:

```dart
final selection = await showNepaliCalendar(
  context: context,
  theme: myTheme,
  startDate: NepaliDate.min,
  initialSelection: myDate == null ? null : NepaliCalendarSelection.single(myDate!),
  showClearButton: true,
  clearLabel: 'Remove date',   // optional; defaults to "Clear"
);

if (selection == null) {
  // Cancel / dismissed — leave whatever you already had.
} else if (selection.isCleared) {
  myDate = null;               // explicitly asked to remove it
} else {
  myDate = selection.date;
}
```

Without `isCleared`, Clear and Cancel would both just resolve to `null` and
be indistinguishable — you'd have no way to tell "leave it alone" apart from
"take it away." Without `initialSelection`, Clear stays hidden even after the
user picks a day in that session — there's nothing from *before* to remove
yet, so Cancel is the only way out.

Clear is tinted red — blended from `theme.textColor` rather than a fixed
hex, so it stays legible in both light and dark themes — as a visual cue
that, unlike Cancel, it discards a value irreversibly.

### Reopening with the previous pick already selected

By default the sheet never remembers anything between calls — every open
starts blank, confirm disabled, nothing highlighted, even if the user picked
something last time and you're reopening to let them change it. Pass
whatever `showNepaliCalendar` returned last time back in as
`initialSelection` to fix that:

```dart
NepaliCalendarSelection? lastPicked;

Future<void> pick() async {
  final selection = await showNepaliCalendar(
    context: context,
    theme: myTheme,
    startDate: NepaliDate.min,
    initialSelection: lastPicked,   // shows the previous pick already selected
  );
  if (selection != null) lastPicked = selection;   // Cancel leaves it alone
}
```

The sheet also opens on the selection's month instead of `startDate`'s, so
the highlighted day is visible immediately rather than requiring a swipe to
find it. Works the same way in range mode with a `.range(...)` selection.
`HorizontalDateStrip` does this automatically for the calendar its own
button opens — the sheet always shows whatever day is currently selected on
the strip.

### All parameters

```dart
await showNepaliCalendar(
  context: context,

  mode: NepaliCalendarMode.single,          // or .range
  presentation: NepaliCalendarPresentation.bottomSheet, // or .center
  theme: const NepaliCalendarTheme(...),    // REQUIRED — your colours, see below

  startDate: NepaliDate.now(),              // REQUIRED — where the calendar opens
  endDate: const NepaliDate(2084, 12, 30),  // …or durationDays, not both
  durationDays: 90,

  language: Language.english,               // or Language.nepali (fixed by you)
  initialSystem: CalendarSystem.bs,         // or CalendarSystem.ad

  showSystemSwitch: true,                   // the BS/AD toggle in the header
  holidays: <NepaliHoliday>[...],           // dates painted in their own colour
  selectableDates: <NepaliDate>[...],       // only these days pickable, on top of the window
  initialSelection: lastPicked,             // preselects it and opens on its month
  isDismissible: false,                     // default; true allows tap-outside

  showClearButton: true,                    // off by default; resolves to .cleared(), not null
  clearLabel: 'Remove date',
  confirmLabel: 'Apply',
  cancelLabel: 'Back',
  maxWidth: 480,                            // caps the sheet on tablets
);
```

## Theming

Every colour comes from `NepaliCalendarTheme`, and every field has a usable
default — pass only what you want to change:

```dart
const NepaliCalendarTheme(
  primaryColor: Color(0xFFC1272D),      // header background, active switch
  selectedDayColor: Color(0xFF003893),  // selected day, range ends
  selectedDayTextColor: Colors.white,
  rangeFillColor: Color(0x22003893),    // band between range ends
  todayHighlightColor: Color(0xFF2F9E44),
  weekendColor: Color(0xFFC1272D),      // Saturday, the Nepali weekend
  textColor: Color(0xFF1D2939),
  subtitleTextColor: Color(0xFF98A2B3),
  headerTextColor: Colors.white,
  backgroundColor: Colors.white,
  disabledDayColor: Color(0xFFD0D5DD),
  weekdayHeaderColor: Color(0xFF667085),
  weekdayHeaderBackgroundColor: Color(0xFFF9FAFB),
  dividerColor: Color(0xFFEAECF0),

  fontFamily: 'Mukta',                  // optional; system fonts cover Devanagari
  dayCellShape: BoxShape.circle,        // or BoxShape.rectangle
  borderRadius: 12,
  cellSpacing: 2,
)
```

Shortcuts: `NepaliCalendarTheme.dark()`, `NepaliCalendarTheme.fromTheme(Theme.of(context))`
to follow the host app's `ColorScheme`, and `copyWith` on any instance.

### Light and dark

There is one `theme` parameter, and it is required — light and dark are just
different values for it:

```dart
// follows the host app, including its light/dark mode
theme: NepaliCalendarTheme.fromTheme(Theme.of(context)),

// always dark
theme: NepaliCalendarTheme.dark(),

// hand-tuned per mode, decided with the brightness you already have
theme: Theme.of(context).brightness == Brightness.dark ? myDark : myLight,
```

Android and iOS both ship a Devanagari-capable system font, so Nepali text renders
with no configuration; set `fontFamily` (plus `fontPackage` if it lives in another
package) only when you want your own font.

## What you get back

```dart
class NepaliCalendarSelection {
  NepaliDate? date;            // set in single mode
  NepaliDateRange? range;      // set in range mode
  DateTime? dateTime;          // date as Gregorian
  DateTimeRange? dateTimeRange;// range as Gregorian
  NepaliCalendarMode mode;
  bool isCleared;               // true when Clear was pressed — see "Letting the user clear a pick"
}
```

`showNepaliCalendar` itself resolves to plain `null` when the user backs out
(Cancel, swipe-down, back gesture, tap-outside) — meaning "leave whatever you
already had." That is different from `isCleared`, which means the user
explicitly asked for the value to be removed; see "Letting the user clear a
pick" earlier in Use.

`NepaliDate` is an immutable BS year/month/day:

```dart
const date = NepaliDate(2081, 1, 15);
date.toDateTime();            // Gregorian equivalent
date.isValid;                 // false for e.g. NepaliDate(2081, 2, 33)
date.weekdayIndex;            // 0 = Sunday … 6 = Saturday
date.isSaturday;              // the Nepali weekend
date.daysInMonth;             // 31
date.addDays(45); date.differenceInDays(other);
date < other;                 // full comparison operators
date.format('EEEE, d MMMM yyyy');                        // Wednesday, 15 Baishakh 2081
date.format('d MMMM yyyy', language: Language.nepali);    // १५ बैशाख २०८१
NepaliDate.now(); NepaliDate.fromDateTime(DateTime.now());
```

`NepaliDateRange` is an inclusive pair: `start`, `end`, `lengthInDays`,
`isSingleDay`, `contains(date)`, `days`, `normalized`, `toDateTimeRange()`.

Conversion is also available without any UI — `DateConverter.adToBs(dateTime)` and
`DateConverter.bsToAd(nepaliDate)` — and out-of-range or impossible dates throw a
descriptive `DateConversionException`.

## Supported range and accuracy

**BS 1970–2199**, i.e. **AD 1913-04-13 to 2143-04-15**. BS month lengths are not
formula-derived, so they come from a hard-coded table anchored at
`1 Baishakh 1970 BS = 13 April 1913 AD`; Gregorian maths (leap years, weekdays,
day arithmetic) is computed from Julian Day Numbers rather than `DateTime`.

The table is verified against 15 independently known real-world dates (Nepali New
Year of 2000, 2050, 2070 and every year 2072–2083 BS), plus every day in the range
round-tripping BS → AD → BS losslessly and every BS weekday matching the Gregorian
weekday of the same day.

To widen the range, add real published month lengths to
`lib/src/data/bs_calendar_data.dart`; every bound follows from that table.

## Layout

```
lib/
  custom_nepali_calendar.dart              # the public API — nothing else is exported
  src/
    sheet/nepali_calendar_sheet.dart  # showNepaliCalendar + selection/mode types
    models/nepali_date.dart
    models/nepali_date_range.dart
    theme/nepali_calendar_theme.dart
    converters/                       # BS ⇄ AD, Gregorian maths, exception
    data/bs_calendar_data.dart        # BS year -> [days per month]
    localization/calendar_strings.dart
    view/                             # internal: the month grid the sheet shows
example/                              # one screen: picker, strip, fiscal year
test/
```

## Run it / test it

```console
cd example && flutter run     # Android emulator, iOS simulator or a real device
flutter test                  # the package
```

## Reporting a bug

Bugs and feature requests go to
[GitHub issues](https://github.com/sarojkhanal51/custom_nepali_calendar/issues) —
pub.dev has no tracker of its own, so that link is the only way to reach the
maintainer. There is a form that asks for what is needed; it takes a couple of
minutes.

Two things make a date-picker bug quick to fix, and without them it usually
takes a round trip to find out:

* **The call you made**, with real argument values — most reports turn out to
  be an interaction between `startDate`, `endDate`/`durationDays`,
  `selectableDates` and `initialSelection`, so leave all of them in even if
  they look unrelated.
* **The exact Bikram Sambat dates**, as `yyyy-MM-dd`: the day you picked, the
  day you got back, and the ends of the window.

For usage questions rather than defects, open a
[discussion](https://github.com/sarojkhanal51/custom_nepali_calendar/discussions)
instead.

## License

MIT — see [LICENSE](LICENSE).
