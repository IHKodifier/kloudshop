import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:kloudshop/models/analytics.dart';
import 'package:kloudshop/models/user_claims.dart';
import 'package:kloudshop/services/auth_service.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/views/billing_view.dart';
import 'package:kloudshop/views/blog_view.dart';
import 'package:kloudshop/views/compliance_view.dart';
import 'package:kloudshop/views/catalog_view.dart';
import 'package:kloudshop/views/orders_view.dart';
import 'package:kloudshop/views/customers_view.dart';
import 'package:kloudshop/views/settings_view.dart';
import 'package:kloudshop/providers/billing_providers.dart';
import 'package:kloudshop/providers/theme_provider.dart';
import 'package:kloudshop/providers/settings_providers.dart';
import 'package:kloudshop/providers/analytics_providers.dart';
import 'package:kloudshop/views/themes_view.dart';
import 'package:kloudshop/widgets/feature_gate.dart';
import 'package:kloudshop/widgets/hover_scale.dart';
import 'package:kloudshop/widgets/lottie_toggle.dart';
import 'package:kloudshop/provisioning_page.dart';

class DashboardPage extends ConsumerStatefulWidget {
  final UserClaims claims;

  const DashboardPage({super.key, required this.claims});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedIndex = 0;
  bool _isRailExtended = true;

  @override
  void initState() {
    super.initState();
    _handleBillingSession();
  }

  Future<void> _handleBillingSession() async {
    // Wait for the next frame to avoid build context issues during initState
    await Future.delayed(Duration.zero);

    final uri = Uri.base;
    String? sessionId = uri.queryParameters['session_id'];

    // Support hash routing (fragment) session_id
    if (sessionId == null && uri.fragment.isNotEmpty) {
      try {
        final fragmentPath = uri.fragment.startsWith('/')
            ? uri.fragment
            : '/${uri.fragment}';
        final fragmentUri = Uri.parse('http://localhost$fragmentPath');
        sessionId = fragmentUri.queryParameters['session_id'];
      } catch (_) {}
    }

    if (sessionId != null) {
      try {
        await ref.read(apiServiceProvider).verifyUpgradeSession(sessionId);

        // Invalidate relevant providers to force fresh data
        ref.invalidate(subscriptionProvider);
        ref.invalidate(tenantSettingsProvider);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Plan upgraded successfully! Welcome to your new tier.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Switch to Billing tab (index 4)
        setState(() => _selectedIndex = 4);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar / Navigation Rail
          _buildSidebar(context),

          const VerticalDivider(thickness: 1, width: 1),

          // Main Content Area
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final sidebarWidth = _isRailExtended ? 240.0 : 78.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: sidebarWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            border: Border(
              right: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header section (Fixed height, always visible)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: _isRailExtended
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.center,
                    children: [
                      if (_isRailExtended) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset(
                                'assets/logo3d.png',
                                width: 20,
                                height: 20,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    LucideIcons.store,
                                    color: Colors.white,
                                    size: 20,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'KloudShop',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(
                            'assets/logo3d.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                LucideIcons.store,
                                color: Colors.white,
                                size: 20,
                              );
                            },
                          ),
                        ),
                      ],
                      if (_isRailExtended)
                        IconButton(
                          icon: const Icon(LucideIcons.chevronLeft, size: 20),
                          onPressed: () =>
                              setState(() => _isRailExtended = false),
                          tooltip: 'Collapse',
                        ),
                    ],
                  ),
                ),

                // Menu toggle when collapsed
                if (!_isRailExtended) ...[
                  IconButton(
                    icon: const Icon(LucideIcons.menu, size: 20),
                    onPressed: () => setState(() => _isRailExtended = true),
                    tooltip: 'Expand',
                  ),
                  const SizedBox(height: 16),
                ],

                // Main navigation scroll view (Scrollable center)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Store Info badge (only when extended)
                        if (_isRailExtended) ...[
                          Consumer(
                            builder: (context, ref, child) {
                              final settingsAsync = ref.watch(
                                tenantSettingsProvider,
                              );
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                ),
                                child: settingsAsync.when(
                                  data: (settings) => Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          theme.colorScheme.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          settings.name.toUpperCase(),
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.2,
                                                color: theme.primaryColor,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          (settings.config['sector'] as String?)
                                                  ?.toUpperCase() ??
                                              'MERCHANT',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(fontSize: 10),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  loading: () =>
                                      const LinearProgressIndicator(),
                                  error: (e, s) => const SizedBox.shrink(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Navigation Menu Items
                        _SidebarItemTile(
                          index: 0,
                          icon: LucideIcons.layoutDashboard,
                          label: 'Overview',
                          isSelected: _selectedIndex == 0,
                          isExtended: _isRailExtended,
                          onTap: () => setState(() => _selectedIndex = 0),
                        ),
                        _SidebarItemTile(
                          index: 1,
                          icon: LucideIcons.shoppingCart,
                          label: 'Catalog',
                          isSelected: _selectedIndex == 1,
                          isExtended: _isRailExtended,
                          onTap: () => setState(() => _selectedIndex = 1),
                        ),
                        _SidebarItemTile(
                          index: 2,
                          icon: LucideIcons.package,
                          label: 'Orders',
                          isSelected: _selectedIndex == 2,
                          isExtended: _isRailExtended,
                          onTap: () => setState(() => _selectedIndex = 2),
                        ),
                        _SidebarItemTile(
                          index: 3,
                          icon: LucideIcons.users,
                          label: 'Customers',
                          isSelected: _selectedIndex == 3,
                          isExtended: _isRailExtended,
                          onTap: () => setState(() => _selectedIndex = 3),
                        ),
                        _SidebarItemTile(
                          index: 4,
                          icon: LucideIcons.creditCard,
                          label: 'Billing',
                          isSelected: _selectedIndex == 4,
                          isExtended: _isRailExtended,
                          onTap: () => setState(() => _selectedIndex = 4),
                        ),
                        _SidebarItemTile(
                          index: 5,
                          icon: LucideIcons.newspaper,
                          label: 'Blog',
                          isSelected: _selectedIndex == 5,
                          isExtended: _isRailExtended,
                          onTap: () => setState(() => _selectedIndex = 5),
                        ),
                        _SidebarItemTile(
                          index: 6,
                          icon: LucideIcons.usersRound,
                          label: 'Wholesale',
                          isSelected: _selectedIndex == 6,
                          isExtended: _isRailExtended,
                          onTap: () => setState(() => _selectedIndex = 6),
                        ),
                        _SidebarItemTile(
                          index: 7,
                          icon: LucideIcons.shieldCheck,
                          label: 'Compliance',
                          isSelected: _selectedIndex == 7,
                          isExtended: _isRailExtended,
                          onTap: () => setState(() => _selectedIndex = 7),
                        ),
                        _SidebarItemTile(
                          index: 8,
                          icon: LucideIcons.palette,
                          label: 'Themes',
                          isSelected: _selectedIndex == 8,
                          isExtended: _isRailExtended,
                          onTap: () => setState(() => _selectedIndex = 8),
                        ),
                        _SidebarItemTile(
                          index: 9,
                          icon: LucideIcons.settings,
                          label: 'Settings',
                          isSelected: _selectedIndex == 9,
                          isExtended: _isRailExtended,
                          onTap: () => setState(() => _selectedIndex = 9),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1),

                // Footer section (Fixed height, always visible)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 4.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Consumer(
                        builder: (context, ref, child) {
                          final themeMode = ref.watch(themeModeProvider);
                          final isDark = themeMode == ThemeMode.dark;

                          if (_isRailExtended) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              leading: Icon(
                                isDark ? LucideIcons.moon : LucideIcons.sun,
                                size: 20,
                              ),
                              title: Text(
                                isDark ? 'Dark Mode' : 'Light Mode',
                                style: const TextStyle(fontSize: 14),
                              ),
                              trailing: LottieToggle(
                                value: isDark,
                                onChanged: (val) => ref
                                    .read(themeModeProvider.notifier)
                                    .toggleTheme(val),
                              ),
                            );
                          } else {
                            return IconButton(
                              icon: Icon(
                                isDark ? LucideIcons.moon : LucideIcons.sun,
                                size: 20,
                              ),
                              onPressed: () => ref
                                  .read(themeModeProvider.notifier)
                                  .toggleTheme(!isDark),
                              tooltip: isDark
                                  ? 'Switch to Light Mode'
                                  : 'Switch to Dark Mode',
                            );
                          }
                        },
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          if (_isRailExtended) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              leading: const Icon(
                                LucideIcons.logOut,
                                size: 20,
                                color: Colors.redAccent,
                              ),
                              title: const Text(
                                'Sign Out',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.redAccent,
                                ),
                              ),
                              onTap: () =>
                                  ref.read(authServiceProvider).signOut(),
                            );
                          } else {
                            return IconButton(
                              icon: const Icon(
                                LucideIcons.logOut,
                                size: 20,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  ref.read(authServiceProvider).signOut(),
                              tooltip: 'Sign Out',
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return _OverviewView(claims: widget.claims);
      case 1:
        return const CatalogView();
      case 2:
        return const OrdersView();
      case 3:
        return const CustomersView();
      case 4:
        return const BillingView();
      case 5:
        return BlogView(claims: widget.claims);
      case 6:
        return FeatureGate(
          feature: Feature.b2bPortal,
          child: _B2BWholesalePlaceholder(),
        );
      case 7:
        return const ComplianceView();
      case 8:
        return const ThemesView();
      case 9:
        return const SettingsView();
      default:
        return Center(child: Text('Module Coming Soon: $_selectedIndex'));
    }
  }
}

class _OverviewView extends ConsumerWidget {
  final UserClaims claims;
  const _OverviewView({required this.claims});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(analyticsOverviewProvider);
    final alertsAsync = ref.watch(needsAttentionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard Overview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  Text(
                    claims.email?.split('@')[0] ?? claims.uid,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        context,
                        'Tenant: ${claims.tenantId}',
                        theme.primaryColor,
                      ),
                      _buildChip(
                        context,
                        'Role: ${claims.roles.join(", ")}',
                        Colors.orange,
                      ),
                      if (claims.isOwner)
                        _buildChip(context, 'OWNER', Colors.redAccent),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProvisioningPage(email: claims.email),
                            ),
                          );
                        },
                        child: _buildChip(
                          context,
                          'Configure Infrastructure ↗',
                          AppTheme.brandEmerald500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Trend Chart (Full Bleed)
              SizedBox(
                height: 360,
                width: double.infinity,
                child: statsAsync.when(
                  data: (stats) => _TrendChart(stats: stats),
                  loading: () => const Center(
                    child: SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(),
                    ),
                  ),
                  error: (e, s) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),

              // Stats Row
              statsAsync.when(
                data: (stats) => SizedBox(
                  height: 180,
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total GMV',
                          value:
                              '${stats.currency} ${stats.gmv.toStringAsFixed(2)}',
                          icon: LucideIcons.dollarSign,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _StatCard(
                          title: 'Orders',
                          value: stats.orderCount.toString(),
                          icon: LucideIcons.shoppingBag,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _StatCard(
                          title: 'Avg. Order',
                          value:
                              '${stats.currency} ${stats.aov.toStringAsFixed(2)}',
                          icon: LucideIcons.trendingUp,
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const Center(
                  child: SizedBox(width: 300, child: LinearProgressIndicator()),
                ),
                error: (e, s) => Text('Error loading stats: $e'),
              ),

              const SizedBox(height: 20),

              // Needs Attention Row
              Text(
                'Needs Attention',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              alertsAsync.when(
                data: (alerts) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _AlertItem(
                        label: 'Overdue Orders',
                        count: alerts.pendingOrdersOverdue,
                        icon: LucideIcons.clock,
                        color: alerts.pendingOrdersOverdue > 0
                            ? Colors.redAccent
                            : Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _AlertItem(
                        label: 'Low Stock',
                        count: alerts.lowStockVariants,
                        icon: LucideIcons.alertTriangle,
                        color: alerts.lowStockVariants > 0
                            ? Colors.orange
                            : Colors.green,
                      ),
                      const SizedBox(width: 16),
                      _AlertItem(
                        label: 'B2B Approvals',
                        count: alerts.pendingB2bApprovals,
                        icon: LucideIcons.userCheck,
                        color: alerts.pendingB2bApprovals > 0
                            ? Colors.blue
                            : Colors.green,
                      ),
                    ],
                  ),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Container(),
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Platform Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                height: 100,
                child: Center(child: Text('Activity Feed Coming Soon')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.2 : 0.1,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.4 : 0.2,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _AlertItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HoverScale(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.1
                    : 0.05,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.3
                      : 0.15,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HoverScale(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.6 : 0.8,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.25 : 0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum ChartType { line, bar }

enum TimeRange { today, h24, d7, d14, d28, d90 }

enum MetricType { sales, orders, aov, customers, conversion, returns }

class _TrendChart extends StatefulWidget {
  final AnalyticsOverview stats;
  const _TrendChart({required this.stats});

  @override
  State<_TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<_TrendChart> {
  MetricType _selectedMetric = MetricType.sales;
  ChartType _chartType = ChartType.line;
  TimeRange _timeRange = TimeRange.d7;

  List<DataPoint> _getFilteredData() {
    if (_timeRange == TimeRange.today) return widget.stats.todayHistory;
    if (_timeRange == TimeRange.h24) return widget.stats.h24History;

    List<DataPoint> source;
    switch (_selectedMetric) {
      case MetricType.sales:
        source = widget.stats.salesHistory;
        break;
      case MetricType.orders:
        source = widget.stats.orderHistory;
        break;
      case MetricType.aov:
        source = widget.stats.aovHistory;
        break;
      case MetricType.customers:
        source = widget.stats.customerHistory;
        break;
      case MetricType.conversion:
        source = widget.stats.conversionHistory;
        break;
      case MetricType.returns:
        source = widget.stats.returnHistory;
        break;
    }

    final days = switch (_timeRange) {
      TimeRange.today => 1,
      TimeRange.h24 => 1,
      TimeRange.d7 => 7,
      TimeRange.d14 => 14,
      TimeRange.d28 => 28,
      TimeRange.d90 => 90,
    };
    if (source.length <= days) return source;
    return source.sublist(source.length - days);
  }

  String _formatValue(double value) {
    switch (_selectedMetric) {
      case MetricType.sales:
      case MetricType.aov:
        return '\$${value.toStringAsFixed(0)}';
      case MetricType.conversion:
        return '${(value * 100).toStringAsFixed(1)}%';
      default:
        return value.toInt().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _getFilteredData();

    if (data.isEmpty) return const Center(child: Text('No data available'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Toolbar: Metric Selection (Scrollable)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Sales',
                isSelected: _selectedMetric == MetricType.sales,
                onTap: () => setState(() => _selectedMetric = MetricType.sales),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Orders',
                isSelected: _selectedMetric == MetricType.orders,
                onTap: () =>
                    setState(() => _selectedMetric = MetricType.orders),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'AOV',
                isSelected: _selectedMetric == MetricType.aov,
                onTap: () => setState(() => _selectedMetric = MetricType.aov),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Customers',
                isSelected: _selectedMetric == MetricType.customers,
                onTap: () =>
                    setState(() => _selectedMetric = MetricType.customers),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Conversion',
                isSelected: _selectedMetric == MetricType.conversion,
                onTap: () =>
                    setState(() => _selectedMetric = MetricType.conversion),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Returns',
                isSelected: _selectedMetric == MetricType.returns,
                onTap: () =>
                    setState(() => _selectedMetric = MetricType.returns),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Middle Toolbar: Chart Type & Time Range
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    LucideIcons.lineChart,
                    size: 18,
                    color: _chartType == ChartType.line
                        ? theme.primaryColor
                        : theme.hintColor,
                  ),
                  onPressed: () => setState(() => _chartType = ChartType.line),
                  tooltip: 'Line Chart',
                ),
                IconButton(
                  icon: Icon(
                    LucideIcons.barChart3,
                    size: 18,
                    color: _chartType == ChartType.bar
                        ? theme.primaryColor
                        : theme.hintColor,
                  ),
                  onPressed: () => setState(() => _chartType = ChartType.bar),
                  tooltip: 'Bar Chart',
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _RangeChip(
                      label: 'To Date',
                      isSelected: _timeRange == TimeRange.today,
                      onTap: () => setState(() => _timeRange = TimeRange.today),
                    ),
                    const SizedBox(width: 4),
                    _RangeChip(
                      label: '24H',
                      isSelected: _timeRange == TimeRange.h24,
                      onTap: () => setState(() => _timeRange = TimeRange.h24),
                    ),
                    const SizedBox(width: 4),
                    _RangeChip(
                      label: '7D',
                      isSelected: _timeRange == TimeRange.d7,
                      onTap: () => setState(() => _timeRange = TimeRange.d7),
                    ),
                    const SizedBox(width: 4),
                    _RangeChip(
                      label: '14D',
                      isSelected: _timeRange == TimeRange.d14,
                      onTap: () => setState(() => _timeRange = TimeRange.d14),
                    ),
                    const SizedBox(width: 4),
                    _RangeChip(
                      label: '28D',
                      isSelected: _timeRange == TimeRange.d28,
                      onTap: () => setState(() => _timeRange = TimeRange.d28),
                    ),
                    const SizedBox(width: 4),
                    _RangeChip(
                      label: '90D',
                      isSelected: _timeRange == TimeRange.d90,
                      onTap: () => setState(() => _timeRange = TimeRange.d90),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Chart Area
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.02, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey('$_selectedMetric-$_chartType-$_timeRange'),
              child: _chartType == ChartType.line
                  ? _buildLineChart(data, theme)
                  : _buildBarChart(data, theme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<DataPoint> data, ThemeData theme) {
    final hasSecondary = data.any((d) => d.secondaryValue != null);
    final showDots = _timeRange != TimeRange.today;

    final bars = <LineChartBarData>[
      LineChartBarData(
        spots: data
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.value))
            .toList(),
        isCurved: true,
        color: theme.primaryColor,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: showDots,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 4,
            color: theme.primaryColor,
            strokeWidth: 2,
            strokeColor: theme.scaffoldBackgroundColor,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          color: theme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
    ];

    if (hasSecondary) {
      bars.add(
        LineChartBarData(
          spots: data
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.secondaryValue ?? 0))
              .toList(),
          isCurved: true,
          color: theme.colorScheme.secondary.withValues(alpha: 0.4),
          barWidth: 2,
          dashArray: [5, 5],
          dotData: const FlDotData(show: false),
        ),
      );
    }

    return LineChart(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: bars,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => theme.cardColor,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                // Only show tooltip for the primary bar (index 0) to avoid duplication
                if (spot.barIndex != 0) return null;

                final dp = data[spot.spotIndex];
                final format =
                    (_timeRange == TimeRange.today ||
                        _timeRange == TimeRange.h24)
                    ? DateFormat('HH:mm')
                    : DateFormat('MMM d');
                final dateStr = format.format(dp.date);

                return LineTooltipItem(
                  '$dateStr\n',
                  theme.textTheme.labelSmall!,
                  children: [
                    TextSpan(
                      text: 'Actual: ${_formatValue(dp.value)}',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasSecondary)
                      TextSpan(
                        text: '\nRef: ${_formatValue(dp.secondaryValue ?? 0)}',
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<DataPoint> data, ThemeData theme) {
    final hasSecondary = data.any((d) => d.secondaryValue != null);

    return BarChart(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          final rods = <BarChartRodData>[
            BarChartRodData(
              toY: e.value.value,
              color: theme.primaryColor,
              width: hasSecondary ? 6 : 10,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ];

          if (e.value.secondaryValue != null) {
            rods.add(
              BarChartRodData(
                toY: e.value.secondaryValue!,
                color: theme.colorScheme.secondary.withValues(alpha: 0.6),
                width: 6,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            );
          }

          return BarChartGroupData(x: e.key, barsSpace: 4, barRods: rods);
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => theme.cardColor,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final dp = data[groupIndex];
              final dateStr = DateFormat('MMM d').format(dp.date);

              String text = '$dateStr\n';
              if (hasSecondary) {
                if (rodIndex == 0) {
                  text += 'Actual: ${_formatValue(dp.value)}';
                } else {
                  text += 'Target/Ref: ${_formatValue(dp.secondaryValue ?? 0)}';
                }
              } else {
                text += _formatValue(rod.toY);
              }

              return BarTooltipItem(
                text,
                theme.textTheme.labelSmall!.copyWith(
                  color: rod.color,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.primaryColor : theme.hintColor,
          ),
        ),
      ),
    );
  }
}

class _B2BWholesalePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('B2B Wholesale Portal')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.usersRound,
              size: 64,
              color: theme.primaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'B2B Wholesale Infrastructure',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage wholesale customers, custom price lists, and net terms.',
            ),
            const SizedBox(height: 48),
            // Example of what would be here
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMockStat(context, 'Active Clients', '12'),
                const SizedBox(width: 24),
                _buildMockStat(context, 'Pending Apps', '4'),
                const SizedBox(width: 24),
                _buildMockStat(context, 'Credit Limit Usage', '68%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockStat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _SidebarItemTile extends StatefulWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExtended;
  final VoidCallback onTap;

  const _SidebarItemTile({
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExtended,
    required this.onTap,
  });

  @override
  State<_SidebarItemTile> createState() => _SidebarItemTileState();
}

class _SidebarItemTileState extends State<_SidebarItemTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeBgColor = theme.primaryColor.withValues(
      alpha: isDark ? 0.15 : 0.08,
    );
    final hoverBgColor = theme.primaryColor.withValues(
      alpha: isDark ? 0.08 : 0.03,
    );
    final activeTextColor = theme.primaryColor;
    final inactiveTextColor = isDark ? Colors.grey[400]! : Colors.grey[700]!;

    final currentBgColor = widget.isSelected
        ? activeBgColor
        : (_isHovered ? hoverBgColor : Colors.transparent);
    final currentTextColor = widget.isSelected
        ? activeTextColor
        : inactiveTextColor;

    Widget content;
    if (widget.isExtended) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? theme.primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Icon(widget.icon, size: 20, color: currentTextColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: currentTextColor,
                  fontWeight: widget.isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      content = Tooltip(
        message: widget.label,
        waitDuration: const Duration(milliseconds: 500),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? theme.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Icon(widget.icon, size: 22, color: currentTextColor),
            ],
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
          decoration: BoxDecoration(
            color: currentBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: content,
        ),
      ),
    );
  }
}
