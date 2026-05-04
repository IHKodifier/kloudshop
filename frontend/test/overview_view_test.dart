import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/dashboard_page.dart';
import 'package:kloudshop/providers/analytics_providers.dart';
import 'package:kloudshop/models/analytics.dart';
import 'package:kloudshop/models/user_claims.dart';

void main() {
  testWidgets('Dashboard Overview displays live analytics', (tester) async {
    final mockStats = AnalyticsOverview(
      gmv: 5000.0,
      orderCount: 50,
      aov: 100.0,
      conversionRate: 0.05,
      currency: 'USD',
      refreshedAt: DateTime.now(),
    );

    final mockAlerts = NeedsAttention(
      pendingOrdersOverdue: 3,
      lowStockVariants: 12,
      pendingB2bApprovals: 2,
      totalAlerts: 17,
    );

    final claims = UserClaims(
      uid: 'user-123',
      email: 'test@example.com',
      tenantId: 'tenant-abc',
      accountType: 'merchant',
      roles: ['admin'],
      isOwner: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsOverviewProvider.overrideWith((ref) => Future.value(mockStats)),
          needsAttentionProvider.overrideWith((ref) => Future.value(mockAlerts)),
        ],
        child: MaterialApp(
          home: DashboardPage(claims: claims),
        ),
      ),
    );

    // Wait for data
    await tester.pump();

    // Verify stats
    expect(find.text('USD 5000.00'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('USD 100.00'), findsOneWidget);

    // Verify alerts
    expect(find.text('3'), findsOneWidget); // Overdue Orders
    expect(find.text('12'), findsOneWidget); // Low Stock
    expect(find.text('2'), findsOneWidget); // B2B Approvals
  });
}
