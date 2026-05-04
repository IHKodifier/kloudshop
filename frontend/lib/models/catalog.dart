class Product {
  final String id;
  final String title;
  final String slug;
  final String? description;
  final String status;
  final bool isDigital;
  final DateTime createdAt;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    required this.status,
    required this.isDigital,
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
      createdAt: DateTime.parse(json['created_at'] as String),
      variants: (json['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ProductVariant {
  final String id;
  final String sku;
  final double price;
  final double? compareAtPrice;
  final String? option1;
  final String? option2;
  final String? option3;
  final int? stock;
  final bool isDefault;
  final bool isActive;

  ProductVariant({
    required this.id,
    required this.sku,
    required this.price,
    this.compareAtPrice,
    this.option1,
    this.option2,
    this.option3,
    this.stock,
    required this.isDefault,
    required this.isActive,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['variant_id'] as String,
      sku: json['sku'] as String,
      price: (json['price'] as num).toDouble(),
      compareAtPrice: json['compare_at_price'] != null
          ? (json['compare_at_price'] as num).toDouble()
          : null,
      option1: json['option_1'] as String?,
      option2: json['option_2'] as String?,
      option3: json['option_3'] as String?,
      stock: (json['stock'] as num?)?.toInt(),
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
