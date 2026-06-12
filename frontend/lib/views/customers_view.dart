import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/providers/customer_providers.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/semantic_text_form_field.dart';
import 'package:kloudshop/widgets/hover_scale.dart';
import 'package:intl/intl.dart';

class CustomersView extends ConsumerStatefulWidget {
  const CustomersView({super.key});

  @override
  ConsumerState<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends ConsumerState<CustomersView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(filteredCustomersProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Premium Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.9),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Directory',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'View and manage your customer base',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Stats summary
                customersAsync.whenData((customers) {
                      if (customers.isEmpty) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.brandEmerald500.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.brandEmerald500.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.users,
                              size: 14,
                              color: AppTheme.brandEmerald500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${customers.length} customers',
                              style: const TextStyle(
                                color: AppTheme.brandEmerald500,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).value ??
                    const SizedBox.shrink(),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: SemanticTextFormField(
                  controller: _searchController,
                  hintText: 'Search customers by email...',
                  prefixIcon: LucideIcons.search,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(customerSearchQueryProvider.notifier)
                                .setQuery('');
                          },
                        )
                      : null,
                  onChanged: (value) => ref
                      .read(customerSearchQueryProvider.notifier)
                      .setQuery(value),
                ),
              ),
            ),
          ),

          // Customer List
          Expanded(
            child: customersAsync.when(
              data: (customers) => customers.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: customers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _CustomerCard(customer: customers[index]),
                    ),
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: AppTheme.brandEmerald500,
                ),
              ),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.brandEmerald500.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.brandEmerald500.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              LucideIcons.users,
              size: 48,
              color: AppTheme.brandEmerald500,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No customers found',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search query.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A premium glassmorphism customer card (replaces the DataTable for a richer look)
class _CustomerCard extends StatelessWidget {
  final dynamic customer;
  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final initials = customer.email.isNotEmpty
        ? customer.email[0].toUpperCase()
        : '?';

    // Generate a consistent color from the email
    final colors = [
      AppTheme.brandEmerald500,
      const Color(0xFF6366F1),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      AppTheme.brandTeal500,
    ];
    final colorIndex = customer.email.codeUnitAt(0) % colors.length;
    final avatarColor = colors[colorIndex];

    return HoverScale(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: avatarColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: avatarColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: avatarColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Email + stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _StatChip(
                            icon: LucideIcons.shoppingBag,
                            label: '${customer.orderCount} orders',
                          ),
                          const SizedBox(width: 12),
                          _StatChip(
                            icon: LucideIcons.dollarSign,
                            label:
                                '\$${customer.totalSpent.toStringAsFixed(2)}',
                            color: AppTheme.brandEmerald500,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Last order
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Last order',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.lastOrderAt != null
                          ? DateFormat(
                              'MMM d, yyyy',
                            ).format(customer.lastOrderAt!)
                          : '—',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _StatChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: c,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
