// Exhaustive sweeps over the conversion core and the month-length table.
//
// The rest of the suite spot-checks known date pairs. This walks every single
// day the package can represent — 84,009 of them — in both directions, which
// is what actually proves the table has no transcription errors in it: a
// single wrong month length shows up here as a day-number gap or a weekday
// break, even when the New Year dates either side of it still line up.

import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';
import 'package:custom_nepali_calendar/src/converters/gregorian_calendar.dart';
import 'package:custom_nepali_calendar/src/data/bs_calendar_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the month-length table', () {
    test('every year has twelve months of 29 to 32 days', () {
      for (int y = BsCalendarData.minYear; y <= BsCalendarData.maxYear; y++) {
        final List<int> months = BsCalendarData.monthDays[y]!;
        expect(months, hasLength(12), reason: 'BS $y');
        for (int m = 0; m < 12; m++) {
          expect(
            months[m],
            inInclusiveRange(29, 32),
            reason: 'BS $y month ${m + 1} has ${months[m]} days',
          );
        }
      }
    });

    test('every year totals 365 or 366 days', () {
      for (int y = BsCalendarData.minYear; y <= BsCalendarData.maxYear; y++) {
        expect(
          BsCalendarData.daysInYear(y),
          inInclusiveRange(365, 366),
          reason: 'BS $y',
        );
      }
    });

    test('the table covers exactly minYear..maxYear with no holes', () {
      expect(
        BsCalendarData.monthDays.length,
        BsCalendarData.maxYear - BsCalendarData.minYear + 1,
      );
      for (int y = BsCalendarData.minYear; y <= BsCalendarData.maxYear; y++) {
        expect(
          BsCalendarData.monthDays.containsKey(y),
          isTrue,
          reason: 'BS $y',
        );
      }
    });
  });

  group('exhaustive round-trip', () {
    test('BS -> AD -> BS is the identity, with no gaps or weekday breaks', () {
      int checked = 0;
      int? previousDayNumber;
      int? previousWeekday;

      for (int y = BsCalendarData.minYear; y <= BsCalendarData.maxYear; y++) {
        for (int m = 1; m <= 12; m++) {
          for (int d = 1; d <= BsCalendarData.daysInMonth(y, m); d++) {
            final NepaliDate bs = NepaliDate(y, m, d);
            final DateTime ad = bs.toDateTime();
            expect(NepaliDate.fromDateTime(ad), bs, reason: 'round-trip $bs');

            final int dayNumber = GregorianCalendar.toDayNumber(
              ad.year,
              ad.month,
              ad.day,
            );
            if (previousDayNumber != null) {
              expect(
                dayNumber,
                previousDayNumber + 1,
                reason: 'day-number gap entering $bs — a month length is wrong',
              );
            }
            previousDayNumber = dayNumber;

            final int weekday = bs.weekdayIndex;
            if (previousWeekday != null) {
              expect(
                weekday,
                (previousWeekday + 1) % 7,
                reason: 'weekday sequence broke at $bs',
              );
            }
            previousWeekday = weekday;
            checked++;
          }
        }
      }
      expect(checked, greaterThan(84000));
    });

    test('AD -> BS -> AD is the identity across the whole AD span', () {
      DateTime cursor = DateConverter.minAdDate;
      final DateTime last = DateConverter.maxAdDate;
      while (!cursor.isAfter(last)) {
        expect(
          DateConverter.bsToAd(DateConverter.adToBs(cursor)),
          cursor,
          reason: 'round-trip $cursor',
        );
        cursor = GregorianCalendar.addDays(cursor, 1);
      }
    });
  });

  group('range boundaries', () {
    test('the edges convert and one day past them does not', () {
      expect(NepaliDate.min.toDateTime(), DateConverter.minAdDate);
      expect(DateConverter.adToBs(DateConverter.maxAdDate), NepaliDate.max);

      final DateTime before = GregorianCalendar.addDays(
        DateConverter.minAdDate,
        -1,
      );
      final DateTime after = GregorianCalendar.addDays(
        DateConverter.maxAdDate,
        1,
      );
      expect(DateConverter.isConvertibleAd(before), isFalse);
      expect(DateConverter.isConvertibleAd(after), isFalse);
      expect(
        () => DateConverter.adToBs(before),
        throwsA(isA<DateConversionException>()),
      );
      expect(
        () => DateConverter.adToBs(after),
        throwsA(isA<DateConversionException>()),
      );
      expect(
        () => NepaliDate.min.subtractDays(1),
        throwsA(isA<DateConversionException>()),
      );
      expect(
        () => NepaliDate.max.addDays(1),
        throwsA(isA<DateConversionException>()),
      );
    });

    test('isValid agrees with the converter on malformed dates', () {
      const List<NepaliDate> malformed = <NepaliDate>[
        NepaliDate(2081, 0, 1),
        NepaliDate(2081, 13, 1),
        NepaliDate(2081, 1, 0),
        NepaliDate(2081, 1, 32),
        NepaliDate(2081, -1, -1),
        NepaliDate(1969, 1, 1),
        NepaliDate(2200, 1, 1),
        NepaliDate(0, 0, 0),
      ];
      for (final NepaliDate d in malformed) {
        expect(d.isValid, isFalse, reason: '$d claimed to be valid');
        expect(
          () => d.toDateTime(),
          throwsA(isA<DateConversionException>()),
          reason: '$d converted anyway',
        );
      }
    });

    test('a 32-day month accepts day 32 and a 31-day month does not', () {
      expect(const NepaliDate(2081, 2, 32).isValid, isTrue);
      expect(const NepaliDate(2081, 1, 32).isValid, isFalse);
    });
  });

  group('derived accessors stay consistent with the table', () {
    test('dayOfYear, daysInYear and differenceInDays agree', () {
      for (int y = 2075; y <= 2090; y++) {
        final NepaliDate first = NepaliDate(y, 1, 1);
        int running = 0;
        for (int m = 1; m <= 12; m++) {
          for (int d = 1; d <= BsCalendarData.daysInMonth(y, m); d++) {
            running++;
            final NepaliDate date = NepaliDate(y, m, d);
            expect(date.dayOfYear, running, reason: '$date');
            expect(first.differenceInDays(date), running - 1, reason: '$date');
          }
        }
        expect(first.daysInYear, running, reason: 'BS $y');
      }
    });

    test('differenceInDays is antisymmetric', () {
      const NepaliDate a = NepaliDate(2081, 1, 1);
      const NepaliDate b = NepaliDate(2083, 7, 19);
      expect(a.differenceInDays(b), -b.differenceInDays(a));
    });

    test('compareTo agrees with every comparison operator', () {
      const List<NepaliDate> sample = <NepaliDate>[
        NepaliDate(2081, 1, 1),
        NepaliDate(2081, 1, 2),
        NepaliDate(2081, 2, 1),
        NepaliDate(2082, 1, 1),
      ];
      for (final NepaliDate x in sample) {
        for (final NepaliDate y in sample) {
          expect(x < y, x.compareTo(y) < 0);
          expect(x <= y, x.compareTo(y) <= 0);
          expect(x > y, x.compareTo(y) > 0);
          expect(x >= y, x.compareTo(y) >= 0);
          expect(x == y, x.compareTo(y) == 0);
        }
      }
    });

    test('every month boundary shifts to a valid date', () {
      for (int y = 2079; y <= 2085; y++) {
        for (int m = 1; m <= 12; m++) {
          final NepaliDate last = NepaliDate(
            y,
            m,
            BsCalendarData.daysInMonth(y, m),
          );
          expect(last.nextMonth.isValid, isTrue, reason: '$last.nextMonth');
          expect(
            last.previousMonth.isValid,
            isTrue,
            reason: '$last.previousMonth',
          );
        }
      }
    });
  });

  group('localization tables', () {
    test('are all the right length', () {
      expect(CalendarStrings.bsMonthsNepali, hasLength(12));
      expect(CalendarStrings.bsMonthsEnglish, hasLength(12));
      expect(CalendarStrings.adMonthsNepali, hasLength(12));
      expect(CalendarStrings.adMonthsEnglish, hasLength(12));
      expect(CalendarStrings.weekdaysEnglish, hasLength(7));
      expect(CalendarStrings.weekdaysShortEnglish, hasLength(7));
      expect(CalendarStrings.weekdaysNepali, hasLength(7));
      expect(CalendarStrings.weekdaysShortNepali, hasLength(7));
      expect(NepaliNumerals.devanagariDigits, hasLength(10));
    });

    test('contain no duplicate entries', () {
      for (final List<String> table in <List<String>>[
        CalendarStrings.bsMonthsNepali,
        CalendarStrings.bsMonthsEnglish,
        CalendarStrings.adMonthsNepali,
        CalendarStrings.adMonthsEnglish,
        CalendarStrings.weekdaysEnglish,
        CalendarStrings.weekdaysShortEnglish,
        CalendarStrings.weekdaysNepali,
        CalendarStrings.weekdaysShortNepali,
      ]) {
        expect(table.toSet(), hasLength(table.length), reason: '$table');
      }
    });

    // Abbreviations used to be the first three characters of the full name,
    // which rendered Ashadh and Ashwin — three months apart — identically.
    test('no two months in a table share an abbreviation', () {
      for (final CalendarSystem system in CalendarSystem.values) {
        for (final Language language in Language.values) {
          final List<String> shorts = <String>[
            for (int m = 1; m <= 12; m++)
              CalendarStrings.monthNameShort(m, system, language),
          ];
          expect(
            shorts.toSet(),
            hasLength(12),
            reason:
                '${system.name}/${language.name} abbreviates two months '
                'to the same string: $shorts',
          );
        }
      }
    });

    test('an abbreviation is never longer than its full name', () {
      for (final CalendarSystem system in CalendarSystem.values) {
        for (final Language language in Language.values) {
          for (int m = 1; m <= 12; m++) {
            final String full = CalendarStrings.monthName(m, system, language);
            final String short = CalendarStrings.monthNameShort(
              m,
              system,
              language,
            );
            expect(
              short.length,
              lessThanOrEqualTo(full.length),
              reason: '$short is longer than $full',
            );
          }
        }
      }
    });

    test('Devanagari month names are never sliced', () {
      for (final CalendarSystem system in CalendarSystem.values) {
        for (int m = 1; m <= 12; m++) {
          expect(
            CalendarStrings.monthNameShort(m, system, Language.nepali),
            CalendarStrings.monthName(m, system, Language.nepali),
            reason: 'cutting Devanagari by code unit breaks vowel marks',
          );
        }
      }
    });

    test('MMM distinguishes Ashadh from Ashwin', () {
      expect(
        const NepaliDate(2081, 3, 12).format('d MMM yyyy'),
        '12 Asar 2081',
      );
      expect(const NepaliDate(2081, 6, 12).format('d MMM yyyy'), '12 Ash 2081');
      expect(const NepaliDate(2081, 3, 12).format('MMMM'), 'Ashadh');
      expect(const NepaliDate(2081, 6, 12).format('MMMM'), 'Ashwin');
    });

    test('reject out-of-range indices instead of returning junk', () {
      for (final int m in <int>[0, 13, -1]) {
        expect(
          () =>
              CalendarStrings.monthName(m, CalendarSystem.bs, Language.english),
          throwsRangeError,
          reason: 'month $m',
        );
      }
      for (final int w in <int>[-1, 7]) {
        expect(
          () => CalendarStrings.weekdayName(w, Language.english),
          throwsRangeError,
          reason: 'weekday $w',
        );
      }
    });

    test('numerals round-trip across a wide span', () {
      for (int i = -50; i < 100000; i += 997) {
        expect(
          NepaliNumerals.toLatin(NepaliNumerals.toDevanagari('$i')),
          '$i',
          reason: 'failed at $i',
        );
      }
    });

    test('numerals leave non-digits alone', () {
      expect(NepaliNumerals.toDevanagari('2081-01-15'), '२०८१-०१-१५');
      expect(NepaliNumerals.toDevanagari('a1b2'), 'a१b२');
      expect(NepaliNumerals.toLatin('क९ख'), 'क9ख');
      expect(NepaliNumerals.toDevanagari(''), '');
    });
  });

  group('NepaliDateRange', () {
    test('days always has exactly lengthInDays entries for a valid range', () {
      const List<NepaliDateRange> samples = <NepaliDateRange>[
        NepaliDateRange(
          start: NepaliDate(2081, 1, 1),
          end: NepaliDate(2081, 1, 1),
        ),
        NepaliDateRange(
          start: NepaliDate(2081, 1, 1),
          end: NepaliDate(2081, 12, 30),
        ),
        NepaliDateRange(
          start: NepaliDate(2080, 5, 12),
          end: NepaliDate(2083, 2, 3),
        ),
      ];
      for (final NepaliDateRange r in samples) {
        expect(r.days, hasLength(r.lengthInDays), reason: '$r');
        expect(r.days.first, r.start);
        expect(r.days.last, r.end);
      }
    });

    test('days at the very top of the range does not throw', () {
      final NepaliDateRange r = NepaliDateRange(
        start: NepaliDate.max.subtractDays(3),
        end: NepaliDate.max,
      );
      expect(r.days, hasLength(4));
    });
  });
}
