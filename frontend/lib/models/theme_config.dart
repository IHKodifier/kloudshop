class ThemeConfigModel {
  final String configId;
  final String tenantId;
  final String themeId;
  final Map<String, dynamic> draftTokens;
  final Map<String, dynamic> liveTokens;
  final Map<String, dynamic> draftSlots;
  final Map<String, dynamic> liveSlots;
  final bool isActive;
  final DateTime updatedAt;

  ThemeConfigModel({
    required this.configId,
    required this.tenantId,
    required this.themeId,
    required this.draftTokens,
    required this.liveTokens,
    required this.draftSlots,
    required this.liveSlots,
    required this.isActive,
    required this.updatedAt,
  });

  factory ThemeConfigModel.fromJson(Map<String, dynamic> json) {
    return ThemeConfigModel(
      configId: json['config_id'],
      tenantId: json['tenant_id'],
      themeId: json['theme_id'],
      draftTokens: json['draft_tokens'] ?? {},
      liveTokens: json['live_tokens'] ?? {},
      draftSlots: json['draft_slots'] ?? {},
      liveSlots: json['live_slots'] ?? {},
      isActive: json['is_active'] ?? false,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
