import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/services/file_uploader.dart';
import 'package:kloudshop/widgets/upload/asset_selection_dialog.dart';

class MediaGalleryUploader extends StatefulWidget {
  final List<String> images;
  final FileUploader uploader;
  final ValueChanged<List<String>> onImagesChanged;

  const MediaGalleryUploader({
    super.key,
    required this.images,
    required this.uploader,
    required this.onImagesChanged,
  });

  @override
  State<MediaGalleryUploader> createState() => _MediaGalleryUploaderState();
}

class _MediaGalleryUploaderState extends State<MediaGalleryUploader> {
  bool _isDragging = false;
  final List<Map<String, dynamic>> _uploadQueue = [];
  List<String>? _localImages;
  int _uploadCounter = 0;

  @override
  void initState() {
    super.initState();
    _localImages = List<String>.from(widget.images);
  }

  @override
  void didUpdateWidget(covariant MediaGalleryUploader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.images != oldWidget.images) {
      final newLocal = List<String>.from(widget.images);
      if (_uploadQueue.isNotEmpty) {
        for (final img in _localImages ?? []) {
          if (!oldWidget.images.contains(img) && !newLocal.contains(img)) {
            newLocal.add(img);
          }
        }
      }
      _localImages = newLocal;
    }
  }

  void _startMockUpload(String fileName, Future<Uint8List> bytesFuture) {
    final String uploadId =
        "${DateTime.now().millisecondsSinceEpoch}_${_uploadCounter++}_$fileName";

    final Map<String, dynamic> uploadItem = {
      'id': uploadId,
      'fileName': fileName,
      'progress': 0.0,
      'status': 'uploading',
    };

    setState(() {
      _uploadQueue.add(uploadItem);
    });

    Future.microtask(() async {
      try {
        final bytes = await bytesFuture;
        final url = await widget.uploader.upload(
          fileName: fileName,
          bytes: bytes,
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              final idx = _uploadQueue.indexWhere((u) => u['id'] == uploadId);
              if (idx != -1) {
                final item = _uploadQueue[idx];
                if (item['status'] == 'cancelled') return;
                item['progress'] = progress;
              }
            });
          },
        );

        if (mounted) {
          final idx = _uploadQueue.indexWhere((u) => u['id'] == uploadId);
          if (idx != -1) {
            final item = _uploadQueue[idx];
            if (item['status'] != 'cancelled') {
              setState(() {
                _localImages!.add(url);
              });
              widget.onImagesChanged(List<String>.from(_localImages!));
            }
            setState(() {
              _uploadQueue.removeAt(idx);
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _uploadQueue.removeWhere((u) => u['id'] == uploadId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  Future<void> _pickAndUploadImage() async {
    final currentImages = _localImages ?? widget.images;
    showDialog<dynamic>(
      context: context,
      builder: (context) {
        return AssetSelectionDialog(
          title: 'Select Product Images',
          isMultiSelect: true,
          initialUrls: currentImages,
        );
      },
    ).then((selected) {
      if (selected is List<String>) {
        setState(() {
          _localImages = selected;
        });
        widget.onImagesChanged(selected);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentImages = _localImages ?? widget.images;
    final showDropzone = currentImages.isEmpty && _uploadQueue.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Product Images', style: theme.textTheme.titleSmall),
            ElevatedButton.icon(
              onPressed: _pickAndUploadImage,
              icon: const Icon(
                LucideIcons.upload,
                size: 14,
                color: Colors.white,
              ),
              label: const Text(
                'Add Image',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandEmerald500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (showDropzone)
          DropTarget(
            onDragDone: (detail) {
              for (final file in detail.files) {
                _startMockUpload(file.name, file.readAsBytes());
              }
            },
            onDragEntered: (detail) {
              setState(() => _isDragging = true);
            },
            onDragExited: (detail) {
              setState(() => _isDragging = false);
            },
            child: GestureDetector(
              onTap: _pickAndUploadImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: _isDragging
                      ? AppTheme.brandEmerald500.withValues(alpha: 0.05)
                      : (isDark
                            ? const Color(0xFF0F172A)
                            : theme.colorScheme.surfaceContainerLow),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isDragging
                        ? AppTheme.brandEmerald500
                        : theme.dividerColor,
                    width: _isDragging ? 2.0 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isDragging
                          ? LucideIcons.uploadCloud
                          : LucideIcons.imagePlus,
                      size: 40,
                      color: _isDragging
                          ? AppTheme.brandEmerald500
                          : theme.hintColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isDragging
                          ? 'Drop files to upload!'
                          : 'Drag and drop or upload your product visuals',
                      style: TextStyle(
                        color: _isDragging
                            ? AppTheme.brandEmerald500
                            : theme.hintColor,
                        fontSize: 13,
                        fontWeight: _isDragging
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          DropTarget(
            onDragDone: (detail) {
              for (final file in detail.files) {
                _startMockUpload(file.name, file.readAsBytes());
              }
            },
            onDragEntered: (detail) {
              setState(() => _isDragging = true);
            },
            onDragExited: (detail) {
              setState(() => _isDragging = false);
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isDragging
                      ? AppTheme.brandEmerald500
                      : Colors.transparent,
                  width: _isDragging ? 2.0 : 0.0,
                ),
                color: _isDragging
                    ? AppTheme.brandEmerald500.withValues(alpha: 0.02)
                    : Colors.transparent,
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: currentImages.length + _uploadQueue.length + 1,
                itemBuilder: (context, index) {
                  if (index < currentImages.length) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            color: theme.colorScheme.surfaceContainerLow,
                            child: Image.network(
                              currentImages[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    LucideIcons.imageOff,
                                    color: Colors.grey,
                                  ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(
                                LucideIcons.x,
                                size: 14,
                                color: Colors.white,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                final updatedList = List<String>.from(
                                  currentImages,
                                )..removeAt(index);
                                setState(() {
                                  _localImages = updatedList;
                                });
                                widget.onImagesChanged(updatedList);
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final queueIndex = index - currentImages.length;
                  if (queueIndex < _uploadQueue.length) {
                    final upload = _uploadQueue[queueIndex];
                    final progress = upload['progress'] as double;
                    final fileName = upload['fileName'] as String;

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  LucideIcons.fileImage,
                                  size: 28,
                                  color: AppTheme.brandEmerald500,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: theme.dividerColor,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppTheme.brandEmerald500,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.hintColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: Icon(
                                LucideIcons.x,
                                size: 14,
                                color: theme.hintColor,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  upload['status'] = 'cancelled';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GestureDetector(
                    onTap: _pickAndUploadImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isDragging
                              ? AppTheme.brandEmerald500
                              : theme.dividerColor,
                          style: BorderStyle.solid,
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.plus,
                              color: _isDragging
                                  ? AppTheme.brandEmerald500
                                  : theme.hintColor,
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add Image',
                              style: TextStyle(
                                fontSize: 11,
                                color: _isDragging
                                    ? AppTheme.brandEmerald500
                                    : theme.hintColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
