import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/notification_provider.dart';

class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _imageController = TextEditingController();
  String _audience = 'all';

  void _handleSend() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<NotificationProvider>().sendNotification({
        'title': _titleController.text,
        'message': _messageController.text,
        'image': _imageController.text,
        'audience': _audience,
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent successfully!'), backgroundColor: Colors.green),
        );
        _titleController.clear();
        _messageController.clear();
        _imageController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Push Notifications', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Broadcast messages to your customers', style: TextStyle(color: AppColors.textLight)),
          const SizedBox(height: 32),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Compose Notification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g., Special Offer!'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Message', hintText: 'Enter notification content...'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageController,
                      decoration: const InputDecoration(labelText: 'Image URL (Optional)', hintText: 'https://example.com/image.jpg'),
                    ),
                    const SizedBox(height: 24),
                    const Text('Target Audience', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildAudienceOption('all', 'All Users'),
                        _buildAudienceOption('active', 'Active Only'),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Consumer<NotificationProvider>(
                      builder: (context, provider, _) {
                        return ElevatedButton.icon(
                          onPressed: provider.isLoading ? null : _handleSend,
                          icon: const Icon(Icons.send_rounded),
                          label: provider.isLoading 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text('Send Broadcast'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceOption(String value, String label) {
    final isSelected = _audience == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _audience = value);
      },
      selectedColor: AppColors.primary.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textLight,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
