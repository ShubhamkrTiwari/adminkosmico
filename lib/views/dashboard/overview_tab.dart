import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/dashboard_provider.dart';
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
                                  color: AppColors.textDark,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildHeaderAction(Icons.notifications_none_rounded, () {}),
                        const SizedBox(width: 12),
                        _buildHeaderAction(Icons.search_rounded, () {}),
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
                        trend: '+12.5%',
                      ),
                      StatCard(
                        title: 'Total Orders',
                        value: (stats?['totalOrders'] ?? 0).toString(),
                        icon: Icons.local_mall_rounded,
                        color: const Color(0xFF1565C0),
                        trend: '+8.2%',
                      ),
                      StatCard(
                        title: 'Customers',
                        value: (stats?['totalUsers'] ?? 0).toString(),
                        icon: Icons.group_rounded,
                        color: const Color(0xFFE65100),
                      ),
                      StatCard(
                        title: 'Notifications',
                        value: (stats?['totalNotifications'] ?? 0).toString(),
                        icon: Icons.campaign_rounded,
                        color: const Color(0xFF6A1B9A),
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
        );
      },
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.textDark, size: 22),
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
          Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context, List salesData) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
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
              Text('Monthly Growth', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textLight)),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Orders', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
            ],
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
                          Text(order['user']?['name'] ?? 'Guest', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(DateFormat('MMM dd').format(DateTime.parse(order['createdAt'])), style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('₹${order['amount'] ?? order['total']}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStockAlerts(List items) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stock Alerts', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
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
