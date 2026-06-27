import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/providers/theme_providers.dart';

class SectionPropertiesPanel extends ConsumerStatefulWidget {
  final ThemeConfigModel? config;
  final String selectedPage;
  final Map<String, dynamic> layout;

  const SectionPropertiesPanel({
    super.key,
    required this.config,
    required this.selectedPage,
    required this.layout,
  });

  @override
  ConsumerState<SectionPropertiesPanel> createState() => _SectionPropertiesPanelState();
}

class _SectionPropertiesPanelState extends ConsumerState<SectionPropertiesPanel> {
  final _textControllers = <String, TextEditingController>{};

  String get _slotKey => widget.selectedPage == 'home' ? 'layout' : 'layout_${widget.selectedPage}';

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _getLayoutTree() {
    return widget.layout;
  }

  Map<String, dynamic> _getDefaultLayout() {
    return {"id": "root", "type": "flexCol", "children": []};
  }

  Map<String, dynamic>? _findNodeInTree(Map<String, dynamic> root, String id) {
    if (root['id'] == id) return root;
    final children = root['children'] as List<dynamic>? ?? [];
    for (final child in children) {
      if (child is Map<String, dynamic>) {
        final res = _findNodeInTree(child, id);
        if (res != null) return res;
      }
    }
    return null;
  }

  Map<String, dynamic> _deepCopyMap(Map<String, dynamic> map) {
    return Map<String, dynamic>.from(
      map.map((key, value) {
        if (value is Map<String, dynamic>) {
          return MapEntry(key, _deepCopyMap(value));
        } else if (value is List) {
          return MapEntry(key, value.map((item) {
            if (item is Map<String, dynamic>) {
              return _deepCopyMap(item);
            }
            return item;
          }).toList());
        }
        return MapEntry(key, value);
      }),
    );
  }

  bool _updateNodeInTree(
    Map<String, dynamic> root,
    String id,
    Map<String, dynamic> Function(Map<String, dynamic>) updater,
  ) {
    if (root['id'] == id) {
      final updated = updater(root);
      root.clear();
      root.addAll(updated);
      return true;
    }
    final children = root['children'] as List<dynamic>? ?? [];
    for (int i = 0; i < children.length; i++) {
      final child = children[i];
      if (child is Map<String, dynamic>) {
        final copied = Map<String, dynamic>.from(child);
        final found = _updateNodeInTree(copied, id, updater);
        if (found) {
          children[i] = copied;
          return true;
        }
      }
    }
    return false;
  }

  void _updateNodeProperties(String nodeId, Map<String, dynamic> properties) {
    final tree = _deepCopyMap(_getLayoutTree());
    final success = _updateNodeInTree(tree, nodeId, (node) {
      final existingProps = node['properties'] as Map<String, dynamic>? ?? {};
      return {
        ...node,
        'properties': {...existingProps, ...properties},
      };
    });
    if (success) {
      ref.read(activeThemeConfigProvider.notifier).updateSlots({
        _slotKey: tree,
      }, editKey: 'properties_node_update_$nodeId');
    }
  }

  void _updateNodeBasic(String nodeId, String key, dynamic value) {
    final tree = _deepCopyMap(_getLayoutTree());
    final success = _updateNodeInTree(tree, nodeId, (node) {
      return {
        ...node,
        key: value,
      };
    });
    if (success) {
      ref.read(activeThemeConfigProvider.notifier).updateSlots({
        _slotKey: tree,
      }, editKey: 'properties_node_basic_$nodeId');
    }
  }

  void _removeNode(String nodeId) {
    final tree = _deepCopyMap(_getLayoutTree());
    final children = tree['children'] as List<dynamic>? ?? [];
    children.removeWhere((item) => item['id'] == nodeId);
    
    // Also check inside nested containers
    _removeNodeFromTreeChildren(tree, nodeId);

    ref.read(activeThemeConfigProvider.notifier).updateSlots({
      _slotKey: tree,
    }, editKey: 'properties_node_remove_$nodeId');

    // Pop navigation stack
    final stack = List<String>.from(ref.read(customizerNavStackProvider));
    if (stack.isNotEmpty) {
      stack.removeLast();
      ref.read(customizerNavStackProvider.notifier).setStack(stack);
    }
    ref.read(selectedSectionIdProvider.notifier).setSelectedId(null);
  }

  void _removeNodeFromTreeChildren(Map<String, dynamic> parent, String id) {
    final children = parent['children'] as List<dynamic>? ?? [];
    children.removeWhere((item) => item['id'] == id);
    for (final child in children) {
      if (child is Map<String, dynamic>) {
        _removeNodeFromTreeChildren(child, id);
      }
    }
  }

  void _simulateSelectImage(String nodeId, String propertyKey) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: const Text('Select Image', style: TextStyle(fontFamily: 'Outfit')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ImageSelectTile(
                name: 'Apparel banner background (3:2)',
                url: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8',
                onSelect: (url) {
                  Navigator.pop(context);
                  _updateNodeProperties(nodeId, {propertyKey: url});
                },
              ),
              _ImageSelectTile(
                name: 'Modern tech background (16:9)',
                url: 'https://images.unsplash.com/photo-1519389950473-47ba0277781c',
                onSelect: (url) {
                  Navigator.pop(context);
                  _updateNodeProperties(nodeId, {propertyKey: url});
                },
              ),
              _ImageSelectTile(
                name: 'Store logo (Square)',
                url: 'https://images.unsplash.com/photo-1542496658-e33a6d0d50f6',
                onSelect: (url) {
                  Navigator.pop(context);
                  _updateNodeProperties(nodeId, {propertyKey: url});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final navStack = ref.watch(customizerNavStackProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (navStack.isEmpty) {
      return const SizedBox.shrink();
    }

    final targetId = navStack.last;
    final tree = _getLayoutTree();
    final node = _findNodeInTree(tree, targetId);

    if (node == null) {
      return Container(
        width: 300,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          border: Border(right: BorderSide(color: theme.dividerColor, width: 1)),
        ),
        child: const Center(
          child: Text('Section not found'),
        ),
      );
    }

    final type = node['type'] ?? 'flexCol';
    final customName = node['customName'] ?? node['label'] ?? type;
    final properties = node['properties'] as Map<String, dynamic>? ?? {};

    // Get text controllers or initialize
    TextEditingController getController(String key, String defaultVal) {
      final cacheKey = '$targetId-$key';
      if (!_textControllers.containsKey(cacheKey)) {
        _textControllers[cacheKey] = TextEditingController(text: defaultVal);
      }
      return _textControllers[cacheKey]!;
    }

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(right: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with back button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, size: 16),
                  onPressed: () {
                    final updatedStack = List<String>.from(navStack);
                    updatedStack.removeLast();
                    ref.read(customizerNavStackProvider.notifier).setStack(updatedStack);
                  },
                ),
                Expanded(
                  child: Text(
                    customName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(LucideIcons.moreHorizontal, size: 16, color: theme.hintColor),
                  onSelected: (val) {
                    if (val == 'remove') {
                      _removeNode(targetId);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove section', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Rename section input
                Text(
                  'SECTION TITLE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: theme.hintColor),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: getController('customName', customName),
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    _updateNodeBasic(targetId, 'customName', val);
                  },
                ),
                const SizedBox(height: 24),

                // 2. Type-Specific Customizer Inputs
                if (type == 'image_banner') ...[
                  Text(
                    'BANNER FIRST IMAGE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: theme.hintColor),
                  ),
                  const SizedBox(height: 6),
                  _buildImagePicker(targetId, 'first_image', properties['first_image']),
                  
                  const SizedBox(height: 16),
                  Text(
                    'BANNER SECOND IMAGE (OPTIONAL)',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: theme.hintColor),
                  ),
                  const SizedBox(height: 6),
                  _buildImagePicker(targetId, 'second_image', properties['second_image']),

                  const SizedBox(height: 16),
                  _buildOpacitySlider(targetId, properties),
                  
                  const SizedBox(height: 16),
                  _buildDropdownInput(
                    nodeId: targetId,
                    label: 'BANNER HEIGHT',
                    propertyKey: 'banner_height',
                    currentVal: properties['banner_height'] ?? 'medium',
                    options: const ['small', 'medium', 'large'],
                  ),
                  
                  const SizedBox(height: 16),
                  _buildDropdownInput(
                    nodeId: targetId,
                    label: 'DESKTOP CONTENT POSITION',
                    propertyKey: 'content_position',
                    currentVal: properties['content_position'] ?? 'center',
                    options: const ['top-left', 'center', 'bottom-center', 'bottom-left'],
                  ),
                ] else if (type == 'collection' || type == 'collection_list') ...[
                  _buildDropdownInput(
                    nodeId: targetId,
                    label: 'GRID COLUMNS (DESKTOP)',
                    propertyKey: 'columns',
                    currentVal: properties['columns']?.toString() ?? '3',
                    options: const ['2', '3', '4'],
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownInput(
                    nodeId: targetId,
                    label: 'GRID SPACING',
                    propertyKey: 'spacing',
                    currentVal: properties['spacing']?.toString() ?? '16',
                    options: const ['8', '16', '24', '32'],
                  ),
                ] else if (type == 'text') ...[
                  Text(
                    'TEXT CONTENT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: theme.hintColor),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: getController('value', node['value'] ?? ''),
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      _updateNodeBasic(targetId, 'value', val);
                    },
                  ),
                ] else if (type == 'button') ...[
                  Text(
                    'BUTTON TEXT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: theme.hintColor),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: getController('value', node['value'] ?? ''),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      _updateNodeBasic(targetId, 'value', val);
                    },
                  ),
                ] else ...[
                  // Fallback Generic Padding Editor
                  _buildPaddingFields(targetId, properties),
                ],

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                // 3. Blocks/Children Drill-Down list
                if ((node['children'] as List<dynamic>? ?? []).isNotEmpty) ...[
                  Text(
                    'NESTED BLOCKS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: theme.hintColor),
                  ),
                  const SizedBox(height: 8),
                  ...List<dynamic>.from(node['children'] ?? []).map((child) {
                    if (child is! Map<String, dynamic>) return const SizedBox.shrink();
                    final childId = child['id'] ?? '';
                    final childType = child['type'] ?? 'block';
                    final childName = child['customName'] ?? child['label'] ?? childType;
                    
                    return Card(
                      elevation: 0,
                      color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF8FAFC),
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        horizontalTitleGap: 8,
                        leading: const Icon(LucideIcons.box, size: 14),
                        title: Text(childName, style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(LucideIcons.chevronRight, size: 12),
                        onTap: () {
                          ref.read(customizerNavStackProvider.notifier).setStack([...navStack, childId]);
                        },
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(String nodeId, String propertyKey, String? currentUrl) {
    final theme = Theme.of(context);
    final isSelected = currentUrl != null && currentUrl.isNotEmpty;

    return InkWell(
      onTap: () => _simulateSelectImage(nodeId, propertyKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppTheme.brandEmerald500 : theme.dividerColor,
            style: BorderStyle.solid,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
          image: isSelected
              ? DecorationImage(image: NetworkImage(currentUrl), fit: BoxFit.cover)
              : null,
        ),
        child: !isSelected
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.image, size: 24, color: AppTheme.brandEmerald500),
                    SizedBox(height: 8),
                    Text('Select Image', style: TextStyle(fontSize: 12, color: AppTheme.brandEmerald500, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            : Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Change Image', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
      ),
    );
  }

  Widget _buildOpacitySlider(String nodeId, Map<String, dynamic> properties) {
    final currentVal = properties['overlay_opacity'] ?? 40.0;
    final displayPercent = (currentVal is num) ? currentVal.toDouble() : 40.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'IMAGE OVERLAY OPACITY',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Theme.of(context).hintColor),
            ),
            Text('${displayPercent.round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: displayPercent,
          min: 0,
          max: 100,
          activeColor: AppTheme.brandEmerald500,
          inactiveColor: Theme.of(context).dividerColor,
          onChanged: (val) {
            _updateNodeProperties(nodeId, {'overlay_opacity': val});
          },
        ),
      ],
    );
  }

  Widget _buildDropdownInput({
    required String nodeId,
    required String label,
    required String propertyKey,
    required String currentVal,
    required List<String> options,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: theme.hintColor),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(currentVal) ? currentVal : options.first,
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
              dropdownColor: theme.cardColor,
              items: options.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Text(opt.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  // Try to cast to double if number
                  final numVal = double.tryParse(val);
                  _updateNodeProperties(nodeId, {propertyKey: numVal ?? val});
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaddingFields(String nodeId, Map<String, dynamic> properties) {
    final padding = properties['padding'] ?? 16.0;
    final paddingVal = (padding is num) ? padding.toDouble() : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PADDING CONSTAINTS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Theme.of(context).hintColor),
            ),
            Text('${paddingVal.round()}px', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: paddingVal,
          min: 0,
          max: 80,
          activeColor: AppTheme.brandEmerald500,
          onChanged: (val) {
            _updateNodeProperties(nodeId, {'padding': val});
          },
        ),
      ],
    );
  }
}

class _ImageSelectTile extends StatelessWidget {
  final String name;
  final String url;
  final ValueChanged<String> onSelect;

  const _ImageSelectTile({
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
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
          ),
        ),
        title: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: theme.hintColor)),
        trailing: const Icon(LucideIcons.check, size: 14, color: AppTheme.brandEmerald500),
        onTap: () => onSelect(url),
      ),
    );
  }
}
