class SystemStatus {
  final String version;
  final String buildHash;
  final String environment;
  final String apiStatus;

  SystemStatus({
    required this.version,
    required this.buildHash,
    required this.environment,
    required this.apiStatus,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    return SystemStatus(
      version: json['version'],
      buildHash: json['build_hash'],
      environment: json['environment'],
      apiStatus: json['api_status'],
    );
  }
}

class SchemaHealth {
  final String status;
  final List<String> missingTables;
  final String databaseType;
  final DateTime timestamp;

  SchemaHealth({
    required this.status,
    required this.missingTables,
    required this.databaseType,
    required this.timestamp,
  });

  factory SchemaHealth.fromJson(Map<String, dynamic> json) {
    return SchemaHealth(
      status: json['status'],
      missingTables: List<String>.from(json['missing_tables'] ?? []),
      databaseType: json['database_type'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
