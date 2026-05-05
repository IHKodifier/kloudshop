import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/providers/customer_providers.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Directory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers by email...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(customerSearchQueryProvider.notifier).setQuery('');
                      },
                    )
                  : null,
              ),
              onChanged: (value) => ref.read(customerSearchQueryProvider.notifier).setQuery(value),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              data: (customers) => customers.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: DataTable(
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('Customer')),
                            DataColumn(label: Text('Orders'), numeric: true),
                            DataColumn(label: Text('Total Spent'), numeric: true),
                            DataColumn(label: Text('Last Order')),
                          ],
                          rows: customers.map((c) => DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                                      child: Text(c.email[0].toUpperCase(), style: TextStyle(fontSize: 10, color: theme.primaryColor)),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(c.email),
                                  ],
                                ),
                              ),
                              DataCell(Text(c.orderCount.toString())),
                              DataCell(Text('\$${c.totalSpent.toStringAsFixed(2)}')),
                              DataCell(Text(c.lastOrderAt != null ? DateFormat('MMM dd, yyyy').format(c.lastOrderAt!) : '-')),
                            ],
                          )).toList(),
                        ),
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('No customers found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Try adjusting your search query.'),
        ],
      ),
    );
  }
}
