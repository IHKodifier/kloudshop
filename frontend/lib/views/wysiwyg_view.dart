import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/providers/theme_providers.dart';
import 'package:kloudshop/widgets/storefront_preview.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _buildTopBar(themeConfigAsync.value, ref.read(activeThemeConfigProvider.notifier)),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(themeConfigAsync),
                Expanded(
                  child: _buildPreviewCanvas(themeConfigAsync),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ThemeConfigModel? config, ActiveThemeConfigNotifier notifier) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.x, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Exit Editor',
          ),
          const SizedBox(width: 16),
          const VerticalDivider(width: 1, indent: 16, endIndent: 16),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config?.themeId?.toUpperCase() ?? 'THEME EDITOR',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Text(
                'Draft version',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(LucideIcons.undo2, size: 20),
            onPressed: notifier.canUndo ? () => notifier.undo() : null,
            tooltip: 'Undo',
            color: notifier.canUndo ? Colors.black87 : Colors.grey[300],
          ),
          IconButton(
            icon: const Icon(LucideIcons.redo2, size: 20),
            onPressed: notifier.canRedo ? () => notifier.redo() : null,
            tooltip: 'Redo',
            color: notifier.canRedo ? Colors.black87 : Colors.grey[300],
          ),
          const SizedBox(width: 16),
          _deviceToggle(),
          const SizedBox(width: 24),
          ElevatedButton.icon(
            onPressed: () => _handlePublish(),
            icon: const Icon(LucideIcons.rocket, size: 16),
            label: const Text('Publish Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _toggleIcon(LucideIcons.monitor, !_isMobile, () => setState(() => _isMobile = false)),
          _toggleIcon(LucideIcons.smartphone, _isMobile, () => setState(() => _isMobile = true)),
        ],
      ),
    );
  }

  Widget _toggleIcon(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
        ),
        child: Icon(icon, size: 18, color: active ? const Color(0xFF6366F1) : Colors.grey),
      ),
    );
  }

  Widget _buildSidebar(AsyncValue<dynamic> configAsync) {
    return Container(
      width: 320,
      color: Colors.white,
      child: configAsync.when(
        data: (config) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              title: 'Design Tokens',
              icon: LucideIcons.palette,
              children: [
                _colorPickerTile('Primary Color', 'primary', config?.draftTokens['primary']),
                _colorPickerTile('Secondary Color', 'secondary', config?.draftTokens['secondary']),
                _colorPickerTile('Background', 'background', config?.draftTokens['background']),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Content Slots',
              icon: LucideIcons.layout,
              children: [
                _slotTextEditor('Hero Heading', 'hero_heading', config?.draftSlots['hero_heading']),
                _slotTextEditor('Hero Subheading', 'hero_subheading', config?.draftSlots['hero_subheading']),
                _slotDropdown('Hero Layout', 'hero', config?.draftSlots['hero'], ['full-width', 'centered']),
              ],
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF6366F1)),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _colorPickerTile(String label, String key, String? hex) {
    final color = _parseColor(hex, Colors.blue);
    
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
      onTap: () => _showColorPicker(label, key, color),
    );
  }

  Widget _slotTextEditor(String label, String key, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          TextField(
            controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value?.length ?? 0),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            onChanged: (val) => ref.read(activeThemeConfigProvider.notifier).updateLocalSlot(key, val),
          ),
        ],
      ),
    );
  }

  Widget _slotDropdown(String label, String key, String? value, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: value,
            items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (val) => ref.read(activeThemeConfigProvider.notifier).updateLocalSlot(key, val ?? ''),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCanvas(AsyncValue<dynamic> configAsync) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.topCenter,
      child: configAsync.when(
        data: (config) => SingleChildScrollView(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isMobile ? 375 : 1000,
            child: StorefrontPreview(
              tokens: config?.draftTokens ?? {},
              slots: config?.draftSlots ?? {},
              isMobile: _isMobile,
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
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
              ref.read(activeThemeConfigProvider.notifier).updateLocalToken(key, hex);
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
        ],
      ),
    );
  }

  Future<void> _handlePublish() async {
    try {
      await ref.read(activeThemeConfigProvider.notifier).publish();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Theme published successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish: $e'), backgroundColor: Colors.red),
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
