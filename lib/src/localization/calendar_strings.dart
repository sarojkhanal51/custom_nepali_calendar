/// Localized month/weekday names and Devanagari numeral helpers.
library;

/// The language used to render every piece of text in the calendar.
///
/// The language is independent of the calendar system: a Bikram Sambat month can
/// be rendered in English (`Baishakh 2081`) and a Gregorian month can be
/// rendered in Nepali (`अप्रिल २०२४`).
enum Language {
  /// Latin digits and English/romanized names.
  english,

  /// Devanagari digits and Nepali names.
  nepali;

  /// Whether this is [Language.nepali].
  bool get isNepali => this == Language.nepali;
}

/// Which calendar system the widget is currently displaying.
enum CalendarSystem {
  /// Bikram Sambat — the official Nepali calendar.
  bs,

  /// Anno Domini — the Gregorian calendar.
  ad;

  /// The other mode. Used by the BS/AD toggle.
  CalendarSystem get opposite =>
      this == CalendarSystem.bs ? CalendarSystem.ad : CalendarSystem.bs;

  /// A short label for this mode (`BS` / `AD`), localized for [language].
  String label(Language language) => switch ((this, language)) {
    (CalendarSystem.bs, Language.english) => 'BS',
    (CalendarSystem.bs, Language.nepali) => 'वि.सं.',
    (CalendarSystem.ad, Language.english) => 'AD',
    (CalendarSystem.ad, Language.nepali) => 'ई.सं.',
  };
}

/// Conversion between Latin (`0-9`) and Devanagari (`०-९`) numerals.
///
/// Nepali calendars render every number — day, month, year — in Devanagari
/// digits, so this is exposed publicly for consuming apps that need the same
/// treatment elsewhere in their UI.
abstract final class NepaliNumerals {
  /// Devanagari digits, indexed by their numeric value.
  static const List<String> devanagariDigits = <String>[
    '०',
    '१',
    '२',
    '३',
    '४',
    '५',
    '६',
    '७',
    '८',
    '९',
  ];

  /// Rewrites every Latin digit in [input] as a Devanagari digit.
  ///
  /// Non-digit characters (separators, letters, whitespace) are preserved, so
  /// `toDevanagari('2081-01-15')` returns `'२०८१-०१-१५'`.
  static String toDevanagari(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in input.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        buffer.write(devanagariDigits[rune - 0x30]);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Rewrites every Devanagari digit in [input] as a Latin digit.
  ///
  /// Non-digit characters are preserved, so `toLatin('२०८१-०१-१५')` returns
  /// `'2081-01-15'`.
  static String toLatin(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in input.runes) {
      if (rune >= 0x966 && rune <= 0x96F) {
        buffer.write(rune - 0x966);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Formats [value] for [language], optionally left-padded with zeros to
  /// [padTo] digits.
  ///
  /// ```dart
  /// NepaliNumerals.format(5, Language.nepali, padTo: 2); // '०५'
  /// NepaliNumerals.format(5, Language.english, padTo: 2); // '05'
  /// ```
  static String format(int value, Language language, {int padTo = 0}) {
    final String latin = value.abs().toString().padLeft(padTo, '0');
    final String signed = value < 0 ? '-$latin' : latin;
    return language.isNepali ? toDevanagari(signed) : signed;
  }
}

/// All localized strings used by the calendar.
///
/// Exposed publicly so consuming apps can reuse the same names in their own
/// widgets (a month dropdown, a report header, and so on).
abstract final class CalendarStrings {
  /// Bikram Sambat month names in Devanagari, Baishakh..Chaitra.
  static const List<String> bsMonthsNepali = <String>[
    'बैशाख',
    'जेठ',
    'असार',
    'साउन',
    'भदौ',
    'असोज',
    'कार्तिक',
    'मंसिर',
    'पुष',
    'माघ',
    'फागुन',
    'चैत',
  ];

  /// Bikram Sambat month names romanized into Latin script, Baishakh..Chaitra.
  static const List<String> bsMonthsEnglish = <String>[
    'Baishakh',
    'Jestha',
    'Ashar',
    'Shrawan',
    'Bhadra',
    'Ashoj',
    'Kartik',
    'Mangsir',
    'Poush',
    'Magh',
    'Falgun',
    'Chaitra',
  ];

  /// Gregorian month names in English, January..December.
  static const List<String> adMonthsEnglish = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Gregorian month names transliterated into Devanagari, January..December.
  static const List<String> adMonthsNepali = <String>[
    'जनवरी',
    'फेब्रुअरी',
    'मार्च',
    'अप्रिल',
    'मे',
    'जून',
    'जुलाई',
    'अगस्ट',
    'सेप्टेम्बर',
    'अक्टोबर',
    'नोभेम्बर',
    'डिसेम्बर',
  ];

  /// Full weekday names in English, Sunday-first.
  static const List<String> weekdaysEnglish = <String>[
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  /// Short weekday names in English, Sunday-first.
  static const List<String> weekdaysShortEnglish = <String>[
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  /// Full weekday names in Nepali, Sunday-first.
  static const List<String> weekdaysNepali = <String>[
    'आइतबार',
    'सोमबार',
    'मंगलबार',
    'बुधबार',
    'बिहीबार',
    'शुक्रबार',
    'शनिबार',
  ];

  /// Short weekday names in Nepali, Sunday-first.
  static const List<String> weekdaysShortNepali = <String>[
    'आइत',
    'सोम',
    'मंगल',
    'बुध',
    'बिही',
    'शुक्र',
    'शनि',
  ];

  /// The localized name of month [month] (1-12) in [mode] and [language].
  ///
  /// Throws a [RangeError] when [month] is outside 1..12.
  static String monthName(int month, CalendarSystem mode, Language language) {
    RangeError.checkValueInInterval(month, 1, 12, 'month');
    return switch ((mode, language)) {
      (CalendarSystem.bs, Language.nepali) => bsMonthsNepali[month - 1],
      (CalendarSystem.bs, Language.english) => bsMonthsEnglish[month - 1],
      (CalendarSystem.ad, Language.nepali) => adMonthsNepali[month - 1],
      (CalendarSystem.ad, Language.english) => adMonthsEnglish[month - 1],
    };
  }

  /// The localized weekday name for [weekdayIndex] (`0` = Sunday … `6` =
  /// Saturday).
  ///
  /// Pass `short: true` for the abbreviated form used in the grid header.
  /// Throws a [RangeError] when [weekdayIndex] is outside 0..6.
  static String weekdayName(
    int weekdayIndex,
    Language language, {
    bool short = false,
  }) {
    RangeError.checkValueInInterval(weekdayIndex, 0, 6, 'weekdayIndex');
    return switch ((language, short)) {
      (Language.nepali, true) => weekdaysShortNepali[weekdayIndex],
      (Language.nepali, false) => weekdaysNepali[weekdayIndex],
      (Language.english, true) => weekdaysShortEnglish[weekdayIndex],
      (Language.english, false) => weekdaysEnglish[weekdayIndex],
    };
  }

  /// Label for the "jump to today" action.
  static String today(Language language) => language.isNepali ? 'आज' : 'Today';

  /// Tooltip for the previous-month arrow.
  static String previousMonth(Language language) =>
      language.isNepali ? 'अघिल्लो महिना' : 'Previous month';

  /// Tooltip for the next-month arrow.
  static String nextMonth(Language language) =>
      language.isNepali ? 'अर्को महिना' : 'Next month';
}
