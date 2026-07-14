import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<Order> _orders = [];
  bool _isLoading = false;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/orders');
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        List? list = result['orders'] ?? (result['data'] is List ? result['data'] : result['data']?['orders']);
        if (list != null) {
          _orders = list.map((item) => Order.fromJson(item)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateOrderStatus(String id, String status) async {
    try {
      final response = await _apiClient.put('/orders/$id/status', {'status': status});
      if (response.statusCode == 200) {
        final index = _orders.indexWhere((o) => o.id == id);
        if (index != -1) {
          fetchOrders(); // Refresh to get updated data
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
    return false;
  }
}
