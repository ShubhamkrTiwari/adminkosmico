import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0D3310); // Rich Dark Forest Green
  static const Color primaryLight = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF051B07);
  static const Color secondary = Color(0xFFF5F5F1); 
  static const Color textDark = Color(0xFF101820);
  static const Color textLight = Color(0xFF667085);
  static const Color accent = Color(0xFFD4AF37); // Luxury Gold accent
  static const Color background = Color(0xFFFCFCFD);
  static const Color surface = Colors.white;

  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D3310), // Rich Dark Green
      Color(0xFF1B5E20), // Deep Green
      Color(0xFF2E7D32), // Forest Green
    ],
  );

  static LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      const Color(0xFF0D3310).withOpacity(0.12), // Darker hint at top
      const Color(0xFFF8FAF8),
      Colors.white,
    ],
    stops: const [0.0, 0.4, 1.0],
  );
}

class AppConstants {
  static const String appName = 'Kosmico Wellness Admin';
  // Production API Base URL on Port 5000
  static const String baseUrl = 'http://3.7.180.215:5000/api/admin';

  
  static const double sidebarWidth = 260.0;
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;
}
