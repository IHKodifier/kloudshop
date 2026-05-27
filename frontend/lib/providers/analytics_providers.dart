import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/models/analytics.dart';
import 'package:kloudshop/services/api_service.dart';

final analyticsOverviewProvider = FutureProvider<AnalyticsOverview>((
  ref,
) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getAnalyticsOverview();
});

final needsAttentionProvider = FutureProvider<NeedsAttention>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getNeedsAttention();
});
