import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';
import 'package:custom_nepali_calendar/src/data/bs_calendar_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validity', () {
    test('a real date is valid', () {
      expect(const NepaliDate(2081, 1, 1).isValid, isTrue);
      expect(const NepaliDate(2081, 2, 32).isValid, isTrue); // Jestha 2081 = 32
    });

    test('an impossible day, month or year is invalid', () {
      expect(const NepaliDate(2081, 2, 33).isValid, isFalse);
      expect(const NepaliDate(2081, 0, 1).isValid, isFalse);
      expect(const NepaliDate(2081, 13, 1).isValid, isFalse);
      expect(const NepaliDate(2081, 1, 0).isValid, isFalse);
      expect(const NepaliDate(1900, 1, 1).isValid, isFalse);
    });

    test('construction itself never throws', () {
      expect(() => const NepaliDate(9999, 99, 99), returnsNormally);
    });
  });

  group('derived values', () {
    test('daysInMonth and daysInYear come from the table', () {
      expect(const NepaliDate(2081, 1, 1).daysInMonth, 31);
      expect(const NepaliDate(2081, 2, 1).daysInMonth, 32);
      expect(const NepaliDate(2081, 1, 1).daysInYear, 366);
      expect(const NepaliDate(2080, 1, 1).daysInYear, 365);
    });

    test('dayOfYear counts from 1 Baishakh', () {
      expect(const NepaliDate(2081, 1, 1).dayOfYear, 1);
      expect(const NepaliDate(2081, 2, 1).dayOfYear, 32);
      expect(
        NepaliDate(2081, 12, BsCalendarData.daysInMonth(2081, 12)).dayOfYear,
        366,
      );
    });

    test('weekday and weekdayIndex use Sunday as the first day', () {
      // 1 Baishakh 2081 was a Saturday.
      const NepaliDate newYear = NepaliDate(2081, 1, 1);
      expect(newYear.weekdayIndex, 6);
      expect(newYear.weekday, 7);
      expect(newYear.isSaturday, isTrue);
      expect(newYear.addDays(1).weekdayIndex, 0); // Sunday
    });

    test('first and last day of the month', () {
      const NepaliDate mid = NepaliDate(2081, 2, 15);
      expect(mid.firstDayOfMonth, const NepaliDate(2081, 2, 1));
      expect(mid.lastDayOfMonth, const NepaliDate(2081, 2, 32));
    });
  });

  group('arithmetic', () {
    test('addDays and subtractDays are inverses', () {
      const NepaliDate start = NepaliDate(2081, 6, 15);
      expect(start.addDays(100).subtractDays(100), start);
      expect(start.addDays(-1), start.subtractDays(1));
    });

    test('addDays crosses month and year boundaries', () {
      expect(
        const NepaliDate(2081, 1, 31).addDays(1),
        const NepaliDate(2081, 2, 1),
      );
      expect(
        const NepaliDate(2081, 12, 31).addDays(1),
        const NepaliDate(2082, 1, 1),
      );
      expect(
        const NepaliDate(2082, 1, 1).addDays(-1),
        const NepaliDate(2081, 12, 31),
      );
    });

    test('differenceInDays is signed', () {
      const NepaliDate a = NepaliDate(2081, 1, 1);
      const NepaliDate b = NepaliDate(2081, 2, 1);
      expect(a.differenceInDays(b), 31);
      expect(b.differenceInDays(a), -31);
      expect(a.differenceInDays(a), 0);
    });

    test('nextMonth and previousMonth clamp the day to the month length', () {
      // Jestha 2081 has 32 days, Ashar has 31: day 32 clamps to 31.
      expect(
        const NepaliDate(2081, 2, 32).nextMonth,
        const NepaliDate(2081, 3, 31),
      );
      expect(
        const NepaliDate(2081, 1, 1).previousMonth,
        const NepaliDate(2080, 12, 1),
      );
      expect(
        const NepaliDate(2081, 12, 1).nextMonth,
        const NepaliDate(2082, 1, 1),
      );
    });

    test('stepping past the supported range throws', () {
      expect(
        () => const NepaliDate(BsCalendarData.minYear, 1, 1).previousMonth,
        throwsA(isA<DateConversionException>()),
      );
      expect(
        () => NepaliDate(BsCalendarData.maxYear, 12, 1).nextMonth,
        throwsA(isA<DateConversionException>()),
      );
    });
  });

  group('comparison', () {
    const NepaliDate earlier = NepaliDate(2081, 1, 1);
    const NepaliDate later = NepaliDate(2081, 1, 2);

    test('operators order dates correctly', () {
      expect(earlier < later, isTrue);
      expect(earlier <= later, isTrue);
      expect(later > earlier, isTrue);
      expect(later >= earlier, isTrue);
      expect(earlier <= earlier, isTrue);
      expect(earlier >= earlier, isTrue);
      expect(earlier > later, isFalse);
    });

    test('ordering respects year, then month, then day', () {
      expect(
        const NepaliDate(2080, 12, 30) < const NepaliDate(2081, 1, 1),
        isTrue,
      );
      expect(
        const NepaliDate(2081, 1, 30) < const NepaliDate(2081, 2, 1),
        isTrue,
      );
    });

    test('sorting uses compareTo', () {
      final List<NepaliDate> dates = <NepaliDate>[
        const NepaliDate(2081, 5, 1),
        const NepaliDate(2079, 1, 1),
        const NepaliDate(2081, 1, 15),
      ]..sort();
      expect(dates.first, const NepaliDate(2079, 1, 1));
      expect(dates.last, const NepaliDate(2081, 5, 1));
    });

    test('equality and hashCode are value-based', () {
      expect(const NepaliDate(2081, 1, 1), const NepaliDate(2081, 1, 1));
      expect(
        const NepaliDate(2081, 1, 1).hashCode,
        const NepaliDate(2081, 1, 1).hashCode,
      );
      // Two equal dates collapse into one set entry.
      final Set<NepaliDate> deduped = <NepaliDate>{}
        ..add(const NepaliDate(2081, 1, 1))
        ..add(const NepaliDate(2081, 1, 1));
      expect(deduped.length, 1);
    });

    test('isSameDay and isSameMonth', () {
      expect(
        const NepaliDate(2081, 1, 1).isSameDay(const NepaliDate(2081, 1, 1)),
        isTrue,
      );
      expect(
        const NepaliDate(2081, 1, 1).isSameMonth(const NepaliDate(2081, 1, 20)),
        isTrue,
      );
      expect(
        const NepaliDate(2081, 1, 1).isSameMonth(const NepaliDate(2081, 2, 1)),
        isFalse,
      );
    });

    test('copyWith replaces only the given fields', () {
      const NepaliDate date = NepaliDate(2081, 1, 1);
      expect(date.copyWith(day: 15), const NepaliDate(2081, 1, 15));
      expect(date.copyWith(year: 2080), const NepaliDate(2080, 1, 1));
    });
  });

  group('formatting', () {
    const NepaliDate date = NepaliDate(2081, 1, 5);

    test('toString is a zero-padded ISO-like string', () {
      expect(date.toString(), '2081-01-05');
      expect(const NepaliDate(2081, 12, 30).toString(), '2081-12-30');
    });

    test('English patterns', () {
      expect(date.format('yyyy-MM-dd'), '2081-01-05');
      expect(date.format('d MMMM yyyy'), '5 Baishakh 2081');
      expect(date.format('MMM d, yy'), 'Bai 5, 81');
      expect(date.format('EEEE'), 'Wednesday');
      expect(date.format('EEE'), 'Wed');
    });

    test('Nepali patterns use Devanagari digits and names', () {
      expect(
        date.format('yyyy-MM-dd', language: Language.nepali),
        '२०८१-०१-०५',
      );
      expect(
        date.format('d MMMM yyyy', language: Language.nepali),
        '५ बैशाख २०८१',
      );
      expect(date.format('EEEE', language: Language.nepali), 'बुधबार');
    });

    test('unknown characters pass through and quotes escape literals', () {
      expect(date.format('yyyy/MM/dd'), '2081/01/05');
      expect(date.format("'day' d"), 'day 5');
      expect(date.format("d 'gate'"), '5 gate');
    });

    test('month and weekday names are localized', () {
      expect(date.monthName(Language.english), 'Baishakh');
      expect(date.monthName(Language.nepali), 'बैशाख');
      expect(date.weekdayName(Language.english, short: true), 'Wed');
      expect(date.weekdayName(Language.nepali, short: true), 'बुध');
    });
  });

  group('interop with DateTime', () {
    test('fromDateTime and toDateTime round-trip', () {
      final DateTime ad = DateTime(2024, 4, 13);
      final NepaliDate bs = NepaliDate.fromDateTime(ad);
      expect(bs, const NepaliDate(2081, 1, 1));
      expect(bs.toDateTime(), ad);
    });

    test('now() agrees with converting DateTime.now()', () {
      expect(NepaliDate.now(), DateConverter.adToBs(DateTime.now()));
    });

    test('min and max describe the supported range', () {
      expect(NepaliDate.min, const NepaliDate(BsCalendarData.minYear, 1, 1));
      expect(NepaliDate.max.year, BsCalendarData.maxYear);
      expect(NepaliDate.max.month, 12);
      expect(NepaliDate.min.isValid, isTrue);
      expect(NepaliDate.max.isValid, isTrue);
    });
  });
}
