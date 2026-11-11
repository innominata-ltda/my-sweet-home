/// Recurrence rule support — RFC 5545 subset.
///
/// Supported fields: FREQ, INTERVAL, COUNT, UNTIL, BYDAY, BYMONTHDAY, DTSTART.
/// Unknown fields are gracefully ignored.
///
/// All dates are handled in **UTC**. Time zone conversion is the
/// caller's responsibility.
library;

// ignore_for_file: prefer_initializing_formals

// ---------------------------------------------------------------------------
// Helper types
// ---------------------------------------------------------------------------

/// Supported recurrence frequency.
enum _Freq { daily, weekly, monthly }

/// Weekdays (RFC 5545).
enum _Weekday { mo, tu, we, th, fr, sa, su }

// ---------------------------------------------------------------------------
// RecurrenceRule
// ---------------------------------------------------------------------------

/// Recurrence rule based on RFC 5545 subset (iCalendar RRULE).
///
/// Exemplo de uso:
/// ```dart
/// final rule = RecurrenceRule.tryParse(
///   'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=15',
///   dtStart: DateTime.utc(2026, 1, 15),
/// );
/// final dates = rule!.occurrencesBetween(
///   DateTime.utc(2026, 1, 1),
///   DateTime.utc(2026, 4, 1),
/// ).toList();
/// ```
final class RecurrenceRule {
  RecurrenceRule._({
    required _Freq freq,
    required int interval,
    required DateTime dtStart,
    int? count,
    DateTime? until,
    List<_Weekday>? byDay,
    int? byMonthDay,
  }) : _freq = freq,
       _interval = interval,
       _dtStart = dtStart,
       _count = count,
       _until = until,
       _byDay = byDay,
       _byMonthDay = byMonthDay;

  final _Freq _freq;
  final int _interval;
  final DateTime _dtStart;
  final int? _count;
  final DateTime? _until;
  final List<_Weekday>? _byDay;
  final int? _byMonthDay;

  // -------------------------------------------------------------------------
  // Parser
  // -------------------------------------------------------------------------

  /// Parses an RRULE string (with or without `RRULE:` prefix).
  ///
  /// Returns `null` if the string is invalid (missing or unknown FREQ).
  ///
  /// [dtStart] is the default start point when string does not contain
  /// `DTSTART`. If both are present, embedded `DTSTART` takes precedence.
  static RecurrenceRule? tryParse(String rrule, {DateTime? dtStart}) {
    // Accepts "RRULE:FREQ=..." with or without prefix.
    final cleaned = rrule.startsWith('RRULE:') ? rrule.substring(6) : rrule;

    final parts = cleaned.split(';');
    final map = <String, String>{};
    for (final part in parts) {
      final idx = part.indexOf('=');
      if (idx < 0) continue;
      final key = part.substring(0, idx).toUpperCase().trim();
      final value = part.substring(idx + 1).trim();
      map[key] = value;
    }

    // Required FREQ
    final freqStr = map['FREQ'];
    if (freqStr == null) return null;
    final freq = switch (freqStr.toUpperCase()) {
      'DAILY' => _Freq.daily,
      'WEEKLY' => _Freq.weekly,
      'MONTHLY' => _Freq.monthly,
      _ => null,
    };
    if (freq == null) return null;

    // INTERVAL
    final intervalStr = map['INTERVAL'];
    final interval = intervalStr != null ? (int.tryParse(intervalStr) ?? 1) : 1;
    if (interval < 1) return null;

    // COUNT
    final countStr = map['COUNT'];
    final count = countStr != null ? int.tryParse(countStr) : null;

    // UNTIL
    final untilStr = map['UNTIL'];
    final until = untilStr != null ? _parseICalDate(untilStr) : null;

    // BYDAY
    final byDayStr = map['BYDAY'];
    List<_Weekday>? byDay;
    if (byDayStr != null) {
      byDay = byDayStr
          .split(',')
          .map((s) => _parseWeekday(s.trim().toUpperCase()))
          .whereType<_Weekday>()
          .toList();
      if (byDay.isEmpty) byDay = null;
    }

    // BYMONTHDAY
    final byMonthDayStr = map['BYMONTHDAY'];
    final byMonthDay = byMonthDayStr != null
        ? int.tryParse(byMonthDayStr)
        : null;

    // Embedded DTSTART takes precedence over parameter
    final dtStartStr = map['DTSTART'];
    final resolvedDtStart =
        (dtStartStr != null ? _parseICalDate(dtStartStr) : null) ??
        dtStart ??
        DateTime.utc(0);

    return RecurrenceRule._(
      freq: freq,
      interval: interval,
      dtStart: resolvedDtStart,
      count: count,
      until: until,
      byDay: byDay,
      byMonthDay: byMonthDay,
    );
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Returns occurrences in the closed interval `[from, to]`.
  Iterable<DateTime> occurrencesBetween(DateTime from, DateTime to) sync* {
    int emitted = 0;
    for (final occurrence in _generateAll()) {
      if (occurrence.isAfter(to)) break;
      final count = _count;
      if (count != null && emitted >= count) break;
      if (!occurrence.isBefore(from)) {
        yield occurrence;
        emitted++;
      }
    }
  }

  /// Returns the next occurrence strictly after [instant], or `null` if
  /// there are no further occurrences.
  DateTime? nextAfter(DateTime instant) {
    for (final occurrence in _generateAll()) {
      if (occurrence.isAfter(instant)) return occurrence;
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Internal generation
  // -------------------------------------------------------------------------

  /// Infinite generator (bounded by COUNT or UNTIL internally).
  Iterable<DateTime> _generateAll() sync* {
    final count = _count;
    final until = _until;
    int emitted = 0;

    switch (_freq) {
      case _Freq.daily:
        var current = _dtStart;
        while (true) {
          if (until != null && current.isAfter(until)) break;
          if (count != null && emitted >= count) break;
          yield current;
          emitted++;
          current = current.add(Duration(days: _interval));
        }

      case _Freq.weekly:
        final days = _byDay;
        if (days == null || days.isEmpty) {
          // Sem BYDAY: repete no mesmo dia da semana.
          var current = _dtStart;
          while (true) {
            if (until != null && current.isAfter(until)) break;
            if (count != null && emitted >= count) break;
            yield current;
            emitted++;
            current = current.add(Duration(days: 7 * _interval));
          }
        } else {
          // With BYDAY: iterate weeks and emit specified days in order.
          // First Monday of week containing _dtStart.
          final startOfWeek = _mondayOf(_dtStart);
          var weekStart = startOfWeek;

          outer:
          while (true) {
            // Days of the current week in order (Mon->Sun)
            final weekdayOrder = [
              _Weekday.mo,
              _Weekday.tu,
              _Weekday.we,
              _Weekday.th,
              _Weekday.fr,
              _Weekday.sa,
              _Weekday.su,
            ];
            for (final wd in weekdayOrder) {
              if (!days.contains(wd)) continue;
              final candidate = weekStart.add(
                Duration(days: _weekdayOffset(wd)),
              );
              if (candidate.isBefore(_dtStart)) continue;
              if (until != null && candidate.isAfter(until)) break outer;
              if (count != null && emitted >= count) break outer;
              yield candidate;
              emitted++;
            }
            weekStart = weekStart.add(Duration(days: 7 * _interval));
          }
        }

      case _Freq.monthly:
        final targetDay = _byMonthDay;
        if (targetDay != null) {
          // Start month: clamp logic.
          var year = _dtStart.year;
          var month = _dtStart.month;

          while (true) {
            final day = _clampDay(targetDay, year, month);
            final candidate = DateTime.utc(year, month, day);
            if (until != null && candidate.isAfter(until)) break;
            if (count != null && emitted >= count) break;
            if (!candidate.isBefore(_dtStart)) {
              yield candidate;
              emitted++;
            }
            // Advance [_interval] months
            month += _interval;
            while (month > 12) {
              month -= 12;
              year++;
            }
          }
        } else {
          // Without BYMONTHDAY: repeats on the same day of the month.
          var year = _dtStart.year;
          var month = _dtStart.month;
          final day = _dtStart.day;

          while (true) {
            final clampedDay = _clampDay(day, year, month);
            final candidate = DateTime.utc(year, month, clampedDay);
            if (until != null && candidate.isAfter(until)) break;
            if (count != null && emitted >= count) break;
            if (!candidate.isBefore(_dtStart)) {
              yield candidate;
              emitted++;
            }
            month += _interval;
            while (month > 12) {
              month -= 12;
              year++;
            }
          }
        }
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Clamps [day] to the last valid day of [year]/[month].
  static int _clampDay(int day, int year, int month) {
    final lastDay = _daysInMonth(year, month);
    return day > lastDay ? lastDay : day;
  }

  /// Number of days in month.
  static int _daysInMonth(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  /// Monday of the week containing [date].
  static DateTime _mondayOf(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

  /// Offset in days from Monday to the given [weekday].
  static int _weekdayOffset(_Weekday wd) => switch (wd) {
    _Weekday.mo => 0,
    _Weekday.tu => 1,
    _Weekday.we => 2,
    _Weekday.th => 3,
    _Weekday.fr => 4,
    _Weekday.sa => 5,
    _Weekday.su => 6,
  };

  /// Parses date in iCalendar format: `YYYYMMDDTHHMMSSZ` or `YYYYMMDD`.
  static DateTime? _parseICalDate(String s) {
    // Strip Z suffix
    final clean = s.endsWith('Z') ? s.substring(0, s.length - 1) : s;
    // Strip T separator
    final flat = clean.replaceAll('T', '');
    if (flat.length == 8) {
      // YYYYMMDD
      final year = int.tryParse(flat.substring(0, 4));
      final month = int.tryParse(flat.substring(4, 6));
      final day = int.tryParse(flat.substring(6, 8));
      if (year == null || month == null || day == null) return null;
      return DateTime.utc(year, month, day);
    }
    if (flat.length == 14) {
      // YYYYMMDDHHMMSS
      final year = int.tryParse(flat.substring(0, 4));
      final month = int.tryParse(flat.substring(4, 6));
      final day = int.tryParse(flat.substring(6, 8));
      final hour = int.tryParse(flat.substring(8, 10));
      final min = int.tryParse(flat.substring(10, 12));
      final sec = int.tryParse(flat.substring(12, 14));
      if (year == null ||
          month == null ||
          day == null ||
          hour == null ||
          min == null ||
          sec == null) {
        return null;
      }
      return DateTime.utc(year, month, day, hour, min, sec);
    }
    return null;
  }

  /// Parses weekday abbreviation.
  static _Weekday? _parseWeekday(String s) => switch (s) {
    'MO' => _Weekday.mo,
    'TU' => _Weekday.tu,
    'WE' => _Weekday.we,
    'TH' => _Weekday.th,
    'FR' => _Weekday.fr,
    'SA' => _Weekday.sa,
    'SU' => _Weekday.su,
    _ => null,
  };

  @override
  String toString() {
    final buf = StringBuffer('RecurrenceRule(FREQ=${_freq.name.toUpperCase()}');
    if (_interval != 1) buf.write(';INTERVAL=$_interval');
    final count = _count;
    if (count != null) buf.write(';COUNT=$count');
    final until = _until;
    if (until != null) buf.write(';UNTIL=$until');
    final byDay = _byDay;
    if (byDay != null) {
      buf.write(';BYDAY=${byDay.map((d) => d.name.toUpperCase()).join(',')}');
    }
    final byMonthDay = _byMonthDay;
    if (byMonthDay != null) buf.write(';BYMONTHDAY=$byMonthDay');
    buf.write(')');
    return buf.toString();
  }
}
