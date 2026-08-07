import 'package:flutter/material.dart';

import '../../core/constants/date_labels.dart';
import '../../core/constants/habit_emojis.dart';
import '../../core/models/habit.dart';

/// A 6-wide grid of emoji options for a habit's icon.
class EmojiPickerGrid extends StatelessWidget {
  const EmojiPickerGrid({
    super.key,
    required this.selectedEmoji,
    required this.onSelected,
  });

  final String selectedEmoji;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: habitEmojiOptions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final emoji = habitEmojiOptions[index];
        final isSelected = emoji == selectedEmoji;
        return InkWell(
          onTap: () => onSelected(emoji),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        );
      },
    );
  }
}

/// Lets the person pick "every day" or specific weekdays for a habit.
class FrequencySelector extends StatelessWidget {
  const FrequencySelector({
    super.key,
    required this.isDaily,
    required this.selectedWeekdays,
    required this.onDailySelected,
    required this.onCustomSelected,
    required this.onWeekdayToggled,
  });

  final bool isDaily;
  final Set<int> selectedWeekdays;
  final VoidCallback onDailySelected;
  final VoidCallback onCustomSelected;
  final ValueChanged<int> onWeekdayToggled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Every day'),
                selected: isDaily,
                onSelected: (_) => onDailySelected(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Text('Specific days'),
                selected: !isDaily,
                onSelected: (_) => onCustomSelected(),
              ),
            ),
          ],
        ),
        if (!isDaily) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final weekday in Habit.allWeekdays)
                FilterChip(
                  label: Text(DateLabels.shortWeekday(weekday)),
                  selected: selectedWeekdays.contains(weekday),
                  onSelected: (_) => onWeekdayToggled(weekday),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
