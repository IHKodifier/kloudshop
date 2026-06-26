import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';

class PagesView extends ConsumerStatefulWidget {
  const PagesView({super.key});

  @override
  ConsumerState<PagesView> createState() => _PagesViewState();
}

class _PagesViewState extends ConsumerState<PagesView> {
  bool _isLoading = false;
  List<dynamic> _pages = [];
  dynamic _editingPage;

  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  final _contentController = TextEditingController();
  final _navLabelController = TextEditingController();
  String _selectedStatus = 'draft';
  bool _showInNav = false;

  @override
  void initState() {
    super.initState();
    _fetchPages();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _contentController.dispose();
    _navLabelController.dispose();
    super.dispose();
  }

  Future<void> _fetchPages() async {
    setState(() => _isLoading = true);
    try {
      final pages = await ref.read(apiServiceProvider).listStorefrontPages();
      setState(() {
        _pages = pages;
      });
    } catch (e) {
      _showError('Failed to load pages: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.brandEmerald600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _startEditing(dynamic page) {
    setState(() {
      _editingPage = page;
      _titleController.text = page['title'] ?? '';
      _slugController.text = page['slug'] ?? '';
      _contentController.text = page['body'] != null ? (page['body']['html'] ?? '') : '';
      _selectedStatus = page['status'] ?? 'draft';
      _showInNav = page['show_in_nav'] ?? false;
      _navLabelController.text = page['nav_label'] ?? '';
    });
  }

  void _clearForm() {
    setState(() {
      _editingPage = null;
      _titleController.clear();
      _slugController.clear();
      _contentController.clear();
      _selectedStatus = 'draft';
      _showInNav = false;
      _navLabelController.clear();
    });
  }

  Future<void> _savePage() async {
    if (_titleController.text.isEmpty || _slugController.text.isEmpty) {
      _showError('Title and Slug are required');
      return;
    }

    setState(() => _isLoading = true);
    final payload = {
      'title': _titleController.text,
      'slug': _slugController.text,
      'body': {'html': _contentController.text},
      'status': _selectedStatus,
      'show_in_nav': _showInNav,
      'nav_label': _navLabelController.text.isEmpty ? _titleController.text : _navLabelController.text,
    };

    try {
      if (_editingPage == null) {
        // Create new
        await ref.read(apiServiceProvider).createStorefrontPage(payload);
        _showSuccess('Page created successfully!');
      } else {
        // Update
        final pageId = _editingPage['page_id'];
        await ref.read(apiServiceProvider).updateStorefrontPage(pageId, payload);
        _showSuccess('Page updated successfully!');
      }
      _clearForm();
      await _fetchPages();
    } catch (e) {
      _showError('Failed to save page: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePage(String pageId) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(apiServiceProvider).deleteStorefrontPage(pageId);
      _showSuccess('Page deleted successfully!');
      _clearForm();
      await _fetchPages();
    } catch (e) {
      _showError('Failed to delete page: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
                      'Store Pages',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Create and manage static informational pages for your shop (e.g. About, FAQ, Contact)',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                if (_editingPage != null)
                  HoverScale(
                    child: ElevatedButton.icon(
                      onPressed: _clearForm,
                      icon: const Icon(LucideIcons.plus, size: 14),
                      label: const Text('New Page'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandEmerald500,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Main split UI
          Expanded(
            child: Row(
              children: [
                // Left pane: list of pages
                Expanded(
                  flex: 3,
                  child: _isLoading && _pages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _pages.length,
                          itemBuilder: (context, index) {
                            final page = _pages[index];
                            final isEditing = _editingPage != null && _editingPage['page_id'] == page['page_id'];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isEditing ? AppTheme.brandEmerald500 : theme.dividerColor,
                                    width: isEditing ? 2 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Row(
                                    children: [
                                      Text(page['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: page['status'] == 'published'
                                              ? AppTheme.brandEmerald500.withOpacity(0.1)
                                              : Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          (page['status'] as String? ?? 'draft').toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: page['status'] == 'published' ? AppTheme.brandEmerald500 : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('Slug: /pages/${page['slug']}', style: TextStyle(color: theme.hintColor, fontSize: 12)),
                                      if (page['show_in_nav'] == true) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(LucideIcons.compass, size: 12, color: AppTheme.brandEmerald500),
                                            const SizedBox(width: 4),
                                            Text('Visible in navigation: "${page['nav_label']}"', style: const TextStyle(fontSize: 11, color: AppTheme.brandEmerald500)),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(LucideIcons.edit, size: 18),
                                        onPressed: () => _startEditing(page),
                                        tooltip: 'Edit page',
                                      ),
                                      IconButton(
                                        icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.redAccent),
                                        onPressed: () => _deletePage(page['page_id']),
                                        tooltip: 'Delete page',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Vertical Divider
                Container(width: 1, color: theme.dividerColor),

                // Right pane: editor form
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
                              _editingPage == null ? 'Create Page' : 'Edit Page',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Page Title',
                                border: OutlineInputBorder(),
                                hintText: 'About Our Brand',
                              ),
                              onChanged: (val) {
                                if (_editingPage == null) {
                                  _slugController.text = val
                                      .toLowerCase()
                                      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
                                      .replaceAll(RegExp(r'\s+'), '-');
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _slugController,
                              decoration: const InputDecoration(
                                labelText: 'URL Slug',
                                border: OutlineInputBorder(),
                                prefixText: '/pages/',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _contentController,
                              maxLines: 8,
                              decoration: const InputDecoration(
                                labelText: 'Page Content (HTML / Text)',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'draft', child: Text('Draft (Hidden)')),
                                DropdownMenuItem(value: 'published', child: Text('Published (Live)')),
                              ],
                              onChanged: (val) => setState(() => _selectedStatus = val!),
                            ),
                            const SizedBox(height: 20),
                            SwitchListTile(
                              title: const Text('Show in Navigation Menus', style: TextStyle(fontSize: 14)),
                              subtitle: const Text('Flag this page to be searchable in link pickers', style: TextStyle(fontSize: 12)),
                              value: _showInNav,
                              activeColor: AppTheme.brandEmerald500,
                              onChanged: (val) => setState(() => _showInNav = val),
                            ),
                            if (_showInNav) ...[
                              const SizedBox(height: 16),
                              TextField(
                                controller: _navLabelController,
                                decoration: const InputDecoration(
                                  labelText: 'Navigation Label Override',
                                  border: OutlineInputBorder(),
                                  hintText: 'About Us',
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: HoverScale(
                                    child: ElevatedButton(
                                      onPressed: _savePage,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.brandEmerald500,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Text(_editingPage == null ? 'Create Page' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                                if (_editingPage != null) ...[
                                  const SizedBox(width: 12),
                                  OutlinedButton(
                                    onPressed: _clearForm,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
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
}
