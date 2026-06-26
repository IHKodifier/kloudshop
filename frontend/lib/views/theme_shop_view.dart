import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/theme.dart';
import 'package:kloudshop/providers/theme_providers.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';

class KloudThemeShopView extends ConsumerStatefulWidget {
  const KloudThemeShopView({super.key});

  @override
  ConsumerState<KloudThemeShopView> createState() => _KloudThemeShopViewState();
}

class _KloudThemeShopViewState extends ConsumerState<KloudThemeShopView> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Clothing & Fashion',
    'Food & Beverage',
    'Arts & Crafts',
    'Electronics',
    'Business'
  ];

  @override
  Widget build(BuildContext context) {
    final themesAsync = ref.watch(themesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'KloudThemeShop',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: theme.textTheme.titleLarge?.color,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(height: 1.0, color: theme.dividerColor),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar Filter Panel
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.white,
              border: Border(right: BorderSide(color: theme.dividerColor)),
            ),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Categories',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.primaryColor.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? LucideIcons.checkSquare
                                  : LucideIcons.square,
                              size: 16,
                              color: isSelected
                                  ? theme.primaryColor
                                  : theme.hintColor.withOpacity(0.6),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Divider(color: theme.dividerColor),
                const SizedBox(height: 16),
                Text(
                  'Price',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      LucideIcons.checkSquare,
                      size: 16,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 10),
                    const Text('Free', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          // Right Theme Grid Panel
          Expanded(
            child: themesAsync.when(
              data: (themesList) {
                // If backend templates are empty (e.g. in test), we generate dummy models
                final themes = themesList.isNotEmpty
                    ? themesList
                    : [
                        ThemeModel(
                          themeId: 'modern-dark',
                          name: 'Dawn (Dark)',
                          description: 'A dark-themed modern design suited for tech and electronic stores.',
                          baseConfig: {},
                          createdAt: DateTime.now(),
                        ),
                        ThemeModel(
                          themeId: 'modern-light',
                          name: 'Spotlight (Light)',
                          description: 'Clean clothing storefront theme highlighting brand imagery.',
                          baseConfig: {},
                          createdAt: DateTime.now(),
                        ),
                        ThemeModel(
                          themeId: 'minimal-light',
                          name: 'Refresh (Minimal)',
                          description: 'Minimalistic design for organic products, foods, and beverages.',
                          baseConfig: {},
                          createdAt: DateTime.now(),
                        ),
                      ];

                final items = _filterAndMapThemes(themes);

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.searchCode, size: 48, color: theme.hintColor.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No themes match this category',
                          style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(32),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: 420,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _ThemeShopCard(
                      themeModel: item.model,
                      name: item.name,
                      category: item.category,
                      description: item.description,
                      colors: item.previewColors,
                      mockAssets: item.mockAssets,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading shop: $err')),
            ),
          ),
        ],
      ),
    );
  }

  List<_ShopItem> _filterAndMapThemes(List<ThemeModel> rawThemes) {
    final List<_ShopItem> mapped = [];

    for (int i = 0; i < rawThemes.length; i++) {
      final theme = rawThemes[i];

      // Distribute dummy metadata based on theme ID / Index
      String name = theme.name;
      String category = 'Clothing & Fashion';
      String description = theme.description ?? 'Free premium template storefront.';
      List<Color> colors = [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
      Map<String, dynamic> mockAssets = {
        'logo': 'FASHION',
        'heading': 'Elevate Your Style',
        'accent': const Color(0xFF6366F1),
        'bg': const Color(0xFFF3F4F6),
        'dark': false,
      };

      if (theme.themeId == 'modern-dark' || theme.name.toLowerCase().contains('dark')) {
        name = 'Dawn (Dark)';
        category = 'Electronics';
        description = 'Premium tech-focused dark theme with high-contrast layout grids.';
        colors = [const Color(0xFF0F172A), const Color(0xFF10B981)];
        mockAssets = {
          'logo': 'TECHSTORE',
          'heading': 'Next Gen Devices',
          'accent': const Color(0xFF10B981),
          'bg': const Color(0xFF090D16),
          'dark': true,
        };
      } else if (theme.themeId == 'minimal-light' || theme.name.toLowerCase().contains('minimal') || theme.name.toLowerCase().contains('two')) {
        name = 'Refresh (Minimal)';
        category = 'Food & Beverage';
        description = 'Minimalistic design for organic products, foods, and wellness.';
        colors = [const Color(0xFFECFDF5), const Color(0xFF059669)];
        mockAssets = {
          'logo': 'ORGANICS',
          'heading': 'Naturally Fresh Foods',
          'accent': const Color(0xFF059669),
          'bg': const Color(0xFFF0FDF4),
          'dark': false,
        };
      } else if (theme.themeId == 'craft' || theme.name.toLowerCase().contains('craft')) {
        name = 'Craft (Artisan)';
        category = 'Arts & Crafts';
        description = 'Rustic editorial design for handmade artifacts and creations.';
        colors = [const Color(0xFFFFFBEB), const Color(0xFFD97706)];
        mockAssets = {
          'logo': 'ARTISAN',
          'heading': 'Handcrafted Creations',
          'accent': const Color(0xFFD97706),
          'bg': const Color(0xFFFDF8F2),
          'dark': false,
        };
      } else if (i % 3 == 0) {
        name = 'Sense (Wellness)';
        category = 'Arts & Crafts';
        colors = [const Color(0xFFFDF2F8), const Color(0xFFDB2777)];
        mockAssets = {
          'logo': 'WELLNESS',
          'heading': 'Find Your Inner Balance',
          'accent': const Color(0xFFDB2777),
          'bg': const Color(0xFFFFF1F2),
          'dark': false,
        };
      } else if (i % 3 == 1) {
        name = 'Dawn (Light)';
        category = 'Clothing & Fashion';
        colors = [const Color(0xFFF3F4F6), const Color(0xFF111827)];
        mockAssets = {
          'logo': 'Dawn',
          'heading': 'Where Quality Meets Style',
          'accent': const Color(0xFF111827),
          'bg': const Color(0xFFFAFAFA),
          'dark': false,
        };
      } else {
        name = 'Spotlight (Light)';
        category = 'Business';
        colors = [const Color(0xFFF0F9FF), const Color(0xFF0284C7)];
        mockAssets = {
          'logo': 'SPOTLIGHT',
          'heading': 'Showcase Your Products',
          'accent': const Color(0xFF0284C7),
          'bg': const Color(0xFFFAFAFA),
          'dark': false,
        };
      }

      if (_selectedCategory == 'All' || _selectedCategory == category) {
        mapped.add(_ShopItem(
          model: theme,
          name: name,
          category: category,
          description: description,
          previewColors: colors,
          mockAssets: mockAssets,
        ));
      }
    }

    return mapped;
  }
}

class _ShopItem {
  final ThemeModel model;
  final String name;
  final String category;
  final String description;
  final List<Color> previewColors;
  final Map<String, dynamic> mockAssets;

  _ShopItem({
    required this.model,
    required this.name,
    required this.category,
    required this.description,
    required this.previewColors,
    required this.mockAssets,
  });
}

class _ThemeShopCard extends ConsumerWidget {
  final ThemeModel themeModel;
  final String name;
  final String category;
  final String description;
  final List<Color> colors;
  final Map<String, dynamic> mockAssets;

  const _ThemeShopCard({
    required this.themeModel,
    required this.name,
    required this.category,
    required this.description,
    required this.colors,
    required this.mockAssets,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual Mock Asset Website Preview Grid
          Expanded(
            child: Container(
              width: double.infinity,
              color: mockAssets['bg'] as Color,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mock Browser Bar
                  Row(
                    children: [
                      Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                      const SizedBox(width: 3),
                      Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle)),
                      const SizedBox(width: 3),
                      Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black26 : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 6),
                          child: const Text('https://demo.kloudshop.com', style: TextStyle(fontSize: 7, color: Colors.grey)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Mock Website Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        mockAssets['logo'] as String,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: mockAssets['dark'] ? Colors.white : Colors.black,
                        ),
                      ),
                      Row(
                        children: List.generate(3, (index) => Container(
                          margin: const EdgeInsets.only(left: 6),
                          width: 14,
                          height: 3,
                          color: (mockAssets['dark'] ? Colors.white : Colors.black).withOpacity(0.5),
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Mock Website Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          mockAssets['accent'] as Color,
                          (mockAssets['accent'] as Color).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mockAssets['heading'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(width: 60, height: 2, color: Colors.white.withOpacity(0.6)),
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              'Shop Now',
                              style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: mockAssets['accent'] as Color),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Mock Quick categories/bubbles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (idx) {
                      final labels = ['New', 'Trending', 'Sale', 'Brands'];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: mockAssets['dark'] ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          labels[idx],
                          style: TextStyle(
                            fontSize: 6,
                            fontWeight: FontWeight.bold,
                            color: (mockAssets['dark'] ? Colors.white : Colors.black).withOpacity(0.7),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      'FEATURED COLLECTIONS',
                      style: TextStyle(
                        fontSize: 6,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: (mockAssets['dark'] ? Colors.white : Colors.black).withOpacity(0.4),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Mock Product Grid Cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(3, (index) => Container(
                      width: 50,
                      height: 48,
                      decoration: BoxDecoration(
                        color: mockAssets['dark'] ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: (mockAssets['dark'] ? Colors.white : Colors.black).withOpacity(0.06)),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: (mockAssets['accent'] as Color).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(child: Icon(LucideIcons.tag, size: 8, color: mockAssets['accent'] as Color)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(width: 25, height: 3, color: (mockAssets['dark'] ? Colors.white : Colors.black).withOpacity(0.4)),
                          const SizedBox(height: 2),
                          Container(width: 15, height: 3, color: (mockAssets['dark'] ? Colors.white : Colors.black).withOpacity(0.6)),
                        ],
                      ),
                    )),
                  ),
                ],
              ),
            ),
          ),

          // Details + Double CTAs Bottom Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Free', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // Double CTAs row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showPreviewDialog(context, ref, name, mockAssets),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                        icon: const Icon(LucideIcons.eye, size: 14),
                        label: const Text('Preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleInstall(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandEmerald500,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(LucideIcons.download, size: 14, color: Colors.white),
                        label: const Text('Install', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPreviewDialog(BuildContext context, WidgetRef ref, String themeName, Map<String, dynamic> assets) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 800,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$themeName Preview',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Large Overlapping Desktop + Mobile Mockup Preview inside Dialog
              Container(
                height: 380,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: assets['bg'] as Color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Desktop Mockup representation
                    Positioned(
                      left: 40,
                      top: 40,
                      right: 140,
                      bottom: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: assets['dark'] ? const Color(0xFF090D16) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black87, width: 8),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 8)),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  assets['logo'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: assets['dark'] ? Colors.white : Colors.black,
                                  ),
                                ),
                                Container(width: 80, height: 6, color: (assets['dark'] ? Colors.white : Colors.black).withOpacity(0.2)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // 1. Hero Banner
                            Container(
                              height: 80,
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    assets['accent'] as Color,
                                    (assets['accent'] as Color).withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    assets['heading'] as String,
                                    style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Shop Now',
                                      style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: assets['accent'] as Color),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // 2. Category Navigation Pills
                            Row(
                              children: List.generate(4, (idx) {
                                final labels = ['Best Sellers', 'New arrivals', 'Trending', 'Hot deals'];
                                return Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: assets['dark'] ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    labels[idx],
                                    style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                      color: (assets['dark'] ? Colors.white : Colors.black).withOpacity(0.6),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const Spacer(),
                            // 3. Products Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(3, (index) => Container(
                                width: 140,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: assets['dark'] ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: (assets['dark'] ? Colors.white : Colors.black).withOpacity(0.06)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: (assets['accent'] as Color).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(child: Icon(LucideIcons.tag, size: 16, color: assets['accent'] as Color)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(width: 50, height: 6, color: (assets['dark'] ? Colors.white : Colors.black).withOpacity(0.4)),
                                          const SizedBox(height: 4),
                                          Container(width: 30, height: 6, color: (assets['dark'] ? Colors.white : Colors.black).withOpacity(0.2)),
                                          const SizedBox(height: 8),
                                          Container(width: 20, height: 6, color: assets['accent'] as Color),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Mobile Mockup representation
                    Positioned(
                      right: 40,
                      bottom: 30,
                      child: Container(
                        width: 140,
                        height: 250,
                        decoration: BoxDecoration(
                          color: assets['dark'] ? const Color(0xFF090D16) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black, width: 6),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(4, 8)),
                          ],
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Container(width: 40, height: 8, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4))),
                            const SizedBox(height: 8),
                            Text(
                              assets['logo'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: assets['dark'] ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 1. Mobile Banner
                            Container(
                              height: 65,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    assets['accent'] as Color,
                                    (assets['accent'] as Color).withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(6),
                              child: Text(
                                assets['heading'] as String,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // 2. Mobile Navigation Pills
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(3, (idx) {
                                final labels = ['New', 'Sale', 'Trending'];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: assets['dark'] ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    labels[idx],
                                    style: TextStyle(
                                      fontSize: 6,
                                      fontWeight: FontWeight.bold,
                                      color: (assets['dark'] ? Colors.white : Colors.black).withOpacity(0.6),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const Spacer(),
                            // 3. Mobile Products Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(2, (index) => Container(
                                width: 56,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: assets['dark'] ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: (assets['dark'] ? Colors.white : Colors.black).withOpacity(0.06)),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: (assets['accent'] as Color).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Center(child: Icon(LucideIcons.tag, size: 8, color: assets['accent'] as Color)),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Container(width: 25, height: 3, color: (assets['dark'] ? Colors.white : Colors.black).withOpacity(0.4)),
                                    const SizedBox(height: 2),
                                    Container(width: 15, height: 3, color: (assets['dark'] ? Colors.white : Colors.black).withOpacity(0.6)),
                                  ],
                                ),
                              )),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _handleInstall(context, ref);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandEmerald500,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Install Theme', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleInstall(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(activeThemeConfigProvider.notifier).selectTheme(themeModel.themeId);
      ref.invalidate(themeConfigurationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme "$name" is now installed and active!'),
            backgroundColor: AppTheme.brandEmerald600,
          ),
        );
        Navigator.of(context).pop(); // Go back to themes view
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to install theme: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
