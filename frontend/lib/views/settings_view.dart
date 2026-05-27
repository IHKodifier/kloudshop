import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/providers/settings_providers.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/providers/catalog_providers.dart';
import 'package:kloudshop/providers/analytics_providers.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';
import 'package:intl/intl.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _nameController = TextEditingController();
  final _senderEmailController = TextEditingController();
  final _accountEmailController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalController = TextEditingController();

  String _selectedIndustry = 'Luxury Apparel & Gear';
  String _selectedCurrency = 'USD';
  String _selectedTimezone = 'GMT-05:00 Eastern Time';
  String _selectedUnitSystem = 'Metric';

  bool _isSaving = false;
  late PageController _pageController;
  int _currentVariantIndex = 0;

  // Zurich Sidebar selection index
  int _zurichSidebarIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _senderEmailController.dispose();
    _accountEmailController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(apiServiceProvider).updateTenantSettings({
        'name': _nameController.text,
        'config': {
          'industry': _selectedIndustry,
          'currency': _selectedCurrency,
          'timezone': _selectedTimezone,
          'unit_system': _selectedUnitSystem,
          'sender_email': _senderEmailController.text,
          'account_email': _accountEmailController.text,
          'street_address': _streetController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'postal_code': _postalController.text,
        },
      });
      if (!mounted) return;
      ref.invalidate(tenantSettingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved successfully!'),
          backgroundColor: AppTheme.brandEmerald600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
          if (_nameController.text.isEmpty && !_isSaving) {
            _nameController.text = settings.name;
            final cfg = settings.config;
            _senderEmailController.text =
                cfg['sender_email'] as String? ?? 'notifications@kloudshop.com';
            _accountEmailController.text =
                cfg['account_email'] as String? ?? 'merchant@company.com';
            _streetController.text =
                cfg['street_address'] as String? ?? '1420 Alpine Heights Rd';
            _cityController.text = cfg['city'] as String? ?? 'Aspen';
            _stateController.text = cfg['state'] as String? ?? 'Colorado';
            _postalController.text = cfg['postal_code'] as String? ?? '81611';
            _selectedIndustry =
                cfg['industry'] as String? ?? 'Luxury Apparel & Gear';
            _selectedCurrency = cfg['currency'] as String? ?? 'USD';
            _selectedTimezone =
                cfg['timezone'] as String? ?? 'GMT-05:00 Eastern Time';
            _selectedUnitSystem = cfg['unit_system'] as String? ?? 'Metric';
          }
          return Column(
            children: [
              // Premium Design Variant Selector Header
              _buildVariantSelectorHeader(theme, isDark),

              // Swipable views container
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentVariantIndex = index;
                    });
                  },
                  children: [
                    _buildZurichSidebarLayout(theme, isDark, settings),
                    _buildBentoGridLayout(theme, isDark, settings),
                    _buildCompactMobileStackLayout(theme, isDark, settings),
                  ],
                ),
              ),

              // Sticky actions bar at the bottom
              _buildStickyActionsBar(theme, isDark),
            ],
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.brandEmerald500),
              const SizedBox(height: 16),
              Text(
                'Loading store settings...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        error: (e, s) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.alertCircle,
                    color: Color(0xFFEF4444),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load settings: $e',
                  textAlign: TextAlign.center,
                ),
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

  Widget _buildVariantSelectorHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.settings2,
                size: 24,
                color: AppTheme.brandEmerald500,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'General Configuration',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Preview design variants by clicking chips or swiping.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Horizontal slider / segment control
          Row(
            children: List.generate(3, (index) {
              final isSelected = _currentVariantIndex == index;
              final labels = ['Zurich Sidebar', 'Bento Grid', 'Mobile Stack'];
              final icons = [
                LucideIcons.sidebar,
                LucideIcons.layoutGrid,
                LucideIcons.smartphone,
              ];
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: HoverScale(
                  child: ChoiceChip(
                    avatar: Icon(
                      icons[index],
                      size: 14,
                      color: isSelected ? Colors.white : theme.hintColor,
                    ),
                    label: Text(labels[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _currentVariantIndex = index);
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                    selectedColor: AppTheme.brandEmerald500,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : theme.dividerColor,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Sticky Actions Bar
  Widget _buildStickyActionsBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.beaker,
                size: 16,
                color: Color(0xFFEC4899),
              ),
              const SizedBox(width: 8),
              Text(
                'Demo Utilities',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEC4899),
                ),
              ),
              const SizedBox(width: 16),
              HoverScale(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Seeding demo data...')),
                      );
                      await ref.read(apiServiceProvider).seedDemoData();
                      ref.invalidate(productsProvider);
                      ref.invalidate(analyticsOverviewProvider);
                      ref.invalidate(needsAttentionProvider);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Store seeded successfully!'),
                          backgroundColor: AppTheme.brandEmerald600,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: const Color(0xFFEF4444),
                        ),
                      );
                    }
                  },
                  icon: const Icon(LucideIcons.database, size: 14),
                  label: const Text(
                    'Seed Demo Data',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEC4899)),
                    foregroundColor: const Color(0xFFEC4899),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  ref.invalidate(tenantSettingsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Changes discarded.')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Discard'),
              ),
              const SizedBox(width: 12),
              HoverScale(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSettings,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(LucideIcons.save, size: 16),
                  label: const Text(
                    'Save Settings',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandEmerald500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- VARIANT 1: ZURICH SIDEBAR LAYOUT ---
  Widget _buildZurichSidebarLayout(
    ThemeData theme,
    bool isDark,
    tenantSettings,
  ) {
    final sidebarItems = [
      {'title': 'Store Details', 'icon': LucideIcons.store},
      {'title': 'Shipping & Regional', 'icon': LucideIcons.globe},
      {'title': 'Infrastructure', 'icon': LucideIcons.cloud},
      {'title': 'Communications', 'icon': LucideIcons.mail},
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left mini sidebar
        Container(
          width: 250,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withOpacity(0.5)
                : const Color(0xFFF9FAFB),
            border: Border(right: BorderSide(color: theme.dividerColor)),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: sidebarItems.length,
                  itemBuilder: (context, index) {
                    final item = sidebarItems[index];
                    final isSelected = _zurichSidebarIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: InkWell(
                        onTap: () =>
                            setState(() => _zurichSidebarIndex = index),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.brandEmerald500.withOpacity(
                                    isDark ? 0.15 : 0.08,
                                  )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item['icon'] as IconData,
                                size: 16,
                                color: isSelected
                                    ? AppTheme.brandEmerald500
                                    : theme.hintColor,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item['title'] as String,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppTheme.brandEmerald500
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Support specialist quick panel
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.brandEmerald500.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.brandEmerald500.withOpacity(0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expert Support',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandEmerald500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Need custom setup help?',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Contacting Specialist...'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandEmerald500,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Contact Support',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Right scrollable details area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildZurichPanelContent(theme, tenantSettings),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZurichPanelContent(ThemeData theme, tenantSettings) {
    switch (_zurichSidebarIndex) {
      case 0:
        return Column(
          key: const ValueKey(0),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PremiumSection(
              title: 'Store Details',
              icon: LucideIcons.store,
              children: [
                _ReadOnlyRow(label: 'Store ID', value: tenantSettings.id),
                const SizedBox(height: 16),
                _EditableRow(label: 'Store Name', controller: _nameController),
                const SizedBox(height: 16),
                _buildDropdownRow(
                  label: 'Store Industry',
                  value: _selectedIndustry,
                  items: const [
                    'Luxury Apparel & Gear',
                    'Home & Sustainable Living',
                    'High-Performance Technology',
                  ],
                  onChanged: (v) => setState(() => _selectedIndustry = v!),
                ),
                const SizedBox(height: 16),
                _ReadOnlyRow(
                  label: 'Created On',
                  value: DateFormat(
                    'MMMM dd, yyyy',
                  ).format(tenantSettings.createdAt),
                ),
              ],
            ),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PremiumSection(
              title: 'Shipping & Regional Standards',
              icon: LucideIcons.globe,
              accentColor: const Color(0xFFF59E0B),
              children: [
                _buildDropdownRow(
                  label: 'Primary Currency',
                  value: _selectedCurrency,
                  items: const ['USD', 'EUR', 'GBP', 'CHF'],
                  onChanged: (v) => setState(() => _selectedCurrency = v!),
                ),
                const SizedBox(height: 16),
                _buildDropdownRow(
                  label: 'Time Zone',
                  value: _selectedTimezone,
                  items: const [
                    'GMT-05:00 Eastern Time',
                    'GMT-08:00 Pacific Time',
                    'GMT+01:00 Central Europe',
                    'GMT+00:00 London',
                  ],
                  onChanged: (v) => setState(() => _selectedTimezone = v!),
                ),
                const SizedBox(height: 16),
                _buildDropdownRow(
                  label: 'Unit System',
                  value: _selectedUnitSystem,
                  items: const ['Metric', 'Imperial'],
                  onChanged: (v) => setState(() => _selectedUnitSystem = v!),
                ),
                const SizedBox(height: 16),
                _ReadOnlyRow(
                  label: 'Primary Locale',
                  value: tenantSettings.supportedLocales.isNotEmpty
                      ? tenantSettings.supportedLocales.first
                      : 'en',
                ),
              ],
            ),
          ],
        );
      case 2:
        return Column(
          key: const ValueKey(2),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PremiumSection(
              title: 'GCP Cloud Infrastructure',
              icon: LucideIcons.cloud,
              accentColor: const Color(0xFF6366F1),
              children: [
                _ReadOnlyRow(
                  label: 'Project ID',
                  value: tenantSettings.gcpProjectId ?? 'Not set',
                ),
                const SizedBox(height: 16),
                _ReadOnlyRow(
                  label: 'Asset Bucket',
                  value: tenantSettings.gcpBucketName ?? 'Not set',
                ),
              ],
            ),
          ],
        );
      case 3:
        return Column(
          key: const ValueKey(3),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PremiumSection(
              title: 'Communications & Notifications',
              icon: LucideIcons.mail,
              accentColor: const Color(0xFFEC4899),
              children: [
                _EditableRow(
                  label: 'Sender Email',
                  controller: _senderEmailController,
                ),
                const SizedBox(height: 16),
                _EditableRow(
                  label: 'Account Email',
                  controller: _accountEmailController,
                ),
              ],
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  // --- VARIANT 2: BENTO GRID LAYOUT ---
  Widget _buildBentoGridLayout(ThemeData theme, bool isDark, tenantSettings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.layoutGrid,
                size: 22,
                color: AppTheme.brandEmerald500,
              ),
              const SizedBox(width: 12),
              Text(
                'Bento Configuration Grid',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Layout grid cards
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              // 1. Store Details Bento Card
              _buildBentoCard(
                width: 500,
                title: 'Store Profile',
                icon: LucideIcons.store,
                color: AppTheme.brandEmerald500,
                theme: theme,
                isDark: isDark,
                children: [
                  _EditableRow(
                    label: 'Store Name',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownRow(
                    label: 'Industry',
                    value: _selectedIndustry,
                    items: const [
                      'Luxury Apparel & Gear',
                      'Home & Sustainable Living',
                      'High-Performance Technology',
                    ],
                    onChanged: (v) => setState(() => _selectedIndustry = v!),
                  ),
                ],
              ),

              // 2. Localization Bento Card
              _buildBentoCard(
                width: 450,
                title: 'Regional Options',
                icon: LucideIcons.globe,
                color: const Color(0xFFF59E0B),
                theme: theme,
                isDark: isDark,
                children: [
                  _buildDropdownRow(
                    label: 'Currency',
                    value: _selectedCurrency,
                    items: const ['USD', 'EUR', 'GBP', 'CHF'],
                    onChanged: (v) => setState(() => _selectedCurrency = v!),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownRow(
                    label: 'Timezone',
                    value: _selectedTimezone,
                    items: const [
                      'GMT-05:00 Eastern Time',
                      'GMT-08:00 Pacific Time',
                      'GMT+01:00 Central Europe',
                      'GMT+00:00 London',
                    ],
                    onChanged: (v) => setState(() => _selectedTimezone = v!),
                  ),
                ],
              ),

              // 3. GCP Infrastructure Bento Card
              _buildBentoCard(
                width: 450,
                title: 'GCP Cloud Specs',
                icon: LucideIcons.cloud,
                color: const Color(0xFF6366F1),
                theme: theme,
                isDark: isDark,
                children: [
                  _ReadOnlyRow(
                    label: 'Project ID',
                    value: tenantSettings.gcpProjectId ?? 'Not set',
                  ),
                  const SizedBox(height: 12),
                  _ReadOnlyRow(
                    label: 'Asset Bucket',
                    value: tenantSettings.gcpBucketName ?? 'Not set',
                  ),
                ],
              ),

              // 4. Physical Address Bento Card
              _buildBentoCard(
                width: 500,
                title: 'Physical Headquarters',
                icon: LucideIcons.mapPin,
                color: const Color(0xFF06B6D4),
                theme: theme,
                isDark: isDark,
                children: [
                  _EditableRow(
                    label: 'Street Address',
                    controller: _streetController,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _EditableRow(
                          label: 'City',
                          controller: _cityController,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _EditableRow(
                          label: 'ZIP',
                          controller: _postalController,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoCard({
    required double width,
    required String title,
    required IconData icon,
    required Color color,
    required ThemeData theme,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // --- VARIANT 3: MOBILE STACK LAYOUT ---
  Widget _buildCompactMobileStackLayout(
    ThemeData theme,
    bool isDark,
    tenantSettings,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mobile Mock Info Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.brandEmerald500.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.smartphone,
                      color: AppTheme.brandEmerald500,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This layout simulates settings stacked for mobile screens.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Collapsible Settings Panels
              ExpansionTile(
                leading: const Icon(
                  LucideIcons.store,
                  color: AppTheme.brandEmerald500,
                ),
                title: const Text(
                  'Store Identity',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  _EditableRow(
                    label: 'Store Name',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 12),
                  _ReadOnlyRow(label: 'Store ID', value: tenantSettings.id),
                ],
              ),
              const Divider(height: 1),
              ExpansionTile(
                leading: const Icon(
                  LucideIcons.globe,
                  color: Color(0xFFF59E0B),
                ),
                title: const Text(
                  'Regional Settings',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  _buildDropdownRow(
                    label: 'Currency',
                    value: _selectedCurrency,
                    items: const ['USD', 'EUR', 'GBP', 'CHF'],
                    onChanged: (v) => setState(() => _selectedCurrency = v!),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownRow(
                    label: 'Timezone',
                    value: _selectedTimezone,
                    items: const [
                      'GMT-05:00 Eastern Time',
                      'GMT-08:00 Pacific Time',
                      'GMT+01:00 Central Europe',
                      'GMT+00:00 London',
                    ],
                    onChanged: (v) => setState(() => _selectedTimezone = v!),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownRow(
                    label: 'Units',
                    value: _selectedUnitSystem,
                    items: const ['Metric', 'Imperial'],
                    onChanged: (v) => setState(() => _selectedUnitSystem = v!),
                  ),
                ],
              ),
              const Divider(height: 1),
              ExpansionTile(
                leading: const Icon(
                  LucideIcons.cloud,
                  color: Color(0xFF6366F1),
                ),
                title: const Text(
                  'Cloud Storage & GCP',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  _ReadOnlyRow(
                    label: 'Project ID',
                    value: tenantSettings.gcpProjectId ?? 'Not set',
                  ),
                  const SizedBox(height: 12),
                  _ReadOnlyRow(
                    label: 'Asset Bucket',
                    value: tenantSettings.gcpBucketName ?? 'Not set',
                  ),
                ],
              ),
              const Divider(height: 1),
              ExpansionTile(
                leading: const Icon(
                  LucideIcons.mapPin,
                  color: Color(0xFF06B6D4),
                ),
                title: const Text(
                  'Physical Address',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                childrenPadding: const EdgeInsets.all(16),
                children: [
                  _EditableRow(label: 'Street', controller: _streetController),
                  const SizedBox(height: 12),
                  _EditableRow(label: 'City', controller: _cityController),
                  const SizedBox(height: 12),
                  _EditableRow(
                    label: 'ZIP Code',
                    controller: _postalController,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers
  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 300,
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: items
                .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// Glassmorphism Section Card
class _PremiumSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? accentColor;

  const _PremiumSection({
    required this.title,
    required this.icon,
    required this.children,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = accentColor ?? AppTheme.brandEmerald500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withOpacity(0.7)
                    : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EditableRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _EditableRow({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 300,
          child: TextFormField(
            controller: controller,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppTheme.brandEmerald500,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
