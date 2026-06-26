import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/providers/settings_providers.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';

class PreferencesView extends ConsumerStatefulWidget {
  const PreferencesView({super.key});

  @override
  ConsumerState<PreferencesView> createState() => _PreferencesViewState();
}

class _PreferencesViewState extends ConsumerState<PreferencesView> {
  final _seoTitleController = TextEditingController();
  final _seoDescriptionController = TextEditingController();
  final _gaTrackingIdController = TextEditingController();
  final _storePasswordController = TextEditingController();
  
  bool _isPasswordEnabled = false;
  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  void dispose() {
    _seoTitleController.dispose();
    _seoDescriptionController.dispose();
    _gaTrackingIdController.dispose();
    _storePasswordController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences(dynamic currentSettings) async {
    setState(() => _isSaving = true);
    
    // Merge new config items with existing config
    final config = Map<String, dynamic>.from(currentSettings.config ?? {});
    config['seo_homepage_title'] = _seoTitleController.text;
    config['seo_homepage_description'] = _seoDescriptionController.text;
    config['google_analytics_id'] = _gaTrackingIdController.text;
    config['password_protection_enabled'] = _isPasswordEnabled;
    config['storefront_password'] = _storePasswordController.text;

    try {
      await ref.read(apiServiceProvider).updateTenantSettings({
        'name': currentSettings.name,
        'config': config,
      });
      ref.invalidate(tenantSettingsProvider);
      _showSuccess('Preferences saved successfully!');
    } catch (e) {
      _showError('Error saving preferences: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.brandEmerald600, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(tenantSettingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: settingsAsync.when(
        data: (settings) {
          if (!_isLoaded) {
            final cfg = settings.config;
            _seoTitleController.text = cfg['seo_homepage_title'] as String? ?? '';
            _seoDescriptionController.text = cfg['seo_homepage_description'] as String? ?? '';
            _gaTrackingIdController.text = cfg['google_analytics_id'] as String? ?? '';
            _isPasswordEnabled = cfg['password_protection_enabled'] as bool? ?? false;
            _storePasswordController.text = cfg['storefront_password'] as String? ?? '';
            _isLoaded = true;
          }

          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.8) : Colors.white.withOpacity(0.9),
                  border: Border(bottom: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preferences',
                            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Configure storefront SEO details, analytics accounts, and visitor password gates.',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    HoverScale(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : () => _savePreferences(settings),
                        icon: _isSaving 
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(LucideIcons.save, size: 14),
                        label: const Text('Save Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandEmerald500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Settings Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // SEO Section Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.searchCode, color: AppTheme.brandEmerald500),
                                  const SizedBox(width: 12),
                                  Text('Storefront SEO (Search Engine Optimization)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Define the default title and meta description search engines show for your homepage.', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _seoTitleController,
                                decoration: const InputDecoration(
                                  labelText: 'Homepage Title',
                                  border: OutlineInputBorder(),
                                  hintText: 'Acme Co - Premium Clothing & Accessories',
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _seoDescriptionController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Homepage Meta Description',
                                  border: OutlineInputBorder(),
                                  hintText: 'Shop the finest selection of hand-crafted apparel, accessories, and organic outdoor gear with worldwide delivery.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Google Analytics Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.barChart3, color: AppTheme.brandEmerald500),
                                  const SizedBox(width: 12),
                                  Text('Google Analytics', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Track visitor traffic and e-commerce conversions on your storefront.', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                              const SizedBox(height: 24),
                              TextField(
                                controller: _gaTrackingIdController,
                                decoration: const InputDecoration(
                                  labelText: 'Google Analytics Measurement ID',
                                  border: OutlineInputBorder(),
                                  hintText: 'G-XXXXXXXXXX',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Storefront Password Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.lock, color: AppTheme.brandEmerald500),
                                  const SizedBox(width: 12),
                                  Text('Storefront Password Protection', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Restrict public storefront access with a password gate page. Visitors must enter the password to view your shop.', style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                              const SizedBox(height: 20),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Enable Password Protection', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                value: _isPasswordEnabled,
                                activeColor: AppTheme.brandEmerald500,
                                onChanged: (val) => setState(() => _isPasswordEnabled = val),
                              ),
                              if (_isPasswordEnabled) ...[
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _storePasswordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Visitor Entry Password',
                                    border: OutlineInputBorder(),
                                    hintText: 'Enter storefront access password',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Failed to load settings: $e')),
      ),
    );
  }
}
