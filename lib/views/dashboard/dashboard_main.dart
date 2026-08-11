import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/theme_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/update_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/coupon_provider.dart';
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

class _DashboardMainState extends State<DashboardMain> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final selectedIndex = navProvider.selectedIndex;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFE1F0E1), // Match the new background top color
                const Color(0xFFE1F0E1).withOpacity(0.5),
              ],
            ),
          ),
        ),
        leading: !isDesktop ? IconButton(
          icon: Icon(
            Icons.menu_rounded, 
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.primary
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ) : null,
        title: Text(
          _titles[selectedIndex],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700, 
            fontSize: 18,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textDark,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
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
              context.read<CouponProvider>().fetchCoupons();
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
          ? Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                child: BottomNavigationBar(
                  currentIndex: _getBottomNavIndex(selectedIndex),
                  onTap: (index) {
                    navProvider.setSelectedIndex(_getTabIndexFromBottomNav(index));
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Theme.of(context).cardColor,
                  elevation: 0,
                  selectedItemColor: Theme.of(context).brightness == Brightness.dark ? AppColors.accent : AppColors.primary,
                  unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.grey.shade400,
                  selectedLabelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, 
                    fontSize: 11,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500, 
                    fontSize: 11,
                  ),
                  items: [
                    _buildBottomNavItem(Icons.grid_view_rounded, 'Overview', 0),
                    _buildBottomNavItem(Icons.inventory_2_outlined, 'Products', 1),
                    _buildBottomNavItem(Icons.shopping_bag_outlined, 'Orders', 2),
                    _buildBottomNavItem(Icons.people_outline_rounded, 'Users', 3),
                  ],
                ),
              ),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.getSubtleGradient(Theme.of(context).brightness == Brightness.dark)),
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
                  children: const [
                    OverviewTab(),
                    ProductsTab(),
                    CategoriesTab(),
                    CouponsTab(),
                    OrdersTab(),
                    UsersTab(),
                    NotificationsTab(),
                    PaymentsTab(),
                    UpdatesTab(),
                    MaintenanceTab(),
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

  BottomNavigationBarItem _buildBottomNavItem(IconData icon, String label, int index) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final isSelected = _getBottomNavIndex(navProvider.selectedIndex) == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }
}
