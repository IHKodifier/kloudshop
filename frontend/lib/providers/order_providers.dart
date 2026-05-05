import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/models/order.dart';
import 'package:kloudshop/services/api_service.dart';

class OrdersStatusFilter extends Notifier<String?> {
  @override
  String? build() => null;
  void setStatus(String? status) => state = status;
}

final ordersStatusFilterProvider = NotifierProvider<OrdersStatusFilter, String?>(OrdersStatusFilter.new);

final ordersProvider = FutureProvider<List<Order>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final status = ref.watch(ordersStatusFilterProvider);
  return apiService.listOrders(status: status);
});

final orderDetailsProvider = FutureProvider.family<Order, String>((ref, id) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getOrderDetails(id);
});

class OrderActionLoading extends Notifier<bool> {
  @override
  bool build() => false;
  void setLoading(bool loading) => state = loading;
}

final orderActionLoadingProvider = NotifierProvider<OrderActionLoading, bool>(OrderActionLoading.new);
