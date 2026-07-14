import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';

class UpdateProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _updates = [];
  bool _isLoading = false;

  List<dynamic> get updates => _updates;
  bool get isLoading => _isLoading;

  Future<void> fetchUpdates() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/updates');
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _updates = result['data'];
      }
    } catch (e) {
      debugPrint('Error fetching updates: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createUpdate(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/updates', data);
      if (response.statusCode == 201) {
        fetchUpdates();
        return true;
      }
    } catch (e) {
      debugPrint('Error creating update: $e');
    }
    return false;
  }
}
