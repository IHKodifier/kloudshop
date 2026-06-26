import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:kloudshop/models/analytics.dart';
import 'package:kloudshop/providers/analytics_providers.dart';
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
import 'package:kloudshop/providers/theme_providers.dart';
import 'package:kloudshop/providers/settings_providers.dart';
import 'package:kloudshop/views/themes_view.dart';
import 'package:kloudshop/views/pages_view.dart';
import 'package:kloudshop/views/navigation_view.dart';
import 'package:kloudshop/views/preferences_view.dart';
import 'package:kloudshop/widgets/feature_gate.dart';
import 'package:kloudshop/widgets/theme_toggle_switch.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:kloudshop/views/product_editor_view.dart';

class DashboardPage extends ConsumerStatefulWidget {
  final UserClaims claims;

  const DashboardPage({super.key, required this.claims});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedIndex = 0;
  bool _isRailExtended = true;
  bool _isMouseOverSidebar = false;
  bool _isOnlineStoreExpanded = true;
  bool _isProductsExpanded = false;

  @override
  void initState() {
    super.initState();
    _isRailExtended = ref.read(sidebarExtendedProvider);
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
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Main Content Area
          AnimatedPositioned(
            duration: const Duration(milliseconds: 3600),
            curve: Curves.bounceOut,
            left: _isRailExtended ? 240.0 : 0.0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent &&
                    _isMouseOverSidebar) {
                  GestureBinding.instance.pointerSignalResolver.register(
                    pointerSignal,
                    (event) {
                      // Absorb scroll events to isolate sidebar scrolling
                    },
                  );
                }
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 3600),
                      curve: Curves.bounceOut,
                      padding: EdgeInsets.only(
                        top: 64.0,
                        left: _isRailExtended ? 0.0 : 80.0,
                      ),
                      child: _buildMainContent(),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildCustomStickyHeader(),
                  ),
                ],
              ),
            ),
          ),

          // 2. Sidebar / Navigation Rail
          AnimatedPositioned(
            duration: const Duration(milliseconds: 3600),
            curve: Curves.bounceOut,
            left: _isRailExtended ? 0.0 : 12.0,
            top: _isRailExtended ? 0.0 : 76.0,
            bottom: _isRailExtended ? 0.0 : 12.0,
            width: _isRailExtended ? 240.0 : 68.0,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isMouseOverSidebar = true),
              onExit: (_) => setState(() => _isMouseOverSidebar = false),
              child: _buildSidebar(context),
            ),
          ),

          // 3. Floating Toggle Button (Overlaps the right border)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 3600),
            curve: Curves.bounceOut,
            left: _isRailExtended ? 240.0 - 14.0 : 12.0 + 68.0 - 14.0,
            top: MediaQuery.of(context).size.height / 2 - 14.0,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isRailExtended = !_isRailExtended;
                  });
                  ref.read(sidebarExtendedProvider.notifier).toggle(_isRailExtended);
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: AnimatedRotation(
                      turns: _isRailExtended ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 3600),
                      curve: Curves.bounceOut,
                      child: const Icon(
                        LucideIcons.chevronRight,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomStickyHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo & Title (permanent part of the app bar)
          Row(
            mainAxisSize: MainAxisSize.min,
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
          const Spacer(),

          if (MediaQuery.of(context).size.width > 950) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 3600),
              curve: Curves.bounceOut,
              width: _isRailExtended ? 380.0 : 500.0,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(LucideIcons.search, size: 16, color: theme.hintColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search orders, customers, or analytics...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: theme.hintColor,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],

          // Right items
          Row(
            children: [
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      LucideIcons.bell,
                      size: 20,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No new notifications')),
                      );
                    },
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  LucideIcons.helpCircle,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Documentation & Support')),
                  );
                },
              ),
              const SizedBox(width: 16),
              Consumer(
                builder: (context, ref, child) {
                  final settingsAsync = ref.watch(tenantSettingsProvider);
                  return Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=80&h=80&fit=crop&q=80',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 32,
                                height: 32,
                                color: theme.primaryColor,
                                child: const Center(
                                  child: Text(
                                    'MA',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                        ),
                      ),
                      if (MediaQuery.of(context).size.width > 800) ...[
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Merchant Admin',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                            settingsAsync.when(
                              data: (settings) {
                                final name = settings.name.toUpperCase();
                                final sector =
                                    (settings.config['sector'] as String?)
                                        ?.toUpperCase() ??
                                    'MERCHANT';
                                return Text(
                                  '$name • $sector',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: theme.hintColor,
                                  ),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (e, s) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 3600),
          curve: Curves.bounceOut,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181A) : const Color(0xFFF1F2F4),
            borderRadius: _isRailExtended
                ? BorderRadius.zero
                : BorderRadius.circular(20.0),
            boxShadow: _isRailExtended
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.35 : 0.08,
                      ),
                      blurRadius: 24,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                  ],
            border: _isRailExtended
                ? null
                : Border.all(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.08,
                    ),
                    width: 0.8,
                  ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),

                // Main navigation scroll view (Scrollable center)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SidebarItemTile(
                          index: 0,
                          icon: LucideIcons.home,
                          label: 'Home',
                          isSelected: _selectedIndex == 0,
                          isExtended: _isRailExtended,
                          onTap: () => setState(() => _selectedIndex = 0),
                        ),
                        _SidebarItemTile(
                          index: 1,
                          icon: LucideIcons.tag,
                          label: 'Products',
                          isSelected:
                              _selectedIndex == 1 ||
                              (_selectedIndex >= 13 && _selectedIndex <= 17),
                          isExtended: _isRailExtended,
                          isExpanded: _isProductsExpanded,
                          onTap: () {
                            setState(() {
                              _selectedIndex = 1;
                              _isProductsExpanded = !_isProductsExpanded;
                            });
                          },
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 3600),
                          curve: Curves.bounceOut,
                          child: _isProductsExpanded
                              ? (!_isRailExtended
                                    ? Container(
                                        key: const ValueKey(
                                          'products_collapsed_menu',
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 12.0,
                                          vertical: 4.0,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(
                                                  0xFF10B981,
                                                ).withValues(alpha: 0.12)
                                              : const Color(
                                                  0xFF10B981,
                                                ).withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF10B981,
                                            ).withValues(alpha: 0.15),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            _SidebarItemTile(
                                              index: 13,
                                              icon: LucideIcons.layers,
                                              label: 'Collections',
                                              isSelected: _selectedIndex == 13,
                                              isExtended: false,
                                              onTap: () => setState(
                                                () => _selectedIndex = 13,
                                              ),
                                            ),
                                            _SidebarItemTile(
                                              index: 14,
                                              icon: LucideIcons.packageOpen,
                                              label: 'Inventory',
                                              isSelected: _selectedIndex == 14,
                                              isExtended: false,
                                              onTap: () => setState(
                                                () => _selectedIndex = 14,
                                              ),
                                            ),
                                            _SidebarItemTile(
                                              index: 15,
                                              icon: LucideIcons.fileInput,
                                              label: 'Purchase orders',
                                              isSelected: _selectedIndex == 15,
                                              isExtended: false,
                                              onTap: () => setState(
                                                () => _selectedIndex = 15,
                                              ),
                                            ),
                                            _SidebarItemTile(
                                              index: 16,
                                              icon: LucideIcons.arrowLeftRight,
                                              label: 'Transfers',
                                              isSelected: _selectedIndex == 16,
                                              isExtended: false,
                                              onTap: () => setState(
                                                () => _selectedIndex = 16,
                                              ),
                                            ),
                                            _SidebarItemTile(
                                              index: 17,
                                              icon: LucideIcons.gift,
                                              label: 'Gift cards',
                                              isSelected: _selectedIndex == 17,
                                              isExtended: false,
                                              onTap: () => setState(
                                                () => _selectedIndex = 17,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        key: const ValueKey(
                                          'products_expanded_menu',
                                        ),
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16.0,
                                            ),
                                            child: _SidebarItemTile(
                                              index: 13,
                                              icon: LucideIcons.layers,
                                              label: 'Collections',
                                              isSelected: _selectedIndex == 13,
                                              isExtended: true,
                                              onTap: () => setState(
                                                () => _selectedIndex = 13,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16.0,
                                            ),
                                            child: _SidebarItemTile(
                                              index: 14,
                                              icon: LucideIcons.packageOpen,
                                              label: 'Inventory',
                                              isSelected: _selectedIndex == 14,
                                              isExtended: true,
                                              onTap: () => setState(
                                                () => _selectedIndex = 14,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16.0,
                                            ),
                                            child: _SidebarItemTile(
                                              index: 15,
                                              icon: LucideIcons.fileInput,
                                              label: 'Purchase orders',
                                              isSelected: _selectedIndex == 15,
                                              isExtended: true,
                                              onTap: () => setState(
                                                () => _selectedIndex = 15,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16.0,
                                            ),
                                            child: _SidebarItemTile(
                                              index: 16,
                                              icon: LucideIcons.arrowLeftRight,
                                              label: 'Transfers',
                                              isSelected: _selectedIndex == 16,
                                              isExtended: true,
                                              onTap: () => setState(
                                                () => _selectedIndex = 16,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16.0,
                                            ),
                                            child: _SidebarItemTile(
                                              index: 17,
                                              icon: LucideIcons.gift,
                                              label: 'Gift cards',
                                              isSelected: _selectedIndex == 17,
                                              isExtended: true,
                                              onTap: () => setState(
                                                () => _selectedIndex = 17,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ))
                              : const SizedBox.shrink(
                                  key: ValueKey('products_empty_menu'),
                                ),
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
                        if (!_isRailExtended)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 6.0,
                            ),
                            child: Divider(
                              height: 1,
                              thickness: 1.6,
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.25),
                            ),
                          )
                        else ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20.0,
                              top: 8.0,
                              bottom: 2.0,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Sales channels',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ],

                        _SidebarItemTile(
                          index: -1,
                          icon: LucideIcons.globe,
                          label: 'Online Store',
                          isSelected:
                              _selectedIndex == 8 ||
                              _selectedIndex == 5 ||
                              _selectedIndex == 10 ||
                              _selectedIndex == 11 ||
                              _selectedIndex == 12,
                          isExtended: _isRailExtended,
                          isExpanded: _isOnlineStoreExpanded,
                          onTap: () {
                            setState(() {
                              _isOnlineStoreExpanded = !_isOnlineStoreExpanded;
                            });
                          },
                        ),

                        // Render Online Store items if expanded or if rail is collapsed (show all in rail)
                        // Render Online Store items if expanded
                        AnimatedSize(
                          duration: const Duration(milliseconds: 3600),
                          curve: Curves.bounceOut,
                          child: _isOnlineStoreExpanded
                              ? (!_isRailExtended
                                    ? Container(
                                        key: const ValueKey(
                                          'onlinestore_collapsed_menu',
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 12.0,
                                          vertical: 4.0,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(
                                                  0xFF10B981,
                                                ).withValues(alpha: 0.12)
                                              : const Color(
                                                  0xFF10B981,
                                                ).withValues(alpha: 0.06),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF10B981,
                                            ).withValues(alpha: 0.15),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            _SidebarItemTile(
                                              index: 8,
                                              icon: LucideIcons.palette,
                                              label: 'Themes',
                                              isSelected: _selectedIndex == 8,
                                              isExtended: false,
                                              onTap: () => setState(
                                                () => _selectedIndex = 8,
                                              ),
                                            ),
                                            _SidebarItemTile(
                                              index: 5,
                                              icon: LucideIcons.newspaper,
                                              label: 'Blog',
                                              isSelected: _selectedIndex == 5,
                                              isExtended: false,
                                              onTap: () => setState(
                                                () => _selectedIndex = 5,
                                              ),
                                            ),
                                            _SidebarItemTile(
                                              index: 10,
                                              icon: LucideIcons.fileText,
                                              label: 'Pages',
                                              isSelected: _selectedIndex == 10,
                                              isExtended: false,
                                              onTap: () => setState(
                                                () => _selectedIndex = 10,
                                              ),
                                            ),
                                            _SidebarItemTile(
                                              index: 11,
                                              icon: LucideIcons.menu,
                                              label: 'Navigation',
                                              isSelected: _selectedIndex == 11,
                                              isExtended: false,
                                              onTap: () => setState(
                                                () => _selectedIndex = 11,
                                              ),
                                            ),
                                            _SidebarItemTile(
                                              index: 12,
                                              icon: LucideIcons.settings2,
                                              label: 'Preferences',
                                              isSelected: _selectedIndex == 12,
                                              isExtended: false,
                                              onTap: () => setState(
                                                () => _selectedIndex = 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        key: const ValueKey(
                                          'onlinestore_expanded_menu',
                                        ),
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16.0,
                                            ),
                                            child: _SidebarItemTile(
                                              index: 8,
                                              icon: LucideIcons.palette,
                                              label: 'Themes',
                                              isSelected: _selectedIndex == 8,
                                              isExtended: true,
                                              onTap: () => setState(
                                                () => _selectedIndex = 8,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16.0,
                                            ),
                                            child: _SidebarItemTile(
                                              index: 5,
                                              icon: LucideIcons.newspaper,
                                              label: 'Blog',
                                              isSelected: _selectedIndex == 5,
                                              isExtended: true,
                                              onTap: () => setState(
                                                () => _selectedIndex = 5,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16.0,
                                            ),
                                            child: _SidebarItemTile(
                                              index: 10,
                                              icon: LucideIcons.fileText,
                                              label: 'Pages',
                                              isSelected: _selectedIndex == 10,
                                              isExtended: true,
                                              onTap: () => setState(
                                                () => _selectedIndex = 10,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16.0,
                                            ),
                                            child: _SidebarItemTile(
                                              index: 11,
                                              icon: LucideIcons.menu,
                                              label: 'Navigation',
                                              isSelected: _selectedIndex == 11,
                                              isExtended: true,
                                              onTap: () => setState(
                                                () => _selectedIndex = 11,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16.0,
                                            ),
                                            child: _SidebarItemTile(
                                              index: 12,
                                              icon: LucideIcons.settings2,
                                              label: 'Preferences',
                                              isSelected: _selectedIndex == 12,
                                              isExtended: true,
                                              onTap: () => setState(
                                                () => _selectedIndex = 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ))
                              : const SizedBox.shrink(
                                  key: ValueKey('onlinestore_empty_menu'),
                                ),
                        ),

                        _SidebarItemTile(
                          index: 6,
                          icon: LucideIcons.usersRound,
                          label: 'Wholesale',
                          isSelected: _selectedIndex == 6,
                          isExtended: _isRailExtended,
                          onTap: () => setState(() => _selectedIndex = 6),
                        ),
                        if (!_isRailExtended)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 6.0,
                            ),
                            child: Divider(
                              height: 1,
                              thickness: 1.6,
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.25),
                            ),
                          )
                        else ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20.0,
                              top: 8.0,
                              bottom: 2.0,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Admin & platform',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ],
                        _SidebarItemTile(
                          index: 4,
                          icon: LucideIcons.creditCard,
                          label: 'Billing',
                          isSelected: _selectedIndex == 4,
                          isExtended: _isRailExtended,
                          onTap: () => setState(() => _selectedIndex = 4),
                        ),
                        _SidebarItemTile(
                          index: 7,
                          icon: LucideIcons.shieldCheck,
                          label: 'Compliance',
                          isSelected: _selectedIndex == 7,
                          isExtended: _isRailExtended,
                          onTap: () => setState(() => _selectedIndex = 7),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1),

                // Footer section (Fixed height, always visible, containing Settings, Theme Mode, and Sign Out)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 4.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Settings tile (sticky third from bottom)
                      _SidebarItemTile(
                        index: 9,
                        icon: LucideIcons.settings,
                        label: 'Settings',
                        isSelected: _selectedIndex == 9,
                        isExtended: _isRailExtended,
                        onTap: () => setState(() => _selectedIndex = 9),
                      ),
                      const SizedBox(height: 4),
                      Consumer(
                        builder: (context, ref, child) {
                          final themeMode = ref.watch(themeModeProvider);
                          final isDark =
                              themeMode == ThemeMode.dark ||
                              (themeMode == ThemeMode.system &&
                                  Theme.of(context).brightness ==
                                      Brightness.dark);

                          if (_isRailExtended) {
                            return Material(
                              color: Colors.transparent,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const NeverScrollableScrollPhysics(),
                                child: SizedBox(
                                  width: 232,
                                  child: ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    leading: Icon(
                                      isDark
                                          ? LucideIcons.moon
                                          : LucideIcons.sun,
                                      size: 20,
                                    ),
                                    title: const Text(
                                      'Theme Mode',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    trailing: ThemeToggleSwitch(
                                      value: isDark,
                                      onChanged: (val) {
                                        _triggerThemeSwitchWithOverlay(
                                          context,
                                          ref,
                                          val,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return IconButton(
                              icon: Icon(
                                isDark ? LucideIcons.moon : LucideIcons.sun,
                                size: 15,
                              ),
                              onPressed: () {
                                _triggerThemeSwitchWithOverlay(
                                  context,
                                  ref,
                                  !isDark,
                                );
                              },
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
                            return Material(
                              color: Colors.transparent,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const NeverScrollableScrollPhysics(),
                                child: SizedBox(
                                  width: 232,
                                  child: ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
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
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return IconButton(
                              icon: const Icon(
                                LucideIcons.logOut,
                                size: 15,
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
        return _OverviewView(
          claims: widget.claims,
          onNavigate: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        );
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
      case 10:
        return const PagesView();
      case 11:
        return const NavigationView();
      case 12:
        return const PreferencesView();
      case 13:
        return _buildSubMenuPlaceholder('Collections', LucideIcons.layers);
      case 14:
        return _buildSubMenuPlaceholder('Inventory', LucideIcons.packageOpen);
      case 15:
        return _buildSubMenuPlaceholder(
          'Purchase Orders',
          LucideIcons.fileInput,
        );
      case 16:
        return _buildSubMenuPlaceholder(
          'Transfers',
          LucideIcons.arrowLeftRight,
        );
      case 17:
        return _buildSubMenuPlaceholder('Gift Cards', LucideIcons.gift);
      default:
        return Center(child: Text('Module Coming Soon: $_selectedIndex'));
    }
  }

  Widget _buildSubMenuPlaceholder(String title, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF020617)
          : const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: theme.primaryColor),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This section is coming soon. Manage your store\'s $title here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _triggerThemeSwitchWithOverlay(
    BuildContext context,
    WidgetRef ref,
    bool targetIsDark,
  ) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _ThemeSwitchOverlayWidget(
          targetIsDark: targetIsDark,
          onSwitchTheme: () {
            ref.read(themeModeProvider.notifier).toggleTheme(targetIsDark);
          },
          onComplete: () {
            entry.remove();
          },
        );
      },
    );

    overlay.insert(entry);
  }
}

class _OverviewView extends ConsumerStatefulWidget {
  final UserClaims claims;
  final Function(int) onNavigate;
  const _OverviewView({required this.claims, required this.onNavigate});

  @override
  ConsumerState<_OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends ConsumerState<_OverviewView> {
  int _expandedIndex = 0;
  final List<bool> _completedSteps = [false, false, false, false];

  Widget _buildStepIllustration(int index, bool isDark) {
    final accentColor = AppTheme.brandEmerald500;
    final bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    switch (index) {
      case 0: // Product Card Illustration
        return Container(
          width: 140,
          height: 100,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                bottom: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    LucideIcons.package,
                    size: 24,
                    color: accentColor.withOpacity(0.8),
                  ),
                ),
              ),
              Positioned(
                bottom: 22,
                left: 8,
                child: Container(
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white30 : Colors.black26,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  width: 30,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        );
      case 1: // Online Store Illustration
        return Container(
          width: 140,
          height: 100,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 8,
                        color: accentColor.withOpacity(0.1),
                        child: Row(
                          children: [
                            const SizedBox(width: 4),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Row(
                            children: [
                              Container(
                                width: 25,
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Icon(
                                  LucideIcons.layout,
                                  size: 10,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 4,
                                      color: isDark
                                          ? Colors.white30
                                          : Colors.black26,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 20,
                                      height: 4,
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.black12,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      case 2: // Shipping & Taxes Illustration
        return Container(
          width: 140,
          height: 100,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                LucideIcons.globe,
                size: 36,
                color: accentColor.withOpacity(0.4),
              ),
              Positioned(
                top: 16,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'USA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.truck, size: 8, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        'Free',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      case 3: // Launch Rocket Illustration
        return Container(
          width: 140,
          height: 100,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: Center(
            child: Icon(LucideIcons.rocket, size: 40, color: accentColor),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final statsAsync = ref.watch(analyticsOverviewProvider);
    final alertsAsync = ref.watch(needsAttentionProvider);
    final stats = statsAsync.value;
    final alerts = alertsAsync.value;

    final completedCount = _completedSteps.where((c) => c).length;
    final progressPercentage = completedCount / _completedSteps.length;

    final setupGuideCard = Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Setup guide',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use this personalized guide to get your store up and running.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$completedCount / 4 completed',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPercentage,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.brandEmerald500,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildAccordionItem(
              index: 0,
              title: 'Add your first product',
              description:
                  'Write a description, add photos, and set pricing for the products you plan to sell.',
              action: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () => widget.onNavigate(1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandEmerald500,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text(
                      'Add product',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onNavigate(1),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black87,
                    ),
                    child: const Text('Import products'),
                  ),
                ],
              ),
              isDark: isDark,
              theme: theme,
            ),
            _buildDivider(theme),

            _buildAccordionItem(
              index: 1,
              title: 'Set up your online store theme',
              description:
                  'Choose a theme, add a logo, and customize the look of your store to match your brand.',
              action: ElevatedButton(
                onPressed: () => widget.onNavigate(8),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandEmerald500,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text(
                  'Customize theme',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              isDark: isDark,
              theme: theme,
            ),
            _buildDivider(theme),

            _buildAccordionItem(
              index: 2,
              title: 'Configure shipping & taxes',
              description:
                  'Set up delivery zones, conditional shipping rates, and automatic Stripe tax fallbacks.',
              action: ElevatedButton(
                onPressed: () => widget.onNavigate(9),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandEmerald500,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text(
                  'Configure settings',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              isDark: isDark,
              theme: theme,
            ),
            _buildDivider(theme),

            _buildAccordionItem(
              index: 3,
              title: 'Launch your online store',
              description:
                  'Remove visitor password protection and launch your storefront so anyone can browse and buy.',
              action: ElevatedButton(
                onPressed: () => widget.onNavigate(12),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandEmerald500,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text(
                  'Launch store',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              isDark: isDark,
              theme: theme,
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.checkCircle2,
                  color: completedCount == 4
                      ? AppTheme.brandEmerald500
                      : theme.hintColor.withOpacity(0.5),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  completedCount == 4
                      ? "You're all set! Ready to make your first sale!"
                      : 'All caught up',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: completedCount == 4
                        ? AppTheme.brandEmerald500
                        : theme.hintColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildKloudAIInsightsCard(context),
        if (alerts != null) ...[
          const SizedBox(height: 24),
          _buildNeedsAttentionCard(context, alerts),
        ],
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _DashboardStatCard(
              title: 'Total Revenue',
              value: stats != null ? '${stats.currency} ${stats.gmv.toStringAsFixed(2)}' : '\$12,482.00',
              trend: '+12.5%',
              isPositive: true,
            ),
            _DashboardStatCard(
              title: 'Orders',
              value: stats != null ? '${stats.orderCount}' : '84',
              trend: '+4.2%',
              isPositive: true,
            ),
            _DashboardStatCard(
              title: 'Avg. Order Value',
              value: stats != null ? '${stats.currency} ${stats.aov.toStringAsFixed(2)}' : '\$148.60',
              trend: 'Steady',
              isPositive: false,
              isSteady: true,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildTopProductsCard(context),
        const SizedBox(height: 24),
        _buildCustomerGrowthCard(context),
      ],
    );

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? const Color(0xFF020617)
          : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Good morning, Merchant',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Here's a guide to get started. As your business grows, you'll get fresh tips and insights here.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 950;
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: setupGuideCard),
                            const SizedBox(width: 24),
                            Expanded(flex: 2, child: rightColumn),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            setupGuideCard,
                            const SizedBox(height: 24),
                            rightColumn,
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: _buildExpandableFab(context),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Divider(color: theme.dividerColor.withOpacity(0.08)),
    );
  }

  Widget _buildAccordionItem({
    required int index,
    required String title,
    required String description,
    required Widget action,
    required bool isDark,
    required ThemeData theme,
  }) {
    final isExpanded = _expandedIndex == index;
    final isCompleted = _completedSteps[index];

    return InkWell(
      onTap: () {
        setState(() {
          _expandedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: isCompleted
                      ? const Icon(
                          LucideIcons.checkCircle2,
                          color: Color(0xFF10B981),
                          size: 22,
                        )
                      : Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.hintColor.withOpacity(0.5),
                              width: 1.5,
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                  onPressed: () {
                    setState(() {
                      _completedSteps[index] = !_completedSteps[index];
                    });
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isExpanded
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 16,
                  color: theme.hintColor,
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(left: 36.0, top: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                action,
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          _buildStepIllustration(index, isDark),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKloudAIInsightsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF022C22),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      LucideIcons.sparkles,
                      color: Color(0xFF34D399),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Kloud AI Insights',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Alert 1
                _buildInsightAlertItem(
                  context,
                  'Inventory Alert',
                  'Inventory is low for "Alpine Mist Diffuser". Estimated out of stock in 3 days based on current velocity.',
                  'Reorder now',
                ),
                const SizedBox(height: 16),

                // Alert 2
                _buildInsightAlertItem(
                  context,
                  'Wholesale Request',
                  'New wholesale application from "EcoDesign Group" is pending review. Potential \$5k monthly volume.',
                  'Review approval',
                ),
              ],
            ),
          ),

          // Bottom glowing design
          Container(
            height: 90,
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [Color(0xFF022C22), Color(0xFF064E3B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 24,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34D399),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 16,
                        height: 2,
                        color: const Color(0xFF34D399).withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedsAttentionCard(BuildContext context, NeedsAttention alerts) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Needs Attention',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAttentionItem(theme, 'Overdue Orders', '${alerts.pendingOrdersOverdue}'),
              _buildAttentionItem(theme, 'Low Stock', '${alerts.lowStockVariants}'),
              _buildAttentionItem(theme, 'B2B Approvals', '${alerts.pendingB2bApprovals}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionItem(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }

  Widget _buildInsightAlertItem(
    BuildContext context,
    String title,
    String body,
    String actionText,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6EE7B7),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {},
            child: Text(
              actionText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Products',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.moreHorizontal),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProductItem(
            context,
            'Alpine Wool Cardigan',
            'Clothing • 24 sales this week',
            '\$3,480',
            'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=100&h=100&fit=crop&q=80',
          ),
          const Divider(height: 24),
          _buildProductItem(
            context,
            'Forest Mist Diffuser',
            'Home • 18 sales this week',
            '\$1,260',
            'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=100&h=100&fit=crop&q=80',
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    String name,
    String subtitle,
    String price,
    String imageUrl,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 40,
              height: 40,
              color: const Color(0xFF022C22),
              child: const Icon(
                LucideIcons.package,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: theme.hintColor),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF057857),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerGrowthCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Customer Growth',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                '+28% this month',
                style: TextStyle(
                  color: Color(0xFF057857),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Custom Bar Chart
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildCustomBar(context, 0.25, false, false),
                _buildCustomBar(context, 0.45, false, false),
                _buildCustomBar(context, 0.3, false, false),
                _buildCustomBar(context, 0.75, true, false), // Dark green
                _buildCustomBar(context, 0.5, false, false),
                _buildCustomBar(context, 0.95, false, true), // Emerald
                _buildCustomBar(context, 0.8, true, false), // Dark green
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Bottom Row
          Row(
            children: [
              // Overlapping avatars
              SizedBox(
                width: 56,
                height: 24,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: _buildOverlapAvatar(
                        context,
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=50&h=50&fit=crop&q=80',
                      ),
                    ),
                    Positioned(
                      left: 14,
                      child: _buildOverlapAvatar(
                        context,
                        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=50&h=50&fit=crop&q=80',
                      ),
                    ),
                    Positioned(
                      left: 28,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Center(
                          child: Text(
                            '+12',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'New high-value customers identified.',
                  style: TextStyle(fontSize: 11, color: theme.hintColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBar(
    BuildContext context,
    double percentage,
    bool isDarkGreen,
    bool isEmerald,
  ) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    Color barColor;
    if (isEmerald) {
      barColor = const Color(0xFF10B981);
    } else if (isDarkGreen) {
      barColor = const Color(0xFF022C22);
    } else {
      barColor = isDarkTheme
          ? const Color(0xFF334155)
          : const Color(0xFFE2E8F0);
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Container(
          height: 100 * percentage,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlapAvatar(BuildContext context, String url) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Container(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildExpandableFab(BuildContext context) {
    // Declare list of actions to support easy addition/removal
    final actions = [
      _ExpandableFabAction(
        icon: LucideIcons.packagePlus,
        tooltip: 'Add Product',
        onPressed: () {
          ProductEditorView.show(context);
        },
      ),
      _ExpandableFabAction(
        icon: LucideIcons.fileSpreadsheet,
        tooltip: 'Import CSV (Placeholder)',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Placeholder Action 2: CSV Import coming soon'),
            ),
          );
        },
      ),
      _ExpandableFabAction(
        icon: LucideIcons.usersRound,
        tooltip: 'Add Customer (Placeholder)',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Placeholder Action 3: Add Customer coming soon'),
            ),
          );
        },
      ),
    ];

    return ExpandableFab(
      type: ExpandableFabType.fan,
      distance: 150.0,
      openButtonBuilder: RotateFloatingActionButtonBuilder(
        child: const Icon(LucideIcons.plus, color: Colors.white),
        fabSize: ExpandableFabSize.regular,
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF022C22),
        shape: const CircleBorder(),
      ),
      closeButtonBuilder: RotateFloatingActionButtonBuilder(
        child: const Icon(LucideIcons.x, color: Colors.white),
        fabSize: ExpandableFabSize.regular,
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF022C22),
        shape: const CircleBorder(),
      ),
      children: actions.map((act) {
        return FloatingActionButton.small(
          heroTag: null,
          child: Icon(act.icon),
          onPressed: act.onPressed,
          tooltip: act.tooltip,
        );
      }).toList(),
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool isPositive;
  final bool isSteady;

  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.isPositive,
    this.isSteady = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final trendColor = isSteady
        ? theme.hintColor
        : (isPositive ? const Color(0xFF057857) : Colors.redAccent);
    final trendIcon = isSteady
        ? LucideIcons.minus
        : (isPositive ? LucideIcons.trendingUp : LucideIcons.trendingDown);

    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: theme.hintColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(trendIcon, size: 12, color: trendColor),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: trendColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpandableFabAction {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ExpandableFabAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
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
  final bool? isExpanded;

  const _SidebarItemTile({
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExtended,
    required this.onTap,
    this.isExpanded,
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

    final activeBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final hoverBgColor = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.04);
    final activeTextColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final inactiveTextColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF5C5F62);

    final currentBgColor = widget.isSelected
        ? activeBgColor
        : (_isHovered ? hoverBgColor : Colors.transparent);
    final currentTextColor = widget.isSelected
        ? activeTextColor
        : inactiveTextColor;

    Widget content;
    if (widget.isExtended) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: SizedBox(
          width: 216,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 20, color: currentTextColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: currentTextColor,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (widget.isExpanded != null)
                  AnimatedRotation(
                    turns: widget.isExpanded! ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 3600),
                    curve: Curves.bounceOut,
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: currentTextColor.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } else {
      Widget iconWidget = Icon(widget.icon, size: 17, color: currentTextColor);
      if (widget.isExpanded != null) {
        iconWidget = Stack(
          clipBehavior: Clip.none,
          children: [
            iconWidget,
            Positioned(
              right: -6,
              bottom: -2,
              child: AnimatedRotation(
                turns: widget.isExpanded! ? 0.25 : 0.0,
                duration: const Duration(milliseconds: 3600),
                curve: Curves.bounceOut,
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 10,
                  color: currentTextColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        );
      }
      content = Tooltip(
        message: widget.label,
        waitDuration: const Duration(milliseconds: 500),
        child: Container(
          height: 34,
          alignment: Alignment.center,
          child: iconWidget,
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.8),
              decoration: BoxDecoration(
                color: currentBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: content,
            ),
          ),
        ),
        if (widget.isSelected)
          Positioned(
            left: 8.0,
            top: 6,
            bottom: 6,
            child: Container(
              width: 3.5,
              decoration: const BoxDecoration(
                color: Color(0xFF007A5A),
                borderRadius: BorderRadius.all(Radius.circular(2.0)),
              ),
            ),
          ),
      ],
    );
  }
}

class _ThemeSwitchOverlayWidget extends StatefulWidget {
  final bool targetIsDark;
  final VoidCallback onSwitchTheme;
  final VoidCallback onComplete;

  const _ThemeSwitchOverlayWidget({
    required this.targetIsDark,
    required this.onSwitchTheme,
    required this.onComplete,
  });

  @override
  State<_ThemeSwitchOverlayWidget> createState() =>
      _ThemeSwitchOverlayWidgetState();
}

class _ThemeSwitchOverlayWidgetState extends State<_ThemeSwitchOverlayWidget> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Trigger fade-in on the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _opacity = 1.0);
      }
    });

    // Step 1: Switch theme after fade-in completes (e.g. 350ms)
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        widget.onSwitchTheme();
      }

      // Step 2: Keep overlay visible for 500ms to let theme settle, then fade out
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _opacity = 0.0);
        }

        // Step 3: Complete after fade-out finishes (e.g. 350ms)
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) {
            widget.onComplete();
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: AnimatedOpacity(
        opacity: _opacity,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Stack(
          children: [
            // Semi-transparent dark background tint
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.65)),
            ),
            // Center Dialog Card
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 290,
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkTheme
                          ? const Color(0xFF1E293B).withOpacity(0.9)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDarkTheme
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Switching to ${widget.targetIsDark ? "Dark" : "Light"} Mode...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDarkTheme ? Colors.white : Colors.black87,
                            decoration: TextDecoration
                                .none, // Disable yellow underline in dialogs
                            fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
