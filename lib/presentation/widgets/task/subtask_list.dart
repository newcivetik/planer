import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database.dart';
import '../../providers/database_provider.dart';

class SubtaskList extends ConsumerStatefulWidget {
  final int taskId;
  final ValueChanged<double>? onProgressChanged;

  const SubtaskList({super.key, required this.taskId, this.onProgressChanged});

  @override
  ConsumerState<SubtaskList> createState() => _SubtaskListState();
}

class _SubtaskListState extends ConsumerState<SubtaskList> {
  final _addController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  void _updateProgress(List<Subtask> subtasks) {
    if (widget.onProgressChanged != null && subtasks.isNotEmpty) {
      final completed = subtasks.where((s) => s.isCompleted).length;
      widget.onProgressChanged!(completed / subtasks.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final theme = Theme.of(context);

    return StreamBuilder<List<Subtask>>(
      stream: db.watchSubtasksForTask(widget.taskId),
      builder: (context, snapshot) {
        final subtasks = snapshot.data ?? [];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateProgress(subtasks);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Подзадачи', style: theme.textTheme.titleSmall),
                const Spacer(),
                if (subtasks.isNotEmpty)
                  Text(
                    '${subtasks.where((s) => s.isCompleted).length}/${subtasks.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => setState(() => _isAdding = true),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (subtasks.isNotEmpty) ...[
              LinearProgressIndicator(
                value: subtasks.isEmpty ? 0 : subtasks.where((s) => s.isCompleted).length / subtasks.length,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
                minHeight: 4,
              ),
              const SizedBox(height: 8),
            ],
            ...subtasks.map((subtask) => _buildSubtaskTile(subtask, db, theme)),
            if (_isAdding) _buildAddField(db),
          ],
        );
      },
    );
  }

  Widget _buildSubtaskTile(Subtask subtask, AppDatabase db, ThemeData theme) {
    return Dismissible(
      key: ValueKey(subtask.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.withValues(alpha: 0.1),
        child: const Icon(Icons.delete, color: Colors.red, size: 20),
      ),
      onDismissed: (_) => db.deleteSubtask(subtask.id),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Checkbox(
          value: subtask.isCompleted,
          onChanged: (val) => db.toggleSubtask(subtask.id, val ?? false),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        title: Text(
          subtask.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
            color: subtask.isCompleted ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
      ),
    );
  }

  Widget _buildAddField(AppDatabase db) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _addController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Новая подзадача...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (value) => _addSubtask(db),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, size: 20),
            onPressed: () => _addSubtask(db),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              _addController.clear();
              setState(() => _isAdding = false);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addSubtask(AppDatabase db) async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    await db.insertSubtask(SubtasksCompanion(
      taskId: Value(widget.taskId),
      title: Value(text),
    ));
    _addController.clear();
  }
}
