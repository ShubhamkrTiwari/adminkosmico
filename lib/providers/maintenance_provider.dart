import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';

class MaintenanceProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  bool _isMaintenanceMode = false;
  bool _isLoading = false;
  String _message = 'Server is under maintenance. Please try again later.';
  String? _error;

  bool get isMaintenanceMode => _isMaintenanceMode;
  bool get isLoading => _isLoading;
  String get message => _message;
  String? get error => _error;

  Future<void> fetchMaintenanceStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.get('/maintenance');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _isMaintenanceMode = data['isMaintenanceMode'] ?? false;
        _message = data['message'] ?? _message;
      } else {
        _error = 'Failed to fetch status: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Connection error: $e';
      debugPrint('Error fetching maintenance status: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> toggleMaintenanceMode(bool value, String message) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final body = {
        'isMaintenanceMode': value,
        'message': message.trim(),
      };
      
      final response = await _apiClient.post('/maintenance', body);
      
      debugPrint('Toggle Maintenance Request Body: $body');
      debugPrint('Toggle Maintenance Status: ${response.statusCode}');
      debugPrint('Toggle Maintenance Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true || data['isMaintenanceMode'] != null) {
          _isMaintenanceMode = data['isMaintenanceMode'] ?? value;
          _message = data['message'] ?? message;
          _error = null;
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = data['message'] ?? 'Failed to update settings';
        }
      } else {
        _error = data['message'] ?? 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Connection error: $e';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
