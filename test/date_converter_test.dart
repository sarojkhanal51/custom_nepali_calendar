import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';
import 'package:custom_nepali_calendar/src/converters/gregorian_calendar.dart';
import 'package:custom_nepali_calendar/src/data/bs_calendar_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('adToBs / bsToAd — known date pairs', () {
    // Each pair is a real, independently verifiable date: the Nepali New Year
    // (1 Baishakh) of the given BS year. These are the anchors that prove the
    // month-length table is aligned with the real calendar rather than merely
    // self-consistent.
    const Map<String, NepaliDate> newYearPairs = <String, NepaliDate>{
      '1943-04-14': NepaliDate(2000, 1, 1),
      '1993-04-13': NepaliDate(2050, 1, 1),
      '2013-04-14': NepaliDate(2070, 1, 1),
      '2015-04-14': NepaliDate(2072, 1, 1),
      '2016-04-13': NepaliDate(2073, 1, 1),
      '2017-04-14': NepaliDate(2074, 1, 1),
      '2018-04-14': NepaliDate(2075, 1, 1),
      '2019-04-14': NepaliDate(2076, 1, 1),
      '2020-04-13': NepaliDate(2077, 1, 1),
      '2021-04-14': NepaliDate(2078, 1, 1),
      '2022-04-14': NepaliDate(2079, 1, 1),
      '2023-04-14': NepaliDate(2080, 1, 1),
      '2024-04-13': NepaliDate(2081, 1, 1),
      '2025-04-14': NepaliDate(2082, 1, 1),
      '2026-04-14': NepaliDate(2083, 1, 1),
    };

    newYearPairs.forEach((String ad, NepaliDate bs) {
      test('$ad AD == $bs BS in both directions', () {
        final DateTime adDate = DateTime.parse(ad);
        expect(DateConverter.adToBs(adDate), bs);
        expect(DateConverter.bsToAd(bs), adDate);
      });
    });

    test('2081-01-01 BS <=> 2024-04-13 AD (the documented example)', () {
      expect(
        DateConverter.bsToAd(const NepaliDate(2081, 1, 1)),
        DateTime(2024, 4, 13),
      );
      expect(
        DateConverter.adToBs(DateTime(2024, 4, 13)),
        const NepaliDate(2081, 1, 1),
      );
    });

    test('a mid-month date converts correctly', () {
      // 15 Shrawan 2081 BS = 30 July 2024 AD.
      expect(
        DateConverter.bsToAd(const NepaliDate(2081, 4, 15)),
        DateTime(2024, 7, 30),
      );
      expect(
        DateConverter.adToBs(DateTime(2024, 7, 30)),
        const NepaliDate(2081, 4, 15),
      );
    });

    test('the time component of an AD date is ignored', () {
      expect(
        DateConverter.adToBs(DateTime(2024, 4, 13, 23, 59, 59)),
        const NepaliDate(2081, 1, 1),
      );
    });

    test('bsToAd always returns midnight', () {
      final DateTime ad = DateConverter.bsToAd(const NepaliDate(2081, 6, 20));
      expect(ad.hour, 0);
      expect(ad.minute, 0);
      expect(ad.second, 0);
    });
  });

  group('round trips', () {
    test('AD -> BS -> AD is lossless for every day of several years', () {
      DateTime cursor = DateTime(2019);
      final DateTime end = DateTime(2027);
      while (cursor.isBefore(end)) {
        final NepaliDate bs = DateConverter.adToBs(cursor);
        expect(
          DateConverter.bsToAd(bs),
          cursor,
          reason: 'round trip failed for $cursor (via $bs)',
        );
        cursor = GregorianCalendar.addDays(cursor, 1);
      }
    });

    test('BS -> AD -> BS is lossless for every day in the supported range', () {
      for (
        int year = BsCalendarData.minYear;
        year <= BsCalendarData.maxYear;
        year++
      ) {
        for (int month = 1; month <= 12; month++) {
          final int days = BsCalendarData.daysInMonth(year, month);
          for (int day = 1; day <= days; day++) {
            final NepaliDate bs = NepaliDate(year, month, day);
            final NepaliDate back = DateConverter.adToBs(
              DateConverter.bsToAd(bs),
            );
            if (back != bs) {
              fail('round trip failed for $bs -> $back');
            }
          }
        }
      }
    });

    test('consecutive BS days map to consecutive AD days', () {
      NepaliDate bs = const NepaliDate(2080, 12, 25);
      DateTime ad = DateConverter.bsToAd(bs);
      for (int i = 0; i < 400; i++) {
        final NepaliDate nextBs = bs.addDays(1);
        final DateTime nextAd = DateConverter.bsToAd(nextBs);
        expect(
          GregorianCalendar.daysBetween(ad, nextAd),
          1,
          reason: 'gap between $bs and $nextBs',
        );
        bs = nextBs;
        ad = nextAd;
      }
    });
  });

  group('month and year boundaries', () {
    test('the last day of Chaitra rolls into Baishakh of the next year', () {
      final int chaitraDays = BsCalendarData.daysInMonth(2081, 12);
      final NepaliDate lastDay = NepaliDate(2081, 12, chaitraDays);
      expect(lastDay.addDays(1), const NepaliDate(2082, 1, 1));
      expect(
        DateConverter.bsToAd(lastDay).add(const Duration(days: 1)),
        DateConverter.bsToAd(const NepaliDate(2082, 1, 1)),
      );
    });

    test('the day after the last day of a month is day 1 of the next', () {
      for (int month = 1; month <= 11; month++) {
        final int days = BsCalendarData.daysInMonth(2081, month);
        expect(
          NepaliDate(2081, month, days).addDays(1),
          NepaliDate(2081, month + 1, 1),
        );
      }
    });

    test('a BS month that spans two AD months converts on both sides', () {
      // Baishakh 2081 starts in April 2024 and ends in May 2024.
      expect(DateConverter.bsToAd(const NepaliDate(2081, 1, 1)).month, 4);
      expect(DateConverter.bsToAd(const NepaliDate(2081, 1, 31)).month, 5);
    });

    test('AD leap day 29 Feb converts and round-trips', () {
      final DateTime leapDay = DateTime(2024, 2, 29);
      final NepaliDate bs = DateConverter.adToBs(leapDay);
      expect(bs, const NepaliDate(2080, 11, 17));
      expect(DateConverter.bsToAd(bs), leapDay);
    });

    test('every BS year in range has 12 months and a sane length', () {
      for (
        int year = BsCalendarData.minYear;
        year <= BsCalendarData.maxYear;
        year++
      ) {
        final List<int> months = BsCalendarData.monthDays[year]!;
        expect(months.length, 12, reason: 'year $year');
        expect(
          BsCalendarData.daysInYear(year),
          anyOf(365, 366),
          reason: 'year $year',
        );
        for (final int days in months) {
          expect(days, inInclusiveRange(29, 32), reason: 'year $year');
        }
      }
    });
  });

  group('range errors', () {
    test('a BS year below the table throws with a helpful message', () {
      expect(
        () => DateConverter.bsToAd(const NepaliDate(1969, 1, 1)),
        throwsA(
          isA<DateConversionException>().having(
            (DateConversionException e) => e.message,
            'message',
            contains('outside the supported range'),
          ),
        ),
      );
    });

    test('a BS year above the table throws', () {
      expect(
        () => DateConverter.bsToAd(const NepaliDate(2200, 1, 1)),
        throwsA(isA<DateConversionException>()),
      );
    });

    test('an AD date before the anchor throws', () {
      expect(
        () => DateConverter.adToBs(DateTime(1913, 4, 12)),
        throwsA(isA<DateConversionException>()),
      );
    });

    test('an AD date after the table throws', () {
      expect(
        () => DateConverter.adToBs(DateTime(2200)),
        throwsA(isA<DateConversionException>()),
      );
    });

    test('an impossible BS day throws and names the real month length', () {
      // Jestha 2081 has 32 days.
      expect(
        () => DateConverter.bsToAd(const NepaliDate(2081, 2, 33)),
        throwsA(
          isA<DateConversionException>().having(
            (DateConversionException e) => e.message,
            'message',
            allOf(contains('32 days'), contains('Invalid date')),
          ),
        ),
      );
    });

    test('an impossible BS month throws', () {
      expect(
        () => DateConverter.bsToAd(const NepaliDate(2081, 13, 1)),
        throwsA(isA<DateConversionException>()),
      );
    });

    test('an impossible AD date throws', () {
      expect(
        () => DateConverter.adPartsToBs(2023, 2, 29),
        throwsA(isA<DateConversionException>()),
      );
    });

    test('the exact range endpoints convert without throwing', () {
      expect(DateConverter.adToBs(DateConverter.minAdDate), NepaliDate.min);
      expect(DateConverter.adToBs(DateConverter.maxAdDate), NepaliDate.max);
      expect(DateConverter.bsToAd(NepaliDate.min), DateConverter.minAdDate);
      expect(DateConverter.bsToAd(NepaliDate.max), DateConverter.maxAdDate);
    });

    test('isConvertible reports range membership without throwing', () {
      expect(DateConverter.isConvertibleAd(DateTime(2024, 4, 13)), isTrue);
      expect(DateConverter.isConvertibleAd(DateTime(1900)), isFalse);
      expect(
        DateConverter.isConvertibleBs(const NepaliDate(2081, 1, 1)),
        isTrue,
      );
      expect(
        DateConverter.isConvertibleBs(const NepaliDate(2081, 2, 33)),
        isFalse,
      );
    });

    test('daysInBsMonth validates its arguments', () {
      expect(DateConverter.daysInBsMonth(2081, 1), 31);
      expect(
        () => DateConverter.daysInBsMonth(2081, 0),
        throwsA(isA<DateConversionException>()),
      );
      expect(
        () => DateConverter.daysInBsMonth(1900, 1),
        throwsA(isA<DateConversionException>()),
      );
    });
  });

  group('weekday alignment', () {
    test('known weekdays are correct in both calendars', () {
      // 1 Baishakh 2000 BS = 14 April 1943, a Wednesday.
      expect(const NepaliDate(2000, 1, 1).weekdayIndex, 3);
      // 13 April 2024 was a Saturday.
      expect(const NepaliDate(2081, 1, 1).weekdayIndex, 6);
      expect(const NepaliDate(2081, 1, 1).isSaturday, isTrue);
      expect(GregorianCalendar.weekdayIndex(2026, 7, 30), 4); // Thursday
    });

    test('the BS weekday matches the AD weekday of the same day', () {
      NepaliDate bs = const NepaliDate(2075, 5, 1);
      for (int i = 0; i < 500; i++) {
        final DateTime ad = bs.toDateTime();
        // DateTime.weekday is Monday-based; convert to a Sunday-based index.
        expect(bs.weekdayIndex, ad.weekday % 7, reason: 'mismatch on $bs');
        bs = bs.addDays(1);
      }
    });
  });
}
