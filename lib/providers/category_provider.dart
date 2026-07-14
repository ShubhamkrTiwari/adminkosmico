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

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/categories');
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List list = result['data']['categories'];
        _categories = list.map((item) => Category.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addCategory(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/categories', data);
      if (response.statusCode == 201) {
        fetchCategories();
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
      final response = await _apiClient.delete('/categories/$id');
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
