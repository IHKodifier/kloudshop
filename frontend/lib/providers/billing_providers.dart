import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/models/subscription.dart';
import 'package:kloudshop/services/api_service.dart';

final subscriptionProvider = FutureProvider<SubscriptionModel>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSubscription();
});
