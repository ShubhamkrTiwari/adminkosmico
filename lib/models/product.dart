class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String categoryId;
  final String? categoryName;
  final String? image;
  final String? productLink;
  final String? ingredients;
  final bool isVisible;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.categoryName,
    this.image,
    this.productLink,
    this.ingredients,
    this.isVisible = true,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle visibility as string or boolean from API
    bool visible = true;
    if (json['visibility'] != null) {
      if (json['visibility'] is bool) {
        visible = json['visibility'];
      } else {
        visible = json['visibility'] == 'visible' || json['visibility'] == 'true';
      }
    }

    // Robust stock parsing
    int parsedStock = 0;
    if (json['stock'] != null) {
      parsedStock = (json['stock'] as num).toInt();
    } else if (json['countInStock'] != null) {
      parsedStock = (json['countInStock'] as num).toInt();
    }

    return Product(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: parsedStock,
      categoryId: json['category'] is Map ? (json['category']['_id']?.toString() ?? '') : (json['category']?.toString() ?? ''),
      categoryName: json['category'] is Map ? (json['category']['name']?.toString() ?? 'General') : (json['category']?.toString() ?? 'General'),
      image: json['image']?.toString(),
      productLink: json['productLink']?.toString(),
      ingredients: json['ingredients']?.toString(),
      isVisible: visible,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': categoryId,
      'image': image,
      'productLink': productLink,
      'ingredients': ingredients,
      'visibility': isVisible,
    };
  }
}
