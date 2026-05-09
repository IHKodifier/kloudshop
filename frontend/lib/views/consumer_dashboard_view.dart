import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/models/order.dart';
import 'package:intl/intl.dart';

class ConsumerDashboardView extends ConsumerStatefulWidget {
  const ConsumerDashboardView({super.key});

  @override
  ConsumerState<ConsumerDashboardView> createState() => _ConsumerDashboardViewState();
}

class _ConsumerDashboardViewState extends ConsumerState<ConsumerDashboardView> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = ref.read(apiServiceProvider).listConsumerOrders();
  }

  void _refresh() {
    setState(() {
      _ordersFuture = ref.read(apiServiceProvider).listConsumerOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('You haven\'t placed any orders yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final order = orders[index];
              return ListTile(
                title: Text('Order ${order.orderNumber}'),
                subtitle: Text(
                  'Placed on ${DateFormat('MMM dd, yyyy').format(order.placedAt)} • ${order.fulfilmentStatus.toUpperCase()}',
                ),
                trailing: Text(
                  '${order.grandTotal.toStringAsFixed(2)} ${order.currency}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/storefront/orders/details',
                    arguments: order.id,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
