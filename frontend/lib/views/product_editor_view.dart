import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/catalog.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/providers/catalog_providers.dart';
import 'package:image_picker/image_picker.dart';

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
  late TextEditingController _metaTitleController;
  late TextEditingController _metaDescriptionController;
  List<String> _images = [];
  late String _status;
  late bool _isDigital;
  bool _isUploading = false;
  
  final List<Map<String, dynamic>> _variants = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product?.title ?? '');
    _slugController = TextEditingController(text: widget.product?.slug ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _metaTitleController = TextEditingController(text: widget.product?.metaTitle ?? '');
    _metaDescriptionController = TextEditingController(text: widget.product?.metaDescription ?? '');
    _images = List.from(widget.product?.images ?? []);
    
    _status = widget.product?.status ?? 'draft';
    _isDigital = widget.product?.isDigital ?? false;
    
    if (widget.product != null) {
      for (var v in widget.product!.variants) {
        _variants.add({
          'variant_id': v.id,
          'sku': v.sku,
          'price': v.price.toString(),
          'compare_at_price': v.compareAtPrice?.toString() ?? '',
          'stock': v.stock?.toString() ?? '0',
          'is_default': v.isDefault,
        });
      }
    } else {
      _addVariant();
    }
  }

  void _addVariant() {
    setState(() {
      _variants.add({
        'variant_id': null,
        'sku': '',
        'price': '0.00',
        'compare_at_price': '',
        'stock': '0',
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
    _metaTitleController.dispose();
    _metaDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Client-side SKU uniqueness check
    final skus = _variants.map((v) => v['sku'] as String).toList();
    if (skus.toSet().length != skus.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Each variant must have a unique SKU'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final apiService = ref.read(apiServiceProvider);
    
    final productData = {
      'title': _titleController.text,
      'slug': _slugController.text,
      'description': _descriptionController.text,
      'meta_title': _metaTitleController.text,
      'meta_description': _metaDescriptionController.text,
      'status': _status,
      'is_digital': _isDigital,
      'images': _images,
      'variants': _variants.map((v) {
        final Map<String, dynamic> vMap = {
          'sku': v['sku'],
          'price': double.tryParse(v['price']) ?? 0.0,
          'is_default': v['is_default'],
        };
        if (v['variant_id'] != null) vMap['variant_id'] = v['variant_id'];
        if (v['compare_at_price'].toString().isNotEmpty) {
          vMap['compare_at_price'] = double.tryParse(v['compare_at_price']);
        }
        return vMap;
      }).toList(),
    };

    try {
      if (widget.product == null) {
        await apiService.createProduct(productData);
      } else {
        await apiService.updateProduct(widget.product!.id, productData);
      }
      ref.invalidate(productsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product saved successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
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
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(LucideIcons.save, size: 18),
              label: const Text('Save Product'),
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
              _buildMediaSection(theme),
              const SizedBox(height: 32),
              _buildSeoSection(theme),
              const SizedBox(height: 32),
              _buildVariantsSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeoSection(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.search, size: 20),
                const SizedBox(width: 8),
                Text('Search Engine Optimization', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _metaTitleController,
              decoration: const InputDecoration(
                labelText: 'Meta Title',
                hintText: 'Keep it under 60 characters',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _metaDescriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Meta Description',
                hintText: 'Brief summary for search results',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfo(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.info, size: 20),
                const SizedBox(width: 8),
                Text('General Information', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Product Title',
                hintText: 'e.g. Classic Cotton T-Shirt',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty == true ? 'Title is required' : null,
              onChanged: (v) {
                if (_slugController.text.isEmpty || 
                    (widget.product == null && _slugController.text == _titleController.text.toLowerCase().replaceAll(' ', '-'))) {
                   _slugController.text = v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(
                labelText: 'URL Slug',
                prefixText: '/products/',
                border: OutlineInputBorder(),
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
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
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
                    subtitle: const Text('No shipping required'),
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
            Row(
              children: [
                const Icon(LucideIcons.layers, size: 20),
                const SizedBox(width: 8),
                Text('Variants & Pricing', style: theme.textTheme.titleLarge),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _addVariant,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add Variant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                foregroundColor: theme.primaryColor,
                elevation: 0,
              ),
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
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: variant['sku'],
                            decoration: const InputDecoration(
                              labelText: 'SKU',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => variant['sku'] = v,
                            validator: (v) => v?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: variant['price'],
                            decoration: const InputDecoration(
                              labelText: 'Price', 
                              prefixText: '\$',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => variant['price'] = v,
                            validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: variant['compare_at_price'],
                            decoration: const InputDecoration(
                              labelText: 'Compare At', 
                              prefixText: '\$',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => variant['compare_at_price'] = v,
                          ),
                        ),
                        if (_variants.length > 1)
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
                            onPressed: () => _removeVariant(index),
                          ),
                      ],
                    ),
                    if (widget.product == null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: variant['stock'],
                              decoration: const InputDecoration(
                                labelText: 'Initial Stock',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => variant['stock'] = v,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  Widget _buildMediaSection(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.image, size: 20),
                    const SizedBox(width: 8),
                    Text('Media Gallery', style: theme.textTheme.titleLarge),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickAndUploadImage,
                  icon: _isUploading 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(LucideIcons.upload, size: 18),
                  label: const Text('Add Image'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_images.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor, style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(LucideIcons.imagePlus, size: 48, color: theme.hintColor),
                    const SizedBox(height: 16),
                    Text('No images added yet', style: TextStyle(color: theme.hintColor)),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: theme.colorScheme.surfaceContainerLow,
                          child: Image.network(
                            _images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.imageOff, color: Colors.grey),
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
                            icon: const Icon(LucideIcons.x, size: 14, color: Colors.white),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setState(() {
                                _images.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await file.readAsBytes();
      final url = await ref.read(apiServiceProvider).uploadMedia(bytes, file.name);
      
      // Update the URL controller with the new public path
      // Note: We need to prepend the actual backend host for local preview to work
      _images.add("http://127.0.0.1:8000$url");
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
