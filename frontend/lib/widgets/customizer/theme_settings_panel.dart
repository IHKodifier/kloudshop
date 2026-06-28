import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kloudshop/widgets/customizer/custom_color_picker.dart';
import 'package:kloudshop/widgets/upload/asset_selection_dialog.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/providers/theme_providers.dart';

class ThemeSettingsPanel extends ConsumerStatefulWidget {
  final ThemeConfigModel? config;

  const ThemeSettingsPanel({
    super.key,
    required this.config,
  });

  @override
  ConsumerState<ThemeSettingsPanel> createState() => _ThemeSettingsPanelState();
}

class _ThemeSettingsPanelState extends ConsumerState<ThemeSettingsPanel> {
  final _expansionStates = <String, bool>{
    'logo': true,
    'colors': false,
    'typography': false,
    'social': false,
    'layout': false,
    'presets': false,
  };

  final _textControllers = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController getController(String key, String defaultVal) {
    if (!_textControllers.containsKey(key)) {
      _textControllers[key] = TextEditingController(text: defaultVal);
    }
    return _textControllers[key]!;
  }

  void _updateToken(String key, dynamic value) {
    ref.read(activeThemeConfigProvider.notifier).updateTokens({
      key: value,
    }, editKey: 'token_update_$key');
  }

  Color _parseColor(dynamic val, Color fallback) {
    if (val == null) return fallback;
    if (val is Color) return val;
    if (val is String && val.startsWith('#')) {
      try {
        return Color(int.parse(val.substring(1), radix: 16) + 0xFF000000);
      } catch (_) {
        return fallback;
      }
    }
    return fallback;
  }

  double _parseDouble(dynamic val, double fallback) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val) ?? fallback;
    }
    return fallback;
  }

  double _luminance(Color color) {
    return color.computeLuminance();
  }

  double _contrastRatio(Color c1, Color c2) {
    final l1 = _luminance(c1);
    final l2 = _luminance(c2);
    return (l1 > l2) ? (l1 + 0.05) / (l2 + 0.05) : (l2 + 0.05) / (l1 + 0.05);
  }

  void _showColorPickerDialog(String key, Color initialColor) {
    Color selectedColor = initialColor;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          title: const Text('Pick Color', style: TextStyle(fontFamily: 'Outfit')),
          content: SizedBox(
            width: 340,
            child: CustomColorPicker(
              pickerColor: initialColor,
              onColorChanged: (color) {
                selectedColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final hex = '#${selectedColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
                _updateToken(key, hex);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandEmerald500),
              child: const Text('Select', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _simulateSelectImage(String tokenKey) {
    final tokens = widget.config?.draftTokens ?? {};
    final currentUrl = tokens[tokenKey]?.toString() ?? '';

    showDialog<dynamic>(
      context: context,
      builder: (context) {
        return AssetSelectionDialog(
          title: tokenKey == 'logo' ? 'Logo' : 'Favicon',
          isMultiSelect: false,
          initialUrls: currentUrl.isNotEmpty ? [currentUrl] : const [],
        );
      },
    ).then((selected) {
      if (selected is String && selected.isNotEmpty) {
        _updateToken(tokenKey, selected);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tokens = widget.config?.draftTokens ?? {};

    // Colors parsing
    final primaryColor = _parseColor(tokens['primary'], AppTheme.brandEmerald500);
    final secondaryColor = _parseColor(tokens['secondary'], AppTheme.brandTeal500);
    final backgroundColor = _parseColor(tokens['background'] ?? tokens['bg_color'], Colors.white);
    final textColor = _parseColor(tokens['text_color'], const Color(0xFF0F172A));

    final customColors = <Map<String, String>>[];
    tokens.forEach((k, v) {
      if (k.startsWith('custom_color_name_')) {
        final id = k.replaceFirst('custom_color_name_', '');
        final name = v.toString();
        final value = tokens['custom_color_value_$id']?.toString() ?? '#000000';
        customColors.add({
          'id': id,
          'name': name,
          'value': value,
        });
      }
    });
    customColors.sort((a, b) => a['id']!.compareTo(b['id']!));

    final contrast = _contrastRatio(textColor, backgroundColor);
    final contrastFailed = contrast < 4.5;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(right: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Theme Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // 1. LOGO & FAVICON ACCORDION
                _buildAccordionHeader(
                  id: 'logo',
                  title: 'Logo & Favicon',
                  icon: LucideIcons.image,
                  children: [
                    const Text('BRAND LOGO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 6),
                    _buildImageField('logo_url', tokens['logo_url']),
                    const SizedBox(height: 12),
                    _buildWidthSlider('logo_width', tokens['logo_width']),
                    const SizedBox(height: 16),
                    const Text('FAVICON (32x32px)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 6),
                    _buildImageField('favicon_url', tokens['favicon_url']),
                  ],
                ),

                // 2. COLORS ACCORDION
                _buildAccordionHeader(
                  id: 'colors',
                  title: 'Colors',
                  icon: LucideIcons.palette,
                  children: [
                    _buildColorTile('Primary Color', 'primary', primaryColor),
                    _buildColorTile('Secondary Color', 'secondary', secondaryColor),
                    _buildColorTile('Background Color', 'background', backgroundColor),
                    _buildColorTile('Body Text Color', 'text_color', textColor),
                    
                    if (customColors.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 12, bottom: 4),
                        child: Text(
                          'CUSTOM COLORS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.grey),
                        ),
                      ),
                      ...customColors.map((cc) => _buildCustomColorTile(cc, theme)),
                    ],

                    _buildAddCustomColorButton(theme),
                    const SizedBox(height: 12),
                    
                    // WCAG Warning Box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: contrastFailed
                            ? const Color(0xFFF59E0B).withOpacity(0.12)
                            : AppTheme.brandEmerald500.withOpacity(0.08),
                        border: Border.all(
                          color: contrastFailed ? const Color(0xFFF59E0B) : AppTheme.brandEmerald500,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                contrastFailed ? LucideIcons.alertTriangle : LucideIcons.checkCircle,
                                size: 14,
                                color: contrastFailed ? const Color(0xFFF59E0B) : AppTheme.brandEmerald500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                contrastFailed ? 'Contrast Ratio: Low' : 'Contrast Ratio: Passed',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: contrastFailed ? const Color(0xFFF59E0B) : AppTheme.brandEmerald500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Contrast ratio is ${contrast.toStringAsFixed(2)}:1 between text and background. (WCAG target: >= 4.5:1)',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 3. TYPOGRAPHY ACCORDION
                _buildAccordionHeader(
                  id: 'typography',
                  title: 'Typography',
                  icon: LucideIcons.type,
                  children: [
                    _buildDropdownInput(
                      label: 'FONT FAMILY',
                      tokenKey: 'font_family',
                      currentVal: tokens['font_family'] ?? 'Inter',
                      options: const ['Inter', 'Outfit', 'Roboto', 'Poppins', 'Montserrat', 'Lora'],
                    ),
                    const SizedBox(height: 12),
                    _buildDropdownInput(
                      label: 'HEADING SCALE',
                      tokenKey: 'heading_scale',
                      currentVal: tokens['heading_scale'] ?? 'medium',
                      options: const ['small', 'medium', 'large'],
                    ),
                    const SizedBox(height: 12),
                    _buildFontSizeSlider('font_size', tokens['font_size']),
                  ],
                ),

                // 4. SOCIAL MEDIA ACCORDION
                _buildAccordionHeader(
                  id: 'social',
                  title: 'Social Media',
                  icon: LucideIcons.share2,
                  children: [
                    _buildSocialTextField('Facebook Link', 'social_facebook', tokens['social_facebook'] ?? ''),
                    _buildSocialTextField('Instagram Link', 'social_instagram', tokens['social_instagram'] ?? ''),
                    _buildSocialTextField('YouTube Link', 'social_youtube', tokens['social_youtube'] ?? ''),
                    _buildSocialTextField('TikTok Link', 'social_tiktok', tokens['social_tiktok'] ?? ''),
                    _buildSocialTextField('Twitter / X Link', 'social_twitter', tokens['social_twitter'] ?? ''),
                  ],
                ),

                // 5. LAYOUT & BUTTONS ACCORDION
                _buildAccordionHeader(
                  id: 'layout',
                  title: 'Layout & Buttons',
                  icon: LucideIcons.layout,
                  children: [
                    _buildBorderRadiusSlider('border_radius', tokens['border_radius']),
                    const SizedBox(height: 12),
                    _buildDropdownInput(
                      label: 'BUTTON STYLE',
                      tokenKey: 'button_style',
                      currentVal: tokens['button_style'] ?? 'filled',
                      options: const ['filled', 'outline', 'ghost'],
                    ),
                    const SizedBox(height: 12),
                    _buildToggleInput(
                      label: 'Enable Transitions',
                      tokenKey: 'animations_enabled',
                      currentVal: tokens['animations_enabled'] == true,
                    ),
                  ],
                ),

                // 6. STYLE PRESETS ACCORDION
                _buildAccordionHeader(
                  id: 'presets',
                  title: 'Style Presets',
                  icon: LucideIcons.sparkles,
                  children: [
                    _buildDropdownInput(
                      label: 'ACTIVE STYLE PRESET',
                      tokenKey: 'style_preset',
                      currentVal: tokens['style_preset'] ?? 'Default',
                      options: const ['Default', 'Summer Fresh', 'Winter Cozy', 'Midnight Neon'],
                      onChanged: (preset) {
                        if (preset == 'Summer Fresh') {
                          ref.read(activeThemeConfigProvider.notifier).updateTokens({
                            'primary': '#0D9488',
                            'secondary': '#14B8A6',
                            'background': '#F0FDFA',
                            'text_color': '#115E59',
                            'style_preset': preset,
                          });
                        } else if (preset == 'Winter Cozy') {
                          ref.read(activeThemeConfigProvider.notifier).updateTokens({
                            'primary': '#2563EB',
                            'secondary': '#3B82F6',
                            'background': '#EFF6FF',
                            'text_color': '#1E3A8A',
                            'style_preset': preset,
                          });
                        } else if (preset == 'Midnight Neon') {
                          ref.read(activeThemeConfigProvider.notifier).updateTokens({
                            'primary': '#F43F5E',
                            'secondary': '#EC4899',
                            'background': '#0F172A',
                            'text_color': '#F1F5F9',
                            'style_preset': preset,
                          });
                        } else {
                          ref.read(activeThemeConfigProvider.notifier).updateTokens({
                            'primary': '#0D9488',
                            'secondary': '#6366F1',
                            'background': '#FFFFFF',
                            'text_color': '#0F172A',
                            'style_preset': preset,
                          });
                        }
                      },
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

  Widget _buildAccordionHeader({
    required String id,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isExpanded = _expansionStates[id] ?? false;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            leading: Icon(icon, size: 16, color: isExpanded ? AppTheme.brandEmerald500 : theme.hintColor),
            title: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isExpanded ? AppTheme.brandEmerald500 : null)),
            trailing: Icon(isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight, size: 14),
            onTap: () {
              setState(() {
                _expansionStates[id] = !isExpanded;
              });
            },
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageField(String tokenKey, String? currentUrl) {
    final theme = Theme.of(context);
    final isSelected = currentUrl != null && currentUrl.isNotEmpty;

    return InkWell(
      onTap: () => _simulateSelectImage(tokenKey),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(6),
          image: isSelected
              ? DecorationImage(image: NetworkImage(currentUrl), fit: BoxFit.contain)
              : null,
        ),
        child: !isSelected
            ? const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.image, size: 14, color: AppTheme.brandEmerald500),
                    SizedBox(width: 6),
                    Text('Select Asset', style: TextStyle(fontSize: 11, color: AppTheme.brandEmerald500, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            : Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(2)),
                  child: const Text('Change', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
      ),
    );
  }

  Widget _buildWidthSlider(String tokenKey, dynamic val) {
    final currentVal = _parseDouble(val, 90.0);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('LOGO DISPLAY WIDTH', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            Text('${currentVal.round()}px', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
            activeTrackColor: AppTheme.brandEmerald500,
            inactiveTrackColor: theme.dividerColor.withOpacity(0.5),
            thumbColor: AppTheme.brandEmerald500,
            overlayColor: AppTheme.brandEmerald500.withOpacity(0.12),
          ),
          child: SizedBox(
            height: 24,
            child: Slider(
              value: currentVal.clamp(40, 300),
              min: 40,
              max: 300,
              onChanged: (val) {
                _updateToken(tokenKey, val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorTile(String label, String tokenKey, Color color) {
    final hex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          GestureDetector(
            onTap: () => _showColorPickerDialog(tokenKey, color),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(hex, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildDropdownInput({
    required String label,
    required String tokenKey,
    required String currentVal,
    required List<String> options,
    ValueChanged<String>? onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: theme.hintColor),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(currentVal) ? currentVal : options.first,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface),
              dropdownColor: theme.cardColor,
              items: options.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Text(opt.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  if (onChanged != null) {
                    onChanged(val);
                  } else {
                    _updateToken(tokenKey, val);
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeSlider(String tokenKey, dynamic val) {
    final currentVal = _parseDouble(val, 14.0);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('BODY FONT SIZE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            Text('${currentVal.round()}px', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
            activeTrackColor: AppTheme.brandEmerald500,
            inactiveTrackColor: theme.dividerColor.withOpacity(0.5),
            thumbColor: AppTheme.brandEmerald500,
            overlayColor: AppTheme.brandEmerald500.withOpacity(0.12),
          ),
          child: SizedBox(
            height: 24,
            child: Slider(
              value: currentVal.clamp(10, 24),
              min: 10,
              max: 24,
              onChanged: (val) {
                _updateToken(tokenKey, val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBorderRadiusSlider(String tokenKey, dynamic val) {
    final currentVal = _parseDouble(val, 8.0);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('BUTTON BORDER RADIUS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            Text('${currentVal.round()}px', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
            activeTrackColor: AppTheme.brandEmerald500,
            inactiveTrackColor: theme.dividerColor.withOpacity(0.5),
            thumbColor: AppTheme.brandEmerald500,
            overlayColor: AppTheme.brandEmerald500.withOpacity(0.12),
          ),
          child: SizedBox(
            height: 24,
            child: Slider(
              value: currentVal.clamp(0, 32),
              min: 0,
              max: 32,
              onChanged: (val) {
                _updateToken(tokenKey, val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleInput({
    required String label,
    required String tokenKey,
    required bool currentVal,
  }) {
    return SwitchListTile.adaptive(
      title: Text(label, style: const TextStyle(fontSize: 12)),
      value: currentVal,
      activeColor: AppTheme.brandEmerald500,
      contentPadding: EdgeInsets.zero,
      onChanged: (val) {
        _updateToken(tokenKey, val);
      },
    );
  }

  Widget _buildSocialTextField(String label, String tokenKey, String currentVal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: getController(tokenKey, currentVal),
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          labelStyle: const TextStyle(fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: const OutlineInputBorder(),
        ),
        onChanged: (val) {
          _updateToken(tokenKey, val);
        },
      ),
    );
  }

  Widget _buildCustomColorTile(Map<String, String> cc, ThemeData theme) {
    final id = cc['id']!;
    final name = cc['name']!;
    final colorHex = cc['value']!;
    final color = _parseColor(colorHex, Colors.black);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 32,
              child: _CustomColorNameInput(
                initialName: name,
                onNameSubmitted: (newName) {
                  if (newName.isNotEmpty) {
                    _updateToken('custom_color_name_$id', newName);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showColorPickerDialog('custom_color_value_$id', color),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            colorHex.length > 7 ? colorHex.substring(0, 7) : colorHex,
            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.red),
            onPressed: () => _deleteCustomColor(id),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCustomColorButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: _showAddCustomColorDialog,
          borderRadius: BorderRadius.circular(4),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.plusCircle,
                  size: 13,
                  color: AppTheme.brandEmerald500,
                ),
                SizedBox(width: 6),
                Text(
                  'Add Custom Color',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.brandEmerald500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddCustomColorDialog() {
    final theme = Theme.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: const Text('Add Custom Color', style: TextStyle(fontFamily: 'Outfit')),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'e.g. Announcement Background',
              labelText: 'Color Name',
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.brandEmerald500),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context);
                  _addCustomColor(name);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandEmerald500),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _addCustomColor(String name) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    ref.read(activeThemeConfigProvider.notifier).updateTokens({
      'custom_color_name_$id': name,
      'custom_color_value_$id': '#000000',
    });
  }

  void _deleteCustomColor(String id) {
    ref.read(activeThemeConfigProvider.notifier).deleteTokens([
      'custom_color_name_$id',
      'custom_color_value_$id',
    ]);
  }
}

class _CustomColorNameInput extends StatefulWidget {
  final String initialName;
  final ValueChanged<String> onNameSubmitted;

  const _CustomColorNameInput({
    required this.initialName,
    required this.onNameSubmitted,
  });

  @override
  State<_CustomColorNameInput> createState() => _CustomColorNameInputState();
}

class _CustomColorNameInputState extends State<_CustomColorNameInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void didUpdateWidget(covariant _CustomColorNameInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialName != widget.initialName && _controller.text != widget.initialName) {
      _controller.text = widget.initialName;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _controller,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        hintText: 'Color Name',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppTheme.brandEmerald500, width: 1.2),
        ),
      ),
      onSubmitted: (val) {
        widget.onNameSubmitted(val.trim());
      },
    );
  }
}

class _AssetSelectTile extends StatelessWidget {
  final String name;
  final String url;
  final ValueChanged<String> onSelect;

  const _AssetSelectTile({
    required this.name,
    required this.url,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
          ),
        ),
        title: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        trailing: const Icon(LucideIcons.check, size: 14, color: AppTheme.brandEmerald500),
        onTap: () => onSelect(url),
      ),
    );
  }
}
