import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/models/catalog.dart';
import 'package:kloudshop/services/api_service.dart';

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.listProducts();
});

class ProductSearchQuery extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

final productSearchQueryProvider = NotifierProvider<ProductSearchQuery, String>(ProductSearchQuery.new);

final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final searchQuery = ref.watch(productSearchQueryProvider).toLowerCase();

  return productsAsync.whenData((products) {
    if (searchQuery.isEmpty) return products;
    return products.where((p) => 
      p.title.toLowerCase().contains(searchQuery) || 
      p.slug.toLowerCase().contains(searchQuery)
    ).toList();
  });
});
