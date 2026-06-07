import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/services/file_uploader.dart';
import 'package:kloudshop/widgets/hover_scale.dart';

class CompactMediaListUploader extends StatefulWidget {
  final List<String> images;
  final FileUploader uploader;
  final ValueChanged<List<String>> onImagesChanged;

  const CompactMediaListUploader({
    super.key,
    required this.images,
    required this.uploader,
    required this.onImagesChanged,
  });

  @override
  State<CompactMediaListUploader> createState() =>
      _CompactMediaListUploaderState();
}

class _CompactMediaListUploaderState extends State<CompactMediaListUploader> {
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
  void didUpdateWidget(covariant CompactMediaListUploader oldWidget) {
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

  void _startVariantUpload(String fileName, Future<Uint8List> bytesFuture) {
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
        final imageUrl = await widget.uploader.upload(
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
                _localImages!.add(imageUrl);
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

  Future<void> _pickAndUploadVariantImage() async {
    final picker = ImagePicker();
    final List<XFile> files = await picker.pickMultiImage();
    for (final file in files) {
      _startVariantUpload(file.name, file.readAsBytes());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentImages = _localImages ?? widget.images;

    return DropTarget(
      onDragDone: (detail) {
        for (final file in detail.files) {
          _startVariantUpload(file.name, file.readAsBytes());
        }
      },
      onDragEntered: (detail) {
        setState(() => _isDragging = true);
      },
      onDragExited: (detail) {
        setState(() => _isDragging = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isDragging
              ? AppTheme.brandEmerald500.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isDragging ? AppTheme.brandEmerald500 : Colors.transparent,
            width: _isDragging ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            HoverScale(
              child: ElevatedButton.icon(
                onPressed: _pickAndUploadVariantImage,
                icon: const Icon(LucideIcons.upload, size: 14),
                label: const Text('Add', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandEmerald500.withValues(
                    alpha: 0.1,
                  ),
                  foregroundColor: AppTheme.brandEmerald500,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (currentImages.isEmpty && _uploadQueue.isEmpty)
              Expanded(
                child: Text(
                  _isDragging
                      ? 'Drop images here!'
                      : 'No variant specific images (Drag & Drop here)',
                  style: TextStyle(
                    color: _isDragging ? AppTheme.brandEmerald500 : Colors.grey,
                    fontSize: 12,
                    fontWeight: _isDragging
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              )
            else
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: currentImages.length + _uploadQueue.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, vImgIdx) {
                      if (vImgIdx < currentImages.length) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                currentImages[vImgIdx],
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(LucideIcons.imageOff, size: 24),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: CircleAvatar(
                                radius: 8,
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(
                                    LucideIcons.x,
                                    size: 8,
                                    color: Colors.white,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    final updatedList = List<String>.from(
                                      currentImages,
                                    )..removeAt(vImgIdx);
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

                      final qIdx = vImgIdx - currentImages.length;
                      final upload = _uploadQueue[qIdx];
                      final progress = upload['progress'] as double;

                      return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 2,
                                backgroundColor: theme.dividerColor,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.brandEmerald500,
                                ),
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    upload['status'] = 'cancelled';
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(1),
                                  child: const Icon(
                                    LucideIcons.x,
                                    size: 6,
                                    color: Colors.white,
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
              ),
          ],
        ),
      ),
    );
  }
}
