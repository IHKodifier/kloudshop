import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/providers/settings_providers.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:intl/intl.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(apiServiceProvider).updateTenantSettings({
        'name': _nameController.text,
      });
      if (!mounted) return;
      ref.invalidate(tenantSettingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving settings: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(tenantSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Store Settings')),
      body: settingsAsync.when(
        data: (settings) {
          if (_nameController.text.isEmpty && !_isSaving) {
            _nameController.text = settings.name;
          }
          return SingleChildScrollView(
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
                    _buildEditableField(context, 'Store Name', _nameController),
                    _buildReadOnlyField(
                      context, 
                      'Created On', 
                      DateFormat('MMMM dd, yyyy').format(settings.createdAt),
                    ),
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
                    _buildReadOnlyField(
                      context, 
                      'Primary Locale', 
                      settings.supportedLocales.isNotEmpty ? settings.supportedLocales.first : 'en',
                    ),
                    _buildReadOnlyField(
                      context, 
                      'Supported', 
                      settings.supportedLocales.isNotEmpty ? settings.supportedLocales.join(', ') : 'en',
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSection(
                  context,
                  title: 'Development & Demo',
                  icon: LucideIcons.beaker,
                  children: [
                    const Text('Populate your store with mock orders and customers for testing purposes.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeding demo data...')));
                          await ref.read(apiServiceProvider).seedDemoData();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store seeded successfully! Refresh listing grids to see changes.')));
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        }
                      },
                      icon: const Icon(LucideIcons.database),
                      label: const Text('Seed Demo Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shadowColor: theme.primaryColor.withValues(alpha: 0.3),
                      elevation: 10,
                    ),
                    child: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Settings'),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading store settings...'),
            ],
          ),
        ),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Failed to load settings: $e', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => ref.invalidate(tenantSettingsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
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
          Flexible(child: Text(label, style: const TextStyle(color: Colors.grey))),
          const SizedBox(width: 16),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEditableField(BuildContext context, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: const TextStyle(color: Colors.grey))),
          const SizedBox(width: 16),
          SizedBox(
            width: 300,
            child: TextFormField(
              controller: controller,
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
