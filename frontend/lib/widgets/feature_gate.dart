import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/models/subscription.dart';
import 'package:kloudshop/providers/billing_providers.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

enum Feature {
  dtcStorefront,
  b2bPortal,
  priceLists,
  approvalWorkflows,
  advancedAnalytics,
}

class FeatureGate extends ConsumerWidget {
  final Feature feature;
  final Widget child;
  final Widget? fallback;

  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.fallback,
  });

  bool _hasAccess(SubscriptionTier tier) {
    switch (feature) {
      case Feature.dtcStorefront:
        return tier == SubscriptionTier.dtc || tier == SubscriptionTier.hybrid || tier == SubscriptionTier.free;
      case Feature.b2bPortal:
      case Feature.priceLists:
      case Feature.approvalWorkflows:
        return tier == SubscriptionTier.b2b || tier == SubscriptionTier.hybrid;
      case Feature.advancedAnalytics:
        return tier == SubscriptionTier.hybrid;
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionProvider);

    return subscriptionAsync.when(
      data: (sub) {
        if (_hasAccess(sub.tier)) {
          return child;
        }
        return fallback ?? _buildLockedOverlay(context);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => child, // Default to showing if error, or show error?
    );
  }

  Widget _buildLockedOverlay(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.lock, size: 48, color: theme.hintColor),
          const SizedBox(height: 16),
          Text(
            'Feature Locked',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Upgrade your plan to access this module.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to Billing tab
            },
            icon: const Icon(LucideIcons.arrowUpCircle, size: 16),
            label: const Text('View Plans'),
          ),
        ],
      ),
    );
  }
}
