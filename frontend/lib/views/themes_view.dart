import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/theme.dart';
import 'package:kloudshop/providers/theme_providers.dart';
import 'package:kloudshop/views/wysiwyg_view.dart';

class ThemesView extends ConsumerWidget {
  const ThemesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themesAsync = ref.watch(themesProvider);
    final activeConfigAsync = ref.watch(activeThemeConfigProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Library'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () {
              ref.invalidate(themesProvider);
              ref.read(activeThemeConfigProvider.notifier).fetch();
            },
          ),
        ],
      ),
      body: themesAsync.when(
        data: (themes) => activeConfigAsync.when(
          data: (activeConfig) => _buildThemeGrid(context, ref, themes, activeConfig?.themeId),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error loading config: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading themes: $e')),
      ),
    );
  }

  Widget _buildThemeGrid(BuildContext context, WidgetRef ref, List<ThemeModel> themes, String? activeThemeId) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 320,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        final isActive = theme.themeId == activeThemeId;
        return _ThemeCard(
          theme: theme,
          isActive: isActive,
          onSelect: () => _handleSelect(context, ref, theme),
        );
      },
    );
  }

  Future<void> _handleSelect(BuildContext context, WidgetRef ref, ThemeModel theme) async {
    try {
      await ref.read(activeThemeConfigProvider.notifier).selectTheme(theme.themeId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Theme "${theme.name}" activated!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error activating theme: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _ThemeCard extends StatelessWidget {
  final ThemeModel theme;
  final bool isActive;
  final VoidCallback onSelect;

  const _ThemeCard({
    required this.theme,
    required this.isActive,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isActive 
          ? BorderSide(color: themeData.primaryColor, width: 2)
          : BorderSide(color: themeData.dividerColor.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: isActive ? null : onSelect,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Image Placeholder
            Expanded(
              child: Container(
                width: double.infinity,
                color: themeData.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(
                    LucideIcons.image, 
                    size: 48, 
                    color: themeData.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          theme.name,
                          style: themeData.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.check, size: 12, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                'ACTIVE',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    theme.description ?? 'No description provided.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: themeData.textTheme.bodySmall?.copyWith(color: themeData.hintColor),
                  ),
                  const SizedBox(height: 16),
                  if (!isActive)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onSelect,
                        child: const Text('Select Theme'),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const WysiwygView()),
                          );
                        },
                        icon: const Icon(LucideIcons.edit, size: 16),
                        label: const Text('Customize'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
