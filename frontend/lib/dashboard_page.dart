import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:kloudshop/models/analytics.dart';
import 'package:kloudshop/models/user_claims.dart';
import 'package:kloudshop/services/auth_service.dart';
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
import 'package:kloudshop/services/api_service.dart';

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
        final fragmentPath = uri.fragment.startsWith('/') ? uri.fragment : '/${uri.fragment}';
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
            content: Text('Plan upgraded successfully! Welcome to your new tier.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Switch to Billing tab (index 4)
        setState(() => _selectedIndex = 4);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e'), backgroundColor: Colors.red),
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
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final theme = Theme.of(context);
        return NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          labelType: NavigationRailLabelType.none,
          extended: _isRailExtended,
          minExtendedWidth: 240,
          unselectedIconTheme: theme.navigationRailTheme.unselectedIconTheme,
          selectedIconTheme: theme.navigationRailTheme.selectedIconTheme,
          unselectedLabelTextStyle: theme.navigationRailTheme.unselectedLabelTextStyle,
          selectedLabelTextStyle: theme.navigationRailTheme.selectedLabelTextStyle,
          leading: Column(
            children: [
              IconButton(
                icon: Icon(_isRailExtended ? LucideIcons.chevronLeft : LucideIcons.menu),
                onPressed: () => setState(() => _isRailExtended = !_isRailExtended),
                tooltip: _isRailExtended ? 'Collapse' : 'Expand',
              ),
              const SizedBox(height: 16),
              // Persistent Logo / Header
              _isRailExtended 
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.store, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'KloudShop',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.store, color: Colors.white, size: 24),
                  ),
              const SizedBox(height: 32),
              // Tenant/Store Info (Only when extended)
              if (_isRailExtended)
                Consumer(
                  builder: (context, ref, child) {
                    final settingsAsync = ref.watch(tenantSettingsProvider);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: settingsAsync.when(
                        data: (settings) => Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                settings.name.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: theme.primaryColor,
                                ),
                              ),
                              Text(
                                (settings.config['sector'] as String?)?.toUpperCase() ?? 'MERCHANT',
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        loading: () => const SizedBox(
                          width: 200,
                          child: LinearProgressIndicator(),
                        ),
                        error: (e, s) => const SizedBox.shrink(),
                      ),
                    );
                  },
                ),
            ],
          ),
          trailing: _isRailExtended ? SizedBox(
            width: 240,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Divider(),
                Consumer(
                  builder: (context, ref, child) {
                    final themeMode = ref.watch(themeModeProvider);
                    final isDark = themeMode == ThemeMode.dark;
                    return ListTile(
                      leading: Icon(isDark ? LucideIcons.moon : LucideIcons.sun),
                      title: Text(isDark ? 'Dark Mode' : 'Light Mode'),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (val) => ref.read(themeModeProvider.notifier).toggleTheme(val),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.logOut),
                  title: const Text('Sign Out'),
                  onTap: () => ref.read(authServiceProvider).signOut(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ) : Column(
            children: [
              const Divider(),
              Consumer(
                builder: (context, ref, child) {
                  final themeMode = ref.watch(themeModeProvider);
                  final isDark = themeMode == ThemeMode.dark;
                  return IconButton(
                    icon: Icon(isDark ? LucideIcons.moon : LucideIcons.sun),
                    onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(!isDark),
                    tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  );
                },
              ),
              IconButton(
                icon: const Icon(LucideIcons.logOut),
                onPressed: () => ref.read(authServiceProvider).signOut(),
                tooltip: 'Sign Out',
              ),
              const SizedBox(height: 16),
            ],
          ),
          destinations: const [
            NavigationRailDestination(
              icon: Icon(LucideIcons.layoutDashboard),
              selectedIcon: Icon(LucideIcons.layoutDashboard),
              label: Text('Overview'),
            ),
            NavigationRailDestination(
              icon: Icon(LucideIcons.shoppingCart),
              label: Text('Catalog'),
            ),
            NavigationRailDestination(
              icon: Icon(LucideIcons.package),
              label: Text('Orders'),
            ),
            NavigationRailDestination(
              icon: Icon(LucideIcons.users),
              label: Text('Customers'),
            ),
            NavigationRailDestination(
              icon: Icon(LucideIcons.creditCard),
              selectedIcon: Icon(LucideIcons.creditCard),
              label: Text('Billing'),
            ),
            NavigationRailDestination(
              icon: Icon(LucideIcons.newspaper),
              selectedIcon: Icon(LucideIcons.newspaper),
              label: Text('Blog'),
            ),
            NavigationRailDestination(
              icon: Icon(LucideIcons.shieldCheck),
              selectedIcon: Icon(LucideIcons.shieldCheck),
              label: Text('Compliance'),
            ),
            NavigationRailDestination(
              icon: Icon(LucideIcons.settings),
              label: Text('Settings'),
            ),
          ],
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
        return const ComplianceView();
      case 7:
        return const SettingsView();
      default:
        return Center(
          child: Text('Module Coming Soon: $_selectedIndex'),
        );
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
        title: Text('Dashboard Overview', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
                ),
                Text(
                  claims.email?.split('@')[0] ?? claims.uid,
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip(context, 'Tenant: ${claims.tenantId}', theme.primaryColor),
                    _buildChip(context, 'Role: ${claims.roles.join(", ")}', Colors.orange),
                    if (claims.isOwner) _buildChip(context, 'OWNER', Colors.redAccent),
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
                    Expanded(child: _StatCard(title: 'Total GMV', value: '${stats.currency} ${stats.gmv.toStringAsFixed(2)}', icon: LucideIcons.dollarSign)),
                    const SizedBox(width: 24),
                    Expanded(child: _StatCard(title: 'Orders', value: stats.orderCount.toString(), icon: LucideIcons.shoppingBag)),
                    const SizedBox(width: 24),
                    Expanded(child: _StatCard(title: 'Avg. Order', value: '${stats.currency} ${stats.aov.toStringAsFixed(2)}', icon: LucideIcons.trendingUp)),
                  ],
                ),
              ),
              loading: () => const Center(
                child: SizedBox(
                  width: 300,
                  child: LinearProgressIndicator(),
                ),
              ),
              error: (e, s) => Text('Error loading stats: $e'),
            ),
            
            const SizedBox(height: 20),
            
            // Needs Attention Row
            Text('Needs Attention', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                      color: alerts.pendingOrdersOverdue > 0 ? Colors.redAccent : Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _AlertItem(
                      label: 'Low Stock', 
                      count: alerts.lowStockVariants, 
                      icon: LucideIcons.alertTriangle,
                      color: alerts.lowStockVariants > 0 ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _AlertItem(
                      label: 'B2B Approvals', 
                      count: alerts.pendingB2bApprovals, 
                      icon: LucideIcons.userCheck,
                      color: alerts.pendingB2bApprovals > 0 ? Colors.blue : Colors.green,
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
            Text('Platform Activity', style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor)),
            const SizedBox(height: 16),
            const SizedBox(height: 100, child: Center(child: Text('Activity Feed Coming Soon'))),
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
        color: color.withValues(alpha: theme.brightness == Brightness.dark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: theme.brightness == Brightness.dark ? 0.4 : 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _AlertItem({required this.label, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
              Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
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
              color: theme.colorScheme.primary.withValues(alpha: theme.brightness == Brightness.dark ? 0.25 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(height: 16),
          Text(title, style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
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
      case MetricType.sales: source = widget.stats.salesHistory; break;
      case MetricType.orders: source = widget.stats.orderHistory; break;
      case MetricType.aov: source = widget.stats.aovHistory; break;
      case MetricType.customers: source = widget.stats.customerHistory; break;
      case MetricType.conversion: source = widget.stats.conversionHistory; break;
      case MetricType.returns: source = widget.stats.returnHistory; break;
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
              _FilterChip(label: 'Sales', isSelected: _selectedMetric == MetricType.sales, onTap: () => setState(() => _selectedMetric = MetricType.sales)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Orders', isSelected: _selectedMetric == MetricType.orders, onTap: () => setState(() => _selectedMetric = MetricType.orders)),
              const SizedBox(width: 8),
              _FilterChip(label: 'AOV', isSelected: _selectedMetric == MetricType.aov, onTap: () => setState(() => _selectedMetric = MetricType.aov)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Customers', isSelected: _selectedMetric == MetricType.customers, onTap: () => setState(() => _selectedMetric = MetricType.customers)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Conversion', isSelected: _selectedMetric == MetricType.conversion, onTap: () => setState(() => _selectedMetric = MetricType.conversion)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Returns', isSelected: _selectedMetric == MetricType.returns, onTap: () => setState(() => _selectedMetric = MetricType.returns)),
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
                  icon: Icon(LucideIcons.lineChart, size: 18, color: _chartType == ChartType.line ? theme.primaryColor : theme.hintColor),
                  onPressed: () => setState(() => _chartType = ChartType.line),
                  tooltip: 'Line Chart',
                ),
                IconButton(
                  icon: Icon(LucideIcons.barChart3, size: 18, color: _chartType == ChartType.bar ? theme.primaryColor : theme.hintColor),
                  onPressed: () => setState(() => _chartType = ChartType.bar),
                  tooltip: 'Bar Chart',
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _RangeChip(label: 'To Date', isSelected: _timeRange == TimeRange.today, onTap: () => setState(() => _timeRange = TimeRange.today)),
                  const SizedBox(width: 4),
                  _RangeChip(label: '24H', isSelected: _timeRange == TimeRange.h24, onTap: () => setState(() => _timeRange = TimeRange.h24)),
                  const SizedBox(width: 4),
                  _RangeChip(label: '7D', isSelected: _timeRange == TimeRange.d7, onTap: () => setState(() => _timeRange = TimeRange.d7)),
                  const SizedBox(width: 4),
                  _RangeChip(label: '14D', isSelected: _timeRange == TimeRange.d14, onTap: () => setState(() => _timeRange = TimeRange.d14)),
                  const SizedBox(width: 4),
                  _RangeChip(label: '28D', isSelected: _timeRange == TimeRange.d28, onTap: () => setState(() => _timeRange = TimeRange.d28)),
                  const SizedBox(width: 4),
                  _RangeChip(label: '90D', isSelected: _timeRange == TimeRange.d90, onTap: () => setState(() => _timeRange = TimeRange.d90)),
                ],
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
        spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
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
          spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.secondaryValue ?? 0)).toList(),
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
                final format = (_timeRange == TimeRange.today || _timeRange == TimeRange.h24) 
                    ? DateFormat('HH:mm') 
                    : DateFormat('MMM d');
                final dateStr = format.format(dp.date);
                
                return LineTooltipItem(
                  '$dateStr\n',
                  theme.textTheme.labelSmall!,
                  children: [
                    TextSpan(
                      text: 'Actual: ${_formatValue(dp.value)}',
                      style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                    ),
                    if (hasSecondary)
                      TextSpan(
                        text: '\nRef: ${_formatValue(dp.secondaryValue ?? 0)}',
                        style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 10),
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ];

          if (e.value.secondaryValue != null) {
            rods.add(
              BarChartRodData(
                toY: e.value.secondaryValue!,
                color: theme.colorScheme.secondary.withValues(alpha: 0.6),
                width: 6,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            );
          }

          return BarChartGroupData(
            x: e.key,
            barsSpace: 4,
            barRods: rods,
          );
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

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? theme.primaryColor : theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
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

  const _RangeChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withValues(alpha: 0.15) : Colors.transparent,
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
