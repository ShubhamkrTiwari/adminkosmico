import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _notifications = [];
  bool _isLoading = false;

  List<dynamic> get notifications => _notifications;
  bool get isLoading => _isLoading;

  void setNotificationsFromDashboard(List<dynamic> list) {
    _notifications = list;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/notifications');
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _notifications = result['notifications'] ?? result['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> deleteNotification(String id) async {
    try {
      final response = await _apiClient.delete('/notifications/$id');
      if (response.statusCode == 200) {
        _notifications.removeWhere((n) => n['_id'] == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
    return false;
  }

  Future<bool> sendNotification(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/notifications', data);
      debugPrint('Send Notification Response: ${response.statusCode} - ${response.body}');
      
      _isLoading = false;
      notifyListeners();
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        fetchNotifications(); // Refresh list after sending
        return true;
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }
}
