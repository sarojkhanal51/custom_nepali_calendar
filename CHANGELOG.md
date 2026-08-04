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
