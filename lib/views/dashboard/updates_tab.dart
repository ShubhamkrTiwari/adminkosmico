import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/update_provider.dart';

class UpdatesTab extends StatefulWidget {
  const UpdatesTab({super.key});

  @override
  State<UpdatesTab> createState() => _UpdatesTabState();
}

class _UpdatesTabState extends State<UpdatesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UpdateProvider>().fetchUpdates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: !isDesktop 
          ? FloatingActionButton.extended(
              onPressed: () => _showUpdateDialog(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.system_update_rounded, color: Colors.white),
              label: const Text('New Update', style: TextStyle(color: Colors.white)),
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
              Expanded(child: _buildUpdateList()),
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
            Text('App Updates', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Force maintenance or publish new versions', style: TextStyle(color: AppColors.textLight)),
          ],
        ),
        if (isDesktop)
          ElevatedButton.icon(
            onPressed: () => _showUpdateDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Publish Update'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(180, 50)),
          ),
      ],
    );
  }

  Widget _buildUpdateList() {
    return Consumer<UpdateProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.updates.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.updates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.update_disabled_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No updates published yet', style: TextStyle(color: Colors.grey)),
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
              itemCount: provider.updates.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
              itemBuilder: (context, index) {
                final update = provider.updates[index];
                final isMaintenance = update['type'] == 'maintenance';
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (isMaintenance ? Colors.orange : AppColors.primary).withOpacity(0.1),
                    child: Icon(
                      isMaintenance ? Icons.engineering_rounded : Icons.system_update_rounded, 
                      color: isMaintenance ? Colors.orange : AppColors.primary, 
                      size: 20
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(update['title'] ?? 'Update', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('v${update['version']}', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(update['releaseNotes'] ?? update['notes'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(DateTime.parse(update['createdAt'])),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isMaintenance ? Colors.red : Colors.blue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (update['type'] ?? 'Feature').toString().toUpperCase(),
                      style: TextStyle(
                        color: isMaintenance ? Colors.red : Colors.blue, 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold
                      ),
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

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => const PublishUpdateDialog(),
    );
  }
}

class PublishUpdateDialog extends StatefulWidget {
  const PublishUpdateDialog({super.key});

  @override
  State<PublishUpdateDialog> createState() => _PublishUpdateDialogState();
}

class _PublishUpdateDialogState extends State<PublishUpdateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _versionController = TextEditingController();
  final _notesController = TextEditingController();
  String _type = 'feature';

  @override
  void dispose() {
    _titleController.dispose();
    _versionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Publish App Update'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                items: [
                  {'val': 'feature', 'label': 'New Feature'},
                  {'val': 'fix', 'label': 'Bug Fix'},
                  {'val': 'maintenance', 'label': 'System Maintenance (Full Screen)'},
                ].map((t) => DropdownMenuItem(value: t['val'], child: Text(t['label']!))).toList(),
                onChanged: (v) => setState(() => _type = v ?? 'feature'),
                decoration: const InputDecoration(labelText: 'Update Type'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Server Maintenance'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _versionController,
                decoration: const InputDecoration(labelText: 'App Version', hintText: 'e.g. 1.0.2'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Update Details / Message'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              if (_type == 'maintenance')
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Maintenance type will block user access to the app with a full-screen message.',
                          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: context.watch<UpdateProvider>().isLoading 
            ? null 
            : () async {
                if (_formKey.currentState!.validate()) {
                  final success = await context.read<UpdateProvider>().createUpdate({
                    'title': _titleController.text,
                    'version': _versionController.text,
                    'type': _type.toUpperCase(), // Matches 'FEATURE', 'FIX', 'MAINTENANCE'
                    'releaseNotes': _notesController.text, // Sync with your JSON field
                    'isUpdateAvailable': true, // Added as per your JSON
                  });
                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Update published successfully!'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
          child: context.watch<UpdateProvider>().isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Publish Now'),
        ),
      ],
    );
  }
}
