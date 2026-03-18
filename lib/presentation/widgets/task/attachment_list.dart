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

    return StreamBuilder<List<Attachment>>(
      stream: db.watchAttachmentsForTask(taskId),
      builder: (context, snapshot) {
        final attachments = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Вложения', style: theme.textTheme.titleSmall),
                const Spacer(),
                if (attachments.isNotEmpty)
                  Text(
                    '${attachments.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.add, size: 20),
                  onSelected: (value) => _addAttachment(context, db, value),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'camera', child: Text('Камера')),
                    const PopupMenuItem(value: 'gallery', child: Text('Галерея')),
                    const PopupMenuItem(value: 'file', child: Text('Файл')),
                  ],
                ),
              ],
            ),
            if (attachments.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: attachments.length,
                  itemBuilder: (context, index) {
                    final att = attachments[index];
                    return _buildAttachmentTile(context, att, db, theme);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAttachmentTile(
      BuildContext context, Attachment att, AppDatabase db, ThemeData theme) {
    final isImage = att.attachmentType == AttachmentType.image;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (isImage && !kIsWeb) {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    child: Image.file(File(att.filePath)),
                  ),
                );
              }
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surfaceContainerHighest,
                image: isImage && !kIsWeb
                    ? DecorationImage(
                        image: FileImage(File(att.filePath)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !isImage
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.insert_drive_file, size: 32),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            att.displayName ?? 'Файл',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
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
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
