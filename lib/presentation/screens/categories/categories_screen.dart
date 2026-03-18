import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/category_providers.dart';
import '../../widgets/common/empty_state.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(allCategoriesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          AppStrings.categories,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_rounded,
              color: theme.colorScheme.primary,
            ),
            onPressed: () => _showAddDialog(context, ref),
            tooltip: AppStrings.newCategory,
          ),
        ],
      ),
      body: categories.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
        error: (err, _) => Center(
          child: Text(
            'Ошибка: $err',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
        data: (cats) {
          if (cats.isEmpty) {
            return EmptyState(
              icon: Icons.folder_outlined,
              message: AppStrings.noCategories,
              actionLabel: AppStrings.newCategory,
              onAction: () => _showAddDialog(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: cats.length,
            itemBuilder: (context, index) {
              final cat = cats[index];
              final catColor = Color(cat.colorValue);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? theme.cardColor : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          // Color circle
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: catColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Category name
                          Expanded(
                            child: Text(
                              cat.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // Delete button
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                              onPressed: () => _showDeleteDialog(context, ref, cat),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, dynamic cat) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isDark ? theme.cardColor : Colors.white,
        title: const Text(
          'Удалить категорию?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Категория «${cat.name}» будет удалена.',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppStrings.cancel,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              AppStrings.delete,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(categoryActionsProvider).deleteCategory(cat.id);
    }
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    int selectedColorIndex = 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: isDark ? theme.cardColor : Colors.white,
          title: const Text(
            AppStrings.newCategory,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: AppStrings.categoryName,
                  labelStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? theme.colorScheme.surfaceContainerHighest
                      : const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.categoryColor,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(
                  AppColors.categoryColors.length,
                  (i) => GestureDetector(
                    onTap: () => setDialogState(() => selectedColorIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.categoryColors[i],
                        shape: BoxShape.circle,
                        border: selectedColorIndex == i
                            ? Border.all(
                                color: theme.colorScheme.onSurface,
                                width: 2.5,
                              )
                            : Border.all(
                                color: Colors.transparent,
                                width: 2.5,
                              ),
                        boxShadow: selectedColorIndex == i
                            ? [
                                BoxShadow(
                                  color: AppColors.categoryColors[i]
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: selectedColorIndex == i
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                AppStrings.cancel,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  ref.read(categoryActionsProvider).createCategory(
                        name: controller.text.trim(),
                        colorValue:
                            AppColors.categoryColors[selectedColorIndex].toARGB32(),
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }
}
