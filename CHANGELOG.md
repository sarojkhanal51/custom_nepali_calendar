## 4.0.0

`selectableDates` grew a colour. It used to be a flat list of days that were
pickable and looked like every other day; it is now a list of groups, each of
which can mark its days in a colour of its own. One breaking signature change,
described under Migration below — everything else about the parameter behaves
as it did.

### Changed

* **`selectableDates` now takes `List<SelectableDates>` instead of
  `List<NepaliDate>`**, on `showNepaliCalendar` and `HorizontalDateStrip`
  alike. A `SelectableDates` group is a list of days plus an optional colour,
  the same shape `NepaliHoliday` already uses, so one list can carry several
  categories at once: free slots in green, nearly-full ones in amber,
  blackout-adjacent ones in red. Everything the parameter already did — a day
  must clear both the window and the list, an empty list disables every day,
  `initialSelection` is validated against it, the strip forwards it into the
  calendar its button opens — is unchanged.

### Added

* **Marked days.** A group carrying a `SelectableDates.color` draws its days
  with a bright 1.5px border in that colour over a light wash of it, and the
  day number in the same colour. An available day now reads as available at a
  glance rather than only by being tappable, and two kinds of available day
  are told apart without a legend. A group with no colour restricts without
  marking, which is exactly the old behaviour.

* **Selection outranks the mark.** Tapping a marked day paints it in the
  theme's `selectedDayColor` like any other pick, and the mark returns if the
  selection moves elsewhere. The mark says *available*, the fill says
  *chosen*, and the two never look alike — which is the whole reason the mark
  is a border-and-wash rather than a solid fill.

* **Days in either calendar.** `SelectableDates` takes Bikram Sambat
  `NepaliDate`s and `SelectableDates.fromDateTimes` takes Gregorian
  `DateTime`s, converting them on the way in. Both forms can appear in the
  same list. Because groups resolve to BS days internally, a mark follows the
  day rather than the calendar it is shown in: it lands on the same cell
  whether the sheet opened in BS or AD, and survives a live switch between
  them.

* **The strip marks its chips too**, with the same border and wash, so a day
  looks the same in the strip as it does in the calendar the strip opens.

* A `SelectableDates` group is a value: two groups with the same days and
  colour are equal, which is what lets the sheet and the strip skip the
  rebuild when a caller hands them a freshly-constructed but identical list.

* The example app gained an **appointment-slot** demo — two colour-coded
  groups driving a strip and a sheet from one list, one built from
  `NepaliDate`s and one from `DateTime`s.

### Migration

A plain allow-list becomes a single group with no colour:

```dart
// 3.x
selectableDates: <NepaliDate>[a, b, c],

// 4.0
selectableDates: <SelectableDates>[SelectableDates(dates: <NepaliDate>[a, b, c])],
```

Add `color:` to that group — or split it into several — to have the days
marked. Nothing else in the API changed, so this is the only edit a 3.x caller
needs.

### Precedence, for the record

A day can carry more than one signal at once. Selected beats everything. Below
that, a marked day keeps its border and wash; if it is also a holiday, the
holiday keeps the number's colour, so a holiday inside an available day still
shows as one. A day the window disabled is never marked.

## 3.2.0

A correctness release. Four of these let a picker resolve to a day the
caller had explicitly excluded, which is a data-integrity problem in the
consuming app rather than a cosmetic one — worth upgrading for even if you
use none of the new behavior.

### Changed

* **Two romanized month names changed:** month 3 is now `Ashadh` (was
  `Ashar`) and month 6 is now `Ashwin` (was `Ashoj`). These are the standard
  romanizations, they are what `nepali_utils` uses — so an app depending on
  both packages now renders the same names from either — and `Ashadh` is
  what this README already called month 3 in the fiscal-year section while
  the code said otherwise. Devanagari names are unchanged, as are the other
  ten Latin names. Nothing about the API changes; if you display
  `format('MMMM')` anywhere, the text your users see for those two months
  will differ.

### Added

* `CalendarStrings.monthNameShort` gives the abbreviated month name for any
  month, system and language, and is now the only way short names are
  produced. `MMM` and the date strip's month caption both used to take the
  first three characters of the full name, which rendered two months three
  apart identically — `12 Ash 2081` could mean Ashadh or Ashwin, with nothing
  on screen to tell them apart. Abbreviations now come from a hand-written
  table, the same way weekday abbreviations always have: `Bai Jes Asar Shr
  Bha Ash Kar Man Pou Mag Fal Cha`, matching `nepali_utils`. Devanagari is
  returned whole, since slicing it by code unit would cut a vowel mark off
  its consonant. `bsMonthsShortEnglish` and `adMonthsShortEnglish` are
  exposed alongside the existing name tables.
* `CalendarStrings` is now exported. It always documented itself as public
  API — "exposed publicly so consuming apps can reuse the same names in
  their own widgets" — but was missing from the library's `show` clause, so
  code following its own documentation did not compile. Month names, weekday
  names and their short forms in both languages are now reachable from
  `package:custom_nepali_calendar/custom_nepali_calendar.dart`, which is what
  you want when building your own month dropdown or report header. Purely
  additive.

### Fixed

* **The Today button no longer returns a day outside your window.** It was
  checked against the visible *month* and then selected unconditionally, so
  any `startDate` falling later in the current month — and any
  `selectableDates` allow-list — left Today free to pick a day the grid had
  already greyed out, with Done lit up and no signal that anything was
  wrong. Today now selects only when the day passes the same check the grid
  uses. When today is reachable but not selectable the button still
  navigates to that month without selecting; when today is out of range
  entirely the button renders disabled instead of looking live and
  swallowing the tap.
* **`initialSelection` no longer smuggles an excluded day back out.** A
  preselected value is a value the sheet can resolve to — Done is live the
  moment it opens — but it was never checked against
  `startDate`/`endDate`/`durationDays` or `selectableDates`. That broke the
  ordinary "hand back whatever you got last time" pattern as soon as the
  window moved: a day picked yesterday, replayed into a window that now
  starts today, arrived preselected, rendered greyed out and selected at the
  same time, and could be confirmed without the user touching anything. It is
  now checked against exactly the bounds a tap is, and ignored when it fails
  — so replaying a stale value is always safe. A selection whose kind does
  not match `mode` is ignored for the same reason, which also stops the Clear
  button offering to erase a value the sheet never displayed.
* **`HorizontalDateStrip` no longer reports a selection you excluded.** With
  no `selectedDate` the strip picks a starting day and reports it through
  `onDateSelected`, and that default ignored `endDate`/`durationDays`/
  `selectableDates` — so the caller ended up holding a date the strip was
  simultaneously painting as disabled. It now defaults to the first day that
  actually qualifies, and reports nothing at all when none of the visible
  days do.
* **The strip no longer throws out of `build`** at the top of the supported
  range. A strip anchored near BS 2199 walked off the end of the
  month-length table and threw `DateConversionException` from inside
  `build()`, where a consumer has no way to catch it and the whole screen
  goes down. It now renders however many days remain.
* **Passing both `endDate` and `durationDays` throws in release too.** It was
  a bare `assert`, so release builds silently dropped `durationDays` and used
  `endDate`. It is now an `ArgumentError`, matching the ordering checks that
  3.1.2 upgraded for the same reason.
* `HorizontalDateStrip` no longer calls `setState` after its calendar closes
  without checking it is still mounted — popping or replacing the host route
  while the sheet was open threw.
* The strip's "today" indicator and its start/end window are now resolved
  once and reused rather than recomputed on every build. 3.1.2 claimed the
  first of these; it was not actually true of the strip until now.

### Internal

* Window and allow-list membership now live in one `isDaySelectable`
  predicate that the month grid, the strip, the Today action and
  `initialSelection` all share. Every excluded-day bug above is a variation
  of the same root cause — the same rule written down in four places and
  drifting apart — so there is now only one place for it to drift from.
* Added a CI workflow: analyze (with `--fatal-infos`), format check, package
  tests, example tests, and `dart pub publish --dry-run` on every push and
  pull request.
* Added exhaustive test coverage: every one of the 84,009 representable days
  now round-trips BS→AD→BS and AD→BS→AD in CI, with the day-number sequence
  and the weekday cycle checked for breaks — which is what would catch a
  single mistyped month length in the table, even where the Nepali New Year
  dates on either side of it still line up. Alongside it, end-to-end coverage
  of the workflows a user actually walks and the inputs an app eventually
  supplies by accident. The suite went from 234 tests to 297 and still runs
  in under ten seconds.
* Added GitHub issue forms for bug reports and feature requests. The bug form
  asks for the two things that make a date-picker report actionable — the
  exact call, and the exact Bikram Sambat dates — because almost every defect
  found so far has been an interaction between `startDate`,
  `endDate`/`durationDays`, `selectableDates` and `initialSelection`.

### Docs

* README screenshots now resolve against the default branch instead of a
  release tag. Pinning them to `v3.1.2` broke every image on the package
  page when that tag was never pushed — the same failure 3.1.1 was released
  to fix. A branch reference cannot go stale this way.

## 3.1.2

### Added

* `selectableDates` restricts the sheet and strip to a caller-supplied list
  of days — every other day is disabled, on top of whatever
  `startDate`/`endDate`/`durationDays` already restrict, not instead of it.
  Useful for e.g. a fixed set of available appointment slots. Takes
  `List<NepaliDate>`, so parse any server-supplied date strings yourself
  first (same pattern as the fiscal-year recipe above). `null` (the default)
  keeps today's behavior; an empty list disables every day.
* `showClearButton` allows a Clear button in `showNepaliCalendar` (off by
  default). Even when enabled it only appears when the sheet opened on a
  value the caller already held, via `initialSelection` — not just because
  the user tapped a day in this session (Cancel already covers undoing an
  in-progress pick). Pressing it resolves to
  `NepaliCalendarSelection.cleared()` rather than plain `null`, so a caller
  can tell "the user explicitly removed the value" apart from "the user
  backed out via Cancel, leave it alone" — both used to be indistinguishable.
  `clearLabel` overrides its text; `NepaliCalendarSelection.isCleared` is the
  flag to check. Styled as a compact outlined button, tinted red, so it's
  visually distinct from Cancel and reads as the irreversible action it is.
* `initialSelection` preselects `showNepaliCalendar` with a value you already
  hold — typically whatever it returned last time. Reopening the sheet used
  to always start blank, with no way to show a previous pick; now passing
  the same `NepaliCalendarSelection` back in shows it already selected and
  opens on its month instead of `startDate`'s. `HorizontalDateStrip`'s own
  calendar button does this automatically with the strip's current value.
  `null` (the default) keeps the existing "nothing preselected" behavior.

### Fixed

* The sheet and strip no longer re-render the whole month grid on every tap —
  a controller update now only triggers a rebuild when the selection or
  calendar system actually changed, and month pages are memoized so an
  unrelated rebuild reuses the previous cells instead of recomputing them.
* Swiping between months no longer computes the visible page's cells twice.
* The header title no longer recomputes on every scroll frame while a month
  transition is animating — only once the page settles.
* `NepaliHoliday` now has value-based equality, so passing an equal-but-new
  holiday list on rebuild no longer forces the holiday lookup to recompute.
* `endDate`/`durationDays` ordering is now validated for real in release
  builds (previously only a debug-only assertion), so an inverted or
  non-positive window throws a clear `ArgumentError` instead of silently
  leaving nothing selectable.
* `NepaliDateRange.days` no longer throws when `end` is `NepaliDate.max`, and
  is now considerably cheaper on multi-month spans.
* `HorizontalDateStrip`'s "today" indicator no longer reads from a
  fresh conversion on every build.

### Docs

* Added a "Nepali fiscal year windows" recipe to the README, showing how to
  cap a picker at today for the current fiscal year while leaving a past one
  fully open — built entirely from `NepaliDate`'s existing comparison
  operators, `lastDayOfMonth` and `.now()`, no new package API involved.
* The example app now demonstrates that recipe, including parsing fiscal-year
  bounds from server-supplied `"yyyy-MM-dd"` strings — see
  `example/lib/fiscal_year.dart`.
* The example app's date and range pickers both now demonstrate
  `showClearButton` + `initialSelection` together — pick a date, close, and
  reopen to see it preselected with Clear available; press Clear to see the
  result reflect that explicitly, distinct from Cancel.

## 3.1.1

### Fixed

* **Docs:** README screenshots pointed at relative `doc/screenshots/*.png`
  paths, which pub.dev's README renderer cannot resolve — it silently drops
  the image and leaves the alt text instead. They now point at absolute
  `raw.githubusercontent.com` URLs pinned to this release's tag.

## 3.1.0

### Added

* `holidays` marks specific days with a caller-chosen colour — pass an
  organization's holiday list and each day in it is painted in its own colour
  wherever it falls in the visible window. Each entry is a `NepaliHoliday`
  (`type`, `dates`, `color`); `type` is free-form and carried through purely
  for the caller's own bookkeeping. Taken by both `showNepaliCalendar` and
  `HorizontalDateStrip`, which forwards it into the sheet its button opens.

## 3.0.0

### Breaking

* Removed `title` from `showNepaliCalendar`. The calendar does not need a title
  of its own — the surrounding screen already says what is being picked. Drop
  the argument; nothing else changes.

## 2.1.1

### Fixed

* `title` is drawn as a heading at the top of the sheet/dialog, above the
  calendar. It used to sit between the grid and the buttons, where it read as a
  stray caption rather than a title. No API change — `title` was, and stays,
  optional.

## 2.1.0

### Added

* `presentation` chooses where the calendar appears:
  `NepaliCalendarPresentation.bottomSheet` (the default, unchanged) or
  `NepaliCalendarPresentation.center` for a dialog in the middle of the screen.
  Both return the same value and honour `isDismissible`.
  `HorizontalDateStrip` takes it too, for the calendar behind its button.

### Fixed

* Switching to AD froze the calendar when the window reached the start of the
  supported range. The header converts the visible Gregorian month's first day to
  Bikram Sambat, and April 1913 opens twelve days before 1 Baishakh 1970, so that
  conversion threw mid-build. Conversions at both edges now clamp into the
  supported range.
* The confirm button was invisible while disabled whenever the calendar's palette
  and the host app's brightness disagreed — a dark calendar in a light app took
  Material's ambient disabled colours and vanished against its own background.
  Those colours now come from the calendar's own `textColor`.

## 2.0.1

* **Docs:** `HorizontalDateStrip` shipped in 2.0.0 without any documentation —
  it is now covered in the README with usage and a parameter table, and the
  example app demonstrates it alongside the bottom sheet.

## 2.0.0

### Breaking

* `theme` is now required. Every field of `NepaliCalendarTheme` still has a
  default, so `const NepaliCalendarTheme()` remains valid to pass; the change is
  that the palette is always an explicit decision at the call site.
* `allowedRange` and `maxDays` are replaced by a required `startDate` plus an
  optional `endDate` **or** `durationDays` — two ways of saying where the window
  closes, of which at most one may be given. `durationDays` counts the start day,
  so `durationDays: 90` means the start plus the next 89. The window bounds
  navigation as well as selection, in both modes and both calendar systems.
* `isDismissible` now defaults to `false`, so the sheet is modal: a tap on the
  barrier or a downward drag no longer discards a half-finished range, and the
  user leaves through Cancel or Done. Pass `isDismissible: true` for the old
  behaviour.

### Added

* `HorizontalDateStrip`, an inline row of consecutive days with the full calendar
  one tap away. Takes the same `startDate` / `endDate` / `durationDays` window,
  shows "Today" or the month above each date and the weekday below, selects a day
  on first build and reports it, and re-anchors when a date outside the strip is
  picked from the calendar.

### Fixed

* The "Today" button slid to the leading edge of the header when
  `showSystemSwitch` was `false`, instead of staying on the trailing edge.
* The selected segment of the BS/AD switch was unreadable in dark palettes: its
  pill fell back to `backgroundColor` while its label used `primaryColor`, two
  near-identical darks. The pill now falls back to `headerTextColor`, which is
  the colour already chosen to be legible against the header.
* The `MMM` format token no longer abbreviates Devanagari month names, which
  could separate a vowel mark from its consonant.
* The package description was over pub.dev's 180-character limit, costing 10 pub
  points.

### Notes

* Light and dark both run through the single `theme` parameter: pass
  `NepaliCalendarTheme.fromTheme(Theme.of(context))` to follow the host app
  including its brightness, or `NepaliCalendarTheme.dark()` for a fixed dark look.

## 1.0.0

Initial release.

* `showNepaliCalendar` — one call opens a Nepali (Bikram Sambat) date picker in a
  modal bottom sheet and returns a `NepaliCalendarSelection?`, or `null` when the
  user dismisses it.
* Single day or start/end range via `mode`; the range's in-between days are
  banded and confirm stays disabled until both ends are picked.
* Caller-supplied colours, fonts and metrics through `NepaliCalendarTheme`, with
  usable defaults, a `dark()` preset and `fromTheme(...)` to follow the host app's
  `ColorScheme`.
* `allowedRange` and `maxDays` bound the calendar — days outside grey out and the
  month arrows stop at the window's edges. Omit both for the full supported range.
* Live Bikram Sambat / Gregorian switch inside the sheet that preserves the
  selection, and English or Nepali labels chosen by the caller.
* `NepaliDate` and `NepaliDateRange` value types with validation, arithmetic,
  comparison and pattern formatting, plus `DateConverter` for BS ⇄ AD conversion
  with no UI involved.
* Bikram Sambat coverage BS 1970–2199 (AD 1913-04-13 – 2143-04-15), from a
  hard-coded month-length table anchored at 1 Baishakh 1970 BS = 13 April 1913 AD
  and verified against known Nepali New Year dates.
* No third-party dependencies, no platform channels, no native code.
