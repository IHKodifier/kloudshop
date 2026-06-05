# Schema Inventory: KloudShop

# Stage 6 — Data Model (Principal Data Engineer)

> **Purpose:** This is the master tracking artifact for all Stage 6 schema
> generation. Every table in the KloudShop data model is listed here, grouped
> by artifact file. Update the Status column to ✅ Generated after each
> artifact is produced and approved. Use this file to hand off to a new chat
> session if token limits are reached — upload it alongside
> `00-carry-forward-flags.md` and the relevant prior schema artifacts.
> 
> **Reads from:** All prior approved artifacts (01 through 05) and
> `00-carry-forward-flags.md` DMF-01 through DMF-10.
> 
> **Schema split:** Two top-level schemas exist in the KloudShop PostgreSQL
> instance on GCP Cloud SQL:
> 
> - `kloudshop_platform` — the control plane. Shared across all tenants.
>   Contains tenant registry, staff, billing, carrier catalogue, theme
>   catalogue, feature registry, and all platform-admin concerns.
> - `tenant_{tenant_id}` — one schema per merchant, provisioned at signup.
>   Contains all merchant-specific commerce, storefront, inventory, B2B,
>   messaging, and consumer data.
> 
> **Consumer auth:** Consumers (DTC storefront shoppers) are authenticated via
> Google Cloud Identity Platform (GCIP) multi-tenancy. Each KloudShop merchant
> gets one GCIP tenant, provisioned programmatically at signup. Staff and B2B
> buyers use the standard Firebase Auth project. The `gcip_tenant_registry`
> table maps KloudShop `tenant_id` → GCIP `tenant_id`.
> 
> **Feature-gated tables:** Tables created only when a merchant activates a
> specific Feature Catalogue item are marked [FEATURE-GATED] and include a
> header comment in their DDL. These tables do NOT exist in the base tenant
> schema — they are created by the Migration Runner (Alembic) on demand.
> 
> > **Last updated:** `06a1`–`06m` generated. Next artifact: `06n-state-machines.md`

---

## Artifact Index

### 06a1 — Platform Core Schema

**File:** `06a1-platform-core-schema.md`
**Schema:** `kloudshop_platform`
**Status:** ✅ Generated
**Tables: 18**

| #   | Table                     | Description                                                                                                                                                                                     | Base/Feature-Gated |
| --- | ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| 1   | `tenants`                 | One row per merchant account. Holds tier, trial state, region config, GCP provisioning status, soft-delete state, and GCIP tenant reference.                                                    | Base               |
| 2   | `tenant_regions`          | Primary and optional secondary GCP region per tenant, provisioning status per region, failover configuration. A tenant with no secondary region has one row only.                               | Base               |
| 3   | `gcip_tenant_registry`    | Maps KloudShop `tenant_id` → Firebase/GCIP `tenant_id` string. Required because GCIP tenant IDs are Firebase-generated strings, not our UUIDs.                                                  | Base               |
| 4   | `staff_users`             | Platform-level Gmail-authenticated staff identities. One row per Gmail account regardless of how many tenancies they belong to. Includes `preferences JSONB` for UI settings (dark mode, etc.). | Base               |
| 5   | `staff_role_assignments`  | Join table: which staff member holds which roles in which tenancy. Supports multi-role, multi-tenancy assignments. Tracks invitation and acceptance state.                                      | Base               |
| 6   | `platform_staff`          | KloudShop internal team accounts (founder + designated platform admins). Separate from merchant `staff_users`. Governs access to ADM-01–ADM-30 flows.                                           | Base               |
| 7   | `platform_audit_log`      | Immutable append-only log of all platform-admin actions (suspend, reinstate, billing credit, theme publish, feature flag changes, etc.).                                                        | Base               |
| 8   | `staff_login_history`     | Immutable append-only log of all successful merchant, owner, and staff logins. Tracks IP, user agent, and triangulated region location.                                                         | Base               |
| 9   | `staff_security_states`   | Manages failed sign-in cool-offs (180s countdown), brute-force lockout blocks (3 strikes per 24h, distinct daily strikes), unblock token email triggers, and unblocking permissions.            | Base               |
| 10  | `migration_jobs`          | Tracks competitor store scraping and import jobs per tenant. Holds source platform, scrape status, GCP Track B provisioning status, error state, and retry count.                               | Base               |
| 11  | `billing_cycles`          | One row per merchant per billing period. Records cycle start/end, GCP actual cost, KloudShop markup applied, Stripe invoice ID, and payment status.                                             | Base               |
| 12  | `billing_line_items`      | Itemised GCP resource cost rows per billing cycle per tenant. One row per resource type (Cloud SQL, Cloud Run, Vertex AI, CDN egress, etc.).                                                    | Base               |
| 13  | `trial_visitor_counts`    | Daily visitor counts per trial tenant during the 216-hour hard-stop window only. Sourced from GCP Load Balancer logs via a Cloud Tasks job. Purged after permanent tenant deletion.             | Base               |
| 14  | `platform_announcements`  | Human-authored release notes per production deployment. Written by Platform Admin post-deploy. Read by the Flutter admin app "What's new" panel.                                                | Base               |
| 15  | `feature_request_channel` | Merchant-submitted feature requests. Authenticated merchants on any paid tier or active trial can submit.                                                                                       | Base               |
| 16  | `feature_request_votes`   | One row per (merchant, feature_request) vote. Enforces one vote per merchant per request.                                                                                                       | Base               |
| 17  | `order_sources`           | Lookup table replacing the `order_source` ENUM. Extensible without code changes. Covers kloudshop, pos, imported, tiktok_shop, instagram_shop, facebook_shop, and future channels.              | Base               |
| 18  | `re_engagement_sequences` | NOT USED — dropped per final decision (Option A). No post-deletion emails. Included here as a tombstone to prevent future confusion.                                                            | N/A — Dropped      |

---

### 06a2 — Platform Catalogue Schema

**File:** `06a2-platform-catalogue-schema.md`
**Schema:** `kloudshop_platform`
**Status:** ⏳ Awaiting generation
**Tables: 18**

| #   | Table                        | Description                                                                                                                                                                                                | Base/Feature-Gated |
| --- | ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| 1   | `themes`                     | Global theme catalogue. One row per theme. Holds Cloud Storage paths for theme.json and assets, sector tags, schema version, and publication status. Adding a theme = one INSERT. No code deploy.          | Base               |
| 2   | `feature_registry`           | Master list of all Feature Catalogue items. Includes `tier_scope` (DTC/B2B/Hybrid), `has_config` boolean, and `status` (stable/beta/deprecated).                                                           | Base               |
| 3   | `feature_config_schema`      | Typed parameter definitions per feature. Drives the generic schema-driven setup wizard in Flutter. One row per config parameter per feature. No Flutter code changes needed to add new feature parameters. | Base               |
| 4   | `feature_dependencies`       | Directed graph of feature → upstream feature dependencies. Resolved via topological sort (Kahn's algorithm) by the Migration Runner. Circular dependencies rejected at CI.                                 | Base               |
| 5   | `feature_migrations`         | Maps Alembic migration script IDs to features. Defines sequence order within a feature's migrations.                                                                                                       | Base               |
| 6   | `carriers`                   | Platform-maintained catalogue of shipping carriers (FedEx, DHL, UPS, Royal Mail, Australia Post, etc.). Shared across all tenants. Never duplicated into tenant schemas.                                   | Base               |
| 7   | `carrier_service_levels`     | Service levels per carrier (e.g. FedEx Ground, FedEx 2Day, DHL Express Worldwide). Includes typical transit day ranges used as fallback when carrier API returns only transit days.                        | Base               |
| 8   | `carrier_regions`            | Which carriers are available in which countries/regions. Drives which carriers a merchant sees in their Shipping Settings based on their primary GCP region and target markets.                            | Base               |
| 9   | `carrier_credential_schemas` | Defines what credential fields each carrier's connection wizard requires (field name, display label, data type, is_secret). Enables fully dynamic carrier connection UI without hardcoded forms.           | Base               |
| 10  | `carrier_webhook_configs`    | Per-carrier webhook endpoint definitions, event types KloudShop subscribes to, and signature validation method. Allows adding new carrier webhook integrations without code changes.                       | Base               |
| 11  | `carrier_rate_zones`         | Geographic zone definitions per carrier for zone-based shipping rate calculation. Used when carrier APIs return zone-based pricing rather than real-time quotes.                                           | Base               |

> **Note on carrier tables:** The split between platform catalogue (06a2) and
> tenant-level carrier configuration (06g) is intentional. Carrier definitions
> live in the platform schema — KloudShop maintains them centrally. Merchant
> carrier account credentials, enabled service levels, and checkout options
> live in the tenant schema. This means adding a new carrier integration
> requires only platform schema inserts, never tenant schema migrations.

---

### 06b — Tenant Catalog Schema

**File:** `06b-tenant-catalog-schema.md`
**Schema:** `tenant_{tenant_id}`
**Status:** ⏳ Awaiting generation
**Tables: 13**

| #   | Table                     | Description                                                                                                                                                                                                                        | Base/Feature-Gated |
| --- | ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| 1   | `products`                | One row per product. Holds title, description, status, SEO metadata, digital flag, POS eligibility, weight/dimension fallbacks, and `in_store_eligible` boolean. No variant caps.                                                  | Base               |
| 2   | `variants`                | One row per variant combination (size × colour × material etc.). Holds SKU, price, all shipping attributes (weight, dimensions, `ships_in_own_packaging`), and stock linkage. Unlimited variants per product.                      | Base               |
| 3   | `product_translations`    | Per-(product_id, locale) row for all translatable product fields: title, description, locale-specific slug, meta_title, meta_description. `is_auto_translated` flag tracks AI vs. merchant-authored.                               | Base               |
| 4   | `variant_translations`    | Per-(variant_id, locale) row for translatable variant display names.                                                                                                                                                               | Base               |
| 5   | `collections`             | Product groupings (categories). Used for storefront navigation, price list scoping, dynamic pricing rules, and Google Shopping feed categorisation.                                                                                | Base               |
| 6   | `collection_translations` | Per-(collection_id, locale) row for title, description, slug, meta_title, meta_description.                                                                                                                                        | Base               |
| 7   | `collection_products`     | Join table: many-to-many between collections and products. Includes `sort_order` for merchant-controlled display order within a collection.                                                                                        | Base               |
| 8   | `product_images`          | Product and variant image records. Holds Cloud Storage path, CDN URL, alt text, sort order, and variant association (nullable — product-level images have null variant_id).                                                        | Base               |
| 9   | `product_suppliers`       | Many-to-many: variants ↔ suppliers with preference ranking, unit cost, MOQ, lead time override, and supplier SKU. Enforces exactly one rank-1 per variant at application layer.                                                    | Base               |
| 10  | `product_reviews`         | Consumer reviews per variant. Holds rating, body, `consumer_id` FK, `is_informed_review` boolean (stored, not computed), and moderation status.                                                                                    | Base               |
| 11  | `review_votes`            | Helpfulness votes on reviews (helpful / not helpful). One row per (consumer_id, review_id).                                                                                                                                        | Base               |
| 12  | `seo_settings`            | One row per tenant. Holds global SEO defaults, `auto_update_informed_reviews` boolean, robots.txt content, and Google Merchant Center connection state.                                                                            | Base               |
| 13  | `ai_copywriter_log`       | Append-only log of every AI Copywriter generation call. Holds content_type, variant_accepted (1/2/3/NULL), was_edited boolean, prompt_hash (SHA-256), staff_user_id, and generated_at. Feeds prompt quality analytics in BigQuery. | Base               |

---

### 06c — Tenant Orders Schema

**File:** `06c-tenant-orders-schema.md`
**Schema:** `tenant_{tenant_id}`
**Status:** ⏳ Awaiting generation
**Tables: 6**

| #   | Table                  | Description                                                                                                                                                                                                                         | Base/Feature-Gated |
| --- | ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| 1   | `orders`               | One row per order. Denormalised totals (subtotal, tax_total, shipping_total, discount_total, grand_total) snapshotted at purchase time. References `order_sources` lookup table. B2B flag, net_terms_days snapshot, approval state. | Base               |
| 2   | `order_items`          | Line items per order. Holds variant snapshot (price, title, SKU at time of purchase — immutable). References `fulfilment_location_id` for multi-location routing.                                                                   | Base               |
| 3   | `order_events`         | Append-only event log per order (placed, payment_confirmed, fulfilment_started, shipped, delivered, refunded, cancelled, etc.). The source of truth for order timeline.                                                             | Base               |
| 4   | `order_shipments`      | One row per shipment per order. Supports partial fulfilment and multi-location split shipments. Holds carrier, tracking number, shipped_at, estimated_delivery, and fulfilment_location_id.                                         | Base               |
| 5   | `order_shipment_items` | Join table: which order_items are in which shipment. Enables partial fulfilment tracking.                                                                                                                                           | Base               |
| 6   | `order_notes`          | Internal staff notes per order. Never visible to consumers. Append-only (no edit, no delete). Holds author staff_user_id and timestamp.                                                                                             | Base               |

---

### 06d — Tenant Inventory Schema

**File:** `06d-tenant-inventory-schema.md`
**Schema:** `tenant_{tenant_id}`
**Status:** ⏳ Awaiting generation
**Tables: 5**

| #   | Table                | Description                                                                                                                                                             | Base/Feature-Gated |
| --- | -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| 1   | `stock_locations`    | Named stock locations (warehouses, physical stores, fulfilment centres). One row per location. Includes address, type (warehouse/store/3pl), and is_active flag.        | Base               |
| 2   | `inventory`          | Per-(variant_id, stock_location_id) stock level record. Holds quantity_on_hand, quantity_reserved, quantity_available (computed). The single source of truth for stock. | Base               |
| 3   | `stock_reservations` | Short-lived locks placed during checkout to prevent oversell. Holds expiry_at (TTL). Cleared on order confirmation or expiry.                                           | Base               |
| 4   | `stock_transfers`    | Records of stock moved between locations. Holds source_location, destination_location, variant_id, quantity, initiated_by, and status (draft/in_transit/received).      | Base               |
| 5   | `packaging_presets`  | Merchant-defined box/envelope size configurations used for shipping rate calculation. Includes max_weight, dimensions, and is_default flag.                             | Base               |

---

### 06e — Tenant Supplier Schema

**File:** `06e-tenant-supplier-schema.md`
**Schema:** `tenant_{tenant_id}`
**Status:** ⏳ Awaiting generation
**Tables: 6**

| #   | Table                         | Description                                                                                                                                                      | Base/Feature-Gated |
| --- | ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| 1   | `suppliers`                   | One row per supplier. Holds contact info, payment terms, default lead time, currency, and status (active/inactive/archived). Deletion blocked if open POs exist. | Base               |
| 2   | `purchase_orders`             | One row per PO. Holds supplier_id, status (draft/sent/partial/received/cancelled), ordered_at, expected_delivery_at, received_at.                                | Base               |
| 3   | `purchase_order_lines`        | Line items per PO. Holds variant_id, supplier_id, qty_ordered, qty_received, unit_cost, discrepancy_flag.                                                        | Base               |
| 4   | `supplier_performance_events` | Logged events against a supplier (late_delivery, short_shipment, quality_issue, etc.). Feeds the supplier scorecard analytics in BigQuery.                       | Base               |
| 5   | `supplier_score_weights`      | One row per tenant. Merchant-adjustable composite score weights (on_time, fill_rate, quality, price_stability). Defaults to (0.35, 0.25, 0.25, 0.15).            | Base               |
| 6   | `shipping_settings`           | One row per tenant. Holds default weight/dimension units, default package weight fallback, handling_days, and order_cutoff_time.                                 | Base               |

---

### 06f — Tenant B2B Schema

**File:** `06f-tenant-b2b-schema.md`
**Schema:** `tenant_{tenant_id}`
**Status:** ⏳ Awaiting generation
**Tables: 6**

| #   | Table                | Description                                                                                                                                                                                                       | Base/Feature-Gated |
| --- | -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| 1   | `b2b_accounts`       | One row per B2B buyer contact (flat — no company hierarchy table). Holds company_name (display/reporting only — no structural FK), contact info, credit limit, net_terms_days, price_list_id, and account status. | Base               |
| 2   | `price_lists`        | Named price lists per tenant. One row per list. Assigned to b2b_accounts.                                                                                                                                         | Base               |
| 3   | `price_list_items`   | Per-(price_list_id, variant_id) price override. Holds fixed price or percentage discount.                                                                                                                         | Base               |
| 4   | `approval_workflows` | Merchant-configured approval rules. Holds order amount threshold, assigned approver roles, and auto-approve conditions.                                                                                           | Base               |
| 5   | `approval_requests`  | One row per order requiring approval. Holds order_id, status (pending/approved/declined), requested_at, decided_at, decided_by, and decline_reason.                                                               | Base               |
| 6   | `b2b_invoices`       | Stripe Invoice reference per approved B2B order. Holds stripe_invoice_id, due_date (net_terms snapshot), amount, and payment status.                                                                              | Base               |

---

### 06g — Tenant Storefront & Carrier Configuration Schema

**File:** `06g-tenant-storefront-schema.md`
**Schema:** `tenant_{tenant_id}`
**Status:** ⏳ Awaiting generation
**Tables: 7**

| #   | Table                          | Description                                                                                                                                                                                                                             | Base/Feature-Gated |
| --- | ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| 1   | `brand_profiles`               | One row per storefront (DTC and B2B are separate rows for Hybrid merchants). Holds brand name, slug, logo URL, colour palette, favicon, active theme_id, draft_theme_config_url, active_theme_config_url, and `enabled_locales TEXT[]`. | Base               |
| 2   | `storefront_content`           | Merchant-authored content per content slot per locale. Primary key is `(slot_id, locale)`. `is_auto_translated` flag. Content carries forward on theme switch. Orphaned content preserved.                                              | Base               |
| 3   | `merchant_carrier_connections` | Which carriers this merchant has connected. Holds carrier_id FK (platform schema), account_number, GCP Secret Manager credential reference (never raw credentials), and is_active.                                                      | Base               |
| 4   | `carrier_checkout_options`     | Per service level enabled/disabled status for this merchant's checkout. Holds markup type and value, and destination country restrictions.                                                                                              | Base               |
| 5   | `static_pages`                 | Merchant-created static pages (About, Contact, FAQ, Policy pages). Holds title, slug, rich-text body (JSONB — Tiptap/ProseMirror), SEO metadata, and published status.                                                                  | Base               |
| 6   | `static_page_translations`     | Per-(page_id, locale) translations of static page content. Same `is_auto_translated` pattern as all other translation tables.                                                                                                           | Base               |
| 7   | `redirect_rules`               | 301 redirect rules. One row per (source_path → destination_path). Auto-created when a slug changes. Merchant-manageable from the 301 redirect manager in admin.                                                                         | Base               |

---

### 06h — Tenant Blog Schema

**File:** `06h-tenant-blog-schema.md`
**Schema:** `tenant_{tenant_id}`
**Status:** ⏳ Awaiting generation
**Tables: 7**

| #   | Table                        | Description                                                                                                                                                                  | Base/Feature-Gated |
| --- | ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| 1   | `blog_posts`                 | One row per blog post. Body stored as JSONB (Tiptap/ProseMirror format). Companion `body_tsv TSVECTOR` generated column for FTS. Status: draft/scheduled/published/archived. | Base               |
| 2   | `blog_post_translations`     | Per-(post_id, locale) translations: title, slug, body (JSONB), body_tsv, meta_title, meta_description. `is_auto_translated` flag.                                            | Base               |
| 3   | `blog_categories`            | Merchant-defined blog categories. Holds name, slug, description, and sort_order.                                                                                             | Base               |
| 4   | `blog_category_translations` | Per-(category_id, locale) translations for category name, slug, and description.                                                                                             | Base               |
| 5   | `blog_post_categories`       | Join table: many-to-many between blog_posts and blog_categories.                                                                                                             | Base               |
| 6   | `blog_tags`                  | Merchant-defined blog tags. Free-text, normalised into a tags table to enable faceted browsing.                                                                              | Base               |
| 7   | `blog_post_tags`             | Join table: many-to-many between blog_posts and blog_tags.                                                                                                                   | Base               |

---

### 06i — Tenant Messaging Schema

**File:** `06i-tenant-messaging-schema.md`
**Schema:** `tenant_{tenant_id}`
**Status:** ⏳ Awaiting generation
**Tables: 4**

| #   | Table                 | Description                                                                                                                                                                                  | Base/Feature-Gated |
| --- | --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| 1   | `message_threads`     | One row per thread. Thread types: direct, order, purchase_order, sku, buyer_account. Linked to a platform object via `linked_object_id`.                                                     | Base               |
| 2   | `thread_participants` | Join table: who is in which thread. Tracks `last_read_at` for unread badge calculation. Participants auto-determined by object access rules for context-linked threads.                      | Base               |
| 3   | `messages`            | Immutable message records. `body_tsv TSVECTOR` generated column for FTS using `'simple'` dictionary (safe for all 10 LTR locales). No `deleted_at` — messages are never deleted by any user. | Base               |
| 4   | `message_attachments` | File attachment records per message. Holds MIME type (server-validated), file size, Cloud Storage path. Files served via signed URLs (15-min TTL).                                           | Base               |

---

### 06j — Tenant Consumer Schema

**File:** `06j-tenant-consumer-schema.md`
**Schema:** `tenant_{tenant_id}`
**Status:** ⏳ Awaiting generation
**Tables: 4**

| #   | Table                | Description                                                                                                                                                                                                                                                         | Base/Feature-Gated |
| --- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| 1   | `consumers`          | One row per registered DTC consumer per tenant. Linked to GCIP via `gcip_uid`. Consumers are per-storefront — the same real-world person can have independent accounts across different merchant storefronts. `consumer_id` is nullable on orders (guest checkout). | Base               |
| 2   | `consumer_addresses` | Saved delivery addresses per consumer. One consumer can have multiple addresses. Holds is_default flag.                                                                                                                                                             | Base               |
| 3   | `consumer_sessions`  | Tracks active consumer sessions for analytics and cart persistence. Holds session token, device type, last_seen_at.                                                                                                                                                 | Base               |
| 4   | `wishlists`          | Consumer product wishlists. One row per (consumer_id, variant_id). Enables "save for later" and personalisation signals.                                                                                                                                            | Base               |

---

### 06k — Tenant Feature Configuration Schema

**File:** `06k-tenant-feature-config-schema.md`
**Schema:** `tenant_{tenant_id}`
**Status:** ⏳ Awaiting generation
**Tables: 3**

| #   | Table                    | Description                                                                                                                                                                                                    | Base/Feature-Gated |
| --- | ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| 1   | `tenant_feature_config`  | Sparse key-value store of merchant configuration choices per feature. In the BASE tenant schema from day one — NOT a per-feature migration. One row per (feature_id, config_key) per tenant.                   | Base               |
| 2   | `tenant_migration_state` | Tracks which Alembic migration IDs have been applied to this tenant's schema. Consulted by the Migration Runner before applying any migration. Guarantees idempotency.                                         | Base               |
| 3   | `tenant_feature_state`   | Current activation state per feature per tenant (available/activating/active/deactivating/inactive/failed). Firebase Remote Config flag `feature_{feature_id}_enabled` is set from this table on state change. | Base               |

---

### 06l — Tenant Analytics & BigQuery Schema

**File:** `06l-tenant-analytics-schema.md`
**Schema:** BigQuery (not PostgreSQL)
**Status:** ⏳ Awaiting generation
**Tables: 8**

> **Note:** These are BigQuery table/view schema definitions, not PostgreSQL DDL.
> All commerce events stream here via Cloud Pub/Sub. Row-level security enforces
> per-tenant data isolation. The `supplier_scores` materialised view is refreshed
> daily by a Cloud Tasks scheduled BigQuery job.

| #   | Table / View                | Description                                                                                                                                               | Base/Feature-Gated |
| --- | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| 1   | `events` (partitioned)      | Central commerce event table. All storefront behaviour, cart, order, B2B, AI interaction, and platform usage events. Partitioned by `tenant_id` + `date`. | Base               |
| 2   | `orders_summary`            | Denormalised view of orders for dashboard queries. Pre-aggregated to avoid expensive joins on every dashboard load.                                       | Base               |
| 3   | `product_performance`       | Per-SKU velocity, revenue, and return rate metrics. Refreshed hourly.                                                                                     | Base               |
| 4   | `customer_cohorts`          | Consumer cohort assignments (new/returning, LTV bands, RFM segments). Refreshed daily.                                                                    | Base               |
| 5   | `inventory_velocity`        | Per-(variant_id, stock_location_id) sales velocity and days-of-stock-remaining calculations.                                                              | Base               |
| 6   | `supplier_scores`           | Materialised view: composite supplier score per (supplier_id, variant_id, window_days). Refreshed daily via Cloud Tasks.                                  | Base               |
| 7   | `b2b_buyer_activity`        | Buyer account order cadence, receivables ageing, approval workflow metrics.                                                                               | Base               |
| 8   | `ai_copywriter_performance` | Variant acceptance rates, edit rates, discard rates per content_type. Feeds prompt quality analysis for the engineering team.                             | Base               |

---

### 06m — Tenant Feature-Gated Schema

**File:** `06m-tenant-feature-gated-schema.md`
**Schema:** `tenant_{tenant_id}` (feature-gated — created by Migration Runner)
**Status:** ⏳ Awaiting generation
**Tables: 17**

> **All tables in this artifact are feature-gated.** They do not exist in the
> base tenant schema. Each is created by the Migration Runner (Alembic) when
> the corresponding Feature Catalogue item is activated by the merchant.
> Every DDL block in 06m will carry the comment:
> `-- Feature-gated: activated by Migration Runner on feature activation`

| #   | Table                       | Feature                 | Description                                                                                                                                                           |
| --- | --------------------------- | ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `loyalty_accounts`          | Loyalty Programme       | One row per consumer in the programme. Holds points balance and tier.                                                                                                 |
| 2   | `point_transactions`        | Loyalty Programme       | Append-only ledger of points earned and redeemed.                                                                                                                     |
| 3   | `reward_tiers`              | Loyalty Programme       | Merchant-configured tiers (Bronze/Silver/Gold etc.) with threshold and benefits.                                                                                      |
| 4   | `redemption_events`         | Loyalty Programme       | Records of points redeemed against specific orders.                                                                                                                   |
| 5   | `discount_codes`            | Discount Engine         | Merchant-created alphanumeric codes. Holds type (% or fixed), scope, usage limits, validity window, min order value. Tenant-scoped.                                   |
| 6   | `discount_code_redemptions` | Discount Engine         | One row per code use. Holds order_id, consumer_id (nullable for guest), redeemed_at. Enforces per-customer and total limits.                                          |
| 7   | `abandoned_cart_jobs`       | Abandoned Cart Recovery | Tracks pending and sent recovery emails per consumer session. Holds cart snapshot, first/second reminder status, and any discount code attached.                      |
| 8   | `dynamic_pricing_rules`     | Dynamic Pricing Engine  | Merchant-configured pricing rules (stock-age markdown, velocity surge, time-triggered flash sale). Holds rule type, conditions, adjustment, scope, and active window. |
| 9   | `dynamic_pricing_events`    | Dynamic Pricing Engine  | Append-only log of every price change made by a rule. Holds product_id, old_price, new_price, rule_id, triggered_at.                                                  |
| 10  | `subscription_plans`        | Subscription Orders     | Merchant-configured recurring order plans. Holds eligible products/collections, frequencies offered, and subscriber discount.                                         |
| 11  | `subscriptions`             | Subscription Orders     | One row per active consumer subscription. Holds plan_id, consumer_id, variant_id, frequency, next_order_date, status.                                                 |
| 12  | `subscription_orders`       | Subscription Orders     | Links recurring orders back to their parent subscription for analytics.                                                                                               |
| 13  | `gift_cards`                | Gift Cards              | Issued gift cards. Holds code, initial balance, current balance, issued_to (consumer_id or email), expiry_at.                                                         |
| 14  | `gift_card_transactions`    | Gift Cards              | Append-only ledger of gift card balance changes (issue, redeem, refund to card).                                                                                      |
| 15  | `bundle_definitions`        | Bundle Builder          | Merchant-defined product bundles. Holds component variant list, bundle price, and stock deduction rules.                                                              |
| 16  | `bundle_components`         | Bundle Builder          | Individual component rows per bundle definition. Holds variant_id, quantity, and whether it is swappable.                                                             |
| 17  | `affiliate_links`           | Affiliate & Referral    | Affiliate tracking links. Holds affiliate_id, UTM parameters, commission rate, and conversion attribution window.                                                     |

---

### 06n — State Machines

**File:** `06n-state-machines.md`
**Schema:** N/A (documentation artifact)
**Status:** ⏳ Awaiting generation

| #   | State Machine      | Entity                 | States                                                                                                                |
| --- | ------------------ | ---------------------- | --------------------------------------------------------------------------------------------------------------------- |
| 1   | Order lifecycle    | `orders`               | pending_payment → payment_confirmed → processing → partially_fulfilled → fulfilled → delivered → refunded / cancelled |
| 2   | Trial lifecycle    | `tenants`              | trialing → hard_stopped → grace_period → deleted / converted                                                          |
| 3   | Feature activation | `tenant_feature_state` | available → activating → active → deactivating → inactive / failed                                                    |
| 4   | Purchase order     | `purchase_orders`      | draft → sent → acknowledged → partial → received / cancelled                                                          |
| 5   | Blog post          | `blog_posts`           | draft → scheduled → published → archived                                                                              |
| 6   | B2B approval       | `approval_requests`    | pending → approved / declined                                                                                         |
| 7   | Migration job      | `migration_jobs`       | queued → scraping → parsing → importing → completed / failed / blocked                                                |
| 8   | Stock transfer     | `stock_transfers`      | draft → in_transit → received / cancelled                                                                             |
| 9   | B2B account        | `b2b_accounts`         | invited → pending_approval → active → suspended / archived                                                            |
| 10  | Subscription       | `subscriptions`        | active → paused → cancelled / expired                                                                                 |

---

### 06o — Index Strategy

**File:** `06o-index-strategy.md`
**Schema:** Both `kloudshop_platform` and `tenant_{tenant_id}`
**Status:** ⏳ Awaiting generation

> This artifact consolidates all `CREATE INDEX` DDL and prose rationale for
> every table across both schemas. Each table section includes: the query
> patterns it serves, the full `CREATE INDEX` statement, and a one-line
> explanation of why the index exists. Non-obvious composite and partial
> indexes are given extended rationale.

---

### 06p — Infrastructure Notes (DMF-09)

**File:** `06p-infrastructure-notes.md`
**Schema:** N/A (infrastructure documentation)
**Status:** ✅ Generated

> Covers SYS-18 version detection infrastructure (version.json on Cloud
> Storage, service worker polling strategy, Flutter JS interop), GCIP
> tenant provisioning flow, and the LB log-based trial visitor count
> pipeline. No PostgreSQL DDL — infrastructure and configuration notes only.

---

## Summary Statistics

| Category                                       | Count                 |
| ---------------------------------------------- | --------------------- |
| Total artifacts to generate                    | 16 (06a1 through 06p) |
| Total PostgreSQL tables (platform schema)      | 29                    |
| Total PostgreSQL tables (tenant base schema)   | 62                    |
| Total PostgreSQL tables (tenant feature-gated) | 17                    |
| BigQuery table/view definitions                | 8                     |
| State machines to document                     | 10                    |
| **Grand total tables / schemas**               | **116**               |

---

## Generation Progress

| Artifact                              | Status           | Tables      | Notes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| ------------------------------------- | ---------------- | ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `06-schema-inventory.md`              | ✅ Generated      | —           | This file                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `06a1-platform-core-schema.md`        | ✅ Generated      | 18          | Platform core operational tables                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `06a2-platform-catalogue-schema.md`   | ✅ Generated      | 11          | Platform theme, feature, and carrier catalogue tables                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `06b-tenant-catalog-schema.md`        | ✅ Generated (v2) | 13          | Tenant product catalogue — gap-hardened (GAP-01 through GAP-09a)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| `06c-tenant-orders-schema.md`         | ✅ Generated      | 6           | Orders, line items, events (append-only), shipments, shipment items, notes                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `06d-tenant-inventory-schema.md`      | ✅ Generated      | 5           | Stock locations, inventory (generated quantity_available), reservations, transfers, packaging presets                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `06e-tenant-supplier-schema.md`       | ✅ Generated      | 6           | Suppliers, purchase orders, PO lines (manufacture_date for perishable batch traceability), performance events (append-only), supplier score weights (single-row), shipping settings (single-row, DMF-01)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `06f-tenant-b2b-schema.md`            | ✅ Generated      | 6           | B2B accounts (flat, company_name display-only), price lists, price list items, approval workflows, approval requests, B2B invoices                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `06g-tenant-storefront-schema.md`     | ✅ Generated      | 7           | brand_profiles (is_age_gated GAP-09b, draft/active theme Cloud Storage paths, enabled_locales), storefront_content ((slot_id,locale) PK, DMF-02/06), merchant_carrier_connections (Secret Manager ref only), carrier_checkout_options, static_pages (Tiptap JSONB + body_tsv), static_page_translations, redirect_rules                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `06h-tenant-blog-schema.md`           | ✅ Generated      | 7           | blog_posts (Tiptap JSONB + body_tsv GENERATED 'simple' FTS, status lifecycle, Cloud Tasks scheduling), blog_post_translations (locale != 'en', is_auto_translated, generated body_tsv), blog_categories (name/slug unique, sort_order), blog_category_translations (is_auto_translated), blog_post_categories (pure join, composite PK), blog_tags (normalised lookup, no translations), blog_post_tags (pure join, composite PK)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `06i-tenant-messaging-schema.md`      | ✅ Generated      | 4           | message_threads (thread_type CHECK, linked_object_id plain UUID, RESTRICT deletes), thread_participants (staff/buyer only — no consumer, last_read_at for Redis reconciliation, participants auto-determined for context-linked threads), messages (IMMUTABLE sent rows — no updated_at after send, no deleted_at ever, body_tsv GENERATED 'simple' FTS DEC-04, is_draft auto-save pattern), message_attachments (mime_type = python-magic server-side only, 100MB max, Cloud Storage signed URL 15-min TTL, PDF JS scan pre-insert, rows never deleted)                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `06j-tenant-consumer-schema.md`       | ✅ Generated      | 4           | consumers (per-storefront GCIP isolation, gcip_uid TEXT opaque string, GDPR anonymisation-not-deletion, accepts_marketing FALSE default), consumer_addresses (is_default enforced at app layer not partial unique index — atomic swap rationale documented), consumer_sessions (nullable consumer_id for guests, session_token = cart persistence key for stock_reservations 06d, GDPR anonymisation of PII fields), wishlists (CASCADE on both FKs, archived variants retained with "no longer available" state, AI personalisation signal source)                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `06k-tenant-feature-config-schema.md` | ✅ Generated      | 3           | —                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| `06l-bigquery-analytics-schema.md`    | ✅ Generated      | 5           | BigQuery DDL (not PostgreSQL). 2 datasets: `kloudshop_analytics` (platform_feature_adoption, platform_revenue_daily) + `tenant_{id}_analytics` (storefront_events, order_funnel_daily, search_performance_daily). PARTITION BY, CLUSTER BY, dedup strategy, PII boundary documented. 5 gap tables deferred to `06l-addendum`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `06m-tenant-feature-gated-schema.md`  | ✅ Generated      | 17          | Loyalty Programme (reward_tiers, loyalty_accounts, point_transactions, redemption_events). Discount Engine/DEC-22 core (discount_codes, discount_code_redemptions). Abandoned Cart/DEC-22 core (abandoned_cart_jobs). Dynamic Pricing/DEC-22 core (dynamic_pricing_rules, dynamic_pricing_events). Subscription Orders (subscription_plans, subscriptions, subscription_orders). Gift Cards (gift_cards, gift_card_transactions). Bundle Builder (bundle_definitions, bundle_components). Affiliate & Referral (affiliate_links). BigQuery gap tables deferred to 06l-addendum.                                                                                                                                                                                                                                                                                                                                                                                                          |
| `06n-state-machines.md`               | ✅ Generated      | 10 machines | Order lifecycle (payment_status 6-state + fulfilment_status 6-state — two independent axes). Trial lifecycle (account_status 5-state including hard_stopped 216-hour window). Feature activation (tenant_feature_state 6-state — Firebase Remote Config sync on every transition). Purchase order (6-state including acknowledged as optional supplier-confirmation step). Blog post (4-state — Cloud Tasks scheduling, HTTP 410 on archive). B2B approval (4-state — auto_approved vs approved distinction preserved). Migration job (3 independent axes: scrape_status 5-state, import_status 5-state, gcp_track_b_status 4-state — "store ready" requires all three at terminal success). Stock transfer (4-state — explicit in_transit for double-entry inventory accounting). B2B account (5-state — pending_approval gated on merchant config). Subscription (4-state — next_order_at self-loop on active). Cross-reference table of all status columns and valid values included. |
| `06o-index-strategy.md`               | ✅ Generated      | All tables  | CREATE INDEX DDL + prose, audit completed with 3 missing state machine indexes identified. |
| `06p-infrastructure-notes.md`         | ✅ Generated      | —           | DMF-09 + GCIP provisioning + LB log-based trial visitor count pipeline                                                                                                                                                                                                                                                                                                                                                                                                                   |

---

## Handoff Instructions (for new chat sessions)

If this session reaches token limits before all artifacts are generated:

1. Upload `06-schema-inventory.md` (this file) to the new chat session
2. Upload `00-carry-forward-flags.md`
3. Upload all already-generated `06a1`, `06a2`, `06b`... artifacts
4. Upload `05-style-guide.md` (surgical edit already applied)
5. Say: *"Continue KloudShop Stage 6 schema generation. The inventory
   shows which artifacts are complete (✅) and which are pending (⏳).
   Continue from the first ⏳ artifact."*

The new session will have full context to resume without regression.
