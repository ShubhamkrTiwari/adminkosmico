import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/products');
      debugPrint('FETCH PRODUCTS RAW: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('PARSING PRODUCTS...');
        
        List? list;
        if (result is List) {
          list = result;
        } else if (result is Map) {
          // Check for products in the priority order
          if (result['data'] is Map && result['data']['products'] is List) {
            list = result['data']['products'];
          } else if (result['products'] is List) {
            list = result['products'];
          } else if (result['data'] is List) {
            list = result['data'];
          }
        }

        if (list != null) {
          _products = list.map((item) => Product.fromJson(item)).toList();
          debugPrint('SUCCESS: Parsed ${_products.length} products');
        } else {
          debugPrint('FAILED: No list found in product response. Structure: ${result.keys}');
          _products = [];
        }
      } else {
        _error = 'Failed to load products: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('CRITICAL: Product fetch failed: $e');
      _error = 'Connection error';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addProduct(Map<String, dynamic> productData) async {
    try {
      final response = await _apiClient.post('/products/admin/add-product', productData);
      debugPrint('Add Product Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 201 || response.statusCode == 200) {
        fetchProducts();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding product: $e');
    }
    return false;
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> productData) async {
    try {
      final response = await _apiClient.put('/products/admin/update-product/$id', productData);
      debugPrint('Update Product Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        fetchProducts();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
    }
    return false;
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final response = await _apiClient.delete('/products/admin/delete-product/$id');
      if (response.statusCode == 200) {
        _products.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
    }
    return false;
  }

  Future<bool> toggleVisibility(String id, bool visible) async {
    try {
      // Send the requested visibility state to ensure sync
      final response = await _apiClient.patch('/products/admin/toggle-visibility/$id', {'visibility': visible});
      debugPrint('Toggle Visibility Response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final index = _products.indexWhere((p) => p.id == id);
        if (index != -1) {
          // Use the data returned from server to update local state
          _products[index] = Product.fromJson(result['data']['product']);
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error toggling visibility: $e');
    }
    return false;
  }
}
