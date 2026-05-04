import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/providers/blog_providers.dart';
import 'package:kloudshop/models/blog.dart';
import 'package:intl/intl.dart';
import 'package:kloudshop/views/blog_post_editor.dart';

import 'package:kloudshop/models/user_claims.dart';
import 'package:kloudshop/services/api_service.dart';

class BlogView extends ConsumerWidget {
  final UserClaims claims;
  const BlogView({super.key, required this.claims});

  void _navigateToEditor(BuildContext context, WidgetRef ref, [BlogPost? post]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BlogPostEditor(post: post)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(blogPostsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Management'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _navigateToEditor(context, ref),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('New Post'),
            ),
          ),
        ],
      ),
      body: postsAsync.when(
        data: (posts) => posts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.bookOpen, size: 64, color: theme.hintColor),
                    const SizedBox(height: 16),
                    Text('No blog posts yet', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    const Text('Start sharing your stories with your customers.'),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: posts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _PostCard(post: post, onEdit: () => _navigateToEditor(context, ref, post));
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final BlogPost post;
  final VoidCallback onEdit;
  const _PostCard({required this.post, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDraft = post.status == 'draft';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.coverImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post.coverImageUrl!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: theme.dividerColor,
                  child: const Icon(LucideIcons.image),
                ),
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.image),
            ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _StatusBadge(status: post.status ?? 'draft'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  post.excerpt ?? 'No excerpt provided.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 14, color: theme.hintColor),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, y').format(post.createdAt),
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                    const SizedBox(width: 16),
                    if (post.categories.isNotEmpty) ...[
                      Icon(LucideIcons.tag, size: 14, color: theme.hintColor),
                      const SizedBox(width: 4),
                      Text(
                        post.categories.map((c) => c.name).join(', '),
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(LucideIcons.edit, size: 20),
                tooltip: 'Edit Post',
              ),
              Consumer(
                builder: (context, ref, child) => IconButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Post'),
                        content: const Text('Are you sure you want to delete this post?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      try {
                        await ref.read(apiServiceProvider).deleteBlogPost(post.id);
                        ref.invalidate(blogPostsProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(LucideIcons.trash2, size: 20, color: Colors.redAccent),
                  tooltip: 'Delete Post',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPublished = status == 'published';
    final color = isPublished ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
