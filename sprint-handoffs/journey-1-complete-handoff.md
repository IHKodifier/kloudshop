# Sprint Handoff: Journey 1 Complete -> Entering Journey 2 (Catalog & Inventory)

This handoff details the completed state of **Merchant Authentication & Onboarding (Journey 1)** and sets the stage for the next agent to begin **Product Catalog & Inventory Management (Journey 2)**.

---

## 1. Current Branch & Workspace Status
- **Active Git Branch:** `phase7/j2-catalog` (freshly branched from `dev`, clean tree).
- **Previous Branch:** `phase7/j1-auth` was fully merged into `dev` and pushed to remote.
- **Verification Status:**
  - All backend unit tests (including the new security lockout and tenant boundary validation tests) pass successfully.
  - Restricted AnyIO test suite to run only on the `asyncio` backend (via `anyio_backend` fixture in `conftest.py`), preventing event loop failures due to the missing `trio` package.

---

## 2. What Was Accomplished in the Last Sprint (Journey 1)
- **Visual Onboarding Wizard:** Overhauled `provisioning_page.dart` to support geographic proximity triangulation (Haversine formula), a vector world map graphic showing proximity targets, collapsible multi-region accordion with checkboxes, and dynamic surcharge calculations.
- **Authentication & Claims Synchronization:** Resolved token replication lag on store spin-up by calling `.getIdToken(forceRefresh: true)` to enforce immediate claims propagation.
- **Security Hardening (API & Client):** Implemented client-side and server-side cooldowns (180s on failed login), brute-force account locking (3 failures/24h or single failure on 3+ distinct days), email unblock request rate limiting, and owner-driven override endpoints.
- **Cross-Tenant Prevention:** Tightened `POST /auth/staff/{uid}/unblock` to check the calling administrator's tenant ID, raising a `403 Forbidden` for cross-tenant spoofing.

---

## 3. Mission for the Next Agent: Journey 2 (Product Catalog & Inventory)
Your goal is to implement the premium, high-fidelity UI and Riverpod providers for **Journey 2: Product Catalog & Inventory Management**.

### Required Screen Work items
Refer to the specifications in `07c-phase7-ui-overhaul-tracker.md`:

#### **A. Catalog Overview**
- **Dart File:** `frontend/lib/views/catalog_view.dart`
- **Riverpod Provider:** `catalogProvider`
- **Mockup PNG:** `mock-screens/catalog_overview.png`
- **Five UI States to Implement:**
  - *Default/Active State:* Frosted cards, emerald filter chips, high-density rows.
  - *Loading/Submitting:* Card-skeleton placeholder grids.
  - *Error/Failure:* Refined error toast with a reload action button.
  - *Empty State:* "No Products Found" custom illustration + "Add Product" CTA.
  - *Input Validation:* N/A

#### **B. Product & Variant Editor**
- **Dart File:** `frontend/lib/views/product_editor_view.dart`
- **Riverpod Provider:** `productEditorProvider`
- **Mockup PNG:** `mock-screens/product_editor.png`
- **Five UI States to Implement:**
  - *Default/Active State:* Forms for slug, status dropdown, compare-at price, digital/in-store toggles. Supports multi-image list gallery.
  - *Loading/Submitting:* Save progress loader overlay, uploading skeletons.
  - *Error/Failure:* Refined error modal on save failure.
  - *Empty State:* N/A
  - *Input Validation:* Highlight empty title fields and reject negative pricing before submission.

---

## 4. Design Guidelines (Alpine Emerald OS)
Ensure all new widgets follow the design parameters in `scratch/stitch_design_alpine.md`:
- **Colors:** `#f8faf6` (Mist Green background), `#ffffff` (Pure White cards), `#064e3b` (Deep Forest Green primary/action buttons), `#10b981` (Vibrant Emerald for success badges), `#ba1a1a` (coral error highlights).
- **Typography:** **Outfit** (headings, geometrically tight letter spacing) & **Inter** (UI data, labels, values).
- **Radius:** Standard `12px` border-radius for cards, `4px` for tags/checkboxes.
- **Transitions:** Implement `HoverScale` micro-animations on interactive cards and buttons.
