# 06f — Tenant B2B Schema
# KloudShop Stage 6 — Data Model

> **Artifact:** `06f-tenant-b2b-schema.md`
> **Schema:** `tenant_{tenant_id}` (one schema per merchant, provisioned at signup)
> **Persona:** Principal Data Engineer
> **Reads from:** `01-product-brief.md`, `01b-tech-stack.md`, `02-architecture.md`,
>   `03-user-journeys.md`, `04-feature-stories.md`, `04b-mvp-scope.md`,
>   `00-carry-forward-flags.md` (DMF-01 through DMF-10)
> **Depends on:** `06b-tenant-catalog-schema.md` (variants FK on price_list_items),
>   `06c-tenant-orders-schema.md` (orders FK on approval_requests),
>   `06j-tenant-consumer-schema.md` (no direct FK — b2b_accounts are a separate
>   identity population from consumers; forward-declared as plain UUIDs where referenced)
> **Tables:** 6 (b2b_accounts, price_lists, price_list_items, approval_workflows,
>   approval_requests, b2b_invoices)
> **Status:** ✅ Generated

---

## Overview

This artifact defines the B2B wholesale engine schema for a KloudShop merchant
tenant. These six tables are provisioned for **every tenant** at signup as part of
the base Alembic migration — including DTC-only merchants. On a DTC-only tenant the
tables exist but are empty. This avoids a feature-activation migration when a DTC
merchant later upgrades to Hybrid tier.

**Key design decisions reflected in this schema:**

- **`b2b_accounts` is flat — no parent/child company hierarchy** — the product
  brief confirmed a flat structure with `company_name` used for display and reporting
  grouping only. There is no `parent_account_id`, no organisational tree, no
  structural FK to any company entity. A future hierarchy requirement (if it
  emerges post-PMF) will be handled via a new `b2b_account_groups` table added
  through the standard non-destructive migration pipeline — not retrofitted onto
  this table.

- **`b2b_accounts` stores its own Firebase Auth credential reference** — B2B
  buyers authenticate via Firebase Auth (Gmail or email/password — unlike merchant
  staff who are Gmail-only). The `firebase_uid` on the account is the link between
  the Firebase identity and the KloudShop buyer account. One `b2b_account` = one
  buyer contact; a company with multiple buyers has multiple `b2b_accounts` rows,
  each with its own credentials.

- **`net_terms_days` on `b2b_accounts` is the source of truth for the buyer's
  payment terms** — it is snapshotted onto `orders.net_terms_days` at order
  placement (see 06c). Changes to the account's terms never retroactively alter
  existing invoices.

- **`price_lists` and `price_list_items` support both fixed-price and percentage
  discount overrides per variant** — `override_type` drives which column is used.
  Only one override type is valid per row (enforced by CHECK constraints). A price
  list can have a mix of row types (some variants overridden by fixed price, others
  by percentage).

- **`approval_workflows` is one row per tenant** — a single approval configuration
  covering the entire B2B operation. The threshold and assigned roles are configured
  once; all buyer accounts are subject to the same workflow unless the merchant
  configures per-account overrides (post-MVP). At MVP, approval is global.

- **`approval_requests` is the per-order approval record** — one row per order that
  enters the approval workflow. It is linked to `orders.order_id` (plain UUID — same
  schema, no FK constraint needed) and records the full decision audit trail.

- **`b2b_invoices` holds the Stripe Invoice reference** — for net-terms B2B orders,
  the Stripe Invoice ID and payment state are tracked here rather than cluttering
  the core `orders` table with Stripe-specific B2B fields. `orders.stripe_invoice_id`
  is a denormalised reference that is set from this table for fast webhook resolution.

- **All Firebase Auth references are plain TEXT fields** — Firebase UIDs are
  opaque strings, not UUIDs. Stored as TEXT, validated at application layer. No
  FK constraint is possible (Firebase Auth is external to PostgreSQL).

**AI agent note:** B2B buyer authentication uses Firebase Auth with
`account_type: buyer` custom claims (defined in `01b-tech-stack.md`). The claim
carries `tenant_id`, `buyer_account_id`, and `roles: ["buyer"]`. FastAPI validates
the JWT, extracts `buyer_account_id`, and all queries scope to the buyer's own
account rows. Cross-buyer data leakage is architecturally impossible at the
application layer — buyers can only see their own `b2b_account_id`'s data.

---

## Table: `b2b_accounts`

```sql
-- ============================================================
-- TABLE: b2b_accounts
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per B2B buyer contact. Each row represents
--   one individual buyer who can log into the B2B portal.
--   company_name is for display and reporting grouping only —
--   there is no structural company hierarchy table.
--
-- BUSINESS RULES:
--   1. FLAT STRUCTURE — no parent_account_id. company_name is
--      a free-text display field only. Multiple buyers from the
--      same company are separate rows sharing the same
--      company_name string. Grouping in analytics and admin UI
--      is done by matching company_name (case-insensitive).
--      A structural hierarchy table (if ever needed) will be
--      added as a separate non-destructive migration. This
--      table will not be modified.
--   2. firebase_uid is the Firebase Auth UID for this buyer.
--      Set when the buyer completes registration via the
--      invitation link. NULL until the buyer has registered.
--      One firebase_uid per buyer — never shared between rows.
--   3. account_status lifecycle:
--      'invited'          — invitation email sent; buyer has not
--                           yet registered. No portal access.
--      'pending_approval' — buyer has registered but the merchant
--                           has configured manual approval before
--                           granting portal access.
--      'active'           — fully operational. Buyer can log in
--                           and place orders.
--      'suspended'        — temporarily blocked. Buyer cannot log
--                           in or place orders. All existing order
--                           history and credit remain intact.
--      'archived'         — permanently decommissioned. Row retained
--                           for order history. No portal access.
--   4. credit_limit is the maximum outstanding order value this
--      buyer is approved for at any one time. Orders that would
--      push outstanding balance above this threshold trigger the
--      approval workflow regardless of the global threshold.
--      NULL = no credit limit configured (unlimited credit — use
--      with caution; typically set for well-established buyers).
--   5. net_terms_days is the agreed payment terms for this buyer.
--      NULL = immediate payment required (no net terms).
--      Snapshotted onto orders.net_terms_days at order placement.
--      Changes here do NOT retroactively alter existing invoices.
--   6. price_list_id references the price_lists table. The buyer
--      sees their assigned price list at all times on the portal.
--      NULL = buyer sees standard retail pricing (no discount).
--      Application layer enforces the FK at write time.
--      Plain UUID — same schema, but declared without a DB FK
--      constraint to allow price list deletion without blocking
--      on existing buyer assignments. Application validates.
--   7. assigned_account_manager_id is the staff_user_id of the
--      merchant staff member responsible for this buyer account.
--      Plain UUID — cross-schema reference. NULL = unassigned.
-- ============================================================

CREATE TABLE b2b_accounts (
    b2b_account_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- ── Identity ─────────────────────────────────────────────
    company_name             TEXT NOT NULL,
    -- Display name for the buyer's company. Used for grouping in
    -- admin UI and analytics. Not unique — multiple buyers from
    -- the same company will share this value. Free-text.

    contact_first_name       TEXT NOT NULL,
    -- First name of the individual buyer contact.

    contact_last_name        TEXT NOT NULL,
    -- Last name of the individual buyer contact.

    contact_email            TEXT NOT NULL,
    -- Email address. Used for invitation email and as the login
    -- identity for email/password Firebase Auth accounts.
    -- For Google-authenticated buyers this matches their Gmail.
    -- Unique within the tenant — one b2b_account per email.

    contact_phone            TEXT,
    -- Optional phone number for direct contact.

    -- ── Firebase Auth ────────────────────────────────────────
    firebase_uid             TEXT UNIQUE,
    -- Firebase Auth UID for this buyer. Set on first registration.
    -- NULL until the buyer has accepted the invitation and registered.
    -- Never shared between rows. TEXT — Firebase UIDs are opaque strings.

    -- ── Commercial Terms ─────────────────────────────────────
    credit_limit             DECIMAL(12, 2),
    -- Maximum approved outstanding order value (in storefront currency).
    -- NULL = no credit limit. Orders above this trigger approval workflow.
    -- Updated by merchant manually or via B2B Account Manager role.

    net_terms_days           INTEGER,
    -- Agreed payment terms in days. Examples: 30, 60, 90.
    -- NULL = no net terms; immediate payment required.
    -- Snapshotted onto orders.net_terms_days at order placement.

    price_list_id            UUID,
    -- References price_lists.price_list_id. Plain UUID — application validates.
    -- NULL = buyer sees standard retail prices.

    -- ── Status ───────────────────────────────────────────────
    account_status           VARCHAR(20) NOT NULL DEFAULT 'invited',
    -- Lifecycle state. See business rules above.

    -- ── Assignment ───────────────────────────────────────────
    assigned_account_manager_id UUID,
    -- staff_user_id of the assigned B2B Account Manager.
    -- Plain UUID — cross-schema reference to kloudshop_platform.staff_users.
    -- NULL = account is unassigned.

    -- ── Shipping Address ─────────────────────────────────────
    -- Default delivery address for this buyer account. Stored on the
    -- account for pre-fill at checkout. Buyer can override per-order.
    default_address_line1    TEXT,
    default_address_line2    TEXT,
    default_address_city     TEXT,
    default_address_state    TEXT,
    default_address_postcode TEXT,
    default_address_country  CHAR(2),
    -- ISO 3166-1 alpha-2.

    -- ── Internal Notes ───────────────────────────────────────
    notes                    TEXT,
    -- Merchant's internal notes on this buyer account.
    -- Visible to staff with B2B Account Manager role only.

    -- ── Invitation Tracking ──────────────────────────────────
    invited_by               UUID,
    -- staff_user_id who created and sent the invitation. Plain UUID.

    invited_at               TIMESTAMPTZ,
    -- When the invitation email was sent. NULL if account was
    -- created but invitation not yet dispatched.

    registered_at            TIMESTAMPTZ,
    -- When the buyer completed registration. NULL if still 'invited'.

    last_login_at            TIMESTAMPTZ,
    -- When the buyer last authenticated via the B2B portal.

    -- ── Metadata ─────────────────────────────────────────────
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT b2b_accounts_email_unique UNIQUE (contact_email),
    -- One b2b_account per email address per tenant.

    CONSTRAINT b2b_accounts_status_check CHECK (
        account_status IN (
            'invited', 'pending_approval', 'active',
            'suspended', 'archived'
        )
    ),

    CONSTRAINT b2b_accounts_credit_limit_non_negative CHECK (
        credit_limit IS NULL OR credit_limit >= 0
    ),

    CONSTRAINT b2b_accounts_net_terms_positive CHECK (
        net_terms_days IS NULL OR net_terms_days >= 1
    ),

    CONSTRAINT b2b_accounts_registered_requires_uid CHECK (
        -- If registered_at is set, firebase_uid must also be set.
        -- A buyer cannot be considered registered without a Firebase identity.
        registered_at IS NULL OR firebase_uid IS NOT NULL
    )
);

COMMENT ON TABLE b2b_accounts IS
    'One row per B2B buyer contact. Flat structure — company_name is display-only, '
    'no hierarchy table. firebase_uid links to Firebase Auth buyer identity. '
    'net_terms_days snapshotted onto orders at placement — changes here are '
    'not retroactive. credit_limit NULL = unlimited credit.';

CREATE UNIQUE INDEX idx_b2b_accounts_email
    ON b2b_accounts (contact_email);
-- Rationale: Invitation flow checks for duplicate email before sending.
-- Login resolution maps contact_email to b2b_account_id. O(1) required.

CREATE UNIQUE INDEX idx_b2b_accounts_firebase_uid
    ON b2b_accounts (firebase_uid)
    WHERE firebase_uid IS NOT NULL;
-- Rationale: FastAPI resolves b2b_account_id from JWT firebase_uid claim
-- on every authenticated B2B portal request. Partial on registered buyers.

CREATE INDEX idx_b2b_accounts_status
    ON b2b_accounts (account_status, company_name)
    WHERE account_status = 'active';
-- Rationale: B2B account management list defaults to active accounts,
-- grouped visually by company_name. Partial on active accounts only.

CREATE INDEX idx_b2b_accounts_company_name_trgm
    ON b2b_accounts USING GIN (company_name gin_trgm_ops);
-- Rationale: Admin buyer search by company name uses trigram similarity
-- for fuzzy matching. GIN required for ILIKE / similarity queries.

CREATE INDEX idx_b2b_accounts_account_manager
    ON b2b_accounts (assigned_account_manager_id, account_status)
    WHERE assigned_account_manager_id IS NOT NULL;
-- Rationale: B2B Account Manager role sees their own assigned accounts.
-- Partial on assigned accounts only.

CREATE INDEX idx_b2b_accounts_price_list
    ON b2b_accounts (price_list_id)
    WHERE price_list_id IS NOT NULL;
-- Rationale: When a price list is updated or deleted, the application
-- must find all affected buyer accounts. Partial on assigned accounts.
```

---

## Table: `price_lists`

```sql
-- ============================================================
-- TABLE: price_lists
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Named price lists. Each price list is assigned to one
--   or more b2b_accounts. A price list defines a set of per-variant
--   price overrides (fixed price or % discount) that the assigned
--   buyers see instead of standard retail prices.
--
-- BUSINESS RULES:
--   1. A price list with no items (empty price_list_items) is valid.
--      An assigned buyer with no item overrides sees standard prices
--      for all unmatched variants. This is intentional — a price list
--      can be partially configured during setup.
--   2. is_default = TRUE marks the fallback price list used when a
--      buyer has no price_list_id assigned. Only one price list per
--      tenant may have is_default = TRUE. Enforced at application layer.
--      NULL = no default; unassigned buyers see retail prices.
--   3. currency_code must match the merchant's storefront currency.
--      All fixed-price overrides in price_list_items are in this currency.
--      Percentage discount overrides are currency-agnostic.
--   4. effective_from and effective_to allow time-windowed price lists
--      (e.g. "seasonal B2B pricing active from Jan 1 to Mar 31").
--      NULL effective_to = price list never expires.
--      NULL effective_from = price list is immediately active.
--   5. Price list deletion is BLOCKED at application layer if any
--      b2b_accounts have this price_list_id assigned. Admin must
--      reassign those accounts first. Deactivate (is_active = FALSE)
--      as the safe alternative.
-- ============================================================

CREATE TABLE price_lists (
    price_list_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name             TEXT NOT NULL,
    -- Human-readable name shown in admin and on the B2B portal header.
    -- Examples: 'Wholesale Standard', 'VIP Distributor', 'Seasonal Q1'.

    description      TEXT,
    -- Optional internal description of when and why this list is used.

    currency_code    CHAR(3) NOT NULL DEFAULT 'USD',
    -- ISO 4217. All fixed-price overrides in price_list_items use this.

    is_default       BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = fallback list for buyers with no explicit assignment.
    -- Application enforces at most one is_default = TRUE per tenant.

    is_active        BOOLEAN NOT NULL DEFAULT TRUE,
    -- FALSE = price list suspended. Assigned buyers fall back to retail
    -- pricing until a new list is assigned or this one is reactivated.

    effective_from   TIMESTAMPTZ,
    -- Optional activation window start. NULL = immediately active.

    effective_to     TIMESTAMPTZ,
    -- Optional activation window end. NULL = no expiry.

    created_by       UUID NOT NULL,
    -- staff_user_id who created this price list. Plain UUID.

    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT price_lists_currency_length CHECK (
        char_length(currency_code) = 3
    ),

    CONSTRAINT price_lists_effective_dates_check CHECK (
        effective_to IS NULL
        OR effective_from IS NULL
        OR effective_to > effective_from
    )
);

COMMENT ON TABLE price_lists IS
    'Named B2B price lists. Assigned to b2b_accounts. Each list contains '
    'per-variant price overrides (fixed or % discount) in price_list_items. '
    'is_default = fallback for unassigned buyers. Deletion blocked if accounts '
    'are assigned — deactivate instead.';

CREATE INDEX idx_price_lists_active
    ON price_lists (is_active, name)
    WHERE is_active = TRUE;
-- Rationale: Price list selector dropdown in b2b_account editor shows
-- only active lists. Partial index on active lists only.

CREATE INDEX idx_price_lists_default
    ON price_lists (is_default)
    WHERE is_default = TRUE;
-- Rationale: Application resolves the default price list at checkout
-- for buyers without an explicit assignment. Fast single-row lookup.
```

---

## Table: `price_list_items`

```sql
-- ============================================================
-- TABLE: price_list_items
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Per-variant price overrides within a price list. One
--   row per (price_list_id, variant_id). Supports either a fixed
--   price override OR a percentage discount — not both simultaneously.
--
-- BUSINESS RULES:
--   1. One row per (price_list_id, variant_id). Composite PK.
--   2. override_type determines which column is used:
--      'fixed'      — override_price is the buyer's price for this
--                     variant. override_discount_pct must be NULL.
--      'percentage' — override_discount_pct is the discount applied
--                     to the variant's current retail price.
--                     override_price must be NULL.
--      The exclusive constraint is enforced by CHECK constraint below.
--   3. override_price must be > 0 for 'fixed' type.
--      Technically a price of 0.00 would mean "free" — this is
--      intentional and valid for gift or sample orders.
--      Enforced as >= 0 to allow legitimate zero-price items.
--   4. override_discount_pct must be > 0 and <= 100 for 'percentage'.
--      100% = free (full discount). Values above 100 are not valid.
--   5. variant_id uses ON DELETE RESTRICT — if a variant is deleted,
--      the application must clean up price list items first. Archiving
--      the variant (is_active = FALSE) is the safe path.
--   6. Pricing resolution at checkout for a B2B buyer:
--      a. Check if buyer's assigned price_list_id has an item for
--         this variant_id.
--      b. If 'fixed': use override_price directly.
--      c. If 'percentage': buyer_price = retail_price × (1 - pct/100).
--      d. If no item exists: use the variant's standard retail price.
-- ============================================================

CREATE TABLE price_list_items (
    price_list_id          UUID NOT NULL
                           REFERENCES price_lists (price_list_id)
                           ON DELETE CASCADE,
    -- CASCADE: deleting a price list removes all its item overrides.

    variant_id             UUID NOT NULL
                           REFERENCES variants (variant_id)
                           ON DELETE RESTRICT,
    -- RESTRICT: cannot delete a variant with active price list items.

    -- ── Override Type ────────────────────────────────────────
    override_type          VARCHAR(16) NOT NULL DEFAULT 'fixed',
    -- 'fixed' | 'percentage'. Determines which column is authoritative.

    -- ── Fixed Price Override ─────────────────────────────────
    override_price         DECIMAL(12, 2),
    -- The buyer's price for this variant. Used when override_type = 'fixed'.
    -- NULL when override_type = 'percentage'.

    -- ── Percentage Discount Override ─────────────────────────
    override_discount_pct  DECIMAL(6, 3),
    -- Percentage discount off retail price. e.g. 15.000 = 15% off.
    -- Used when override_type = 'percentage'.
    -- NULL when override_type = 'fixed'.

    -- ── Metadata ─────────────────────────────────────────────
    created_by             UUID NOT NULL,
    -- staff_user_id who created or last updated this override. Plain UUID.

    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (price_list_id, variant_id),

    CONSTRAINT price_list_items_override_type_check CHECK (
        override_type IN ('fixed', 'percentage')
    ),

    CONSTRAINT price_list_items_fixed_exclusive CHECK (
        -- For 'fixed' type: override_price must be set, pct must be NULL.
        override_type != 'fixed'
        OR (override_price IS NOT NULL AND override_discount_pct IS NULL)
    ),

    CONSTRAINT price_list_items_percentage_exclusive CHECK (
        -- For 'percentage' type: pct must be set, price must be NULL.
        override_type != 'percentage'
        OR (override_discount_pct IS NOT NULL AND override_price IS NULL)
    ),

    CONSTRAINT price_list_items_override_price_non_negative CHECK (
        override_price IS NULL OR override_price >= 0
    ),

    CONSTRAINT price_list_items_discount_pct_range CHECK (
        override_discount_pct IS NULL
        OR (override_discount_pct > 0 AND override_discount_pct <= 100)
    )
);

COMMENT ON TABLE price_list_items IS
    'Per-variant price overrides within a price list. '
    'override_type = ''fixed'': override_price is used directly. '
    'override_type = ''percentage'': buyer_price = retail × (1 - pct/100). '
    'Exactly one override field must be set per row (CHECK constraints enforce). '
    'Variants with no item use standard retail price at checkout.';

CREATE INDEX idx_price_list_items_price_list
    ON price_list_items (price_list_id, variant_id);
-- Rationale: Checkout pricing resolution loads all items for a buyer's
-- assigned price list to build the variant→price lookup map.
-- Composite PK covers this pattern.

CREATE INDEX idx_price_list_items_variant
    ON price_list_items (variant_id, price_list_id);
-- Rationale: "Which price lists include this variant?" — used when a
-- variant's retail price changes and affected price list items need
-- reviewing (for percentage overrides, the buyer price changes too).
```

---

## Table: `approval_workflows`

```sql
-- ============================================================
-- TABLE: approval_workflows
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Merchant-configured B2B order approval rules. One row
--   per tenant at MVP. Orders that exceed the configured threshold
--   are held for human approval before fulfilment begins.
--
-- BUSINESS RULES:
--   1. Single-row table at MVP. The workflow applies globally to
--      all B2B orders for this tenant. Per-account overrides are
--      post-MVP — they will be added as a new column on b2b_accounts
--      (approval_workflow_id FK) via a non-destructive migration.
--      Use upsert; never plain INSERT after the base Alembic migration
--      inserts the seed row.
--   2. is_enabled = FALSE disables the approval workflow entirely.
--      All B2B orders auto-approve regardless of order value.
--      is_enabled = TRUE enables threshold-based approval gating.
--   3. auto_approve_under is the order total threshold below which
--      orders auto-approve without human review.
--      NULL = ALL orders require approval (regardless of value).
--      0.00 = ALL orders auto-approve (workflow effectively disabled
--             even when is_enabled = TRUE — use is_enabled = FALSE
--             instead; this combination is technically valid but
--             semantically redundant).
--   4. auto_approve_within_credit_limit applies an additional
--      auto-approval condition: if the buyer's outstanding balance
--      (existing open orders) plus this order's value is within
--      their credit_limit, the order auto-approves regardless of
--      the threshold. This allows trusted buyers to order freely
--      within their approved credit envelope.
--   5. approver_roles TEXT[] defines which staff roles are
--      notified (FCM push + email) and can action approvals.
--      Valid role values match the roles CHECK in
--      kloudshop_platform.staff_role_assignments.
--      Common values: 'owner', 'admin', 'b2b_account_manager'.
--      At least one role must be configured when is_enabled = TRUE.
--   6. escalation_hours: if an approval has been pending for this
--      many hours without action, a reminder notification fires to
--      all approver_roles. NULL = no escalation reminders.
-- ============================================================

CREATE TABLE approval_workflows (
    workflow_id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Single-row sentinel. Never generate a second row.

    is_enabled                     BOOLEAN NOT NULL DEFAULT FALSE,
    -- FALSE = approval workflow off; all B2B orders auto-approve.
    -- TRUE  = orders above auto_approve_under require approval.

    auto_approve_under             DECIMAL(12, 2),
    -- Orders with grand_total < this value auto-approve.
    -- NULL = no auto-approve threshold; ALL orders require approval.
    -- Stored in the tenant's storefront currency.

    auto_approve_within_credit_limit BOOLEAN NOT NULL DEFAULT TRUE,
    -- TRUE = orders within the buyer's credit limit auto-approve
    -- even if they exceed auto_approve_under. Commonly TRUE —
    -- allows pre-vetted buyers to operate freely within their limit.

    approver_roles                 TEXT[] NOT NULL DEFAULT '{"owner","admin"}',
    -- Staff roles notified and authorised to approve/decline.
    -- At least one role required when is_enabled = TRUE.
    -- Enforced at application layer — not a DB constraint
    -- (would require a complex array-element CHECK).

    escalation_hours               INTEGER,
    -- Hours before an un-actioned approval triggers a reminder.
    -- NULL = no escalation. Typically 4 or 8 for business-hours coverage.

    updated_at                     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- No created_at — this is a single seed row, only ever updated.

    CONSTRAINT approval_workflows_auto_approve_non_negative CHECK (
        auto_approve_under IS NULL OR auto_approve_under >= 0
    ),

    CONSTRAINT approval_workflows_escalation_positive CHECK (
        escalation_hours IS NULL OR escalation_hours >= 1
    )
);

COMMENT ON TABLE approval_workflows IS
    'Single-row B2B order approval configuration per tenant. '
    'is_enabled = FALSE disables workflow entirely (all orders auto-approve). '
    'auto_approve_under = NULL means ALL orders require approval. '
    'auto_approve_within_credit_limit allows trusted buyers to order freely. '
    'Use upsert; never plain INSERT after base Alembic provisioning.';

-- No indexes needed — single-row table. PK lookup is always O(1).
-- Fetched on every B2B order placement and cached in Redis (TTL: 5 minutes).
```

---

## Table: `approval_requests`

```sql
-- ============================================================
-- TABLE: approval_requests
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per B2B order that enters the approval
--   workflow. Records the full decision audit trail — who requested,
--   who decided, and when. Approval and decline events also write
--   rows to order_events (06c) for the order timeline.
--
-- BUSINESS RULES:
--   1. Created when an order is placed and meets the approval
--      threshold conditions defined in approval_workflows.
--   2. order_id references orders.order_id (same schema).
--      Declared as a plain UUID rather than a FK to avoid a
--      circular dependency at table creation time (orders
--      references b2b_accounts; b2b_accounts is in this artifact).
--      Application layer validates order_id on INSERT.
--   3. status lifecycle:
--      'pending'      — awaiting merchant action
--      'approved'     — merchant approved; order proceeds to fulfilment
--      'auto_approved'— system auto-approved based on workflow rules
--      'declined'     — merchant declined; order is never fulfilled
--   4. decided_by is the staff_user_id who actioned the request.
--      NULL for auto_approved decisions (actor_type = 'system').
--   5. decline_reason is required when status = 'declined'.
--      Enforced at application layer; the DB allows NULL to avoid
--      blocking automated rollback scenarios.
--   6. Every approval/decline also writes an event to order_events:
--      'approval_approved', 'approval_declined', or 'approval_auto_approved'.
--      The order_events table is the consumer-visible timeline;
--      this table is the merchant-facing approval management surface.
--   7. This table is append-effectively — rows are only created (on
--      order placement) and updated once (on decision). They are
--      never deleted. Cancelled orders retain their approval_request
--      row with the status it had at cancellation time.
--   8. b2b_account_id is denormalised here from the order for fast
--      querying of "all pending approvals for buyers managed by this
--      account manager" without joining through orders.
-- ============================================================

CREATE TABLE approval_requests (
    approval_request_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id             UUID NOT NULL,
    -- References orders.order_id (same schema). Plain UUID — application
    -- validates. Not a FK constraint to avoid circular dependency at
    -- table creation time.
    -- UNIQUE: one approval request per order.

    b2b_account_id       UUID NOT NULL
                         REFERENCES b2b_accounts (b2b_account_id)
                         ON DELETE RESTRICT,
    -- Denormalised from the order for fast per-account-manager queries.
    -- RESTRICT: retain approval history if a buyer account is archived.

    -- ── Request Details ───────────────────────────────────────
    order_grand_total    DECIMAL(12, 2) NOT NULL,
    -- The order's grand_total at the time the approval request was
    -- created. Snapshotted here because the order total cannot change
    -- after placement, but this avoids a join for the approval queue.

    currency_code        CHAR(3) NOT NULL,
    -- Currency of order_grand_total.

    -- ── Status ───────────────────────────────────────────────
    status               VARCHAR(16) NOT NULL DEFAULT 'pending',
    -- 'pending' | 'approved' | 'auto_approved' | 'declined'

    -- ── Decision ─────────────────────────────────────────────
    decided_by           UUID,
    -- staff_user_id who approved or declined. Plain UUID.
    -- NULL for auto_approved (system decision) and pending requests.

    decided_at           TIMESTAMPTZ,
    -- When the decision was made. NULL while still pending.

    decline_reason       TEXT,
    -- Shown to the buyer in their portal notification.
    -- Required when status = 'declined'. NULL for all other statuses.

    -- ── Escalation ───────────────────────────────────────────
    escalation_sent_at   TIMESTAMPTZ,
    -- When the escalation reminder was last sent (if any).
    -- NULL if no escalation has fired for this request.

    -- ── Metadata ─────────────────────────────────────────────
    requested_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- When the approval request was created.

    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT approval_requests_order_unique UNIQUE (order_id),
    -- One approval request per order.

    CONSTRAINT approval_requests_status_check CHECK (
        status IN ('pending', 'approved', 'auto_approved', 'declined')
    ),

    CONSTRAINT approval_requests_decision_consistency CHECK (
        -- decided_at must be set when status is not 'pending'.
        status = 'pending' OR decided_at IS NOT NULL
    ),

    CONSTRAINT approval_requests_decline_reason_consistency CHECK (
        -- decline_reason should be present on declined requests.
        -- DB allows NULL to avoid blocking automated scenarios.
        -- Application layer enforces this at write time.
        TRUE -- informational constraint — see comment above
    ),

    CONSTRAINT approval_requests_order_total_non_negative CHECK (
        order_grand_total >= 0
    )
);

COMMENT ON TABLE approval_requests IS
    'One row per B2B order in the approval workflow. Records full decision '
    'audit trail. b2b_account_id denormalised for fast account manager queries. '
    'Every status change also writes to order_events for the order timeline. '
    'Rows are never deleted — cancelled orders retain their approval_request row.';

CREATE UNIQUE INDEX idx_approval_requests_order_id
    ON approval_requests (order_id);
-- Rationale: One approval request per order. Fast lookup from order detail
-- view to its associated approval request.

CREATE INDEX idx_approval_requests_pending
    ON approval_requests (status, requested_at ASC)
    WHERE status = 'pending';
-- Rationale: B2B approval queue shows all pending requests oldest-first
-- (most urgent = longest waiting). Partial on pending only.

CREATE INDEX idx_approval_requests_b2b_account
    ON approval_requests (b2b_account_id, status, requested_at DESC);
-- Rationale: "All approval requests for this buyer account" — shown on
-- the buyer account detail screen. Composite covers filter + sort.

CREATE INDEX idx_approval_requests_escalation_candidates
    ON approval_requests (requested_at ASC, escalation_sent_at)
    WHERE status = 'pending';
-- Rationale: Escalation job finds pending requests older than
-- approval_workflows.escalation_hours that have not yet had an
-- escalation sent (escalation_sent_at IS NULL or sent_at + hours < NOW()).
-- Partial on pending requests only.
```

---

## Table: `b2b_invoices`

```sql
-- ============================================================
-- TABLE: b2b_invoices
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Stripe Invoice reference and payment tracking for
--   B2B net-terms orders. One row per approved B2B order that
--   has net payment terms. Provides a clean separation between
--   the core order record (06c) and the B2B invoicing lifecycle.
--
-- BUSINESS RULES:
--   1. Created when a B2B order is approved and the buyer has
--      net_terms_days > 0. Not created for immediate-payment
--      B2B orders (net_terms_days IS NULL or = 0).
--   2. order_id references orders.order_id (same schema).
--      Plain UUID — application validates on INSERT.
--      UNIQUE: one invoice row per order.
--   3. stripe_invoice_id is the Stripe Invoice object ID created
--      via the Stripe Invoicing API on the merchant's connected
--      Stripe account. The merchant's Stripe account (not
--      KloudShop UK Ltd) is the invoice issuer — consistent with
--      Stripe Connect Direct Charges model.
--   4. payment_status tracks the Stripe Invoice payment lifecycle:
--      'draft'      — invoice not yet finalised (unusual at this stage)
--      'open'       — invoice sent to buyer; awaiting payment
--      'paid'       — payment received and confirmed
--      'void'       — invoice voided (order cancelled post-invoice)
--      'uncollectible' — Stripe has marked the invoice as
--                        uncollectible after failed payment attempts
--   5. due_date is the Stripe Invoice due date. Should equal
--      order.placed_at + net_terms_days. Stored here for fast
--      receivables ageing queries without joining to orders.
--   6. invoice_amount and currency_code are snapshotted from the
--      order at invoice creation. Stripe invoices are immutable
--      once sent — this provides a local reference without needing
--      to call the Stripe API for every receivables report.
--   7. Stripe webhook events for invoice payment update both this
--      table (payment_status + paid_at) and the parent order's
--      payment_status (06c) atomically.
--   8. stripe_pdf_url is the Stripe-hosted PDF URL for the invoice.
--      Surfaced in the merchant admin and sent to the buyer via email.
--      Short-lived — Stripe PDFs expire. Application always fetches
--      a fresh URL from the Stripe API for download links rather than
--      storing a cached version here. This column is optional metadata.
-- ============================================================

CREATE TABLE b2b_invoices (
    invoice_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id             UUID NOT NULL,
    -- References orders.order_id (same schema). Plain UUID.
    -- UNIQUE: one invoice per order.

    b2b_account_id       UUID NOT NULL
                         REFERENCES b2b_accounts (b2b_account_id)
                         ON DELETE RESTRICT,
    -- Denormalised from the order for fast receivables queries per account.
    -- RESTRICT: retain invoice history if a buyer account is archived.

    -- ── Stripe Invoice Reference ─────────────────────────────
    stripe_invoice_id    TEXT NOT NULL UNIQUE,
    -- Stripe Invoice object ID. Example: 'in_1NjPOl2eZvKYlo2C...'
    -- Created on the merchant's connected Stripe account.
    -- Immutable once set — Stripe invoice IDs never change.

    stripe_pdf_url       TEXT,
    -- Stripe-hosted PDF URL. Optional metadata — always fetch fresh
    -- from Stripe API for actual download links (Stripe PDFs expire).

    -- ── Invoice Amounts ──────────────────────────────────────
    invoice_amount       DECIMAL(12, 2) NOT NULL,
    -- Total invoice amount. Snapshotted from order.grand_total.

    currency_code        CHAR(3) NOT NULL,
    -- ISO 4217 currency. Snapshotted from order at invoice creation.

    -- ── Payment Terms ────────────────────────────────────────
    net_terms_days       INTEGER NOT NULL,
    -- Snapshotted from b2b_accounts.net_terms_days at invoice creation.
    -- Retained here for receivables ageing calculation independent of
    -- any future changes to the buyer account's terms.

    due_date             TIMESTAMPTZ NOT NULL,
    -- The invoice due date = order.placed_at + net_terms_days.
    -- Stored here for fast receivables ageing queries.

    -- ── Payment Status ───────────────────────────────────────
    payment_status       VARCHAR(20) NOT NULL DEFAULT 'open',
    -- Mirrors the Stripe Invoice status.
    -- 'draft' | 'open' | 'paid' | 'void' | 'uncollectible'

    paid_at              TIMESTAMPTZ,
    -- When payment was confirmed by Stripe webhook. NULL until paid.

    -- ── Metadata ─────────────────────────────────────────────
    issued_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- When the Stripe invoice was created and sent to the buyer.

    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT b2b_invoices_order_unique UNIQUE (order_id),
    -- One invoice per order.

    CONSTRAINT b2b_invoices_payment_status_check CHECK (
        payment_status IN ('draft', 'open', 'paid', 'void', 'uncollectible')
    ),

    CONSTRAINT b2b_invoices_invoice_amount_positive CHECK (
        invoice_amount > 0
    ),

    CONSTRAINT b2b_invoices_net_terms_positive CHECK (
        net_terms_days >= 1
    ),

    CONSTRAINT b2b_invoices_paid_at_consistency CHECK (
        -- paid_at must be set when payment_status = 'paid'.
        payment_status != 'paid' OR paid_at IS NOT NULL
    )
);

COMMENT ON TABLE b2b_invoices IS
    'Stripe Invoice reference and payment tracking for B2B net-terms orders. '
    'One row per approved net-terms order. Stripe invoice issued on the '
    'merchant''s connected Stripe account — not KloudShop UK Ltd. '
    'due_date and invoice_amount snapshotted for fast receivables ageing '
    'without Stripe API calls on every report.';

CREATE UNIQUE INDEX idx_b2b_invoices_order_id
    ON b2b_invoices (order_id);
-- Rationale: Order detail view links to its invoice. One invoice per order.

CREATE UNIQUE INDEX idx_b2b_invoices_stripe_invoice_id
    ON b2b_invoices (stripe_invoice_id);
-- Rationale: Stripe webhook handler resolves the KloudShop invoice row
-- from stripe_invoice_id on every invoice payment event. O(1) required.

CREATE INDEX idx_b2b_invoices_b2b_account
    ON b2b_invoices (b2b_account_id, due_date ASC, payment_status);
-- Rationale: Per-buyer receivables view — all invoices for an account,
-- ordered by due date ascending (most overdue first).

CREATE INDEX idx_b2b_invoices_overdue
    ON b2b_invoices (due_date ASC, payment_status)
    WHERE payment_status = 'open';
-- Rationale: Receivables ageing dashboard — all open invoices past their
-- due date. Partial on open invoices only; sorted by due date ascending
-- so the longest-overdue appear first.

CREATE INDEX idx_b2b_invoices_payment_status
    ON b2b_invoices (payment_status, issued_at DESC)
    WHERE payment_status IN ('open', 'uncollectible');
-- Rationale: Finance dashboard summary — outstanding and problematic
-- invoices. Partial on actionable statuses.
```

---

## Updated Schema Inventory Entry

After generating this artifact, update `06-schema-inventory.md`:

```
| `06f-tenant-b2b-schema.md` | ✅ Generated | 6 | B2B accounts (flat, company_name display-only), price lists, price list items, approval workflows, approval requests, B2B invoices |
```
