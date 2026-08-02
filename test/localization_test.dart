import 'package:custom_nepali_calendar/src/localization/calendar_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NepaliNumerals', () {
    test('converts Latin digits to Devanagari', () {
      expect(NepaliNumerals.toDevanagari('0123456789'), '०१२३४५६७८९');
      expect(NepaliNumerals.toDevanagari('2081'), '२०८१');
    });

    test('converts Devanagari digits back to Latin', () {
      expect(NepaliNumerals.toLatin('०१२३४५६७८९'), '0123456789');
      expect(NepaliNumerals.toLatin('२०८१'), '2081');
    });

    test('round-trips every number up to four digits', () {
      for (int value = 0; value <= 9999; value++) {
        final String devanagari = NepaliNumerals.toDevanagari('$value');
        expect(int.parse(NepaliNumerals.toLatin(devanagari)), value);
      }
    });

    test('preserves non-digit characters in both directions', () {
      expect(NepaliNumerals.toDevanagari('2081-01-15'), '२०८१-०१-१५');
      expect(NepaliNumerals.toLatin('२०८१-०१-१५'), '2081-01-15');
      expect(NepaliNumerals.toDevanagari('Baishakh 1'), 'Baishakh १');
      expect(NepaliNumerals.toLatin('बैशाख १'), 'बैशाख 1');
    });

    test('format pads and localizes', () {
      expect(NepaliNumerals.format(5, Language.english), '5');
      expect(NepaliNumerals.format(5, Language.english, padTo: 2), '05');
      expect(NepaliNumerals.format(5, Language.nepali), '५');
      expect(NepaliNumerals.format(5, Language.nepali, padTo: 2), '०५');
      expect(NepaliNumerals.format(2081, Language.nepali), '२०८१');
    });

    test('format keeps the sign in front of a negative number', () {
      expect(NepaliNumerals.format(-7, Language.english), '-7');
      expect(NepaliNumerals.format(-7, Language.nepali), '-७');
    });
  });

  group('CalendarStrings', () {
    test('all four mode/language combinations resolve month names', () {
      expect(
        CalendarStrings.monthName(1, CalendarSystem.bs, Language.english),
        'Baishakh',
      );
      expect(
        CalendarStrings.monthName(1, CalendarSystem.bs, Language.nepali),
        'बैशाख',
      );
      expect(
        CalendarStrings.monthName(1, CalendarSystem.ad, Language.english),
        'January',
      );
      expect(
        CalendarStrings.monthName(1, CalendarSystem.ad, Language.nepali),
        'जनवरी',
      );
    });

    test('every month index is covered in every list', () {
      for (int month = 1; month <= 12; month++) {
        for (final CalendarSystem mode in CalendarSystem.values) {
          for (final Language language in Language.values) {
            expect(
              CalendarStrings.monthName(month, mode, language),
              isNotEmpty,
              reason: 'month $month, $mode, $language',
            );
          }
        }
      }
    });

    test('an out-of-range month is rejected', () {
      expect(
        () => CalendarStrings.monthName(0, CalendarSystem.bs, Language.english),
        throwsRangeError,
      );
      expect(
        () =>
            CalendarStrings.monthName(13, CalendarSystem.bs, Language.english),
        throwsRangeError,
      );
    });

    test('weekday names start on Sunday in both languages', () {
      expect(CalendarStrings.weekdayName(0, Language.english), 'Sunday');
      expect(CalendarStrings.weekdayName(6, Language.english), 'Saturday');
      expect(CalendarStrings.weekdayName(0, Language.nepali), 'आइतबार');
      expect(CalendarStrings.weekdayName(6, Language.nepali), 'शनिबार');
      expect(
        CalendarStrings.weekdayName(0, Language.nepali, short: true),
        'आइत',
      );
      expect(
        CalendarStrings.weekdayName(6, Language.english, short: true),
        'Sat',
      );
    });

    test('an out-of-range weekday is rejected', () {
      expect(
        () => CalendarStrings.weekdayName(7, Language.english),
        throwsRangeError,
      );
    });

    test('the BS month lists are romanizations of one another', () {
      expect(CalendarStrings.bsMonthsEnglish.length, 12);
      expect(CalendarStrings.bsMonthsNepali.length, 12);
      expect(CalendarStrings.adMonthsEnglish.length, 12);
      expect(CalendarStrings.adMonthsNepali.length, 12);
    });
  });

  group('enums', () {
    test('CalendarSystem.opposite flips the mode', () {
      expect(CalendarSystem.bs.opposite, CalendarSystem.ad);
      expect(CalendarSystem.ad.opposite, CalendarSystem.bs);
    });

    test('mode labels are localized', () {
      expect(CalendarSystem.bs.label(Language.english), 'BS');
      expect(CalendarSystem.ad.label(Language.english), 'AD');
      expect(CalendarSystem.bs.label(Language.nepali), 'वि.सं.');
      expect(CalendarSystem.ad.label(Language.nepali), 'ई.सं.');
    });

    test('Language.isNepali', () {
      expect(Language.nepali.isNepali, isTrue);
      expect(Language.english.isNepali, isFalse);
    });
  });
}
