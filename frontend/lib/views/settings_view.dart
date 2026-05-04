import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/providers/settings_providers.dart';
import 'package:intl/intl.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(tenantSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Store Settings')),
      body: settingsAsync.when(
        data: (settings) => SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context,
                title: 'General Information',
                icon: LucideIcons.info,
                children: [
                  _buildReadOnlyField(context, 'Store ID', settings.id),
                  _buildEditableField(context, 'Store Name', settings.name),
                  _buildReadOnlyField(context, 'Created On', DateFormat('MMMM dd, yyyy').format(settings.createdAt)),
                ],
              ),
              const SizedBox(height: 32),
              _buildSection(
                context,
                title: 'Infrastructure (GCP)',
                icon: LucideIcons.cloud,
                children: [
                  _buildReadOnlyField(context, 'Project ID', settings.gcpProjectId ?? 'Not set'),
                  _buildReadOnlyField(context, 'Asset Bucket', settings.gcpBucketName ?? 'Not set'),
                ],
              ),
              const SizedBox(height: 32),
              _buildSection(
                context,
                title: 'Localization',
                icon: LucideIcons.languages,
                children: [
                  _buildReadOnlyField(context, 'Primary Locale', settings.supportedLocales.first),
                  _buildReadOnlyField(context, 'Supported', settings.supportedLocales.join(', ')),
                ],
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {}, // TODO: Save changes
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Settings'),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.primaryColor),
            const SizedBox(width: 12),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEditableField(BuildContext context, String label, String initialValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          SizedBox(
            width: 300,
            child: TextFormField(
              initialValue: initialValue,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
