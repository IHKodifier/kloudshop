import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/services/auth_service.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/models/user_claims.dart';

class ForceRefreshClaims extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle(bool value) => state = value;
}

final forceRefreshClaimsProvider = NotifierProvider<ForceRefreshClaims, bool>(
  ForceRefreshClaims.new,
);

final userClaimsProvider = FutureProvider<UserClaims?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final forceRefresh = ref.watch(forceRefreshClaimsProvider);

  return authState.when(
    data: (user) async {
      if (user == null) return null;

      final apiService = ref.read(apiServiceProvider);
      try {
        final claims = await apiService.getMe(forceRefresh: forceRefresh);

        // Reset the force refresh flag after a successful fetch
        if (forceRefresh) {
          Future.microtask(
            () => ref.read(forceRefreshClaimsProvider.notifier).toggle(false),
          );
        }

        return claims;
      } catch (e) {
        rethrow;
      }
    },
    loading: () => null,
    error: (e, s) => throw e,
  );
});
