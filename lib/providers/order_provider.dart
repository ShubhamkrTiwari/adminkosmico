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

  void setOrdersFromDashboard(List<dynamic> list) {
    try {
      _orders = list.map((item) => Order.fromJson(item)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing orders from dashboard: $e');
    }
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/orders');
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List list = result['orders'] ?? result['data'] ?? [];
        _orders = list.map((item) => Order.fromJson(item)).toList();
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
        fetchOrders();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
    return false;
  }

  // Shiprocket Actions
  Future<Map<String, dynamic>> createShiprocketOrder(String id) async {
    try {
      final response = await _apiClient.post('/orders/$id/shiprocket/create', {});
      if (response.statusCode == 200) {
        fetchOrders();
        return {'success': true, 'message': 'Shiprocket order created successfully'};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Failed to create Shiprocket order'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> cancelShiprocketOrder(String id) async {
    try {
      final response = await _apiClient.post('/orders/$id/shiprocket/cancel', {});
      if (response.statusCode == 200) {
        fetchOrders();
        return {'success': true, 'message': 'Shiprocket order cancelled'};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Failed to cancel Shiprocket order'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> trackShiprocketOrder(String id) async {
    try {
      final response = await _apiClient.get('/orders/$id/shiprocket/track');
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Failed to track order'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> returnShiprocketOrder(String id) async {
    try {
      final response = await _apiClient.post('/orders/$id/shiprocket/return', {});
      if (response.statusCode == 200) {
        fetchOrders();
        return {'success': true, 'message': 'Return pickup initiated'};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'message': error['message'] ?? 'Failed to initiate return'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
