import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/maintenance_provider.dart';

class MaintenanceTab extends StatefulWidget {
  const MaintenanceTab({super.key});

  @override
  State<MaintenanceTab> createState() => _MaintenanceTabState();
}

class _MaintenanceTabState extends State<MaintenanceTab> {
  final _messageController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    final provider = context.read<MaintenanceProvider>();
    await provider.fetchMaintenanceStatus();
    if (mounted) {
      setState(() {
        _messageController.text = provider.message;
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<MaintenanceProvider>().isLoading;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('System Maintenance', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Control app accessibility and maintenance state', style: TextStyle(color: AppColors.textLight)),
              const SizedBox(height: 32),
              _buildMaintenanceCard(),
            ],
          ),
        ),
        if (isLoading && !_isInitialized)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildMaintenanceCard() {
    return Consumer<MaintenanceProvider>(
      builder: (context, provider, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (provider.isMaintenanceMode ? Colors.red : Colors.green).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      provider.isMaintenanceMode ? Icons.engineering_rounded : Icons.check_circle_outline_rounded,
                      color: provider.isMaintenanceMode ? Colors.red : Colors.green,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Maintenance Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(
                          provider.isMaintenanceMode 
                              ? 'Currently ACTIVE - Users cannot access the app' 
                              : 'Currently INACTIVE - App is live for all users',
                          style: TextStyle(
                            color: provider.isMaintenanceMode ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: provider.isMaintenanceMode,
                    activeColor: AppColors.primary,
                    onChanged: provider.isLoading ? null : (value) => _showConfirmToggle(value),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),
              const Text('Maintenance Message', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter message to show to users during maintenance...',
                  fillColor: Colors.grey.shade50,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: provider.isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded),
                  onPressed: provider.isLoading 
                    ? null 
                    : () async {
                        final success = await provider.toggleMaintenanceMode(
                          provider.isMaintenanceMode, 
                          _messageController.text
                        );
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Settings saved successfully!'), 
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                  label: Text(provider.isLoading ? 'Processing...' : 'Save Settings'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmToggle(bool newValue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newValue ? 'Activate Maintenance?' : 'Deactivate Maintenance?'),
        content: Text(newValue 
            ? 'Activating maintenance will block all users from using the app. Only admins will have access.' 
            : 'This will make the app live for all users again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<MaintenanceProvider>().toggleMaintenanceMode(newValue, _messageController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: newValue ? Colors.red : AppColors.primary),
            child: Text(newValue ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );
  }
}
