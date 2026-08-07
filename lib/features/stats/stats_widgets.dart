import 'package:flutter/material.dart';

import '../../core/constants/date_labels.dart';
import '../../core/logic/heatmap.dart';
import '../../core/models/habit.dart';

/// 4-week grid of daily completion intensity, GitHub-contributions style.
class ConsistencyHeatmap extends StatelessWidget {
  const ConsistencyHeatmap({super.key, required this.weeks});

  final List<HeatmapWeek> weeks;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (weeks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final day in weeks.first.days)
              Expanded(
                child: Center(
                  child: Text(
                    DateLabels.shortWeekday(day.date.weekday).substring(0, 1),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (final week in weeks)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (final day in week.days)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: _cellColor(day, colorScheme),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('less', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 6),
            for (final level in const [0.0, 0.5, 1.0])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: _intensityColor(level, colorScheme),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 6),
            Text('more', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Color _cellColor(HeatmapDay day, ColorScheme colorScheme) {
    if (day.isFuture || day.scheduled == 0) return colorScheme.surfaceContainerHighest;
    return _intensityColor(day.intensity, colorScheme);
  }

  Color _intensityColor(double intensity, ColorScheme colorScheme) {
    if (intensity <= 0) return colorScheme.surfaceContainerHighest;
    final clamped = intensity.clamp(0.0, 1.0).toDouble();
    return Color.lerp(colorScheme.primaryContainer, colorScheme.primary, clamped)!;
  }
}

/// One habit's streaks and 4-week completion rate.
class HabitStatsCard extends StatelessWidget {
  const HabitStatsCard({
    super.key,
    required this.habit,
    required this.currentStreak,
    required this.bestStreak,
    required this.completionRate,
  });

  final Habit habit;
  final int currentStreak;
  final int bestStreak;
  final double completionRate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final percent = (completionRate * 100).round();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(habit.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    habit.name,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatChip(icon: Icons.local_fire_department, label: '$currentStreak current'),
                const SizedBox(width: 8),
                _StatChip(icon: Icons.emoji_events, label: '$bestStreak best'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last 4 weeks',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                Text(
                  '$percent%',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: completionRate.clamp(0.0, 1.0).toDouble(),
                minHeight: 8,
                backgroundColor: colorScheme.surface,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown on Stats when there are no habits to report on yet.
class StatsEmptyState extends StatelessWidget {
  const StatsEmptyState({super.key});

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
            Icon(Icons.insights_outlined, size: 56, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text('No stats yet', style: textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Add a habit and start checking in to see your streaks and trends here.',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
