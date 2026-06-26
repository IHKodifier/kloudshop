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
import 'package:kloudshop/widgets/semantic_text_form_field.dart';

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

  // Shipping sub-view state
  Future<List<Map<String, dynamic>>>? _shippingProfilesFuture;
  void _refreshShippingProfiles() {
    _shippingProfilesFuture = ref.read(apiServiceProvider).listShippingProfiles();
  }

  // Taxes sub-view state
  bool _stripeTaxEnabled = false;
  Future<List<Map<String, dynamic>>>? _taxRatesFuture;
  void _refreshTaxRates() {
    _taxRatesFuture = ref.read(apiServiceProvider).listTaxRates();
  }

  // Navigation sub-view state
  Future<List<Map<String, dynamic>>>? _navigationMenusFuture;
  String? _selectedMenuId;
  void _refreshNavigationMenus() {
    _navigationMenusFuture = ref.read(apiServiceProvider).listNavigationMenus().then((menus) {
      if (menus.isNotEmpty && _selectedMenuId == null) {
        setState(() {
          _selectedMenuId = menus.first['menu_id']?.toString();
        });
      }
      return menus;
    });
  }

  // Policies sub-view state
  Future<List<Map<String, dynamic>>>? _policiesFuture;
  void _refreshPolicies() {
    _policiesFuture = ref.read(apiServiceProvider).listPolicies();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _refreshShippingProfiles();
    _refreshTaxRates();
    _refreshNavigationMenus();
    _refreshPolicies();
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
          'stripe_tax_enabled': _stripeTaxEnabled,
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
            _stripeTaxEnabled = cfg['stripe_tax_enabled'] as bool? ?? false;
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
      {'title': 'Shipping Profiles', 'icon': LucideIcons.truck},
      {'title': 'Taxes & Stripe', 'icon': LucideIcons.percent},
      {'title': 'Navigation Menus', 'icon': LucideIcons.menu},
      {'title': 'Store Policies', 'icon': LucideIcons.fileText},
      {'title': 'Regional Standards', 'icon': LucideIcons.globe},
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
    final isDark = theme.brightness == Brightness.dark;
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
        return _buildShippingSettingsTab(theme, isDark);
      case 2:
        return _buildTaxesSettingsTab(theme, isDark, tenantSettings);
      case 3:
        return _buildNavigationSettingsTab(theme, isDark);
      case 4:
        return _buildPoliciesSettingsTab(theme, isDark);
      case 5:
        return Column(
          key: const ValueKey(5),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PremiumSection(
              title: 'Regional Standards',
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
      case 6:
        return Column(
          key: const ValueKey(6),
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
      case 7:
        return Column(
          key: const ValueKey(7),
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
                  prefixIcon: LucideIcons.mail,
                ),
                const SizedBox(height: 16),
                _EditableRow(
                  label: 'Account Email',
                  controller: _accountEmailController,
                  prefixIcon: LucideIcons.mail,
                ),
              ],
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  // --- Shipping Settings Helper View ---
  Widget _buildShippingSettingsTab(ThemeData theme, bool isDark) {
    return Column(
      key: const ValueKey(101),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PremiumSection(
          title: 'Shipping Profiles & Regional zones',
          icon: LucideIcons.truck,
          accentColor: AppTheme.brandEmerald500,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Shipping Profiles',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateProfileDialog(theme),
                  icon: const Icon(LucideIcons.plus, size: 14),
                  label: const Text('Create Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandEmerald500,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _shippingProfilesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.brandEmerald500));
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent));
                }
                final profiles = snapshot.data ?? [];
                if (profiles.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: Text('No shipping profiles configured. Click "Create Profile" to start.')),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: profiles.length,
                  itemBuilder: (context, idx) {
                    final profile = profiles[idx];
                    final profileId = profile['profile_id']?.toString() ?? '';
                    final isGeneral = profile['is_general'] == true;
                    final zones = (profile['zones'] as List?) ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  profile['name']?.toString() ?? 'Unnamed Profile',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                if (isGeneral)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.brandEmerald500.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'General',
                                      style: TextStyle(color: AppTheme.brandEmerald500, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                const Spacer(),
                                if (!isGeneral)
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                                    onPressed: () async {
                                      await ref.read(apiServiceProvider).deleteShippingProfile(profileId);
                                      _refreshShippingProfiles();
                                    },
                                  ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Zones', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                TextButton.icon(
                                  onPressed: () => _showCreateZoneDialog(theme, profileId),
                                  icon: const Icon(LucideIcons.plus, size: 12),
                                  label: const Text('Add Zone'),
                                ),
                              ],
                            ),
                            if (zones.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('No shipping zones in this profile.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ),
                            ...zones.map((zone) {
                              final zoneId = zone['zone_id']?.toString() ?? '';
                              final countries = (zone['countries'] as List?) ?? [];
                              final rates = (zone['rates'] as List?) ?? [];

                              return Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                zone['name']?.toString() ?? 'Unnamed Zone',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Countries: ${countries.join(", ")}',
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                                          onPressed: () async {
                                            await ref.read(apiServiceProvider).deleteShippingZone(zoneId);
                                            _refreshShippingProfiles();
                                          },
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Rates', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
                                        TextButton.icon(
                                          onPressed: () => _showCreateRateDialog(theme, zoneId),
                                          icon: const Icon(LucideIcons.plus, size: 10),
                                          label: const Text('Add Rate', style: TextStyle(fontSize: 11)),
                                        ),
                                      ],
                                    ),
                                    if (rates.isEmpty)
                                      const Text('No rates configured for this zone.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    ...rates.map((rate) {
                                      final rateId = rate['rate_id']?.toString() ?? '';
                                      final price = rate['price'] ?? 0.0;
                                      final rateType = rate['rate_type']?.toString() ?? 'price';
                                      final minVal = rate['min_value'];
                                      final maxVal = rate['max_value'];
                                      final minWt = rate['min_weight'];
                                      final maxWt = rate['max_weight'];

                                      String conditionStr = 'Any condition';
                                      if (rateType == 'price' && (minVal != null || maxVal != null)) {
                                        conditionStr = 'Price: \$${minVal ?? 0.0}' + (maxVal != null ? ' - \$${maxVal}' : '+');
                                      } else if (rateType == 'weight' && (minWt != null || maxWt != null)) {
                                        conditionStr = 'Weight: ${minWt ?? 0.0}kg' + (maxWt != null ? ' - ${maxWt}kg' : '+');
                                      }

                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                        title: Text(rate['name']?.toString() ?? 'Unnamed Rate', style: const TextStyle(fontSize: 12)),
                                        subtitle: Text(conditionStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                                              onPressed: () async {
                                                await ref.read(apiServiceProvider).deleteShippingRate(rateId);
                                                _refreshShippingProfiles();
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showCreateProfileDialog(ThemeData theme) {
    final nameCtrl = TextEditingController();
    bool isGeneral = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Shipping Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Profile Name', hintText: 'e.g. Fragile Items'),
              ),
              CheckboxListTile(
                title: const Text('General Shipping Profile'),
                value: isGeneral,
                onChanged: (val) {
                  setDialogState(() {
                    isGeneral = val ?? false;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty) {
                  await ref.read(apiServiceProvider).createShippingProfile(nameCtrl.text, isGeneral);
                  _refreshShippingProfiles();
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateZoneDialog(ThemeData theme, String profileId) {
    final nameCtrl = TextEditingController();
    final countriesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Shipping Zone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Zone Name', hintText: 'e.g. Domestic US'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: countriesCtrl,
              decoration: const InputDecoration(labelText: 'Countries (comma separated ISO codes)', hintText: 'e.g. US, CA, MX'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && countriesCtrl.text.isNotEmpty) {
                final countryList = countriesCtrl.text.split(',').map((c) => c.trim().toUpperCase()).toList();
                await ref.read(apiServiceProvider).createShippingZone(profileId, nameCtrl.text, countryList);
                _refreshShippingProfiles();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showCreateRateDialog(ThemeData theme, String zoneId) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final minCtrl = TextEditingController();
    final maxCtrl = TextEditingController();
    String rateType = 'price'; // 'price' or 'weight'
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Shipping Rate'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Rate Name', hintText: 'e.g. Standard Shipping'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price (\$)', hintText: 'e.g. 5.99'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: rateType,
                  decoration: const InputDecoration(labelText: 'Condition Type'),
                  items: const [
                    DropdownMenuItem(value: 'price', child: Text('Price-based')),
                    DropdownMenuItem(value: 'weight', child: Text('Weight-based')),
                  ],
                  onChanged: (val) {
                    setDialogState(() {
                      rateType = val!;
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: minCtrl,
                  decoration: InputDecoration(
                    labelText: rateType == 'price' ? 'Min Order Value (\$)' : 'Min Weight (kg)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: maxCtrl,
                  decoration: InputDecoration(
                    labelText: rateType == 'price' ? 'Max Order Value (\$)' : 'Max Weight (kg)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                  final price = double.tryParse(priceCtrl.text) ?? 0.0;
                  final minVal = double.tryParse(minCtrl.text);
                  final maxVal = double.tryParse(maxCtrl.text);

                  await ref.read(apiServiceProvider).createShippingRate(
                    zoneId: zoneId,
                    name: nameCtrl.text,
                    price: price,
                    minValue: rateType == 'price' ? minVal : null,
                    maxValue: rateType == 'price' ? maxVal : null,
                    minWeight: rateType == 'weight' ? minVal : null,
                    maxWeight: rateType == 'weight' ? maxVal : null,
                    rateType: rateType,
                  );
                  _refreshShippingProfiles();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Taxes Settings View ---
  Widget _buildTaxesSettingsTab(ThemeData theme, bool isDark, tenantSettings) {
    return Column(
      key: const ValueKey(102),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PremiumSection(
          title: 'Taxes Configuration',
          icon: LucideIcons.percent,
          accentColor: const Color(0xFFF59E0B),
          children: [
            SwitchListTile(
              title: const Text('Stripe Connect Automated Tax'),
              subtitle: const Text('Use Stripe automated address detection to compute taxes dynamically.'),
              value: _stripeTaxEnabled,
              activeColor: AppTheme.brandEmerald500,
              onChanged: (val) {
                setState(() {
                  _stripeTaxEnabled = val;
                });
              },
            ),
            const Divider(height: 32),
            if (!_stripeTaxEnabled) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Manual Fallback Tax Rates',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddTaxRateDialog(theme),
                    icon: const Icon(LucideIcons.plus, size: 12),
                    label: const Text('Add Tax Rate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandEmerald500,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _taxRatesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.brandEmerald500));
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  final rates = snapshot.data ?? [];
                  if (rates.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('No manual tax rates configured.', style: TextStyle(color: Colors.grey)),
                    );
                  }
                  return Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(1),
                    },
                    border: TableBorder.all(color: theme.dividerColor, width: 0.5, borderRadius: BorderRadius.circular(8)),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.03)),
                        children: const [
                          Padding(padding: EdgeInsets.all(8.0), child: Text('Country', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('State/Region', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('Tax Rate (%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8.0), child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                      ...rates.map((rate) {
                        final rateId = rate['tax_rate_id']?.toString() ?? '';
                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(8.0), child: Text(rate['country_code']?.toString() ?? '', style: const TextStyle(fontSize: 12))),
                            Padding(padding: const EdgeInsets.all(8.0), child: Text(rate['state_code']?.toString() ?? 'All States', style: const TextStyle(fontSize: 12))),
                            Padding(padding: const EdgeInsets.all(8.0), child: Text('${rate['tax_percentage']}%', style: const TextStyle(fontSize: 12))),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () async {
                                  await ref.read(apiServiceProvider).deleteTaxRate(rateId);
                                  _refreshTaxRates();
                                },
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  );
                },
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.brandEmerald500.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.brandEmerald500.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.shieldCheck, color: AppTheme.brandEmerald500, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Stripe Tax is active. All fallback manual rates are ignored, and sales tax is calculated automatically at checkout based on regional rules.',
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showAddTaxRateDialog(ThemeData theme) {
    final countryCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final percentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Manual Tax Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: countryCtrl,
              decoration: const InputDecoration(labelText: 'Country Code (2 letters)', hintText: 'e.g. US'),
              maxLength: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: stateCtrl,
              decoration: const InputDecoration(labelText: 'State/Region Code (optional)', hintText: 'e.g. NY'),
              maxLength: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: percentCtrl,
              decoration: const InputDecoration(labelText: 'Tax Percentage (%)', hintText: 'e.g. 8.25'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (countryCtrl.text.isNotEmpty && percentCtrl.text.isNotEmpty) {
                final pct = double.tryParse(percentCtrl.text) ?? 0.0;
                await ref.read(apiServiceProvider).createTaxRate(
                  countryCode: countryCtrl.text,
                  stateCode: stateCtrl.text.isEmpty ? null : stateCtrl.text,
                  taxPercentage: pct,
                  isActive: true,
                );
                _refreshTaxRates();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // --- Navigation Settings View ---
  Widget _buildNavigationSettingsTab(ThemeData theme, bool isDark) {
    return Column(
      key: const ValueKey(103),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PremiumSection(
          title: 'Storefront Navigation Builder',
          icon: LucideIcons.menu,
          accentColor: const Color(0xFF6366F1),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Navigation Menus',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCreateMenuDialog(theme),
                  icon: const Icon(LucideIcons.plus, size: 12),
                  label: const Text('Create Menu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandEmerald500,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _navigationMenusFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.brandEmerald500));
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                final menus = snapshot.data ?? [];
                if (menus.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text('No navigation menus created. Click "Create Menu" to add one.'),
                  );
                }

                // Dropdown to select active menu
                final selectedMenu = menus.firstWhere(
                  (m) => m['menu_id']?.toString() == _selectedMenuId,
                  orElse: () => menus.first,
                );
                _selectedMenuId = selectedMenu['menu_id']?.toString();

                final menuItems = (selectedMenu['items'] as List?) ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Active Menu: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _selectedMenuId,
                          onChanged: (val) {
                            setState(() {
                              _selectedMenuId = val;
                            });
                          },
                          items: menus.map((m) {
                            return DropdownMenuItem<String>(
                              value: m['menu_id']?.toString(),
                              child: Text('${m['name']} (${m['handle']})'),
                            );
                          }).toList(),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 16),
                          onPressed: () async {
                            if (_selectedMenuId != null) {
                              await ref.read(apiServiceProvider).deleteNavigationMenu(_selectedMenuId!);
                              setState(() {
                                _selectedMenuId = null;
                              });
                              _refreshNavigationMenus();
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Menu Items Outline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ElevatedButton.icon(
                          onPressed: () => _showAddMenuItemDialog(theme, _selectedMenuId!),
                          icon: const Icon(LucideIcons.plus, size: 12),
                          label: const Text('Add Menu Item', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandEmerald500.withOpacity(0.1),
                            foregroundColor: AppTheme.brandEmerald500,
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (menuItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text('No items in this menu. Click "Add Menu Item" to add links.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    ...menuItems.map((item) {
                      final itemId = item['item_id']?.toString() ?? '';
                      final title = item['title']?.toString() ?? '';
                      final type = item['link_type']?.toString() ?? '';
                      final url = item['url']?.toString() ?? '';
                      final children = (item['children'] as List?) ?? [];
                      final pos = item['position'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          leading: const Icon(LucideIcons.link, size: 16, color: AppTheme.brandEmerald500),
                          title: Text('$title ($type)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          subtitle: Text('Slug: $url', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(LucideIcons.arrowUp, size: 14),
                                onPressed: pos > 0 ? () async {
                                  // Simple move up simulation
                                  final reorderedItems = menuItems.map((m) {
                                    int p = m['position'] ?? 0;
                                    if (m['item_id'] == itemId) {
                                      return {'item_id': m['item_id'], 'position': p - 1};
                                    } else if (p == pos - 1) {
                                      return {'item_id': m['item_id'], 'position': p + 1};
                                    }
                                    return {'item_id': m['item_id'], 'position': p};
                                  }).toList();
                                  await ref.read(apiServiceProvider).reorderNavigationItems(_selectedMenuId!, reorderedItems);
                                  _refreshNavigationMenus();
                                } : null,
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.arrowDown, size: 14),
                                onPressed: pos < menuItems.length - 1 ? () async {
                                  // Simple move down simulation
                                  final reorderedItems = menuItems.map((m) {
                                    int p = m['position'] ?? 0;
                                    if (m['item_id'] == itemId) {
                                      return {'item_id': m['item_id'], 'position': p + 1};
                                    } else if (p == pos + 1) {
                                      return {'item_id': m['item_id'], 'position': p - 1};
                                    }
                                    return {'item_id': m['item_id'], 'position': p};
                                  }).toList();
                                  await ref.read(apiServiceProvider).reorderNavigationItems(_selectedMenuId!, reorderedItems);
                                  _refreshNavigationMenus();
                                } : null,
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                                onPressed: () async {
                                  await ref.read(apiServiceProvider).deleteNavigationItem(itemId);
                                  _refreshNavigationMenus();
                                },
                              ),
                            ],
                          ),
                          children: children.map<Widget>((child) {
                            final childId = child['item_id']?.toString() ?? '';
                            return ListTile(
                              contentPadding: const EdgeInsets.only(left: 32, right: 16),
                              leading: const Icon(LucideIcons.cornerDownRight, size: 14, color: Colors.grey),
                              title: Text(child['title']?.toString() ?? '', style: const TextStyle(fontSize: 12)),
                              subtitle: Text(child['url']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              trailing: IconButton(
                                icon: const Icon(LucideIcons.trash2, size: 14, color: Colors.redAccent),
                                onPressed: () async {
                                  await ref.read(apiServiceProvider).deleteNavigationItem(childId);
                                  _refreshNavigationMenus();
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showCreateMenuDialog(ThemeData theme) {
    final nameCtrl = TextEditingController();
    final handleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Navigation Menu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Menu Name', hintText: 'e.g. Header Menu'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: handleCtrl,
              decoration: const InputDecoration(labelText: 'Menu Handle (URL identifier)', hintText: 'e.g. main-menu'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && handleCtrl.text.isNotEmpty) {
                await ref.read(apiServiceProvider).createNavigationMenu(nameCtrl.text, handleCtrl.text);
                _refreshNavigationMenus();
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddMenuItemDialog(ThemeData theme, String menuId) {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String linkType = 'custom_url';
    String? resourceId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Menu Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Link Title', hintText: 'e.g. Shop All'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: linkType,
                  decoration: const InputDecoration(labelText: 'Link Destination Type'),
                  items: const [
                    DropdownMenuItem(value: 'custom_url', child: Text('Custom URL')),
                    DropdownMenuItem(value: 'product', child: Text('Linked Product')),
                    DropdownMenuItem(value: 'collection', child: Text('Linked Collection')),
                    DropdownMenuItem(value: 'page', child: Text('Linked Static Page')),
                    DropdownMenuItem(value: 'policy', child: Text('Linked Store Policy')),
                  ],
                  onChanged: (val) {
                    setDialogState(() {
                      linkType = val!;
                      // Reset resourceId when type changes
                      resourceId = null;
                      if (linkType == 'custom_url') {
                        urlCtrl.text = '/';
                      } else {
                        urlCtrl.text = '/$linkType/';
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                if (linkType != 'custom_url') ...[
                  TextField(
                    onChanged: (val) {
                      setDialogState(() {
                        resourceId = val;
                        urlCtrl.text = '/$linkType/$resourceId';
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Linked Resource ID / Handle',
                      hintText: 'e.g. winter-boots-sku',
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(labelText: 'Generated URL slug'),
                  readOnly: linkType != 'custom_url',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isNotEmpty) {
                  await ref.read(apiServiceProvider).createNavigationItem(
                    menuId: menuId,
                    title: titleCtrl.text,
                    url: urlCtrl.text,
                    linkType: linkType,
                    resourceId: resourceId,
                    position: 9999, // default last position
                  );
                  _refreshNavigationMenus();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Policies Settings View ---
  String _selectedPolicyType = 'refund';
  final _policyContentCtrl = TextEditingController();

  Widget _buildPoliciesSettingsTab(ThemeData theme, bool isDark) {
    return Column(
      key: const ValueKey(104),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PremiumSection(
          title: 'Store Legal Policies',
          icon: LucideIcons.fileText,
          accentColor: const Color(0xFFEC4899),
          children: [
            Row(
              children: [
                const Text('Select Policy: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedPolicyType,
                  onChanged: (val) {
                    setState(() {
                      _selectedPolicyType = val!;
                      // Clear controller so it fetches the fresh policy type
                      _policyContentCtrl.clear();
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: 'refund', child: Text('Refund Policy')),
                    DropdownMenuItem(value: 'privacy', child: Text('Privacy Policy')),
                    DropdownMenuItem(value: 'terms', child: Text('Terms of Service')),
                    DropdownMenuItem(value: 'shipping', child: Text('Shipping Policy')),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _policiesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.brandEmerald500));
                }
                if (snapshot.hasError) {
                  return Text('Error loading policies: ${snapshot.error}');
                }
                final policies = snapshot.data ?? [];
                
                // Find policy object locally
                final policy = policies.firstWhere(
                  (p) => p['policy_type']?.toString().toLowerCase() == _selectedPolicyType,
                  orElse: () => <String, dynamic>{},
                );

                final policyId = policy['policy_id']?.toString() ?? '';
                final isPublished = policy['is_active'] == true;
                final publishedContent = policy['published_content']?.toString() ?? '';
                
                if (_policyContentCtrl.text.isEmpty && policy['draft_content'] != null) {
                  _policyContentCtrl.text = policy['draft_content'].toString();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${_selectedPolicyType.toUpperCase()} Policy Editor',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        if (isPublished)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.brandEmerald500.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Published', style: TextStyle(color: AppTheme.brandEmerald500, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Draft', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _policyContentCtrl,
                      maxLines: 12,
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.grey.withOpacity(0.03),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        hintText: 'Enter HTML content or click Seed Template below...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final seeded = await ref.read(apiServiceProvider).seedPolicyTemplate(_selectedPolicyType);
                            setState(() {
                              _policyContentCtrl.text = seeded;
                            });
                          },
                          icon: const Icon(LucideIcons.fileText, size: 14),
                          label: const Text('Seed Template'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (policyId.isEmpty) {
                              // create new
                              await ref.read(apiServiceProvider).createPolicy(_selectedPolicyType, _policyContentCtrl.text);
                            } else {
                              // update draft
                              await ref.read(apiServiceProvider).updatePolicyDraft(policyId, _policyContentCtrl.text);
                            }
                            _refreshPolicies();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Draft saved successfully!')),
                            );
                          },
                          icon: const Icon(LucideIcons.save, size: 14),
                          label: const Text('Save Draft'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (policyId.isEmpty) return;
                            try {
                              await ref.read(apiServiceProvider).publishPolicy(policyId, force: false);
                              _refreshPolicies();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Policy published successfully!')),
                              );
                            } catch (e) {
                              // Show confirmation if it failed due to lack of links (Unprocessable Entity 422)
                              if (e.toString().contains('422')) {
                                _showPublishBypassDialog(policyId);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Publish failed: $e'), backgroundColor: Colors.redAccent),
                                );
                              }
                            }
                          },
                          icon: const Icon(LucideIcons.rocket, size: 14),
                          label: const Text('Publish'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandEmerald500,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (publishedContent.isNotEmpty) ...[
                      const Divider(height: 48),
                      const Text(
                        'Currently Published Storefront HTML Preview:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Text(
                          publishedContent,
                          style: const TextStyle(fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showPublishBypassDialog(String policyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Storefront Link Detected'),
        content: const Text(
          'This policy has no active links pointing to it from any navigation menus.\n\n'
          'Would you like to force publish it anyway?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(apiServiceProvider).publishPolicy(policyId, force: true);
              _refreshPolicies();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Policy published (bypass validated) successfully!')),
              );
            },
            child: const Text('Publish Anyway'),
          ),
        ],
      ),
    );
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
                    prefixIcon: LucideIcons.mapPin,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _EditableRow(
                          label: 'City',
                          controller: _cityController,
                          prefixIcon: LucideIcons.mapPin,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _EditableRow(
                          label: 'ZIP',
                          controller: _postalController,
                          prefixIcon: LucideIcons.mapPin,
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
                  _EditableRow(
                    label: 'Street',
                    controller: _streetController,
                    prefixIcon: LucideIcons.mapPin,
                  ),
                  const SizedBox(height: 12),
                  _EditableRow(
                    label: 'City',
                    controller: _cityController,
                    prefixIcon: LucideIcons.mapPin,
                  ),
                  const SizedBox(height: 12),
                  _EditableRow(
                    label: 'ZIP Code',
                    controller: _postalController,
                    prefixIcon: LucideIcons.mapPin,
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
  final IconData? prefixIcon;
  const _EditableRow({
    required this.label,
    required this.controller,
    this.prefixIcon,
  });

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
          child: SemanticTextFormField(
            controller: controller,
            labelText: label,
            prefixIcon: prefixIcon,
          ),
        ),
      ],
    );
  }
}
