import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/models/order.dart';
import 'package:intl/intl.dart';

class ConsumerOrderDetailsView extends ConsumerStatefulWidget {
  final String orderId;

  const ConsumerOrderDetailsView({super.key, required this.orderId});

  @override
  ConsumerState<ConsumerOrderDetailsView> createState() => _ConsumerOrderDetailsViewState();
}

class _ConsumerOrderDetailsViewState extends ConsumerState<ConsumerOrderDetailsView> {
  late Future<Order> _orderFuture;

  @override
  void initState() {
    super.initState();
    _orderFuture = ref.read(apiServiceProvider).getConsumerOrderDetails(widget.orderId);
  }

  Future<void> _showReturnDialog(Order order) async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Return'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for the return request.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );

    if (result == true && reasonController.text.isNotEmpty) {
      try {
        await ref.read(apiServiceProvider).requestReturn(
          order.id,
          reason: reasonController.text,
          items: order.items.map((i) => {'variant_id': i.variantId, 'quantity': i.quantity}).toList(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Return request submitted.')),
          );
          setState(() {
            _orderFuture = ref.read(apiServiceProvider).getConsumerOrderDetails(widget.orderId);
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: FutureBuilder<Order>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final order = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ${order.orderNumber}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('MMMM dd, yyyy').format(order.placedAt),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    Chip(
                      label: Text(order.fulfilmentStatus.toUpperCase()),
                      backgroundColor: _getStatusColor(order.fulfilmentStatus).withValues(alpha: 0.1),
                      labelStyle: TextStyle(color: _getStatusColor(order.fulfilmentStatus)),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text('Qty: ${item.quantity}', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text('${item.totalPrice.toStringAsFixed(2)} ${order.currency}'),
                    ],
                  ),
                )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      '${order.grandTotal.toStringAsFixed(2)} ${order.currency}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                if (order.fulfilmentStatus == 'delivered' || order.fulfilmentStatus == 'fulfilled')
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => _showReturnDialog(order),
                      icon: const Icon(Icons.keyboard_return),
                      label: const Text('Request Return or Refund'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                const Text('Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                ...order.events.reversed.map((event) => ListTile(
                  leading: const Icon(Icons.radio_button_checked, size: 16),
                  title: Text(event.eventType.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: Text(event.description ?? ''),
                  dense: true,
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return Colors.green;
      case 'fulfilled': return Colors.blue;
      case 'unfulfilled': return Colors.orange;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}
