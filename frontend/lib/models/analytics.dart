class DataPoint {
  final DateTime date;
  final double value;
  final double? secondaryValue;

  DataPoint({required this.date, required this.value, this.secondaryValue});

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      date: DateTime.parse(json['date']),
      value: _toDouble(json['value']),
      secondaryValue: json['secondary_value'] != null
          ? _toDouble(json['secondary_value'])
          : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class AnalyticsOverview {
  final double gmv;
  final int orderCount;
  final double aov;
  final double conversionRate;
  final String currency;
  final DateTime refreshedAt;

  // Historical Lists
  final List<DataPoint> salesHistory;
  final List<DataPoint> orderHistory;
  final List<DataPoint> aovHistory;
  final List<DataPoint> customerHistory;
  final List<DataPoint> conversionHistory;
  final List<DataPoint> returnHistory;
  final List<DataPoint> todayHistory;
  final List<DataPoint> h24History;

  AnalyticsOverview({
    required this.gmv,
    required this.orderCount,
    required this.aov,
    required this.conversionRate,
    required this.currency,
    required this.refreshedAt,
    required this.salesHistory,
    required this.orderHistory,
    required this.aovHistory,
    required this.customerHistory,
    required this.conversionHistory,
    required this.returnHistory,
    required this.todayHistory,
    required this.h24History,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverview(
      gmv: DataPoint._toDouble(json['gmv']),
      orderCount: json['order_count'] as int? ?? 0,
      aov: DataPoint._toDouble(json['aov']),
      conversionRate: DataPoint._toDouble(json['conversion_rate']),
      currency: json['currency'] as String? ?? 'USD',
      refreshedAt: DateTime.parse(json['refreshed_at']),
      salesHistory: _parsePoints(json['sales_history']),
      orderHistory: _parsePoints(json['order_history']),
      aovHistory: _parsePoints(json['aov_history']),
      customerHistory: _parsePoints(json['customer_history']),
      conversionHistory: _parsePoints(json['conversion_history']),
      returnHistory: _parsePoints(json['return_history']),
      todayHistory: _parsePoints(json['today_history']),
      h24History: _parsePoints(json['h24_history']),
    );
  }

  static List<DataPoint> _parsePoints(dynamic data) {
    if (data == null || data is! List) return [];
    return data.map((item) => DataPoint.fromJson(item)).toList();
  }
}

class NeedsAttention {
  final int pendingOrdersOverdue;
  final int lowStockVariants;
  final int pendingB2bApprovals;
  final int totalAlerts;

  NeedsAttention({
    required this.pendingOrdersOverdue,
    required this.lowStockVariants,
    required this.pendingB2bApprovals,
    required this.totalAlerts,
  });

  factory NeedsAttention.fromJson(Map<String, dynamic> json) {
    return NeedsAttention(
      pendingOrdersOverdue: json['pending_orders_overdue'] as int,
      lowStockVariants: json['low_stock_variants'] as int,
      pendingB2bApprovals: json['pending_b2b_approvals'] as int,
      totalAlerts: json['total_alerts'] as int,
    );
  }
}
