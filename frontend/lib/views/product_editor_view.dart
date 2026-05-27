import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/catalog.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/providers/catalog_providers.dart';
import 'package:lottie/lottie.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';
import 'package:kloudshop/widgets/glass_card.dart';

// Services & Shared Widgets
import 'package:kloudshop/services/file_uploader.dart';
import 'package:kloudshop/widgets/upload/media_gallery_uploader.dart';

// Product-specific Components
import 'package:kloudshop/widgets/product/product_general_info_card.dart';
import 'package:kloudshop/widgets/product/product_seo_card.dart';
import 'package:kloudshop/widgets/product/product_classification_card.dart';
import 'package:kloudshop/widgets/product/product_options_card.dart';
import 'package:kloudshop/widgets/product/product_variants_section.dart';

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
        final dialogWidth = screenWidth > 900
            ? screenWidth * 0.75
            : screenWidth * 0.95;
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
          child: FadeTransition(opacity: anim1, child: child),
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

  void _showNotification(
    String message, {
    bool isError = false,
    bool isDeletion = false,
  }) {
    final bool isFailure = isError || isDeletion;
    final backgroundColor = isFailure
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFF0FDF4);
    final contentColor = isFailure
        ? const Color(0xFF991B1B)
        : const Color(0xFF166534);
    final borderColor = isFailure
        ? const Color(0xFFFECACA)
        : const Color(0xFFBBF7D0);

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
  late final FileUploader _uploader;

  late TextEditingController _productWeightController;
  late TextEditingController _productLengthController;
  late TextEditingController _productWidthController;
  late TextEditingController _productHeightController;
  String _productWeightUnit = 'kg';
  String _productDimensionUnit = 'cm';
  bool _isPerishable = false;

  final List<Map<String, dynamic>> _optionsSchema = [];
  final List<Map<String, dynamic>> _variants = [];
  int _lastVariantCount = 0;
  bool _showVariantChangeAnimation = false;

  @override
  void initState() {
    super.initState();
    _uploader = MockFileUploader(
      apiUpload: (bytes, name) =>
          ref.read(apiServiceProvider).uploadMedia(bytes, name),
    );
    _titleController = TextEditingController(text: widget.product?.title ?? '');
    _slugController = TextEditingController(text: widget.product?.slug ?? '');
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _metaTitleController = TextEditingController(
      text: widget.product?.metaTitle ?? '',
    );
    _metaDescriptionController = TextEditingController(
      text: widget.product?.metaDescription ?? '',
    );
    _images = List.from(widget.product?.images ?? []);

    _productWeightController = TextEditingController(
      text: widget.product?.weightValue?.toString() ?? '',
    );
    _productLengthController = TextEditingController(
      text: widget.product?.lengthValue?.toString() ?? '',
    );
    _productWidthController = TextEditingController(
      text: widget.product?.widthValue?.toString() ?? '',
    );
    _productHeightController = TextEditingController(
      text: widget.product?.heightValue?.toString() ?? '',
    );
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
    _lastVariantCount = _variants.length;
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

    List<Map<String, String>> cartesianProduct(
      List<Map<String, dynamic>> options,
      int index,
    ) {
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
          result.add({currentName: val, ...subProduct});
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
        final suffix = optionStr.toUpperCase().replaceAll(
          RegExp(r'[^A-Z0-9\-]'),
          '-',
        );
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

    // Display Success Modal with Lottie animation
    final List<String> names = permutations
        .map((perm) => perm.values.join(' / '))
        .toList();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Variants Generated',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 120,
                  child: Lottie.network(
                    'https://lottie.host/c5c8e31a-e8f0-466d-9db8-5d2df1c469f6/mH9y7G1j7C.json',
                    repeat: false,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        LucideIcons.checkCircle2,
                        size: 80,
                        color: AppTheme.brandEmerald500,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Variants Generated Successfully!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Created ${permutations.length} variants:',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: names.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 8),
                    itemBuilder: (context, idx) {
                      return Row(
                        children: [
                          const Icon(
                            LucideIcons.check,
                            color: AppTheme.brandEmerald500,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              names[idx],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandEmerald500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  void _removeVariant(int index) {
    if (_variants.length > 1) {
      final variant = _variants[index];
      final Map<String, String> optionVals = Map<String, String>.from(
        variant['option_values'] ?? {},
      );
      final variantName = optionVals.isEmpty
          ? 'Default Variant'
          : optionVals.values.map((v) => v.trim()).join(' / ');

      setState(() {
        _variants.removeAt(index);
        if (!_variants.any((v) => v['is_default'] == true)) {
          _variants[0]['is_default'] = true;
        }
      });
      _showNotification(
        'Variant "$variantName" deleted Successfully',
        isDeletion: true,
      );
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
      _showNotification(
        'Error: Each variant must have a unique SKU',
        isError: true,
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
      'is_perishable': _isPerishable,
      'images': _images,
      'options_schema': _optionsSchema,
      'weight_value': double.tryParse(_productWeightController.text),
      'weight_unit': _productWeightController.text.isNotEmpty
          ? _productWeightUnit
          : null,
      'length_value': double.tryParse(_productLengthController.text),
      'width_value': double.tryParse(_productWidthController.text),
      'height_value': double.tryParse(_productHeightController.text),
      'dimension_unit':
          (_productLengthController.text.isNotEmpty ||
              _productWidthController.text.isNotEmpty ||
              _productHeightController.text.isNotEmpty)
          ? _productDimensionUnit
          : null,
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

    if (_variants.length != _lastVariantCount) {
      final hasPreviousCount = _lastVariantCount > 0;
      _lastVariantCount = _variants.length;
      if (hasPreviousCount) {
        _showVariantChangeAnimation = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() {
              _showVariantChangeAnimation = false;
            });
          }
        });
      }
    }

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            widget.product == null ? 'New Product' : 'Edit Product',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
                  icon: const Icon(
                    LucideIcons.save,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Save Product',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandEmerald500,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                      ProductGeneralInfoCard(
                        titleController: _titleController,
                        slugController: _slugController,
                        descriptionController: _descriptionController,
                        isNewProduct: widget.product == null,
                      ),
                      const SizedBox(height: 32),
                      GlassCard(
                        title: 'Media Gallery',
                        icon: LucideIcons.image,
                        color: const Color(0xFFEC4899),
                        children: [
                          MediaGalleryUploader(
                            images: _images,
                            uploader: _uploader,
                            onImagesChanged: (newImages) {
                              setState(() {
                                _images = newImages;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      ProductSeoCard(
                        metaTitleController: _metaTitleController,
                        metaDescriptionController: _metaDescriptionController,
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
                      ProductClassificationCard(
                        status: _status,
                        onStatusChanged: (v) => setState(() => _status = v),
                        isDigital: _isDigital,
                        onIsDigitalChanged: (v) =>
                            setState(() => _isDigital = v),
                        isPerishable: _isPerishable,
                        onIsPerishableChanged: (v) =>
                            setState(() => _isPerishable = v),
                        weightController: _productWeightController,
                        weightUnit: _productWeightUnit,
                        onWeightUnitChanged: (v) =>
                            setState(() => _productWeightUnit = v),
                        lengthController: _productLengthController,
                        widthController: _productWidthController,
                        heightController: _productHeightController,
                        dimensionUnit: _productDimensionUnit,
                        onDimensionUnitChanged: (v) =>
                            setState(() => _productDimensionUnit = v),
                      ),
                      const SizedBox(height: 32),
                      ProductOptionsCard(
                        optionsSchema: _optionsSchema,
                        onGenerateVariants: _generateVariantsFromOptions,
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 32),
                      ProductVariantsSection(
                        variants: _variants,
                        optionsSchema: _optionsSchema,
                        isNewProduct: widget.product == null,
                        isDigital: _isDigital,
                        uploader: _uploader,
                        showVariantChangeAnimation: _showVariantChangeAnimation,
                        onAddVariant: _addVariant,
                        onRemoveVariant: _removeVariant,
                        onChanged: () => setState(() {}),
                      ),
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
}
