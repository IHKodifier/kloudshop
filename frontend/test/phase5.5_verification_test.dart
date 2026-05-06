import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/widgets/feature_gate.dart';
import 'package:kloudshop/models/subscription.dart';
import 'package:kloudshop/providers/billing_providers.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

void main() {
  group('FeatureGate Verification', () {
    testWidgets('Shows child when user has access (Hybrid tier)', (tester) async {
      final mockSub = SubscriptionModel(
        id: '1',
        tenantId: 't1',
        tier: SubscriptionTier.hybrid,
        status: SubscriptionStatus.active,
        cancelAtPeriodEnd: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionProvider.overrideWith((ref) => mockSub),
          ],
          child: const MaterialApp(
            home: FeatureGate(
              feature: Feature.b2bPortal,
              child: Text('Access Granted'),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Access Granted'), findsOneWidget);
      expect(find.text('Feature Locked'), findsNothing);
    });

    testWidgets('Shows fallback when user lacks access (DTC tier)', (tester) async {
      final mockSub = SubscriptionModel(
        id: '1',
        tenantId: 't1',
        tier: SubscriptionTier.dtc,
        status: SubscriptionStatus.active,
        cancelAtPeriodEnd: false,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionProvider.overrideWith((ref) => mockSub),
          ],
          child: const MaterialApp(
            home: FeatureGate(
              feature: Feature.b2bPortal,
              child: Text('Access Granted'),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Access Granted'), findsNothing);
      expect(find.text('Feature Locked'), findsOneWidget);
      expect(find.byIcon(LucideIcons.lock), findsOneWidget);
    });
  });

  group('URL Parsing Verification', () {
    test('Can parse session_id from fragment (hash routing)', () {
      final uri = Uri.parse('http://localhost:8080/#/dashboard?session_id=mock_123');
      String? sessionId;
      
      if (uri.fragment.isNotEmpty) {
        final fragmentPath = uri.fragment.startsWith('/') ? uri.fragment : '/${uri.fragment}';
        final fragmentUri = Uri.parse('http://localhost$fragmentPath');
        sessionId = fragmentUri.queryParameters['session_id'];
      }
      
      expect(sessionId, 'mock_123');
    });

    test('Can parse session_id from queryParameters (path routing)', () {
      final uri = Uri.parse('http://localhost:8080/dashboard?session_id=mock_456');
      final sessionId = uri.queryParameters['session_id'];
      expect(sessionId, 'mock_456');
    });
  });
}
