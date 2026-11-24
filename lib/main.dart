import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:adminkosmico/core/constants.dart';
import 'package:adminkosmico/providers/auth_provider.dart';
import 'package:adminkosmico/providers/theme_provider.dart';
import 'package:adminkosmico/providers/navigation_provider.dart';
import 'package:adminkosmico/providers/dashboard_provider.dart';
import 'package:adminkosmico/providers/product_provider.dart';
import 'package:adminkosmico/providers/category_provider.dart';
import 'package:adminkosmico/providers/order_provider.dart';
import 'package:adminkosmico/providers/user_provider.dart';
import 'package:adminkosmico/providers/notification_provider.dart';
import 'package:adminkosmico/providers/payment_provider.dart';
import 'package:adminkosmico/providers/update_provider.dart';
import 'package:adminkosmico/providers/maintenance_provider.dart';
import 'package:adminkosmico/providers/coupon_provider.dart';
import 'package:adminkosmico/providers/subscription_provider.dart';
import 'package:adminkosmico/providers/lead_provider.dart';
import 'package:adminkosmico/views/auth/login_screen.dart';
import 'package:adminkosmico/views/dashboard/dashboard_main.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => UpdateProvider()),
        ChangeNotifierProvider(create: (_) => MaintenanceProvider()),
        ChangeNotifierProvider(create: (_) => CouponProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => LeadProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Kosmico Wellness Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary, 
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E), // Lighter surface
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF242424), // Lighter cards
        dividerColor: Colors.white10,
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIconColor: Colors.white54,
          labelStyle: const TextStyle(color: Colors.white70),
          fillColor: Colors.white.withOpacity(0.05),
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Staying on a splash while the stored token is being validated keeps
          // a slow /me response from flashing the login screen.
          if (auth.isBooting && !auth.isAuthenticated) {
            return const _AuthSplash();
          }
          if (auth.isAuthenticated) {
            return const DashboardMain();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

class _AuthSplash extends StatelessWidget {
  const _AuthSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
