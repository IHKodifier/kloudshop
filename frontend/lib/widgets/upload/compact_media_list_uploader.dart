import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/services/file_uploader.dart';

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

    final Color dropBgColor = _isDragging
        ? AppTheme.brandEmerald500.withValues(alpha: 0.05)
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));
    final Color dropBorderColor = _isDragging
        ? AppTheme.brandEmerald500
        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1));

    if (currentImages.isEmpty && _uploadQueue.isEmpty) {
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
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _pickAndUploadVariantImage,
            child: CustomPaint(
              painter: DashedBorderPainter(
                color: dropBorderColor,
                strokeWidth: _isDragging ? 2.0 : 1.2,
                borderRadius: 12.0,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                decoration: BoxDecoration(
                  color: dropBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isDragging ? LucideIcons.uploadCloud : LucideIcons.imagePlus,
                      size: 32,
                      color: _isDragging ? AppTheme.brandEmerald500 : theme.hintColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isDragging
                          ? 'Drop files to upload!'
                          : 'Drag and drop or upload variant images',
                      style: TextStyle(
                        color: _isDragging ? AppTheme.brandEmerald500 : theme.hintColor,
                        fontSize: 12,
                        fontWeight: _isDragging ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isDragging ? AppTheme.brandEmerald500.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDragging ? AppTheme.brandEmerald500 : Colors.transparent,
            width: _isDragging ? 1.5 : 0.0,
          ),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (int i = 0; i < currentImages.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      currentImages[i],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                        child: const Icon(LucideIcons.imageOff, size: 28),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(
                          LucideIcons.x,
                          size: 10,
                          color: Colors.white,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          final updatedList = List<String>.from(currentImages)..removeAt(i);
                          setState(() {
                            _localImages = updatedList;
                          });
                          widget.onImagesChanged(updatedList);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            for (int i = 0; i < _uploadQueue.length; i++)
              (() {
                final upload = _uploadQueue[i];
                final progress = upload['progress'] as double;
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 3,
                          backgroundColor: theme.dividerColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.brandEmerald500,
                          ),
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
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
                            padding: const EdgeInsets.all(2),
                            child: const Icon(
                              LucideIcons.x,
                              size: 8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }()),
            // Prominent dash uploader tile
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _pickAndUploadVariantImage,
                child: CustomPaint(
                  painter: DashedBorderPainter(
                    color: dropBorderColor,
                    strokeWidth: 1.2,
                    borderRadius: 8.0,
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0D251A).withValues(alpha: 0.3) : const Color(0xFFEBFDF2).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.plus,
                      size: 28,
                      color: AppTheme.brandEmerald500.withValues(alpha: 0.8),
                    ),
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

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashPath = Path();
    double distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        final len = dashLength;
        final nextDistance = distance + len;
        dashPath.addPath(
          pathMetric.extractPath(distance, nextDistance.clamp(0.0, pathMetric.length)),
          Offset.zero,
        );
        distance = nextDistance + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}
