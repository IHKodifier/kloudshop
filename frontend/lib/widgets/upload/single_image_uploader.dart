import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/services/file_uploader.dart';

class SingleImageUploader extends StatefulWidget {
  final String? imageUrl;
  final FileUploader uploader;
  final ValueChanged<String> onUploadCompleted;
  final VoidCallback onImageRemoved;
  final String label;

  const SingleImageUploader({
    super.key,
    this.imageUrl,
    required this.uploader,
    required this.onUploadCompleted,
    required this.onImageRemoved,
    this.label = 'Upload Image',
  });

  @override
  State<SingleImageUploader> createState() => _SingleImageUploaderState();
}

class _SingleImageUploaderState extends State<SingleImageUploader> {
  bool _isDragging = false;
  double? _uploadProgress;
  String? _activeUploadId;

  void _startUpload(String fileName, Future<Uint8List> bytesFuture) {
    final String uploadId =
        "${DateTime.now().millisecondsSinceEpoch}_$fileName";
    setState(() {
      _activeUploadId = uploadId;
      _uploadProgress = 0.0;
    });

    Future.microtask(() async {
      try {
        final bytes = await bytesFuture;
        final url = await widget.uploader.upload(
          fileName: fileName,
          bytes: bytes,
          onProgress: (progress) {
            if (!mounted || _activeUploadId != uploadId) return;
            setState(() {
              _uploadProgress = progress;
            });
          },
        );

        if (mounted && _activeUploadId == uploadId) {
          widget.onUploadCompleted(url);
          setState(() {
            _uploadProgress = null;
            _activeUploadId = null;
          });
        }
      } catch (e) {
        if (mounted && _activeUploadId == uploadId) {
          setState(() {
            _uploadProgress = null;
            _activeUploadId = null;
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

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    _startUpload(file.name, file.readAsBytes());
  }

  void _cancelUpload() {
    setState(() {
      _uploadProgress = null;
      _activeUploadId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_uploadProgress != null) {
      // Show uploading state
      return Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.fileImage,
                    size: 32,
                    color: AppTheme.brandEmerald500,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Uploading cover image...',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: theme.dividerColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.brandEmerald500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${((_uploadProgress ?? 0.0) * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.hintColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                child: IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    size: 14,
                    color: theme.iconTheme.color,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: _cancelUpload,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.imageUrl != null) {
      // Show preview state
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 160,
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerLow,
              child: Image.network(
                widget.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    LucideIcons.imageOff,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickAndUpload,
                  icon: const Icon(LucideIcons.upload, size: 14),
                  label: const Text('Change Image'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: widget.onImageRemoved,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                child: const Icon(LucideIcons.trash2, size: 14),
              ),
            ],
          ),
        ],
      );
    }

    // Show empty / dropzone state
    return DropTarget(
      onDragDone: (detail) {
        if (detail.files.isNotEmpty) {
          final file = detail.files.first;
          _startUpload(file.name, file.readAsBytes());
        }
      },
      onDragEntered: (detail) {
        setState(() => _isDragging = true);
      },
      onDragExited: (detail) {
        setState(() => _isDragging = false);
      },
      child: GestureDetector(
        onTap: _pickAndUpload,
        child: Container(
          width: double.infinity,
          height: 160,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isDragging ? LucideIcons.uploadCloud : LucideIcons.imagePlus,
                size: 36,
                color: _isDragging ? AppTheme.brandEmerald500 : theme.hintColor,
              ),
              const SizedBox(height: 12),
              Text(
                _isDragging
                    ? 'Drop image here!'
                    : 'Drag & drop or tap to select',
                style: TextStyle(
                  color: _isDragging
                      ? AppTheme.brandEmerald500
                      : theme.hintColor,
                  fontSize: 12,
                  fontWeight: _isDragging ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
