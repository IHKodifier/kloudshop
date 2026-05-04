import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/models/customer.dart';
import 'package:kloudshop/services/api_service.dart';

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.listCustomers();
});
