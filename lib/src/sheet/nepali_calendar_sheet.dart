/// The package's public entry point: open the calendar in a bottom sheet.
library;

import 'package:flutter/material.dart';

import '../data/day_selectability.dart';
import '../data/selectable_dates.dart';
import '../localization/calendar_strings.dart';
import '../models/nepali_date.dart';
import '../models/nepali_date_range.dart';
import '../models/nepali_holiday.dart';
import '../theme/nepali_calendar_theme.dart';
import '../view/calendar_controller.dart';
import '../view/calendar_view.dart';
import 'calendar_window.dart';

/// Whether the calendar collects a single day or a start/end pair.
enum NepaliCalendarMode {
  /// One tap picks one day.
  single,

  /// The first tap sets the range start, the second sets the end.
  range;

  /// Whether this is [NepaliCalendarMode.range].
  bool get isRange => this == NepaliCalendarMode.range;
}

/// Where the calendar appears on screen.
enum NepaliCalendarPresentation {
  /// A modal sheet that slides up from the bottom edge. The default.
  bottomSheet,

  /// A dialog centred on the screen.
  center;

  /// Whether this is [NepaliCalendarPresentation.center].
  bool get isCentered => this == NepaliCalendarPresentation.center;
}

/// What the user picked, returned by [showNepaliCalendar].
///
/// Exactly one of [date] and [range] is set, matching the [NepaliCalendarMode]
/// the sheet was opened with — except [isCleared], where both are null:
///
/// ```dart
/// final selection = await showNepaliCalendar(context: context);
/// selection?.date;   // set when opened in single mode
/// selection?.range;  // set when opened in range mode
/// selection?.isCleared;  // true when the Clear button was pressed instead
/// ```
@immutable
class NepaliCalendarSelection {
  /// A single-day result.
  const NepaliCalendarSelection.single(NepaliDate this.date)
    : range = null,
      isCleared = false;

  /// A range result.
  const NepaliCalendarSelection.range(NepaliDateRange this.range)
    : date = null,
      isCleared = false;

  /// The result of pressing Clear — [date] and [range] are both null.
  ///
  /// Distinct from the sheet resolving to plain `null` (the user backed out
  /// via Cancel/dismiss, meaning "leave whatever I already had alone"):
  /// this means the user explicitly asked for the value to be removed, so a
  /// caller holding a previous selection should clear it too.
  const NepaliCalendarSelection.cleared()
    : date = null,
      range = null,
      isCleared = true;

  /// The picked day, set only in [NepaliCalendarMode.single].
  final NepaliDate? date;

  /// The picked range, set only in [NepaliCalendarMode.range].
  final NepaliDateRange? range;

  /// Whether this came from the Clear button rather than a pick.
  final bool isCleared;

  /// The mode this selection came from.
  NepaliCalendarMode get mode =>
      range == null ? NepaliCalendarMode.single : NepaliCalendarMode.range;

  /// The picked day as a Gregorian [DateTime], or null in range mode.
  DateTime? get dateTime => date?.toDateTime();

  /// The picked range as a Gregorian [DateTimeRange], or null in single mode.
  DateTimeRange? get dateTimeRange => range?.toDateTimeRange();

  @override
  String toString() => isCleared
      ? 'NepaliCalendarSelection.cleared()'
      : 'NepaliCalendarSelection(${date ?? range})';

  @override
  bool operator ==(Object other) =>
      other is NepaliCalendarSelection &&
      other.date == date &&
      other.range == range &&
      other.isCleared == isCleared;

  @override
  int get hashCode => Object.hash(date, range, isCleared);
}

/// Opens the Nepali calendar in a modal bottom sheet and returns what was picked.
///
/// Resolves to `null` when the user backs out — so a null check is all the
/// handling needed.
///
/// By default the sheet is modal: tapping the barrier or dragging it down does
/// nothing, and the user leaves through Cancel or Done. Pass
/// `isDismissible: true` to allow tap-outside and swipe-down as well. The system
/// back gesture always pops the sheet either way.
///
/// ```dart
/// final selection = await showNepaliCalendar(
///   context: context,
///   mode: NepaliCalendarMode.range,          // or .single (the default)
///   theme: const NepaliCalendarTheme(              // required
///     primaryColor: Color(0xFF0B7285),            // header + active switch
///     selectedDayColor: Color(0xFFE8590C),
///     weekendColor: Color(0xFFE03131),            // Saturday
///   ),

///   startDate: NepaliDate.now(),                 // required: where it opens
///   durationDays: 90,                            // …or endDate: someDate
/// );
///
/// if (selection != null) {
///   final NepaliDateRange? range = selection.range;   // range mode
///   final NepaliDate? day = selection.date;           // single mode
/// }
/// ```
///
/// In [NepaliCalendarMode.range] the first tap sets the start and the second the
/// end; the days between are banded, and the confirm button stays disabled until
/// both ends exist.
///
/// * [presentation] decides where it appears:
///   [NepaliCalendarPresentation.bottomSheet] slides up from the bottom edge —
///   the default — and [NepaliCalendarPresentation.center] shows the same
///   calendar in a dialog centred on the screen. Both return the same value and
///   honour [isDismissible].
/// * [theme] carries every colour the sheet paints with, and is required. Each of
///   its fields has a usable default, so `const NepaliCalendarTheme()` is a valid
///   thing to pass. For a sheet that follows the host app — including its light
///   or dark mode — pass `NepaliCalendarTheme.fromTheme(Theme.of(context))`;
///   for a fixed dark look, `NepaliCalendarTheme.dark()`.
/// * Nothing is preselected by default — see [initialSelection] to change
///   that. The sheet opens on [startDate]'s month and confirm stays disabled
///   until the user picks.
/// * [startDate] is where the calendar opens and the earliest day it offers —
///   pass `NepaliDate.now()` for "from today", or `NepaliDate.min` to go back as
///   far as the package can.
/// * [endDate] and [durationDays] are two ways of saying where the window
///   closes, and only one may be given. [durationDays] counts the start day, so
///   `durationDays: 90` means the start plus the next 89. With neither, the
///   window runs to the end of the supported range.
/// * Days outside the window are greyed out and the month arrows stop at its
///   first and last month, so a range can never be longer than the window it is
///   picked from.
/// * [language] picks English or Nepali labels, and [initialSystem] picks the
///   calendar the sheet opens in. The user can switch Bikram Sambat/Gregorian
///   from the header unless [showSystemSwitch] is false; the language is fixed by
///   the caller and is not switchable in the sheet.
/// * [holidays] marks specific days with a caller-chosen color — pass an
///   organization's holiday list and each day in it is painted in its
///   [NepaliHoliday.color] wherever it falls in the visible window.
/// * [selectableDates], when given, disables every day not in it — on top of
///   whatever [startDate]/[endDate]/[durationDays] already restrict, not
///   instead of it. Useful for e.g. a fixed set of available appointment
///   slots. Null (the default) means no extra restriction.
/// * [confirmLabel] and [cancelLabel] override the button text.
/// * [showClearButton] allows a Clear button beside Cancel/Done — off by
///   default, and even when `true` it only appears when the sheet opened on
///   a value the caller already held, via [initialSelection]. Picking a day
///   in this session does not reveal it — Cancel already covers "undo my
///   in-progress pick"; Clear is specifically for removing a value from a
///   previous session. Pressing it resolves to
///   `const NepaliCalendarSelection.cleared()` rather than plain `null`, so a
///   caller can tell "the user removed the value" apart from "the user backed
///   out, leave it alone." [clearLabel] overrides its text.
/// * [initialSelection] preselects the sheet with a value you already hold —
///   typically whatever [showNepaliCalendar] returned last time. It must
///   match [mode]: a `.single` selection's [NepaliCalendarSelection.date] is
///   used in single mode, a `.range` selection's
///   [NepaliCalendarSelection.range] in range mode; the other is ignored.
///   The sheet also opens on the selection's month instead of [startDate]'s.
///   Leave it `null` (the default) for the existing "nothing preselected"
///   behavior.
///
///   It is checked against the same bounds a tap is. A value that falls
///   outside [startDate]/[endDate]/[durationDays], or that [selectableDates]
///   excludes, is ignored and the sheet opens with nothing selected — so
///   handing back a stale value is always safe, and this call can never
///   resolve to a day you excluded. That matters most for the common pattern
///   of persisting the last result against a rolling window like
///   `startDate: NepaliDate.now()`, where yesterday's pick falls out of the
///   window overnight.
/// * [isDismissible] defaults to `false`, so a stray tap on the barrier cannot
///   throw away a half-finished range. Set it to `true` for a sheet the user can
///   flick away.
Future<NepaliCalendarSelection?> showNepaliCalendar({
  required BuildContext context,
  required NepaliCalendarTheme theme,
  NepaliCalendarMode mode = NepaliCalendarMode.single,
  NepaliCalendarPresentation presentation =
      NepaliCalendarPresentation.bottomSheet,
  Language language = Language.english,
  CalendarSystem initialSystem = CalendarSystem.bs,
  required NepaliDate startDate,
  NepaliDate? endDate,
  int? durationDays,
  bool showSystemSwitch = true,
  List<NepaliHoliday> holidays = const <NepaliHoliday>[],
  List<NepaliDate>? selectableDates,
  NepaliCalendarSelection? initialSelection,
  bool isDismissible = false,
  bool showClearButton = false,
  String? clearLabel,
  String? confirmLabel,
  String? cancelLabel,
  double maxWidth = 480,
}) {
  // The endDate/durationDays conflict is rejected by resolveCalendarWindow
  // below, in release as well as debug — no assert needed here on top of it.
  final Widget body = _CalendarSheet(
    mode: mode,
    theme: theme,
    language: language,
    initialSystem: initialSystem,
    allowedRange: resolveCalendarWindow(
      startDate: startDate,
      endDate: endDate,
      durationDays: durationDays,
    ),
    showSystemSwitch: showSystemSwitch,
    holidays: holidays,
    selectableDates: selectableDates,
    initialSelection: initialSelection,
    showDragHandle: !presentation.isCentered,
    showClearButton: showClearButton,
    clearLabel: clearLabel,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
  );
  final ShapeBorder shape = RoundedRectangleBorder(
    borderRadius: presentation.isCentered
        ? BorderRadius.circular(theme.borderRadius + 8)
        : BorderRadius.vertical(top: Radius.circular(theme.borderRadius + 8)),
  );

  if (presentation.isCentered) {
    return showDialog<NepaliCalendarSelection>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (BuildContext context) => Dialog(
        backgroundColor: theme.backgroundColor,
        insetPadding: const EdgeInsets.all(20),
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: body,
        ),
      ),
    );
  }

  return showModalBottomSheet<NepaliCalendarSelection>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: theme.backgroundColor,
    constraints: BoxConstraints(maxWidth: maxWidth),
    shape: shape,
    builder: (BuildContext context) => body,
  );
}

class _CalendarSheet extends StatefulWidget {
  const _CalendarSheet({
    required this.mode,
    required this.theme,
    required this.language,
    required this.initialSystem,
    required this.allowedRange,
    required this.showSystemSwitch,
    required this.holidays,
    required this.selectableDates,
    required this.initialSelection,
    required this.showDragHandle,
    required this.showClearButton,
    required this.clearLabel,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  final NepaliCalendarMode mode;
  final NepaliCalendarTheme theme;
  final Language language;
  final CalendarSystem initialSystem;
  final NepaliDateRange? allowedRange;
  final bool showSystemSwitch;
  final List<NepaliHoliday> holidays;
  final List<NepaliDate>? selectableDates;
  final NepaliCalendarSelection? initialSelection;
  final bool showDragHandle;
  final bool showClearButton;
  final String? clearLabel;
  final String? confirmLabel;
  final String? cancelLabel;

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  /// The caller's [_CalendarSheet.initialSelection], or null when it names days
  /// this sheet would not let the user pick anyway.
  ///
  /// A preselected value is still a value the sheet can resolve to — Done is
  /// live the moment it opens — so it has to clear the same bar a tap does.
  /// Without this check, the ordinary "hand back whatever you got last time"
  /// pattern quietly breaks as soon as the window moves: a value picked
  /// yesterday, replayed into a window that now starts today, would arrive
  /// preselected, render greyed out and selected at once, and be confirmable
  /// without the user touching a thing.
  ///
  /// Rejecting it here also settles the mode mismatch: a `.single` handed to
  /// range mode (or the reverse) resolves to null, so the Clear button stops
  /// offering to erase a value the sheet never showed.
  late final NepaliCalendarSelection? _initialSelection =
      _resolveInitialSelection();

  NepaliCalendarSelection? _resolveInitialSelection() {
    final NepaliCalendarSelection? selection = widget.initialSelection;
    if (selection == null || selection.isCleared) {
      return null;
    }
    final Set<NepaliDate>? allowed = toSelectableDateSet(
      widget.selectableDates,
    );
    bool selectable(NepaliDate date) => isDaySelectable(
      date,
      startDate: widget.allowedRange?.start,
      endDate: widget.allowedRange?.end,
      selectableDates: allowed,
    );

    if (widget.mode.isRange) {
      final NepaliDateRange? range = selection.range;
      // Only the ends are checked: they are the days the user actually picks,
      // and an allow-list is about pickable days, not the span between them.
      if (range == null || !selectable(range.start) || !selectable(range.end)) {
        return null;
      }
      return selection;
    }
    final NepaliDate? date = selection.date;
    return date != null && selectable(date) ? selection : null;
  }

  // Nothing is preselected by default: the sheet opens on the window's first
  // month (or today when unbounded) and the user picks from there. When
  // initialSelection survives _resolveInitialSelection, the sheet opens on its
  // month instead and starts with it already selected.
  late final CalendarController _controller = CalendarController(
    mode: widget.mode,
    focusedDate:
        _initialSelection?.date ??
        _initialSelection?.range?.start ??
        widget.allowedRange?.start,
    initialDate: _initialSelection?.date,
    initialRange: _initialSelection?.range,
    system: widget.initialSystem,
    language: widget.language,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The result to pop, or null while the selection is not usable yet.
  NepaliCalendarSelection? get _result {
    if (widget.mode.isRange) {
      final NepaliDateRange? range = _controller.selectedRange;
      return range == null ? null : NepaliCalendarSelection.range(range);
    }
    final NepaliDate? date = _controller.selectedDate;
    return date == null ? null : NepaliCalendarSelection.single(date);
  }

  @override
  Widget build(BuildContext context) {
    final NepaliCalendarTheme theme = widget.theme;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The grab handle belongs to a sheet you can drag; a centred dialog
          // has no such gesture, so it would only take up room.
          if (widget.showDragHandle)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.subtitleTextColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )
          else
            const SizedBox(height: 8),
          CalendarView(
            controller: _controller,
            theme: theme,
            allowedRange: widget.allowedRange,
            showSystemSwitch: widget.showSystemSwitch,
            holidays: widget.holidays,
            selectableDates: widget.selectableDates,
          ),
          ListenableBuilder(
            listenable: _controller,
            builder: (BuildContext context, Widget? child) {
              final NepaliCalendarSelection? result = _result;
              final bool nepali = _controller.language.isNepali;
              // Only shown when the sheet opened on a value the caller
              // already held (initialSelection) — not just because the user
              // has tapped a day in this session. Clear means "remove what
              // was there before", not "undo my in-progress pick" (Cancel
              // already does that).
              final bool hasInitialSelection =
                  _initialSelection?.date != null ||
                  _initialSelection?.range != null;
              // Tinted red rather than neutral: unlike Cancel, Clear discards
              // a value irreversibly, so it earns a touch of warning colour.
              // Blended from the theme's own textColor rather than a flat
              // hex, so it keeps reasonable contrast in both light and dark
              // themes instead of one hard-coded shade fighting either.
              final Color clearColor = Color.lerp(
                theme.textColor,
                const Color(0xFFD32F2F),
                0.6,
              )!;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        if (widget.showClearButton &&
                            hasInitialSelection) ...<Widget>[
                          // Same shape and height as Cancel — just not
                          // Expanded, so it reads as a compact tertiary
                          // action beside the two full-width primary ones.
                          OutlinedButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pop(const NepaliCalendarSelection.cleared()),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: clearColor,
                              side: BorderSide(
                                color: clearColor.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              widget.clearLabel ??
                                  (nepali ? 'हटाउनुहोस्' : 'Clear'),
                              style: theme.applyFont(const TextStyle()),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.textColor,
                              side: BorderSide(color: theme.dividerColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              widget.cancelLabel ??
                                  (nepali ? 'रद्द' : 'Cancel'),
                              style: theme.applyFont(const TextStyle()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: result == null
                                ? null
                                : () => Navigator.of(context).pop(result),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: theme.headerTextColor,
                              // Derived from the calendar's own palette, not the
                              // ambient one: a dark calendar inside a light app
                              // would otherwise take Material's light disabled
                              // colours and vanish against its own background.
                              disabledBackgroundColor: theme.textColor
                                  .withValues(alpha: 0.12),
                              disabledForegroundColor: theme.textColor
                                  .withValues(alpha: 0.38),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              widget.confirmLabel ??
                                  (nepali ? 'ठीक छ' : 'Done'),
                              style: theme.applyFont(const TextStyle()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
