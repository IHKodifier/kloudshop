import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/catalog.dart';
import 'package:kloudshop/providers/catalog_providers.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/views/product_editor_view.dart';

class CatalogView extends ConsumerStatefulWidget {
  const CatalogView({super.key});

  @override
  ConsumerState<CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends ConsumerState<CatalogView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(filteredProductsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Catalog'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showCreateProductDialog(context),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('New Product'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products by title or slug...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => ref.read(productSearchQueryProvider.notifier).setQuery(value),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) => products.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: products.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _ProductCard(product: products[index]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.shoppingCart, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('No products found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Start by adding your first product to the catalog.'),
        ],
      ),
    );
  }

  Future<void> _showCreateProductDialog(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductEditorView()),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final variantCount = product.variants.length;
    final minPrice = product.variants.isEmpty 
        ? 0.0 
        : product.variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProductEditorView(product: product)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  product.isDigital ? LucideIcons.fileDigit : LucideIcons.package,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          product.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(status: product.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '/${product.slug}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _InfoChip(label: '$variantCount variants', icon: LucideIcons.layers),
                        const SizedBox(width: 12),
                        _InfoChip(label: 'From \$${minPrice.toStringAsFixed(2)}', icon: LucideIcons.tag),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.edit, size: 20),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProductEditorView(product: product)),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 20, color: Colors.redAccent),
                    onPressed: () async {
                      final confirmed = await _showDeleteConfirm(context);
                      if (confirmed == true) {
                        try {
                          await ref.read(apiServiceProvider).deleteProduct(product.id);
                          ref.invalidate(productsProvider);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.title}"? This will also remove all variants.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        break;
      case 'archived':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

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

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.hintColor),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
