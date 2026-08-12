import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/stat_card.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await context.read<DashboardProvider>().fetchDashboardData(context);
  }

  String _calculateTrend(num current, num previous) {
    if (previous == 0) {
      return current > 0 ? '+100%' : '0%';
    }
    final change = ((current - previous) / previous) * 100;
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}%';
  }

  bool _isTrendPositive(num current, num previous) {
    return current >= previous;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = provider.data?['stats'];
        final recentOrders = provider.data?['orders'] as List? ?? [];
        final lowStock = provider.data?['lowStockProducts'] as List? ?? [];
        final salesData = provider.data?['salesData'] as List? ?? [];

        return RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.getSubtleGradient(Theme.of(context).brightness == Brightness.dark),
            ),
            child: CustomScrollView(
              slivers: [
                // Modern App Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dashboard Overview',
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).textTheme.titleLarge?.color,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.getSecondaryTextColor(Theme.of(context).brightness == Brightness.dark),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildHeaderAction(Icons.notifications_none_rounded, () {
                          context.read<NavigationProvider>().setSelectedIndex(6);
                        }),
                        const SizedBox(width: 12),
                        _buildHeaderAction(Icons.search_rounded, () {
                          context.read<NavigationProvider>().setSelectedIndex(1);
                        }),
                      ],
                    ),
                  ),
                ),

                // KPI Stats Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.15,
                    ),
                    delegate: SliverChildListDelegate([
                      StatCard(
                        title: 'Total Revenue',
                        value: currencyFormat.format(stats?['totalRevenue'] ?? 0),
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFF2E7D32),
                        trend: _calculateTrend(stats?['revenueToday'] ?? 0, stats?['revenueYesterday'] ?? 0),
                        isTrendPositive: _isTrendPositive(stats?['revenueToday'] ?? 0, stats?['revenueYesterday'] ?? 0),
                        onTap: () => context.read<NavigationProvider>().setSelectedIndex(7),
                      ),
                      StatCard(
                        title: 'Total Orders',
                        value: (stats?['totalOrders'] ?? 0).toString(),
                        icon: Icons.local_mall_rounded,
                        color: const Color(0xFF1565C0),
                        trend: _calculateTrend(stats?['ordersToday'] ?? 0, stats?['ordersYesterday'] ?? 0),
                        isTrendPositive: _isTrendPositive(stats?['ordersToday'] ?? 0, stats?['ordersYesterday'] ?? 0),
                        onTap: () => context.read<NavigationProvider>().setSelectedIndex(4),
                      ),
                      StatCard(
                        title: 'Customers',
                        value: (stats?['totalUsers'] ?? 0).toString(),
                        icon: Icons.group_rounded,
                        color: const Color(0xFFE65100),
                        onTap: () => context.read<NavigationProvider>().setSelectedIndex(5),
                      ),
                      StatCard(
                        title: 'Notifications',
                        value: (stats?['totalNotifications'] ?? 0).toString(),
                        icon: Icons.campaign_rounded,
                        color: const Color(0xFF6A1B9A),
                        onTap: () => context.read<NavigationProvider>().setSelectedIndex(6),
                      ),
                    ]),
                  ),
                ),

                // Daily Performance Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    child: Text(
                      'Daily Performance',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    delegate: SliverChildListDelegate([
                      StatCard(
                        title: 'Orders Today',
                        value: (stats?['ordersToday'] ?? 0).toString(),
                        icon: Icons.today_rounded,
                        color: AppColors.primary,
                        onTap: () => context.read<NavigationProvider>().setSelectedIndex(4),
                      ),
                      StatCard(
                        title: 'Orders Yesterday',
                        value: (stats?['ordersYesterday'] ?? 0).toString(),
                        icon: Icons.history_rounded,
                        color: Colors.blueGrey,
                        onTap: () => context.read<NavigationProvider>().setSelectedIndex(4),
                      ),
                      StatCard(
                        title: 'Revenue Today',
                        value: currencyFormat.format(stats?['revenueToday'] ?? 0),
                        icon: Icons.payments_rounded,
                        color: Colors.teal,
                        onTap: () => context.read<NavigationProvider>().setSelectedIndex(7),
                      ),
                      StatCard(
                        title: 'Revenue Yesterday',
                        value: currencyFormat.format(stats?['revenueYesterday'] ?? 0),
                        icon: Icons.wallet_rounded,
                        color: Colors.brown,
                        onTap: () => context.read<NavigationProvider>().setSelectedIndex(7),
                      ),
                    ]),
                  ),
                ),

                // Sales Chart
                SliverToBoxAdapter(
                  child: _buildSectionWrapper(
                    title: 'Revenue Analytics',
                    child: _buildSalesChart(context, salesData),
                  ),
                ),

                // Inventory & Recent Activity
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 800) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: _buildActivityList(recentOrders)),
                              const SizedBox(width: 24),
                              Expanded(child: _buildStockAlerts(lowStock)),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildStockAlerts(lowStock),
                              const SizedBox(height: 24),
                              _buildActivityList(recentOrders),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: IconButton(
        icon: Icon(icon, color: isDark ? Colors.white : AppColors.textDark, size: 22),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSectionWrapper({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleMedium?.color)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context, List salesData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Monthly Growth', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.getSecondaryTextColor(isDark))),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: salesData.isEmpty 
              ? const Center(child: Text('No data available'))
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: salesData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['total'] as num).toDouble())).toList(),
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 6,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primary.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(List orders) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.read<NavigationProvider>().setSelectedIndex(4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Orders', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppColors.textDark)),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No recent orders')))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.take(5).length,
              separatorBuilder: (_, _) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final order = orders[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.shopping_bag_outlined, color: Colors.blue, size: 18),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order['user']?['name'] ?? 'Guest', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                          Text(DateFormat('MMM dd').format(DateTime.parse(order['createdAt'])), style: TextStyle(color: AppColors.getSecondaryTextColor(isDark), fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('₹${order['amount'] ?? order['total']}', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStockAlerts(List items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.read<NavigationProvider>().setSelectedIndex(1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Stock Alerts', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppColors.textDark)),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            const Center(child: Text('All items in stock', style: TextStyle(color: Colors.grey, fontSize: 12)))
          else
            ...items.take(3).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  Text('${item['stock']} left', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            )),
        ],
      ),
    );
  }
}
