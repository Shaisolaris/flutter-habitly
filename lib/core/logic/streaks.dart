import '../models/check_in.dart';
import '../models/habit.dart';
import 'date_math.dart';

/// Pure, UI-independent streak and completion-rate math.
///
/// Every function here treats a habit's non-scheduled days as transparent:
/// they are skipped over and never break a streak. Only days the habit is
/// actually scheduled on (per [Habit.isScheduledOn]) count towards a streak
/// or a completion rate.

/// Returns true if [habit] has a recorded check-in on [date].
bool isHabitCompletedOn(Habit habit, List<CheckIn> checkIns, DateTime date) {
  final target = dateOnly(date);
  return checkIns.any(
    (checkIn) => checkIn.habitId == habit.id && dateOnly(checkIn.date) == target,
  );
}

/// The current, ongoing streak for [habit] as of [asOf] (usually "today").
///
/// Walks backwards from [asOf], counting consecutive *scheduled* days that
/// have a check-in. Non-scheduled days are skipped without breaking the
/// streak. If [asOf] itself is scheduled but not yet checked in, it is
/// given a one-day grace period (it doesn't break the streak) so a habit
/// doesn't look "reset" the moment a new day starts, before the user has
/// had a chance to check in.
int calculateCurrentStreak({
  required Habit habit,
  required List<CheckIn> checkIns,
  required DateTime asOf,
}) {
  final completedDates = _completedDateSet(habit.id, checkIns);
  final createdDate = dateOnly(habit.createdAt);
  var cursor = dateOnly(asOf);

  if (habit.isScheduledOn(cursor) && !completedDates.contains(cursor)) {
    cursor = addCalendarDays(cursor, -1);
  }

  var streak = 0;
  while (!cursor.isBefore(createdDate)) {
    if (habit.isScheduledOn(cursor)) {
      if (completedDates.contains(cursor)) {
        streak++;
      } else {
        break;
      }
    }
    cursor = addCalendarDays(cursor, -1);
  }
  return streak;
}

/// The longest streak [habit] has ever had, scanning its entire history
/// from [Habit.createdAt] through [asOf].
int calculateBestStreak({
  required Habit habit,
  required List<CheckIn> checkIns,
  required DateTime asOf,
}) {
  final completedDates = _completedDateSet(habit.id, checkIns);
  if (completedDates.isEmpty) return 0;

  final createdDate = dateOnly(habit.createdAt);
  final endDate = dateOnly(asOf);

  var best = 0;
  var running = 0;
  var cursor = createdDate;
  while (!cursor.isAfter(endDate)) {
    if (habit.isScheduledOn(cursor)) {
      if (completedDates.contains(cursor)) {
        running++;
        if (running > best) best = running;
      } else {
        running = 0;
      }
    }
    cursor = addCalendarDays(cursor, 1);
  }
  return best;
}

/// Fraction (0.0-1.0) of [habit]'s scheduled days between [start] and [end]
/// (inclusive) that have a check-in. Days before [Habit.createdAt] are
/// excluded from both the numerator and denominator. Returns 0.0 if the
/// habit had no scheduled days in the window.
double calculateCompletionRate({
  required Habit habit,
  required List<CheckIn> checkIns,
  required DateTime start,
  required DateTime end,
}) {
  final completedDates = _completedDateSet(habit.id, checkIns);
  final createdDate = dateOnly(habit.createdAt);
  final endDate = dateOnly(end);

  var scheduled = 0;
  var completed = 0;
  var cursor = dateOnly(start);
  if (cursor.isBefore(createdDate)) cursor = createdDate;

  while (!cursor.isAfter(endDate)) {
    if (habit.isScheduledOn(cursor)) {
      scheduled++;
      if (completedDates.contains(cursor)) completed++;
    }
    cursor = addCalendarDays(cursor, 1);
  }

  if (scheduled == 0) return 0.0;
  return completed / scheduled;
}

Set<DateTime> _completedDateSet(String habitId, List<CheckIn> checkIns) {
  return checkIns
      .where((checkIn) => checkIn.habitId == habitId)
      .map((checkIn) => dateOnly(checkIn.date))
      .toSet();
}
