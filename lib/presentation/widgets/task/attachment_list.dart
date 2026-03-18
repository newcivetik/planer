import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../data/database.dart';
import '../../providers/database_provider.dart';

class AttachmentList extends ConsumerWidget {
  final int taskId;

  const AttachmentList({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<List<Attachment>>(
      stream: db.watchAttachmentsForTask(taskId),
      builder: (context, snapshot) {
        final attachments = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section header ---
            Row(
              children: [
                Icon(
                  Icons.attach_file_rounded,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Вложения',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                if (attachments.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.surfaceContainerHighest
                          : theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${attachments.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showAddSheet(context, db),
                  child: Icon(
                    Icons.add_circle_outline_rounded,
                    size: 24,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // --- Content ---
            if (attachments.isEmpty)
              _buildEmptyState(context, db, theme, isDark)
            else
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: attachments.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final att = attachments[index];
                    return _AttachmentTileAnimated(
                      key: ValueKey(att.id),
                      child: _buildAttachmentTile(context, att, db, theme, isDark),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  // --- Empty state: dashed border + icon ---
  Widget _buildEmptyState(
      BuildContext context, AppDatabase db, ThemeData theme, bool isDark) {
    final borderColor = isDark
        ? theme.colorScheme.outlineVariant.withValues(alpha: 0.4)
        : theme.colorScheme.outlineVariant;

    return GestureDetector(
      onTap: () => _showAddSheet(context, db),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: borderColor,
            borderRadius: 10,
            dashWidth: 6,
            dashSpace: 4,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 28,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 4),
                Text(
                  'Добавить вложение',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Attachment tile ---
  Widget _buildAttachmentTile(
      BuildContext context, Attachment att, AppDatabase db, ThemeData theme, bool isDark) {
    final isImage = att.attachmentType == AttachmentType.image;

    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        children: [
          // Tile body
          GestureDetector(
            onTap: () {
              if (isImage && !kIsWeb) {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(att.filePath)),
                    ),
                  ),
                );
              }
            },
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isImage
                    ? null
                    : (isDark
                        ? theme.colorScheme.surfaceContainerHigh
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.7)),
                image: isImage && !kIsWeb
                    ? DecorationImage(
                        image: FileImage(File(att.filePath)),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: !isImage
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _fileIcon(att.displayName),
                          size: 28,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            att.displayName ?? 'Файл',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),

          // Delete button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () async {
                await db.deleteAttachment(att.id);
                // Clean up file
                if (!kIsWeb) {
                  final file = File(att.filePath);
                  if (await file.exists()) await file.delete();
                }
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Add bottom sheet ---
  void _showAddSheet(BuildContext context, AppDatabase db) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark
          ? theme.colorScheme.surfaceContainerHigh
          : theme.colorScheme.surface,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Добавить вложение',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSheetOption(
                  context: ctx,
                  icon: Icons.camera_alt_rounded,
                  iconColor: theme.colorScheme.primary,
                  title: 'Камера',
                  subtitle: 'Сделать фото',
                  onTap: () {
                    Navigator.pop(ctx);
                    _addAttachment(context, db, 'camera');
                  },
                  theme: theme,
                ),
                _buildSheetOption(
                  context: ctx,
                  icon: Icons.photo_library_rounded,
                  iconColor: Colors.orange,
                  title: 'Галерея',
                  subtitle: 'Выбрать из галереи',
                  onTap: () {
                    Navigator.pop(ctx);
                    _addAttachment(context, db, 'gallery');
                  },
                  theme: theme,
                ),
                _buildSheetOption(
                  context: ctx,
                  icon: Icons.folder_rounded,
                  iconColor: Colors.teal,
                  title: 'Файл',
                  subtitle: 'Выбрать документ',
                  onTap: () {
                    Navigator.pop(ctx);
                    _addAttachment(context, db, 'file');
                  },
                  theme: theme,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  // --- File icon helper ---
  IconData _fileIcon(String? name) {
    if (name == null) return Icons.insert_drive_file_rounded;
    final ext = p.extension(name).toLowerCase();
    return switch (ext) {
      '.pdf' => Icons.picture_as_pdf_rounded,
      '.doc' || '.docx' => Icons.description_rounded,
      '.xls' || '.xlsx' => Icons.table_chart_rounded,
      '.zip' || '.rar' || '.7z' => Icons.folder_zip_rounded,
      '.mp3' || '.wav' || '.aac' => Icons.audio_file_rounded,
      '.mp4' || '.mov' || '.avi' => Icons.video_file_rounded,
      _ => Icons.insert_drive_file_rounded,
    };
  }

  // --- Original attachment logic (preserved) ---
  Future<void> _addAttachment(BuildContext context, AppDatabase db, String source) async {
    if (kIsWeb) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вложения недоступны в веб-версии')),
        );
      }
      return;
    }

    String? filePath;
    String? displayName;
    AttachmentType type = AttachmentType.file;

    if (source == 'camera' || source == 'gallery') {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      );
      if (image != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'att_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
        final savedFile = await File(image.path).copy(p.join(appDir.path, fileName));
        filePath = savedFile.path;
        displayName = fileName;
        type = AttachmentType.image;
      }
    } else if (source == 'file') {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        final picked = result.files.single;
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'att_${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
        final savedFile = await File(picked.path!).copy(p.join(appDir.path, fileName));
        filePath = savedFile.path;
        displayName = picked.name;
        type = AttachmentType.file;
      }
    }

    if (filePath != null) {
      await db.insertAttachment(AttachmentsCompanion(
        taskId: Value(taskId),
        filePath: Value(filePath),
        displayName: Value(displayName),
        attachmentType: Value(type),
        createdAt: Value(DateTime.now()),
      ));
    }
  }
}

// --- Fade-in animation wrapper for tiles ---
class _AttachmentTileAnimated extends StatefulWidget {
  final Widget child;

  const _AttachmentTileAnimated({super.key, required this.child});

  @override
  State<_AttachmentTileAnimated> createState() => _AttachmentTileAnimatedState();
}

class _AttachmentTileAnimatedState extends State<_AttachmentTileAnimated>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

// --- Dashed border painter for empty state ---
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;

  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color;
}
