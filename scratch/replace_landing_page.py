"""
Utility script to replace the contents of `landing_page.dart`.
This script injects the 8-section conversion-first architecture (based on the landing page blueprint)
into the KloudShop frontend.

Usage: Run this script directly (`python replace_landing_page.py`) to overwrite the dart file.
"""
import os

# Target file to overwrite with the new layout
file_path = r"e:\Non_Office\Dev_Space\vibe_skool\kloudShop\frontend\lib\landing_page.dart"

# The new Flutter code for the landing page containing all 8 modular sections
new_content = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/providers/theme_provider.dart';
import 'package:kloudshop/login_page.dart';

class KloudShopLandingPage extends ConsumerWidget {
  const KloudShopLandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Navigation Bar ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
              color: theme.colorScheme.surface,
              child: Row(
                children: [
                  // Standardized Logo logic
                  SizedBox(
                    height: 56,
                    child: Image.asset(
                      isDark ? 'assets/logo_dark.png' : 'assets/logo.png',
                      fit: BoxFit.contain,
                      semanticLabel: 'KloudShop Logo',
                      errorBuilder: (context, error, stackTrace) => Row(
                        children: [
                          Icon(
                            LucideIcons.cloud,
                            color: theme.colorScheme.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          SelectableText(
                            'KloudShop',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                        
                      ),
                    ),
                  ),
                  const Spacer(),
                  _navItem(context, 'Features'),
                  _navItem(context, 'Solutions'),
                  _navItem(context, 'Pricing'),
                  const SizedBox(width: 32),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                    child: const Text(
                      'Merchant Login',
                      style: TextStyle(fontWeight: FontWeight.w500),
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
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(fontWeight: FontWeight.w600),
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
      child: SelectableText(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurfaceVariant,
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
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 80),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  'Stop Paying a Tax on Your Own Growth.',
                  style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 24),
                SelectableText(
                  'The e-commerce operating system for mid-market brands. Run B2B and DTC from one unified engine, replace your expensive app stack with native features, and never pay a transaction fee again.',
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 20, height: 1.5, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Start Your 30-Day Free Trial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(LucideIcons.checkCircle2, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: SelectableText(
                        'No credit card required. Migrate your Shopify or WooCommerce store in 2 minutes.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                )
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
                    color: theme.colorScheme.onSurface.withOpacity(0.05),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  isDark ? 'web/landing_hero_dark.png' : 'web/landing_hero.png',
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 400,
                    color: theme.colorScheme.surfaceContainerHigh,
                    child: Center(
                      child: Icon(LucideIcons.image, size: 64, color: theme.colorScheme.onSurfaceVariant),
                    ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 48),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          SelectableText(
            'Live in 2 minutes. No developer required.',
            style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 800,
            child: SelectableText(
              'Paste your current store URL. Our AI migration engine imports your entire product catalogue, variants, and SEO metadata before your coffee gets cold.',
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 64),
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MigrationStep(icon: LucideIcons.search, title: 'Detected Shopify', isActive: true, theme: theme),
                Icon(LucideIcons.arrowRight, color: theme.colorScheme.onSurfaceVariant),
                _MigrationStep(icon: LucideIcons.packageIcon, title: 'Read 847 Products', isActive: true, theme: theme),
                Icon(LucideIcons.arrowRight, color: theme.colorScheme.onSurfaceVariant),
                _MigrationStep(icon: LucideIcons.fileSearch, title: 'Preserved SEO', isActive: true, theme: theme),
                Icon(LucideIcons.arrowRight, color: theme.colorScheme.onSurfaceVariant),
                _MigrationStep(icon: LucideIcons.checkCircle2, title: 'Store Ready', isActive: true, theme: theme, isFinal: true),
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
  final bool isActive;
  final bool isFinal;
  final ThemeData theme;
  const _MigrationStep({required this.icon, required this.title, required this.isActive, this.isFinal = false, required this.theme});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isFinal ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isFinal ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface, size: 32),
        ),
        const SizedBox(height: 16),
        SelectableText(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isFinal ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        )
      ],
    );
  }
}

class _ProblemAgitateSection extends StatelessWidget {
  const _ProblemAgitateSection();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 48),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SelectableText(
                    'The Problem',
                    style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onErrorContainer, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                SelectableText(
                  "You're trapped in the App Store ecosystem.",
                  style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 24),
                SelectableText(
                  "You're paying \$2,000/month for a platform, and another \$1,500/month for 15 third-party apps just to get basic B2B pricing and wholesale features. And every time the platform updates, your checkout breaks. You aren't running a business anymore—you're managing a fragile tech stack.",
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 20, height: 1.6, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 80),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText('Monthly Tech Tax', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 24),
                  _CostItem(title: 'Base Platform Fee', cost: '\$2,000/mo', theme: theme),
                  const SizedBox(height: 16),
                  _CostItem(title: 'B2B Wholesale Portal App', cost: '\$399/mo', theme: theme),
                  const SizedBox(height: 16),
                  _CostItem(title: 'Tiered Pricing App', cost: '\$149/mo', theme: theme),
                  const SizedBox(height: 16),
                  _CostItem(title: 'Subscription App', cost: '\$299/mo', theme: theme),
                  const SizedBox(height: 16),
                  _CostItem(title: 'Transaction Fees (1.5%)', cost: 'Scale Penalty', theme: theme, isPenalty: true),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SelectableText('Total Frustration', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      SelectableText('Too High', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.error)),
                    ],
                  )
                ],
              ),
            ),
          )
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
  const _CostItem({required this.title, required this.cost, required this.theme, this.isPenalty = false});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SelectableText(title, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        SelectableText(cost, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: isPenalty ? theme.colorScheme.error : theme.colorScheme.onSurface)),
      ],
    );
  }
}

class _ValueStackSection extends StatelessWidget {
  const _ValueStackSection();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 48),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          SelectableText(
            'Everything you need is already built in.',
            style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ValueCard(
                icon: LucideIcons.layers,
                title: 'Unified B2B & DTC Engine',
                description: 'Stop managing two separate stores. One inventory, two distinct shopping experiences, unified analytics.',
                theme: theme,
              ),
              const SizedBox(width: 32),
              _ValueCard(
                icon: LucideIcons.blocks,
                title: 'Native Feature Catalogue',
                description: 'Say goodbye to paid apps. Wholesale portals, tiered pricing, AI replenishment, and subscriptions—all native, all free to toggle on.',
                theme: theme,
              ),
              const SizedBox(width: 32),
              _ValueCard(
                icon: LucideIcons.creditCard,
                title: 'Flat, Predictable Pricing',
                description: '\$24.99 to \$49.99 a month. Plus your raw GCP infrastructure cost. We take 0% of your GMV. When you grow, your margins stay yours.',
                theme: theme,
              ),
            ],
          )
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
  const _ValueCard({required this.icon, required this.title, required this.description, required this.theme});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 32),
            ),
            const SizedBox(height: 24),
            SelectableText(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            SelectableText(description, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5, color: theme.colorScheme.onSurfaceVariant)),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 48),
      child: Column(
        children: [
          SelectableText(
            'The brands escaping the platform tax.',
            style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          Container(
            padding: const EdgeInsets.all(64),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ]
            ),
            child: Column(
              children: [
                Icon(LucideIcons.quote, size: 48, color: theme.colorScheme.primary.withOpacity(0.5)),
                const SizedBox(height: 24),
                SelectableText(
                  '"We were paying Shopify Plus \$2,500 a month and still had to bolt on \$800 of B2B apps. We migrated to KloudShop in an afternoon. Our storefront is twice as fast, our B2B portal is finally connected to our retail inventory, and our tech bill dropped by 90%."',
                  style: theme.textTheme.headlineMedium?.copyWith(height: 1.6, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(LucideIcons.user, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText('Sarah Jenkins', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        SelectableText('CFO, Mid-Market Wholesaler', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    )
                  ],
                )
              ],
            ),
          )
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 48),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          SelectableText(
            'From duct-tape to enterprise-grade.',
            style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText('The Old Way', style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 32),
                      _TransformationItem(text: '14 third-party apps', isGood: false, theme: theme),
                      const SizedBox(height: 24),
                      _TransformationItem(text: 'Desynced B2B inventory', isGood: false, theme: theme),
                      const SizedBox(height: 24),
                      _TransformationItem(text: 'Punishing transaction fees', isGood: false, theme: theme),
                      const SizedBox(height: 24),
                      _TransformationItem(text: 'Constant developer maintenance', isGood: false, theme: theme),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 48),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText('The KloudShop Way', style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 32),
                      _TransformationItem(text: '1 native codebase', isGood: true, theme: theme),
                      const SizedBox(height: 24),
                      _TransformationItem(text: 'Perfectly synced multi-channel inventory', isGood: true, theme: theme),
                      const SizedBox(height: 24),
                      _TransformationItem(text: '0% platform transaction fees', isGood: true, theme: theme),
                      const SizedBox(height: 24),
                      _TransformationItem(text: 'Automated AI stock forecasting', isGood: true, theme: theme),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _TransformationItem extends StatelessWidget {
  final String text;
  final bool isGood;
  final ThemeData theme;
  const _TransformationItem({required this.text, required this.isGood, required this.theme});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(isGood ? LucideIcons.check : LucideIcons.x, color: isGood ? theme.colorScheme.primary : theme.colorScheme.error, size: 24),
        const SizedBox(width: 16),
        Expanded(child: SelectableText(text, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500))),
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
      padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 48),
      child: Container(
        padding: const EdgeInsets.all(80),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.primary.withBlue(200)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Column(
          children: [
            SelectableText(
              'Afraid of the migration headache? Don\'t be.',
              style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 800,
              child: SelectableText(
                'Our automated migration engine does the heavy lifting. You can preview your imported store on KloudShop *before* you ever change your DNS records or cancel your current platform. You have nothing to lose and tens of thousands of dollars in margin to gain.',
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 20, color: theme.colorScheme.onPrimary.withOpacity(0.9), height: 1.6),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.onPrimary,
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Start Your Risk-Free Migration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 48),
      color: theme.colorScheme.surface,
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
                        Icon(LucideIcons.cloud, color: theme.colorScheme.primary, size: 24),
                        const SizedBox(width: 8),
                        SelectableText('KloudShop UK Ltd.', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SelectableText('The zero-fee e-commerce engine for mid-market brands.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText('Legal', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                    SelectableText('Trust', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(LucideIcons.shieldCheck, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        SelectableText('Stripe Verified Partner', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(LucideIcons.server, size: 16, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        SelectableText('Google Cloud Secured', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          SelectableText(
            '© ${DateTime.now().year} KloudShop UK Ltd. All rights reserved.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
      child: SelectableText(title, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, decoration: TextDecoration.underline)),
    );
  }
}
"""

with open(file_path, "w", encoding="utf-8") as f:
    f.write(new_content)
print("Updated landing_page.dart successfully!")
