import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:kloudshop/providers/billing_providers.dart';
import 'package:kloudshop/models/subscription.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';

class BillingView extends ConsumerStatefulWidget {
  const BillingView({super.key});

  @override
  ConsumerState<BillingView> createState() => _BillingViewState();
}

class _BillingViewState extends ConsumerState<BillingView> {
  late PageController _pageController;
  int _currentVariantIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleUpgrade(BuildContext context, String planId) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Preparing upgrade...')),
      );

      final successUrl =
          '${Uri.base.origin}/#/dashboard?session_id={CHECKOUT_SESSION_ID}';
      final cancelUrl = '${Uri.base.origin}/#/dashboard';

      final url = await ref
          .read(apiServiceProvider)
          .createUpgradeSession(
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
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionAsync = ref.watch(subscriptionProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: subscriptionAsync.when(
        data: (sub) => Column(
          children: [
            // Variant Switcher Header
            _buildVariantSwitcherHeader(theme, isDark),

            // PageView content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentVariantIndex = index;
                  });
                },
                children: [
                  _buildZurichBillingLayout(theme, isDark, sub),
                  _buildBentoBillingLayout(theme, isDark, sub),
                  _buildMobileStackBillingLayout(theme, isDark, sub),
                ],
              ),
            ),
          ],
        ),
        loading: () => Center(
          child: CircularProgressIndicator(color: AppTheme.brandEmerald500),
        ),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.alertCircle,
                  color: Color(0xFFEF4444),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load billing info: $e',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(subscriptionProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVariantSwitcherHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.creditCard,
                size: 24,
                color: AppTheme.brandEmerald500,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Billing & Subscription',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Compare billing interface variants by clicking chips or swiping.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: List.generate(3, (index) {
              final isSelected = _currentVariantIndex == index;
              final labels = ['Zurich Layout', 'Bento Usage', 'Mobile Stack'];
              final icons = [
                LucideIcons.layoutGrid,
                LucideIcons.barChart3,
                LucideIcons.smartphone,
              ];
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: HoverScale(
                  child: ChoiceChip(
                    avatar: Icon(
                      icons[index],
                      size: 14,
                      color: isSelected ? Colors.white : theme.hintColor,
                    ),
                    label: Text(labels[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _currentVariantIndex = index);
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                    selectedColor: AppTheme.brandEmerald500,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : theme.dividerColor,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- VARIANT 1: ZURICH BILLING LAYOUT ---
  Widget _buildZurichBillingLayout(
    ThemeData theme,
    bool isDark,
    SubscriptionModel sub,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Plan: ${sub.tier.toString().split('.').last.toUpperCase()}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Redirecting to Stripe Portal...'),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.externalLink, size: 14),
                label: const Text('Manage via Stripe'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandEmerald500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatusCard(context, sub),
          const SizedBox(height: 36),
          _buildBillingHistoryTable(theme, isDark),
          const SizedBox(height: 36),
          Text(
            'Available Plans',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPricingTable(context, sub),
        ],
      ),
    );
  }

  // --- VARIANT 2: BENTO BILLING LAYOUT (Resource Metrics Focus) ---
  Widget _buildBentoBillingLayout(
    ThemeData theme,
    bool isDark,
    SubscriptionModel sub,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.barChart3,
                size: 22,
                color: AppTheme.brandEmerald500,
              ),
              const SizedBox(width: 12),
              Text(
                'Bento Billing & System Usage',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              // Bento Card 1: Active Subscription Summary
              Container(
                width: 450,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.brandEmerald500.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.shieldCheck,
                          color: AppTheme.brandEmerald500,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Plan Status',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hybrid Enterprise',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandEmerald500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supports dual storefronts (DTC + B2B wholesale portals) with priority global routing.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandEmerald500,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Manage Stripe Portal'),
                    ),
                  ],
                ),
              ),

              // Bento Card 2: Performance Metrics & Limits
              Container(
                width: 480,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.activity,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'System Resource Usage',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildUsageBar(
                      theme,
                      'API Requests',
                      '8.4M / 10M',
                      0.84,
                      const Color(0xFF6366F1),
                    ),
                    const SizedBox(height: 16),
                    _buildUsageBar(
                      theme,
                      'Database Storage',
                      '210 GB / 500 GB',
                      0.42,
                      const Color(0xFF06B6D4),
                    ),
                    const SizedBox(height: 16),
                    _buildUsageBar(
                      theme,
                      'Compute Units',
                      '12,104 / 25,000',
                      0.48,
                      const Color(0xFFEC4899),
                    ),
                  ],
                ),
              ),

              // Bento Card 3: Invoices History
              Container(
                width: 954,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: _buildBillingHistoryTable(theme, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageBar(
    ThemeData theme,
    String title,
    String val,
    double progress,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              val,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.dividerColor,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // --- VARIANT 3: MOBILE STACK LAYOUT ---
  Widget _buildMobileStackBillingLayout(
    ThemeData theme,
    bool isDark,
    SubscriptionModel sub,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.brandEmerald500.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.smartphone,
                      color: AppTheme.brandEmerald500,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Optimized stacked view for handheld screens.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              ExpansionTile(
                leading: const Icon(
                  LucideIcons.award,
                  color: AppTheme.brandEmerald500,
                ),
                title: const Text(
                  'Active Plan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                childrenPadding: const EdgeInsets.all(16),
                children: [_buildStatusCard(context, sub)],
              ),
              const Divider(height: 1),
              ExpansionTile(
                leading: const Icon(
                  LucideIcons.history,
                  color: Color(0xFFF59E0B),
                ),
                title: const Text(
                  'Invoice History',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      final dates = [
                        'Oct 12, 2023',
                        'Sep 12, 2023',
                        'Aug 12, 2023',
                      ];
                      final amounts = ['\$49.99', '\$49.99', '\$49.99'];
                      return ListTile(
                        title: Text(dates[index]),
                        subtitle: const Text(
                          'Status: PAID',
                          style: TextStyle(color: Colors.green, fontSize: 11),
                        ),
                        trailing: Text(
                          amounts[index],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Divider(height: 1),
              ExpansionTile(
                leading: const Icon(
                  LucideIcons.creditCard,
                  color: Color(0xFF6366F1),
                ),
                title: const Text(
                  'Change Subscription',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildPricingOptionRow(
                          theme,
                          'DTC Plan',
                          '\$24.99/mo',
                          () => _handleUpgrade(context, 'dtc'),
                        ),
                        const SizedBox(height: 12),
                        _buildPricingOptionRow(
                          theme,
                          'B2B Plan',
                          '\$39.99/mo',
                          () => _handleUpgrade(context, 'b2b'),
                        ),
                        const SizedBox(height: 12),
                        _buildPricingOptionRow(
                          theme,
                          'Hybrid Plan',
                          '\$49.99/mo',
                          () => _handleUpgrade(context, 'hybrid'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPricingOptionRow(
    ThemeData theme,
    String name,
    String price,
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                price,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandEmerald500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Choose'),
          ),
        ],
      ),
    );
  }

  // --- REUSED SUB-WIDGETS FROM PREVIOUS IMPLEMENTATION ---
  Widget _buildStatusCard(BuildContext context, SubscriptionModel sub) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM d, yyyy');

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      AppTheme.brandTeal900.withOpacity(0.9),
                      const Color(0xFF065F46).withOpacity(0.8),
                    ]
                  : [AppTheme.brandTeal500, AppTheme.brandEmerald600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            sub.tier.toString().split('.').last.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        if (sub.isTrialing) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              sub.trialEnd != null
                                  ? 'Trial ends ${dateFormat.format(sub.trialEnd!)}'
                                  : 'Trial active',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      sub.status == SubscriptionStatus.active
                          ? 'Active'
                          : 'Trialing',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Next payment: ${dateFormat.format(sub.currentPeriodEnd ?? DateTime.now().add(const Duration(days: 30)))}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(
                  LucideIcons.creditCard,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillingHistoryTable(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Billing History',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.download, size: 16),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading invoices...')),
                  );
                },
                tooltip: 'Download All Invoices',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.dividerColor)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('DATE', style: theme.textTheme.labelSmall),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('AMOUNT', style: theme.textTheme.labelSmall),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('STATUS', style: theme.textTheme.labelSmall),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('ACTION', style: theme.textTheme.labelSmall),
                  ),
                ],
              ),
              _buildInvoiceTableRow(theme, 'Oct 12, 2023', '\$49.99', 'PAID'),
              _buildInvoiceTableRow(theme, 'Sep 12, 2023', '\$49.99', 'PAID'),
              _buildInvoiceTableRow(theme, 'Aug 12, 2023', '\$49.99', 'PAID'),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildInvoiceTableRow(
    ThemeData theme,
    String date,
    String amount,
    String status,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(date, style: theme.textTheme.bodyMedium),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            amount,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            status,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.brandEmerald500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading invoice for $date')),
              );
            },
            child: const Icon(
              LucideIcons.downloadCloud,
              size: 16,
              color: AppTheme.brandEmerald500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingTable(
    BuildContext context,
    SubscriptionModel currentSub,
  ) {
    return Row(
      children: [
        Expanded(
          child: _PricingCard(
            title: 'DTC',
            price: '\$24.99',
            tagline: 'Perfect for new stores',
            icon: LucideIcons.shoppingBag,
            features: const [
              'Consumer Storefront',
              'Unlimited Products',
              'AI Copywriter',
              'Zero GMV Fees',
            ],
            isCurrent: currentSub.tier == SubscriptionTier.dtc,
            onPressed: () => _handleUpgrade(context, 'dtc'),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _PricingCard(
            title: 'B2B',
            price: '\$39.99',
            tagline: 'For wholesale businesses',
            icon: LucideIcons.building2,
            features: const [
              'Wholesale Portal',
              'Custom Price Lists',
              'Net Terms & Credit Limits',
              'Approval Workflows',
            ],
            isCurrent: currentSub.tier == SubscriptionTier.b2b,
            isPopular: true,
            onPressed: () => _handleUpgrade(context, 'b2b'),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _PricingCard(
            title: 'Hybrid',
            price: '\$49.99',
            tagline: 'The complete commerce stack',
            icon: LucideIcons.layers,
            features: const [
              'DTC + B2B Simultaneously',
              'Shared Inventory',
              'Unified Dashboard',
              'Dual Storefronts',
            ],
            isCurrent: currentSub.tier == SubscriptionTier.hybrid,
            onPressed: () => _handleUpgrade(context, 'hybrid'),
          ),
        ),
      ],
    );
  }
}

class _PricingCard extends StatefulWidget {
  final String title;
  final String price;
  final String tagline;
  final IconData icon;
  final List<String> features;
  final bool isCurrent;
  final bool isPopular;
  final VoidCallback onPressed;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.tagline,
    required this.icon,
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
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withOpacity(0.7)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: widget.isPopular
                      ? AppTheme.brandEmerald500
                      : _isHovered
                      ? AppTheme.brandEmerald500.withOpacity(0.5)
                      : theme.dividerColor.withOpacity(0.6),
                  width: widget.isPopular ? 2 : 1,
                ),
                boxShadow: _isHovered || widget.isPopular
                    ? [
                        BoxShadow(
                          color: AppTheme.brandEmerald500.withOpacity(0.15),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.isPopular)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.brandEmerald500,
                            AppTheme.brandEmerald600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'MOST POPULAR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.brandEmerald500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 22,
                      color: AppTheme.brandEmerald500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.tagline,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.price,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandEmerald500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '/month',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(
                    color: theme.dividerColor.withOpacity(0.4),
                    height: 1,
                  ),
                  const SizedBox(height: 24),
                  ...widget.features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppTheme.brandEmerald500.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.check,
                              size: 12,
                              color: AppTheme.brandEmerald500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(f, style: theme.textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: widget.isCurrent
                        ? Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.brandEmerald500.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.brandEmerald500.withOpacity(
                                  0.4,
                                ),
                              ),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.checkCircle2,
                                    size: 16,
                                    color: AppTheme.brandEmerald500,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Current Plan',
                                    style: TextStyle(
                                      color: AppTheme.brandEmerald500,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : HoverScale(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: widget.isPopular
                                    ? const LinearGradient(
                                        colors: [
                                          AppTheme.brandEmerald500,
                                          AppTheme.brandEmerald600,
                                        ],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                border: widget.isPopular
                                    ? null
                                    : Border.all(
                                        color: theme.colorScheme.outline,
                                      ),
                              ),
                              child: ElevatedButton(
                                onPressed: widget.onPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Choose ${widget.title}',
                                  style: TextStyle(
                                    color: widget.isPopular
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
