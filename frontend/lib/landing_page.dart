import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kloudshop/providers/theme_provider.dart';
import 'package:kloudshop/login_page.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';

class KloudShopLandingPage extends ConsumerWidget {
  const KloudShopLandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF020617)
          : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Navigation Bar ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.brandEmerald500.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.asset(
                          'assets/logo3d.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              LucideIcons.cloud,
                              color: AppTheme.brandEmerald500,
                              size: 24,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'KloudShop',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.brandTeal900,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _navItem(context, 'Features'),
                  _navItem(context, 'Solutions'),
                  _navItem(context, 'Pricing'),
                  const SizedBox(width: 32),
                  HoverScale(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSurface,
                      ),
                      child: const Text(
                        'Merchant Login',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Theme Toggle
                  IconButton(
                    onPressed: () {
                      ref.read(themeModeProvider.notifier).toggleTheme(!isDark);
                    },
                    icon: Icon(
                      isDark ? LucideIcons.sun : LucideIcons.moon,
                      color: theme.colorScheme.onSurface,
                    ),
                    tooltip: 'Toggle Dark/Light Mode',
                  ),
                  const SizedBox(width: 16),

                  HoverScale(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.brandEmerald500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 8-Section Architecture ---
            const _HeroSection(),
            const _SuccessSection(),
            const _ProblemAgitateSection(),
            const _ValueStackSection(),
            const _SocialProofSection(),
            const _TransformationSection(),
            const _SecondaryCTASection(),
            const _FooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends ConsumerWidget {
  const _HeroSection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 96),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF020617)]
              : [const Color(0xFFECFDF5), const Color(0xFFF8FAFC)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  'Stop Paying a Tax on Your Own Growth.',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: isDark ? Colors.white : AppTheme.brandTeal900,
                  ),
                ),
                const SizedBox(height: 24),
                SelectableText(
                  'The e-commerce operating system for mid-market brands. Run B2B and DTC from one unified engine, replace your expensive app stack with native features, and never pay a transaction fee again.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    height: 1.6,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    HoverScale(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandEmerald500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 22,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: AppTheme.brandEmerald500.withOpacity(
                            0.3,
                          ),
                        ),
                        child: const Text(
                          'Start Your 30-Day Free Trial',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.checkCircle2,
                      size: 16,
                      color: AppTheme.brandEmerald500,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: SelectableText(
                        'No credit card required. Migrate your Shopify or WooCommerce store in 2 minutes.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 64),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 420,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: Image.asset(
                    'assets/landing_hero.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          LucideIcons.cloudLightning,
                          size: 84,
                          color: AppTheme.brandEmerald500.withOpacity(0.5),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessSection extends StatelessWidget {
  const _SuccessSection();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 48),
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Column(
        children: [
          SelectableText(
            'Live in 2 minutes. No developer required.',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.brandTeal900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 800,
            child: SelectableText(
              'Paste your current store URL. Our AI migration engine imports your entire product catalogue, variants, and SEO metadata before your coffee gets cold.',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),

          // Migration Steps process flow
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withOpacity(0.4)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MigrationStep(
                  icon: LucideIcons.search,
                  title: 'Detected Shopify',
                  theme: theme,
                ),
                Icon(
                  LucideIcons.arrowRight,
                  color: theme.hintColor.withOpacity(0.5),
                ),
                _MigrationStep(
                  icon: LucideIcons.package,
                  title: 'Read 847 Products',
                  theme: theme,
                ),
                Icon(
                  LucideIcons.arrowRight,
                  color: theme.hintColor.withOpacity(0.5),
                ),
                _MigrationStep(
                  icon: LucideIcons.fileSearch,
                  title: 'Preserved SEO',
                  theme: theme,
                ),
                Icon(
                  LucideIcons.arrowRight,
                  color: theme.hintColor.withOpacity(0.5),
                ),
                _MigrationStep(
                  icon: LucideIcons.checkCircle2,
                  title: 'Store Live',
                  theme: theme,
                  isFinal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MigrationStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isFinal;
  final ThemeData theme;
  const _MigrationStep({
    required this.icon,
    required this.title,
    this.isFinal = false,
    required this.theme,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isFinal
                ? AppTheme.brandEmerald500
                : AppTheme.brandEmerald500.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.brandEmerald500.withOpacity(0.3),
            ),
          ),
          child: Icon(
            icon,
            color: isFinal ? Colors.white : AppTheme.brandEmerald500,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        SelectableText(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isFinal
                ? AppTheme.brandEmerald500
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ProblemAgitateSection extends StatelessWidget {
  const _ProblemAgitateSection();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 48),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.2),
                    ),
                  ),
                  child: const Text(
                    'The Problem',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SelectableText(
                  "You're trapped in the App Store ecosystem.",
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.brandTeal900,
                  ),
                ),
                const SizedBox(height: 20),
                SelectableText(
                  "You're paying \$2,000/month for a platform, and another \$1,500/month for 15 third-party apps just to get basic B2B pricing and wholesale features. And every time the platform updates, your checkout breaks. You aren't running a business anymore—you're managing a fragile tech stack.",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    height: 1.6,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 64),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.alertTriangle,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Monthly Tech Tax',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _CostItem(
                    title: 'Base Platform Fee',
                    cost: '\$2,000/mo',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _CostItem(
                    title: 'B2B Wholesale Portal App',
                    cost: '\$399/mo',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _CostItem(
                    title: 'Tiered Pricing App',
                    cost: '\$149/mo',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _CostItem(
                    title: 'Subscription App',
                    cost: '\$299/mo',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _CostItem(
                    title: 'Transaction Fees (1.5%)',
                    cost: 'Scale Penalty',
                    theme: theme,
                    isPenalty: true,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Frustration',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Too High',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CostItem extends StatelessWidget {
  final String title;
  final String cost;
  final ThemeData theme;
  final bool isPenalty;
  const _CostItem({
    required this.title,
    required this.cost,
    required this.theme,
    this.isPenalty = false,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          cost,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isPenalty ? Colors.redAccent : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ValueStackSection extends StatelessWidget {
  const _ValueStackSection();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 48),
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Column(
        children: [
          SelectableText(
            'Everything you need is already built in.',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.brandTeal900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 56),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ValueCard(
                icon: LucideIcons.layers,
                title: 'Unified B2B & DTC Engine',
                description:
                    'Stop managing two separate stores. One inventory, two distinct shopping experiences, unified analytics.',
                theme: theme,
                isDark: isDark,
              ),
              const SizedBox(width: 24),
              _ValueCard(
                icon: LucideIcons.packagePlus,
                title: 'Native Feature Catalogue',
                description:
                    'Say goodbye to paid apps. Wholesale portals, tiered pricing, AI replenishment, and subscriptions—all native, all free to toggle on.',
                theme: theme,
                isDark: isDark,
              ),
              const SizedBox(width: 24),
              _ValueCard(
                icon: LucideIcons.creditCard,
                title: 'Flat, Predictable Pricing',
                description:
                    '\$24.99 to \$49.99 a month. Plus your raw GCP infrastructure cost. We take 0% of your GMV. When you grow, your margins stay yours.',
                theme: theme,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ThemeData theme;
  final bool isDark;
  const _ValueCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.theme,
    required this.isDark,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withOpacity(0.5)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.brandEmerald500.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.brandEmerald500, size: 24),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialProofSection extends StatelessWidget {
  const _SocialProofSection();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 48),
      child: Column(
        children: [
          SelectableText(
            'The brands escaping the platform tax.',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.brandTeal900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Testimonial details
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withOpacity(0.7)
                      : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.brandEmerald500.withOpacity(0.15),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      LucideIcons.quote,
                      size: 40,
                      color: AppTheme.brandEmerald500,
                    ),
                    const SizedBox(height: 20),
                    SelectableText(
                      '"We were paying Shopify Plus \$2,500 a month and still had to bolt on \$800 of B2B apps. We migrated to KloudShop in an afternoon. Our storefront is twice as fast, our B2B portal is finally connected to our retail inventory, and our tech bill dropped by 90%."',
                      style: theme.textTheme.titleLarge?.copyWith(
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.brandEmerald500.withOpacity(
                            0.15,
                          ),
                          child: const Icon(
                            LucideIcons.user,
                            color: AppTheme.brandEmerald500,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sarah Jenkins',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'CFO, Mid-Market Wholesaler',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransformationSection extends StatelessWidget {
  const _TransformationSection();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 48),
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Column(
        children: [
          SelectableText(
            'From duct-tape to enterprise-grade.',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.brandTeal900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 56),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'The Old Way',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _TransformationItem(
                        text: '14 third-party apps',
                        isGood: false,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _TransformationItem(
                        text: 'Desynced B2B inventory',
                        isGood: false,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _TransformationItem(
                        text: 'Punishing transaction fees',
                        isGood: false,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _TransformationItem(
                        text: 'Constant developer maintenance',
                        isGood: false,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.brandEmerald500.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'The KloudShop Way',
                        style: TextStyle(
                          color: AppTheme.brandEmerald600,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _TransformationItem(
                        text: '1 native codebase',
                        isGood: true,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _TransformationItem(
                        text: 'Perfectly synced B2B + DTC inventory',
                        isGood: true,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _TransformationItem(
                        text: '0% platform transaction fees',
                        isGood: true,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _TransformationItem(
                        text: 'Automated AI stock forecasting',
                        isGood: true,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransformationItem extends StatelessWidget {
  final String text;
  final bool isGood;
  final ThemeData theme;
  const _TransformationItem({
    required this.text,
    required this.isGood,
    required this.theme,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isGood ? LucideIcons.check : LucideIcons.x,
          color: isGood ? AppTheme.brandEmerald500 : Colors.redAccent,
          size: 20,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondaryCTASection extends StatelessWidget {
  const _SecondaryCTASection();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 48),
      child: Container(
        padding: const EdgeInsets.all(64),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.brandTeal900, Color(0xFF047857)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brandTeal900.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              "Afraid of the migration headache? Don't be.",
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 800,
              child: Text(
                'Our automated migration engine does the heavy lifting. You can preview your imported store on KloudShop *before* you ever change your DNS records or cancel your current platform. You have nothing to lose and tens of thousands of dollars in margin to gain.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 36),
            HoverScale(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.brandTeal900,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Start Your Risk-Free Migration',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 48),
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 48),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/logo3d.png',
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              LucideIcons.cloud,
                              color: AppTheme.brandEmerald500,
                              size: 22,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'KloudShop UK Ltd.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The zero-fee e-commerce engine for mid-market brands.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Legal',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FooterLink('Terms of Service', theme),
                    const SizedBox(height: 8),
                    _FooterLink('Privacy Policy', theme),
                    const SizedBox(height: 8),
                    _FooterLink('DPA (GDPR)', theme),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trust',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.shieldCheck,
                          size: 14,
                          color: AppTheme.brandEmerald500,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Stripe Verified Partner',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.server,
                          size: 14,
                          color: AppTheme.brandEmerald500,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Google Cloud Secured',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Text(
            '© ${DateTime.now().year} KloudShop UK Ltd. All rights reserved.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String title;
  final ThemeData theme;
  const _FooterLink(this.title, this.theme);
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
