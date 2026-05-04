class Order {
  final String id;
  final String orderNumber;
  final String email;
  final String paymentStatus;
  final String fulfilmentStatus;
  final String currency;
  final double subtotal;
  final double taxTotal;
  final double grandTotal;
  final String? shippingName;
  final String? shippingAddress1;
  final String? shippingCity;
  final DateTime placedAt;
  final List<OrderItem> items;
  final List<OrderEvent> events;

  Order({
    required this.id,
    required this.orderNumber,
    required this.email,
    required this.paymentStatus,
    required this.fulfilmentStatus,
    required this.currency,
    required this.subtotal,
    required this.taxTotal,
    required this.grandTotal,
    this.shippingName,
    this.shippingAddress1,
    this.shippingCity,
    required this.placedAt,
    required this.items,
    required this.events,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['order_id'] as String,
      orderNumber: json['order_number'] as String,
      email: json['email'] as String,
      paymentStatus: json['payment_status'] as String,
      fulfilmentStatus: json['fulfilment_status'] as String,
      currency: json['currency'] as String,
      subtotal: (json['subtotal'] as num).toDouble(),
      taxTotal: (json['tax_total'] as num).toDouble(),
      grandTotal: (json['grand_total'] as num).toDouble(),
      shippingName: json['shipping_name'] as String?,
      shippingAddress1: json['shipping_address1'] as String?,
      shippingCity: json['shipping_city'] as String?,
      placedAt: DateTime.parse(json['placed_at'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((v) => OrderItem.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
      events: (json['events'] as List<dynamic>?)
              ?.map((v) => OrderEvent.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OrderItem {
  final String id;
  final String title;
  final String? sku;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.id,
    required this.title,
    this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['order_item_id'] as String,
      title: json['title'] as String,
      sku: json['sku'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }
}

class OrderEvent {
  final String id;
  final String eventType;
  final String? description;
  final DateTime createdAt;

  OrderEvent({
    required this.id,
    required this.eventType,
    this.description,
    required this.createdAt,
  });

  factory OrderEvent.fromJson(Map<String, dynamic> json) {
    return OrderEvent(
      id: json['event_id'] as String,
      eventType: json['event_type'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
