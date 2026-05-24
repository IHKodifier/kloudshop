import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/catalog.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/providers/catalog_providers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.product == null ? 'New Product' : 'Edit Product', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: theme.dividerColor, height: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: HoverScale(
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(LucideIcons.save, size: 16, color: Colors.white),
                label: const Text('Save Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandEmerald500,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
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
              // Left Column (General info, Media, SEO)
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGlassCard(
                      title: 'General Information',
                      icon: LucideIcons.info,
                      color: AppTheme.brandEmerald500,
                      isDark: isDark,
                      theme: theme,
                      children: [
                        _buildInputField('Product Title', _titleController, 'e.g. Classic Cotton T-Shirt', theme, validator: (v) => v?.isEmpty == true ? 'Title is required' : null, onChanged: (v) {
                          if (_slugController.text.isEmpty || 
                              (widget.product == null && _slugController.text == _titleController.text.toLowerCase().replaceAll(' ', '-'))) {
                             _slugController.text = v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-');
                          }
                        }),
                        const SizedBox(height: 20),
                        _buildInputField('URL Slug', _slugController, 'e.g. classic-cotton-t-shirt', theme, prefixText: '/products/', validator: (v) => v?.isEmpty == true ? 'Slug is required' : null),
                        const SizedBox(height: 20),
                        _buildInputField('Description', _descriptionController, 'Describe your product...', theme, maxLines: 4),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildMediaSectionWidget(theme, isDark),
                    const SizedBox(height: 32),
                    _buildGlassCard(
                      title: 'Search Engine Optimization',
                      icon: LucideIcons.search,
                      color: const Color(0xFF6366F1),
                      isDark: isDark,
                      theme: theme,
                      children: [
                        _buildInputField('Meta Title', _metaTitleController, 'Keep it under 60 characters', theme),
                        const SizedBox(height: 20),
                        _buildInputField('Meta Description', _metaDescriptionController, 'Brief summary for search results', theme, maxLines: 2),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Right Column (Variants, Status)
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Details Panel
                    _buildGlassCard(
                      title: 'Status & Classification',
                      icon: LucideIcons.tags,
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                      theme: theme,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _status,
                          decoration: InputDecoration(
                            labelText: 'Product Status',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppTheme.brandEmerald500, width: 1.5),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'active', child: Text('Active')),
                            DropdownMenuItem(value: 'draft', child: Text('Draft')),
                            DropdownMenuItem(value: 'archived', child: Text('Archived')),
                          ],
                          onChanged: (v) => setState(() => _status = v!),
                        ),
                        const SizedBox(height: 24),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Digital Product', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('No shipping required for service or downloads'),
                          value: _isDigital,
                          activeColor: AppTheme.brandEmerald500,
                          onChanged: (v) => setState(() => _isDigital = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildVariantsSectionWidget(theme, isDark),
                  ],
                ),
              ),
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
          padding: const EdgeInsets.all(28),
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
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label, 
    TextEditingController controller, 
    String hint, 
    ThemeData theme, {
    int maxLines = 1,
    String? prefixText,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.brandEmerald500, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildMediaSectionWidget(ThemeData theme, bool isDark) {
    return _buildGlassCard(
      title: 'Media Gallery',
      icon: LucideIcons.image,
      color: const Color(0xFFEC4899),
      isDark: isDark,
      theme: theme,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Product Images', style: theme.textTheme.titleSmall),
            HoverScale(
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickAndUploadImage,
                icon: _isUploading 
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.upload, size: 14, color: Colors.white),
                label: const Text('Add Image', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandEmerald500,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_images.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                Icon(LucideIcons.imagePlus, size: 40, color: theme.hintColor),
                const SizedBox(height: 12),
                Text('Drag and drop or upload your product visuals', style: TextStyle(color: theme.hintColor, fontSize: 13)),
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
    );
  }

  Widget _buildVariantsSectionWidget(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.layers, size: 20, color: AppTheme.brandEmerald500),
                const SizedBox(width: 8),
                Text('Variants & Pricing', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            HoverScale(
              child: ElevatedButton.icon(
                onPressed: _addVariant,
                icon: const Icon(LucideIcons.plus, size: 14, color: AppTheme.brandEmerald500),
                label: const Text('Add Variant', style: TextStyle(color: AppTheme.brandEmerald500)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandEmerald500.withOpacity(0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
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
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
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
                              labelText: 'Initial Stock Inventory',
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
            );
          },
        ),
      ],
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
