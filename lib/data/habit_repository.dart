import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/app_settings.dart';
import '../core/models/check_in.dart';
import '../core/models/habit.dart';

/// Persistence contract for everything Habitly stores locally.
///
/// Kept as an abstraction - rather than calling `shared_preferences`
/// directly from widgets or controllers - so the app's state layer can be
/// unit tested against a real (but in-memory-backed) implementation, and so
/// the storage backend could be swapped later without touching feature
/// code.
abstract class HabitRepository {
  Future<List<Habit>> loadHabits();
  Future<void> saveHabits(List<Habit> habits);

  Future<List<CheckIn>> loadCheckIns();
  Future<void> saveCheckIns(List<CheckIn> checkIns);

  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);

  /// Whether the demo/seed content has already been generated once before.
  /// Used to tell "first launch ever" apart from "the user deleted every
  /// habit", which should stay empty rather than being re-seeded.
  Future<bool> hasSeededBefore();
  Future<void> markSeeded();

  /// Wipes all habits and check-in history. Settings (reminder time, week
  /// start day) are left untouched.
  Future<void> resetHabitData();
}

/// [HabitRepository] implementation backed by [SharedPreferences]. Each
/// collection is stored as a single JSON-encoded string.
class SharedPreferencesHabitRepository implements HabitRepository {
  SharedPreferencesHabitRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String habitsKey = 'habitly.habits.v1';
  static const String checkInsKey = 'habitly.check_ins.v1';
  static const String settingsKey = 'habitly.settings.v1';
  static const String seededKey = 'habitly.seeded.v1';

  @override
  Future<List<Habit>> loadHabits() async {
    final raw = _prefs.getString(habitsKey);
    if (raw == null || raw.isEmpty) return <Habit>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((dynamic item) => Habit.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveHabits(List<Habit> habits) async {
    final raw = jsonEncode(habits.map((habit) => habit.toJson()).toList());
    await _prefs.setString(habitsKey, raw);
  }

  @override
  Future<List<CheckIn>> loadCheckIns() async {
    final raw = _prefs.getString(checkInsKey);
    if (raw == null || raw.isEmpty) return <CheckIn>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((dynamic item) => CheckIn.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> saveCheckIns(List<CheckIn> checkIns) async {
    final raw = jsonEncode(checkIns.map((checkIn) => checkIn.toJson()).toList());
    await _prefs.setString(checkInsKey, raw);
  }

  @override
  Future<AppSettings> loadSettings() async {
    final raw = _prefs.getString(settingsKey);
    if (raw == null || raw.isEmpty) return AppSettings.defaults();
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(settingsKey, jsonEncode(settings.toJson()));
  }

  @override
  Future<bool> hasSeededBefore() async {
    return _prefs.getBool(seededKey) ?? false;
  }

  @override
  Future<void> markSeeded() async {
    await _prefs.setBool(seededKey, true);
  }

  @override
  Future<void> resetHabitData() async {
    await _prefs.remove(habitsKey);
    await _prefs.remove(checkInsKey);
    await _prefs.remove(seededKey);
  }
}
