import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adminkosmico/core/constants.dart';
import 'package:adminkosmico/providers/theme_provider.dart';
import 'package:adminkosmico/providers/dashboard_provider.dart';
import 'package:adminkosmico/providers/product_provider.dart';
import 'package:adminkosmico/providers/category_provider.dart';
import 'package:adminkosmico/providers/maintenance_provider.dart';
import 'package:adminkosmico/providers/navigation_provider.dart';
import 'package:adminkosmico/widgets/sidebar.dart';
import 'package:adminkosmico/widgets/liquid_floating_bar.dart';
import 'package:adminkosmico/views/dashboard/overview_tab.dart';
import 'package:adminkosmico/views/dashboard/products_tab.dart';
import 'package:adminkosmico/views/dashboard/categories_tab.dart';
import 'package:adminkosmico/views/dashboard/orders_tab.dart';
import 'package:adminkosmico/views/dashboard/users_tab.dart';
import 'package:adminkosmico/views/dashboard/notifications_tab.dart';
import 'package:adminkosmico/views/dashboard/payments_tab.dart';
import 'package:adminkosmico/views/dashboard/updates_tab.dart';
import 'package:adminkosmico/views/dashboard/maintenance_tab.dart';
import 'package:adminkosmico/views/dashboard/coupons_tab.dart';
import 'package:adminkosmico/views/dashboard/subscriptions_tab.dart';
import 'package:adminkosmico/views/dashboard/whatsapp_tab.dart';
import 'package:adminkosmico/views/dashboard/leads_tab.dart';

class DashboardMain extends StatefulWidget {
  const DashboardMain({super.key});

  @override
  State<DashboardMain> createState() => _DashboardMainState();
}

class _DashboardMainState extends State<DashboardMain> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _titles = [
    'Dashboard Overview',
    'Product Management',
    'Category Management',
    'Coupon Management',
    'Order Management',
    'User Management',
    'Leads Management',
    'Notifications',
    'WhatsApp Messaging',
    'Payments & Transactions',
    'App Updates',
    'Maintenance',
    'Subscription Management'
  ];

  int _getBottomNavIndex(int tabIndex) {
    if (tabIndex == 0) return 0; // Overview
    if (tabIndex == 1) return 1; // Products
    if (tabIndex == 4) return 2; // Orders
    if (tabIndex == 5) return 3; // Users
    return 0; // Default to first if not in bottom nav
  }

  int _getTabIndexFromBottomNav(int navIndex) {
    if (navIndex == 0) return 0; // Overview
    if (navIndex == 1) return 1; // Products
    if (navIndex == 2) return 4; // Orders
    if (navIndex == 3) return 5; // Users
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final navProvider = Provider.of<NavigationProvider>(context);
    final selectedIndex = navProvider.selectedIndex;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.05),
                AppColors.primary.withOpacity(0.1),
              ],
            ),
          ),
        ),
        leading: !isDesktop ? _AnimatedMenuButton(
          color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : AppColors.primary,
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ) : null,
        title: Text(
          _titles[selectedIndex],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, 
            fontSize: 18,
            color: themeProvider.themeMode == ThemeMode.dark ? Colors.white : AppColors.textDark,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              size: 22,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: () {
              context.read<DashboardProvider>().fetchDashboardData(context);
              context.read<ProductProvider>().fetchProducts();
              context.read<CategoryProvider>().fetchCategories();
              context.read<MaintenanceProvider>().fetchMaintenanceStatus();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Sidebar(
        selectedIndex: selectedIndex,
        onItemSelected: (index) {
          navProvider.setSelectedIndex(index);
          if (!isDesktop) Navigator.pop(context);
        },
      ),
      bottomNavigationBar: !isDesktop
          ? LiquidFloatingBar(
              currentIndex: _getBottomNavIndex(selectedIndex),
              onTap: (index) {
                navProvider.setSelectedIndex(_getTabIndexFromBottomNav(index));
              },
              isDark: themeProvider.themeMode == ThemeMode.dark,
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.getSubtleGradient(themeProvider.themeMode == ThemeMode.dark),
        ),
        child: Row(
          children: [
            if (isDesktop)
              Sidebar(
                selectedIndex: selectedIndex,
                onItemSelected: (index) => navProvider.setSelectedIndex(index),
              ),
            Expanded(
              child: Container(
                color: Colors.transparent,
                child: IndexedStack(
                  index: selectedIndex,
                  children: [
                    const OverviewTab(),
                    const ProductsTab(),
                    const CategoriesTab(),
                    const CouponsTab(),
                    const OrdersTab(),
                    const UsersTab(),
                    const LeadsTab(),
                    const NotificationsTab(),
                    const WhatsAppTab(),
                    const PaymentsTab(),
                    const UpdatesTab(),
                    const MaintenanceTab(),
                    const SubscriptionsTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDialog(BuildContext context) {}

  void _showCategoryDialog(BuildContext context) {}
}

class _AnimatedMenuButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color color;

  const _AnimatedMenuButton({required this.onPressed, required this.color});

  @override
  State<_AnimatedMenuButton> createState() => _AnimatedMenuButtonState();
}

class _AnimatedMenuButtonState extends State<_AnimatedMenuButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.9 : (_isHovered ? 1.15 : 1.0),
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovered ? widget.color.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isHovered ? widget.color.withOpacity(0.3) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(Icons.menu_rounded, color: widget.color, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
