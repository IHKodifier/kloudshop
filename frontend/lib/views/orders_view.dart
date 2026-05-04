import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/order.dart';
import 'package:kloudshop/providers/order_providers.dart';
import 'package:intl/intl.dart';

class OrdersView extends ConsumerWidget {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final currentFilter = ref.watch(ordersStatusFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          _FilterChip(
            label: 'All',
            isSelected: currentFilter == null,
            onSelected: () => ref.read(ordersStatusFilterProvider.notifier).setStatus(null),
          ),
          _FilterChip(
            label: 'Unfulfilled',
            isSelected: currentFilter == 'unfulfilled',
            onSelected: () => ref.read(ordersStatusFilterProvider.notifier).setStatus('unfulfilled'),
          ),
          _FilterChip(
            label: 'Fulfilled',
            isSelected: currentFilter == 'fulfilled',
            onSelected: () => ref.read(ordersStatusFilterProvider.notifier).setStatus('fulfilled'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) => orders.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: orders.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _OrderCard(order: orders[index]),
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
          Icon(LucideIcons.shoppingBag, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('No orders found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Customer orders will appear here once they are placed.'),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(order.placedAt),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _StatusBadge(label: order.paymentStatus, color: _getPaymentColor(order.paymentStatus)),
                    const SizedBox(width: 8),
                    _StatusBadge(label: order.fulfilmentStatus, color: _getFulfilmentColor(order.fulfilmentStatus)),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.shippingName ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(order.email, style: theme.textTheme.bodySmall),
                  ],
                ),
                Text(
                  '${order.currency} ${order.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (order.fulfilmentStatus == 'unfulfilled')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showFulfilDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Mark as Fulfilled'),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showDetailsDialog(context),
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFulfilDialog(BuildContext context) {
    // TODO: Implement fulfillment dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fulfillment dialog coming in next iteration!')),
    );
  }

  void _showDetailsDialog(BuildContext context) {
    // TODO: Implement details modal
  }

  Color _getPaymentColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid': return Colors.green;
      case 'refunded': return Colors.red;
      default: return Colors.orange;
    }
  }

  Color _getFulfilmentColor(String status) {
    switch (status.toLowerCase()) {
      case 'fulfilled': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.blue;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({required this.label, required this.isSelected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
