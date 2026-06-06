class ColorPreset {
  final String presetId;
  final String tenantId;
  final String name;
  final String hexCode;
  final DateTime createdAt;

  ColorPreset({
    required this.presetId,
    required this.tenantId,
    required this.name,
    required this.hexCode,
    required this.createdAt,
  });

  factory ColorPreset.fromJson(Map<String, dynamic> json) {
    return ColorPreset(
      presetId: json['preset_id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      hexCode: json['hex_code'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preset_id': presetId,
      'tenant_id': tenantId,
      'name': name,
      'hex_code': hexCode,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
