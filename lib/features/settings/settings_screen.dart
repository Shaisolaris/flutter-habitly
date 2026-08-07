import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_providers.dart';
import 'settings_widgets.dart';

/// Reminder time, week-start day, and a guarded "reset all data" action.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load settings.\n$error', textAlign: TextAlign.center),
            ),
          ),
          data: (settings) {
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const SettingsSectionHeader(title: 'Reminders'),
                ReminderTimeTile(
                  hour: settings.reminderHour,
                  minute: settings.reminderMinute,
                  onChanged: (hour, minute) =>
                      ref.read(settingsControllerProvider.notifier).updateReminderTime(hour: hour, minute: minute),
                ),
                const Divider(height: 32),
                const SettingsSectionHeader(title: 'Calendar'),
                WeekStartTile(
                  weekStartDay: settings.weekStartDay,
                  onChanged: (weekday) => ref.read(settingsControllerProvider.notifier).updateWeekStartDay(weekday),
                ),
                const Divider(height: 32),
                const SettingsSectionHeader(title: 'Data'),
                ResetDataTile(
                  onConfirmedReset: () => ref.read(habitsControllerProvider.notifier).resetAllData(),
                ),
                const SizedBox(height: 24),
                const AppFooter(),
              ],
            );
          },
        ),
      ),
    );
  }
}
