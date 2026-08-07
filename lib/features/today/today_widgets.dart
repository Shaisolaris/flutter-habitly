import 'package:flutter/material.dart';

import '../../core/models/habit.dart';

/// Animated ring showing how many of today's habits are checked in.
class HabitProgressRing extends StatelessWidget {
  const HabitProgressRing({
    super.key,
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total == 0 ? 0.0 : completed / total;

    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 148,
            height: 148,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 12,
                  strokeCap: StrokeCap.round,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                );
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$completed/$total',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'checked in',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single habit row on the Today screen: emoji, name, current streak, and
/// a tappable check-in circle.
class HabitCheckInTile extends StatelessWidget {
  const HabitCheckInTile({
    super.key,
    required this.habit,
    required this.isCompleted,
    required this.currentStreak,
    required this.onToggle,
    required this.onTap,
  });

  final Habit habit;
  final bool isCompleted;
  final int currentStreak;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: isCompleted ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(habit.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (currentStreak > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department, size: 16, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            currentStreak == 1 ? '1 day streak' : '$currentStreak day streak',
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _CheckInButton(isCompleted: isCompleted, onToggle: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckInButton extends StatelessWidget {
  const _CheckInButton({required this.isCompleted, required this.onToggle});

  final bool isCompleted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? colorScheme.primary : colorScheme.surface,
          border: Border.all(
            color: isCompleted ? colorScheme.primary : colorScheme.outline,
            width: 2,
          ),
        ),
        child: isCompleted ? Icon(Icons.check, color: colorScheme.onPrimary, size: 22) : null,
      ),
    );
  }
}

/// Shown on Today when the person hasn't created any habits yet.
class TodayEmptyState extends StatelessWidget {
  const TodayEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.self_improvement, size: 56, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text('No habits yet', style: textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first habit and start building a streak.',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown on Today when habits exist, but none are scheduled for today.
class TodayNothingScheduled extends StatelessWidget {
  const TodayNothingScheduled({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Nothing scheduled for today. Enjoy the break.',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
