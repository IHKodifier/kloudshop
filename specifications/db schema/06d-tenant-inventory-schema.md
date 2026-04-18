# 06d — Tenant Inventory Schema
# KloudShop Stage 6 — Data Model

> **Artifact:** `06d-tenant-inventory-schema.md`
> **Schema:** `tenant_{tenant_id}` (one schema per merchant, provisioned at signup)
> **Persona:** Principal Data Engineer
> **Reads from:** `01-product-brief.md`, `01b-tech-stack.md`, `02-architecture.md`,
>   `03-user-journeys.md`, `04-feature-stories.md`, `04b-mvp-scope.md`,
>   `00-carry-forward-flags.md` (DMF-01 through DMF-10)
> **Depends on:** `06b-tenant-catalog-schema.md` (variants FK),
>   `06c-tenant-orders-schema.md` (orders FK on reservations)
> **Tables:** 5 (stock_locations, inventory, stock_reservations,
>   stock_transfers, packaging_presets)
> **Status:** ✅ Generated

---

## Overview

This artifact defines the inventory management schema for a KloudShop merchant
tenant. Inventory in KloudShop is multi-location from day one — every stock level
is tracked per variant per location, not just as a single aggregate count. This
design supports warehouses, physical retail stores, and third-party logistics
centres within a single merchant account.

**Key design decisions reflected in this schema:**

- **`inventory` is keyed on `(variant_id, stock_location_id)`** — the atomic
  unit of stock is a specific variant at a specific location. There is no
  single aggregate stock count. Cross-location totals are computed by the
  application layer when needed.

- **`quantity_available` is a generated column** — it is always computed as
  `quantity_on_hand - quantity_reserved`. This eliminates the class of bugs
  where available quantity drifts from the two source values due to missed
  updates. The DB always owns the computation.

- **`stock_reservations` are short-lived** — created when a consumer begins
  checkout, released on order confirmation or expiry. They prevent overselling
  during concurrent checkouts without requiring long-lived DB locks. Redis also
  maintains a fast counter for real-time availability display, but the DB
  reservation is the authoritative source.

- **`stock_transfers` are double-entry** — a transfer always has a source
  location and a destination location. In-transit stock is tracked explicitly
  so it is never double-counted in either location's `quantity_on_hand`.

- **`packaging_presets` are tenant-defined box sizes** — used in shipping rate
  calculation to select the smallest box that fits the cart. The `is_default`
  flag marks the fallback box used when no preset fits.

**AI agent note:** `quantity_available` is a PostgreSQL generated column
(`GENERATED ALWAYS AS ... STORED`). Never attempt to INSERT or UPDATE this
column directly — the database computes it. All inventory mutations must go
through the `quantity_on_hand` and `quantity_reserved` columns only.

---

## Table: `stock_locations`

```sql
-- ============================================================
-- TABLE: stock_locations
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Named stock locations for this merchant. One row per
--   physical or virtual location where inventory is held.
--   Examples: 'Main Warehouse', 'London Store', 'Sydney 3PL'.
--
-- BUSINESS RULES:
--   1. Every merchant has at least one stock location created
--      automatically at signup (the default location).
--      This default location cannot be deleted — only renamed.
--   2. location_type classifies the location for analytics and
--      fulfilment routing logic:
--      'warehouse'  — dedicated storage facility
--      'store'      — physical retail store (also used as POS location)
--      '3pl'        — third-party logistics / fulfilment centre
--      'virtual'    — no physical location (e.g. dropshipping, consignment)
--   3. POS Operator role users are assigned to a specific
--      stock_location_id. All POS sales decrement inventory
--      from that assigned location.
--   4. is_active = FALSE prevents new stock from being allocated
--      to this location. Existing stock remains; existing orders
--      linked to this location are unaffected.
--   5. is_default = TRUE marks the location used for online
--      storefront fulfilment when no specific routing rule applies.
--      Exactly one location per tenant should have is_default = TRUE.
--      Enforced at application layer — not a DB unique constraint
--      (to allow atomic default-switching without transient violations).
--   6. fulfils_online = TRUE means this location can be assigned
--      as the fulfilment source for online (DTC / B2B) orders.
--      fulfils_pos = TRUE means POS operators can sell from this
--      location. Both can be TRUE simultaneously (e.g. a store
--      that both serves walk-in customers and ships online orders).
-- ============================================================

CREATE TABLE stock_locations (
    stock_location_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name               TEXT NOT NULL,
    -- Human-readable location name. Shown in admin and analytics.
    -- Examples: 'Main Warehouse', 'London Flagship', 'US East 3PL'.

    location_type      VARCHAR(16) NOT NULL DEFAULT 'warehouse',
    -- Classification of this location. See business rules.

    -- ── Address ──────────────────────────────────────────────
    address_line1      TEXT,
    address_line2      TEXT,
    city               TEXT,
    state              TEXT,
    postcode           TEXT,
    country_code       CHAR(2),
    -- ISO 3166-1 alpha-2. Used for shipping origin in carrier rate queries.

    -- ── Fulfilment Capabilities ───────────────────────────────
    fulfils_online     BOOLEAN NOT NULL DEFAULT TRUE,
    -- TRUE = this location can fulfil online (DTC / B2B) orders.

    fulfils_pos        BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = POS operators can sell from this location.
    -- Set to TRUE automatically when a POS Operator is assigned here.

    is_default         BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = fallback fulfilment location for online orders when no
    -- routing rule applies. Application layer enforces one default.

    -- ── Status ───────────────────────────────────────────────
    is_active          BOOLEAN NOT NULL DEFAULT TRUE,
    -- FALSE = location is inactive. No new stock allocations.
    -- Existing inventory and orders are unaffected.

    -- ── Metadata ─────────────────────────────────────────────
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT stock_locations_type_check CHECK (
        location_type IN ('warehouse', 'store', '3pl', 'virtual')
    )
);

COMMENT ON TABLE stock_locations IS
    'Named stock locations per tenant (warehouses, stores, 3PL centres). '
    'Inventory tracked per (variant, location) pair. POS operators assigned '
    'to a location. is_default = fallback online fulfilment location.';

CREATE INDEX idx_stock_locations_active
    ON stock_locations (is_active)
    WHERE is_active = TRUE;
-- Rationale: Active locations list loaded on every inventory dashboard
-- view and fulfilment routing calculation.

CREATE INDEX idx_stock_locations_online
    ON stock_locations (fulfils_online, is_active)
    WHERE fulfils_online = TRUE AND is_active = TRUE;
-- Rationale: Fulfilment routing queries only locations that can fulfil
-- online orders. Partial index keeps this targeted.

CREATE INDEX idx_stock_locations_pos
    ON stock_locations (fulfils_pos, is_active)
    WHERE fulfils_pos = TRUE AND is_active = TRUE;
-- Rationale: POS operator login resolves their assigned location.
-- Partial index on POS-capable active locations.
```

---

## Table: `inventory`

```sql
-- ============================================================
-- TABLE: inventory
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Per-(variant, location) stock level record. This is
--   the single source of truth for all stock quantities.
--   One row per variant per stock location.
--
-- BUSINESS RULES:
--   1. Every variant that exists in the system should have an
--      inventory row for at least one stock location. Created
--      automatically when a variant is added to a location.
--   2. quantity_on_hand is the physical count — units that exist
--      in this location, regardless of whether they are reserved
--      for pending orders.
--   3. quantity_reserved is the count of units held by active
--      stock_reservations for this (variant, location). Updated
--      atomically when a reservation is created or released.
--   4. quantity_available is a GENERATED column:
--      quantity_on_hand - quantity_reserved
--      Never written directly. Always computed by the DB.
--      This eliminates drift between available quantity and its
--      two source columns.
--   5. quantity_on_hand and quantity_reserved must always be >= 0.
--      quantity_available can temporarily be negative if a manual
--      stock adjustment reduces on_hand below reserved (the
--      application layer must surface this as an alert).
--   6. reorder_point is the quantity threshold at which the admin
--      surfaces a low-stock alert and the AI replenishment engine
--      triggers a reorder recommendation.
--   7. reorder_quantity is the suggested order quantity when the
--      reorder_point is breached. Pre-populated by the AI
--      replenishment engine; merchant can override.
--   8. All inventory mutations (sales, receipts, adjustments,
--      transfers) must use SELECT FOR UPDATE on the affected
--      inventory row to prevent concurrent write races.
--      Application layer is responsible for locking discipline.
-- ============================================================

CREATE TABLE inventory (
    inventory_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    variant_id         UUID NOT NULL
                       REFERENCES variants (variant_id)
                       ON DELETE CASCADE,
    -- CASCADE: deleting a variant removes all its inventory records.
    -- This is intentional — stock records have no meaning without
    -- the variant they belong to.

    stock_location_id  UUID NOT NULL
                       REFERENCES stock_locations (stock_location_id)
                       ON DELETE RESTRICT,
    -- RESTRICT: never silently delete inventory records when a
    -- location is deleted. Locations should be deactivated, not deleted.
    -- If deletion is truly needed, all inventory must be manually
    -- cleared first (application layer enforces this).

    -- ── Stock Quantities ─────────────────────────────────────
    quantity_on_hand   INTEGER NOT NULL DEFAULT 0,
    -- Physical unit count at this location.
    -- Updated on: goods receipt, manual adjustment, stock transfer,
    -- order fulfilment, POS sale. Never negative (enforced by CHECK).

    quantity_reserved  INTEGER NOT NULL DEFAULT 0,
    -- Units reserved by active checkout sessions.
    -- Updated atomically alongside stock_reservations rows.
    -- Never negative (enforced by CHECK).

    quantity_available INTEGER GENERATED ALWAYS AS (
        quantity_on_hand - quantity_reserved
    ) STORED,
    -- Computed: units available for new orders right now.
    -- STORED = computed at write time and persisted; fast to read.
    -- Never write to this column directly — DB owns the computation.
    -- Can be negative if manual adjustment reduces on_hand below
    -- reserved (application layer must surface this as an alert).

    -- ── Reorder Settings ─────────────────────────────────────
    reorder_point      INTEGER,
    -- Low-stock threshold. When quantity_available drops to or below
    -- this value, a low-stock alert fires and the AI replenishment
    -- engine surfaces a recommendation.
    -- NULL = no reorder point configured for this variant/location.

    reorder_quantity   INTEGER,
    -- Suggested order quantity when reorder_point is breached.
    -- Set by AI replenishment engine; merchant can override.
    -- NULL = no suggestion; merchant determines quantity manually.

    -- ── Tracking ─────────────────────────────────────────────
    last_received_at   TIMESTAMPTZ,
    -- When stock was last received at this location (goods receipt).
    -- Used in supplier lead time analytics and stock age calculations.

    last_sold_at       TIMESTAMPTZ,
    -- When the most recent sale was recorded for this variant at
    -- this location. Used in dead-stock identification.

    -- ── Metadata ─────────────────────────────────────────────
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT inventory_unique_variant_location
        UNIQUE (variant_id, stock_location_id),
    -- One inventory row per (variant, location) pair.

    CONSTRAINT inventory_on_hand_non_negative CHECK (
        quantity_on_hand >= 0
    ),

    CONSTRAINT inventory_reserved_non_negative CHECK (
        quantity_reserved >= 0
    ),

    CONSTRAINT inventory_reorder_point_positive CHECK (
        reorder_point IS NULL OR reorder_point >= 0
    ),

    CONSTRAINT inventory_reorder_quantity_positive CHECK (
        reorder_quantity IS NULL OR reorder_quantity >= 1
    )
);

COMMENT ON TABLE inventory IS
    'Per-(variant, stock_location) stock level. Single source of truth for stock. '
    'quantity_available is a GENERATED ALWAYS column — never write to it directly. '
    'Use SELECT FOR UPDATE on mutations to prevent concurrent write races.';

CREATE UNIQUE INDEX idx_inventory_variant_location
    ON inventory (variant_id, stock_location_id);
-- Rationale: Primary lookup — "how much stock does this variant have
-- at this location?" Called on every checkout, POS sale, and order.
-- Must be unique and O(1).

CREATE INDEX idx_inventory_location
    ON inventory (stock_location_id, quantity_available);
-- Rationale: Per-location inventory dashboard loads all variants at a
-- location. quantity_available in the index enables the dashboard to
-- sort by availability without a table fetch.

CREATE INDEX idx_inventory_low_stock
    ON inventory (stock_location_id, variant_id, quantity_available)
    WHERE quantity_available <= reorder_point
      AND reorder_point IS NOT NULL;
-- Rationale: Low-stock alert query — find all (variant, location) pairs
-- where available quantity has dropped to or below the reorder point.
-- Partial index on rows where reorder_point is configured.
-- Note: Because quantity_available is a generated column, this partial
-- index condition is valid in PostgreSQL 12+.

CREATE INDEX idx_inventory_dead_stock
    ON inventory (stock_location_id, last_sold_at)
    WHERE quantity_on_hand > 0 AND last_sold_at IS NOT NULL;
-- Rationale: Dead-stock identification — find variants with stock but
-- no recent sales. Partial on rows that have both stock and a sale record.
```

---

## Table: `stock_reservations`

```sql
-- ============================================================
-- TABLE: stock_reservations
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Short-lived stock locks placed during the checkout
--   process to prevent overselling during concurrent checkouts.
--   A reservation holds units at a specific location for a
--   specific variant for the duration of a checkout session.
--
-- BUSINESS RULES:
--   1. A reservation is created when a consumer's cart moves
--      into the active checkout flow (payment step begins).
--   2. A reservation is RELEASED (deleted) in two scenarios:
--      (a) Order confirmed — inventory.quantity_on_hand is
--          decremented, inventory.quantity_reserved is decremented,
--          and the reservation row is deleted in a single transaction.
--      (b) Reservation expires (expires_at < NOW()) — a Cloud Tasks
--          scheduled job scans for expired reservations, releases
--          them by decrementing quantity_reserved, and deletes them.
--   3. expires_at is set to NOW() + 15 minutes at creation time.
--      15 minutes gives the consumer enough time to complete payment
--      without holding stock indefinitely for abandoned checkouts.
--   4. When a reservation is created, inventory.quantity_reserved
--      is incremented atomically in the same transaction (SELECT
--      FOR UPDATE on the inventory row, then UPDATE + INSERT).
--   5. One reservation per (session_token, variant_id, location_id).
--      If the consumer changes their cart quantity, the reservation
--      row is updated (not replaced) and quantity_reserved is
--      adjusted accordingly.
--   6. session_token links the reservation to the consumer's
--      checkout session. For authenticated consumers this may be
--      the consumer_id; for guests it is a session UUID generated
--      at cart creation time.
-- ============================================================

CREATE TABLE stock_reservations (
    reservation_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    variant_id         UUID NOT NULL
                       REFERENCES variants (variant_id)
                       ON DELETE CASCADE,
    -- CASCADE: if a variant is deleted, its reservations are released.
    -- Application must also decrement quantity_reserved on the
    -- corresponding inventory row when this cascade fires.

    stock_location_id  UUID NOT NULL
                       REFERENCES stock_locations (stock_location_id)
                       ON DELETE RESTRICT,
    -- RESTRICT: never auto-delete reservations if a location is removed.
    -- Locations should never be hard-deleted while active reservations exist.

    quantity_reserved  INTEGER NOT NULL,
    -- Number of units held by this reservation.
    -- Must be >= 1.

    session_token      TEXT NOT NULL,
    -- Identifies the checkout session holding this reservation.
    -- For authenticated consumers: consumer_id as text.
    -- For guests: a UUID generated at cart creation.
    -- Used to release all reservations for an abandoned session.

    order_id           UUID,
    -- Set when the checkout completes and an order is created.
    -- NULL during active checkout. Used to correlate the reservation
    -- with the completed order before the reservation row is deleted.
    -- References orders (plain UUID — same schema, but set post-creation).

    expires_at         TIMESTAMPTZ NOT NULL,
    -- When this reservation expires if not confirmed.
    -- = created_at + 15 minutes.
    -- Cloud Tasks expiry job scans for rows where expires_at < NOW().

    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT stock_reservations_unique_session_variant_location
        UNIQUE (session_token, variant_id, stock_location_id),
    -- One reservation per (session, variant, location).

    CONSTRAINT stock_reservations_quantity_positive CHECK (
        quantity_reserved >= 1
    )
);

COMMENT ON TABLE stock_reservations IS
    'Short-lived checkout locks. Created at checkout start, released on '
    'order confirmation or expiry. Prevents overselling during concurrent '
    'checkouts. quantity_reserved on inventory updated atomically with this row.';

CREATE INDEX idx_stock_reservations_variant_location
    ON stock_reservations (variant_id, stock_location_id);
-- Rationale: "How many units of this variant are reserved at this location?"
-- Called during checkout to validate availability before creating reservation.

CREATE INDEX idx_stock_reservations_expires_at
    ON stock_reservations (expires_at)
    WHERE order_id IS NULL;
-- Rationale: Expiry cleanup job scans for reservations past their TTL
-- that have not been converted to orders. Partial index on un-confirmed
-- reservations only — completed reservations have order_id set.

CREATE INDEX idx_stock_reservations_session
    ON stock_reservations (session_token);
-- Rationale: "Release all reservations for this checkout session" —
-- called on checkout abandonment and order cancellation.
```

---

## Table: `stock_transfers`

```sql
-- ============================================================
-- TABLE: stock_transfers
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Records of stock moved between locations. Each transfer
--   has a source location, a destination location, and a lifecycle
--   that tracks the stock as it moves between them. In-transit
--   stock is tracked explicitly to prevent double-counting.
--
-- BUSINESS RULES:
--   1. A transfer is always between two different locations.
--      source_location_id != destination_location_id enforced
--      by CHECK constraint.
--   2. Transfer lifecycle:
--      'draft'     — transfer planned but not yet initiated.
--                    No inventory changes yet.
--      'in_transit'— stock has left the source location.
--                    source inventory decremented at this point.
--                    Destination inventory NOT yet incremented.
--      'received'  — stock has arrived at the destination.
--                    destination inventory incremented at this point.
--      'cancelled' — transfer cancelled before dispatch.
--                    If status was 'in_transit', source inventory
--                    is re-incremented on cancellation.
--   3. quantity_transferred is the intended quantity.
--      quantity_received is the actual received quantity (may differ
--      due to damage or loss in transit). Discrepancy is flagged.
--   4. Inventory mutations happen at status transitions:
--      draft → in_transit: decrement source quantity_on_hand
--      in_transit → received: increment destination quantity_on_hand
--      in_transit → cancelled: re-increment source quantity_on_hand
--      All transitions use SELECT FOR UPDATE on both inventory rows.
--   5. initiated_by and received_by are staff_user_ids.
--      Stored as plain UUIDs (cross-schema reference).
-- ============================================================

CREATE TABLE stock_transfers (
    transfer_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- ── Locations ────────────────────────────────────────────
    source_location_id     UUID NOT NULL
                           REFERENCES stock_locations (stock_location_id)
                           ON DELETE RESTRICT,
    -- RESTRICT: never delete a location with active transfers.

    destination_location_id UUID NOT NULL
                            REFERENCES stock_locations (stock_location_id)
                            ON DELETE RESTRICT,

    -- ── Item ─────────────────────────────────────────────────
    variant_id             UUID NOT NULL
                           REFERENCES variants (variant_id)
                           ON DELETE RESTRICT,
    -- RESTRICT: do not delete a variant with in-transit transfers.

    -- ── Quantities ───────────────────────────────────────────
    quantity_transferred   INTEGER NOT NULL,
    -- Number of units being transferred. Set at creation. >= 1.

    quantity_received      INTEGER,
    -- Actual units received at destination. Set on status → 'received'.
    -- NULL until received. May differ from quantity_transferred (damage,
    -- loss). Discrepancy = quantity_transferred - quantity_received.

    -- ── Status ───────────────────────────────────────────────
    status                 VARCHAR(16) NOT NULL DEFAULT 'draft',
    -- 'draft' | 'in_transit' | 'received' | 'cancelled'
    -- See business rules for inventory mutation timing per transition.

    -- ── People & Dates ───────────────────────────────────────
    initiated_by           UUID,
    -- staff_user_id who initiated the transfer. Plain UUID.

    initiated_at           TIMESTAMPTZ,
    -- When status transitioned to 'in_transit'.

    received_by            UUID,
    -- staff_user_id who confirmed receipt. Plain UUID.

    received_at            TIMESTAMPTZ,
    -- When status transitioned to 'received'.

    -- ── Notes ────────────────────────────────────────────────
    notes                  TEXT,
    -- Optional reason or reference for this transfer.

    -- ── Metadata ─────────────────────────────────────────────
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT stock_transfers_different_locations CHECK (
        source_location_id != destination_location_id
        -- A transfer must move stock between different locations.
    ),

    CONSTRAINT stock_transfers_status_check CHECK (
        status IN ('draft', 'in_transit', 'received', 'cancelled')
    ),

    CONSTRAINT stock_transfers_quantity_positive CHECK (
        quantity_transferred >= 1
    ),

    CONSTRAINT stock_transfers_received_quantity_check CHECK (
        quantity_received IS NULL OR quantity_received >= 0
        -- quantity_received can be 0 if all units were lost in transit.
    ),

    CONSTRAINT stock_transfers_received_dates_consistency CHECK (
        -- received_at must be set when status = 'received'.
        status != 'received' OR received_at IS NOT NULL
    )
);

COMMENT ON TABLE stock_transfers IS
    'Stock movements between locations. In-transit stock tracked explicitly '
    'to prevent double-counting. Inventory mutations happen at status transitions: '
    'draft→in_transit decrements source; in_transit→received increments destination.';

CREATE INDEX idx_stock_transfers_source
    ON stock_transfers (source_location_id, status, created_at DESC);
-- Rationale: Location inventory dashboard shows outbound transfers.
-- Composite covers location filter + status filter + recency sort.

CREATE INDEX idx_stock_transfers_destination
    ON stock_transfers (destination_location_id, status, created_at DESC);
-- Rationale: Location inventory dashboard shows inbound transfers.

CREATE INDEX idx_stock_transfers_variant
    ON stock_transfers (variant_id, status)
    WHERE status IN ('draft', 'in_transit');
-- Rationale: "What transfers are in progress for this variant?"
-- Partial index on active statuses only.

CREATE INDEX idx_stock_transfers_in_transit
    ON stock_transfers (status, initiated_at DESC)
    WHERE status = 'in_transit';
-- Rationale: Operations dashboard flags long-running in-transit transfers
-- that may indicate lost shipments. Partial on in_transit only.
```

---

## Table: `packaging_presets`

```sql
-- ============================================================
-- TABLE: packaging_presets
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Merchant-defined box, envelope, and pallet size
--   configurations used in shipping rate calculation. When a
--   consumer's cart is ready for shipping, KloudShop selects
--   the smallest preset whose max_weight accommodates the total
--   cart weight and uses its dimensions in the carrier rate query.
--
-- BUSINESS RULES:
--   1. Presets are optional. If a merchant has no presets,
--      KloudShop falls back to the carrier API's default packaging
--      assumption (carrier-specific; usually a small parcel).
--   2. is_default = TRUE marks the fallback preset used when no
--      other preset's max_weight fits the cart, or when multiple
--      presets fit and no sorting rule selects a specific one.
--      Application layer enforces at most one is_default = TRUE.
--   3. The preset selection algorithm:
--      (a) Filter presets where max_weight_value >= cart total weight.
--      (b) Sort remaining presets by max_weight_value ASC
--          (select smallest fitting box).
--      (c) If none fit, use is_default = TRUE preset.
--      (d) If no is_default preset, use carrier API default.
--   4. When variant.ships_in_own_packaging = TRUE for all items in
--      the cart, presets are bypassed entirely — the variant's own
--      dimensions are used directly in the carrier rate query.
--   5. dimension_unit and weight_unit must match the tenant's
--      shipping_settings preferences, but this is not enforced
--      at the DB level — the application layer converts units as
--      needed before carrier API calls.
--   6. Presets are informational for carrier rate calculation only.
--      They do not affect stock management or order fulfilment logic.
-- ============================================================

CREATE TABLE packaging_presets (
    preset_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    name             TEXT NOT NULL,
    -- Human-readable preset name. Shown in shipping settings admin.
    -- Examples: 'Small Box', 'Padded Envelope', 'Large Pallet'.

    -- ── Dimensions ───────────────────────────────────────────
    length_value     DECIMAL(10, 2) NOT NULL,
    -- Length (longest dimension). Always > 0.

    width_value      DECIMAL(10, 2) NOT NULL,
    -- Width. Always > 0.

    height_value     DECIMAL(10, 2) NOT NULL,
    -- Height. Always > 0.

    dimension_unit   VARCHAR(4) NOT NULL DEFAULT 'cm',
    -- 'cm' | 'in'

    -- ── Weight Capacity ──────────────────────────────────────
    max_weight_value DECIMAL(10, 3) NOT NULL,
    -- Maximum total cart weight this preset can hold.
    -- Used in the preset selection algorithm (see business rules).
    -- Always > 0.

    max_weight_unit  VARCHAR(4) NOT NULL DEFAULT 'kg',
    -- 'kg' | 'lb'

    -- ── Default Flag ─────────────────────────────────────────
    is_default       BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = fallback when no other preset fits the cart.
    -- Application layer enforces at most one is_default = TRUE.

    -- ── Metadata ─────────────────────────────────────────────
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT packaging_presets_dimension_unit_check CHECK (
        dimension_unit IN ('cm', 'in')
    ),

    CONSTRAINT packaging_presets_weight_unit_check CHECK (
        max_weight_unit IN ('kg', 'lb')
    ),

    CONSTRAINT packaging_presets_length_positive CHECK (length_value > 0),
    CONSTRAINT packaging_presets_width_positive  CHECK (width_value > 0),
    CONSTRAINT packaging_presets_height_positive CHECK (height_value > 0),
    CONSTRAINT packaging_presets_max_weight_positive CHECK (
        max_weight_value > 0
    )
);

COMMENT ON TABLE packaging_presets IS
    'Merchant-defined box sizes for shipping rate calculation. '
    'Algorithm selects smallest preset whose max_weight >= cart weight. '
    'is_default = fallback when no preset fits. Optional — carriers have '
    'their own defaults if no presets are configured.';

CREATE INDEX idx_packaging_presets_weight_asc
    ON packaging_presets (max_weight_value ASC);
-- Rationale: Preset selection algorithm sorts by max_weight_value ASC
-- to find the smallest fitting box. Index makes this sort O(log n).

CREATE INDEX idx_packaging_presets_default
    ON packaging_presets (is_default)
    WHERE is_default = TRUE;
-- Rationale: Fast lookup of the default preset for fallback calculation.
-- Partial index — typically only one row matches.
```

---

## Updated Schema Inventory Entry

After generating this artifact, update `06-schema-inventory.md`:

```
| `06d-tenant-inventory-schema.md` | ✅ Generated | 5 | Stock locations, inventory (generated quantity_available), reservations, transfers, packaging presets |
```
