import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/theme.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/providers/theme_providers.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/views/wysiwyg_view.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';
import 'package:url_launcher/url_launcher.dart';

class ThemesView extends ConsumerWidget {
  const ThemesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themesAsync = ref.watch(themesProvider);
    final configsAsync = ref.watch(themeConfigurationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Premium Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withOpacity(0.8)
                  : Colors.white.withOpacity(0.9),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme Library',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Manage, clone, and test visual layouts for your storefront',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                HoverScale(
                  child: IconButton.outlined(
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    onPressed: () {
                      ref.invalidate(themesProvider);
                      ref.invalidate(themeConfigurationsProvider);
                      ref.read(activeThemeConfigProvider.notifier).fetch();
                    },
                    tooltip: 'Refresh library',
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable layout lists
          Expanded(
            child: configsAsync.when(
              data: (configs) {
                final ThemeConfigModel? activeConfig = configs.any((c) => c.isActive)
                    ? configs.firstWhere((c) => c.isActive)
                    : null;
                final clonedConfigs = configs.where((c) => !c.isActive).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION 1: Active layout
                      if (activeConfig != null) ...[
                        _buildSectionHeader(
                          context,
                          'Active Storefront Layout',
                          'This design layout is currently live on your storefront.',
                        ),
                        const SizedBox(height: 16),
                        _buildActiveLayoutCard(context, ref, activeConfig, isDark),
                        const SizedBox(height: 32),
                      ],

                      // SECTION 2: Custom layouts & A/B testing
                      _buildSectionHeader(
                        context,
                        'Theme Layout Clones (A/B Testing)',
                        'Alternative designs to share with peers or switch storefront looks.',
                      ),
                      const SizedBox(height: 16),
                      if (clonedConfigs.isEmpty)
                        _buildEmptyClonesCard(context)
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400,
                            mainAxisExtent: 210,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          itemCount: clonedConfigs.length,
                          itemBuilder: (context, index) {
                            return _buildClonedLayoutCard(
                              context,
                              ref,
                              clonedConfigs[index],
                              isDark,
                            );
                          },
                        ),
                      const SizedBox(height: 32),

                      // SECTION 3: Base Templates
                      _buildSectionHeader(
                        context,
                        'Base Theme Templates',
                        'Start from scratch with a fresh layout pre-configuration.',
                      ),
                      const SizedBox(height: 16),
                      themesAsync.when(
                        data: (themes) => GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 400,
                            mainAxisExtent: 220,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                          ),
                          itemCount: themes.length,
                          itemBuilder: (context, index) {
                            final themeModel = themes[index];
                            final isThemeActive = activeConfig?.themeId == themeModel.themeId;
                            return _buildThemeTemplateCard(
                              context,
                              ref,
                              themeModel,
                              isThemeActive,
                              isDark,
                            );
                          },
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Center(child: Text('Failed to load templates: $err')),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Error loading configurations: $err'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveLayoutCard(
    BuildContext context,
    WidgetRef ref,
    ThemeConfigModel config,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final shareLink = '${_getSafeOrigin()}/#/preview?configId=${config.configId}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.brandEmerald500, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandEmerald500.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graphic container
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.brandEmerald500, AppTheme.brandTeal500],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(LucideIcons.layout, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(width: 20),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      config.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.brandEmerald500.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.brandEmerald500.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.check, size: 10, color: AppTheme.brandEmerald500),
                          SizedBox(width: 4),
                          Text(
                            'LIVE ACTIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brandEmerald500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Base Template: ${config.themeId} | Updated: ${_formatDateTime(config.updatedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _openEditor(context, ref, config),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandEmerald500,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(LucideIcons.edit3, size: 14, color: Colors.white),
                      label: const Text('Customize Live Layout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showRenameDialog(context, ref, config),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(LucideIcons.pencil, size: 14),
                      label: const Text('Rename'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _launchPreview(shareLink),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(LucideIcons.externalLink, size: 14),
                      label: const Text('Preview / Share'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClonedLayoutCard(
    BuildContext context,
    WidgetRef ref,
    ThemeConfigModel config,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final shareLink = '${_getSafeOrigin()}/#/preview?configId=${config.configId}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.copy, size: 16, color: AppTheme.brandEmerald500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  config.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                tooltip: 'Delete Draft',
                onPressed: () => _showDeleteDialog(context, ref, config),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Base Theme: ${config.themeId}',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
          Text(
            'Updated: ${_formatDateTime(config.updatedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => _openEditor(context, ref, config),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.brandEmerald500,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Edit Layout', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.pencil, size: 14),
                    tooltip: 'Rename',
                    onPressed: () => _showRenameDialog(context, ref, config),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.externalLink, size: 14),
                    tooltip: 'Preview / Share',
                    onPressed: () => _launchPreview(shareLink),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.rocket, size: 14),
                    tooltip: 'Make Active (Publish)',
                    onPressed: () => _publishLayout(context, ref, config),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyClonesCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
          style: BorderStyle.none, // Custom dashed border or simple thin border
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.copy, size: 36, color: theme.hintColor.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              'No layout clones created yet',
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.hintColor),
            ),
            const SizedBox(height: 6),
            Text(
              'Clone your theme layout inside the editor to create design variants for A/B testing.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: theme.hintColor.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeTemplateCard(
    BuildContext context,
    WidgetRef ref,
    ThemeModel themeModel,
    bool isActive,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.layoutTemplate, size: 16, color: AppTheme.brandEmerald500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  themeModel.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              themeModel.description ?? 'A visual storefront design theme template.',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isActive
                  ? null
                  : () => _selectTemplate(context, ref, themeModel),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isActive ? theme.disabledColor : AppTheme.brandEmerald500,
                ),
                foregroundColor: AppTheme.brandEmerald500,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isActive ? 'Currently Installed' : 'Use Base Template'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, ThemeConfigModel config) async {
    ref.read(editingThemeConfigIdProvider.notifier).setConfigId(config.configId);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WysiwygView()),
    );
    ref.read(editingThemeConfigIdProvider.notifier).setConfigId(null);
    ref.invalidate(themeConfigurationsProvider);
    ref.read(activeThemeConfigProvider.notifier).fetch();
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeConfigModel config,
  ) async {
    final nameController = TextEditingController(text: config.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Layout'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Layout Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(nameController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandEmerald500),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != config.name) {
      try {
        await ref.read(apiServiceProvider).updateThemeConfigById(
              config.configId,
              name: newName,
            );
        ref.invalidate(themeConfigurationsProvider);
        ref.read(activeThemeConfigProvider.notifier).fetch();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to rename: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeConfigModel config,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Layout Variant?'),
        content: Text('Are you sure you want to delete "${config.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(apiServiceProvider).deleteThemeConfig(config.configId);
        ref.invalidate(themeConfigurationsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _publishLayout(
    BuildContext context,
    WidgetRef ref,
    ThemeConfigModel config,
  ) async {
    try {
      await ref.read(apiServiceProvider).publishThemeById(config.configId);
      ref.invalidate(themeConfigurationsProvider);
      ref.read(activeThemeConfigProvider.notifier).fetch();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${config.name}" is now the active layout!'),
            backgroundColor: AppTheme.brandEmerald600,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to activate layout: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectTemplate(
    BuildContext context,
    WidgetRef ref,
    ThemeModel themeModel,
  ) async {
    try {
      await ref.read(activeThemeConfigProvider.notifier).selectTheme(themeModel.themeId);
      ref.invalidate(themeConfigurationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New layout from template "${themeModel.name}" activated!'),
            backgroundColor: AppTheme.brandEmerald600,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load template: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _launchPreview(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  String _getSafeOrigin() {
    try {
      if (Uri.base.scheme == 'http' || Uri.base.scheme == 'https') {
        return Uri.base.origin;
      }
    } catch (_) {}
    return 'http://localhost:3000';
  }
}
