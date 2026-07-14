import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<User> _users = [];
  bool _isLoading = false;

  List<User> get users => _users;
  bool get isLoading => _isLoading;

  void setUsersFromDashboard(List<dynamic> list) {
    try {
      _users = list.map((item) => User.fromJson(item)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing users from dashboard: $e');
    }
  }

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/users');
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List list = result['users'] ?? result['data'] ?? [];
        _users = list.map((item) => User.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> fetchUserDetails(String id) async {
    try {
      final response = await _apiClient.get('/users/$id');
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['data'] ?? result;
      }
    } catch (e) {
      debugPrint('Error fetching user details: $e');
    }
    return null;
  }

  Future<bool> toggleUserBlock(String id) async {
    try {
      final response = await _apiClient.put('/users/$id/block', {});
      if (response.statusCode == 200) {
        fetchUsers();
        return true;
      }
    } catch (e) {
      debugPrint('Error blocking user: $e');
    }
    return false;
  }

  Future<bool> deleteUser(String id) async {
    try {
      final response = await _apiClient.delete('/users/$id');
      if (response.statusCode == 200) {
        _users.removeWhere((u) => u.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
    return false;
  }
}
