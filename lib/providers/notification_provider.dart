import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<bool> sendNotification(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/notifications', data);
      _isLoading = false;
      notifyListeners();
      return response.statusCode == 201;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
