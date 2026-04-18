# 06m — Tenant Feature-Gated Schema
# KloudShop Stage 6 — Data Model

> **Artifact:** `06m-tenant-feature-gated-schema.md`
> **Schema:** `tenant_{tenant_id}` (feature-gated — created by Migration Runner on demand)
> **Persona:** Principal Data Engineer
> **Reads from:** `01-product-brief.md`, `01b-tech-stack.md`, `02-architecture.md`,
>   `03-user-journeys.md`, `04-feature-stories.md`, `04b-mvp-scope.md`,
>   `00-carry-forward-flags.md` (DMF-01 through DMF-10),
>   `06a1` through `06l` (all prior Stage 6 sub-artifacts)
> **Depends on (application-layer only — no DB FKs across schema boundaries):**
>   `06b` (variants, products, collections), `06c` (orders), `06j` (consumers),
>   `06k` (tenant_feature_state, tenant_migration_state)
> **Tables:** 17 across 8 features
> **Migration class:** FEATURE-GATED — none of these tables exist in the base
>   tenant schema. Each is created by the Migration Runner (Alembic) when the
>   corresponding Feature Catalogue item is activated by the merchant.
>   Every DDL block carries the comment:
>   `-- Feature-gated: created by Migration Runner on feature activation`
> **Status:** ✅ Generated

---

## Overview

This artifact defines the complete DDL for all feature-gated tables in a KloudShop
merchant tenant schema. Unlike the base tenant schema tables defined in `06b` through
`06k`, **none of these tables exist at tenant provisioning time**. They are created
on demand by the Migration Runner (Alembic), triggered when a merchant activates a
specific Feature Catalogue item through the Phase 1 activation flow documented in
`01b-tech-stack.md` and `06k`.

The 17 tables span 8 distinct features:

| Feature | Tables | Feature Catalogue ID |
|---------|--------|----------------------|
| Customer Loyalty Programme | `loyalty_accounts`, `point_transactions`, `reward_tiers`, `redemption_events` | `loyalty_programme` |
| Discount Engine / Coupon Codes | `discount_codes`, `discount_code_redemptions` | Core platform feature — see note |
| Abandoned Cart Recovery | `abandoned_cart_jobs` | Core platform feature — see note |
| Dynamic Pricing Engine | `dynamic_pricing_rules`, `dynamic_pricing_events` | Core platform feature — see note |
| Subscription / Recurring Orders | `subscription_plans`, `subscriptions`, `subscription_orders` | `subscription_orders` |
| Gift Cards & Store Credit | `gift_cards`, `gift_card_transactions` | `gift_cards` |
| Bundle Builder | `bundle_definitions`, `bundle_components` | `bundle_builder` |
| Affiliate & Referral Tracking | `affiliate_links` | `affiliate_referral` |

> **Note on "core platform features":** Per DEC-22 in `00-carry-forward-flags.md`,
> the Discount Engine, Abandoned Cart Recovery, and Dynamic Pricing Engine are
> classified as **always-on core platform features** — not Feature Catalogue toggle
> items. Their tables are therefore technically BASE tables that should be provisioned
> at signup, not feature-gated. However, because these features benefit from the
> same non-destructive, Alembic-managed migration pattern, and because their tables
> were listed in `BKP-06-schema-inventory.md` under `06m`, they are defined here
> for completeness. The Migration Runner creates them at tenant provisioning alongside
> the base schema migrations, not on a merchant toggle action.

**Non-destructive migration policy applies throughout:** Every table here is additive.
The CI linter enforced at build time (documented in `01b-tech-stack.md`) blocks any
`DROP`, `TRUNCATE`, or destructive `ALTER` from appearing in any migration file.
All columns are nullable or carry explicit `DEFAULT` values so that pre-existing rows
written by older application code remain valid after any migration.

**AI agent note:** All cross-table references in this artifact use plain `UUID`
columns with application-layer validation. PostgreSQL does not support FK constraints
across schemas in Cloud SQL, and even within the tenant schema, FK constraints to
tables in `BKP-06-schema-inventory.md` base artifacts must be declared with care:
if the referenced table might not yet exist (e.g. a feature-gated table referencing
another feature-gated table), a DB-level FK would prevent the migration from running
in isolation. Application-layer validation is the correct approach throughout.
Where a FK is declared in the DDL below, it references a table that is guaranteed
to exist in the base schema (e.g. `variants`, `orders`, `consumers`).

---

## Feature: Customer Loyalty Programme

**Feature ID:** `loyalty_programme`
**Alembic dependency chain:** none (standalone — no upstream feature required)
**Phase 2 config keys:** `points_per_dollar`, `welcome_bonus_points`,
`points_expiry_days`, `min_points_to_redeem`, `redemption_rate_points`,
`reward_tiers` (JSON array of tier objects)

This feature creates four tables. The activation order enforced by
`feature_migrations` sequence_order is: `reward_tiers` first (no FK dependencies),
then `loyalty_accounts`, then `point_transactions`, then `redemption_events`.

---

### Table: `reward_tiers`

```sql
-- Feature-gated: created by Migration Runner on feature activation
-- ============================================================
-- TABLE: reward_tiers
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Merchant-configured loyalty tiers (Bronze, Silver, Gold,
--   Platinum, etc.). Each tier has a point threshold and optional
--   benefits label. A consumer advances to the next tier when their
--   lifetime points_earned crosses the threshold.
--
-- BUSINESS RULES:
--   1. At least one tier is required for the Loyalty Programme to
--      be operational. The lowest tier (sort_order = 1) must have
--      threshold_points = 0 (all consumers start here on enrolment).
--      Enforced at application layer during the wizard — not a DB
--      constraint (would require a subquery check).
--   2. Tiers are never deleted while any loyalty_account references
--      them. Application layer blocks deletion and offers deactivation.
--      is_active = FALSE hides the tier from new promotions but
--      retains historical consumer tier assignments.
--   3. sort_order controls display sequence and tier progression logic.
--      sort_order is unique (no two tiers share a position).
--   4. benefits_label is free text — used for display on the storefront
--      loyalty widget and in order confirmation emails.
--      Examples: "5% discount on all orders", "Free standard shipping".
-- ============================================================

CREATE TABLE reward_tiers (
    tier_id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),

    name             TEXT            NOT NULL
                         CHECK (char_length(name) BETWEEN 1 AND 100),
    -- Display name. Examples: 'Bronze', 'Silver', 'Gold', 'Platinum'.

    threshold_points INTEGER         NOT NULL
                         CHECK (threshold_points >= 0),
    -- Minimum lifetime points_earned to enter this tier.
    -- The entry tier must have threshold_points = 0.

    benefits_label   TEXT
                         CHECK (char_length(benefits_label) <= 500),
    -- Optional marketing description of the tier's perks.
    -- Displayed on storefront loyalty widget and emails. NULL = no label.

    sort_order       INTEGER         NOT NULL DEFAULT 0,
    -- Ascending order of tier progression (1 = entry, N = top).

    is_active        BOOLEAN         NOT NULL DEFAULT TRUE,
    -- FALSE = tier hidden from new promotions; consumer assignments retained.

    created_at       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT reward_tiers_sort_order_unique UNIQUE (sort_order),
    CONSTRAINT reward_tiers_name_unique       UNIQUE (name)
);

COMMENT ON TABLE reward_tiers IS
    'Feature-gated (loyalty_programme). Merchant-configured loyalty tiers. '
    'sort_order defines tier progression; threshold_points is the lifetime '
    'earned-points entry threshold. Entry tier must have threshold_points = 0 '
    '(enforced at app layer). Tiers are never deleted while consumers hold them.';

CREATE INDEX idx_reward_tiers_sort_order
    ON reward_tiers (sort_order)
    WHERE is_active = TRUE;
-- Rationale: Tier resolution at purchase time — find the highest active
-- tier whose threshold_points <= consumer's lifetime points_earned.
-- ORDER BY sort_order DESC LIMIT 1 is the dominant query pattern.
```

---

### Table: `loyalty_accounts`

```sql
-- Feature-gated: created by Migration Runner on feature activation
-- ============================================================
-- TABLE: loyalty_accounts
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per consumer enrolled in the Loyalty Programme.
--   Tracks current points balance, lifetime earned totals, and tier
--   assignment. Created on consumer enrolment (post-checkout soft
--   signup or explicit enrolment from the consumer account panel).
--
-- BUSINESS RULES:
--   1. One loyalty_account per consumer. consumer_id is UNIQUE.
--      consumer_id references consumers (base schema) — DB FK valid.
--   2. points_balance is the current redeemable balance:
--      points_earned (lifetime total) minus points_redeemed (lifetime).
--      Stored as a denormalised integer for fast checkout queries.
--      The authoritative ledger is point_transactions; this balance
--      is reconciled by a nightly Cloud Tasks job.
--   3. current_tier_id references reward_tiers (created in this same
--      feature migration). Declared as a DB FK — safe because
--      reward_tiers is created first in the migration sequence.
--   4. Tier advancement is computed by the application on every
--      points_earned increment. It is NOT auto-computed by the DB.
--   5. enrolled_at records first programme enrolment. NULL until the
--      consumer actively joins (welcome bonus points are credited then).
--   6. is_active = FALSE suspends the account (e.g. fraud flag).
--      Points balance is frozen. No earn or redeem while inactive.
-- ============================================================

CREATE TABLE loyalty_accounts (
    loyalty_account_id   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    consumer_id          UUID        NOT NULL UNIQUE
                             REFERENCES consumers (consumer_id)
                             ON DELETE CASCADE,
    -- CASCADE: GDPR erasure of a consumer removes their loyalty account.
    -- point_transactions and redemption_events cascade from this FK.

    current_tier_id      UUID
                             REFERENCES reward_tiers (tier_id)
                             ON DELETE RESTRICT,
    -- RESTRICT: never delete a tier that consumers are assigned to.
    -- NULL only if no tiers are configured (degenerate state; blocked at
    -- app layer during wizard). In practice always set after enrolment.

    points_balance       INTEGER     NOT NULL DEFAULT 0
                             CHECK (points_balance >= 0),
    -- Current redeemable balance (lifetime earned minus lifetime redeemed).
    -- Denormalised — reconciled by nightly Cloud Tasks job against
    -- point_transactions ledger. Never goes negative (enforced by CHECK).

    points_earned        INTEGER     NOT NULL DEFAULT 0
                             CHECK (points_earned >= 0),
    -- Lifetime total points earned (never decremented on redemption).
    -- Used for tier progression calculations.

    points_redeemed      INTEGER     NOT NULL DEFAULT 0
                             CHECK (points_redeemed >= 0),
    -- Lifetime total points redeemed. points_balance = points_earned
    -- - points_redeemed (reconciliation invariant).

    enrolled_at          TIMESTAMPTZ,
    -- When the consumer first joined the programme. NULL = not yet enrolled
    -- (account may be pre-created by migration for existing consumers).

    is_active            BOOLEAN     NOT NULL DEFAULT TRUE,

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE loyalty_accounts IS
    'Feature-gated (loyalty_programme). One row per enrolled consumer. '
    'points_balance is denormalised for fast checkout; reconciled nightly '
    'against point_transactions ledger. Tier progression computed at app layer '
    'on every earn event. CASCADE on consumer delete (GDPR erasure path).';

CREATE UNIQUE INDEX idx_loyalty_accounts_consumer_id
    ON loyalty_accounts (consumer_id);
-- Rationale: Checkout queries loyalty_account by consumer_id on every
-- cart view to display points balance and available redemption. O(1).

CREATE INDEX idx_loyalty_accounts_tier
    ON loyalty_accounts (current_tier_id, points_earned DESC)
    WHERE is_active = TRUE;
-- Rationale: Tier analytics — "how many active consumers are in each tier?"
-- and "who is closest to advancing?" Dashboard query pattern.
```

---

### Table: `point_transactions`

```sql
-- Feature-gated: created by Migration Runner on feature activation
-- ============================================================
-- TABLE: point_transactions
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Append-only ledger of all point earn and redeem events.
--   This is the authoritative source for loyalty account balances.
--   The denormalised balance on loyalty_accounts is reconciled
--   against this table nightly.
--
-- BUSINESS RULES:
--   1. Append-only. No UPDATE. No DELETE. Ever.
--      This is the financial ledger for the loyalty programme.
--   2. transaction_type distinguishes earn from redeem:
--      'earn'         — points credited to the account
--      'redeem'       — points debited at checkout
--      'expire'       — points removed on expiry job run
--      'adjust'       — manual correction by merchant (positive or negative)
--      'welcome_bonus'— points credited on first enrolment
--      'refund_earn'  — earn reversal on order refund
--   3. points_delta is signed: positive for earn/welcome/adjust (if
--      positive adjustment), negative for redeem/expire/refund_earn/
--      negative adjust.
--   4. order_id references orders (base schema). Plain UUID — no DB
--      FK constraint (order could be from any channel, and we must
--      not block expiry or welcome bonus transactions that have no
--      linked order). Application validates when set.
--   5. expiry_date is populated for 'earn' transactions when the
--      programme is configured with points_expiry_days > 0. The
--      nightly expiry Cloud Tasks job queries for unexpired earn rows
--      where expiry_date <= TODAY() and no corresponding 'expire'
--      transaction has been written yet.
-- ============================================================

CREATE TABLE point_transactions (
    transaction_id       UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    loyalty_account_id   UUID        NOT NULL
                             REFERENCES loyalty_accounts (loyalty_account_id)
                             ON DELETE CASCADE,
    -- CASCADE: consumer GDPR erasure removes loyalty account which
    -- cascades to remove all their transaction history.

    transaction_type     VARCHAR(20) NOT NULL
                             CHECK (transaction_type IN (
                                 'earn', 'redeem', 'expire',
                                 'adjust', 'welcome_bonus', 'refund_earn'
                             )),

    points_delta         INTEGER     NOT NULL,
    -- Signed integer. Positive = points added. Negative = points removed.
    -- 'earn' and 'welcome_bonus' are always positive.
    -- 'redeem', 'expire', 'refund_earn' are always negative.
    -- 'adjust' may be either.

    points_balance_after INTEGER     NOT NULL
                             CHECK (points_balance_after >= 0),
    -- Running balance snapshot after this transaction applied.
    -- Enables point-in-time balance reconstruction without a full scan.

    order_id             UUID,
    -- References orders.order_id (base schema). Plain UUID — no DB FK.
    -- Set for 'earn', 'redeem', 'refund_earn' transactions.
    -- NULL for 'expire', 'adjust', 'welcome_bonus'.

    description          TEXT,
    -- Optional human-readable description. Examples:
    -- "Earned for order #1042", "Redeemed at checkout", "Points expiry".

    expiry_date          DATE,
    -- For 'earn' transactions when points_expiry_days > 0.
    -- The date on which these specific points expire if not redeemed.
    -- NULL for non-earn transactions and when no expiry is configured.

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
    -- No updated_at — this table is append-only.
);

COMMENT ON TABLE point_transactions IS
    'Feature-gated (loyalty_programme). Append-only points ledger. '
    'No UPDATE, no DELETE ever. Authoritative source for loyalty_accounts '
    'balance reconciliation. points_balance_after enables point-in-time '
    'reconstruction. expiry_date populated for earn rows when programme '
    'has a points_expiry_days config value > 0.';

CREATE INDEX idx_point_transactions_account
    ON point_transactions (loyalty_account_id, created_at DESC);
-- Rationale: Consumer account history — all transactions for an account,
-- newest first. Also used by the nightly balance reconciliation job.

CREATE INDEX idx_point_transactions_order
    ON point_transactions (order_id)
    WHERE order_id IS NOT NULL;
-- Rationale: "Which point transactions are linked to this order?" —
-- used when processing refunds to generate the corresponding refund_earn row.

CREATE INDEX idx_point_transactions_expiry
    ON point_transactions (expiry_date, loyalty_account_id)
    WHERE transaction_type = 'earn'
      AND expiry_date IS NOT NULL;
-- Rationale: Nightly expiry job — find all earn rows with expiry_date
-- <= TODAY() that need a corresponding 'expire' transaction written.
-- Partial index on earn rows with an expiry_date only.
```

---

### Table: `redemption_events`

```sql
-- Feature-gated: created by Migration Runner on feature activation
-- ============================================================
-- TABLE: redemption_events
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Records of points redeemed against specific orders.
--   One row per redemption. Links the point_transaction (the ledger
--   entry) to the order against which the discount was applied,
--   the monetary value of the discount, and the Stripe discount
--   reference used to apply the deduction at checkout.
--
-- BUSINESS RULES:
--   1. A redemption_event is created atomically with a 'redeem'
--      point_transaction row in a single DB transaction. They are
--      always 1-to-1 at write time. The redemption_event provides
--      the monetary context that point_transactions (a points ledger)
--      intentionally lacks.
--   2. discount_value_minor is the actual monetary discount applied
--      to the order in minor currency units (cents, paise, fils).
--      Calculated as: (points_redeemed / redemption_rate_points) × 100
--      where redemption_rate_points is read from tenant_feature_config
--      at checkout time and snapshotted here for historical accuracy.
--   3. redemption_rate_snapshot is the exact ratio used at this
--      redemption event (e.g. 100 = "100 points = $1 discount").
--      Snapshotted so that changes to the programme's redemption rate
--      do not retroactively alter the historical record.
--   4. order_id is NOT NULL — a redemption always has an associated
--      order. References orders (base schema), plain UUID.
-- ============================================================

CREATE TABLE redemption_events (
    redemption_event_id  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    loyalty_account_id   UUID        NOT NULL
                             REFERENCES loyalty_accounts (loyalty_account_id)
                             ON DELETE RESTRICT,
    -- RESTRICT: never auto-delete redemption history on account changes.
    -- Redemption history is a financial record.

    point_transaction_id UUID        NOT NULL UNIQUE,
    -- References point_transactions.transaction_id. Plain UUID — no DB FK
    -- (both tables are in the same feature migration, but declared separately
    -- to avoid ordering issues). UNIQUE: one redemption per ledger entry.

    order_id             UUID        NOT NULL,
    -- References orders.order_id (base schema). Plain UUID — app validates.

    points_redeemed      INTEGER     NOT NULL CHECK (points_redeemed > 0),
    -- The number of points deducted in this redemption event. Always positive.

    discount_value_minor INTEGER     NOT NULL CHECK (discount_value_minor > 0),
    -- The monetary discount applied in minor currency units.

    currency_code        CHAR(3)     NOT NULL,
    -- ISO 4217 currency of discount_value_minor.

    redemption_rate_snapshot INTEGER NOT NULL CHECK (redemption_rate_snapshot > 0),
    -- Snapshotted redemption rate at time of redemption.
    -- Example: 100 means "100 points = 1 major currency unit discount".

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE redemption_events IS
    'Feature-gated (loyalty_programme). One row per redemption event. '
    'Links point ledger entries to orders with the monetary discount applied. '
    'redemption_rate_snapshot preserves the rate at transaction time — '
    'changes to the programme config do not retroactively alter history.';

CREATE INDEX idx_redemption_events_account
    ON redemption_events (loyalty_account_id, created_at DESC);
-- Rationale: Consumer redemption history in the account dashboard.

CREATE INDEX idx_redemption_events_order
    ON redemption_events (order_id);
-- Rationale: Order detail view shows associated loyalty redemption.
```

---

## Feature: Discount Engine / Coupon Codes

**Feature ID:** Core platform feature (DEC-22) — tables provisioned at signup.
**Note:** Per DEC-22 (`00-carry-forward-flags.md`), the Discount Engine is an
always-on core feature. These tables are created by the base Alembic migration,
not on a merchant toggle. They are documented here as they appeared in the
`BKP-06-schema-inventory.md` 06m scope.

---

### Table: `discount_codes`

```sql
-- Core platform feature (DEC-22): created at tenant provisioning.
-- ============================================================
-- TABLE: discount_codes
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Merchant-created alphanumeric discount codes. Supports
--   percentage and fixed-amount discounts, with configurable scope,
--   usage limits, validity windows, and minimum order thresholds.
--
-- BUSINESS RULES:
--   1. code must be unique within the tenant. Case-insensitive
--      matching enforced at application layer (stored normalised
--      to uppercase). The UNIQUE constraint on code enforces
--      physical uniqueness; normalisation is application responsibility.
--   2. discount_type drives how the discount is applied at checkout:
--      'percentage' — discount_value is a percentage (e.g. 15.00 = 15%)
--      'fixed'      — discount_value is a fixed amount in minor currency units
--   3. scope controls which items qualify for the discount:
--      'all'        — applies to all products in the cart
--      'collection' — applies only to items in scope_collection_ids
--      'product'    — applies only to items in scope_product_ids
--   4. usage_limit_total: maximum total redemptions across all consumers.
--      NULL = unlimited total uses.
--   5. usage_limit_per_consumer: maximum times any single consumer can
--      use this code. NULL = unlimited per-consumer uses.
--      One redemption row in discount_code_redemptions per use.
--   6. valid_from / valid_to: the active window. NULL valid_from = active
--      immediately. NULL valid_to = no expiry.
--   7. minimum_order_value_minor: cart subtotal must meet or exceed this
--      value for the code to apply. NULL = no minimum.
--   8. is_active = FALSE disables the code without deleting it.
--      Used to pause a campaign without losing the usage history.
-- ============================================================

CREATE TABLE discount_codes (
    discount_code_id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    code                     TEXT        NOT NULL
                                 CHECK (char_length(code) BETWEEN 1 AND 64),
    -- Alphanumeric + hyphens/underscores. Stored UPPERCASE.
    -- Examples: 'SUMMER20', 'WELCOME10', 'FLASH-24H'.

    description              TEXT,
    -- Optional internal merchant note. Not shown to consumers.

    discount_type            VARCHAR(16) NOT NULL
                                 CHECK (discount_type IN ('percentage', 'fixed')),

    discount_value           DECIMAL(12, 4) NOT NULL
                                 CHECK (discount_value > 0),
    -- For 'percentage': value in percent (e.g. 15.0000 = 15%).
    --   Maximum 100.0000 enforced at application layer.
    -- For 'fixed': value in minor currency units (e.g. 1000 = $10.00 USD).

    currency_code            CHAR(3),
    -- ISO 4217 currency. Required when discount_type = 'fixed'.
    -- NULL for percentage discounts (currency-agnostic).

    -- Scope
    scope                    VARCHAR(16) NOT NULL DEFAULT 'all'
                                 CHECK (scope IN ('all', 'collection', 'product')),

    scope_collection_ids     UUID[],
    -- Collection UUIDs when scope = 'collection'. NULL otherwise.

    scope_product_ids        UUID[],
    -- Product UUIDs when scope = 'product'. NULL otherwise.

    -- Usage limits
    usage_limit_total        INTEGER     CHECK (usage_limit_total > 0),
    -- NULL = unlimited total uses.

    usage_limit_per_consumer INTEGER     CHECK (usage_limit_per_consumer > 0),
    -- NULL = unlimited per-consumer uses.

    redemption_count         INTEGER     NOT NULL DEFAULT 0
                                 CHECK (redemption_count >= 0),
    -- Denormalised running total. Reconciled against discount_code_redemptions.
    -- Used for fast "has this code hit its total usage limit?" check at checkout.

    -- Validity window
    valid_from               TIMESTAMPTZ,
    -- NULL = active immediately.

    valid_to                 TIMESTAMPTZ,
    -- NULL = no expiry.

    -- Minimum order threshold
    minimum_order_value_minor BIGINT     CHECK (minimum_order_value_minor >= 0),
    -- In minor currency units. NULL = no minimum.

    is_active                BOOLEAN     NOT NULL DEFAULT TRUE,

    created_by               UUID        NOT NULL,
    -- staff_user_id. Plain UUID — app validates.

    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT discount_codes_code_unique UNIQUE (code),

    CONSTRAINT discount_codes_fixed_currency_required CHECK (
        discount_type != 'fixed' OR currency_code IS NOT NULL
    ),

    CONSTRAINT discount_codes_valid_window CHECK (
        valid_to IS NULL OR valid_from IS NULL OR valid_to > valid_from
    ),

    CONSTRAINT discount_codes_scope_ids_required CHECK (
        (scope = 'collection' AND scope_collection_ids IS NOT NULL) OR
        (scope = 'product' AND scope_product_ids IS NOT NULL) OR
        scope = 'all'
    )
);

COMMENT ON TABLE discount_codes IS
    'Core platform feature (DEC-22). Merchant-created discount codes. '
    'Supports percentage and fixed-amount discounts with scope, usage '
    'limits, validity windows, and minimum order thresholds. '
    'redemption_count is denormalised for fast checkout validation. '
    'code is stored UPPERCASE; app-layer normalises before insert/lookup.';

CREATE UNIQUE INDEX idx_discount_codes_code
    ON discount_codes (code);
-- Rationale: Checkout resolves the discount code by code string.
-- Must be O(1) and unique. Most critical index on this table.

CREATE INDEX idx_discount_codes_active_window
    ON discount_codes (is_active, valid_from, valid_to)
    WHERE is_active = TRUE;
-- Rationale: Admin discount list filters to active codes within their
-- validity window. Partial on active codes only.

CREATE INDEX idx_discount_codes_scope_collections
    ON discount_codes USING GIN (scope_collection_ids)
    WHERE scope = 'collection';
-- Rationale: When a collection changes, find all discount codes scoped
-- to it. GIN required for UUID[] array queries. Partial on collection scope.

CREATE INDEX idx_discount_codes_scope_products
    ON discount_codes USING GIN (scope_product_ids)
    WHERE scope = 'product';
-- Rationale: Same pattern as collections — find codes scoped to a product.
```

---

### Table: `discount_code_redemptions`

```sql
-- Core platform feature (DEC-22): created at tenant provisioning.
-- ============================================================
-- TABLE: discount_code_redemptions
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per discount code use. Enforces per-consumer and
--   total usage limits. Provides the audit trail for all discount
--   applications across the merchant's order history.
--
-- BUSINESS RULES:
--   1. One row per (discount_code_id, order_id). A code can only be
--      applied to an order once. Enforced by UNIQUE constraint.
--   2. consumer_id is nullable — guest checkout orders have no
--      registered consumer_id. Per-consumer usage limit enforcement
--      for guest orders is not possible at the DB level; the application
--      enforces it via email address matching where available.
--   3. discount_applied_minor is the actual discount amount deducted
--      from this order in minor currency units. For percentage codes
--      this may differ from code to code (percentage of cart total).
--      Snapshotted at the time of redemption.
--   4. Redemptions are never deleted — they are the audit trail.
--      If an order is refunded, the redemption row is retained.
--      The usage count on discount_codes is NOT decremented on refund
--      (the code was used regardless of refund outcome).
-- ============================================================

CREATE TABLE discount_code_redemptions (
    redemption_id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    discount_code_id       UUID        NOT NULL
                               REFERENCES discount_codes (discount_code_id)
                               ON DELETE RESTRICT,
    -- RESTRICT: never auto-delete redemption history if a code is removed.

    order_id               UUID        NOT NULL,
    -- References orders.order_id (base schema). Plain UUID — app validates.

    consumer_id            UUID,
    -- References consumers.consumer_id (base schema). NULL for guest orders.
    -- Plain UUID — app validates.

    discount_applied_minor BIGINT      NOT NULL CHECK (discount_applied_minor > 0),
    -- Actual discount deducted in minor currency units. Snapshotted.

    currency_code          CHAR(3)     NOT NULL,

    redeemed_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT discount_code_redemptions_unique_per_order
        UNIQUE (discount_code_id, order_id)
);

COMMENT ON TABLE discount_code_redemptions IS
    'Core platform feature (DEC-22). One row per discount code use. '
    'Audit trail for all discount applications. Never deleted — retained '
    'even on order refund. discount_applied_minor snapshotted at redemption. '
    'consumer_id nullable for guest checkout orders.';

CREATE INDEX idx_discount_code_redemptions_code
    ON discount_code_redemptions (discount_code_id, redeemed_at DESC);
-- Rationale: Usage analytics per code — redemption count and trend over time.
-- Also used by the per-consumer usage limit check at checkout.

CREATE INDEX idx_discount_code_redemptions_consumer
    ON discount_code_redemptions (consumer_id, discount_code_id)
    WHERE consumer_id IS NOT NULL;
-- Rationale: Per-consumer usage limit enforcement at checkout:
-- "has this consumer already used this code N times?"

CREATE INDEX idx_discount_code_redemptions_order
    ON discount_code_redemptions (order_id);
-- Rationale: Order detail view displays the discount code applied.
```

---

## Feature: Abandoned Cart Recovery

**Feature ID:** Core platform feature (DEC-22) — table provisioned at signup.

---

### Table: `abandoned_cart_jobs`

```sql
-- Core platform feature (DEC-22): created at tenant provisioning.
-- ============================================================
-- TABLE: abandoned_cart_jobs
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Tracks pending and dispatched abandoned cart recovery
--   email jobs per consumer session. One row per session that
--   enters the abandoned cart recovery pipeline. Prevents duplicate
--   recovery emails and tracks which reminder tier has been sent.
--
-- BUSINESS RULES:
--   1. A session enters the pipeline when it has an active cart
--      (at least one item) and the consumer has not completed
--      checkout after the configured first_reminder_delay_hours
--      from the last cart modification.
--   2. recovery_status tracks the pipeline state:
--      'pending'        — cart abandoned; first reminder not yet sent
--      'first_sent'     — first reminder email dispatched
--      'second_sent'    — second reminder email dispatched (if configured)
--      'recovered'      — consumer completed checkout (order placed)
--      'expired'        — recovery window elapsed with no conversion
--      'suppressed'     — consumer opted out or merchant disabled mid-campaign
--   3. cart_snapshot JSONB is a point-in-time capture of the cart
--      contents at the time the abandonment was detected. It is used
--      to render the cart contents in the recovery email and to link
--      back to specific products. It does NOT affect live inventory.
--   4. A recovery_discount_code_id may be set when the merchant
--      has configured abandoned cart recovery to include a discount code.
--      References discount_codes. Plain UUID — app validates.
--   5. consumer_id is nullable — recovery emails can be sent to a
--      guest's email address if captured at checkout step 1.
--   6. One row per session_token. A new cart in the same session
--      updates the existing row rather than creating a new one.
-- ============================================================

CREATE TABLE abandoned_cart_jobs (
    job_id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    session_token             TEXT        NOT NULL UNIQUE,
    -- References consumer_sessions.session_token (base schema).
    -- Application-layer join only — no DB FK.

    consumer_id               UUID,
    -- References consumers.consumer_id. NULL for fully anonymous guests.
    -- Plain UUID — app validates.

    consumer_email            TEXT,
    -- Email address for recovery email dispatch. May be guest email
    -- captured at checkout step 1, or the registered consumer's email.
    -- NULL only if no email has been captured (cannot send recovery email).

    cart_snapshot             JSONB       NOT NULL,
    -- Point-in-time cart contents at abandonment detection.
    -- Schema: {"items": [{"variant_id": "...", "quantity": N, "price_minor": N, "title": "..."}],
    --           "subtotal_minor": N, "currency_code": "USD"}
    -- Used for email rendering only — does not affect live inventory.

    cart_value_minor          BIGINT      NOT NULL CHECK (cart_value_minor > 0),
    -- Total cart value in minor currency units at detection time.
    -- Denormalised from cart_snapshot for fast analytics queries.

    currency_code             CHAR(3)     NOT NULL,

    recovery_status           VARCHAR(20) NOT NULL DEFAULT 'pending'
                                  CHECK (recovery_status IN (
                                      'pending', 'first_sent', 'second_sent',
                                      'recovered', 'expired', 'suppressed'
                                  )),

    recovery_discount_code_id UUID,
    -- References discount_codes.discount_code_id. Plain UUID.
    -- NULL if no discount is attached to this recovery campaign instance.

    first_email_sent_at       TIMESTAMPTZ,
    -- When the first recovery email was dispatched. NULL until sent.

    second_email_sent_at      TIMESTAMPTZ,
    -- When the second recovery email was dispatched. NULL until sent
    -- or if second reminder is not configured.

    recovered_at              TIMESTAMPTZ,
    -- When the consumer placed an order (recovery_status → 'recovered').
    -- NULL until recovered.

    abandoned_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- When the abandonment was first detected.

    updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE abandoned_cart_jobs IS
    'Core platform feature (DEC-22). Tracks abandoned cart recovery pipeline '
    'per consumer session. One row per session_token. Cart snapshot stored for '
    'email rendering — does not affect live inventory. recovery_status drives '
    'the Cloud Tasks email dispatch pipeline.';

CREATE UNIQUE INDEX idx_abandoned_cart_jobs_session
    ON abandoned_cart_jobs (session_token);
-- Rationale: Cart modification events upsert to this table by session_token.
-- Must be O(1) lookup for every cart update event.

CREATE INDEX idx_abandoned_cart_jobs_status_pending
    ON abandoned_cart_jobs (recovery_status, abandoned_at ASC)
    WHERE recovery_status IN ('pending', 'first_sent');
-- Rationale: Cloud Tasks scheduler queries for jobs whose next email
-- trigger time has elapsed. Partial on actionable statuses only.

CREATE INDEX idx_abandoned_cart_jobs_consumer
    ON abandoned_cart_jobs (consumer_id, abandoned_at DESC)
    WHERE consumer_id IS NOT NULL;
-- Rationale: Consumer account view shows recent abandoned carts.
-- Partial on registered consumers (excludes anonymous guests).
```

---

## Feature: Dynamic Pricing Engine

**Feature ID:** Core platform feature (DEC-22) — tables provisioned at signup.

---

### Table: `dynamic_pricing_rules`

```sql
-- Core platform feature (DEC-22): created at tenant provisioning.
-- ============================================================
-- TABLE: dynamic_pricing_rules
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Merchant-configured automatic pricing rules. Three rule
--   types: stock-age markdown, velocity-based surge, and time-triggered
--   flash sale. Rules fire on schedule via Cloud Tasks.
--
-- BUSINESS RULES:
--   1. rule_type determines the trigger condition and adjustment logic:
--      'stock_age_markdown' — reduce price progressively as stock ages.
--        Required conditions JSONB keys: min_days_in_stock, markdown_pct
--      'velocity_surge'    — increase price when sales velocity exceeds threshold.
--        Required conditions JSONB keys: units_sold_per_day_threshold, surge_pct
--      'flash_sale'        — reduce price for a fixed datetime window.
--        Required fields: sale_start_at, sale_end_at. Conditions JSONB: sale_pct
--   2. scope controls which products the rule applies to:
--      'all'        — entire catalogue
--      'collection' — scope_collection_ids
--      'product'    — scope_product_ids
--      'variant'    — scope_variant_ids
--   3. conditions JSONB holds rule-type-specific trigger parameters.
--      Schema documented per rule_type in column comment.
--   4. adjustment_pct is the price adjustment percentage.
--      Positive = price increase. Negative = price reduction.
--      For flash_sale this is always negative (discount).
--   5. Flash sale rules: sale_start_at and sale_end_at define the
--      exact window. Cloud Tasks creates two jobs: one to apply the
--      rule at sale_start_at, one to revert at sale_end_at.
--   6. is_active = FALSE suspends the rule without deleting it.
--      Historical dynamic_pricing_events are preserved.
--   7. max_adjustments_per_day limits how frequently a stock_age or
--      velocity rule fires on the same product in a 24-hour window.
--      NULL = no limit.
-- ============================================================

CREATE TABLE dynamic_pricing_rules (
    rule_id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    name                   TEXT        NOT NULL
                               CHECK (char_length(name) BETWEEN 1 AND 200),

    rule_type              VARCHAR(24) NOT NULL
                               CHECK (rule_type IN (
                                   'stock_age_markdown',
                                   'velocity_surge',
                                   'flash_sale'
                               )),

    scope                  VARCHAR(16) NOT NULL DEFAULT 'all'
                               CHECK (scope IN ('all', 'collection', 'product', 'variant')),

    scope_collection_ids   UUID[],
    scope_product_ids      UUID[],
    scope_variant_ids      UUID[],

    conditions             JSONB       NOT NULL DEFAULT '{}',
    -- Rule-type-specific trigger parameters. Examples:
    -- stock_age_markdown: {"min_days_in_stock": 30, "markdown_pct": 10}
    -- velocity_surge:     {"units_sold_per_day_threshold": 50, "surge_pct": 5}
    -- flash_sale:         {"sale_pct": 20}

    adjustment_pct         DECIMAL(6, 2) NOT NULL,
    -- Positive = price increase. Negative = price reduction.
    -- Range: -99.99 to +100.00 enforced at application layer.
    -- flash_sale rules must have adjustment_pct < 0.

    -- Flash sale timing (only for rule_type = 'flash_sale')
    sale_start_at          TIMESTAMPTZ,
    sale_end_at            TIMESTAMPTZ,

    max_adjustments_per_day INTEGER    CHECK (max_adjustments_per_day >= 1),
    -- NULL = unlimited adjustments per day.
    -- Relevant for stock_age_markdown and velocity_surge rules only.

    is_active              BOOLEAN     NOT NULL DEFAULT TRUE,

    created_by             UUID        NOT NULL,
    -- staff_user_id. Plain UUID.

    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT dynamic_pricing_rules_flash_sale_dates_required CHECK (
        rule_type != 'flash_sale'
        OR (sale_start_at IS NOT NULL AND sale_end_at IS NOT NULL)
    ),

    CONSTRAINT dynamic_pricing_rules_flash_sale_date_order CHECK (
        sale_end_at IS NULL OR sale_start_at IS NULL
        OR sale_end_at > sale_start_at
    ),

    CONSTRAINT dynamic_pricing_rules_flash_sale_negative_adjustment CHECK (
        rule_type != 'flash_sale' OR adjustment_pct < 0
    ),

    CONSTRAINT dynamic_pricing_rules_scope_ids_required CHECK (
        (scope = 'collection' AND scope_collection_ids IS NOT NULL) OR
        (scope = 'product'    AND scope_product_ids    IS NOT NULL) OR
        (scope = 'variant'    AND scope_variant_ids    IS NOT NULL) OR
        scope = 'all'
    )
);

COMMENT ON TABLE dynamic_pricing_rules IS
    'Core platform feature (DEC-22). Merchant-configured automatic pricing rules. '
    'Three types: stock_age_markdown, velocity_surge, flash_sale. '
    'Flash sales require sale_start_at/sale_end_at and must have negative adjustment_pct. '
    'Cloud Tasks fires rule execution at schedule_time or sale_start_at/sale_end_at. '
    'scope controls which products/variants/collections the rule applies to.';

CREATE INDEX idx_dynamic_pricing_rules_active_type
    ON dynamic_pricing_rules (rule_type, is_active)
    WHERE is_active = TRUE;
-- Rationale: Pricing engine job fetches all active rules of a given type.
-- Partial on active rules only.

CREATE INDEX idx_dynamic_pricing_rules_flash_sale_window
    ON dynamic_pricing_rules (sale_start_at, sale_end_at)
    WHERE rule_type = 'flash_sale' AND is_active = TRUE;
-- Rationale: Cloud Tasks scheduler enqueues flash sale start/end jobs by
-- looking for rules whose window has not yet been processed. Partial on
-- active flash sale rules only.

CREATE INDEX idx_dynamic_pricing_rules_scope_collections
    ON dynamic_pricing_rules USING GIN (scope_collection_ids)
    WHERE scope = 'collection';

CREATE INDEX idx_dynamic_pricing_rules_scope_variants
    ON dynamic_pricing_rules USING GIN (scope_variant_ids)
    WHERE scope = 'variant';
```

---

### Table: `dynamic_pricing_events`

```sql
-- Core platform feature (DEC-22): created at tenant provisioning.
-- ============================================================
-- TABLE: dynamic_pricing_events
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Append-only log of every automatic price change made by
--   a dynamic pricing rule. Provides full price change audit trail
--   and feeds the pricing rule performance analytics in BigQuery.
--
-- BUSINESS RULES:
--   1. Append-only. No UPDATE. No DELETE.
--   2. One row per (variant_id, rule execution). A single rule
--      execution that adjusts 500 variants creates 500 rows.
--   3. old_price_minor and new_price_minor are in minor currency
--      units. They are snapshotted from variants.price at the time
--      of rule execution — not computed from the rule's adjustment_pct
--      (which may have changed since the event).
--   4. revert_event_id is set when this row records a price reversion
--      (e.g. a flash sale ending). It references the original
--      price-change event that is being reverted, enabling clean
--      event-pair linkage in analytics.
-- ============================================================

CREATE TABLE dynamic_pricing_events (
    pricing_event_id   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    rule_id            UUID        NOT NULL,
    -- References dynamic_pricing_rules.rule_id. Plain UUID — no DB FK
    -- (rule may be deleted after event is logged; history must survive).

    variant_id         UUID        NOT NULL,
    -- References variants.variant_id. Plain UUID — same reason as rule_id.

    old_price_minor    BIGINT      NOT NULL CHECK (old_price_minor >= 0),
    new_price_minor    BIGINT      NOT NULL CHECK (new_price_minor >= 0),

    currency_code      CHAR(3)     NOT NULL,

    adjustment_pct_applied DECIMAL(6, 2) NOT NULL,
    -- The exact adjustment_pct from the rule at execution time. Snapshotted.

    revert_event_id    UUID,
    -- References dynamic_pricing_events.pricing_event_id.
    -- Set when this event is a reversion of a prior price-change event.
    -- NULL for original change events.

    triggered_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE dynamic_pricing_events IS
    'Core platform feature (DEC-22). Append-only log of automatic price changes. '
    'No UPDATE, no DELETE ever. One row per (variant, rule execution). '
    'revert_event_id links a price reversion to its original change event. '
    'Feeds BigQuery pricing rule performance analytics (ROI, GMV impact).';

CREATE INDEX idx_dynamic_pricing_events_rule
    ON dynamic_pricing_events (rule_id, triggered_at DESC);
-- Rationale: Pricing rule analytics — "all price changes triggered by this rule".

CREATE INDEX idx_dynamic_pricing_events_variant
    ON dynamic_pricing_events (variant_id, triggered_at DESC);
-- Rationale: Product price history — "all automatic price changes for this variant".

CREATE INDEX idx_dynamic_pricing_events_triggered_at
    ON dynamic_pricing_events (triggered_at DESC);
-- Rationale: Platform-wide pricing audit — "all price changes in the last 24 hours".
```

---

## Feature: Subscription / Recurring Orders

**Feature ID:** `subscription_orders`
**Alembic dependency chain:** none (standalone)
**Phase 2 config keys:** `subscriber_discount_pct`, `allowed_frequencies`

---

### Table: `subscription_plans`

```sql
-- Feature-gated: created by Migration Runner on feature activation
-- ============================================================
-- TABLE: subscription_plans
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Merchant-configured recurring order plans. Defines the
--   frequencies and subscriber discount available to consumers when
--   they subscribe to eligible products.
--
-- BUSINESS RULES:
--   1. Frequencies are stored as a JSONB array of strings matching
--      the allowed_frequencies config key values:
--      'weekly' | 'biweekly' | 'monthly' | 'quarterly'
--   2. eligible_product_ids: when non-empty, only these products can
--      be subscribed to under this plan. Empty array = all products
--      with subscriptions enabled are eligible.
--   3. subscriber_discount_pct is the percentage discount applied
--      at checkout for subscribers. 0 = no discount.
--   4. is_active = FALSE hides the plan from new subscriptions.
--      Existing subscriptions on this plan continue unaffected.
--   5. One merchant may have multiple plans (e.g. "Starter" with
--      monthly only, "Flexible" with all frequencies + higher discount).
-- ============================================================

CREATE TABLE subscription_plans (
    plan_id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    name                     TEXT        NOT NULL
                                 CHECK (char_length(name) BETWEEN 1 AND 200),

    eligible_product_ids     UUID[]      NOT NULL DEFAULT '{}',
    -- Empty array = all subscription-eligible products apply.

    allowed_frequencies      JSONB       NOT NULL,
    -- Array of frequency strings. Example: ["weekly", "monthly", "quarterly"]

    subscriber_discount_pct  DECIMAL(6, 2) NOT NULL DEFAULT 0
                                 CHECK (subscriber_discount_pct >= 0
                                    AND subscriber_discount_pct <= 100),

    is_active                BOOLEAN     NOT NULL DEFAULT TRUE,

    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE subscription_plans IS
    'Feature-gated (subscription_orders). Merchant-configured subscription plans. '
    'allowed_frequencies is a JSONB array of frequency strings. '
    'eligible_product_ids empty array = all subscription-eligible products.';

CREATE INDEX idx_subscription_plans_active
    ON subscription_plans (is_active)
    WHERE is_active = TRUE;

CREATE INDEX idx_subscription_plans_products
    ON subscription_plans USING GIN (eligible_product_ids)
    WHERE array_length(eligible_product_ids, 1) > 0;
-- Rationale: PDP checks which plans are eligible for a specific product.
```

---

### Table: `subscriptions`

```sql
-- Feature-gated: created by Migration Runner on feature activation
-- ============================================================
-- TABLE: subscriptions
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per active consumer subscription. Tracks the
--   plan, variant, frequency, next order date, and billing state.
--
-- BUSINESS RULES:
--   1. consumer_id references consumers (base schema). DB FK valid.
--      CASCADE: GDPR erasure removes the consumer's subscriptions.
--   2. variant_id is the subscribed variant. Plain UUID — subscription
--      history must survive variant archiving.
--   3. subscription_status lifecycle:
--      'active'    — next order will fire on next_order_at
--      'paused'    — consumer has paused; next_order_at frozen
--      'cancelled' — consumer or merchant cancelled; terminal state
--      'expired'   — subscription reached its configured end date
--   4. next_order_at is advanced by the billing cycle duration on
--      every successful recurring order placement. The Cloud Tasks
--      job that fires the recurring order also advances this value.
--   5. stripe_payment_method_id is the Stripe saved payment method
--      used for recurring billing. Plain text reference — Stripe
--      holds the actual method; KloudShop stores only the ID.
-- ============================================================

CREATE TABLE subscriptions (
    subscription_id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    consumer_id              UUID        NOT NULL
                                 REFERENCES consumers (consumer_id)
                                 ON DELETE CASCADE,

    plan_id                  UUID        NOT NULL,
    -- References subscription_plans.plan_id. Plain UUID — history
    -- must survive plan archiving.

    variant_id               UUID        NOT NULL,
    -- References variants.variant_id. Plain UUID — same reason.

    frequency                VARCHAR(20) NOT NULL
                                 CHECK (frequency IN (
                                     'weekly', 'biweekly', 'monthly', 'quarterly'
                                 )),

    quantity                 INTEGER     NOT NULL DEFAULT 1
                                 CHECK (quantity >= 1),

    subscription_status      VARCHAR(16) NOT NULL DEFAULT 'active'
                                 CHECK (subscription_status IN (
                                     'active', 'paused', 'cancelled', 'expired'
                                 )),

    next_order_at            TIMESTAMPTZ,
    -- The scheduled date/time of the next recurring order placement.
    -- NULL when subscription_status is 'cancelled' or 'expired'.

    started_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    paused_at                TIMESTAMPTZ,
    cancelled_at             TIMESTAMPTZ,

    stripe_payment_method_id TEXT,
    -- Stripe payment method ID for recurring billing. Plain text.
    -- NULL until consumer completes first subscription checkout.

    shipping_address_id      UUID,
    -- References consumer_addresses.address_id (base schema). Plain UUID.
    -- The delivery address for recurring orders. NULL = use default at order time.

    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE subscriptions IS
    'Feature-gated (subscription_orders). One row per active consumer subscription. '
    'next_order_at advanced by Cloud Tasks on each successful recurring order placement. '
    'CASCADE on consumer_id (GDPR erasure path).';

CREATE INDEX idx_subscriptions_consumer
    ON subscriptions (consumer_id, subscription_status);
-- Rationale: Consumer account panel shows all subscriptions.

CREATE INDEX idx_subscriptions_status
    ON subscriptions (subscription_status);
-- Rationale: Admin dashboard and metrics aggregation group by subscription_status.

CREATE INDEX idx_subscriptions_next_order
    ON subscriptions (next_order_at ASC)
    WHERE subscription_status = 'active';
-- Rationale: Cloud Tasks recurring order job fetches subscriptions
-- whose next_order_at <= NOW(). Partial on active subscriptions only.

CREATE INDEX idx_subscriptions_variant
    ON subscriptions (variant_id, subscription_status);
-- Rationale: Product admin shows subscriber count per variant.
```

---

### Table: `subscription_orders`

```sql
-- Feature-gated: created by Migration Runner on feature activation
-- ============================================================
-- TABLE: subscription_orders
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Links recurring orders back to their parent subscription
--   for analytics and operational tracking. One row per recurring
--   order placed by the subscription billing system.
--
-- BUSINESS RULES:
--   1. order_id references orders (base schema). Plain UUID — app validates.
--   2. subscription_id references subscriptions. Plain UUID — same reason.
--   3. billing_attempt_number is 1 for the first recurring charge,
--      incrementing for each subsequent charge. Used to track
--      subscription age and lifetime value in analytics.
-- ============================================================

CREATE TABLE subscription_orders (
    subscription_order_id    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    subscription_id          UUID        NOT NULL,
    -- References subscriptions.subscription_id. Plain UUID.

    order_id                 UUID        NOT NULL UNIQUE,
    -- References orders.order_id. Plain UUID. UNIQUE: one subscription_order
    -- per order — recurring orders are always tied to exactly one subscription.

    billing_attempt_number   INTEGER     NOT NULL CHECK (billing_attempt_number >= 1),
    -- 1 = first recurring charge. Increments on each successful billing cycle.

    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE subscription_orders IS
    'Feature-gated (subscription_orders). Links recurring orders to their parent '
    'subscription. billing_attempt_number tracks subscription age in analytics.';

CREATE INDEX idx_subscription_orders_subscription
    ON subscription_orders (subscription_id, created_at DESC);
-- Rationale: Subscription order history — all orders for a subscription.

CREATE INDEX idx_subscription_orders_order
    ON subscription_orders (order_id);
-- Rationale: Order detail view links to its parent subscription if applicable.
```

---

## Feature: Gift Cards & Store Credit

**Feature ID:** `gift_cards`
**Alembic dependency chain:** none (standalone)

---

### Table: `gift_cards`

```sql
-- Feature-gated: created by Migration Runner on feature activation
-- ============================================================
-- TABLE: gift_cards
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Issued gift cards and store credit balances. One row
--   per gift card. Gift cards are digital-only — KloudShop does not
--   manage physical card printing or hardware.
--
-- BUSINESS RULES:
--   1. code is the alphanumeric redemption code shown to the
--      recipient. Must be globally unique within the tenant.
--      Stored UPPERCASE. Generated by the platform at issue time
--      using a cryptographically random function (not sequential).
--   2. card_type distinguishes gift cards from store credit:
--      'gift_card'    — purchased by a consumer and optionally gifted
--      'store_credit' — issued by the merchant (return, compensation, etc.)
--   3. balance_minor / initial_balance_minor are in minor currency units.
--      balance_minor is decremented on each redemption and must not
--      go below zero (enforced by CHECK).
--   4. is_active = FALSE disables the card (merchant or fraud block).
--      Redemptions against inactive cards are rejected at checkout.
--   5. expires_at: NULL = no expiry. Checkout validates expiry before
--      applying the gift card.
--   6. issued_to_consumer_id: the consumer who purchased or received
--      this card. NULL for store credit not linked to a specific consumer,
--      or for gift cards emailed to a non-registered recipient.
--   7. issued_to_email: the email address the gift card notification
--      was sent to. May be a guest email or a registered consumer's email.
-- ============================================================

CREATE TABLE gift_cards (
    gift_card_id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    code                     TEXT        NOT NULL
                                 CHECK (char_length(code) BETWEEN 8 AND 64),
    -- Alphanumeric redemption code. Stored UPPERCASE. Unique within tenant.

    card_type                VARCHAR(16) NOT NULL
                                 CHECK (card_type IN ('gift_card', 'store_credit')),

    initial_balance_minor    BIGINT      NOT NULL CHECK (initial_balance_minor > 0),
    -- Balance at time of issuance. Never changes after creation.

    balance_minor            BIGINT      NOT NULL CHECK (balance_minor >= 0),
    -- Current redeemable balance. Decremented on each redemption.
    -- Reconciled against gift_card_transactions nightly.

    currency_code            CHAR(3)     NOT NULL,

    is_active                BOOLEAN     NOT NULL DEFAULT TRUE,

    expires_at               TIMESTAMPTZ,
    -- NULL = no expiry. Checkout validates before applying.

    issued_to_consumer_id    UUID,
    -- References consumers.consumer_id. Plain UUID. NULL if not linked.

    issued_to_email          TEXT,
    -- Email address the gift card notification was sent to. May be guest email.

    issued_by                UUID,
    -- staff_user_id for store_credit issuances. NULL for gift_card purchases
    -- (system-issued on order confirmation). Plain UUID.

    issued_order_id          UUID,
    -- References orders.order_id for gift cards purchased on storefront.
    -- NULL for store_credit issued manually by a staff member.

    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT gift_cards_code_unique UNIQUE (code)
);

COMMENT ON TABLE gift_cards IS
    'Feature-gated (gift_cards). Issued gift cards and store credit per tenant. '
    'balance_minor decremented on redemption; reconciled nightly against '
    'gift_card_transactions. code is UPPERCASE cryptographically random — '
    'never sequential. Checkout validates is_active and expires_at before applying.';

CREATE UNIQUE INDEX idx_gift_cards_code
    ON gift_cards (code);
-- Rationale: Checkout resolves gift card by code. O(1) required.

CREATE INDEX idx_gift_cards_consumer
    ON gift_cards (issued_to_consumer_id, created_at DESC)
    WHERE issued_to_consumer_id IS NOT NULL;
-- Rationale: Consumer account panel shows their gift cards and store credit.

CREATE INDEX idx_gift_cards_expiring
    ON gift_cards (expires_at ASC, is_active)
    WHERE expires_at IS NOT NULL AND is_active = TRUE;
-- Rationale: Expiry notification job finds cards expiring within N days.
```

---

### Table: `gift_card_transactions`

```sql
-- Feature-gated: created by Migration Runner on feature activation
-- ============================================================
-- TABLE: gift_card_transactions
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Append-only ledger of all gift card balance changes.
--   Every issue, redemption, and refund-to-card event is recorded
--   here. The balance on gift_cards is reconciled against this table.
--
-- BUSINESS RULES:
--   1. Append-only. No UPDATE. No DELETE. Ever.
--   2. transaction_type covers all balance-change scenarios:
--      'issue'         — initial balance on card creation
--      'redeem'        — partial or full redemption at checkout
--      'refund_to_card'— refund credited back to the gift card
--      'expire'        — balance zeroed on card expiry
--      'adjust'        — manual merchant adjustment
--   3. amount_minor is always positive — the direction of the
--      balance change is implicit in transaction_type.
--   4. balance_after_minor is the gift card balance immediately
--      after this transaction. Enables point-in-time balance
--      reconstruction without a full scan.
--   5. order_id is set for 'redeem' and 'refund_to_card' transactions.
--      NULL for 'issue', 'expire', 'adjust'.
-- ============================================================

CREATE TABLE gift_card_transactions (
    gc_transaction_id    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    gift_card_id         UUID        NOT NULL
                             REFERENCES gift_cards (gift_card_id)
                             ON DELETE RESTRICT,
    -- RESTRICT: gift card deletion is not supported — archive via is_active.

    transaction_type     VARCHAR(20) NOT NULL
                             CHECK (transaction_type IN (
                                 'issue', 'redeem', 'refund_to_card',
                                 'expire', 'adjust'
                             )),

    amount_minor         BIGINT      NOT NULL CHECK (amount_minor > 0),
    -- Always positive. Direction determined by transaction_type.

    balance_after_minor  BIGINT      NOT NULL CHECK (balance_after_minor >= 0),
    -- Balance snapshot immediately after this transaction.

    currency_code        CHAR(3)     NOT NULL,

    order_id             UUID,
    -- References orders.order_id. Plain UUID. Set for redeem/refund_to_card.

    notes                TEXT,
    -- Optional description for 'adjust' transactions.

    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE gift_card_transactions IS
    'Feature-gated (gift_cards). Append-only gift card balance ledger. '
    'No UPDATE, no DELETE ever. balance_after_minor enables point-in-time '
    'balance reconstruction. amount_minor is always positive; direction '
    'is determined by transaction_type.';

CREATE INDEX idx_gift_card_transactions_card
    ON gift_card_transactions (gift_card_id, created_at DESC);
-- Rationale: Gift card transaction history in merchant admin and consumer account.

CREATE INDEX idx_gift_card_transactions_order
    ON gift_card_transactions (order_id)
    WHERE order_id IS NOT NULL;
-- Rationale: Order detail view shows gift card redemptions applied to the order.
```

---

## Feature: Bundle Builder

**Feature ID:** `bundle_builder`
**Alembic dependency chain:** none (standalone)

---

### Table: `bundle_definitions`

```sql
-- Feature-gated: created by Migration Runner on feature activation
-- ============================================================
-- TABLE: bundle_definitions
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Merchant-defined product bundles. A bundle groups multiple
--   product variants together at a single bundle price, with optional
--   per-component swappability for consumer choice.
--
-- BUSINESS RULES:
--   1. bundle_price_minor is the total price for the complete bundle
--      in minor currency units. It must be less than the sum of
--      individual component prices to provide a meaningful discount.
--      This constraint is enforced at the application layer (the DB
--      cannot efficiently compute the component sum at INSERT time).
--   2. is_active = FALSE hides the bundle from the storefront without
--      deleting its definition. Existing orders containing bundles
--      are unaffected.
--   3. The bundle is listed on the storefront as a single product
--      unit. When added to cart, each component is added as a
--      separate order_item tagged with the bundle_definition_id
--      for analytics purposes. The aggregate bundle price is applied
--      as a line-item discount in the order totals.
--   4. stock is tracked per component variant — not at the bundle
--      level. A bundle becomes unavailable when any required (non-
--      swappable) component is out of stock.
-- ============================================================

CREATE TABLE bundle_definitions (
    bundle_definition_id     UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    name                     TEXT        NOT NULL
                                 CHECK (char_length(name) BETWEEN 1 AND 300),

    description              TEXT,
    -- Optional marketing description shown on the bundle PDP.

    bundle_price_minor       BIGINT      NOT NULL CHECK (bundle_price_minor > 0),
    -- Total bundle price in minor currency units.

    currency_code            CHAR(3)     NOT NULL,

    is_active                BOOLEAN     NOT NULL DEFAULT TRUE,

    image_url                TEXT,
    -- Optional Cloud Storage CDN URL for a bundle-specific image.
    -- NULL = use the first component's primary image as the bundle image.

    created_by               UUID        NOT NULL,
    -- staff_user_id. Plain UUID.

    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE bundle_definitions IS
    'Feature-gated (bundle_builder). Merchant-defined product bundles. '
    'bundle_price_minor must be less than sum of component prices (app-layer enforced). '
    'Stock tracked per component variant — bundle unavailable when any required '
    'component is out of stock. Bundle adds each component as a separate order_item '
    'tagged with bundle_definition_id for analytics.';

CREATE INDEX idx_bundle_definitions_active
    ON bundle_definitions (is_active, updated_at DESC)
    WHERE is_active = TRUE;
-- Rationale: Storefront bundle listing queries active bundles.
```

---

### Table: `bundle_components`

```sql
-- Feature-gated: created by Migration Runner on feature activation
-- ============================================================
-- TABLE: bundle_components
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Individual component rows per bundle definition. Each
--   component is a specific variant (or a set of swappable variant
--   options) that makes up the bundle.
--
-- BUSINESS RULES:
--   1. When is_swappable = FALSE, variant_id is the fixed component.
--      The consumer cannot substitute it.
--   2. When is_swappable = TRUE, variant_id is the default option and
--      swappable_variant_ids lists the alternatives the consumer may
--      choose from. variant_id must also appear in swappable_variant_ids
--      (or be the only option). Application enforces this at wizard time.
--   3. quantity is how many units of the component variant are included
--      in the bundle (e.g. "3 pairs of socks" in a socks bundle).
--   4. display_order controls the order in which components appear on
--      the bundle PDP. Lower = shown first.
--   5. sort_order on bundle_definitions is independent — it controls
--      the order bundles appear in a collection, not within the bundle.
-- ============================================================

CREATE TABLE bundle_components (
    bundle_component_id      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    bundle_definition_id     UUID        NOT NULL
                                 REFERENCES bundle_definitions (bundle_definition_id)
                                 ON DELETE CASCADE,
    -- CASCADE: deleting a bundle removes its component definitions.

    variant_id               UUID        NOT NULL,
    -- The primary (or default) variant for this component slot.
    -- References variants.variant_id. Plain UUID — must survive variant archiving.

    quantity                 INTEGER     NOT NULL DEFAULT 1
                                 CHECK (quantity >= 1),

    is_swappable             BOOLEAN     NOT NULL DEFAULT FALSE,
    -- FALSE = fixed component; consumer has no choice.
    -- TRUE = consumer may swap to any variant in swappable_variant_ids.

    swappable_variant_ids    UUID[],
    -- List of variant UUIDs the consumer may choose from when is_swappable = TRUE.
    -- NULL when is_swappable = FALSE.
    -- Application validates: when is_swappable = TRUE, this must be non-empty.

    display_order            INTEGER     NOT NULL DEFAULT 0,

    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE bundle_components IS
    'Feature-gated (bundle_builder). Component rows per bundle definition. '
    'is_swappable = TRUE allows consumer to select from swappable_variant_ids. '
    'variant_id is the default (or only) option. quantity specifies units per bundle. '
    'CASCADE on bundle_definition_id.';

CREATE INDEX idx_bundle_components_bundle
    ON bundle_components (bundle_definition_id, display_order);
-- Rationale: Bundle PDP loads all components in display_order.

CREATE INDEX idx_bundle_components_variant
    ON bundle_components (variant_id);
-- Rationale: When a variant is archived, find all bundles containing it
-- to flag them as potentially unavailable.

CREATE INDEX idx_bundle_components_swappable_variants
    ON bundle_components USING GIN (swappable_variant_ids)
    WHERE is_swappable = TRUE;
-- Rationale: When a variant is archived, find all swappable component slots
-- that include it so the admin can update the swap options.
```

---

## Feature: Affiliate & Referral Tracking

**Feature ID:** `affiliate_referral`
**Alembic dependency chain:** none (standalone)

---

### Table: `affiliate_links`

```sql
-- Feature-gated: created by Migration Runner on feature activation
-- ============================================================
-- TABLE: affiliate_links
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Affiliate tracking links. Each row represents one
--   affiliate's unique tracked link to the merchant's storefront.
--   Conversions are attributed when an order is placed within
--   the attribution_window_hours after a tracked click.
--
-- BUSINESS RULES:
--   1. affiliate_code is the unique tracking parameter appended to
--      the storefront URL (e.g. ?aff=JOHNDOE2024). Case-insensitive
--      at checkout; stored UPPERCASE. Unique within tenant.
--   2. commission_type determines how the affiliate earns:
--      'percentage' — commission_value is a percentage of order GMV
--      'flat'       — commission_value is a fixed amount per conversion
--                     in minor currency units
--   3. attribution_window_hours: the number of hours after a click
--      within which a completed order is attributed to this affiliate.
--      Default: 30 days (720 hours). Consumer may close and reopen
--      browser; attribution relies on the cookie persisting.
--   4. Conversion tracking is the application layer's responsibility.
--      A click event is recorded in BigQuery (via storefront_events)
--      when the affiliate_code is detected in the URL. A conversion
--      is recorded when an order is placed within the attribution window.
--      This table defines the affiliate; conversion reporting is in BigQuery.
--   5. affiliate_name and affiliate_email are the affiliate's display
--      name and contact email. These may be an individual or a company.
--   6. is_active = FALSE disables the tracking link. Existing attributed
--      conversions and historical analytics are preserved.
--   7. total_clicks and total_conversions are denormalised counters
--      updated by the application. Reconciled daily against BigQuery.
--      These are convenience fields for the admin affiliate dashboard —
--      not the source of truth (BigQuery is).
-- ============================================================

CREATE TABLE affiliate_links (
    affiliate_link_id        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),

    affiliate_code           TEXT        NOT NULL
                                 CHECK (char_length(affiliate_code) BETWEEN 3 AND 64),
    -- Tracking parameter. Stored UPPERCASE. Unique within tenant.

    affiliate_name           TEXT        NOT NULL
                                 CHECK (char_length(affiliate_name) BETWEEN 1 AND 200),

    affiliate_email          TEXT,
    -- Contact email for commission payouts and communication. Optional.

    commission_type          VARCHAR(16) NOT NULL
                                 CHECK (commission_type IN ('percentage', 'flat')),

    commission_value         DECIMAL(12, 4) NOT NULL
                                 CHECK (commission_value > 0),
    -- For 'percentage': value in percent (e.g. 10.0000 = 10%).
    -- For 'flat': value in minor currency units per conversion.

    currency_code            CHAR(3),
    -- Required when commission_type = 'flat'. NULL for percentage commissions.

    attribution_window_hours INTEGER     NOT NULL DEFAULT 720
                                 CHECK (attribution_window_hours >= 1),
    -- 720 = 30 days. The time window after a click within which an order
    -- is attributed to this affiliate.

    is_active                BOOLEAN     NOT NULL DEFAULT TRUE,

    -- Denormalised analytics counters (reconciled daily against BigQuery)
    total_clicks             BIGINT      NOT NULL DEFAULT 0
                                 CHECK (total_clicks >= 0),
    total_conversions        BIGINT      NOT NULL DEFAULT 0
                                 CHECK (total_conversions >= 0),
    total_commission_earned_minor BIGINT NOT NULL DEFAULT 0
                                 CHECK (total_commission_earned_minor >= 0),
    -- In minor currency units. Accumulated commission across all conversions.

    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT affiliate_links_code_unique UNIQUE (affiliate_code),

    CONSTRAINT affiliate_links_flat_currency_required CHECK (
        commission_type != 'flat' OR currency_code IS NOT NULL
    )
);

COMMENT ON TABLE affiliate_links IS
    'Feature-gated (affiliate_referral). Affiliate tracking links per tenant. '
    'affiliate_code is UPPERCASE and unique within the tenant — appended to storefront URLs. '
    'Conversion attribution window is configurable per affiliate. '
    'total_clicks/conversions are denormalised convenience counters — BigQuery is authoritative. '
    'Commission payouts are handled outside KloudShop (Payoneer or direct bank transfer).';

CREATE UNIQUE INDEX idx_affiliate_links_code
    ON affiliate_links (affiliate_code);
-- Rationale: Storefront edge detects affiliate_code on every request.
-- O(1) resolution is critical for click attribution performance.

CREATE INDEX idx_affiliate_links_active
    ON affiliate_links (is_active, total_conversions DESC)
    WHERE is_active = TRUE;
-- Rationale: Admin affiliate dashboard shows active affiliates sorted
-- by performance (total_conversions DESC). Partial on active only.

CREATE INDEX idx_affiliate_links_email
    ON affiliate_links (affiliate_email)
    WHERE affiliate_email IS NOT NULL;
-- Rationale: Support queries and commission payout workflows find
-- affiliates by email address.
```

---

## BigQuery Gap Tables (Flagged by 06l — Deferred to `06l-addendum`)

The following five tables were identified as analytical gaps in `06l-bigquery-analytics-schema.md` and flagged for `06m` resolution. Per the decision to follow the original `BKP-06-schema-inventory.md` scope for this artifact (Option A), these are noted here for tracking but are **not defined in this artifact**. They will be addressed in a separate `06l-addendum` artifact:

| Gap | Table | Dataset |
|-----|-------|---------|
| Product-level performance analytics | `tenant_{id}_analytics.product_performance_daily` | Merchant |
| Coupon and discount attribution | `tenant_{id}_analytics.coupon_attribution_daily` | Merchant |
| Inventory velocity analytics | `tenant_{id}_analytics.inventory_movement_daily` | Merchant |
| Platform churn signal | `kloudshop_analytics.platform_churn_signals_daily` | Platform |
| Payment method analytics | `tenant_{id}_analytics.payment_method_daily` | Merchant |

---

## Updated Schema Inventory Entry

Apply the following surgical patch to `BKP-06-schema-inventory.md` (or the
actively maintained offline inventory) — replace the `06m` row in the
Generation Progress table:

```
| `06m-tenant-feature-gated-schema.md` | ✅ Generated | 17 | Loyalty Programme (reward_tiers, loyalty_accounts, point_transactions, redemption_events), Discount Engine/DEC-22 core (discount_codes, discount_code_redemptions), Abandoned Cart Recovery/DEC-22 core (abandoned_cart_jobs), Dynamic Pricing Engine/DEC-22 core (dynamic_pricing_rules, dynamic_pricing_events), Subscription Orders (subscription_plans, subscriptions, subscription_orders), Gift Cards (gift_cards, gift_card_transactions), Bundle Builder (bundle_definitions, bundle_components), Affiliate & Referral (affiliate_links). BigQuery gap tables from 06l deferred to 06l-addendum. |
```
