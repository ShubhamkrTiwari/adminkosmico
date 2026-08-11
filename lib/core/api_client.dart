import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

class ApiClient {
  final _storage = const FlutterSecureStorage();
  
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: await _getHeaders(),
    );
    _handleResponse(response);
    return response;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    _handleResponse(response);
    return response;
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    _handleResponse(response);
    return response;
  }

  Future<http.Response> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: await _getHeaders(),
    );
    _handleResponse(response);
    return response;
  }

  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse('${AppConstants.baseUrl}$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );
    _handleResponse(response);
    return response;
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      // Session expired or unauthorized
      clearSession();
    }
    
    // Check if the response is HTML (often happens on 404 or server errors)
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('text/html') || response.body.trim().startsWith('<!DOCTYPE')) {
      throw FormatException('Server returned HTML instead of JSON. Status: ${response.statusCode}');
    }
  }
}
