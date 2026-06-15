import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/widgets/storefront_preview.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';

final previewThemeConfigProvider =
    FutureProvider.family<ThemeConfigModel, String>((ref, configId) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getThemeConfig(configId);
});

class ThemePreviewPage extends ConsumerWidget {
  final String configId;

  const ThemePreviewPage({super.key, required this.configId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(previewThemeConfigProvider(configId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      body: configAsync.when(
        data: (config) => Column(
          children: [
            // Glassmorphic Top Bar
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withOpacity(0.8)
                        : Colors.white.withOpacity(0.9),
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.brandEmerald500.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.brandEmerald500.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              LucideIcons.flaskConical,
                              size: 12,
                              color: AppTheme.brandEmerald500,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'A/B TEST PREVIEW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.brandEmerald500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Layout Title
                      Expanded(
                        child: Text(
                          config.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Share button
                      HoverScale(
                        child: TextButton.icon(
                          onPressed: () {
                            final currentUrl = Uri.base.toString();
                            // If base URL doesn't contain configId, construct the exact preview link
                            String shareLink = currentUrl;
                            if (!currentUrl.contains('configId=')) {
                              final origin = (Uri.base.scheme == 'http' || Uri.base.scheme == 'https')
                                  ? Uri.base.origin
                                  : 'http://localhost:3000';
                              shareLink = '$origin/#/preview?configId=$configId';
                            }
                            Clipboard.setData(ClipboardData(text: shareLink));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Share link copied to clipboard!'),
                                backgroundColor: AppTheme.brandEmerald600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.copy, size: 14),
                          label: const Text(
                            'Copy Share Link',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.brandEmerald500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Preview viewport
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
                            blurRadius: 32,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: StorefrontPreview(
                        tokens: config.draftTokens,
                        slots: config.draftSlots,
                        isMobile: false,
                        previewState: 'default',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.brandEmerald500),
              const SizedBox(height: 16),
              Text(
                'Loading storefront layout...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.alertTriangle,
                  color: Colors.redAccent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load preview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.hintColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
