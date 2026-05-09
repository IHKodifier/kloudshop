import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/blog.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/providers/blog_providers.dart';

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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post?.title ?? '');
    _slugController = TextEditingController(text: widget.post?.slug ?? '');
    _excerptController = TextEditingController(text: widget.post?.excerpt ?? '');
    _bodyController = TextEditingController(text: widget.post?.body ?? '');
    _status = widget.post?.status ?? 'draft';

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

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _excerptController.dispose();
    _bodyController.dispose();
    super.dispose();
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
          SnackBar(content: Text('Post ${widget.post == null ? 'created' : 'updated'} successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.post != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Post' : 'New Post'),
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: TextButton.icon(
                onPressed: _save,
                icon: const Icon(LucideIcons.save, size: 18),
                label: const Text('Save'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Post Title',
                hintText: 'Enter a catchy title...',
                border: OutlineInputBorder(),
              ),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              validator: (v) => v?.isEmpty ?? true ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(
                labelText: 'Slug',
                hintText: 'post-url-slug',
                prefixText: 'blog/',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Slug is required' : null,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Publication Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'draft', child: Text('Draft')),
                DropdownMenuItem(value: 'published', child: Text('Published')),
                DropdownMenuItem(value: 'archived', child: Text('Archived')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _excerptController,
              decoration: const InputDecoration(
                labelText: 'Excerpt',
                hintText: 'A short summary for the post list...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Body Content',
                hintText: 'Write your post here...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 15,
              validator: (v) => v?.isEmpty ?? true ? 'Body content is required' : null,
            ),
          ],
        ),
      ),
    );
  }
}
