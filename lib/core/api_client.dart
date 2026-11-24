import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

class ApiClient {
  final _storage = const FlutterSecureStorage();

  /// Called when the backend rejects the stored token. AuthProvider listens to
  /// this so a dead session becomes a visible redirect instead of a silent
  /// token wipe that only shows up as a forced login on the next app start.
  static void Function()? onSessionExpired;
  static bool _expiryInFlight = false;

  // Auth endpoints answer 401/403 for "wrong credentials" reasons, which must
  // never be interpreted as "the current session is invalid".
  static const List<String> _authEndpoints = [
    '/login',
    '/signup',
    '/signup-verify',
    '/forgot-password',
    '/verify-otp',
    '/reset-password',
    '/me',
  ];

  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      // Older builds could persist an empty value; it is not a usable token.
      return (token == null || token.isEmpty) ? null : token;
    } catch (e) {
      debugPrint('Secure storage read failed: $e');
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    if (token.isEmpty) {
      throw Exception('Login response did not contain a token');
    }
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> clearSession() async {
    try {
      await _storage.delete(key: 'jwt_token');
    } catch (e) {
      debugPrint('Secure storage delete failed: $e');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _parseUri(String endpoint) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';

    if (cleanEndpoint.startsWith('/api/admin/') || cleanEndpoint.startsWith('/api/subscription')) {
      return Uri.parse('https://api.kosmicowellness.com$cleanEndpoint');
    }
    if (cleanEndpoint.startsWith('/admin/') || cleanEndpoint.startsWith('/subscription')) {
      return Uri.parse('https://api.kosmicowellness.com/api$cleanEndpoint');
    }
    if (cleanEndpoint.startsWith('/api/')) {
      return Uri.parse('https://api.kosmicowellness.com$cleanEndpoint');
    }
    if (cleanEndpoint.startsWith('/whatsapp') || cleanEndpoint.startsWith('/notification')) {
      return Uri.parse('https://api.kosmicowellness.com/api$cleanEndpoint');
    }
    return Uri.parse('${AppConstants.baseUrl}$cleanEndpoint');
  }

  Future<http.Response> get(String endpoint) async {
    final response = await http.get(
      _parseUri(endpoint),
      headers: await _getHeaders(),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Request timeout after 15 seconds'),
    );
    _handleResponse(response, endpoint);
    return response;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      _parseUri(endpoint),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Request timeout after 15 seconds'),
    );
    _handleResponse(response, endpoint);
    return response;
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final response = await http.put(
      _parseUri(endpoint),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Request timeout after 15 seconds'),
    );
    _handleResponse(response, endpoint);
    return response;
  }

  Future<http.Response> delete(String endpoint) async {
    final response = await http.delete(
      _parseUri(endpoint),
      headers: await _getHeaders(),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Request timeout after 15 seconds'),
    );
    _handleResponse(response, endpoint);
    return response;
  }

  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final response = await http.patch(
      _parseUri(endpoint),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Request timeout after 15 seconds'),
    );
    _handleResponse(response, endpoint);
    return response;
  }

  void _handleResponse(http.Response response, String endpoint) {
    // Only a 401 on a non-auth endpoint proves the stored token is unusable.
    // 403 is an authorization/business answer (e.g. "product unavailable"), and
    // 5xx/HTML are transient - clearing the session there logs the admin out
    // for no reason.
    if (response.statusCode == 401 && !_isAuthEndpoint(endpoint)) {
      _expireSession();
    }

    // Check if the response is HTML (often happens on 404 or server errors)
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('text/html') || response.body.trim().startsWith('<!DOCTYPE')) {
      throw FormatException('Server returned HTML instead of JSON. Status: ${response.statusCode}');
    }
  }

  bool _isAuthEndpoint(String endpoint) =>
      _authEndpoints.any((e) => endpoint == e || endpoint.startsWith('$e/'));

  void _expireSession() {
    if (_expiryInFlight) return;
    _expiryInFlight = true;
    clearSession().whenComplete(() {
      onSessionExpired?.call();
      _expiryInFlight = false;
    });
  }
}
