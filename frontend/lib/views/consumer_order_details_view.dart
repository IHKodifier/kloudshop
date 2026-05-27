import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/models/order.dart';
import 'package:intl/intl.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';

class ConsumerOrderDetailsView extends ConsumerStatefulWidget {
  final String orderId;
  const ConsumerOrderDetailsView({super.key, required this.orderId});

  @override
  ConsumerState<ConsumerOrderDetailsView> createState() =>
      _ConsumerOrderDetailsViewState();
}

class _ConsumerOrderDetailsViewState
    extends ConsumerState<ConsumerOrderDetailsView> {
  late Future<Order> _orderFuture;

  @override
  void initState() {
    super.initState();
    _orderFuture = ref
        .read(apiServiceProvider)
        .getConsumerOrderDetails(widget.orderId);
  }

  Future<void> _showReturnDialog(Order order) async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Request Return / Refund',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for the return request below. Our support team will review it.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for return',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );

    if (result == true && reasonController.text.isNotEmpty) {
      try {
        await ref
            .read(apiServiceProvider)
            .requestReturn(
              order.id,
              reason: reasonController.text,
              items: order.items
                  .map(
                    (i) => {'variant_id': i.variantId, 'quantity': i.quantity},
                  )
                  .toList(),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Return request submitted successfully.'),
              backgroundColor: AppTheme.brandEmerald600,
            ),
          );
          setState(() {
            _orderFuture = ref
                .read(apiServiceProvider)
                .getConsumerOrderDetails(widget.orderId);
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting return: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: theme.dividerColor, height: 1),
        ),
      ),
      body: FutureBuilder<Order>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.brandEmerald500),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.alertCircle,
                      color: Colors.redAccent,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          final order = snapshot.data!;
          final isEligibleForReturn =
              order.fulfilmentStatus == 'delivered' ||
              order.fulfilmentStatus == 'fulfilled';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ${order.orderNumber}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Placed on ${DateFormat('MMMM dd, yyyy').format(order.placedAt)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          order.fulfilmentStatus,
                        ).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.fulfilmentStatus.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(order.fulfilmentStatus),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Left column / Right column split on wide viewports (simulated stacked for simplicity)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main items
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          _buildGlassCard(
                            title: 'Purchased Items',
                            icon: LucideIcons.package,
                            color: AppTheme.brandEmerald500,
                            isDark: isDark,
                            theme: theme,
                            children: [
                              ...order.items.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppTheme.brandEmerald500
                                              .withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          LucideIcons.package,
                                          color: AppTheme.brandEmerald500,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Qty: ${item.quantity}',
                                              style: TextStyle(
                                                color: theme.hintColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '\$${item.totalPrice.toStringAsFixed(2)} ${order.currency}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(height: 32),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Amount Paid',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '\$${order.grandTotal.toStringAsFixed(2)} ${order.currency}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.brandEmerald500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildTimelineCard(order, theme, dateFormat, isDark),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Action sidebar
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          if (isEligibleForReturn) ...[
                            _buildGlassCard(
                              title: 'Support Actions',
                              icon: LucideIcons.helpCircle,
                              color: Colors.redAccent,
                              isDark: isDark,
                              theme: theme,
                              children: [
                                const Text(
                                  'If you have any issues with your items, you can request a refund or return service below.',
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: HoverScale(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showReturnDialog(order),
                                      icon: const Icon(
                                        LucideIcons.undo2,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        'Request Return / Refund',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            _buildGlassCard(
                              title: 'Fulfillment Info',
                              icon: LucideIcons.truck,
                              color: const Color(0xFF6366F1),
                              isDark: isDark,
                              theme: theme,
                              children: [
                                Text(
                                  'This order is currently ${order.fulfilmentStatus.toUpperCase()}.',
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Once delivered, return and refund options will become available.',
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required ThemeData theme,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withOpacity(0.7)
                : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineCard(
    Order order,
    ThemeData theme,
    DateFormat dateFormat,
    bool isDark,
  ) {
    return _buildGlassCard(
      title: 'Order Status Log',
      icon: LucideIcons.history,
      color: const Color(0xFF6366F1),
      isDark: isDark,
      theme: theme,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: order.events.length,
          itemBuilder: (context, index) {
            final event = order.events[index];
            final isLast = index == order.events.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      const Icon(
                        LucideIcons.circleDot,
                        size: 14,
                        color: AppTheme.brandEmerald500,
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(width: 2, color: theme.dividerColor),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.eventType.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (event.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              event.description!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(event.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'fulfilled':
        return AppTheme.brandEmerald500;
      case 'unfulfilled':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}
