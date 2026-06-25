<!-- AGENT NOTICE: Read specifications/AGENT_MANIFEST.md BEFORE making any code changes.
     This file contains 🔴 MVP PRODUCTION BLOCKERS. Check every FCL entry marked 🔴
     against your current task before writing a single line of code. -->

# Feature Catalogue Parking Lot: KloudShop

> **Purpose:** Rolling reference of all features earmarked for the KloudShop
> Feature Catalogue at any stage of development. Each entry is a candidate for
> eventual inclusion as a native, toggleable, zero-extra-cost platform capability.
> 
> **How to use:** Park a feature here the moment it is identified. Full story
> writing, schema design, and MVP/post-MVP classification happen in later stages.
> This document is never pruned — features are promoted out (to `04-feature-stories.md`
> and `04b-mvp-scope.md`) but never deleted from this log.
> 
> **ID convention:** `FCL-NNN` — sequential, never reused.
> **Category:** Assigned per feature — no fixed taxonomy enforced.
> **Last updated:** Stage 4b session.

---

## Categories in Use

| Category                       | Features                         |
| ------------------------------ | -------------------------------- |
| Cart-Level Promotions          | FCL-001, FCL-003, FCL-004        |
| Product-Level Promotions       | FCL-002                          |
| Time-Limited & Campaign Offers | FCL-005, FCL-006                 |
| Storefront Display Components  | FCL-007                          |
| Catalog & Data Architecture    | FCL-008, FCL-009, FCL-010        |
| Product Editor UI              | FCL-011                          |

**Total features parked: 11**

---

## Parked Features

---

### FCL-001

**Title:** Buy X, Get Y Free (Cart Quantity Trigger)
**Category:** Cart-Level Promotions
**Description:** Merchant configures a rule: when a customer adds a qualifying
quantity of an eligible product (or any product) to their cart, a specified number
of units are automatically discounted to \$0 at checkout. 
Supports same-SKU(buy 2, get 1 free) and cross-SKU configurations. The free unit(s) are surfaced
transparently in the cart as a line item at $0 with a labelled promotion badge —
never silently deducted.

---

### FCL-002

**Title:** Complementary Free Gift with SKU Purchase (Choose-from-a-Set)
**Category:** Product-Level Promotions
**Description:** Merchant configures a gifting rule tied to the purchase of a
specific trigger SKU (SKU X). When SKU X is in the cart, the customer is prompted
to choose one free item from a merchant-defined pool of eligible gift SKUs. The
pool can be as small as one item (effectively a fixed pairing) or as large as the
merchant wishes (e.g. "buy a laptop, pick any one accessory free"). The chosen gift
item is added to the cart at $0 with a "Free gift" badge. Inventory for the chosen
gift SKU is decremented normally. The rule can additionally be scoped by minimum
quantity of SKU X or a minimum order value threshold. The gift selection prompt
appears inline on the cart or as a modal — never silently auto-added without
customer acknowledgement.

---

### FCL-003

**Title:** Volume Discount (Quantity Tier Pricing)
**Category:** Cart-Level Promotions
**Description:** Merchant configures tiered quantity-based discounts on a per-SKU
or per-collection basis. When a customer's cart contains a qualifying quantity of
an eligible SKU, a percentage discount is applied to the total value of that SKU
across all matching line items. Example: buy 10–19 units of SKU X → 5% off;
buy 20+ units → 12% off. Tiers are merchant-configurable with no fixed limit on
the number of tiers. Discount is shown per applicable line item in the cart and
summarised in the order total. Particularly valuable for B2B buyers purchasing in
bulk — surfaced in both the DTC storefront and the B2B buyer portal.

---

### FCL-004

**Title:** Coupon / Discount Code
**Category:** Cart-Level Promotions
**Description:** Merchant creates alphanumeric discount codes that customers enter
at checkout. Each code is configurable with: discount type (percentage off or fixed
amount off), applicable scope (entire order, specific collections, or specific SKUs),
usage limit (total redemptions and/or one-per-customer), validity window (start and
end datetime), and minimum order value threshold. Codes can be single-use, multi-use,
or unlimited. Applied discount is shown as a line item deduction in the order summary.
Invalid, expired, or exhausted codes surface a clear inline error at the checkout
coupon field.

---

### FCL-005

**Title:** Flash Sale (SKU-Level Time-Limited Price Reduction)
**Category:** Time-Limited & Campaign Offers
**Description:** Merchant configures a time-limited price reduction on a specific
SKU or set of SKUs with a defined start and end datetime. The sale price is shown
alongside the original crossed-out price on all storefront surfaces where the SKU
appears (PDP, collection pages, search results, product grid components, cart).
When the sale window closes, prices revert automatically — no merchant action
required. FCM push confirms sale start and sale end to the merchant. This feature
governs the pricing rule only; urgency display (countdown timer, stock scarcity
label) is a separate attachable component — see FCL-007.

---

### FCL-006

**Title:** Campaign Offer (Collection or SKU-Scoped, Date-Windowed Discount)
**Category:** Time-Limited & Campaign Offers
**Description:** Merchant configures a promotional campaign with a defined
date-range window and a flat percentage discount or fixed amount off, applied
across one or more of: a collection/category (e.g. all Men's Clothing), a
hand-picked set of specific SKUs, or any combination of both. The campaign
activates and deactivates automatically at the configured start and end datetimes.
Sale pricing is reflected across all storefront surfaces where affected products
appear. The original price is displayed alongside the campaign price with a labelled
promotion badge. Multiple non-overlapping campaigns can be active simultaneously
on different scopes; where campaigns overlap, discount priority is governed by a
merchant-configurable rule (highest discount wins or most specific scope wins).
Urgency display (countdown timer, stock scarcity label) is optionally attachable
via FCL-007.

---

### FCL-007

**Title:** Urgency Display Component (Countdown Timer + Stock Scarcity Label)
**Category:** Storefront Display Components
**Description:** A reusable storefront display component that any promotion feature
(Flash Sale, Campaign Offer, or future promotion types) can attach to. When attached,
it renders on the relevant product surfaces: a live countdown timer showing time
remaining until the promotion ends (DD:HH:MM:SS), and/or an optional stock scarcity
label ("Only N left at this price" or "Only N in stock") that activates when
remaining inventory for the SKU falls below a merchant-configured threshold.
Both the timer and the scarcity label are independently toggleable — a promotion
can use one, both, or neither. The component is configuration-driven: the end
datetime is inherited from the attached promotion rule; the scarcity threshold is
set per promotion. This component has no standalone pricing or discount logic —
it is display only.

---

### FCL-008

**Title:** Hierarchical Collections — `parent_collection_id`
**Category:** Catalog & Data Architecture
**MVP classification:** 🔴 **CORE MVP — PRODUCTION BLOCKER**
**Stage:** Must be implemented before the app goes into production. This is no longer a post-MVP item.

> **This feature MUST ship with the MVP.** Without hierarchical collections, merchants with multi-level catalogs (e.g. Outdoor Equipment → Mountaineering Gear → Alpine Climate Wear) cannot properly organise their storefront. Flat-only collections are a hard limitation for any merchant with a category tree deeper than one level.

> ✅ **Baseline already implemented**: Flat collections exist at all layers — schema spec, SQLAlchemy ORM (`Collection`, `CollectionProduct` in `backend/modules/catalog/models.py`), and API tests (`backend/tests/test_collections.py`). The remaining work is **adding `parent_collection_id`** to the existing table.

**Description:**
The current `collections` table is flat — no parent/child relationship. This must be extended to support hierarchy:

```
Outdoor Equipment
  └── Mountaineering Gear
        └── Alpine Climate Wear
  └── Fishing Gear

Apparel
  └── Winter Wear
  └── Kids Wear
  └── Party Wear
```

**Mandatory implementation order — do not skip or resequence:**

```
Step 1 — Schema migration
  ALTER TABLE collections
    ADD COLUMN parent_collection_id UUID
      REFERENCES collections (collection_id)
      ON DELETE SET NULL;
  Recursive queries use PostgreSQL WITH RECURSIVE CTEs.
  ↓

Step 2 — SQLAlchemy ORM update
  Add parent_collection_id column to Collection model.
  Add self-referential relationship:
    parent = relationship("Collection", remote_side=[collection_id], back_populates="children")
    children = relationship("Collection", back_populates="parent")
  ↓

Step 3 — API update
  Accept optional parent_collection_id on POST /collections and PATCH /collections/{id}.
  Validate: no circular references (parent cannot be a descendant of itself).
  Expose GET /collections as a nested tree response for UI rendering.
  ↓

Step 4 — Flutter UI
  Collection picker in product editor shows nested tree (indented list).
  Collection management screen shows hierarchy with expand/collapse.
  ↓

Step 5 — Storefront
  Navigation menu renders parent → child collections as nested menu items.
  Breadcrumbs on collection pages show ancestor path.
```

**Cross-references:**
- FCL-003 (Volume Discount) and FCL-006 (Campaign Offer) — discounts can be scoped to a branch of the hierarchy.
- Storefront navigation (theme sections) binds to `collection_id`, hierarchy enables nested menus.
- `06b-tenant-catalog-schema.md` must be updated to remove the "Flat structure" annotation and add `parent_collection_id`.

**Source:** Identified during Shopify UX analysis session (§8a of `shopify-theme-customization/shopify-theme-customization-analysis.md`). Reclassified from Post-MVP to Core MVP blocker, June 2026.

---


### FCL-009

**Title:** Product Hero Image — First Image Convention + Variant-Specific Image Sets
**Category:** Catalog & Data Architecture
**Stage:** Design decision needed before the PDP and product editor are built.

**Description:**
The Product Detail Page (PDP) must display a primary/hero image for every product. Two approaches were considered:

- **Option A**: Merchant explicitly designates one image as the hero (via a star/pin). Adds UI complexity and cognitive load.
- **Option B (recommended)**: The **first image in the product's ordered image set = the hero image**. This is the universal convention (Shopify, WooCommerce, etc.). Zero extra UI. In the product editor itself — a subtle tooltip or info badge near the "Add variant option" button reinforcing there's no limit.

**Variant-specific images:**
For products with variants (e.g. colour variants), each variant should have its own ordered image set. When a customer selects a variant on the PDP (e.g. "Red"), the hero image auto-swaps to the first image in that variant's image set.

**Schema implication:**
```sql
product_media (
  id, product_id, variant_id (nullable),
  url, alt_text,
  sort_order INT,   ← position 0 = hero
  media_type ENUM('image', 'video', '3d_model'),
  created_at
)
```
The `sort_order = 0` record (per product, or per variant) is the hero. Reordering in the UI updates `sort_order` values.

**Source:** Identified during Shopify UX analysis session (Screen 5 of `shopify-onboarding-inspiration/shopify-onboarding-ux-reference.md`).

---

### FCL-010

**Title:** Auto-Publish Pipeline — Active Products Go Live Without Extra Steps
**Category:** Catalog & Data Architecture
**Stage:** MVP scope — core product publishing behaviour.

**Description:**
In Shopify, a product with `status = Active` and published to "Online Store" is immediately live on the storefront. No extra "push to storefront" action is needed. KloudShop should follow the same model.

**Current concern:** If KloudShop requires merchants to take an additional step to publish an active product to the storefront (beyond setting it to Active), this creates unnecessary friction and confusion.

**Recommended behaviour:**
- `status = Active` → product is live on the storefront automatically.
- `status = Draft` → product is saved but not visible to customers.
- No separate "Publish to storefront" button should be required.

**Future extension (post-MVP):** Scheduled publishing — allow merchants to set a future datetime at which a draft product goes Active automatically (useful for product launches, seasonal drops).

**Further future extension:** Supplier/inventory feed integration — products from a connected supplier or ERP system auto-populate the catalog when received, without manual entry per product.

**Source:** Identified during Shopify UX analysis session (Screen 5 of `shopify-onboarding-inspiration/shopify-onboarding-ux-reference.md`).

---

### FCL-011

**Title:** Product Editor — Drag-Reorderable Image Grid
**Category:** Product Editor UI
**MVP classification:** 🔴 **CORE MVP — PRODUCTION BLOCKER**
**Stage:** Must be completed and verified before the app goes into production. This is not a post-MVP enhancement.

> **This feature MUST ship with the MVP.** The hero image convention (first image = PDP hero, per FCL-009) is only usable if the merchant can control image order. Without drag-reorder, the merchant has no reliable way to set the PDP hero image. Shipping to production without this would be a broken product experience.

**Description:**
The product editor's image/media grid is currently **not drag-reorderable**. Since the architectural decision (FCL-009, Option B) is that the **first image = the PDP hero image**, the ability to reorder images by drag-and-drop is a core editing capability, not a nice-to-have.

**Required behaviour:**
- Images displayed in a grid in the product editor.
- Each image tile is draggable — merchant can drag to reorder.
- First slot in the grid carries a subtle **"Primary"** label/badge to make the convention self-documenting.
- On drop, `sort_order` values are updated in the DB for all affected images (`product_media.sort_order`).
- The reorder is **per-product** at the product level, and **per-variant** when editing variant-specific image sets.

**Applies to:**
- `product_editor_view.dart` (or equivalent) — the admin-side product editor.
- Variant image sets within the same editor (when a variant has its own images assigned).

**Mandatory implementation order — do not skip or resequence:**

```
Step 1 — Schema (FCL-009)
  Add sort_order INT column to product_media table.
  Backfill existing rows (set sort_order = upload sequence).
  ↓

Step 2 — API / Backend
  Expose a PATCH /products/{id}/media/reorder endpoint
  that accepts an ordered list of media IDs and updates sort_order.
  ↓

Step 3 — Flutter UI (THIS ITEM — FCL-011)
  Implement drag-reorderable image grid in product_editor_view.dart.
  First tile labelled "Primary". On drop → call reorder API.
  ↓

Step 4 — PDP rendering
  PDP loads images ordered by sort_order ASC.
  sort_order = 0 (or lowest) → hero/primary image displayed first.
  Variant selection → swaps to that variant's sort_order = 0 image.
```

**Implementation note:** In Flutter, drag-reorder in a grid can be implemented with `ReorderableWrap` (from the `reorderables` package) or a custom `Draggable`/`DragTarget` setup. A simpler interim approach is a reorderable `ListView` (single column) using Flutter's built-in `ReorderableListView`.

**Source:** Architectural decision recorded in FCL-009. MVP classification confirmed in session, June 2026.

---


| Blog Post Comments | HIGH | Consumers can comment on published blog posts. Threaded or flat TBD. Requires moderation queue (approve/reject/spam), optional merchant notification via Resend. Consumer identity via GCIP (`consumer_id` FK to `tenant_consumers`). Guest comments need a separate name+email capture. Spam protection via reCAPTCHA or Akismet integration. Comment count denormalised onto `blog_posts.comment_count` for storefront display performance. Feature-gated — DDL additions to `blog_posts` (comment_count) + new tables: `blog_comments`, `blog_comment_moderation_log`. | `blog_comments`, `blog_comment_moderation_log`; `blog_posts.allow_comments` column already provisioned as the enable flag. |
