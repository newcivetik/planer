import 'package:flutter/material.dart';

class ReminderOption {
  final String label;
  final Duration? offset;
  final bool isCustom;

  const ReminderOption(this.label, this.offset, {this.isCustom = false});
}

class ReminderPicker extends StatefulWidget {
  final List<Duration> selectedOffsets;
  final ValueChanged<List<Duration>> onChanged;

  const ReminderPicker({
    super.key,
    required this.selectedOffsets,
    required this.onChanged,
  });

  @override
  State<ReminderPicker> createState() => _ReminderPickerState();
}

class _ReminderPickerState extends State<ReminderPicker> {
  static const _options = [
    ReminderOption('В момент задачи', Duration.zero),
    ReminderOption('За 5 минут', Duration(minutes: 5)),
    ReminderOption('За 15 минут', Duration(minutes: 15)),
    ReminderOption('За 30 минут', Duration(minutes: 30)),
    ReminderOption('За 1 час', Duration(hours: 1)),
    ReminderOption('За 2 часа', Duration(hours: 2)),
    ReminderOption('За 1 день', Duration(days: 1)),
  ];

  late List<Duration> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedOffsets);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notifications_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text('Напоминания', style: theme.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _options.map((option) {
            final isSelected = _selected.contains(option.offset);
            return FilterChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selected.add(option.offset!);
                  } else {
                    _selected.remove(option.offset);
                  }
                });
                widget.onChanged(_selected);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
