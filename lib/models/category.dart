class Category {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final bool isVisible;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    this.isVisible = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      icon: json['icon'],
      isVisible: json['visibility'] ?? true,
    );
  }
}
