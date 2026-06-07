import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/models/catalog.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/providers/catalog_providers.dart';

class ProductEditorState {
  final String title;
  final String slug;
  final String description;
  final String metaTitle;
  final String metaDescription;
  final List<String> images;
  final String status;
  final bool isDigital;
  final bool isPerishable;
  final String weightValue;
  final String weightUnit;
  final String lengthValue;
  final String widthValue;
  final String heightValue;
  final String dimensionUnit;
  final bool ageVerificationRequired;
  final String minimumAgeYears;
  final bool requiresPrescription;
  final bool prescriptionDocumentRequired;
  final List<Map<String, dynamic>> optionsSchema;
  final List<Map<String, dynamic>> variants;
  final bool isSaving;
  final String? errorMessage;

  ProductEditorState({
    this.title = '',
    this.slug = '',
    this.description = '',
    this.metaTitle = '',
    this.metaDescription = '',
    this.images = const [],
    this.status = 'draft',
    this.isDigital = false,
    this.isPerishable = false,
    this.weightValue = '',
    this.weightUnit = 'kg',
    this.lengthValue = '',
    this.widthValue = '',
    this.heightValue = '',
    this.dimensionUnit = 'cm',
    this.ageVerificationRequired = false,
    this.minimumAgeYears = '',
    this.requiresPrescription = false,
    this.prescriptionDocumentRequired = false,
    this.optionsSchema = const [],
    this.variants = const [],
    this.isSaving = false,
    this.errorMessage,
  });

  ProductEditorState copyWith({
    String? title,
    String? slug,
    String? description,
    String? metaTitle,
    String? metaDescription,
    List<String>? images,
    String? status,
    bool? isDigital,
    bool? isPerishable,
    String? weightValue,
    String? weightUnit,
    String? lengthValue,
    String? widthValue,
    String? heightValue,
    String? dimensionUnit,
    bool? ageVerificationRequired,
    String? minimumAgeYears,
    bool? requiresPrescription,
    bool? prescriptionDocumentRequired,
    List<Map<String, dynamic>>? optionsSchema,
    List<Map<String, dynamic>>? variants,
    bool? isSaving,
    String? errorMessage,
  }) {
    return ProductEditorState(
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      metaTitle: metaTitle ?? this.metaTitle,
      metaDescription: metaDescription ?? this.metaDescription,
      images: images ?? this.images,
      status: status ?? this.status,
      isDigital: isDigital ?? this.isDigital,
      isPerishable: isPerishable ?? this.isPerishable,
      weightValue: weightValue ?? this.weightValue,
      weightUnit: weightUnit ?? this.weightUnit,
      lengthValue: lengthValue ?? this.lengthValue,
      widthValue: widthValue ?? this.widthValue,
      heightValue: heightValue ?? this.heightValue,
      dimensionUnit: dimensionUnit ?? this.dimensionUnit,
      ageVerificationRequired:
          ageVerificationRequired ?? this.ageVerificationRequired,
      minimumAgeYears: minimumAgeYears ?? this.minimumAgeYears,
      requiresPrescription: requiresPrescription ?? this.requiresPrescription,
      prescriptionDocumentRequired:
          prescriptionDocumentRequired ?? this.prescriptionDocumentRequired,
      optionsSchema: optionsSchema ?? this.optionsSchema,
      variants: variants ?? this.variants,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

class ProductEditorNotifier extends Notifier<ProductEditorState> {
  final Product? product;
  ProductEditorNotifier(this.product);

  @override
  ProductEditorState build() {
    final product = this.product;
    if (product == null) {
      return ProductEditorState(
        optionsSchema: const [
          {
            'name': 'Color',
            'values': <String>['Pure white', 'Jet black', 'Metallic silver'],
          }
        ],
        variants: [
          {
            'variant_id': null,
            'sku': '',
            'price': '0.00',
            'compare_at_price': '',
            'stock': '0',
            'is_default': true,
            'is_active': true,
            'option_values': <String, String>{'Color': 'Pure white'},
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
          }
        ],
      );
    }

    final List<Map<String, dynamic>> opts = [];
    for (var opt in product.optionsSchema) {
      opts.add({
        'name': opt['name'] as String,
        'values': List<String>.from(opt['values'] as List),
      });
    }

    final List<Map<String, dynamic>> vars = [];
    for (var v in product.variants) {
      vars.add({
        'variant_id': v.id,
        'sku': v.sku,
        'price': v.price.toString(),
        'compare_at_price': v.compareAtPrice?.toString() ?? '',
        'stock': v.stock?.toString() ?? '0',
        'is_default': v.isDefault,
        'is_active': v.isActive,
        'option_values': Map<String, String>.from(v.optionValues),
        'images': List<String>.from(v.images),
        'image_url': v.imageUrl,
        'weight_value': v.weightValue?.toString() ?? '',
        'weight_unit': v.weightUnit ?? 'kg',
        'length_value': v.lengthValue?.toString() ?? '',
        'width_value': v.widthValue?.toString() ?? '',
        'height_value': v.heightValue?.toString() ?? '',
        'dimension_unit': v.dimensionUnit ?? 'cm',
        'show_shipping_overrides': v.weightValue != null ||
            v.lengthValue != null ||
            v.widthValue != null ||
            v.heightValue != null,
        'is_expanded': false,
      });
    }

    return ProductEditorState(
      title: product.title,
      slug: product.slug,
      description: product.description ?? '',
      metaTitle: product.metaTitle ?? '',
      metaDescription: product.metaDescription ?? '',
      images: List.from(product.images),
      status: product.status,
      isDigital: product.isDigital,
      isPerishable: product.isPerishable,
      weightValue: product.weightValue?.toString() ?? '',
      weightUnit: product.weightUnit ?? 'kg',
      lengthValue: product.lengthValue?.toString() ?? '',
      widthValue: product.widthValue?.toString() ?? '',
      heightValue: product.heightValue?.toString() ?? '',
      dimensionUnit: product.dimensionUnit ?? 'cm',
      ageVerificationRequired: product.ageVerificationRequired,
      minimumAgeYears: product.minimumAgeYears?.toString() ?? '',
      requiresPrescription: product.requiresPrescription,
      prescriptionDocumentRequired: product.prescriptionDocumentRequired,
      optionsSchema: opts,
      variants: vars,
    );
  }

  void updateTitle(String val) {
    state = state.copyWith(title: val);
  }

  void updateSlug(String val) {
    state = state.copyWith(slug: val);
  }

  void updateDescription(String val) {
    state = state.copyWith(description: val);
  }

  void updateMetaTitle(String val) {
    state = state.copyWith(metaTitle: val);
  }

  void updateMetaDescription(String val) {
    state = state.copyWith(metaDescription: val);
  }

  void updateImages(List<String> val) {
    state = state.copyWith(images: val);
  }

  void updateStatus(String val) {
    state = state.copyWith(status: val);
  }

  void updateIsDigital(bool val) {
    state = state.copyWith(isDigital: val);
  }

  void updateIsPerishable(bool val) {
    state = state.copyWith(isPerishable: val);
  }

  void updateAgeVerificationRequired(bool val) {
    state = state.copyWith(ageVerificationRequired: val);
  }

  void updateMinimumAgeYears(String val) {
    state = state.copyWith(minimumAgeYears: val);
  }

  void updateRequiresPrescription(bool val) {
    state = state.copyWith(
      requiresPrescription: val,
      prescriptionDocumentRequired: val,
    );
  }

  void updateWeightValue(String val) {
    state = state.copyWith(weightValue: val);
  }

  void updateWeightUnit(String val) {
    state = state.copyWith(weightUnit: val);
  }

  void updateLengthValue(String val) {
    state = state.copyWith(lengthValue: val);
  }

  void updateWidthValue(String val) {
    state = state.copyWith(widthValue: val);
  }

  void updateHeightValue(String val) {
    state = state.copyWith(heightValue: val);
  }

  void updateDimensionUnit(String val) {
    state = state.copyWith(dimensionUnit: val);
  }

  void updateOptionsSchema(List<Map<String, dynamic>> val) {
    state = state.copyWith(optionsSchema: val);
  }

  void updateVariants(List<Map<String, dynamic>> val) {
    state = state.copyWith(variants: val);
  }

  void addVariant() {
    final Map<String, String> defaultOptionValues = {};
    for (var opt in state.optionsSchema) {
      final String name = opt['name'];
      final List<String> vals = List<String>.from(opt['values']);
      if (name.isNotEmpty && vals.isNotEmpty) {
        defaultOptionValues[name] = vals.first;
      }
    }

    final newVariants = [
      ...state.variants,
      {
        'variant_id': null,
        'sku': '',
        'price': '0.00',
        'compare_at_price': '',
        'stock': '0',
        'is_default': state.variants.isEmpty,
        'is_active': true,
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
      }
    ];
    state = state.copyWith(variants: newVariants);
  }

  void removeVariant(int index) {
    if (state.variants.length > 1) {
      final newVariants =
          List<Map<String, dynamic>>.from(state.variants)..removeAt(index);
      if (!newVariants.any((v) => v['is_default'] == true)) {
        newVariants[0]['is_default'] = true;
      }
      state = state.copyWith(variants: newVariants);
    }
  }

  void generateVariantsFromOptions() {
    final activeOptions = state.optionsSchema.where((opt) {
      final name = (opt['name'] as String? ?? '').trim();
      final values = List<dynamic>.from(opt['values'] ?? []);
      return name.isNotEmpty && values.isNotEmpty;
    }).toList();

    if (activeOptions.isEmpty) return;

    List<Map<String, String>> cartesianProduct(
      List<Map<String, dynamic>> options,
      int index,
    ) {
      if (index == options.length) {
        return [{}];
      }

      final currentOpt = options[index];
      final currentName = currentOpt['name'] as String;
      final currentValues = List<String>.from(currentOpt['values'] ?? []);

      final subProducts = cartesianProduct(options, index + 1);
      final List<Map<String, String>> result = [];

      for (var val in currentValues) {
        for (var subProduct in subProducts) {
          result.add({currentName: val, ...subProduct});
        }
      }
      return result;
    }

    final permutations = cartesianProduct(activeOptions, 0);
    final List<Map<String, dynamic>> newVariants = [];

    for (var i = 0; i < permutations.length; i++) {
      final perm = permutations[i];
      final optionStr = perm.values.join('-');
      final baseSku = state.slug.toUpperCase();
      final suffix = optionStr.toUpperCase().replaceAll(
        RegExp(r'[^A-Z0-9\-]'),
        '-',
      );
      final sku = baseSku.isNotEmpty ? '$baseSku-$suffix' : '';

      newVariants.add({
        'variant_id': null,
        'sku': sku,
        'price': '0.00',
        'compare_at_price': '',
        'stock': '0',
        'is_default': i == 0,
        'is_active': true,
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

    state = state.copyWith(variants: newVariants);
  }

  Future<bool> save(ApiService apiService, String? productId) async {
    state = state.copyWith(isSaving: true, errorMessage: null);

    final productData = {
      'title': state.title,
      'slug': state.slug,
      'description': state.description,
      'meta_title': state.metaTitle,
      'meta_description': state.metaDescription,
      'status': state.status,
      'is_digital': state.isDigital,
      'is_perishable': state.isPerishable,
      'age_verification_required': state.ageVerificationRequired,
      'minimum_age_years': state.ageVerificationRequired
          ? int.tryParse(state.minimumAgeYears)
          : null,
      'requires_prescription': state.requiresPrescription,
      'prescription_document_required': state.requiresPrescription,
      'images': state.images,
      'options_schema': state.optionsSchema,
      'weight_value': double.tryParse(state.weightValue),
      'weight_unit': state.weightValue.isNotEmpty ? state.weightUnit : null,
      'length_value': double.tryParse(state.lengthValue),
      'width_value': double.tryParse(state.widthValue),
      'height_value': double.tryParse(state.heightValue),
      'dimension_unit':
          (state.lengthValue.isNotEmpty ||
                  state.widthValue.isNotEmpty ||
                  state.heightValue.isNotEmpty)
              ? state.dimensionUnit
              : null,
      'variants':
          state.variants.map((v) {
            final Map<String, dynamic> vMap = {
              'sku': v['sku'],
              'price': double.tryParse(v['price'].toString()) ?? 0.0,
              'is_default': v['is_default'],
              'is_active': v['is_active'] ?? true,
              'option_values': Map<String, String>.from(
                v['option_values'] ?? {},
              ),
              'images': List<String>.from(v['images'] ?? []),
              'image_url': v['image_url'],
            };
            if (v['variant_id'] != null) vMap['variant_id'] = v['variant_id'];
            if (v['compare_at_price'].toString().isNotEmpty) {
              vMap['compare_at_price'] = double.tryParse(
                v['compare_at_price'].toString(),
              );
            }

            // Shipping overrides
            if (v['weight_value'].toString().isNotEmpty) {
              vMap['weight_value'] = double.tryParse(
                v['weight_value'].toString(),
              );
              vMap['weight_unit'] = v['weight_unit'];
            }
            if (v['length_value'].toString().isNotEmpty) {
              vMap['length_value'] = double.tryParse(
                v['length_value'].toString(),
              );
            }
            if (v['width_value'].toString().isNotEmpty) {
              vMap['width_value'] = double.tryParse(
                v['width_value'].toString(),
              );
            }
            if (v['height_value'].toString().isNotEmpty) {
              vMap['height_value'] = double.tryParse(
                v['height_value'].toString(),
              );
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
      if (productId == null) {
        await apiService.createProduct(productData);
      } else {
        await apiService.updateProduct(productId, productData);
      }
      ref.invalidate(productsProvider);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
      return false;
    }
  }
}

final productEditorProvider =
    NotifierProvider.autoDispose.family<
      ProductEditorNotifier,
      ProductEditorState,
      Product?
    >(ProductEditorNotifier.new);
