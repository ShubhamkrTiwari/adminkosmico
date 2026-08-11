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
      // Trying to use public route first for better reliability across apps
      final response = await _apiClient.get('/coupons/admin/list');
      debugPrint('FETCH COUPONS: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('COUPON DATA RECEIVED: $result');
        
        List? list;
        if (result is Map) {
          if (result['success'] == true) {
            if (result['data'] != null && result['data']['coupons'] is List) {
              list = result['data']['coupons'];
            } else if (result['coupons'] is List) {
              list = result['coupons'];
            } else if (result['data'] is List) {
              list = result['data'];
            }
          }
        } else if (result is List) {
          list = result;
        }

        if (list != null) {
          _coupons = list.map((item) => Coupon.fromJson(item)).toList();
          debugPrint('SUCCESS: Loaded ${_coupons.length} coupons');
        } else {
          _coupons = [];
          debugPrint('WARNING: No coupons found in response');
        }
      } else {
        _error = 'Failed to load coupons: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('CRITICAL: Coupon fetch failed: $e');
      _error = 'Connection error: $e';
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
      final response = await _apiClient.put('/coupons/update/$id', data);
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
      final response = await _apiClient.delete('/coupons/$id');
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
      final response = await _apiClient.patch('/coupons/toggle/$id', {});
      if (response.statusCode == 200) {
        final index = _coupons.indexWhere((c) => c.id == id);
        if (index != -1) {
          final result = jsonDecode(response.body);
          // If the server returns the full coupon object in result['data']['coupon']
          if (result['data'] != null && result['data']['coupon'] != null) {
             _coupons[index] = Coupon.fromJson(result['data']['coupon']);
          } else {
            // If it only returns isActive status as per screenshot
            final current = _coupons[index];
            _coupons[index] = Coupon(
              id: current.id,
              code: current.code,
              discountType: current.discountType,
              discountAmount: current.discountAmount,
              minOrderAmount: current.minOrderAmount,
              expiryDate: current.expiryDate,
              usageLimit: current.usageLimit,
              usedCount: current.usedCount,
              isActive: result['isActive'] ?? !current.isActive,
              description: current.description,
            );
          }
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
