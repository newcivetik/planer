import 'package:flutter/material.dart';

class ReminderOption {
  final String label;
  final Duration? offset;
  final IconData icon;
  final bool isCustom;

  const ReminderOption(this.label, this.offset, this.icon,
      {this.isCustom = false});
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
    ReminderOption('В момент', Duration.zero, Icons.alarm_rounded),
    ReminderOption('5 мин', Duration(minutes: 5), Icons.timer_outlined),
    ReminderOption('15 мин', Duration(minutes: 15), Icons.timer_outlined),
    ReminderOption('30 мин', Duration(minutes: 30), Icons.timer_outlined),
    ReminderOption('1 час', Duration(hours: 1), Icons.schedule_rounded),
    ReminderOption('2 часа', Duration(hours: 2), Icons.schedule_rounded),
    ReminderOption('1 день', Duration(days: 1), Icons.today_rounded),
  ];

  late List<Duration> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedOffsets);
  }

  @override
  void didUpdateWidget(covariant ReminderPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedOffsets != widget.selectedOffsets) {
      _selected = List.from(widget.selectedOffsets);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.notifications_rounded,
              size: 22,
              color: accentColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Напоминания',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _options.map((option) {
            final isSelected = _selected.contains(option.offset);
            return _ReminderChip(
              label: option.label,
              icon: option.icon,
              isSelected: isSelected,
              accentColor: accentColor,
              isDark: isDark,
              theme: theme,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selected.remove(option.offset);
                  } else {
                    _selected.add(option.offset!);
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

class _ReminderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ReminderChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = accentColor.withValues(alpha: 0.12);
    final unselectedBg = Colors.transparent;
    final selectedBorder = accentColor;
    final unselectedBorder = theme.dividerColor;
    final selectedTextColor = accentColor;
    final unselectedTextColor = theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? selectedBorder : unselectedBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? selectedTextColor : unselectedTextColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? selectedTextColor : unselectedTextColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
