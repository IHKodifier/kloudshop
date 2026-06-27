import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/providers/theme_providers.dart';
import 'package:kloudshop/widgets/storefront_preview.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';
import 'package:kloudshop/widgets/customizer/icon_utility_ribbon.dart';
import 'package:kloudshop/widgets/customizer/outline_panel.dart';
import 'package:kloudshop/widgets/customizer/section_properties_panel.dart';
import 'package:kloudshop/widgets/customizer/theme_settings_panel.dart';
import 'package:kloudshop/widgets/customizer/native_embeds_panel.dart';
import 'package:kloudshop/widgets/customizer/canvas_section_highlight_overlay.dart';
import 'package:kloudshop/services/api_service.dart';

class ThemeCustomizerView extends ConsumerStatefulWidget {
  const ThemeCustomizerView({super.key});

  @override
  ConsumerState<ThemeCustomizerView> createState() => _ThemeCustomizerViewState();
}

class _ThemeCustomizerViewState extends ConsumerState<ThemeCustomizerView> {
  bool _isMobile = false;
  final String _previewState = 'default';
  final Map<String, GlobalKey> _sectionKeys = {};

  // Customizer active page
  String _selectedPage = 'home'; // 'home', 'pdp', 'checkout', 'cart'
  double _zoomScale = 1.0;
  final FocusNode _keyboardFocusNode = FocusNode();

  final GlobalKey _previewContentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSaveDraft() async {
    try {
      await ref.read(activeThemeConfigProvider.notifier).commitSave();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft saved successfully!'),
            backgroundColor: AppTheme.brandEmerald600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save draft: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    final changesCount = ref.read(activeThemeConfigProvider.notifier).getSessionChangesCount();
    if (changesCount == 0) {
      return true;
    }

    final theme = Theme.of(context);
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: const Text('Unsaved Changes', style: TextStyle(fontFamily: 'Outfit')),
          content: Text(
            'You have $changesCount unsaved changes in this session. Do you want to save them before exiting?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child: const Text('Discard', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'save'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandEmerald500),
              child: const Text('Save draft', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (result == 'save') {
      await _handleSaveDraft();
      return true;
    } else if (result == 'discard') {
      await ref.read(activeThemeConfigProvider.notifier).revertToOriginal();
      return true;
    }

    return false;
  }

  Future<void> _handleSaveAndPublishConfirmation() async {
    final config = ref.read(activeThemeConfigProvider).value;
    if (config == null) return;

    final theme = Theme.of(context);
    final changesCount = ref.read(activeThemeConfigProvider.notifier).getSessionChangesCount();

    if (changesCount > 0) {
      final shouldSave = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: theme.dialogBackgroundColor,
            title: const Text('Unsaved Changes', style: TextStyle(fontFamily: 'Outfit')),
            content: const Text('You have unsaved changes. Would you like to save now?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandEmerald500),
                child: const Text('Save & Continue', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
      if (shouldSave != true) return;
      await _handleSaveDraft();
    } else {
      try {
        await ref.read(activeThemeConfigProvider.notifier).saveDraft();
      } catch (e) {
        debugPrint('Save draft before publish failed: $e');
      }
    }

    if (!mounted) return;

    final isDark = theme.brightness == Brightness.dark;

    final primaryColorHex = config.draftTokens['primary'] ?? '#0D9488';
    final canvasColorHex = config.draftTokens['background'] ?? '#FFFFFF';
    final fontName = config.draftTokens['font_family'] ?? 'Inter';

    final pagesList = <Map<String, dynamic>>[];
    config.draftSlots.forEach((key, value) {
      if (key == 'layout') {
        pagesList.add({'name': 'Home Page', 'key': key, 'sections': _countTopLevelSections(value)});
      } else if (key.startsWith('layout_')) {
        final pageName = key.replaceFirst('layout_', '').toUpperCase();
        pagesList.add({'name': '$pageName Page', 'key': key, 'sections': _countTopLevelSections(value)});
      }
    });

    pagesList.sort((a, b) {
      if (a['key'] == 'layout') return -1;
      if (b['key'] == 'layout') return 1;
      return (a['name'] as String).compareTo(b['name'] as String);
    });

    final primaryColor = _parseColor(primaryColorHex, AppTheme.brandEmerald500);
    final canvasColor = _parseColor(canvasColorHex, Colors.white);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: 500,
                constraints: const BoxConstraints(maxHeight: 650),
                decoration: BoxDecoration(
                  color: isDark 
                      ? const Color(0xFF0F172A).withOpacity(0.85) 
                      : Colors.white.withOpacity(0.9),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.brandEmerald500.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.rocket, size: 22, color: AppTheme.brandEmerald500),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Publish Storefront',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Outfit',
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Review changes to make live on your storefront',
                                style: TextStyle(fontSize: 11, color: theme.hintColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    Text(
                      'ACTIVE LAYOUT CONFIGURATION',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: theme.hintColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      config.name,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'DESIGN TOKENS BEING PUBLISHED',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: theme.hintColor),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : const Color(0xFFF1F5F9).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.palette, size: 14, color: AppTheme.brandEmerald500),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Primary Color:',
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                                ),
                              ),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.dividerColor, width: 0.5),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                primaryColorHex,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: theme.colorScheme.onSurface),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(LucideIcons.paintBucket, size: 14, color: AppTheme.brandEmerald500),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Canvas Background:',
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                                ),
                              ),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: canvasColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.dividerColor, width: 0.5),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                canvasColorHex,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: theme.colorScheme.onSurface),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(LucideIcons.type, size: 14, color: AppTheme.brandEmerald500),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Typography Font:',
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.8)),
                                ),
                              ),
                              Text(
                                fontName,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'PAGES / LAYOUTS TO BE UPDATED',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: theme.hintColor),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: pagesList.length,
                        shrinkWrap: true,
                        itemBuilder: (context, idx) {
                          final page = pagesList[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B).withOpacity(0.25) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.dividerColor.withOpacity(0.03)),
                            ),
                            child: Row(
                              children: [
                                Icon(LucideIcons.fileText, size: 14, color: theme.hintColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    page['name'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brandEmerald500.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${page['sections']} sections',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.brandEmerald500,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Keep Editing',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _handlePublish();
                          },
                          icon: const Icon(LucideIcons.rocket, size: 14, color: Colors.white),
                          label: const Text(
                            'Confirm & Publish',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandEmerald500,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
          SnackBar(content: Text('Failed to publish: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddPageDialog(ActiveThemeConfigNotifier notifier) {
    String pageName = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Page'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'e.g. blog, landing_sale'),
          onChanged: (val) => pageName = val.trim(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (pageName.isNotEmpty) {
                final blankLayout = {
                  "id": "root",
                  "type": "flexCol",
                  "properties": {"padding": 24.0},
                  "children": []
                };
                notifier.updateSlots({'layout_$pageName': blankLayout});
                setState(() {
                  _selectedPage = pageName;
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add Page'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(ThemeConfigModel config, ActiveThemeConfigNotifier notifier) async {
    final nameController = TextEditingController(text: config.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Theme Layout'),
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
            onPressed: () {
              Navigator.of(context).pop(nameController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandEmerald500),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != config.name) {
      notifier.updateName(newName);
    }
  }

  int _countTopLevelSections(dynamic slotValue) {
    if (slotValue is Map && slotValue['children'] is List) {
      return (slotValue['children'] as List).length;
    }
    return 0;
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

  @override
  Widget build(BuildContext context) {
    final themeConfigAsync = ref.watch(activeThemeConfigProvider);
    final mode = ref.watch(customizerModeProvider);
    final navStack = ref.watch(customizerNavStackProvider);
    final selectedSectionId = ref.watch(selectedSectionIdProvider);
    
    final notifier = ref.read(activeThemeConfigProvider.notifier);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final layout = _getLayoutTree(themeConfigAsync.value);

    // Center Panel context resolution
    Widget centerPanel = const SizedBox.shrink();
    if (navStack.isNotEmpty) {
      centerPanel = SectionPropertiesPanel(
        config: themeConfigAsync.value,
        selectedPage: _selectedPage,
        layout: layout,
      );
    } else {
      switch (mode) {
        case CustomizerMode.outline:
          centerPanel = OutlinePanel(
            config: themeConfigAsync.value,
            selectedPage: _selectedPage,
            layout: layout,
          );
          break;
        case CustomizerMode.settings:
          centerPanel = ThemeSettingsPanel(
            config: themeConfigAsync.value,
          );
          break;
        case CustomizerMode.embeds:
          centerPanel = NativeEmbedsPanel(
            config: themeConfigAsync.value,
            selectedPage: _selectedPage,
            layout: layout,
          );
          break;
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmationDialog();
        if (shouldExit && context.mounted) {
          ref.read(editingThemeConfigIdProvider.notifier).setConfigId(null);
          Navigator.of(context).pop();
        }
      },
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            final isControlPressed = event.logicalKey == LogicalKeyboardKey.controlLeft ||
                event.logicalKey == LogicalKeyboardKey.controlRight ||
                HardwareKeyboard.instance.isControlPressed;

            if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyZ) {
              if (notifier.canUndo) notifier.undo();
            } else if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyY) {
              if (notifier.canRedo) notifier.redo();
            }
          }
        },
        child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF1F5F9),
          body: Column(
            children: [
              // 1. Top bar
              _buildTopBar(themeConfigAsync.value, notifier, theme, isDark),

              // 2. Main 3-Pane Body
              Expanded(
                child: Row(
                  children: [
                    // Pane 1: Left utility icon ribbon
                    const IconUtilityRibbon(),

                    // Pane 2: Contextual outline / settings panel
                    centerPanel,

                    // Pane 3: Wide Live Preview Canvas
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _keyboardFocusNode.requestFocus(),
                        child: _buildPreviewCanvas(themeConfigAsync, theme, isDark, selectedSectionId),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    ThemeConfigModel? config,
    ActiveThemeConfigNotifier notifier,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          // Logo/Active Layout info
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Layout: ',
                style: TextStyle(color: theme.hintColor, fontSize: 13),
              ),
              Text(
                config?.name ?? 'Loading...',
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(LucideIcons.pencil, size: 12),
                tooltip: 'Rename Layout',
                onPressed: config == null ? null : () => _showRenameDialog(config, notifier),
              ),
            ],
          ),
          const Spacer(),

          // Page Switcher (Center dropdown)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Storefront > ',
                style: TextStyle(color: theme.hintColor, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPage,
                  dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.bold),
                  items: const [
                    DropdownMenuItem(value: 'home', child: Text('Home Page')),
                    DropdownMenuItem(value: 'pdp', child: Text('Product Details (PDP)')),
                    DropdownMenuItem(value: 'checkout', child: Text('Checkout Page')),
                    DropdownMenuItem(value: 'cart', child: Text('Cart Page')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedPage = val;
                        ref.read(selectedSectionIdProvider.notifier).setSelectedId(null);
                        ref.read(customizerNavStackProvider.notifier).setStack([]);
                      });
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.plus, size: 14, color: AppTheme.brandEmerald500),
                tooltip: 'Add Page Template',
                onPressed: () => _showAddPageDialog(notifier),
              ),
            ],
          ),
          const Spacer(),

          // Actions and toggles
          Row(
            children: [
              // Undo/Redo
              IconButton(
                icon: const Icon(LucideIcons.undo, size: 16),
                onPressed: notifier.canUndo ? () => notifier.undo() : null,
                tooltip: 'Undo',
                color: notifier.canUndo ? theme.colorScheme.onSurface : theme.hintColor.withOpacity(0.3),
              ),
              IconButton(
                icon: const Icon(LucideIcons.redo, size: 16),
                onPressed: notifier.canRedo ? () => notifier.redo() : null,
                tooltip: 'Redo',
                color: notifier.canRedo ? theme.colorScheme.onSurface : theme.hintColor.withOpacity(0.3),
              ),
              const SizedBox(width: 12),
              const VerticalDivider(width: 1, indent: 16, endIndent: 16),
              const SizedBox(width: 12),

              // Device Toggle
              _buildDeviceToggle(theme, isDark),
              const SizedBox(width: 16),

              // Save Draft and Publish CTA
              HoverScale(
                child: ElevatedButton(
                  onPressed: config == null ? null : _handleSaveDraft,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: Text(
                    notifier.getSessionChangesCount() == 0
                        ? 'No changes to save'
                        : 'Save (${notifier.getSessionChangesCount()} changes)',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              HoverScale(
                child: ElevatedButton(
                  onPressed: config == null ? null : _handleSaveAndPublishConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandEmerald500,
                  ),
                  child: const Text('Save & Publish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceToggle(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(LucideIcons.monitor, size: 16, color: !_isMobile ? AppTheme.brandEmerald500 : theme.hintColor),
            onPressed: () => setState(() => _isMobile = false),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
          IconButton(
            icon: Icon(LucideIcons.smartphone, size: 16, color: _isMobile ? AppTheme.brandEmerald500 : theme.hintColor),
            onPressed: () => setState(() => _isMobile = true),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCanvas(
    AsyncValue<dynamic> configAsync,
    ThemeData theme,
    bool isDark,
    String? selectedSectionId,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;

        final double safariWidth = (availableWidth - 24).clamp(300.0, double.infinity);
        final double safariHeight = (availableHeight - 48).clamp(300.0, double.infinity);

        final double contentWidth = _isMobile ? 380.0 : 1200.0;

        return Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
          color: isDark ? const Color(0xFF090D16) : const Color(0xFFE2E8F0),
          child: configAsync.when(
            data: (config) {
              final previewWidget = StorefrontPreview(
                key: _previewContentKey,
                tokens: config?.draftTokens ?? {},
                slots: config?.draftSlots ?? {},
                isMobile: _isMobile,
                previewState: _previewState,
                selectedNodeId: selectedSectionId,
                page: _selectedPage,
                sectionKeys: _sectionKeys,
                onNodeSelected: (id) {
                  ref.read(selectedSectionIdProvider.notifier).setSelectedId(id);
                  ref.read(customizerNavStackProvider.notifier).setStack([id]);
                },
              );

              final Widget scaledContent = SingleChildScrollView(
                child: Center(
                  child: Container(
                    width: contentWidth * _zoomScale,
                    child: FittedBox(
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: contentWidth,
                        child: previewWidget,
                      ),
                    ),
                  ),
                ),
              );

              final Widget canvasStack = Stack(
                fit: StackFit.passthrough,
                children: [
                  scaledContent,
                  CanvasSectionHighlightOverlay(sectionKeys: _sectionKeys),
                ],
              );

              if (_isMobile) {
                return Center(
                  child: _buildMobilePhoneWrapper(
                    child: canvasStack,
                    isDark: isDark,
                    theme: theme,
                  ),
                );
              } else {
                return Center(
                  child: _buildBrowserWrapper(
                    child: canvasStack,
                    isDark: isDark,
                    theme: theme,
                    width: safariWidth,
                    height: safariHeight,
                  ),
                );
              }
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.brandEmerald500)),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        );
      },
    );
  }

  Widget _buildBrowserWrapper({
    required Widget child,
    required bool isDark,
    required ThemeData theme,
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 36, offset: const Offset(0, 16)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
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
                        const Icon(LucideIcons.lock, size: 10, color: AppTheme.brandEmerald500),
                        const SizedBox(width: 6),
                        Text(
                          'https://merchant-preview.kloudshop.com/$_selectedPage',
                          style: TextStyle(color: theme.hintColor, fontSize: 11),
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
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              child: child,
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
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFF1E293B), width: 12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 40, offset: const Offset(0, 20)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 160,
            height: 24,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFF1E293B),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                const SizedBox(width: 30),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getLayoutTree(ThemeConfigModel? config) {
    final key = _selectedPage == 'home' ? 'layout' : 'layout_$_selectedPage';
    if (config != null && config.draftSlots.containsKey(key)) {
      final layout = config.draftSlots[key];
      if (layout is Map<String, dynamic>) {
        return layout;
      }
    }
    return _getDefaultLayoutForPage(_selectedPage, config);
  }

  Map<String, dynamic> _getDefaultLayoutForPage(String page, ThemeConfigModel? config) {
    if (page == 'pdp') {
      return {
        "id": "root",
        "type": "flexCol",
        "properties": {"padding": 0.0},
        "children": [
          {
            "id": "pdp_header_section",
            "type": "flexRow",
            "customName": "Product Detail Header",
            "properties": {"padding": 16.0, "spacing": 16.0, "alignment": "center"},
            "children": [
              {"id": "pdp_back_icon", "type": "icon", "icon_name": "package", "properties": {"color": "tokens.primary"}},
              {"id": "pdp_title", "type": "text", "value": "Premium Leather Jacket", "style": {"font_size": 20.0, "font_weight": "bold", "font_family": "Outfit"}}
            ]
          },
          {
            "id": "pdp_main_section",
            "type": "flexCol",
            "customName": "Product Details Layout",
            "properties": {"padding": 24.0, "spacing": 16.0},
            "children": [
              {
                "id": "pdp_gallery",
                "type": "grid",
                "customName": "Product Gallery",
                "properties": {"columns": 2, "spacing": 8.0},
                "children": [
                  {"type": "flexCol", "properties": {"padding": 40.0, "background_color": "#E2E8F0"}, "children": [{"type": "text", "value": "Front View"}]},
                  {"type": "flexCol", "properties": {"padding": 40.0, "background_color": "#E2E8F0"}, "children": [{"type": "text", "value": "Detail Zoom"}]}
                ]
              },
              {
                "id": "pdp_details_card",
                "type": "flexCol",
                "customName": "Price & Purchase Options",
                "properties": {"padding": 16.0, "background_color": "#F8FAFC"},
                "children": [
                  {"type": "text", "value": "\$129.00", "style": {"font_size": 22.0, "font_weight": "bold", "color": "tokens.primary"}},
                  {"type": "button", "value": "Add to Bag", "style": {"background_color": "tokens.primary", "text_color": "#FFFFFF"}}
                ]
              },
              {"id": "pdp_tabs_widget", "type": "pdp_tabs"}
            ]
          }
        ]
      };
    } else if (page == 'checkout') {
      return {
        "id": "root",
        "type": "flexCol",
        "properties": {"padding": 0.0},
        "children": [
          {
            "id": "checkout_header",
            "type": "flexRow",
            "customName": "Checkout Header",
            "properties": {"padding": 16.0, "background_color": "#0F172A", "alignment": "center"},
            "children": [
              {"type": "text", "value": "Secure Checkout Powered by KloudShop", "style": {"font_size": 14.0, "color": "#FFFFFF", "font_weight": "bold"}}
            ]
          },
          {
            "id": "checkout_content",
            "type": "flexCol",
            "customName": "Payment Details",
            "properties": {"padding": 24.0, "spacing": 16.0},
            "children": [
              {"type": "checkout_form"},
              {"type": "trust_badges"}
            ]
          }
        ]
      };
    } else if (page == 'cart') {
      return {
        "id": "root",
        "type": "flexCol",
        "properties": {"padding": 0.0},
        "children": [
          {
            "id": "cart_header",
            "type": "flexRow",
            "customName": "Cart Header",
            "properties": {"padding": 20.0, "alignment": "spaceBetween"},
            "children": [
              {"type": "text", "value": "Your Shopping Bag", "style": {"font_size": 18.0, "font_weight": "bold", "font_family": "Outfit"}},
              {"type": "text", "value": "2 items", "style": {"font_size": 12.0}}
            ]
          },
          {
            "id": "cart_items_section",
            "type": "flexCol",
            "customName": "Cart Item list",
            "properties": {"padding": 16.0, "spacing": 12.0},
            "children": [
              {
                "type": "flexRow",
                "customName": "Cart Item 1",
                "properties": {"padding": 12.0, "background_color": "#F8FAFC", "alignment": "spaceBetween"},
                "children": [
                  {"type": "text", "value": "Premium Leather Jacket - Size M", "style": {"font_size": 13.0, "font_weight": "bold"}},
                  {"type": "text", "value": "\$129.00", "style": {"font_size": 13.0, "color": "tokens.primary"}}
                ]
              },
              {
                "type": "flexRow",
                "customName": "Cart Item 2",
                "properties": {"padding": 12.0, "background_color": "#F8FAFC", "alignment": "spaceBetween"},
                "children": [
                  {"type": "text", "value": "Urban Canvas Sneakers - Size 10", "style": {"font_size": 13.0, "font_weight": "bold"}},
                  {"type": "text", "value": "\$89.00", "style": {"font_size": 13.0, "color": "tokens.primary"}}
                ]
              }
            ]
          },
          {
            "id": "cart_footer",
            "type": "flexCol",
            "customName": "Total and Checkout Button",
            "properties": {"padding": 24.0, "spacing": 16.0},
            "children": [
              {
                "type": "flexRow",
                "properties": {"alignment": "spaceBetween"},
                "children": [
                  {"type": "text", "value": "Subtotal", "style": {"font_size": 15.0, "font_weight": "bold"}},
                  {"type": "text", "value": "\$218.00", "style": {"font_size": 16.0, "font_weight": "bold", "color": "tokens.primary"}}
                ]
              },
              {"type": "button", "value": "Proceed to Secure Checkout", "style": {"background_color": "tokens.primary", "text_color": "#FFFFFF"}}
            ]
          }
        ]
      };
    }
    return _getDefaultLayout(config);
  }

  Map<String, dynamic> _getDefaultLayout(ThemeConfigModel? config) {
    final shader = config?.draftTokens['background_shader'] ?? 'wave';
    final heading = config?.draftSlots['hero_heading'] ?? 'Modern. Sleek. Professional.';
    final subheading = config?.draftSlots['hero_subheading'] ?? 'The next generation of e-commerce is here.';

    return {
      "id": "root",
      "type": "flexCol",
      "properties": {"padding": 0.0},
      "children": [
        {
          "id": "hero_section",
          "type": "flexCol",
          "properties": {"padding": 54.0, "shader_source": shader, "alignment": "center", "spacing": 16.0},
          "children": [
            {
              "id": "hero_heading",
              "type": "text",
              "value": heading,
              "style": {"font_size": 36.0, "font_weight": "bold", "color": "#FFFFFF", "font_family": "Outfit", "align": "center"}
            },
            {
              "id": "hero_subheading",
              "type": "text",
              "value": subheading,
              "style": {"font_size": 15.0, "color": "#E2E8F0", "font_family": "Inter", "align": "center"}
            },
            {
              "id": "hero_buttons",
              "type": "button",
              "value": "Shop Collection",
              "style": {"background_color": "tokens.primary", "text_color": "#FFFFFF", "border_radius": 8.0}
            }
          ]
        },
        {
          "id": "featured_section",
          "type": "flexCol",
          "properties": {"padding": 24.0, "spacing": 16.0},
          "children": [
            {"id": "featured_heading", "type": "text", "value": "Featured Products", "style": {"font_size": 18.0, "font_weight": "bold", "font_family": "Outfit"}},
            {
              "id": "featured_grid",
              "type": "grid",
              "properties": {"columns": 3, "spacing": 16.0},
              "children": [
                {"id": "prod_1", "type": "product_card", "product_name": "Premium Jacket", "price": "\$129"},
                {"id": "prod_2", "type": "product_card", "product_name": "Urban Sneakers", "price": "\$89"},
                {"id": "prod_3", "type": "product_card", "product_name": "Classic Watch", "price": "\$199"}
              ]
            }
          ]
        }
      ]
    };
  }
}
