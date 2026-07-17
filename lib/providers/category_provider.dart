import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  void setCategoriesFromDashboard(List<dynamic> list) {
    try {
      _categories = list.map((item) => Category.fromJson(item)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing categories from dashboard: $e');
    }
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/categories');
      debugPrint('Fetch Categories Response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        List? list;
        
        // Comprehensive check for all possible backend structures
        if (result['categories'] != null) {
          list = result['categories'];
        } else if (result['data'] != null) {
          if (result['data'] is List) {
            list = result['data'];
          } else if (result['data']['categories'] != null) {
            list = result['data']['categories'];
          }
        } else if (result is List) {
          list = result;
        }

        if (list != null) {
          _categories = list.map((item) => Category.fromJson(item)).toList();
          debugPrint('Parsed ${_categories.length} categories');
        }
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addCategory(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/categories/admin/add-category', {
        'name': data['name'],
      });
      
      debugPrint('Add Category Status: ${response.statusCode}');
      debugPrint('Add Category Body: ${response.body}');
      
      final resData = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200 || resData['success'] == true) {
        await fetchCategories();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding category: $e');
    }
    return false;
  }

  Future<bool> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('/categories/$id', data);
      if (response.statusCode == 200) {
        fetchCategories();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating category: $e');
    }
    return false;
  }

  Future<bool> deleteCategory(String id) async {
    try {
      // Updated to match your new specific delete endpoint
      final response = await _apiClient.delete('/categories/admin/delete-category/$id');
      debugPrint('Delete Category Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        _categories.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting category: $e');
    }
    return false;
  }
}
