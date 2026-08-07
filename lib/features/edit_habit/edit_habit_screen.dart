import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/habit_emojis.dart';
import '../../core/models/habit.dart';
import '../../data/app_providers.dart';
import 'edit_habit_widgets.dart';

/// Create-or-edit form for a single habit. Passing [habit] switches the
/// screen into edit mode (pre-filled fields, a delete action); omitting it
/// creates a brand new habit.
class EditHabitScreen extends ConsumerStatefulWidget {
  const EditHabitScreen({super.key, this.habit});

  final Habit? habit;

  @override
  ConsumerState<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends ConsumerState<EditHabitScreen> {
  late final TextEditingController _nameController;
  late String _selectedEmoji;
  late Set<int> _selectedWeekdays;
  late bool _isDaily;
  bool _isSaving = false;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _nameController = TextEditingController(text: habit?.name ?? '');
    _selectedEmoji = habit?.emoji ?? habitEmojiOptions.first;
    _isDaily = habit == null ? true : habit.isDaily;
    _selectedWeekdays = habit == null ? Set<int>.from(Habit.allWeekdays) : Set<int>.from(habit.frequency);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleWeekday(int weekday) {
    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        if (_selectedWeekdays.length > 1) {
          _selectedWeekdays.remove(weekday);
        }
      } else {
        _selectedWeekdays.add(weekday);
      }
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your habit a name first.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final frequency = _isDaily ? Set<int>.from(Habit.allWeekdays) : Set<int>.from(_selectedWeekdays);
    final notifier = ref.read(habitsControllerProvider.notifier);

    if (_isEditing) {
      final updated = widget.habit!.copyWith(
        name: name,
        emoji: _selectedEmoji,
        frequency: frequency,
      );
      await notifier.updateHabit(updated);
    } else {
      final newHabit = Habit(
        id: 'habit-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        emoji: _selectedEmoji,
        frequency: frequency,
        createdAt: DateTime.now(),
      );
      await notifier.addHabit(newHabit);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final habit = widget.habit;
    if (habit == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('"${habit.name}" and all of its check-in history will be removed. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(habitsControllerProvider.notifier).deleteHabit(habit.id);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit habit' : 'New habit'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _isSaving ? null : _delete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete habit',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('Name', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. Morning run',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text('Icon', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          EmojiPickerGrid(
            selectedEmoji: _selectedEmoji,
            onSelected: (emoji) => setState(() => _selectedEmoji = emoji),
          ),
          const SizedBox(height: 24),
          Text('Frequency', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          FrequencySelector(
            isDaily: _isDaily,
            selectedWeekdays: _selectedWeekdays,
            onDailySelected: () => setState(() => _isDaily = true),
            onCustomSelected: () => setState(() => _isDaily = false),
            onWeekdayToggled: _toggleWeekday,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: Text(_isEditing ? 'Save changes' : 'Add habit'),
          ),
        ],
      ),
    );
  }
}
