# 06g — Tenant Storefront & Carrier Configuration Schema
# KloudShop Stage 6 — Data Model

> **Artifact:** `06g-tenant-storefront-schema.md`
> **Schema:** `tenant_{tenant_id}` (one schema per merchant, provisioned at signup)
> **Persona:** Principal Data Engineer
> **Reads from:** `01-product-brief.md`, `01b-tech-stack.md`, `02-architecture.md`,
>   `03-user-journeys.md`, `04-feature-stories.md`, `04b-mvp-scope.md`,
>   `00-carry-forward-flags.md` (DMF-01 through DMF-10)
> **Depends on:** `06a2-platform-catalogue-schema.md` (carriers,
>   carrier_service_levels FKs — cross-schema, plain VARCHAR/UUID),
>   `06b-tenant-catalog-schema.md` (brand_profiles referenced by products,
>   collections, and the AI copywriter log)
> **Tables:** 7 (brand_profiles, storefront_content, merchant_carrier_connections,
>   carrier_checkout_options, static_pages, static_page_translations,
>   redirect_rules)
> **Gap additions in this artifact:**
>   GAP-09b — `brand_profiles.is_age_gated` BOOLEAN
> **Status:** ✅ Generated

---

## Overview

This artifact defines the storefront identity, content, carrier connection, and
navigation schema for a KloudShop merchant tenant. All seven tables live inside
`tenant_{tenant_id}` and are provisioned at signup via the base Alembic migration.

**Key design decisions reflected in this schema:**

- **`brand_profiles` is one row per storefront, not one row per tenant** — Hybrid
  merchants have two rows: one for their DTC storefront and one for their B2B buyer
  portal. Each has independent brand name, slug, logo, theme, and locale settings.
  DTC and B2B tiers have exactly one row. The `storefront_type` column (`'dtc'` or
  `'b2b'`) distinguishes them. A UNIQUE constraint on `(storefront_type)` is intentionally
  absent — it is enforced at application layer to allow flexible future storefront types
  without a schema change.

- **`brand_profiles.draft_theme_config_url` and `active_theme_config_url`** — these
  are Cloud Storage paths, not theme_id references. A merchant's customised theme
  lives in their own tenant bucket, not in the global theme catalogue. The global
  catalogue entry is never mutated by any merchant action (01b-tech-stack.md).

- **`storefront_content` has a composite PK of `(slot_id, locale)`** — mandated by
  DMF-02 and DMF-06. The base locale is always `en`. Other locales are populated by
  the AI auto-translation pipeline. `is_auto_translated = TRUE` flags unreviewed
  AI content. Orphaned content (from old themes) is never deleted — the row is
  retained so switching back to a previous theme restores the merchant's copy.

- **`merchant_carrier_connections` never stores raw credentials** — only a GCP
  Secret Manager reference path. The actual API keys and account secrets live in
  Secret Manager, accessed by FastAPI via Workload Identity. The
  `credentials_secret_ref` column stores the path only
  (e.g. `projects/kloudshop-prod/secrets/carrier-fedex-tenant-acmeco/versions/latest`).

- **`carrier_checkout_options` references `carrier_service_levels` from the platform
  schema** — stored as `VARCHAR(64)` matching the `service_level_id` PK. No DB FK
  constraint is possible across schemas in Cloud SQL. Application layer validates.

- **`static_pages` uses Tiptap/ProseMirror JSONB for body** — consistent with
  `blog_posts` (06h). A companion `body_tsv TSVECTOR` generated column provides
  full-text search across page content. Slug is unique among published pages.

- **`redirect_rules` is auto-populated** — when any slug changes (product, collection,
  static page, blog post), the application automatically inserts a 301 redirect row
  from the old path to the new path. Merchants can also create rules manually from
  the 301 redirect manager in admin.

- **GAP-09b — `brand_profiles.is_age_gated BOOLEAN`** — when TRUE, the entire
  storefront presents an age-verification gate before any content is shown. This is
  distinct from per-product age gating (`products.minimum_age_years` in 06b), which
  gates individual checkout items. Storefront-level gating is for merchants whose
  entire catalogue is age-restricted (e.g. a dedicated alcohol retailer, adult
  content platform). Both mechanisms can coexist — storefront gate first, then
  per-product gate at checkout.

**AI agent note:** Cross-schema references to `kloudshop_platform.carriers` and
`kloudshop_platform.carrier_service_levels` are stored as `VARCHAR(64)` columns
matching those tables' primary keys. PostgreSQL does not support FK constraints
across schemas in Cloud SQL. All referential integrity is enforced at the application
layer on write.

---

## Table: `brand_profiles`

```sql
-- ============================================================
-- TABLE: brand_profiles
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per storefront. DTC and B2B tiers have one row.
--   Hybrid merchants have two rows — one per storefront.
--   Holds all brand identity and theme configuration for a storefront.
--
-- BUSINESS RULES:
--   1. DTC tier: exactly one row with storefront_type = 'dtc'.
--      B2B tier: exactly one row with storefront_type = 'b2b'.
--      Hybrid tier: one 'dtc' row + one 'b2b' row.
--      Enforced at application layer — no DB UNIQUE on storefront_type
--      to allow future storefront types without schema migration.
--   2. slug is the subdomain component of the storefront URL:
--      {slug}.kloudshop.biz (DTC) and wholesale.{slug}.kloudshop.biz (B2B).
--      Slug is chosen by the merchant at brand setup. Completely
--      independent of the account owner's Gmail or KloudShop login.
--      Unique across all tenants — enforced in kloudshop_platform.tenants
--      as well as here.
--   3. theme_id references kloudshop_platform.themes (platform schema).
--      Stored as VARCHAR(64) — cross-schema, no DB FK constraint.
--      Application validates on write.
--   4. active_theme_config_url is the Cloud Storage path of the
--      currently live theme.json for this storefront.
--      Pattern: gs://kloudshop-{tenant_id}/themes/active/{brand_profile_id}/theme.json
--      This is the merchant's CUSTOMISED copy — never the global catalogue entry.
--   5. draft_theme_config_url is the Cloud Storage path of the
--      in-progress WYSIWYG edits.
--      Pattern: gs://kloudshop-{tenant_id}/themes/draft/{brand_profile_id}/theme.json
--      NULL when no draft exists (merchant has not opened the WYSIWYG editor
--      or has applied all changes). Writing in WYSIWYG = saves here.
--      Applying theme = copies draft → active, clears draft_status.
--   6. enabled_locales TEXT[] controls which locales are active on this
--      storefront. Only listed locales generate hreflang tags and
--      locale-prefixed URLs. 'en' is always implicitly active; it may or
--      may not appear in the array (application normalises on read).
--   7. is_age_gated (GAP-09b): when TRUE, the storefront presents a
--      full-screen age verification gate before any content is shown.
--      Used for merchants whose entire catalogue is age-restricted
--      (e.g. alcohol-only retailer, adult content platform). Distinct
--      from per-product age gating (products.minimum_age_years in 06b).
--      Both mechanisms can coexist: storefront gate fires first, then
--      per-product gate at checkout for specific items.
--   8. primary_color and secondary_color are the brand palette hex values.
--      Stored here for fast access during theme rendering without reading
--      the full theme.json from Cloud Storage on every request.
--      Always kept in sync with the active theme's color_tokens by the
--      application on theme apply.
--   9. timezone is the merchant's local timezone (IANA format). Used in
--      combination with shipping_settings.order_cutoff_time (06e) to
--      compute actual UTC cutoff for handling day calculations.
-- ============================================================

CREATE TABLE brand_profiles (
    brand_profile_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- ── Storefront Type ───────────────────────────────────────
    storefront_type          VARCHAR(8) NOT NULL DEFAULT 'dtc',
    -- 'dtc' | 'b2b'
    -- DTC and B2B tiers have one row. Hybrid has two.

    -- ── Brand Identity ────────────────────────────────────────
    brand_name               TEXT NOT NULL,
    -- Display name for this storefront's brand. Shown in the storefront
    -- header, email templates, SEO metadata, and JSON-LD. Completely
    -- independent of the merchant's account name or Gmail address.

    slug                     VARCHAR(63) NOT NULL,
    -- Subdomain slug for this storefront.
    -- DTC: {slug}.kloudshop.biz
    -- B2B: wholesale.{slug}.kloudshop.biz
    -- Unique within this tenant (enforced below). Must also be unique
    -- across all tenants — platform-level uniqueness enforced in
    -- kloudshop_platform.tenants at provisioning time.
    -- Format: lowercase, alphanumeric + hyphens, 3–63 chars.

    logo_url                 TEXT,
    -- Cloud CDN URL of the brand logo. Uploaded to Cloud Storage and
    -- served via CDN. NULL until merchant uploads a logo.
    -- Pattern: https://cdn.kloudshop.biz/tenant/{tenant_id}/logo/{uuid}.png

    favicon_url              TEXT,
    -- Cloud CDN URL of the favicon. NULL until uploaded.

    -- ── Colour Palette (fast-access denormalisation) ──────────
    primary_color            CHAR(7),
    -- Brand primary colour as hex (e.g. '#124B47'). Kept in sync with
    -- the active theme's color_tokens.primary on theme apply.

    secondary_color          CHAR(7),
    -- Brand secondary/accent colour as hex.

    -- ── Age Gating (GAP-09b) ─────────────────────────────────
    is_age_gated             BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = entire storefront presents a full-screen age verification
    -- gate before any content is accessible. Used for merchants whose
    -- entire catalogue is age-restricted (e.g. dedicated alcohol retailer).
    -- Distinct from per-product age gating (products.minimum_age_years).
    -- Both can coexist: storefront gate fires first, then product gate
    -- at checkout. NULL for DTC merchants who do not use this feature;
    -- DEFAULT FALSE ensures no accidental gating.

    minimum_age_years_gate   SMALLINT DEFAULT NULL,
    -- The minimum age required to pass the storefront-level gate.
    -- Only meaningful when is_age_gated = TRUE.
    -- NULL when is_age_gated = FALSE.
    -- Examples: 18 (alcohol UK/EU), 21 (alcohol US), 18 (adult content).

    -- ── Theme Configuration ───────────────────────────────────
    theme_id                 VARCHAR(64),
    -- References kloudshop_platform.themes.theme_id.
    -- The base theme this storefront is built on. VARCHAR(64) — cross-schema,
    -- no DB FK constraint. Application validates on write.
    -- NULL if merchant has not yet selected a theme.

    active_theme_config_url  TEXT,
    -- Cloud Storage path of the currently live customised theme.json.
    -- Pattern: gs://kloudshop-{tenant_id}/themes/active/{brand_profile_id}/theme.json
    -- NULL until the merchant first applies a theme.
    -- This is the merchant's customised copy — the global catalogue entry
    -- (gs://kloudshop-themes/{theme_id}/theme.json) is NEVER mutated.

    draft_theme_config_url   TEXT,
    -- Cloud Storage path of in-progress WYSIWYG edits.
    -- Pattern: gs://kloudshop-{tenant_id}/themes/draft/{brand_profile_id}/theme.json
    -- NULL when no draft exists (no edits in progress).
    -- Saving in the WYSIWYG writes here. Applying promotes draft → active.

    -- ── Localisation ─────────────────────────────────────────
    enabled_locales          TEXT[] NOT NULL DEFAULT '{"en"}',
    -- Locales active on this storefront. 'en' always implicitly active.
    -- Only listed locales generate hreflang tags and locale-prefixed URLs.
    -- Application normalises 'en' presence on read.
    -- Examples: '{"en"}', '{"en","de","fr"}', '{"en","de","fr","sv","nl"}'

    -- ── Custom Domain ─────────────────────────────────────────
    custom_domain            TEXT,
    -- Merchant's custom domain (e.g. 'www.acmeco.com' for DTC,
    -- 'wholesale.acmeco.com' for B2B). NULL if using kloudshop.biz subdomain.
    -- SSL provisioned automatically via GCP Certificate Manager on set.

    custom_domain_verified   BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE once DNS propagation is confirmed and SSL is active.

    -- ── Timezone ─────────────────────────────────────────────
    timezone                 TEXT NOT NULL DEFAULT 'UTC',
    -- Merchant's local timezone in IANA format.
    -- Examples: 'America/New_York', 'Europe/London', 'Australia/Sydney'.
    -- Used with shipping_settings.order_cutoff_time to compute actual
    -- UTC cutoff for handling day calculations at checkout.

    -- ── Social & Contact ─────────────────────────────────────
    contact_email            TEXT,
    -- Public contact email shown in storefront footer and About page.

    social_links             JSONB NOT NULL DEFAULT '{}',
    -- Social media URLs for this storefront. Schema-free JSONB.
    -- Conventional keys: "instagram", "tiktok", "facebook", "x",
    --                    "linkedin", "youtube", "pinterest".
    -- Example: {"instagram": "https://instagram.com/acmeco", "tiktok": "..."}

    -- ── SEO Defaults ─────────────────────────────────────────
    default_meta_title       TEXT,
    -- Default meta title used on pages without an explicit meta title.
    -- Usually the brand name or a tagline.

    default_meta_description TEXT,
    -- Default meta description for pages without an explicit one.

    -- ── Status ───────────────────────────────────────────────
    is_published             BOOLEAN NOT NULL DEFAULT FALSE,
    -- FALSE = storefront is not publicly accessible (setup in progress).
    -- TRUE = storefront is live and serving traffic.

    -- ── Metadata ─────────────────────────────────────────────
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT brand_profiles_storefront_type_check CHECK (
        storefront_type IN ('dtc', 'b2b')
    ),

    CONSTRAINT brand_profiles_slug_format CHECK (
        slug ~ '^[a-z0-9][a-z0-9\-]*[a-z0-9]$' OR slug ~ '^[a-z0-9]$'
        -- Lowercase, alphanumeric + hyphens. No leading/trailing hyphens.
    ),

    CONSTRAINT brand_profiles_primary_color_format CHECK (
        primary_color IS NULL OR primary_color ~ '^#[0-9A-Fa-f]{6}$'
    ),

    CONSTRAINT brand_profiles_secondary_color_format CHECK (
        secondary_color IS NULL OR secondary_color ~ '^#[0-9A-Fa-f]{6}$'
    ),

    CONSTRAINT brand_profiles_age_gate_consistency CHECK (
        -- minimum_age_years_gate only valid when is_age_gated = TRUE.
        is_age_gated = TRUE OR minimum_age_years_gate IS NULL
    ),

    CONSTRAINT brand_profiles_minimum_age_positive CHECK (
        minimum_age_years_gate IS NULL OR minimum_age_years_gate > 0
    ),

    CONSTRAINT brand_profiles_slug_unique UNIQUE (slug)
    -- Slug must be unique within this tenant (between DTC and B2B profiles).
    -- Cross-tenant uniqueness enforced in kloudshop_platform.tenants.
);

COMMENT ON TABLE brand_profiles IS
    'One row per storefront (DTC and B2B are separate rows for Hybrid merchants). '
    'Holds brand identity, theme Cloud Storage paths, enabled locales, and '
    'is_age_gated (GAP-09b) for full-storefront age verification gates. '
    'active_theme_config_url = live customised theme.json in tenant Cloud Storage — '
    'never the global catalogue entry. Slug unique within tenant.';

CREATE UNIQUE INDEX idx_brand_profiles_slug
    ON brand_profiles (slug);
-- Rationale: Storefront SSR routing resolves brand_profile_id from the
-- subdomain slug on every request. O(1) lookup required.

CREATE INDEX idx_brand_profiles_storefront_type
    ON brand_profiles (storefront_type);
-- Rationale: Application fetches the DTC or B2B profile for a tenant
-- by type. Only 1–2 rows per tenant; index is a safety net for clarity.

CREATE INDEX idx_brand_profiles_custom_domain
    ON brand_profiles (custom_domain)
    WHERE custom_domain IS NOT NULL;
-- Rationale: Custom domain routing resolves brand_profile_id from the
-- incoming Host header on requests to merchant custom domains.
-- Partial on profiles that have a custom domain configured.

CREATE INDEX idx_brand_profiles_theme_id
    ON brand_profiles (theme_id)
    WHERE theme_id IS NOT NULL;
-- Rationale: When a theme is deprecated in the platform catalogue, the
-- Platform Admin queries which tenants are using it. Partial on configured.

CREATE INDEX idx_brand_profiles_age_gated
    ON brand_profiles (is_age_gated)
    WHERE is_age_gated = TRUE;
-- Rationale: Storefront SSR service checks is_age_gated on every page
-- load for age-gated storefronts. Partial index on gated profiles only —
-- the overwhelming majority of storefronts are not age-gated.
```

---

## Table: `storefront_content`

```sql
-- ============================================================
-- TABLE: storefront_content
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Merchant-authored content for every content slot on
--   the active storefront theme, per locale. This is the source
--   of truth for all storefront marketing text and media.
--   Theme.json defines slot structure; this table holds the values.
--
-- BUSINESS RULES:
--   1. Primary key is (slot_id, locale) — mandated by DMF-02/DMF-06.
--      'en' is always the base locale. Non-English locales are
--      populated by the AI auto-translation pipeline and stored here
--      with is_auto_translated = TRUE pending merchant review.
--   2. slot_id format: "{component_instance_id}.{slot_key}"
--      Examples: "hero_main.heading", "strip_mens.title",
--                "footer.newsletter_label"
--      The component_instance_id is the ID from component_order in
--      theme.json. The slot_key matches the content_slots definition.
--   3. slot_type determines the Flutter widget rendered in the WYSIWYG
--      Content tab and how content_value is interpreted:
--      'short_text'    — single-line text, max_chars enforced
--      'long_text'     — multi-line textarea, drag-resizeable (DEC-05)
--      'rich_text'     — Tiptap/ProseMirror JSONB (see note below)
--      'image_url'     — Cloud Storage URL of uploaded image
--      'video_url'     — Cloud Storage URL of uploaded video
--      'link_url'      — URL string with validation
--      'collection_ref'— collection_id (FK to collections)
--      'product_query' — JSON query spec resolved at render time (DEC-06)
--   4. content_value stores all types as TEXT. For rich_text slots,
--      it stores the Tiptap document as a JSON string. For image_url
--      and video_url it stores the Cloud Storage path. For
--      collection_ref it stores the UUID as text. For product_query
--      it stores the JSON query spec as text.
--   5. ORPHANED CONTENT IS NEVER DELETED. When a merchant switches
--      themes, slots that exist in the old theme but not the new theme
--      become orphans. Their rows are preserved so that switching back
--      restores the merchant's copy exactly. Orphaned rows are invisible
--      in the WYSIWYG (no slot definition in current theme.json) but
--      are retained in the DB indefinitely.
--   6. is_auto_translated = TRUE: content was AI-generated (Google
--      Cloud Translation API) and has not yet been reviewed by the
--      merchant. Shown with a "Review translation" badge in the WYSIWYG.
--      is_auto_translated = FALSE: merchant-authored or reviewed.
--      AI pipeline NEVER overwrites rows where is_auto_translated = FALSE.
--   7. updated_by is the staff_user_id who last edited this slot.
--      NULL for AI-generated translations (no human author).
-- ============================================================

CREATE TABLE storefront_content (
    slot_id              VARCHAR(128) NOT NULL,
    -- Composite identifier: "{component_instance_id}.{slot_key}"
    -- e.g. "hero_main.heading", "strip_mens.title"
    -- The component_instance_id matches the id field in theme.json
    -- component_order. The slot_key matches a content_slots entry.

    locale               VARCHAR(8) NOT NULL DEFAULT 'en',
    -- ISO locale code. 'en' = base locale (always present).
    -- Other values: 'de', 'fr', 'sv', 'no', 'da', 'nl', 'es', 'pt', 'it'.

    slot_type            VARCHAR(16) NOT NULL,
    -- Determines how content_value is interpreted and rendered.
    -- See business rules above for the full type definitions.

    content_value        TEXT,
    -- The actual content. NULL = slot is empty (not yet filled).
    -- Never force-populated — empty slots are valid and render with
    -- placeholder text or theme defaults in the storefront.

    is_auto_translated   BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = AI-generated translation pending merchant review.
    -- FALSE = merchant-authored or confirmed via review.
    -- AI pipeline never overwrites FALSE rows.

    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- When this content slot was last written to.

    updated_by           UUID,
    -- staff_user_id who last edited. NULL for AI-generated translations.

    PRIMARY KEY (slot_id, locale),

    CONSTRAINT storefront_content_slot_type_check CHECK (
        slot_type IN (
            'short_text', 'long_text', 'rich_text',
            'image_url', 'video_url', 'link_url',
            'collection_ref', 'product_query'
        )
    )
);

COMMENT ON TABLE storefront_content IS
    'Merchant-authored storefront content per (slot_id, locale). '
    'slot_id = "{component_instance_id}.{slot_key}" matching theme.json. '
    'is_auto_translated = TRUE rows never overwritten by AI pipeline. '
    'Orphaned content (from old themes) is never deleted — preserved '
    'for theme-switching back. NULL content_value = empty slot (valid).';

CREATE INDEX idx_storefront_content_locale
    ON storefront_content (locale, slot_id);
-- Rationale: Storefront SSR fetches all content for the current locale
-- in a single query. Composite covers locale filter + slot lookup.

CREATE INDEX idx_storefront_content_stale_translations
    ON storefront_content (locale, is_auto_translated)
    WHERE is_auto_translated = TRUE AND locale != 'en';
-- Rationale: Translation review queue in the merchant admin — all
-- slots with AI-generated content pending review. Partial on non-English
-- auto-translated rows only (English is never auto-translated).

CREATE INDEX idx_storefront_content_slot_id
    ON storefront_content (slot_id);
-- Rationale: Theme switch content carry-forward algorithm — given the
-- set of slot_ids in the new theme, find all existing content rows
-- by slot_id to determine what carries forward vs. what is new/orphaned.
```

---

## Table: `merchant_carrier_connections`

```sql
-- ============================================================
-- TABLE: merchant_carrier_connections
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Records of carrier accounts connected by this merchant.
--   One row per carrier per merchant. Never stores raw credentials —
--   only a GCP Secret Manager reference path.
--
-- BUSINESS RULES:
--   1. carrier_id references kloudshop_platform.carriers.carrier_id.
--      VARCHAR(64) — cross-schema, no DB FK. Application validates.
--   2. credentials_secret_ref is the GCP Secret Manager path for
--      this merchant's credentials for this carrier.
--      Pattern: projects/{project_id}/secrets/
--               carrier-{carrier_id}-tenant-{tenant_id}/versions/latest
--      FastAPI retrieves the actual credentials at runtime via
--      Workload Identity — never cached, never logged, never stored here.
--   3. account_number is NOT a secret — it appears on waybills and
--      is safe to store in the database directly. It is separate
--      from the credentials_secret_ref (which holds API keys, OAuth
--      tokens, etc.).
--   4. is_active = FALSE means the connection is suspended without
--      deleting the record. The merchant can reactivate by providing
--      new credentials. credentials_secret_ref is retained to allow
--      the merchant to reconnect without re-entering all fields.
--   5. last_verified_at records when the credentials were last
--      successfully tested against the carrier API. NULL = never tested
--      or credentials have been updated but not yet re-verified.
--   6. One row per carrier per tenant. A merchant cannot have two
--      active connections to the same carrier. Enforced by UNIQUE.
-- ============================================================

CREATE TABLE merchant_carrier_connections (
    connection_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    carrier_id             VARCHAR(64) NOT NULL,
    -- References kloudshop_platform.carriers.carrier_id.
    -- VARCHAR(64) — cross-schema, application validates on write.
    -- Examples: 'fedex', 'dhl_express', 'royal_mail'.

    account_number         TEXT,
    -- The merchant's carrier account number. Safe to store in DB —
    -- appears on waybills and shipping documents. Not a secret.
    -- NULL for carriers that do not use account numbers.

    credentials_secret_ref TEXT,
    -- GCP Secret Manager path for this carrier's API credentials.
    -- Pattern: projects/{project_id}/secrets/
    --          carrier-{carrier_id}-tenant-{tenant_id}/versions/latest
    -- NULL for 'manual' integration_type carriers (no API credentials).
    -- FastAPI retrieves credentials at runtime via Workload Identity.

    is_active              BOOLEAN NOT NULL DEFAULT TRUE,
    -- TRUE = connection is live and used for rate quotes and labels.
    -- FALSE = suspended. Record retained; merchant can reactivate.

    last_verified_at       TIMESTAMPTZ,
    -- When the credentials were last successfully tested against the
    -- carrier API. NULL if never verified or credentials updated recently.

    connected_by           UUID NOT NULL,
    -- staff_user_id who connected this carrier account. Plain UUID.

    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT merchant_carrier_connections_unique_carrier
        UNIQUE (carrier_id)
    -- One connection per carrier per tenant. A merchant cannot
    -- have two connections to FedEx simultaneously.
);

COMMENT ON TABLE merchant_carrier_connections IS
    'Carrier account connections per tenant. Never stores raw credentials — '
    'only a GCP Secret Manager reference path. credentials_secret_ref is '
    'the path; FastAPI fetches actual secrets at runtime via Workload Identity. '
    'account_number is safe to store (appears on waybills, not a secret).';

CREATE UNIQUE INDEX idx_merchant_carrier_connections_carrier
    ON merchant_carrier_connections (carrier_id);
-- Rationale: One connection per carrier. Also serves as the lookup
-- when the checkout rate engine resolves which credential to use
-- for a given carrier_id.

CREATE INDEX idx_merchant_carrier_connections_active
    ON merchant_carrier_connections (carrier_id, is_active)
    WHERE is_active = TRUE;
-- Rationale: Checkout shipping rate calculation fetches all active
-- connections to query rates from. Partial on active connections only.
```

---

## Table: `carrier_checkout_options`

```sql
-- ============================================================
-- TABLE: carrier_checkout_options
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Per-service-level checkout configuration for this
--   merchant. Controls which carrier service levels appear at
--   checkout, with optional handling markup and country restrictions.
--
-- BUSINESS RULES:
--   1. service_level_id references kloudshop_platform.carrier_service_levels.
--      VARCHAR(64) — cross-schema, no DB FK. Application validates.
--   2. One row per service level. A merchant enables/disables and
--      configures each service level independently.
--   3. handling_markup_type determines how the merchant's handling
--      fee is applied on top of the carrier's rate:
--      'none'       — pass carrier rate through exactly; no markup
--      'flat'       — add a flat amount (handling_markup_value in currency)
--      'percentage' — add a percentage of the carrier rate
--                     (handling_markup_value as %, e.g. 10.00 = 10%)
--   4. handling_markup_value is the amount or percentage. Must be >= 0.
--      0.00 = no markup even when markup_type is 'flat' or 'percentage'.
--   5. allowed_destination_countries TEXT[]: when non-empty, this
--      service level only appears at checkout when the shipping address
--      country is in the array. Empty array = no country restriction.
--   6. is_enabled = FALSE hides this service level from checkout
--      without deleting the configuration. Useful for temporarily
--      disabling a service level during carrier outages.
--   7. display_name_override: when set, this overrides the carrier's
--      default service level display name at checkout. Useful for
--      merchants who want branded shipping options
--      (e.g. "Standard Delivery" instead of "FedEx Ground").
-- ============================================================

CREATE TABLE carrier_checkout_options (
    option_id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    service_level_id             VARCHAR(64) NOT NULL,
    -- References kloudshop_platform.carrier_service_levels.service_level_id.
    -- VARCHAR(64) — cross-schema, application validates on write.
    -- Examples: 'fedex_ground', 'dhl_express_ww', 'royal_mail_t24'.

    -- ── Visibility ────────────────────────────────────────────
    is_enabled                   BOOLEAN NOT NULL DEFAULT TRUE,
    -- TRUE = shown at checkout. FALSE = hidden but config preserved.

    display_name_override        TEXT,
    -- Custom checkout label. NULL = use carrier's default display_name.
    -- Example: "Standard Delivery" overriding "FedEx Ground".

    -- ── Handling Markup ───────────────────────────────────────
    handling_markup_type         VARCHAR(16) NOT NULL DEFAULT 'none',
    -- 'none' | 'flat' | 'percentage'

    handling_markup_value        DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    -- The markup amount or percentage. >= 0.
    -- For 'flat': added directly to the carrier rate (in storefront currency).
    -- For 'percentage': carrier_rate × (1 + value / 100).
    -- For 'none': ignored.

    -- ── Country Restrictions ──────────────────────────────────
    allowed_destination_countries TEXT[] NOT NULL DEFAULT '{}',
    -- ISO 3166-1 alpha-2 country codes. Empty array = no restriction.
    -- When non-empty, this option only shows for orders shipping to
    -- a country in this list.
    -- Example: '{"US","CA"}' — US and Canada only.

    -- ── Metadata ─────────────────────────────────────────────
    created_at                   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT carrier_checkout_options_service_level_unique
        UNIQUE (service_level_id),
    -- One configuration row per service level per tenant.

    CONSTRAINT carrier_checkout_options_markup_type_check CHECK (
        handling_markup_type IN ('none', 'flat', 'percentage')
    ),

    CONSTRAINT carrier_checkout_options_markup_value_non_negative CHECK (
        handling_markup_value >= 0
    ),

    CONSTRAINT carrier_checkout_options_percentage_range CHECK (
        -- Percentage markup must be <= 100% (doubling the rate is the max).
        -- Flat markups have no upper limit enforced at DB level.
        handling_markup_type != 'percentage'
        OR handling_markup_value <= 100.00
    )
);

COMMENT ON TABLE carrier_checkout_options IS
    'Per-service-level checkout configuration. Controls which carrier service '
    'levels appear at checkout, handling markup, and destination restrictions. '
    'service_level_id references kloudshop_platform.carrier_service_levels '
    '(cross-schema VARCHAR — no DB FK). One row per service level per tenant.';

CREATE UNIQUE INDEX idx_carrier_checkout_options_service_level
    ON carrier_checkout_options (service_level_id);
-- Rationale: Checkout rate engine resolves the merchant's configuration
-- for each carrier service level by service_level_id. O(1) lookup.

CREATE INDEX idx_carrier_checkout_options_enabled
    ON carrier_checkout_options (service_level_id, is_enabled)
    WHERE is_enabled = TRUE;
-- Rationale: Checkout only queries enabled options. Partial index keeps
-- the working set small when a merchant has many disabled options.

CREATE INDEX idx_carrier_checkout_options_countries
    ON carrier_checkout_options USING GIN (allowed_destination_countries)
    WHERE array_length(allowed_destination_countries, 1) > 0;
-- Rationale: Checkout filters options by buyer's destination country.
-- GIN required for efficient ANY() / @> queries on TEXT[] arrays.
-- Partial index excludes unrestricted options (empty array).
```

---

## Table: `static_pages`

```sql
-- ============================================================
-- TABLE: static_pages
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Merchant-created static content pages — About Us,
--   Contact, FAQ, Privacy Policy, Terms of Service, etc.
--   These are custom pages added by the merchant beyond the
--   storefront component stack. Each has its own URL slug and
--   appears in the storefront navigation.
--
-- BUSINESS RULES:
--   1. Body stored as JSONB (Tiptap/ProseMirror document format) —
--      consistent with blog_posts (06h). The rich-text editor in
--      the admin serialises to and deserialises from this format.
--      body_tsv provides full-text search across page content.
--   2. slug is unique among published pages. Archived pages may
--      share slugs with new pages (the new page is the canonical
--      destination; a redirect_rules row is auto-created).
--   3. status lifecycle:
--      'draft'     — not publicly accessible
--      'published' — live on storefront
--      'archived'  — hidden from storefront; row retained for history
--   4. show_in_nav = TRUE means this page appears in the storefront
--      navigation (footer links or nav_bar). FALSE = page exists
--      at its URL but is not linked from the navigation.
--   5. page_type is an advisory classification for admin UI grouping.
--      It does not affect rendering or routing — all pages render
--      the same way regardless of type.
-- ============================================================

CREATE TABLE static_pages (
    page_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- ── Content ───────────────────────────────────────────────
    title            TEXT NOT NULL,
    -- Page title in base locale (English). Shown in browser tab and
    -- as the page heading on the storefront.

    slug             VARCHAR(255) NOT NULL,
    -- URL slug: /pages/{slug}. URL-safe, lowercase, hyphens.
    -- Unique among non-archived pages (enforced by partial unique index).

    body             JSONB,
    -- Page body in Tiptap/ProseMirror document format.
    -- NULL = empty page (valid for pages under construction).
    -- Structured document: {"type": "doc", "content": [...]}

    body_tsv         TSVECTOR GENERATED ALWAYS AS (
        CASE
            WHEN body IS NOT NULL
            THEN to_tsvector('simple', COALESCE(body::text, ''))
            ELSE NULL
        END
    ) STORED,
    -- Generated FTS vector from the page body JSONB cast to text.
    -- 'simple' dictionary — safe for multilingual content.
    -- NULL when body is NULL.

    -- ── SEO ──────────────────────────────────────────────────
    meta_title       TEXT,
    meta_description TEXT,

    -- ── Classification ───────────────────────────────────────
    page_type        VARCHAR(32) NOT NULL DEFAULT 'custom',
    -- Advisory classification for admin UI grouping:
    -- 'about' | 'contact' | 'faq' | 'privacy_policy' |
    -- 'terms_of_service' | 'returns_policy' | 'cookie_policy' | 'custom'
    -- Does not affect routing or rendering.

    -- ── Status & Navigation ───────────────────────────────────
    status           VARCHAR(16) NOT NULL DEFAULT 'draft',
    -- 'draft' | 'published' | 'archived'

    show_in_nav      BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = linked from storefront navigation (footer or nav_bar).
    -- FALSE = accessible by URL but not linked from navigation.

    nav_label        TEXT,
    -- The label shown in navigation when show_in_nav = TRUE.
    -- NULL = use title as the navigation label.

    -- ── Metadata ─────────────────────────────────────────────
    created_by       UUID NOT NULL,
    -- staff_user_id who created this page. Plain UUID.

    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT static_pages_status_check CHECK (
        status IN ('draft', 'published', 'archived')
    ),

    CONSTRAINT static_pages_page_type_check CHECK (
        page_type IN (
            'about', 'contact', 'faq', 'privacy_policy',
            'terms_of_service', 'returns_policy', 'cookie_policy', 'custom'
        )
    )
);

COMMENT ON TABLE static_pages IS
    'Merchant-created static content pages (About, Contact, FAQ, Policy pages). '
    'Body stored as Tiptap/ProseMirror JSONB with companion body_tsv for FTS. '
    'show_in_nav controls navigation linking. Slug unique among non-archived pages.';

CREATE UNIQUE INDEX idx_static_pages_slug_published
    ON static_pages (slug)
    WHERE status != 'archived';
-- Rationale: Storefront SSR routing resolves page by slug. Slug must be
-- unique among non-archived pages — archived pages can share slugs with
-- newer pages. Partial index enforces this correctly.

CREATE INDEX idx_static_pages_status
    ON static_pages (status, show_in_nav)
    WHERE status = 'published';
-- Rationale: Navigation builder fetches all published pages that are
-- flagged for nav inclusion (show_in_nav = TRUE). Partial on published.

CREATE INDEX idx_static_pages_body_fts
    ON static_pages USING GIN (body_tsv)
    WHERE body_tsv IS NOT NULL;
-- Rationale: Storefront search queries static page content alongside
-- products and blog posts. GIN on the generated tsvector column.
-- Partial excludes NULL body_tsv (pages with no body content).
```

---

## Table: `static_page_translations`

```sql
-- ============================================================
-- TABLE: static_page_translations
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Per-(page_id, locale) translations of static page
--   content. English content stays on static_pages table.
--   Same is_auto_translated pattern as all other translation tables.
--
-- BUSINESS RULES:
--   1. PK: (page_id, locale). 'en' excluded by CHECK constraint.
--   2. body stored as JSONB (Tiptap/ProseMirror format) — same as
--      the parent static_pages.body. body_tsv generated column
--      provides FTS on translated content.
--   3. is_auto_translated = TRUE: AI-generated, not yet reviewed.
--      is_auto_translated = FALSE: merchant-authored, never
--      auto-overwritten by the AI translation pipeline.
--   4. When English source is updated on the static_pages table,
--      all translation rows for that page have is_auto_translated
--      set back to TRUE (stale) via Cloud Tasks job. Merchant-
--      reviewed (FALSE) rows are flagged stale but never overwritten.
-- ============================================================

CREATE TABLE static_page_translations (
    page_id              UUID NOT NULL
                         REFERENCES static_pages (page_id)
                         ON DELETE CASCADE,
    -- CASCADE: deleting a page removes all its translations.

    locale               VARCHAR(8) NOT NULL,
    -- 'de'|'fr'|'sv'|'no'|'da'|'nl'|'es'|'pt'|'it' — never 'en'.

    title                TEXT NOT NULL,
    -- Translated page title.

    slug                 VARCHAR(255),
    -- Locale-specific URL slug. NULL = use English slug + locale prefix.
    -- When set, the page is accessible at /{locale}/pages/{locale_slug}.

    body                 JSONB,
    -- Translated body in Tiptap/ProseMirror JSONB format. NULL = empty.

    body_tsv             TSVECTOR GENERATED ALWAYS AS (
        CASE
            WHEN body IS NOT NULL
            THEN to_tsvector('simple', COALESCE(body::text, ''))
            ELSE NULL
        END
    ) STORED,
    -- Generated FTS vector for this locale's body content.

    meta_title           TEXT,
    meta_description     TEXT,

    is_auto_translated   BOOLEAN NOT NULL DEFAULT TRUE,
    translated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_by          UUID,
    -- staff_user_id who reviewed/approved this translation. NULL if not reviewed.

    PRIMARY KEY (page_id, locale),

    CONSTRAINT static_page_translations_locale_not_english CHECK (locale != 'en')
);

COMMENT ON TABLE static_page_translations IS
    'Per-(page_id, locale) static page translations. English on static_pages table. '
    'body as Tiptap JSONB with generated body_tsv for FTS. '
    'is_auto_translated = FALSE rows never auto-overwritten by AI pipeline.';

CREATE INDEX idx_static_page_translations_locale
    ON static_page_translations (locale, page_id);
-- Rationale: Storefront SSR fetches the translation for a specific page
-- in the current locale. Composite covers locale + page lookup.

CREATE UNIQUE INDEX idx_static_page_translations_slug
    ON static_page_translations (locale, slug)
    WHERE slug IS NOT NULL;
-- Rationale: Locale-specific slug routing. One slug per locale.
-- Partial on rows that have an explicit locale slug.

CREATE INDEX idx_static_page_translations_stale
    ON static_page_translations (page_id, is_auto_translated)
    WHERE is_auto_translated = TRUE;
-- Rationale: Translation review queue — pages with AI-generated
-- translations pending merchant review.

CREATE INDEX idx_static_page_translations_fts
    ON static_page_translations USING GIN (body_tsv)
    WHERE body_tsv IS NOT NULL;
-- Rationale: Multilingual storefront search on translated page content.
```

---

## Table: `redirect_rules`

```sql
-- ============================================================
-- TABLE: redirect_rules
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: 301 redirect rules mapping old URL paths to new ones.
--   Rows are created automatically when slugs change (product,
--   collection, static page, blog post). Merchants can also create
--   and manage rules manually from the 301 redirect manager in admin.
--
-- BUSINESS RULES:
--   1. source_path is the old URL path (without domain).
--      Format: /products/old-slug, /collections/old-name,
--              /pages/old-page, /blog/old-post.
--      Always starts with '/'. Stored without trailing slash.
--   2. destination_path is the new URL path or a full URL for
--      external redirects. Internal paths start with '/'.
--      External redirects store the full URL (https://...).
--   3. redirect_type is always '301' at MVP. '302' reserved for
--      future temporary redirect support.
--   4. source_path must be unique — two rules cannot redirect
--      the same source path to different destinations.
--      Enforced by UNIQUE constraint.
--   5. Redirect chains (A → B → C) are resolved at the application
--      layer before writing — the application checks if the
--      destination_path is itself a source_path and flattens the
--      chain to A → C. This prevents redirect chains accumulating
--      over time and degrading SEO equity.
--   6. is_auto_generated = TRUE: created automatically by the
--      platform when a slug changes. is_auto_generated = FALSE:
--      manually created by a merchant or staff member.
--   7. Redirects for the locale-prefixed URL equivalents are
--      auto-created alongside the base redirect when a slug changes:
--      /products/old-slug → /products/new-slug
--      /de/products/old-slug → /de/products/new-slug
--      /fr/produits/ancien-slug → /fr/produits/nouveau-slug (if locale slug set)
--      This is handled at the application layer, not stored as
--      separate rows here — the SSR service applies the locale prefix
--      to both source and destination at render time.
-- ============================================================

CREATE TABLE redirect_rules (
    rule_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    source_path          TEXT NOT NULL,
    -- The old URL path being redirected FROM.
    -- Always starts with '/'. No trailing slash. No domain.
    -- Examples: '/products/old-widget', '/collections/legacy-sale',
    --           '/pages/old-about-us'

    destination_path     TEXT NOT NULL,
    -- The new URL path or full URL being redirected TO.
    -- Internal: starts with '/' (e.g. '/products/new-widget').
    -- External: full URL (e.g. 'https://example.com').

    redirect_type        SMALLINT NOT NULL DEFAULT 301,
    -- HTTP redirect status code. 301 = permanent (SEO equity passes).
    -- 302 reserved for future use (temporary, no SEO equity transfer).

    is_auto_generated    BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = auto-created by the platform on a slug change.
    -- FALSE = manually created by merchant from the 301 redirect manager.

    created_by           UUID,
    -- staff_user_id who created this rule. NULL for auto-generated rules
    -- (system actor). Plain UUID.

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT redirect_rules_source_path_unique UNIQUE (source_path),
    -- One redirect per source path — no conflicting rules.

    CONSTRAINT redirect_rules_redirect_type_check CHECK (
        redirect_type IN (301, 302)
    ),

    CONSTRAINT redirect_rules_source_starts_with_slash CHECK (
        source_path LIKE '/%'
    ),

    CONSTRAINT redirect_rules_no_self_redirect CHECK (
        source_path != destination_path
        -- A path cannot redirect to itself.
    )
);

COMMENT ON TABLE redirect_rules IS
    'URL 301 redirect rules. Auto-created when slugs change; '
    'manually manageable from the admin redirect manager. '
    'source_path must be unique — no conflicting rules. '
    'Redirect chains are flattened at application layer before INSERT.';

CREATE UNIQUE INDEX idx_redirect_rules_source_path
    ON redirect_rules (source_path);
-- Rationale: Storefront SSR checks for a redirect rule on every 404
-- response. O(1) lookup by source_path is critical for performance —
-- every broken link or slug change triggers this query.

CREATE INDEX idx_redirect_rules_auto_generated
    ON redirect_rules (is_auto_generated, created_at DESC);
-- Rationale: Admin redirect manager separates auto-generated and
-- manually-created rules in the UI, sorted by recency.

CREATE INDEX idx_redirect_rules_destination
    ON redirect_rules (destination_path);
-- Rationale: Redirect chain detection — before inserting a new redirect,
-- the application checks if destination_path is itself a source_path
-- (chain) and flattens it. This reverse lookup makes that check O(1).
```

---

## Updated Schema Inventory Entry

After generating this artifact, update `06-schema-inventory.md`:

```
| `06g-tenant-storefront-schema.md` | ✅ Generated | 7 | brand_profiles (is_age_gated GAP-09b, draft/active theme Cloud Storage paths, enabled_locales), storefront_content ((slot_id,locale) PK, DMF-02/06), merchant_carrier_connections (Secret Manager ref only), carrier_checkout_options, static_pages (Tiptap JSONB + body_tsv), static_page_translations, redirect_rules (chain-flattening noted) |
```
