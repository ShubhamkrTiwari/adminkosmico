import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../config/api_config.dart';
import 'user_provider.dart';
import 'order_provider.dart';
import 'notification_provider.dart';
import 'category_provider.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  Map<String, dynamic>? _data;
  String? _error;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get data => _data;
  String? get error => _error;

  bool _isCacheValid() {
    if (_lastFetchTime == null || _data == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  Future<void> fetchDashboardData(BuildContext context, {bool forceRefresh = false}) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid()) {
      debugPrint('Using cached dashboard data');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConfig.dashboard);
      debugPrint('Dashboard API Response: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _data = result['data'] ?? result;
        _lastFetchTime = DateTime.now();

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
