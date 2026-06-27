import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

/// Descriptor for a platform-level feature module that merchants can toggle
/// on/off in the theme customizer's Native Embeds panel.
///
/// New modules are added by the Kloudshop platform owner — they appear
/// automatically in every merchant's embeds panel.
class KloudFeatureModule {
  /// Unique machine-readable identifier (e.g. 'wholesale_b2b').
  final String id;

  /// Human-readable display name (e.g. 'Wholesale B2B Display').
  final String label;

  /// Educational copy shown when the module is disabled.
  final String description;

  /// Icon displayed next to the module in the panel.
  final IconData icon;

  /// Minimum subscription plan tier required to use this module.
  /// `null` means available to all plans.
  final String? minPlanTier;

  /// The section type injected into the layout tree when toggled on.
  /// `null` means this module operates as a floating embed (no layout section).
  final String? themeSectionType;

  /// The default group to insert into ('header', 'template', 'footer', 'floating').
  final String insertionGroup;

  const KloudFeatureModule({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    this.minPlanTier,
    this.themeSectionType,
    this.insertionGroup = 'template',
  });
}

/// Central registry of all platform features available in the customizer.
///
/// To add a new feature to the platform:
/// 1. Add a new [KloudFeatureModule] entry to [defaultModules].
/// 2. It will automatically appear in every merchant's Native Embeds panel.
/// 3. Optionally gate it behind a plan tier using [minPlanTier].
class FeatureRegistry {
  FeatureRegistry._();

  static final FeatureRegistry instance = FeatureRegistry._();

  /// Master list of all platform features. Order determines display order.
  final List<KloudFeatureModule> defaultModules = const [
    KloudFeatureModule(
      id: 'wholesale_b2b',
      label: 'Wholesale B2B Display',
      description:
          'Enable a dedicated buyer portal and wholesale pricing display on your storefront for B2B customers.',
      icon: LucideIcons.building2,
      minPlanTier: 'pro',
      themeSectionType: 'wholesale_showcase',
      insertionGroup: 'template',
    ),
    KloudFeatureModule(
      id: 'customer_reviews',
      label: 'Customer Reviews',
      description:
          'Show verified customer reviews and star ratings on product pages to build trust and drive conversions.',
      icon: LucideIcons.star,
      themeSectionType: 'reviews_strip',
      insertionGroup: 'template',
    ),
    KloudFeatureModule(
      id: 'live_chat',
      label: 'Live Chat Widget',
      description:
          'Add a floating live chat bubble to your storefront so customers can reach you in real time.',
      icon: LucideIcons.messageCircle,
      themeSectionType: null, // floating embed, no layout section
      insertionGroup: 'floating',
    ),
    KloudFeatureModule(
      id: 'newsletter_popup',
      label: 'Newsletter Popup',
      description:
          'Display a timed newsletter signup popup to capture visitor emails and grow your subscriber list.',
      icon: LucideIcons.mail,
      themeSectionType: 'newsletter_modal',
      insertionGroup: 'floating',
    ),
    KloudFeatureModule(
      id: 'cookie_consent',
      label: 'Cookie Consent Banner',
      description:
          'Show a GDPR/CCPA-compliant cookie consent banner to visitors. Required for EU storefronts.',
      icon: LucideIcons.cookie,
      themeSectionType: 'cookie_banner',
      insertionGroup: 'floating',
    ),
    KloudFeatureModule(
      id: 'social_proof',
      label: 'Social Proof Notifications',
      description:
          'Display real-time purchase notifications ("Someone just bought...") to create urgency and social proof.',
      icon: LucideIcons.bellRing,
      themeSectionType: 'social_proof_bubble',
      insertionGroup: 'floating',
    ),
  ];

  /// Returns all modules available for a given plan tier.
  List<KloudFeatureModule> modulesForPlan(String? currentPlan) {
    return defaultModules.where((m) {
      if (m.minPlanTier == null) return true;
      // Simple tier ordering: free < starter < pro < enterprise
      const tiers = ['free', 'starter', 'pro', 'enterprise'];
      final moduleIdx = tiers.indexOf(m.minPlanTier!);
      final currentIdx = tiers.indexOf(currentPlan ?? 'free');
      return currentIdx >= moduleIdx;
    }).toList();
  }
}
