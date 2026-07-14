import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final token = await _apiClient.getToken();
    if (token != null) {
      try {
        final response = await _apiClient.get('/me');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['data'] != null && data['data']['user'] != null) {
            _user = User.fromJson(data['data']['user']);
          } else if (data['user'] != null) {
            _user = User.fromJson(data['user']);
          }
        } else {
          await _apiClient.clearSession();
        }
      } catch (e) {
        debugPrint('Error loading user: $e');
      }
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/login', {
        'email': email,
        'password': password,
      });

      debugPrint('Login Response: ${response.body}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final responseData = data['data'];
        if (responseData != null && responseData is Map) {
          await _apiClient.saveToken(responseData['token'] ?? '');
          _user = User.fromJson(responseData['user'] ?? {});
          _isLoading = false;
          notifyListeners();
          return true;
        } else if (data['token'] != null) {
          // Fallback if data is at root
          await _apiClient.saveToken(data['token']);
          _user = User.fromJson(data['user'] ?? {});
          _isLoading = false;
          notifyListeners();
          return true;
        } else if (data['user'] != null && data['user']['token'] != null) {
          // Check if token is inside user object
          await _apiClient.saveToken(data['user']['token']);
          _user = User.fromJson(data['user']);
          _isLoading = false;
          notifyListeners();
          return true;
        }
        _error = 'Invalid response structure: ${response.body}';
      } else {
        _error = data['message'] ?? 'Login failed';
      }
    } catch (e) {
      _error = 'Connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signup(String name, String email, String password, String? phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/signup', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
      });

      debugPrint('Signup Response: ${response.body}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Signup failed';
      }
    } catch (e) {
      _error = 'Connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> verifyOtp(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/signup-verify', {
        'email': email,
        'otp': otp,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final responseData = data['data'];
        if (responseData != null && responseData is Map) {
          await _apiClient.saveToken(responseData['token'] ?? '');
          _user = User.fromJson(responseData['user'] ?? {});
          _isLoading = false;
          notifyListeners();
          return true;
        } else if (data['token'] != null) {
          // Fallback if data is at root
          await _apiClient.saveToken(data['token']);
          _user = User.fromJson(data['user'] ?? {});
          _isLoading = false;
          notifyListeners();
          return true;
        } else if (data['user'] != null && data['user']['token'] != null) {
          // Check if token is inside user object
          await _apiClient.saveToken(data['user']['token']);
          _user = User.fromJson(data['user']);
          _isLoading = false;
          notifyListeners();
          return true;
        }
        _error = 'Invalid response structure: ${response.body}';
      } else {
        _error = data['message'] ?? 'Verification failed';
      }
    } catch (e) {
      _error = 'Connection error';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _apiClient.clearSession();
    _user = null;
    notifyListeners();
  }
}
