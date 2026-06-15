import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/providers/theme_providers.dart';
import 'package:kloudshop/widgets/storefront_preview.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kloudshop/services/api_service.dart';

class WysiwygView extends ConsumerStatefulWidget {
  const WysiwygView({super.key});

  @override
  ConsumerState<WysiwygView> createState() => _WysiwygViewState();
}

class _WysiwygViewState extends ConsumerState<WysiwygView> {
  bool _isMobile = false;
  String _previewState = 'default'; // 'default', 'loading', 'error', 'empty', 'validation'
  bool _isLeftCollapsed = false;
  bool _isRightCollapsed = false;
  String? _selectedNodeId;
  final Set<String> _expandedGroupIds = {'root', 'hero_section', 'featured_section', 'spec_tabs_section', 'footer_section'};

  // Left Pane Accordions & Category States
  bool _isLayersTreeExpanded = true;
  bool _isComponentLibraryExpanded = true;
  final Set<String> _expandedLibraryGroups = {'ESSENTIALS'};

  // Dynamic Viewport Size Caching (for zoom presets)
  double _lastViewportWidth = 1000;
  double _lastViewportHeight = 600;
  final GlobalKey _previewContentKey = GlobalKey();

  // Figma Parity States
  String _selectedPage = 'home'; // 'home', 'pdp', 'checkout', 'cart', or custom
  double _zoomScale = 1.0;
  final List<String> _colorPresets = ['#0D9488', '#0F172A', '#6366F1', '#F43F5E', '#F59E0B'];
  final FocusNode _keyboardFocusNode = FocusNode();

  // Zoom Textfield Editing
  late TextEditingController _zoomTextController;
  late FocusNode _zoomFocusNode;
  bool _isEditingZoom = false;
  bool _isDraggingComponent = false;
  bool _isLeftRibbonHovered = false;
  bool _isRightRibbonHovered = false;

  String get _selectedPageSlotKey => _selectedPage == 'home' ? 'layout' : 'layout_$_selectedPage';

  @override
  void initState() {
    super.initState();
    _zoomTextController = TextEditingController();
    _zoomFocusNode = FocusNode();
    _zoomFocusNode.addListener(() {
      if (!_zoomFocusNode.hasFocus && _isEditingZoom) {
        _submitZoomValue(_zoomTextController.text);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _zoomTextController.dispose();
    _zoomFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _submitZoomValue(String text) {
    final clean = text.replaceAll('%', '').trim();
    final parsed = double.tryParse(clean);
    if (parsed != null && parsed > 0) {
      setState(() {
        _zoomScale = (parsed / 100.0).clamp(0.1, 3.0);
        _isEditingZoom = false;
      });
    } else {
      setState(() {
        _isEditingZoom = false;
      });
    }
  }

  void _addComponentToSelectedOrRoot(Map<String, dynamic> childTemplate) {
    final themeConfig = ref.read(activeThemeConfigProvider).value;
    if (themeConfig == null) return;

    final layout = _getLayoutTree(themeConfig);
    final copiedTree = _deepCopyMap(layout);

    String targetParentId = 'root';
    if (_selectedNodeId != null) {
      final selectedNode = _findNodeInTree(copiedTree, _selectedNodeId!);
      if (selectedNode != null) {
        final type = selectedNode['type'] ?? '';
        final isContainer = ['flexRow', 'flexCol', 'grid', 'stack'].contains(type);
        if (isContainer) {
          targetParentId = _selectedNodeId!;
        }
      }
    }

    final newId = '${childTemplate['type']}_${DateTime.now().microsecondsSinceEpoch}';
    final nodeToInsert = _deepCopyMap(childTemplate);
    nodeToInsert['id'] = newId;

    _insertNodeIntoTree(copiedTree, targetParentId, 9999, nodeToInsert);

    setState(() {
      _selectedNodeId = newId;
      _expandedGroupIds.add(targetParentId);
    });

    ref.read(activeThemeConfigProvider.notifier).updateSlots(
      {_selectedPageSlotKey: copiedTree},
      editKey: 'layout_add_click',
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeConfigAsync = ref.watch(activeThemeConfigProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final isControlPressed = event.logicalKey == LogicalKeyboardKey.controlLeft ||
              event.logicalKey == LogicalKeyboardKey.controlRight ||
              HardwareKeyboard.instance.isControlPressed;

          if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyZ) {
            final notifier = ref.read(activeThemeConfigProvider.notifier);
            if (notifier.canUndo) notifier.undo();
          } else if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyY) {
            final notifier = ref.read(activeThemeConfigProvider.notifier);
            if (notifier.canRedo) notifier.redo();
          } else if (event.logicalKey == LogicalKeyboardKey.delete ||
              event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_selectedNodeId != null && _selectedNodeId != 'root') {
              _handleDeleteNode(_selectedNodeId!);
            }
          } else if (_selectedNodeId != null) {
            // Nudging absolute elements
            final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
            final nudgeAmount = isShiftPressed ? 10.0 : 1.0;
            double dx = 0;
            double dy = 0;
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) dx = -nudgeAmount;
            if (event.logicalKey == LogicalKeyboardKey.arrowRight) dx = nudgeAmount;
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) dy = -nudgeAmount;
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) dy = nudgeAmount;

            if (dx != 0 || dy != 0) {
              _nudgeSelectedNode(dx, dy);
            }
          }
        }
      },
      child: Scaffold(
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
                  // Left Component Stack (Layers & Primitives)
                  AnimatedContainer(
                    width: _isLeftCollapsed ? 0 : 280,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(),
                    child: SizedBox(
                      width: 280,
                      child: _buildLeftComponentStack(themeConfigAsync.value, theme, isDark),
                    ),
                  ),

                  // Left Collapse Ribbon
                  _buildLeftCollapseRibbon(theme, isDark),

                  // Interactive Zoomable Device Canvas Viewport
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _keyboardFocusNode.requestFocus(),
                      child: _buildPreviewCanvas(themeConfigAsync, theme, isDark),
                    ),
                  ),

                  // Right Collapse Ribbon
                  _buildRightCollapseRibbon(theme, isDark),

                  // Grouped Right Config Panel
                  AnimatedContainer(
                    width: _isRightCollapsed ? 0 : 350,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(),
                    child: SizedBox(
                      width: 350,
                      child: _buildRightConfigPanel(themeConfigAsync, theme, isDark),
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

  Widget _buildLeftCollapseRibbon(ThemeData theme, bool isDark) {
    final hoverColor = AppTheme.brandEmerald500.withOpacity(isDark ? 0.3 : 0.15);
    final normalColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isLeftRibbonHovered = true),
      onExit: (_) => setState(() => _isLeftRibbonHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _isLeftCollapsed = !_isLeftCollapsed),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 16,
          height: double.infinity,
          decoration: BoxDecoration(
            color: _isLeftRibbonHovered ? hoverColor : normalColor,
            border: Border(
              right: BorderSide(color: theme.dividerColor),
              left: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: _isLeftRibbonHovered 
                      ? AppTheme.brandEmerald500 
                      : theme.hintColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                _isLeftCollapsed ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
                size: 10,
                color: _isLeftRibbonHovered ? AppTheme.brandEmerald500 : theme.hintColor.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightCollapseRibbon(ThemeData theme, bool isDark) {
    final hoverColor = AppTheme.brandEmerald500.withOpacity(isDark ? 0.3 : 0.15);
    final normalColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isRightRibbonHovered = true),
      onExit: (_) => setState(() => _isRightRibbonHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _isRightCollapsed = !_isRightCollapsed),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 16,
          height: double.infinity,
          decoration: BoxDecoration(
            color: _isRightRibbonHovered ? hoverColor : normalColor,
            border: Border(
              left: BorderSide(color: theme.dividerColor),
              right: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: _isRightRibbonHovered 
                      ? AppTheme.brandEmerald500 
                      : theme.hintColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                _isRightCollapsed ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                size: 10,
                color: _isRightRibbonHovered ? AppTheme.brandEmerald500 : theme.hintColor.withOpacity(0.6),
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
              // Left Section Group
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HoverScale(
                    child: IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Exit Editor',
                    ),
                  ),
                  const SizedBox(width: 8),
                  HoverScale(
                    child: IconButton(
                      icon: const Icon(LucideIcons.save, size: 20),
                      onPressed: () => _handlePublish(),
                      tooltip: 'Save & Publish',
                    ),
                  ),
                  const SizedBox(width: 8),
                  HoverScale(
                    child: IconButton(
                      icon: const Icon(LucideIcons.undo, size: 18),
                      onPressed: notifier.canUndo ? () => notifier.undo() : null,
                      tooltip: 'Undo',
                      color: notifier.canUndo ? theme.colorScheme.onSurface : theme.hintColor.withOpacity(0.3),
                    ),
                  ),
                  HoverScale(
                    child: IconButton(
                      icon: const Icon(LucideIcons.redo, size: 18),
                      onPressed: notifier.canRedo ? () => notifier.redo() : null,
                      tooltip: 'Redo',
                      color: notifier.canRedo ? theme.colorScheme.onSurface : theme.hintColor.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const VerticalDivider(width: 1, indent: 20, endIndent: 20),
                  const SizedBox(width: 16),

                  // Page selector dropdown
                  Text(
                    'Storefront > ',
                    style: TextStyle(
                      color: theme.hintColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPage,
                      dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
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
                            _selectedNodeId = null;
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
                  const SizedBox(width: 8),
                  const VerticalDivider(width: 1, indent: 20, endIndent: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Layout: ',
                    style: TextStyle(
                      color: theme.hintColor,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    config?.name ?? 'Loading...',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.pencil, size: 12),
                    tooltip: 'Rename Layout',
                    onPressed: config == null ? null : () => _showRenameDialog(config, notifier),
                  ),
                ],
              ),
              const Spacer(),
              // Right Section Group (Wrapped in horizontal SingleChildScrollView to prevent overflows)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Zoom controls (- 100% +)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HoverScale(
                            child: IconButton(
                              icon: const Icon(LucideIcons.minus, size: 14),
                              tooltip: 'Zoom Out',
                              onPressed: _zoomScale > 0.5 ? () => setState(() => _zoomScale -= 0.1) : null,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _isEditingZoom
                              ? SizedBox(
                                  width: 60,
                                  child: TextField(
                                    controller: _zoomTextController,
                                    focusNode: _zoomFocusNode,
                                    keyboardType: TextInputType.text,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                      filled: true,
                                      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: const BorderSide(color: AppTheme.brandEmerald500, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: const BorderSide(color: AppTheme.brandEmerald500, width: 1.5),
                                      ),
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[0-9%]')),
                                    ],
                                    onSubmitted: _submitZoomValue,
                                  ),
                                )
                              : MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isEditingZoom = true;
                                        _zoomTextController.text = '${(_zoomScale * 100).toStringAsFixed(0)}%';
                                      });
                                      _zoomFocusNode.requestFocus();
                                      _zoomTextController.selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset: _zoomTextController.text.length,
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: Colors.transparent,
                                      ),
                                      child: Text(
                                        '${(_zoomScale * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.brandEmerald500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                          const SizedBox(width: 4),
                          HoverScale(
                            child: IconButton(
                              icon: const Icon(LucideIcons.plus, size: 14),
                              tooltip: 'Zoom In',
                              onPressed: _zoomScale < 1.5 ? () => setState(() => _zoomScale += 0.1) : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      HoverScale(
                        child: IconButton(
                          icon: const Icon(LucideIcons.expand, size: 16),
                          tooltip: 'Fit Width',
                          onPressed: () {
                            final contentWidth = _isMobile ? 380.0 : 1200.0;
                            _zoomFitWidth(_lastViewportWidth, contentWidth);
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      HoverScale(
                        child: IconButton(
                          icon: const Icon(LucideIcons.maximize, size: 16),
                          tooltip: 'Fit Height',
                          onPressed: () => _zoomFitHeight(_lastViewportHeight),
                        ),
                      ),
                      const SizedBox(width: 4),
                      HoverScale(
                        child: IconButton(
                          icon: const Icon(LucideIcons.monitor, size: 16),
                          tooltip: 'Full Page',
                          onPressed: () {
                            final contentWidth = _isMobile ? 380.0 : 1200.0;
                            _zoomFullPage(_lastViewportWidth, _lastViewportHeight, contentWidth);
                          },
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Fullscreen Preview Tab
                      HoverScale(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => WysiwygFullscreenPreview(
                                  tokens: config?.draftTokens ?? {},
                                  slots: config?.draftSlots ?? {},
                                  page: _selectedPage,
                                  previewState: _previewState,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(LucideIcons.externalLink, size: 14),
                          label: const Text('Preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Clone Layout Button (A/B testing)
                      HoverScale(
                        child: OutlinedButton.icon(
                          onPressed: config == null ? null : () => _handleClone(config),
                          icon: const Icon(LucideIcons.copy, size: 14),
                          label: const Text('Clone Layout', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Preview State Selector
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _previewState,
                            dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'default', child: Text('View: Active Draft')),
                              DropdownMenuItem(value: 'loading', child: Text('View: Stripe Loading')),
                              DropdownMenuItem(value: 'error', child: Text('View: Insufficient Funds')),
                              DropdownMenuItem(value: 'empty', child: Text('View: Empty Cart')),
                              DropdownMenuItem(value: 'validation', child: Text('View: Invalid CVV')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _previewState = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Responsive Toggles
                      _buildDeviceToggle(theme, isDark),
                      const SizedBox(width: 16),

                      // Create from Scratch
                      HoverScale(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleCreateFromScratch(),
                          icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                          label: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Publish
                      HoverScale(
                        child: ElevatedButton.icon(
                          onPressed: () => _handlePublish(),
                          icon: const Icon(LucideIcons.rocket, size: 16, color: Colors.white),
                          label: const Text('Publish', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandEmerald500,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  void _zoomFitWidth(double viewportWidth, double contentWidth) {
    setState(() {
      _zoomScale = (viewportWidth / contentWidth).clamp(0.1, 3.0);
    });
  }

  void _zoomFitHeight(double viewportHeight) {
    final renderBox = _previewContentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final contentHeight = renderBox.size.height;
      if (contentHeight > 0) {
        setState(() {
          _zoomScale = (viewportHeight / contentHeight).clamp(0.1, 3.0);
        });
        return;
      }
    }
    setState(() {
      _zoomScale = (viewportHeight / 1000.0).clamp(0.1, 3.0);
    });
  }

  void _zoomFullPage(double viewportWidth, double viewportHeight, double contentWidth) {
    final renderBox = _previewContentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final contentHeight = renderBox.size.height;
      if (contentHeight > 0) {
        final fitWidthScale = viewportWidth / contentWidth;
        final fitHeightScale = viewportHeight / contentHeight;
        setState(() {
          _zoomScale = (fitWidthScale < fitHeightScale ? fitWidthScale : fitHeightScale).clamp(0.1, 3.0);
        });
        return;
      }
    }
    setState(() {
      _zoomScale = (viewportWidth / contentWidth).clamp(0.1, 3.0);
    });
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
          _buildToggleIconButton(LucideIcons.monitor, !_isMobile, () => setState(() => _isMobile = false), theme, isDark),
          const SizedBox(width: 4),
          _buildToggleIconButton(LucideIcons.smartphone, _isMobile, () => setState(() => _isMobile = true), theme, isDark),
        ],
      ),
    );
  }

  Widget _buildToggleIconButton(IconData icon, bool active, VoidCallback onTap, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? (isDark ? const Color(0xFF0F172A) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: active ? AppTheme.brandEmerald500 : theme.hintColor),
      ),
    );
  }

  Widget _buildLeftComponentStack(ThemeConfigModel? config, ThemeData theme, bool isDark) {
    final layout = _getLayoutTree(config);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Layers Tree Accordion Header
            _AccordionHeaderTile(
              title: 'Layers Tree',
              icon: LucideIcons.layers,
              isExpanded: _isLayersTreeExpanded,
              onTap: () => setState(() => _isLayersTreeExpanded = !_isLayersTreeExpanded),
              theme: theme,
              isDark: isDark,
            ),
            
            // 2. Layers Tree Content
            if (_isLayersTreeExpanded)
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.2) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(4.0),
                    children: [
                      _buildComponentTree(layout, theme, isDark),
                    ],
                  ),
                ),
              ),

            // 3. Component Library Accordion Header
            _AccordionHeaderTile(
              title: 'Component Library',
              icon: LucideIcons.plusCircle,
              isExpanded: _isComponentLibraryExpanded,
              onTap: () => setState(() => _isComponentLibraryExpanded = !_isComponentLibraryExpanded),
              theme: theme,
              isDark: isDark,
            ),

            // 4. Component Library Content
            if (_isComponentLibraryExpanded)
              _buildComponentLibraryInline(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildComponentTree(Map<String, dynamic> node, ThemeData theme, bool isDark, {int depth = 0}) {
    final id = node['id'] ?? '';
    final type = node['type'] ?? 'flexCol';
    final children = node['children'] as List<dynamic>? ?? [];

    final isSelected = _selectedNodeId == id;
    final isContainer = ['flexRow', 'flexCol', 'grid', 'stack'].contains(type);
    final isLocked = node['locked'] == true;
    final isHidden = node['hidden'] == true;

    String name = _getFriendlyNodeName(node);
    IconData icon = _getNodeIcon(type);

    Widget itemContent = Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandEmerald500.withOpacity(isDark ? 0.2 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: AppTheme.brandEmerald500, width: 1.5) : null,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                final themeConfig = ref.read(activeThemeConfigProvider).value;
                if (themeConfig == null) return;
                final layoutTree = _getLayoutTree(themeConfig);
                final copied = _deepCopyMap(layoutTree);
                _updateNodeMetaProperty(copied, id, 'hidden', !isHidden);
                ref.read(activeThemeConfigProvider.notifier).updateSlots({_selectedPageSlotKey: copied}, editKey: 'hidden_$id');
              },
              child: Icon(
                isHidden ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 12,
                color: isHidden ? Colors.redAccent : theme.hintColor,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                final themeConfig = ref.read(activeThemeConfigProvider).value;
                if (themeConfig == null) return;
                final layoutTree = _getLayoutTree(themeConfig);
                final copied = _deepCopyMap(layoutTree);
                _updateNodeMetaProperty(copied, id, 'locked', !isLocked);
                ref.read(activeThemeConfigProvider.notifier).updateSlots({_selectedPageSlotKey: copied}, editKey: 'locked_$id');
              },
              child: Icon(
                isLocked ? LucideIcons.lock : LucideIcons.unlock,
                size: 12,
                color: isLocked ? AppTheme.brandEmerald500 : theme.hintColor,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 13, color: isSelected ? AppTheme.brandEmerald500 : theme.hintColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppTheme.brandEmerald500 : (isHidden ? theme.hintColor.withOpacity(0.5) : null),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected && id != 'root')
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(LucideIcons.trash2, size: 12, color: Colors.redAccent),
                onPressed: () => _handleDeleteNode(id),
                tooltip: 'Delete Layer',
              ),
          ],
        ),
      ),
    );

    itemContent = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedNodeId = id;
        });
      },
      child: itemContent,
    );

    if (isContainer && children.isNotEmpty) {
      final isExpanded = _expandedGroupIds.contains(id);
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B).withOpacity(0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.brandEmerald500.withOpacity(0.5) : theme.dividerColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedGroupIds.remove(id);
                        } else {
                          _expandedGroupIds.add(id);
                        }
                      });
                    },
                    child: Icon(
                      isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                      size: 12,
                      color: theme.hintColor,
                    ),
                  ),
                  Expanded(child: itemContent),
                ],
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 4, bottom: 4),
                child: Column(
                  children: children
                      .map((child) => child is Map<String, dynamic>
                          ? _buildComponentTree(child, theme, isDark, depth: depth + 1)
                          : const SizedBox.shrink())
                      .toList(),
                ),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: itemContent,
    );
  }

  Widget _buildComponentLibraryInline(ThemeData theme, bool isDark) {
    final Map<String, List<Map<String, dynamic>>> groups = {
      'ESSENTIALS': [
        {
          'label': 'Hero',
          'icon': LucideIcons.image,
          'data': {
            'type': 'flexCol',
            'customName': 'Hero Section',
            'properties': {'padding': 48.0, 'spacing': 16.0, 'alignment': 'center', 'background_color': '#0F172A', 'shader_source': 'wave'},
            'children': [
              {'type': 'text', 'value': 'Precision Built for Global Scale.', 'style': {'font_size': 32.0, 'font_weight': 'bold', 'color': '#FFFFFF', 'font_family': 'Outfit', 'align': 'center'}},
              {'type': 'text', 'value': 'Deploy high-altitude commerce environments with surgical accuracy.', 'style': {'font_size': 14.0, 'color': '#94A3B8', 'font_family': 'Inter', 'align': 'center'}},
              {'type': 'button', 'value': 'Start Operations', 'style': {'background_color': 'tokens.primary', 'text_color': '#FFFFFF', 'border_radius': 8.0}}
            ]
          }
        },
        {
          'label': 'Features',
          'icon': LucideIcons.layoutGrid,
          'data': {
            'type': 'flexCol',
            'customName': 'Features Grid',
            'properties': {'padding': 24.0, 'spacing': 16.0},
            'children': [
              {'type': 'text', 'value': 'High-Altitude Features', 'style': {'font_size': 18.0, 'font_weight': 'bold', 'font_family': 'Outfit'}},
              {
                'type': 'flexRow',
                'properties': {'spacing': 16.0, 'padding': 8.0},
                'children': [
                  {
                    'type': 'flexCol',
                    'customName': 'Feature A',
                    'properties': {'padding': 12.0, 'background_color': '#F8FAFC'},
                    'children': [
                      {'type': 'icon', 'icon_name': 'store', 'properties': {'color': 'tokens.primary'}},
                      {'type': 'text', 'value': 'Native Speed', 'style': {'font_size': 12.0, 'font_weight': 'bold'}},
                      {'type': 'text', 'value': 'Built on Flutter.', 'style': {'font_size': 10.0}}
                    ]
                  },
                  {
                    'type': 'flexCol',
                    'customName': 'Feature B',
                    'properties': {'padding': 12.0, 'background_color': '#F8FAFC'},
                    'children': [
                      {'type': 'icon', 'icon_name': 'shoppingBag', 'properties': {'color': 'tokens.primary'}},
                      {'type': 'text', 'value': 'Smart Cart', 'style': {'font_size': 12.0, 'font_weight': 'bold'}},
                      {'type': 'text', 'value': 'Optimized flows.', 'style': {'font_size': 10.0}}
                    ]
                  }
                ]
              }
            ]
          }
        },
        {
          'label': 'Banner CTA',
          'icon': LucideIcons.megaphone,
          'data': {
            'type': 'flexRow',
            'customName': 'Announcement Banner',
            'properties': {'padding': 12.0, 'background_color': 'tokens.primary', 'alignment': 'center', 'spacing': 8.0},
            'children': [
              {'type': 'icon', 'icon_name': 'store', 'properties': {'color': '#FFFFFF'}},
              {'type': 'text', 'value': 'FLASH SALE: Get 20% off today! Code: KLOUD20', 'style': {'font_size': 11.0, 'color': '#FFFFFF', 'font_weight': 'bold'}}
            ]
          }
        },
        {
          'label': 'FAQ Accordion',
          'icon': LucideIcons.helpCircle,
          'data': {
            'type': 'flexCol',
            'customName': 'FAQ Accordion',
            'properties': {'padding': 24.0, 'spacing': 8.0},
            'children': [
              {'type': 'text', 'value': 'Frequently Asked Questions', 'style': {'font_size': 16.0, 'font_weight': 'bold'}},
              {'type': 'text', 'value': 'Q: How fast is shipping? \nA: We ship instantly within 24 hours.', 'style': {'font_size': 12.0}}
            ]
          }
        },
        {
          'label': 'Testimonials',
          'icon': LucideIcons.messageSquare,
          'data': {
            'type': 'testimonials',
            'customName': 'Client Testimonials'
          }
        }
      ],
      'COMMERCE': [
        {
          'label': 'Product Grid',
          'icon': LucideIcons.grid,
          'data': {
            'type': 'grid',
            'customName': 'Product Grid',
            'properties': {'columns': 3, 'spacing': 16.0, 'padding': 16.0},
            'children': [
              {'type': 'product_card', 'product_name': 'Premium Jacket', 'price': '\$129'},
              {'type': 'product_card', 'product_name': 'Urban Sneakers', 'price': '\$89'},
              {'type': 'product_card', 'product_name': 'Classic Watch', 'price': '\$199'}
            ]
          }
        },
        {
          'label': 'Product Carousel',
          'icon': LucideIcons.arrowRightLeft,
          'data': {
            'type': 'flexRow',
            'customName': 'Product Carousel',
            'properties': {'padding': 16.0, 'spacing': 12.0, 'alignment': 'start'},
            'children': [
              {'type': 'product_card', 'product_name': 'Product A', 'price': '\$49'},
              {'type': 'product_card', 'product_name': 'Product B', 'price': '\$59'},
              {'type': 'product_card', 'product_name': 'Product C', 'price': '\$69'}
            ]
          }
        },
        {
          'label': 'Smart Cart',
          'icon': LucideIcons.shoppingBag,
          'data': {
            'type': 'flexRow',
            'customName': 'Smart Cart Banner',
            'properties': {'padding': 16.0, 'background_color': '#F1F5F9', 'alignment': 'spaceBetween'},
            'children': [
              {'type': 'text', 'value': 'You have items in your cart', 'style': {'font_size': 13.0, 'font_weight': 'bold'}},
              {'type': 'button', 'value': 'View Cart', 'style': {'background_color': '#0F172A', 'text_color': '#FFFFFF'}}
            ]
          }
        },
        {
          'label': 'Inventory Badge',
          'icon': LucideIcons.alertTriangle,
          'data': {
            'type': 'flexRow',
            'customName': 'Inventory Badge',
            'properties': {'padding': 6.0, 'background_color': '#FEE2E2', 'alignment': 'center'},
            'children': [
              {'type': 'text', 'value': 'Low Stock: Only 3 items left!', 'style': {'font_size': 10.0, 'color': '#EF4444', 'font_weight': 'bold'}}
            ]
          }
        },
        {
          'label': 'Checkout Form',
          'icon': LucideIcons.creditCard,
          'data': {
            'type': 'flexCol',
            'customName': 'Checkout Form',
            'properties': {'padding': 24.0, 'spacing': 12.0, 'background_color': '#F8FAFC', 'border_style': 'solid', 'stroke_width': 1.0, 'border_color': '#E2E8F0'},
            'children': [
              {'type': 'text', 'value': 'Secure Checkout', 'style': {'font_size': 15.0, 'font_weight': 'bold'}},
              {'type': 'button', 'value': 'Complete Payment', 'style': {'background_color': 'tokens.primary', 'text_color': '#FFFFFF'}}
            ]
          }
        },
        {
          'label': 'Trust Badges',
          'icon': LucideIcons.shieldCheck,
          'data': {
            'type': 'trust_badges',
            'customName': 'Trust & Security Badges'
          }
        },
        {
          'label': 'Collection List',
          'icon': LucideIcons.list,
          'data': {
            'type': 'collection_list',
            'customName': 'Shop by Collections'
          }
        }
      ],
      'MEDIA': [
        {
          'label': 'Image',
          'icon': LucideIcons.image,
          'data': {
            'type': 'flexCol',
            'customName': 'Image Block',
            'properties': {'padding': 40.0, 'background_color': '#E2E8F0', 'alignment': 'center'},
            'children': [
              {'type': 'icon', 'icon_name': 'package', 'properties': {'color': '#64748B'}},
              {'type': 'text', 'value': 'Premium Image Frame', 'style': {'font_size': 12.0, 'color': '#64748B'}}
            ]
          }
        },
        {
          'label': 'Video',
          'icon': LucideIcons.video,
          'data': {
            'type': 'flexCol',
            'customName': 'Video Block',
            'properties': {'padding': 48.0, 'background_color': '#0F172A', 'alignment': 'center'},
            'children': [
              {'type': 'icon', 'icon_name': 'playCircle', 'properties': {'color': '#FFFFFF'}},
              {'type': 'text', 'value': 'Simulated Video Player', 'style': {'font_size': 11.0, 'color': '#94A3B8'}}
            ]
          }
        },
        {
          'label': 'Gallery',
          'icon': LucideIcons.images,
          'data': {
            'type': 'grid',
            'customName': 'Image Gallery',
            'properties': {'columns': 2, 'spacing': 8.0, 'padding': 8.0},
            'children': [
              {'type': 'flexCol', 'properties': {'padding': 24.0, 'background_color': '#E2E8F0'}, 'children': [{'type': 'text', 'value': 'Image 1'}]},
              {'type': 'flexCol', 'properties': {'padding': 24.0, 'background_color': '#E2E8F0'}, 'children': [{'type': 'text', 'value': 'Image 2'}]}
            ]
          }
        },
        {
          'label': 'Logo Grid',
          'icon': LucideIcons.layoutGrid,
          'data': {
            'type': 'flexRow',
            'customName': 'Partner Logos',
            'properties': {'padding': 16.0, 'spacing': 24.0, 'alignment': 'center'},
            'children': [
              {'type': 'text', 'value': 'BRAND A', 'style': {'font_size': 11.0, 'font_weight': 'bold', 'color': '#64748B'}},
              {'type': 'text', 'value': 'BRAND B', 'style': {'font_size': 11.0, 'font_weight': 'bold', 'color': '#64748B'}},
              {'type': 'text', 'value': 'BRAND C', 'style': {'font_size': 11.0, 'font_weight': 'bold', 'color': '#64748B'}}
            ]
          }
        },
        {
          'label': 'Store Locator',
          'icon': LucideIcons.mapPin,
          'data': {
            'type': 'store_locator',
            'customName': 'Find Our Store'
          }
        },
        {
          'label': 'Newsletter',
          'icon': LucideIcons.mail,
          'data': {
            'type': 'newsletter_signup',
            'customName': 'Newsletter Sign Up'
          }
        }
      ],
      'LAYOUTS & DESIGN': [
        {
          'label': 'Row Layout',
          'icon': LucideIcons.alignJustify,
          'data': {
            'type': 'flexRow',
            'customName': 'Row Container',
            'properties': {'padding': 8.0, 'spacing': 8.0, 'alignment': 'start'},
            'children': []
          }
        },
        {
          'label': 'Col Layout',
          'icon': LucideIcons.alignLeft,
          'data': {
            'type': 'flexCol',
            'customName': 'Column Container',
            'properties': {'padding': 8.0, 'spacing': 8.0, 'alignment': 'start'},
            'children': []
          }
        },
        {
          'label': 'Grid Layout',
          'icon': LucideIcons.grid,
          'data': {
            'type': 'grid',
            'customName': 'Grid Container',
            'properties': {'columns': 3, 'spacing': 8.0, 'padding': 8.0},
            'children': []
          }
        },
        {
          'label': 'Overlay Stack',
          'icon': LucideIcons.layers,
          'data': {
            'type': 'stack',
            'customName': 'Overlay Stack',
            'properties': {'padding': 0.0},
            'children': []
          }
        },
        {
          'label': 'Card Container',
          'icon': LucideIcons.square,
          'data': {
            'type': 'flexCol',
            'customName': 'Premium Card Container',
            'properties': {
              'padding': 16.0,
              'background_color': '#FFFFFF',
              'border_style': 'solid',
              'stroke_width': 1.0,
              'border_color': '#E2E8F0',
              'elevation': 2.0
            },
            'children': []
          }
        },
        {
          'label': 'Divider',
          'icon': LucideIcons.minus,
          'data': {'type': 'divider', 'customName': 'Divider'}
        },
        {
          'label': 'Spacer',
          'icon': LucideIcons.move,
          'data': {
            'type': 'spacer',
            'customName': 'Spacer Space',
            'properties': {'height': 24.0}
          }
        }
      ]
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: groups.entries.map((entry) {
        final groupName = entry.key;
        final primitivesList = entry.value;
        final isExpanded = _expandedLibraryGroups.contains(groupName);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LibraryGroupHeaderTile(
              title: groupName,
              isExpanded: isExpanded,
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedLibraryGroups.remove(groupName);
                  } else {
                    _expandedLibraryGroups.add(groupName);
                  }
                });
              },
              theme: theme,
              isDark: isDark,
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: primitivesList.length,
                  itemBuilder: (context, idx) {
                    final prim = primitivesList[idx];
                    final data = prim['data'] as Map<String, dynamic>;
                    return GestureDetector(
                      onDoubleTap: () => _addComponentToSelectedOrRoot(data),
                      child: Draggable<Map<String, dynamic>>(
                        data: data,
                        onDragStarted: () => setState(() => _isDraggingComponent = true),
                        onDragEnd: (_) => setState(() => _isDraggingComponent = false),
                        onDraggableCanceled: (_, __) => setState(() => _isDraggingComponent = false),
                        feedback: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.brandEmerald500.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              prim['label'],
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(prim['icon'], size: 14, color: theme.hintColor),
                                const SizedBox(height: 2),
                                Text(
                                  prim['label'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRightConfigPanel(
    AsyncValue<dynamic> configAsync,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: configAsync.when(
        data: (config) => _buildRightConfigPanelContent(config, theme, isDark),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.brandEmerald500)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildRightConfigPanelContent(
    ThemeConfigModel? config,
    ThemeData theme,
    bool isDark,
  ) {
    if (config == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.brandEmerald500));
    }

    final layout = _getLayoutTree(config);

    if (_selectedNodeId == null) {
      // General Page Settings
      final bgType = config.draftTokens['bg_type'] ?? 'solid';
      final bgColor = config.draftTokens['bg_color'] ?? '#FFFFFF';
      final bgGradType = config.draftTokens['bg_gradient_type'] ?? 'linear';
      final bgGradStart = config.draftTokens['bg_gradient_start'] ?? '#FFFFFF';
      final bgGradEnd = config.draftTokens['bg_gradient_end'] ?? '#E2E8F0';
      final bgImgUrl = config.draftTokens['bg_image_url'] ?? '';
      final bgImgFit = config.draftTokens['bg_image_fit'] ?? 'cover';
      final bgImgRepeat = config.draftTokens['bg_image_repeat'] ?? 'no-repeat';
      final bgImgOpacity = _parseDouble(config.draftTokens['bg_image_opacity'], 1.0);
      final bgShader = config.draftTokens['bg_shader'] ?? 'wave';

      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Canvas Settings',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          
          _buildConfigGroup(
            title: 'Page Background',
            icon: LucideIcons.palette,
            theme: theme,
            isDark: isDark,
            children: [
              _buildSlotDropdown(
                'Background Style Type',
                'bg_type',
                bgType,
                ['solid', 'gradient', 'image', 'shader'],
                theme,
                isToken: true,
              ),
              const SizedBox(height: 12),
              
              if (bgType == 'solid') ...[
                _colorPickerTile('Solid Color', 'bg_color', bgColor, theme),
                _buildColorSwatchesRow('bg_color', bgColor, '', isToken: true, tokenKey: 'bg_color'),
              ] else if (bgType == 'gradient') ...[
                _buildSlotDropdown(
                  'Gradient Type',
                  'bg_gradient_type',
                  bgGradType,
                  ['linear', 'radial'],
                  theme,
                  isToken: true,
                ),
                const SizedBox(height: 12),
                _colorPickerTile('Start Color', 'bg_gradient_start', bgGradStart, theme),
                _buildColorSwatchesRow('bg_gradient_start', bgGradStart, '', isToken: true, tokenKey: 'bg_gradient_start'),
                const SizedBox(height: 12),
                _colorPickerTile('End Color', 'bg_gradient_end', bgGradEnd, theme),
                _buildColorSwatchesRow('bg_gradient_end', bgGradEnd, '', isToken: true, tokenKey: 'bg_gradient_end'),
              ] else if (bgType == 'image') ...[
                _buildSlotTextEditor('Background Image URL', 'bg_image_url', bgImgUrl, theme, isToken: true),
                const SizedBox(height: 12),
                _buildSlotDropdown(
                  'Image Fit',
                  'bg_image_fit',
                  bgImgFit,
                  ['cover', 'contain', 'fill'],
                  theme,
                  isToken: true,
                ),
                const SizedBox(height: 12),
                _buildSlotDropdown(
                  'Image Repeat',
                  'bg_image_repeat',
                  bgImgRepeat,
                  ['no-repeat', 'repeat'],
                  theme,
                  isToken: true,
                ),
                const SizedBox(height: 12),
                _buildTokenSpinInput(
                  label: 'Image Opacity',
                  key: 'bg_image_opacity',
                  value: bgImgOpacity,
                  min: 0.0,
                  max: 1.0,
                  step: 0.1,
                ),
              ] else if (bgType == 'shader') ...[
                _buildSlotDropdown(
                  'Liquid Shader Wave',
                  'bg_shader',
                  bgShader,
                  ['wave', 'aurora', 'cosmic'],
                  theme,
                  isToken: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          
          _buildConfigGroup(
            title: 'Global Design Tokens',
            icon: LucideIcons.settings,
            theme: theme,
            isDark: isDark,
            children: [
              _colorPickerTile('Brand Primary Color', 'primary', config.draftTokens['primary'], theme),
              _buildColorSwatchesRow('primary', config.draftTokens['primary'], '', isToken: true, tokenKey: 'primary'),
              const SizedBox(height: 12),
              _colorPickerTile('Brand Secondary Color', 'secondary', config.draftTokens['secondary'], theme),
              _buildColorSwatchesRow('secondary', config.draftTokens['secondary'], '', isToken: true, tokenKey: 'secondary'),
              const SizedBox(height: 12),
              _colorPickerTile('Selection Highlight', 'highlight_color', config.draftTokens['highlight_color'] ?? '#18A0FB', theme),
              _buildColorSwatchesRow('highlight_color', config.draftTokens['highlight_color'] ?? '#18A0FB', '', isToken: true, tokenKey: 'highlight_color'),
              const Divider(),
              _buildTokenSpinInput(
                label: 'Global Border Radius',
                key: 'border_radius',
                value: _parseDouble(config.draftTokens['border_radius'], 12.0),
                min: 0.0,
                max: 32.0,
              ),
            ],
          ),
        ],
      );
    }

    final selectedNode = _findNodeInTree(layout, _selectedNodeId!);
    if (selectedNode == null) {
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('Node $_selectedNodeId not found', style: const TextStyle(color: Colors.redAccent)),
        ],
      );
    }

    final type = selectedNode['type'] ?? '';
    final props = selectedNode['properties'] ?? {};
    final style = selectedNode['style'] ?? {};
    final nodeId = selectedNode['id'] ?? '';

    final isAbsolute = props['position'] == 'absolute';

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Node Header
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(_getNodeIcon(type), size: 16, color: AppTheme.brandEmerald500),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getFriendlyNodeName(selectedNode),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        
        // Double-click rename alternative textfield
        _buildNodeTextEditor('Rename Layer Name', selectedNode, 'customName', theme),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),

        // Absolute geometry section
        if (isAbsolute) ...[
          _buildAbsolutePositionFields(selectedNode, theme),
          const SizedBox(height: 12),
        ],

        if (type == 'text') ...[
          _buildNodeTextEditor('Text Content', selectedNode, 'value', theme),
          const SizedBox(height: 12),
          _buildNodeSpinInput(
            label: 'Font Size',
            node: selectedNode,
            propKey: 'font_size',
            value: _parseDouble(style['font_size'], 14.0),
            min: 8.0,
            max: 72.0,
            isStyle: true,
          ),
          const SizedBox(height: 12),
          _buildNodeDropdown(
            label: 'Font Weight',
            node: selectedNode,
            propKey: 'font_weight',
            value: style['font_weight'] ?? 'normal',
            options: ['normal', 'bold'],
            theme: theme,
            isStyle: true,
          ),
          const SizedBox(height: 12),
          _buildNodeDropdown(
            label: 'Alignment',
            node: selectedNode,
            propKey: 'align',
            value: style['align'] ?? 'left',
            options: ['left', 'center', 'right'],
            theme: theme,
            isStyle: true,
          ),
          const SizedBox(height: 12),
          _buildNodeColorPickerTile(
            label: 'Text Color',
            node: selectedNode,
            propKey: 'color',
            hex: style['color'],
            theme: theme,
            isStyle: true,
          ),
        ] else if (type == 'button') ...[
          _buildNodeTextEditor('Button Label', selectedNode, 'value', theme),
          const SizedBox(height: 12),
          _buildNodeColorPickerTile(
            label: 'Background Color',
            node: selectedNode,
            propKey: 'background_color',
            hex: style['background_color'],
            theme: theme,
            isStyle: true,
          ),
          const SizedBox(height: 12),
          _buildNodeSpinInput(
            label: 'Corner Radius',
            node: selectedNode,
            propKey: 'border_radius',
            value: _parseDouble(style['border_radius'], 8.0),
            min: 0.0,
            max: 24.0,
            isStyle: true,
          ),
        ] else if (type == 'product_card') ...[
          _buildNodeTextEditor('Product Name', selectedNode, 'product_name', theme),
          const SizedBox(height: 12),
          _buildNodeTextEditor('Price Tag', selectedNode, 'price', theme),
        ] else if (type == 'icon') ...[
          _buildNodeDropdown(
            label: 'Select Icon',
            node: selectedNode,
            propKey: 'icon_name',
            value: selectedNode['icon_name'] ?? 'store',
            options: ['store', 'shoppingBag', 'package'],
            theme: theme,
          ),
          const SizedBox(height: 12),
          _buildNodeColorPickerTile(
            label: 'Icon Color',
            node: selectedNode,
            propKey: 'color',
            hex: props['color'],
            theme: theme,
          ),
        ] else if (type == 'grid') ...[
          _buildNodeSpinInput(
            label: 'Columns Count',
            node: selectedNode,
            propKey: 'columns',
            value: _parseDouble(props['columns'], 3.0),
            min: 1.0,
            max: 6.0,
          ),
          const SizedBox(height: 12),
          _buildNodeSpinInput(
            label: 'Grid Spacing',
            node: selectedNode,
            propKey: 'spacing',
            value: _parseDouble(props['spacing'], 16.0),
            min: 0.0,
            max: 48.0,
          ),
        ] else if (['flexRow', 'flexCol'].contains(type)) ...[
          _buildNodeDropdown(
            label: 'Layout Mode',
            node: selectedNode,
            propKey: 'layout_mode',
            value: props['layout_mode'] ?? 'flex',
            options: ['flex', 'absolute'],
            theme: theme,
          ),
          const SizedBox(height: 12),
          if (props['layout_mode'] != 'absolute') ...[
            _buildFigmaAlignmentSelector(selectedNode, theme),
            const SizedBox(height: 12),
          ],
          // Individual Margins/Paddings
          const Text('Padding', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CompactSpinInput(
                  label: 'L',
                  value: _parseDouble(props['padding_left'], 0.0),
                  min: 0.0,
                  max: 128.0,
                  onChanged: (val) {
                    final themeConfig = ref.read(activeThemeConfigProvider).value;
                    if (themeConfig == null) return;
                    final layout = _getLayoutTree(themeConfig);
                    final copiedTree = _deepCopyMap(layout);
                    _updateNodeProperty(copiedTree, nodeId, 'padding_left', val);
                    ref.read(activeThemeConfigProvider.notifier).updateSlots({_selectedPageSlotKey: copiedTree}, editKey: nodeId);
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: CompactSpinInput(
                  label: 'R',
                  value: _parseDouble(props['padding_right'], 0.0),
                  min: 0.0,
                  max: 128.0,
                  onChanged: (val) {
                    final themeConfig = ref.read(activeThemeConfigProvider).value;
                    if (themeConfig == null) return;
                    final layout = _getLayoutTree(themeConfig);
                    final copiedTree = _deepCopyMap(layout);
                    _updateNodeProperty(copiedTree, nodeId, 'padding_right', val);
                    ref.read(activeThemeConfigProvider.notifier).updateSlots({_selectedPageSlotKey: copiedTree}, editKey: nodeId);
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: CompactSpinInput(
                  label: 'T',
                  value: _parseDouble(props['padding_top'], 0.0),
                  min: 0.0,
                  max: 128.0,
                  onChanged: (val) {
                    final themeConfig = ref.read(activeThemeConfigProvider).value;
                    if (themeConfig == null) return;
                    final layout = _getLayoutTree(themeConfig);
                    final copiedTree = _deepCopyMap(layout);
                    _updateNodeProperty(copiedTree, nodeId, 'padding_top', val);
                    ref.read(activeThemeConfigProvider.notifier).updateSlots({_selectedPageSlotKey: copiedTree}, editKey: nodeId);
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: CompactSpinInput(
                  label: 'B',
                  value: _parseDouble(props['padding_bottom'], 0.0),
                  min: 0.0,
                  max: 128.0,
                  onChanged: (val) {
                    final themeConfig = ref.read(activeThemeConfigProvider).value;
                    if (themeConfig == null) return;
                    final layout = _getLayoutTree(themeConfig);
                    final copiedTree = _deepCopyMap(layout);
                    _updateNodeProperty(copiedTree, nodeId, 'padding_bottom', val);
                    ref.read(activeThemeConfigProvider.notifier).updateSlots({_selectedPageSlotKey: copiedTree}, editKey: nodeId);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNodeSpinInput(
            label: 'Child Spacing',
            node: selectedNode,
            propKey: 'spacing',
            value: _parseDouble(props['spacing'], 0.0),
            min: 0.0,
            max: 48.0,
          ),
          const SizedBox(height: 12),
          _buildNodeDropdown(
            label: 'Border Outline Style',
            node: selectedNode,
            propKey: 'border_style',
            value: props['border_style'] ?? 'none',
            options: ['none', 'solid'],
            theme: theme,
          ),
          const SizedBox(height: 12),
          _buildNodeColorPickerTile(
            label: 'Border Color',
            node: selectedNode,
            propKey: 'border_color',
            hex: props['border_color'],
            theme: theme,
          ),
          const SizedBox(height: 12),
          _buildNodeSpinInput(
            label: 'Outline Stroke Width',
            node: selectedNode,
            propKey: 'stroke_width',
            value: _parseDouble(props['stroke_width'], 1.0),
            min: 0.5,
            max: 5.0,
            step: 0.5,
          ),
          const SizedBox(height: 12),
          _buildNodeSpinInput(
            label: 'Shadow Elevation Depth',
            node: selectedNode,
            propKey: 'elevation',
            value: _parseDouble(props['elevation'], 0.0),
            min: 0.0,
            max: 8.0,
          ),
          const SizedBox(height: 12),
          _buildNodeColorPickerTile(
            label: 'Background Color',
            node: selectedNode,
            propKey: 'background_color',
            hex: props['background_color'],
            theme: theme,
          ),
          const SizedBox(height: 12),
          _buildNodeDropdown(
            label: 'Dynamic Fragment Shader',
            node: selectedNode,
            propKey: 'shader_source',
            value: props['shader_source'] ?? 'none',
            options: ['none', 'wave', 'aurora', 'cosmic'],
            theme: theme,
          ),
        ] else if (type == 'spacer') ...[
          _buildNodeSpinInput(
            label: 'Spacer Height',
            node: selectedNode,
            propKey: 'height',
            value: _parseDouble(props['height'], 24.0),
            min: 4.0,
            max: 200.0,
          ),
        ] else ...[
          const SizedBox(height: 12),
          Text(
            'This component (${type.toUpperCase()}) does not expose custom visual properties.',
            style: TextStyle(color: theme.hintColor, fontStyle: FontStyle.italic),
          ),
        ]
      ],
    );
  }

  Widget _buildAbsolutePositionFields(Map<String, dynamic> node, ThemeData theme) {
    final nodeId = node['id'] ?? '';
    final props = node['properties'] ?? {};

    final left = _parseDouble(props['left'], 0.0);
    final top = _parseDouble(props['top'], 0.0);
    final width = _parseDouble(props['width'], 150.0);
    final height = _parseDouble(props['height'], 50.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Geometry Position',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildGeometryField('X (Left px)', nodeId, 'left', left, theme)),
            const SizedBox(width: 8),
            Expanded(child: _buildGeometryField('Y (Top px)', nodeId, 'top', top, theme)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildGeometryField('W (Width px)', nodeId, 'width', width, theme)),
            const SizedBox(width: 8),
            Expanded(child: _buildGeometryField('H (Height px)', nodeId, 'height', height, theme)),
          ],
        ),
      ],
    );
  }

  Widget _buildGeometryField(String label, String nodeId, String key, double value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: theme.hintColor)),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value.toStringAsFixed(0))
            ..selection = TextSelection.collapsed(offset: value.toStringAsFixed(0).length),
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          ),
          onSubmitted: (val) {
            final doubleVal = double.tryParse(val) ?? value;
            final themeConfig = ref.read(activeThemeConfigProvider).value;
            if (themeConfig == null) return;
            final layout = _getLayoutTree(themeConfig);
            final copiedTree = _deepCopyMap(layout);
            _updateNodeProperty(copiedTree, nodeId, key, doubleVal);
            ref.read(activeThemeConfigProvider.notifier).updateSlots({_selectedPageSlotKey: copiedTree}, editKey: nodeId);
          },
        ),
      ],
    );
  }

  Widget _buildFigmaAlignmentSelector(Map<String, dynamic> node, ThemeData theme) {
    final nodeId = node['id'] ?? '';
    final props = node['properties'] ?? {};
    final currentAlign = props['alignment'] ?? 'center';

    final alignments = [
      ['topLeft', 'topCenter', 'topRight'],
      ['centerLeft', 'center', 'centerRight'],
      ['bottomLeft', 'bottomCenter', 'bottomRight'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Auto Layout Alignment',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: 96,
          height: 96,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: alignments.map((row) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: row.map((align) {
                  final isSelected = currentAlign == align;
                  return GestureDetector(
                    onTap: () {
                      final themeConfig = ref.read(activeThemeConfigProvider).value;
                      if (themeConfig == null) return;
                      final layout = _getLayoutTree(themeConfig);
                      final copiedTree = _deepCopyMap(layout);
                      _updateNodeProperty(copiedTree, nodeId, 'alignment', align);
                      ref.read(activeThemeConfigProvider.notifier).updateSlots({_selectedPageSlotKey: copiedTree}, editKey: nodeId);
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.brandEmerald500 : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : theme.dividerColor.withOpacity(0.5),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : theme.hintColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSwatchesRow(
    String propKey,
    String? currentHex,
    String nodeId, {
    bool isStyle = false,
    bool isToken = false,
    String? tokenKey,
  }) {
    return Container(
      height: 24,
      margin: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colorPresets.length,
              itemBuilder: (context, idx) {
                final preset = _colorPresets[idx];
                final presetColor = _parseColor(preset, Colors.blue);
                final isSelected = currentHex == preset;
                
                return GestureDetector(
                  onTap: () {
                    final themeConfig = ref.read(activeThemeConfigProvider).value;
                    if (themeConfig == null) return;
                    if (isToken && tokenKey != null) {
                      ref.read(activeThemeConfigProvider.notifier).updateLocalToken(tokenKey, preset);
                    } else {
                      final layout = _getLayoutTree(themeConfig);
                      final copiedTree = _deepCopyMap(layout);
                      _updateNodeProperty(copiedTree, nodeId, propKey, preset, isStyle: isStyle);
                      ref.read(activeThemeConfigProvider.notifier).updateSlots({_selectedPageSlotKey: copiedTree}, editKey: nodeId);
                    }
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: presetColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.brandEmerald500 : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2.0 : 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (currentHex != null && !_colorPresets.contains(currentHex))
            IconButton(
              icon: const Icon(LucideIcons.plusCircle, size: 14, color: AppTheme.brandEmerald500),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  _colorPresets.add(currentHex);
                });
              },
              tooltip: 'Save Swatch',
            ),
        ],
      ),
    );
  }

  Widget _buildNodeTextEditor(
    String label,
    Map<String, dynamic> node,
    String propKey,
    ThemeData theme,
  ) {
    final nodeId = node['id'] ?? '';
    final currentValue = node[propKey] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.hintColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: currentValue)
            ..selection = TextSelection.collapsed(offset: currentValue.length),
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppTheme.brandEmerald500),
            ),
          ),
          onChanged: (val) {
            final themeConfig = ref.read(activeThemeConfigProvider).value;
            if (themeConfig == null) return;
            final layout = _getLayoutTree(themeConfig);
            final copiedTree = _deepCopyMap(layout);
            _updateNodeProperty(copiedTree, nodeId, propKey, val);
            ref.read(activeThemeConfigProvider.notifier).updateSlots({_selectedPageSlotKey: copiedTree}, editKey: nodeId);
          },
        ),
      ],
    );
  }



  Widget _buildNodeDropdown({
    required String label,
    required Map<String, dynamic> node,
    required String propKey,
    required String value,
    required List<String> options,
    required ThemeData theme,
    bool isStyle = false,
  }) {
    final nodeId = node['id'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.hintColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: options.contains(value) ? value : options.first,
          items: options
              .map(
                (opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(opt, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              final themeConfig = ref.read(activeThemeConfigProvider).value;
              if (themeConfig == null) return;
              final layout = _getLayoutTree(themeConfig);
              final copiedTree = _deepCopyMap(layout);
              _updateNodeProperty(copiedTree, nodeId, propKey, val, isStyle: isStyle);
              ref.read(activeThemeConfigProvider.notifier).updateSlots({_selectedPageSlotKey: copiedTree}, editKey: nodeId);
            }
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNodeColorPickerTile({
    required String label,
    required Map<String, dynamic> node,
    required String propKey,
    required String? hex,
    required ThemeData theme,
    bool isStyle = false,
  }) {
    final nodeId = node['id'] ?? '';
    final color = _parseColor(hex, Colors.transparent);

    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              hex ?? 'Transparent',
              style: TextStyle(color: theme.hintColor, fontSize: 11),
            ),
            trailing: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color == Colors.transparent ? Colors.transparent : color,
                shape: BoxShape.circle,
                border: Border.all(color: theme.dividerColor),
              ),
            ),
            onTap: () => _showNodeColorPicker(label, nodeId, propKey, color, isStyle: isStyle),
          ),
          _buildColorSwatchesRow(propKey, hex, nodeId, isStyle: isStyle),
        ],
      ),
    );
  }

  void _showNodeColorPicker(String title, String nodeId, String propKey, Color initialColor, {bool isStyle = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick $title'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: initialColor == Colors.transparent ? Colors.blue : initialColor,
            onColorChanged: (color) {
              final hex = '#${color.value.toRadixString(16).substring(2)}';
              final themeConfig = ref.read(activeThemeConfigProvider).value;
              if (themeConfig == null) return;
              final layout = _getLayoutTree(themeConfig);
              final copiedTree = _deepCopyMap(layout);
              _updateNodeProperty(copiedTree, nodeId, propKey, hex, isStyle: isStyle);
              ref.read(activeThemeConfigProvider.notifier).updateSlots({_selectedPageSlotKey: copiedTree}, editKey: nodeId);
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

  Widget _buildConfigGroup({
    required String title,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            initiallyExpanded: title.startsWith('Canvas') || title.startsWith('Page'),
            leading: Icon(icon, size: 18, color: AppTheme.brandEmerald500),
            title: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            childrenPadding: const EdgeInsets.all(16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
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

    return Material(
      color: Colors.transparent,
      child: ListTile(
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
          ),
        ),
        onTap: () => _showColorPicker(label, key, color),
      ),
    );
  }

  Widget _buildSlotTextEditor(
    String label,
    String key,
    String? value,
    ThemeData theme, {
    bool isToken = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.hintColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value?.length ?? 0),
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppTheme.brandEmerald500),
            ),
          ),
          onChanged: (val) {
            if (isToken) {
              ref.read(activeThemeConfigProvider.notifier).updateLocalToken(key, val);
            } else {
              ref.read(activeThemeConfigProvider.notifier).updateLocalSlot(key, val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSlotDropdown(
    String label,
    String key,
    String? value,
    List<String> options,
    ThemeData theme, {
    bool isToken = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.hintColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: options.contains(value) ? value : options.first,
          items: options
              .map(
                (opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(opt, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) {
              if (isToken) {
                ref.read(activeThemeConfigProvider.notifier).updateLocalToken(key, val);
              } else {
                ref.read(activeThemeConfigProvider.notifier).updateLocalSlot(key, val);
              }
            }
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCanvas(
    AsyncValue<dynamic> configAsync,
    ThemeData theme,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;

        // Horizontal margin: 4px on each side -> subtract 8px
        // Vertical margin: 16px on each side -> subtract 32px
        final double safariWidth = (availableWidth - 8).clamp(300.0, double.infinity);
        final double safariHeight = (availableHeight - 32).clamp(300.0, double.infinity);

        // Cache viewport sizes (excluding macOS window bar height of 53px)
        _lastViewportWidth = safariWidth;
        _lastViewportHeight = safariHeight - 53;

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
                selectedNodeId: _selectedNodeId,
                page: _selectedPage,
                isDragging: _isDraggingComponent,
                onNodeSelected: _selectAndExpandNode,
                onNodeDropped: _handleNodeDropped,
                onNodeMoved: (id, left, top) {
                  final tree = _getLayoutTree(config);
                  final copied = _deepCopyMap(tree);
                  _updateNodeProperty(copied, id, 'left', left);
                  _updateNodeProperty(copied, id, 'top', top);
                  ref.read(activeThemeConfigProvider.notifier).updateSlots({_selectedPageSlotKey: copied}, editKey: id);
                },
              );

              // Scrollable container wrapping the FittedBox which scales the preview
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

              if (_isMobile) {
                return Center(
                  child: _buildMobilePhoneWrapper(
                    child: scaledContent,
                    isDark: isDark,
                    theme: theme,
                  ),
                );
              } else {
                return Center(
                  child: _buildBrowserWrapper(
                    child: scaledContent,
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
                // Static macOS dots in preview frame
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
          SnackBar(content: Text('Failed to publish: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleClone(ThemeConfigModel config) async {
    String cloneName = 'Clone of ${config.name}';
    final nameController = TextEditingController(text: cloneName);

    final resultName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clone Theme Layout'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Layout Name',
            hintText: 'e.g. Header Variant A',
          ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandEmerald500,
            ),
            child: const Text('Clone', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (resultName == null || resultName.isEmpty) return;

    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final cloned = await ref.read(apiServiceProvider).cloneTheme(resultName);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close spinner
        
        final String origin = (Uri.base.scheme == 'http' || Uri.base.scheme == 'https')
            ? Uri.base.origin
            : 'http://localhost:3000';
        final shareLink = '$origin/#/preview?configId=${cloned.configId}';

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Layout Cloned Successfully!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your new layout "${cloned.name}" has been created for A/B testing.'),
                const SizedBox(height: 16),
                const Text('Share link for colleagues:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          shareLink,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.copy, size: 16),
                        tooltip: 'Copy Link',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: shareLink));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(shareLink);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandEmerald500,
                ),
                icon: const Icon(LucideIcons.externalLink, size: 14, color: Colors.white),
                label: const Text('Open Preview', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close spinner if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clone: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showRenameDialog(ThemeConfigModel config, ActiveThemeConfigNotifier notifier) async {
    final nameController = TextEditingController(text: config.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Theme Layout'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Layout Name',
          ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandEmerald500,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != config.name) {
      notifier.updateName(newName);
    }
  }

  // Layout Helper Functions
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
              "id": "hero_button",
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
        },
        {
          "id": "spec_tabs_section",
          "type": "flexCol",
          "properties": {"padding": 24.0, "background_color": "tokens.background", "border_style": "solid", "stroke_width": 1.0, "border_color": "#E2E8F0"},
          "children": [
            {"id": "pdp_tabs_widget", "type": "pdp_tabs"}
          ]
        },
        {
          "id": "footer_section",
          "type": "flexCol",
          "properties": {"padding": 36.0, "background_color": "#0F172A", "alignment": "center"},
          "children": [
            {
              "id": "footer_text",
              "type": "text",
              "value": "© 2026 KloudShop. Challenging the giants with native speed.",
              "style": {"font_size": 11.0, "color": "#94A3B8", "font_family": "Inter", "align": "center"}
            }
          ]
        }
      ]
    };
  }

  Map<String, dynamic> _deepCopyMap(Map<String, dynamic> source) {
    final copy = <String, dynamic>{};
    source.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        copy[key] = _deepCopyMap(value);
      } else if (value is List) {
        copy[key] = _deepCopyList(value);
      } else {
        copy[key] = value;
      }
    });
    return copy;
  }

  List<dynamic> _deepCopyList(List<dynamic> source) {
    final copy = [];
    for (final item in source) {
      if (item is Map<String, dynamic>) {
        copy.add(_deepCopyMap(item));
      } else if (item is List) {
        copy.add(_deepCopyList(item));
      } else {
        copy.add(item);
      }
    }
    return copy;
  }

  Map<String, dynamic>? _findNodeInTree(Map<String, dynamic> node, String targetId) {
    if (node['id'] == targetId) return node;
    if (node['children'] is List) {
      for (final child in node['children']) {
        if (child is Map<String, dynamic>) {
          final result = _findNodeInTree(child, targetId);
          if (result != null) return result;
        }
      }
    }
    return null;
  }

  bool _removeNodeFromTree(Map<String, dynamic> node, String targetId) {
    if (node['children'] is List) {
      final list = node['children'] as List;
      final index = list.indexWhere((child) => child is Map<String, dynamic> && child['id'] == targetId);
      if (index != -1) {
        list.removeAt(index);
        return true;
      }
      for (final child in list) {
        if (child is Map<String, dynamic>) {
          if (_removeNodeFromTree(child, targetId)) return true;
        }
      }
    }
    return false;
  }

  bool _insertNodeIntoTree(Map<String, dynamic> node, String parentId, int index, Map<String, dynamic> childNode) {
    if (node['id'] == parentId) {
      if (node['children'] == null) {
        node['children'] = <dynamic>[];
      }
      final list = node['children'] as List;
      if (index < 0) {
        list.insert(0, childNode);
      } else if (index >= list.length) {
        list.add(childNode);
      } else {
        list.insert(index, childNode);
      }
      return true;
    }
    if (node['children'] is List) {
      for (final child in node['children']) {
        if (child is Map<String, dynamic>) {
          if (_insertNodeIntoTree(child, parentId, index, childNode)) return true;
        }
      }
    }
    return false;
  }

  bool _updateNodeProperty(Map<String, dynamic> node, String targetId, String propKey, dynamic value, {bool isStyle = false}) {
    if (node['id'] == targetId) {
      if (isStyle) {
        if (node['style'] == null) node['style'] = <String, dynamic>{};
        node['style'][propKey] = value;
      } else {
        if (propKey == 'value') {
          node['value'] = value;
        } else if (propKey == 'customName') {
          node['customName'] = value;
        } else if (propKey == 'product_name') {
          node['product_name'] = value;
        } else if (propKey == 'price') {
          node['price'] = value;
        } else if (propKey == 'icon_name') {
          node['icon_name'] = value;
        } else {
          if (node['properties'] == null) node['properties'] = <String, dynamic>{};
          node['properties'][propKey] = value;
        }
      }
      return true;
    }
    if (node['children'] is List) {
      for (final child in node['children']) {
        if (child is Map<String, dynamic>) {
          if (_updateNodeProperty(child, targetId, propKey, value, isStyle: isStyle)) return true;
        }
      }
    }
    return false;
  }

  bool _updateNodeMetaProperty(Map<String, dynamic> node, String targetId, String key, dynamic value) {
    if (node['id'] == targetId) {
      node[key] = value;
      return true;
    }
    if (node['children'] is List) {
      for (final child in node['children']) {
        if (child is Map<String, dynamic>) {
          if (_updateNodeMetaProperty(child, targetId, key, value)) return true;
        }
      }
    }
    return false;
  }

  void _nudgeSelectedNode(double dx, double dy) {
    if (_selectedNodeId == null) return;
    final themeConfig = ref.read(activeThemeConfigProvider).value;
    if (themeConfig == null) return;

    final layout = _getLayoutTree(themeConfig);
    final selectedNode = _findNodeInTree(layout, _selectedNodeId!);
    if (selectedNode == null) return;

    final props = selectedNode['properties'] ?? {};
    final isAbsolute = props['position'] == 'absolute';
    if (!isAbsolute) return;

    final currentLeft = _parseDouble(props['left'], 0.0);
    final currentTop = _parseDouble(props['top'], 0.0);

    final copiedTree = _deepCopyMap(layout);
    _updateNodeProperty(copiedTree, _selectedNodeId!, 'left', currentLeft + dx);
    _updateNodeProperty(copiedTree, _selectedNodeId!, 'top', currentTop + dy);

    ref.read(activeThemeConfigProvider.notifier).updateSlots({_selectedPageSlotKey: copiedTree}, editKey: _selectedNodeId);
  }

  void _handleNodeDropped(String parentId, int index, Map<String, dynamic> child) {
    final themeConfig = ref.read(activeThemeConfigProvider).value;
    if (themeConfig == null) return;

    final layout = _getLayoutTree(themeConfig);
    final copiedTree = _deepCopyMap(layout);

    final childId = child['id'];
    Map<String, dynamic> nodeToInsert;
    if (childId != null && childId.isNotEmpty) {
      _removeNodeFromTree(copiedTree, childId);
      nodeToInsert = child;
    } else {
      final newId = '${child['type']}_${DateTime.now().microsecondsSinceEpoch}';
      nodeToInsert = _deepCopyMap(child);
      nodeToInsert['id'] = newId;
    }

    if (index == -1) {
      _insertNodeIntoTree(copiedTree, parentId, 9999, nodeToInsert);
    } else {
      _insertNodeIntoTree(copiedTree, parentId, index, nodeToInsert);
    }
    ref.read(activeThemeConfigProvider.notifier).updateSlots({_selectedPageSlotKey: copiedTree}, editKey: 'layout_drop');
  }

  void _handleDeleteNode(String id) {
    if (id == 'root') return;

    final themeConfig = ref.read(activeThemeConfigProvider).value;
    if (themeConfig == null) return;

    final layout = _getLayoutTree(themeConfig);
    final copiedTree = _deepCopyMap(layout);

    if (_removeNodeFromTree(copiedTree, id)) {
      if (_selectedNodeId == id) {
        _selectedNodeId = null;
      }
      ref.read(activeThemeConfigProvider.notifier).updateSlots({_selectedPageSlotKey: copiedTree}, editKey: 'layout_delete');
    }
  }

  void _handleCreateFromScratch() {
    final blankLayout = {
      "id": "root",
      "type": "flexCol",
      "properties": {"padding": 24.0},
      "children": []
    };

    setState(() {
      _selectedNodeId = null;
    });

    ref.read(activeThemeConfigProvider.notifier).updateSlots(
      {_selectedPageSlotKey: blankLayout},
      editKey: 'layout_scratch',
    );
  }

  String _getFriendlyNodeName(Map<String, dynamic> node) {
    final customName = node['customName'];
    if (customName is String && customName.isNotEmpty) return customName;

    final type = node['type'] ?? 'Component';
    final id = node['id'] ?? '';
    if (id == 'root') return 'Root Canvas (Column)';

    switch (type) {
      case 'flexRow': return 'Row Layout';
      case 'flexCol': return 'Column Layout';
      case 'grid': return 'Grid Layout';
      case 'stack': return 'Overlay Stack';
      case 'text':
        final val = node['value'] ?? 'Text';
        return 'Text: "$val"';
      case 'button':
        final val = node['value'] ?? 'Button';
        return 'Button: "$val"';
      case 'product_card':
        final name = node['product_name'] ?? 'Product';
        return 'Product: $name';
      case 'pdp_tabs': return 'PDP Tabs';
      case 'divider': return 'Divider Line';
      case 'icon':
        final name = node['icon_name'] ?? 'package';
        return 'Icon: $name';
      case 'testimonials': return 'Testimonials';
      case 'trust_badges': return 'Trust Badges';
      case 'collection_list': return 'Collection List';
      case 'newsletter_signup': return 'Newsletter Sign-Up';
      case 'store_locator': return 'Store Locator Map';
      case 'spacer': return 'Spacer';
      default: return 'Component';
    }
  }

  IconData _getNodeIcon(String type) {
    switch (type) {
      case 'flexRow': return LucideIcons.alignJustify;
      case 'flexCol': return LucideIcons.alignLeft;
      case 'grid': return LucideIcons.grid;
      case 'stack': return LucideIcons.layers;
      case 'text': return LucideIcons.type;
      case 'button': return LucideIcons.playCircle;
      case 'product_card': return LucideIcons.package;
      case 'pdp_tabs': return LucideIcons.layers;
      case 'divider': return LucideIcons.minus;
      case 'icon': return LucideIcons.smile;
      case 'testimonials': return LucideIcons.messageSquare;
      case 'trust_badges': return LucideIcons.shieldCheck;
      case 'collection_list': return LucideIcons.list;
      case 'newsletter_signup': return LucideIcons.mail;
      case 'store_locator': return LucideIcons.mapPin;
      case 'spacer': return LucideIcons.move;
      default: return LucideIcons.helpCircle;
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

  double _parseDouble(dynamic val, double fallback) {
    if (val == null) return fallback;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? fallback;
    return fallback;
  }

  Widget _buildTokenSpinInput({
    required String label,
    required String key,
    required double value,
    required double min,
    required double max,
    double step = 1.0,
  }) {
    return CompactSpinInput(
      label: label,
      value: value,
      min: min,
      max: max,
      step: step,
      onChanged: (val) {
        ref.read(activeThemeConfigProvider.notifier).updateLocalToken(key, val.toString());
      },
    );
  }

  Widget _buildNodeSpinInput({
    required String label,
    required Map<String, dynamic> node,
    required String propKey,
    required double value,
    required double min,
    required double max,
    double step = 1.0,
    bool isStyle = false,
  }) {
    final nodeId = node['id'] ?? '';
    return CompactSpinInput(
      label: label,
      value: value,
      min: min,
      max: max,
      step: step,
      onChanged: (val) {
        final themeConfig = ref.read(activeThemeConfigProvider).value;
        if (themeConfig == null) return;
        final layout = _getLayoutTree(themeConfig);
        final copiedTree = _deepCopyMap(layout);
        _updateNodeProperty(copiedTree, nodeId, propKey, val, isStyle: isStyle);
        ref.read(activeThemeConfigProvider.notifier).updateSlots({_selectedPageSlotKey: copiedTree}, editKey: nodeId);
      },
    );
  }

  void _selectAndExpandNode(String nodeId) {
    final themeConfig = ref.read(activeThemeConfigProvider).value;
    if (themeConfig == null) return;
    final layout = _getLayoutTree(themeConfig);
    
    final List<String> path = [];
    if (_findPathToNode(layout, nodeId, path)) {
      setState(() {
        _selectedNodeId = nodeId;
        for (final parentId in path) {
          _expandedGroupIds.add(parentId);
        }
      });
    } else {
      setState(() {
        _selectedNodeId = nodeId;
      });
    }
  }

  bool _findPathToNode(Map<String, dynamic> root, String targetId, List<String> path) {
    final id = root['id'] ?? '';
    if (id == targetId) {
      return true;
    }
    
    final children = root['children'] as List<dynamic>? ?? [];
    for (final child in children) {
      if (child is Map<String, dynamic>) {
        path.add(id);
        if (_findPathToNode(child, targetId, path)) {
          return true;
        }
        path.removeLast();
      }
    }
    return false;
  }
}

class WysiwygFullscreenPreview extends StatelessWidget {
  final Map<String, dynamic> tokens;
  final Map<String, dynamic> slots;
  final String page;
  final String previewState;

  const WysiwygFullscreenPreview({
    super.key,
    required this.tokens,
    required this.slots,
    required this.page,
    required this.previewState,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              child: StorefrontPreview(
                tokens: tokens,
                slots: slots,
                isMobile: false,
                previewState: previewState,
              ),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: FloatingActionButton.extended(
              backgroundColor: AppTheme.brandEmerald500,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(LucideIcons.x, color: Colors.white, size: 16),
              label: const Text(
                'Close Preview',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccordionHeaderTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isDark;

  const _AccordionHeaderTile({
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.onTap,
    required this.theme,
    required this.isDark,
  });

  @override
  State<_AccordionHeaderTile> createState() => _AccordionHeaderTileState();
}

class _AccordionHeaderTileState extends State<_AccordionHeaderTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeBgColor = widget.theme.primaryColor.withOpacity(widget.isDark ? 0.15 : 0.08);
    final hoverBgColor = widget.theme.primaryColor.withOpacity(widget.isDark ? 0.08 : 0.03);
    final activeTextColor = widget.theme.primaryColor;
    final inactiveTextColor = widget.isDark ? Colors.grey[300]! : Colors.grey[800]!;

    final currentBgColor = widget.isExpanded
        ? activeBgColor
        : (_isHovered ? hoverBgColor : Colors.transparent);
    final currentTextColor = widget.isExpanded
        ? activeTextColor
        : inactiveTextColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: currentBgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isExpanded
                  ? widget.theme.primaryColor.withOpacity(0.3)
                  : widget.theme.dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: widget.isExpanded ? widget.theme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Icon(widget.icon, size: 16, color: currentTextColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: currentTextColor,
                    fontWeight: widget.isExpanded ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(
                widget.isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                size: 14,
                color: currentTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryGroupHeaderTile extends StatefulWidget {
  final String title;
  final bool isExpanded;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isDark;

  const _LibraryGroupHeaderTile({
    required this.title,
    required this.isExpanded,
    required this.onTap,
    required this.theme,
    required this.isDark,
  });

  @override
  State<_LibraryGroupHeaderTile> createState() => _LibraryGroupHeaderTileState();
}

class _LibraryGroupHeaderTileState extends State<_LibraryGroupHeaderTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeBgColor = widget.theme.primaryColor.withOpacity(widget.isDark ? 0.1 : 0.05);
    final hoverBgColor = widget.theme.primaryColor.withOpacity(widget.isDark ? 0.05 : 0.02);
    final activeTextColor = widget.theme.primaryColor;
    final inactiveTextColor = widget.isDark ? Colors.grey[400]! : Colors.grey[700]!;

    final currentBgColor = widget.isExpanded
        ? activeBgColor
        : (_isHovered ? hoverBgColor : Colors.transparent);
    final currentTextColor = widget.isExpanded
        ? activeTextColor
        : inactiveTextColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: currentBgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isExpanded
                  ? widget.theme.primaryColor.withOpacity(0.2)
                  : widget.theme.dividerColor.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: currentTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(
                widget.isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                size: 12,
                color: currentTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompactSpinInput extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final double step;

  const CompactSpinInput({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1.0,
  });

  @override
  State<CompactSpinInput> createState() => _CompactSpinInputState();
}

class _CompactSpinInputState extends State<CompactSpinInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(covariant CompactSpinInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = widget.value.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSubmitted(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9.-]'), '');
    final parsed = double.tryParse(clean);
    if (parsed != null) {
      final clamped = parsed.clamp(widget.min, widget.max);
      widget.onChanged(clamped);
      _controller.text = clamped.toStringAsFixed(0);
    } else {
      _controller.text = widget.value.toStringAsFixed(0);
    }
  }

  void _increment() {
    final newValue = (widget.value + widget.step).clamp(widget.min, widget.max);
    widget.onChanged(newValue);
    _controller.text = newValue.toStringAsFixed(0);
  }

  void _decrement() {
    final newValue = (widget.value - widget.step).clamp(widget.min, widget.max);
    widget.onChanged(newValue);
    _controller.text = newValue.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 9, 
            fontWeight: FontWeight.bold, 
            color: theme.hintColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Container(
          height: 28,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
                  ],
                  style: const TextStyle(fontSize: 11),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    border: InputBorder.none,
                  ),
                  onSubmitted: _onSubmitted,
                  onTapOutside: (_) => _onSubmitted(_controller.text),
                ),
              ),
              Container(
                width: 16,
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: theme.dividerColor)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _increment,
                        child: Center(
                          child: Icon(Icons.keyboard_arrow_up, size: 10, color: theme.hintColor),
                        ),
                      ),
                    ),
                    Divider(height: 1, color: theme.dividerColor),
                    Expanded(
                      child: InkWell(
                        onTap: _decrement,
                        child: Center(
                          child: Icon(Icons.keyboard_arrow_down, size: 10, color: theme.hintColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
