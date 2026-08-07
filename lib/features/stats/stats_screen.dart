import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logic/date_math.dart';
import '../../core/logic/heatmap.dart';
import '../../core/logic/streaks.dart';
import '../../data/app_providers.dart';
import 'stats_widgets.dart';

/// Streaks, completion-rate bars, and a 4-week consistency heatmap.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(habitsControllerProvider);
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: SafeArea(
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load your stats.\n$error', textAlign: TextAlign.center),
            ),
          ),
          data: (data) {
            if (data.habits.isEmpty) {
              return const StatsEmptyState();
            }

            final today = DateTime.now();
            final weekStartDay = settingsAsync.value?.weekStartDay ?? DateTime.monday;
            final heatmapWeeks = buildConsistencyHeatmap(
              habits: data.habits,
              checkIns: data.checkIns,
              endDate: today,
              weekStartDay: weekStartDay,
            );

            final sortedHabits = [...data.habits]..sort((a, b) => a.name.compareTo(b.name));
            final statsWindowStart = addCalendarDays(dateOnly(today), -27);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Text('4-week consistency', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ConsistencyHeatmap(weeks: heatmapWeeks),
                const SizedBox(height: 28),
                Text('Your habits', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                for (final habit in sortedHabits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: HabitStatsCard(
                      habit: habit,
                      currentStreak: calculateCurrentStreak(
                        habit: habit,
                        checkIns: data.checkIns,
                        asOf: today,
                      ),
                      bestStreak: calculateBestStreak(
                        habit: habit,
                        checkIns: data.checkIns,
                        asOf: today,
                      ),
                      completionRate: calculateCompletionRate(
                        habit: habit,
                        checkIns: data.checkIns,
                        start: statsWindowStart,
                        end: today,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
