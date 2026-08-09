import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NepaliHoliday value semantics', () {
    const NepaliHoliday holiday = NepaliHoliday(
      type: 'Public',
      dates: <NepaliDate>[NepaliDate(2082, 1, 1)],
      color: Color(0xFFC1272D),
    );

    test('equal type, dates and color are equal', () {
      const NepaliHoliday other = NepaliHoliday(
        type: 'Public',
        dates: <NepaliDate>[NepaliDate(2082, 1, 1)],
        color: Color(0xFFC1272D),
      );
      expect(holiday, other);
      expect(holiday.hashCode, other.hashCode);
    });

    test('a different type is not equal', () {
      const NepaliHoliday other = NepaliHoliday(
        type: 'Optional',
        dates: <NepaliDate>[NepaliDate(2082, 1, 1)],
        color: Color(0xFFC1272D),
      );
      expect(holiday, isNot(other));
    });

    test('different dates are not equal', () {
      const NepaliHoliday other = NepaliHoliday(
        type: 'Public',
        dates: <NepaliDate>[NepaliDate(2082, 1, 2)],
        color: Color(0xFFC1272D),
      );
      expect(holiday, isNot(other));
    });

    test('a different color is not equal', () {
      const NepaliHoliday other = NepaliHoliday(
        type: 'Public',
        dates: <NepaliDate>[NepaliDate(2082, 1, 1)],
        color: Color(0xFF000000),
      );
      expect(holiday, isNot(other));
    });
  });
}
