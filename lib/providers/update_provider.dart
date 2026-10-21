import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';

class UpdateProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  Map<String, dynamic>? _currentUpdate;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get currentUpdate => _currentUpdate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUpdates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.get('/updates');
      debugPrint('FETCH UPDATE STATUS: ${response.statusCode}');
      debugPrint('FETCH UPDATE BODY: ${response.body}');
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _currentUpdate = result['update'];
      } else {
        _error = 'Server returned ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Error fetching update: $e');
      _error = 'Error: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createUpdate(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/updates', data);
      debugPrint('CREATE UPDATE STATUS: ${response.statusCode}');
      debugPrint('CREATE UPDATE BODY: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['update'] != null) {
          _currentUpdate = result['update'];
        } else {
          await fetchUpdates();
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Create failed: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('Error creating update: $e');
      _error = 'Create error: $e';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> toggleUpdateStatus(bool isAvailable) async {
    if (_currentUpdate == null) return false;
    
    // Optimistic local update for instant UI response
    _currentUpdate!['isUpdateAvailable'] = isAvailable;
    notifyListeners();

    try {
      // Backend developer confirmed: Use POST /api/admin/updates with {"isUpdateAvailable": false/true}
      final response = await _apiClient.post('/updates', {
        'isUpdateAvailable': isAvailable,
      });
      debugPrint('TOGGLE STATUS: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        if (result['update'] != null) {
          _currentUpdate = result['update'];
        }
        notifyListeners();
        return true;
      } else {
        // Revert on failure
        _currentUpdate!['isUpdateAvailable'] = !isAvailable;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling update status: $e');
      // Revert on exception
      _currentUpdate!['isUpdateAvailable'] = !isAvailable;
      notifyListeners();
    }
    return false;
  }

  Future<bool> deleteUpdate() async {
    try {
      final response = await _apiClient.delete('/updates');
      debugPrint('DELETE UPDATE STATUS: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        _currentUpdate = null;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting update: $e');
    }
    return false;
  }
}
