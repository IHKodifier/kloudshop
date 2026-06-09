import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/models/color_preset.dart';
import 'package:kloudshop/providers/color_presets_provider.dart';

class OptionCategoryEditor extends ConsumerStatefulWidget {
  final Map<String, dynamic> option;
  final List<String> siblingNames;
  final VoidCallback onDelete;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const OptionCategoryEditor({
    super.key,
    required this.option,
    required this.siblingNames,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  ConsumerState<OptionCategoryEditor> createState() =>
      _OptionCategoryEditorState();
}

enum PickerStyle { wheel, swatches, palette }

class _OptionCategoryEditorState extends ConsumerState<OptionCategoryEditor> {
  late TextEditingController _nameController;
  late TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.option['name']);
    _valueController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _addValue() async {
    final val = _valueController.text.trim();
    if (val.isEmpty) return;

    final isColorOption =
        widget.option['name'].toString().trim().toLowerCase() == 'color';
    final List<String> vals = List<String>.from(widget.option['values'] ?? []);

    if (isColorOption) {
      final presets = ref.read(colorPresetsProvider).value ?? [];
      final existingPreset = presets.firstWhere(
        (p) => p.name.trim().toLowerCase() == val.toLowerCase(),
        orElse: () => ColorPreset(
          presetId: '',
          tenantId: '',
          name: '',
          hexCode: '',
          createdAt: DateTime.now(),
        ),
      );

      if (existingPreset.hexCode.isNotEmpty) {
        if (!vals.contains(existingPreset.name)) {
          final updatedOption = Map<String, dynamic>.from(widget.option);
          updatedOption['values'] = [...vals, existingPreset.name];
          widget.onChanged(updatedOption);
          _valueController.clear();
          setState(() {});
        } else {
          _valueController.clear();
        }
      } else {
        _showAddColorValuePicker(context, val);
      }
    } else {
      if (!vals.contains(val)) {
        final updatedOption = Map<String, dynamic>.from(widget.option);
        updatedOption['values'] = [...vals, val];
        widget.onChanged(updatedOption);
        _valueController.clear();
        setState(() {});
      } else {
        _valueController.clear();
      }
    }
  }

  void _showAddColorValuePicker(BuildContext context, String presetName) {
    _showVisualColorPicker(context, Colors.blue, (pickedColor) async {
      final hexStr =
          '#${pickedColor.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';
      try {
        await ref
            .read(colorPresetsProvider.notifier)
            .addPreset(presetName, hexStr);

        final List<String> vals = List<String>.from(
          widget.option['values'] ?? [],
        );
        if (!vals.contains(presetName)) {
          final updatedOption = Map<String, dynamic>.from(widget.option);
          updatedOption['values'] = [...vals, presetName];
          widget.onChanged(updatedOption);
        }
        _valueController.clear();
        setState(() {});
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save color preset: $e')),
          );
        }
      }
    }, titleText: 'Set Color for "$presetName"');
  }

  void _togglePreset(ColorPreset preset) {
    final List<String> vals = List<String>.from(widget.option['values'] ?? []);
    final updatedOption = Map<String, dynamic>.from(widget.option);
    final newVals = List<String>.from(vals);
    if (newVals.contains(preset.name)) {
      newVals.remove(preset.name);
    } else {
      newVals.add(preset.name);
    }
    updatedOption['values'] = newVals;
    widget.onChanged(updatedOption);
    setState(() {});
  }

  Color _parseColor(String hex) {
    try {
      final hexClean = hex.replaceAll('#', '');
      return Color(int.parse('FF$hexClean', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  bool _isHexColorLight(Color color) {
    return color.computeLuminance() > 0.6;
  }

  Color? _getPresetColorByName(String name, List<ColorPreset> presets) {
    final String normalized = name.trim().toLowerCase();

    // 1. Try finding in the DB loaded presets
    final preset = presets.firstWhere(
      (p) => p.name.trim().toLowerCase() == normalized,
      orElse: () => ColorPreset(
        presetId: '',
        tenantId: '',
        name: '',
        hexCode: '',
        createdAt: DateTime.now(),
      ),
    );
    if (preset.hexCode.isNotEmpty) {
      return _parseColor(preset.hexCode);
    }

    // 2. Try finding in the local defaultPresets
    final fallbackPreset = defaultPresets.firstWhere(
      (p) => p.name.trim().toLowerCase() == normalized,
      orElse: () => ColorPreset(
        presetId: '',
        tenantId: '',
        name: '',
        hexCode: '',
        createdAt: DateTime.now(),
      ),
    );
    if (fallbackPreset.hexCode.isNotEmpty) {
      return _parseColor(fallbackPreset.hexCode);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> values = List<String>.from(
      widget.option['values'] ?? [],
    );
    final isColorOption =
        widget.option['name'].toString().trim().toLowerCase() == 'color';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final presets = ref.watch(colorPresetsProvider).value ?? [];

    final currentName = _nameController.text.trim().toLowerCase();
    final isDuplicate = widget.siblingNames.any(
      (name) => name.trim().toLowerCase() == currentName,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isColorOption
              ? AppTheme.brandEmerald500.withValues(alpha: 0.25)
              : (isDark ? const Color(0xFF334155) : Colors.grey[200]!),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Option Name (e.g. Color, Size)',
                    border: const OutlineInputBorder(),
                    errorText: isDuplicate ? 'Duplicate option name' : null,
                  ),
                  onChanged: (v) {
                    final updatedOption = Map<String, dynamic>.from(
                      widget.option,
                    );
                    updatedOption['name'] = v.trim();
                    widget.onChanged(updatedOption);
                    setState(() {}); // Rebuild to toggle color preset shelf
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _valueController,
                  decoration: InputDecoration(
                    labelText: 'Add Value',
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppTheme.brandEmerald500,
                      ),
                      onPressed: _addValue,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (_) => _addValue(),
                ),
              ),
              if (!isColorOption)
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
                  tooltip: 'Delete category',
                  onPressed: widget.onDelete,
                ),
            ],
          ),

          // Color Presets Shelf
          if (isColorOption) ...[
            const SizedBox(height: 16),
            const Text(
              'Click to add any of your previously used colors.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ref
                .watch(colorPresetsProvider)
                .when(
                  data: (loadedPresets) {
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...loadedPresets.map((preset) {
                          final isSelected = values.contains(preset.name);
                          final color = _parseColor(preset.hexCode);
                          final isLight = _isHexColorLight(color);

                          return ColorPresetShelfItem(
                            preset: preset,
                            isSelected: isSelected,
                            color: color,
                            isLight: isLight,
                            onTap: () => _togglePreset(preset),
                            onEdit: () =>
                                _showEditPresetDialog(context, preset),
                            onDelete: () =>
                                _showDeletePresetConfirm(context, preset),
                          );
                        }),
                        GestureDetector(
                          onTap: () => _showAddPresetDialog(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.grey[100],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF475569)
                                    : Colors.grey[300]!,
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.plus,
                                size: 18,
                                color: AppTheme.brandEmerald500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () {
                    return const SizedBox(
                      height: 38,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.brandEmerald500,
                          ),
                        ),
                      ),
                    );
                  },
                  error: (err, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.alertCircle,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Failed to load presets.',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.refreshCw, size: 14),
                            onPressed: () =>
                                ref.invalidate(colorPresetsProvider),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ],

          if (values.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: values.map((val) {
                final Color? chipColor = isColorOption
                    ? _getPresetColorByName(val, presets)
                    : null;

                // For color chips: resolve the current preset name in case
                // the preset was renamed after it was selected — fixes stale label bug.
                String displayLabel = val;
                if (isColorOption) {
                  final String normalizedVal = val.trim().toLowerCase();
                  final matchedPreset = presets.firstWhere(
                    (p) => p.name.trim().toLowerCase() == normalizedVal,
                    orElse: () => defaultPresets.firstWhere(
                      (p) => p.name.trim().toLowerCase() == normalizedVal,
                      orElse: () => presets.isNotEmpty ? presets.first : defaultPresets.first,
                    ),
                  );
                  // Only use matched name if it actually matched (not a fallback mismatch)
                  if (matchedPreset.name.trim().toLowerCase() == normalizedVal ||
                      matchedPreset.name.trim().toLowerCase() == normalizedVal) {
                    displayLabel = matchedPreset.name;
                  }
                }

                return Chip(
                  avatar: chipColor != null
                      ? Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: chipColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.1),
                              width: 0.5,
                            ),
                          ),
                        )
                      : null,
                  label: Text(displayLabel),
                  onDeleted: () {
                    final updatedOption = Map<String, dynamic>.from(
                      widget.option,
                    );
                    final newVals = List<String>.from(
                      widget.option['values'] as List? ?? [],
                    )..remove(val);
                    updatedOption['values'] = newVals;
                    widget.onChanged(updatedOption);
                    setState(() {});
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showVisualColorPicker(
    BuildContext context,
    Color initialColor,
    ValueChanged<Color> onSelected, {
    String titleText = 'Pick a Color',
  }) {
    showDialog(
      context: context,
      builder: (context) {
        PickerStyle activeStyle = PickerStyle.wheel;
        Color pickedColor = initialColor;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                titleText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Wheel'),
                        selected: activeStyle == PickerStyle.wheel,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(
                              () => activeStyle = PickerStyle.wheel,
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Swatches'),
                        selected: activeStyle == PickerStyle.swatches,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(
                              () => activeStyle = PickerStyle.swatches,
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Palette'),
                        selected: activeStyle == PickerStyle.palette,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(
                              () => activeStyle = PickerStyle.palette,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 300,
                    height: 280,
                    child: activeStyle == PickerStyle.wheel
                        ? ColorPicker(
                            pickerColor: pickedColor,
                            onColorChanged: (color) {
                              setDialogState(() {
                                pickedColor = color;
                              });
                            },
                            pickerAreaHeightPercent: 0.7,
                            enableAlpha: false,
                            portraitOnly: true,
                            colorPickerWidth: 260.0,
                            labelTypes: const [],
                          )
                        : activeStyle == PickerStyle.swatches
                        ? _SwatchesPicker(
                            pickerColor: pickedColor,
                            onColorChanged: (color) {
                              setDialogState(() {
                                pickedColor = color;
                              });
                            },
                          )
                        : BlockPicker(
                            pickerColor: pickedColor,
                            onColorChanged: (color) {
                              setDialogState(() {
                                pickedColor = color;
                              });
                            },
                          ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    onSelected(pickedColor);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandEmerald500,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeletePresetConfirm(BuildContext context, ColorPreset preset) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Preset'),
          content: Text('Are you sure you want to delete "${preset.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                try {
                  await ref
                      .read(colorPresetsProvider.notifier)
                      .removePreset(preset.presetId);
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Preset deleted')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to delete preset: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showAddPresetDialog(BuildContext context) {
    final dialogFormKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final hexController = TextEditingController(text: '#');
    bool isSaving = false;
    String? apiError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hex = hexController.text.trim();
            final isValidHex = RegExp(r'^#([A-Fa-f0-9]{6})$').hasMatch(hex);
            final previewColor = isValidHex ? _parseColor(hex) : Colors.grey;

            return AlertDialog(
              title: const Text(
                'New Color Preset',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (apiError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          apiError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Preset Name',
                        hintText: 'e.g. Lavender',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: hexController,
                            decoration: const InputDecoration(
                              labelText: 'Hex Code',
                              hintText: '#ffffff',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) {
                              setDialogState(() {});
                            },
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Hex code is required';
                              }
                              if (!RegExp(
                                r'^#([A-Fa-f0-9]{6})$',
                              ).hasMatch(v.trim())) {
                                return 'Must be #RRGGBB format';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            _showVisualColorPicker(context, previewColor, (
                              color,
                            ) {
                              final hexStr =
                                  '#${color.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';
                              hexController.text = hexStr;
                              setDialogState(() {});
                            });
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: previewColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!dialogFormKey.currentState!.validate()) return;
                          setDialogState(() {
                            isSaving = true;
                            apiError = null;
                          });

                          try {
                            await ref
                                .read(colorPresetsProvider.notifier)
                                .addPreset(
                                  nameController.text.trim(),
                                  hexController.text.trim(),
                                );
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              apiError = e.toString().replaceFirst(
                                'ApiException: ',
                                '',
                              );
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandEmerald500,
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Preset'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditPresetDialog(BuildContext context, ColorPreset preset) {
    final dialogFormKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: preset.name);
    final hexController = TextEditingController(text: preset.hexCode);
    bool isSaving = false;
    String? apiError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hex = hexController.text.trim();
            final isValidHex = RegExp(r'^#([A-Fa-f0-9]{6})$').hasMatch(hex);
            final previewColor = isValidHex ? _parseColor(hex) : Colors.grey;

            return AlertDialog(
              title: const Text(
                'Edit Color Preset',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (apiError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          apiError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Preset Name',
                        hintText: 'e.g. Lavender',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: hexController,
                            decoration: const InputDecoration(
                              labelText: 'Hex Code',
                              hintText: '#ffffff',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) {
                              setDialogState(() {});
                            },
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Hex code is required';
                              }
                              if (!RegExp(
                                r'^#([A-Fa-f0-9]{6})$',
                              ).hasMatch(v.trim())) {
                                return 'Must be #RRGGBB format';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            _showVisualColorPicker(context, previewColor, (
                              color,
                            ) {
                              final hexStr =
                                  '#${color.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';
                              hexController.text = hexStr;
                              setDialogState(() {});
                            });
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: previewColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!dialogFormKey.currentState!.validate()) return;
                          setDialogState(() {
                            isSaving = true;
                            apiError = null;
                          });

                          try {
                            await ref
                                .read(colorPresetsProvider.notifier)
                                .updatePreset(
                                  preset.presetId,
                                  nameController.text.trim(),
                                  hexController.text.trim(),
                                );
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              apiError = e.toString().replaceFirst(
                                'ApiException: ',
                                '',
                              );
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandEmerald500,
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Preset'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class ColorPresetShelfItem extends StatefulWidget {
  final ColorPreset preset;
  final bool isSelected;
  final Color color;
  final bool isLight;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ColorPresetShelfItem({
    super.key,
    required this.preset,
    required this.isSelected,
    required this.color,
    required this.isLight,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ColorPresetShelfItem> createState() => _ColorPresetShelfItemState();
}

class _ColorPresetShelfItemState extends State<ColorPresetShelfItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Tooltip(
            message: widget.preset.name,
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSelected
                        ? AppTheme.brandEmerald500
                        : (isDark
                              ? const Color(0xFF475569)
                              : Colors.grey[300]!),
                    width: widget.isSelected ? 3.0 : 1.5,
                  ),
                  boxShadow: [
                    if (widget.isSelected)
                      BoxShadow(
                        color: AppTheme.brandEmerald500.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Center(
                  child: widget.isSelected
                      ? Icon(
                          LucideIcons.check,
                          size: 18,
                          color: widget.isLight ? Colors.black : Colors.white,
                        )
                      : null,
                ),
              ),
            ),
          ),
          if (_isHovered) ...[
            Positioned(
              left: -6,
              top: -6,
              child: GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -6,
              top: -6,
              child: GestureDetector(
                onTap: widget.onEdit,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.brandEmerald500,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.pencil,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SwatchesPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const _SwatchesPicker({
    required this.pickerColor,
    required this.onColorChanged,
  });

  static const List<Color> swatchColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: swatchColors.length,
      itemBuilder: (context, index) {
        final color = swatchColors[index];
        final isSelected = color.toARGB32() == pickerColor.toARGB32();
        final isLightColor = color.computeLuminance() > 0.6;

        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isLightColor ? Colors.grey[300]! : Colors.transparent,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: isSelected
                ? Icon(
                    LucideIcons.check,
                    color: isLightColor ? Colors.black : Colors.white,
                    size: 14,
                  )
                : null,
          ),
        );
      },
    );
  }
}
