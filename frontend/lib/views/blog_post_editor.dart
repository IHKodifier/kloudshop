import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/blog.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/providers/blog_providers.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';
import 'package:image_picker/image_picker.dart';

class BlogPostEditor extends ConsumerStatefulWidget {
  final BlogPost? post;
  const BlogPostEditor({super.key, this.post});

  @override
  ConsumerState<BlogPostEditor> createState() => _BlogPostEditorState();
}

class _BlogPostEditorState extends ConsumerState<BlogPostEditor> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _slugController;
  late TextEditingController _excerptController;
  late TextEditingController _bodyController;
  String _status = 'draft';
  String? _coverImageUrl;
  bool _isSubmitting = false;
  bool _isUploadingCover = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post?.title ?? '');
    _slugController = TextEditingController(text: widget.post?.slug ?? '');
    _excerptController = TextEditingController(text: widget.post?.excerpt ?? '');
    _bodyController = TextEditingController(text: widget.post?.body ?? '');
    _status = widget.post?.status ?? 'draft';
    _coverImageUrl = widget.post?.coverImageUrl;

    _titleController.addListener(_updateSlug);
  }

  void _updateSlug() {
    if (widget.post == null) {
      final slug = _titleController.text
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '-');
      _slugController.text = slug;
    }
  }

  void _applyFormat(String prefix, String suffix) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    if (selection.start == -1 || selection.end == -1) {
      final newText = text + prefix + suffix;
      _bodyController.text = newText;
      return;
    }
    
    final selectedText = text.substring(selection.start, selection.end);
    final newText = text.replaceRange(selection.start, selection.end, '$prefix$selectedText$suffix');
    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + prefix.length + selectedText.length + suffix.length),
    );
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateSlug);
    _titleController.dispose();
    _slugController.dispose();
    _excerptController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadCover() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isUploadingCover = true);
    try {
      final bytes = await file.readAsBytes();
      final url = await ref.read(apiServiceProvider).uploadMedia(bytes, file.name);
      setState(() {
        _coverImageUrl = "http://127.0.0.1:8000$url";
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cover image uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final api = ref.read(apiServiceProvider);
      final data = {
        'title': _titleController.text,
        'slug': _slugController.text,
        'excerpt': _excerptController.text,
        'body': _bodyController.text,
        'status': _status,
        'cover_image_url': _coverImageUrl,
      };

      if (widget.post == null) {
        await api.createBlogPost(data);
      } else {
        await api.updateBlogPost(widget.post!.id, data);
      }

      if (mounted) {
        ref.invalidate(blogPostsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post ${widget.post == null ? 'created' : 'updated'} successfully'),
            backgroundColor: AppTheme.brandEmerald600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'), 
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.post == null ? 'Create New Post' : 'Edit Blog Post', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: theme.dividerColor, height: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('Discard'),
                ),
                const SizedBox(width: 12),
                HoverScale(
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _save,
                    icon: _isSubmitting 
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(LucideIcons.save, size: 14, color: Colors.white),
                    label: const Text('Save Post', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandEmerald500,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column - Editor Area
              Expanded(
                flex: isDesktop ? 8 : 12,
                child: Column(
                  children: [
                    _buildGlassCard(
                      title: 'Story Editor',
                      icon: LucideIcons.fileEdit,
                      color: AppTheme.brandEmerald500,
                      isDark: isDark,
                      theme: theme,
                      children: [
                        // Post Title Input
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Post Title',
                            hintText: 'Enter a catchy title...',
                            border: OutlineInputBorder(),
                          ),
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          validator: (v) => v?.isEmpty ?? true ? 'Title is required' : null,
                        ),
                        const SizedBox(height: 20),
                        
                        // Slug Input
                        TextFormField(
                          controller: _slugController,
                          decoration: const InputDecoration(
                            labelText: 'Slug URL',
                            hintText: 'post-url-slug',
                            prefixText: 'blog/',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'Slug is required' : null,
                        ),
                        const SizedBox(height: 20),
                        
                        // Excerpt Input
                        TextFormField(
                          controller: _excerptController,
                          decoration: const InputDecoration(
                            labelText: 'Excerpt Summary',
                            hintText: 'Brief summary for post listings...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Main Editor Content & Toolbars
                    _buildGlassCard(
                      title: 'Article Body',
                      icon: LucideIcons.bookOpen,
                      color: const Color(0xFF6366F1),
                      isDark: isDark,
                      theme: theme,
                      children: [
                        // Mock WYSIWYG Editor Toolbar
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Row(
                            children: [
                              _buildToolbarIcon(LucideIcons.bold, 'Bold', () => _applyFormat('**', '**')),
                              _buildToolbarIcon(LucideIcons.italic, 'Italic', () => _applyFormat('*', '*')),
                              _buildToolbarIcon(LucideIcons.underline, 'Underline', () => _applyFormat('<u>', '</u>')),
                              const SizedBox(width: 8),
                              Container(height: 16, width: 1, color: theme.dividerColor),
                              const SizedBox(width: 8),
                              _buildToolbarIcon(LucideIcons.alignLeft, 'Align Left', () => _applyFormat('<p align="left">', '</p>')),
                              _buildToolbarIcon(LucideIcons.alignCenter, 'Align Center', () => _applyFormat('<p align="center">', '</p>')),
                              _buildToolbarIcon(LucideIcons.alignRight, 'Align Right', () => _applyFormat('<p align="right">', '</p>')),
                              const SizedBox(width: 8),
                              Container(height: 16, width: 1, color: theme.dividerColor),
                              const SizedBox(width: 8),
                              _buildToolbarIcon(LucideIcons.link, 'Insert Link', () => _applyFormat('[', '](https://)')),
                              _buildToolbarIcon(LucideIcons.image, 'Insert Image', () => _applyFormat('![', '](image_url)')),
                              _buildToolbarIcon(LucideIcons.code, 'Code Block', () => _applyFormat('\n```\n', '\n```\n')),
                            ],
                          ),
                        ),
                        
                        // Editor Textarea
                        TextFormField(
                          controller: _bodyController,
                          maxLines: 15,
                          decoration: InputDecoration(
                            hintText: 'Start writing your story here...',
                            border: OutlineInputBorder(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                              borderSide: BorderSide(color: theme.dividerColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                              borderSide: BorderSide(color: theme.dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                              borderSide: const BorderSide(color: AppTheme.brandEmerald500, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'Body content is required' : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Right Column - Meta & Publishing Sidebar
              if (isDesktop) ...[
                const SizedBox(width: 32),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      // Publishing Settings Card
                      _buildGlassCard(
                        title: 'Publish Settings',
                        icon: LucideIcons.send,
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
                        theme: theme,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _status,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppTheme.brandEmerald500, width: 1.5),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'draft', child: Text('Draft')),
                              DropdownMenuItem(value: 'published', child: Text('Published')),
                              DropdownMenuItem(value: 'archived', child: Text('Archived')),
                            ],
                            onChanged: (v) => setState(() => _status = v!),
                          ),
                          const SizedBox(height: 20),
                          const _ReadOnlyRow(label: 'Author', value: 'Store Admin'),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Featured Cover Image Card
                      _buildGlassCard(
                        title: 'Cover Image',
                        icon: LucideIcons.image,
                        color: const Color(0xFFEC4899),
                        isDark: isDark,
                        theme: theme,
                        children: [
                          if (_coverImageUrl != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 160,
                                width: double.infinity,
                                color: theme.colorScheme.surfaceContainerLow,
                                child: Image.network(_coverImageUrl!, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isUploadingCover ? null : _pickAndUploadCover,
                              icon: _isUploadingCover
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(LucideIcons.upload, size: 14),
                              label: Text(_coverImageUrl == null ? 'Upload Cover Image' : 'Change Image'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required ThemeData theme,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarIcon(IconData icon, String tooltip, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onTap,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          hoverColor: theme.primaryColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
