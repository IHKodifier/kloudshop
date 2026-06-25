# Agent Execution Tracker (SSOT) - Phase 7 & 8

> **Purpose:** This is the Single Source of Truth (SSOT) for all AI Agents working on KloudShop's final phases.
> *Note: Phases 1 through 6 are completed and tracked in `07a-agent-execution-tracker.md` (Archived).*
>
> **Rule for Agents — MANDATORY SESSION START PROTOCOL:**
> 1. Read `00-MASTER-PRD.md` first (vision, commandments, architecture, epic map).
> 2. Read this file to find your assigned task and current sprint status.
> 3. Read `08a-api-specification.md` for the exact endpoint contract before writing any code.
> 4. Check `04b-mvp-scope.md` to confirm your story is MVP — do not implement Post-MVP features.
> 5. **Always update this tracker before handing back to the Human.**

---

## Current Environment Status

| Environment | GCP/Firebase Project | Git Branch | Status |
|-------------|----------------------|------------|--------|
| **Dev** | `kloudshop-dev` | `phase6/storefront-parity-ssr` | MVP Backend/Functional COMPLETE ✅ |
| **Staging** | `kloudshop-staging` | `dev` | Stable for QA |
| **Prod** | `kloudshop-prod` | `main` | Pending Phase 8 |

---

## Sprint 19 — Designer UI Implementation (COMPLETE ✅)

> [!NOTE]
> All Sprint 19 front-end views have been upgraded with premium glassmorphism, Outfit/Inter typography, and hover micro-animations. All backend tests pass.

- [x] **Dashboard Overview Restore:** Restore the charts and cards in the Dashboard Overview that were missing or flickering. Ensure they correctly reflect seeded demo data.
- [x] **Product Gallery Multi-image:** Expand the single `image_url` support to a full multi-image `List<String>` gallery in Catalog/Product Editor.
- [x] **Core Brand Identity:** Replace all skeletal components with premium, design-system-compliant UI tokens.
- [x] **Merchant Dashboard Overhaul:** Full high-fidelity overhaul of the admin interface (Dark mode, glassmorphism, fluid transitions).
- [x] **Landing Page Overhaul:** Complete conversion-focused 8-section architecture with Alpine Emerald styling.
- [x] **Premium UI Upgrade - Core Views:** Applied "Alpine Emerald" styling, glassmorphism, Outfit/Inter typography, and `HoverScale` micro-animations to all remaining views:
  - [x] Onboarding / Provisioning Page — animated rocket icon pulse, glassmorphism card, gradient CTA
  - [x] Catalog View — frosted product cards, emerald filter chips, gradient New Product button
  - [x] Orders View — glassmorphism order cards, customer avatars, styled fulfil dialog
  - [x] Customers View — replaced DataTable with color-coded avatar cards, stat chips
  - [x] Settings View — glassmorphism section cards with accent icons, gradient Save button
  - [x] Billing View — premium gradient status card, redesigned pricing cards with skeleton preview
  - [x] Blog View — frosted post cards, emerald image placeholders, blurred delete dialog
  - [x] Themes View — stylised storefront skeleton previews, gradient per-theme palette, HoverScale
- [x] **Storefront Themes:** Implement pixel-perfect designer versions of all default storefront templates.
- [x] **Global Visual Audit:** Manual "Surgical" pass on every single screen to ensure 100% parity with design taste.

---

## Active Overhaul Sprint: Storefront Settings & Theme Customizer Overhaul (Sprints 7 & 9)

> [!IMPORTANT]
> This sprint is dedicated to completely scraping the old Figma-style WYSIWYG editor and flat settings views, replacing them with a Shopify-cloned storefront settings and customization experience.

#### Sprints 7 & 9 — Database, API & UI Implementation
- [ ] **Database & Backend Migrations:**
  - [ ] Create `store_tax_rates` table for manual fallback rates.
  - [ ] Add `tax_category` and `stripe_tax_code` columns to the `products` table.
  - [ ] Add `collect_tax_automatically` and `tax_calculation_fallback` to `brand_profiles`.
  - [ ] Add `tax_breakdown` and `tax_calculation_source` to `orders`.
  - [ ] Create `shipping_profiles`, `shipping_zones`, and `shipping_rates` tables. Add `shipping_profile_id` to `variants`.
- [ ] **Tax & Shipping Backend Router Updates:**
  - [ ] Update `/tax/*` endpoints to handle Stripe Connect automatic calculations and query manual fallbacks.
  - [ ] Implement checkout tax calculation triggers bound to shipping address changes.
  - [ ] Update `/shipping/*` router to handle custom profiles, country zoning, weight/price conditional rates, and checkout rate blending.
- [ ] **Shopify Theme Customizer UI (Flutter Frontend):**
  - [ ] Replace `wysiwyg_view.dart` with a Shopify-cloned 3-pane layout:
    - [ ] Left vertical utility ribbon (Exit, Sections, Theme Settings, Native Features).
    - [ ] Center properties panel with a navigation stack for drill-down editing and back buttons.
    - [ ] Rightmost live preview canvas with desktop/mobile view toggles.
  - [ ] Implement bi-directional highlight linking between the outline tree and preview canvas.
  - [ ] Support reusable JSON page templates (Home, PDP, Cart) and custom template assignments.
  - [ ] Implement Named Style Presets (saving/loading design token combinations) and WCAG contrast check.
- [ ] **Settings & Brand Profile UI Upgrades:**
  - [ ] Build Taxes setting page: Stripe Connect Embedded view vs manual rate editor.
  - [ ] Build Shipping settings page: Shipping profiles directory, zones editor, and conditional flat rates builder.
  - [ ] Sync brand logo/favicon changes automatically with the active theme settings.
  - [ ] Update existing Product Add / Variant Creator UI to add `Charge tax on this product` (taxable) toggle and `Tax Category` dropdown selector.


---

## Active Sprint: PHASE 8 — Launch Readiness (Sprint 20)

> [!IMPORTANT]
> Focus on production infrastructure setup, custom domain routing, SSL provisioning, and final E2E UAT.

#### Sprint 20 — Production Infrastructure (E19 + E20)
- [ ] **Custom Domains:** CNAME verification and SSL auto-provisioning.
- [ ] **Platform Production:** Final terraform/scripts for `kloudshop-prod`.
- [ ] **Final UAT:** End-to-end "Minimum Value Loop" (Sign up → Design → Sell) using Mock Mode.

#### Sprint 21 — Production Handover (POST-LLC SETUP)
- [ ] **Stripe Live Mode:** Transition from Mock Billing to real Stripe once UK LLC is verified.
- [ ] **Connect Platform:** Final Live integration for merchant payouts and transaction fee collection.
- [ ] **Security Audit:** Pentesting RBAC and data isolation boundaries.
- [ ] **Public Launch:** Merge `dev` to `main` and activate marketing site.


---

## Agent Handoff Protocol

### When completing a task:
1. Verify all unit/integration tests pass.
2. Confirm implementation aligns perfectly with modern design standards.
3. Update this checklist: `[ ]` → `[x]`.
4. Update `Current Environment Status` table if infra/env changed.
5. Commit code with descriptive conventional commits.
6. Prompt the Human to run manual verification via IDE debugger or approve the next task.
