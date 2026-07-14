import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2E7D32); // Natural Green
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color secondary = Color(0xFFF5F5F1); // Cream/Off-white
  static const Color textDark = Color(0xFF1A1A1A); // Dark Navy/Black
  static const Color textLight = Color(0xFF757575);
  static const Color accent = Color(0xFF673AB7); // Subtle Purple
  static const Color background = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color info = Color(0xFF1976D2);
  static const Color warning = Color(0xFFFBC02D);
}

class AppConstants {
  static const String appName = 'Kosmico Wellness Admin';
  // Production API Base URL on Port 5000
  static const String baseUrl = 'http://3.7.180.215:5000/api/admin';

  
  static const double sidebarWidth = 260.0;
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;
}
