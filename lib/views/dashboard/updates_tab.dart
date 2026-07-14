import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          Expanded(child: _buildUpdateList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderText(),
              _buildPublishButton(),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderText(),
              const SizedBox(height: 16),
              _buildPublishButton(),
            ],
          );
        }
      },
    );
  }

  Widget _buildHeaderText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Release Management', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
        Text('Manage app versions and maintenance announcements', style: TextStyle(color: AppColors.textLight)),
      ],
    );
  }

  Widget _buildPublishButton() {
    return ElevatedButton.icon(
      onPressed: () => _showUpdateDialog(),
      icon: const Icon(Icons.cloud_upload_outlined),
      label: const Text('Publish Update'),
    );
  }

  Widget _buildUpdateList() {
    return Consumer<UpdateProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        if (provider.updates.isEmpty) return const Center(child: Text('No updates published yet'));

        return ListView.builder(
          itemCount: provider.updates.length,
          itemBuilder: (context, index) {
            final update = provider.updates[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                title: Row(
                  children: [
                    Text(update['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text('v${update['version']}', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(update['notes'] ?? 'No notes provided', maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            );
          },
        );
      },
    );
  }

  void _showUpdateDialog() {
    // TODO: Implement Publish Update Dialog
  }
}
