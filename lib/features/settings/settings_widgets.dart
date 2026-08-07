import 'package:flutter/material.dart';

/// Section label used to group related settings tiles.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// Tapping opens the native time picker to set the daily reminder time.
class ReminderTimeTile extends StatelessWidget {
  const ReminderTimeTile({
    super.key,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  @override
  Widget build(BuildContext context) {
    final timeOfDay = TimeOfDay(hour: hour, minute: minute);
    return ListTile(
      leading: const Icon(Icons.notifications_outlined),
      title: const Text('Daily reminder'),
      subtitle: Text('Nudge me at ${timeOfDay.format(context)}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: timeOfDay,
          helpText: 'Set reminder time',
        );
        if (picked != null) {
          onChanged(picked.hour, picked.minute);
        }
      },
    );
  }
}

/// Lets the person choose whether the stats heatmap's weeks start on
/// Monday or Sunday.
class WeekStartTile extends StatelessWidget {
  const WeekStartTile({
    super.key,
    required this.weekStartDay,
    required this.onChanged,
  });

  final int weekStartDay;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSunday = weekStartDay == DateTime.sunday;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined),
              const SizedBox(width: 16),
              const Text('Week starts on'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Monday'),
                  selected: !isSunday,
                  onSelected: (_) => onChanged(DateTime.monday),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Sunday'),
                  selected: isSunday,
                  onSelected: (_) => onChanged(DateTime.sunday),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Destructive "reset everything" action, gated behind a confirmation
/// dialog so it can't be triggered by an accidental tap.
class ResetDataTile extends StatefulWidget {
  const ResetDataTile({super.key, required this.onConfirmedReset});

  final Future<void> Function() onConfirmedReset;

  @override
  State<ResetDataTile> createState() => _ResetDataTileState();
}

class _ResetDataTileState extends State<ResetDataTile> {
  bool _isResetting = false;

  Future<void> _handleReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset all data?'),
        content: const Text(
          'This erases every habit and check-in, then restores Habitly to its original demo habits. '
          "This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isResetting = true);
    await widget.onConfirmedReset();
    if (!mounted) return;
    setState(() => _isResetting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your data has been reset.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.restart_alt, color: colorScheme.error),
      title: Text('Reset all data', style: TextStyle(color: colorScheme.error)),
      subtitle: const Text('Clear habits and check-ins, restore demo data'),
      trailing: _isResetting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _isResetting ? null : _handleReset,
    );
  }
}

/// Small credit footer at the bottom of Settings.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'Habitly · version 1.0.0',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),
      ),
    );
  }
}
