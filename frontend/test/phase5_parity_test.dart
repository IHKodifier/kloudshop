import 'package:flutter_test/flutter_test.dart';
import 'package:kloudshop/models/analytics.dart';
import 'package:kloudshop/models/blog.dart';
import 'package:kloudshop/models/hygiene.dart';

void main() {
  group('Phase 5 Model Parsing', () {
    test('AnalyticsOverview parsing', () {
      final json = {
        "gmv": 1250.50,
        "order_count": 10,
        "aov": 125.05,
        "conversion_rate": 0.035,
        "currency": "USD",
        "refreshed_at": "2026-05-04T07:00:00Z"
      };
      
      final stats = AnalyticsOverview.fromJson(json);
      expect(stats.gmv, 1250.50);
      expect(stats.orderCount, 10);
      expect(stats.currency, 'USD');
      expect(stats.refreshedAt.year, 2026);
    });

    test('NeedsAttention parsing', () {
      final json = {
        "pending_orders_overdue": 5,
        "low_stock_variants": 2,
        "pending_b2b_approvals": 1,
        "total_alerts": 8
      };
      
      final alerts = NeedsAttention.fromJson(json);
      expect(alerts.pendingOrdersOverdue, 5);
      expect(alerts.totalAlerts, 8);
    });

    test('BlogPost parsing', () {
      final json = {
        "id": "post-123",
        "title": "Welcome to KloudShop",
        "slug": "welcome-to-kloudshop",
        "excerpt": "This is our first post.",
        "body": "Full body content.",
        "status": "published",
        "published_at": "2026-05-04T10:00:00Z",
        "created_at": "2026-05-04T08:00:00Z",
        "categories": [
          {"id": "cat-1", "name": "News", "slug": "news", "sort_order": 0}
        ],
        "tags": [
          {"id": "tag-1", "name": "Launch", "slug": "launch"}
        ]
      };
      
      final post = BlogPost.fromJson(json);
      expect(post.id, 'post-123');
      expect(post.categories.first.name, 'News');
      expect(post.tags.first.name, 'Launch');
      expect(post.publishedAt != null, true);
    });

    test('SystemStatus & Health parsing', () {
      final statusJson = {
        "version": "1.0.4-rc2",
        "build_hash": "a1b2c3d4",
        "environment": "production",
        "api_status": "operational"
      };
      
      final healthJson = {
        "status": "healthy",
        "missing_tables": [],
        "database_type": "sqlite",
        "timestamp": "2026-05-04T12:00:00Z"
      };
      
      final status = SystemStatus.fromJson(statusJson);
      final health = SchemaHealth.fromJson(healthJson);
      
      expect(status.version, '1.0.4-rc2');
      expect(health.status, 'healthy');
      expect(health.missingTables.isEmpty, true);
    });
    group('Edge Cases', () {
      test('Empty lists and nulls', () {
        final json = {
          "id": "post-empty",
          "title": "Empty",
          "slug": "empty",
          "created_at": "2026-05-04T08:00:00Z",
          "categories": null,
          "tags": [],
        };
        final post = BlogPost.fromJson(json);
        expect(post.categories.length, 0);
        expect(post.tags.length, 0);
      });
    });
  });
}
