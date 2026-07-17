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
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List list = result['products'] ?? result['data']?['products'] ?? result['data'] ?? [];
        _products = list.map((item) => Product.fromJson(item)).toList();
      } else {
        _error = 'Failed to load products';
      }
    } catch (e) {
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
      final response = await _apiClient.put('/products/$id', productData);
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
      final response = await _apiClient.delete('/products/$id');
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
      final response = await _apiClient.patch('/products/$id/visibility', {});
      if (response.statusCode == 200) {
        final index = _products.indexWhere((p) => p.id == id);
        if (index != -1) {
          final updatedProduct = Product.fromJson(jsonDecode(response.body)['data']['product']);
          _products[index] = updatedProduct;
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
