import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';
import 'core/constants.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/product_provider.dart';
import 'providers/category_provider.dart';
import 'providers/order_provider.dart';
import 'providers/user_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/update_provider.dart';
import 'providers/maintenance_provider.dart';
import 'providers/coupon_provider.dart';
import 'views/auth/login_screen.dart';
import 'views/dashboard/dashboard_main.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
        ],
        child: const MyApp(),
      ),
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
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeProvider.themeMode,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const DashboardMain();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
