import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/providers/library_providers.dart';
import 'package:kloudshop/services/api_service.dart';

class ActiveUpload {
  final String fileName;
  double progress;

  ActiveUpload({
    required this.fileName,
    required this.progress,
  });
}

class AssetSelectionDialog extends ConsumerStatefulWidget {
  final String title;
  final bool isMultiSelect;
  final List<String> initialUrls;

  const AssetSelectionDialog({
    super.key,
    required this.title,
    this.isMultiSelect = false,
    this.initialUrls = const [],
  });

  @override
  ConsumerState<AssetSelectionDialog> createState() => _AssetSelectionDialogState();
}

class _AssetSelectionDialogState extends ConsumerState<AssetSelectionDialog> {
  final Set<String> _selectedUrls = {};
  String _searchQuery = '';
  bool _isDragging = false;
  bool _showUploadSuccess = false;
  
  // Active selected view name in the sidebar
  String _activeViewName = 'All images';

  // Search controller to dynamically update query field
  late TextEditingController _searchController;

  // View modes: Thumbnail (Grid), List
  String _viewMode = 'Thumbnail';
  int _zoomLevel = 6; // Zoom level from 3 (smallest) to 8 (largest)
  bool _showZoomPopup = false; // Controls floating zoom slider card visibility

  // Track dragging to select (Mouse selection gesture)
  bool _isDraggingToSelect = false;
  bool _dragSelectToAdd = true;
  String? _lastClickedUrl;

  // Upload status tracking (Parallel uploads list)
  final List<ActiveUpload> _activeUploads = [];

  @override
  void initState() {
    super.initState();
    _selectedUrls.addAll(widget.initialUrls);
    _searchController = TextEditingController(text: _searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String url, List<LibraryAsset> currentList) {
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    
    setState(() {
      if (isShiftPressed && _lastClickedUrl != null) {
        final lastIdx = currentList.indexWhere((a) => a.url == _lastClickedUrl);
        final currentIdx = currentList.indexWhere((a) => a.url == url);
        if (lastIdx != -1 && currentIdx != -1) {
          final start = lastIdx < currentIdx ? lastIdx : currentIdx;
          final end = lastIdx < currentIdx ? currentIdx : lastIdx;
          
          final shouldSelect = !_selectedUrls.contains(url);
          for (int i = start; i <= end; i++) {
            final targetUrl = currentList[i].url;
            if (shouldSelect) {
              _selectedUrls.add(targetUrl);
            } else {
              _selectedUrls.remove(targetUrl);
            }
          }
        }
      } else {
        // Multi-selection is always enabled inside the dialog for bulk operations / views saving.
        // We only enforce single vs multi selection output when the user clicks 'Done'.
        if (_selectedUrls.contains(url)) {
          _selectedUrls.remove(url);
        } else {
          _selectedUrls.add(url);
        }
      }
      _lastClickedUrl = url;
    });
  }

  Future<void> _uploadSingleFile(String fileName, Future<Uint8List> bytesFuture) async {
    final upload = ActiveUpload(fileName: fileName, progress: 0.0);
    setState(() {
      _activeUploads.add(upload);
    });

    try {
      final bytes = await bytesFuture;
      
      const totalSteps = 10;
      for (int step = 1; step <= totalSteps; step++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        setState(() {
          upload.progress = step / totalSteps;
        });
      }

      final relativeUrl = await ref.read(apiServiceProvider).uploadMedia(bytes, fileName);
      final fullUrl = relativeUrl.startsWith('http') ? relativeUrl : "http://127.0.0.1:8000$relativeUrl";

      if (mounted) {
        ref.read(libraryImagesProvider.notifier).addImage(
          fullUrl, 
          name: fileName.split('.').first,
          localBytes: bytes,
        );
        setState(() {
          _selectedUrls.add(fullUrl);
          _activeUploads.remove(upload);
          _showUploadSuccess = true;
        });

        // Hide success banner after 4 seconds
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() {
              _showUploadSuccess = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeUploads.remove(upload);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed for $fileName: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final List<XFile> files = await picker.pickMultiImage();
    for (final file in files) {
      _uploadSingleFile(file.name, file.readAsBytes());
    }
  }

  void _showSaveViewDialog() {
    final theme = Theme.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: const Text('Save Current View', style: TextStyle(fontFamily: 'Outfit')),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. Logos, Hero banners, My Selection',
              hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.4), fontSize: 13),
              labelText: 'View Name',
              labelStyle: TextStyle(color: theme.hintColor.withOpacity(0.7), fontSize: 12),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.brandEmerald500),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.dividerColor),
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
                  ref.read(savedViewsProvider.notifier).saveView(
                    name, 
                    _searchQuery,
                    _selectedUrls.toList(),
                  );
                  setState(() {
                    _activeViewName = name;
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandEmerald500),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showRenameViewDialog(String oldName) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: const Text('Rename Saved View', style: TextStyle(fontFamily: 'Outfit')),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: 'View Name',
              labelStyle: TextStyle(color: theme.hintColor.withOpacity(0.7), fontSize: 12),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.brandEmerald500),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.dividerColor),
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
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != oldName) {
                  ref.read(savedViewsProvider.notifier).renameView(oldName, newName);
                  if (_activeViewName == oldName) {
                    setState(() {
                      _activeViewName = newName;
                    });
                  }
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandEmerald500),
              child: const Text('Rename', style: TextStyle(color: Colors.white)),
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
    final libraryAssets = ref.watch(libraryImagesProvider);
    final savedViews = ref.watch(savedViewsProvider);

    // Get active SavedViewConfig mapping
    final activeView = savedViews.firstWhere(
      (v) => v.name == _activeViewName,
      orElse: () => SavedViewConfig(name: 'All images', searchQuery: '', selectedUrls: []),
    );

    // Filter images:
    final filteredAssets = libraryAssets.where((asset) {
      if (_activeViewName == 'All images') {
        if (_searchQuery.isEmpty) return true;
        final query = _searchQuery.toLowerCase();
        return asset.name.toLowerCase().contains(query) ||
            asset.url.split('/').last.toLowerCase().contains(query);
      }

      if (activeView.selectedUrls.isNotEmpty) {
        return activeView.selectedUrls.contains(asset.url);
      }

      final query = (activeView.searchQuery.isNotEmpty ? activeView.searchQuery : _searchQuery).toLowerCase();
      if (query.isEmpty) return true;
      return asset.name.toLowerCase().contains(query) ||
          asset.url.split('/').last.toLowerCase().contains(query);
    }).toList();

    // Check if there are custom saved views to show the "Clear all" button
    final hasCustomViews = savedViews.any((v) => v.name != 'All images');

    // Check if the current search filter or selected urls combination is already saved
    final isCurrentViewSaved = savedViews.any((v) =>
        v.searchQuery == _searchQuery &&
        v.selectedUrls.length == _selectedUrls.length &&
        v.selectedUrls.every(_selectedUrls.contains));

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Listener(
        onPointerUp: (event) {
          if (_isDraggingToSelect) {
            setState(() {
              _isDraggingToSelect = false;
            });
          }
        },
        child: Container(
          width: 950,
          height: 620,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // 1. Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 2. Main Dialog Body
              Expanded(
                child: Row(
                  children: [
                    // Left Sidebar
                    Container(
                      width: 200,
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Store Library Label
                          Row(
                            children: [
                              Icon(LucideIcons.database, size: 14, color: theme.hintColor),
                              const SizedBox(width: 8),
                              Text(
                                'Store library',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Images Tab Link
                          InkWell(
                            onTap: () {
                              setState(() {
                                _activeViewName = 'All images';
                                _searchQuery = '';
                                _searchController.text = '';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: _activeViewName == 'All images'
                                    ? AppTheme.brandEmerald500.withOpacity(0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _activeViewName == 'All images'
                                      ? AppTheme.brandEmerald500.withOpacity(0.2)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.image,
                                        size: 13,
                                        color: _activeViewName == 'All images'
                                            ? AppTheme.brandEmerald500
                                            : theme.hintColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Images',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _activeViewName == 'All images'
                                              ? AppTheme.brandEmerald500
                                              : theme.textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _activeViewName == 'All images'
                                          ? AppTheme.brandEmerald500.withOpacity(0.12)
                                          : theme.dividerColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${libraryAssets.length}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _activeViewName == 'All images'
                                            ? AppTheme.brandEmerald500
                                            : theme.hintColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Saved Views Label with Clear Action
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Saved Views',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.hintColor,
                                ),
                              ),
                              if (hasCustomViews)
                                GestureDetector(
                                  onTap: () {
                                    ref.read(savedViewsProvider.notifier).clearAllCustomViews();
                                    setState(() {
                                      _activeViewName = 'All images';
                                      _searchQuery = '';
                                      _searchController.text = '';
                                    });
                                  },
                                  child: const Text(
                                    'Clear all',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // List saved views
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                ...savedViews.map((view) {
                                  final name = view.name;
                                  final isActive = _activeViewName == name;
                                  final isDefault = name == 'All images';

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _activeViewName = name;
                                        _searchQuery = view.searchQuery;
                                        _searchController.text = view.searchQuery;
                                        
                                        // Load the saved selection list!
                                        if (view.selectedUrls.isNotEmpty) {
                                          _selectedUrls.clear();
                                          _selectedUrls.addAll(view.selectedUrls);
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? AppTheme.brandEmerald500.withOpacity(0.04)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(
                                                  view.selectedUrls.isNotEmpty
                                                      ? LucideIcons.checkSquare
                                                      : LucideIcons.bookmark,
                                                  size: 11,
                                                  color: isActive ? AppTheme.brandEmerald500 : theme.hintColor,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                                      color: isActive ? AppTheme.brandEmerald500 : null,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!isDefault)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GestureDetector(
                                                  onTap: () => _showRenameViewDialog(name),
                                                  child: Icon(
                                                    LucideIcons.pencil,
                                                    size: 11,
                                                    color: isActive ? AppTheme.brandEmerald500 : theme.hintColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                GestureDetector(
                                                  onTap: () {
                                                    ref.read(savedViewsProvider.notifier).removeView(name);
                                                    if (_activeViewName == name) {
                                                      setState(() {
                                                        _activeViewName = 'All images';
                                                        _searchQuery = '';
                                                        _searchController.text = '';
                                                      });
                                                    }
                                                  },
                                                  child: const Icon(LucideIcons.trash2, size: 11, color: Colors.red),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                
                                if ((_searchQuery.isNotEmpty || _selectedUrls.isNotEmpty) && !isCurrentViewSaved) ...[
                                  const SizedBox(height: 12),
                                  InkWell(
                                    onTap: _showSaveViewDialog,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Row(
                                        children: [
                                          const Icon(LucideIcons.plusCircle, size: 12, color: AppTheme.brandEmerald500),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _selectedUrls.isNotEmpty ? 'Save selection as view' : 'Save search as view',
                                              style: const TextStyle(
                                                fontSize: 11, 
                                                color: AppTheme.brandEmerald500, 
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Vertical Divider
                    const VerticalDivider(width: 1),

                    // Right Panel Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Column(
                              children: [
                            // Search & Filter & View mode controls row
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 36,
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: (val) {
                                        setState(() {
                                          _searchQuery = val;
                                          _activeViewName = 'Custom Search';
                                        });
                                      },
                                      style: const TextStyle(fontSize: 12),
                                      decoration: InputDecoration(
                                        hintText: 'Search files',
                                        prefixIcon: const Icon(LucideIcons.search, size: 14),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(LucideIcons.slidersHorizontal, size: 13),
                                  label: const Text('Filter', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(LucideIcons.arrowUpDown, size: 13),
                                  label: const Text('Sort', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                
                                 // View layout mode buttons and zoom slider toggle
                                 Container(
                                   decoration: BoxDecoration(
                                     border: Border.all(color: theme.dividerColor),
                                     borderRadius: BorderRadius.circular(6),
                                   ),
                                   padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                   child: Row(
                                     children: [
                                       IconButton(
                                         icon: Icon(
                                           LucideIcons.layoutGrid, 
                                           color: _viewMode == 'Thumbnail' ? AppTheme.brandEmerald500 : null, 
                                           size: 15,
                                         ),
                                         padding: const EdgeInsets.all(6),
                                         constraints: const BoxConstraints(),
                                         tooltip: 'Grid view',
                                         onPressed: () => setState(() {
                                           _viewMode = 'Thumbnail';
                                         }),
                                       ),
                                       IconButton(
                                         icon: Icon(
                                           LucideIcons.list, 
                                           color: _viewMode == 'List' ? AppTheme.brandEmerald500 : null, 
                                           size: 15,
                                         ),
                                         padding: const EdgeInsets.all(6),
                                         constraints: const BoxConstraints(),
                                         tooltip: 'List view',
                                         onPressed: () => setState(() {
                                           _viewMode = 'List';
                                           _showZoomPopup = false;
                                         }),
                                       ),
                                       if (_viewMode == 'Thumbnail') ...[
                                         const SizedBox(width: 4),
                                         IconButton(
                                           icon: Icon(
                                             LucideIcons.zoomIn, 
                                             color: _showZoomPopup ? AppTheme.brandEmerald500 : null,
                                             size: 15,
                                           ),
                                           padding: const EdgeInsets.all(6),
                                           constraints: const BoxConstraints(),
                                           tooltip: 'Zoom thumbnails',
                                           onPressed: () => setState(() {
                                             _showZoomPopup = !_showZoomPopup;
                                           }),
                                         ),
                                       ],
                                     ],
                                   ),
                                 ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Dashed File Upload Box (Parallel Progress Indicators)
                            DropTarget(
                              onDragDone: (detail) {
                                for (final file in detail.files) {
                                  _uploadSingleFile(file.name, file.readAsBytes());
                                }
                              },
                              onDragEntered: (detail) => setState(() => _isDragging = true),
                              onDragExited: (detail) => setState(() => _isDragging = false),
                              child: Container(
                                width: double.infinity,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: _isDragging
                                      ? AppTheme.brandEmerald500.withOpacity(0.04)
                                      : (isDark ? const Color(0xFF131B2E) : Colors.grey[50]),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _isDragging ? AppTheme.brandEmerald500 : Colors.grey.withOpacity(0.4),
                                    width: _isDragging ? 2.0 : 1.0,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: _activeUploads.isNotEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: ListView.builder(
                                          itemCount: _activeUploads.length,
                                          itemBuilder: (context, index) {
                                            final upload = _activeUploads[index];
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    flex: 3,
                                                    child: Text(
                                                      upload.fileName,
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    flex: 5,
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(2),
                                                      child: LinearProgressIndicator(
                                                        value: upload.progress,
                                                        backgroundColor: theme.dividerColor,
                                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                                          AppTheme.brandEmerald500,
                                                        ),
                                                        minHeight: 4,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${(upload.progress * 100).toInt()}%',
                                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                InkWell(
                                                  onTap: _pickImages,
                                                  child: const Text(
                                                    'Add images',
                                                    style: TextStyle(
                                                      color: AppTheme.brandEmerald500,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      decoration: TextDecoration.underline,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Text(
                                                  'or drag and drop',
                                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Files List or Grid with Drag-Selection
                            Expanded(
                              child: filteredAssets.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No images found in library',
                                        style: TextStyle(color: theme.hintColor),
                                      ),
                                    )
                                  : (_viewMode == 'List'
                                      ? ListView.builder(
                                          itemCount: filteredAssets.length,
                                          itemBuilder: (context, index) {
                                            final asset = filteredAssets[index];
                                            final url = asset.url;
                                            final isSelected = _selectedUrls.contains(url);

                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 6),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppTheme.brandEmerald500.withOpacity(0.04)
                                                    : (isDark ? const Color(0xFF131B2E) : Colors.grey[50]),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppTheme.brandEmerald500
                                                      : Colors.grey.withOpacity(0.2),
                                                ),
                                              ),
                                              child: ListTile(
                                                dense: true,
                                                leading: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Checkbox(
                                                      value: isSelected,
                                                      activeColor: AppTheme.brandEmerald500,
                                                      onChanged: (val) => _toggleSelection(url, filteredAssets),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Icon(LucideIcons.image, size: 16, color: Colors.grey),
                                                  ],
                                                ),
                                                title: _AssetEditableName(
                                                  asset: asset,
                                                  onSubmitted: (newName) {
                                                    ref.read(libraryImagesProvider.notifier).renameAsset(url, newName);
                                                  },
                                                ),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      asset.type,
                                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    IconButton(
                                                      icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.red),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () {
                                                        ref.read(libraryImagesProvider.notifier).removeAsset(url);
                                                        setState(() {
                                                          _selectedUrls.remove(url);
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                onTap: () => _toggleSelection(url, filteredAssets),
                                              ),
                                            );
                                          },
                                        )
                                      : GridView.builder(
                                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 11 - _zoomLevel,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 0.7 + (8.0 - (11 - _zoomLevel)) * 0.03,
                                          ),
                                          itemCount: filteredAssets.length,
                                          itemBuilder: (context, index) {
                                            final asset = filteredAssets[index];
                                            final url = asset.url;
                                            final isSelected = _selectedUrls.contains(url);

                                            return MouseRegion(
                                              onEnter: (_) {
                                                if (_isDraggingToSelect) {
                                                  setState(() {
                                                    if (_dragSelectToAdd) {
                                                      _selectedUrls.add(url);
                                                    } else {
                                                      _selectedUrls.remove(url);
                                                    }
                                                  });
                                                }
                                              },
                                              child: Listener(
                                                onPointerDown: (event) {
                                                  setState(() {
                                                    _isDraggingToSelect = true;
                                                    _dragSelectToAdd = !_selectedUrls.contains(url);
                                                    _toggleSelection(url, filteredAssets);
                                                  });
                                                },
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: isDark ? const Color(0xFF131B2E) : Colors.grey[100],
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(
                                                            color: isSelected
                                                                ? AppTheme.brandEmerald500
                                                                : Colors.grey.withOpacity(0.3),
                                                            width: isSelected ? 2.0 : 1.0,
                                                          ),
                                                        ),
                                                        child: Stack(
                                                          fit: StackFit.expand,
                                                          children: [
                                                            // Image Preview
                                                            ClipRRect(
                                                              borderRadius: BorderRadius.circular(6),
                                                              child: asset.localBytes != null
                                                                  ? Image.memory(
                                                                      asset.localBytes!,
                                                                      fit: BoxFit.cover,
                                                                    )
                                                                  : Image.network(
                                                                      url,
                                                                      fit: BoxFit.cover,
                                                                      errorBuilder: (c, e, s) =>
                                                                          const Icon(LucideIcons.imageOff, color: Colors.grey),
                                                                    ),
                                                            ),
                                                            // Selection Checkbox Overlay (Top-Left)
                                                            Positioned(
                                                              top: 6,
                                                              left: 6,
                                                              child: Container(
                                                                width: 16,
                                                                height: 16,
                                                                decoration: BoxDecoration(
                                                                  color: isSelected
                                                                      ? AppTheme.brandEmerald500
                                                                      : Colors.transparent,
                                                                  border: Border.all(
                                                                    color: isSelected
                                                                        ? AppTheme.brandEmerald500
                                                                        : Colors.white,
                                                                    width: 1.5,
                                                                  ),
                                                                  borderRadius: BorderRadius.circular(3),
                                                                ),
                                                                child: isSelected
                                                                    ? const Icon(
                                                                        LucideIcons.check,
                                                                        size: 11,
                                                                        color: Colors.white,
                                                                      )
                                                                    : null,
                                                              ),
                                                            ),
                                                            // Delete Trash Icon (Top-Right)
                                                            Positioned(
                                                              top: 6,
                                                              right: 6,
                                                              child: CircleAvatar(
                                                                radius: 10,
                                                                backgroundColor: Colors.black54,
                                                                child: IconButton(
                                                                  icon: const Icon(
                                                                    LucideIcons.trash2,
                                                                    size: 11,
                                                                    color: Colors.red,
                                                                  ),
                                                                  padding: EdgeInsets.zero,
                                                                  constraints: const BoxConstraints(),
                                                                  onPressed: () {
                                                                    ref.read(libraryImagesProvider.notifier).removeAsset(url);
                                                                    setState(() {
                                                                      _selectedUrls.remove(url);
                                                                    });
                                                                  },
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    // Image Info Labels with in-place rename field
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: _AssetEditableName(
                                                              asset: asset,
                                                              onSubmitted: (newName) {
                                                                ref.read(libraryImagesProvider.notifier).renameAsset(url, newName);
                                                              },
                                                            ),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            asset.type,
                                                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        )),
                            ),
                              ],
                            ),
                            // Floating zoom slider card popup
                            if (_showZoomPopup && _viewMode == 'Thumbnail')
                              Positioned(
                                top: 40,
                                right: 0,
                                child: Container(
                                  width: 220,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: theme.dividerColor),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Minus Button (Zoom out, makes thumbnails smaller, i.e. increases columns)
                                      IconButton(
                                        icon: const Icon(LucideIcons.minus, size: 14),
                                        onPressed: _zoomLevel > 3
                                            ? () {
                                                setState(() {
                                                  _zoomLevel--;
                                                });
                                              }
                                            : null,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Zoom out (Smaller)',
                                      ),
                                      // Slider
                                      Expanded(
                                        child: SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            trackHeight: 3,
                                            thumbColor: AppTheme.brandEmerald500,
                                            activeTrackColor: AppTheme.brandEmerald500,
                                            inactiveTrackColor: theme.dividerColor,
                                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                          ),
                                          child: Slider(
                                            value: _zoomLevel.toDouble(),
                                            min: 3,
                                            max: 8,
                                            divisions: 5,
                                            onChanged: (val) {
                                              setState(() {
                                                _zoomLevel = val.toInt();
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      // Plus Button (Zoom in, makes thumbnails larger, i.e. decreases columns)
                                      IconButton(
                                        icon: const Icon(LucideIcons.plus, size: 14),
                                        onPressed: _zoomLevel < 8
                                            ? () {
                                                setState(() {
                                                  _zoomLevel++;
                                                });
                                              }
                                            : null,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Zoom in (Larger)',
                                      ),
                                    ],
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

              // 3. Footer Bar / Toast Banner
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: isDark ? const Color(0xFF131B2E) : Colors.grey[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Upload Success Toast Banner
                    AnimatedOpacity(
                      opacity: _showUploadSuccess ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : Colors.black,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.checkCircle2, color: AppTheme.brandEmerald500, size: 14),
                            const SizedBox(width: 8),
                            const Text(
                              'File uploaded',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => setState(() => _showUploadSuccess = false),
                              child: const Icon(LucideIcons.x, color: Colors.grey, size: 12),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actions Cancel / Done
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (widget.isMultiSelect) {
                              Navigator.pop(context, _selectedUrls.toList());
                            } else {
                              Navigator.pop(context, _selectedUrls.isNotEmpty ? _selectedUrls.last : '');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandEmerald500,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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
}

class _AssetEditableName extends StatefulWidget {
  final LibraryAsset asset;
  final void Function(String newName) onSubmitted;

  const _AssetEditableName({
    required this.asset,
    required this.onSubmitted,
  });

  @override
  State<_AssetEditableName> createState() => _AssetEditableNameState();
}

class _AssetEditableNameState extends State<_AssetEditableName> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.asset.name);
  }

  @override
  void didUpdateWidget(covariant _AssetEditableName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.name != widget.asset.name && _controller.text != widget.asset.name) {
      _controller.text = widget.asset.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            setState(() => _isEditing = false);
            widget.onSubmitted(_controller.text.trim());
          }
        },
        child: SizedBox(
          height: 22,
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.brandEmerald500, width: 1.0),
              ),
            ),
            onSubmitted: (val) {
              setState(() => _isEditing = false);
              widget.onSubmitted(val.trim());
            },
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => setState(() => _isEditing = true),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Text(
              widget.asset.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 2),
          const Icon(LucideIcons.pencil, size: 8, color: Colors.grey),
        ],
      ),
    );
  }
}
