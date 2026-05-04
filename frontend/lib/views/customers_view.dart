import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/providers/customer_providers.dart';
import 'package:intl/intl.dart';

class CustomersView extends ConsumerWidget {
  const CustomersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Directory')),
      body: customersAsync.when(
        data: (customers) => customers.isEmpty
            ? _buildEmptyState()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('No customers yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Once customers place orders, they will appear here.'),
        ],
      ),
    );
  }
}
