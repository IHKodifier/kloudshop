import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/order.dart';
import 'package:kloudshop/providers/order_providers.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';
import 'package:kloudshop/widgets/semantic_text_form_field.dart';

class OrderDetailView extends ConsumerWidget {
  final String orderId;
  const OrderDetailView({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailsProvider(orderId));
    final isActionLoading = ref.watch(orderActionLoadingProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

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
      body: Stack(
        children: [
          orderAsync.when(
            data: (order) => SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  _buildHeader(context, ref, order, theme, dateFormat),
                  const SizedBox(height: 32),

                  // Responsiveness: Side-by-side on desktop, stacked on mobile
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column - Items & Timeline
                        Expanded(
                          flex: 8,
                          child: Column(
                            children: [
                              _buildItemsCard(order, theme, isDark),
                              const SizedBox(height: 32),
                              _buildTimelineCard(
                                order,
                                theme,
                                dateFormat,
                                isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Right column - Customer, Shipping & Payment metadata
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _buildCustomerCard(order, theme, isDark),
                              const SizedBox(height: 32),
                              _buildShippingCard(order, theme, isDark),
                              const SizedBox(height: 32),
                              _buildPaymentMethodCard(order, theme, isDark),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildItemsCard(order, theme, isDark),
                        const SizedBox(height: 24),
                        _buildCustomerCard(order, theme, isDark),
                        const SizedBox(height: 24),
                        _buildShippingCard(order, theme, isDark),
                        const SizedBox(height: 24),
                        _buildPaymentMethodCard(order, theme, isDark),
                        const SizedBox(height: 24),
                        _buildTimelineCard(order, theme, dateFormat, isDark),
                      ],
                    ),
                ],
              ),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.brandEmerald500),
            ),
            error: (e, s) => Center(
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
                    Text('Failed to load order: $e'),
                  ],
                ),
              ),
            ),
          ),

          if (isActionLoading)
            Container(
              color: Colors.black38,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      color: Colors.black54,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: AppTheme.brandEmerald500,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Updating order...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    Order order,
    ThemeData theme,
    DateFormat dateFormat,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  order.orderNumber,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusBadge(order),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Placed on ${dateFormat.format(order.placedAt)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (order.fulfilmentStatus == 'unfulfilled')
              HoverScale(
                child: ElevatedButton.icon(
                  onPressed: () => _showFulfilDialog(context, ref, order),
                  icon: const Icon(
                    LucideIcons.packageCheck,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Fulfil Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandEmerald500,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            if (order.fulfilmentStatus == 'unfulfilled' &&
                (order.paymentStatus == 'paid' ||
                    order.paymentStatus == 'partially_refunded'))
              const SizedBox(width: 12),
            if (order.paymentStatus == 'paid' ||
                order.paymentStatus == 'partially_refunded')
              HoverScale(
                child: OutlinedButton.icon(
                  onPressed: () => _showRefundDialog(context, ref, order),
                  icon: const Icon(
                    LucideIcons.undo2,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                  label: const Text(
                    'Refund',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(Order order) {
    Color bg = AppTheme.brandEmerald500.withOpacity(0.15);
    Color fg = AppTheme.brandEmerald500;
    String txt = 'PAID';

    if (order.paymentStatus == 'unpaid') {
      bg = const Color(0xFFF59E0B).withOpacity(0.15);
      fg = const Color(0xFFF59E0B);
      txt = 'UNPAID';
    } else if (order.paymentStatus == 'refunded') {
      bg = Colors.redAccent.withOpacity(0.15);
      fg = Colors.redAccent;
      txt = 'REFUNDED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        txt,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsCard(Order order, ThemeData theme, bool isDark) {
    return _buildGlassCard(
      title: 'Order Items',
      icon: LucideIcons.package,
      color: AppTheme.brandEmerald500,
      isDark: isDark,
      theme: theme,
      children: [
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.brandEmerald500.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: const Icon(
                    LucideIcons.shoppingCart,
                    size: 22,
                    color: AppTheme.brandEmerald500,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${item.sku ?? 'N/A'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${item.quantity} x \$${item.unitPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 24),
                Text(
                  '\$${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            );
          },
        ),
        const Divider(height: 40),
        _buildPriceRow(theme, 'Subtotal', order.subtotal),
        _buildPriceRow(theme, 'Tax Total', order.taxTotal),
        _buildPriceRow(theme, 'Shipping & Handling', order.shippingTotal),
        const SizedBox(height: 8),
        _buildPriceRow(theme, 'Grand Total', order.grandTotal, isBold: true),
      ],
    );
  }

  Widget _buildPriceRow(
    ThemeData theme,
    String label,
    double amount, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
              color: isBold
                  ? AppTheme.brandEmerald500
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
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
      title: 'Timeline Events',
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

  Widget _buildCustomerCard(Order order, ThemeData theme, bool isDark) {
    return _buildGlassCard(
      title: 'Customer Details',
      icon: LucideIcons.user,
      color: const Color(0xFFF59E0B),
      isDark: isDark,
      theme: theme,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFF59E0B).withOpacity(0.1),
              child: const Icon(
                LucideIcons.user,
                size: 18,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.shippingName ?? 'Unknown Customer',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.email,
                  style: TextStyle(color: theme.hintColor, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShippingCard(Order order, ThemeData theme, bool isDark) {
    return _buildGlassCard(
      title: 'Shipping Address',
      icon: LucideIcons.truck,
      color: const Color(0xFF06B6D4),
      isDark: isDark,
      theme: theme,
      children: [
        Text(
          order.shippingName ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          order.shippingAddress1 ?? 'No address provided',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        if (order.shippingCity != null) ...[
          const SizedBox(height: 4),
          Text(
            order.shippingCity!,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentMethodCard(Order order, ThemeData theme, bool isDark) {
    return _buildGlassCard(
      title: 'Payment Details',
      icon: LucideIcons.wallet,
      color: const Color(0xFFEC4899),
      isDark: isDark,
      theme: theme,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  LucideIcons.creditCard,
                  size: 16,
                  color: Colors.blueAccent,
                ),
                SizedBox(width: 8),
                Text(
                  'Visa ending in 4242',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              order.grandTotal.toStringAsFixed(2),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showFulfilDialog(
    BuildContext context,
    WidgetRef ref,
    Order order,
  ) async {
    final trackingController = TextEditingController();
    final carrierController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fulfil Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SemanticTextFormField(
              controller: carrierController,
              labelText: 'Carrier (e.g. FedEx, UPS)',
              hintText: 'FedEx',
              prefixIcon: LucideIcons.truck,
            ),
            const SizedBox(height: 16),
            SemanticTextFormField(
              controller: trackingController,
              labelText: 'Tracking Number',
              hintText: 'TRK123456789',
              prefixIcon: LucideIcons.barcode,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performAction(
                context,
                ref,
                () => ref
                    .read(apiServiceProvider)
                    .fulfilOrder(
                      order.id,
                      trackingNumber: trackingController.text,
                      carrier: carrierController.text,
                    ),
              );
            },
            child: const Text('Confirm Fulfilment'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRefundDialog(
    BuildContext context,
    WidgetRef ref,
    Order order,
  ) async {
    final amountController = TextEditingController(
      text: order.grandTotal.toStringAsFixed(2),
    );
    final reasonController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refund Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SemanticTextFormField(
              controller: amountController,
              labelText: 'Refund Amount',
              prefixWidget: const Text(
                '\$',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.brandEmerald500,
                  fontSize: 16,
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            SemanticTextFormField(
              controller: reasonController,
              labelText: 'Reason for Refund',
              hintText: 'Customer requested cancellation',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final amount = double.tryParse(amountController.text);
              await _performAction(
                context,
                ref,
                () => ref
                    .read(apiServiceProvider)
                    .refundOrder(
                      order.id,
                      amount: amount,
                      reason: reasonController.text,
                    ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Refund'),
          ),
        ],
      ),
    );
  }

  Future<void> _performAction(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    ref.read(orderActionLoadingProvider.notifier).setLoading(true);
    try {
      await action();
      ref.invalidate(orderDetailsProvider(orderId));
      ref.invalidate(ordersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action completed successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      ref.read(orderActionLoadingProvider.notifier).setLoading(false);
    }
  }
}
