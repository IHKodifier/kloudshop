import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/models/hygiene.dart';
import 'package:kloudshop/services/api_service.dart';

final systemStatusProvider = FutureProvider<SystemStatus>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSystemStatus();
});

final schemaHealthProvider = FutureProvider<SchemaHealth>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getSchemaHealth();
});
