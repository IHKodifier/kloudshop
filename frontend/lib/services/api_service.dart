import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/services/auth_service.dart';
import 'package:kloudshop/models/theme.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/models/user_claims.dart';
import 'package:kloudshop/models/subscription.dart';
import 'package:kloudshop/models/analytics.dart';
import 'package:kloudshop/models/blog.dart';
import 'package:kloudshop/models/hygiene.dart';
import 'package:kloudshop/models/catalog.dart';
import 'package:kloudshop/models/order.dart';
import 'package:kloudshop/models/customer.dart';
import 'package:kloudshop/models/settings.dart';
import 'package:kloudshop/models/color_preset.dart';

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

  Future<Map<String, String>> _getAppCheckHeaders() async {
    return {
      'Content-Type': 'application/json',
      'X-AppCheck-Bypass': 'true',
    };
  }

  Future<Map<String, dynamic>> getLoginStatus(String gmail) async {
    try {
      final headers = await _getAppCheckHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/login-status/$gmail'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException(response.statusCode, 'Failed to get login status: ${response.body}');
      }
    } catch (e) {
      log('ApiService.getLoginStatus error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendFailedLoginAlert({
    required String email,
    String? tenantId,
    String? userAgent,
  }) async {
    try {
      final headers = await _getAppCheckHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/failed-login-alert'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'tenant_id': tenantId,
          'user_agent': userAgent,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException(response.statusCode, 'Failed to send failed login alert: ${response.body}');
      }
    } catch (e) {
      log('ApiService.sendFailedLoginAlert error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> requestUnblock(String email) async {
    try {
      final headers = await _getAppCheckHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/unblock/request'),
        headers: headers,
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException(response.statusCode, 'Failed to request unblock: ${response.body}');
      }
    } catch (e) {
      log('ApiService.requestUnblock error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyUnblock(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/unblock/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException(response.statusCode, 'Failed to verify unblock token: ${response.body}');
      }
    } catch (e) {
      log('ApiService.verifyUnblock error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerConsumer({
    required String email,
    required String password,
    required String tenantId,
    String? fullName,
    Map<String, dynamic>? shippingAddress,
    String? orderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/consumers/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'tenant_id': tenantId,
          'full_name': fullName,
          'shipping_address': shippingAddress,
          'order_id': orderId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException(
          response.statusCode,
          'Registration failed: ${response.body}',
        );
      }
    } catch (e) {
      log('ApiService.registerConsumer error: $e');
      rethrow;
    }
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
        throw ApiException(
          response.statusCode,
          'Access forbidden: Missing tenant or permissions',
        );
      } else {
        throw ApiException(
          response.statusCode,
          'Failed to fetch user claims: ${response.body}',
        );
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
        throw ApiException(
          response.statusCode,
          'Failed to fetch subscription: ${response.body}',
        );
      }
    } catch (e) {
      log('ApiService.getSubscription error: $e');
      rethrow;
    }
  }

  Future<String> createUpgradeSession(
    String planId, {
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/billing/upgrade'),
        headers: headers,
        body: jsonEncode({
          'plan_id': planId,
          'success_url':
              successUrl ??
              'http://localhost:3000/dashboard?session_id={CHECKOUT_SESSION_ID}',
          'cancel_url': cancelUrl ?? 'http://localhost:3000/dashboard',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String;
      } else {
        throw ApiException(
          response.statusCode,
          'Failed to create upgrade session: ${response.body}',
        );
      }
    } catch (e) {
      log('ApiService.createUpgradeSession error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> provisionTenant(String tenantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/internal/provision-tenant?tenant_id=$tenantId'),
        headers: headers,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        log('Tenant provisioned successfully: ${response.body}');
        return jsonDecode(response.body);
      } else {
        throw ApiException(
          response.statusCode,
          'Failed to provision tenant: ${response.body}',
        );
      }
    } catch (e) {
      log('ApiService.provisionTenant error: $e');
      rethrow;
    }
  }

  Future<bool> checkTenantAvailability(String tenantId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/onboarding/check-availability?tenant_id=$tenantId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['available'] ?? false;
      }
      return false;
    } catch (e) {
      log('ApiService.checkTenantAvailability error: $e');
      return false;
    }
  }

  Future<void> verifyUpgradeSession(String sessionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/billing/complete-upgrade?session_id=$sessionId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw ApiException(
          response.statusCode,
          'Failed to verify upgrade session: ${response.body}',
        );
      }
    } catch (e) {
      log('ApiService.verifyUpgradeSession error: $e');
      rethrow;
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
        throw ApiException(
          response.statusCode,
          'Failed to seed demo data: ${response.body}',
        );
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
      throw ApiException(
        response.statusCode,
        'Failed to fetch analytics: ${response.body}',
      );
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
      throw ApiException(
        response.statusCode,
        'Failed to fetch alerts: ${response.body}',
      );
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
      throw ApiException(
        response.statusCode,
        'Failed to list posts: ${response.body}',
      );
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
      throw ApiException(
        response.statusCode,
        'Failed to create post: ${response.body}',
      );
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
      throw ApiException(
        response.statusCode,
        'Failed to update blog post: ${response.body}',
      );
    }
  }

  Future<void> deleteBlogPost(String postId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/blog/posts/$postId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        response.statusCode,
        'Failed to delete post: ${response.body}',
      );
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
      throw ApiException(
        response.statusCode,
        'Failed to fetch system status: ${response.body}',
      );
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
      throw ApiException(
        response.statusCode,
        'Failed to fetch schema health: ${response.body}',
      );
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
      throw ApiException(
        response.statusCode,
        'Failed to trigger erasure: ${response.body}',
      );
    }
  }

  // --- Catalog ---
  Future<List<Product>> listProducts({String? status, String? search}) async {
    final headers = await _getHeaders();
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (search != null) params['search'] = search;

    final uri = Uri.parse(
      '$baseUrl/products/',
    ).replace(queryParameters: params);
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Product.fromJson(item)).toList();
    } else {
      throw ApiException(
        response.statusCode,
        'Failed to list products: ${response.body}',
      );
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
      throw ApiException(
        response.statusCode,
        'Failed to create product: ${response.body}',
      );
    }
  }

  Future<Product> updateProduct(
    String productId,
    Map<String, dynamic> productData, {
    bool emailSkuReport = false,
  }) async {
    final headers = await _getHeaders();
    final url = emailSkuReport
        ? '$baseUrl/products/$productId?email_sku_report=true'
        : '$baseUrl/products/$productId';
    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(productData),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(
        response.statusCode,
        'Failed to update product: ${response.body}',
      );
    }
  }

  Future<void> deleteProduct(String productId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$productId'),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(
        response.statusCode,
        'Failed to delete product: ${response.body}',
      );
    }
  }

  // --- Color Presets ---
  Future<ColorPreset> createColorPreset(String name, String hexCode) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/products/color-presets'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'hex_code': hexCode,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ColorPreset.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(
        response.statusCode,
        'Failed to create color preset: ${response.body}',
      );
    }
  }

  Future<List<ColorPreset>> listColorPresets() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/products/color-presets'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => ColorPreset.fromJson(item)).toList();
    } else {
      throw ApiException(
        response.statusCode,
        'Failed to list color presets: ${response.body}',
      );
    }
  }

  Future<void> deleteColorPreset(String presetId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/products/color-presets/$presetId'),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(
        response.statusCode,
        'Failed to delete color preset: ${response.body}',
      );
    }
  }

  Future<ColorPreset> updateColorPreset(String presetId, String name, String hexCode) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/products/color-presets/$presetId'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'hex_code': hexCode,
      }),
    );

    if (response.statusCode == 200) {
      return ColorPreset.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(
        response.statusCode,
        'Failed to update color preset: ${response.body}',
      );
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
      throw ApiException(
        response.statusCode,
        'Failed to list orders: ${response.body}',
      );
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
      throw ApiException(
        response.statusCode,
        'Failed to fetch order: ${response.body}',
      );
    }
  }

  Future<Order> fulfilOrder(
    String orderId, {
    String? trackingNumber,
    String? carrier,
  }) async {
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
      throw ApiException(
        response.statusCode,
        'Failed to fulfil order: ${response.body}',
      );
    }
  }

  Future<Order> refundOrder(
    String orderId, {
    double? amount,
    String? reason,
  }) async {
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
      throw ApiException(
        response.statusCode,
        'Failed to refund order: ${response.body}',
      );
    }
  }

  // --- Consumer Self-Service ---
  Future<List<Order>> listConsumerOrders() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/orders/consumer/orders'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Order.fromJson(item)).toList();
    } else {
      throw ApiException(
        response.statusCode,
        'Failed to list orders: ${response.body}',
      );
    }
  }

  Future<Order> getConsumerOrderDetails(String orderId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/orders/consumer/orders/$orderId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(
        response.statusCode,
        'Failed to fetch order: ${response.body}',
      );
    }
  }

  Future<Order> requestReturn(
    String orderId, {
    required String reason,
    String? description,
    List<Map<String, dynamic>>? items,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/consumer/orders/$orderId/return'),
      headers: headers,
      body: jsonEncode({
        'reason': reason,
        'description': description,
        'items': items ?? [],
      }),
    );

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(
        response.statusCode,
        'Failed to request return: ${response.body}',
      );
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
      throw ApiException(
        response.statusCode,
        'Failed to list customers: ${response.body}',
      );
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
      throw ApiException(
        response.statusCode,
        'Failed to fetch settings: ${response.body}',
      );
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
      throw ApiException(
        response.statusCode,
        'Failed to update settings: ${response.body}',
      );
    }
  }

  // --- Themes ---

  Future<List<ThemeModel>> listThemes() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/themes'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => ThemeModel.fromJson(item)).toList();
    } else {
      throw ApiException(response.statusCode, 'Failed to list themes');
    }
  }

  Future<ThemeConfigModel?> getActiveTheme() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/themes/active'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return ThemeConfigModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw ApiException(response.statusCode, 'Failed to fetch active theme');
    }
  }

  Future<ThemeConfigModel> selectTheme(String themeId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/themes/select'),
      headers: headers,
      body: jsonEncode({'theme_id': themeId}),
    );

    if (response.statusCode == 200) {
      return ThemeConfigModel.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to select theme');
    }
  }

  Future<ThemeConfigModel> updateThemeConfig({
    String? name,
    Map<String, dynamic>? tokens,
    Map<String, dynamic>? slots,
  }) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/themes/config'),
      headers: headers,
      body: jsonEncode({
        if (name != null) 'name': name,
        'tokens': tokens,
        'slots': slots,
      }),
    );

    if (response.statusCode == 200) {
      return ThemeConfigModel.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to update theme config');
    }
  }

  Future<ThemeConfigModel> publishTheme() async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/themes/publish'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return ThemeConfigModel.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to publish theme');
    }
  }

  Future<ThemeConfigModel> cloneTheme(String name) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/themes/clone'),
      headers: headers,
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode == 200) {
      return ThemeConfigModel.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to clone theme');
    }
  }

  Future<List<ThemeConfigModel>> listThemeConfigurations() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/themes/configurations'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => ThemeConfigModel.fromJson(item)).toList();
    } else {
      throw ApiException(response.statusCode, 'Failed to list theme configurations');
    }
  }

  Future<ThemeConfigModel> getThemeConfig(String configId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/themes/config/$configId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return ThemeConfigModel.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to fetch theme config');
    }
  }

  Future<ThemeConfigModel> updateThemeConfigById(
    String configId, {
    String? name,
    Map<String, dynamic>? tokens,
    Map<String, dynamic>? slots,
  }) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/themes/config/$configId'),
      headers: headers,
      body: jsonEncode({
        if (name != null) 'name': name,
        'tokens': tokens,
        'slots': slots,
      }),
    );

    if (response.statusCode == 200) {
      return ThemeConfigModel.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to update theme config by ID');
    }
  }

  Future<ThemeConfigModel> publishThemeById(String configId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/themes/publish/$configId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return ThemeConfigModel.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException(response.statusCode, 'Failed to publish theme by ID');
    }
  }

  Future<void> deleteThemeConfig(String configId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/themes/config/$configId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to delete theme config');
    }
  }

  // --- Media ---
  Future<String> uploadMedia(List<int> bytes, String filename) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/internal/media/upload');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(headers)
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['url'] as String;
    } else {
      throw ApiException(
        response.statusCode,
        'Upload failed: ${response.body}',
      );
    }
  }

  /// Sends a variant retirement report to the merchant admin.
  ///
  /// **Debug mode**: pretty-prints the full report to the debug console.
  /// **Production mode**: POSTs the report payload to the backend which
  /// emails the merchant admin with SKU, price, compareAtPrice, and stock
  /// details of every retired variant.
  ///
  /// [productId] may be null for unsaved products (report is debug-only then).
  Future<void> sendVariantRetirementReport({
    required String productTitle,
    required String productSlug,
    required String? productId,
    required List<Map<String, dynamic>> retiringVariants,
    required int aggregatedStock,
    required String survivingVariantSku,
  }) async {
    final timestamp = DateTime.now().toIso8601String();

    // ── Debug console report ──────────────────────────────────────────────
    if (kDebugMode) {
      debugPrint('════════════════════════════════════════════════════════');
      debugPrint('VARIANT RETIREMENT REPORT');
      debugPrint('Generated at : $timestamp');
      debugPrint('Product      : $productTitle ($productSlug)');
      debugPrint('Product ID   : ${productId ?? "(unsaved)"}');
      debugPrint('─────────────────────────────────────────────────────────');
      debugPrint('Retiring variants:');
      for (final v in retiringVariants) {
        final optVals = Map<String, String>.from(v['option_values'] ?? {});
        final optStr = optVals.entries.map((e) => '${e.key}: ${e.value}').join(', ');
        debugPrint(
          '  SKU: ${v['sku']}  |  Options: $optStr'
          '  |  Price: \$${v['price']}'
          '  |  CompareAt: \$${v['compare_at_price'].toString().isNotEmpty ? v['compare_at_price'] : 'N/A'}'
          '  |  Stock: ${v['stock']}'
          '  |  DB ID: ${v['variant_id'] ?? "(new, never saved)"}',
        );
      }
      debugPrint('─────────────────────────────────────────────────────────');
      debugPrint('Aggregated stock assigned to: $survivingVariantSku');
      debugPrint('Total aggregated stock       : $aggregatedStock units');
      debugPrint('════════════════════════════════════════════════════════');
    }

    // ── Production email trigger ──────────────────────────────────────────
    // Only attempt if the product is already saved (has a DB id).
    if (!kDebugMode && productId != null) {
      try {
        final headers = await _getHeaders();
        final payload = {
          'timestamp': timestamp,
          'product_title': productTitle,
          'product_slug': productSlug,
          'surviving_variant_sku': survivingVariantSku,
          'aggregated_stock': aggregatedStock,
          'retiring_variants': retiringVariants.map((v) => {
            'variant_id': v['variant_id'],
            'sku': v['sku'],
            'price': v['price'],
            'compare_at_price': v['compare_at_price'],
            'stock': v['stock'],
            'option_values': Map<String, String>.from(v['option_values'] ?? {}),
          }).toList(),
        };
        final response = await http.post(
          Uri.parse('$baseUrl/catalog/products/$productId/variant-retirement-report'),
          headers: headers,
          body: jsonEncode(payload),
        );
        if (response.statusCode != 200 && response.statusCode != 202) {
          log('sendVariantRetirementReport: unexpected status ${response.statusCode}');
        }
      } catch (e) {
        // Non-fatal: log but do not surface to user.
        log('sendVariantRetirementReport error: $e');
      }
    }
  }

  // --- Bulk CSV/XLSX Product Import ---
  Future<Uint8List> downloadCsvTemplate() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/products/import/template'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw ApiException(response.statusCode, 'Failed to download CSV template: ${response.body}');
      }
    } catch (e) {
      log('ApiService.downloadCsvTemplate error: $e');
      rethrow;
    }
  }

  Future<List<String>> checkSkuExists(List<String> skus) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/products/sku-exists'),
        headers: headers,
        body: jsonEncode({'skus': skus}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['duplicates'] ?? []);
      } else {
        throw ApiException(response.statusCode, 'Failed to check SKUs: ${response.body}');
      }
    } catch (e) {
      log('ApiService.checkSkuExists error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadCsvImport({
    required Uint8List bytes,
    required String filename,
    required String conflictStrategy,
    required Map<String, String> customSkuMap,
  }) async {
    try {
      final token = await _authService.getIdToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/products/import'),
      );
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.fields['conflict_strategy'] = conflictStrategy;
      request.fields['custom_sku_map_json'] = jsonEncode(customSkuMap);
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 202) {
        return jsonDecode(response.body);
      } else {
        throw ApiException(response.statusCode, 'Failed to upload CSV: ${response.body}');
      }
    } catch (e) {
      log('ApiService.uploadCsvImport error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getImportJobStatus(String jobId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/products/import/$jobId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw ApiException(response.statusCode, 'Failed to get import job status: ${response.body}');
      }
    } catch (e) {
      log('ApiService.getImportJobStatus error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getImportHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/products/import/history'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        throw ApiException(response.statusCode, 'Failed to get import history: ${response.body}');
      }
    } catch (e) {
      log('ApiService.getImportHistory error: $e');
      rethrow;
    }
  }

  // --- Shipping ---
  Future<List<Map<String, dynamic>>> listShippingProfiles() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/shipping/profiles'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    throw ApiException(response.statusCode, 'Failed to list shipping profiles');
  }

  Future<Map<String, dynamic>> createShippingProfile(String name, bool isGeneral) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/shipping/profiles'),
      headers: headers,
      body: jsonEncode({'name': name, 'is_general': isGeneral}),
    );
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'Failed to create shipping profile');
  }

  Future<void> deleteShippingProfile(String profileId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/shipping/profiles/$profileId'),
      headers: headers,
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to delete shipping profile');
    }
  }

  Future<Map<String, dynamic>> createShippingZone(String profileId, String name, List<String> countries) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/shipping/profiles/$profileId/zones'),
      headers: headers,
      body: jsonEncode({'name': name, 'countries': countries}),
    );
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'Failed to create shipping zone');
  }

  Future<void> deleteShippingZone(String zoneId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/shipping/zones/$zoneId'),
      headers: headers,
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to delete shipping zone');
    }
  }

  Future<Map<String, dynamic>> createShippingRate({
    required String zoneId,
    required String name,
    required double price,
    double? minValue,
    double? maxValue,
    double? minWeight,
    double? maxWeight,
    required String rateType,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/shipping/zones/$zoneId/rates'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'price': price,
        'min_value': minValue,
        'max_value': maxValue,
        'min_weight': minWeight,
        'max_weight': maxWeight,
        'rate_type': rateType,
      }),
    );
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'Failed to create shipping rate');
  }

  Future<void> deleteShippingRate(String rateId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/shipping/rates/$rateId'),
      headers: headers,
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to delete shipping rate');
    }
  }

  // --- Taxes ---
  Future<List<Map<String, dynamic>>> listTaxRates() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/tax/rates'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    throw ApiException(response.statusCode, 'Failed to list tax rates');
  }

  Future<Map<String, dynamic>> createTaxRate({
    required String countryCode,
    String? stateCode,
    required double taxPercentage,
    required bool isActive,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/tax/rates'),
      headers: headers,
      body: jsonEncode({
        'country_code': countryCode,
        'state_code': stateCode,
        'tax_percentage': taxPercentage,
        'is_active': isActive,
      }),
    );
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'Failed to create tax rate');
  }

  Future<void> deleteTaxRate(String taxRateId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/tax/rates/$taxRateId'),
      headers: headers,
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to delete tax rate');
    }
  }

  // --- Navigation ---
  Future<List<Map<String, dynamic>>> listNavigationMenus() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/navigation/menus'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    throw ApiException(response.statusCode, 'Failed to list navigation menus');
  }

  Future<Map<String, dynamic>> createNavigationMenu(String name, String handle) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/navigation/menus'),
      headers: headers,
      body: jsonEncode({'name': name, 'handle': handle}),
    );
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'Failed to create navigation menu');
  }

  Future<void> deleteNavigationMenu(String menuId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/navigation/menus/$menuId'),
      headers: headers,
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to delete navigation menu');
    }
  }

  Future<Map<String, dynamic>> createNavigationItem({
    required String menuId,
    String? parentId,
    required String title,
    required String url,
    required String linkType,
    String? resourceId,
    required int position,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/navigation/menus/$menuId/items'),
      headers: headers,
      body: jsonEncode({
        'parent_id': parentId,
        'title': title,
        'url': url,
        'link_type': linkType,
        'resource_id': resourceId,
        'position': position,
      }),
    );
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'Failed to create navigation item');
  }

  Future<void> deleteNavigationItem(String itemId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/navigation/items/$itemId'),
      headers: headers,
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to delete navigation item');
    }
  }

  Future<void> reorderNavigationItems(String menuId, List<Map<String, dynamic>> items) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/navigation/menus/$menuId/reorder'),
      headers: headers,
      body: jsonEncode({'items': items}),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to reorder navigation items');
    }
  }

  // --- Policies ---
  Future<List<Map<String, dynamic>>> listPolicies() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/policies'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    throw ApiException(response.statusCode, 'Failed to list policies');
  }

  Future<Map<String, dynamic>> createPolicy(String policyType, String draftContent) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/policies'),
      headers: headers,
      body: jsonEncode({
        'policy_type': policyType,
        'draft_content': draftContent,
        'published_content': '',
      }),
    );
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'Failed to create policy');
  }

  Future<Map<String, dynamic>> updatePolicyDraft(String policyId, String draftContent) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/policies/$policyId'),
      headers: headers,
      body: jsonEncode({'draft_content': draftContent}),
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'Failed to update policy draft');
  }

  Future<Map<String, dynamic>> publishPolicy(String policyId, {bool force = false}) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/policies/$policyId/publish?force=$force'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'Failed to publish policy');
  }

  Future<String> seedPolicyTemplate(String policyType) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/policies/seed-template'),
      headers: headers,
      body: jsonEncode({'policy_type': policyType}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['seeded_content'] as String;
    }
    throw ApiException(response.statusCode, 'Failed to seed policy template');
  }

  Future<List<Map<String, dynamic>>> listCollections() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/products/collections'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    throw ApiException(response.statusCode, 'Failed to list collections');
  }

  Future<List<Map<String, dynamic>>> listStorefrontPages() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/storefront/pages'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    }
    throw ApiException(response.statusCode, 'Failed to list storefront pages');
  }

  Future<Map<String, dynamic>> createStorefrontPage(Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/storefront/pages'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'Failed to create storefront page');
  }

  Future<Map<String, dynamic>> updateStorefrontPage(String pageId, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/storefront/pages/$pageId'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw ApiException(response.statusCode, 'Failed to update storefront page');
  }

  Future<void> deleteStorefrontPage(String pageId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/storefront/pages/$pageId'),
      headers: headers,
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiException(response.statusCode, 'Failed to delete storefront page');
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
