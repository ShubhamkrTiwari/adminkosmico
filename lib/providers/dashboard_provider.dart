import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  Map<String, dynamic>? _data;
  String? _error;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get data => _data;
  String? get error => _error;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/dashboard');
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // The controller might return data at root or inside a 'data' key
        _data = result['data'] ?? result;
      } else {
        _error = 'Failed to fetch dashboard data';
      }
    } catch (e) {
      _error = 'Connection error';
    }

    _isLoading = false;
    notifyListeners();
  }
}
