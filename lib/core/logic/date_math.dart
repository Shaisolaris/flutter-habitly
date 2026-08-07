/// Calendar-safe date arithmetic helpers.
///
/// Deliberately avoid `date.add(Duration(days: n))` / `.subtract(...)`: for
/// local (non-UTC) `DateTime`s, adding a fixed-length [Duration] can land on
/// the wrong wall-clock time across a daylight-saving transition (a local
/// "day" isn't always exactly 24 hours). Rebuilding the date from its
/// calendar fields instead is DST-safe and keeps every date at local
/// midnight, which the streak and heatmap math both depend on.
library;

/// Returns local midnight, [days] calendar days after [date] (or before, if
/// [days] is negative).
DateTime addCalendarDays(DateTime date, int days) {
  return DateTime(date.year, date.month, date.day + days);
}

/// Strips the time-of-day component, returning local midnight on the same
/// calendar date.
DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}
