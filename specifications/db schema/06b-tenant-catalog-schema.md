# 06b — Tenant Catalog Schema
# KloudShop Stage 6 — Data Model

> **Artifact:** `06b-tenant-catalog-schema.md`
> **Schema:** `tenant_{tenant_id}` (one schema per merchant, provisioned at signup)
> **Persona:** Principal Data Engineer
> **Reads from:** `01-product-brief.md`, `01b-tech-stack.md`, `02-architecture.md`,
>   `03-user-journeys.md`, `04-feature-stories.md`, `04b-mvp-scope.md`,
>   `00-carry-forward-flags.md` (DMF-01 through DMF-10),
>   `8_apr_.md` (GAP-01 through GAP-09a — genre positioning additions)
> **Depends on:** `06a1-platform-core-schema.md` (order_sources FK),
>   `06a2-platform-catalogue-schema.md` (carriers FK via product_suppliers),
>   `06j-tenant-consumer-schema.md` (consumers FK on product_reviews — forward-declared
>   with plain UUID; FK constraint added post-provisioning via ALTER TABLE)
> **Tables:** 13 (products, variants, product_translations, variant_translations,
>   collections, collection_translations, collection_products, product_images,
>   product_suppliers, product_reviews, review_votes, seo_settings,
>   ai_copywriter_log)
> **Gap additions in this revision:**
>   GAP-01 — Digital asset delivery fields on variants
>   GAP-02 — Perishable / batch / expiry tracking on variants
>   GAP-03 — Regulatory / compliance metadata on products
>   GAP-04 — Age restriction / verification gate on products
>   GAP-05 — Prescription / controlled-product flag on products
>   GAP-06 — Donation / pay-what-you-want pricing model on variants
>   GAP-08 — Species / pet-type attribute on variants
>   GAP-09a — Compliance document URL on products
> **Status:** ✅ Generated (v2 — gap-hardened)

---

## Overview

This artifact defines the complete product catalogue schema for a KloudShop
merchant tenant. Every table here lives inside `tenant_{tenant_id}` — a
PostgreSQL schema provisioned exclusively for one merchant at signup. No table
in this artifact is shared between merchants.

**Key design decisions reflected in this schema:**

- **Unlimited variants** — no artificial cap. The `variants` table carries a
  simple FK to `products` with no constraint on row count per product.
- **Shipping attributes at both product and variant level** (DMF-01) — variant
  values override product-level fallbacks. Missing values fall back to tenant
  `shipping_settings.default_weight_value`.
- **Translation tables use `(entity_id, locale)` composite PKs** (DMF-02) —
  one row per entity per locale. `is_auto_translated` flag distinguishes
  AI-generated from merchant-authored translations. English (`en`) is always
  the base locale and is stored in the parent table, not in translation rows.
- **`product_reviews.is_informed_review`** is a stored boolean, not computed
  on read. Set at review creation time; updated by event-driven Cloud Tasks
  when a qualifying purchase is confirmed, governed by
  `seo_settings.auto_update_informed_reviews`.
- **`ai_copywriter_log`** is append-only. No UPDATE, no DELETE. Feeds prompt
  quality analytics in BigQuery.
- **`product_suppliers`** implements DMF-07 (multi-supplier per SKU with
  preference ranking). Exactly one `preference_rank = 1` per variant is
  enforced at the application layer, not with a DB constraint, to allow
  atomic rank swaps without intermediate constraint violations.
- **Genre positioning gap fields** (8 Apr brief) — all gap additions are
  nullable columns or columns with explicit DEFAULT values. No existing
  row ever requires backfill. Non-destructive migration policy is preserved.

**AI agent note:** All tables in this schema are provisioned by the base
Alembic migration that runs when a new tenant is created (SYS-01). They are
NOT feature-gated. Every merchant has every table in this artifact from day one,
regardless of which features they have activated. The gap fields are harmless
NULL/DEFAULT values for merchants who do not need them.

---

## Extensions Required

```sql
-- Idempotent — safe to run at every tenant provisioning.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pg_trgm";    -- trigram similarity for product search
CREATE EXTENSION IF NOT EXISTS "btree_gin";  -- GIN indexes on scalar types
CREATE EXTENSION IF NOT EXISTS "vector";     -- pgvector for AI semantic search
```

---

## Table: `products`

```sql
-- ============================================================
-- TABLE: products
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per product in the merchant's catalogue.
--   Products are the parent entity. All variants, images,
--   translations, and supplier relationships are children.
--
-- BUSINESS RULES:
--   1. A product with no variants cannot be sold. At least one
--      variant must exist before a product can be published.
--      Enforced at application layer — not a DB constraint.
--   2. Weight and dimension fields are FALLBACK values only.
--      Variant-level values take precedence. If neither product
--      nor variant has weight set, shipping_settings.default_weight_value
--      is used. Full resolution order in DMF-01.
--   3. is_digital = TRUE excludes from all shipping logic.
--      Digital delivery is via email/download link.
--      See also variants.digital_asset_url (GAP-01).
--   4. in_store_eligible = TRUE = appears in POS catalog.
--   5. status: 'draft' (not visible) | 'active' (on storefront)
--              | 'archived' (hidden, retained for order history).
--   6. English title/description stored here (base locale).
--      Other locales stored in product_translations.
--   7. Changing slug auto-creates a redirect_rules row.
--   8. embedding: pgvector for AI semantic search on storefront.
--   9. compliance_metadata JSONB (GAP-03): schema-free regulatory
--      identifiers. Conventional keys documented in column comment.
--      Surfaced in Google Shopping feed where applicable.
--  10. minimum_age_years / age_verification_required (GAP-04):
--      signals checkout to present age-confirmation step.
--      Affects alcohol, adult content, certain supplements.
--  11. requires_prescription / prescription_document_required
--      (GAP-05): prescription_document_required = TRUE triggers
--      a file-upload step at checkout for pharmacy and vet merchants.
--  12. compliance_document_url (GAP-09a): Cloud Storage path to
--      an attached regulatory document (SDS, CE declaration, etc).
-- ============================================================

CREATE TABLE products (
    product_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- ── Identity & Content ───────────────────────────────────
    title            TEXT NOT NULL,
    -- Product title in the base locale (English).

    description      TEXT,
    -- Product description in base locale. NULL is valid.

    -- ── Status ───────────────────────────────────────────────
    status           VARCHAR(16) NOT NULL DEFAULT 'draft',

    -- ── SEO ──────────────────────────────────────────────────
    slug             VARCHAR(255) NOT NULL,
    -- /products/{slug}. Auto-generated from title.
    -- Unique among non-archived products.

    meta_title       TEXT,
    meta_description TEXT,

    -- ── Flags ────────────────────────────────────────────────
    is_digital       BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = excluded from all shipping logic.

    in_store_eligible BOOLEAN NOT NULL DEFAULT TRUE,
    -- FALSE = online-only; excluded from POS catalog.

    -- ── Shipping Fallbacks (DMF-01) ──────────────────────────
    weight_value     DECIMAL(10, 3),
    weight_unit      VARCHAR(4),       -- 'kg' | 'lb'
    length_value     DECIMAL(10, 2),
    width_value      DECIMAL(10, 2),
    height_value     DECIMAL(10, 2),
    dimension_unit   VARCHAR(4),       -- 'cm' | 'in'

    -- ── Compliance & Regulatory (GAP-03) ─────────────────────
    compliance_metadata JSONB NOT NULL DEFAULT '{}',
    -- Schema-free regulatory identifiers. JSONB is intentionally
    -- flexible — regulatory requirements vary by category/jurisdiction.
    --
    -- Conventional keys (not enforced — merchant-defined):
    --   "fda_ndc"           — FDA National Drug Code (Health)
    --   "ce_declaration"    — CE marking declaration (EU)
    --   "isbn"              — Book ISBN (Arts & Entertainment)
    --   "ean"               — EAN-13 barcode (all categories)
    --   "ingredients"       — Ingredient list (Food, Health)
    --   "allergens"         — Allergen declarations (Food)
    --   "nutritional_info"  — Nutrition facts (Food, Health)
    --   "breed_restriction" — Breed restrictions (Pets)
    --   "country_of_origin" — Origin labelling (Food, general)
    --
    -- Google Shopping feed mappings:
    --   compliance_metadata->>'ean'  → GTIN field
    --   compliance_metadata->>'nutritional_info' → food listing attributes

    compliance_document_url TEXT DEFAULT NULL,
    -- (GAP-09a) Cloud Storage path to an attached regulatory document.
    -- Examples: safety data sheet, CE declaration, FDA registration letter.
    -- Pattern: gs://kloudshop-{tenant_id}/compliance/{product_id}/{uuid}.pdf
    -- NULL = no document attached (the default for most products).

    -- ── Age Restriction (GAP-04) ─────────────────────────────
    minimum_age_years SMALLINT DEFAULT NULL,
    -- NULL = no age restriction. 18 or 21 for age-gated products.
    -- Storefront renderer and checkout flow check this field to
    -- present an age-confirmation step before purchase.

    age_verification_required BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = checkout must present an age verification step.
    -- Typically TRUE when minimum_age_years IS NOT NULL, but can
    -- also be TRUE where ID verification is required regardless of
    -- a specific minimum age.

    -- ── Prescription / Controlled Products (GAP-05) ──────────
    requires_prescription BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = product requires a valid prescription.
    -- Affects pharmacy, veterinary supply, medical device merchants.

    prescription_document_required BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = customer must upload a prescription document file
    -- at checkout. Triggers the prescription file-upload component.
    -- Only meaningful when requires_prescription = TRUE.

    -- ── AI Semantic Search ───────────────────────────────────
    embedding        vector(768),
    -- pgvector embedding from Vertex AI text-embeddings-gecko@003.
    -- NULL until first embedding job runs. Updated async via Cloud Tasks.

    -- ── Metadata ─────────────────────────────────────────────
    created_by       UUID NOT NULL,
    -- staff_user_id (plain UUID, no cross-schema FK).

    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- ── Constraints ──────────────────────────────────────────
    CONSTRAINT products_status_check CHECK (
        status IN ('draft', 'active', 'archived')
    ),
    CONSTRAINT products_weight_unit_check CHECK (
        weight_unit IN ('kg', 'lb') OR weight_unit IS NULL
    ),
    CONSTRAINT products_dimension_unit_check CHECK (
        dimension_unit IN ('cm', 'in') OR dimension_unit IS NULL
    ),
    CONSTRAINT products_slug_format CHECK (
        slug ~ '^[a-z0-9][a-z0-9\-]*[a-z0-9]$' OR slug ~ '^[a-z0-9]$'
    ),
    CONSTRAINT products_minimum_age_positive CHECK (
        minimum_age_years IS NULL OR minimum_age_years > 0
    ),
    CONSTRAINT products_prescription_logic CHECK (
        -- prescription_document_required can only be TRUE when
        -- requires_prescription is also TRUE.
        NOT (prescription_document_required = TRUE
             AND requires_prescription = FALSE)
    )
);

COMMENT ON TABLE products IS
    'One row per product. English content stored here; translations in '
    'product_translations. Weight/dimensions are fallbacks (DMF-01). '
    'compliance_metadata JSONB holds regulatory identifiers (GAP-03). '
    'Age restriction (GAP-04) and prescription (GAP-05) flags control checkout.';

CREATE UNIQUE INDEX idx_products_slug
    ON products (slug)
    WHERE status != 'archived';
-- Rationale: Storefront PDP routing resolves product by slug. Must be
-- unique among active/draft products. Archived products may share slugs.

CREATE INDEX idx_products_status
    ON products (status, updated_at DESC);
-- Rationale: Admin product list filtered by status, sorted by recency.

CREATE INDEX idx_products_in_store
    ON products (in_store_eligible, status)
    WHERE in_store_eligible = TRUE AND status = 'active';
-- Rationale: POS operator catalog query. Partial index keeps it fast
-- even with large catalogs.

CREATE INDEX idx_products_age_gated
    ON products (minimum_age_years)
    WHERE minimum_age_years IS NOT NULL;
-- Rationale: Checkout validation identifies age-gated products in cart.
-- Partial index on age-gated products only — small subset.

CREATE INDEX idx_products_prescription
    ON products (requires_prescription)
    WHERE requires_prescription = TRUE;
-- Rationale: Checkout identifies prescription products in cart.
-- Partial index on prescription products only.

CREATE INDEX idx_products_compliance_metadata
    ON products USING GIN (compliance_metadata);
-- Rationale: Admin search by compliance attribute (e.g. all products
-- with an EAN, all products with allergen data). GIN required for JSONB.

CREATE INDEX idx_products_embedding
    ON products USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);
-- Rationale: Semantic storefront search via cosine similarity.
-- IVFFlat lists=100 suitable for catalogs up to ~500K products.
-- Revisit nprobe and lists values as catalog grows.
```

---

## Table: `variants`

```sql
-- ============================================================
-- TABLE: variants
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per variant combination. No upper limit.
--   A simple product has exactly one variant.
--
-- BUSINESS RULES:
--   1. sku unique within tenant (not just product).
--   2. For pricing_model = 'fixed': price is the retail price.
--      For 'pwyw'/'donation': price is the minimum floor (0.00
--      means any amount accepted). compare_at_price MUST be NULL
--      for non-fixed models (variants_pwyw_no_compare_at constraint).
--   3. Shipping attributes override product-level fallbacks (DMF-01).
--   4. is_active = FALSE hides from storefront; preserves order history.
--   5. DIGITAL ASSET DELIVERY (GAP-01):
--      digital_asset_url: Cloud Storage path of the downloadable file.
--      Only meaningful when product.is_digital = TRUE.
--      download_limit: max downloads after purchase (NULL = unlimited).
--      download_expiry_hours: link TTL in hours (NULL = no expiry).
--   6. PERISHABLE / BATCH (GAP-02):
--      is_perishable flags food, supplement, vet product variants.
--      best_before_days: shelf life in days — static product characteristic.
--        manufacture_date is NOT here; it belongs on purchase_order_lines
--        (06e) recorded at goods receipt. Expiry = manufacture_date +
--        best_before_days. Post-MVP: inventory_batches for FIFO/FEFO.
--      lot_number: populated at goods receipt; used for recalls.
--   7. PRICING MODEL (GAP-06):
--      'fixed' = standard. 'pwyw' = pay-what-you-want.
--      'donation' = donation (same mechanics as pwyw, different UI).
--      pwyw_minimum_price: floor (NULL = any amount).
--      pwyw_suggested_price: pre-fills checkout input (NULL = blank).
--   8. PET SPECIES (GAP-08):
--      pet_species TEXT[]: species this variant is for.
--      Empty array = not pet-specific (default).
--      Maps to Google Shopping Merchant Center 'pet_type' attribute.
-- ============================================================

CREATE TABLE variants (
    variant_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    product_id       UUID NOT NULL
                     REFERENCES products (product_id)
                     ON DELETE CASCADE,

    -- ── Identity ─────────────────────────────────────────────
    sku              VARCHAR(255) NOT NULL,
    barcode          VARCHAR(128),

    -- ── Options ──────────────────────────────────────────────
    option_1         TEXT,
    option_2         TEXT,
    option_3         TEXT,

    -- ── Pricing Model (GAP-06) ────────────────────────────────
    pricing_model    VARCHAR(16) NOT NULL DEFAULT 'fixed',
    -- 'fixed' | 'pwyw' | 'donation'
    -- For pwyw/donation: price = minimum floor. compare_at_price must be NULL.

    -- ── Pricing ──────────────────────────────────────────────
    price            DECIMAL(12, 2) NOT NULL,
    -- Fixed price, or minimum floor for pwyw/donation. Never negative.

    compare_at_price DECIMAL(12, 2),
    -- Crossed-out sale price. Must be > price when set.
    -- Must be NULL for pricing_model != 'fixed' (see constraint).

    cost_per_item    DECIMAL(12, 2),
    -- Merchant purchase cost. For margin analytics only.

    -- ── PWYW Fields (GAP-06) ─────────────────────────────────
    pwyw_minimum_price   DECIMAL(10, 2) DEFAULT NULL,
    -- Minimum consumer input amount. NULL = any amount accepted.
    -- Only meaningful when pricing_model IN ('pwyw', 'donation').

    pwyw_suggested_price DECIMAL(10, 2) DEFAULT NULL,
    -- Pre-fills checkout price input. NULL = empty input shown.
    -- Only meaningful when pricing_model IN ('pwyw', 'donation').

    -- ── Shipping Attributes (DMF-01) ─────────────────────────
    weight_value     DECIMAL(10, 3),
    weight_unit      VARCHAR(4),         -- 'kg' | 'lb'
    length_value     DECIMAL(10, 2),
    width_value      DECIMAL(10, 2),
    height_value     DECIMAL(10, 2),
    dimension_unit   VARCHAR(4),         -- 'cm' | 'in'

    ships_in_own_packaging BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = use declared dimensions directly, skip packaging preset.

    -- ── Digital Asset Delivery (GAP-01) ──────────────────────
    digital_asset_url TEXT DEFAULT NULL,
    -- Cloud Storage path of the downloadable file.
    -- Pattern: gs://kloudshop-{tenant_id}/digital-assets/{variant_id}/{uuid}.{ext}
    -- NULL for all physical products.
    -- On order confirmation, fulfilment service generates a signed
    -- Cloud Storage download URL and emails it to the consumer.
    -- TTL of signed URL governed by download_expiry_hours.

    download_limit   INTEGER DEFAULT NULL,
    -- Max download count post-purchase. NULL = unlimited.
    -- Enforced at signed URL generation layer, not DB-level.

    download_expiry_hours INTEGER DEFAULT NULL,
    -- Hours until download link expires after order confirmation.
    -- NULL = no expiry. Common: 24, 48, 168 (7 days), 720 (30 days).

    -- ── Perishable / Batch Tracking (GAP-02) ─────────────────
    is_perishable    BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = variant has shelf life / requires batch traceability.
    -- Food, supplements, vet products, dated beauty products.

    best_before_days INTEGER DEFAULT NULL,
    -- Shelf life specification in days — a static PRODUCT CHARACTERISTIC,
    -- not a per-batch operational value. Example: 365 for a supplement
    -- with a one-year shelf life. NULL if not perishable or not tracked.
    --
    -- WHY manufacture_date is NOT stored here or on the products table:
    -- Manufacture date is per-batch operational data, not a product property.
    -- The same variant can have a January batch and a March batch in stock
    -- simultaneously. manufacture_date belongs on purchase_order_lines
    -- (artifact 06e), recorded at goods receipt.
    --
    -- Actual expiry date per batch is computed as:
    --   expiry_date = purchase_order_lines.manufacture_date + best_before_days
    --
    -- Post-MVP: an inventory_batches table will track per-batch stock levels
    -- with manufacture dates for merchants requiring FIFO/FEFO stock rotation.
    --
    -- Used for Google Shopping feed freshness signals for food listings.

    lot_number       TEXT DEFAULT NULL,
    -- Current batch/lot number. Populated at goods receipt.
    -- Used for recall traceability across orders.
    -- NULL if not tracked (most non-food merchants).

    -- ── Pet Species (GAP-08) ─────────────────────────────────
    pet_species      TEXT[] NOT NULL DEFAULT '{}',
    -- Species this variant is for. Empty = not pet-specific.
    -- Examples: '{dog}', '{dog,cat}', '{bird}', '{reptile}'.
    -- Maps to Google Merchant Center 'pet_type' feed attribute.

    -- ── Flags ────────────────────────────────────────────────
    is_active        BOOLEAN NOT NULL DEFAULT TRUE,
    requires_shipping BOOLEAN NOT NULL DEFAULT TRUE,
    taxable          BOOLEAN NOT NULL DEFAULT TRUE,

    -- ── Metadata ─────────────────────────────────────────────
    position         INTEGER NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- ── Constraints ──────────────────────────────────────────
    CONSTRAINT variants_sku_unique UNIQUE (sku),

    CONSTRAINT variants_pricing_model_check CHECK (
        pricing_model IN ('fixed', 'pwyw', 'donation')
    ),

    CONSTRAINT variants_price_non_negative CHECK (price >= 0),

    CONSTRAINT variants_compare_at_price_check CHECK (
        compare_at_price IS NULL OR compare_at_price > price
    ),

    CONSTRAINT variants_pwyw_no_compare_at CHECK (
        -- pay-what-you-want and donation variants must not have
        -- a compare_at_price — a crossed-out price is semantically
        -- meaningless on these pricing models.
        -- Confirmed: 8 Apr gap review session.
        pricing_model = 'fixed' OR compare_at_price IS NULL
    ),

    CONSTRAINT variants_weight_unit_check CHECK (
        weight_unit IN ('kg', 'lb') OR weight_unit IS NULL
    ),

    CONSTRAINT variants_dimension_unit_check CHECK (
        dimension_unit IN ('cm', 'in') OR dimension_unit IS NULL
    ),

    CONSTRAINT variants_download_fields_require_digital CHECK (
        -- download_limit and download_expiry_hours only valid when
        -- digital_asset_url is set. Safety net for data integrity.
        digital_asset_url IS NOT NULL
        OR (download_limit IS NULL AND download_expiry_hours IS NULL)
    ),

    CONSTRAINT variants_perishable_logic CHECK (
        -- best_before_days only meaningful when is_perishable = TRUE.
        is_perishable = TRUE OR best_before_days IS NULL
    ),

    CONSTRAINT variants_pwyw_minimum_non_negative CHECK (
        pwyw_minimum_price IS NULL OR pwyw_minimum_price >= 0
    ),

    CONSTRAINT variants_pwyw_fields_require_pwyw_model CHECK (
        -- pwyw price fields only valid on pwyw/donation pricing models.
        pricing_model IN ('pwyw', 'donation')
        OR (pwyw_minimum_price IS NULL AND pwyw_suggested_price IS NULL)
    )
);

COMMENT ON TABLE variants IS
    'One row per product variant. No variant cap. SKU unique per tenant. '
    'pricing_model: fixed/pwyw/donation controls checkout behaviour (GAP-06). '
    'digital_asset_url for digital file delivery (GAP-01). '
    'is_perishable/best_before_days/lot_number for food/supplement tracking (GAP-02). '
    'pet_species array for species discovery and Shopping feed (GAP-08). '
    'Shipping attributes override product-level fallbacks (DMF-01).';

CREATE UNIQUE INDEX idx_variants_sku
    ON variants (sku);
-- Rationale: SKU lookups on every order, POS sale, inventory update. O(1).

CREATE INDEX idx_variants_product_id
    ON variants (product_id, position);
-- Rationale: PDP loads all variants for a product ordered by position.

CREATE INDEX idx_variants_active_product
    ON variants (product_id, is_active)
    WHERE is_active = TRUE;
-- Rationale: Storefront variant selector — active variants only.

CREATE INDEX idx_variants_digital_assets
    ON variants (product_id)
    WHERE digital_asset_url IS NOT NULL;
-- Rationale: Order fulfilment identifies digital variants needing
-- download link generation. Partial on digital variants only.

CREATE INDEX idx_variants_perishable
    ON variants (is_perishable, lot_number)
    WHERE is_perishable = TRUE;
-- Rationale: Recall management — find all variants with a specific
-- lot_number. Partial on perishable variants only.

CREATE INDEX idx_variants_pet_species
    ON variants USING GIN (pet_species)
    WHERE array_length(pet_species, 1) > 0;
-- Rationale: Storefront species filter (@> contains query).
-- GIN required for TEXT[] array queries. Partial excludes non-pet products.

CREATE INDEX idx_variants_pricing_model
    ON variants (pricing_model)
    WHERE pricing_model != 'fixed';
-- Rationale: Checkout renders pwyw/donation input component for
-- non-fixed variants. Partial index — vast majority are 'fixed'.
```

---

## Table: `product_translations`

```sql
-- ============================================================
-- TABLE: product_translations
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Per-(product, locale) translations of all translatable
--   product fields. English content stays on products table.
--   One row per product per non-English locale.
--
-- BUSINESS RULES:
--   1. PK: (product_id, locale). 'en' excluded by CHECK constraint.
--   2. is_auto_translated = TRUE: AI-generated, not yet reviewed.
--      is_auto_translated = FALSE: merchant-authored, never
--      auto-overwritten by the AI translation pipeline.
--   3. When English source is updated on the products table,
--      all translation rows for the product have is_auto_translated
--      set back to TRUE (stale) via Cloud Tasks. FALSE rows are
--      flagged stale but never overwritten.
-- ============================================================

CREATE TABLE product_translations (
    product_id       UUID NOT NULL
                     REFERENCES products (product_id)
                     ON DELETE CASCADE,

    locale           VARCHAR(8) NOT NULL,
    -- 'de'|'fr'|'sv'|'no'|'da'|'nl'|'es'|'pt'|'it' — never 'en'.

    title            TEXT NOT NULL,
    description      TEXT,
    slug             VARCHAR(255),   -- NULL = use English slug + locale prefix
    meta_title       TEXT,
    meta_description TEXT,

    is_auto_translated BOOLEAN NOT NULL DEFAULT TRUE,
    translated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_by        UUID,

    PRIMARY KEY (product_id, locale),

    CONSTRAINT product_translations_locale_not_english CHECK (locale != 'en')
);

COMMENT ON TABLE product_translations IS
    'Per-(product, locale) translations. English on products table. '
    'is_auto_translated = FALSE rows never auto-overwritten by AI pipeline.';

CREATE INDEX idx_product_translations_locale
    ON product_translations (locale, product_id)
    WHERE is_auto_translated = FALSE;
-- Rationale: Storefront renders reviewed translations preferentially.

CREATE INDEX idx_product_translations_stale
    ON product_translations (product_id, is_auto_translated)
    WHERE is_auto_translated = TRUE;
-- Rationale: Translation review queue — all products with pending AI drafts.

CREATE UNIQUE INDEX idx_product_translations_slug
    ON product_translations (locale, slug)
    WHERE slug IS NOT NULL;
-- Rationale: Locale-specific slug routing. Unique per locale.
```

---

## Table: `variant_translations`

```sql
-- ============================================================
-- TABLE: variant_translations
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Per-(variant, locale) translations of variant display
--   names (translated option value combinations). Same
--   is_auto_translated pattern as product_translations.
-- ============================================================

CREATE TABLE variant_translations (
    variant_id         UUID NOT NULL
                       REFERENCES variants (variant_id)
                       ON DELETE CASCADE,

    locale             VARCHAR(8) NOT NULL,

    title              TEXT NOT NULL,
    -- Translated variant display name.
    -- Example: 'Rot / Groß / Baumwolle' (German for Red/Large/Cotton).

    is_auto_translated BOOLEAN NOT NULL DEFAULT TRUE,
    translated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (variant_id, locale),

    CONSTRAINT variant_translations_locale_not_english CHECK (locale != 'en')
);

COMMENT ON TABLE variant_translations IS
    'Per-(variant, locale) translated display names. '
    'Same is_auto_translated pattern as product_translations.';

CREATE INDEX idx_variant_translations_locale
    ON variant_translations (locale);
-- Rationale: Storefront loads all variant translations for a product
-- in the current locale via a single join query on variants.
```

---

## Table: `collections`

```sql
-- ============================================================
-- TABLE: collections
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Product groupings for storefront navigation, B2B price
--   list scoping, dynamic pricing rules, and Google Shopping feed
--   categorisation. Flat structure — no parent/child hierarchy.
--
-- BUSINESS RULES:
--   1. A product can belong to multiple collections.
--   2. sort_type controls product order within the collection.
--   3. collection_type 'automated' is post-MVP.
--   4. is_visible = FALSE for internal collections (pricing rules,
--      B2B) not shown in storefront navigation.
-- ============================================================

CREATE TABLE collections (
    collection_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    title            TEXT NOT NULL,
    description      TEXT,
    slug             VARCHAR(255) NOT NULL,
    image_url        TEXT,
    meta_title       TEXT,
    meta_description TEXT,

    collection_type  VARCHAR(16) NOT NULL DEFAULT 'manual',
    -- 'manual' | 'automated' (post-MVP)

    sort_type        VARCHAR(16) NOT NULL DEFAULT 'manual',
    -- 'manual'|'best_selling'|'price_asc'|'price_desc'|
    -- 'newest'|'alpha_asc'|'alpha_desc'

    is_visible       BOOLEAN NOT NULL DEFAULT TRUE,
    position         INTEGER NOT NULL DEFAULT 0,

    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT collections_slug_unique UNIQUE (slug),
    CONSTRAINT collections_type_check CHECK (
        collection_type IN ('manual', 'automated')
    ),
    CONSTRAINT collections_sort_type_check CHECK (
        sort_type IN (
            'manual', 'best_selling', 'price_asc', 'price_desc',
            'newest', 'alpha_asc', 'alpha_desc'
        )
    )
);

COMMENT ON TABLE collections IS
    'Product groupings. Flat structure. Products via collection_products.';

CREATE UNIQUE INDEX idx_collections_slug
    ON collections (slug);
-- Rationale: Storefront collection page routing resolves by slug.

CREATE INDEX idx_collections_visible_position
    ON collections (is_visible, position)
    WHERE is_visible = TRUE;
-- Rationale: Navigation menu query — visible collections in display order.
```

---

## Table: `collection_translations`

```sql
-- ============================================================
-- TABLE: collection_translations
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Per-(collection, locale) translations.
--   Same pattern as product_translations.
-- ============================================================

CREATE TABLE collection_translations (
    collection_id      UUID NOT NULL
                       REFERENCES collections (collection_id)
                       ON DELETE CASCADE,

    locale             VARCHAR(8) NOT NULL,

    title              TEXT NOT NULL,
    description        TEXT,
    slug               VARCHAR(255),
    meta_title         TEXT,
    meta_description   TEXT,

    is_auto_translated BOOLEAN NOT NULL DEFAULT TRUE,
    translated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_by        UUID,

    PRIMARY KEY (collection_id, locale),

    CONSTRAINT collection_translations_locale_not_english CHECK (locale != 'en')
);

COMMENT ON TABLE collection_translations IS
    'Per-(collection, locale) translations. Same is_auto_translated pattern.';

CREATE INDEX idx_collection_translations_locale
    ON collection_translations (locale, collection_id);
-- Rationale: Collection page translation lookup by (locale, collection_id).

CREATE UNIQUE INDEX idx_collection_translations_slug
    ON collection_translations (locale, slug)
    WHERE slug IS NOT NULL;
-- Rationale: Locale-specific slug routing — unique per locale.
```

---

## Table: `collection_products`

```sql
-- ============================================================
-- TABLE: collection_products
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Many-to-many join between collections and products.
-- ============================================================

CREATE TABLE collection_products (
    collection_id    UUID NOT NULL
                     REFERENCES collections (collection_id)
                     ON DELETE CASCADE,

    product_id       UUID NOT NULL
                     REFERENCES products (product_id)
                     ON DELETE CASCADE,

    sort_order       INTEGER NOT NULL DEFAULT 0,
    -- Manual position within collection. Meaningful only when
    -- parent collection.sort_type = 'manual'.

    added_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (collection_id, product_id)
);

COMMENT ON TABLE collection_products IS
    'Many-to-many: collections ↔ products. '
    'sort_order used when collection.sort_type = ''manual''.';

CREATE INDEX idx_collection_products_product
    ON collection_products (product_id);
-- Rationale: "Which collections does this product belong to?"
-- Product edit screen and pricing rule scoping.

CREATE INDEX idx_collection_products_collection_sort
    ON collection_products (collection_id, sort_order);
-- Rationale: Collection product listing ordered by sort_order.
```

---

## Table: `product_images`

```sql
-- ============================================================
-- TABLE: product_images
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Product and variant image metadata. Images stored in
--   Cloud Storage, served via Cloud CDN.
--
-- BUSINESS RULES:
--   1. variant_id NULL = product-level image (all variants).
--      Non-null = variant-specific image.
--   2. SET NULL on variant delete — image becomes product-level.
--   3. is_primary = main listing image per product.
-- ============================================================

CREATE TABLE product_images (
    image_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    product_id       UUID NOT NULL
                     REFERENCES products (product_id)
                     ON DELETE CASCADE,

    variant_id       UUID
                     REFERENCES variants (variant_id)
                     ON DELETE SET NULL,

    storage_path     TEXT NOT NULL,
    -- gs://kloudshop-{tenant_id}/products/{product_id}/{uuid}.{ext}

    cdn_url          TEXT NOT NULL,
    -- Pre-computed CDN URL. Used directly in storefront img src.

    alt_text         TEXT,
    -- NULL triggers admin warning badge (SEO impact).

    position         INTEGER NOT NULL DEFAULT 0,
    is_primary       BOOLEAN NOT NULL DEFAULT FALSE,
    width_px         INTEGER,
    height_px        INTEGER,
    file_size_bytes  BIGINT,

    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE product_images IS
    'Product and variant image metadata. Cloud Storage + Cloud CDN. '
    'variant_id NULL = product-level image.';

CREATE INDEX idx_product_images_product
    ON product_images (product_id, position);
-- Rationale: PDP loads all images for a product in display order.

CREATE INDEX idx_product_images_variant
    ON product_images (variant_id, position)
    WHERE variant_id IS NOT NULL;
-- Rationale: Variant-specific images on variant selection.

CREATE INDEX idx_product_images_primary
    ON product_images (product_id, is_primary)
    WHERE is_primary = TRUE;
-- Rationale: Collection grids need only the primary image. Very fast.
```

---

## Table: `product_suppliers`

```sql
-- ============================================================
-- TABLE: product_suppliers
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Many-to-many: variants ↔ suppliers with preference
--   ranking, cost, and lead time data (DMF-07).
--
-- BUSINESS RULES:
--   1. One row per (variant_id, supplier_id).
--   2. preference_rank scoped per variant. Rank 1 = most preferred.
--   3. Exactly one rank-1 per variant enforced at APPLICATION LAYER
--      (not DB) to allow atomic rank swaps without transient
--      constraint violations. Use SELECT FOR UPDATE in transaction.
--   4. lead_time_override_days overrides supplier global default.
--   5. Supplier deletion BLOCKED via RESTRICT. Archive instead.
-- ============================================================

CREATE TABLE product_suppliers (
    variant_id              UUID NOT NULL
                            REFERENCES variants (variant_id)
                            ON DELETE CASCADE,

    supplier_id             UUID NOT NULL
                            REFERENCES suppliers (supplier_id)
                            ON DELETE RESTRICT,

    supplier_sku            TEXT,
    unit_cost               DECIMAL(12, 4),
    cost_currency           CHAR(3) NOT NULL DEFAULT 'USD',
    moq                     INTEGER,
    lead_time_override_days INTEGER,
    preference_rank         INTEGER NOT NULL,
    last_ordered_at         TIMESTAMPTZ,
    notes                   TEXT,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (variant_id, supplier_id),

    CONSTRAINT product_suppliers_preference_rank_positive CHECK (preference_rank >= 1),
    CONSTRAINT product_suppliers_unit_cost_non_negative CHECK (unit_cost IS NULL OR unit_cost >= 0),
    CONSTRAINT product_suppliers_moq_positive CHECK (moq IS NULL OR moq >= 1)
);

COMMENT ON TABLE product_suppliers IS
    'Multi-supplier per variant with preference ranking (DMF-07). '
    'Rank-1 enforced at application layer for atomic swaps. RESTRICT on delete.';

CREATE INDEX idx_product_suppliers_variant_rank
    ON product_suppliers (variant_id, preference_rank);
-- Rationale: Replenishment engine fetches suppliers in preference order.

CREATE INDEX idx_product_suppliers_supplier
    ON product_suppliers (supplier_id, variant_id);
-- Rationale: Supplier detail lists all assigned variants.

CREATE INDEX idx_product_suppliers_rank_1
    ON product_suppliers (variant_id)
    WHERE preference_rank = 1;
-- Rationale: Fast rank-1 lookup for PO draft generation. O(1).
```

---

## Table: `product_reviews`

```sql
-- ============================================================
-- TABLE: product_reviews
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Consumer reviews per variant. Only registered
--   consumers (DEC-20). is_informed_review is stored, not computed.
--
-- BUSINESS RULES:
--   1. consumer_id NOT NULL — only registered consumers.
--   2. One review per (consumer_id, variant_id).
--   3. is_informed_review set at submission. Retroactively updated
--      by Cloud Tasks on qualifying purchase, if
--      seo_settings.auto_update_informed_reviews = TRUE.
--   4. moderation_status controls storefront visibility.
--   5. helpful_count/not_helpful_count denormalised from review_votes.
-- ============================================================

CREATE TABLE product_reviews (
    review_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    variant_id       UUID NOT NULL
                     REFERENCES variants (variant_id)
                     ON DELETE CASCADE,

    consumer_id      UUID NOT NULL,
    -- FK to consumers (06j). Plain UUID — FK added post-provisioning.

    rating           SMALLINT NOT NULL,
    title            TEXT,
    body             TEXT,

    is_informed_review BOOLEAN NOT NULL DEFAULT FALSE,

    moderation_status VARCHAR(16) NOT NULL DEFAULT 'pending',
    moderated_by      UUID,
    moderated_at      TIMESTAMPTZ,

    helpful_count     INTEGER NOT NULL DEFAULT 0,
    not_helpful_count INTEGER NOT NULL DEFAULT 0,

    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT product_reviews_one_per_consumer_variant UNIQUE (consumer_id, variant_id),
    CONSTRAINT product_reviews_rating_range CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT product_reviews_moderation_status_check CHECK (
        moderation_status IN ('pending', 'approved', 'rejected')
    )
);

COMMENT ON TABLE product_reviews IS
    'Consumer reviews per variant. Registered consumers only. '
    'is_informed_review stored boolean — retroactively updated on qualifying purchase.';

CREATE INDEX idx_product_reviews_variant_approved
    ON product_reviews (variant_id, rating DESC, created_at DESC)
    WHERE moderation_status = 'approved';
-- Rationale: PDP loads approved reviews sorted by rating then recency.

CREATE INDEX idx_product_reviews_consumer
    ON product_reviews (consumer_id);
-- Rationale: Consumer "my reviews" + informed review update query.

CREATE INDEX idx_product_reviews_informed_pending_update
    ON product_reviews (variant_id, is_informed_review)
    WHERE is_informed_review = FALSE AND moderation_status = 'approved';
-- Rationale: Retroactive update job targets approved non-informed reviews.

CREATE INDEX idx_product_reviews_pending_moderation
    ON product_reviews (created_at DESC)
    WHERE moderation_status = 'pending';
-- Rationale: Admin moderation queue — oldest pending first.
```

---

## Table: `review_votes`

```sql
-- ============================================================
-- TABLE: review_votes
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Consumer helpfulness votes on reviews.
--   One row per (consumer, review). Vote changes are UPDATEs.
-- ============================================================

CREATE TABLE review_votes (
    consumer_id  UUID NOT NULL,
    review_id    UUID NOT NULL
                 REFERENCES product_reviews (review_id)
                 ON DELETE CASCADE,
    vote_type    VARCHAR(16) NOT NULL,  -- 'helpful' | 'not_helpful'
    voted_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (consumer_id, review_id),

    CONSTRAINT review_votes_type_check CHECK (
        vote_type IN ('helpful', 'not_helpful')
    )
);

COMMENT ON TABLE review_votes IS
    'Helpfulness votes on reviews. One row per (consumer, review). '
    'Flips are UPDATEs. Counters on product_reviews updated by application.';

CREATE INDEX idx_review_votes_review
    ON review_votes (review_id, vote_type);
-- Rationale: Counter recalculation and consistency checks per review.
```

---

## Table: `seo_settings`

```sql
-- ============================================================
-- TABLE: seo_settings
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per tenant — global SEO configuration.
--   Created by base Alembic migration. Never more than one row.
--   Use upsert with fixed seed UUID, never plain INSERT.
-- ============================================================

CREATE TABLE seo_settings (
    seo_settings_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    auto_update_informed_reviews BOOLEAN NOT NULL DEFAULT TRUE,
    -- TRUE = Cloud Tasks retroactively updates is_informed_review
    -- on product_reviews when a qualifying purchase is confirmed.

    auto_approve_reviews         BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = reviews skip moderation and go directly to 'approved'.

    google_merchant_center_id    TEXT,
    google_merchant_connected_at TIMESTAMPTZ,

    robots_txt_override          TEXT,
    -- NULL = use KloudShop default robots.txt.

    sitemap_last_generated_at    TIMESTAMPTZ,

    default_product_condition    VARCHAR(16) NOT NULL DEFAULT 'new',
    -- Google Shopping feed 'condition' default. 'new'|'used'|'refurbished'.

    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT seo_settings_product_condition_check CHECK (
        default_product_condition IN ('new', 'used', 'refurbished')
    )
);

COMMENT ON TABLE seo_settings IS
    'One row per tenant — global SEO config. Use upsert, never plain INSERT. '
    'auto_update_informed_reviews governs retroactive review updates (DMF resolution).';
-- Single-row table — no additional indexes needed.
```

---

## Table: `ai_copywriter_log`

```sql
-- ============================================================
-- TABLE: ai_copywriter_log
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Append-only log of every AI Copywriter generation call.
--   No UPDATE, no DELETE ever. Feeds BigQuery prompt quality analytics.
--
-- BUSINESS RULES:
--   1. Append-only. No UPDATE. No DELETE. Ever.
--   2. entity_id: product_id or blog_post_id. Plain UUID, no FK.
--   3. variant_accepted 1/2/3 = variant chosen. NULL = all discarded.
--   4. was_edited NULL when variant_accepted IS NULL (nothing accepted).
--   5. prompt_hash: SHA-256 of the server-side assembled prompt.
--      Preserves auditability without storing PII or Brand Voice
--      profile content in plain text.
-- ============================================================

CREATE TABLE ai_copywriter_log (
    log_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    content_type     VARCHAR(32) NOT NULL,
    -- 'product_title'|'product_description'|'blog_title'|'blog_body'

    entity_id        UUID NOT NULL,
    -- product_id or blog_post_id. No FK — avoids failures on archive.

    variant_accepted SMALLINT,        -- 1, 2, or 3. NULL = all discarded.
    was_edited       BOOLEAN,         -- NULL when variant_accepted IS NULL.

    prompt_hash      CHAR(64) NOT NULL,
    -- SHA-256 hex hash of the assembled server-side prompt.

    gemini_model     TEXT NOT NULL,   -- e.g. 'gemini-1.5-pro-001'
    tokens_input     INTEGER,
    tokens_output    INTEGER,

    generated_by     UUID NOT NULL,   -- staff_user_id
    generated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    latency_ms       INTEGER,

    CONSTRAINT ai_copywriter_log_content_type_check CHECK (
        content_type IN (
            'product_title', 'product_description',
            'blog_title', 'blog_body'
        )
    ),
    CONSTRAINT ai_copywriter_log_variant_accepted_check CHECK (
        variant_accepted IN (1, 2, 3) OR variant_accepted IS NULL
    ),
    CONSTRAINT ai_copywriter_log_was_edited_consistency CHECK (
        (variant_accepted IS NULL AND was_edited IS NULL)
        OR (variant_accepted IS NOT NULL AND was_edited IS NOT NULL)
    )
);

COMMENT ON TABLE ai_copywriter_log IS
    'Append-only AI Copywriter audit log. No UPDATE, no DELETE ever. '
    'prompt_hash = SHA-256 of assembled prompt — no PII in plain text.';

CREATE INDEX idx_ai_copywriter_log_entity
    ON ai_copywriter_log (entity_id, content_type, generated_at DESC);
-- Rationale: Product/blog editor fetches generation history per entity.

CREATE INDEX idx_ai_copywriter_log_content_type
    ON ai_copywriter_log (content_type, generated_at DESC);
-- Rationale: Platform analytics on acceptance rates per content_type.

CREATE INDEX idx_ai_copywriter_log_discard_rate
    ON ai_copywriter_log (content_type, generated_at DESC)
    WHERE variant_accepted IS NULL;
-- Rationale: Prompt quality monitoring — high discard rate signals issues.

CREATE INDEX idx_ai_copywriter_log_prompt_hash
    ON ai_copywriter_log (prompt_hash);
-- Rationale: Correlate acceptance rate changes with prompt version updates.
```

---

## Gap Additions Summary

| Gap | Fields Added | Table | Notes |
|-----|-------------|-------|-------|
| GAP-01 | `digital_asset_url`, `download_limit`, `download_expiry_hours` | `variants` | Digital product file delivery — Arts, Health (PDF guides) |
| GAP-02 | `is_perishable`, `best_before_days`, `lot_number` | `variants` | Recall traceability + expiry — Food & Drink, Health |
| GAP-03 | `compliance_metadata JSONB DEFAULT '{}'` | `products` | Schema-free regulatory IDs — FDA NDC, CE, ISBN, allergens |
| GAP-04 | `minimum_age_years`, `age_verification_required` | `products` | Checkout age-gate — alcohol, adult content, supplements |
| GAP-05 | `requires_prescription`, `prescription_document_required` | `products` | Prescription checkout gating — pharmacy, veterinary, medical |
| GAP-06 | `pricing_model`, `pwyw_minimum_price`, `pwyw_suggested_price` | `variants` | PWYW + donation pricing — People & Society, non-profits |
| GAP-08 | `pet_species TEXT[] DEFAULT '{}'` | `variants` | Species filter + Google Shopping pet_type — Pets & Animals |
| GAP-09a | `compliance_document_url` | `products` | Regulatory document attachment — Health, Food, Pets, Arts |

**Deferred to later artifacts:**
- **GAP-07** (event ticketing `events` + `event_tickets` tables) → `06m-tenant-feature-gated-schema.md`
- **GAP-09b** (`brand_profiles.is_age_gated`) → `06g-tenant-storefront-schema.md`

---

## Updated Schema Inventory Entry

After generating this artifact, update `06-schema-inventory.md`:

```
| `06b-tenant-catalog-schema.md` | ✅ Generated (v2) | 13 | Tenant product catalogue — gap-hardened (GAP-01 through GAP-09a) |
```
