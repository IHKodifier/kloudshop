# 06e — Tenant Supplier Schema
# KloudShop Stage 6 — Data Model

> **Artifact:** `06e-tenant-supplier-schema.md`
> **Schema:** `tenant_{tenant_id}` (one schema per merchant, provisioned at signup)
> **Persona:** Principal Data Engineer
> **Reads from:** `01-product-brief.md`, `01b-tech-stack.md`, `02-architecture.md`,
>   `03-user-journeys.md`, `04-feature-stories.md`, `04b-mvp-scope.md`,
>   `00-carry-forward-flags.md` (DMF-01 through DMF-10, DMF-07 in particular)
> **Depends on:** `06b-tenant-catalog-schema.md` (variants FK on purchase_order_lines,
>   product_suppliers),
>   `06d-tenant-inventory-schema.md` (stock_locations FK on purchase_orders — for
>   future receiving-location attribution; forward-declared as plain UUID)
> **Tables:** 6 (suppliers, purchase_orders, purchase_order_lines,
>   supplier_performance_events, supplier_score_weights, shipping_settings)
> **Status:** ✅ Generated

---

## Overview

This artifact defines the supplier management, procurement, and shipping
configuration schema for a KloudShop merchant tenant. All six tables live
inside `tenant_{tenant_id}` and are provisioned at signup as part of the base
Alembic migration — none are feature-gated.

**Key design decisions reflected in this schema:**

- **`suppliers` uses `ON DELETE RESTRICT` everywhere** — a supplier with any
  purchase orders (open or historical) must never be silently deleted. The
  application layer blocks deletion and offers archiving as the safe alternative.
  `status = 'archived'` is the permanent soft-deactivation path.

- **`purchase_order_lines.manufacture_date DATE`** — for perishable variants
  (`variants.is_perishable = TRUE`), the batch manufacture date is recorded at
  goods receipt on each PO line. Expiry is computed as:
  `manufacture_date + variants.best_before_days`. This field is NULL for
  non-perishable items. The manufacture date is a per-batch operational datum,
  not a product property — it belongs here, not on the variants table.

- **`supplier_score_weights` is one row per tenant** — same pattern as
  `seo_settings`. Use upsert with a fixed seed UUID; never plain INSERT.
  The composite score formula is:
  `score = (on_time_rate × on_time_weight) + (fill_rate × fill_rate_weight)
           + (quality_score × quality_weight) + (price_stability × price_stability_weight)`
  Weights are merchant-adjustable. Defaults sum to 1.00.

- **`shipping_settings` is one row per tenant** — holds the tenant-level
  weight/dimension defaults from DMF-01, plus `handling_days` and
  `order_cutoff_time` required for estimated delivery date calculation at
  checkout. Created by base Alembic migration. Use upsert; never plain INSERT.

- **`supplier_performance_events` is append-only** — no UPDATE, no DELETE.
  It is the raw event ledger from which BigQuery computes supplier scorecard
  metrics (on-time rates, fill rates, quality event rates). The KloudShop
  composite score is never stored here — it lives in the BigQuery
  `supplier_scores` materialised view refreshed daily.

- **`product_suppliers` is NOT in this artifact** — it is defined in
  `06b-tenant-catalog-schema.md` as the join table between variants and
  suppliers (DMF-07). This artifact defines the `suppliers` entity that
  `product_suppliers` references.

**AI agent note:** `shipping_settings` and `supplier_score_weights` are
single-row tables. Never INSERT a second row — always use upsert
(`INSERT ... ON CONFLICT DO UPDATE`). The `seo_settings_id` and
`supplier_score_weights_id` PKs are generated once at tenant provisioning
and never change. Both tables are provisioned with seed rows by the base
Alembic migration.

---

## Table: `suppliers`

```sql
-- ============================================================
-- TABLE: suppliers
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per supplier. Supplier is a business entity
--   that provides goods to the merchant. A supplier can be
--   assigned to one or more product variants (via product_suppliers).
--   Supplier performance is tracked via supplier_performance_events.
--
-- BUSINESS RULES:
--   1. Deletion is BLOCKED at application layer if the supplier
--      has any purchase_orders rows (in any status). The application
--      must check before allowing delete; the DB enforces via RESTRICT
--      FK on purchase_orders.supplier_id.
--      'archived' status is the correct deactivation path — the
--      supplier row is retained for historical PO records and analytics.
--   2. status lifecycle:
--      'active'   — available for PO creation and variant assignment
--      'inactive' — temporarily suspended (e.g. awaiting contract renewal).
--                   Not available for new POs. Existing variant assignments
--                   retained; AI replenishment engine skips inactive suppliers.
--      'archived' — permanently decommissioned. No new POs. No new variant
--                   assignments. Historical records fully preserved.
--   3. default_lead_time_days is the supplier's global lead time.
--      It is used in the replenishment engine and dashboard urgency
--      calculations unless overridden by product_suppliers.lead_time_override_days
--      for a specific variant.
--   4. payment_terms is free text (e.g. 'Net-30', 'Prepayment', 'COD').
--      Not machine-parsed — for merchant reference only.
--   5. currency is the supplier's billing currency (ISO 4217).
--      Unit costs in product_suppliers.unit_cost are stored in this
--      currency. Conversion to merchant's display currency happens at
--      application layer for analytics.
--   6. On-the-fly supplier creation (during product/inventory entry)
--      must use an inline modal that returns to the caller on save.
--      The FK from product_suppliers to suppliers uses RESTRICT —
--      deleting a supplier that has variant assignments is blocked.
-- ============================================================

CREATE TABLE suppliers (
    supplier_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- ── Identity ─────────────────────────────────────────────
    name                     TEXT NOT NULL,
    -- Supplier company name. Shown in admin, POs, replenishment panel.

    -- ── Contact ──────────────────────────────────────────────
    contact_name             TEXT,
    -- Primary contact person at this supplier. Optional.

    contact_email            TEXT,
    -- Email address for sending purchase orders (via Resend).
    -- NULL = POs cannot be emailed; merchant must export and send manually.

    contact_phone            TEXT,
    -- Optional phone number for supplier contact.

    -- ── Address ──────────────────────────────────────────────
    address_line1            TEXT,
    address_line2            TEXT,
    city                     TEXT,
    state                    TEXT,
    postcode                 TEXT,
    country_code             CHAR(2),
    -- ISO 3166-1 alpha-2. Used for shipping origin analytics.

    -- ── Commercial Terms ─────────────────────────────────────
    payment_terms            TEXT,
    -- Free-text payment terms. Example: 'Net-30', 'Prepayment', 'COD'.
    -- For merchant reference only — not machine-parsed.

    default_lead_time_days   INTEGER,
    -- Global lead time in business days for this supplier.
    -- Used in replenishment urgency calculations and reorder point dates.
    -- NULL = lead time not configured; urgency colouring uses raw stock days.
    -- Overridden per-variant by product_suppliers.lead_time_override_days.

    currency                 CHAR(3) NOT NULL DEFAULT 'USD',
    -- ISO 4217 currency code for this supplier's pricing.
    -- Unit costs in product_suppliers.unit_cost are in this currency.

    -- ── Status ───────────────────────────────────────────────
    status                   VARCHAR(16) NOT NULL DEFAULT 'active',
    -- 'active' | 'inactive' | 'archived'
    -- See business rules. Archived suppliers cannot be unarchived
    -- without platform admin intervention — use 'inactive' for
    -- temporary suspension.

    -- ── Internal Notes ───────────────────────────────────────
    notes                    TEXT,
    -- Merchant's private notes on this supplier.
    -- Examples: "Preferred packaging specs", "Contact via WhatsApp".

    -- ── Metadata ─────────────────────────────────────────────
    created_by               UUID NOT NULL,
    -- staff_user_id who created this supplier record. Plain UUID.

    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT suppliers_status_check CHECK (
        status IN ('active', 'inactive', 'archived')
    ),
    CONSTRAINT suppliers_lead_time_positive CHECK (
        default_lead_time_days IS NULL OR default_lead_time_days >= 1
    ),
    CONSTRAINT suppliers_currency_length CHECK (
        char_length(currency) = 3
    )
);

COMMENT ON TABLE suppliers IS
    'One row per supplier. Deletion blocked when purchase orders exist — '
    'archive instead. default_lead_time_days drives replenishment urgency '
    'calculations; overridden per-variant in product_suppliers. '
    'currency = ISO 4217 code for unit_cost values in product_suppliers.';

CREATE INDEX idx_suppliers_status
    ON suppliers (status, name)
    WHERE status = 'active';
-- Rationale: Supplier selector dropdown in product editor and PO draft
-- shows only active suppliers, sorted alphabetically by name.
-- Partial index on active suppliers only — keeps it small.

CREATE INDEX idx_suppliers_name_trgm
    ON suppliers USING GIN (name gin_trgm_ops);
-- Rationale: Supplier search in the admin uses trigram similarity
-- (pg_trgm) for fuzzy name matching. GIN index is required for
-- fast ILIKE / similarity queries on supplier names.

CREATE INDEX idx_suppliers_all_statuses
    ON suppliers (status, name);
-- Rationale: Supplier management screen shows all suppliers (including
-- inactive/archived) in the full list view, sortable by name.
-- Separate from the active-only partial index above.
```

---

## Table: `purchase_orders`

```sql
-- ============================================================
-- TABLE: purchase_orders
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per purchase order. A PO is raised against
--   a single supplier and contains one or more line items
--   (purchase_order_lines). Tracks the full lifecycle from draft
--   to fully received.
--
-- BUSINESS RULES:
--   1. A PO is always associated with exactly one supplier.
--      supplier_id uses ON DELETE RESTRICT — deleting a supplier
--      with POs is blocked at the DB level as well as application layer.
--   2. status lifecycle:
--      'draft'     — PO is being built. Line items can be added,
--                    removed, or modified. No inventory changes yet.
--      'sent'      — PO has been emailed to the supplier. Line items
--                    are now locked — no modifications. Merchant can
--                    cancel (transitions to 'cancelled').
--      'acknowledged'— Supplier has confirmed receipt of the PO.
--                    Optional status — not all suppliers use this step.
--      'partial'   — At least one line item has been partially received
--                    (quantity_received < quantity_ordered on some lines).
--      'received'  — All line items fully received (quantity_received
--                    = quantity_ordered on all lines). Terminal state.
--      'cancelled' — PO cancelled before full receipt. If any goods
--                    were partially received before cancellation,
--                    those goods are retained in inventory.
--   3. expected_delivery_at is the anticipated delivery date based
--      on the supplier's lead time at time of PO creation.
--      = ordered_at + supplier.default_lead_time_days (or variant-
--      level lead_time_override_days for specific lines).
--      Not enforced by the DB — used for supplier performance analytics
--      and dashboard urgency colouring.
--   4. receiving_location_id is the stock location where goods will
--      be received. This determines which inventory rows are
--      incremented on receipt. Stored as plain UUID — references
--      stock_locations.stock_location_id. Application layer validates.
--   5. po_number is the human-readable reference shown in the admin,
--      on PO documents, and in supplier emails.
--      Format: PO-{sequential_number} e.g. 'PO-0042'.
--      Unique within tenant. Generated at application layer.
--   6. total_cost_usd is the sum of (quantity_ordered × unit_cost)
--      across all purchase_order_lines. Denormalised for admin
--      display — recomputed by the application when lines are updated.
--      Not a source of financial truth (that is BigQuery analytics).
-- ============================================================

CREATE TABLE purchase_orders (
    po_id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- ── Identity ─────────────────────────────────────────────
    po_number             VARCHAR(32) NOT NULL,
    -- Human-readable PO reference. Format: 'PO-0042'.
    -- Unique within tenant. Generated at application layer.

    supplier_id           UUID NOT NULL
                          REFERENCES suppliers (supplier_id)
                          ON DELETE RESTRICT,
    -- RESTRICT: PO records must never be auto-deleted when a supplier
    -- is removed. Supplier deletion is already blocked by this constraint.

    -- ── Status ───────────────────────────────────────────────
    status                VARCHAR(16) NOT NULL DEFAULT 'draft',
    -- 'draft' | 'sent' | 'acknowledged' | 'partial' | 'received' | 'cancelled'
    -- See business rules for inventory mutation timing per transition.

    -- ── Receiving Location ───────────────────────────────────
    receiving_location_id UUID,
    -- stock_locations.stock_location_id where goods will be received.
    -- Plain UUID — application validates against stock_locations.
    -- NULL = not yet assigned (acceptable for draft POs).
    -- Must be set before status can transition to 'sent'.

    -- ── Dates ────────────────────────────────────────────────
    ordered_at            TIMESTAMPTZ,
    -- When the PO was sent to the supplier (status → 'sent').
    -- NULL for draft POs.

    expected_delivery_at  TIMESTAMPTZ,
    -- Anticipated delivery date. Used for urgency colouring and
    -- supplier on-time rate calculations.
    -- = ordered_at + effective lead time at time of sending.
    -- NULL for draft POs. May be updated if supplier revises.

    received_at           TIMESTAMPTZ,
    -- When the last line item was fully received (status → 'received').
    -- NULL until fully received.

    cancelled_at          TIMESTAMPTZ,
    -- When the PO was cancelled. NULL if not cancelled.

    -- ── Financial Summary ─────────────────────────────────────
    total_cost            DECIMAL(14, 4),
    -- Sum of (line.quantity_ordered × line.unit_cost) across all lines.
    -- Denormalised for admin display. Recomputed by application when
    -- lines are updated. NULL for POs with no cost data.

    total_cost_currency   CHAR(3),
    -- Currency of total_cost. Matches supplier.currency at PO creation.
    -- NULL when total_cost is NULL.

    -- ── Metadata ─────────────────────────────────────────────
    notes                 TEXT,
    -- Internal merchant notes on this PO (e.g. special packaging,
    -- delivery instructions to include in the email).

    sent_by               UUID,
    -- staff_user_id who sent (emailed) this PO. Plain UUID.
    -- NULL for draft POs or auto-generated POs.

    created_by            UUID NOT NULL,
    -- staff_user_id who created this PO. Plain UUID.

    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT purchase_orders_po_number_unique UNIQUE (po_number),

    CONSTRAINT purchase_orders_status_check CHECK (
        status IN (
            'draft', 'sent', 'acknowledged',
            'partial', 'received', 'cancelled'
        )
    ),

    CONSTRAINT purchase_orders_date_consistency CHECK (
        -- ordered_at must be set when status != 'draft' and != 'cancelled'
        -- with no ordering activity. Allow NULL for cancelled-before-send.
        status = 'draft'
        OR cancelled_at IS NOT NULL
        OR ordered_at IS NOT NULL
    ),

    CONSTRAINT purchase_orders_received_date_consistency CHECK (
        -- received_at must be set when status = 'received'.
        status != 'received' OR received_at IS NOT NULL
    ),

    CONSTRAINT purchase_orders_total_cost_currency_consistency CHECK (
        -- total_cost and total_cost_currency must both be set or both NULL.
        (total_cost IS NULL AND total_cost_currency IS NULL)
        OR (total_cost IS NOT NULL AND total_cost_currency IS NOT NULL)
    )
);

COMMENT ON TABLE purchase_orders IS
    'One row per purchase order against a single supplier. '
    'status lifecycle: draft→sent→acknowledged→partial→received (or cancelled). '
    'receiving_location_id determines which stock_location inventory is incremented. '
    'total_cost is denormalised for display — not a financial source of truth.';

CREATE UNIQUE INDEX idx_purchase_orders_po_number
    ON purchase_orders (po_number);
-- Rationale: PO lookup by human-readable number in admin, supplier
-- emails, and performance event correlation. Must be O(1).

CREATE INDEX idx_purchase_orders_supplier
    ON purchase_orders (supplier_id, status, created_at DESC);
-- Rationale: Supplier detail view shows all POs for a supplier,
-- filterable by status and sorted by recency. Composite covers all
-- three dimensions in one index.

CREATE INDEX idx_purchase_orders_status_open
    ON purchase_orders (status, expected_delivery_at ASC)
    WHERE status IN ('sent', 'acknowledged', 'partial');
-- Rationale: Operations dashboard shows open POs ordered by expected
-- delivery date (earliest first = most urgent). Partial index on
-- active statuses only — draft and terminal POs excluded.

CREATE INDEX idx_purchase_orders_receiving_location
    ON purchase_orders (receiving_location_id, status)
    WHERE receiving_location_id IS NOT NULL
      AND status IN ('sent', 'acknowledged', 'partial');
-- Rationale: Per-location goods receipt queue — "what POs are expected
-- at this warehouse?" Partial on assigned, open POs only.

CREATE INDEX idx_purchase_orders_overdue
    ON purchase_orders (expected_delivery_at, supplier_id)
    WHERE status IN ('sent', 'acknowledged', 'partial')
      AND expected_delivery_at IS NOT NULL;
-- Rationale: Supplier performance monitoring — identifies POs past
-- their expected delivery date that have not been received yet.
-- Used to compute late_delivery events and on-time rate scores.

CREATE INDEX idx_purchase_orders_all_statuses
    ON purchase_orders (status, created_at DESC);
-- Rationale: Supports full state machine transition history filtering and
-- general admin list views that include draft and terminal POs.
```

---

## Table: `purchase_order_lines`

```sql
-- ============================================================
-- TABLE: purchase_order_lines
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per variant per purchase order. Tracks ordered
--   quantity, received quantity, unit cost, and — critically —
--   the manufacture date of the received batch (for perishable
--   variants). Also records any quantity discrepancies found at
--   goods receipt.
--
-- BUSINESS RULES:
--   1. variant_id uses ON DELETE RESTRICT — a variant with PO line
--      history must not be deleted (it may have active or historical
--      receipt records). Variants should be deactivated, not deleted.
--   2. quantity_ordered is set when the PO is created and locked
--      when the PO status transitions to 'sent'. No modifications
--      after sending without cancelling and recreating the PO.
--   3. quantity_received is NULL until goods are received. Set
--      to the actual count on goods receipt. May be less than
--      quantity_ordered (short shipment) or, in rare cases, more
--      (overage). The discrepancy_flag is set when they differ.
--   4. manufacture_date DATE — the batch manufacture date for
--      perishable items. Recorded at goods receipt by the merchant.
--      NULL for non-perishable variants and before receipt.
--      EXPIRY CALCULATION: expiry_date = manufacture_date + variants.best_before_days
--      This computation is done at application layer; it is not
--      stored in this table (too volatile — best_before_days can
--      be updated on the variant if the specification changes).
--      Batch traceability: lot_number on variants.lot_number is
--      updated from this field at goods receipt for the received variant.
--   5. unit_cost is the actual unit cost on this PO, at the time
--      of the PO. May differ from product_suppliers.unit_cost if
--      the supplier has revised pricing. Historical cost accuracy
--      requires snapshotting here — never back-calculated from
--      the product_suppliers table.
--   6. supplier_id on the line level allows split POs where different
--      variants come from different sub-suppliers within the same PO.
--      In practice, most POs have all lines from the same supplier
--      as the PO header (purchase_orders.supplier_id). The line-level
--      supplier_id is included for correctness and future flexibility.
--   7. discrepancy_notes is mandatory when discrepancy_flag = TRUE.
--      Enforced at application layer — not a DB constraint (the note
--      may be filled in asynchronously after flagging).
-- ============================================================

CREATE TABLE purchase_order_lines (
    po_line_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    po_id               UUID NOT NULL
                        REFERENCES purchase_orders (po_id)
                        ON DELETE CASCADE,
    -- CASCADE: deleting a PO removes all its line items.
    -- POs are never hard-deleted in practice (they are cancelled),
    -- but CASCADE is the safe default.

    -- ── Variant ──────────────────────────────────────────────
    variant_id          UUID NOT NULL
                        REFERENCES variants (variant_id)
                        ON DELETE RESTRICT,
    -- RESTRICT: never auto-delete PO lines if a variant is deleted.
    -- Variants with PO line history must be deactivated, not deleted.

    supplier_id         UUID NOT NULL
                        REFERENCES suppliers (supplier_id)
                        ON DELETE RESTRICT,
    -- Line-level supplier. Usually matches po_id→supplier_id.
    -- RESTRICT: PO line records must not be auto-deleted on supplier removal.

    -- ── Ordering ─────────────────────────────────────────────
    quantity_ordered    INTEGER NOT NULL,
    -- Number of units ordered. Set at PO creation. >= 1.
    -- Locked after PO status → 'sent'.

    unit_cost           DECIMAL(12, 4),
    -- Unit cost at time of ordering. Snapshotted from product_suppliers
    -- or entered manually. NULL if not tracked (some merchants do not
    -- record cost per PO line).

    unit_cost_currency  CHAR(3),
    -- Currency of unit_cost. Matches supplier.currency. NULL when
    -- unit_cost is NULL.

    -- ── Receipt ──────────────────────────────────────────────
    quantity_received   INTEGER,
    -- Actual units received. NULL until goods receipt event occurs.
    -- May be < quantity_ordered (short shipment — discrepancy_flag = TRUE).
    -- May be > quantity_ordered (overage — discrepancy_flag = TRUE).
    -- May be = quantity_ordered (correct fulfilment — discrepancy_flag = FALSE).
    -- May be 0 (entire line not delivered — discrepancy_flag = TRUE).

    received_at         TIMESTAMPTZ,
    -- When this line was received (goods receipt recorded by merchant).
    -- NULL until received. A line can be received independently of
    -- other lines in the same PO (partial receipts are valid).

    -- ── Perishable Batch Tracking ────────────────────────────
    manufacture_date    DATE,
    -- The manufacture date of the batch received on this PO line.
    -- NULL for non-perishable variants (variants.is_perishable = FALSE).
    -- NULL before goods receipt even for perishable variants.
    --
    -- EXPIRY COMPUTATION (application layer, not stored):
    --   expiry_date = manufacture_date + variants.best_before_days
    --
    -- At goods receipt, the application also updates
    -- variants.lot_number with the batch identifier associated with
    -- this manufacture_date. This enables recall traceability:
    -- "which orders contained lot X?" is answerable by joining
    -- purchase_order_lines → purchase_orders → receiving_location_id
    -- → inventory → order_items → orders.
    --
    -- Post-MVP: an inventory_batches table will track per-batch
    -- stock levels with manufacture dates for FIFO/FEFO rotation.

    -- ── Discrepancy ──────────────────────────────────────────
    discrepancy_flag    BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE when quantity_received != quantity_ordered, or when a
    -- quality issue is identified at goods receipt.
    -- Also TRUE for overages (quantity_received > quantity_ordered).

    discrepancy_notes   TEXT,
    -- Human-readable description of the discrepancy.
    -- Examples: "Received 47 of 50 ordered", "3 units damaged on arrival".
    -- Application layer enforces this is filled when discrepancy_flag = TRUE.

    -- ── Metadata ─────────────────────────────────────────────
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT po_lines_quantity_ordered_positive CHECK (
        quantity_ordered >= 1
    ),

    CONSTRAINT po_lines_quantity_received_non_negative CHECK (
        quantity_received IS NULL OR quantity_received >= 0
        -- 0 is valid: entire line not delivered.
    ),

    CONSTRAINT po_lines_unit_cost_non_negative CHECK (
        unit_cost IS NULL OR unit_cost >= 0
    ),

    CONSTRAINT po_lines_received_date_consistency CHECK (
        -- received_at must be set when quantity_received is set.
        (quantity_received IS NULL AND received_at IS NULL)
        OR (quantity_received IS NOT NULL AND received_at IS NOT NULL)
    ),

    CONSTRAINT po_lines_unit_cost_currency_consistency CHECK (
        (unit_cost IS NULL AND unit_cost_currency IS NULL)
        OR (unit_cost IS NOT NULL AND unit_cost_currency IS NOT NULL)
    ),

    CONSTRAINT po_lines_manufacture_date_sanity CHECK (
        -- manufacture_date must not be in the future.
        -- (goods cannot be manufactured after they are received)
        manufacture_date IS NULL
        OR manufacture_date <= CURRENT_DATE
    )
);

COMMENT ON TABLE purchase_order_lines IS
    'One row per variant per PO. manufacture_date records the batch manufacture '
    'date for perishable variants at goods receipt — NULL for non-perishable. '
    'Expiry = manufacture_date + variants.best_before_days (computed at app layer). '
    'discrepancy_flag set when quantity_received != quantity_ordered.';

CREATE INDEX idx_po_lines_po_id
    ON purchase_order_lines (po_id);
-- Rationale: PO detail view fetches all line items for a PO.
-- Most frequent read pattern on this table.

CREATE INDEX idx_po_lines_variant
    ON purchase_order_lines (variant_id, received_at DESC);
-- Rationale: Variant receipt history — "when was this variant last received
-- and at what cost?" Used for cost analytics and supplier comparison.

CREATE INDEX idx_po_lines_supplier
    ON purchase_order_lines (supplier_id, received_at DESC)
    WHERE received_at IS NOT NULL;
-- Rationale: Supplier fill-rate calculation — "how many units ordered from
-- this supplier were actually received?" Partial on received lines only.

CREATE INDEX idx_po_lines_discrepancy
    ON purchase_order_lines (po_id, discrepancy_flag)
    WHERE discrepancy_flag = TRUE;
-- Rationale: PO receipt reconciliation view highlights all discrepant
-- lines across a PO. Partial on flagged lines only.

CREATE INDEX idx_po_lines_manufacture_date
    ON purchase_order_lines (variant_id, manufacture_date DESC)
    WHERE manufacture_date IS NOT NULL;
-- Rationale: Perishable batch traceability — "what is the most recent
-- manufacture date for this variant?" Used for stock expiry monitoring
-- and recall management. Partial on lines that have manufacture dates.

CREATE INDEX idx_po_lines_pending_receipt
    ON purchase_order_lines (po_id, variant_id)
    WHERE quantity_received IS NULL;
-- Rationale: Goods receipt screen shows all unreceived lines for a PO.
-- Partial index on pending lines only — received lines are historical.
```

---

## Table: `supplier_performance_events`

```sql
-- ============================================================
-- TABLE: supplier_performance_events
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Append-only ledger of performance events logged
--   against a supplier. These events are the raw inputs to the
--   supplier scorecard analytics computed in BigQuery.
--   This table is NEVER queried for real-time scorecard display —
--   scores are read from the BigQuery supplier_scores materialised
--   view. This table is the audit source.
--
-- BUSINESS RULES:
--   1. Append-only. No UPDATE. No DELETE. Ever.
--      Performance events are immutable audit records.
--      If a merchant logs an event in error, they log a corrective
--      event (e.g. a 'correct_shipment' note can offset an
--      erroneous 'short_shipment' event at analytics level).
--   2. event_type covers all performance signal categories:
--      NEGATIVE: 'late_delivery', 'short_shipment', 'quality_issue',
--                'damaged_goods', 'price_increase'
--      POSITIVE: 'early_delivery', 'correct_shipment', 'price_decrease',
--                'exceptional_service'
--   3. po_id links the event to a specific purchase order.
--      NULL is allowed only for events not tied to a specific PO
--      (e.g. a price increase notification received outside of an order).
--   4. severity is only meaningful for NEGATIVE events.
--      NULL for positive events.
--      'minor'    — minor inconvenience, no operational impact
--      'moderate' — operational impact (e.g. delayed product launch)
--      'severe'   — significant business impact (e.g. stockout caused)
--   5. logged_by is the staff_user_id who manually logged this event.
--      Plain UUID — cross-schema reference.
--   6. BigQuery job: Cloud Tasks scheduled job reads this table daily
--      and aggregates into the supplier_scores materialised view.
--      The composite score formula (from supplier_score_weights) is
--      applied in BigQuery, not in PostgreSQL.
-- ============================================================

CREATE TABLE supplier_performance_events (
    event_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    supplier_id      UUID NOT NULL
                     REFERENCES suppliers (supplier_id)
                     ON DELETE RESTRICT,
    -- RESTRICT: never auto-delete performance history if a supplier row
    -- is somehow deleted. Supplier deletion is already blocked by PO FKs.

    po_id            UUID
                     REFERENCES purchase_orders (po_id)
                     ON DELETE RESTRICT,
    -- Optional link to a specific PO. RESTRICT: retain event if PO is
    -- somehow deleted (POs are never deleted in practice).
    -- NULL for events not tied to a specific PO.

    po_line_id       UUID
                     REFERENCES purchase_order_lines (po_line_id)
                     ON DELETE RESTRICT,
    -- Optional link to a specific PO line (e.g. a quality issue on one
    -- variant within a multi-line PO). NULL for PO-level events.

    -- ── Event Classification ──────────────────────────────────
    event_type       VARCHAR(32) NOT NULL,
    -- The performance signal type. See business rules.
    -- NEGATIVE: 'late_delivery' | 'short_shipment' | 'quality_issue'
    --           | 'damaged_goods' | 'price_increase'
    -- POSITIVE: 'early_delivery' | 'correct_shipment' | 'price_decrease'
    --           | 'exceptional_service'

    severity         VARCHAR(16),
    -- Only meaningful for negative events. NULL for positive events.
    -- 'minor' | 'moderate' | 'severe'

    -- ── Details ──────────────────────────────────────────────
    notes            TEXT,
    -- Human-readable description of the event. Optional but encouraged.
    -- Examples: "Arrived 4 days late — delayed product launch",
    --           "3 of 50 units cracked on arrival".

    -- ── Attribution ──────────────────────────────────────────
    logged_by        UUID NOT NULL,
    -- staff_user_id who logged this event. Plain UUID.

    -- ── Timestamp ────────────────────────────────────────────
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- When the event was logged. Immutable.

    CONSTRAINT supplier_performance_events_event_type_check CHECK (
        event_type IN (
            'late_delivery', 'short_shipment', 'quality_issue',
            'damaged_goods', 'price_increase',
            'early_delivery', 'correct_shipment', 'price_decrease',
            'exceptional_service'
        )
    ),

    CONSTRAINT supplier_performance_events_severity_check CHECK (
        severity IN ('minor', 'moderate', 'severe') OR severity IS NULL
    ),

    CONSTRAINT supplier_performance_events_severity_only_negative CHECK (
        -- severity is only meaningful for negative events.
        severity IS NULL
        OR event_type IN (
            'late_delivery', 'short_shipment', 'quality_issue',
            'damaged_goods', 'price_increase'
        )
    ),

    CONSTRAINT supplier_performance_events_po_line_requires_po CHECK (
        -- Cannot link to a PO line without also linking to its parent PO.
        po_line_id IS NULL OR po_id IS NOT NULL
    )
);

COMMENT ON TABLE supplier_performance_events IS
    'Append-only supplier performance ledger. No UPDATE, no DELETE ever. '
    'Raw inputs for BigQuery supplier scorecard analytics. '
    'Negative events have severity (minor/moderate/severe); positive events do not. '
    'BigQuery supplier_scores materialised view refreshed daily from this table.';

CREATE INDEX idx_supplier_perf_events_supplier
    ON supplier_performance_events (supplier_id, created_at DESC);
-- Rationale: Supplier scorecard history view — all events for a supplier
-- in reverse chronological order. Primary read pattern on this table.

CREATE INDEX idx_supplier_perf_events_po
    ON supplier_performance_events (po_id)
    WHERE po_id IS NOT NULL;
-- Rationale: PO detail view shows all performance events linked to a
-- specific PO. Partial index on linked events only.

CREATE INDEX idx_supplier_perf_events_type
    ON supplier_performance_events (supplier_id, event_type, created_at DESC);
-- Rationale: BigQuery export and analytics filter by event_type to
-- compute on-time rates (late_delivery count / total POs) and quality
-- event rates. Composite covers supplier + type + time window.

CREATE INDEX idx_supplier_perf_events_negative_severity
    ON supplier_performance_events (supplier_id, severity, created_at DESC)
    WHERE severity IS NOT NULL;
-- Rationale: Severity-weighted scoring — 'severe' events carry more
-- weight in the composite quality score. Partial on events that have
-- a severity value (negative events only).
```

---

## Table: `supplier_score_weights`

```sql
-- ============================================================
-- TABLE: supplier_score_weights
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per tenant. Merchant-adjustable weights for
--   the composite supplier score formula. Defaults sum to 1.00.
--   This table is a single-row configuration table — use upsert,
--   never plain INSERT (base Alembic migration inserts the seed row).
--
-- COMPOSITE SCORE FORMULA:
--   score = (on_time_rate    × on_time_weight)
--         + (fill_rate       × fill_rate_weight)
--         + (quality_score   × quality_weight)
--         + (price_stability × price_stability_weight)
--
--   Where:
--     on_time_rate    = orders received on/before expected_delivery / total
--     fill_rate       = total qty_received / total qty_ordered
--     quality_score   = 100 - quality_event_rate (inverted: lower events = higher score)
--     price_stability = inverted standard deviation of unit_cost over trailing 12 months
--
--   The formula is applied in BigQuery (supplier_scores materialised view),
--   not in PostgreSQL. This table provides only the weight parameters.
--
-- BUSINESS RULES:
--   1. Single-row table. Use upsert; never plain INSERT after provisioning.
--   2. Weights must sum to exactly 1.00. Enforced by CHECK constraint.
--   3. All weights must be >= 0.00 and <= 1.00.
--   4. When a merchant adjusts weights, the composite scores for ALL
--      their suppliers are recomputed in BigQuery on the next daily job.
--      Scores are never stored in PostgreSQL.
--   5. Reset to defaults button in admin UX calls upsert with the
--      default values (0.35, 0.25, 0.25, 0.15).
-- ============================================================

CREATE TABLE supplier_score_weights (
    score_weights_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Single-row sentinel. Never generate a second row.
    -- Base Alembic migration inserts this with a fixed UUID.

    on_time_weight       DECIMAL(4, 2) NOT NULL DEFAULT 0.35,
    -- Weight for on-time delivery rate in composite score.
    -- Default: 0.35 (35% of composite score).

    fill_rate_weight     DECIMAL(4, 2) NOT NULL DEFAULT 0.25,
    -- Weight for fill rate (quantity accuracy) in composite score.
    -- Default: 0.25 (25% of composite score).

    quality_weight       DECIMAL(4, 2) NOT NULL DEFAULT 0.25,
    -- Weight for quality score (inverted quality event rate).
    -- Default: 0.25 (25% of composite score).

    price_stability_weight DECIMAL(4, 2) NOT NULL DEFAULT 0.15,
    -- Weight for price stability (inverted price variance).
    -- Default: 0.15 (15% of composite score).

    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- When the weights were last adjusted. No created_at — this is
    -- a single seed row that is only ever updated, never inserted again.

    CONSTRAINT supplier_score_weights_sum_to_one CHECK (
        -- All four weights must sum to exactly 1.00.
        -- NUMERIC arithmetic is exact at 4,2 precision.
        on_time_weight + fill_rate_weight + quality_weight + price_stability_weight = 1.00
    ),

    CONSTRAINT supplier_score_weights_on_time_range CHECK (
        on_time_weight >= 0.00 AND on_time_weight <= 1.00
    ),
    CONSTRAINT supplier_score_weights_fill_rate_range CHECK (
        fill_rate_weight >= 0.00 AND fill_rate_weight <= 1.00
    ),
    CONSTRAINT supplier_score_weights_quality_range CHECK (
        quality_weight >= 0.00 AND quality_weight <= 1.00
    ),
    CONSTRAINT supplier_score_weights_price_stability_range CHECK (
        price_stability_weight >= 0.00 AND price_stability_weight <= 1.00
    )
);

COMMENT ON TABLE supplier_score_weights IS
    'Single-row tenant config for composite supplier score formula weights. '
    'All four weights must sum to 1.00 (enforced by CHECK constraint). '
    'Composite score computation happens in BigQuery supplier_scores view — '
    'not in PostgreSQL. Use upsert; never plain INSERT after provisioning. '
    'Defaults: on_time=0.35, fill_rate=0.25, quality=0.25, price_stability=0.15.';

-- No indexes needed — single row table. PK lookup is always O(1).
-- The BigQuery job reads this via FastAPI /supplier-score-weights
-- endpoint; no direct DB index is required for this access pattern.
```

---

## Table: `shipping_settings`

```sql
-- ============================================================
-- TABLE: shipping_settings
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per tenant. Global shipping configuration:
--   default weight/dimension units, default package weight fallback
--   for products without weight configured, handling days (how many
--   business days the merchant needs to pack and hand off to carrier),
--   and order_cutoff_time (the daily cut-off after which orders are
--   treated as next-business-day for handling calculation).
--
--   This is the DMF-01 tenant-level shipping_settings table.
--   It holds only merchant-specific preferences that genuinely vary
--   per merchant. Carrier definitions and service levels live in
--   the platform schema (06a2).
--
-- BUSINESS RULES:
--   1. Single-row table. Use upsert; never plain INSERT after the
--      base Alembic migration inserts the seed row.
--   2. default_weight_value and default_weight_unit are the fallback
--      used in shipping rate calculation when a variant has no weight
--      set and the product has no weight fallback either. This is the
--      bottom of the DMF-01 fallback resolution chain:
--      1. variants.weight_value (per-variant)
--      2. products.weight_value (product-level fallback)
--      3. shipping_settings.default_weight_value (this field)
--      4. Carrier API default packaging assumption (no DB field)
--   3. weight_unit_preference and dimension_unit_preference control
--      which units are shown in the admin UI for weight and dimension
--      inputs throughout the product editor and shipping settings.
--      Does NOT affect storage — weights and dimensions on products
--      and variants are stored in whatever unit the merchant entered.
--      The application layer converts for rate calculation.
--   4. handling_days is the number of BUSINESS DAYS between order
--      placement and carrier pickup/handoff.
--      Example: handling_days = 1 means an order placed today ships
--      tomorrow (assuming before order_cutoff_time).
--   5. order_cutoff_time is the LOCAL time of day (merchant's timezone)
--      before which an order counts as "placed today" for handling
--      calculation. After this time, handling_days count starts from
--      the next business day.
--      Example: order_cutoff_time = '14:00' → orders before 2pm ship
--      in handling_days days; orders after 2pm ship in handling_days+1 days.
--      Stored as TIME (no date, no timezone). The merchant's timezone
--      is stored on brand_profiles (06g). Application layer combines.
--   6. free_shipping_threshold_amount and free_shipping_threshold_currency:
--      If set, orders with a subtotal >= this amount qualify for free
--      shipping. NULL = no free shipping threshold configured.
--      This is the tenant-level global threshold; product-level or
--      collection-level free shipping rules are feature-gated (dynamic
--      pricing / discount engine — 06m).
-- ============================================================

CREATE TABLE shipping_settings (
    shipping_settings_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Single-row sentinel. Base Alembic migration inserts with a fixed UUID.

    -- ── Default Weight Fallback (DMF-01) ─────────────────────
    default_weight_value        DECIMAL(10, 3) NOT NULL DEFAULT 0.5,
    -- Fallback weight when no variant or product weight is set.
    -- Default: 0.5 (units per default_weight_unit).
    -- A clothing merchant may set 0.3 kg; an industrial parts
    -- merchant may set 5.0 kg. Genuinely varies per merchant.

    default_weight_unit         VARCHAR(4) NOT NULL DEFAULT 'kg',
    -- Unit for default_weight_value. 'kg' | 'lb'.

    -- ── Display Preferences ──────────────────────────────────
    weight_unit_preference      VARCHAR(4) NOT NULL DEFAULT 'kg',
    -- Store-wide display unit for weight inputs in admin UI.
    -- 'kg' | 'lb'. Does not affect stored values — display only.

    dimension_unit_preference   VARCHAR(4) NOT NULL DEFAULT 'cm',
    -- Store-wide display unit for dimension inputs in admin UI.
    -- 'cm' | 'in'. Does not affect stored values — display only.

    -- ── Handling Time ────────────────────────────────────────
    handling_days               INTEGER NOT NULL DEFAULT 1,
    -- Business days between order placement and carrier handoff.
    -- Minimum 0 (same-day dispatch possible).
    -- Used in estimated delivery date calculation at checkout:
    --   estimated_delivery = order_date
    --                      + handling_days (business days)
    --                      + carrier transit days
    --                      + weekend/public holiday skip forward

    order_cutoff_time           TIME,
    -- Daily cut-off time (in merchant's local time) for same-day
    -- handling start. Orders after this time roll to next business day.
    -- Example: TIME '14:00' → 2:00 PM local.
    -- NULL = no cut-off; all orders start handling the same business day.
    -- Stored without timezone — combined with brand_profiles.timezone
    -- (06g) at application layer for actual UTC calculation.

    -- ── Free Shipping Threshold ───────────────────────────────
    free_shipping_threshold_amount   DECIMAL(12, 2),
    -- Global free shipping threshold. Orders with subtotal >=
    -- this amount qualify for free shipping.
    -- NULL = no global free shipping threshold configured.

    free_shipping_threshold_currency CHAR(3),
    -- ISO 4217 currency of the threshold. Must match the storefront
    -- currency. NULL when threshold is NULL.

    -- ── Metadata ─────────────────────────────────────────────
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Last time any shipping setting was changed. No created_at —
    -- single seed row, only ever updated after provisioning.

    CONSTRAINT shipping_settings_default_weight_unit_check CHECK (
        default_weight_unit IN ('kg', 'lb')
    ),
    CONSTRAINT shipping_settings_weight_unit_preference_check CHECK (
        weight_unit_preference IN ('kg', 'lb')
    ),
    CONSTRAINT shipping_settings_dimension_unit_preference_check CHECK (
        dimension_unit_preference IN ('cm', 'in')
    ),
    CONSTRAINT shipping_settings_handling_days_non_negative CHECK (
        handling_days >= 0
    ),
    CONSTRAINT shipping_settings_default_weight_positive CHECK (
        default_weight_value > 0
    ),
    CONSTRAINT shipping_settings_threshold_currency_consistency CHECK (
        (free_shipping_threshold_amount IS NULL
         AND free_shipping_threshold_currency IS NULL)
        OR (free_shipping_threshold_amount IS NOT NULL
            AND free_shipping_threshold_currency IS NOT NULL)
    ),
    CONSTRAINT shipping_settings_threshold_positive CHECK (
        free_shipping_threshold_amount IS NULL
        OR free_shipping_threshold_amount > 0
    )
);

COMMENT ON TABLE shipping_settings IS
    'Single-row tenant shipping configuration (DMF-01). '
    'default_weight_value = bottom of DMF-01 weight fallback chain. '
    'handling_days + order_cutoff_time drive estimated delivery date at checkout. '
    'Use upsert; never plain INSERT after base Alembic provisioning. '
    'Carrier definitions and service levels live in platform schema (06a2).';

-- No indexes needed — single-row table. PK lookup is always O(1).
-- Fetched once per checkout flow and cached in Redis (TTL: 5 minutes).
```

---

## Seed Data (Base Alembic Migration)

The following seed INSERTs are executed by the base Alembic migration at
tenant provisioning time (SYS-01). They establish the single required rows
for the two single-row configuration tables.

```sql
-- ── supplier_score_weights seed (one row per tenant) ─────────────────────────
-- Inserted by base migration with a deterministic UUID derived from tenant_id.
-- In practice, gen_random_uuid() is used at INSERT time; the UUID is then
-- stored and never changes.

INSERT INTO supplier_score_weights
    (score_weights_id, on_time_weight, fill_rate_weight,
     quality_weight, price_stability_weight)
VALUES
    (gen_random_uuid(), 0.35, 0.25, 0.25, 0.15);
-- Defaults: 0.35 + 0.25 + 0.25 + 0.15 = 1.00 ✓

-- ── shipping_settings seed (one row per tenant) ───────────────────────────────
INSERT INTO shipping_settings
    (shipping_settings_id, default_weight_value, default_weight_unit,
     weight_unit_preference, dimension_unit_preference,
     handling_days, order_cutoff_time)
VALUES
    (gen_random_uuid(), 0.5, 'kg', 'kg', 'cm', 1, '14:00');
-- Defaults: 0.5 kg, metric display units, 1 handling day, 2pm cutoff.
-- Merchant configures these in Settings → Shipping after onboarding.
```

---

## Updated Schema Inventory Entry

After generating this artifact, update `06-schema-inventory.md`:

```
| `06e-tenant-supplier-schema.md` | ✅ Generated | 6 | Suppliers, purchase orders, PO lines (manufacture_date for perishable batch traceability), performance events (append-only), supplier score weights (single-row), shipping settings (single-row, DMF-01) |
```
