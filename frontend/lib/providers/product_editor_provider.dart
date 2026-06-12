import 'dart:async';
import 'package:flutter/foundation.dart';
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
            'values': <String>[],
          }
        ],
        variants: [
          {
            'variant_id': null,
            'sku': '',
            'barcode': '',
            'price': '0.00',
            'compare_at_price': '',
            'stock': '0',
            'is_default': true,
            'is_active': true,
            'option_values': <String, String>{},
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
    final hasColor = opts.any((opt) => opt['name'].toString().trim().toLowerCase() == 'color');
    if (!hasColor) {
      opts.add({
        'name': 'Color',
        'values': <String>[],
      });
    }

    final List<Map<String, dynamic>> vars = [];
    for (var v in product.variants) {
      vars.add({
        'variant_id': v.id,
        'sku': v.sku,
        'original_sku': v.sku,
        'barcode': v.barcode ?? '',
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
    if (state.slug.trim().isEmpty) {
      // Build slug: lowercase, collapse non-alphanum to hyphens, strip leading/trailing hyphens
      final rawSlug = val
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\-]'), '-')
          .replaceAll(RegExp(r'-+'), '-');
      final generatedSlug = rawSlug
          .replaceAll(RegExp(r'^-+'), '')
          .replaceAll(RegExp(r'-+$'), '');
      updateSlug(generatedSlug);
    }
  }

  void updateSlug(String val) {
    final oldSlug = state.slug;
    state = state.copyWith(slug: val);

    final activeOpts = state.optionsSchema.where((opt) {
      final name = (opt['name'] as String? ?? '').trim();
      final values = List<dynamic>.from(opt['values'] ?? []);
      return name.isNotEmpty && values.isNotEmpty;
    }).toList();

    if (activeOpts.isEmpty && state.variants.length == 1) {
      final baseVar = state.variants.first;
      final currentSku = (baseVar['sku'] as String? ?? '').trim();
      final expectedOldSku = oldSlug.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\-]'), '-');

      if (currentSku.isEmpty || currentSku == expectedOldSku) {
        // Build SKU: uppercase slug, strip leading/trailing hyphens
        final rawSku = val
            .toUpperCase()
            .replaceAll(RegExp(r'[^A-Z0-9\-]'), '-')
            .replaceAll(RegExp(r'-+'), '-');
        final newSku = rawSku
            .replaceAll(RegExp(r'^-+'), '')
            .replaceAll(RegExp(r'-+$'), '');
        final updatedVariants = [
          {
            ...baseVar,
            'sku': newSku,
          }
        ];
        state = state.copyWith(variants: updatedVariants);
      }
    }
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
    final List<Map<String, dynamic>> updated = val.map((m) => Map<String, dynamic>.from(m)).toList();
    final hasColor = updated.any((opt) => opt['name'].toString().trim().toLowerCase() == 'color');
    if (!hasColor) {
      updated.insert(0, {
        'name': 'Color',
        'values': <String>[],
      });
    }
    state = state.copyWith(optionsSchema: updated);
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
        'barcode': '',
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

  /// Dry-run: returns the list of currently active variants that WOULD be
  /// retired (made inactive) if [generateVariantsFromOptions] were called now.
  ///
  /// For the full-collapse case (zero active options) every active
  /// option-based variant is returned.  For a partial reconciliation the
  /// returned list contains only those old variants that have no matching
  /// permutation in the new option set.
  ///
  /// Does NOT modify state.
  List<Map<String, dynamic>> computeRetiringVariants() {
    final activeOptions = state.optionsSchema.where((opt) {
      final name = (opt['name'] as String? ?? '').trim();
      final values = List<dynamic>.from(opt['values'] ?? []);
      return name.isNotEmpty && values.isNotEmpty;
    }).toList();

    final oldVariants = state.variants;

    // Full-collapse case: every active option-based variant will be retired.
    if (activeOptions.isEmpty) {
      return oldVariants.where((v) {
        final optVals = Map<String, String>.from(v['option_values'] ?? {});
        return v['is_active'] != false && optVals.isNotEmpty;
      }).toList();
    }

    // Build new permutations (same logic as generateVariantsFromOptions).
    List<Map<String, String>> cartesian(
        List<Map<String, dynamic>> opts, int idx) {
      if (idx == opts.length) return [{}];
      final cur = opts[idx];
      final name = cur['name'] as String;
      final vals = List<String>.from(cur['values'] ?? []);
      final sub = cartesian(opts, idx + 1);
      return [for (var v in vals) for (var s in sub) {name: v, ...s}];
    }

    final permutations = cartesian(activeOptions, 0);

    // For each old active option-based variant, check if ANY permutation
    // partially or fully matches it.  If none match → it will be retired.
    final Set<Map<String, dynamic>> matched = {};
    for (var perm in permutations) {
      for (var oldVar in oldVariants) {
        final oldOpts = Map<String, String>.from(oldVar['option_values'] ?? {});
        if (oldOpts.isEmpty) continue;
        final intersect = perm.keys.where((k) => oldOpts.containsKey(k));
        if (intersect.isNotEmpty &&
            intersect.every((k) => perm[k] == oldOpts[k])) {
          matched.add(oldVar);
        }
      }
    }

    return oldVariants.where((v) {
      final optVals = Map<String, String>.from(v['option_values'] ?? {});
      return v['is_active'] != false &&
          optVals.isNotEmpty &&
          !matched.contains(v);
    }).toList();
  }

  void generateVariantsFromOptions({bool reconcile = false}) {
    final activeOptions = state.optionsSchema.where((opt) {
      final name = (opt['name'] as String? ?? '').trim();
      final values = List<dynamic>.from(opt['values'] ?? []);
      return name.isNotEmpty && values.isNotEmpty;
    }).toList();

    final oldVariants = state.variants;

    if (activeOptions.isEmpty) {
      // Collapse to No-Options Base Variant Behavior
      if (oldVariants.isEmpty) return;

      // Find the last active default variant to inherit values
      final defaultActiveVar = oldVariants.firstWhere(
        (v) => v['is_default'] == true && v['is_active'] != false,
        orElse: () => oldVariants.firstWhere(
          (v) => v['is_active'] != false,
          orElse: () => oldVariants.first,
        ),
      );

      // Sum stock of all currently active option-based variants
      int totalStock = 0;
      final List<Map<String, dynamic>> deactivatedList = [];
      for (var v in oldVariants) {
        final optVals = Map<String, String>.from(v['option_values'] ?? {});
        if (v['is_active'] != false && optVals.isNotEmpty) {
          totalStock += int.tryParse(v['stock']?.toString() ?? '0') ?? 0;
          deactivatedList.add(v);
        }
      }

      // Look for an existing retired/deactivated base variant (where option_values is empty)
      var baseVarIndex = oldVariants.indexWhere((v) {
        final optVals = Map<String, String>.from(v['option_values'] ?? {});
        return optVals.isEmpty;
      });

      final List<Map<String, dynamic>> updatedVariants = [];
      Map<String, dynamic> baseVar;

      if (baseVarIndex != -1) {
        // Recycle the existing base variant
        baseVar = Map<String, dynamic>.from(oldVariants[baseVarIndex]);
      } else {
        // Create a new base variant if none existed historically
        // Strip any leading/trailing hyphens from the generated SKU
        final rawBaseSku = state.slug
            .toUpperCase()
            .replaceAll(RegExp(r'[^A-Z0-9\-]'), '-')
            .replaceAll(RegExp(r'-+'), '-');
        final cleanBaseSku = rawBaseSku
            .replaceAll(RegExp(r'^-+'), '')
            .replaceAll(RegExp(r'-+$'), '');
        baseVar = {
          'variant_id': null,
          'sku': cleanBaseSku,
          'original_sku': '',
          'option_values': <String, String>{},
        };
      }

      // Overwrite base variant properties with default variant values & summed stock
      baseVar['is_active'] = true;
      baseVar['is_default'] = true;
      baseVar['price'] = defaultActiveVar['price'] ?? '0.00';
      baseVar['compare_at_price'] = defaultActiveVar['compare_at_price'] ?? '';
      baseVar['stock'] = totalStock.toString();
      baseVar['images'] = List<String>.from(defaultActiveVar['images'] ?? []);
      baseVar['image_url'] = defaultActiveVar['image_url'];
      baseVar['weight_value'] = defaultActiveVar['weight_value'] ?? '';
      baseVar['weight_unit'] = defaultActiveVar['weight_unit'] ?? 'kg';
      baseVar['length_value'] = defaultActiveVar['length_value'] ?? '';
      baseVar['width_value'] = defaultActiveVar['width_value'] ?? '';
      baseVar['height_value'] = defaultActiveVar['height_value'] ?? '';
      baseVar['dimension_unit'] = defaultActiveVar['dimension_unit'] ?? 'cm';
      baseVar['show_shipping_overrides'] = defaultActiveVar['show_shipping_overrides'] ?? false;
      baseVar['is_expanded'] = false;

      updatedVariants.add(baseVar);

      // Silently retire all other option-based variants (if they have database IDs)
      for (var i = 0; i < oldVariants.length; i++) {
        if (i == baseVarIndex) continue;
        final v = oldVariants[i];
        final optVals = Map<String, String>.from(v['option_values'] ?? {});
        if (v['variant_id'] != null && optVals.isNotEmpty) {
          final retiredVar = Map<String, dynamic>.from(v);
          retiredVar['is_active'] = false;
          retiredVar['is_default'] = false;
          updatedVariants.add(retiredVar);
        }
      }

      state = state.copyWith(variants: updatedVariants);

      // Print summary report to debug console if running in debug mode
      if (kDebugMode) {
        debugPrint('================================================================');
        debugPrint('MANDATORY COLLAPSE VARIANT REPORT (DEACTIVATED VARIANTS)');
        debugPrint('Product: ${state.title} (${state.slug})');
        debugPrint('Deactivated Option-Based Variants:');
        for (var v in deactivatedList) {
          final optVals = Map<String, String>.from(v['option_values'] ?? {});
          final optStr = optVals.entries.map((e) => '${e.key}: ${e.value}').join(', ');
          debugPrint('  - SKU: ${v['sku']} ($optStr) | Price: \$${v['price']} | Stock: ${v['stock']}');
        }
        debugPrint('Collapsed Base Variant:');
        debugPrint('  - SKU: ${baseVar['sku']} | Price: \$${baseVar['price']} | Total Summed Stock: $totalStock');
        debugPrint('================================================================');
      }
      return;
    }

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
    final Set<Map<String, dynamic>> usedOldVariants = {};

    final defaultOldVariant = oldVariants.isNotEmpty
        ? oldVariants.firstWhere(
            (v) => v['is_default'] == true,
            orElse: () => oldVariants.first,
          )
        : null;

    // Look for a base variant to use as prefix SKU template
    final baseVar = oldVariants.firstWhere(
      (v) => Map<String, String>.from(v['option_values'] ?? {}).isEmpty,
      orElse: () => <String, dynamic>{},
    );

    for (var i = 0; i < permutations.length; i++) {
      final perm = permutations[i];

      // Default fallback generation for SKU using base variant SKU if available
      final optionStr = perm.values.join('-');
      final baseSku = (baseVar.isNotEmpty && (baseVar['sku'] as String? ?? '').isNotEmpty)
          ? baseVar['sku'] as String
          : state.slug.toUpperCase();
      final defaultSuffix = optionStr.toUpperCase().replaceAll(
        RegExp(r'[^A-Z0-9\-]'),
        '-',
      ).replaceAll(RegExp(r'-+'), '-');

      // Trim leading/trailing dashes from suffix
      String cleanSuffix = defaultSuffix;
      if (cleanSuffix.startsWith('-')) cleanSuffix = cleanSuffix.substring(1);
      if (cleanSuffix.endsWith('-')) cleanSuffix = cleanSuffix.substring(0, cleanSuffix.length - 1);

      final defaultSku = baseSku.isNotEmpty
          ? (cleanSuffix.isNotEmpty ? '$baseSku-$cleanSuffix' : baseSku)
          : cleanSuffix;

      if (reconcile && oldVariants.isNotEmpty) {
        // Step 1: Identify Overlap Matches (skip empty option base variants)
        final matches = oldVariants.where((oldVar) {
          final oldOpts = Map<String, String>.from(oldVar['option_values'] ?? {});
          if (oldOpts.isEmpty) return false;
          final intersectionKeys = perm.keys.where((k) => oldOpts.containsKey(k));
          if (intersectionKeys.isEmpty) return false;
          return intersectionKeys.every((k) => perm[k] == oldOpts[k]);
        }).toList();

        if (matches.isNotEmpty) {
          // Step 2: Priority Sorting
          matches.sort((a, b) {
            final aOpts = Map<String, String>.from(a['option_values'] ?? {});
            final bOpts = Map<String, String>.from(b['option_values'] ?? {});
            
            // 1. Perfect Match
            final aIsPerfect = aOpts.length == perm.length;
            final bIsPerfect = bOpts.length == perm.length;
            if (aIsPerfect && !bIsPerfect) return -1;
            if (!aIsPerfect && bIsPerfect) return 1;

            // 2. Default Variant
            final aIsDefault = a['is_default'] == true;
            final bIsDefault = b['is_default'] == true;
            if (aIsDefault && !bIsDefault) return -1;
            if (!aIsDefault && bIsDefault) return 1;

            return 0;
          });

          final bestMatch = matches.first;
          final bestMatchOpts = Map<String, String>.from(bestMatch['option_values'] ?? {});
          final isPerfectMatch = bestMatchOpts.length == perm.length;

          // Step 3: Value Propagation
          dynamic variantId;
          String sku;

          if (isPerfectMatch) {
            variantId = bestMatch['variant_id'];
            sku = bestMatch['sku'] ?? '';
            usedOldVariants.add(bestMatch);
          } else {
            // Partial Match (split / add / remove options)
            if (bestMatch['variant_id'] != null && !usedOldVariants.contains(bestMatch)) {
              variantId = bestMatch['variant_id'];
              usedOldVariants.add(bestMatch);
            } else {
              variantId = null;
            }

            // Suffix generation
            final newKeys = perm.keys.where((k) => !bestMatchOpts.containsKey(k)).toList();
            if (newKeys.isNotEmpty) {
              final suffixParts = newKeys.map((k) => perm[k]!).join('-');
              final suffix = suffixParts.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\-]'), '-');
              final baseOldSku = bestMatch['sku'] as String? ?? '';
              sku = baseOldSku.isNotEmpty ? '$baseOldSku-$suffix' : '';
            } else {
              sku = bestMatch['sku'] as String? ?? '';
            }
          }

          newVariants.add({
            'variant_id': variantId,
            'sku': sku,
            'original_sku': bestMatch['original_sku'] ?? bestMatch['sku'],
            'barcode': bestMatch['barcode'] ?? '',
            'price': bestMatch['price'] ?? '0.00',
            'compare_at_price': bestMatch['compare_at_price'] ?? '',
            'stock': bestMatch['stock'] ?? '0',
            'is_default': bestMatch['is_default'] ?? (i == 0),
            'is_active': bestMatch['is_active'] ?? true,
            'option_values': perm,
            'images': List<String>.from(bestMatch['images'] ?? []),
            'image_url': bestMatch['image_url'],
            'weight_value': bestMatch['weight_value'] ?? '',
            'weight_unit': bestMatch['weight_unit'] ?? 'kg',
            'length_value': bestMatch['length_value'] ?? '',
            'width_value': bestMatch['width_value'] ?? '',
            'height_value': bestMatch['height_value'] ?? '',
            'dimension_unit': bestMatch['dimension_unit'] ?? 'cm',
            'show_shipping_overrides': bestMatch['show_shipping_overrides'] ?? false,
            'is_expanded': false,
          });
          continue;
        }
      }

      final fallbackPrice = (reconcile && defaultOldVariant != null) ? (defaultOldVariant['price'] ?? '0.00') : '0.00';
      final fallbackCompareAt = (reconcile && defaultOldVariant != null) ? (defaultOldVariant['compare_at_price'] ?? '') : '';
      final fallbackStock = (reconcile && defaultOldVariant != null) ? (defaultOldVariant['stock'] ?? '0') : '0';
      final fallbackWeightVal = (reconcile && defaultOldVariant != null) ? (defaultOldVariant['weight_value'] ?? '') : '';
      final fallbackWeightUnit = (reconcile && defaultOldVariant != null) ? (defaultOldVariant['weight_unit'] ?? 'kg') : 'kg';
      final fallbackLengthVal = (reconcile && defaultOldVariant != null) ? (defaultOldVariant['length_value'] ?? '') : '';
      final fallbackWidthVal = (reconcile && defaultOldVariant != null) ? (defaultOldVariant['width_value'] ?? '') : '';
      final fallbackHeightVal = (reconcile && defaultOldVariant != null) ? (defaultOldVariant['height_value'] ?? '') : '';
      final fallbackDimUnit = (reconcile && defaultOldVariant != null) ? (defaultOldVariant['dimension_unit'] ?? 'cm') : 'cm';
      final fallbackShippingOverride = (reconcile && defaultOldVariant != null) ? (defaultOldVariant['show_shipping_overrides'] ?? false) : false;

      // Fresh generation or no match found
      newVariants.add({
        'variant_id': null,
        'sku': defaultSku,
        'barcode': '',
        'price': fallbackPrice,
        'compare_at_price': fallbackCompareAt,
        'stock': fallbackStock,
        'is_default': i == 0,
        'is_active': true,
        'option_values': perm,
        'images': <String>[],
        'image_url': null,
        'weight_value': fallbackWeightVal,
        'weight_unit': fallbackWeightUnit,
        'length_value': fallbackLengthVal,
        'width_value': fallbackWidthVal,
        'height_value': fallbackHeightVal,
        'dimension_unit': fallbackDimUnit,
        'show_shipping_overrides': fallbackShippingOverride,
        'is_expanded': false,
      });
    }

    // Collect retired variants (old variants not used in any new permutation)
    final List<Map<String, dynamic>> retiredVars = [];
    for (var oldVar in oldVariants) {
      if (!usedOldVariants.contains(oldVar)) {
        retiredVars.add(oldVar);
      }
    }

    // Aggregate stock from retired variants into the first surviving active variant.
    // Only during Intelligent Reconciliation — Fresh Generation is a clean slate.
    if (reconcile && retiredVars.isNotEmpty) {
      int retiredStock = 0;
      for (var rv in retiredVars) {
        if (rv['is_active'] != false) {
          retiredStock += int.tryParse(rv['stock']?.toString() ?? '0') ?? 0;
        }
      }
      if (retiredStock > 0 && newVariants.isNotEmpty) {
        final firstActive = newVariants.indexWhere((v) => v['is_active'] != false);
        if (firstActive != -1) {
          final existingStock = int.tryParse(newVariants[firstActive]['stock']?.toString() ?? '0') ?? 0;
          newVariants[firstActive] = Map<String, dynamic>.from(newVariants[firstActive])
            ..['stock'] = (existingStock + retiredStock).toString();
          if (kDebugMode) {
            debugPrint('Stock from retired variants ($retiredStock units) added to ${newVariants[firstActive]['sku']}');
          }
        }
      }
    }

    // Append retired variants with database IDs as is_active:false so the
    // backend can mark them inactive on save.
    for (var rv in retiredVars) {
      if (rv['variant_id'] != null) {
        final retiredVar = Map<String, dynamic>.from(rv)
          ..['is_active'] = false
          ..['is_default'] = false;
        newVariants.add(retiredVar);
      }
    }

    state = state.copyWith(variants: newVariants);
  }

  Future<bool> save(ApiService apiService, String? productId, {bool emailSkuReport = false}) async {
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
      'options_schema': state.optionsSchema
          .where((opt) => List.from(opt['values'] ?? []).isNotEmpty)
          .toList(),
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
              'barcode': v['barcode']?.toString().trim().isEmpty == true ? null : v['barcode'].toString().trim(),
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
        await apiService.updateProduct(productId, productData, emailSkuReport: emailSkuReport);
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
