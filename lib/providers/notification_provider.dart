import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../config/api_config.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _notifications = [];
  List<dynamic> _whatsappTemplates = [];
  bool _isLoading = false;

  List<dynamic> get notifications => _notifications;
  List<dynamic> get whatsappTemplates => _whatsappTemplates;
  bool get isLoading => _isLoading;

  void setNotificationsFromDashboard(List<dynamic> list) {
    _notifications = list;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('/notifications');
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['data'] is Map && result['data']['notifications'] is List) {
          _notifications = result['data']['notifications'];
        } else if (result['notifications'] is List) {
          _notifications = result['notifications'];
        } else if (result['data'] is List) {
          _notifications = result['data'];
        } else {
          _notifications = [];
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> deleteNotification(String id) async {
    try {
      final response = await _apiClient.delete('/notifications/$id');
      if (response.statusCode == 200) {
        _notifications.removeWhere((n) => n['_id'] == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
    return false;
  }

  Future<bool> sendNotification(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final audience = (data['audience'] ?? data['user'] ?? 'all').toString();
      final bool isBroadcast = (audience == 'all' || audience == 'subscribed');

      final String endpoint = isBroadcast ? '/notifications/broadcast' : '/notifications/send';

      final payload = {
        'title': data['title'],
        'message': data['message'],
        'image': data['image'] ?? '',
        'category': data['category'] ?? 'General',
        'audience': audience,
        'userId': audience,
        'user': audience,
        'status': 'sent',
      };

      final response = await _apiClient.post(endpoint, payload);
      debugPrint('Send Notification Response ($endpoint): ${response.statusCode} - ${response.body}');
      
      _isLoading = false;
      notifyListeners();
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchNotifications(); // Refresh list after sending
        return true;
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // 1. Broadcast Custom Push Notification
  Future<bool> sendAdminNotification({
    required String title,
    required String message,
    required String target,
    String? targetUserId,
    String? type,
    String? icon,
    String? imageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final payload = {
        'userId': targetUserId ?? (target == 'all' ? 'all' : ''),
        'targetUserId': targetUserId ?? (target == 'all' ? 'all' : ''),
        'title': title,
        'message': message,
        'body': message,
        'target': target,
        'audience': target,
        'type': type ?? 'promo',
        'category': type ?? 'promo',
        'icon': icon ?? '🎁',
        'image': imageUrl ?? '',
        'imageUrl': imageUrl ?? '',
      };
      
      final endpoint = target == 'all' ? '/notifications/broadcast' : '/notifications/send';
      final response = await _apiClient.post(endpoint, payload);
      debugPrint('Send Admin Notification Response: Status ${response.statusCode}, Body: ${response.body}');
      _isLoading = false;
      notifyListeners();
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchNotifications();
        return true;
      }
    } catch (e) {
      debugPrint('Error sending admin notification: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // 2. View Sent Admin Notifications History
  Future<List<dynamic>> getAdminSentNotifications() async {
    try {
      final response = await _apiClient.get('/notifications/admin/history');
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['notifications'] != null) {
          _notifications = result['notifications'];
        } else if (result['data'] != null && result['data']['notifications'] != null) {
          _notifications = result['data']['notifications'];
        }
        notifyListeners();
        return _notifications;
      }
    } catch (e) {
      debugPrint('Error fetching admin history: $e');
    }
    await fetchNotifications();
    return _notifications;
  }

  // 3. Get Platform Auto Notifications Settings
  Future<Map<String, dynamic>?> getNotificationPreferences() async {
    try {
      final response = await _apiClient.get('/notification-preferences');
      debugPrint('Get Preferences Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['data'] != null && result['data']['preferences'] != null) {
          return result['data']['preferences'];
        } else if (result['preferences'] != null) {
          return result['preferences'];
        }
      }
    } catch (e) {
      debugPrint('Error fetching notification preferences: $e');
    }
    return null;
  }

  // 3. Save Platform Auto Notifications Settings
  Future<bool> saveNotificationPreferences(Map<String, dynamic> preferences) async {
    try {
      final response = await _apiClient.put('/notification-preferences', preferences);
      debugPrint('Save Preferences Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      debugPrint('Error saving notification preferences: $e');
    }
    return false;
  }

  // 4. Trigger AI Analysis & Auto Push
  Future<Map<String, dynamic>?> triggerAnalysis() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('/notification-analysis/trigger', {});
      _isLoading = false;
      notifyListeners();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        await fetchNotifications();
        return result;
      }
    } catch (e) {
      debugPrint('Error triggering analysis: $e');
    }
    _isLoading = false;
    notifyListeners();
    return null;
  }

  // 5. Send Self Test Notification
  Future<bool> sendSelfTestNotification({
    required String fcmToken,
    required String title,
    required String message,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final payload = {
        'fcmToken': fcmToken,
        'title': title,
        'message': message,
      };
      final response = await _apiClient.post('/notifications/test', payload);
      _isLoading = false;
      notifyListeners();
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // 6. Send WhatsApp Message to User
  Future<bool> sendWhatsAppMessage({
    required String userId,
    required String templateName,
    String language = 'en',
    List<String>? bodyParams,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final isBroadcast = userId == 'all';
      final payload = {
        if (!isBroadcast) 'userId': userId,
        if (isBroadcast) 'broadcast': true,
        if (isBroadcast) 'audience': 'all',
        'template_name': templateName,
        'language': language,
        if (bodyParams != null && bodyParams.isNotEmpty) 'body_params': bodyParams,
      };
      final response = await _apiClient.post(ApiConfig.whatsappSend, payload);
      debugPrint('Send WhatsApp Response: Status ${response.statusCode}, Body: ${response.body}');
      _isLoading = false;
      notifyListeners();
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      debugPrint('Error sending WhatsApp message: $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // 7. Fetch WhatsApp Templates
  Future<void> fetchWhatsAppTemplates() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get(ApiConfig.whatsappTemplates);
      debugPrint('WhatsApp Templates Response: Status ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Parsed data: $data');
        // Handle different response structures
        if (data['data'] != null) {
          _whatsappTemplates = data['data'];
        } else if (data['templates'] != null) {
          _whatsappTemplates = data['templates'];
        } else if (data is List) {
          _whatsappTemplates = data;
        } else {
          _whatsappTemplates = [];
        }
        debugPrint('Templates loaded: ${_whatsappTemplates.length}');
      } else {
        debugPrint('Non-200 status: ${response.statusCode}');
        _whatsappTemplates = [];
      }
    } catch (e) {
      debugPrint('Error fetching WhatsApp templates: $e');
      _whatsappTemplates = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
