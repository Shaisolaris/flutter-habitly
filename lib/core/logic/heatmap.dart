import '../models/check_in.dart';
import '../models/habit.dart';
import 'date_math.dart';

/// One day's worth of aggregated check-in data for the consistency heatmap.
class HeatmapDay {
  const HeatmapDay({
    required this.date,
    required this.completed,
    required this.scheduled,
    this.isFuture = false,
  });

  final DateTime date;

  /// How many habits were checked in on this day.
  final int completed;

  /// How many habits were scheduled on this day (across habits that
  /// existed by this date). Zero means "no data" - either nothing was
  /// scheduled, or the day hasn't happened yet (see [isFuture]).
  final int scheduled;

  /// True for days after the heatmap's end date - they haven't happened
  /// yet, so they're rendered as empty rather than "missed".
  final bool isFuture;

  /// Fraction (0.0-1.0) of scheduled habits completed on this day.
  double get intensity => scheduled == 0 ? 0.0 : completed / scheduled;
}

/// A single 7-day row of the heatmap, starting on [weekStart].
class HeatmapWeek {
  const HeatmapWeek({
    required this.weekStart,
    required this.days,
  });

  final DateTime weekStart;
  final List<HeatmapDay> days;
}

/// Buckets check-in history across all [habits] into [weeks] full 7-day
/// weeks (oldest first), ending with the week that contains [endDate].
///
/// Weeks start on [weekStartDay] ([DateTime.monday] by default, following
/// the same convention as [DateTime.weekday]). Days before a habit's
/// [Habit.createdAt] are not counted as scheduled for it, and days after
/// [endDate] are marked [HeatmapDay.isFuture] instead of "missed".
List<HeatmapWeek> buildConsistencyHeatmap({
  required List<Habit> habits,
  required List<CheckIn> checkIns,
  required DateTime endDate,
  int weeks = 4,
  int weekStartDay = DateTime.monday,
}) {
  assert(weeks > 0, 'weeks must be positive');

  final endDay = dateOnly(endDate);
  final currentWeekStart = _startOfWeek(endDay, weekStartDay);
  final firstWeekStart = addCalendarDays(currentWeekStart, -7 * (weeks - 1));

  final completedByHabit = <String, Set<DateTime>>{};
  for (final checkIn in checkIns) {
    completedByHabit.putIfAbsent(checkIn.habitId, () => <DateTime>{}).add(dateOnly(checkIn.date));
  }

  final result = <HeatmapWeek>[];
  for (var week = 0; week < weeks; week++) {
    final weekStart = addCalendarDays(firstWeekStart, 7 * week);
    final days = <HeatmapDay>[];

    for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = addCalendarDays(weekStart, dayOffset);

      if (date.isAfter(endDay)) {
        days.add(HeatmapDay(date: date, completed: 0, scheduled: 0, isFuture: true));
        continue;
      }

      var scheduled = 0;
      var completed = 0;
      for (final habit in habits) {
        if (date.isBefore(dateOnly(habit.createdAt))) continue;
        if (!habit.isScheduledOn(date)) continue;
        scheduled++;
        if (completedByHabit[habit.id]?.contains(date) ?? false) {
          completed++;
        }
      }
      days.add(HeatmapDay(date: date, completed: completed, scheduled: scheduled));
    }

    result.add(HeatmapWeek(weekStart: weekStart, days: days));
  }
  return result;
}

/// The most recent date on or before [date] that falls on [weekStartDay].
DateTime _startOfWeek(DateTime date, int weekStartDay) {
  final normalized = dateOnly(date);
  final diff = (normalized.weekday - weekStartDay) % 7;
  return addCalendarDays(normalized, -diff);
}
