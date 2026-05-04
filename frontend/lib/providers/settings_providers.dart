import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/models/settings.dart';
import 'package:kloudshop/services/api_service.dart';

final tenantSettingsProvider = FutureProvider<TenantSettings>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getTenantSettings();
});
