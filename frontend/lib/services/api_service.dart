import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/services/auth_service.dart';
import 'package:kloudshop/models/user_claims.dart';
import 'package:kloudshop/models/subscription.dart';
import 'package:kloudshop/models/analytics.dart';
import 'package:kloudshop/models/blog.dart';
import 'package:kloudshop/models/hygiene.dart';
import 'package:kloudshop/models/catalog.dart';
import 'package:kloudshop/models/order.dart';
import 'package:kloudshop/models/customer.dart';
import 'package:kloudshop/models/settings.dart';

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
        log('Subscription Response: ${response.body}');
        return SubscriptionModel.fromJson(jsonDecode(response.body));
      } else {
        throw ApiException(response.statusCode, 'Failed to fetch subscription: ${response.body}');
      }
    } catch (e) {
      log('ApiService.getSubscription error: $e');
      rethrow;
    }
  }

  Future<String> createUpgradeSession(String planId, {String? successUrl, String? cancelUrl}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/billing/upgrade'),
        headers: headers,
        body: jsonEncode({
          'plan_id': planId,
          'success_url': successUrl ?? 'http://localhost:3000/dashboard?session_id={CHECKOUT_SESSION_ID}',
          'cancel_url': cancelUrl ?? 'http://localhost:3000/dashboard',
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

  Future<void> verifyUpgradeSession(String sessionId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/billing/complete-upgrade?session_id=$sessionId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to verify upgrade session: ${response.body}');
    }
  }

  Future<void> seedDemoData() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/internal/seed-demo-data'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(response.statusCode, 'Failed to seed demo data: ${response.body}');
      }
    } catch (e) {
      log('ApiService.seedDemoData error: $e');
      rethrow;
    }
  }

  // --- Analytics ---
  Future<AnalyticsOverview> getAnalyticsOverview() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/overview'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return AnalyticsOverview.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to fetch analytics: ${response.body}');
    }
  }

  Future<NeedsAttention> getNeedsAttention() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/needs-attention'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return NeedsAttention.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to fetch alerts: ${response.body}');
    }
  }

  // --- Blog ---
  Future<List<BlogPost>> listBlogPosts({String? status}) async {
    final headers = await _getHeaders();
    final queryParams = status != null ? '?status=$status' : '';
    final response = await http.get(
      Uri.parse('$baseUrl/blog/posts$queryParams'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => BlogPost.fromJson(item)).toList();
    } else {
      throw ApiException(response.statusCode, 'Failed to list posts: ${response.body}');
    }
  }

  Future<BlogPost> createBlogPost(Map<String, dynamic> postData) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/blog/posts'),
      headers: headers,
      body: jsonEncode(postData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return BlogPost.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to create post: ${response.body}');
    }
  }

  Future<BlogPost> updateBlogPost(String id, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/blog/posts/$id'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return BlogPost.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to update blog post: ${response.body}');
    }
  }

  Future<void> deleteBlogPost(String postId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/blog/posts/$postId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to delete post: ${response.body}');
    }
  }

  // --- Hygiene & Compliance ---
  Future<SystemStatus> getSystemStatus() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/internal/version'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return SystemStatus.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to fetch system status: ${response.body}');
    }
  }

  Future<SchemaHealth> getSchemaHealth() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/internal/health/schema-drift'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return SchemaHealth.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to fetch schema health: ${response.body}');
    }
  }

  Future<void> triggerGdprErasure(String email) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/internal/gdpr/erasure'),
      headers: headers,
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to trigger erasure: ${response.body}');
    }
  }

  // --- Catalog ---
  Future<List<Product>> listProducts({String? status, String? search}) async {
    final headers = await _getHeaders();
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (search != null) params['search'] = search;
    
    final uri = Uri.parse('$baseUrl/products/').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Product.fromJson(item)).toList();
    } else {
      throw ApiException(response.statusCode, 'Failed to list products: ${response.body}');
    }
  }

  Future<Product> createProduct(Map<String, dynamic> productData) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/products/'),
      headers: headers,
      body: jsonEncode(productData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to create product: ${response.body}');
    }
  }

  Future<Product> updateProduct(String productId, Map<String, dynamic> productData) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/products/$productId'),
      headers: headers,
      body: jsonEncode(productData),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to update product: ${response.body}');
    }
  }

  Future<void> deleteProduct(String productId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$productId'),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(response.statusCode, 'Failed to delete product: ${response.body}');
    }
  }

  // --- Orders ---
  Future<List<Order>> listOrders({String? status}) async {
    final headers = await _getHeaders();
    final params = <String, String>{};
    if (status != null) params['status'] = status;

    final uri = Uri.parse('$baseUrl/orders/').replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Order.fromJson(item)).toList();
    } else {
      throw ApiException(response.statusCode, 'Failed to list orders: ${response.body}');
    }
  }

  Future<Order> getOrderDetails(String orderId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to fetch order: ${response.body}');
    }
  }

  Future<Order> fulfilOrder(String orderId, {String? trackingNumber, String? carrier}) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/fulfil'),
      headers: headers,
      body: jsonEncode({
        'tracking_number': trackingNumber,
        'carrier': carrier,
        'notify_customer': true,
      }),
    );

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to fulfil order: ${response.body}');
    }
  }

  Future<Order> refundOrder(String orderId, {double? amount, String? reason}) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/refund'),
      headers: headers,
      body: jsonEncode({
        'amount': amount,
        'reason': reason ?? 'Requested by merchant',
      }),
    );

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to refund order: ${response.body}');
    }
  }

  // --- Customers ---
  Future<List<Customer>> listCustomers() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/orders/customers'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Customer.fromJson(item)).toList();
    } else {
      throw ApiException(response.statusCode, 'Failed to list customers: ${response.body}');
    }
  }

  // --- Settings ---
  Future<TenantSettings> getTenantSettings() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/onboarding/tenant'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return TenantSettings.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to fetch settings: ${response.body}');
    }
  }

  Future<TenantSettings> updateTenantSettings(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/onboarding/tenant'),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return TenantSettings.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to update settings: ${response.body}');
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
