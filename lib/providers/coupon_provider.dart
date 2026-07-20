import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/coupon.dart';

class CouponProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<Coupon> _coupons = [];
  bool _isLoading = false;
  String? _error;

  List<Coupon> get coupons => _coupons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCoupons() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/coupons');
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          final List list = result['data']['coupons'];
          _coupons = list.map((item) => Coupon.fromJson(item)).toList();
        }
      } else {
        _error = 'Failed to load coupons';
      }
    } catch (e) {
      _error = 'Connection error';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addCoupon(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/coupons/admin/add-coupon', data);
      if (response.statusCode == 201) {
        fetchCoupons();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding coupon: $e');
    }
    return false;
  }

  Future<bool> updateCoupon(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put('/coupons/admin/update-coupon/$id', data);
      if (response.statusCode == 200) {
        fetchCoupons();
        return true;
      }
    } catch (e) {
      debugPrint('Error updating coupon: $e');
    }
    return false;
  }

  Future<bool> deleteCoupon(String id) async {
    try {
      final response = await _apiClient.delete('/coupons/admin/delete-coupon/$id');
      if (response.statusCode == 200) {
        _coupons.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting coupon: $e');
    }
    return false;
  }

  Future<bool> toggleStatus(String id) async {
    try {
      final response = await _apiClient.patch('/coupons/admin/toggle-status/$id', {});
      if (response.statusCode == 200) {
        final index = _coupons.indexWhere((c) => c.id == id);
        if (index != -1) {
          final result = jsonDecode(response.body);
          _coupons[index] = Coupon.fromJson(result['data']['coupon']);
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error toggling coupon status: $e');
    }
    return false;
  }
}
