class TenantSettings {
  final String id;
  final String name;
  final DateTime createdAt;
  final String? gcpProjectId;
  final String? gcpBucketName;
  final Map<String, dynamic> config;
  final List<String> supportedLocales;

  TenantSettings({
    required this.id,
    required this.name,
    required this.createdAt,
    this.gcpProjectId,
    this.gcpBucketName,
    required this.config,
    required this.supportedLocales,
  });

  factory TenantSettings.fromJson(Map<String, dynamic> json) {
    return TenantSettings(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      gcpProjectId: json['gcp_project_id'] as String?,
      gcpBucketName: json['gcp_bucket_name'] as String?,
      config: json['config'] as Map<String, dynamic>? ?? {},
      supportedLocales: List<String>.from(json['supported_locales'] ?? ['en']),
    );
  }
}
