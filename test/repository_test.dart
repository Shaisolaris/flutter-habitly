import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_habitly/core/models/app_settings.dart';
import 'package:flutter_habitly/core/models/check_in.dart';
import 'package:flutter_habitly/core/models/habit.dart';
import 'package:flutter_habitly/data/habit_repository.dart';

void main() {
  group('SharedPreferencesHabitRepository', () {
    late SharedPreferencesHabitRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      repository = SharedPreferencesHabitRepository(prefs);
    });

    group('empty history', () {
      test('loadHabits returns an empty list when nothing is stored', () async {
        expect(await repository.loadHabits(), isEmpty);
      });

      test('loadCheckIns returns an empty list when nothing is stored', () async {
        expect(await repository.loadCheckIns(), isEmpty);
      });

      test('loadSettings returns defaults when nothing is stored', () async {
        final settings = await repository.loadSettings();
        final defaults = AppSettings.defaults();

        expect(settings.reminderHour, defaults.reminderHour);
        expect(settings.reminderMinute, defaults.reminderMinute);
        expect(settings.weekStartDay, defaults.weekStartDay);
      });

      test('hasSeededBefore is false before markSeeded is ever called', () async {
        expect(await repository.hasSeededBefore(), isFalse);
      });
    });

    test('saveHabits then loadHabits round-trips every field', () async {
      final habits = [
        Habit(
          id: 'h1',
          name: 'Morning run',
          emoji: '🏃',
          frequency: const {1, 3, 5},
          createdAt: DateTime(2026, 7, 1),
        ),
        Habit(
          id: 'h2',
          name: 'Read 20 pages',
          emoji: '📖',
          frequency: const {1, 2, 3, 4, 5, 6, 7},
          createdAt: DateTime(2026, 7, 2),
        ),
      ];

      await repository.saveHabits(habits);
      final loaded = await repository.loadHabits();

      expect(loaded, hasLength(2));
      expect(loaded[0].id, 'h1');
      expect(loaded[0].name, 'Morning run');
      expect(loaded[0].emoji, '🏃');
      expect(loaded[0].frequency, {1, 3, 5});
      expect(loaded[0].createdAt, DateTime(2026, 7, 1));
      expect(loaded[1].frequency, {1, 2, 3, 4, 5, 6, 7});
    });

    test('saveCheckIns then loadCheckIns round-trips every field', () async {
      final checkIns = [
        CheckIn(habitId: 'h1', date: DateTime(2026, 7, 2)),
        CheckIn(habitId: 'h1', date: DateTime(2026, 7, 3)),
      ];

      await repository.saveCheckIns(checkIns);
      final loaded = await repository.loadCheckIns();

      expect(loaded, hasLength(2));
      expect(loaded[0].habitId, 'h1');
      expect(loaded[0].date, DateTime(2026, 7, 2));
      expect(loaded[1].date, DateTime(2026, 7, 3));
    });

    test('saveSettings then loadSettings round-trips every field', () async {
      const settings = AppSettings(reminderHour: 7, reminderMinute: 30, weekStartDay: DateTime.sunday);

      await repository.saveSettings(settings);
      final loaded = await repository.loadSettings();

      expect(loaded.reminderHour, 7);
      expect(loaded.reminderMinute, 30);
      expect(loaded.weekStartDay, DateTime.sunday);
    });

    test('markSeeded flips hasSeededBefore to true', () async {
      expect(await repository.hasSeededBefore(), isFalse);
      await repository.markSeeded();
      expect(await repository.hasSeededBefore(), isTrue);
    });

    test('resetHabitData clears habits, check-ins, and the seeded flag, but keeps settings', () async {
      await repository.saveHabits([
        Habit(
          id: 'h1',
          name: 'Morning run',
          emoji: '🏃',
          frequency: const {1, 3, 5},
          createdAt: DateTime(2026, 7, 1),
        ),
      ]);
      await repository.saveCheckIns([
        CheckIn(habitId: 'h1', date: DateTime(2026, 7, 2)),
      ]);
      const customSettings = AppSettings(reminderHour: 6, reminderMinute: 15, weekStartDay: DateTime.sunday);
      await repository.saveSettings(customSettings);
      await repository.markSeeded();

      await repository.resetHabitData();

      expect(await repository.loadHabits(), isEmpty);
      expect(await repository.loadCheckIns(), isEmpty);
      expect(await repository.hasSeededBefore(), isFalse);

      // Settings are a separate concern from habit data and should survive.
      final settingsAfterReset = await repository.loadSettings();
      expect(settingsAfterReset.reminderHour, 6);
      expect(settingsAfterReset.reminderMinute, 15);
      expect(settingsAfterReset.weekStartDay, DateTime.sunday);
    });

    test('data persists across repository instances backed by the same prefs', () async {
      await repository.saveHabits([
        Habit(
          id: 'h1',
          name: 'Drink water',
          emoji: '💧',
          frequency: const {1, 2, 3, 4, 5, 6, 7},
          createdAt: DateTime(2026, 7, 1),
        ),
      ]);

      final samePrefs = await SharedPreferences.getInstance();
      final secondRepository = SharedPreferencesHabitRepository(samePrefs);

      final loaded = await secondRepository.loadHabits();
      expect(loaded, hasLength(1));
      expect(loaded.first.name, 'Drink water');
    });
  });
}
