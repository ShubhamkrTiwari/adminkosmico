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
      name: json['name'] ?? 'General',
      slug: json['slug'] ?? (json['name'] ?? '').toString().toLowerCase().replaceAll(' ', '-'),
      description: json['description'],
      icon: json['icon'],
      isVisible: json['visibility'] == 'visible' || json['visibility'] == true,
    );
  }
}
