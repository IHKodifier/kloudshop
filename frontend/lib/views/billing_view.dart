import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:kloudshop/providers/billing_providers.dart';
import 'package:kloudshop/models/subscription.dart';
import 'package:kloudshop/services/api_service.dart';

class BillingView extends ConsumerWidget {
  const BillingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(subscriptionProvider);

    return subscriptionAsync.when(
      data: (sub) => _buildContent(context, ref, sub),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load billing info: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(subscriptionProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, SubscriptionModel sub) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, sub),
          const SizedBox(height: 32),
          _buildStatusCard(context, sub),
          const SizedBox(height: 48),
          Text('Available Plans', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 24),
          _buildPricingTable(context, ref, sub),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, SubscriptionModel sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subscription & Billing', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Manage your plan, billing history, and payment methods.',
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, SubscriptionModel sub) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withBlue(255)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Use a safer way to display the tier name
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        sub.tier.toString().split('.').last.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (sub.isTrialing) ...[
                      if (sub.trialEnd != null)
                        Text(
                          'Trial ends ${dateFormat.format(sub.trialEnd!)}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                        )
                      else
                        Text(
                          'Trial period active',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  sub.status == SubscriptionStatus.active ? 'Active' : 'Trialing',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Next payment: ${dateFormat.format(sub.currentPeriodEnd ?? DateTime.now().add(const Duration(days: 30)))}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.creditCard, color: Colors.white, size: 64),
        ],
      ),
    );
  }

  Widget _buildPricingTable(BuildContext context, WidgetRef ref, SubscriptionModel currentSub) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _PricingCard(
              title: 'DTC',
              price: '\$24.99',
              features: [
                'Consumer Storefront',
                'Unlimited Products',
                'AI Copywriter',
                'Zero GMV Fees',
              ],
              isCurrent: currentSub.tier == SubscriptionTier.dtc,
              onPressed: () => _handleUpgrade(context, ref, 'dtc'),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _PricingCard(
              title: 'B2B',
              price: '\$39.99',
              features: [
                'Wholesale Portal',
                'Custom Price Lists',
                'Net Terms & Credit Limits',
                'Approval Workflows',
              ],
              isCurrent: currentSub.tier == SubscriptionTier.b2b,
              isPopular: true,
              onPressed: () => _handleUpgrade(context, ref, 'b2b'),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _PricingCard(
              title: 'Hybrid',
              price: '\$49.99',
              features: [
                'DTC + B2B Simultaneously',
                'Shared Inventory',
                'Unified Dashboard',
                'Dual Storefronts',
              ],
              isCurrent: currentSub.tier == SubscriptionTier.hybrid,
              onPressed: () => _handleUpgrade(context, ref, 'hybrid'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpgrade(BuildContext context, WidgetRef ref, String planId) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Preparing upgrade...')),
      );

      final successUrl = '${Uri.base.origin}/#/dashboard?session_id={CHECKOUT_SESSION_ID}';
      final cancelUrl = '${Uri.base.origin}/#/dashboard';

      final url = await ref.read(apiServiceProvider).createUpgradeSession(
        planId,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

class _PricingCard extends StatefulWidget {
  final String title;
  final String price;
  final List<String> features;
  final bool isCurrent;
  final bool isPopular;
  final VoidCallback onPressed;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.features,
    this.isCurrent = false,
    this.isPopular = false,
    required this.onPressed,
  });

  @override
  State<_PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<_PricingCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: widget.isPopular ? theme.primaryColor : (_isHovered ? theme.primaryColor.withValues(alpha: 0.5) : theme.dividerColor),
            width: widget.isPopular ? 2 : 1,
          ),
          boxShadow: _isHovered
              ? [BoxShadow(color: theme.primaryColor.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, 20))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isPopular)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('MOST POPULAR', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            Text(widget.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(widget.price, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text('/month', style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor)),
              ],
            ),
            const SizedBox(height: 32),
            ...widget.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Icon(LucideIcons.check, size: 16, color: theme.primaryColor),
                      const SizedBox(width: 12),
                      Text(f),
                    ],
                  ),
                )),
            const Spacer(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.isCurrent ? null : widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isPopular ? theme.primaryColor : null,
                  foregroundColor: widget.isPopular ? Colors.white : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(widget.isCurrent ? 'Current Plan' : 'Choose ${widget.title}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
