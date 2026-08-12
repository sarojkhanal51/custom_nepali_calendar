/// A Nepali (Bikram Sambat) date picker that opens in a bottom sheet.
///
/// One call is the whole API: pass your theme colours and whether you want a
/// single day or a range, and get the picked value back.
///
/// ```dart
/// import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';
///
/// final selection = await showNepaliCalendar(
///   context: context,
///   mode: NepaliCalendarMode.range,     // or .single
///   theme: const NepaliCalendarTheme(primaryColor: Color(0xFF0B7285)),
/// );
///
/// selection?.date;             // NepaliDate?       in single mode
/// selection?.range;            // NepaliDateRange?  in range mode
/// selection?.dateTime;         // the same day as a Gregorian DateTime
/// ```
///
/// For a persistent row of days on a screen — today and the next few, with the
/// full calendar one tap away — use [HorizontalDateStrip] instead.
///
/// The sheet renders a Bikram Sambat month grid with a live BS/AD switch and
/// English/Nepali labels. Dates come back as [NepaliDate] / [NepaliDateRange],
/// which convert to Gregorian `DateTime` on demand; [DateConverter] exposes the
/// same conversion for use without any UI.
///
/// Everything else is internal to the package.
library;

export 'src/converters/date_conversion_exception.dart';
export 'src/converters/date_converter.dart';
export 'src/localization/calendar_strings.dart'
    show CalendarStrings, CalendarSystem, Language, NepaliNumerals;
export 'src/models/nepali_date.dart';
export 'src/models/nepali_date_range.dart';
export 'src/models/nepali_holiday.dart';
export 'src/sheet/nepali_calendar_sheet.dart'
    show
        NepaliCalendarMode,
        NepaliCalendarPresentation,
        NepaliCalendarSelection,
        showNepaliCalendar;
export 'src/strip/horizontal_date_strip.dart' show HorizontalDateStrip;
export 'src/theme/nepali_calendar_theme.dart';
