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
  String? _selectedStatus;

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
      decoration: BoxDecoration(gradient: AppColors.getSubtleGradient(Theme.of(context).brightness == Brightness.dark)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Management', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
        Text('Track and process customer orders', style: TextStyle(color: AppColors.getSecondaryTextColor(isDark))),
      ],
    );
  }

  Widget _buildFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButton<String>(
      hint: Text('All Status', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
      value: _selectedStatus,
      underline: const SizedBox(),
      dropdownColor: isDark ? Colors.grey[900] : Colors.white,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      items: [null, 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled']
          .map((s) => DropdownMenuItem<String>(
                value: s,
                child: Text(s ?? 'All Status'),
              ))
          .toList(),
      onChanged: (v) {
        setState(() => _selectedStatus = v);
      },
    );
  }

  Widget _buildOrderTable() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        
        final filteredOrders = provider.orders.where((o) {
          final matchesSearch = o.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                               o.userName.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesStatus = _selectedStatus == null || 
                               o.status.toLowerCase() == _selectedStatus!.toLowerCase();
          return matchesSearch && matchesStatus;
        }).toList();

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
                  color: Theme.of(context).cardColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
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
                    Expanded(
                      child: Text(
                        o.userName, 
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(o.createdAt),
                      style: TextStyle(color: AppColors.getSecondaryTextColor(isDark), fontSize: 12),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Amount', style: TextStyle(color: AppColors.getSecondaryTextColor(isDark), fontSize: 11)),
                          Text(
                            '₹${o.total}', 
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : AppColors.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _buildStatusChip(o.paymentStatus),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded),
                          padding: EdgeInsets.zero,
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Details', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('#${o.id.toUpperCase()}', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                    ],
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(height: 32),
              _buildDetailRow('Customer', o.userName),
              _buildDetailRow('Status', o.status.toUpperCase()),
              _buildDetailRow('Amount', '₹${o.total}'),
              _buildDetailRow('Payment', o.paymentStatus.toUpperCase()),
              _buildDetailRow('Date', DateFormat('MMM dd, yyyy').format(o.createdAt)),
              
              const SizedBox(height: 24),
              Text('Logistics (Shiprocket)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildShiprocketAction(
                    label: 'Create Order',
                    icon: Icons.add_business_rounded,
                    color: Colors.blue,
                    onTap: () => _handleShiprocketAction(o.id, 'create'),
                  ),
                  _buildShiprocketAction(
                    label: 'Track',
                    icon: Icons.track_changes_rounded,
                    color: Colors.orange,
                    onTap: () => _handleShiprocketAction(o.id, 'track'),
                  ),
                  _buildShiprocketAction(
                    label: 'Cancel',
                    icon: Icons.cancel_outlined,
                    color: Colors.red,
                    onTap: () => _handleShiprocketAction(o.id, 'cancel'),
                  ),
                  _buildShiprocketAction(
                    label: 'Return',
                    icon: Icons.keyboard_return_rounded,
                    color: Colors.purple,
                    onTap: () => _handleShiprocketAction(o.id, 'return'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.getSecondaryTextColor(Theme.of(context).brightness == Brightness.dark))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildShiprocketAction({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleShiprocketAction(String id, String action) async {
    final provider = context.read<OrderProvider>();
    Map<String, dynamic> result;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Processing $action...')));

    switch (action) {
      case 'create': result = await provider.createShiprocketOrder(id); break;
      case 'cancel': result = await provider.cancelShiprocketOrder(id); break;
      case 'return': result = await provider.returnShiprocketOrder(id); break;
      case 'track':
        result = await provider.trackShiprocketOrder(id);
        if (result['success']) {
          _showTrackingInfo(result['data']);
          return;
        }
        break;
      default: return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? (result['success'] ? 'Success' : 'Failed')),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showTrackingInfo(dynamic data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tracking Info'),
        content: Text(data.toString()), // Simple for now, can be improved
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
