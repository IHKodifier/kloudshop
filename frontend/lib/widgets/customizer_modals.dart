import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/theme/app_theme.dart';

// --- SEARCHABLE ADD SECTION MODAL ---
class SearchableAddSectionModal extends StatefulWidget {
  final ValueChanged<String> onSectionSelected;

  const SearchableAddSectionModal({Key? key, required this.onSectionSelected}) : super(key: key);

  @override
  State<SearchableAddSectionModal> createState() => _SearchableAddSectionModalState();
}

class _SearchableAddSectionModalState extends State<SearchableAddSectionModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _sections = [
    {
      'name': 'Featured collection',
      'desc': 'Display a grid of products from a specific collection.',
      'icon': LucideIcons.grid,
    },
    {
      'name': 'Featured product',
      'desc': 'Feature a single product with detail descriptions.',
      'icon': LucideIcons.tag,
    },
    {
      'name': 'Rich text',
      'desc': 'Add headings, body texts, and action buttons.',
      'icon': LucideIcons.type,
    },
    {
      'name': 'Image with text',
      'desc': 'Pair an image with descriptive text and buttons.',
      'icon': LucideIcons.image,
    },
    {
      'name': 'Image banner',
      'desc': 'Large hero banner with overlay buttons and typography.',
      'icon': LucideIcons.layoutTemplate,
    },
    {
      'name': 'Slideshow',
      'desc': 'A carousel banner cycling through multiple slides.',
      'icon': LucideIcons.sliders,
    },
    {
      'name': 'Collage',
      'desc': 'A beautiful dynamic grid combining images and collections.',
      'icon': LucideIcons.component,
    },
    {
      'name': 'Video',
      'desc': 'Embed a video player card with play buttons.',
      'icon': LucideIcons.playSquare,
    },
    {
      'name': 'Multi-column',
      'desc': 'Display multiple text blocks or cards side-by-side.',
      'icon': LucideIcons.columns,
    },
    {
      'name': 'Multi-row',
      'desc': 'Alternating rows of images and descriptions.',
      'icon': LucideIcons.rows,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = _sections.where((sec) {
      final name = sec['name'].toString().toLowerCase();
      final desc = sec['desc'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || desc.contains(_searchQuery.toLowerCase());
    }).toList();

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Section',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search layout templates...',
                prefixIcon: const Icon(LucideIcons.search, size: 16),
                isDense: true,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No matching templates found',
                        style: TextStyle(color: theme.hintColor, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final sec = filtered[index];
                        return Card(
                          elevation: 0,
                          color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF8FAFC),
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
                          ),
                          child: InkWell(
                            onTap: () {
                              widget.onSectionSelected(sec['name']);
                              Navigator.of(context).pop();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppTheme.brandEmerald500.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(sec['icon'] as IconData, color: AppTheme.brandEmerald500, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sec['name'],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          sec['desc'],
                                          style: TextStyle(color: theme.hintColor, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(LucideIcons.chevronRight, size: 16, color: theme.hintColor),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SEARCHABLE ADD BLOCK MODAL ---
class SearchableAddBlockModal extends StatefulWidget {
  final ValueChanged<String> onBlockSelected;

  const SearchableAddBlockModal({Key? key, required this.onBlockSelected}) : super(key: key);

  @override
  State<SearchableAddBlockModal> createState() => _SearchableAddBlockModalState();
}

class _SearchableAddBlockModalState extends State<SearchableAddBlockModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _blocks = [
    {
      'name': 'Menu',
      'desc': 'Insert a navigation link list menu block.',
      'icon': LucideIcons.menu,
    },
    {
      'name': 'Brand information',
      'desc': 'Introduce your brand with a logo, text, or social icons.',
      'icon': LucideIcons.info,
    },
    {
      'name': 'Text',
      'desc': 'Add custom rich text headings or paragraphs.',
      'icon': LucideIcons.type,
    },
    {
      'name': 'Image',
      'desc': 'Showcase a graphic or photography asset block.',
      'icon': LucideIcons.image,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = _blocks.where((b) {
      final name = b['name'].toString().toLowerCase();
      final desc = b['desc'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || desc.contains(_searchQuery.toLowerCase());
    }).toList();

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Block / Section Element',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search block types...',
                prefixIcon: const Icon(LucideIcons.search, size: 16),
                isDense: true,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No matching blocks found',
                        style: TextStyle(color: theme.hintColor, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final b = filtered[index];
                        return Card(
                          elevation: 0,
                          color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF8FAFC),
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
                          ),
                          child: InkWell(
                            onTap: () {
                              widget.onBlockSelected(b['name']);
                              Navigator.of(context).pop();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppTheme.brandEmerald500.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(b['icon'] as IconData, color: AppTheme.brandEmerald500, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          b['name'],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          b['desc'],
                                          style: TextStyle(color: theme.hintColor, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(LucideIcons.chevronRight, size: 16, color: theme.hintColor),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CENTRALIZED MEDIA LIBRARY DRAW_MODAL ---
class SearchableMediaLibraryModal extends StatefulWidget {
  final ValueChanged<String> onImageSelected;

  const SearchableMediaLibraryModal({Key? key, required this.onImageSelected}) : super(key: key);

  @override
  State<SearchableMediaLibraryModal> createState() => _SearchableMediaLibraryModalState();
}

class _SearchableMediaLibraryModalState extends State<SearchableMediaLibraryModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _defaultMedia = [
    {
      'id': 'dawn_logo',
      'name': 'Dawn Logo',
      'url': 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=200',
    },
    {
      'id': 'banner_graphic',
      'name': 'Banner Graphic',
      'url': 'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=800',
    },
    {
      'id': 'hoodie_coll',
      'name': 'Hoodie Collection Cover',
      'url': 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=500',
    },
    {
      'id': 'shorts_coll',
      'name': 'Shorts Collection Cover',
      'url': 'https://images.unsplash.com/photo-1591195853828-11db59a44f6b?w=500',
    },
    {
      'id': 'tshirt_coll',
      'name': 'Tshirt Collection Cover',
      'url': 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=500',
    },
    {
      'id': 'illustrated_shirt_1',
      'name': 'Illustrated Graphic Tee',
      'url': 'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=500',
    },
    {
      'id': 'illustrated_shirt_2',
      'name': 'Retro Long Sleeve',
      'url': 'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?w=500',
    },
    {
      'id': 'illustrated_shirt_3',
      'name': 'Oversized Vintage Hoodie',
      'url': 'https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=500',
    },
  ];

  late List<Map<String, String>> _mediaItems;

  @override
  void initState() {
    super.initState();
    _mediaItems = List.from(_defaultMedia);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _simulateUpload() {
    final uploadNum = _mediaItems.length - _defaultMedia.length + 1;
    setState(() {
      _mediaItems.add({
        'id': 'uploaded_$uploadNum',
        'name': 'Uploaded Asset #$uploadNum',
        'url': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=500',
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulated file upload complete!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = _mediaItems.where((item) {
      return item['name']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Media Library',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search files in library...',
                prefixIcon: const Icon(LucideIcons.search, size: 16),
                isDense: true,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text('No media items found', style: TextStyle(color: theme.hintColor)),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {
                              widget.onImageSelected(item['url']!);
                              Navigator.of(context).pop();
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  item['url']!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.brandEmerald500),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stack) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.grey.shade400, Colors.grey.shade600],
                                        ),
                                      ),
                                      child: const Icon(LucideIcons.imageOff, color: Colors.white),
                                    );
                                  },
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    color: Colors.black.withOpacity(0.6),
                                    child: Text(
                                      item['name']!,
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: _simulateUpload,
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B).withOpacity(0.3) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.brandEmerald500.withOpacity(0.5), style: BorderStyle.values[1]),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.uploadCloud, color: AppTheme.brandEmerald500, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Drag & drop or Click to simulate mock file upload',
                        style: TextStyle(color: AppTheme.brandEmerald500, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- COLLECTION BINDER PANEL/MODAL ---
class CollectionBinderModal extends StatefulWidget {
  final Function(String id, String name, String imageUrl) onCollectionSelected;

  const CollectionBinderModal({Key? key, required this.onCollectionSelected}) : super(key: key);

  @override
  State<CollectionBinderModal> createState() => _CollectionBinderModalState();
}

class _CollectionBinderModalState extends State<CollectionBinderModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _collections = [
    {
      'id': 'home',
      'name': 'Home page',
      'url': 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=500',
    },
    {
      'id': 'hoodies',
      'name': 'Hoodies',
      'url': 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=500',
    },
    {
      'id': 'shorts',
      'name': 'Shorts',
      'url': 'https://images.unsplash.com/photo-1591195853828-11db59a44f6b?w=500',
    },
    {
      'id': 'tshirts',
      'name': 'T-shirts',
      'url': 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=500',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _createNewCollection() {
    final TextEditingController newColController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Collection'),
          content: TextField(
            controller: newColController,
            decoration: const InputDecoration(
              hintText: 'e.g. Winter Wear',
              labelText: 'Collection Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = newColController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _collections.add({
                      'id': name.toLowerCase().replaceAll(' ', '_'),
                      'name': name,
                      'url': 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=500',
                    });
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = _collections.where((col) {
      return col['name']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Collection',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search collections...',
                      prefixIcon: const Icon(LucideIcons.search, size: 16),
                      isDense: true,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _createNewCollection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandEmerald500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  icon: const Icon(LucideIcons.plus, size: 14),
                  label: const Text('Create', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text('No collections found', style: TextStyle(color: theme.hintColor)),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final col = filtered[index];
                        return Card(
                          elevation: 0,
                          color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF8FAFC),
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
                          ),
                          child: InkWell(
                            onTap: () {
                              widget.onCollectionSelected(col['id']!, col['name']!, col['url']!);
                              Navigator.of(context).pop();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      col['url']!,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      col['name']!,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  Icon(LucideIcons.chevronRight, size: 16, color: theme.hintColor),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
