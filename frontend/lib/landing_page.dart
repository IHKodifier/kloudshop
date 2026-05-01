import 'package:flutter/material.dart';
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
    final appColors = theme.extension<AppColors>()!;
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

            // --- Hero Section ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 80),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: SelectableText(
                            'Now in Beta',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SelectableText(
                          'The Multi-Tenant B2B Commerce Platform for Scale.',
                          style: theme.textTheme.displayLarge,
                        ),
                        const SizedBox(height: 24),
                        SelectableText(
                          'KloudShop handles the complexity of wholesale, multi-brand isolation, and tenant provisioning, so you can focus on growth. Built on a pure API-only architecture for ultimate flexibility.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text('Launch Your Store'),
                            ),
                            const SizedBox(width: 16),
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(LucideIcons.play, size: 18),
                              label: const Text('Watch Demo'),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                            color: theme.colorScheme.onSurface.withAlpha(25),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          isDark ? 'web/landing_hero_dark.png' : 'web/landing_hero.png',
                          errorBuilder: (context, error, stackTrace) => Image.asset('web/landing_hero.png'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Features Summary ---
            Container(
              padding: const EdgeInsets.all(80),
              color: theme.colorScheme.surface,
              child: Column(
                children: [
                  SelectableText(
                    'Engineered for Performance',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: appColors.success,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    'Everything you need to run a global commerce network.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayMedium,
                  ),
                  const SizedBox(height: 64),
                  Row(
                    children: [
                      _FeatureCard(
                        icon: LucideIcons.users,
                        title: 'Multi-Tenancy',
                        description: 'Isolated schemas for every merchant with shared platform authority.',
                        iconColor: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 32),
                      _FeatureCard(
                        icon: LucideIcons.zap,
                        title: 'FastAPI Core',
                        description: 'Sub-100ms response times for all critical commerce endpoints.',
                        iconColor: appColors.success,
                      ),
                      const SizedBox(width: 32),
                      _FeatureCard(
                        icon: LucideIcons.shieldCheck,
                        title: 'Secure by Design',
                        description: 'Built-in RBAC, Firebase Auth, and App Check protection.',
                        iconColor: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
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

class _FeatureCard extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 24),
            SelectableText(
              title,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            SelectableText(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
