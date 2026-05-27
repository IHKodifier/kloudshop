import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/providers/theme_providers.dart';
import 'package:kloudshop/widgets/storefront_preview.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';

class WysiwygView extends ConsumerStatefulWidget {
  const WysiwygView({super.key});

  @override
  ConsumerState<WysiwygView> createState() => _WysiwygViewState();
}

class _WysiwygViewState extends ConsumerState<WysiwygView> {
  bool _isMobile = false;

  @override
  Widget build(BuildContext context) {
    final themeConfigAsync = ref.watch(activeThemeConfigProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF020617)
          : const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // Glassmorphic Top Bar
          _buildTopBar(
            themeConfigAsync.value,
            ref.read(activeThemeConfigProvider.notifier),
            theme,
            isDark,
          ),

          Expanded(
            child: Row(
              children: [
                // Design Settings Sidebar
                _buildSidebar(themeConfigAsync, theme, isDark),

                // Interactive Device Canvas Viewport
                Expanded(
                  child: _buildPreviewCanvas(themeConfigAsync, theme, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    ThemeConfigModel? config,
    ActiveThemeConfigNotifier notifier,
    ThemeData theme,
    bool isDark,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withOpacity(0.8)
                : Colors.white.withOpacity(0.9),
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              HoverScale(
                child: IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Exit Editor',
                ),
              ),
              const SizedBox(width: 16),
              const VerticalDivider(width: 1, indent: 20, endIndent: 20),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        config?.themeId.toUpperCase() ?? 'THEME STUDIO',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.brandEmerald500.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'DRAFT',
                          style: TextStyle(
                            color: AppTheme.brandEmerald500,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Customize colors, slots and headers in real-time',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),

              // Undo/Redo Buttons
              HoverScale(
                child: IconButton(
                  icon: const Icon(LucideIcons.undo, size: 18),
                  onPressed: notifier.canUndo ? () => notifier.undo() : null,
                  tooltip: 'Undo',
                  color: notifier.canUndo
                      ? theme.colorScheme.onSurface
                      : theme.hintColor.withOpacity(0.3),
                ),
              ),
              HoverScale(
                child: IconButton(
                  icon: const Icon(LucideIcons.redo, size: 18),
                  onPressed: notifier.canRedo ? () => notifier.redo() : null,
                  tooltip: 'Redo',
                  color: notifier.canRedo
                      ? theme.colorScheme.onSurface
                      : theme.hintColor.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: 16),

              // Responsive Design Toggles
              _buildDeviceToggle(theme, isDark),
              const SizedBox(width: 24),

              // Publish Button
              HoverScale(
                child: ElevatedButton.icon(
                  onPressed: () => _handlePublish(),
                  icon: const Icon(
                    LucideIcons.rocket,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Publish Changes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandEmerald500,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
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
    );
  }

  Widget _buildDeviceToggle(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          _buildToggleIconButton(
            LucideIcons.monitor,
            !_isMobile,
            () => setState(() => _isMobile = false),
            theme,
            isDark,
          ),
          const SizedBox(width: 4),
          _buildToggleIconButton(
            LucideIcons.smartphone,
            _isMobile,
            () => setState(() => _isMobile = true),
            theme,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleIconButton(
    IconData icon,
    bool active,
    VoidCallback onTap,
    ThemeData theme,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active
              ? (isDark ? const Color(0xFF0F172A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? AppTheme.brandEmerald500 : theme.hintColor,
        ),
      ),
    );
  }

  Widget _buildSidebar(
    AsyncValue<dynamic> configAsync,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: configAsync.when(
        data: (config) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSidebarSection(
              title: 'Design Tokens',
              icon: LucideIcons.palette,
              theme: theme,
              isDark: isDark,
              children: [
                _colorPickerTile(
                  'Primary Theme Color',
                  'primary',
                  config?.draftTokens['primary'],
                  theme,
                ),
                const SizedBox(height: 8),
                _colorPickerTile(
                  'Secondary Tone Color',
                  'secondary',
                  config?.draftTokens['secondary'],
                  theme,
                ),
                const SizedBox(height: 8),
                _colorPickerTile(
                  'Canvas Background',
                  'background',
                  config?.draftTokens['background'],
                  theme,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSidebarSection(
              title: 'Content Slots',
              icon: LucideIcons.layout,
              theme: theme,
              isDark: isDark,
              children: [
                _buildSlotTextEditor(
                  'Hero Title',
                  'hero_heading',
                  config?.draftSlots['hero_heading'],
                  theme,
                ),
                const SizedBox(height: 16),
                _buildSlotTextEditor(
                  'Hero Subtitle',
                  'hero_subheading',
                  config?.draftSlots['hero_subheading'],
                  theme,
                ),
                const SizedBox(height: 16),
                _buildSlotDropdown(
                  'Hero Alignment',
                  'hero',
                  config?.draftSlots['hero'],
                  ['full-width', 'centered'],
                  theme,
                ),
              ],
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.brandEmerald500),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSidebarSection({
    required String title,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.brandEmerald500),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorPickerTile(
    String label,
    String key,
    String? hex,
    ThemeData theme,
  ) {
    final color = _parseColor(hex, Colors.blue);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        hex ?? '#000000',
        style: TextStyle(color: theme.hintColor, fontSize: 11),
      ),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4),
          ],
        ),
      ),
      onTap: () => _showColorPicker(label, key, color),
    );
  }

  Widget _buildSlotTextEditor(
    String label,
    String key,
    String? value,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.hintColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value?.length ?? 0),
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.brandEmerald500),
            ),
          ),
          onChanged: (val) => ref
              .read(activeThemeConfigProvider.notifier)
              .updateLocalSlot(key, val),
        ),
      ],
    );
  }

  Widget _buildSlotDropdown(
    String label,
    String key,
    String? value,
    List<String> options,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.hintColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: options
              .map(
                (opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(opt, style: const TextStyle(fontSize: 13)),
                ),
              )
              .toList(),
          onChanged: (val) => ref
              .read(activeThemeConfigProvider.notifier)
              .updateLocalSlot(key, val ?? ''),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
          ),
        ),
      ],
    );
  }

  // Preview Viewport with Browser / Mobile Device mockup frames
  Widget _buildPreviewCanvas(
    AsyncValue<dynamic> configAsync,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(48),
      alignment: Alignment.center,
      child: configAsync.when(
        data: (config) {
          if (_isMobile) {
            // Render mobile phone frame mockup
            return _buildMobilePhoneWrapper(
              child: StorefrontPreview(
                tokens: config?.draftTokens ?? {},
                slots: config?.draftSlots ?? {},
                isMobile: true,
              ),
              isDark: isDark,
              theme: theme,
            );
          } else {
            // Render desktop browser frame mockup
            return _buildBrowserWrapper(
              child: StorefrontPreview(
                tokens: config?.draftTokens ?? {},
                slots: config?.draftSlots ?? {},
                isMobile: false,
              ),
              isDark: isDark,
              theme: theme,
            );
          }
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.brandEmerald500),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildBrowserWrapper({
    required Widget child,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          // Browser header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                // Left window action dots
                const Row(
                  children: [
                    CircleAvatar(radius: 5, backgroundColor: Color(0xFFEF4444)),
                    SizedBox(width: 6),
                    CircleAvatar(radius: 5, backgroundColor: Color(0xFFF59E0B)),
                    SizedBox(width: 6),
                    CircleAvatar(radius: 5, backgroundColor: Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(width: 24),
                // URL input field
                Expanded(
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.lock,
                          size: 10,
                          color: AppTheme.brandEmerald500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'https://merchant-preview.kloudshop.com',
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(LucideIcons.refreshCw, size: 12, color: theme.hintColor),
              ],
            ),
          ),

          // Browser viewport content
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
              child: SingleChildScrollView(child: child),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePhoneWrapper({
    required Widget child,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Container(
      width: 380,
      height: 720,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFF1E293B),
          width: 12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          // Notch
          Container(
            width: 160,
            height: 24,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFF1E293B),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 30),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          // Screen content
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SingleChildScrollView(child: child),
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(String title, String key, Color initialColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick $title'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initialColor,
            onColorChanged: (color) {
              final hex = '#${color.value.toRadixString(16).substring(2)}';
              ref
                  .read(activeThemeConfigProvider.notifier)
                  .updateLocalToken(key, hex);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePublish() async {
    try {
      await ref.read(activeThemeConfigProvider.notifier).publish();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Theme published successfully!'),
            backgroundColor: AppTheme.brandEmerald600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || !hex.startsWith('#')) return fallback;
    try {
      return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
    } catch (_) {
      return fallback;
    }
  }
}
