# 06a2 — Platform Catalogue Schema
# KloudShop Stage 6 — Data Model

> **Artifact:** `06a2-platform-catalogue-schema.md`
> **Schema:** `kloudshop_platform`
> **Persona:** Principal Data Engineer
> **Reads from:** `01-product-brief.md`, `01b-tech-stack.md`, `02-architecture.md`,
>   `03-user-journeys.md`, `04-feature-stories.md`, `04b-mvp-scope.md`,
>   `00-carry-forward-flags.md` (DMF-01 through DMF-10)
> **Depends on:** `06a1-platform-core-schema.md` (tenants, platform_staff FKs)
> **Tables:** 11 (themes, feature_registry, feature_config_schema,
>   feature_dependencies, feature_migrations, carriers, carrier_service_levels,
>   carrier_regions, carrier_credential_schemas, carrier_webhook_configs,
>   carrier_rate_zones)
> **Status:** ✅ Generated

---

## Overview

This artifact covers the **platform catalogue tables** of the `kloudshop_platform`
schema. These tables define the two major catalogues that KloudShop maintains
centrally on behalf of all merchants:

1. **Theme Catalogue** — the global library of storefront themes. Adding a new
   theme requires one INSERT and a Cloud Storage upload. No code deployment.
   No per-tenant schema change.

2. **Feature Catalogue** — the registry of all Feature Catalogue items including
   their typed configuration parameter schemas, directed dependency graph, and
   Alembic migration mappings. This is the control plane for the entire
   schema-driven feature activation system.

3. **Carrier Catalogue** — the platform-maintained library of shipping carriers,
   their service levels, regional availability, credential schemas, webhook
   configurations, and rate zone definitions. Merchants connect to carriers
   from this catalogue — KloudShop never stores raw carrier credentials here
   (those live encrypted in GCP Secret Manager, referenced from the tenant
   schema).

**Design principle for all catalogue tables:** Adding a new entry (theme, feature,
carrier) must require only SQL INSERTs into these tables — never a code change,
never a CI/CD pipeline run, never a Flutter build. The application code reads
catalogue definitions at runtime. This is the architectural guarantee that
KloudShop can expand its theme library, feature set, and carrier integrations
at the pace of business, not the pace of engineering deployments.

**AI agent note:** All catalogue tables use `VARCHAR` or `TEXT` primary keys
where the identifier is a meaningful human-readable slug (e.g. `theme_id`,
`feature_id`, `carrier_id`). This is intentional — it makes debugging,
logging, and analytics dramatically more readable than UUID-only keys for
catalogue entities that have stable, well-known identities.

---

## Table: `themes`

```sql
-- ============================================================
-- TABLE: themes
-- SCHEMA: kloudshop_platform
-- PURPOSE: Global theme catalogue. One row per theme. Adding a
--   new theme to the KloudShop library requires:
--     1. Upload theme package to gs://kloudshop-themes/{theme_id}/
--     2. INSERT one row here with status = 'draft'
--     3. QA and set status = 'published'
--   Zero code changes. Zero CI/CD pipeline. Zero deployment.
--   The Flutter storefront renderer reads theme.json from Cloud
--   Storage at runtime — it never has themes baked in.
--
-- BUSINESS RULES:
--   1. theme_id is the canonical identifier. It must match the
--      Cloud Storage folder name: gs://kloudshop-themes/{theme_id}/
--   2. config_url points to the theme.json file. The Flutter renderer
--      fetches this URL at storefront render time (Redis cached, TTL 1hr).
--   3. status lifecycle: 'draft' → 'published' → 'deprecated'
--      Deprecated themes remain renderable for tenants already using
--      them — they are only hidden from new theme selection.
--   4. sector_category is the primary browseable filter (e.g. 'Apparel').
--      sector_tags is a secondary freeform tag array for additional
--      filtering (e.g. ['dark', 'B2B', 'manufacturing']).
--   5. schema_version tracks the theme.json schema version (e.g. '1.0',
--      '1.1'). The Flutter renderer supports all versions simultaneously
--      via backward-compatible schema handling. No merchant storefront
--      ever breaks when the schema version bumps.
--   6. likes_count is a denormalised count of merchant ♥ saves.
--      Updated on INSERT/DELETE of theme_favourites rows in tenant schemas.
--   7. install_count is a denormalised count of tenants currently using
--      this theme as their active theme. Updated on theme application.
-- ============================================================

CREATE TABLE kloudshop_platform.themes (
    theme_id         VARCHAR(64) PRIMARY KEY,
    -- Canonical identifier. Must be URL-safe, lowercase, hyphen-separated.
    -- Examples: 'industrial-dark', 'minimal-fashion', 'food-beverage-warm'.
    -- Must exactly match the Cloud Storage folder name.

    display_name     TEXT NOT NULL,
    -- Human-readable theme name shown in the theme library.
    -- Example: 'Industrial Dark', 'Minimal Fashion'.

    description      TEXT,
    -- Short description of the theme's visual style and best-fit sectors.
    -- Shown on the theme card in the merchant theme library.

    sector_category  VARCHAR(64) NOT NULL,
    -- Primary browseable category for the theme library filter.
    -- Valid values (enforced by CHECK constraint):
    --   'Apparel', 'Restaurants', 'Electronics', 'Fashion', 'Beauty',
    --   'Industrial B2B', 'Food & Beverage', 'Health & Beauty',
    --   'Automotive', 'Home Décor', 'Digital Products',
    --   'Sporting Goods', 'Other'

    sector_tags      TEXT[] NOT NULL DEFAULT '{}',
    -- Secondary freeform tags for additional filtering and discovery.
    -- Examples: '{dark, B2B, manufacturing}', '{minimal, luxury, fashion}'.

    preview_url      TEXT NOT NULL,
    -- CDN URL of the theme preview screenshot (rendered with sample data).
    -- Served from gs://kloudshop-themes/{theme_id}/preview.jpg via Cloud CDN.

    config_url       TEXT NOT NULL,
    -- Cloud Storage URL of the theme.json file.
    -- Pattern: gs://kloudshop-themes/{theme_id}/theme.json

    asset_base_url   TEXT NOT NULL,
    -- Base Cloud Storage URL for all theme assets (fonts, icons, images).
    -- Pattern: gs://kloudshop-themes/{theme_id}/assets/

    schema_version   VARCHAR(8) NOT NULL DEFAULT '1.0',
    -- The theme.json schema version this theme was authored against.
    -- The Flutter renderer handles all versions simultaneously.
    -- Bump only when backward-incompatible changes are made to the schema.

    status           VARCHAR(16) NOT NULL DEFAULT 'draft',
    -- Lifecycle status:
    --   'draft'      — internal only, not visible to merchants
    --   'published'  — live in merchant theme library
    --   'deprecated' — hidden from new selection; still rendered for
    --                  tenants already using it

    likes_count      INTEGER NOT NULL DEFAULT 0,
    -- Denormalised count of merchant ♥ saves (theme_favourites).
    -- Updated by application code on save/unsave. Never computed on read.

    install_count    INTEGER NOT NULL DEFAULT 0,
    -- Denormalised count of tenants with this as their active theme.
    -- Updated when a merchant applies or switches away from this theme.

    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT themes_sector_category_check CHECK (
        sector_category IN (
            'Apparel', 'Restaurants', 'Electronics', 'Fashion', 'Beauty',
            'Industrial B2B', 'Food & Beverage', 'Health & Beauty',
            'Automotive', 'Home Décor', 'Digital Products',
            'Sporting Goods', 'Other'
        )
    ),
    CONSTRAINT themes_status_check CHECK (
        status IN ('draft', 'published', 'deprecated')
    ),
    CONSTRAINT themes_schema_version_check CHECK (
        schema_version ~ '^\d+\.\d+$'
        -- Enforces format like '1.0', '1.1', '2.0'. Regex match.
    )
);

COMMENT ON TABLE kloudshop_platform.themes IS
    'Global theme catalogue. Adding a theme = one INSERT + Cloud Storage upload. '
    'No code deploy. No CI/CD. Flutter renderer reads theme.json at runtime. '
    'Deprecated themes remain renderable for existing users — never hard-deleted.';

CREATE INDEX idx_themes_published_by_category
    ON kloudshop_platform.themes (sector_category, likes_count DESC)
    WHERE status = 'published';
-- Rationale: Theme library default view — published themes filtered by
-- sector_category, sorted by popularity (likes_count). Partial index
-- on published only avoids exposing draft/deprecated themes.

CREATE INDEX idx_themes_published_by_installs
    ON kloudshop_platform.themes (install_count DESC)
    WHERE status = 'published';
-- Rationale: "Most popular" sort order in the theme library.

CREATE INDEX idx_themes_sector_tags
    ON kloudshop_platform.themes USING GIN (sector_tags)
    WHERE status = 'published';
-- Rationale: Secondary tag-based filtering in theme library
-- (e.g. filter by 'dark' or 'B2B'). GIN index is required
-- for efficient ANY() and @> queries on TEXT[] arrays.

CREATE INDEX idx_themes_schema_version
    ON kloudshop_platform.themes (schema_version);
-- Rationale: Platform Admin queries themes by schema_version during
-- renderer compatibility checks and deprecation planning.
```

---

## Table: `feature_registry`

```sql
-- ============================================================
-- TABLE: feature_registry
-- SCHEMA: kloudshop_platform
-- PURPOSE: Master list of all Feature Catalogue items. Every
--   feature that can be toggled by a merchant must have a row
--   here before it appears in any merchant's Feature Catalogue.
--
-- BUSINESS RULES:
--   1. feature_id is the canonical identifier used across the
--      entire system: feature_config_schema, feature_dependencies,
--      feature_migrations, tenant_feature_state, tenant_feature_config,
--      and Firebase Remote Config flag names.
--   2. tier_scope controls which merchants see this feature:
--      'DTC'    — visible to DTC and Hybrid merchants
--      'B2B'    — visible to B2B and Hybrid merchants
--      'Hybrid' — visible to Hybrid merchants only
--      'All'    — visible to all tiers
--   3. has_config = TRUE means this feature requires the merchant
--      to complete a setup wizard (Phase 2) after activation.
--      The wizard is driven entirely by feature_config_schema rows
--      for this feature_id. No Flutter code change needed.
--   4. has_schema_migration = TRUE means this feature requires
--      Alembic to run DDL migrations in the tenant schema at
--      activation time (Phase 1). The migrations are defined in
--      feature_migrations. Features with has_schema_migration = FALSE
--      become active immediately on toggle with no database work.
--   5. status lifecycle: 'beta' → 'stable' → 'deprecated'
--      Deprecated features remain active for tenants who have them
--      enabled. They are hidden from new activation.
--   6. display_order controls the sort order within the Feature
--      Catalogue grid in the merchant admin UI.
--   7. replaces_app_label is the marketing copy shown on the
--      feature card: "Replaces Klaviyo — $45/mo saved".
-- ============================================================

CREATE TABLE kloudshop_platform.feature_registry (
    feature_id           VARCHAR(64) PRIMARY KEY,
    -- Canonical identifier. Lowercase, underscores. Stable — never rename.
    -- Examples: 'loyalty_programme', 'abandoned_cart_recovery',
    --           'subscription_orders', 'gift_cards', 'bundle_builder'.
    -- Used as Firebase Remote Config flag name:
    --   feature_{feature_id}_enabled (e.g. feature_loyalty_programme_enabled)

    display_name         TEXT NOT NULL,
    -- Human-readable feature name shown in Feature Catalogue.
    -- Example: 'Customer Loyalty Programme'.

    short_description    TEXT NOT NULL,
    -- One-line description shown on the feature card.
    -- Example: 'Reward repeat buyers with points, tiers, and discounts.'

    replaces_app_label   TEXT,
    -- Optional marketing copy. Shown on feature card as:
    -- "Replaces {replaces_app_label}".
    -- Example: 'Klaviyo — $45/mo saved', 'Yotpo Loyalty — $79/mo saved'.
    -- NULL for features that don't directly replace a common app.

    tier_scope           VARCHAR(8) NOT NULL DEFAULT 'All',
    -- Which merchant tiers can see and activate this feature.
    -- Values: 'DTC' | 'B2B' | 'Hybrid' | 'All'
    -- 'All' = visible to every tier (DTC, B2B, Hybrid).

    has_config           BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = activation triggers Phase 2 setup wizard.
    -- FALSE = feature is operational immediately on activation
    --         with no configuration required.

    has_schema_migration BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = activation triggers Alembic migration runner (Phase 1).
    -- FALSE = no DDL changes needed; feature uses only base tenant schema.

    status               VARCHAR(16) NOT NULL DEFAULT 'beta',
    -- Lifecycle status:
    --   'beta'       — available to merchants, labelled as beta
    --   'stable'     — fully supported, no beta label
    --   'deprecated' — hidden from new activation; retained for existing users

    display_order        INTEGER NOT NULL DEFAULT 100,
    -- Sort order within the Feature Catalogue grid. Lower = shown first.
    -- KloudShop engineers set this manually when publishing a feature.

    icon_name            VARCHAR(64),
    -- Lucide icon name to display on the feature card.
    -- Example: 'award' (loyalty), 'shopping-cart' (abandoned cart).
    -- NULL = use a default generic icon.

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT feature_registry_tier_scope_check CHECK (
        tier_scope IN ('DTC', 'B2B', 'Hybrid', 'All')
    ),
    CONSTRAINT feature_registry_status_check CHECK (
        status IN ('beta', 'stable', 'deprecated')
    )
);

COMMENT ON TABLE kloudshop_platform.feature_registry IS
    'Master Feature Catalogue registry. One row per feature. '
    'Adding a feature = INSERT here + rows in feature_config_schema '
    'and/or feature_migrations. No Flutter code change required '
    'if feature uses existing data_types in the config schema.';

CREATE INDEX idx_feature_registry_tier_scope
    ON kloudshop_platform.feature_registry (tier_scope, display_order)
    WHERE status != 'deprecated';
-- Rationale: Feature Catalogue screen fetches features visible to
-- the merchant's tier, ordered by display_order. Partial index
-- excludes deprecated features from active screens.

CREATE INDEX idx_feature_registry_status
    ON kloudshop_platform.feature_registry (status);
-- Rationale: Platform Admin queries by status for catalogue management.

-- Seed data — core platform Feature Catalogue items at MVP launch
INSERT INTO kloudshop_platform.feature_registry
    (feature_id, display_name, short_description, replaces_app_label,
     tier_scope, has_config, has_schema_migration, status, display_order, icon_name)
VALUES
    ('loyalty_programme',
     'Customer Loyalty Programme',
     'Reward repeat buyers with points, tiers, and exclusive perks.',
     'Yotpo Loyalty — $79/mo saved',
     'All', TRUE, TRUE, 'stable', 10, 'award'),

    ('abandoned_cart_recovery',
     'Abandoned Cart Recovery',
     'Automatically recover lost sales with timed reminder emails.',
     'Klaviyo — $45/mo saved',
     'All', TRUE, TRUE, 'stable', 20, 'shopping-cart'),

    ('subscription_orders',
     'Subscription & Recurring Orders',
     'Let customers subscribe to products for automatic repeat delivery.',
     'ReCharge — $99/mo saved',
     'All', TRUE, TRUE, 'stable', 30, 'repeat'),

    ('gift_cards',
     'Gift Cards & Store Credit',
     'Sell digital gift cards and issue store credit to customers.',
     'Gift Up! — $19/mo saved',
     'All', TRUE, TRUE, 'stable', 40, 'gift'),

    ('bundle_builder',
     'Bundle Builder',
     'Create product bundles with custom pricing and discount rules.',
     'Bold Bundles — $24/mo saved',
     'All', TRUE, TRUE, 'beta', 50, 'package'),

    ('affiliate_referral',
     'Affiliate & Referral Tracking',
     'Run an affiliate programme with commission tracking and payouts.',
     'Refersion — $89/mo saved',
     'All', TRUE, TRUE, 'beta', 60, 'share-2');
```

---

## Table: `feature_config_schema`

```sql
-- ============================================================
-- TABLE: feature_config_schema
-- SCHEMA: kloudshop_platform
-- PURPOSE: Typed parameter definitions for each Feature Catalogue
--   item. This table drives the generic schema-driven setup wizard
--   in the Flutter admin — no Flutter code changes are needed when
--   a new feature with new parameters is added. The wizard renderer
--   reads this table and renders the correct input widget per
--   data_type automatically.
--
-- BUSINESS RULES:
--   1. One row per config parameter per feature.
--      A feature with no configurable parameters has zero rows here
--      (has_config = FALSE in feature_registry).
--   2. data_type drives the Flutter widget rendered in the wizard:
--      'string'     → TextInputField (single-line) or DropdownSelector
--                     if allowed_values is set in validation_rules
--      'text'       → TextAreaField (multi-line)
--      'integer'    → NumberInputField
--      'float'      → DecimalInputField
--      'boolean'    → SwitchToggle
--      'date'       → DatePicker
--      'time'       → TimePicker (HH:MM)
--      'datetime'   → DateTimePicker
--      'json_array' → MultiSelectChips (if allowed_values set)
--                     or DynamicListInput (free-form)
--      'json_object'→ StructuredObjectForm
--   3. validation_rules is a JSONB field with type-specific
--      constraints enforced at the application layer (not DB level):
--      integer: {"min": 1, "max": 1000}
--      float:   {"min": 0.01, "max": 1.0}
--      string:  {"max_length": 255, "allowed_values": ["a","b"]}
--      time:    {"format": "HH:MM"}
--      json_array: {"item_type": "string", "allowed_values": ["mon","tue"]}
--   4. default_value is stored as TEXT and cast to the correct type
--      on read using data_type. The application layer performs the cast.
--   5. wizard_group groups parameters into named wizard steps.
--      All parameters with the same wizard_group appear on the same
--      wizard step/page. NULL = ungrouped (shown on step 1).
--   6. display_order controls the order of parameters within a
--      wizard_group. Lower = shown first within the group.
-- ============================================================

CREATE TABLE kloudshop_platform.feature_config_schema (
    config_key       VARCHAR(128) NOT NULL,
    -- Parameter identifier. Unique within a feature. Used as the key
    -- in tenant_feature_config rows.
    -- Examples: 'points_per_dollar', 'first_reminder_delay_hours',
    --           'allowed_delivery_days', 'subscriber_discount_pct'.

    feature_id       VARCHAR(64) NOT NULL
                     REFERENCES kloudshop_platform.feature_registry (feature_id)
                     ON DELETE CASCADE,
    -- CASCADE: if a feature is removed from the registry (very rare),
    -- its config schema is also removed. Application code must handle
    -- this gracefully — existing tenant_feature_config rows for this
    -- feature_id become orphaned and must be cleaned up separately.

    display_label    TEXT NOT NULL,
    -- Human-readable label shown above the input in the setup wizard.
    -- Example: 'Points earned per $1 spent'.

    description      TEXT,
    -- Optional helper text shown below the input in the wizard.
    -- Explains what this parameter controls and any important caveats.
    -- Example: 'Changing this affects all future purchases. Existing
    --           points already earned are not affected.'

    data_type        VARCHAR(16) NOT NULL,
    -- The type of this parameter. Drives Flutter widget selection.
    -- Valid values enforced by CHECK constraint below.

    default_value    TEXT,
    -- The default value for this parameter, stored as TEXT.
    -- Cast to data_type on read. NULL = no default; parameter starts empty.
    -- Pre-populated in the wizard so merchants can click through in 30 seconds.

    is_required      BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = this parameter must be set before the feature is marked
    -- 'Active' (not 'Active — setup needed'). Blocks wizard step advance.

    validation_rules JSONB NOT NULL DEFAULT '{}',
    -- Type-specific validation constraints. Enforced at application layer.
    -- See business rules above for examples per data_type.

    display_order    INTEGER NOT NULL DEFAULT 0,
    -- Sort order within the wizard_group. Lower = shown first.

    wizard_group     VARCHAR(64),
    -- Groups parameters into wizard steps. All parameters with the same
    -- wizard_group appear on the same step. NULL = step 1 (ungrouped).
    -- Example groups for Loyalty Programme:
    --   'Points Configuration', 'Reward Tiers', 'Redemption Rules'

    PRIMARY KEY (config_key, feature_id),

    CONSTRAINT feature_config_schema_data_type_check CHECK (
        data_type IN (
            'string', 'text', 'integer', 'float', 'boolean',
            'date', 'time', 'datetime', 'json_array', 'json_object'
        )
    )
);

COMMENT ON TABLE kloudshop_platform.feature_config_schema IS
    'Typed parameter definitions per Feature Catalogue item. Drives the '
    'generic Flutter setup wizard — no code change needed for new features. '
    'One row per parameter per feature. data_type drives widget selection.';

CREATE INDEX idx_feature_config_schema_feature_id
    ON kloudshop_platform.feature_config_schema (feature_id, display_order);
-- Rationale: Setup wizard fetches all parameters for a feature ordered
-- by display_order to render the wizard steps. This is the primary
-- read pattern for this table — called on every wizard load.

CREATE INDEX idx_feature_config_schema_wizard_group
    ON kloudshop_platform.feature_config_schema (feature_id, wizard_group, display_order);
-- Rationale: Wizard step grouping query — fetch all parameters for a
-- specific feature grouped by wizard_group. Composite index matches
-- the exact WHERE + ORDER BY pattern.

-- Seed data — Loyalty Programme parameters
INSERT INTO kloudshop_platform.feature_config_schema
    (config_key, feature_id, display_label, description, data_type,
     default_value, is_required, validation_rules, display_order, wizard_group)
VALUES
    ('points_per_dollar', 'loyalty_programme',
     'Points earned per $1 spent',
     'How many points a customer earns for every $1 they spend.',
     'integer', '10', TRUE,
     '{"min": 1, "max": 10000}', 10, 'Points Configuration'),

    ('welcome_bonus_points', 'loyalty_programme',
     'Welcome bonus points',
     'Points awarded to a customer when they first enrol in the programme.',
     'integer', '100', FALSE,
     '{"min": 0, "max": 100000}', 20, 'Points Configuration'),

    ('points_expiry_days', 'loyalty_programme',
     'Points expiry (days)',
     'Points expire after this many days of inactivity. Set to 0 for no expiry.',
     'integer', '365', FALSE,
     '{"min": 0}', 30, 'Points Configuration'),

    ('min_points_to_redeem', 'loyalty_programme',
     'Minimum points required to redeem',
     'Customers must accumulate at least this many points before they can redeem.',
     'integer', '100', TRUE,
     '{"min": 1}', 10, 'Redemption Rules'),

    ('redemption_rate_points', 'loyalty_programme',
     'Points per $1 discount',
     'How many points equal $1 of discount at redemption.',
     'integer', '100', TRUE,
     '{"min": 1}', 20, 'Redemption Rules'),

    ('first_reminder_delay_hours', 'abandoned_cart_recovery',
     'Send first reminder after (hours)',
     'How many hours after cart abandonment to send the first recovery email.',
     'integer', '4', TRUE,
     '{"min": 1, "max": 72, "allowed_values": [1, 4, 24]}',
     10, 'Email Timing'),

    ('send_second_reminder', 'abandoned_cart_recovery',
     'Send a second reminder email',
     'Enable a follow-up reminder if the customer does not return after the first email.',
     'boolean', 'false', FALSE,
     '{}', 20, 'Email Timing'),

    ('second_reminder_delay_hours', 'abandoned_cart_recovery',
     'Send second reminder after (hours)',
     'Hours after the first reminder to send the second reminder. Only applies if second reminder is enabled.',
     'integer', '48', FALSE,
     '{"min": 1, "max": 168}', 30, 'Email Timing'),

    ('include_discount_code', 'abandoned_cart_recovery',
     'Include a discount code in recovery emails',
     'Attach a one-time discount code to the recovery email to incentivise return.',
     'boolean', 'false', FALSE,
     '{}', 10, 'Incentive'),

    ('recovery_discount_percentage', 'abandoned_cart_recovery',
     'Recovery discount percentage',
     'Percentage discount applied via the one-time code in the recovery email.',
     'float', '10.0', FALSE,
     '{"min": 1.0, "max": 50.0}', 20, 'Incentive'),

    ('subscriber_discount_pct', 'subscription_orders',
     'Subscriber discount (%)',
     'Percentage discount applied automatically at checkout for subscribers.',
     'float', '10.0', TRUE,
     '{"min": 0.0, "max": 50.0}', 10, 'Subscriber Benefits'),

    ('allowed_frequencies', 'subscription_orders',
     'Billing frequencies offered to customers',
     'Select which recurring intervals customers can choose from.',
     'json_array', '["monthly"]', TRUE,
     '{"item_type": "string", "allowed_values": ["weekly","biweekly","monthly","quarterly"]}',
     20, 'Subscriber Benefits');
```

---

## Table: `feature_dependencies`

```sql
-- ============================================================
-- TABLE: feature_dependencies
-- SCHEMA: kloudshop_platform
-- PURPOSE: Directed acyclic graph of feature → upstream feature
--   dependencies. When a merchant activates Feature B that depends
--   on Feature A, the Migration Runner silently applies Feature A's
--   schema migrations first (even if the merchant never explicitly
--   activated Feature A), then applies Feature B's migrations.
--
-- BUSINESS RULES:
--   1. One row per (feature_id → depends_on) edge.
--      A feature with multiple upstream dependencies has multiple rows.
--   2. The Migration Runner resolves the full dependency graph using
--      Kahn's algorithm (topological sort) before queuing migrations.
--   3. Circular dependencies are FORBIDDEN and are detected at CI time
--      by the Alembic migration linter (hard build failure).
--      Application code must also validate on INSERT to this table.
--   4. A dependency being silently applied does NOT activate the
--      upstream feature in the merchant's Feature Catalogue. The
--      merchant only sees the feature they explicitly toggled.
--      Upstream schema is applied transparently as infrastructure.
--   5. Dependencies are immutable once published — removing a
--      dependency after tenants have activated the downstream feature
--      could leave their schemas in an unexpected state.
-- ============================================================

CREATE TABLE kloudshop_platform.feature_dependencies (
    feature_id   VARCHAR(64) NOT NULL
                 REFERENCES kloudshop_platform.feature_registry (feature_id)
                 ON DELETE RESTRICT,
    -- The downstream feature that has the dependency.
    -- RESTRICT: do not allow deleting a feature that other features depend on.

    depends_on   VARCHAR(64) NOT NULL
                 REFERENCES kloudshop_platform.feature_registry (feature_id)
                 ON DELETE RESTRICT,
    -- The upstream feature that must be migrated first.
    -- RESTRICT: do not allow deleting a feature that others depend on.

    PRIMARY KEY (feature_id, depends_on),
    -- Composite PK prevents duplicate dependency edges.

    CONSTRAINT feature_dependencies_no_self_reference CHECK (
        feature_id != depends_on
        -- A feature cannot depend on itself.
    )
);

COMMENT ON TABLE kloudshop_platform.feature_dependencies IS
    'Directed dependency graph for Feature Catalogue items. '
    'Migration Runner resolves via topological sort (Kahn''s algorithm). '
    'Circular dependencies rejected at CI — hard build failure. '
    'Upstream schemas applied silently; upstream features NOT activated.';

CREATE INDEX idx_feature_dependencies_feature_id
    ON kloudshop_platform.feature_dependencies (feature_id);
-- Rationale: Migration Runner queries all dependencies FOR a given
-- feature_id to build the dependency graph. Primary read pattern.

CREATE INDEX idx_feature_dependencies_depends_on
    ON kloudshop_platform.feature_dependencies (depends_on);
-- Rationale: Reverse lookup — "which features depend on THIS feature?"
-- Used in deprecation planning to safely determine blast radius.
```

---

## Table: `feature_migrations`

```sql
-- ============================================================
-- TABLE: feature_migrations
-- SCHEMA: kloudshop_platform
-- PURPOSE: Maps Alembic migration script revision IDs to Feature
--   Catalogue items. Defines the sequence in which migrations must
--   be applied for a given feature. The Migration Runner consults
--   this table to determine which Alembic revisions to apply when
--   a feature is activated, and in what order.
--
-- BUSINESS RULES:
--   1. migration_id is the Alembic revision ID — the exact string
--      that appears in the migration file header:
--      revision = 'abc123def456'
--      It must match a real Alembic migration file in the codebase.
--   2. sequence_order defines the order migrations run within a
--      single feature. If a feature has 3 migration scripts (e.g.
--      create tables, add indexes, add constraints), sequence_order
--      values 1, 2, 3 ensure they run in the correct order.
--   3. is_required = FALSE marks optional schema enhancements that
--      improve performance but are not required for the feature to
--      function (e.g. a secondary GIN index added post-MVP).
--      The Migration Runner applies required migrations first, then
--      optional ones as a separate async job.
--   4. The Migration Runner checks tenant_migration_state (tenant
--      schema) before applying any migration to ensure idempotency.
--      Re-running a migration that has already been applied is
--      safe — Alembic skips it.
--   5. Non-destructive migration policy (enforced by CI linter):
--      Only ADD COLUMN, CREATE TABLE, CREATE INDEX CONCURRENTLY are
--      permitted. DROP TABLE, DROP COLUMN, ALTER COLUMN TYPE, and
--      non-CONCURRENT CREATE INDEX are forbidden and fail the CI build.
-- ============================================================

CREATE TABLE kloudshop_platform.feature_migrations (
    migration_id     VARCHAR(128) PRIMARY KEY,
    -- Alembic revision ID. Must exactly match the revision string in
    -- the corresponding Alembic migration file.
    -- Example: 'a1b2c3d4e5f6'

    feature_id       VARCHAR(64) NOT NULL
                     REFERENCES kloudshop_platform.feature_registry (feature_id)
                     ON DELETE RESTRICT,
    -- The feature this migration belongs to.
    -- RESTRICT: do not allow deleting a feature that has migrations registered.

    sequence_order   INTEGER NOT NULL,
    -- Execution order within this feature's migration set.
    -- Lower values run first. Start at 1.

    description      TEXT NOT NULL,
    -- Human-readable description of what this migration does.
    -- Written by the engineer who authored the Alembic script.
    -- Example: 'Create loyalty_accounts, point_transactions,
    --           reward_tiers, redemption_events tables.'

    is_required      BOOLEAN NOT NULL DEFAULT TRUE,
    -- TRUE = must run before the feature is marked Active.
    -- FALSE = optional enhancement, applied asynchronously post-activation.

    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT feature_migrations_sequence_positive CHECK (
        sequence_order > 0
    )
);

COMMENT ON TABLE kloudshop_platform.feature_migrations IS
    'Maps Alembic migration revision IDs to Feature Catalogue items. '
    'Migration Runner applies these in sequence_order on feature activation. '
    'Non-destructive migrations only — enforced by CI linter at build time.';

CREATE INDEX idx_feature_migrations_feature_sequence
    ON kloudshop_platform.feature_migrations (feature_id, sequence_order);
-- Rationale: Migration Runner fetches all migrations for a feature
-- in sequence_order on every activation. This is the exact query
-- pattern — composite index covering both columns.

CREATE INDEX idx_feature_migrations_required
    ON kloudshop_platform.feature_migrations (feature_id, is_required, sequence_order);
-- Rationale: Migration Runner separates required and optional migrations
-- into two passes. This index supports the filtered query:
-- WHERE feature_id = ? AND is_required = TRUE ORDER BY sequence_order.
```

---

## Table: `carriers`

```sql
-- ============================================================
-- TABLE: carriers
-- SCHEMA: kloudshop_platform
-- PURPOSE: Platform-maintained catalogue of all shipping carriers
--   available for merchants to connect. This is the single source
--   of truth for carrier identity across the platform. Never
--   duplicated into tenant schemas.
--
-- BUSINESS RULES:
--   1. carrier_id is the canonical identifier used across all carrier
--      tables and tenant-schema carrier connection tables.
--   2. Adding a new carrier integration requires:
--      a. INSERT a row here
--      b. INSERT service levels in carrier_service_levels
--      c. INSERT regional availability in carrier_regions
--      d. INSERT credential field definitions in carrier_credential_schemas
--      e. INSERT webhook config in carrier_webhook_configs (if applicable)
--      f. INSERT rate zones in carrier_rate_zones (if applicable)
--      No code changes required for steps a–f if the carrier uses
--      the standard HTTP API integration pattern already in FastAPI.
--      A new carrier API adapter in FastAPI IS required for carriers
--      with non-standard integration patterns.
--   3. integration_type defines how KloudShop communicates with this carrier:
--      'api'     — real-time rate quotes, label generation via REST API
--      'webhook' — carrier pushes events to KloudShop webhooks
--      'hybrid'  — both API and webhook (most major carriers)
--      'manual'  — no API; merchants enter tracking numbers manually
--   4. status = 'deprecated' hides the carrier from new connections
--      but retains it for merchants already connected.
--   5. logo_url is served from KloudShop's own Cloud Storage — never
--      an external carrier URL (avoids broken images on carrier rebrands).
-- ============================================================

CREATE TABLE kloudshop_platform.carriers (
    carrier_id         VARCHAR(64) PRIMARY KEY,
    -- Canonical identifier. Lowercase, underscores.
    -- Examples: 'fedex', 'dhl_express', 'ups', 'royal_mail',
    --           'australia_post', 'usps', 'canada_post'.

    display_name       TEXT NOT NULL,
    -- Human-readable carrier name shown in merchant admin.
    -- Example: 'FedEx', 'DHL Express', 'Royal Mail'.

    logo_url           TEXT,
    -- URL of the carrier logo image, served from KloudShop Cloud Storage.
    -- Pattern: gs://kloudshop-platform/carrier-logos/{carrier_id}.png

    integration_type   VARCHAR(16) NOT NULL DEFAULT 'hybrid',
    -- How KloudShop integrates with this carrier:
    --   'api'     — real-time REST API only
    --   'webhook' — webhook events only
    --   'hybrid'  — both API + webhooks
    --   'manual'  — no API; manual tracking number entry only

    requires_account   BOOLEAN NOT NULL DEFAULT TRUE,
    -- TRUE  = merchant must have their own carrier account and provide
    --         credentials to connect (most carriers).
    -- FALSE = KloudShop platform account is used for all merchants
    --         (rare; platform-negotiated rates only).

    status             VARCHAR(16) NOT NULL DEFAULT 'active',
    -- 'active'     — available for new merchant connections
    -- 'deprecated' — hidden from new connections; existing connections retained

    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT carriers_integration_type_check CHECK (
        integration_type IN ('api', 'webhook', 'hybrid', 'manual')
    ),
    CONSTRAINT carriers_status_check CHECK (
        status IN ('active', 'deprecated')
    )
);

COMMENT ON TABLE kloudshop_platform.carriers IS
    'Platform-maintained carrier catalogue. Adding a carrier = INSERTs across '
    'carrier_* tables. No code change needed for standard API integration pattern. '
    'Never duplicated into tenant schemas — shared across all merchants.';

CREATE INDEX idx_carriers_active
    ON kloudshop_platform.carriers (status)
    WHERE status = 'active';
-- Rationale: Merchant shipping settings screen lists all active carriers.

-- Seed data — major carriers at launch
INSERT INTO kloudshop_platform.carriers
    (carrier_id, display_name, integration_type, requires_account, status)
VALUES
    ('fedex',          'FedEx',            'hybrid',  TRUE,  'active'),
    ('dhl_express',    'DHL Express',      'hybrid',  TRUE,  'active'),
    ('ups',            'UPS',              'hybrid',  TRUE,  'active'),
    ('usps',           'USPS',             'api',     TRUE,  'active'),
    ('royal_mail',     'Royal Mail',       'hybrid',  TRUE,  'active'),
    ('australia_post', 'Australia Post',   'hybrid',  TRUE,  'active'),
    ('canada_post',    'Canada Post',      'api',     TRUE,  'active'),
    ('manual_carrier', 'Manual / Other',   'manual',  FALSE, 'active');
```

---

## Table: `carrier_service_levels`

```sql
-- ============================================================
-- TABLE: carrier_service_levels
-- SCHEMA: kloudshop_platform
-- PURPOSE: Service levels per carrier (e.g. FedEx Ground, FedEx 2Day,
--   DHL Express Worldwide). One row per service level. Shared across
--   all merchants. Merchants enable/disable service levels for their
--   checkout in carrier_checkout_options (tenant schema).
--
-- BUSINESS RULES:
--   1. service_level_id is the canonical identifier used in tenant
--      carrier_checkout_options rows.
--   2. transit_days_min and transit_days_max are FALLBACK values used
--      only when the carrier API does not return a specific estimated
--      delivery date. At checkout, KloudShop always prefers the carrier
--      API's specific date. These values are for display when the API
--      is unavailable or returns only transit days.
--   3. carrier_api_code is the carrier's own internal code for this
--      service level — used in API requests to the carrier.
--      Example: FedEx uses 'FEDEX_GROUND' in their API.
--   4. supports_tracking = TRUE means this service level provides
--      trackable shipments with a tracking number. FALSE for services
--      like standard letter mail where tracking is not available.
--   5. is_signature_required = TRUE is a service characteristic, not
--      a per-shipment option. This is the carrier's default for this
--      service level. Per-shipment signature options are in
--      carrier_checkout_options (tenant schema).
-- ============================================================

CREATE TABLE kloudshop_platform.carrier_service_levels (
    service_level_id      VARCHAR(64) PRIMARY KEY,
    -- Canonical identifier. Pattern: {carrier_id}_{service_code}.
    -- Examples: 'fedex_ground', 'fedex_2day', 'dhl_express_worldwide',
    --           'ups_ground', 'royal_mail_tracked_24'.

    carrier_id            VARCHAR(64) NOT NULL
                          REFERENCES kloudshop_platform.carriers (carrier_id)
                          ON DELETE RESTRICT,
    -- Parent carrier. RESTRICT: do not delete a carrier that has service levels.

    display_name          TEXT NOT NULL,
    -- Human-readable service level name shown at checkout and in admin.
    -- Example: 'FedEx Ground', 'DHL Express Worldwide', 'Royal Mail Tracked 24'.

    carrier_api_code      TEXT,
    -- The carrier's own service code used in API rate requests.
    -- Example: 'FEDEX_GROUND', 'EXPRESS_WORLDWIDE', 'TRK'.
    -- NULL for manual carriers (no API code needed).

    transit_days_min      INTEGER,
    -- Minimum transit days for this service level (fallback estimate).
    -- NULL if the carrier always returns specific delivery dates via API.

    transit_days_max      INTEGER,
    -- Maximum transit days for this service level (fallback estimate).
    -- NULL if the carrier always returns specific delivery dates via API.

    supports_tracking     BOOLEAN NOT NULL DEFAULT TRUE,
    -- TRUE = shipments via this service level have a tracking number.
    -- FALSE = untracked service (e.g. standard letter mail).

    is_express            BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = express/expedited service (used for sorting in checkout UI).
    -- Express options are shown after standard options in checkout.

    max_weight_kg         DECIMAL(8, 3),
    -- Maximum package weight for this service level in kilograms.
    -- NULL = no weight limit defined by the carrier for this service.

    status                VARCHAR(16) NOT NULL DEFAULT 'active',
    -- 'active'     — available for merchant checkout configuration
    -- 'deprecated' — hidden from new configurations; existing retained

    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT carrier_service_levels_status_check CHECK (
        status IN ('active', 'deprecated')
    ),
    CONSTRAINT carrier_service_levels_transit_days_check CHECK (
        transit_days_max IS NULL OR transit_days_min IS NULL
        OR transit_days_max >= transit_days_min
    )
);

COMMENT ON TABLE kloudshop_platform.carrier_service_levels IS
    'Service levels per carrier. Shared across all merchants. '
    'transit_days_min/max are fallback estimates — carrier API response '
    'specific dates always take precedence at checkout.';

CREATE INDEX idx_carrier_service_levels_carrier
    ON kloudshop_platform.carrier_service_levels (carrier_id, is_express)
    WHERE status = 'active';
-- Rationale: Checkout carrier configuration screen loads all active
-- service levels for a carrier, express services separated for display.

-- Seed data — major service levels at launch
INSERT INTO kloudshop_platform.carrier_service_levels
    (service_level_id, carrier_id, display_name, carrier_api_code,
     transit_days_min, transit_days_max, supports_tracking, is_express)
VALUES
    ('fedex_ground',       'fedex',       'FedEx Ground',            'FEDEX_GROUND',         1, 5, TRUE,  FALSE),
    ('fedex_express_saver','fedex',       'FedEx Express Saver',     'FEDEX_EXPRESS_SAVER',  3, 3, TRUE,  TRUE),
    ('fedex_2day',         'fedex',       'FedEx 2Day',              'FEDEX_2_DAY',          2, 2, TRUE,  TRUE),
    ('fedex_overnight',    'fedex',       'FedEx Priority Overnight','PRIORITY_OVERNIGHT',   1, 1, TRUE,  TRUE),
    ('dhl_express_ww',     'dhl_express', 'DHL Express Worldwide',   'EXPRESS_WORLDWIDE',    1, 3, TRUE,  TRUE),
    ('dhl_economy',        'dhl_express', 'DHL Economy Select',      'ECONOMY_SELECT',       3, 7, TRUE,  FALSE),
    ('ups_ground',         'ups',         'UPS Ground',              '03',                   1, 5, TRUE,  FALSE),
    ('ups_2day',           'ups',         'UPS 2nd Day Air',         '02',                   2, 2, TRUE,  TRUE),
    ('ups_overnight',      'ups',         'UPS Next Day Air',        '01',                   1, 1, TRUE,  TRUE),
    ('royal_mail_t24',     'royal_mail',  'Royal Mail Tracked 24',   'TRK24',                1, 1, TRUE,  TRUE),
    ('royal_mail_t48',     'royal_mail',  'Royal Mail Tracked 48',   'TRK48',                2, 3, TRUE,  FALSE),
    ('aus_post_express',   'australia_post','Australia Post Express','EXPRESS',              1, 2, TRUE,  TRUE),
    ('aus_post_standard',  'australia_post','Australia Post Standard','STANDARD',            2, 6, TRUE,  FALSE),
    ('manual_delivery',    'manual_carrier','Manual / Other Carrier', NULL,                  NULL,NULL,FALSE,FALSE);
```

---

## Table: `carrier_regions`

```sql
-- ============================================================
-- TABLE: carrier_regions
-- SCHEMA: kloudshop_platform
-- PURPOSE: Defines which carriers are available in which countries
--   and GCP regions. Controls which carriers a merchant sees in
--   their Shipping Settings based on their storefront's primary
--   GCP region and their target shipping destinations.
--
-- BUSINESS RULES:
--   1. One row per (carrier, country) pair.
--      A carrier available in many countries has many rows.
--   2. country_code is ISO 3166-1 alpha-2 (e.g. 'US', 'GB', 'AU').
--   3. is_origin = TRUE means the carrier can pick up shipments FROM
--      this country (relevant for label generation).
--   4. is_destination = TRUE means the carrier can deliver TO this
--      country (relevant for checkout rate options).
--   5. gcp_region_hint is an optional advisory — when a merchant's
--      primary GCP region is 'us-central1', the UI surfaces US-based
--      carriers prominently. This is a UX hint only — merchants can
--      still connect any globally available carrier regardless.
-- ============================================================

CREATE TABLE kloudshop_platform.carrier_regions (
    carrier_region_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    carrier_id         VARCHAR(64) NOT NULL
                       REFERENCES kloudshop_platform.carriers (carrier_id)
                       ON DELETE CASCADE,
    -- CASCADE: if a carrier is removed, its regional mappings are removed.

    country_code       CHAR(2) NOT NULL,
    -- ISO 3166-1 alpha-2 country code. Examples: 'US', 'GB', 'AU', 'DE'.

    is_origin          BOOLEAN NOT NULL DEFAULT TRUE,
    -- TRUE = carrier picks up from this country.
    -- FALSE = carrier only delivers to this country (no pickup).

    is_destination     BOOLEAN NOT NULL DEFAULT TRUE,
    -- TRUE = carrier delivers to this country.

    gcp_region_hint    VARCHAR(32),
    -- Optional GCP region that maps to this country for UI prioritisation.
    -- Example: 'us-central1' for 'US', 'europe-west2' for 'GB'.
    -- NULL = no specific GCP region preference for this country.

    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT carrier_regions_unique_carrier_country
        UNIQUE (carrier_id, country_code)
);

COMMENT ON TABLE kloudshop_platform.carrier_regions IS
    'Carrier availability by country. Controls which carriers appear '
    'in a merchant''s Shipping Settings based on their GCP region '
    'and target markets. is_origin/is_destination distinguish pickup vs delivery.';

CREATE INDEX idx_carrier_regions_carrier
    ON kloudshop_platform.carrier_regions (carrier_id, country_code);
-- Rationale: Carrier connection wizard queries all countries a carrier
-- serves for validation and display.

CREATE INDEX idx_carrier_regions_country_origin
    ON kloudshop_platform.carrier_regions (country_code, carrier_id)
    WHERE is_origin = TRUE;
-- Rationale: Shipping settings loads carriers available for pickup
-- in the merchant's country (their primary shipping origin).

CREATE INDEX idx_carrier_regions_gcp_hint
    ON kloudshop_platform.carrier_regions (gcp_region_hint, carrier_id)
    WHERE gcp_region_hint IS NOT NULL;
-- Rationale: Merchant onboarding surfaces region-appropriate carriers
-- based on their chosen GCP primary region.
```

---

## Table: `carrier_credential_schemas`

```sql
-- ============================================================
-- TABLE: carrier_credential_schemas
-- SCHEMA: kloudshop_platform
-- PURPOSE: Defines the credential fields required to connect a
--   merchant's carrier account to KloudShop. Drives the dynamic
--   carrier connection wizard in the Flutter admin — no hardcoded
--   forms per carrier. Adding a new carrier with different credential
--   requirements requires only INSERTs here, no Flutter code changes.
--
-- BUSINESS RULES:
--   1. One row per credential field per carrier.
--      FedEx might have 3 fields (account_number, api_key, api_secret).
--      Royal Mail might have 2 fields (oba_number, api_key).
--   2. is_secret = TRUE marks fields that must be stored encrypted
--      in GCP Secret Manager, never in the database. The merchant
--      carrier connection record (tenant schema) stores only the
--      Secret Manager reference path for secret fields.
--      is_secret = FALSE fields are stored directly in the tenant schema
--      (e.g. account_number is not secret — it appears on waybills).
--   3. field_type drives the Flutter input widget:
--      'text'     → standard TextInput (visible while typing)
--      'password' → obscured TextInput (hidden while typing, for API keys)
--      'number'   → numeric TextInput with format validation
--   4. validation_regex is an optional server-side validation pattern.
--      Applied by FastAPI when saving the credential, before the value
--      is sent to GCP Secret Manager.
--   5. display_order controls the order fields appear in the wizard.
-- ============================================================

CREATE TABLE kloudshop_platform.carrier_credential_schemas (
    credential_schema_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    carrier_id            VARCHAR(64) NOT NULL
                          REFERENCES kloudshop_platform.carriers (carrier_id)
                          ON DELETE CASCADE,
    -- CASCADE: if a carrier is removed, its credential schema is removed.

    field_key             VARCHAR(64) NOT NULL,
    -- Machine-readable field identifier. Used as the key in the
    -- Secret Manager path and in API calls to validate credentials.
    -- Examples: 'account_number', 'api_key', 'api_secret', 'meter_number'.

    display_label         TEXT NOT NULL,
    -- Human-readable label shown in the carrier connection wizard.
    -- Example: 'FedEx Account Number', 'API Key', 'API Secret'.

    helper_text           TEXT,
    -- Optional guidance shown below the input field.
    -- Example: 'Your 9-digit FedEx account number, found on your waybills.'

    field_type            VARCHAR(16) NOT NULL DEFAULT 'text',
    -- Input field type. Drives Flutter widget:
    --   'text'     → TextInput (visible)
    --   'password' → TextInput (obscured — for secrets)
    --   'number'   → NumericInput

    is_secret             BOOLEAN NOT NULL DEFAULT TRUE,
    -- TRUE  = store in GCP Secret Manager; DB stores only the reference path.
    -- FALSE = safe to store directly in tenant schema (e.g. account numbers).

    is_required           BOOLEAN NOT NULL DEFAULT TRUE,
    -- TRUE = must be provided before the connection can be saved.

    validation_regex      TEXT,
    -- Optional server-side regex validation pattern. Applied by FastAPI.
    -- Example for FedEx account number: '^\d{9}$'
    -- NULL = no format validation beyond is_required.

    display_order         INTEGER NOT NULL DEFAULT 0,
    -- Order in which fields appear in the connection wizard.

    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT carrier_credential_schemas_unique_carrier_field
        UNIQUE (carrier_id, field_key),
    CONSTRAINT carrier_credential_schemas_field_type_check CHECK (
        field_type IN ('text', 'password', 'number')
    )
);

COMMENT ON TABLE kloudshop_platform.carrier_credential_schemas IS
    'Credential field definitions per carrier. Drives dynamic carrier '
    'connection wizard — no Flutter code change for new carriers. '
    'is_secret = TRUE fields stored in GCP Secret Manager, never in DB.';

CREATE INDEX idx_carrier_credential_schemas_carrier
    ON kloudshop_platform.carrier_credential_schemas (carrier_id, display_order);
-- Rationale: Carrier connection wizard loads all fields for a carrier
-- in display_order. Primary read pattern for this table.

-- Seed data — credential schemas for major carriers
INSERT INTO kloudshop_platform.carrier_credential_schemas
    (carrier_id, field_key, display_label, helper_text, field_type,
     is_secret, is_required, validation_regex, display_order)
VALUES
    ('fedex', 'account_number', 'FedEx Account Number',
     'Your 9-digit FedEx account number, found on your shipping waybills.',
     'number', FALSE, TRUE, '^\d{9}$', 10),

    ('fedex', 'api_key', 'API Key',
     'Found in your FedEx Developer Portal under your app credentials.',
     'password', TRUE, TRUE, NULL, 20),

    ('fedex', 'api_secret', 'API Secret',
     'The secret key paired with your API Key in the FedEx Developer Portal.',
     'password', TRUE, TRUE, NULL, 30),

    ('dhl_express', 'account_number', 'DHL Account Number',
     'Your DHL Express account number provided by your DHL representative.',
     'text', FALSE, TRUE, NULL, 10),

    ('dhl_express', 'api_key', 'API Key',
     'Generated in the DHL Express Developer Portal.',
     'password', TRUE, TRUE, NULL, 20),

    ('dhl_express', 'api_secret', 'API Secret',
     'The API secret paired with your API Key.',
     'password', TRUE, TRUE, NULL, 30),

    ('ups', 'account_number', 'UPS Account Number',
     'Your 6-character UPS shipper account number.',
     'text', FALSE, TRUE, '^[A-Z0-9]{6}$', 10),

    ('ups', 'client_id', 'Client ID',
     'Found in your UPS Developer Kit application settings.',
     'password', TRUE, TRUE, NULL, 20),

    ('ups', 'client_secret', 'Client Secret',
     'The client secret for your UPS Developer Kit application.',
     'password', TRUE, TRUE, NULL, 30),

    ('royal_mail', 'oba_number', 'OBA Account Number',
     'Your Royal Mail Online Business Account (OBA) number.',
     'text', FALSE, TRUE, NULL, 10),

    ('royal_mail', 'api_key', 'API Key',
     'Generated in the Royal Mail Developer Portal.',
     'password', TRUE, TRUE, NULL, 20),

    ('australia_post', 'account_number', 'Australia Post Account Number',
     'Your Australia Post charge account number.',
     'text', FALSE, TRUE, NULL, 10),

    ('australia_post', 'api_key', 'API Key',
     'Your Australia Post API key from the Developer Centre.',
     'password', TRUE, TRUE, NULL, 20);
```

---

## Table: `carrier_webhook_configs`

```sql
-- ============================================================
-- TABLE: carrier_webhook_configs
-- SCHEMA: kloudshop_platform
-- PURPOSE: Per-carrier webhook configuration. Defines the events
--   a carrier pushes to KloudShop, the endpoint KloudShop exposes
--   to receive them, and how KloudShop validates the webhook
--   signature to prevent spoofed events.
--
-- BUSINESS RULES:
--   1. One row per carrier per event_type.
--      A carrier that sends tracking updates and delivery confirmations
--      has two rows.
--   2. kloudshop_endpoint_path is the relative path on KloudShop's
--      FastAPI service that handles this carrier's webhook events.
--      Pattern: /webhooks/carriers/{carrier_id}/{event_type}
--      The full URL registered with the carrier is:
--      https://api.kloudshop.biz/webhooks/carriers/{carrier_id}/{event_type}
--   3. signature_method defines how to validate the incoming webhook:
--      'hmac_sha256' — carrier signs with HMAC-SHA256; KloudShop
--                      recomputes and compares (most common)
--      'basic_auth'  — carrier sends HTTP Basic Auth header
--      'ip_allowlist'— validate against carrier's known IP ranges
--      'none'        — no signature validation (not recommended;
--                       only for carriers with no signing support)
--   4. signature_header is the HTTP header name the carrier uses
--      to send the signature. Example: 'X-FedEx-Signature'.
--      NULL if signature_method is 'none' or 'ip_allowlist'.
--   5. retry_policy_max_attempts: how many times KloudShop retries
--      processing a failed webhook event before dead-lettering it.
-- ============================================================

CREATE TABLE kloudshop_platform.carrier_webhook_configs (
    webhook_config_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    carrier_id             VARCHAR(64) NOT NULL
                           REFERENCES kloudshop_platform.carriers (carrier_id)
                           ON DELETE CASCADE,

    event_type             VARCHAR(64) NOT NULL,
    -- The carrier event type this config handles.
    -- Examples: 'tracking_update', 'delivery_confirmed',
    --           'shipment_exception', 'pickup_confirmed'.

    kloudshop_endpoint_path TEXT NOT NULL,
    -- Relative FastAPI endpoint path for this webhook.
    -- Pattern: /webhooks/carriers/{carrier_id}/{event_type}
    -- Example: /webhooks/carriers/fedex/tracking_update

    signature_method       VARCHAR(16) NOT NULL DEFAULT 'hmac_sha256',
    -- Webhook signature validation method.
    -- Values: 'hmac_sha256' | 'basic_auth' | 'ip_allowlist' | 'none'

    signature_header       TEXT,
    -- HTTP header name containing the webhook signature.
    -- Example: 'X-FedEx-Signature', 'X-DHL-Signature'.
    -- NULL if signature_method is 'none' or 'ip_allowlist'.

    signature_secret_ref   TEXT,
    -- GCP Secret Manager path for the HMAC signing secret.
    -- Pattern: projects/{project_id}/secrets/carrier-{carrier_id}-webhook-secret/versions/latest
    -- NULL if signature_method is not 'hmac_sha256'.

    retry_policy_max_attempts INTEGER NOT NULL DEFAULT 3,
    -- Maximum retry attempts for failed webhook event processing
    -- before the event is sent to the Cloud Tasks dead-letter queue.

    is_active              BOOLEAN NOT NULL DEFAULT TRUE,
    -- FALSE = KloudShop stops processing events of this type.
    -- Used to disable a specific event type without full carrier removal.

    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT carrier_webhook_configs_unique_carrier_event
        UNIQUE (carrier_id, event_type),
    CONSTRAINT carrier_webhook_configs_signature_method_check CHECK (
        signature_method IN ('hmac_sha256', 'basic_auth', 'ip_allowlist', 'none')
    )
);

COMMENT ON TABLE kloudshop_platform.carrier_webhook_configs IS
    'Per-carrier webhook endpoint and signature validation configuration. '
    'Allows adding new carrier webhook integrations without code changes '
    'for carriers using the standard HMAC-SHA256 signing pattern.';

CREATE INDEX idx_carrier_webhook_configs_carrier
    ON kloudshop_platform.carrier_webhook_configs (carrier_id)
    WHERE is_active = TRUE;
-- Rationale: FastAPI webhook router validates incoming events against
-- this table on every webhook receipt.

CREATE INDEX idx_carrier_webhook_configs_endpoint
    ON kloudshop_platform.carrier_webhook_configs (kloudshop_endpoint_path)
    WHERE is_active = TRUE;
-- Rationale: Webhook handler resolves the carrier and event_type
-- from the incoming request path. Partial index on active configs.
```

---

## Table: `carrier_rate_zones`

```sql
-- ============================================================
-- TABLE: carrier_rate_zones
-- SCHEMA: kloudshop_platform
-- PURPOSE: Geographic zone definitions per carrier for zone-based
--   shipping rate calculation. Some carriers (particularly USPS,
--   Canada Post, and Australia Post) use a zone system where the
--   shipping cost is determined by the zone from origin to destination,
--   not by a real-time API rate quote. This table enables KloudShop
--   to calculate accurate rates for zone-based carriers without
--   requiring a live API call for every checkout.
--
-- BUSINESS RULES:
--   1. Not all carriers use zone-based pricing. Carriers like FedEx
--      and DHL return real-time rate quotes via API. This table is
--      only populated for carriers where zone tables are the primary
--      pricing mechanism.
--   2. origin_country_code and destination_country_code define the
--      shipping pair. zone_identifier is the carrier's zone label
--      for that pair (e.g. 'Zone 1', 'Zone 5', 'International').
--   3. base_rate_usd is the rate for the first weight_unit_kg of
--      the shipment. additional_rate_per_kg_usd is added per kg above
--      the base weight. This models the most common zone table format.
--   4. Zone tables are updated periodically as carriers publish new
--      rate schedules. The Platform Admin updates rows here — no
--      merchant action required.
--   5. effective_from and effective_to define the rate validity window.
--      Multiple overlapping rate versions can coexist; the application
--      always uses the row where NOW() is between effective_from and
--      effective_to.
-- ============================================================

CREATE TABLE kloudshop_platform.carrier_rate_zones (
    rate_zone_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    carrier_id                VARCHAR(64) NOT NULL
                              REFERENCES kloudshop_platform.carriers (carrier_id)
                              ON DELETE CASCADE,

    service_level_id          VARCHAR(64) NOT NULL
                              REFERENCES kloudshop_platform.carrier_service_levels (service_level_id)
                              ON DELETE CASCADE,
    -- Rate zones are specific to a service level within a carrier.
    -- FedEx Ground and FedEx 2Day have independent zone tables.

    origin_country_code       CHAR(2) NOT NULL,
    -- ISO 3166-1 alpha-2 origin country. Example: 'US', 'AU'.

    destination_country_code  CHAR(2) NOT NULL,
    -- ISO 3166-1 alpha-2 destination country. Example: 'US', 'AU'.

    destination_postal_prefix VARCHAR(8),
    -- Optional postal code prefix for intra-country zone determination.
    -- Example: '1' for US ZIP codes starting with 1 (Northeast).
    -- NULL = the zone applies to all destinations in the country.

    zone_identifier           VARCHAR(16) NOT NULL,
    -- Carrier's zone label for this origin/destination pair.
    -- Examples: '1', '2', '8', 'Zone 1', 'International'.

    base_rate_usd             DECIMAL(10, 4) NOT NULL,
    -- Base rate (USD) for the minimum weight (typically first 0.5kg or 1kg).

    base_weight_kg            DECIMAL(6, 3) NOT NULL DEFAULT 0.5,
    -- Weight (kg) included in the base_rate_usd.

    additional_rate_per_kg_usd DECIMAL(10, 4) NOT NULL DEFAULT 0,
    -- Additional charge per kg above base_weight_kg.

    currency_code             CHAR(3) NOT NULL DEFAULT 'USD',
    -- ISO 4217 currency code for the rates in this row.
    -- Most zone tables are in USD. Non-USD carriers (e.g. Royal Mail)
    -- have their own currency_code.

    effective_from            DATE NOT NULL,
    -- Date from which this rate applies.

    effective_to              DATE,
    -- Date until which this rate applies. NULL = current/no expiry.

    created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT carrier_rate_zones_dates_check CHECK (
        effective_to IS NULL OR effective_to > effective_from
    ),
    CONSTRAINT carrier_rate_zones_base_rate_positive CHECK (
        base_rate_usd > 0
    )
);

COMMENT ON TABLE kloudshop_platform.carrier_rate_zones IS
    'Zone-based rate tables per carrier/service level. Used for carriers '
    'that price by origin-destination zone rather than real-time API quote. '
    'effective_from/to allows rate schedule versioning without deleting old rows.';

CREATE INDEX idx_carrier_rate_zones_lookup
    ON kloudshop_platform.carrier_rate_zones
    (carrier_id, service_level_id, origin_country_code,
     destination_country_code, effective_from DESC);
-- Rationale: Rate calculation query — given carrier, service level,
-- and origin/destination pair, find the current zone rate.
-- Composite index covers the exact WHERE columns used in the lookup.
-- Sorted by effective_from DESC so the most recent rate is first.

CREATE INDEX idx_carrier_rate_zones_postal_prefix
    ON kloudshop_platform.carrier_rate_zones
    (carrier_id, service_level_id, origin_country_code, destination_postal_prefix)
    WHERE destination_postal_prefix IS NOT NULL;
-- Rationale: Intra-country zone determination by postal prefix.
-- Partial index on rows that use postal prefix — avoids scanning
-- international rows during domestic rate calculations.
```

---

## Updated Schema Inventory Entry

After generating this artifact, update `06-schema-inventory.md`:

```
| `06a2-platform-catalogue-schema.md` | ✅ Generated | 11 | Platform theme, feature, and carrier catalogue tables |
```
