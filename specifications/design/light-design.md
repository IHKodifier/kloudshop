---
name: Alpine Emerald OS
colors:
  surface: '#ffffff'
  surface-dim: '#f3f4f6'
  surface-bright: '#ffffff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f9fafb'
  surface-container: '#f3f4f6'
  surface-container-high: '#e5e7eb'
  surface-container-highest: '#9ca3af'
  on-surface: '#111827'
  on-surface-variant: '#6b7280'
  inverse-surface: '#111827'
  inverse-on-surface: '#ffffff'
  outline: '#e5e7eb'
  outline-variant: '#f3f4f6'
  surface-tint: '#124B47'
  primary: '#124B47'
  on-primary: '#ffffff'
  primary-container: '#f0fdfa'
  on-primary-container: '#134e4a'
  inverse-primary: '#ecfdf5'
  secondary: '#134e4a'
  on-secondary: '#ffffff'
  secondary-container: '#ecfdf5'
  on-secondary-container: '#065f46'
  tertiary: '#047857'
  on-tertiary: '#ffffff'
  tertiary-container: '#ecfdf5'
  on-tertiary-container: '#047857'
  error: '#ef4444'
  on-error: '#ffffff'
  error-container: '#fef2f2'
  on-error-container: '#ef4444'
  primary-fixed: '#f0fdfa'
  primary-fixed-dim: '#124b47'
  on-primary-fixed: '#134e4a'
  on-primary-fixed-variant: '#124b47'
  secondary-fixed: '#ecfdf5'
  secondary-fixed-dim: '#134e4a'
  on-secondary-fixed: '#134e4a'
  on-secondary-fixed-variant: '#134e4a'
  tertiary-fixed: '#ecfdf5'
  tertiary-fixed-dim: '#047857'
  on-tertiary-fixed: '#047857'
  on-tertiary-fixed-variant: '#047857'
  background: '#ffffff'
  on-background: '#111827'
  surface-variant: '#f3f4f6'
typography:
  display-lg:
    fontFamily: Outfit
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.04em
  display-lg-mobile:
    fontFamily: Outfit
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.03em
  headline-md:
    fontFamily: Outfit
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.02em
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
    letterSpacing: 0em
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0em
  label-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  container-max: 1440px
  gutter: 24px
  margin-desktop: 64px
  margin-mobile: 20px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 32px
  section-gap: 80px
---

## Brand & Style

The design system embodies a "High-Altitude Performance" aesthetic, blending the serene, spacious clarity of Alpine Minimalism with the rich, authoritative depth of Deep Emerald. It is engineered for an e-commerce operating system that prioritizes speed, precision, and luxury.

The visual direction avoids unnecessary ornamentation, focusing instead on structural integrity and breathtaking whitespace. The emotional response is one of calm confidence—evoking a sense of premium reliability and sustainable growth. The interface feels less like a website and more like a high-precision instrument for commerce.

## Colors

The palette is anchored by **Brand Teal Dark (#134E4A)**, used for heavy typography, navigation headers, and gradients to establish authority. **Brand Teal Primary (#124B47)** serves as the primary functional accent, reserved for conversion-driving actions and primary UI highlights. 

**Brand Emerald Primary (#047857)** is the high-contrast emerald green color used for positive growth indicators, success states, active badges, and focus borders.

Backgrounds utilize a tiered system: **Pure White (#FFFFFF)** for primary content containers to ensure maximum clarity, and **Neutral 50 (#F9FAFB)** and **Neutral 100 (#F3F4F6)** for secondary canvases and backgrounds. Text contrast is maintained at AAA levels using a dark neutral color (#111827) for body copy to ensure excellent readability.

## Typography

This design system utilizes a dual-font strategy. **Outfit** is used for headings to provide a geometric, tech-forward character. To maintain the "Alpine" precision, headings use tight negative tracking (letter-spacing) to feel "locked-in" and architectural.

**Inter** is utilized for all functional UI elements, body text, and data points. It provides the utilitarian clarity required for complex e-commerce management. Large display sizes scale down aggressively for mobile to maintain the layout's high-contrast impact without breaking the grid.

## Layout & Spacing

The layout follows a **Fixed Grid** philosophy for desktop to maintain a premium, editorial feel, while transitioning to a fluid model for tablet and mobile. A 12-column system is used with generous 24px gutters.

Whitespace is treated as a first-class citizen. Section gaps are intentionally large (80px+) to prevent the interface from feeling cluttered or "cheap." Internal component spacing follows a strict 4px base unit, ensuring a mathematical rhythm across the entire OS.

## Elevation & Depth

Depth is achieved through **low-diffusion, high-precision shadows** that mimic a direct overhead light source. This creates a "hovering" effect rather than a "glowing" one, aligning with the minimalist aesthetic.

We use three primary elevation levels:
1.  **Flat:** Used for the main background and secondary layout zones (Mist Green).
2.  **Level 1 (Surface):** Pure White cards with a subtle 1px border (#E2E8F0) and no shadow, used for standard content.
3.  **Level 2 (Elevated):** Pure White surfaces with a tight shadow (Y: 4px, Blur: 12px, Opacity: 6% Black) used for active states, dropdowns, and modals.

## Shapes

The design system employs a consistent **12px (0.75rem) border radius** for all primary containers and components. This specific radius bridges the gap between the sharpness of traditional minimalist design and the approachability of modern SaaS tools.

Small UI elements like checkboxes and tags use a reduced 4px radius to maintain a sense of precision, while "Hero" elements and large image containers strictly adhere to the 12px standard.

// Components

/// Buttons
- **Primary:** Deep Forest Green (#064E3B) background with White text. Bold, authoritative.
- *+Action:** Brand Teal (#124B47) background. Used exclusively for "Add to Cart," "Publish," or "Finalize."
- **Secondary:** Transparent background with a 1.5px Deep Forest Green border.

### Input Fields
- Fields use a Pure White background with a subtle Grey-Slate border. On focus, the border shifts to Deep Forest Green with a 2px outer ring of soft Mist Green.
- **Semantic Prefix Patterns**: Form inputs that represent specific system semantics (e.g., prices, weights, dimensions, codes, credentials) must leverage `SemanticTextFormField` to display a left-aligned, shaded prefix container containing an icon or text matching that semantic.
  - Custom brand colors: Shaded prefix container uses `Color(0xFFECFDF5)` background, a `Color(0xFFA7F3D0)` right border, and `AppTheme.brandEmerald500` icon/text color in light mode.
  - Icon mapping rules:
    - Emails / Accounts: `LucideIcons.mail`
    - Passwords / Keys: `LucideIcons.lock`
    - Street / Addresses: `LucideIcons.mapPin`
    - Weight / Scales: `LucideIcons.scale`
    - Dimensions (L / W / H): `LucideIcons.ruler`
    - SKU / Product Tags: `LucideIcons.tag`
    - Colors / Hex: `LucideIcons.palette`
    - Domains / URLs: `LucideIcons.globe`
    - Carrier / Shipping: `LucideIcons.truck`
    - Barcode / Tracking: `LucideIcons.barcode`
    - Search Query: `LucideIcons.search`
    - Pricing / Currency: Text prefix overlay (e.g. `$`)
  - Standard/Narrative text fields (like titles, descriptions, slugs) must use `SemanticTextFormField` with `prefixIcon: null` to keep the layout clean and uncluttered.

### Cards
- Standard cards feature a 12px radius, a Pure White background, and a subtle 1px border. They do not use shadows unless they are "interactive" or "hoverable," at which point they transition to Level 2 elevation.

### Data Tables
- High-density layouts with zero borders between rows; instead, use alternating "Mist Green" zebra striping for horizontal rhythm. Headers are in `label-sm` (uppercase) for clear categorization.

### Status Indicators
- Utilize the Brand Emerald for success/growth and a refined, desaturated coral for errors, ensuring the primary green palette remains the dominant visual force.

### Toggle Switches
- **Mandatory Toggle Component**: `LottieToggle` is the default widget for any toggle switch across all screens. Do **not** use the default Flutter `Switch` or `Switch.adaptive`.
- **List Item Settings**: For standard setting rows, use `LottieSwitchListTile` (from `lib/widgets/lottie_toggle.dart`), which packages the `LottieToggle` widget with standardized title, subtitle, and layout. Do **not** use `SwitchListTile`.
- **Global Animation Speed Config**: The transition animation speed/delay is controlled globally via `LottieToggle.defaultDuration` (defined in `lib/widgets/lottie_toggle.dart`). Changing this updates all switches simultaneously.