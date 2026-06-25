# Implementation Plan - Storefront Settings & Theme Customization Overhaul

This plan outlines the technical design, database migrations, backend API endpoints, and frontend Flutter UI changes required to deliver a Shopify-like store settings and theme customization experience for Kloudshop.

---

## User Review Required

> [!IMPORTANT]
> The database migration will introduce new tables for shipping profiles, zones, rates, navigation menus, and store policies, and update the existing `products` and `variants` tables. In production, this will require Alembic migration scripts to run cleanly without data loss.

---

## Open Questions

*No open questions are pending at this stage as all 11 architectural decisions have been finalized and documented in [decisions.md](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/specifications/shopify-theme-customization/decisions.md).*

---

## Proposed Changes

### 1. Database & Migrations (Alembic)

We will introduce several new SQLAlchemy models to represent settings, shipping, taxes, navigation, and policies.

#### [NEW] [models.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/shipping/models.py)
* Create `StoreShippingProfile` table:
  * `profile_id` (String primary key)
  * `tenant_id` (String, indexed)
  * `name` (Text)
  * `is_general` (Boolean, default False)
* Create `StoreShippingZone` table:
  * `zone_id` (String primary key)
  * `profile_id` (String ForeignKey to `StoreShippingProfile`)
  * `tenant_id` (String)
  * `name` (Text)
  * `countries` (JSON - list of country codes, e.g. `["US", "CA"]`)
* Create `StoreShippingRate` table:
  * `rate_id` (String primary key)
  * `zone_id` (String ForeignKey to `StoreShippingZone`)
  * `tenant_id` (String)
  * `name` (Text)
  * `price` (Numeric(12, 2))
  * `min_value` (Numeric(12, 2), optional)
  * `max_value` (Numeric(12, 2), optional)
  * `min_weight` (Numeric(10, 3), optional)
  * `max_weight` (Numeric(10, 3), optional)
  * `rate_type` (String: flat / weight_based / price_based)

#### [NEW] [models.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/tax/models.py)
* Create `StoreTaxRate` table (manual fallback):
  * `tax_rate_id` (String primary key)
  * `tenant_id` (String, indexed)
  * `country_code` (String(2))
  * `state_code` (String(8), optional)
  * `tax_percentage` (Numeric(5, 2))
  * `is_active` (Boolean, default True)

#### [NEW] [models.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/navigation/models.py)
* Create `StoreNavigationMenu` table:
  * `menu_id` (String primary key)
  * `tenant_id` (String, indexed)
  * `name` (Text)
  * `handle` (String, indexed)
* Create `StoreNavigationItem` table (self-referencing hierarchy):
  * `item_id` (String primary key)
  * `menu_id` (String ForeignKey to `StoreNavigationMenu`)
  * `tenant_id` (String)
  * `parent_id` (String ForeignKey to `StoreNavigationItem.item_id`, nullable)
  * `title` (Text)
  * `url` (Text)
  * `link_type` (String: product / collection / page / policy / custom)
  * `resource_id` (String, nullable)
  * `position` (Integer, default 0)

#### [NEW] [models.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/policies/models.py)
* Create `StorePolicy` table:
  * `policy_id` (String primary key)
  * `tenant_id` (String, indexed)
  * `policy_type` (String: refund / privacy / terms / shipping)
  * `draft_content` (Text, nullable)
  * `published_content` (Text, nullable)
  * `version` (Integer, default 1)
  * `is_active` (Boolean, default False)
  * `created_at` (DateTime)
  * `updated_at` (DateTime)
  * `deactivated_at` (DateTime, nullable)

#### [MODIFY] [models.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/catalog/models.py)
* Add `tax_category` (String, default "Standard Physical Goods") to `Product` model.
* Add `shipping_profile_id` (String ForeignKey referencing `StoreShippingProfile`, nullable) to `Variant` model.

---

### 2. Backend API & Routers

We will build the endpoint handlers for Sprints 7 and 9 under `backend/modules`.

#### [NEW] [router.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/shipping/router.py)
* Implement CRUD for Shipping Profiles, Zones, and Rates.
* Implement a checkout shipping calculation endpoint: `/shipping/calculate` (accepts target address and variant IDs + quantities, matches profiles, zones, applies thresholds, and aggregates/blends shipping rates).

#### [NEW] [router.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/tax/router.py)
* Implement CRUD for manual `StoreTaxRate` fallback.
* Implement tax calculation endpoint: `/tax/calculate` (checks tenant settings for Stripe Connect toggle. If active, invokes Stripe Connect tax automation; otherwise queries `StoreTaxRate` fallback).

#### [NEW] [router.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/navigation/router.py)
* Implement CRUD for navigation menus.
* Implement sorting and hierarchy updates endpoint for drag-and-drop structural updates.
* Implement dynamic relative link resolver query endpoint.

#### [NEW] [router.py](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/policies/router.py)
* Implement endpoints for policy editing (draft vs. publish transactions).
* Implement template generators to seed policies with company variables.

---

### 3. Frontend UI (Flutter)

We will overhaul the dashboard views and customization widgets to match the Shopify clones.

#### [MODIFY] [dashboard_page.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/dashboard_page.dart)
* Restructure sidebar to group Online Store features under a collapsible sub-menu (Themes, Blog, Pages, Navigation, Preferences).

#### [MODIFY] [themes_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/themes_view.dart)
* Redesign themes library to follow the 2-pane active preview + My Themes draft library + Popular Themes shelf layout.

#### [MODIFY] [wysiwyg_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/wysiwyg_view.dart)
* Restructure editor into a 3-pane Layout (left ribbon, center outlines panel/property fields stack, right visual canvas preview).
* Add WCAG contrast checker warnings to color pickers.
* Support named presets and native feature embeds panels.

#### [MODIFY] [settings_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/settings_view.dart)
* Add sub-views for:
  * **Taxes settings** (Stripe Connect iframe overlay + manual rates fallback editor).
  * **Shipping settings** (Profiles, zones, flat weight/price rates forms).
  * **Navigation** (Menu list and nested menu item drag-nest builder).
  * **Policies** (Editors for Refund, Privacy, Terms, and Shipping policies with HTML source toggle and template triggers).

---

## Verification Plan

### Automated Tests
* We will write backend Python unit and integration tests using `pytest`:
  * `pytest backend/tests/test_shipping_blending.py` to verify checkout shipping rates aggregation.
  * `pytest backend/tests/test_tax_calculations.py` to verify Stripe Connect automatic vs manual tax fallback.
  * `pytest backend/tests/test_policies_versioning.py` to verify the single-transaction publishing and versioning rules.
  * `pytest backend/tests/test_navigation_resolver.py` to verify polymorphic asset route link resolutions.

### Manual Verification
* Run the Flutter web client locally (`flutter run -d chrome`).
* Verify visual UI layout accuracy of Themes Library and 3-pane Customizer panels.
* Walk through creating custom shipping profiles, adding conditional flat rates, toggling manual tax fallback rates, nested navigation building, and drafting/publishing policies.
