---
name: Alpine Emerald Dark
colors:
  surface: '#0f172a'
  surface-dim: '#0f172a'
  surface-bright: '#1e293b'
  surface-container-lowest: '#020617'
  surface-container-low: '#1e293b'
  surface-container: '#334155'
  surface-container-high: '#475569'
  surface-container-highest: '#64748b'
  on-surface: '#f8fafc'
  on-surface-variant: '#cbd5e1'
  inverse-surface: '#cbd5e1'
  inverse-on-surface: '#0f172a'
  outline: '#475569'
  outline-variant: '#334155'
  surface-tint: '#124b47'
  primary: '#124b47'
  on-primary: '#ffffff'
  primary-container: '#124b47'
  on-primary-container: '#ffffff'
  inverse-primary: '#124b47'
  secondary: '#134e4a'
  on-secondary: '#ffffff'
  secondary-container: '#1e293b'
  on-secondary-container: '#cbd5e1'
  tertiary: '#047857'
  on-tertiary: '#ffffff'
  tertiary-container: '#065f46'
  on-tertiary-container: '#34d399'
  error: '#ef4444'
  on-error: '#ffffff'
  error-container: '#450a0a'
  on-error-container: '#fecaca'
  primary-fixed: '#124b47'
  primary-fixed-dim: '#124b47'
  on-primary-fixed: '#ffffff'
  on-primary-fixed-variant: '#124b47'
  secondary-fixed: '#1e293b'
  secondary-fixed-dim: '#1e293b'
  on-secondary-fixed: '#cbd5e1'
  on-secondary-fixed-variant: '#cbd5e1'
  tertiary-fixed: '#065f46'
  tertiary-fixed-dim: '#34d399'
  on-tertiary-fixed: '#dde4dd'
  on-tertiary-fixed-variant: '#34d399'
  background: '#020617'
  on-background: '#f8fafc'
  surface-variant: '#1e293b'
typography:
  display:
    fontFamily: Manrope
    fontSize: 48px
    fontWeight: '800'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Manrope
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
  headline-md:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.3'
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: '1.4'
    letterSpacing: 0.05em
  headline-lg-mobile:
    fontFamily: Manrope
    fontSize: 28px
    fontWeight: '700'
    lineHeight: '1.2'
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 48px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 64px
---

## Brand & Style

The design system is a high-performance, sophisticated dark theme that balances the organic depth of a dense forest with the precision of modern engineering. It is designed for users who require extended focus and professional-grade clarity, evoking a sense of calm, premium stability, and rhythmic efficiency.

The aesthetic blends **Minimalism** with **Tonal Layering**. By utilizing a monochromatic foundation of deep greens punctuated by vibrant emerald strikes, the UI achieves a "biophilic-tech" feel. The style is intentionally bold yet understated, prioritizing legibility and structural integrity over decorative flair.

## Colors

The color palette is rooted in the "Deep Forest" and "Brand Teal" spectrums, designed to minimize eye strain and maximize depth.

- **Primary Brand Teal (#124B47):** A deep teal used for primary elements, active controls, and main theme actions.
- **Vibrant Success Emerald (#34D399):** The high-contrast green accent used for positive status labels, charts, and successful events.
- **Background (#020617):** Real deep black used for the main scaffold canvas to ensure absolute contrast.
- **Surface (#0F172A):** Slate 900 base used for cards, navigation bars, and panels.
- **Surface Container Low (#1E293B):** Slate 800 surface layer used for secondary containers, inputs, and active list item regions.
- **Typography:** High-contrast text uses Slate 50 (#F8FAFC) for premium readability. Secondary text uses Slate 300 (#CBD5E1) to establish clear information hierarchy.
- **Accents:** Amber (#FBBF24 / #F59E0B) is reserved strictly for critical actions, warnings, or high-priority notifications.

## Typography

This design system utilizes a trio of typefaces to establish its technical-sophisticate persona:

- **Manrope** serves as the headline face. Its modern, geometric construction feels architectural and refined.
- **Inter** handles the bulk of body copy. Chosen for its exceptional legibility in dark-mode environments and its neutral, systematic utilitarianism.
- **JetBrains Mono** is used for small labels, data points, and metadata. This adds a "high-performance" technical edge to the UI, suggesting precision and data-driven roots.

Keep line lengths for body text between 45-75 characters to ensure comfortable reading against the dark background.

## Layout & Spacing

The layout follows a **Fluid Grid** model with a strict 4px baseline rhythm. 

- **Desktop:** 12-column grid with 24px gutters and 64px outer margins.
- **Tablet:** 8-column grid with 24px gutters and 32px outer margins.
- **Mobile:** 4-column grid with 16px gutters and 16px outer margins.

Spacing should favor generosity to avoid the "cramped" feeling often associated with dark themes. Use `xl` spacing to separate major content sections, ensuring the Deep Forest background provides enough "breathing room" for the Near-black Emerald surfaces to stand out.

## Elevation & Depth

Depth is achieved through **Tonal Layering** and **Tinted Shadows**. Instead of using traditional grey-scale shadows, this system uses a "Green Gloom" approach:

1.  **Level 0 (Background):** #064E3B. The furthest layer back.
2.  **Level 1 (Surface):** #022C22. Used for cards and primary containers. 
3.  **Level 2 (Raised):** Same as Surface, but with a subtle 1px border of #10B981 at 15% opacity and a soft shadow (0px 4px 20px) tinted with #022C22 at 50% opacity.
4.  **Level 3 (Overlay):** Used for modals. Increased border opacity (25%) and a larger, more diffused shadow to pull the element toward the user.

Shadows should never be black; they must always be a darker, more saturated version of the background green to maintain the organic, immersive atmosphere.

## Shapes

The design system employs a consistent **12px border radius** (Level 2: Rounded) for all primary components like buttons, cards, and input fields. 

- **Small Components:** Tooltips and tags may use a reduced 4px (Soft) radius to maintain crispness at small scales.
- **Interactive Elements:** Buttons and form inputs must adhere to the 12px standard to create a friendly, tactile interface that contrasts against the sharp, technical typography.
- **Containers:** Large layout containers or sections may increase to 24px (rounded-xl) for a more immersive, "contained" look.

## Components

- **Buttons:** Primary buttons use the Brand Teal (#124B47) with White text. Secondary buttons use an outline of the primary color with no fill. Critical buttons use the Amber accent (#F59E0B).
- **Inputs:** Input fields use the Surface Container Low color (#1E293B) with a 1px border of Slate 600 (#475569). Upon focus, the border glows with Brand Teal.
  - **Semantic Prefix Patterns**: Form inputs that represent specific system semantics (e.g., prices, weights, dimensions, codes, credentials) must leverage `SemanticTextFormField` to display a left-aligned, shaded prefix container containing an icon or text matching that semantic.
    - Custom brand colors: Shaded prefix container uses `Color(0xFF334155)` background, a `Color(0xFF475569)` right border, and `Color(0xFF34D399)` (Vibrant Success Emerald) icon/text color in dark mode.
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
- **Chips/Tags:** Small, 4px rounded containers with a background of #124B47 at 10% opacity and text in the primary color.
- **Cards:** Defined by the 12px radius, Surface color (#0F172A), and the Slate 700 divider. No heavy borders; let the tonal layering define the edge.
- **Checkboxes & Radios:** When active, these are solid Brand Teal (#124B47) or Success Emerald (#34D399) with high-contrast indicator marks.

### Toggle Switches
- **Mandatory Toggle Component**: `LottieToggle` is the default widget for any toggle switch across all screens. Do **not** use the default Flutter `Switch` or `Switch.adaptive`.
- **List Item Settings**: For standard setting rows, use `LottieSwitchListTile` (from `lib/widgets/lottie_toggle.dart`), which packages the `LottieToggle` widget with standardized title, subtitle, and layout. Do **not** use `SwitchListTile`.
- **Global Animation Speed Config**: The transition animation speed/delay is controlled globally via `LottieToggle.defaultDuration` (defined in `lib/widgets/lottie_toggle.dart`). Changing this updates all switches simultaneously.