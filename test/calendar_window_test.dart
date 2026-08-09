import 'package:custom_nepali_calendar/custom_nepali_calendar.dart';
import 'package:custom_nepali_calendar/src/sheet/calendar_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveCalendarWindow', () {
    test('rejects an endDate before startDate', () {
      expect(
        () => resolveCalendarWindow(
          startDate: const NepaliDate(2081, 1, 20),
          endDate: const NepaliDate(2081, 1, 15),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a non-positive durationDays', () {
      expect(
        () => resolveCalendarWindow(
          startDate: const NepaliDate(2081, 1, 1),
          durationDays: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => resolveCalendarWindow(
          startDate: const NepaliDate(2081, 1, 1),
          durationDays: -5,
        ),
        throwsArgumentError,
      );
    });

    test('accepts a well-ordered endDate', () {
      final NepaliDateRange range = resolveCalendarWindow(
        startDate: const NepaliDate(2081, 1, 1),
        endDate: const NepaliDate(2081, 1, 10),
      );
      expect(range.start, const NepaliDate(2081, 1, 1));
      expect(range.end, const NepaliDate(2081, 1, 10));
    });

    test('an endDate equal to startDate is a valid single-day window', () {
      final NepaliDateRange range = resolveCalendarWindow(
        startDate: const NepaliDate(2081, 1, 1),
        endDate: const NepaliDate(2081, 1, 1),
      );
      expect(range.isSingleDay, isTrue);
    });

    test('with neither endDate nor durationDays, the window runs to max', () {
      final NepaliDateRange range = resolveCalendarWindow(
        startDate: const NepaliDate(2081, 1, 1),
      );
      expect(range.end, NepaliDate.max);
    });

    test('durationDays counts the start day', () {
      final NepaliDateRange range = resolveCalendarWindow(
        startDate: const NepaliDate(2081, 1, 1),
        durationDays: 10,
      );
      expect(range.lengthInDays, 10);
    });
  });
}
