enum SubscriptionTier { free, dtc, b2b, hybrid }

enum SubscriptionStatus { trialing, active, pastDue, canceled, incomplete }

class SubscriptionModel {
  final String id;
  final String tenantId;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? trialStart;
  final DateTime? trialEnd;
  final bool cancelAtPeriodEnd;
  final DateTime createdAt;

  SubscriptionModel({
    required this.id,
    required this.tenantId,
    required this.tier,
    required this.status,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.trialStart,
    this.trialEnd,
    required this.cancelAtPeriodEnd,
    required this.createdAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'],
      tenantId: json['tenant_id'],
      tier: _parseTier(json['tier']),
      status: _parseStatus(json['status']),
      currentPeriodStart: json['current_period_start'] != null
          ? DateTime.parse(json['current_period_start'])
          : null,
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'])
          : null,
      trialStart: json['trial_start'] != null
          ? DateTime.parse(json['trial_start'])
          : null,
      trialEnd: json['trial_end'] != null
          ? DateTime.parse(json['trial_end'])
          : null,
      cancelAtPeriodEnd: json['cancel_at_period_end'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static SubscriptionTier _parseTier(String? tier) {
    switch (tier?.toLowerCase()) {
      case 'dtc':
        return SubscriptionTier.dtc;
      case 'b2b':
        return SubscriptionTier.b2b;
      case 'hybrid':
        return SubscriptionTier.hybrid;
      case 'free':
      default:
        return SubscriptionTier.free;
    }
  }

  static SubscriptionStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'past_due':
        return SubscriptionStatus.pastDue;
      case 'canceled':
        return SubscriptionStatus.canceled;
      case 'incomplete':
        return SubscriptionStatus.incomplete;
      case 'trialing':
      default:
        return SubscriptionStatus.trialing;
    }
  }

  bool get isTrialing => status == SubscriptionStatus.trialing;
  bool get isActive =>
      status == SubscriptionStatus.active ||
      status == SubscriptionStatus.trialing;
}
