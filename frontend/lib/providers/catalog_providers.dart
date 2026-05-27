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

final productSearchQueryProvider = NotifierProvider<ProductSearchQuery, String>(
  ProductSearchQuery.new,
);

enum CatalogStatusFilter { all, active, draft, archived }

class ProductStatusFilterNotifier extends Notifier<CatalogStatusFilter> {
  @override
  CatalogStatusFilter build() => CatalogStatusFilter.all;
  void setFilter(CatalogStatusFilter filter) => state = filter;
}

final productStatusFilterProvider =
    NotifierProvider<ProductStatusFilterNotifier, CatalogStatusFilter>(
      ProductStatusFilterNotifier.new,
    );

final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final searchQuery = ref.watch(productSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(productStatusFilterProvider);

  return productsAsync.whenData((products) {
    var filtered = products;

    // Status Filter
    if (statusFilter != CatalogStatusFilter.all) {
      final statusStr = statusFilter.name;
      filtered = filtered
          .where((p) => p.status.toLowerCase() == statusStr)
          .toList();
    }

    // Search Filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (p) =>
                p.title.toLowerCase().contains(searchQuery) ||
                p.slug.toLowerCase().contains(searchQuery),
          )
          .toList();
    }

    return filtered;
  });
});
