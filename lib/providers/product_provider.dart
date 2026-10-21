import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Add this for MediaType
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Image Upload logic - Updated with fallback endpoints and Base64 Data URL fallback
  Future<String?> uploadImage(dynamic file, String filename) async {
    try {
      final token = await _apiClient.getToken();
      
      final endpoints = [
        '${AppConstants.baseUrl}/upload/product-image',
        '${AppConstants.baseUrl}/upload',
        '${AppConstants.rootUrl}/api/upload',
        '${AppConstants.baseUrl}/products/upload',
      ];

      for (String urlStr in endpoints) {
        try {
          var request = http.MultipartRequest('POST', Uri.parse(urlStr));

          if (token != null) {
            request.headers['Authorization'] = 'Bearer $token';
          }

          final ext = filename.split('.').last.toLowerCase();
          final MediaType contentType = MediaType('image', ext == 'jpg' ? 'jpeg' : (ext == 'png' ? 'png' : 'jpeg'));

          if (kIsWeb) {
            request.files.add(http.MultipartFile.fromBytes(
              'image',
              file,
              filename: filename,
              contentType: contentType,
            ));
          } else {
            request.files.add(await http.MultipartFile.fromPath(
              'image',
              (file as File).path,
              contentType: contentType,
            ));
          }

          var streamedResponse = await request.send();
          var response = await http.Response.fromStream(streamedResponse);

          debugPrint('Upload Response ($urlStr): ${response.statusCode} - ${response.body}');

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = jsonDecode(response.body);
            String? path = data['url'] ?? data['imageUrl'] ?? data['data']?['url'];
            
            if (path != null) {
              if (path.startsWith('http')) return path;
              if (!path.startsWith('/')) path = '/$path';
              return AppConstants.rootUrl + path;
            }
          }
        } catch (apiErr) {
          debugPrint('Endpoint $urlStr failed: $apiErr');
        }
      }

      // FALLBACK: If server upload fails, convert image bytes to Base64 Data URL
      debugPrint('Server upload endpoints failed. Falling back to Base64 Data URL.');
      Uint8List? bytes;
      if (kIsWeb) {
        bytes = file as Uint8List?;
      } else {
        bytes = await (file as File).readAsBytes();
      }

      if (bytes != null) {
        final ext = filename.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
        final base64String = base64Encode(bytes);
        return 'data:$mimeType;base64,$base64String';
      }
    } catch (e) {
      debugPrint('Upload error detail: $e');
    }
    return null;
  }

  Future<void> fetchProducts({String? category, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _apiClient.getToken();
      debugPrint('FETCH PRODUCTS - Token exists: ${token != null}');
      
      String url = '/products?limit=100';
      if (category != null && category.isNotEmpty) url += '&category=$category';
      if (search != null && search.isNotEmpty) url += '&search=${Uri.encodeComponent(search)}';

      debugPrint('FETCH PRODUCTS URL: ${AppConstants.baseUrl}$url');
      
      final response = await _apiClient.get(url);
      debugPrint('FETCH PRODUCTS Response Status: ${response.statusCode}');
      debugPrint('FETCH PRODUCTS Response Body: ${response.body}');
      
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
          _error = 'Invalid response format from server';
          _products = [];
        }
      } else {
        _error = 'Failed to load products: ${response.statusCode} - ${response.body}';
        debugPrint('Error response: ${response.body}');
      }
    } catch (e) {
      debugPrint('CRITICAL: Product fetch failed: $e');
      _error = 'Connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addProduct(Map<String, dynamic> productData) async {
    _error = null;
    try {
      final endpoints = [
        '/products/admin/add-product',
        '/products',
        '/admin/products',
      ];

      for (String endpoint in endpoints) {
        try {
          final response = await _apiClient.post(endpoint, productData);
          debugPrint('Add Product Response ($endpoint): ${response.statusCode} - ${response.body}');
          if (response.statusCode == 201 || response.statusCode == 200) {
            fetchProducts();
            return true;
          } else {
            try {
              final errData = jsonDecode(response.body);
              if (errData['message'] != null) {
                _error = errData['message'];
              }
            } catch (_) {}
          }
        } catch (apiErr) {
          debugPrint('Endpoint $endpoint failed: $apiErr');
        }
      }
    } catch (e) {
      debugPrint('Error adding product: $e');
      _error = e.toString();
    }
    return false;
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> productData) async {
    _error = null;
    try {
      final endpoints = [
        '/products/admin/update-product/$id',
        '/products/$id',
        '/admin/products/$id',
      ];

      for (String endpoint in endpoints) {
        try {
          final response = await _apiClient.put(endpoint, productData);
          debugPrint('Update Product Response ($endpoint): ${response.statusCode} - ${response.body}');
          if (response.statusCode == 200) {
            fetchProducts();
            return true;
          } else {
            try {
              final errData = jsonDecode(response.body);
              if (errData['message'] != null) {
                _error = errData['message'];
              }
            } catch (_) {}
          }
        } catch (apiErr) {
          debugPrint('Endpoint $endpoint failed: $apiErr');
        }
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
      _error = e.toString();
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
