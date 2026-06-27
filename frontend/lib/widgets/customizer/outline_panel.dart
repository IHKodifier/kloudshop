import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/providers/theme_providers.dart';

class OutlinePanel extends ConsumerStatefulWidget {
  final ThemeConfigModel? config;
  final String selectedPage;
  final Map<String, dynamic> layout;

  const OutlinePanel({
    super.key,
    required this.config,
    required this.selectedPage,
    required this.layout,
  });

  @override
  ConsumerState<OutlinePanel> createState() => _OutlinePanelState();
}

class _OutlinePanelState extends ConsumerState<OutlinePanel> {
  bool _headerExpanded = true;
  bool _templateExpanded = true;
  bool _footerExpanded = true;

  final Set<String> _expandedSections = {};
  bool _initializedExpansion = false;

  String get _slotKey => widget.selectedPage == 'home' ? 'layout' : 'layout_${widget.selectedPage}';

  Map<String, dynamic> _getLayoutTree() {
    return widget.layout;
  }

  Map<String, dynamic> _getDefaultLayout() {
    if (widget.selectedPage == 'pdp') {
      return {
        "id": "root",
        "type": "flexCol",
        "children": [
          {"id": "pdp_header_section", "type": "flexRow", "customName": "Product Detail Header", "children": []},
          {"id": "pdp_main_section", "type": "flexCol", "customName": "Product Details Layout", "children": []}
        ]
      };
    } else if (widget.selectedPage == 'checkout') {
      return {
        "id": "root",
        "type": "flexCol",
        "children": [
          {"id": "checkout_header", "type": "flexRow", "customName": "Checkout Header", "children": []},
          {"id": "checkout_content", "type": "flexCol", "customName": "Payment Details", "children": []}
        ]
      };
    } else if (widget.selectedPage == 'cart') {
      return {
        "id": "root",
        "type": "flexCol",
        "children": [
          {"id": "cart_header", "type": "flexRow", "customName": "Cart Header", "children": []},
          {"id": "cart_items_section", "type": "flexCol", "customName": "Cart Item list", "children": []},
          {"id": "cart_footer", "type": "flexCol", "customName": "Total and Checkout Button", "children": []}
        ]
      };
    }
    return {
      "id": "root",
      "type": "flexCol",
      "children": [
        {"id": "announcement_bar", "type": "announcement_bar", "customName": "Announcement Bar", "children": []},
        {"id": "header_section", "type": "header", "customName": "Header", "children": []},
        {"id": "hero_section", "type": "image_banner", "customName": "Image Banner", "children": []},
        {"id": "featured_section", "type": "collection", "customName": "Featured Collection", "children": []},
        {"id": "footer_section", "type": "footer", "customName": "Footer", "children": []}
      ]
    };
  }

  bool _isHeaderNode(Map<String, dynamic> node) {
    final type = (node['type'] ?? '').toString().toLowerCase();
    final id = (node['id'] ?? '').toString().toLowerCase();
    final customName = (node['customName'] ?? node['label'] ?? '').toString().toLowerCase();
    return type == 'announcement_bar' ||
        type == 'header' ||
        id.contains('header') ||
        customName.contains('header') ||
        id.contains('announcement') ||
        customName.contains('announcement');
  }

  bool _isFooterNode(Map<String, dynamic> node) {
    final type = (node['type'] ?? '').toString().toLowerCase();
    final id = (node['id'] ?? '').toString().toLowerCase();
    final customName = (node['customName'] ?? node['label'] ?? '').toString().toLowerCase();
    return type == 'footer' ||
        id.contains('footer') ||
        customName.contains('footer') ||
        id.contains('newsletter') ||
        customName.contains('newsletter');
  }

  void _updateLayout(Map<String, dynamic> updatedTree) {
    ref.read(activeThemeConfigProvider.notifier).updateSlots({
      _slotKey: updatedTree,
    }, editKey: 'outline_layout_update');
  }

  void _toggleVisibility(Map<String, dynamic> section) {
    final tree = _getLayoutTree();
    final list = List<dynamic>.from(tree['children'] ?? []);
    final idx = list.indexWhere((item) => item['id'] == section['id']);
    if (idx != -1) {
      final updatedNode = Map<String, dynamic>.from(list[idx]);
      updatedNode['hidden'] = !(updatedNode['hidden'] == true);
      list[idx] = updatedNode;
      final updatedTree = {...tree, 'children': list};
      _updateLayout(updatedTree);
    }
  }

  void _duplicateSection(Map<String, dynamic> section) {
    final tree = _getLayoutTree();
    final list = List<dynamic>.from(tree['children'] ?? []);
    final idx = list.indexWhere((item) => item['id'] == section['id']);
    if (idx != -1) {
      final copy = Map<String, dynamic>.from(list[idx]);
      copy['id'] = '${section['type'] ?? 'section'}_${DateTime.now().millisecondsSinceEpoch}';
      copy['customName'] = '${section['customName'] ?? section['type'] ?? 'Section'} (Copy)';
      list.insert(idx + 1, copy);
      final updatedTree = {...tree, 'children': list};
      _updateLayout(updatedTree);
    }
  }

  void _removeSection(Map<String, dynamic> section) {
    final tree = _getLayoutTree();
    final list = List<dynamic>.from(tree['children'] ?? []);
    list.removeWhere((item) => item['id'] == section['id']);
    final updatedTree = {...tree, 'children': list};
    _updateLayout(updatedTree);
    if (ref.read(selectedSectionIdProvider) == section['id']) {
      ref.read(selectedSectionIdProvider.notifier).setSelectedId(null);
    }
  }

  void _addSection(String type, String name, String group) {
    final tree = _getLayoutTree();
    final list = List<dynamic>.from(tree['children'] ?? []);
    final newId = '${type}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Default properties for templates
    final newSection = {
      'id': newId,
      'type': type,
      'customName': name,
      'properties': {
        'padding': type == 'announcement_bar' ? 8.0 : 24.0,
        'spacing': 16.0,
      },
      'children': []
    };

    int insertIdx = list.length;
    if (group == 'HEADER') {
      insertIdx = 0;
      for (int i = 0; i < list.length; i++) {
        if (_isHeaderNode(list[i])) {
          insertIdx = i + 1;
        }
      }
    } else if (group == 'TEMPLATE') {
      insertIdx = list.length;
      for (int i = 0; i < list.length; i++) {
        if (_isFooterNode(list[i])) {
          insertIdx = i;
          break;
        }
      }
    }

    list.insert(insertIdx, newSection);
    final updatedTree = {...tree, 'children': list};
    _updateLayout(updatedTree);
    
    setState(() {
      ref.read(selectedSectionIdProvider.notifier).setSelectedId(newId);
      ref.read(customizerNavStackProvider.notifier).setStack([newId]);
    });
  }

  void _showAddSectionDialog(String group) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        final List<Widget> dialogContent = [];
        
        if (group == 'HEADER') {
          dialogContent.addAll([
            _AddSectionTile(
              icon: LucideIcons.megaphone,
              title: 'Announcement Bar',
              subtitle: 'Show key announcements at the very top of the storefront',
              onTap: () {
                Navigator.pop(context);
                _addSection('announcement_bar', 'Announcement Bar', 'HEADER');
              },
            ),
            _AddSectionTile(
              icon: LucideIcons.menu,
              title: 'Header Navigation',
              subtitle: 'Main storefront brand header and navigation links',
              onTap: () {
                Navigator.pop(context);
                _addSection('header', 'Header', 'HEADER');
              },
            ),
          ]);
        } else if (group == 'FOOTER') {
          dialogContent.addAll([
            _AddSectionTile(
              icon: LucideIcons.layoutGrid,
              title: 'Footer',
              subtitle: 'Bottom links, newsletter signups, copyright, and payment badges',
              onTap: () {
                Navigator.pop(context);
                _addSection('footer', 'Footer', 'FOOTER');
              },
            ),
            _AddSectionTile(
              icon: LucideIcons.mail,
              title: 'Newsletter Sign-up',
              subtitle: 'Invite newsletter subscriber sign-ups',
              onTap: () {
                Navigator.pop(context);
                _addSection('newsletter_signup', 'Newsletter Sign-up', 'FOOTER');
              },
            ),
          ]);
        } else {
          // TEMPLATE
          dialogContent.addAll([
            _AddSectionTile(
              icon: LucideIcons.image,
              title: 'Image Banner',
              subtitle: 'Large photo showcase with optional titles and CTAs',
              onTap: () {
                Navigator.pop(context);
                _addSection('image_banner', 'Image Banner', 'TEMPLATE');
              },
            ),
            _AddSectionTile(
              icon: LucideIcons.shoppingBag,
              title: 'Featured Collection',
              subtitle: 'Grid list of items from a curated product catalog',
              onTap: () {
                Navigator.pop(context);
                _addSection('collection', 'Featured Collection', 'TEMPLATE');
              },
            ),
            _AddSectionTile(
              icon: LucideIcons.layers,
              title: 'Collection List',
              subtitle: 'Curated grids showcasing various product categories',
              onTap: () {
                Navigator.pop(context);
                _addSection('collection_list', 'Collection List', 'TEMPLATE');
              },
            ),
            _AddSectionTile(
              icon: LucideIcons.text,
              title: 'Rich Text block',
              subtitle: 'Editorial statement with title, descriptions, and CTA',
              onTap: () {
                Navigator.pop(context);
                _addSection('flexCol', 'Rich Text block', 'TEMPLATE');
              },
            ),
            _AddSectionTile(
              icon: LucideIcons.mail,
              title: 'Newsletter Sign-up',
              subtitle: 'Invite newsletter subscriber sign-ups',
              onTap: () {
                Navigator.pop(context);
                _addSection('newsletter_signup', 'Newsletter Sign-up', 'TEMPLATE');
              },
            ),
          ]);
        }

        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: Text('Add Section to $group', style: const TextStyle(fontFamily: 'Outfit')),
          content: SizedBox(
            width: 320,
            child: ListView(
              shrinkWrap: true,
              children: dialogContent,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'announcement_bar':
        return LucideIcons.megaphone;
      case 'header':
      case 'nav':
        return LucideIcons.navigation;
      case 'image_banner':
        return LucideIcons.image;
      case 'collection':
      case 'product_card':
        return LucideIcons.shoppingBag;
      case 'collection_list':
        return LucideIcons.layers;
      case 'footer':
        return LucideIcons.layoutGrid;
      case 'newsletter_signup':
        return LucideIcons.mail;
      case 'divider':
        return LucideIcons.minus;
      case 'text':
        return LucideIcons.type;
      case 'button':
        return LucideIcons.play;
      default:
        return LucideIcons.box;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedSectionIdProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tree = _getLayoutTree();
    final allSections = List<Map<String, dynamic>>.from(
      (tree['children'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e)),
    );

    // Auto-initialize expansion state for sections that have children
    if (!_initializedExpansion && allSections.isNotEmpty) {
      for (final s in allSections) {
        final children = s['children'] as List<dynamic>? ?? [];
        if (children.isNotEmpty) {
          _expandedSections.add(s['id'] ?? '');
        }
      }
      _initializedExpansion = true;
    }

    final headerSections = allSections.where((s) => _isHeaderNode(s)).toList();
    final footerSections = allSections.where((s) => _isFooterNode(s)).toList();
    final templateSections = allSections.where((s) => !_isHeaderNode(s) && !_isFooterNode(s)).toList();

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(right: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Template Layout',
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // 1. HEADER GROUP
                _buildGroupHeader('HEADER', _headerExpanded, (val) => setState(() => _headerExpanded = val)),
                if (_headerExpanded) ...[
                  if (headerSections.isEmpty)
                    const _EmptyGroupPlaceholder(label: 'No header sections')
                  else
                    ..._buildSectionListWithBlocks(headerSections, selectedId, theme, isDark, 'HEADER'),
                  
                  _buildAddSectionButton('HEADER', theme),
                ],
                
                const SizedBox(height: 12),
                
                // 2. TEMPLATE GROUP
                _buildGroupHeader('TEMPLATE', _templateExpanded, (val) => setState(() => _templateExpanded = val)),
                if (_templateExpanded) ...[
                  if (templateSections.isEmpty)
                    const _EmptyGroupPlaceholder(label: 'Add sections here')
                  else
                    ..._buildSectionListWithBlocks(templateSections, selectedId, theme, isDark, 'TEMPLATE'),
                  
                  _buildAddSectionButton('TEMPLATE', theme),
                ],

                const SizedBox(height: 12),

                // 3. FOOTER GROUP
                _buildGroupHeader('FOOTER', _footerExpanded, (val) => setState(() => _footerExpanded = val)),
                if (_footerExpanded) ...[
                  if (footerSections.isEmpty)
                    const _EmptyGroupPlaceholder(label: 'No footer sections')
                  else
                    ..._buildSectionListWithBlocks(footerSections, selectedId, theme, isDark, 'FOOTER'),
                  
                  _buildAddSectionButton('FOOTER', theme),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String title, bool isExpanded, ValueChanged<bool> onToggle) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: theme.hintColor,
            ),
          ),
          InkWell(
            onTap: () => onToggle(!isExpanded),
            child: Icon(
              isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
              size: 14,
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionRow(
    Map<String, dynamic> section,
    String? selectedId,
    ThemeData theme,
    bool isDark,
    bool hasChildren,
    bool isExpanded,
  ) {
    final id = section['id'] ?? '';
    final type = section['type'] ?? 'flexCol';
    final customName = section['customName'] ?? section['label'] ?? type;
    final isSelected = selectedId == id;
    final isHidden = section['hidden'] == true;

    final rowBg = isSelected
        ? AppTheme.brandEmerald500.withOpacity(0.1)
        : Colors.transparent;

    return StatefulBuilder(
      builder: (context, setStateRow) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setStateRow(() => isHovered = true),
          onExit: (_) => setStateRow(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              ref.read(selectedSectionIdProvider.notifier).setSelectedId(id);
              ref.read(customizerNavStackProvider.notifier).setStack([id]);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              color: rowBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(LucideIcons.gripVertical, size: 14, color: theme.hintColor.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  if (hasChildren)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedSections.remove(id);
                          } else {
                            _expandedSections.add(id);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(
                          isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                          size: 14,
                          color: theme.hintColor,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 4),
                  Icon(
                    _getIconForType(type),
                    size: 16,
                    color: isSelected ? AppTheme.brandEmerald500 : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isHidden
                            ? theme.hintColor
                            : (isSelected ? AppTheme.brandEmerald500 : theme.colorScheme.onSurface),
                      ),
                    ),
                  ),
                  
                  // Visibility eye toggle (always show if hidden, or on hover)
                  if (isHidden || isHovered)
                    IconButton(
                      icon: Icon(
                        isHidden ? LucideIcons.eyeOff : LucideIcons.eye,
                        size: 14,
                        color: theme.hintColor,
                      ),
                      onPressed: () => _toggleVisibility(section),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),

                  // Actions menu button
                  if (isHovered)
                    PopupMenuButton<String>(
                      icon: Icon(LucideIcons.moreHorizontal, size: 14, color: theme.hintColor),
                      onSelected: (val) {
                        if (val == 'duplicate') {
                          _duplicateSection(section);
                        } else if (val == 'delete') {
                          _removeSection(section);
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                        const PopupMenuItem(value: 'delete', child: Text('Remove', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSectionListWithBlocks(
    List<dynamic> sections,
    String? selectedId,
    ThemeData theme,
    bool isDark,
    String groupName,
  ) {
    final List<Widget> items = [];
    final activeStack = ref.watch(customizerNavStackProvider);
    final activeSectionId = activeStack.isNotEmpty ? activeStack.first : null;
    final activeChildId = activeStack.length > 1 ? activeStack.last : null;

    for (final s in sections) {
      final id = s['id'] ?? '';
      final children = s['children'] as List<dynamic>? ?? [];
      final isExpanded = _expandedSections.contains(id);

      items.add(
        _buildSectionRow(s, selectedId, theme, isDark, children.isNotEmpty, isExpanded),
      );

      if (children.isNotEmpty && isExpanded) {
        for (final c in children) {
          items.add(
            _buildChildBlockRow(id, c, activeChildId, theme, isDark),
          );
        }
        // Add block button
        items.add(
          _buildAddBlockButton(s, theme),
        );
      }
    }

    return items;
  }

  Widget _buildChildBlockRow(
    String parentId,
    Map<String, dynamic> child,
    String? activeChildId,
    ThemeData theme,
    bool isDark,
  ) {
    final childId = child['id'] ?? '';
    final type = child['type'] ?? 'text';
    final customName = child['customName'] ?? child['value'] ?? type;
    final isSelected = activeChildId == childId;

    final rowBg = isSelected
        ? AppTheme.brandEmerald500.withOpacity(0.08)
        : Colors.transparent;

    return StatefulBuilder(
      builder: (context, setStateRow) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setStateRow(() => isHovered = true),
          onExit: (_) => setStateRow(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              ref.read(selectedSectionIdProvider.notifier).setSelectedId(parentId);
              ref.read(customizerNavStackProvider.notifier).setStack([parentId, childId]);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              color: rowBg,
              padding: const EdgeInsets.only(left: 36, right: 16, top: 6, bottom: 6),
              child: Row(
                children: [
                  Icon(
                    _getIconForType(type),
                    size: 14,
                    color: isSelected ? AppTheme.brandEmerald500 : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customName.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.brandEmerald500 : theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                  if (isHovered)
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 12, color: Colors.red),
                      onPressed: () => _removeChildBlock(parentId, childId),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddBlockButton(Map<String, dynamic> parentSection, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, top: 4, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: () => _addChildBlock(parentSection),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.plusCircle,
                  size: 12,
                  color: AppTheme.brandEmerald500,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Add block',
                  style: TextStyle(
                    fontSize: 11,
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

  void _addChildBlock(Map<String, dynamic> parentSection) {
    final theme = Theme.of(context);
    final parentId = parentSection['id'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: const Text('Add Block', style: TextStyle(fontFamily: 'Outfit')),
          content: SizedBox(
            width: 260,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.text, size: 16),
                  title: const Text('Text block', style: TextStyle(fontSize: 13)),
                  onTap: () {
                    Navigator.pop(context);
                    _addChildBlockToSection(parentId, 'text', 'New Text Block');
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.mousePointerClick, size: 16),
                  title: const Text('Button', style: TextStyle(fontSize: 13)),
                  onTap: () {
                    Navigator.pop(context);
                    _addChildBlockToSection(parentId, 'button', 'Click Me');
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.image, size: 16),
                  title: const Text('Image', style: TextStyle(fontSize: 13)),
                  onTap: () {
                    Navigator.pop(context);
                    _addChildBlockToSection(parentId, 'image', 'Image Block');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addChildBlockToSection(String parentId, String type, String defaultValue) {
    final tree = _getLayoutTree();
    final children = List<dynamic>.from(tree['children'] ?? []);
    final childId = '${type}_${DateTime.now().millisecondsSinceEpoch}';

    final newBlock = {
      'id': childId,
      'type': type,
      'value': defaultValue,
      'style': {
        'font_size': 14.0,
        'color': '#000000',
      }
    };

    for (int i = 0; i < children.length; i++) {
      if (children[i]['id'] == parentId) {
        final parentSection = Map<String, dynamic>.from(children[i]);
        final sectionChildren = List<dynamic>.from(parentSection['children'] ?? []);
        sectionChildren.add(newBlock);
        parentSection['children'] = sectionChildren;
        children[i] = parentSection;
        break;
      }
    }

    final updatedTree = {...tree, 'children': children};
    _updateLayout(updatedTree);
    
    // Automatically select the new block
    ref.read(selectedSectionIdProvider.notifier).setSelectedId(parentId);
    ref.read(customizerNavStackProvider.notifier).setStack([parentId, childId]);
  }

  void _removeChildBlock(String parentId, String childId) {
    final tree = _getLayoutTree();
    final children = List<dynamic>.from(tree['children'] ?? []);
    
    for (int i = 0; i < children.length; i++) {
      if (children[i]['id'] == parentId) {
        final parentSection = Map<String, dynamic>.from(children[i]);
        final sectionChildren = List<dynamic>.from(parentSection['children'] ?? []);
        sectionChildren.removeWhere((c) => c['id'] == childId);
        parentSection['children'] = sectionChildren;
        children[i] = parentSection;
        break;
      }
    }

    final updatedTree = {...tree, 'children': children};
    _updateLayout(updatedTree);
    
    final currentStack = ref.read(customizerNavStackProvider);
    if (currentStack.length > 1 && currentStack.last == childId) {
      ref.read(customizerNavStackProvider.notifier).setStack([parentId]);
    }
  }

  Widget _buildAddSectionButton(String group, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, right: 16, top: 4, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: () => _showAddSectionDialog(group),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.plusCircle,
                  size: 14,
                  color: AppTheme.brandEmerald500,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Add section',
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
}

class _EmptyGroupPlaceholder extends StatelessWidget {
  final String label;
  const _EmptyGroupPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontStyle: FontStyle.italic,
          color: Theme.of(context).hintColor.withOpacity(0.5),
        ),
      ),
    );
  }
}

class _AddSectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddSectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: AppTheme.brandEmerald500, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: theme.hintColor)),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}
