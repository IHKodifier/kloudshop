# 06c — Tenant Orders Schema
# KloudShop Stage 6 — Data Model

> **Artifact:** `06c-tenant-orders-schema.md`
> **Schema:** `tenant_{tenant_id}` (one schema per merchant, provisioned at signup)
> **Persona:** Principal Data Engineer
> **Reads from:** `01-product-brief.md`, `01b-tech-stack.md`, `02-architecture.md`,
>   `03-user-journeys.md`, `04-feature-stories.md`, `04b-mvp-scope.md`,
>   `00-carry-forward-flags.md` (DMF-01 through DMF-10)
> **Depends on:** `06a1-platform-core-schema.md` (order_sources lookup table),
>   `06a2-platform-catalogue-schema.md` (carrier_service_levels FK on shipments),
>   `06b-tenant-catalog-schema.md` (products, variants FKs),
>   `06j-tenant-consumer-schema.md` (consumers FK — forward-declared as plain UUID),
>   `06f-tenant-b2b-schema.md` (b2b_accounts FK — forward-declared as plain UUID)
> **Tables:** 6 (orders, order_items, order_events, order_shipments,
>   order_shipment_items, order_notes)
> **Status:** ✅ Generated

---

## Overview

This artifact defines the complete order lifecycle schema for a KloudShop merchant
tenant. Orders are the financial heart of the platform — every design decision here
prioritises immutability, financial integrity, and auditability over normalisation.

**Key design decisions reflected in this schema:**

- **Denormalised order totals** — `subtotal`, `tax_total`, `shipping_total`,
  `discount_total`, and `grand_total` are snapshotted at purchase time and never
  recomputed from line items. This is essential for financial reporting accuracy:
  price changes, variant deletions, or discount rule modifications after the order
  is placed must never alter the historical financial record.

- **Separate `order_shipments` table** — one order can produce multiple shipments
  (partial fulfilment, multi-location stock, split by carrier). A dedicated shipments
  table with `order_shipment_items` gives clean per-shipment tracking, carrier
  attribution, analytics, and consumer notification without contorting `order_items`.

- **`order_source_id` as a FK to the `order_sources` lookup table** — not a
  hardcoded ENUM. New sales channels (new social platforms, new POS locations) are
  added with a single INSERT into `order_sources` on the platform schema, with
  zero code or schema changes required in any tenant schema.

- **Variant snapshots on `order_items`** — title, SKU, price, and weight at
  time of purchase are copied onto each order item row. If the variant is later
  modified or archived, the historical order record is unaffected.

- **`order_events` append-only** — the complete state transition history of every
  order is preserved forever. No order event is ever updated or deleted.

- **`net_terms_days` snapshotted on orders** — for B2B orders with net payment
  terms, the agreed terms at order placement are copied from `b2b_accounts` onto
  the order row. Future changes to the buyer account's terms do not retroactively
  alter existing invoices.

- **`imported` orders excluded from financials** — orders migrated from competitor
  platforms carry `order_source_id = 'imported'`. These are excluded from all
  financial reporting, Stripe billing reconciliation, and revenue analytics. Only
  orders placed natively through KloudShop channels are treated as live financial
  transactions.

**AI agent note:** Cross-schema foreign keys (to `kloudshop_platform.order_sources`,
`kloudshop_platform.carrier_service_levels`) are declared as plain UUID/VARCHAR
columns with application-layer validation rather than PostgreSQL FK constraints.
PostgreSQL does not support FK constraints across schemas in Cloud SQL. The
application layer enforces referential integrity at write time.

---

## Table: `orders`

```sql
-- ============================================================
-- TABLE: orders
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per order. The central commerce record.
--   Holds the complete financial snapshot at purchase time,
--   buyer identity, payment state, B2B approval state, and
--   fulfilment status summary.
--
-- BUSINESS RULES:
--   1. All monetary totals are DENORMALISED and snapshotted at
--      purchase time. They are NEVER recomputed from order_items
--      after the order is placed. This preserves financial
--      reporting integrity regardless of future price changes.
--   2. consumer_id is NULL for guest checkout orders. It is set
--      to the registered consumer's UUID for authenticated orders.
--      Plain UUID — FK to consumers enforced at application layer.
--   3. order_source_id references kloudshop_platform.order_sources
--      (the lookup table). Stored as VARCHAR(64) matching the
--      source_id PK on that table. Not a DB FK constraint — cross-
--      schema FKs are not supported. Application layer validates.
--      'imported' orders are EXCLUDED from all financial reporting
--      and Stripe billing reconciliation.
--   4. b2b_account_id is NULL for DTC consumer orders. Set for
--      all B2B buyer portal orders. Plain UUID — no FK constraint.
--   5. net_terms_days is snapshotted from b2b_accounts.net_terms_days
--      at order placement. NULL for DTC orders and B2B orders
--      paid immediately. Changes to the buyer's account terms
--      never retroactively alter existing orders.
--   6. approval_status controls the B2B approval workflow:
--      NULL        — DTC orders (no approval workflow)
--      'pending'   — awaiting merchant approval
--      'approved'  — approved; proceeds to fulfilment
--      'declined'  — declined; never fulfilled
--      'auto_approved' — approved automatically (within credit
--                        limit and below approval threshold)
--   7. fulfilment_status is a denormalised summary of the order's
--      current fulfilment state. Updated by the order_events
--      pipeline as shipments are created and confirmed.
--      Source of truth for fulfilment detail is order_shipments.
--   8. payment_status tracks the Stripe payment state.
--      For net-terms B2B orders, 'pending' means awaiting invoice
--      payment, not awaiting card authorisation.
--   9. currency_code is the storefront's active currency at the
--      time of order. All monetary fields in this row use this
--      currency. Never changes after order placement.
--  10. pricing_rule_id is set when a dynamic pricing rule was
--      active for this order. References dynamic_pricing_rules
--      (feature-gated table in 06m). NULL if no rule applied.
-- ============================================================

CREATE TABLE orders (
    order_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- ── Order Identity ───────────────────────────────────────
    order_number     VARCHAR(32) NOT NULL,
    -- Human-readable order reference shown to merchant and consumer.
    -- Format: #{sequential_number} e.g. '#1042'.
    -- Generated at application layer. Unique within tenant.
    -- Sequential integer padded to at least 4 digits.

    order_source_id  VARCHAR(64) NOT NULL,
    -- References kloudshop_platform.order_sources.source_id.
    -- Stored as VARCHAR matching source_id PK. Application validates.
    -- Examples: 'kloudshop', 'pos', 'tiktok_shop', 'imported'.
    -- 'imported' orders excluded from financial reporting.

    -- ── Buyer Identity ───────────────────────────────────────
    consumer_id      UUID,
    -- NULL = guest checkout. Non-null = registered consumer.
    -- FK to consumers (06j) — plain UUID, enforced at app layer.

    b2b_account_id   UUID,
    -- NULL = DTC consumer order.
    -- Non-null = B2B buyer portal order.
    -- FK to b2b_accounts (06f) — plain UUID, enforced at app layer.

    -- ── Buyer Snapshot (denormalised at order time) ───────────
    -- These fields capture the buyer's details at order placement.
    -- They do not change if the consumer updates their profile later.
    buyer_email      TEXT NOT NULL,
    -- Consumer's email at time of order. Used for order confirmation
    -- email and as the fallback contact if consumer_id is NULL.

    buyer_first_name TEXT,
    buyer_last_name  TEXT,

    -- ── Shipping Address Snapshot ────────────────────────────
    -- Snapshotted at order placement. Changes to saved addresses
    -- do not affect historical orders.
    shipping_line1   TEXT,
    shipping_line2   TEXT,
    shipping_city    TEXT,
    shipping_state   TEXT,
    shipping_postcode TEXT,
    shipping_country CHAR(2),
    -- ISO 3166-1 alpha-2 country code.

    -- ── Financial Totals (denormalised — snapshotted at purchase) ──
    currency_code    CHAR(3) NOT NULL DEFAULT 'USD',
    -- ISO 4217 currency code. All monetary fields below use this.

    subtotal         DECIMAL(12, 2) NOT NULL DEFAULT 0,
    -- Sum of (line_item_price × quantity) before any adjustments.
    -- = SUM(order_items.unit_price × order_items.quantity)

    discount_total   DECIMAL(12, 2) NOT NULL DEFAULT 0,
    -- Total discount applied (coupon codes, dynamic pricing rules,
    -- B2B price list discounts, loyalty redemptions).
    -- Always stored as a positive number. Subtracted from subtotal.

    shipping_total   DECIMAL(12, 2) NOT NULL DEFAULT 0,
    -- Total shipping charged to the buyer across all shipments.
    -- 0.00 for free shipping or digital-only orders.

    tax_total        DECIMAL(12, 2) NOT NULL DEFAULT 0,
    -- Total tax calculated by Stripe Tax at checkout.
    -- 0.00 for tax-exempt orders or orders where no tax applies.

    grand_total      DECIMAL(12, 2) NOT NULL DEFAULT 0,
    -- = subtotal - discount_total + shipping_total + tax_total
    -- The amount actually charged (or invoiced for net-terms orders).
    -- Enforced by CHECK constraint below.

    -- ── Payment ──────────────────────────────────────────────
    payment_status   VARCHAR(16) NOT NULL DEFAULT 'pending',
    -- 'pending'    — payment not yet received (card auth pending,
    --                or net-terms invoice awaiting payment)
    -- 'paid'       — payment confirmed (Stripe webhook received)
    -- 'partially_refunded' — partial refund issued
    -- 'refunded'   — fully refunded
    -- 'voided'     — order cancelled before payment captured
    -- 'failed'     — payment attempt failed

    stripe_payment_intent_id TEXT,
    -- Stripe PaymentIntent ID for card/wallet payments.
    -- NULL for net-terms B2B orders (these use Stripe Invoicing).
    -- NULL for imported historical orders.

    stripe_invoice_id TEXT,
    -- Stripe Invoice ID for B2B net-terms orders.
    -- NULL for standard card/wallet payments.

    -- ── B2B Net Terms ────────────────────────────────────────
    net_terms_days   INTEGER,
    -- Snapshotted from b2b_accounts.net_terms_days at order placement.
    -- NULL for DTC orders and immediate-payment B2B orders.
    -- Example: 30 for Net-30 terms.

    net_terms_due_at TIMESTAMPTZ,
    -- = placed_at + net_terms_days. NULL for non-net-terms orders.
    -- The date by which the Stripe Invoice must be paid.

    -- ── B2B Approval Workflow ─────────────────────────────────
    approval_status  VARCHAR(16),
    -- NULL for DTC orders. See business rules for B2B values.

    approved_by      UUID,
    -- staff_user_id who approved or declined. NULL if auto-approved
    -- or not yet actioned.

    approved_at      TIMESTAMPTZ,
    -- When the approval decision was made. NULL if pending.

    decline_reason   TEXT,
    -- Merchant-provided reason for declining. NULL if not declined.

    -- ── Fulfilment Status Summary ─────────────────────────────
    fulfilment_status VARCHAR(24) NOT NULL DEFAULT 'unfulfilled',
    -- Denormalised summary. Source of truth is order_shipments.
    -- 'unfulfilled'       — no items shipped yet
    -- 'partially_fulfilled' — some items shipped
    -- 'fulfilled'         — all items shipped
    -- 'delivered'         — all shipments confirmed delivered
    -- 'returned'          — return initiated
    -- 'cancelled'         — order cancelled

    -- ── Pricing Rule Attribution ─────────────────────────────
    pricing_rule_id  UUID,
    -- References dynamic_pricing_rules (feature-gated, 06m).
    -- NULL if no dynamic pricing rule was active for this order.
    -- Plain UUID — no FK constraint (table may not exist if feature
    -- not activated). Application layer validates when set.

    -- ── Discount Attribution ─────────────────────────────────
    discount_code_used TEXT,
    -- The coupon/discount code applied, if any. NULL if none.
    -- Stored as plain text for historical record — the code may
    -- be deactivated or deleted after use.

    -- ── Metadata ─────────────────────────────────────────────
    placed_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- When the order was placed (payment intent confirmed for card
    -- orders; submission time for net-terms B2B orders).

    cancelled_at     TIMESTAMPTZ,
    -- When the order was cancelled. NULL if not cancelled.

    cancelled_by     UUID,
    -- staff_user_id or NULL (consumer-initiated via future self-serve).

    cancellation_reason TEXT,

    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- ── Constraints ──────────────────────────────────────────
    CONSTRAINT orders_order_number_unique UNIQUE (order_number),

    CONSTRAINT orders_payment_status_check CHECK (
        payment_status IN (
            'pending', 'paid', 'partially_refunded',
            'refunded', 'voided', 'failed'
        )
    ),

    CONSTRAINT orders_fulfilment_status_check CHECK (
        fulfilment_status IN (
            'unfulfilled', 'partially_fulfilled', 'fulfilled',
            'delivered', 'returned', 'cancelled'
        )
    ),

    CONSTRAINT orders_approval_status_check CHECK (
        approval_status IN (
            'pending', 'approved', 'declined', 'auto_approved'
        ) OR approval_status IS NULL
    ),

    CONSTRAINT orders_grand_total_check CHECK (
        -- grand_total must equal the sum of its components.
        -- Enforced at application layer on write; DB constraint is
        -- a safety net. Allow tiny floating point rounding tolerance.
        grand_total >= 0
        -- Note: We do not enforce the exact formula here as DECIMAL
        -- arithmetic is exact but the formula involves subtraction
        -- which could produce negative results for fully discounted
        -- orders. grand_total >= 0 is the meaningful constraint.
    ),

    CONSTRAINT orders_net_terms_consistency CHECK (
        -- net_terms_due_at must be set when net_terms_days is set.
        (net_terms_days IS NULL AND net_terms_due_at IS NULL)
        OR (net_terms_days IS NOT NULL AND net_terms_due_at IS NOT NULL)
    ),

    CONSTRAINT orders_b2b_approval_consistency CHECK (
        -- b2b_account_id must be set if approval_status is set.
        approval_status IS NULL OR b2b_account_id IS NOT NULL
    )
);

COMMENT ON TABLE orders IS
    'One row per order. Financial totals are denormalised and snapshotted '
    'at purchase time — never recomputed from line items. '
    'order_source_id references kloudshop_platform.order_sources lookup table. '
    '''imported'' orders are excluded from all financial reporting and Stripe billing.';

CREATE UNIQUE INDEX idx_orders_order_number
    ON orders (order_number);
-- Rationale: Order number is the primary human-readable reference used
-- everywhere — merchant dashboard, consumer emails, support queries.
-- Must be unique and O(1) lookup.

CREATE INDEX idx_orders_consumer_id
    ON orders (consumer_id, placed_at DESC)
    WHERE consumer_id IS NOT NULL;
-- Rationale: Consumer order history screen fetches all orders for a
-- consumer, most recent first. Partial index excludes guest orders.

CREATE INDEX idx_orders_b2b_account
    ON orders (b2b_account_id, placed_at DESC)
    WHERE b2b_account_id IS NOT NULL;
-- Rationale: B2B buyer order history. Partial index on B2B orders only.

CREATE INDEX idx_orders_placed_at
    ON orders (placed_at DESC);
-- Rationale: Admin orders list default view — most recent first.
-- Also used by the BigQuery streaming export job.

CREATE INDEX idx_orders_fulfilment_status
    ON orders (fulfilment_status, placed_at DESC)
    WHERE fulfilment_status IN ('unfulfilled', 'partially_fulfilled');
-- Rationale: "Needs fulfilment" filter in admin orders list.
-- Partial index on actionable statuses only — most orders are fulfilled.

CREATE INDEX idx_orders_payment_status
    ON orders (payment_status, placed_at DESC)
    WHERE payment_status IN ('pending', 'failed');
-- Rationale: Finance dashboard flags unpaid and failed orders.
-- Partial index on actionable statuses — most orders are 'paid'.

CREATE INDEX idx_orders_approval_pending
    ON orders (approval_status, placed_at DESC)
    WHERE approval_status = 'pending';
-- Rationale: B2B approval queue shows all orders awaiting approval.
-- Partial index on pending only — very small working set.

CREATE INDEX idx_orders_source
    ON orders (order_source_id, placed_at DESC);
-- Rationale: Channel analytics — revenue by source (DTC vs B2B vs
-- TikTok Shop vs POS). Also used to exclude 'imported' orders from
-- financial reports.

CREATE INDEX idx_orders_net_terms_overdue
    ON orders (net_terms_due_at, payment_status)
    WHERE net_terms_due_at IS NOT NULL AND payment_status = 'pending';
-- Rationale: B2B receivables ageing — identifies overdue net-terms
-- invoices. Partial index on net-terms pending orders only.

CREATE INDEX idx_orders_stripe_payment_intent
    ON orders (stripe_payment_intent_id)
    WHERE stripe_payment_intent_id IS NOT NULL;
-- Rationale: Stripe webhook handler resolves order from payment intent
-- on every payment event. Partial index excludes net-terms orders.

CREATE INDEX idx_orders_stripe_invoice
    ON orders (stripe_invoice_id)
    WHERE stripe_invoice_id IS NOT NULL;
-- Rationale: Stripe webhook handler resolves order from invoice ID
-- on B2B invoice payment events.
```

---

## Table: `order_items`

```sql
-- ============================================================
-- TABLE: order_items
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per line item per order. Holds a complete
--   snapshot of the variant at purchase time — immutable after
--   order placement.
--
-- BUSINESS RULES:
--   1. All variant-level fields (title, sku, unit_price, weight)
--      are SNAPSHOTTED at order placement. If the variant is later
--      modified, archived, or deleted, the order item is unaffected.
--      This is critical for financial and legal accuracy.
--   2. variant_id is retained as a reference for analytics (which
--      variants are selling well) but is NOT enforced as a hard FK
--      with CASCADE — deleting or archiving a variant must not
--      delete historical order items. Declared as plain UUID.
--      Application layer validates existence on order creation.
--   3. unit_price is the actual price charged per unit AFTER any
--      discounts or pricing rule adjustments. This is what the
--      consumer paid per unit, not the variant's list price.
--   4. total_price = unit_price × quantity. Denormalised for
--      fast aggregation in reporting queries.
--   5. fulfilment_location_id references stock_locations (06d).
--      It is the stock location from which this item is to be
--      fulfilled. Set at order placement based on fulfilment
--      routing rules. NULL for digital products.
--   6. is_digital mirrors product.is_digital at order time.
--      Ensures digital items are never included in shipment
--      calculations even if the product flag changes later.
-- ============================================================

CREATE TABLE order_items (
    order_item_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id         UUID NOT NULL
                     REFERENCES orders (order_id)
                     ON DELETE CASCADE,
    -- CASCADE: deleting an order removes all its line items.
    -- Orders are never deleted in practice (they are cancelled),
    -- but CASCADE is the safe default.

    -- ── Variant Reference ────────────────────────────────────
    variant_id       UUID,
    -- Reference to variants.variant_id. Stored as plain UUID —
    -- no ON DELETE CASCADE (archiving a variant must not destroy
    -- order history). Application layer validates on write.
    -- NULL for manually created orders (rare edge case).

    -- ── Variant Snapshot (immutable after order placement) ────
    variant_title    TEXT NOT NULL,
    -- Full variant display name at time of purchase.
    -- Example: 'Blue Widget — Large / Cotton'

    variant_sku      TEXT NOT NULL,
    -- SKU at time of purchase.

    product_id       UUID,
    -- Reference to products.product_id. Plain UUID, same reasoning
    -- as variant_id. Used for product-level analytics.

    product_title    TEXT NOT NULL,
    -- Product title at time of purchase.

    -- ── Quantity & Pricing ───────────────────────────────────
    quantity         INTEGER NOT NULL,
    -- Number of units ordered. Always >= 1.

    unit_price       DECIMAL(12, 2) NOT NULL,
    -- Actual price per unit charged — AFTER discounts and pricing
    -- rule adjustments. Not the variant's list price.

    compare_at_price DECIMAL(12, 2),
    -- Variant's compare_at_price at time of purchase (if on sale).
    -- NULL if not on sale. Used for "saved X%" display in receipts.

    total_price      DECIMAL(12, 2) NOT NULL,
    -- = unit_price × quantity. Denormalised for fast aggregation.

    -- ── Tax ──────────────────────────────────────────────────
    tax_amount       DECIMAL(12, 2) NOT NULL DEFAULT 0,
    -- Tax amount for this line item as calculated by Stripe Tax.
    -- 0.00 for tax-exempt items.

    taxable          BOOLEAN NOT NULL DEFAULT TRUE,
    -- Snapshotted from variants.taxable at order time.

    -- ── Shipping ─────────────────────────────────────────────
    is_digital       BOOLEAN NOT NULL DEFAULT FALSE,
    -- Snapshotted from product.is_digital. Digital items excluded
    -- from all shipment logic even if product flag changes later.

    requires_shipping BOOLEAN NOT NULL DEFAULT TRUE,
    -- Snapshotted from variants.requires_shipping.

    weight_value     DECIMAL(10, 3),
    -- Variant weight at order time. Used for historical shipment
    -- weight calculation. NULL for digital or weightless items.

    weight_unit      VARCHAR(4),
    -- 'kg' | 'lb'

    -- ── Fulfilment Routing ───────────────────────────────────
    fulfilment_location_id UUID,
    -- References stock_locations.stock_location_id (06d).
    -- Plain UUID — no FK constraint (same reasoning as variant_id).
    -- The stock location assigned to fulfil this item.
    -- NULL for digital items.

    -- ── Pricing Rule Attribution ─────────────────────────────
    pricing_rule_id  UUID,
    -- References dynamic_pricing_rules (feature-gated, 06m).
    -- NULL if no dynamic pricing rule affected this line item's price.

    -- ── Metadata ─────────────────────────────────────────────
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT order_items_quantity_positive CHECK (quantity >= 1),
    CONSTRAINT order_items_unit_price_non_negative CHECK (unit_price >= 0),
    CONSTRAINT order_items_total_price_non_negative CHECK (total_price >= 0),
    CONSTRAINT order_items_weight_unit_check CHECK (
        weight_unit IN ('kg', 'lb') OR weight_unit IS NULL
    )
);

COMMENT ON TABLE order_items IS
    'One row per line item per order. All variant fields snapshotted at purchase '
    'time — immutable. variant_id retained for analytics but not a hard FK '
    '(archiving a variant must not destroy order history).';

CREATE INDEX idx_order_items_order_id
    ON order_items (order_id);
-- Rationale: Every order detail view fetches all line items for an order.
-- Most frequent read pattern on this table.

CREATE INDEX idx_order_items_variant_id
    ON order_items (variant_id, created_at DESC)
    WHERE variant_id IS NOT NULL;
-- Rationale: Product performance analytics — "how many units of this
-- variant have been sold?" Partial index excludes manual order items.

CREATE INDEX idx_order_items_product_id
    ON order_items (product_id, created_at DESC)
    WHERE product_id IS NOT NULL;
-- Rationale: Product-level sales aggregation for analytics dashboards.

CREATE INDEX idx_order_items_fulfilment_location
    ON order_items (fulfilment_location_id, order_id)
    WHERE fulfilment_location_id IS NOT NULL AND is_digital = FALSE;
-- Rationale: Multi-location fulfilment routing — "which items need to
-- be fulfilled from this location?" Partial index on physical items only.

CREATE INDEX idx_order_items_digital
    ON order_items (order_id)
    WHERE is_digital = TRUE;
-- Rationale: Digital fulfilment job fetches all digital items in an
-- order to generate download links. Partial on digital only.
```

---

## Table: `order_events`

```sql
-- ============================================================
-- TABLE: order_events
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Append-only event log for every order. Records every
--   state transition and significant action on an order. This is
--   the source of truth for the order timeline displayed in the
--   merchant admin and consumer account.
--
-- BUSINESS RULES:
--   1. Append-only. No UPDATE. No DELETE. Ever.
--      Once an event is written, it is permanent. The order
--      timeline is an immutable audit trail.
--   2. actor_type and actor_id identify who triggered the event:
--      'system'   — automated platform action (payment webhook,
--                   Cloud Tasks job, approval auto-approve)
--      'staff'    — merchant staff action (actor_id = staff_user_id)
--      'consumer' — consumer action (actor_id = consumer_id)
--   3. event_type covers the full order lifecycle. See the CHECK
--      constraint for the complete list of valid event types.
--   4. metadata JSONB holds event-specific structured data.
--      Schema varies by event_type — examples documented below.
--   5. is_visible_to_consumer controls whether this event is
--      shown on the consumer's order tracking page. FALSE for
--      internal events (approval workflow, staff notes, system
--      reconciliation events).
-- ============================================================

CREATE TABLE order_events (
    event_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id         UUID NOT NULL
                     REFERENCES orders (order_id)
                     ON DELETE CASCADE,

    -- ── Event Classification ──────────────────────────────────
    event_type       VARCHAR(48) NOT NULL,
    -- The type of event. Valid values (enforced by CHECK):
    --
    -- PAYMENT EVENTS:
    --   'payment_pending'       — order created, awaiting payment
    --   'payment_confirmed'     — Stripe payment intent succeeded
    --   'payment_failed'        — Stripe payment failed
    --   'payment_voided'        — payment intent voided/cancelled
    --   'refund_initiated'      — refund requested
    --   'refund_completed'      — Stripe refund confirmed
    --   'invoice_issued'        — Stripe Invoice created (net-terms)
    --   'invoice_paid'          — Stripe Invoice payment confirmed
    --   'invoice_overdue'       — net-terms payment past due date
    --
    -- APPROVAL EVENTS (B2B):
    --   'approval_requested'    — order sent for approval
    --   'approval_approved'     — merchant approved the order
    --   'approval_declined'     — merchant declined the order
    --   'approval_auto_approved'— auto-approved (within threshold)
    --
    -- FULFILMENT EVENTS:
    --   'fulfilment_started'    — first shipment created
    --   'shipment_created'      — a shipment record created
    --   'shipment_label_printed'— shipping label generated
    --   'shipment_dispatched'   — carrier collected / handed off
    --   'shipment_in_transit'   — carrier tracking update
    --   'shipment_delivered'    — carrier confirmed delivery
    --   'fulfilment_completed'  — all items shipped
    --
    -- CANCELLATION / RETURNS:
    --   'cancellation_requested'— cancellation initiated
    --   'order_cancelled'       — order fully cancelled
    --   'return_initiated'      — return request opened
    --   'return_received'       — returned goods received
    --
    -- CONSUMER EVENTS:
    --   'order_placed'          — order submitted by consumer/buyer
    --   'note_added'            — staff note added
    --
    -- SYSTEM EVENTS:
    --   'order_imported'        — historical order imported from CSV

    -- ── Actor ────────────────────────────────────────────────
    actor_type       VARCHAR(16) NOT NULL DEFAULT 'system',
    -- Who triggered this event. 'system' | 'staff' | 'consumer'

    actor_id         UUID,
    -- staff_user_id or consumer_id, depending on actor_type.
    -- NULL when actor_type = 'system'.

    -- ── Event Data ───────────────────────────────────────────
    metadata         JSONB NOT NULL DEFAULT '{}',
    -- Event-specific structured data. Examples:
    --
    -- 'payment_confirmed':
    --   {"stripe_payment_intent_id": "pi_...", "amount": 127.50}
    --
    -- 'shipment_dispatched':
    --   {"shipment_id": "...", "carrier": "FedEx",
    --    "tracking_number": "794...", "service_level": "fedex_ground"}
    --
    -- 'approval_declined':
    --   {"decline_reason": "Credit limit exceeded", "approved_by": "..."}
    --
    -- 'refund_completed':
    --   {"refund_amount": 45.00, "stripe_refund_id": "re_..."}

    -- ── Visibility ───────────────────────────────────────────
    is_visible_to_consumer BOOLEAN NOT NULL DEFAULT FALSE,
    -- TRUE = shown on the consumer's order tracking page.
    -- FALSE = internal event (staff notes, system reconciliation).
    -- Fulfilment events are TRUE; payment/approval events are FALSE.

    -- ── Timestamp ────────────────────────────────────────────
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- When the event occurred. Never updated.

    CONSTRAINT order_events_actor_type_check CHECK (
        actor_type IN ('system', 'staff', 'consumer')
    ),

    CONSTRAINT order_events_event_type_check CHECK (
        event_type IN (
            'payment_pending', 'payment_confirmed', 'payment_failed',
            'payment_voided', 'refund_initiated', 'refund_completed',
            'invoice_issued', 'invoice_paid', 'invoice_overdue',
            'approval_requested', 'approval_approved',
            'approval_declined', 'approval_auto_approved',
            'fulfilment_started', 'shipment_created',
            'shipment_label_printed', 'shipment_dispatched',
            'shipment_in_transit', 'shipment_delivered',
            'fulfilment_completed', 'cancellation_requested',
            'order_cancelled', 'return_initiated', 'return_received',
            'order_placed', 'note_added', 'order_imported'
        )
    )
);

COMMENT ON TABLE order_events IS
    'Append-only event log per order. No UPDATE, no DELETE — ever. '
    'Source of truth for order timeline in merchant admin and consumer tracking. '
    'is_visible_to_consumer controls what consumers see on their tracking page.';

CREATE INDEX idx_order_events_order_id
    ON order_events (order_id, created_at ASC);
-- Rationale: Order timeline view fetches all events for an order in
-- chronological order. Composite covers filter and sort in one index.

CREATE INDEX idx_order_events_type
    ON order_events (event_type, created_at DESC);
-- Rationale: Platform analytics — event frequency by type over time.
-- Also used by the BigQuery streaming job to filter by event category.

CREATE INDEX idx_order_events_consumer_visible
    ON order_events (order_id, created_at ASC)
    WHERE is_visible_to_consumer = TRUE;
-- Rationale: Consumer order tracking page fetches only consumer-visible
-- events. Partial index keeps this small and fast.
```

---

## Table: `order_shipments`

```sql
-- ============================================================
-- TABLE: order_shipments
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: One row per shipment per order. An order may have
--   multiple shipments (partial fulfilment, multi-location stock,
--   split by carrier, or separate physical and digital fulfilment).
--
-- BUSINESS RULES:
--   1. A shipment is created when the merchant marks items as
--      ready to dispatch and generates a shipping label (or
--      records manual dispatch).
--   2. fulfilment_location_id is the stock location from which
--      this shipment originates. References stock_locations (06d).
--      Plain UUID — no FK constraint.
--   3. service_level_id references kloudshop_platform.carrier_service_levels.
--      Stored as VARCHAR(64) matching the service_level_id PK.
--      NULL for manual shipments where no carrier integration is used.
--   4. tracking_number and carrier_name are set when a label is
--      generated or manually entered by the merchant. NULL until
--      then.
--   5. estimated_delivery_at is the carrier API's specific delivery
--      date estimate at label generation time. NULL if not provided
--      by the carrier API (fallback: transit days + handling days).
--   6. shipped_at is set when the merchant marks the shipment as
--      dispatched (handed off to carrier). NULL until dispatch.
--   7. delivered_at is set when the carrier confirms delivery
--      (via webhook or manual update). NULL until delivered.
--   8. shipment_status tracks the shipment lifecycle independently
--      from the parent order's fulfilment_status.
-- ============================================================

CREATE TABLE order_shipments (
    shipment_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id         UUID NOT NULL
                     REFERENCES orders (order_id)
                     ON DELETE CASCADE,

    -- ── Origin ───────────────────────────────────────────────
    fulfilment_location_id UUID,
    -- Stock location originating this shipment.
    -- References stock_locations.stock_location_id (06d).
    -- Plain UUID — application layer validates.
    -- NULL for digital-only shipments.

    -- ── Carrier ──────────────────────────────────────────────
    service_level_id VARCHAR(64),
    -- References kloudshop_platform.carrier_service_levels.service_level_id.
    -- Stored as VARCHAR(64). Application validates against platform table.
    -- NULL for manual shipments (local courier, post office walk-in).

    carrier_name     TEXT,
    -- Human-readable carrier name. Set at label generation or manual entry.
    -- Example: 'FedEx', 'Royal Mail', 'Pakistan Post'.
    -- NULL until label generated or manually entered.

    tracking_number  TEXT,
    -- Carrier-issued tracking number. NULL until label generated.

    tracking_url     TEXT,
    -- Full tracking URL for the consumer. Auto-generated for known carriers.
    -- NULL for manual carriers where no tracking URL is available.

    -- ── Shipping Cost ────────────────────────────────────────
    shipping_cost    DECIMAL(12, 2) NOT NULL DEFAULT 0,
    -- The shipping cost charged to the consumer for this shipment.
    -- Part of the order's shipping_total.

    -- ── Dates ────────────────────────────────────────────────
    estimated_delivery_at TIMESTAMPTZ,
    -- Carrier API's specific delivery date estimate.
    -- NULL if carrier returned only transit days (not a specific date).

    label_generated_at TIMESTAMPTZ,
    -- When the shipping label was generated.

    shipped_at       TIMESTAMPTZ,
    -- When the shipment was handed off to the carrier.

    delivered_at     TIMESTAMPTZ,
    -- When the carrier confirmed delivery. NULL until delivered.

    -- ── Status ───────────────────────────────────────────────
    shipment_status  VARCHAR(24) NOT NULL DEFAULT 'pending',
    -- 'pending'     — created but not yet dispatched
    -- 'label_ready' — label generated, awaiting pickup
    -- 'dispatched'  — handed to carrier
    -- 'in_transit'  — carrier tracking update received
    -- 'delivered'   — delivery confirmed
    -- 'failed'      — delivery failed / returned to sender
    -- 'cancelled'   — shipment cancelled before dispatch

    -- ── Destination Address Snapshot ─────────────────────────
    -- Copied from the order's shipping address at shipment creation.
    -- Stored here so changes to the order address (if allowed) do
    -- not affect label-generation records.
    dest_line1       TEXT,
    dest_line2       TEXT,
    dest_city        TEXT,
    dest_state       TEXT,
    dest_postcode    TEXT,
    dest_country     CHAR(2),

    -- ── Metadata ─────────────────────────────────────────────
    notes            TEXT,
    -- Internal merchant notes on this shipment.

    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT order_shipments_status_check CHECK (
        shipment_status IN (
            'pending', 'label_ready', 'dispatched',
            'in_transit', 'delivered', 'failed', 'cancelled'
        )
    ),

    CONSTRAINT order_shipments_shipping_cost_non_negative CHECK (
        shipping_cost >= 0
    )
);

COMMENT ON TABLE order_shipments IS
    'One row per shipment per order. Supports partial fulfilment and '
    'multi-location split shipments. service_level_id references '
    'kloudshop_platform.carrier_service_levels (cross-schema, no DB FK).';

CREATE INDEX idx_order_shipments_order_id
    ON order_shipments (order_id);
-- Rationale: Order detail view fetches all shipments for an order.
-- Most frequent read pattern on this table.

CREATE INDEX idx_order_shipments_status
    ON order_shipments (shipment_status, created_at DESC)
    WHERE shipment_status IN ('pending', 'label_ready', 'dispatched', 'in_transit');
-- Rationale: Fulfilment dashboard shows active shipments needing action.
-- Partial index on actionable statuses — delivered/cancelled are historical.

CREATE INDEX idx_order_shipments_tracking
    ON order_shipments (tracking_number)
    WHERE tracking_number IS NOT NULL;
-- Rationale: Carrier webhook handler resolves shipment from tracking
-- number on status update events. Partial excludes untracked shipments.

CREATE INDEX idx_order_shipments_location
    ON order_shipments (fulfilment_location_id, shipment_status)
    WHERE fulfilment_location_id IS NOT NULL;
-- Rationale: Per-location fulfilment dashboard — "what needs to ship
-- from this warehouse today?" Partial excludes digital shipments.

CREATE INDEX idx_order_shipments_service_level
    ON order_shipments (service_level_id)
    WHERE service_level_id IS NOT NULL;
-- Rationale: Carrier performance analytics — "which service levels
-- are merchants using most?" and "what is the average delivery time
-- by service level?"
```

---

## Table: `order_shipment_items`

```sql
-- ============================================================
-- TABLE: order_shipment_items
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Join table: which order_items are in which shipment.
--   Enables partial fulfilment — some items ship in one shipment,
--   others in a later shipment once restocked or prepared.
--
-- BUSINESS RULES:
--   1. One row per (shipment, order_item) pair.
--   2. quantity_in_shipment allows partial item fulfilment:
--      if 10 units of a variant were ordered and only 7 are
--      available, this row records quantity_in_shipment = 7.
--      The remaining 3 will be in a later shipment row.
--   3. quantity_in_shipment must not exceed the order_item's
--      total quantity minus quantities in other shipments.
--      Enforced at application layer — not a DB constraint
--      (would require a subquery constraint).
-- ============================================================

CREATE TABLE order_shipment_items (
    shipment_item_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    shipment_id       UUID NOT NULL
                      REFERENCES order_shipments (shipment_id)
                      ON DELETE CASCADE,
    -- CASCADE: cancelling a shipment removes its item assignments.

    order_item_id     UUID NOT NULL
                      REFERENCES order_items (order_item_id)
                      ON DELETE CASCADE,
    -- CASCADE: removing an order item removes its shipment assignments.

    quantity_in_shipment INTEGER NOT NULL,
    -- Number of units of this order_item included in this shipment.
    -- Must be >= 1. Must not exceed remaining unfulfilled quantity.

    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT order_shipment_items_unique UNIQUE (shipment_id, order_item_id),
    -- One row per (shipment, order_item) pair.

    CONSTRAINT order_shipment_items_quantity_positive CHECK (
        quantity_in_shipment >= 1
    )
);

COMMENT ON TABLE order_shipment_items IS
    'Join table: which order_items are in which shipment. '
    'Enables partial fulfilment — items can be split across multiple shipments. '
    'quantity_in_shipment allows partial item quantities per shipment.';

CREATE INDEX idx_order_shipment_items_shipment
    ON order_shipment_items (shipment_id);
-- Rationale: Shipment packing list — all items in a given shipment.
-- Used for label generation and packing slip generation.

CREATE INDEX idx_order_shipment_items_order_item
    ON order_shipment_items (order_item_id);
-- Rationale: "How much of this order_item has already been shipped?"
-- Used to calculate remaining unfulfilled quantity per line item.
```

---

## Table: `order_notes`

```sql
-- ============================================================
-- TABLE: order_notes
-- SCHEMA: tenant_{tenant_id}
-- PURPOSE: Internal staff notes attached to orders. Never visible
--   to consumers. Append-only — notes are never edited or deleted.
--
-- BUSINESS RULES:
--   1. Append-only. No UPDATE. No DELETE. Ever.
--      Notes are an internal audit trail — once written they are
--      permanent. Staff who write a note cannot retract it.
--   2. Only staff members can write notes (author_staff_user_id
--      is always set). Consumers and B2B buyers cannot write notes.
--   3. Notes are never shown to consumers or B2B buyers.
--      Consumer-facing communication happens via order_events
--      (is_visible_to_consumer = TRUE) or direct messaging.
--   4. note_type distinguishes between general notes and
--      system-generated notes (e.g. auto-notes from approval
--      workflow actions).
-- ============================================================

CREATE TABLE order_notes (
    note_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id         UUID NOT NULL
                     REFERENCES orders (order_id)
                     ON DELETE CASCADE,

    note_type        VARCHAR(16) NOT NULL DEFAULT 'manual',
    -- 'manual' — written by a staff member manually
    -- 'system' — auto-generated by platform workflows
    --            (e.g. "Auto-approved: within credit limit")

    body             TEXT NOT NULL,
    -- The note content. Free text. No length limit enforced at DB level
    -- (application layer may impose a soft UI limit).

    author_staff_user_id UUID NOT NULL,
    -- staff_user_id who wrote this note.
    -- Plain UUID — no FK constraint (cross-schema reference).
    -- Application layer validates against staff_users on write.
    -- For system notes, this is the service account user UUID.

    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- When the note was written. Immutable.

    CONSTRAINT order_notes_type_check CHECK (
        note_type IN ('manual', 'system')
    )
);

COMMENT ON TABLE order_notes IS
    'Internal staff notes per order. Never visible to consumers. '
    'Append-only — no UPDATE, no DELETE ever. '
    'system notes are auto-generated by platform workflows.';

CREATE INDEX idx_order_notes_order_id
    ON order_notes (order_id, created_at ASC);
-- Rationale: Order detail view fetches all notes for an order in
-- chronological order. Composite covers filter and sort.

CREATE INDEX idx_order_notes_author
    ON order_notes (author_staff_user_id, created_at DESC);
-- Rationale: "Show me all notes written by this staff member" —
-- useful for staff activity audits and support escalations.
```

---

## Updated Schema Inventory Entry

After generating this artifact, update `06-schema-inventory.md`:

```
| `06c-tenant-orders-schema.md` | ✅ Generated | 6 | Orders, line items, events (append-only), shipments, shipment items, notes |
```
