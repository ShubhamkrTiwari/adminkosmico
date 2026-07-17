import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import 'user_provider.dart';
import 'order_provider.dart';
import 'notification_provider.dart';
import 'category_provider.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  Map<String, dynamic>? _data;
  String? _error;

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get data => _data;
  String? get error => _error;

  Future<void> fetchDashboardData(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/dashboard');
      debugPrint('Dashboard API Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _data = result['data'] ?? result;
        
        // Sync other providers immediately
        if (_data != null) {
          if (_data!['users'] != null) {
            context.read<UserProvider>().setUsersFromDashboard(_data!['users']);
          }
          if (_data!['orders'] != null) {
            context.read<OrderProvider>().setOrdersFromDashboard(_data!['orders']);
          }
          if (_data!['notifications'] != null) {
            context.read<NotificationProvider>().setNotificationsFromDashboard(_data!['notifications']);
          }
          if (_data!['categories'] != null) {
            context.read<CategoryProvider>().setCategoriesFromDashboard(_data!['categories']);
          }
        }
      } else {
        _error = 'Failed to fetch dashboard data: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Connection error: $e';
      debugPrint('Dashboard Fetch Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
