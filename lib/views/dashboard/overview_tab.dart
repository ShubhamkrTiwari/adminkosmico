import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/notification_provider.dart';
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
          child: Material(
            color: const Color(0xFFF8FAF8), 
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, MMM dd').format(DateTime.now()),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Compact 2-column grid for Stats
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                    children: [
                      StatCard(
                        title: 'Revenue',
                        value: currencyFormat.format(stats?['totalRevenue'] ?? 0),
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.green,
                        trend: '+12%',
                      ),
                      StatCard(
                        title: 'Orders',
                        value: (stats?['totalOrders'] ?? 0).toString(),
                        icon: Icons.shopping_basket_rounded,
                        color: Colors.blue,
                        trend: '+5%',
                      ),
                      StatCard(
                        title: 'Customers',
                        value: (stats?['totalUsers'] ?? 0).toString(),
                        icon: Icons.people_alt_rounded,
                        color: Colors.orange,
                      ),
                      StatCard(
                        title: 'Alerts',
                        value: (stats?['totalNotifications'] ?? 0).toString(),
                        icon: Icons.notifications_active_rounded,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader('Sales Overview'),
                  const SizedBox(height: 16),
                  _buildSalesChart(context, salesData),
                  
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildSectionHeader('Stock Alerts')),
                      TextButton(onPressed: () {}, child: const Text('View All')),
                    ],
                  ),
                  _buildInventoryAlerts(context, lowStock),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader('Recent Activity'),
                  const SizedBox(height: 16),
                  _buildRecentOrdersSection(context, recentOrders),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildResponsiveGrid(BuildContext context, List<Widget> children) {
    double width = MediaQuery.of(context).size.width;
    int crossAxisCount = width > 1200 ? 4 : (width > 600 ? 2 : 1);
    
    // Adjusting aspect ratio to make cards less tall on mobile
    double aspectRatio = width > 1200 ? 1.6 : (width > 800 ? 1.8 : 2.2);
    
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: aspectRatio,
      children: children,
    );
  }

  Widget _buildSalesChart(BuildContext context, List salesData) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sales Growth', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: salesData.isEmpty 
              ? const Center(child: Text('No sales data available'))
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: salesData.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), (e.value['total'] as num).toDouble());
                        }).toList(),
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 4,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withOpacity(0.1),
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

  Widget _buildInventoryAlerts(BuildContext context, List items) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Low Stock Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Center(child: Text('No inventory issues', style: TextStyle(color: Colors.grey)))
          else
            ...items.take(5).map((item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: Text(
                '${item['stock']} left',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection(BuildContext context, List orders) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              TextButton(onPressed: () {}, child: const Text('View All Transactions')),
            ],
          ),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No recent orders')))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                horizontalMargin: 0,
                columnSpacing: 40,
                columns: const [
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Date')),
                ],
                rows: orders.take(10).map((order) {
                  return DataRow(cells: [
                    DataCell(Text(order['user']?['name'] ?? 'Guest')),
                    DataCell(Text('₹${order['amount'] ?? order['total']}')),
                    DataCell(_buildStatusBadge(order['orderStatus'] ?? order['status'])),
                    DataCell(Text(DateFormat('MMM dd').format(DateTime.parse(order['createdAt'])))),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'delivered': color = Colors.green; break;
      case 'pending': color = Colors.orange; break;
      case 'processing': color = Colors.blue; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
