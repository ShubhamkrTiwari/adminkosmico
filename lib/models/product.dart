import '../core/constants.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final int stock;
  final String categoryId;
  final String? categoryName;
  final String? image;
  final List<String> images;
  final String? productLink;
  final String? ingredients;
  final bool isVisible;
  final bool notify;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.stock,
    required this.categoryId,
    this.categoryName,
    this.image,
    this.images = const [],
    this.productLink,
    this.ingredients,
    this.isVisible = true,
    this.notify = true,
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

    // Handle notify
    bool notify = true;
    var n = json['notify'];
    if (n != null) {
      if (n is bool) notify = n;
      else if (n is String) notify = (n.toLowerCase() == 'true');
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

    String? img = json['image']?.toString();
    if (img != null && img.isNotEmpty && !img.startsWith('http') && !img.startsWith('data:image')) {
      if (img.contains('uploads')) {
        String path = img;
        if (!path.startsWith('/')) {
          if (path.startsWith('uploads')) {
            path = '/$path';
          }
        }
        img = AppConstants.rootUrl + path;
      }
    }

    // Parse images array
    List<String> parsedImages = [];
    if (json['images'] != null && json['images'] is List) {
      parsedImages = (json['images'] as List).map((i) {
        String? iStr = i?.toString();
        if (iStr != null && iStr.isNotEmpty && !iStr.startsWith('http') && !iStr.startsWith('data:image')) {
          if (iStr.contains('uploads')) {
            String path = iStr;
            if (!path.startsWith('/')) {
              if (path.startsWith('uploads')) {
                path = '/$path';
              }
            }
            iStr = AppConstants.rootUrl + path;
          }
        }
        return iStr ?? '';
      }).where((s) => s.isNotEmpty).toList();
    }

    if (parsedImages.isEmpty && img != null && img.isNotEmpty) {
      parsedImages.add(img);
    }
    if ((img == null || img.isEmpty) && parsedImages.isNotEmpty) {
      img = parsedImages.first;
    }

    return Product(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      stock: parsedStock,
      categoryId: catId,
      categoryName: catName,
      image: img,
      images: parsedImages,
      productLink: json['productLink']?.toString(),
      ingredients: json['ingredients']?.toString(),
      isVisible: visible,
      notify: notify,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'stock': stock,
      'category': categoryId,
      'image': image,
      'images': images,
      'productLink': productLink,
      'ingredients': ingredients,
      'visibility': isVisible,
      'notify': notify,
    };
  }
}
