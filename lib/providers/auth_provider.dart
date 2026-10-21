import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  static const String _userCacheKey = 'admin_user_cache';

  final ApiClient _apiClient = ApiClient();
  User? _user;
  bool _isLoading = false;
  bool _isBooting = true;
  bool _sessionExpired = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isBooting => _isBooting;
  bool get sessionExpired => _sessionExpired;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    ApiClient.onSessionExpired = _handleSessionExpired;
    _bootstrap();
  }

  @override
  void dispose() {
    if (ApiClient.onSessionExpired == _handleSessionExpired) {
      ApiClient.onSessionExpired = null;
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // A cached admin lets the app open straight away, so a slow or failing
    // `/me` call never bounces the user back to the login screen.
    await _restoreCachedUser();
    await _refreshFromServer();
    _isBooting = false;
    notifyListeners();
  }

  Future<void> _restoreCachedUser() async {
    final token = await _apiClient.getToken();
    if (token == null) return;

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_userCacheKey);
    if (cached == null) return;

    try {
      _user = User.fromJson(jsonDecode(cached));
    } catch (e) {
      debugPrint('Cached user is unreadable: $e');
    }
  }

  Future<void> _refreshFromServer() async {
    final token = await _apiClient.getToken();
    if (token == null) {
      // Token is gone (expired storage / manual clear) - nothing to restore.
      await _clearLocalSession();
      return;
    }

    try {
      final response = await _apiClient.get('/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userJson = (data['data'] is Map && data['data']['user'] != null)
            ? data['data']['user']
            : data['user'];
        if (userJson is Map<String, dynamic>) {
          _user = User.fromJson(userJson);
          await _cacheUser(_user!);
        }
      } else if (response.statusCode == 401) {
        // Token really is invalid/expired.
        await _apiClient.clearSession();
        await _clearLocalSession();
      }
      // 403 / 503 / proxy errors stay non-destructive: keep the cached session.
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  void _handleSessionExpired() {
    _sessionExpired = true;
    _error = 'Session expired. Please login again.';
    _clearLocalSession();
  }

  /// Lets the login screen show the "session expired" notice only once.
  void clearError() {
    _error = null;
    _sessionExpired = false;
  }

  Future<void> _clearLocalSession() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userCacheKey);
    notifyListeners();
  }

  Future<void> _cacheUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userCacheKey, jsonEncode(user.toJson()));
  }

  /// Accepts the token/user wherever the backend nested them, and refuses to
  /// persist an empty token (an empty value used to look like a valid session
  /// and then get rejected with 401 on the next screen).
  Future<bool> _applyAuthPayload(dynamic data) async {
    if (data is! Map) return false;

    final payload = data['data'] is Map ? data['data'] as Map : data;
    final candidates = <dynamic>[
      payload['token'],
      data['token'],
      (data['user'] is Map) ? (data['user'] as Map)['token'] : null,
    ];
    final token = candidates.firstWhere(
      (c) => c is String && c.isNotEmpty,
      orElse: () => null,
    ) as String?;

    if (token == null) return false;

    await _apiClient.saveToken(token);
    final userJson = (payload['user'] is Map) ? payload['user'] : data['user'];
    _user = User.fromJson(userJson is Map<String, dynamic> ? userJson : <String, dynamic>{});
    await _cacheUser(_user!);
    return true;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    _sessionExpired = false;
    notifyListeners();

    try {
      final response = await _apiClient.post('/login', {
        'email': email.trim(),
        'password': password.trim(),
      });

      debugPrint('Login Response: ${response.body}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (await _applyAuthPayload(data)) {
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

      debugPrint('Signup Verify Response: ${response.body}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (await _applyAuthPayload(data)) {
          _isLoading = false;
          notifyListeners();
          return true;
        }
        _error = 'Invalid response structure: ${response.body}';
      } else {
        _error = data['message'] ?? 'Verification failed';
      }
    } catch (e) {
      _error = 'Connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/forgot-password', {'email': email});
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Failed to send OTP';
      }
    } catch (e) {
      _error = 'Connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> verifyForgotPasswordOtp(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/verify-otp', {
        'email': email,
        'otp': otp,
      });
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'OTP verification failed';
      }
    } catch (e) {
      _error = 'Connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('/reset-password', {
        'email': email,
        'newPassword': newPassword, // Updated field name to match backend
      });
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = data['message'] ?? 'Reset failed';
      }
    } catch (e) {
      _error = 'Connection error: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _apiClient.clearSession();
    await _clearLocalSession();
  }
}
