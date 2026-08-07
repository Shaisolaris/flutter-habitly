import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_habitly/core/logic/streaks.dart';
import 'package:flutter_habitly/core/models/check_in.dart';
import 'package:flutter_habitly/core/models/habit.dart';

/// Every expected value below was hand-traced against the algorithm before
/// being written down here (see the PR description / commit history), then
/// cross-checked with an independent re-implementation. Dates use
/// [DateTime.weekday]'s Monday=1..Sunday=7 convention throughout.
void main() {
  final dailyHabit = Habit(
    id: 'h-daily',
    name: 'Drink water',
    emoji: '💧',
    frequency: const {1, 2, 3, 4, 5, 6, 7},
    createdAt: DateTime(2026, 7, 20), // a Monday
  );

  // Monday/Wednesday/Friday habit, created Monday 2026-08-03.
  final mwfHabit = Habit(
    id: 'h-mwf',
    name: 'Morning run',
    emoji: '🏃',
    frequency: const {DateTime.monday, DateTime.wednesday, DateTime.friday},
    createdAt: DateTime(2026, 8, 3),
  );

  group('calculateCurrentStreak - daily habit', () {
    test('unbroken history counts every day including today', () {
      final checkIns = [
        for (var d = 20; d <= 26; d++) CheckIn(habitId: 'h-daily', date: DateTime(2026, 7, d)),
      ];

      final streak = calculateCurrentStreak(
        habit: dailyHabit,
        checkIns: checkIns,
        asOf: DateTime(2026, 7, 26),
      );

      expect(streak, 7);
    });

    test('an unchecked "today" is graced, not counted as a break', () {
      final checkIns = [
        for (var d = 20; d <= 25; d++) CheckIn(habitId: 'h-daily', date: DateTime(2026, 7, d)),
        // July 26 (today) has no check-in yet.
      ];

      final streak = calculateCurrentStreak(
        habit: dailyHabit,
        checkIns: checkIns,
        asOf: DateTime(2026, 7, 26),
      );

      expect(streak, 6);
    });

    test('a real gap before today stops the count there', () {
      final checkIns = [
        CheckIn(habitId: 'h-daily', date: DateTime(2026, 7, 20)),
        CheckIn(habitId: 'h-daily', date: DateTime(2026, 7, 21)),
        CheckIn(habitId: 'h-daily', date: DateTime(2026, 7, 22)),
        // July 23 missed.
        CheckIn(habitId: 'h-daily', date: DateTime(2026, 7, 24)),
        CheckIn(habitId: 'h-daily', date: DateTime(2026, 7, 25)),
        // July 26 (today) not yet checked in either.
      ];

      final streak = calculateCurrentStreak(
        habit: dailyHabit,
        checkIns: checkIns,
        asOf: DateTime(2026, 7, 26),
      );

      expect(streak, 2);
    });

    test('brand-new habit with no check-in yet on its creation day is 0', () {
      final streak = calculateCurrentStreak(
        habit: dailyHabit,
        checkIns: const [],
        asOf: DateTime(2026, 7, 20),
      );

      expect(streak, 0);
    });
  });

  group('calculateCurrentStreak - frequency-aware (Mon/Wed/Fri)', () {
    test('streak carries across non-scheduled days without breaking', () {
      // Mon Aug3, Wed Aug5, Fri Aug7 - a clean run through week one.
      final checkIns = [
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 3)),
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 5)),
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 7)),
      ];

      // Saturday Aug 8 is not scheduled; the streak should look straight
      // through Sat/Sun/Thu/Tue back to the three completed weekdays.
      final streak = calculateCurrentStreak(
        habit: mwfHabit,
        checkIns: checkIns,
        asOf: DateTime(2026, 8, 8),
      );

      expect(streak, 3);
    });

    test('a missed scheduled day breaks the streak even though today is graced', () {
      final checkIns = [
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 3)), // Mon - done
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 5)), // Wed - done
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 7)), // Fri - done
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 10)), // Mon - done
        // Wed Aug 12 missed.
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 14)), // Fri - done
      ];

      final streak = calculateCurrentStreak(
        habit: mwfHabit,
        checkIns: checkIns,
        asOf: DateTime(2026, 8, 14),
      );

      // Only the Aug 14 check-in counts; Aug 12's miss stops the count dead.
      expect(streak, 1);
    });

    test('grace period: today not yet checked in still counts recent days', () {
      final checkIns = [
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 10)), // Mon
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 12)), // Wed
        // Fri Aug 14 (today) not checked in yet.
      ];

      final streak = calculateCurrentStreak(
        habit: mwfHabit,
        checkIns: checkIns,
        asOf: DateTime(2026, 8, 14),
      );

      expect(streak, 2);
    });

    test('a real break plus an ungraced today both count as zero', () {
      final checkIns = [
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 10)), // Mon checked
        // Wed Aug 12 missed.
        // Fri Aug 14 (today) not checked in yet.
      ];

      final streak = calculateCurrentStreak(
        habit: mwfHabit,
        checkIns: checkIns,
        asOf: DateTime(2026, 8, 14),
      );

      expect(streak, 0);
    });
  });

  group('calculateBestStreak', () {
    test('is 0 for a habit with no check-ins', () {
      final streak = calculateBestStreak(habit: mwfHabit, checkIns: const [], asOf: DateTime(2026, 8, 14));
      expect(streak, 0);
    });

    test('finds the longest run across a gap, spanning non-scheduled days', () {
      final checkIns = [
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 3)), // Mon
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 5)), // Wed
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 7)), // Fri
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 10)), // Mon
        // Wed Aug 12 missed - breaks the run at 4.
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 14)), // Fri - new run of 1.
      ];

      final streak = calculateBestStreak(habit: mwfHabit, checkIns: checkIns, asOf: DateTime(2026, 8, 14));

      expect(streak, 4);
    });
  });

  group('calculateCompletionRate', () {
    test('counts only scheduled days, excluding a mid-window miss', () {
      final checkIns = [
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 3)),
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 5)),
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 7)),
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 10)),
        // Aug 12 missed.
        CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 14)),
      ];

      final rate = calculateCompletionRate(
        habit: mwfHabit,
        checkIns: checkIns,
        start: DateTime(2026, 8, 3),
        end: DateTime(2026, 8, 14),
      );

      // 5 of 6 scheduled occurrences (Mon/Wed/Fri x2 weeks) were completed.
      expect(rate, closeTo(5 / 6, 1e-9));
    });

    test('is 0.0 when the window ends before the habit was created', () {
      final rate = calculateCompletionRate(
        habit: mwfHabit,
        checkIns: const [],
        start: DateTime(2026, 8, 1),
        end: DateTime(2026, 8, 2),
      );

      expect(rate, 0.0);
    });

    test('clamps a window that starts before the habit was created', () {
      final checkIns = [
        CheckIn(habitId: 'h-daily', date: DateTime(2026, 7, 20)),
        CheckIn(habitId: 'h-daily', date: DateTime(2026, 7, 21)),
      ];

      final rate = calculateCompletionRate(
        habit: dailyHabit,
        checkIns: checkIns,
        start: DateTime(2026, 7, 1), // 19 days before the habit existed
        end: DateTime(2026, 7, 21),
      );

      // Only Jul 20-21 (the habit's actual lifetime) should be counted.
      expect(rate, 1.0);
    });
  });

  group('isHabitCompletedOn', () {
    test('true when a matching check-in exists for that day', () {
      final checkIns = [CheckIn(habitId: 'h-daily', date: DateTime(2026, 7, 20))];
      expect(isHabitCompletedOn(dailyHabit, checkIns, DateTime(2026, 7, 20)), isTrue);
    });

    test('false when there is no check-in for that day', () {
      final checkIns = [CheckIn(habitId: 'h-daily', date: DateTime(2026, 7, 20))];
      expect(isHabitCompletedOn(dailyHabit, checkIns, DateTime(2026, 7, 21)), isFalse);
    });

    test('ignores the time-of-day component of a check-in', () {
      final checkIns = [CheckIn(habitId: 'h-daily', date: DateTime(2026, 7, 20, 23, 45))];
      expect(isHabitCompletedOn(dailyHabit, checkIns, DateTime(2026, 7, 20, 6, 0)), isTrue);
    });
  });
}
