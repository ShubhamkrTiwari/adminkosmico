import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/theme_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/update_provider.dart';
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

class DashboardMain extends StatefulWidget {
  const DashboardMain({super.key});

  @override
  State<DashboardMain> createState() => _DashboardMainState();
}

class _DashboardMainState extends State<DashboardMain> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _titles = [
    'Dashboard Overview',
    'Product Management',
    'Category Management',
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
    if (tabIndex == 3) return 2; // Orders
    if (tabIndex == 4) return 3; // Users
    return 4; // More (for anything else)
  }

  int _getTabIndexFromBottomNav(int navIndex) {
    if (navIndex == 0) return 0; // Overview
    if (navIndex == 1) return 1; // Products
    if (navIndex == 2) return 3; // Orders
    if (navIndex == 3) return 4; // Users
    return _selectedIndex; // Default (don't change if 'More' is clicked)
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFF8FAF8),
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
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _getBottomNavIndex(_selectedIndex),
                onTap: (index) {
                  if (index == 4) {
                    _scaffoldKey.currentState?.openDrawer();
                  } else {
                    setState(() => _selectedIndex = _getTabIndexFromBottomNav(index));
                  }
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                elevation: 0,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: Colors.grey.shade400,
                selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11),
                unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 11),
                items: const [
                  BottomNavigationBarItem(
                    icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.grid_view_rounded)), 
                    label: 'Overview',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.inventory_2_outlined)), 
                    label: 'Products',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.shopping_bag_outlined)), 
                    label: 'Orders',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.people_outline_rounded)), 
                    label: 'Users',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.menu_rounded)), 
                    label: 'More',
                  ),
                ],
              ),
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            Sidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) => setState(() => _selectedIndex = index),
            ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: IndexedStack(
                index: _selectedIndex,
                children: const [
                  OverviewTab(),
                  ProductsTab(),
                  CategoriesTab(),
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
    );
  }

  void _showProductDialog(BuildContext context) {}

  void _showCategoryDialog(BuildContext context) {}
}
