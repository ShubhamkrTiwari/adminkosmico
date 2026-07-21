import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../providers/dashboard_provider.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<OrderProvider>().orders.isEmpty) {
        context.read<DashboardProvider>().fetchDashboardData(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.subtleGradient),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildFilters(),
              const SizedBox(height: 24),
              Expanded(child: _buildOrderTable()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Management', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
        Text('Track and process customer orders', style: TextStyle(color: AppColors.textLight)),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Row(
              children: [
                Expanded(child: _buildSearchField()),
                const VerticalDivider(),
                _buildStatusDropdown(),
              ],
            );
          } else {
            return Column(
              children: [
                _buildSearchField(),
                const Divider(),
                _buildStatusDropdown(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Search by Order ID or Phone...',
        prefixIcon: Icon(Icons.search_rounded),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      onChanged: (v) => setState(() => _searchQuery = v),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButton<String>(
      hint: const Text('All Status'),
      underline: const SizedBox(),
      items: ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled']
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (v) {},
    );
  }

  Widget _buildOrderTable() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        
        final filteredOrders = provider.orders.where((o) => 
          o.id.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        if (filteredOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No orders found', style: TextStyle(color: Colors.black54, fontSize: 16)),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      horizontalMargin: 24,
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text('Order ID')),
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Total')),
                        DataColumn(label: Text('Payment')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: filteredOrders.map((o) => _buildDataRow(o)).toList(),
                    ),
                  ),
                ),
              );
            } else {
              return ListView.builder(
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) => _buildOrderMobileCard(filteredOrders[index]),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildOrderMobileCard(Order o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOrderDetails(o),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${o.id.substring(o.id.length - 6).toUpperCase()}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    _buildStatusChip(o.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(o.userName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(o.createdAt),
                      style: TextStyle(color: AppColors.textLight, fontSize: 12),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Amount', style: TextStyle(color: AppColors.textLight, fontSize: 11)),
                        Text('₹${o.total}', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
                      ],
                    ),
                    Row(
                      children: [
                        _buildStatusChip(o.paymentStatus),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded),
                          onSelected: (status) => context.read<OrderProvider>().updateOrderStatus(o.id, status),
                          itemBuilder: (context) => [
                            'Processing', 'Shipped', 'Delivered', 'Cancelled'
                          ].map((s) => PopupMenuItem(value: s.toLowerCase(), child: Text('Mark as $s'))).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(Order o) {
    return DataRow(cells: [
      DataCell(Text('#${o.id.substring(o.id.length - 6).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text(o.userName)),
      DataCell(Text('₹${o.total}')),
      DataCell(_buildStatusChip(o.paymentStatus)),
      DataCell(_buildStatusChip(o.status)),
      DataCell(Text(DateFormat('MMM dd, yyyy').format(o.createdAt))),
      DataCell(
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined, size: 20),
              onPressed: () => _showOrderDetails(o),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              onSelected: (status) => context.read<OrderProvider>().updateOrderStatus(o.id, status),
              itemBuilder: (context) => [
                'Processing', 'Shipped', 'Delivered', 'Cancelled'
              ].map((s) => PopupMenuItem(value: s.toLowerCase(), child: Text('Mark as $s'))).toList(),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'delivered': case 'completed': color = Colors.green; break;
      case 'pending': color = Colors.orange; break;
      case 'processing': color = Colors.blue; break;
      case 'cancelled': case 'failed': color = Colors.red; break;
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
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showOrderDetails(Order o) {
    // TODO: Implement Detailed Order Modal
  }
}
