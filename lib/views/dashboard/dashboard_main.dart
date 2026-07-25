import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/theme_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../widgets/sidebar.dart';
import 'overview_tab.dart';
import 'products_tab.dart';
import 'categories_tab.dart';
import 'orders_tab.dart';
import 'users_tab.dart';
import 'notifications_tab.dart';
import 'payments_tab.dart';
import 'updates_tab.dart';
import 'maintenance_tab.dart';
import 'coupons_tab.dart';

class DashboardMain extends StatefulWidget {
  const DashboardMain({super.key});

  @override
  State<DashboardMain> createState() => _DashboardMainState();
}

class _DashboardMainState extends State<DashboardMain> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _menuController;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  final List<String> _titles = [
    'Dashboard Overview',
    'Product Management',
    'Category Management',
    'Coupon Management',
    'Order Management',
    'User Management',
    'Notifications',
    'Payments & Transactions',
    'App Updates',
    'Maintenance'
  ];

  int? _getBottomNavIndex(int tabIndex) {
    if (tabIndex == 0) return 0; // Overview
    if (tabIndex == 1) return 1; // Products
    if (tabIndex == 4) return 2; // Orders
    if (tabIndex == 5) return 3; // Users
    return null;
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
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      key: _scaffoldKey,
      onDrawerChanged: (isOpen) {
        if (isOpen) {
          _menuController.forward();
        } else {
          _menuController.reverse();
        }
      },
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: themeProvider.themeMode == ThemeMode.dark 
                ? [
                    AppColors.primaryLight.withValues(alpha: 0.1),
                    AppColors.darkBg.withValues(alpha: 0.1),
                  ]
                : [
                    AppColors.primary.withValues(alpha: 0.05),
                    AppColors.primary.withValues(alpha: 0.1),
                  ],
            ),
          ),
        ),
        leading: !isDesktop ? Center(
          child: Container(
            decoration: BoxDecoration(
              color: (themeProvider.themeMode == ThemeMode.dark ? Colors.white : AppColors.primary).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _menuController,
                color: themeProvider.themeMode == ThemeMode.dark ? AppColors.primaryLight : AppColors.primary,
                size: 20,
              ),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
        ) : null,
        title: Text(
          _titles[_selectedIndex],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, 
            fontSize: 18,
            color: themeProvider.themeMode == ThemeMode.dark ? AppColors.darkTextPrimary : AppColors.textDark,
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
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() => _selectedIndex = index);
          if (!isDesktop) Navigator.pop(context);
        },
      ),
      bottomNavigationBar: !isDesktop
          ? SafeArea(
              child: Container(
                height: 75,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (themeProvider.themeMode == ThemeMode.dark ? Colors.black : AppColors.primary).withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: themeProvider.themeMode == ThemeMode.dark 
                            ? AppColors.darkSurface.withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.1), 
                          width: 1.5
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavButton(Icons.grid_view_rounded, 'Overview', 0, themeProvider.themeMode == ThemeMode.dark),
                          _buildNavButton(Icons.inventory_2_outlined, 'Products', 1, themeProvider.themeMode == ThemeMode.dark),
                          _buildNavButton(Icons.shopping_bag_outlined, 'Orders', 2, themeProvider.themeMode == ThemeMode.dark),
                          _buildNavButton(Icons.people_outline_rounded, 'Users', 3, themeProvider.themeMode == ThemeMode.dark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.getSubtleGradient(themeProvider.themeMode == ThemeMode.dark)),
        child: Row(
          children: [
            if (isDesktop)
              Sidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) => setState(() => _selectedIndex = index),
              ),
            Expanded(
              child: Container(
                color: Colors.transparent,
                child: IndexedStack(
                  index: _selectedIndex,
                  children: const [
                    OverviewTab(key: ValueKey('overview')),
                    ProductsTab(key: ValueKey('products')),
                    CategoriesTab(key: ValueKey('categories')),
                    CouponsTab(key: ValueKey('coupons')),
                    OrdersTab(key: ValueKey('orders')),
                    UsersTab(key: ValueKey('users')),
                    NotificationsTab(key: ValueKey('notifications')),
                    PaymentsTab(key: ValueKey('payments')),
                    UpdatesTab(key: ValueKey('updates')),
                    MaintenanceTab(key: ValueKey('maintenance')),
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

  Widget _buildNavButton(IconData icon, String label, int index, bool isDark) {
    final navIndex = _getBottomNavIndex(_selectedIndex);
    final isSelected = navIndex == index;
    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;
    
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() => _selectedIndex = _getTabIndexFromBottomNav(index));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuint,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20 : 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected 
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withValues(alpha: 0.15),
                  primaryColor.withValues(alpha: 0.05),
                ],
              ) 
            : null,
          borderRadius: BorderRadius.circular(20),
          border: isSelected 
            ? Border.all(color: primaryColor.withValues(alpha: 0.1), width: 1)
            : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedRotation(
              turns: isSelected ? 1.0 : 0,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.elasticOut,
              child: AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                child: Icon(
                  icon,
                  color: isSelected ? primaryColor : (isDark ? Colors.white54 : Colors.grey.shade400),
                  size: 22,
                ),
              ),
            ),
            ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutQuint,
                alignment: Alignment.centerLeft,
                widthFactor: isSelected ? 1.0 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.poppins(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
