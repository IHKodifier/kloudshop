import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/services/auth_service.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/models/user_claims.dart';

final userClaimsProvider = FutureProvider<UserClaims?>((ref) async {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) async {
      if (user == null) return null;

      final apiService = ref.read(apiServiceProvider);
      try {
        final claims = await apiService.getMe();
        return claims;
      } catch (e) {
        rethrow;
      }
    },
    loading: () => null,
    error: (e, s) => throw e,
  );
});
