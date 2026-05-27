import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class StorefrontPreview extends StatelessWidget {
  final Map<String, dynamic> tokens;
  final Map<String, dynamic> slots;
  final bool isMobile;

  const StorefrontPreview({
    super.key,
    required this.tokens,
    required this.slots,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    // Parse tokens
    final primaryColor = _parseColor(tokens['primary'], Colors.blue);
    final secondaryColor = _parseColor(tokens['secondary'], Colors.grey);
    final backgroundColor = _parseColor(tokens['background'], Colors.white);

    final textColor = backgroundColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    final surfaceColor = backgroundColor.computeLuminance() > 0.5
        ? Colors.grey.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.1);

    return Container(
      width: isMobile ? 375 : double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(primaryColor, textColor),

          // Hero Section
          _buildHero(primaryColor, textColor, slots['hero'] ?? 'Full-width'),

          // Featured Products Mock
          _buildFeaturedProducts(surfaceColor, textColor, primaryColor),

          // Footer
          _buildFooter(surfaceColor, textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color primary, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Icon(LucideIcons.store, color: primary),
          const SizedBox(width: 12),
          Text(
            'MY STORE',
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          if (!isMobile) ...[
            _navItem('Home', text),
            _navItem('Catalog', text),
            _navItem('About', text),
          ],
          Icon(LucideIcons.shoppingBag, color: text, size: 20),
        ],
      ),
    );
  }

  Widget _navItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Text(label, style: TextStyle(color: color, fontSize: 14)),
    );
  }

  Widget _buildHero(Color primary, Color text, String type) {
    final isCentered = type == 'centered';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      child: Column(
        crossAxisAlignment: isCentered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            slots['hero_heading'] ?? 'Modern. Sleek. Professional.',
            textAlign: isCentered ? TextAlign.center : TextAlign.start,
            style: TextStyle(
              color: text,
              fontSize: isMobile ? 32 : 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slots['hero_subheading'] ??
                'The next generation of e-commerce is here.',
            textAlign: isCentered ? TextAlign.center : TextAlign.start,
            style: TextStyle(color: text.withValues(alpha: 0.7), fontSize: 18),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Shop Collection'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedProducts(Color surface, Color text, Color primary) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured Products',
            style: TextStyle(
              color: text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _productCard(
                  surface,
                  text,
                  primary,
                  'Premium Jacket',
                  '\$129',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _productCard(
                  surface,
                  text,
                  primary,
                  'Urban Sneakers',
                  '\$89',
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _productCard(
                    surface,
                    text,
                    primary,
                    'Classic Watch',
                    '\$199',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _productCard(
    Color surface,
    Color text,
    Color primary,
    String name,
    String price,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: text.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Icon(
                LucideIcons.package,
                color: text.withValues(alpha: 0.2),
                size: 40,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(color: text, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Color surface, Color text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      color: surface,
      child: Column(
        children: [
          Text(
            '© 2026 KloudShop Storefront',
            style: TextStyle(color: text.withValues(alpha: 0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _parseColor(dynamic hex, Color fallback) {
    if (hex == null || hex is! String || !hex.startsWith('#')) return fallback;
    try {
      return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
    } catch (_) {
      return fallback;
    }
  }
}
