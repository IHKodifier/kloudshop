import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/theme.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/providers/theme_providers.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/views/theme_customizer_view.dart';
import 'package:kloudshop/views/theme_shop_view.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';
import 'package:kloudshop/widgets/storefront_preview.dart';
import 'package:url_launcher/url_launcher.dart';

class ThemesView extends ConsumerWidget {
  const ThemesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themesAsync = ref.watch(themesProvider);
    final configsAsync = ref.watch(themeConfigurationsProvider);
    final isSidebarExtended = ref.watch(sidebarExtendedProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final columnsCount = isSidebarExtended ? 2 : 3;
    final totalGridItems = columnsCount * 3;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withOpacity(0.8)
                  : Colors.white.withOpacity(0.9),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Themes',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      configsAsync.maybeWhen(
                        data: (configs) {
                          final ThemeConfigModel? activeConfig = configs.any((c) => c.isActive)
                              ? configs.firstWhere((c) => c.isActive)
                              : null;
                          if (activeConfig == null) return const SizedBox.shrink();
                          final shareLink = '${_getSafeOrigin()}/#/preview?configId=${activeConfig.configId}';
                          return Row(
                            children: [
                              TextButton.icon(
                                onPressed: () => _launchPreview(shareLink),
                                icon: const Icon(LucideIcons.eye, size: 16),
                                label: const Text('View your store'),
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
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
              ),
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
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. ACTIVE THEME SECTION
                          if (activeConfig != null) ...[
                            _buildActiveThemeCard(context, ref, activeConfig, isDark),
                            const SizedBox(height: 32),
                          ],

                          // 2. MY THEMES LIBRARY
                          Text(
                            'My Themes Library',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (clonedConfigs.isEmpty)
                            _buildEmptyClonesCard(context)
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: clonedConfigs.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _buildClonedLayoutRow(
                                  context,
                                  ref,
                                  clonedConfigs[index],
                                  isDark,
                                );
                              },
                            ),
                          const SizedBox(height: 36),

                          // 3. TOP / TRENDING THEMES
                          Text(
                            'Top / Trending Themes',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          themesAsync.when(
                            data: (themesList) {
                              final themes = themesList.isNotEmpty ? themesList : _getDummyBaseThemes();
                              final displayTemplates = themes.take(totalGridItems - 1).toList();

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columnsCount,
                                  mainAxisExtent: 380,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                ),
                                itemCount: displayTemplates.length + 1,
                                itemBuilder: (context, index) {
                                  if (index < displayTemplates.length) {
                                    final themeModel = displayTemplates[index];
                                    final isThemeActive = activeConfig?.themeId == themeModel.themeId;
                                    return _buildPopularThemeCard(
                                      context,
                                      ref,
                                      themeModel,
                                      isThemeActive,
                                      isDark,
                                      index,
                                    );
                                  } else {
                                    // The final explore more card
                                    return _buildExploreMoreCard(context);
                                  }
                                },
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, stack) => Center(child: Text('Failed to load templates: $err')),
                          ),
                        ],
                      ),
                    ),
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

  // --- Active Theme Card with mockups, password banner, details row ---
  Widget _buildActiveThemeCard(
    BuildContext context,
    WidgetRef ref,
    ThemeConfigModel config,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final shareLink = '${_getSafeOrigin()}/#/preview?configId=${config.configId}';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Previews Stack
          _buildPreviewMockups(context, config, isDark),

          // Password Protected Warning Banner
          _buildPasswordBanner(context),

          // Theme details row
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.brandEmerald500, AppTheme.brandTeal500],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.layout, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            config.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA), // Soft green
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF34A853).withOpacity(0.2),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.check, size: 10, color: Color(0xFF34A853)),
                                SizedBox(width: 4),
                                Text(
                                  'LIVE ACTIVE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF34A853),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Last saved: ${_getTimeAgo(config.updatedAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '|',
                            style: TextStyle(color: theme.dividerColor, fontSize: 11),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${config.themeId} version 1.0.0',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(LucideIcons.chevronDown, size: 10, color: theme.hintColor),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'rename') {
                      _showRenameDialog(context, ref, config);
                    } else if (val == 'share') {
                      _launchPreview(shareLink);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Text('Rename'),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Text('Duplicate'),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Text('Preview / Share'),
                    ),
                  ],
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(LucideIcons.moreHorizontal, size: 16, color: theme.textTheme.bodyMedium?.color),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _openEditor(context, ref, config),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'Customize',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Password protection banner helper ---
  Widget _buildPasswordBanner(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3B2E15) : const Color(0xFFFFFBEB),
        border: Border.symmetric(
          horizontal: BorderSide(
            color: isDark ? const Color(0xFF6B5828) : const Color(0xFFFDE68A),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.lock,
            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your online store is password protected. To remove the password, pick a plan.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF92400E),
              ),
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: Text(
              'Manage password',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF92400E),
              ),
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: BorderSide(
                color: isDark ? const Color(0xFFFBBF24).withOpacity(0.5) : const Color(0xFFD97706).withOpacity(0.5),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(
              'Pick a plan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Overlapping Mockups Previews ---
  Widget _buildPreviewMockups(
    BuildContext context,
    ThemeConfigModel config,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double containerWidth = constraints.maxWidth;
        // Clamp laptop width slightly smaller to fit perfectly inside the 360 height limits
        final double laptopWidth = (containerWidth * 0.68).clamp(240.0, 500.0);
        final double laptopHeight = laptopWidth * 0.62;

        final double phoneWidth = 160.0;
        final double phoneHeight = 290.0;
        final double separation = 20.0; // Small separation between MacBook and phone (no overlap)

        final double totalWidth = laptopWidth + phoneWidth + separation;
        final double startLeft = ((containerWidth - totalWidth) / 2).clamp(24.0, double.infinity);

        return Container(
          height: 360,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFFF9FAFB), const Color(0xFFE5E7EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Laptop Mockup
              Positioned(
                left: startLeft,
                top: 20,
                width: laptopWidth,
                height: laptopHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF090D16) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.black : const Color(0xFF1E293B), width: 8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Browser Bar
                      Container(
                        height: 24,
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                height: 14,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.black26 : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 6),
                                child: const Text(
                                  'https://storefront.kloudshop.com',
                                  style: TextStyle(fontSize: 8, color: Colors.grey),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Viewport
                      Expanded(
                        child: IgnorePointer(
                          child: FittedBox(
                            fit: BoxFit.fill,
                            child: SizedBox(
                              width: 1200,
                              height: 800,
                              child: StorefrontPreview(
                                tokens: config.draftTokens,
                                slots: config.draftSlots,
                                isMobile: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Laptop base stand
              Positioned(
                left: startLeft - 10,
                top: 20 + laptopHeight - 2,
                width: laptopWidth + 20,
                height: 10,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade300,
                        Colors.grey.shade400,
                        Colors.grey.shade500,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Center thumb notch/indent
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(3),
                              bottomRight: Radius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      // Left USB/Port silhouette
                      Positioned(
                        left: 24,
                        top: 3,
                        child: Container(
                          width: 10,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                      // Right USB/Port silhouette
                      Positioned(
                        right: 24,
                        top: 3,
                        child: Container(
                          width: 10,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Phone Mockup
              Positioned(
                left: startLeft + laptopWidth + separation,
                bottom: 30,
                width: phoneWidth,
                height: phoneHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF090D16) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black, width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(4, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Dynamic Island / Speaker notch
                      Container(
                        height: 12,
                        color: Colors.black,
                        width: double.infinity,
                        child: Center(
                          child: Container(
                            width: 50,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      // Viewport
                      Expanded(
                        child: IgnorePointer(
                          child: FittedBox(
                            fit: BoxFit.fill,
                            child: SizedBox(
                              width: 380,
                              height: 680,
                              child: StorefrontPreview(
                                tokens: config.draftTokens,
                                slots: config.draftSlots,
                                isMobile: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Cloned layout row for My Themes Library list ---
  Widget _buildClonedLayoutRow(
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
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          // Small Thumbnail
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.dividerColor),
            ),
            child: const Center(
              child: Icon(LucideIcons.layout, size: 18, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      config.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Draft',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.hintColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Last saved: ${_getTimeAgo(config.updatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Text('|', style: TextStyle(color: theme.dividerColor, fontSize: 10)),
                    const SizedBox(width: 8),
                    Text(
                      '${config.themeId} version 1.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'rename') {
                _showRenameDialog(context, ref, config);
              } else if (val == 'share') {
                _launchPreview(shareLink);
              } else if (val == 'publish') {
                _publishLayout(context, ref, config);
              } else if (val == 'delete') {
                _showDeleteDialog(context, ref, config);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'publish',
                child: Text('Make Active (Publish)'),
              ),
              const PopupMenuItem(
                value: 'rename',
                child: Text('Rename'),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Text('Preview / Share'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(6),
              child: Icon(LucideIcons.moreHorizontal, size: 14, color: theme.hintColor),
            ),
          ),
          OutlinedButton(
            onPressed: () => _openEditor(context, ref, config),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide(color: theme.dividerColor),
            ),
            child: const Text('Customize', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- Base templates / Popular themes card ---
  Widget _buildPopularThemeCard(
    BuildContext context,
    WidgetRef ref,
    ThemeModel themeModel,
    bool isActive,
    bool isDark,
    int index,
  ) {
    final theme = Theme.of(context);

    // Mock website styles
    final mockStyle = _getPopularMockStyle(themeModel, index);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail asset web preview
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/landing_hero.png'),
                  fit: BoxFit.cover,
                  colorFilter: mockStyle.dark
                      ? ColorFilter.mode(Colors.black.withOpacity(0.55), BlendMode.darken)
                      : null,
                ),
              ),
            ),
          ),
          // Info + Action
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mockStyle.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  mockStyle.desc,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.hintColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isActive
                        ? null
                        : () => _selectTemplate(context, ref, themeModel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      side: BorderSide(
                        color: isActive ? theme.disabledColor : theme.primaryColor,
                      ),
                    ),
                    child: Text(isActive ? 'Currently Installed' : 'Add', style: const TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Explore Theme Store card ---
  Widget _buildExploreMoreCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, style: BorderStyle.solid),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.globe, size: 36, color: theme.primaryColor.withOpacity(0.6)),
          const SizedBox(height: 12),
          const Text(
            'Explore more themes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Browse premium curated templates on our Theme Store.',
            style: TextStyle(fontSize: 10, color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KloudThemeShopView()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text(
              'Visit Theme Store',
              style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- Empty Clones Card ---
  Widget _buildEmptyClonesCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(LucideIcons.copy, size: 28, color: theme.hintColor.withOpacity(0.4)),
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

  // --- Relative Time Ago Formatter ---
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final count = difference.inMinutes;
      return '$count minute${count > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      final count = difference.inHours;
      return '$count hour${count > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 30) {
      final count = difference.inDays;
      return '$count day${count > 1 ? 's' : ''} ago';
    } else {
      final count = (difference.inDays / 30).floor();
      return '$count month${count > 1 ? 's' : ''} ago';
    }
  }

  // --- Dummy base themes generator for grid shelf ---
  List<ThemeModel> _getDummyBaseThemes() {
    return [
      ThemeModel(
        themeId: 'modern-dark',
        name: 'Dawn (Dark)',
        description: 'A tech electronics store theme.',
        baseConfig: {},
        createdAt: DateTime.now(),
      ),
      ThemeModel(
        themeId: 'modern-light',
        name: 'Spotlight (Light)',
        description: 'A clean clothing layout.',
        baseConfig: {},
        createdAt: DateTime.now(),
      ),
      ThemeModel(
        themeId: 'minimal-light',
        name: 'Refresh (Minimal)',
        description: 'A minimalist organic products layout.',
        baseConfig: {},
        createdAt: DateTime.now(),
      ),
    ];
  }

  // --- Helper to get dummy styles matching base themes ---
  _PopularThemeStyle _getPopularMockStyle(ThemeModel model, int index) {
    if (model.themeId == 'modern-dark' || model.name.toLowerCase().contains('dark')) {
      return _PopularThemeStyle(
        name: 'Dawn (Dark)',
        desc: 'Tech / Electronics theme',
        logo: 'TECHSTORE',
        heading: 'Next Gen Tech',
        accent: const Color(0xFF10B981),
        bg: const Color(0xFF090D16),
        dark: true,
      );
    } else if (model.themeId == 'minimal-light' || model.name.toLowerCase().contains('minimal') || model.name.toLowerCase().contains('two')) {
      return _PopularThemeStyle(
        name: 'Refresh (Minimal)',
        desc: 'Food / Organic theme',
        logo: 'ORGANICS',
        heading: 'Fresh Organics',
        accent: const Color(0xFF059669),
        bg: const Color(0xFFF0FDF4),
        dark: false,
      );
    } else {
      return _PopularThemeStyle(
        name: 'Spotlight (Light)',
        desc: 'Clothing / Fashion theme',
        logo: 'FASHION',
        heading: 'Shop Summer Styles',
        accent: const Color(0xFF6366F1),
        bg: const Color(0xFFF3F4F6),
        dark: false,
      );
    }
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, ThemeConfigModel config) async {
    ref.read(editingThemeConfigIdProvider.notifier).setConfigId(config.configId);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ThemeCustomizerView()),
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
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
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

class _PopularThemeStyle {
  final String name;
  final String desc;
  final String logo;
  final String heading;
  final Color accent;
  final Color bg;
  final bool dark;

  _PopularThemeStyle({
    required this.name,
    required this.desc,
    required this.logo,
    required this.heading,
    required this.accent,
    required this.bg,
    required this.dark,
  });
}
