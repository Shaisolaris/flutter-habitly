import '../logic/date_math.dart';
import '../models/check_in.dart';
import '../models/habit.dart';

/// Demo content shown the very first time Habitly runs, before the person
/// using it has added anything of their own. Five realistic habits with
/// three weeks of plausible (deterministically generated, not random)
/// check-in history, so Stats and the heatmap have something meaningful to
/// show immediately.
const int seedHistoryDays = 21;

List<Habit> buildSeedHabits({DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  final createdAt = addCalendarDays(today, -seedHistoryDays);

  return <Habit>[
    Habit(
      id: 'habit-morning-run',
      name: 'Morning run',
      emoji: '🏃',
      frequency: const {1, 3, 5},
      createdAt: createdAt,
    ),
    Habit(
      id: 'habit-read-pages',
      name: 'Read 20 pages',
      emoji: '📖',
      frequency: const {1, 2, 3, 4, 5, 6, 7},
      createdAt: createdAt,
    ),
    Habit(
      id: 'habit-drink-water',
      name: 'Drink 8 glasses of water',
      emoji: '💧',
      frequency: const {1, 2, 3, 4, 5, 6, 7},
      createdAt: createdAt,
    ),
    Habit(
      id: 'habit-stretch',
      name: 'Stretch before bed',
      emoji: '🧘',
      frequency: const {1, 2, 3, 4, 5},
      createdAt: createdAt,
    ),
    Habit(
      id: 'habit-meal-prep',
      name: 'Meal prep',
      emoji: '🥗',
      frequency: const {7},
      createdAt: createdAt,
    ),
  ];
}

/// Generates believable check-in history for [habits]. Deterministic (no
/// `Random`): each habit's most recent scheduled occurrences are always
/// checked in - so every seeded habit opens with a visible current streak -
/// while older occurrences follow a fixed one-in-five miss pattern, offset
/// per habit so the gaps don't line up. "Today" is left unchecked so the
/// person opening the app for the first time has something to do.
List<CheckIn> buildSeedCheckIns(List<Habit> habits, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  final checkIns = <CheckIn>[];

  for (var habitIndex = 0; habitIndex < habits.length; habitIndex++) {
    final habit = habits[habitIndex];
    final scheduledDays = <DateTime>[];
    var day = dateOnly(habit.createdAt);
    while (day.isBefore(today)) {
      if (habit.isScheduledOn(day)) scheduledDays.add(day);
      day = addCalendarDays(day, 1);
    }

    final maxGuaranteed = 4 + habitIndex;
    final guaranteedStreak = maxGuaranteed < scheduledDays.length ? maxGuaranteed : scheduledDays.length;
    final streakStart = scheduledDays.length - guaranteedStreak;

    for (var i = 0; i < scheduledDays.length; i++) {
      final withinGuaranteedStreak = i >= streakStart;
      final isDeterministicMiss = !withinGuaranteedStreak && (i + habitIndex) % 5 == 0;
      if (!isDeterministicMiss) {
        checkIns.add(CheckIn(habitId: habit.id, date: scheduledDays[i]));
      }
    }
  }

  return checkIns;
}
