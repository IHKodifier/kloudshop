class BlogCategory {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final int sortOrder;

  BlogCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.sortOrder,
  });

  factory BlogCategory.fromJson(Map<String, dynamic> json) {
    return BlogCategory(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}

class BlogTag {
  final String id;
  final String name;
  final String slug;

  BlogTag({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory BlogTag.fromJson(Map<String, dynamic> json) {
    return BlogTag(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
    );
  }
}

class BlogPost {
  final String id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? body;
  final String? coverImageUrl;
  final String? status;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final List<BlogCategory> categories;
  final List<BlogTag> tags;

  BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    this.body,
    this.coverImageUrl,
    this.status,
    this.publishedAt,
    required this.createdAt,
    required this.categories,
    required this.tags,
  });

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    return BlogPost(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      excerpt: json['excerpt'],
      body: json['body'],
      coverImageUrl: json['cover_image_url'],
      status: json['status'],
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      categories: (json['categories'] as List?)?.map((c) => BlogCategory.fromJson(c)).toList() ?? [],
      tags: (json['tags'] as List?)?.map((t) => BlogTag.fromJson(t)).toList() ?? [],
    );
  }
}
