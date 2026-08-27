# custom_nepali_calendar example

A one-screen demo of everything
[`custom_nepali_calendar`](https://pub.dev/packages/custom_nepali_calendar)
does. Run it with `flutter run` from this directory.

What each section shows:

| Section | What it demonstrates |
|---|---|
| **Pick a date** / **Pick a range** | `showNepaliCalendar` in both modes, with a 90-day window, holidays, a Clear button, and `initialSelection` feeding the last result back in |
| **Or pick inline** | `HorizontalDateStrip` — a permanent row of days with the full calendar one tap away |
| **Appointment slots** | `selectableDates`: two colour-marked `SelectableDates` groups (green for a day with room, amber for a nearly-full one) driving the strip and the sheet from one list. The green group is built from `NepaliDate`s and the amber one from Gregorian `DateTime`s, since either calendar can be passed in |
| **Fiscal year** | Building a window from plain `NepaliDate` comparisons — see `lib/fiscal_year.dart` — capped at today while the year is current, fully open once it has elapsed |
| **English / नेपाली** | The `language` parameter, switched live |

`flutter test` in this directory runs the smoke test that drives the demo the
same way a user would.
