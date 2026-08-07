import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/date_labels.dart';
import '../../core/logic/streaks.dart';
import '../../data/app_providers.dart';
import '../edit_habit/edit_habit_screen.dart';
import 'today_widgets.dart';

/// The home screen: today's habits with check-in toggles, and an animated
/// progress ring that fills in as they're completed.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(habitsControllerProvider);
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habitly'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const EditHabitScreen()),
        ),
        tooltip: 'New habit',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => _TodayError(error: error),
          data: (data) {
            if (data.habits.isEmpty) {
              return const TodayEmptyState();
            }

            final todaysHabits = data.habits.where((habit) => habit.isScheduledOn(today)).toList()
              ..sort((a, b) => a.name.compareTo(b.name));
            final completedCount =
                todaysHabits.where((habit) => isHabitCompletedOn(habit, data.checkIns, today)).length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              children: [
                Text(
                  DateLabels.fullDate(today),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Center(
                  child: HabitProgressRing(completed: completedCount, total: todaysHabits.length),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _summary(completedCount, todaysHabits.length),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),
                if (todaysHabits.isEmpty)
                  const TodayNothingScheduled()
                else
                  for (final habit in todaysHabits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: HabitCheckInTile(
                        habit: habit,
                        isCompleted: isHabitCompletedOn(habit, data.checkIns, today),
                        currentStreak: calculateCurrentStreak(
                          habit: habit,
                          checkIns: data.checkIns,
                          asOf: today,
                        ),
                        onToggle: () => ref.read(habitsControllerProvider.notifier).toggleCheckIn(habit.id, today),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => EditHabitScreen(habit: habit)),
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

  String _summary(int completed, int total) {
    if (total == 0) return 'No habits scheduled for today.';
    if (completed == total) return 'All done for today. Nice work.';
    final remaining = total - completed;
    return remaining == 1 ? '1 habit left to check in.' : '$remaining habits left to check in.';
  }
}

class _TodayError extends StatelessWidget {
  const _TodayError({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Could not load your habits.\n$error', textAlign: TextAlign.center),
      ),
    );
  }
}
