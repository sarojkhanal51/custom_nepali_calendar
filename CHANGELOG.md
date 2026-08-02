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
