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

  static Future<bool?> show(BuildContext context, {Product? product}) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Product Editor',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final dialogWidth = screenWidth > 900 ? screenWidth * 0.75 : screenWidth * 0.95;
        final dialogHeight = screenHeight * 0.9;
        
        return Center(
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ProductEditorView(product: product),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutQuad),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<ProductEditorView> createState() => _ProductEditorViewState();
}

class _ProductEditorViewState extends ConsumerState<ProductEditorView> {
  final _formKey = GlobalKey<FormState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  void _showNotification(String message, {bool isError = false, bool isDeletion = false}) {
    final bool isFailure = isError || isDeletion;
    final backgroundColor = isFailure ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
    final contentColor = isFailure ? const Color(0xFF991B1B) : const Color(0xFF166534);
    final borderColor = isFailure ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0);

    _messengerKey.currentState?.clearSnackBars();
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFailure ? LucideIcons.alertCircle : LucideIcons.checkCircle2,
              color: contentColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  color: contentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  late TextEditingController _titleController;
  late TextEditingController _slugController;
  late TextEditingController _descriptionController;
  late TextEditingController _metaTitleController;
  late TextEditingController _metaDescriptionController;
  List<String> _images = [];
  late String _status;
  late bool _isDigital;
  bool _isUploading = false;
  
  late TextEditingController _productWeightController;
  late TextEditingController _productLengthController;
  late TextEditingController _productWidthController;
  late TextEditingController _productHeightController;
  String _productWeightUnit = 'kg';
  String _productDimensionUnit = 'cm';
  bool _isPerishable = false;

  final List<Map<String, dynamic>> _optionsSchema = [];
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
    
    _productWeightController = TextEditingController(text: widget.product?.weightValue?.toString() ?? '');
    _productLengthController = TextEditingController(text: widget.product?.lengthValue?.toString() ?? '');
    _productWidthController = TextEditingController(text: widget.product?.widthValue?.toString() ?? '');
    _productHeightController = TextEditingController(text: widget.product?.heightValue?.toString() ?? '');
    _productWeightUnit = widget.product?.weightUnit ?? 'kg';
    _productDimensionUnit = widget.product?.dimensionUnit ?? 'cm';
    _isPerishable = widget.product?.isPerishable ?? false;
    
    _status = widget.product?.status ?? 'draft';
    _isDigital = widget.product?.isDigital ?? false;
    
    if (widget.product != null) {
      for (var opt in widget.product!.optionsSchema) {
        _optionsSchema.add({
          'name': opt['name'] as String,
          'values': List<String>.from(opt['values'] as List),
        });
      }
      for (var v in widget.product!.variants) {
        _variants.add({
          'variant_id': v.id,
          'sku': v.sku,
          'price': v.price.toString(),
          'compare_at_price': v.compareAtPrice?.toString() ?? '',
          'stock': v.stock?.toString() ?? '0',
          'is_default': v.isDefault,
          'option_values': Map<String, String>.from(v.optionValues),
          'images': List<String>.from(v.images),
          'image_url': v.imageUrl,
          'weight_value': v.weightValue?.toString() ?? '',
          'weight_unit': v.weightUnit ?? 'kg',
          'length_value': v.lengthValue?.toString() ?? '',
          'width_value': v.widthValue?.toString() ?? '',
          'height_value': v.heightValue?.toString() ?? '',
          'dimension_unit': v.dimensionUnit ?? 'cm',
          'show_shipping_overrides': false,
          'is_expanded': false,
        });
      }
    } else {
      _addVariant(showToast: false);
    }
  }

  void _addVariant({bool showToast = true}) {
    setState(() {
      final Map<String, String> defaultOptionValues = {};
      for (var opt in _optionsSchema) {
        final String name = opt['name'];
        final List<String> vals = List<String>.from(opt['values']);
        if (name.isNotEmpty && vals.isNotEmpty) {
          defaultOptionValues[name] = vals.first;
        }
      }

      _variants.add({
        'variant_id': null,
        'sku': '',
        'price': '0.00',
        'compare_at_price': '',
        'stock': '0',
        'is_default': _variants.isEmpty,
        'option_values': defaultOptionValues,
        'images': <String>[],
        'image_url': null,
        'weight_value': '',
        'weight_unit': 'kg',
        'length_value': '',
        'width_value': '',
        'height_value': '',
        'dimension_unit': 'cm',
        'show_shipping_overrides': false,
        'is_expanded': true,
      });
    });
    if (showToast) {
      _showNotification('Variant added');
    }
  }

  void _generateVariantsFromOptions() {
    if (_optionsSchema.isEmpty) return;

    List<Map<String, String>> cartesianProduct(List<Map<String, dynamic>> options, int index) {
      if (index == options.length) {
        return [{}];
      }

      final currentOpt = options[index];
      final currentName = currentOpt['name'] as String;
      final currentValues = currentOpt['values'] as List<String>;

      final subProducts = cartesianProduct(options, index + 1);
      final List<Map<String, String>> result = [];

      for (var val in currentValues) {
        for (var subProduct in subProducts) {
          result.add({
            currentName: val,
            ...subProduct,
          });
        }
      }
      return result;
    }

    final permutations = cartesianProduct(_optionsSchema, 0);

    setState(() {
      _variants.clear();
      for (var i = 0; i < permutations.length; i++) {
        final perm = permutations[i];
        final optionStr = perm.values.join('-');
        final baseSku = _slugController.text.toUpperCase();
        final suffix = optionStr.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\-]'), '-');
        final sku = baseSku.isNotEmpty ? '$baseSku-$suffix' : '';

        _variants.add({
          'variant_id': null,
          'sku': sku,
          'price': '0.00',
          'compare_at_price': '',
          'stock': '0',
          'is_default': i == 0,
          'option_values': perm,
          'images': <String>[],
          'image_url': null,
          'weight_value': '',
          'weight_unit': 'kg',
          'length_value': '',
          'width_value': '',
          'height_value': '',
          'dimension_unit': 'cm',
          'show_shipping_overrides': false,
          'is_expanded': false,
        });
      }
    });
    _showNotification('Generated ${permutations.length} variants');
  }

  void _removeVariant(int index) {
    if (_variants.length > 1) {
      setState(() {
        _variants.removeAt(index);
        if (!_variants.any((v) => v['is_default'] == true)) {
          _variants[0]['is_default'] = true;
        }
      });
      _showNotification('Variant deleted Successfully', isDeletion: true);
    }
  }

  Future<void> _pickAndUploadVariantImage(int variantIndex) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await file.readAsBytes();
      final url = await ref.read(apiServiceProvider).uploadMedia(bytes, file.name);
      final fullUrl = "http://127.0.0.1:8000$url";
      
      setState(() {
        final List<String> vImages = List<String>.from(_variants[variantIndex]['images'] ?? []);
        vImages.add(fullUrl);
        _variants[variantIndex]['images'] = vImages;
        
        if (_variants[variantIndex]['image_url'] == null) {
          _variants[variantIndex]['image_url'] = fullUrl;
        }
      });
      
      if (mounted) {
        _showNotification('Variant image uploaded successfully');
      }
    } catch (e) {
      if (mounted) {
        _showNotification('Upload failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _metaTitleController.dispose();
    _metaDescriptionController.dispose();
    _productWeightController.dispose();
    _productLengthController.dispose();
    _productWidthController.dispose();
    _productHeightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final skus = _variants.map((v) => v['sku'] as String).toList();
    if (skus.toSet().length != skus.length) {
      _showNotification('Error: Each variant must have a unique SKU', isError: true);
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
      'is_perishable': _isPerishable,
      'images': _images,
      'options_schema': _optionsSchema,
      'weight_value': double.tryParse(_productWeightController.text),
      'weight_unit': _productWeightController.text.isNotEmpty ? _productWeightUnit : null,
      'length_value': double.tryParse(_productLengthController.text),
      'width_value': double.tryParse(_productWidthController.text),
      'height_value': double.tryParse(_productHeightController.text),
      'dimension_unit': (_productLengthController.text.isNotEmpty || 
                         _productWidthController.text.isNotEmpty || 
                         _productHeightController.text.isNotEmpty) ? _productDimensionUnit : null,
      'variants': _variants.map((v) {
        final Map<String, dynamic> vMap = {
          'sku': v['sku'],
          'price': double.tryParse(v['price']) ?? 0.0,
          'is_default': v['is_default'],
          'option_values': Map<String, String>.from(v['option_values'] ?? {}),
          'images': List<String>.from(v['images'] ?? []),
          'image_url': v['image_url'],
        };
        if (v['variant_id'] != null) vMap['variant_id'] = v['variant_id'];
        if (v['compare_at_price'].toString().isNotEmpty) {
          vMap['compare_at_price'] = double.tryParse(v['compare_at_price']);
        }
        
        // Shipping overrides
        if (v['weight_value'].toString().isNotEmpty) {
          vMap['weight_value'] = double.tryParse(v['weight_value']);
          vMap['weight_unit'] = v['weight_unit'];
        }
        if (v['length_value'].toString().isNotEmpty) {
          vMap['length_value'] = double.tryParse(v['length_value']);
        }
        if (v['width_value'].toString().isNotEmpty) {
          vMap['width_value'] = double.tryParse(v['width_value']);
        }
        if (v['height_value'].toString().isNotEmpty) {
          vMap['height_value'] = double.tryParse(v['height_value']);
        }
        if (v['length_value'].toString().isNotEmpty || 
            v['width_value'].toString().isNotEmpty || 
            v['height_value'].toString().isNotEmpty) {
          vMap['dimension_unit'] = v['dimension_unit'];
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
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showNotification('Error: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
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
                          initialValue: _status,
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
                          activeThumbColor: AppTheme.brandEmerald500,
                          onChanged: (v) => setState(() => _isDigital = v),
                        ),
                        const SizedBox(height: 24),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Perishable Product', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('Requires expiration and batch tracking upon stock receipts'),
                          value: _isPerishable,
                          activeThumbColor: AppTheme.brandEmerald500,
                          onChanged: (v) => setState(() => _isPerishable = v),
                        ),
                      ],
                    ),
                    if (!_isDigital) ...[
                      const SizedBox(height: 32),
                      _buildGlassCard(
                        title: 'Shipping Defaults',
                        icon: LucideIcons.truck,
                        color: const Color(0xFF3B82F6),
                        isDark: isDark,
                        theme: theme,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _productWeightController,
                                  decoration: const InputDecoration(
                                    labelText: 'Default Weight',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) {
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _productWeightUnit,
                                  decoration: const InputDecoration(
                                    labelText: 'Unit',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                                    DropdownMenuItem(value: 'lb', child: Text('lb')),
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      _productWeightUnit = v!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _productLengthController,
                                  decoration: const InputDecoration(
                                    labelText: 'Length',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _productWidthController,
                                  decoration: const InputDecoration(
                                    labelText: 'Width',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _productHeightController,
                                  decoration: const InputDecoration(
                                    labelText: 'Height',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _productDimensionUnit,
                                  decoration: const InputDecoration(
                                    labelText: 'Unit',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'cm', child: Text('cm')),
                                    DropdownMenuItem(value: 'in', child: Text('in')),
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      _productDimensionUnit = v!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                    _buildGlassCard(
                      title: 'Product Options',
                      icon: LucideIcons.sliders,
                      color: const Color(0xFF8B5CF6),
                      isDark: isDark,
                      theme: theme,
                      children: [
                        const Text(
                          'Define variant attributes like Size, Color, or Material. These will be used to generate specific product variants.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ..._optionsSchema.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final opt = entry.value;
                          return OptionCategoryEditor(
                            key: ValueKey('opt-$idx-${opt['name']}'),
                            option: opt,
                            onDelete: () {
                              setState(() {
                                _optionsSchema.removeAt(idx);
                              });
                            },
                            onChanged: () {
                              setState(() {});
                            },
                          );
                        }),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _optionsSchema.add({
                                    'name': '',
                                    'values': <String>[],
                                  });
                                });
                              },
                              icon: const Icon(LucideIcons.plus, size: 16),
                              label: const Text('Add Option Category'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.brandEmerald500,
                              ),
                            ),
                            if (_optionsSchema.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: _generateVariantsFromOptions,
                                icon: const Icon(LucideIcons.refreshCw, size: 14, color: Colors.white),
                                label: const Text('Generate Variants', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.brandEmerald500,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                          ],
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
            color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                      color: color.withValues(alpha: 0.1),
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
                  backgroundColor: AppTheme.brandEmerald500.withValues(alpha: 0.1),
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
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final variant = _variants[index];
            final Map<String, String> optionVals = Map<String, String>.from(variant['option_values'] ?? {});
            final bool isExpanded = variant['is_expanded'] ?? false;
            
            final customInputStyle = theme.textTheme.bodyMedium?.copyWith(fontSize: 10);
            final customLabelStyle = theme.textTheme.bodySmall?.copyWith(fontSize: 9);
            const customPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 6);

            // Build dynamic option dropdowns
            final List<Widget> optionDropdowns = [];
            for (var opt in _optionsSchema) {
              final String name = opt['name'];
              final List<String> vals = List<String>.from(opt['values']);
              if (name.isNotEmpty && vals.isNotEmpty) {
                if (!vals.contains(optionVals[name])) {
                  optionVals[name] = vals.first;
                  variant['option_values'] = optionVals;
                }
                optionDropdowns.add(
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: optionVals[name],
                      style: customInputStyle,
                      decoration: InputDecoration(
                        labelText: name,
                        labelStyle: customLabelStyle,
                        border: const OutlineInputBorder(),
                        contentPadding: customPadding,
                      ),
                      items: vals.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (newVal) {
                        setState(() {
                          optionVals[name] = newVal!;
                          variant['option_values'] = optionVals;
                        });
                      },
                    ),
                  ),
                );
                optionDropdowns.add(const SizedBox(width: 12));
              }
            }

            final List<String> vImages = List<String>.from(variant['images'] ?? []);

            return Container(
              padding: isExpanded 
                  ? const EdgeInsets.all(20) 
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Collapse / Expand Header Row
                  InkWell(
                    onTap: () {
                      setState(() {
                        variant['is_expanded'] = !isExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                            size: 20,
                            color: AppTheme.brandEmerald500,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    optionVals.isEmpty 
                                        ? 'Default Variant' 
                                        : optionVals.entries.map((e) => e.value).join(' / '),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                if (variant['sku']?.toString().isNotEmpty == true) ...[
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.blueGrey.withValues(alpha: 0.2) : Colors.blueGrey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'SKU: ${variant['sku']}',
                                        style: TextStyle(
                                          fontSize: 11, 
                                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            variant['price']?.toString().isNotEmpty == true ? '\$${variant['price']}' : '\$0.00',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brandEmerald500,
                            ),
                          ),
                          if (_variants.length > 1) ...[
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _removeVariant(index),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  if (isExpanded) ...[
                    const Divider(height: 24),
                    if (optionDropdowns.isNotEmpty) ...[
                      Row(children: optionDropdowns),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: variant['sku'],
                            style: customInputStyle,
                            decoration: InputDecoration(
                              labelText: 'SKU',
                              labelStyle: customLabelStyle,
                              border: const OutlineInputBorder(),
                              contentPadding: customPadding,
                            ),
                            onChanged: (v) {
                              setState(() {
                                variant['sku'] = v;
                              });
                            },
                            validator: (v) => v?.isEmpty == true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: variant['price'],
                            style: customInputStyle,
                            decoration: InputDecoration(
                              labelText: 'Price', 
                              labelStyle: customLabelStyle,
                              prefixText: '\$',
                              prefixStyle: customInputStyle,
                              border: const OutlineInputBorder(),
                              contentPadding: customPadding,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              setState(() {
                                variant['price'] = v;
                              });
                            },
                            validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: variant['compare_at_price'],
                            style: customInputStyle,
                            decoration: InputDecoration(
                              labelText: 'Compare At', 
                              labelStyle: customLabelStyle,
                              prefixText: '\$',
                              prefixStyle: customInputStyle,
                              border: const OutlineInputBorder(),
                              contentPadding: customPadding,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              setState(() {
                                variant['compare_at_price'] = v;
                              });
                            },
                          ),
                        ),
                        if (widget.product == null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              initialValue: variant['stock'],
                              style: customInputStyle,
                              decoration: InputDecoration(
                                labelText: 'Initial Stock Inventory',
                                labelStyle: customLabelStyle,
                                border: const OutlineInputBorder(),
                                contentPadding: customPadding,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                setState(() {
                                  variant['stock'] = v;
                                });
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Media Section for Variant
                    const SizedBox(height: 16),
                    const Text('Variant Images', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickAndUploadVariantImage(index),
                          icon: const Icon(LucideIcons.upload, size: 14),
                          label: const Text('Add', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandEmerald500.withValues(alpha: 0.1),
                            foregroundColor: AppTheme.brandEmerald500,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (vImages.isEmpty)
                          const Text('No variant specific images', style: TextStyle(color: Colors.grey, fontSize: 12))
                        else
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: vImages.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 8),
                                itemBuilder: (context, vImgIdx) {
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          vImages[vImgIdx],
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.imageOff, size: 24),
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: CircleAvatar(
                                          radius: 8,
                                          backgroundColor: Colors.black54,
                                          child: IconButton(
                                            icon: const Icon(LucideIcons.x, size: 8, color: Colors.white),
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              setState(() {
                                                vImages.removeAt(vImgIdx);
                                                variant['images'] = vImages;
                                                if (variant['image_url'] == vImages.firstOrNull) {
                                                  variant['image_url'] = vImages.firstOrNull;
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    // Shipping Overrides Section
                    if (!_isDigital) ...[
                      const Divider(height: 24),
                      _buildVariantShippingOverrides(variant),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVariantShippingOverrides(Map<String, dynamic> variant) {
    final bool showOverrides = variant['show_shipping_overrides'] ?? false;
    final theme = Theme.of(context);
    final customInputStyle = theme.textTheme.bodyMedium?.copyWith(fontSize: 10);
    final customLabelStyle = theme.textTheme.bodySmall?.copyWith(fontSize: 9);
    const customPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 6);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  variant['show_shipping_overrides'] = !showOverrides;
                });
              },
              icon: Icon(
                showOverrides ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 16,
                color: AppTheme.brandEmerald500,
              ),
              label: Text(
                showOverrides ? 'Hide Shipping Overrides' : 'Configure Shipping Overrides',
                style: const TextStyle(color: AppTheme.brandEmerald500, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        if (showOverrides) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: variant['weight_value']?.toString() ?? '',
                  style: customInputStyle,
                  decoration: InputDecoration(
                    labelText: 'Variant Weight',
                    labelStyle: customLabelStyle,
                    hintText: 'variant weight',
                    hintStyle: customInputStyle,
                    border: const OutlineInputBorder(),
                    contentPadding: customPadding,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => variant['weight_value'] = v,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: variant['weight_unit'] ?? 'kg',
                  style: customInputStyle,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    labelStyle: customLabelStyle,
                    border: const OutlineInputBorder(),
                    contentPadding: customPadding,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                    DropdownMenuItem(value: 'lb', child: Text('lb')),
                  ],
                  onChanged: (v) => variant['weight_unit'] = v!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: variant['length_value']?.toString() ?? '',
                  style: customInputStyle,
                  decoration: InputDecoration(
                    labelText: 'Variant Length',
                    labelStyle: customLabelStyle,
                    hintText: 'variant length',
                    hintStyle: customInputStyle,
                    border: const OutlineInputBorder(),
                    contentPadding: customPadding,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => variant['length_value'] = v,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: variant['width_value']?.toString() ?? '',
                  style: customInputStyle,
                  decoration: InputDecoration(
                    labelText: 'Variant Width',
                    labelStyle: customLabelStyle,
                    hintText: 'variant width',
                    hintStyle: customInputStyle,
                    border: const OutlineInputBorder(),
                    contentPadding: customPadding,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => variant['width_value'] = v,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: variant['height_value']?.toString() ?? '',
                  style: customInputStyle,
                  decoration: InputDecoration(
                    labelText: 'Variant Height',
                    labelStyle: customLabelStyle,
                    hintText: 'variant height',
                    hintStyle: customInputStyle,
                    border: const OutlineInputBorder(),
                    contentPadding: customPadding,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => variant['height_value'] = v,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: variant['dimension_unit'] ?? 'cm',
                  style: customInputStyle,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    labelStyle: customLabelStyle,
                    border: const OutlineInputBorder(),
                    contentPadding: customPadding,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cm', child: Text('cm')),
                    DropdownMenuItem(value: 'in', child: Text('in')),
                  ],
                  onChanged: (v) => variant['dimension_unit'] = v!,
                ),
              ),
            ],
          ),
        ],
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
        _showNotification('Image uploaded successfully');
      }
    } catch (e) {
      if (mounted) {
        _showNotification('Upload failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

class OptionCategoryEditor extends StatefulWidget {
  final Map<String, dynamic> option;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const OptionCategoryEditor({
    super.key,
    required this.option,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<OptionCategoryEditor> createState() => _OptionCategoryEditorState();
}

class _OptionCategoryEditorState extends State<OptionCategoryEditor> {
  late TextEditingController _nameController;
  late TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.option['name']);
    _valueController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  void _addValue() {
    final val = _valueController.text.trim();
    if (val.isNotEmpty) {
      final List<String> vals = List<String>.from(widget.option['values']);
      if (!vals.contains(val)) {
        vals.add(val);
        widget.option['values'] = vals;
        widget.onChanged();
        _valueController.clear();
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> values = List<String>.from(widget.option['values']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Option Name (e.g. Color, Size)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  widget.option['name'] = v.trim();
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: TextFormField(
                controller: _valueController,
                decoration: InputDecoration(
                  labelText: 'Add Value',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle, color: AppTheme.brandEmerald500),
                    onPressed: _addValue,
                  ),
                  border: const OutlineInputBorder(),
                ),
                onFieldSubmitted: (_) => _addValue(),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.redAccent),
              onPressed: widget.onDelete,
            ),
          ],
        ),
        if (values.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((val) => Chip(
              label: Text(val),
              onDeleted: () {
                values.remove(val);
                widget.option['values'] = values;
                widget.onChanged();
                setState(() {});
              },
            )).toList(),
          ),
        ],
        const Divider(height: 32),
      ],
    );
  }
}
