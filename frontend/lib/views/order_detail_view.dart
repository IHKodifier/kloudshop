import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/order.dart';
import 'package:kloudshop/providers/order_providers.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:intl/intl.dart';

class OrderDetailView extends ConsumerWidget {
  final String orderId;
  const OrderDetailView({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailsProvider(orderId));
    final isActionLoading = ref.watch(orderActionLoadingProvider);
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: Stack(
        children: [
          orderAsync.when(
            data: (order) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, ref, order, theme, dateFormat),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildItemsCard(order, theme),
                            const SizedBox(height: 24),
                            _buildTimelineCard(order, theme, dateFormat),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildCustomerCard(order, theme),
                            const SizedBox(height: 24),
                            _buildShippingCard(order, theme),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
          if (isActionLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, Order order, ThemeData theme, DateFormat dateFormat) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.orderNumber, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text('Placed on ${dateFormat.format(order.placedAt)}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          ],
        ),
        Row(
          children: [
            if (order.fulfilmentStatus == 'unfulfilled')
              ElevatedButton.icon(
                onPressed: () => _showFulfilDialog(context, ref, order),
                icon: const Icon(LucideIcons.packageCheck, size: 18),
                label: const Text('Fulfil Order'),
                style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white),
              ),
            const SizedBox(width: 12),
            if (order.paymentStatus == 'paid' || order.paymentStatus == 'partially_refunded')
              OutlinedButton.icon(
                onPressed: () => _showRefundDialog(context, ref, order),
                icon: const Icon(LucideIcons.undo2, size: 18),
                label: const Text('Refund'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsCard(Order order, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.dividerColor)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(LucideIcons.package, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('SKU: ${item.sku ?? 'N/A'}', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Text('${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}'),
                    const SizedBox(width: 16),
                    Text('\$${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                );
              },
            ),
            const Divider(height: 40),
            _buildPriceRow('Subtotal', order.subtotal),
            _buildPriceRow('Tax', order.taxTotal),
            _buildPriceRow('Shipping', order.shippingTotal),
            const SizedBox(height: 8),
            _buildPriceRow('Total', order.grandTotal, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text('\$${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14)),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(Order order, ThemeData theme, DateFormat dateFormat) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.dividerColor)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timeline', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            ...order.events.map((event) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.circleDot, size: 16, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.eventType.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        if (event.description != null) Text(event.description!),
                        Text(dateFormat.format(event.createdAt), style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Order order, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.dividerColor)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(order.shippingName ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(order.email),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingCard(Order order, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.dividerColor)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shipping Address', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(order.shippingName ?? ''),
            Text(order.shippingAddress1 ?? ''),
            Text(order.shippingCity ?? ''),
          ],
        ),
      ),
    );
  }

  Future<void> _showFulfilDialog(BuildContext context, WidgetRef ref, Order order) async {
    final trackingController = TextEditingController();
    final carrierController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fulfil Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: carrierController,
              decoration: const InputDecoration(labelText: 'Carrier (e.g. FedEx, UPS)', hintText: 'FedEx'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: trackingController,
              decoration: const InputDecoration(labelText: 'Tracking Number', hintText: 'TRK123456789'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performAction(context, ref, () => ref.read(apiServiceProvider).fulfilOrder(
                order.id,
                trackingNumber: trackingController.text,
                carrier: carrierController.text,
              ));
            },
            child: const Text('Confirm Fulfilment'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRefundDialog(BuildContext context, WidgetRef ref, Order order) async {
    final amountController = TextEditingController(text: order.grandTotal.toStringAsFixed(2));
    final reasonController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refund Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Refund Amount', prefixText: '\$'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason for Refund', hintText: 'Customer requested cancellation'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final amount = double.tryParse(amountController.text);
              await _performAction(context, ref, () => ref.read(apiServiceProvider).refundOrder(
                order.id,
                amount: amount,
                reason: reasonController.text,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Confirm Refund'),
          ),
        ],
      ),
    );
  }

  Future<void> _performAction(BuildContext context, WidgetRef ref, Future<void> Function() action) async {
    ref.read(orderActionLoadingProvider.notifier).setLoading(true);
    try {
      await action();
      ref.invalidate(orderDetailsProvider(orderId));
      ref.invalidate(ordersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action completed successfully')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      ref.read(orderActionLoadingProvider.notifier).setLoading(false);
    }
  }
}
