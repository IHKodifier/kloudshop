import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/catalog.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/providers/catalog_providers.dart';

class ProductEditorView extends ConsumerStatefulWidget {
  final Product? product; // null if creating new
  const ProductEditorView({super.key, this.product});

  @override
  ConsumerState<ProductEditorView> createState() => _ProductEditorViewState();
}

class _ProductEditorViewState extends ConsumerState<ProductEditorView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _slugController;
  late TextEditingController _descriptionController;
  late String _status;
  late bool _isDigital;
  
  final List<Map<String, dynamic>> _variants = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product?.title ?? '');
    _slugController = TextEditingController(text: widget.product?.slug ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _status = widget.product?.status ?? 'draft';
    _isDigital = widget.product?.isDigital ?? false;
    
    if (widget.product != null) {
      for (var v in widget.product!.variants) {
        _variants.add({
          'sku': v.sku,
          'price': v.price.toString(),
          'stock': v.stock?.toString() ?? '0',
          'is_default': v.isDefault,
        });
      }
    } else {
      // Add a default variant
      _addVariant();
    }
  }

  void _addVariant() {
    setState(() {
      _variants.add({
        'sku': '',
        'price': '0.00',
        'stock': '100',
        'is_default': _variants.isEmpty,
      });
    });
  }

  void _removeVariant(int index) {
    if (_variants.length > 1) {
      setState(() {
        _variants.removeAt(index);
        if (!_variants.any((v) => v['is_default'] == true)) {
          _variants[0]['is_default'] = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final apiService = ref.read(apiServiceProvider);
    
    final productData = {
      'title': _titleController.text,
      'slug': _slugController.text,
      'description': _descriptionController.text,
      'status': _status,
      'is_digital': _isDigital,
      'variants': _variants.map((v) => {
        'sku': v['sku'],
        'price': double.tryParse(v['price']) ?? 0.0,
        'stock': int.tryParse(v['stock']) ?? 0,
        'is_default': v['is_default'],
      }).toList(),
    };

    try {
      if (widget.product == null) {
        await apiService.createProduct(productData);
      } else {
        // TODO: Update product API
      }
      ref.invalidate(productsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'New Product' : 'Edit Product'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save Product'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGeneralInfo(theme),
              const SizedBox(height: 32),
              _buildVariantsSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralInfo(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('General Information', style: theme.textTheme.titleLarge),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Product Title',
                hintText: 'e.g. Classic Cotton T-Shirt',
              ),
              validator: (v) => v?.isEmpty == true ? 'Title is required' : null,
              onChanged: (v) {
                if (_slugController.text.isEmpty || _slugController.text == _titleController.text.toLowerCase().replaceAll(' ', '-')) {
                   _slugController.text = v.toLowerCase().replaceAll(' ', '-');
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(
                labelText: 'URL Slug',
                prefixText: '/products/',
              ),
              validator: (v) => v?.isEmpty == true ? 'Slug is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'draft', child: Text('Draft')),
                      DropdownMenuItem(value: 'archived', child: Text('Archived')),
                    ],
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Digital Product'),
                    value: _isDigital,
                    onChanged: (v) => setState(() => _isDigital = v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Variants & Pricing', style: theme.textTheme.titleLarge),
            TextButton.icon(
              onPressed: _addVariant,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add Variant'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _variants.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final variant = _variants[index];
            return Card(
              color: theme.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: variant['sku'],
                        decoration: const InputDecoration(labelText: 'SKU'),
                        onChanged: (v) => variant['sku'] = v,
                        validator: (v) => v?.isEmpty == true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: variant['price'],
                        decoration: const InputDecoration(labelText: 'Price', prefixText: '\$'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => variant['price'] = v,
                        validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: variant['stock'],
                        decoration: const InputDecoration(labelText: 'Stock'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => variant['stock'] = v,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
                      onPressed: () => _removeVariant(index),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
