class ThemeModel {
  final String themeId;
  final String name;
  final String? description;
  final String? previewUrl;
  final Map<String, dynamic> baseConfig;
  final DateTime createdAt;

  ThemeModel({
    required this.themeId,
    required this.name,
    this.description,
    this.previewUrl,
    required this.baseConfig,
    required this.createdAt,
  });

  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    return ThemeModel(
      themeId: json['theme_id'],
      name: json['name'],
      description: json['description'],
      previewUrl: json['preview_url'],
      baseConfig: json['base_config'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
