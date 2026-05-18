# Phase 7 (Sprint 19) Premium UI Upgrade Handoff

## Context
The "Surgical UI/UX Overhaul" (Phase 7 - Sprint 19) for KloudShop has commenced. We are applying the new "Alpine Emerald" premium design system across the entire application to replace all minimum viable product (MVP) screens with a high-fidelity, designer-quality look.

**What we have completed so far:**
1. **Landing Page:** Converted to an 8-section architecture with the new design system.
2. **Dashboard Page (`dashboard_page.dart`):** Refactored with Glassmorphism (`BackdropFilter` with blur), global micro-animations (`HoverScale`), and advanced typography (Outfit/Inter).
3. **Data Models & Catalog:** `Product` model has been refactored to support a multi-image `List<String> images` gallery instead of a single `image_url`. The product editor now features an interactive image grid.
4. **App Theme:** `app_theme.dart` is correctly configured with `GoogleFonts.outfit` for display/headlines, `GoogleFonts.inter` for body, and `brandEmerald500` & `brandTeal500` color palettes.
5. **SSOT Updated:** The `specifications/07b-agent-execution-tracker-ui-launch.md` tracker has been updated. All legacy handoffs were purged.

## Current Blockers / Next Steps
The UI upgrade is **NOT complete**. Only the landing page and the dashboard overview have the premium styling. All other user journeys and screens are still using older, rigid MVP styling. 

**Your Task for the Next Session:**
You need to systematically go through the remaining core views and apply the "Alpine Emerald" styling, Glassmorphism, Outfit/Inter typography, and `HoverScale` animations.

Please start by upgrading the following screens one by one, checking them off in `specifications/07b-agent-execution-tracker-ui-launch.md` as you complete them:
- `provisioning_page.dart` (Onboarding)
- `catalog_view.dart` & `product_editor_view.dart` (Finish any missing visual polishes)
- `orders_view.dart`
- `customers_view.dart`
- `settings_view.dart`
- `billing_view.dart`
- `blog_view.dart`
- `themes_view.dart`

## Key UI Guidelines to Enforce
- **Glassmorphism:** Use `ClipRRect` and `BackdropFilter` (blur 10-15) over semi-transparent backgrounds (`color.withValues(alpha: 0.1)`) instead of flat solid colors for cards and dialogs.
- **Micro-Animations:** Import and wrap interactive items (buttons, cards, list tiles) with `HoverScale` from `widgets/hover_scale.dart`.
- **Typography:** Ensure `theme.textTheme.headlineLarge/Medium` etc. are used correctly so they pick up the `Outfit` font, and `bodyLarge/Medium` pick up `Inter`.
- **Borders & Shadows:** Use very subtle borders (`theme.dividerColor.withValues(alpha: 0.5)`) and soft, deep shadows (`blurRadius: 15`).

**SSOT:** Always refer to `specifications/07b-agent-execution-tracker-ui-launch.md` as your single source of truth.

When you resume, run the flutter app (`flutter run -d chrome` or check backend) to verify the current look, then begin with `provisioning_page.dart` or `catalog_view.dart`.
