import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';

class PaymentProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _payments = [];
  bool _isLoading = false;

  List<dynamic> get payments => _payments;
  bool get isLoading => _isLoading;

  Future<void> fetchPayments() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/payments');
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _payments = result['payments'] ?? result['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching payments: $e');
    }
    _isLoading = false;
    notifyListeners();
  }
}
