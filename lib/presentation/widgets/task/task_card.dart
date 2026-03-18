import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOutBack,
    );
    if (widget.task.isCompleted) {
      _checkController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.isCompleted != oldWidget.task.isCompleted) {
      if (widget.task.isCompleted) {
        _checkController.forward();
      } else {
        _checkController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Color get _priorityColor {
    switch (widget.task.priority) {
      case TaskPriority.low:
        return AppColors.priorityLow;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.high:
        return AppColors.priorityHigh;
    }
  }

  String? get _timeString {
    final task = widget.task;
    if (task.timeHour != null && task.timeMinute != null) {
      return '${task.timeHour!.toString().padLeft(2, '0')}:${task.timeMinute!.toString().padLeft(2, '0')}';
    }
    return null;
  }

  List<String> get _tagList {
    final tags = widget.task.tags;
    if (tags.isEmpty) return [];
    return tags
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final completedOpacity = task.isCompleted ? 0.5 : 1.0;

    return Animate(
      effects: [
        FadeEffect(duration: 300.ms),
        SlideEffect(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
          duration: 300.ms,
        ),
      ],
      child: Slidable(
        // Slide right -> complete / undo
        startActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => widget.onToggle(),
              backgroundColor: task.isCompleted
                  ? AppColors.priorityMedium
                  : AppColors.success,
              foregroundColor: Colors.white,
              icon: task.isCompleted ? Icons.undo_rounded : Icons.check_rounded,
              label: task.isCompleted ? 'Вернуть' : 'Готово',
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
        // Slide left -> delete
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => widget.onDelete(),
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline_rounded,
              label: 'Удалить',
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.lightCard,
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppColors.subtleShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated priority checkbox
                  GestureDetector(
                    onTap: widget.onToggle,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, right: 12),
                      child: _buildCheckbox(),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Opacity(
                      opacity: completedOpacity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.lightText,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: AppColors.lightMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Description
                          if (task.description != null &&
                              task.description!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              task.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.lightSecondary,
                              ),
                            ),
                          ],
                          // Meta row
                          if (_timeString != null || _tagList.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildMetaRow(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return AnimatedBuilder(
      animation: _checkAnimation,
      builder: (context, _) {
        final value = _checkAnimation.value;
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _priorityColor,
              width: 2,
            ),
            color: Color.lerp(
              Colors.transparent,
              _priorityColor,
              value,
            ),
          ),
          child: value > 0.3
              ? Opacity(
                  opacity: ((value - 0.3) / 0.7).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * value,
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildMetaRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Time
        if (_timeString != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 13,
                color: AppColors.lightMuted,
              ),
              const SizedBox(width: 3),
              Text(
                _timeString!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.lightMuted,
                ),
              ),
            ],
          ),
        // Tag pills
        ..._tagList.map(
          (tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _priorityColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _priorityColor.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
