# Carry-Forward Flags: KloudShop

> **Purpose:** This artifact is a single consolidated reference for every decision,
> data model requirement, deferred item, assumption, risk, and architectural note
> that has been flagged across all completed stages for resolution in a later stage
> or a later chat session. It is updated at the end of every session.
>
> **How to use it:** At the start of each new chat session, upload this file to the
> Claude Project alongside the relevant stage artifacts. Reference it before beginning
> any new stage to ensure no flagged item is silently dropped.
>
> **Last updated:** End of Stage 5 session.
> **Stages completed:** 1 (Product Brief), 1b (Tech Stack), 2 (Architecture),
> 3 (User Journeys), 4 (Feature Stories), 4b (MVP Scoping Gate), 5 (Style Guide).
> **Next stage:** 6 — Data Model & State.

---

## Section 1 — Data Model Flags (Stage 6)

All items below must be fully modelled in `06-data-model.md`. Each flag references
its source artifact for full detail.

---

### DMF-01 — Product & Variant Shipping Attributes
**Source:** `03-user-journeys.md` → Merchant Catalogue Management → M-43 flag

Fields required on `variants` table (per-variant):
- `weight_value` DECIMAL(10,3) nullable
- `weight_unit` VARCHAR(4) ENUM: `kg` | `lb`
- `length_value`, `width_value`, `height_value` DECIMAL(10,2) nullable
- `dimension_unit` VARCHAR(4) ENUM: `cm` | `in`
- `ships_in_own_packaging` BOOLEAN DEFAULT FALSE

Fields required on `products` table (product-level fallback):
- Same weight + dimension fields as variants
- `is_digital` BOOLEAN DEFAULT FALSE — excludes from all shipping logic
- `in_store_eligible` BOOLEAN DEFAULT TRUE — POS catalog filter field

Tenant-level `shipping_settings` table (one row per tenant):
- `default_weight_value`, `default_weight_unit` — fallback when product has no weight
- `weight_unit_preference`, `dimension_unit_preference` — store-wide display units
- `handling_days` INTEGER DEFAULT 1
- `order_cutoff_time` TIME

Platform-schema tables (shared, never per-tenant):
- `carriers` — carrier_id, display_name, logo_url, supported_regions, integration_type, status
- `carrier_service_levels` — service_level_id, carrier_id, display_name, transit_days_min/max, supported_regions

Tenant-schema tables:
- `merchant_carrier_connections` — connection_id, carrier_id, account_number, credentials_secret_ref, is_active
- `carrier_checkout_options` — option_id, service_level_id, is_enabled, handling_markup_type, handling_markup_value, allowed_destination_countries
- `packaging_presets` — preset_id, name, dimensions, max_weight, is_default

Fallback resolution order for rate calculation:
1. Variant-level weight + dimensions
2. Product-level weight + dimensions
3. Tenant `default_weight_value`
4. Smallest packaging preset whose max_weight ≥ cart total
5. `is_default = TRUE` preset
6. Carrier API default packaging assumption

Google Shopping: `weight_value` at variant level maps to `shipping_weight` in feed.
Missing weight must surface a per-product admin warning.

---

### DMF-02 — Multilingual / i18n Architecture
**Source:** `03-user-journeys.md` → Merchant Storefront & Theming → M-53b flag

Supported locales at launch (LTR only): `en`, `de`, `fr`, `sv`, `no`, `da`, `nl`, `es`, `pt`, `it`.
RTL (Arabic, Hebrew, Urdu) — explicitly deferred post-MVP.

Tables required (tenant schema):
- `product_translations` — (product_id, locale) PK, title, description, slug, meta_title, meta_description
- `variant_translations` — (variant_id, locale) PK, title
- `collection_translations` — (collection_id, locale) PK, title, description, slug, meta_title, meta_description

`storefront_content` table — primary key changes to `(slot_id, locale)`:
```sql
CREATE TABLE storefront_content (
    slot_id        VARCHAR(128) NOT NULL,
    locale         VARCHAR(8)   NOT NULL DEFAULT 'en',
    slot_type      VARCHAR(32)  NOT NULL,
    content_value  TEXT,
    is_auto_translated BOOLEAN  DEFAULT FALSE,
    updated_at     TIMESTAMPTZ  DEFAULT NOW(),
    updated_by     UUID,
    PRIMARY KEY (slot_id, locale)
);
```
`is_auto_translated = TRUE` flags AI-generated content pending merchant review.

`brand_profiles.enabled_locales TEXT[]` — only listed locales generate hreflang tags.

Locale fallback chain: requested locale → `en` — never blank.
Storefront URL structure: `/de/products/widget-pro` (path-prefix, Google recommended).
hreflang tags auto-generated per page for all active locales.

Flutter admin i18n: all strings in ARB files (`app_en.arb`, `app_de.arb`, etc.).
`flutter_localizations` + `intl` package. Zero hardcoded strings enforced by `flutter_gen`.

---

### DMF-03 — Feature Configuration Parameters (feature_registry + tenant_feature_config)
**Source:** `03-user-journeys.md` → Feature Catalogue flag; `01b-tech-stack.md` → Schema-Driven Feature Setup Wizard

Platform-schema tables:
```sql
CREATE TABLE feature_registry (
    feature_id     VARCHAR(64) PRIMARY KEY,
    display_name   TEXT NOT NULL,
    tier_required  VARCHAR(16) NOT NULL,  -- 'DTC' | 'B2B' | 'Hybrid'
    tier_scope     VARCHAR(16) NOT NULL,  -- 'DTC' | 'B2B' | 'Hybrid'
    -- tier_scope drives Feature Catalogue visibility:
    -- trial DTC accounts see features where tier_scope IN ('DTC','Hybrid')
    -- trial B2B accounts see features where tier_scope IN ('B2B','Hybrid')
    -- paid Hybrid accounts see all features
    status         VARCHAR(16) NOT NULL,  -- 'stable' | 'beta' | 'deprecated'
    has_config     BOOLEAN DEFAULT FALSE,
    created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE feature_config_schema (
    config_key       VARCHAR(128) NOT NULL,
    feature_id       VARCHAR(64) REFERENCES feature_registry(feature_id),
    display_label    TEXT NOT NULL,
    description      TEXT,
    data_type        VARCHAR(16) NOT NULL,
    -- ENUM: 'string' | 'text' | 'integer' | 'float' | 'boolean'
    --       'date' | 'time' | 'datetime' | 'json_array' | 'json_object'
    default_value    TEXT,
    is_required      BOOLEAN DEFAULT FALSE,
    validation_rules JSONB,
    display_order    INTEGER NOT NULL DEFAULT 0,
    wizard_group     VARCHAR(64),
    PRIMARY KEY (config_key, feature_id)
);
```

Tenant-schema table (in base tenant schema from day one — never a per-feature migration):
```sql
CREATE TABLE tenant_feature_config (
    tenant_id    VARCHAR(64) NOT NULL,
    feature_id   VARCHAR(64) REFERENCES feature_registry(feature_id),
    config_key   VARCHAR(128) NOT NULL,
    config_value TEXT NOT NULL,
    set_at       TIMESTAMPTZ DEFAULT NOW(),
    set_by       UUID NOT NULL,
    PRIMARY KEY (tenant_id, feature_id, config_key)
);
```

Key separation: `feature_dependencies` + Alembic = schema changes (Phase 1).
`feature_config_schema` + `tenant_feature_config` = application data (Phase 2 wizard).
These never overlap.

---

### DMF-04 — Feature Dependency Graph & Migration State
**Source:** `01b-tech-stack.md` → Feature-Gated Schema Migration Architecture

```sql
CREATE TABLE feature_dependencies (
    feature_id  VARCHAR(64) REFERENCES feature_registry(feature_id),
    depends_on  VARCHAR(64) REFERENCES feature_registry(feature_id),
    -- Multiple rows per feature_id = multiple upstream dependencies
    -- Migration Runner resolves via Kahn's algorithm (topological sort)
    -- Circular dependencies rejected at CI by migration linter (hard build failure)
    PRIMARY KEY (feature_id, depends_on)
);

CREATE TABLE feature_migrations (
    migration_id   VARCHAR(128) PRIMARY KEY,
    feature_id     VARCHAR(64) REFERENCES feature_registry(feature_id),
    sequence_order INTEGER NOT NULL,
    description    TEXT NOT NULL,
    is_required    BOOLEAN DEFAULT TRUE
);

-- Per-tenant (in tenant_{tenant_id} schema):
CREATE TABLE tenant_migration_state (
    migration_id VARCHAR(128) PRIMARY KEY,
    feature_id   VARCHAR(64) NOT NULL,
    applied_at   TIMESTAMPTZ DEFAULT NOW(),
    applied_by   VARCHAR(64) NOT NULL
);
```

Firebase Remote Config flag `feature_{feature_id}_enabled` set TRUE on successful
activation — Flutter and FastAPI gate all feature code behind this flag from day one.

---

### DMF-05 — Internal Messaging Tables
**Source:** `01b-tech-stack.md` → Internal Messaging Architecture

All tables tenant-scoped (in `tenant_{tenant_id}` schema):
```sql
CREATE TABLE message_threads (
    thread_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_type      VARCHAR(32) NOT NULL,
    -- ENUM: 'direct' | 'order' | 'purchase_order' | 'sku' | 'buyer_account'
    linked_object_id UUID,
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    created_by       UUID NOT NULL
);

CREATE TABLE thread_participants (
    thread_id        UUID REFERENCES message_threads(thread_id),
    participant_id   UUID NOT NULL,
    participant_type VARCHAR(16) NOT NULL,  -- 'staff' | 'buyer'
    joined_at        TIMESTAMPTZ DEFAULT NOW(),
    last_read_at     TIMESTAMPTZ,
    PRIMARY KEY (thread_id, participant_id)
);

CREATE TABLE messages (
    message_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id   UUID REFERENCES message_threads(thread_id),
    sender_id   UUID NOT NULL,
    sender_type VARCHAR(16) NOT NULL,
    body        TEXT NOT NULL,
    body_tsv    TSVECTOR GENERATED ALWAYS AS (to_tsvector('simple', body)) STORED,
    -- 'simple' used (not 'english') — multilingual message bodies across 10 LTR locales
    -- Per-locale tsvector columns are a future i18n backlog enhancement
    is_draft    BOOLEAN DEFAULT FALSE,
    sent_at     TIMESTAMPTZ DEFAULT NOW()
    -- NO deleted_at — messages are immutable and never deleted
);

CREATE INDEX idx_messages_fts    ON messages USING GIN(body_tsv);
CREATE INDEX idx_messages_thread ON messages(thread_id, sent_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id, sent_at DESC);

CREATE TABLE message_attachments (
    attachment_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id      UUID REFERENCES messages(message_id),
    file_name       TEXT NOT NULL,
    mime_type       VARCHAR(64) NOT NULL,  -- server-validated via python-magic
    file_size_bytes BIGINT NOT NULL,
    storage_path    TEXT NOT NULL,
    uploaded_at     TIMESTAMPTZ DEFAULT NOW()
);
```

Business rules:
- Messages immutable after sending — no edit, no delete, ever
- Drafts: `is_draft = TRUE`, converted on send
- Unread counts in Redis (fast badge rendering), reconciled with `last_read_at` on session start
- Thread participants for context-linked threads auto-determined by object access rules

---

### DMF-06 — Storefront Content Table (with locale support)
**Source:** `01b-tech-stack.md` → Content Slot Architecture

```sql
CREATE TABLE storefront_content (
    slot_id        VARCHAR(128) NOT NULL,
    locale         VARCHAR(8)   NOT NULL DEFAULT 'en',
    slot_type      VARCHAR(32)  NOT NULL,
    -- ENUM: short_text | long_text | rich_text | image_url | video_url
    --       link_url | collection_ref | product_query
    content_value  TEXT,
    is_auto_translated BOOLEAN DEFAULT FALSE,
    updated_at     TIMESTAMPTZ DEFAULT NOW(),
    updated_by     UUID,
    PRIMARY KEY (slot_id, locale)
);
```

`slot_id` format: `"{component_instance_id}.{slot_key}"` e.g. `"hero_main.heading"`.
`product_query` slot type: stores JSON query spec (filters, sort, limit) resolved at render time.
Orphaned content (from old themes) is never deleted — preserved for theme switching back.

---

### DMF-07 — Multi-Supplier per SKU with Preference Ranking
**Source:** `03-user-journeys.md` → Merchant Supplier Management flag

```sql
-- Tenant-scoped tables
CREATE TABLE suppliers (
    supplier_id          UUID PRIMARY KEY,
    name                 TEXT NOT NULL,
    contact_name         TEXT,
    email                TEXT,
    phone                TEXT,
    address              TEXT,
    payment_terms        TEXT,
    default_lead_time_days INTEGER,
    currency             VARCHAR(3),
    status               VARCHAR(16),  -- 'active' | 'inactive' | 'archived'
    created_at           TIMESTAMPTZ DEFAULT NOW(),
    updated_at           TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE product_suppliers (
    variant_id             UUID REFERENCES variants(variant_id),
    supplier_id            UUID REFERENCES suppliers(supplier_id),
    supplier_sku           TEXT,
    unit_cost              DECIMAL(10,2),
    moq                    INTEGER,
    lead_time_override_days INTEGER,  -- NULL = use supplier default
    preference_rank        INTEGER NOT NULL,
    -- 1 = most preferred; scoped per variant
    -- exactly one rank-1 per variant enforced at application layer
    -- reranking is a transactional swap — never leaves two rank-1 entries
    last_used_at           TIMESTAMPTZ,
    notes                  TEXT,
    PRIMARY KEY (variant_id, supplier_id)
);

CREATE TABLE supplier_performance_events (
    event_id    UUID PRIMARY KEY,
    supplier_id UUID REFERENCES suppliers(supplier_id),
    po_id       UUID REFERENCES purchase_orders(po_id),
    event_type  VARCHAR(32),
    -- ENUM: 'late_delivery' | 'short_shipment' | 'quality_issue'
    --       'early_delivery' | 'correct_shipment' | 'price_increase' | 'price_decrease'
    severity    VARCHAR(16),  -- 'minor' | 'moderate' | 'severe'
    notes       TEXT,
    logged_by   UUID,
    logged_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE purchase_orders (
    po_id                UUID PRIMARY KEY,
    supplier_id          UUID REFERENCES suppliers(supplier_id),
    status               VARCHAR(16),
    -- 'draft' | 'sent' | 'partial' | 'received' | 'cancelled'
    ordered_at           TIMESTAMPTZ,
    expected_delivery_at TIMESTAMPTZ,
    received_at          TIMESTAMPTZ,
    notes                TEXT
);

CREATE TABLE purchase_order_lines (
    po_line_id        UUID PRIMARY KEY,
    po_id             UUID REFERENCES purchase_orders(po_id),
    variant_id        UUID,
    supplier_id       UUID,
    qty_ordered       INTEGER,
    qty_received      INTEGER,
    unit_cost         DECIMAL(10,2),
    discrepancy_flag  BOOLEAN DEFAULT FALSE,
    discrepancy_notes TEXT
);

CREATE TABLE supplier_score_weights (
    tenant_id            VARCHAR(64) PRIMARY KEY,
    on_time_weight       DECIMAL(4,2) DEFAULT 0.35,
    fill_rate_weight     DECIMAL(4,2) DEFAULT 0.25,
    quality_weight       DECIMAL(4,2) DEFAULT 0.25,
    price_stability_weight DECIMAL(4,2) DEFAULT 0.15
);
```

Composite supplier score formula:
`score = (on_time_rate × 0.35) + (fill_rate × 0.25) + (quality_score × 0.25) + (price_stability × 0.15)`
Weights are merchant-adjustable via `supplier_score_weights`.
Score never auto-changes preference_rank — advisory only.

BigQuery materialised view `supplier_scores` refreshed daily via Cloud Tasks.

---

### DMF-08 — Trial Account Hard-Stop Monitoring
**Source:** `04-feature-stories.md` → US-057; `01-product-brief.md` → Business Model

Tenant-schema additions for trial monitoring:
- `trial_gcp_credit_used` DECIMAL(10,4) — tracks cumulative GCP spend against $5 cap
- `trial_gmv_total` DECIMAL(12,2) — tracks cumulative pre-tax GMV against $600 cap
- `trial_start_at` TIMESTAMPTZ
- `trial_tier` VARCHAR(8) — 'DTC' | 'B2B' (Hybrid not available during trial)
- `trial_hard_stop_trigger` VARCHAR(16) nullable — 'gcp_credit' | 'gmv_cap' | 'day_30'
- `trial_hard_stop_at` TIMESTAMPTZ nullable — when trigger fired
- `trial_published_closing_at` TIMESTAMPTZ nullable — shown to merchant (trigger + 168 hrs rounded to 00:00 GMT)
- `trial_permanent_deletion_at` TIMESTAMPTZ nullable — actual deletion time (published + 48 hrs)
- `trial_storefront_hit_counter` INTEGER DEFAULT 0 — Redis counter, reset every 24 hrs after email send
- `trial_deleted_at` TIMESTAMPTZ nullable — when data permanently deleted
- `account_soft_deleted_at` TIMESTAMPTZ nullable — platform record soft-deletion timestamp

Platform-schema `tenants` table additions:
- `is_trial` BOOLEAN DEFAULT TRUE
- `paid_tier_activated_at` TIMESTAMPTZ nullable

Business rules:
- $5 GCP credit and $600 GMV monitored via Cloud Tasks scheduled jobs
- 216-hour deletion window = 168 hrs (published) + 48 hrs (silent grace)
- Storefront hit counter (Redis, per tenant_id) drives daily visitor-count emails
- All trial monitoring Cloud Tasks jobs are idempotent
- Account record never hard-deleted; soft-deleted indefinitely for re-engagement

---

### DMF-09 — Web Version Detection Infrastructure (SYS-18)
**Source:** `01b-tech-stack.md` → SYS-18 section; `03-user-journeys.md` → SYS-18

Static asset required: `/version.json` served at Cloud CDN with `Cache-Control: no-store`
```json
{ "build": "<git-sha>", "deployed_at": "<ISO8601>", "features_added": <int> }
```
- Written by Cloud Build at each production deployment
- `features_added` = diff of `feature_registry` rows between previous and current build

Service worker: custom (Flutter build with `--pwa-strategy=none`)
- Polls `/version.json` every 10 minutes and on user interaction after idle
- On hash mismatch: `postMessage({ type: 'NEW_VERSION_AVAILABLE', features_added: N })`
- Flutter admin app handles message via JS interop; renders banner in authenticated admin shell only
- Never shown on public storefront renderer
- "Update now" → `skipWaiting()` + `clients.claim()` + `window.location.reload()`
- "Remind me later" → re-shown after 4 hours or next login

Mobile: `package_info_plus` + `/version/latest` endpoint → standard app store update banner.

Risk: Custom service worker must not break Flutter's own hash-based cache manifest.
Fallback: `setInterval` polling in `main.dart` via `dart:js` — same UX, no service worker.
Validate in one dedicated spike sprint before committing.

---

### DMF-10 — Staff User Preferences (UI Settings)
**Source:** `05-style-guide.md` → Flutter Implementation Notes; decision DEC-23

`staff_users` table in `kloudshop_platform` schema gains a `preferences` JSONB column:

```sql
ALTER TABLE staff_users
  ADD COLUMN preferences JSONB NOT NULL DEFAULT '{}';
-- Example value: { "theme_mode": "dark", "dashboard_layout": "compact" }
```

- `theme_mode` — `"light"` | `"dark"` | `"system"` (default: `"system"`)
- Fetched on session bootstrap alongside the staff user record
- Updated via `PATCH /me/preferences` — FastAPI partial update, merges keys
- JSONB is extensible — future UI preferences (language override, notification
  settings, dashboard widget layout) add keys without schema migrations
- Never stored in Firebase Auth custom claims (reserved strictly for RBAC:
  `tenant_id`, `roles[]`, `account_type`, `is_owner`)
- Never stored in Firestore

---

## Section 2 — Deferred Items (Post-MVP / Post-PMF)

| ID | Item | Deferred To | Source |
|----|------|-------------|--------|
| DEF-01 | RTL language support (Arabic, Hebrew, Urdu) | Post-MVP | `01-product-brief.md`, `01b-tech-stack.md` |
| DEF-02 | PayPal payment method at checkout | Post-PMF | `01-product-brief.md` |
| DEF-03 | MBWay (Portugal) — direct SIBS API integration | Post-MVP | `01-product-brief.md`, `01b-tech-stack.md` |
| DEF-04 | ERP/CRM pre-built connectors (Salesforce, HubSpot, SAP) | Post-MVP | `01-product-brief.md` |
| DEF-05 | Headless commerce API tier (merchant brings own frontend) | Out of scope | `01-product-brief.md` |
| DEF-06 | AI regional inventory routing (multi-warehouse) | Post-MVP | `01b-tech-stack.md` |
| DEF-07 | Multi-region active-active Cloud SQL (Cloud Spanner) | Post-PMF scale | `01b-tech-stack.md` |
| DEF-08 | GKE Autopilot migration from Cloud Run | Post-PMF scale | `01b-tech-stack.md` |
| DEF-09 | AlloyDB migration from Cloud SQL | Post-PMF scale | `01b-tech-stack.md` |
| DEF-10 | Vertex AI Search migration from pgvector | Post-PMF scale | `01b-tech-stack.md` |
| DEF-11 | Consumer-facing DTC live chat / support messaging | Post-MVP | `01b-tech-stack.md` |
| DEF-12 | Per-locale tsvector FTS columns (messages.body) | Post-MVP i18n | `01b-tech-stack.md` |
| DEF-13 | Social commerce channels (TikTok/Instagram/Facebook) | MVP or post-MVP | `04-feature-stories.md` |
| DEF-14 | AI per-customer homepage personalisation | Post-PMF | `04-feature-stories.md` |
| DEF-15 | Customer churn prediction dashboard | Post-MVP | `04-feature-stories.md` |
| DEF-16 | B2B quote request workflow | Post-MVP | `04-feature-stories.md` |
| DEF-17 | Subscription / recurring orders | Feature Catalogue item | `04-feature-stories.md` |
| DEF-18 | Advanced bundle builder | Feature Catalogue item | `04-feature-stories.md` |
| DEF-19 | Multi-region Cloud Tasks fan-out for schema migrations | Post-PMF | `01b-tech-stack.md` |
| DEF-20 | Hybrid tier available during trial | Paid-only — by design | `04-feature-stories.md` |

---

## Section 3 — Assumptions Requiring Validation

| ID | Assumption | Action Required | Source |
|----|-----------|-----------------|--------|
| ASM-01 | Flutter Web storefronts can achieve Core Web Vitals scores competitive with Next.js SSR | CWV benchmark sprint in Phase 0 before committing Flutter Web for storefronts | `01-product-brief.md` |
| ASM-02 | Migration scraper can reliably extract structured data from Shopify/WooCommerce/Adobe Commerce without triggering bot-protection at scale | Technical spike in Sprint 1 | `01-product-brief.md` |
| ASM-03 | Mid-market merchants will self-serve onboard without a sales-assisted motion | 10 user interviews with Shopify Plus merchants before beta | `01-product-brief.md` |
| ASM-04 | Pass-through GCP billing at fixed 15% markup is commercially viable at low merchant counts | Unit economics model at 100, 500, and 2,000 merchants | `01-product-brief.md` |
| ASM-05 | One-click theme switching can be implemented without storefront downtime or content loss across all niche templates | Storefront theming architecture spike in Phase 0 | `01-product-brief.md` |
| ASM-06 | Custom service worker for SYS-18 version detection does not break Flutter's own hash-based cache manifest | One dedicated spike sprint before committing service worker approach | `01b-tech-stack.md` |

---

## Section 4 — Architecture Risks (Open)

| ID | Risk | Severity | Mitigation | Source |
|----|------|----------|------------|--------|
| RSK-01 | Flutter Web CWV scores uncompetitive for storefronts | High | Phase 0 benchmark. Fallback: FastAPI + Jinja2 for storefronts, Flutter Web for admin only | `02-architecture.md` |
| RSK-02 | Wildcard SSL for `*.*.kloudshop.biz` (two-level wildcard) not supported by standard certs | High | Use GCP-managed cert with explicit SANs for `wholesale.*` pattern, or Cloudflare proxying. Validate in Phase 0 | `02-architecture.md` |
| RSK-03 | Migration scraper blocked at scale by competitor bot-protection | High | Sprint 1 technical spike. Residential proxy pool (Bright Data). Playwright fallback. Crawl-rate throttling | `02-architecture.md` |
| RSK-04 | `.biz` → `.com` TLD migration SEO equity loss | Medium | 301 redirects auto-generated. Google Search Console recrawl via API. Dual-TLD operation minimum 3 months | `02-architecture.md` |
| RSK-05 | Schema migration failure mid-feature-activation leaving tenant schema in partial state | Medium | Cloud Tasks retry with exponential backoff. Alembic idempotency guarantees safe retry. Sentry alert on first failure | `02-architecture.md` |
| RSK-06 | Tenant schema isolation breach via SQL injection | High | Parameterised queries via SQLAlchemy Core. `tenant_id` injected server-side from JWT. Penetration test before beta | `02-architecture.md` |
| RSK-07 | GCP pass-through billing reconciliation complexity at scale | Medium | Isolate billing service as dedicated FastAPI module. Build and test before first paying merchant | `01b-tech-stack.md` |
| RSK-08 | Firebase Auth custom claims complexity for multi-tenant B2B | Medium | Define auth claim schema in Phase 0. Validate with B2B buyer portal prototype before full build | `01b-tech-stack.md` |

---

## Section 5 — Decisions Made This Session (Carry to All Future Stages)

| ID | Decision | Rationale | Affects |
|----|---------- |-----------|---------|
| DEC-01 | GCP pass-through billing markup is fixed 15% — formula: `merchant_bill = gcp_actual_cost × 1.15` | Replaces earlier variable 3–5% figure. Fixed markup is simpler to communicate and model | All artifacts |
| DEC-02 | Firebase Realtime Database replaced by Cloud Firestore for all real-time signalling | Firestore is newer, richer querying, better consistency — same GCP ecosystem | `01b-tech-stack.md`, `02-architecture.md` |
| DEC-03 | End consumer Firebase Auth claims: `tenant_id` + `account_type: consumer` on registration | Enables future loyalty, gift vouchers, repeat-checkout from Feature Catalogue | `01b-tech-stack.md` |
| DEC-04 | FTS on `messages.body` uses `'simple'` dictionary, not `'english'` | Safe for multilingual message bodies across 10 LTR locales | `01b-tech-stack.md` |
| DEC-05 | `long_text` content slot is drag-resizeable in WYSIWYG | Better merchant UX for long copy | `01b-tech-stack.md` |
| DEC-06 | `product_query` content slot type added | Enables dynamic product sourcing (e.g. "top 8 bestsellers") beyond static collection reference | `01b-tech-stack.md` |
| DEC-07 | `component_order_mobile` optional array in `theme.json` | Different component ordering per viewport without duplicating component configs | `01b-tech-stack.md` |
| DEC-08 | WYSIWYG Apply does not clear the draft — draft status set to `"active"` | Merchants can fine-tune and re-apply without starting over | `01b-tech-stack.md` |
| DEC-09 | `in_store_eligible BOOLEAN DEFAULT TRUE` on `products` table | POS catalog filter field; merchants mark `FALSE` for online-only items | `01b-tech-stack.md` |
| DEC-10 | `feature_dependencies` supports multiple upstream deps; resolved via topological sort (Kahn's algorithm); circular deps rejected at CI | Ensures correct migration sequencing for complex feature dependency chains | `01b-tech-stack.md` |
| DEC-11 | Feature activation sets Firebase Remote Config flag `feature_{feature_id}_enabled`; all feature code written behind this flag | Schema migration (Phase 1) and code activation (Remote Config) are always in sync | `01b-tech-stack.md` |
| DEC-12 | Trial is 30 days, not 1 month; three independent hard-stop triggers: (a) $5 GCP credit, (b) $600 GMV, (c) day-30 elapsed | Protects GCP costs while giving merchants real selling experience before committing | All artifacts |
| DEC-13 | Trial scope: merchant chooses DTC OR B2B — not both. Hybrid is paid-only ($49.99/mo) | Allows full feature depth trial of chosen tier; Hybrid preserved as paid differentiator | `04-feature-stories.md`, `01-product-brief.md` |
| DEC-14 | Post-hard-stop data window: 168 hrs (published, shown to merchant) + 48 hrs silent grace = 216 hrs total. Closing datetime always shown as `{DDD DD MMM YYYY} at 00:00 GMT` | Eliminates merchant confusion about "7 days" counting; GMT midnight is unambiguous | `04-feature-stories.md` |
| DEC-15 | Storefront 503 during trial hard-stop shows merchant-branded "We'll be back soon" — no KloudShop branding | Storefront is a consumer surface; upgrade prompt belongs in the merchant admin only | `04-feature-stories.md` |
| DEC-16 | Storefront visitor counter (Redis, per tenant_id) drives daily email to merchant during hard-stop: "Your store received {XX} visitors in the past 24 hours..." | Personalised urgency nudge; rate-limited to 1 email/24 hrs to avoid spam-flagging | `04-feature-stories.md` |
| DEC-17 | Account never hard-deleted; platform record soft-deleted indefinitely for re-engagement | Preserves re-engagement and promotional email targeting opportunity | `04-feature-stories.md` |
| DEC-18 | `feature_registry.tier_scope` VARCHAR(16) ENUM: `'DTC' | 'B2B' | 'Hybrid'` — drives Feature Catalogue visibility per trial tier and paid tier | Replaces implicit tier filtering; made explicit and data-driven | `04-feature-stories.md`, DMF-03 |
| DEC-19 | SYS-18: Flutter Web admin version detection via custom service worker polling `version.json` (Cache-Control: no-store); non-intrusive banner in authenticated admin shell only; mobile via standard app store update flow | Seamless non-forced update UX for merchant admin; never affects storefront consumers | `01b-tech-stack.md`, `03-user-journeys.md` |
| DEC-20 | Product Reviews: core platform feature — always-on, configured under Admin → Products → Reviews. Only registered consumers can submit reviews. Reviews from consumers with a matching purchase in order history are labelled "Informed Review". Reviews without a purchase match are shown without the badge — not suppressed. Not a Feature Catalogue item. | Incentivises post-purchase account creation; rewards verified buyers without excluding others | `04-feature-stories.md`, `04b-mvp-scope.md`, Stage 6 data model |
| DEC-21 | AI Copywriter (E23): core platform feature — always available inline in product editor and blog editor, no Feature Catalogue toggle. Three variants per request (benefit-led, problem-solution, authority). Brand Voice profile optional. GCP pass-through billable at actual Gemini cost × 1.15. | Immediate differentiator from day one for every merchant regardless of data volume | `04-feature-stories.md`, `04b-mvp-scope.md` |
| DEC-22 | Dynamic Pricing, Discount Engine / Coupon Codes, and Abandoned Cart Recovery are core platform features — always-on, configured directly in the merchant admin (Pricing → Rules, Discounts, Marketing → Automations respectively). Not Feature Catalogue items. Feature Catalogue is reserved for genuinely opt-in features a merchant may never want. | Eliminates contradiction between always-on MVP epics and Feature Catalogue opt-in model | `04b-mvp-scope.md`, all future stages |
| DEC-23 | User UI preferences (theme mode, future: language override, dashboard layout) stored in `staff_users.preferences JSONB` in `kloudshop_platform` schema. Never in Firebase Auth custom claims (reserved for RBAC only) or Firestore. Fetched on session bootstrap; updated via `PATCH /me/preferences`. | Custom claims are for auth/RBAC only — 1000 byte limit fills quickly with role assignments | `05-style-guide.md`, DMF-10 |

---

## Section 6 — Stage 4b Gate — MVP Scoping Gate

**Persona:** Technical Product Strategist
**Reads from:** `01-product-brief.md`, `04-feature-stories.md`
**Produces:** `04b-mvp-scope.md`
**Status:** Complete — `04b-mvp-scope.md` approved.

### Scoping decisions made at this gate

| Question | Decision |
|----------|----------|
| First merchant cohort | No preference — serve DTC or B2B whichever first paying merchant needs |
| Migration engine | Automated scraping is the MVP — CSV upload is a mandatory fallback if scraping is blocked |
| Multilingual (E21) | English-only at MVP. i18n architecture baked into core from day one; 10 LTR languages in v1.1 |
| POS (E11) | In MVP |
| Social Commerce (E12) | All four channels at MVP: TikTok Shop, Instagram Shopping, Facebook Shops, Google Shopping |
| Feature Catalogue content | Architecture + toggle engine ships at MVP; specific launch feature set decided as a follow-up |

### Five-filter applied per epic — see `04b-mvp-scope.md` for full rationale

| Filter | Question |
|--------|----------|
| Core loop | Does this feature sit in the critical path of the core user value loop? |
| Dependency | Is something else blocked until this is built? |
| Fake-ability | Can this be done manually in v1 without hurting trust? |
| Complexity tax | Is build cost disproportionate to v1 impact? |
| Validation value | Does this help us learn something important from real users? |

### What `04b-mvp-scope.md` contains

1. Core Hypothesis Being Tested
2. The Minimum Value Loop
3. MVP Feature Set (In MVP / Post-MVP / Explicitly Descoped)
4. MVP Build Sequence
5. Risks of This MVP Scope
6. What We're Explicitly NOT Learning From This MVP
