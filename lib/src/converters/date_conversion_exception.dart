/// Exception type thrown by the conversion API.
library;

/// Thrown when a date cannot be converted between Bikram Sambat and Gregorian.
///
/// The two causes are a date outside the supported BS range (the month-length
/// table only covers a finite span of years) and a structurally invalid date
/// such as `2081-13-01` or `2081-02-33`.
class DateConversionException implements Exception {
  /// Creates an exception with a human-readable [message].
  const DateConversionException(this.message);

  /// Creates the exception used when a date falls outside the supported range.
  DateConversionException.outOfRange({
    required Object date,
    required Object supportedFrom,
    required Object supportedTo,
  }) : message =
           'Date $date is outside the supported range '
           '($supportedFrom to $supportedTo). Extend the month-length table in '
           'BsCalendarData to support a wider range.';

  /// Creates the exception used when a date is structurally invalid.
  DateConversionException.invalidDate(Object date, [String? reason])
    : message = 'Invalid date: $date${reason == null ? '' : ' ($reason)'}.';

  /// A description of what went wrong and how to fix it.
  final String message;

  @override
  String toString() => 'DateConversionException: $message';
}
