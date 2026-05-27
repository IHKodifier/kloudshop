class Customer {
  final String email;
  final int orderCount;
  final double totalSpent;
  final DateTime? lastOrderAt;

  Customer({
    required this.email,
    required this.orderCount,
    required this.totalSpent,
    this.lastOrderAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      email: json['email'] as String,
      orderCount: json['order_count'] as int,
      totalSpent: (json['total_spent'] as num).toDouble(),
      lastOrderAt: json['last_order_at'] != null
          ? DateTime.parse(json['last_order_at'] as String)
          : null,
    );
  }
}
