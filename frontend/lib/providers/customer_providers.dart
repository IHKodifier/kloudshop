import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/models/customer.dart';
import 'package:kloudshop/services/api_service.dart';

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.listCustomers();
});

class CustomerSearchQuery extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

final customerSearchQueryProvider =
    NotifierProvider<CustomerSearchQuery, String>(CustomerSearchQuery.new);

final filteredCustomersProvider = Provider<AsyncValue<List<Customer>>>((ref) {
  final customersAsync = ref.watch(customersProvider);
  final searchQuery = ref.watch(customerSearchQueryProvider).toLowerCase();

  return customersAsync.whenData((customers) {
    if (searchQuery.isEmpty) return customers;
    return customers
        .where((c) => c.email.toLowerCase().contains(searchQuery))
        .toList();
  });
});
