import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/theme_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/update_provider.dart';
import '../../widgets/sidebar.dart';
import 'overview_tab.dart';
import 'products_tab.dart';
import 'categories_tab.dart';
import 'orders_tab.dart';
import 'users_tab.dart';
import 'notifications_tab.dart';
import 'payments_tab.dart';
import 'updates_tab.dart';

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
    'App Updates'
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
        title: Text(_titles[_selectedIndex]),
        centerTitle: !isDesktop,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              switch (_selectedIndex) {
                case 0: context.read<DashboardProvider>().fetchDashboardData(); break;
                case 1: context.read<ProductProvider>().fetchProducts(); break;
                case 2: context.read<CategoryProvider>().fetchCategories(); break;
                case 3: context.read<OrderProvider>().fetchOrders(); break;
                case 4: context.read<UserProvider>().fetchUsers(); break;
                case 6: context.read<PaymentProvider>().fetchPayments(); break;
                case 7: context.read<UpdateProvider>().fetchUpdates(); break;
              }
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
      floatingActionButton: (!isDesktop && (_selectedIndex == 1 || _selectedIndex == 2))
          ? FloatingActionButton(
              onPressed: () {
                if (_selectedIndex == 1) {
                  _showProductDialog(context);
                } else if (_selectedIndex == 2) {
                  _showCategoryDialog(context);
                }
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: _getBottomNavIndex(_selectedIndex),
              onTap: (index) {
                if (index == 4) {
                  _scaffoldKey.currentState?.openDrawer();
                } else {
                  setState(() => _selectedIndex = _getTabIndexFromBottomNav(index));
                }
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
                BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Products'),
                BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: 'Orders'),
                BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Users'),
                BottomNavigationBarItem(icon: Icon(Icons.menu_rounded), label: 'More'),
              ],
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
