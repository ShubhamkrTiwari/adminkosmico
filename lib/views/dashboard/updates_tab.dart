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
    final provider = context.watch<UpdateProvider>();
    final hasUpdate = provider.currentUpdate != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: !isDesktop && !hasUpdate
          ? FloatingActionButton.extended(
              onPressed: () => _showUpdateDialog(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.system_update_rounded, color: Colors.white),
              label: const Text('New Update', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.getSubtleGradient(Theme.of(context).brightness == Brightness.dark),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDesktop, hasUpdate),
              const SizedBox(height: 32),
              Expanded(child: _buildUpdateList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop, bool hasUpdate) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Updates', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
            Text('Manage active version and publish new updates', style: TextStyle(color: AppColors.getSecondaryTextColor(isDark))),
          ],
        ),
        if (isDesktop && !hasUpdate)
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
        if (provider.isLoading && provider.currentUpdate == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final update = provider.currentUpdate;

        if (update == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.update_disabled_rounded, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  provider.error != null ? 'Error: ${provider.error}' : 'No active update published yet',
                  style: TextStyle(color: provider.error != null ? Colors.red : Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => provider.fetchUpdates(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isMaintenance = update['type'] == 'maintenance' || update['type'] == 'MAINTENANCE';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: (isMaintenance ? Colors.orange : AppColors.primary).withOpacity(0.1),
                    child: Icon(
                      isMaintenance ? Icons.engineering_rounded : Icons.system_update_rounded, 
                      color: isMaintenance ? Colors.orange : AppColors.primary, 
                      size: 20
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(update['title'] ?? 'Update', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('v${update['version']}', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          update['publishedAt'] != null 
                              ? 'Published: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(update['publishedAt']))}' 
                              : '',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (update['isUpdateAvailable'] ?? true) ? 'On' : 'Off',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: (update['isUpdateAvailable'] ?? true) ? Colors.green : Colors.grey,
                        ),
                      ),
                      Switch.adaptive(
                        value: update['isUpdateAvailable'] ?? true,
                        onChanged: (val) {
                          context.read<UpdateProvider>().toggleUpdateStatus(val);
                        },
                        activeColor: AppColors.primary,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Remove Update'),
                              content: const Text('Are you sure you want to remove this active update? Users will no longer see the update prompt.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    context.read<UpdateProvider>().deleteUpdate();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text('Release Notes / Message:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              Text(
                update['releaseNotes'] ?? update['notes'] ?? '',
                style: const TextStyle(fontSize: 14),
              ),
              if (update['playStoreUrl'] != null && update['playStoreUrl'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Play Store URL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  update['playStoreUrl'],
                  style: const TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
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
  final _titleController = TextEditingController(text: 'New Update Available');
  final _versionController = TextEditingController(text: '1.0.8');
  final _notesController = TextEditingController(text: 'A new version of the app is available. Please update. If you have already updated, you can ignore this message.');
  final _playStoreUrlController = TextEditingController(text: 'https://play.google.com/store/apps/details?id=com.kosmico.wellness');
  String _type = 'feature';

  @override
  void dispose() {
    _titleController.dispose();
    _versionController.dispose();
    _notesController.dispose();
    _playStoreUrlController.dispose();
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
                isExpanded: true,
                items: [
                  {'val': 'feature', 'label': 'New Feature'},
                  {'val': 'fix', 'label': 'Bug Fix'},
                  {'val': 'maintenance', 'label': 'Maintenance (Full Screen)'},
                ].map((t) => DropdownMenuItem(
                  value: t['val'], 
                  child: Text(
                    t['label']!,
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
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
                decoration: const InputDecoration(labelText: 'Update Details / Message (Release Notes)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _playStoreUrlController,
                decoration: const InputDecoration(labelText: 'Play Store URL', hintText: 'https://play.google.com/store/apps/details?id=...'),
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
                    'type': _type.toUpperCase(),
                    'releaseNotes': _notesController.text,
                    'playStoreUrl': _playStoreUrlController.text,
                    'isUpdateAvailable': true,
                  });
                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Update published successfully!'), backgroundColor: Colors.green),
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
