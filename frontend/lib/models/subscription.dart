enum SubscriptionTier {
  basic,
  pro,
  enterprise,
}

enum SubscriptionStatus {
  trialing,
  active,
  past_due,
  canceled,
  incomplete,
}

class SubscriptionModel {
  final String id;
  final String tenantId;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime? currentPeriodEnd;
  final DateTime? trialEnd;
  final bool cancelAtPeriodEnd;
  final DateTime createdAt;

  SubscriptionModel({
    required this.id,
    required this.tenantId,
    required this.tier,
    required this.status,
    this.currentPeriodEnd,
    this.trialEnd,
    required this.cancelAtPeriodEnd,
    required this.createdAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      tier: _parseTier(json['tier'] as String),
      status: _parseStatus(json['status'] as String),
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'] as String)
          : null,
      trialEnd: json['trial_end'] != null
          ? DateTime.parse(json['trial_end'] as String)
          : null,
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static SubscriptionTier _parseTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'pro':
        return SubscriptionTier.pro;
      case 'enterprise':
        return SubscriptionTier.enterprise;
      case 'basic':
      default:
        return SubscriptionTier.basic;
    }
  }

  static SubscriptionStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'past_due':
        return SubscriptionStatus.past_due;
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
  bool get isActive => status == SubscriptionStatus.active || status == SubscriptionStatus.trialing;
}
