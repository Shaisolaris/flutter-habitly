import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/app_settings.dart';
import '../core/models/check_in.dart';
import '../core/models/habit.dart';
import '../core/seed/seed_data.dart';
import 'habit_repository.dart';

/// Provided a real value in `main()` once [SharedPreferences.getInstance]
/// has resolved; never read before then.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden before use.');
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return SharedPreferencesHabitRepository(ref.watch(sharedPreferencesProvider));
});

/// Immutable snapshot of everything the Today/Stats screens need.
class HabitlyData {
  const HabitlyData({required this.habits, required this.checkIns});

  const HabitlyData.empty()
      : habits = const <Habit>[],
        checkIns = const <CheckIn>[];

  final List<Habit> habits;
  final List<CheckIn> checkIns;

  HabitlyData copyWith({List<Habit>? habits, List<CheckIn>? checkIns}) {
    return HabitlyData(
      habits: habits ?? this.habits,
      checkIns: checkIns ?? this.checkIns,
    );
  }
}

/// Owns habit and check-in state: loads it on startup (seeding demo data on
/// a genuine first run), and applies every mutation to both in-memory state
/// and persistent storage together so they can never drift apart.
class HabitsController extends StateNotifier<AsyncValue<HabitlyData>> {
  HabitsController(this._repository) : super(const AsyncValue.loading()) {
    _initialize();
  }

  final HabitRepository _repository;

  Future<void> _initialize() async {
    try {
      final seededBefore = await _repository.hasSeededBefore();
      if (!seededBefore) {
        final seededData = await _seedFreshData();
        state = AsyncValue.data(seededData);
        return;
      }

      final habits = await _repository.loadHabits();
      final checkIns = await _repository.loadCheckIns();
      state = AsyncValue.data(HabitlyData(habits: habits, checkIns: checkIns));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<HabitlyData> _seedFreshData() async {
    final seededHabits = buildSeedHabits();
    final seededCheckIns = buildSeedCheckIns(seededHabits);
    await _repository.saveHabits(seededHabits);
    await _repository.saveCheckIns(seededCheckIns);
    await _repository.markSeeded();
    return HabitlyData(habits: seededHabits, checkIns: seededCheckIns);
  }

  /// Flips whether [habitId] is checked in on [date].
  Future<void> toggleCheckIn(String habitId, DateTime date) async {
    final current = state.value;
    if (current == null) return;

    final day = DateTime(date.year, date.month, date.day);
    final alreadyChecked = current.checkIns.any(
      (checkIn) => checkIn.habitId == habitId && _isSameDay(checkIn.date, day),
    );

    final updatedCheckIns = alreadyChecked
        ? current.checkIns.where((checkIn) => !(checkIn.habitId == habitId && _isSameDay(checkIn.date, day))).toList()
        : (List<CheckIn>.from(current.checkIns)..add(CheckIn(habitId: habitId, date: day)));

    state = AsyncValue.data(current.copyWith(checkIns: updatedCheckIns));
    await _repository.saveCheckIns(updatedCheckIns);
  }

  Future<void> addHabit(Habit habit) async {
    final current = state.value;
    if (current == null) return;

    final updatedHabits = List<Habit>.from(current.habits)..add(habit);
    state = AsyncValue.data(current.copyWith(habits: updatedHabits));
    await _repository.saveHabits(updatedHabits);
  }

  Future<void> updateHabit(Habit habit) async {
    final current = state.value;
    if (current == null) return;

    final updatedHabits = [
      for (final existing in current.habits) if (existing.id == habit.id) habit else existing,
    ];
    state = AsyncValue.data(current.copyWith(habits: updatedHabits));
    await _repository.saveHabits(updatedHabits);
  }

  Future<void> deleteHabit(String habitId) async {
    final current = state.value;
    if (current == null) return;

    final updatedHabits = current.habits.where((habit) => habit.id != habitId).toList();
    final updatedCheckIns = current.checkIns.where((checkIn) => checkIn.habitId != habitId).toList();

    state = AsyncValue.data(HabitlyData(habits: updatedHabits, checkIns: updatedCheckIns));
    await _repository.saveHabits(updatedHabits);
    await _repository.saveCheckIns(updatedCheckIns);
  }

  /// Erases all habits and check-ins, then restores Habitly's original
  /// demo content - a predictable "factory reset" rather than leaving the
  /// person opening Settings with an empty app.
  Future<void> resetAllData() async {
    await _repository.resetHabitData();
    final seededData = await _seedFreshData();
    state = AsyncValue.data(seededData);
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

final habitsControllerProvider = StateNotifierProvider<HabitsController, AsyncValue<HabitlyData>>((ref) {
  return HabitsController(ref.watch(habitRepositoryProvider));
});

/// Owns reminder-time and week-start-day preferences.
class SettingsController extends StateNotifier<AsyncValue<AppSettings>> {
  SettingsController(this._repository) : super(const AsyncValue.loading()) {
    _initialize();
  }

  final HabitRepository _repository;

  Future<void> _initialize() async {
    try {
      final settings = await _repository.loadSettings();
      state = AsyncValue.data(settings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateReminderTime({required int hour, required int minute}) async {
    final current = state.value ?? AppSettings.defaults();
    final updated = current.copyWith(reminderHour: hour, reminderMinute: minute);
    state = AsyncValue.data(updated);
    await _repository.saveSettings(updated);
  }

  Future<void> updateWeekStartDay(int weekday) async {
    final current = state.value ?? AppSettings.defaults();
    final updated = current.copyWith(weekStartDay: weekday);
    state = AsyncValue.data(updated);
    await _repository.saveSettings(updated);
  }
}

final settingsControllerProvider = StateNotifierProvider<SettingsController, AsyncValue<AppSettings>>((ref) {
  return SettingsController(ref.watch(habitRepositoryProvider));
});
