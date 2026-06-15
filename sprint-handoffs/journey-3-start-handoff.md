# Sprint Handoff: Entering Journey 3 — DTC Consumer Storefront

This handoff brief sets the stage for the next agent to implement **Journey 3: DTC Consumer Storefront** (Phase 7 UI/UX Overhaul).

---

## ⚠️ CRITICAL FIRST STEP: Consult the Changelog
Before writing any code or analyzing the workspace files, you **MUST** consult [changelog.md](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/specifications/changelog.md). 

During the development of Journey 1 and Journey 2, several cross-cutting architecture changes and security features were introduced that are **not** present in the original design specifications:
*   **Variant Stock Serialization**: Stock is now represented as a computed property in the `Variant` model and eager-loaded on catalog endpoints to sync with the database `Inventory` tables.
*   **Root-Level Asset Fallthrough Routing**: A route resolver handles static assets (like `/flutter_bootstrap.js`, etc.) dynamically in `ssr_router.py`.
*   **Security Lockout Rules**: Active cooldown and strike rules are implemented on login.
*   **Lottie Animation Speed Rule**: App-wide toggles must respect `LottieToggle.defaultDuration` (preset to `1800ms`) inside `lib/widgets/lottie_toggle.dart`.
*   **Intelligent Variant Reconciliation**: Change confirmation overlays appear when mutating options schemas.

Ensure you check [changelog.md](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/specifications/changelog.md) to maintain parity with these updates.

---

## 1. Git Branching Protocol
1.  Verify the current status: `git status`. (The previous agent left the repository on `phase7/j2-catalog`).
2.  Commit any remaining changes on `phase7/j2-catalog`.
3.  if `phase7/j2-catalog` is merged with dev, then 
4.  Checkout a new branch for this journey from 'dev' branch: `git checkout -b phase7/j3-storefront`.

---

## 2. Active Journey 3 Work Items
You will implement the high-fidelity designer views, assets, and Riverpod state configurations for the consumer storefront. Refer to [07c-phase7-ui-overhaul-tracker.md](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/specifications/07c-phase7-ui-overhaul-tracker.md) to track your progress.

### A. Storefront (PDP / Cart / Checkout)
*   **Target File:** [storefront_preview.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/widgets/storefront_preview.dart)
*   **Riverpod Provider:** `storefrontProvider`
*   **Mockup PNG:** `mock-screens/storefront_pdp.png`
*   **Required States**:
    1.  *Default/Active State*: Implement sliding cart drawer, responsive PDP layouts, and Alpine emerald custom colors.
    2.  *Loading/Submitting State*: Visual overlays simulating Stripe payment process checks.
    3.  *Error/Failure State*: Rounded coral alert dialogs for mocked payment failure cases.
    4.  *Empty State*: Empty cart placeholder screen with a "Back to Shop" CTA button.
    5.  *Input Validation State*: In-line form validation for dummy credit card checks.

### B. Consumer Registration / Sign-up
*   **Target File:** [consumer_registration_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/consumer_registration_view.dart)
*   **Riverpod Provider:** `consumerAuthProvider`
*   **Mockup PNG:** `mock-screens/consumer_register.png`
*   **Required States**:
    1.  *Default/Active State*: Post-purchase registration form fields.
    2.  *Loading/Submitting State*: Loading request indicator (spinner) inside registration action triggers.
    3.  *Error/Failure State*: Error banners for weak passwords or pre-existing email registrations.
    4.  *Empty State*: `N/A`
    5.  *Input Validation State*: Real-time passwords match checks and required email format filters.

---

## 3. Design System & Styling Parameters
Ensure storefront UI matches the Alpine Emerald guidelines inside [stitch_design_alpine.md](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/scratch/stitch_design_alpine.md):
*   **Fonts**: **Outfit** for headers/pricing and **Inter** for descriptions/labels.
*   **Spacing & Corners**: Clean card boxes with `12px` border-radii.
*   **Micro-Animations**: Apply `HoverScale` scale-up configurations to buttons, product grids, and checkout CTAs to make the storefront feel alive.
