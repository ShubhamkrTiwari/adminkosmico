import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/notification_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user.dart'; // Add this line

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: !isDesktop 
          ? FloatingActionButton.extended(
              onPressed: () => _showComposeDialog(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              label: const Text('Send New', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.15),
              const Color(0xFFF4F7F4),
              Colors.white,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDesktop),
              const SizedBox(height: 32),
              Expanded(child: _buildNotificationHistory()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Push Notifications', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Broadcast and track system messages', style: TextStyle(color: AppColors.textLight)),
          ],
        ),
        if (isDesktop)
          ElevatedButton.icon(
            onPressed: () => _showComposeDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Broadcast'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(180, 50)),
          ),
      ],
    );
  }

  Widget _buildNotificationHistory() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No notifications sent yet', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: Material(
            color: Colors.transparent,
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: provider.notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
              itemBuilder: (context, index) {
                final n = provider.notifications[index];
                final notificationId = n['_id']?.toString() ?? '';

                return Dismissible(
                  key: Key(notificationId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await _showDeleteConfirm(n);
                  },
                  onDismissed: (direction) {
                    provider.deleteNotification(notificationId);
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 20),
                    ),
                    title: Text(n['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n['message'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, hh:mm a').format(DateTime.parse(n['createdAt'])),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                    trailing: Consumer<UserProvider>(
                      builder: (context, userProvider, _) {
                        final targetId = (n['audience'] ?? n['user'] ?? '').toString();
                        String displayName = targetId.toUpperCase();
                        
                        if (targetId == 'all') {
                          displayName = 'ALL USERS';
                        } else if (targetId == 'active') {
                          displayName = 'ACTIVE ONLY';
                        } else {
                          // Find user name from provider list
                          final user = userProvider.users.firstWhere(
                            (u) => u.id == targetId,
                            orElse: () => User(id: '', name: '', email: '', accountStatus: '', isAdmin: false),
                          );
                          if (user.name.isNotEmpty) {
                            displayName = user.name.toUpperCase();
                          } else if (targetId.length > 8) {
                            displayName = 'USER: ${targetId.substring(targetId.length - 6).toUpperCase()}';
                          }
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            displayName,
                            style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showComposeDialog() {
    showDialog(
      context: context,
      builder: (context) => const ComposeNotificationDialog(),
    );
  }

  Future<bool?> _showDeleteConfirm(dynamic notification) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: Text('Are you sure you want to delete "${notification['title']}"? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class ComposeNotificationDialog extends StatefulWidget {
  const ComposeNotificationDialog({super.key});

  @override
  State<ComposeNotificationDialog> createState() => _ComposeNotificationDialogState();
}

class _ComposeNotificationDialogState extends State<ComposeNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _imageController = TextEditingController();
  String _targetUser = 'all';
  String _type = 'info';

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send Push Notification'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                items: ['info', 'promo', 'alert', 'update']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? 'info'),
                decoration: const InputDecoration(labelText: 'Notification Type'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Notification Title', hintText: 'e.g. Flash Sale!'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Message Body', hintText: 'Enter your message here...'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: 'Image URL (Optional)', hintText: 'https://...'),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Target User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(height: 8),
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  return DropdownButtonFormField<String>(
                    value: ['all', 'active'].contains(_targetUser) ? _targetUser : null,
                    decoration: const InputDecoration(
                      labelText: 'Select Recipient',
                      hintText: 'All Users',
                    ),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('All Users (Broadcast)')),
                      const DropdownMenuItem(value: 'active', child: Text('Active Users Only')),
                      ...userProvider.users.map((u) => DropdownMenuItem(
                        value: u.id,
                        child: Text(u.name),
                      )),
                    ],
                    onChanged: (v) => setState(() => _targetUser = v ?? 'all'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: context.watch<NotificationProvider>().isLoading 
            ? null 
            : () async {
                if (_formKey.currentState!.validate()) {
                  final provider = context.read<NotificationProvider>();
                  
                  final success = await provider.sendNotification({
                    'user': _targetUser,
                    'title': _titleController.text,
                    'message': _messageController.text,
                    'image': _imageController.text,
                    'type': _type,
                  });
                  
                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification sent!'), backgroundColor: Colors.green),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to send notification. Check logs.'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
          child: context.watch<NotificationProvider>().isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Send Now'),
        ),
      ],
    );
  }
}
