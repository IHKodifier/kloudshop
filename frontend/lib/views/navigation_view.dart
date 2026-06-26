import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';
import 'package:kloudshop/models/catalog.dart';

class NavigationView extends ConsumerStatefulWidget {
  const NavigationView({super.key});

  @override
  ConsumerState<NavigationView> createState() => _NavigationViewState();
}

class _NavigationViewState extends ConsumerState<NavigationView> {
  bool _isLoading = false;
  List<dynamic> _menus = [];
  dynamic _selectedMenu;
  List<dynamic> _flatItems = []; // Flat representation of menu items for reordering/editing

  final _menuNameController = TextEditingController();
  final _menuHandleController = TextEditingController();

  final _itemTitleController = TextEditingController();
  final _itemUrlController = TextEditingController();
  String _selectedLinkType = 'custom'; // custom, product, collection, page, policy
  String? _selectedResourceId;
  String? _itemParentId;
  int _itemPosition = 0;
  dynamic _editingItem;

  // Resource lists for link picker dropdowns
  List<Product> _products = [];
  List<dynamic> _collections = [];
  List<dynamic> _pages = [];
  List<dynamic> _policies = [];

  @override
  void initState() {
    super.initState();
    _fetchMenus();
    _fetchResources();
  }

  @override
  void dispose() {
    _menuNameController.dispose();
    _menuHandleController.dispose();
    _itemTitleController.dispose();
    _itemUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchMenus() async {
    setState(() => _isLoading = true);
    try {
      final menus = await ref.read(apiServiceProvider).listNavigationMenus();
      setState(() {
        _menus = menus;
        if (_menus.isNotEmpty) {
          // Select first menu or keep selected
          if (_selectedMenu != null) {
            _selectedMenu = _menus.firstWhere(
              (m) => m['menu_id'] == _selectedMenu['menu_id'],
              orElse: () => _menus.first,
            );
          } else {
            _selectedMenu = _menus.first;
          }
          _loadMenuTree();
        } else {
          _selectedMenu = null;
          _flatItems = [];
        }
      });
    } catch (e) {
      _showError('Failed to load menus: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchResources() async {
    try {
      final products = await ref.read(apiServiceProvider).listProducts();
      final collections = await ref.read(apiServiceProvider).listCollections();
      final pages = await ref.read(apiServiceProvider).listStorefrontPages();
      final policies = await ref.read(apiServiceProvider).listPolicies();

      setState(() {
        _products = products;
        _collections = collections;
        _pages = pages;
        _policies = policies;
      });
    } catch (_) {}
  }

  void _loadMenuTree() {
    if (_selectedMenu == null) return;
    final List<dynamic> flat = [];
    
    void traverse(List<dynamic> items, int level, String? parentId) {
      for (final item in items) {
        flat.add({
          'item_id': item['item_id'],
          'parent_id': parentId,
          'title': item['title'],
          'url': item['url'],
          'link_type': item['link_type'],
          'resource_id': item['resource_id'],
          'position': item['position'],
          'level': level,
        });
        if (item['children'] != null && (item['children'] as List).isNotEmpty) {
          traverse(item['children'], level + 1, item['item_id']);
        }
      }
    }

    if (_selectedMenu['items'] != null) {
      traverse(_selectedMenu['items'], 0, null);
    }

    setState(() {
      _flatItems = flat;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.brandEmerald600, behavior: SnackBarBehavior.floating),
    );
  }

  // --- Actions ---

  Future<void> _createMenu() async {
    if (_menuNameController.text.isEmpty || _menuHandleController.text.isEmpty) {
      _showError('Menu Name and Handle are required');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final handle = _menuHandleController.text.toLowerCase().replaceAll(' ', '-');
      await ref.read(apiServiceProvider).createNavigationMenu(_menuNameController.text, handle);
      _showSuccess('Menu created successfully!');
      _menuNameController.clear();
      _menuHandleController.clear();
      Navigator.of(context).pop();
      await _fetchMenus();
    } catch (e) {
      _showError('Failed to create menu: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveItem() async {
    if (_itemTitleController.text.isEmpty || _itemUrlController.text.isEmpty) {
      _showError('Title and URL link are required');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final menuId = _selectedMenu['menu_id'];
      if (_editingItem == null) {
        // Create item
        await ref.read(apiServiceProvider).createNavigationItem(
          menuId: menuId,
          parentId: _itemParentId,
          title: _itemTitleController.text,
          url: _itemUrlController.text,
          linkType: _selectedLinkType,
          resourceId: _selectedResourceId,
          position: _itemPosition,
        );
        _showSuccess('Item added to menu!');
      } else {
        final itemId = _editingItem['item_id'];
        await ref.read(apiServiceProvider).deleteNavigationItem(itemId);
        await ref.read(apiServiceProvider).createNavigationItem(
          menuId: menuId,
          parentId: _itemParentId,
          title: _itemTitleController.text,
          url: _itemUrlController.text,
          linkType: _selectedLinkType,
          resourceId: _selectedResourceId,
          position: _itemPosition,
        );
        _showSuccess('Item updated successfully!');
      }
      _clearItemForm();
      await _fetchMenus();
    } catch (e) {
      _showError('Failed to save navigation item: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(String itemId) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(apiServiceProvider).deleteNavigationItem(itemId);
      _showSuccess('Item removed from menu!');
      _clearItemForm();
      await _fetchMenus();
    } catch (e) {
      _showError('Failed to delete item: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reorderItems(List<dynamic> reorderedList) async {
    setState(() => _isLoading = true);
    final itemsPayload = reorderedList.map<Map<String, dynamic>>((item) => {
      'item_id': item['item_id'],
      'parent_id': item['parent_id'],
      'position': item['position'],
    }).toList();
    try {
      final menuId = _selectedMenu['menu_id'];
      await ref.read(apiServiceProvider).reorderNavigationItems(menuId, itemsPayload);
      _showSuccess('Menu layout saved!');
      await _fetchMenus();
    } catch (e) {
      _showError('Failed to save layout: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearItemForm() {
    setState(() {
      _editingItem = null;
      _itemTitleController.clear();
      _itemUrlController.clear();
      _selectedLinkType = 'custom';
      _selectedResourceId = null;
      _itemParentId = null;
      _itemPosition = 0;
    });
  }

  void _startEditingItem(dynamic item) {
    setState(() {
      _editingItem = item;
      _itemTitleController.text = item['title'];
      _itemUrlController.text = item['url'];
      _selectedLinkType = item['link_type'];
      _selectedResourceId = item['resource_id'];
      _itemParentId = item['parent_id'];
      _itemPosition = item['position'];
    });
  }

  // Helper functions to move items up/down/left/right (nesting)
  void _moveItemUp(int index) {
    if (index <= 0) return;
    final list = List<dynamic>.from(_flatItems);
    
    // Swap positions
    final temp = list[index];
    list[index] = list[index - 1];
    list[index - 1] = temp;

    // Reset positions based on order
    _applySequentialPositionsAndSave(list);
  }

  void _moveItemDown(int index) {
    if (index >= _flatItems.length - 1) return;
    final list = List<dynamic>.from(_flatItems);
    
    final temp = list[index];
    list[index] = list[index + 1];
    list[index + 1] = temp;

    _applySequentialPositionsAndSave(list);
  }

  void _indentItem(int index) {
    if (index <= 0) return;
    final list = List<dynamic>.from(_flatItems);
    final current = list[index];
    
    // Find the nearest preceding sibling at the same level or higher
    // To make it a child of that sibling
    String? potentialParentId;
    for (int i = index - 1; i >= 0; i--) {
      if (list[i]['level'] == current['level'] || list[i]['level'] == current['level'] - 1) {
        potentialParentId = list[i]['item_id'];
        break;
      }
    }

    if (potentialParentId != null) {
      current['parent_id'] = potentialParentId;
      current['level'] += 1;
      _applySequentialPositionsAndSave(list);
    }
  }

  void _outdentItem(int index) {
    final list = List<dynamic>.from(_flatItems);
    final current = list[index];
    if (current['parent_id'] == null) return; // Already at root

    // Outdenting means moving parent_id to the parent's parent
    // Find the parent item
    final parent = list.firstWhere((item) => item['item_id'] == current['parent_id'], orElse: () => null);
    if (parent != null) {
      current['parent_id'] = parent['parent_id'];
      current['level'] = parent['level'];
      _applySequentialPositionsAndSave(list);
    }
  }

  void _applySequentialPositionsAndSave(List<dynamic> list) {
    // Re-calculate positions grouped by parent_id
    final Map<String?, int> counts = {};
    for (var item in list) {
      final pId = item['parent_id'];
      final pos = counts[pId] ?? 0;
      item['position'] = pos;
      counts[pId] = pos + 1;
    }
    _reorderItems(list);
  }

  bool _hasDeepNesting() {
    return _flatItems.any((item) => item['level'] >= 3); // 0-indexed levels: 3 means level 4
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B).withOpacity(0.8) : Colors.white.withOpacity(0.9),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Store Navigation',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Organize main menus, footer links, and nested dropdowns for your store.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_menus.isNotEmpty)
                      DropdownButton<String>(
                        value: _selectedMenu?['menu_id'],
                        items: _menus.map<DropdownMenuItem<String>>((m) {
                          return DropdownMenuItem<String>(
                            value: m['menu_id'],
                            child: Text(m['name']),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedMenu = _menus.firstWhere((m) => m['menu_id'] == val);
                            _loadMenuTree();
                            _clearItemForm();
                          });
                        },
                      ),
                    const SizedBox(width: 16),
                    HoverScale(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCreateMenuDialog(context),
                        icon: const Icon(LucideIcons.plus, size: 14),
                        label: const Text('New Menu'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),

          // Nested Levels Warning
          if (_hasDeepNesting())
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.alertTriangle, color: Colors.amber, size: 18),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nesting beyond 3 levels is allowed but not recommended, as it can make navigation difficult for customers on mobile devices.',
                      style: TextStyle(fontSize: 12, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),

          // Main content split view
          Expanded(
            child: _selectedMenu == null
                ? const Center(child: Text('Create a navigation menu to begin.'))
                : Row(
                    children: [
                      // Left Pane: Menu list editor tree
                      Expanded(
                        flex: 3,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _flatItems.length,
                          itemBuilder: (context, index) {
                            final item = _flatItems[index];
                            final level = item['level'] as int;
                            final isEditing = _editingItem != null && _editingItem['item_id'] == item['item_id'];
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  // Indentation spacer
                                  SizedBox(width: level * 30.0),
                                  // Hierarchy visual line indicator
                                  if (level > 0)
                                    Container(
                                      width: 2,
                                      height: 40,
                                      color: AppTheme.brandEmerald500.withOpacity(0.3),
                                      margin: const EdgeInsets.only(right: 12),
                                    ),
                                  // Item Card
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isEditing ? AppTheme.brandEmerald500 : theme.dividerColor,
                                          width: isEditing ? 2 : 1,
                                        ),
                                      ),
                                      child: ListTile(
                                        title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        subtitle: Text(item['url'] ?? '', style: TextStyle(color: theme.hintColor, fontSize: 11)),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Hierarchy controllers
                                            IconButton(
                                              icon: const Icon(LucideIcons.chevronUp, size: 14),
                                              onPressed: () => _moveItemUp(index),
                                              tooltip: 'Move Up',
                                            ),
                                            IconButton(
                                              icon: const Icon(LucideIcons.chevronDown, size: 14),
                                              onPressed: () => _moveItemDown(index),
                                              tooltip: 'Move Down',
                                            ),
                                            IconButton(
                                              icon: const Icon(LucideIcons.indent, size: 14),
                                              onPressed: () => _indentItem(index),
                                              tooltip: 'Indent (Make Child)',
                                            ),
                                            IconButton(
                                              icon: const Icon(LucideIcons.outdent, size: 14),
                                              onPressed: () => _outdentItem(index),
                                              tooltip: 'Outdent (Make Parent)',
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(LucideIcons.edit2, size: 14),
                                              onPressed: () => _startEditingItem(item),
                                              tooltip: 'Edit Link',
                                            ),
                                            IconButton(
                                              icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                                              onPressed: () => _deleteItem(item['item_id']),
                                              tooltip: 'Delete Link',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Vertical Divider
                      Container(width: 1, color: theme.dividerColor),

                      // Right Pane: Item Editor form
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: theme.dividerColor),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _editingItem == null ? 'Add Link Item' : 'Edit Link Item',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 24),
                                  TextField(
                                    controller: _itemTitleController,
                                    decoration: const InputDecoration(
                                      labelText: 'Link Name',
                                      border: OutlineInputBorder(),
                                      hintText: 'Summer Collections',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _selectedLinkType,
                                    decoration: const InputDecoration(
                                      labelText: 'Link Type',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'custom', child: Text('Custom / External URL')),
                                      DropdownMenuItem(value: 'product', child: Text('Product Page')),
                                      DropdownMenuItem(value: 'collection', child: Text('Collection Page')),
                                      DropdownMenuItem(value: 'page', child: Text('Store Page')),
                                      DropdownMenuItem(value: 'policy', child: Text('Store Legal Policy')),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedLinkType = val!;
                                        _selectedResourceId = null;
                                        _itemUrlController.clear();
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Contextual Resource picker
                                  if (_selectedLinkType == 'custom')
                                    TextField(
                                      controller: _itemUrlController,
                                      decoration: const InputDecoration(
                                        labelText: 'URL Link',
                                        border: OutlineInputBorder(),
                                        hintText: 'https://example.com',
                                      ),
                                    )
                                  else if (_selectedLinkType == 'product')
                                    DropdownButtonFormField<String>(
                                      value: _selectedResourceId,
                                      hint: const Text('Select a Product'),
                                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Product'),
                                      items: _products.map<DropdownMenuItem<String>>((p) {
                                        return DropdownMenuItem<String>(
                                          value: p.id,
                                          child: Text(p.title),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        final prod = _products.firstWhere((p) => p.id == val);
                                        setState(() {
                                          _selectedResourceId = val;
                                          _itemUrlController.text = '/products/${prod.slug}';
                                          if (_itemTitleController.text.isEmpty) {
                                            _itemTitleController.text = prod.title;
                                          }
                                        });
                                      },
                                    )
                                  else if (_selectedLinkType == 'collection')
                                    DropdownButtonFormField<String>(
                                      value: _selectedResourceId,
                                      hint: const Text('Select a Collection'),
                                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Collection'),
                                      items: _collections.map<DropdownMenuItem<String>>((c) {
                                        return DropdownMenuItem<String>(
                                          value: c['collection_id'],
                                          child: Text(c['title']),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        final coll = _collections.firstWhere((c) => c['collection_id'] == val);
                                        setState(() {
                                          _selectedResourceId = val;
                                          _itemUrlController.text = '/collections/${coll['slug']}';
                                          if (_itemTitleController.text.isEmpty) {
                                            _itemTitleController.text = coll['title'];
                                          }
                                        });
                                      },
                                    )
                                  else if (_selectedLinkType == 'page')
                                    DropdownButtonFormField<String>(
                                      value: _selectedResourceId,
                                      hint: const Text('Select a Page'),
                                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Static Page'),
                                      items: _pages.map<DropdownMenuItem<String>>((p) {
                                        return DropdownMenuItem<String>(
                                          value: p['page_id'],
                                          child: Text(p['title']),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        final page = _pages.firstWhere((p) => p['page_id'] == val);
                                        setState(() {
                                          _selectedResourceId = val;
                                          _itemUrlController.text = '/pages/${page['slug']}';
                                          if (_itemTitleController.text.isEmpty) {
                                            _itemTitleController.text = page['title'];
                                          }
                                        });
                                      },
                                    )
                                  else if (_selectedLinkType == 'policy')
                                    DropdownButtonFormField<String>(
                                      value: _selectedResourceId,
                                      hint: const Text('Select a Legal Policy'),
                                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Legal Policy'),
                                      items: _policies.map<DropdownMenuItem<String>>((p) {
                                        return DropdownMenuItem<String>(
                                          value: p['policy_id'],
                                          child: Text('${(p['policy_type'] as String).toUpperCase()} Policy'),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        final poly = _policies.firstWhere((p) => p['policy_id'] == val);
                                        setState(() {
                                          _selectedResourceId = val;
                                          _itemUrlController.text = '/policies/${poly['policy_type']}';
                                          if (_itemTitleController.text.isEmpty) {
                                            _itemTitleController.text = '${(poly['policy_type'] as String).replaceFirst(poly['policy_type'][0], poly['policy_type'][0].toUpperCase())} Policy';
                                          }
                                        });
                                      },
                                    ),
                                  const SizedBox(height: 32),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: HoverScale(
                                          child: ElevatedButton(
                                            onPressed: _saveItem,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.brandEmerald500,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                            ),
                                            child: Text(_editingItem == null ? 'Add to Menu' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ),
                                      if (_editingItem != null) ...[
                                        const SizedBox(width: 12),
                                        OutlinedButton(
                                          onPressed: _clearItemForm,
                                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                                          child: const Text('Cancel'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
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
    );
  }

  void _showCreateMenuDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Navigation Menu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _menuNameController,
                decoration: const InputDecoration(labelText: 'Menu Name (e.g. Main Menu)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _menuHandleController,
                decoration: const InputDecoration(labelText: 'Handle (e.g. main-menu)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _createMenu,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandEmerald500, foregroundColor: Colors.white),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
