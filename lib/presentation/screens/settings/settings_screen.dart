import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/sync_service.dart';
import '../../../services/cloud_sync_service.dart';
import '../../../services/notification_service.dart';
import '../../providers/theme_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final accentColor = ref.watch(accentColorProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          AppStrings.settings,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // --- Оформление ---
          _sectionHeader(theme, 'Оформление'),
          const SizedBox(height: 8),
          _SectionCard(
            isDark: isDark,
            theme: theme,
            children: [
              // Dark mode toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      size: 22,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.darkMode,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDark ? 'Включена' : 'Выключена',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: isDark,
                      activeTrackColor: theme.colorScheme.primary,
                      activeThumbColor: Colors.white,
                      onChanged: (_) => ref.read(isDarkModeProvider.notifier).toggle(),
                    ),
                  ],
                ),
              ),
              _thinDivider(theme),
              // Accent color selector
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.accentColor,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                        AppColors.accentOptions.length,
                        (i) {
                          final color = AppColors.accentOptions[i];
                          final isSelected =
                              color.toARGB32() == accentColor.toARGB32();
                          return GestureDetector(
                            onTap: () => ref
                                .read(accentColorProvider.notifier)
                                .setColor(color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: theme.colorScheme.onSurface,
                                        width: 2.5,
                                      )
                                    : Border.all(
                                        color: Colors.transparent,
                                        width: 2.5,
                                      ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- Уведомления ---
          _sectionHeader(theme, 'Уведомления'),
          const SizedBox(height: 8),
          _SectionCard(
            isDark: isDark,
            theme: theme,
            children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Разрешить уведомления',
                subtitle: 'Запросить разрешение на push-уведомления',
                theme: theme,
                onTap: () async {
                  if (!kIsWeb) {
                    await NotificationService.instance.requestPermissions();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Разрешения запрошены'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- Данные ---
          _sectionHeader(theme, 'Данные'),
          const SizedBox(height: 8),
          _SectionCard(
            isDark: isDark,
            theme: theme,
            children: [
              _SettingsTile(
                icon: Icons.upload_outlined,
                title: 'Экспорт данных',
                subtitle: 'Сохранить бэкап в JSON файл',
                theme: theme,
                onTap: () async {
                  try {
                    final path = await SyncService.exportToFile();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Бэкап сохранён: $path'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка: $e'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              _thinDivider(theme),
              FutureBuilder<String?>(
                future: SyncService.getLastSyncTime(),
                builder: (context, snapshot) {
                  if (snapshot.data != null) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(52, 0, 16, 12),
                      child: Text(
                        'Последний бэкап: ${snapshot.data}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- Облако ---
          _sectionHeader(theme, 'Облако'),
          const SizedBox(height: 8),
          _SectionCard(
            isDark: isDark,
            theme: theme,
            children: [
              _SettingsTile(
                icon: Icons.cloud_upload_outlined,
                title: 'Синхронизировать в облако',
                subtitle: 'Сохранить данные в iCloud / локальное хранилище',
                theme: theme,
                onTap: () async {
                  if (kIsWeb) return;
                  try {
                    final path = await CloudSyncService.syncToCloud();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Синхронизировано: $path'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка синхронизации: $e'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              _thinDivider(theme),
              _SettingsTile(
                icon: Icons.cloud_download_outlined,
                title: 'Восстановить из облака',
                subtitle: 'Загрузить данные из облачного бэкапа',
                theme: theme,
                onTap: () async {
                  if (kIsWeb) return;
                  try {
                    final restored = await CloudSyncService.syncFromCloud();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(restored
                              ? 'Данные восстановлены из облака'
                              : 'Облачный бэкап не найден'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка: $e'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              _thinDivider(theme),
              FutureBuilder<String?>(
                future: CloudSyncService.getLastCloudSyncTime(),
                builder: (context, snapshot) {
                  if (snapshot.data != null) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(52, 0, 16, 12),
                      child: Text(
                        'Последняя синхронизация: ${snapshot.data}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- О приложении ---
          _sectionHeader(theme, 'О приложении'),
          const SizedBox(height: 8),
          _SectionCard(
            isDark: isDark,
            theme: theme,
            children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: AppStrings.appName,
                subtitle: 'Версия 1.0.0',
                theme: theme,
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: AppStrings.appName,
                    applicationVersion: '1.0.0',
                    applicationLegalese: '\u00a9 2026',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          fontSize: 11,
        ),
      ),
    );
  }

  static Widget _thinDivider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 52,
      color: theme.dividerColor.withValues(alpha: 0.3),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;
  final List<Widget> children;

  const _SectionCard({
    required this.isDark,
    required this.theme,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeData theme;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
