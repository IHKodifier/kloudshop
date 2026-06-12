class Product {
  final String id;
  final String title;
  final String slug;
  final String? description;
  final String status;
  final bool isDigital;
  final bool isPerishable;
  final String? metaTitle;
  final String? metaDescription;
  final List<String> images;
  final List<Map<String, dynamic>> optionsSchema;
  final double? weightValue;
  final String? weightUnit;
  final double? lengthValue;
  final double? widthValue;
  final double? heightValue;
  final String? dimensionUnit;
  final int? minimumAgeYears;
  final bool ageVerificationRequired;
  final bool requiresPrescription;
  final bool prescriptionDocumentRequired;
  final DateTime createdAt;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    required this.status,
    required this.isDigital,
    required this.isPerishable,
    this.metaTitle,
    this.metaDescription,
    this.images = const [],
    this.optionsSchema = const [],
    this.weightValue,
    this.weightUnit,
    this.lengthValue,
    this.widthValue,
    this.heightValue,
    this.dimensionUnit,
    this.minimumAgeYears,
    required this.ageVerificationRequired,
    required this.requiresPrescription,
    required this.prescriptionDocumentRequired,
    required this.createdAt,
    required this.variants,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['product_id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'draft',
      isDigital: json['is_digital'] as bool? ?? false,
      isPerishable: json['is_perishable'] as bool? ?? false,
      metaTitle: json['meta_title'] as String?,
      metaDescription: json['meta_description'] as String?,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      optionsSchema:
          (json['options_schema'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      weightValue: json['weight_value'] != null
          ? _toDouble(json['weight_value'])
          : null,
      weightUnit: json['weight_unit'] as String?,
      lengthValue: json['length_value'] != null
          ? _toDouble(json['length_value'])
          : null,
      widthValue: json['width_value'] != null
          ? _toDouble(json['width_value'])
          : null,
      heightValue: json['height_value'] != null
          ? _toDouble(json['height_value'])
          : null,
      dimensionUnit: json['dimension_unit'] as String?,
      minimumAgeYears: json['minimum_age_years'] as int?,
      ageVerificationRequired:
          json['age_verification_required'] as bool? ?? false,
      requiresPrescription: json['requires_prescription'] as bool? ?? false,
      prescriptionDocumentRequired:
          json['prescription_document_required'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      variants:
          (json['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class ProductVariant {
  final String id;
  final String sku;
  final String? barcode;
  final double price;
  final double? compareAtPrice;
  final Map<String, String> optionValues;
  final int? stock;
  final bool isDefault;
  final bool isActive;
  final String? imageUrl;
  final List<String> images;
  final double? weightValue;
  final String? weightUnit;
  final double? lengthValue;
  final double? widthValue;
  final double? heightValue;
  final String? dimensionUnit;

  ProductVariant({
    required this.id,
    required this.sku,
    this.barcode,
    required this.price,
    this.compareAtPrice,
    this.optionValues = const {},
    this.stock,
    required this.isDefault,
    required this.isActive,
    this.imageUrl,
    this.images = const [],
    this.weightValue,
    this.weightUnit,
    this.lengthValue,
    this.widthValue,
    this.heightValue,
    this.dimensionUnit,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['variant_id'] as String,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String?,
      price: _toDouble(json['price']),
      compareAtPrice: json['compare_at_price'] != null
          ? _toDouble(json['compare_at_price'])
          : null,
      optionValues: json['option_values'] != null
          ? Map<String, String>.from(json['option_values'] as Map)
          : const {},
      stock: _toInt(json['stock']),
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      weightValue: json['weight_value'] != null
          ? _toDouble(json['weight_value'])
          : null,
      weightUnit: json['weight_unit'] as String?,
      lengthValue: json['length_value'] != null
          ? _toDouble(json['length_value'])
          : null,
      widthValue: json['width_value'] != null
          ? _toDouble(json['width_value'])
          : null,
      heightValue: json['height_value'] != null
          ? _toDouble(json['height_value'])
          : null,
      dimensionUnit: json['dimension_unit'] as String?,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
