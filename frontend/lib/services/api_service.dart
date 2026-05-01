import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/services/auth_service.dart';
import 'package:kloudshop/models/user_claims.dart';
import 'package:kloudshop/models/subscription.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ApiService(authService);
});

class ApiService {
  final AuthService _authService;
  final String baseUrl = 'http://127.0.0.1:8000/api/v1';

  ApiService(this._authService);

  Future<Map<String, String>> _getHeaders({bool forceRefresh = false}) async {
    final token = await _authService.getIdToken(forceRefresh: forceRefresh);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<UserClaims?> getMe({bool forceRefresh = false}) async {
    try {
      final headers = await _getHeaders(forceRefresh: forceRefresh);
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserClaims.fromJson(data);
      } else if (response.statusCode == 403) {
        log('User authenticated but lacks tenant_id or permissions.');
        // We might want to throw a specific error here to handle onboarding
        throw ApiException(response.statusCode, 'Access forbidden: Missing tenant or permissions');
      } else {
        throw ApiException(response.statusCode, 'Failed to fetch user claims: ${response.body}');
      }
    } catch (e) {
      log('ApiService.getMe error: $e');
      rethrow;
    }
  }

  Future<SubscriptionModel> getSubscription() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/billing/subscription'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return SubscriptionModel.fromJson(jsonDecode(response.body));
      } else {
        throw ApiException(response.statusCode, 'Failed to fetch subscription: ${response.body}');
      }
    } catch (e) {
      log('ApiService.getSubscription error: $e');
      rethrow;
    }
  }

  Future<String> createUpgradeSession(String planId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/billing/upgrade'),
        headers: headers,
        body: jsonEncode({
          'plan_id': planId,
          'success_url': 'http://localhost:3000/dashboard?session_id={CHECKOUT_SESSION_ID}',
          'cancel_url': 'http://localhost:3000/dashboard',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String;
      } else {
        throw ApiException(response.statusCode, 'Failed to create upgrade session: ${response.body}');
      }
    } catch (e) {
      log('ApiService.createUpgradeSession error: $e');
      rethrow;
    }
  }

  Future<void> provisionTenant(String tenantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/internal/provision-tenant?tenant_id=$tenantId'),
        headers: headers,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        log('Tenant provisioned successfully: ${response.body}');
      } else {
        throw ApiException(response.statusCode, 'Failed to provision tenant: ${response.body}');
      }
    } catch (e) {
      log('ApiService.provisionTenant error: $e');
      rethrow;
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
