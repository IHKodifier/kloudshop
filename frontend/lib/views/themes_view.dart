import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/theme.dart';
import 'package:kloudshop/providers/theme_providers.dart';
import 'package:kloudshop/views/wysiwyg_view.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';

class ThemesView extends ConsumerWidget {
  const ThemesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themesAsync = ref.watch(themesProvider);
    final activeConfigAsync = ref.watch(activeThemeConfigProvider);
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
                  ? const Color(0xFF1E293B).withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.9),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme Library',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Choose and customize your storefront look',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                HoverScale(
                  child: IconButton.outlined(
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    onPressed: () {
                      ref.invalidate(themesProvider);
                      ref.read(activeThemeConfigProvider.notifier).fetch();
                    },
                    tooltip: 'Refresh themes',
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

          // Theme grid
          Expanded(
            child: themesAsync.when(
              data: (themes) => activeConfigAsync.when(
                data: (activeConfig) => _buildThemeGrid(
                  context,
                  ref,
                  themes,
                  activeConfig?.themeId,
                ),
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.brandEmerald500,
                  ),
                ),
                error: (e, s) =>
                    Center(child: Text('Error loading config: $e')),
              ),
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: AppTheme.brandEmerald500,
                ),
              ),
              error: (e, s) => Center(child: Text('Error loading themes: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeGrid(
    BuildContext context,
    WidgetRef ref,
    List<ThemeModel> themes,
    String? activeThemeId,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisExtent: 340,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final themeModel = themes[index];
        final isActive = themeModel.themeId == activeThemeId;
        return _ThemeCard(
          theme: themeModel,
          isActive: isActive,
          onSelect: () => _handleSelect(context, ref, themeModel),
        );
      },
    );
  }

  Future<void> _handleSelect(
    BuildContext context,
    WidgetRef ref,
    ThemeModel themeModel,
  ) async {
    try {
      await ref
          .read(activeThemeConfigProvider.notifier)
          .selectTheme(themeModel.themeId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme "${themeModel.name}" activated!'),
            backgroundColor: AppTheme.brandEmerald600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error activating theme: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}

class _ThemeCard extends StatefulWidget {
  final ThemeModel theme;
  final bool isActive;
  final VoidCallback onSelect;

  const _ThemeCard({
    required this.theme,
    required this.isActive,
    required this.onSelect,
  });

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final isDark = themeData.brightness == Brightness.dark;

    // Palette preview colors based on theme name hash
    final previewGradientColors = _getPreviewColors(widget.theme.themeId);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered && !widget.isActive ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.75)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isActive
                      ? AppTheme.brandEmerald500
                      : _isHovered
                      ? AppTheme.brandEmerald500.withValues(alpha: 0.4)
                      : themeData.dividerColor.withValues(alpha: 0.6),
                  width: widget.isActive ? 2 : 1,
                ),
                boxShadow: widget.isActive || _isHovered
                    ? [
                        BoxShadow(
                          color: AppTheme.brandEmerald500.withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: InkWell(
                onTap: widget.isActive ? null : widget.onSelect,
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stylised preview area
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(19),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Gradient preview
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: previewGradientColors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                            // Simulated UI skeleton
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // "Nav bar" mock
                                  Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // "Hero text" mock
                                  Container(
                                    width: 100,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 70,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  // "Product cards" mock
                                  Row(
                                    children: List.generate(
                                      3,
                                      (i) => Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            right: i < 2 ? 6 : 0,
                                          ),
                                          child: Container(
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Active overlay glow
                            if (widget.isActive)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppTheme.brandEmerald500
                                          .withValues(alpha: 0.5),
                                      width: 2,
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(19),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Info section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.theme.name,
                                  style: themeData.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (widget.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brandEmerald500.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.brandEmerald500
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.check,
                                        size: 10,
                                        color: AppTheme.brandEmerald500,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.brandEmerald500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.theme.description ??
                                'No description provided.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: themeData.textTheme.bodySmall?.copyWith(
                              color: themeData.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (!widget.isActive)
                            HoverScale(
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: widget.onSelect,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppTheme.brandEmerald500,
                                    ),
                                    foregroundColor: AppTheme.brandEmerald500,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Select Theme'),
                                ),
                              ),
                            )
                          else
                            HoverScale(
                              child: SizedBox(
                                width: double.infinity,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppTheme.brandEmerald500,
                                        AppTheme.brandEmerald600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.brandEmerald500
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const WysiwygView(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      LucideIcons.edit,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Customize',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getPreviewColors(String themeId) {
    // Generate deterministic but varied palette based on themeId
    final palettes = [
      [AppTheme.brandEmerald500, AppTheme.brandTeal500],
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFFF59E0B), const Color(0xFFEC4899)],
      [const Color(0xFF0EA5E9), const Color(0xFF6366F1)],
      [const Color(0xFF10B981), const Color(0xFF0EA5E9)],
    ];
    final index = themeId.codeUnits.fold(0, (a, b) => a + b) % palettes.length;
    return palettes[index];
  }
}
