import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../providers/dashboard_provider.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<UserProvider>().users.isEmpty) {
        context.read<DashboardProvider>().fetchDashboardData(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.getSubtleGradient(isDark),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildSearchField(),
            const SizedBox(height: 24),
            Expanded(child: _buildUserList()),
          ],
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
        Text('Customer Management', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
        Text('View and manage registered customers', style: TextStyle(color: AppColors.getSecondaryTextColor(isDark))),
      ],
    );
  }

  Widget _buildSearchField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search by Name, Email or Phone...',
          prefixIcon: Icon(Icons.search_rounded),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildUserList() {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        
        final filteredUsers = provider.users.where((u) {
          final matchesName = u.name.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesEmail = u.email.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchesName || matchesEmail;
        }).toList();

        if (filteredUsers.isEmpty) return const Center(child: Text('No users found'));

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: Material(
            color: Colors.transparent,
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: filteredUsers.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return ListTile(
                  onTap: () => _showUserDetails(user),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: user.profilePic != null && user.profilePic!.isNotEmpty
                        ? CachedNetworkImageProvider(user.profilePic!)
                        : null,
                    child: user.profilePic == null || user.profilePic!.isEmpty
                        ? Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase(), 
                            style: const TextStyle(color: AppColors.primary))
                        : null,
                  ),
                  title: Text(user.name, 
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                  subtitle: Text(user.email, overflow: TextOverflow.ellipsis),
                  trailing: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildStatusBadge(user.accountStatus),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (value) {
                          if (value == 'block') {
                            context.read<UserProvider>().toggleUserBlock(user.id);
                          } else if (value == 'delete') {
                            _showDeleteConfirm(user);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'block', 
                            child: Text(user.accountStatus == 'blocked' ? 'Unblock User' : 'Block User')
                          ),
                          const PopupMenuItem(
                            value: 'delete', 
                            child: Text('Delete User', style: TextStyle(color: Colors.redAccent))
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'active' ? Colors.green : Colors.red;
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

  void _showUserDetails(User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: FutureBuilder<Map<String, dynamic>?>(
            future: context.read<UserProvider>().fetchUserDetails(user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final data = snapshot.data;
              final userDetails = data?['user'];
              final shoppingSummary = data?['shoppingSummary'];
              final recentOrders = data?['recentOrders'] as List? ?? [];

              return ListView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  
                  // Profile Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primary.withOpacity(0.05),
                          backgroundImage: user.profilePic != null && user.profilePic!.isNotEmpty
                              ? CachedNetworkImageProvider(user.profilePic!)
                              : null,
                          child: user.profilePic == null || user.profilePic!.isEmpty
                              ? Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase(), 
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary))
                              : null,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userDetails?['name'] ?? user.name, 
                              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              userDetails?['email'] ?? user.email, 
                              style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            _buildStatusBadge(userDetails?['isBlocked'] == true ? 'blocked' : 'active'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  Text('Contact Information', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 20),
                  _buildInfoTile(Icons.phone_outlined, 'Phone Number', userDetails?['phoneNumber'] ?? 'Not provided'),
                  _buildInfoTile(Icons.calendar_today_outlined, 'Joined On', 
                      userDetails?['createdAt'] != null 
                        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(userDetails!['createdAt']))
                        : 'Unknown'),
                  
                  const SizedBox(height: 32),
                  Text('Shopping Summary', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatBox('Total Orders', '${shoppingSummary?['totalOrders'] ?? 0}'),
                      const SizedBox(width: 16),
                      _buildStatBox('Total Spend', '₹${shoppingSummary?['totalSpend'] ?? 0}'),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Orders', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
                      TextButton(
                        onPressed: () => _showAllOrders(user.id, user.name), 
                        child: const Text('View All', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  if (recentOrders.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(child: Text('No orders yet', style: TextStyle(color: Colors.grey))),
                    )
                  else
                    ...recentOrders.take(5).map((o) => _buildOrderTile(o)),
                  
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: Colors.blueGrey.shade700),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
              Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.blueGrey.shade900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTile(Map<String, dynamic> o) {
    final orderId = o['_id'].toString();
    final displayId = orderId.length > 8 ? orderId.substring(orderId.length - 8).toUpperCase() : orderId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.shopping_bag_outlined, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #$displayId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(o['createdAt'])), 
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${o['amount'] ?? o['total']}', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (o['orderStatus'] == 'Delivered' ? Colors.green : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  (o['orderStatus'] ?? 'Pending').toString().toUpperCase(),
                  style: TextStyle(
                    color: o['orderStatus'] == 'Delivered' ? Colors.green : Colors.orange,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAllOrders(String userId, String userName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order History', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(userName, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: context.read<UserProvider>().fetchUserOrders(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final orders = snapshot.data ?? [];
                    if (orders.isEmpty) return const Center(child: Text('No orders found'));

                    return ListView.builder(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: orders.length,
                      itemBuilder: (context, index) => _buildOrderTile(orders[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<UserProvider>().deleteUser(user.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
