import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_habitly/core/logic/heatmap.dart';
import 'package:flutter_habitly/core/models/check_in.dart';
import 'package:flutter_habitly/core/models/habit.dart';

/// Every date below was checked against a real calendar before being used
/// (2026-08-07 is a Friday), so the week-boundary math is verified against
/// ground truth rather than assumed.
void main() {
  final dailyHabit = Habit(
    id: 'h-daily',
    name: 'Read',
    emoji: '📖',
    frequency: const {1, 2, 3, 4, 5, 6, 7},
    createdAt: DateTime(2026, 7, 1),
  );

  group('buildConsistencyHeatmap - shape', () {
    test('returns exactly `weeks` weeks of exactly 7 days each', () {
      final weeks = buildConsistencyHeatmap(
        habits: [dailyHabit],
        checkIns: const [],
        endDate: DateTime(2026, 8, 7),
      );

      expect(weeks.length, 4);
      for (final week in weeks) {
        expect(week.days.length, 7);
      }
    });

    test('defaults to 4 weeks even with a custom weeks count', () {
      final weeks = buildConsistencyHeatmap(
        habits: [dailyHabit],
        checkIns: const [],
        endDate: DateTime(2026, 8, 7),
        weeks: 2,
      );

      expect(weeks.length, 2);
      expect(weeks.first.days.length, 7);
    });
  });

  group('buildConsistencyHeatmap - week boundaries (Monday start)', () {
    final weeks = buildConsistencyHeatmap(
      habits: [dailyHabit],
      checkIns: [CheckIn(habitId: 'h-daily', date: DateTime(2026, 8, 7))],
      endDate: DateTime(2026, 8, 7), // a Friday
      weekStartDay: DateTime.monday,
    );

    test('the first week starts 3 full weeks before the week containing endDate', () {
      // Aug 7 2026 is a Friday; its Monday is Aug 3. Three weeks earlier is
      // Jul 13.
      expect(weeks.first.weekStart, DateTime(2026, 7, 13));
      expect(weeks.first.weekStart.weekday, DateTime.monday);
    });

    test('the last week starts on the Monday of the week containing endDate', () {
      expect(weeks.last.weekStart, DateTime(2026, 8, 3));
    });

    test('endDate itself is included, not marked as future', () {
      final endDay = weeks.last.days.firstWhere((day) => day.date == DateTime(2026, 8, 7));
      expect(endDay.isFuture, isFalse);
      expect(endDay.scheduled, 1);
      expect(endDay.completed, 1);
    });

    test('days after endDate within the final week are marked as future', () {
      final saturday = weeks.last.days.firstWhere((day) => day.date == DateTime(2026, 8, 8));
      final sunday = weeks.last.days.firstWhere((day) => day.date == DateTime(2026, 8, 9));

      expect(saturday.isFuture, isTrue);
      expect(saturday.scheduled, 0);
      expect(sunday.isFuture, isTrue);
    });
  });

  group('buildConsistencyHeatmap - week boundaries (Sunday start)', () {
    test('weeks realign to start on Sunday instead of Monday', () {
      final weeks = buildConsistencyHeatmap(
        habits: [dailyHabit],
        checkIns: const [],
        endDate: DateTime(2026, 8, 7), // a Friday
        weekStartDay: DateTime.sunday,
      );

      expect(weeks.first.weekStart, DateTime(2026, 7, 12));
      expect(weeks.first.weekStart.weekday, DateTime.sunday);
      expect(weeks.last.weekStart, DateTime(2026, 8, 2));

      // With a Sunday-start week, Saturday Aug 8 is the last slot in the
      // final row and is still in the future relative to Friday Aug 7.
      final saturday = weeks.last.days.last;
      expect(saturday.date, DateTime(2026, 8, 8));
      expect(saturday.isFuture, isTrue);
    });
  });

  group('buildConsistencyHeatmap - habit creation boundary', () {
    test('days before a habit existed are not counted as scheduled', () {
      final midWindowHabit = Habit(
        id: 'h-mid',
        name: 'New habit',
        emoji: '🌱',
        frequency: const {1, 2, 3, 4, 5, 6, 7},
        createdAt: DateTime(2026, 7, 25),
      );

      final weeks = buildConsistencyHeatmap(
        habits: [midWindowHabit],
        checkIns: const [],
        endDate: DateTime(2026, 8, 7),
      );

      final allDays = weeks.expand((week) => week.days);
      final dayBefore = allDays.firstWhere((day) => day.date == DateTime(2026, 7, 24));
      final creationDay = allDays.firstWhere((day) => day.date == DateTime(2026, 7, 25));
      final dayAfter = allDays.firstWhere((day) => day.date == DateTime(2026, 7, 26));

      expect(dayBefore.scheduled, 0);
      expect(creationDay.scheduled, 1);
      expect(dayAfter.scheduled, 1);
    });
  });

  group('buildConsistencyHeatmap - multiple habits with different frequencies', () {
    test('only habits scheduled on a given day count towards it', () {
      final mwfHabit = Habit(
        id: 'h-mwf',
        name: 'Morning run',
        emoji: '🏃',
        frequency: const {DateTime.monday, DateTime.wednesday, DateTime.friday},
        createdAt: DateTime(2026, 7, 1),
      );

      final weeks = buildConsistencyHeatmap(
        habits: [dailyHabit, mwfHabit],
        checkIns: [
          CheckIn(habitId: 'h-daily', date: DateTime(2026, 8, 4)),
          CheckIn(habitId: 'h-mwf', date: DateTime(2026, 8, 4)),
        ],
        endDate: DateTime(2026, 8, 7),
      );

      // Aug 4 2026 is a Tuesday: only the daily habit is scheduled on it,
      // even though a (spurious) check-in exists for the Mon/Wed/Fri habit.
      final tuesday =
          weeks.expand((week) => week.days).firstWhere((day) => day.date == DateTime(2026, 8, 4));

      expect(tuesday.scheduled, 1);
      expect(tuesday.completed, 1);
    });
  });

  group('HeatmapDay.intensity', () {
    test('is 0.0 when nothing was scheduled', () {
      final day = HeatmapDay(date: DateTime(2026, 8, 7), completed: 0, scheduled: 0);
      expect(day.intensity, 0.0);
    });

    test('is the completed/scheduled fraction otherwise', () {
      final day = HeatmapDay(date: DateTime(2026, 8, 7), completed: 3, scheduled: 4);
      expect(day.intensity, 0.75);
    });
  });
}
