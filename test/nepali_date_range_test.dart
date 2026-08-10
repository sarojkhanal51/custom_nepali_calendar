import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const NepaliDateRange range = NepaliDateRange(
    start: NepaliDate(2081, 1, 15),
    end: NepaliDate(2081, 1, 20),
  );

  group('basics', () {
    test('length counts both ends', () {
      expect(range.lengthInDays, 6);
      expect(
        const NepaliDateRange.singleDay(NepaliDate(2081, 1, 15)).lengthInDays,
        1,
      );
    });

    test('isSingleDay', () {
      expect(range.isSingleDay, isFalse);
      expect(
        const NepaliDateRange.singleDay(NepaliDate(2081, 1, 15)).isSingleDay,
        isTrue,
      );
    });

    test('contains is inclusive of both ends', () {
      expect(range.contains(const NepaliDate(2081, 1, 15)), isTrue);
      expect(range.contains(const NepaliDate(2081, 1, 20)), isTrue);
      expect(range.contains(const NepaliDate(2081, 1, 17)), isTrue);
      expect(range.contains(const NepaliDate(2081, 1, 14)), isFalse);
      expect(range.contains(const NepaliDate(2081, 1, 21)), isFalse);
    });

    test('days lists every day in order', () {
      expect(range.days.length, 6);
      expect(range.days.first, range.start);
      expect(range.days.last, range.end);
    });

    test('spans month and year boundaries', () {
      const NepaliDateRange crossYear = NepaliDateRange(
        start: NepaliDate(2081, 12, 29),
        end: NepaliDate(2082, 1, 2),
      );
      expect(crossYear.lengthInDays, 5);
      expect(crossYear.contains(const NepaliDate(2081, 12, 31)), isTrue);
      expect(crossYear.contains(const NepaliDate(2082, 1, 1)), isTrue);
    });

    test(
      'a single day at the very top of the supported range does not throw',
      () {
        final NepaliDateRange atMax = NepaliDateRange(
          start: NepaliDate.max,
          end: NepaliDate.max,
        );
        expect(atMax.days, <NepaliDate>[NepaliDate.max]);
      },
    );

    test('a reversed range has no days', () {
      const NepaliDateRange reversed = NepaliDateRange(
        start: NepaliDate(2081, 1, 20),
        end: NepaliDate(2081, 1, 15),
      );
      expect(reversed.days, isEmpty);
    });
  });

  group('validity and normalization', () {
    test('a well-ordered range of real dates is valid', () {
      expect(range.isValid, isTrue);
    });

    test('a reversed or impossible range is not valid', () {
      expect(
        const NepaliDateRange(
          start: NepaliDate(2081, 1, 20),
          end: NepaliDate(2081, 1, 15),
        ).isValid,
        isFalse,
      );
      expect(
        const NepaliDateRange(
          start: NepaliDate(2081, 2, 33),
          end: NepaliDate(2081, 3, 1),
        ).isValid,
        isFalse,
      );
    });

    test('normalized swaps reversed ends and leaves good ones alone', () {
      const NepaliDateRange reversed = NepaliDateRange(
        start: NepaliDate(2081, 1, 20),
        end: NepaliDate(2081, 1, 15),
      );
      expect(reversed.normalized, range);
      expect(range.normalized, same(range));
    });
  });

  group('Gregorian interop', () {
    test('toDateTimeRange converts both ends', () {
      final DateTimeRange ad = range.toDateTimeRange();
      expect(ad.start, DateTime(2024, 4, 27));
      expect(ad.end, DateTime(2024, 5, 2));
    });

    test('fromDateTimes converts both ends', () {
      final NepaliDateRange converted = NepaliDateRange.fromDateTimes(
        start: DateTime(2024, 4, 27),
        end: DateTime(2024, 5, 2),
      );
      expect(converted, range);
    });

    test('an out-of-range end throws', () {
      expect(
        () => NepaliDateRange.fromDateTimes(
          start: DateTime(1900),
          end: DateTime(2024, 5, 2),
        ),
        throwsA(isA<DateConversionException>()),
      );
    });
  });

  group('value semantics', () {
    test('equality and hashCode are value-based', () {
      expect(
        range,
        const NepaliDateRange(
          start: NepaliDate(2081, 1, 15),
          end: NepaliDate(2081, 1, 20),
        ),
      );
      expect(
        range.hashCode,
        const NepaliDateRange(
          start: NepaliDate(2081, 1, 15),
          end: NepaliDate(2081, 1, 20),
        ).hashCode,
      );
    });

    test('copyWith replaces one end', () {
      expect(
        range.copyWith(end: const NepaliDate(2081, 1, 25)).end,
        const NepaliDate(2081, 1, 25),
      );
    });

    test('toString shows both ends', () {
      expect(range.toString(), '2081-01-15 – 2081-01-20');
    });
  });
}
