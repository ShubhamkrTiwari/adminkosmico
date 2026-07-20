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
    // Handle visibility
    bool visible = true;
    var v = json['visibility'];
    if (v != null) {
      if (v is bool) visible = v;
      else if (v is String) visible = (v.toLowerCase() == 'visible' || v.toLowerCase() == 'true');
    }

    // Handle stock
    int parsedStock = 0;
    if (json['stock'] != null) parsedStock = (json['stock'] as num).toInt();
    else if (json['countInStock'] != null) parsedStock = (json['countInStock'] as num).toInt();

    // Robust Category parsing
    String catId = '';
    String catName = '';
    
    // 1. Try to get categoryName from the root (New backend feature)
    if (json['categoryName'] != null && json['categoryName'].toString().isNotEmpty) {
      catName = json['categoryName'].toString();
    }
    
    // 2. Parse category ID and handle populated object
    if (json['category'] != null) {
      if (json['category'] is Map) {
        catId = json['category']['_id']?.toString() ?? '';
        // If categoryName was "General" or empty, try to get it from the populated map
        if ((catName == 'General' || catName.isEmpty) && json['category']['name'] != null) {
          catName = json['category']['name'].toString();
        }
      } else {
        catId = json['category'].toString();
        // If catName is still General, it means the backend didn't provide a name
        // But the category ID itself might be the name (in some legacy data)
        if (catName == 'General' || catName.isEmpty) {
          catName = catId;
        }
      }
    }

    return Product(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: parsedStock,
      categoryId: catId,
      categoryName: catName,
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
