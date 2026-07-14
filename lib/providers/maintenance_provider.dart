import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';

class MaintenanceProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  bool _isMaintenanceMode = false;
  bool _isLoading = false;
  String _message = 'Server is under maintenance. Please try again later.';

  bool get isMaintenanceMode => _isMaintenanceMode;
  bool get isLoading => _isLoading;
  String get message => _message;

  Future<void> fetchMaintenanceStatus() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/maintenance/status');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _isMaintenanceMode = data['isMaintenanceMode'] ?? false;
        _message = data['message'] ?? _message;
      }
    } catch (e) {
      debugPrint('Error fetching maintenance status: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> toggleMaintenanceMode(bool value, String message) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/maintenance/toggle', {
        'isMaintenanceMode': value,
        'message': message,
      });
      if (response.statusCode == 200) {
        _isMaintenanceMode = value;
        _message = message;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling maintenance mode: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
