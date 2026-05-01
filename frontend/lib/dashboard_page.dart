import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/user_claims.dart';
import 'package:kloudshop/services/auth_service.dart';
import 'package:kloudshop/views/billing_view.dart';

class DashboardPage extends StatefulWidget {
  final UserClaims claims;

  const DashboardPage({super.key, required this.claims});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer(
      builder: (context, ref, child) {
        return NavigationRail(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          labelType: NavigationRailLabelType.none,
          extended: true,
          minExtendedWidth: 240,
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.store, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'KloudShop',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ),
          trailing: Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Divider(),
                ListTile(
                  leading: const Icon(LucideIcons.logOut),
                  title: const Text('Sign Out'),
                  onTap: () => ref.read(authServiceProvider).signOut(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          destinations: const [
            NavigationRailDestination(
              icon: Icon(LucideIcons.layoutDashboard),
              selectedIcon: Icon(LucideIcons.layoutDashboard, color: Colors.blue),
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
              selectedIcon: Icon(LucideIcons.creditCard, color: Colors.blue),
              label: Text('Billing'),
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
      case 4:
        return const BillingView();
      default:
        return Center(
          child: Text('Module Coming Soon: ${_selectedIndex}'),
        );
    }
  }
}

class _OverviewView extends StatelessWidget {
  final UserClaims claims;
  const _OverviewView({required this.claims});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Overview'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${claims.email ?? claims.uid}',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChip(context, 'Tenant: ${claims.tenantId}', theme.primaryColor),
                const SizedBox(width: 8),
                _buildChip(context, 'Role: ${claims.roles.join(", ")}', Colors.orange),
                if (claims.isOwner) ...[
                  const SizedBox(width: 8),
                  _buildChip(context, 'OWNER', Colors.redAccent),
                ],
              ],
            ),
            const SizedBox(height: 48),
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.5,
                children: const [
                  _StatCard(title: 'Total Sales', value: '\$0.00', icon: LucideIcons.dollarSign),
                  _StatCard(title: 'Active Orders', value: '0', icon: LucideIcons.shoppingBag),
                  _StatCard(title: 'Inventory Alerts', value: 'None', icon: LucideIcons.alertTriangle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.primaryColor, size: 20),
          ),
          const Spacer(),
          Text(title, style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
