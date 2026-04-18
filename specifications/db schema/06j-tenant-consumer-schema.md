# 06j — Tenant Consumer Schema
# KloudShop Stage 6 — Data Model

> **Artifact:** `06j-tenant-consumer-schema.md`
> **Schema:** `tenant_{tenant_id}` (one schema per merchant, provisioned at signup)
> **Persona:** Principal Data Engineer
> **Reads from:** `01-product-brief.md`, `01b-tech-stack.md`, `02-architecture.md`,
>   `03-user-journeys.md`, `04-feature-stories.md`, `04b-mvp-scope.md`,
>   `00-carry-forward-flags.md` (DMF-01 through DMF-10)
> **Depends on:** `06b-tenant-catalog-schema.md` (variants FK on wishlists — ON DELETE CASCADE),
>   `06c-tenant-orders-schema.md` (orders.consumer_id references this table — nullable,
>   forward-declared as plain UUID in 06c; FK added post-provisioning via ALTER TABLE),
>   `06d-tenant-inventory-schema.md` (stock_reservations.session_token links to
>   consumer_sessions.session_token — application-layer join, no DB FK)
> **Tables:** 4 (consumers, consumer_addresses, consumer_sessions, wishlists)
> **Status:** ✅ Generated

---

## Overview

This artifact defines the consumer identity schema for a KloudShop merchant tenant.
All four tables are part of the **BASE tenant schema** — provisioned at signup, not
feature-gated. DTC and Hybrid tier merchants use these tables actively. B2B-only
merchants have the tables present but empty; they become relevant if the merchant
ever adds a DTC storefront (Hybrid upgrade).

**Key design decisions reflected in this schema:**

- **Per-storefront consumer isolation** — the same real-world person has entirely
  independent consumer accounts on different KloudShop merchant storefronts. This is
  by design: GCIP multi-tenancy provisions one Firebase/GCIP tenant per KloudShop
  merchant tenant (`gcip_tenant_registry` in 06a1). A consumer authenticating on
  `acmeco.kloudshop.biz` gets a GCIP identity scoped to the Acme Co GCIP tenant.
  The same email on `globalbolt.kloudshop.biz` is a completely independent identity.
  There is no cross-merchant consumer identity; there is no platform-level consumer
  table. This is not a limitation — it is the correct model for a multi-tenant SaaS
  where merchants must never see each other's customers.

- **`gcip_uid TEXT UNIQUE NOT NULL`** — Firebase/GCIP assigns opaque string UIDs,
  not UUIDs. Stored as `TEXT`. This is the link between the GCIP identity and the
  KloudShop consumer record, resolved from the JWT `sub` claim on every authenticated
  consumer request. Never confused with `UUID` — the column type signals this clearly.

- **`consumer_id` is nullable on `orders` (06c)** — guest checkout orders carry no
  consumer_id. The `consumers` table records only registered consumers who have
  completed the soft post-checkout signup prompt (US-074). Soft signup is not forced;
  it is offered after order placement.

- **`consumer_sessions.consumer_id` is also nullable** — guest checkout sessions
  carry a `session_token` but NULL `consumer_id`. The `session_token` is the cart
  persistence key referenced by `stock_reservations.session_token` in 06d. The join
  between the two tables is application-layer only — no DB FK constraint.

- **`consumer_addresses.is_default`** — exactly one default per consumer is enforced
  at the application layer, not via a partial unique index. The rationale: a partial
  unique index on `(consumer_id) WHERE is_default = TRUE` would block the application
  from atomically swapping the default (set new one, then unset the old) in a single
  transaction without a temporary constraint violation. Application-layer enforcement
  avoids this and also cleanly handles the zero-addresses edge case.

- **`wishlists` uses `ON DELETE CASCADE` on both FKs** — if a consumer account is
  deleted (GDPR erasure), their wishlist is removed. If a variant is archived or
  deleted, it is removed from all wishlists. Both are correct and desired behaviours.
  No orphaned wishlist rows accumulate over time.

- **No `consumer_payments` table** — Stripe handles all payment method storage on
  the consumer's Stripe account (or as Stripe guest payment methods). KloudShop
  never stores card data. No PCI-DSS implications arise from this artifact.

- **No `consumer_preferences` JSONB column at MVP** — future preference keys (notification
  opt-ins, locale override, dark mode, etc.) will be added via a non-destructive
  `ADD COLUMN preferences JSONB NOT NULL DEFAULT '{}'` migration post-MVP. Keeping
  the base table lean avoids speculative columns.

- **`consumer_sessions` retains historical sessions** — `ended_at` is NULL for active
  sessions and set on logout or expiry. Historical session records support behavioural
  analytics in BigQuery (session duration, bounce rate, device breakdown). Sessions
  are never hard-deleted; GDPR erasure anonymises rather than deletes (same pattern
  as orders — PII nulled, record retained for analytics integrity).

- **`is_informed_review` on `product_reviews` (06b) references `consumer_id`** —
  the retroactive update job checks `orders` for a qualifying purchase by `consumer_id`
  for the reviewed `variant_id`. This join goes orders → consumers, not the other way
  around. The `consumers` table itself has no `reviewed_variant_ids` or similar.

---

## Extensions Required

```sql
-- Idempotent — already declared in prior tenant schema artifacts.
-- Repeated here for completeness; safe to run at every provisioning.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pg_trgm";    -- trigram similarity for name search
```

---

## Table: `consumers`

```sql
-- ============================================================
-- TABLE: consumers
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per registered DTC consumer per tenant.
--   The consumer identity is per-storefront — the same real-world
--   person has independent accounts across different KloudShop
--   merchant storefronts. This is by design: each merchant gets
--   their own GCIP tenant, so identities are fully isolated.
--   There is no platform-level consumer table.
--
-- BUSINESS RULES:
--   1. A consumer row is created ONLY after the soft post-checkout
--      signup prompt (US-074) is accepted. Guest checkout orders
--      complete without any row here — orders.consumer_id = NULL
--      for guest orders (06c).
--   2. gcip_uid is the Firebase/GCIP UID assigned when the consumer
--      authenticated via GCIP for this merchant's GCIP tenant.
--      It is an opaque string (e.g. 'abc123def456') — NOT a UUID.
--      Stored as TEXT. Used to resolve the consumer on every
--      authenticated request from the JWT sub claim.
--   3. email is the consumer's email address. Must be unique within
--      this tenant — a consumer cannot register twice with the same
--      email on the same storefront.
--   4. accepts_marketing controls whether this consumer has opted in
--      to marketing emails (abandoned cart recovery, newsletters, etc.).
--      GDPR/CAN-SPAM compliance: FALSE by default. Opt-in is explicit.
--      Never TRUE unless the consumer actively checked the opt-in box.
--   5. is_active = FALSE is used for soft suspension (e.g. fraud flag)
--      without deleting the account. The consumer cannot log in when
--      is_active = FALSE. All historical orders remain intact.
--   6. GDPR erasure: on a right-to-erasure request, consumer PII
--      is anonymised — NOT deleted:
--        email     → anonymised_{sha256_of_email}@kloudshop-deleted.com
--        first_name → 'Anonymised'
--        last_name  → 'User'
--        phone      → NULL
--      The consumer_id UUID is preserved so that historical order records
--      (06c) retain their consumer_id FK without going NULL. Order history
--      is required for accounting and legal compliance and is not erased.
--      The gcip_uid is cleared (set to NULL) after the GCIP account is
--      deleted by the erasure pipeline.
--   7. There is no consumer_preferences JSONB column at MVP. Future
--      preference keys will be added via a non-destructive ADD COLUMN
--      migration post-MVP.
-- ============================================================

CREATE TABLE consumers (
    consumer_id      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    -- The KloudShop-internal consumer identifier. Used as the FK on:
    --   orders.consumer_id (06c) — nullable (guest checkout)
    --   consumer_addresses.consumer_id (this artifact)
    --   consumer_sessions.consumer_id (this artifact) — nullable (guest sessions)
    --   wishlists.consumer_id (this artifact)
    --   product_reviews.consumer_id (06b)

    -- ── GCIP Identity ─────────────────────────────────────────
    gcip_uid         TEXT            UNIQUE,
    -- Firebase/GCIP UID assigned by the merchant's GCIP tenant.
    -- Opaque string — NOT a UUID. Resolved from JWT sub claim.
    -- UNIQUE: one consumer row per GCIP identity per tenant.
    -- NULL after GDPR erasure (GCIP account deleted; row retained).
    -- Not NOT NULL at DB level to allow the erasure NULL write without
    -- constraint violation. Application enforces NOT NULL at creation time.

    -- ── Contact ───────────────────────────────────────────────
    email            TEXT            NOT NULL,
    -- Consumer's email address. Must be unique within this tenant.
    -- Anonymised to anonymised_{hash}@kloudshop-deleted.com on GDPR erasure.
    -- Never stored without the consumer's explicit registration action.

    first_name       TEXT,
    -- Optional. Anonymised to 'Anonymised' on GDPR erasure.

    last_name        TEXT,
    -- Optional. Anonymised to 'User' on GDPR erasure.

    phone            TEXT,
    -- Optional. Set to NULL on GDPR erasure.

    -- ── Marketing Consent ────────────────────────────────────
    accepts_marketing BOOLEAN        NOT NULL DEFAULT FALSE,
    -- GDPR/CAN-SPAM compliance: FALSE by default. Explicit opt-in only.
    -- Set to TRUE only when the consumer actively checks the opt-in box.
    -- Marketing features (abandoned cart recovery, newsletters) check
    -- this flag before sending any marketing email.

    -- ── Status ───────────────────────────────────────────────
    is_active        BOOLEAN         NOT NULL DEFAULT TRUE,
    -- FALSE = account suspended (fraud flag, merchant ban, etc.).
    -- Consumer cannot authenticate when FALSE. Orders are unaffected.
    -- Not used for GDPR erasure — that path uses email anonymisation.

    -- ── Metadata ─────────────────────────────────────────────
    created_at       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    -- ── Constraints ──────────────────────────────────────────
    CONSTRAINT consumers_email_unique UNIQUE (email),
    -- One registered consumer per email per tenant.
    -- Note: email uniqueness is enforced here and at GCIP layer.
    -- After GDPR erasure, the anonymised email is effectively unique
    -- (SHA-256 hash of original email), preventing re-registration
    -- under the same real email without a collision.

    CONSTRAINT consumers_email_format CHECK (
        email ~ '.+@.+\..+'
        -- Minimal email format validation. Detailed validation at app layer.
    )
);

COMMENT ON TABLE consumers IS
    'One row per registered DTC consumer per tenant. Per-storefront isolation: '
    'the same real-world person has independent consumer accounts on different '
    'KloudShop merchant storefronts — this is by design given GCIP multi-tenancy. '
    'gcip_uid is a TEXT opaque string (not UUID) from Firebase/GCIP. '
    'Guest checkout orders (orders.consumer_id = NULL in 06c) never create a row here. '
    'GDPR erasure anonymises PII in-place — never deletes the row, preserving '
    'the consumer_id FK on historical order records.';

COMMENT ON COLUMN consumers.gcip_uid IS
    'Firebase/GCIP UID from the merchant''s GCIP tenant. Opaque string, NOT a UUID. '
    'Resolved from the JWT sub claim on every authenticated consumer request. '
    'NULL after GDPR erasure (GCIP account deleted; row and consumer_id retained).';

COMMENT ON COLUMN consumers.accepts_marketing IS
    'GDPR/CAN-SPAM compliance: FALSE by default. Explicit opt-in only. '
    'Marketing pipelines (abandoned cart, newsletters) must check this flag '
    'before sending. Never set to TRUE without affirmative consumer action.';

COMMENT ON COLUMN consumers.email IS
    'Unique within this tenant. Anonymised to anonymised_{sha256}@kloudshop-deleted.com '
    'on GDPR right-to-erasure execution. Application enforces format at write time.';

-- Indexes
CREATE UNIQUE INDEX idx_consumers_email
    ON consumers (email);
-- Rationale: Primary lookup at registration and login (email → consumer_id).
-- Also enforces the uniqueness constraint. Must be O(1).

CREATE UNIQUE INDEX idx_consumers_gcip_uid
    ON consumers (gcip_uid)
    WHERE gcip_uid IS NOT NULL;
-- Rationale: FastAPI resolves consumer_id from the JWT gcip_uid (sub claim)
-- on every authenticated consumer storefront request. O(1) required.
-- Partial index excludes NULL values (GDPR-erased consumers).

CREATE INDEX idx_consumers_is_active
    ON consumers (is_active, created_at DESC)
    WHERE is_active = TRUE;
-- Rationale: Admin consumer list defaults to active consumers, newest first.
-- Partial index on active consumers only.

CREATE INDEX idx_consumers_accepts_marketing
    ON consumers (accepts_marketing, created_at DESC)
    WHERE accepts_marketing = TRUE;
-- Rationale: Marketing automation and abandoned cart recovery pipelines
-- query for opted-in consumers. Partial index keeps working set small.

CREATE INDEX idx_consumers_name_trgm
    ON consumers USING GIN (
        (COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')) gin_trgm_ops
    );
-- Rationale: Admin consumer search by name uses trigram similarity
-- for fuzzy matching (e.g. "John Sm" matches "John Smith").
-- GIN index on the concatenated name expression.
```

---

## Table: `consumer_addresses`

```sql
-- ============================================================
-- TABLE: consumer_addresses
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Saved delivery addresses per registered consumer.
--   One consumer may have multiple addresses (Home, Work, etc.).
--   Pre-fills the checkout shipping address form on repeat visits.
--
-- BUSINESS RULES:
--   1. ON DELETE CASCADE on consumer_id: when a consumer account is
--      hard-deleted (which never happens in practice — GDPR erasure
--      uses anonymisation, not deletion), addresses cascade out.
--      In the GDPR erasure path, addresses are deleted explicitly by
--      the erasure pipeline before the consumer row is anonymised,
--      as address data is PII and must be fully removed (unlike the
--      consumer_id FK on orders, which must be preserved).
--   2. is_default = TRUE marks the address pre-selected at checkout.
--      Exactly one default per consumer enforced at the APPLICATION
--      LAYER — not via a partial unique index. Rationale: a partial
--      unique index on (consumer_id) WHERE is_default = TRUE would
--      cause a constraint violation during an atomic "swap default"
--      operation (set new to TRUE, then set old to FALSE) unless the
--      two UPDATEs are ordered perfectly within the transaction.
--      Application-layer enforcement avoids this fragility.
--   3. A consumer with no addresses is valid (zero rows is fine).
--      The checkout form falls back to manual address entry.
--   4. label is a merchant/consumer-facing friendly name for the
--      address (e.g. "Home", "Office", "Warehouse"). Optional.
--   5. country_code must be a 2-character ISO 3166-1 alpha-2 code.
--      Application validates the value against a known country list.
--   6. On GDPR erasure, all consumer_addresses rows for the consumer
--      are hard-deleted by the erasure pipeline. Address data is
--      direct PII and must be fully removed (not anonymised).
-- ============================================================

CREATE TABLE consumer_addresses (
    address_id       UUID            PRIMARY KEY DEFAULT gen_random_uuid(),

    consumer_id      UUID            NOT NULL
                         REFERENCES consumers (consumer_id)
                         ON DELETE CASCADE,
    -- CASCADE: if a consumer row is somehow hard-deleted, addresses go with it.
    -- In practice, the GDPR erasure pipeline deletes address rows explicitly
    -- before anonymising the parent consumer row.

    -- ── Label ────────────────────────────────────────────────
    label            TEXT,
    -- Optional friendly name for this address. Examples: 'Home', 'Work', 'Depot'.
    -- Shown in the address selector at checkout. NULL = unlabelled.
    -- Max 100 characters enforced at application layer.

    -- ── Address Fields ────────────────────────────────────────
    line1            TEXT            NOT NULL,
    -- Street address line 1. Required. Examples: '42 Acacia Avenue', '3rd Floor'.

    line2            TEXT,
    -- Optional. Apartment, suite, building name, unit number, etc.

    city             TEXT            NOT NULL,
    -- City or town. Required.

    state            TEXT,
    -- State, province, region, or county. Optional — not all countries use states.

    postcode         TEXT,
    -- Postal or ZIP code. Optional — some regions (e.g. parts of Ireland) have none.

    country_code     CHAR(2)         NOT NULL,
    -- ISO 3166-1 alpha-2 code. Examples: 'US', 'GB', 'AU', 'DE'.
    -- Validated against the known country list at application layer.
    -- Used in carrier rate queries (shipping origin/destination).

    -- ── Default Flag ─────────────────────────────────────────
    is_default       BOOLEAN         NOT NULL DEFAULT FALSE,
    -- TRUE = pre-selected at checkout and pre-filled in address picker.
    -- Exactly one default per consumer enforced at APPLICATION LAYER.
    -- Not enforced by a partial unique index — see business rules above.

    -- ── Metadata ─────────────────────────────────────────────
    created_at       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT consumer_addresses_country_code_format CHECK (
        country_code ~ '^[A-Z]{2}$'
        -- ISO 3166-1 alpha-2 format: two uppercase letters.
        -- Detailed country validation at application layer.
    )
);

COMMENT ON TABLE consumer_addresses IS
    'Saved delivery addresses per consumer. One consumer may have multiple addresses. '
    'is_default marks the address pre-selected at checkout — enforced at application '
    'layer, NOT via a partial unique index, to allow atomic default-swapping. '
    'All rows for a consumer are hard-deleted by the GDPR erasure pipeline '
    '(address data is PII and must be fully removed, unlike orders which are retained).';

COMMENT ON COLUMN consumer_addresses.is_default IS
    'Exactly one default per consumer enforced at application layer. '
    'A partial unique index on (consumer_id) WHERE is_default = TRUE is deliberately '
    'NOT used — it would cause constraint violations during atomic default-swap operations. '
    'Application uses a transaction: UPDATE new row SET is_default = TRUE; '
    'UPDATE all other rows for this consumer SET is_default = FALSE.';

COMMENT ON COLUMN consumer_addresses.country_code IS
    'ISO 3166-1 alpha-2 code (two uppercase letters). DB enforces format via CHECK. '
    'Application validates against the known country list before write. '
    'Used in carrier rate queries as the shipping destination country.';

-- Indexes
CREATE INDEX idx_consumer_addresses_consumer_id
    ON consumer_addresses (consumer_id, is_default DESC, created_at ASC);
-- Rationale: Checkout address picker loads all addresses for a consumer,
-- with the default first. Composite covers consumer filter, default sort,
-- and creation date tiebreak in one index scan.

CREATE INDEX idx_consumer_addresses_default
    ON consumer_addresses (consumer_id)
    WHERE is_default = TRUE;
-- Rationale: Fast lookup of a consumer's default address for checkout pre-fill.
-- Partial index on default addresses only — at most one row per consumer.
-- Complements the composite index above for single-address lookups.

CREATE INDEX idx_consumer_addresses_country
    ON consumer_addresses (country_code);
-- Rationale: Carrier configuration and shipping analytics filter addresses
-- by country_code to determine which carriers are applicable.
```

---

## Table: `consumer_sessions`

```sql
-- ============================================================
-- TABLE: consumer_sessions
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Tracks active and historical consumer sessions for
--   analytics and cart persistence. One row per session — both
--   authenticated (registered consumer) and guest (no consumer_id).
--
-- BUSINESS RULES:
--   1. consumer_id is NULLABLE — guest sessions have no consumer_id.
--      The session_token is the identity key for guest sessions.
--      When a guest converts to a registered consumer via the soft
--      signup prompt, the application UPDATEs consumer_id on the
--      existing session row to link it to the new consumer record.
--   2. session_token is a cryptographically random token generated
--      at session start. It is the key used in:
--        stock_reservations.session_token (06d) — cart lock identity
--        Redis session/cart cache key
--      The join between consumer_sessions and stock_reservations
--      is application-layer only — no DB FK constraint.
--   3. ended_at = NULL means the session is still active (or was
--      abandoned without explicit logout). A Cloud Tasks scheduled
--      job sets ended_at for sessions where last_seen_at is older
--      than the session expiry threshold (typically 30 minutes of
--      inactivity for guest sessions, 24 hours for logged-in sessions).
--   4. Historical session records are retained for BigQuery analytics
--      (session duration, device breakdown, bounce rate, conversion
--      funnel analysis). Sessions are never hard-deleted.
--   5. GDPR erasure: consumer_sessions rows for the erased consumer
--      are anonymised:
--        consumer_id  → NULL (unlinking from the consumer record)
--        ip_address   → NULL
--        user_agent   → NULL
--      session_token, started_at, last_seen_at, ended_at, device_type
--      are retained for aggregate analytics (they contain no PII).
--   6. ip_address uses the PostgreSQL INET type for efficient storage
--      and subnet queries. Supports both IPv4 and IPv6. Set to NULL
--      on GDPR erasure.
--   7. device_type is derived from user_agent at session creation by
--      the application layer (UA parsing). The raw user_agent string
--      is also stored for more detailed analytics if needed.
-- ============================================================

CREATE TABLE consumer_sessions (
    session_id       UUID            PRIMARY KEY DEFAULT gen_random_uuid(),

    -- ── Consumer Identity ────────────────────────────────────
    consumer_id      UUID
                         REFERENCES consumers (consumer_id)
                         ON DELETE SET NULL,
    -- NULL for guest sessions. Non-null for authenticated sessions.
    -- SET NULL on delete: if a consumer row is somehow removed, session records
    -- are retained but unlinked (same reason as order_items.variant_id design).
    -- In practice, GDPR erasure sets consumer_id = NULL rather than deleting
    -- the consumer row, so this SET NULL is a safety net.
    -- Updated from NULL → consumer_id when a guest converts to registered consumer.

    -- ── Session Token ─────────────────────────────────────────
    session_token    TEXT            NOT NULL UNIQUE,
    -- Cryptographically random token generated at session start.
    -- Used as the cart persistence key in stock_reservations (06d) and Redis.
    -- Application join only — no DB FK to stock_reservations.
    -- Token format: 256-bit random hex string (64 hex characters).
    -- Remains stable across guest → registered consumer conversion.

    -- ── Device & Browser ─────────────────────────────────────
    device_type      VARCHAR(16)
                         CHECK (device_type IN ('mobile', 'tablet', 'desktop', 'unknown')),
    -- Derived from user_agent by the application (UA parsing library).
    -- NULL only if UA parsing fails completely.
    -- Used in analytics dashboards for device breakdown reports.

    user_agent       TEXT,
    -- Raw User-Agent string. Retained for detailed analytics.
    -- Set to NULL on GDPR erasure (user agents can be fingerprinting vectors).

    ip_address       INET,
    -- Client IP address. Supports IPv4 and IPv6 via PostgreSQL INET type.
    -- Used for geolocation analytics (country-level only — no precise tracking).
    -- Set to NULL on GDPR erasure.

    -- ── Timestamps ───────────────────────────────────────────
    started_at       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    -- When the session was initiated (first page load or cart add).

    last_seen_at     TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    -- Updated on each storefront page load or API call within this session.
    -- Used by the expiry job to identify abandoned sessions.
    -- Updated in Redis first (fast path); DB updated on session end or periodically.

    ended_at         TIMESTAMPTZ,
    -- When the session ended — either via explicit logout or inactivity expiry.
    -- NULL = session is active or was abandoned without logout.
    -- Set by: (a) consumer logout action, or (b) Cloud Tasks expiry job.

    CONSTRAINT consumer_sessions_dates_consistency CHECK (
        ended_at IS NULL OR ended_at >= started_at
    )
);

COMMENT ON TABLE consumer_sessions IS
    'Active and historical consumer sessions per tenant. Both authenticated '
    '(consumer_id set) and guest (consumer_id = NULL) sessions are tracked. '
    'session_token is the cart persistence key — used in stock_reservations (06d) '
    'and Redis. Consumer ID updated from NULL when a guest converts to registered. '
    'Sessions are never hard-deleted. GDPR erasure anonymises: '
    'consumer_id → NULL, ip_address → NULL, user_agent → NULL.';

COMMENT ON COLUMN consumer_sessions.session_token IS
    '256-bit cryptographically random token. Cart persistence identity — '
    'referenced as session_token in stock_reservations (06d) and Redis cart cache. '
    'Application-layer join only; no DB FK. Stable across guest → registered conversion.';

COMMENT ON COLUMN consumer_sessions.consumer_id IS
    'NULL for guest sessions. Set on authenticated login or guest → registered conversion. '
    'ON DELETE SET NULL: if consumer row is removed, session record is retained but unlinked. '
    'GDPR erasure sets this to NULL explicitly rather than deleting the row.';

COMMENT ON COLUMN consumer_sessions.last_seen_at IS
    'Updated on each storefront interaction. Fast path: Redis. '
    'DB updated on session close or by a periodic flush job. '
    'Used by the Cloud Tasks expiry job to identify abandoned sessions '
    '(inactivity threshold: 30 min for guest, 24 hr for authenticated).';

COMMENT ON COLUMN consumer_sessions.ip_address IS
    'PostgreSQL INET type — stores IPv4 and IPv6 addresses. '
    'Used for country-level geolocation analytics only. '
    'Set to NULL on GDPR erasure (IP addresses are personal data under GDPR).';

-- Indexes
CREATE UNIQUE INDEX idx_consumer_sessions_token
    ON consumer_sessions (session_token);
-- Rationale: Primary session resolution — every storefront page load and
-- cart operation resolves the session from the session_token cookie.
-- Must be O(1). UNIQUE enforces no duplicate tokens.

CREATE INDEX idx_consumer_sessions_consumer_id
    ON consumer_sessions (consumer_id, started_at DESC)
    WHERE consumer_id IS NOT NULL;
-- Rationale: Consumer session history in admin and for analytics queries
-- ("all sessions for this consumer"). Partial excludes guest sessions.

CREATE INDEX idx_consumer_sessions_active
    ON consumer_sessions (last_seen_at DESC)
    WHERE ended_at IS NULL;
-- Rationale: Cloud Tasks expiry job scans for sessions where
-- last_seen_at < NOW() - threshold and ended_at IS NULL.
-- Partial index on active sessions only — the majority of rows over time
-- will have ended_at set.

CREATE INDEX idx_consumer_sessions_device_type
    ON consumer_sessions (device_type, started_at DESC)
    WHERE device_type IS NOT NULL;
-- Rationale: Analytics dashboard device breakdown — "what proportion of
-- sessions were mobile vs desktop this month?" Partial on non-NULL device_type.

CREATE INDEX idx_consumer_sessions_started_at
    ON consumer_sessions (started_at DESC);
-- Rationale: Time-series analytics — sessions per day/week/month.
-- Used by BigQuery streaming export and the native analytics dashboards.
```

---

## Table: `wishlists`

```sql
-- ============================================================
-- TABLE: wishlists
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Consumer saved product variants. Simple save-for-later
--   functionality. One row per (consumer_id, variant_id). No named
--   lists, no sharing, no sharing at MVP — single flat wishlist per
--   consumer per storefront.
--
-- BUSINESS RULES:
--   1. Composite PK (consumer_id, variant_id) enforces one wishlist
--      entry per consumer per variant. A consumer cannot save the
--      same variant twice — the application checks before inserting.
--   2. ON DELETE CASCADE on consumer_id: when a consumer account is
--      GDPR-erased (anonymised), or in the rare case of hard deletion,
--      all wishlist entries are removed. A wishlist has no meaning
--      without a consumer.
--   3. ON DELETE CASCADE on variant_id: when a variant is deleted
--      (hard delete — not archive), it is removed from all consumer
--      wishlists automatically. Archived variants (is_active = FALSE)
--      are NOT deleted from the DB; their wishlist entries persist.
--      The storefront renders archived variants on wishlists with an
--      "out of stock" or "no longer available" state. Merchants may
--      restore archived variants and the wishlist entries remain intact.
--   4. No quantity field — wishlist is a save intent, not a cart.
--      Consumers add the variant to cart when ready to purchase.
--   5. No post-MVP named list or collaborative wishlist features
--      are implied by this schema. Those require a separate
--      wishlist_lists table added via non-destructive migration.
--   6. added_at is the only timestamp. No updated_at — there is
--      nothing to update on a wishlist entry: it exists (added) or
--      it does not (removed). No soft-delete.
--   7. Wishlists feed personalisation signals for the AI consultative
--      search layer (products the consumer has expressed interest in
--      but not purchased = high-intent signals for recommendations).
--      These signals are read-only from the Vertex AI embedding pipeline.
-- ============================================================

CREATE TABLE wishlists (
    consumer_id      UUID            NOT NULL
                         REFERENCES consumers (consumer_id)
                         ON DELETE CASCADE,
    -- CASCADE: removing a consumer removes all their wishlist entries.
    -- In the GDPR erasure path, the erasure pipeline deletes wishlist
    -- rows explicitly before anonymising the consumer row (same pattern
    -- as consumer_addresses — wishlist entries reference a specific
    -- consumer and have no meaning without that consumer).

    variant_id       UUID            NOT NULL
                         REFERENCES variants (variant_id)
                         ON DELETE CASCADE,
    -- CASCADE: hard-deleting a variant removes it from all wishlists.
    -- Archived variants (is_active = FALSE) are NOT deleted; their
    -- wishlist entries persist and render as "no longer available".

    added_at         TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    -- When the consumer saved this variant to their wishlist.
    -- No updated_at — wishlist entries are add or remove; no update.

    PRIMARY KEY (consumer_id, variant_id)
    -- Composite PK enforces one entry per (consumer, variant).
    -- Doubles as the primary index for both lookup directions.
);

COMMENT ON TABLE wishlists IS
    'Consumer saved variants (save-for-later). One row per (consumer_id, variant_id). '
    'ON DELETE CASCADE on both FKs: consumer removal clears their wishlist; '
    'hard-deleted variants are removed from all wishlists. Archived (soft-inactive) '
    'variants are retained in wishlists and rendered as "no longer available". '
    'No named lists, no sharing, no quantity — single flat wishlist per consumer. '
    'Feeds AI personalisation signals for product recommendation (high-intent save data).';

COMMENT ON COLUMN wishlists.variant_id IS
    'ON DELETE CASCADE: hard-deleted variants are removed from all wishlists automatically. '
    'Archived variants (variants.is_active = FALSE) are NOT hard-deleted; their '
    'wishlist entries persist and render as "no longer available" on the storefront.';

COMMENT ON COLUMN wishlists.consumer_id IS
    'ON DELETE CASCADE: removing a consumer removes all their wishlist entries. '
    'GDPR erasure pipeline deletes wishlist rows explicitly before anonymising '
    'the parent consumer row — wishlist entries reference a specific consumer '
    'and have no meaning or analytics value without that consumer.';

-- Indexes
CREATE INDEX idx_wishlists_consumer_id
    ON wishlists (consumer_id, added_at DESC);
-- Rationale: Consumer wishlist page loads all saved variants for a consumer,
-- newest saved first. Composite covers consumer filter + date sort.
-- The composite PK index covers (consumer_id, variant_id) — this separate
-- index adds the added_at sort direction without a full table scan.

CREATE INDEX idx_wishlists_variant_id
    ON wishlists (variant_id, added_at DESC);
-- Rationale: "How many consumers have saved this variant?" — used in the
-- product admin to surface wishlist popularity signals. Also used by the
-- AI recommendation pipeline to score variant interest without a purchase.
-- Reverse lookup: variant → consumers who saved it.
```

---

## Updated Schema Inventory Entry

Replace the `06j` row in `06-schema-inventory.md` progress table with:

```
| `06j-tenant-consumer-schema.md` | ✅ Generated | 4 | consumers (per-storefront GCIP isolation, gcip_uid TEXT opaque string, GDPR anonymisation-not-deletion, accepts_marketing FALSE default), consumer_addresses (is_default enforced at app layer not partial unique index — atomic swap rationale documented), consumer_sessions (nullable consumer_id for guests, session_token = cart persistence key for stock_reservations 06d, GDPR anonymisation of PII fields), wishlists (CASCADE on both FKs, archived variants retained with "no longer available" state, AI personalisation signal source) |
```
