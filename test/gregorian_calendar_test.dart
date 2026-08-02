import 'package:custom_nepali_calendar/src/converters/gregorian_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('leap years', () {
    test('divisible by 4 but not 100 is a leap year', () {
      expect(GregorianCalendar.isLeapYear(2024), isTrue);
      expect(GregorianCalendar.isLeapYear(1996), isTrue);
    });

    test('divisible by 100 but not 400 is not a leap year', () {
      expect(GregorianCalendar.isLeapYear(1900), isFalse);
      expect(GregorianCalendar.isLeapYear(2100), isFalse);
    });

    test('divisible by 400 is a leap year', () {
      expect(GregorianCalendar.isLeapYear(2000), isTrue);
      expect(GregorianCalendar.isLeapYear(1600), isTrue);
    });

    test('odd years are not leap years', () {
      expect(GregorianCalendar.isLeapYear(2023), isFalse);
      expect(GregorianCalendar.isLeapYear(2025), isFalse);
    });

    test('year length follows the leap rule', () {
      expect(GregorianCalendar.daysInYear(2024), 366);
      expect(GregorianCalendar.daysInYear(2023), 365);
      expect(GregorianCalendar.daysInYear(1900), 365);
    });
  });

  group('days in month', () {
    test('February is 28 or 29 days', () {
      expect(GregorianCalendar.daysInMonth(2023, 2), 28);
      expect(GregorianCalendar.daysInMonth(2024, 2), 29);
      expect(GregorianCalendar.daysInMonth(1900, 2), 28);
      expect(GregorianCalendar.daysInMonth(2000, 2), 29);
    });

    test('the 30/31-day pattern is correct', () {
      const List<int> expected = <int>[
        31,
        28,
        31,
        30,
        31,
        30,
        31,
        31,
        30,
        31,
        30,
        31,
      ];
      for (int month = 1; month <= 12; month++) {
        expect(
          GregorianCalendar.daysInMonth(2023, month),
          expected[month - 1],
          reason: 'month $month',
        );
      }
    });

    test('an out-of-range month throws', () {
      expect(() => GregorianCalendar.daysInMonth(2024, 0), throwsArgumentError);
      expect(
        () => GregorianCalendar.daysInMonth(2024, 13),
        throwsArgumentError,
      );
    });

    test('date validity accounts for month length', () {
      expect(GregorianCalendar.isValidDate(2024, 2, 29), isTrue);
      expect(GregorianCalendar.isValidDate(2023, 2, 29), isFalse);
      expect(GregorianCalendar.isValidDate(2024, 4, 31), isFalse);
      expect(GregorianCalendar.isValidDate(2024, 13, 1), isFalse);
      expect(GregorianCalendar.isValidDate(2024, 1, 0), isFalse);
    });
  });

  group('day numbers', () {
    test('toDayNumber and fromDayNumber are inverses', () {
      for (int offset = 0; offset < 5000; offset += 7) {
        final int dayNumber =
            GregorianCalendar.toDayNumber(2000, 1, 1) + offset;
        final List<int> parts = GregorianCalendar.fromDayNumber(dayNumber);
        expect(
          GregorianCalendar.toDayNumber(parts[0], parts[1], parts[2]),
          dayNumber,
        );
      }
    });

    test('known Julian Day Numbers match', () {
      // 1 January 2000 is JDN 2451545.
      expect(GregorianCalendar.toDayNumber(2000, 1, 1), 2451545);
      expect(GregorianCalendar.fromDayNumber(2451545), <int>[2000, 1, 1]);
    });

    test('daysBetween counts calendar days in both directions', () {
      expect(
        GregorianCalendar.daysBetween(
          DateTime(2024, 1, 1),
          DateTime(2024, 3, 1),
        ),
        60, // 2024 is a leap year
      );
      expect(
        GregorianCalendar.daysBetween(
          DateTime(2023, 1, 1),
          DateTime(2023, 3, 1),
        ),
        59,
      );
      expect(
        GregorianCalendar.daysBetween(
          DateTime(2024, 3, 1),
          DateTime(2024, 1, 1),
        ),
        -60,
      );
      expect(
        GregorianCalendar.daysBetween(
          DateTime(2024, 5, 5),
          DateTime(2024, 5, 5),
        ),
        0,
      );
    });

    test('daysBetween ignores the time of day', () {
      expect(
        GregorianCalendar.daysBetween(
          DateTime(2024, 1, 1, 23, 59),
          DateTime(2024, 1, 2, 0, 1),
        ),
        1,
      );
    });

    test('addDays crosses month, year and leap-day boundaries', () {
      expect(
        GregorianCalendar.addDays(DateTime(2024, 2, 28), 1),
        DateTime(2024, 2, 29),
      );
      expect(
        GregorianCalendar.addDays(DateTime(2023, 2, 28), 1),
        DateTime(2023, 3, 1),
      );
      expect(
        GregorianCalendar.addDays(DateTime(2024, 12, 31), 1),
        DateTime(2025, 1, 1),
      );
      expect(
        GregorianCalendar.addDays(DateTime(2025, 1, 1), -1),
        DateTime(2024, 12, 31),
      );
    });
  });

  group('weekdays', () {
    test('known weekdays are correct', () {
      expect(GregorianCalendar.weekdayIndex(2000, 1, 1), 6); // Saturday
      expect(GregorianCalendar.weekdayIndex(2024, 4, 13), 6); // Saturday
      expect(GregorianCalendar.weekdayIndex(1943, 4, 14), 3); // Wednesday
      expect(GregorianCalendar.weekdayIndex(2026, 7, 30), 4); // Thursday
    });

    test('the weekday index agrees with DateTime over a long span', () {
      DateTime cursor = DateTime(1950);
      for (int i = 0; i < 3000; i++) {
        expect(
          GregorianCalendar.weekdayIndex(cursor.year, cursor.month, cursor.day),
          cursor.weekday % 7, // DateTime is Monday-based; make it Sunday-based
          reason: 'mismatch on $cursor',
        );
        cursor = GregorianCalendar.addDays(cursor, 13);
      }
    });

    test('dateOnly strips the time component', () {
      expect(
        GregorianCalendar.dateOnly(DateTime(2024, 4, 13, 18, 42, 7)),
        DateTime(2024, 4, 13),
      );
    });
  });
}
