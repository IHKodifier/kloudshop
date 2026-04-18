# 06n — State Machines
# KloudShop Stage 6 — Data Model

> **Artifact:** `06n-state-machines.md`
> **Stage:** 6 — Data Model (documentation sub-artifact)
> **Schema:** N/A — documentation only; no DDL produced
> **Persona:** Principal Data Engineer
> **Reads from:** `06a1` (tenants, migration_jobs), `06c` (orders, order_shipments),
>   `06d` (stock_transfers), `06e` (purchase_orders), `06f` (approval_requests,
>   b2b_accounts), `06h` (blog_posts), `06k` (tenant_feature_state),
>   `06m` (subscriptions)
> **Tables documented:** 10 state machines across the full schema
> **Status:** ✅ Generated

---

## Purpose & Conventions

This artifact documents the lifecycle state machines for every entity in the
KloudShop schema that carries a `status` or equivalent lifecycle column. It
is the canonical reference for:

- All valid status values per entity (matching the CHECK constraints defined
  in the DDL artifacts)
- Valid state transitions and the events that trigger them
- Which actor performs each transition (system, staff, consumer, external webhook)
- Which columns are set alongside each transition
- Business rules enforced at the application layer at each transition point

**Conventions used throughout:**

- **State names** match exactly the VARCHAR values enforced by CHECK constraints
  in the DDL. PostgreSQL ENUMs are never used in this schema (see DEC decisions
  in `00-carry-forward-flags.md`) — VARCHAR + CHECK is the pattern throughout.
- **Terminal states** are marked with ⛔. No further transitions are possible
  from a terminal state without explicit operator intervention (admin override),
  which is treated as a separate exceptional flow outside the standard machine.
- **System actor** means the transition is triggered by an automated process:
  Cloud Tasks job, Stripe webhook, Firebase Remote Config sync, Migration Runner,
  or the nightly reconciliation pipeline. No human action is required.
- **Immutable event log**: `order_events` (06c) records every state transition
  for the `orders` machine as append-only rows. Other machines do not have a
  dedicated event log — their lifecycle is traced via the `updated_at` column
  plus external observability (Cloud Logging, Sentry).
- **Timestamps set at transition**: each transition description notes which
  `TIMESTAMPTZ` columns are written alongside the status column change. All
  timestamps are UTC.

---

## 1. Order Lifecycle — `orders.fulfilment_status` + `orders.payment_status`

**Table:** `tenant_{tenant_id}.orders`
**Relevant columns:** `fulfilment_status VARCHAR(24)`, `payment_status VARCHAR(16)`,
`placed_at TIMESTAMPTZ`, `cancelled_at TIMESTAMPTZ`
**Source artifact:** `06c-tenant-orders-schema.md`

The order entity has two independent status dimensions that evolve in parallel:
**payment status** (does KloudShop have money for this order?) and **fulfilment
status** (have the goods been sent?). They are modelled as separate columns
rather than a single composite status because the two axes are genuinely
orthogonal — a B2B net-terms order can be fully shipped before the invoice is
paid, and a refunded order may have already been delivered. Treating them
separately keeps each axis simple and avoids a combinatorial explosion of
composite states.

### 1a. Payment Status Machine

```
                          ┌─────────────────────────────────────┐
                          │             PAYMENT STATUS           │
                          └─────────────────────────────────────┘

  [Order placed]
       │
       ▼
  ┌──────────┐  Stripe webhook: payment_intent.succeeded    ┌──────┐
  │ pending  │ ─────────────────────────────────────────── ▶│ paid │
  └──────────┘                                              └──────┘
       │                                                       │
       │  Stripe webhook: payment_intent.payment_failed        │  Stripe webhook:
       ▼                                                       │  charge.refund.created (full)
  ┌────────┐                                                   ▼
  │ failed │ ⛔                                        ┌──────────────┐
  └────────┘                                           │  refunded    │ ⛔
                                                       └──────────────┘
  [Order cancelled before capture]                            ▲
       │                                                       │
       ▼                                          Stripe webhook:
  ┌────────┐                                      charge.refund.created (partial)
  │ voided │ ⛔                                              │
  └────────┘                                         ┌──────────────────────┐
                                                     │ partially_refunded   │
  [Net-terms B2B order: invoice issued]              └──────────────────────┘
       │
       ▼
  ┌──────────┐  Stripe webhook: invoice.paid           ┌──────┐
  │ pending  │ ─────────────────────────────────────── ▶│ paid │
  └──────────┘
```

**Valid payment_status values and transitions:**

| From | Event / Trigger | To | Actor | Columns Set |
|------|-----------------|----|-------|-------------|
| *(order created)* | Order placed — payment capture pending | `pending` | System | `placed_at = NOW()` |
| `pending` | Stripe `payment_intent.succeeded` webhook | `paid` | System (webhook) | `updated_at = NOW()` |
| `pending` | Stripe `payment_intent.payment_failed` webhook | `failed` | System (webhook) | `updated_at = NOW()` |
| `pending` | Order cancelled before payment captured | `voided` | Staff or System | `cancelled_at = NOW()`, `cancelled_by = actor_id` |
| `paid` | Full refund issued via Stripe Refunds API | `refunded` | Staff | `updated_at = NOW()` |
| `paid` | Partial refund issued | `partially_refunded` | Staff | `updated_at = NOW()` |
| `partially_refunded` | Remaining balance fully refunded | `refunded` | Staff | `updated_at = NOW()` |

**Business rules at transition:**
- `failed` is not terminal in user experience terms — the consumer can retry payment — but each retry creates a new Stripe PaymentIntent and writes a new `order_events` row. The `payment_status` column does not reset; a new attempt is tracked separately.
- `voided` is only reachable from `pending`. An order that has been `paid` is never voided — it must go through the refund path.
- `refunded` and `voided` are terminal. No further payment-status transitions occur on these orders.
- Every transition writes an `order_events` row (06c). The `order_events.event_type` values mapping to payment transitions are: `payment_confirmed`, `payment_failed`, `payment_voided`, `refund_initiated`, `refund_completed`, `invoice_issued`, `invoice_paid`, `invoice_overdue`.

---

### 1b. Fulfilment Status Machine

```
                    ┌──────────────────────────────────────────────┐
                    │              FULFILMENT STATUS                │
                    └──────────────────────────────────────────────┘

  [Order confirmed / payment received]
         │
         ▼
  ┌──────────────┐  First shipment created      ┌───────────────────────┐
  │ unfulfilled  │ ───────────────────────────▶ │ partially_fulfilled   │
  └──────────────┘                              └───────────────────────┘
         │                                               │
         │  All items included in                        │  Remaining items shipped
         │  a single shipment                            ▼
         │                                       ┌─────────────┐
         └──────────────────────────────────────▶│  fulfilled  │
                                                 └─────────────┘
         │ (from unfulfilled or partially)               │
         ▼                                               │  All shipments confirmed
  ┌─────────────┐                                        │  delivered by carrier
  │  cancelled  │ ⛔                                     ▼
  └─────────────┘                               ┌─────────────┐
                                                │  delivered  │
  [From fulfilled or delivered]                 └─────────────┘
         │
         ▼
  ┌─────────────┐
  │  returned   │  (not terminal — return resolved via payment refund path)
  └─────────────┘
```

**Valid fulfilment_status values and transitions:**

| From | Event / Trigger | To | Actor | Columns Set |
|------|-----------------|----|-------|-------------|
| *(order confirmed)* | Payment confirmed — no shipments yet | `unfulfilled` | System | `placed_at = NOW()` |
| `unfulfilled` | First shipment record created (partial items) | `partially_fulfilled` | Staff | `updated_at = NOW()` |
| `unfulfilled` | Shipment created covering all items | `fulfilled` | Staff | `updated_at = NOW()` |
| `partially_fulfilled` | Final remaining items shipped | `fulfilled` | Staff | `updated_at = NOW()` |
| `fulfilled` | All shipments confirmed delivered | `delivered` | System (carrier webhook) | `updated_at = NOW()` |
| `unfulfilled` | Order cancelled before any dispatch | `cancelled` | Staff or Consumer | `cancelled_at = NOW()`, `cancelled_by` |
| `partially_fulfilled` | Order cancelled (remaining unshipped items) | `cancelled` | Staff | `cancelled_at = NOW()`, `cancelled_by` |
| `fulfilled` | Return initiated by consumer or staff | `returned` | Staff or Consumer | `updated_at = NOW()` |
| `delivered` | Return initiated post-delivery | `returned` | Staff or Consumer | `updated_at = NOW()` |

**Business rules at transition:**
- `fulfilment_status` is a **denormalised summary**. The source of truth for per-shipment state is `order_shipments.shipment_status` (06c). The application must update `fulfilment_status` atomically when creating or updating `order_shipments` rows.
- `cancelled` is terminal for fulfilment purposes. A cancelled order may still transition through the payment status machine (e.g. to `refunded`).
- `returned` is not terminal — it signals a return has been initiated. The resolution (goods received back, refund issued) flows through the payment machine and the `order_events` log.
- Digital-only orders (`order_items.is_digital = TRUE` for all items) transition directly from `unfulfilled` to `fulfilled` upon download link delivery — they never touch `partially_fulfilled`.

---

## 2. Trial Lifecycle — `tenants.account_status`

**Table:** `kloudshop_platform.tenants`
**Relevant columns:** `account_status VARCHAR(16)`, `is_trial BOOLEAN`,
`is_paid BOOLEAN`, `trial_hard_stop_trigger VARCHAR(16)`,
`trial_hard_stop_at TIMESTAMPTZ`, `trial_published_closing_at TIMESTAMPTZ`,
`trial_permanent_deletion_at TIMESTAMPTZ`, `soft_deleted_at TIMESTAMPTZ`
**Source artifact:** `06a1-platform-core-schema.md`

```
  [Merchant completes signup]
         │
         ▼
  ┌───────────────┐
  │ provisioning  │  ──── GCP resource provisioning in progress (SYS-01)
  └───────────────┘
         │
         │  All GCP readiness probes pass
         ▼
  ┌────────┐
  │ active │  ◄──────────────────────────────────────────────────────────┐
  └────────┘                                                              │
         │                                                                │
         │  Any of three hard-stop triggers fires:                        │ Merchant pays →
         │  (a) trial_gcp_credit_used >= 5.00                            │ Stripe payment
         │  (b) trial_gmv_total >= 600.00                                │ confirmed
         │  (c) NOW() >= trial_start_at + INTERVAL '30 days'             │
         ▼                                                                │
  ┌──────────────┐                                              ┌──────────────────┐
  │ hard_stopped │ ─── 216-hour window (168h published + 48h ──▶│   [upgraded to   │
  └──────────────┘     silent grace) with visitor count emails  │  paid — returns  │
         │                                                       │  to active]      │
         │  216-hour window elapses without upgrade              └──────────────────┘
         │  (permanent data deletion executes)
         ▼
  ┌─────────┐
  │ deleted │ ⛔  (row retained; soft_deleted_at set; Firebase Auth deleted;
  └─────────┘     GCIP tenant deleted; all product/order/customer data destroyed)


  [Separately — payment failure path for paid merchants]
  ┌────────┐  Stripe dunning exhausted    ┌───────────┐  Payment received  ┌────────┐
  │ active │ ─────────────────────────── ▶│ suspended │ ─────────────────▶ │ active │
  └────────┘                              └───────────┘                    └────────┘
```

**Valid account_status values and transitions:**

| From | Event / Trigger | To | Actor | Columns Set |
|------|-----------------|----|-------|-------------|
| *(signup approved)* | GCP provisioning begins | `provisioning` | System | `created_at = NOW()` |
| `provisioning` | All GCP readiness probes pass | `active` | System (SYS-01) | `gcp_provisioning_status = 'complete'` |
| `provisioning` | GCP provisioning fails after retries | `provisioning` (retry) or manual triage | System + Platform Admin | `gcp_provisioning_status = 'failed'` |
| `active` (trial) | GCP credit cap hit ($5.00) | `hard_stopped` | System (Cloud Tasks) | `trial_hard_stop_trigger = 'gcp_credit'`, `trial_hard_stop_at = NOW()`, `trial_published_closing_at`, `trial_permanent_deletion_at` |
| `active` (trial) | GMV cap hit ($600.00) | `hard_stopped` | System (Cloud Tasks) | `trial_hard_stop_trigger = 'gmv_cap'`, same timestamps |
| `active` (trial) | Day 30 elapsed | `hard_stopped` | System (Cloud Tasks) | `trial_hard_stop_trigger = 'day_30'`, same timestamps |
| `hard_stopped` | Merchant upgrades to paid tier (Stripe payment confirmed) | `active` | System (Stripe webhook) | `is_trial = FALSE`, `is_paid = TRUE`, `trial_hard_stop_trigger = NULL` (cleared) |
| `hard_stopped` | 216-hour deletion window elapses | `deleted` | System (Cloud Tasks) | `soft_deleted_at = NOW()` |
| `active` (paid) | Stripe dunning exhausted (all retries failed) | `suspended` | System (Stripe webhook) | `is_paid = FALSE`, `updated_at = NOW()` |
| `suspended` | Merchant pays outstanding balance | `active` | System (Stripe webhook) | `is_paid = TRUE`, `updated_at = NOW()` |

**Business rules at transition:**
- The `tenants` row is **never hard-deleted**. `account_status = 'deleted'` is the terminal state but the row survives indefinitely for re-engagement detection and deduplication.
- `trial_published_closing_at` is shown to the merchant in the admin as their closing deadline. It is calculated as: `trial_hard_stop_at + INTERVAL '168 hours'` rounded up to the next `00:00 GMT`.
- `trial_permanent_deletion_at` is the actual execution time: `trial_published_closing_at + INTERVAL '48 hours'`. The 48-hour gap is a silent grace period — never communicated to the merchant.
- During `hard_stopped`, the storefront returns HTTP 503 via a Cloud Storage-hosted static error page (Cloud Run is suspended). No GCP compute cost accrues.
- `trial_gmv_total` hard stop pauses selling but does not suspend the store or start the deletion clock — the merchant retains full admin access and can continue setting up their store. Only the $5 GCP credit and day-30 triggers start the 216-hour deletion window.
- `suspended` merchants have admin access restricted to the billing page only. Storefront is suspended. Reinstatement is automatic within 60 seconds of Stripe payment confirmation.

---

## 3. Feature Activation — `tenant_feature_state.status`

**Table:** `tenant_{tenant_id}.tenant_feature_state`
**Relevant columns:** `status VARCHAR(20)`, `activated_at TIMESTAMPTZ`,
`activated_by UUID`, `deactivated_at TIMESTAMPTZ`, `last_error TEXT`,
`updated_at TIMESTAMPTZ`
**Source artifact:** `06k-tenant-feature-config-schema.md`

```
  [Feature first discovered / tenant provisioned]
         │
         ▼
  ┌───────────┐
  │ available │  ◄─────────────────────────────────────────────┐
  └───────────┘                                                 │
         │                                                      │
         │  Merchant toggles feature ON                        │
         ▼                                                      │
  ┌────────────┐                                                │
  │ activating │  ── Phase 1: Migration Runner applying DDL     │
  └────────────┘      Phase 2: Setup wizard (if has_config)    │
         │     \                                                │
         │      └── Any error ──────────────────────┐          │
         │  Both phases complete                     ▼          │
         ▼                                    ┌────────┐       │
  ┌────────┐                                  │ failed │       │
  │ active │                                  └────────┘       │
  └────────┘                                       │           │
         │                                         │ Merchant  │
         │  Merchant toggles feature OFF            │ retries   │
         ▼                                         └──────────▶│
  ┌──────────────┐                                             │
  │ deactivating │  ── Cleanup jobs run                        │
  └──────────────┘       \                                     │
         │                └── Error ──────────────────────────▶│ (back to failed)
         │  Cleanup complete
         ▼
  ┌──────────┐
  │ inactive │  ◄──────── (config preserved; schema tables retained)
  └──────────┘
         │
         │  Merchant re-activates
         └──────────────────────────────────────────▶ activating
```

**Valid status values and transitions:**

| From | Event / Trigger | To | Actor | Columns Set | Firebase Remote Config |
|------|-----------------|----|-------|-------------|------------------------|
| *(row created)* | Feature first encountered by tenant | `available` | System | `updated_at = NOW()` | `feature_{id}_enabled = FALSE` |
| `available` | Merchant initiates activation | `activating` | Staff | `updated_at = NOW()` | `FALSE` (unchanged) |
| `inactive` | Merchant re-activates | `activating` | Staff | `updated_at = NOW()` | `FALSE` (unchanged) |
| `failed` | Merchant retries activation | `activating` | Staff | `last_error = NULL`, `updated_at = NOW()` | `FALSE` (unchanged) |
| `activating` | Phase 1 (DDL) + Phase 2 (wizard) complete | `active` | System (Migration Runner) + Staff (wizard) | `activated_at = NOW()` (first time only), `activated_by`, `updated_at = NOW()` | **`feature_{id}_enabled = TRUE`** |
| `activating` | Any phase error | `failed` | System | `last_error = <message>`, `updated_at = NOW()` | `FALSE` (unchanged) |
| `active` | Merchant toggles feature OFF | `deactivating` | Staff | `updated_at = NOW()` | `FALSE` (immediately) |
| `deactivating` | Cleanup complete | `inactive` | System | `deactivated_at = NOW()`, `updated_at = NOW()` | `FALSE` (already set) |
| `deactivating` | Cleanup error | `failed` | System | `last_error = <message>`, `updated_at = NOW()` | `FALSE` (unchanged) |

**Business rules at transition:**
- `tenant_feature_config` rows for a feature are **never deleted** when status transitions to `inactive`. Configuration is preserved for re-activation.
- Feature-gated schema tables (created by Phase 1 DDL) are **never dropped** on deactivation. Non-destructive migration policy is absolute — DROP TABLE is forbidden by the CI linter.
- Firebase Remote Config flag `feature_{feature_id}_enabled` is synchronised by FastAPI immediately after every status write. The DB column is the source of truth; Firebase is derived.
- `activated_at` records the **first** successful activation timestamp and is never reset on subsequent re-activations. Use `deactivated_at` and `updated_at` to reconstruct the full activation history.
- The `active` state is the only state in which the feature's storefront functionality is rendered and the feature's API routes are served. All other states result in the feature being hidden/non-functional at the application layer.

---

## 4. Purchase Order Lifecycle — `purchase_orders.status`

**Table:** `tenant_{tenant_id}.purchase_orders`
**Relevant columns:** `status VARCHAR(16)`, `ordered_at TIMESTAMPTZ`,
`expected_delivery_at TIMESTAMPTZ`, `received_at TIMESTAMPTZ`,
`cancelled_at TIMESTAMPTZ`
**Source artifact:** `06e-tenant-supplier-schema.md`

```
  [Merchant or AI replenishment creates PO]
         │
         ▼
  ┌───────┐
  │ draft │  ── Lines can be added, edited, removed. No inventory effects.
  └───────┘
         │
         │  Merchant sends PO to supplier (email via Resend)
         ▼
  ┌──────┐
  │ sent │  ── Lines locked. Merchant can cancel. No inventory effects.
  └──────┘
         │  \
         │   └── Merchant cancels before receipt ──────────────────────┐
         │  Supplier confirms receipt of PO (optional step)             │
         ▼                                                              │
  ┌──────────────┐                                                      │
  │ acknowledged │  (optional) ── Some suppliers use this; many don't  │
  └──────────────┘                                                      │
         │                                                              │
         │  First goods received (partial shipment)                     │
         ▼                                                              │
  ┌─────────┐                                                           │
  │ partial │  ── Some lines received; others still outstanding         │
  └─────────┘                                                           │
         │                                                              │
         │  All lines fully received                                    │
         ▼                                                              │
  ┌──────────┐                                                          ▼
  │ received │ ⛔                                                ┌───────────┐
  └──────────┘                                                   │ cancelled │ ⛔
                                                                 └───────────┘
```

**Valid status values and transitions:**

| From | Event / Trigger | To | Actor | Columns Set | Inventory Effect |
|------|-----------------|----|-------|-------------|-----------------|
| *(created)* | PO drafted by merchant or AI job | `draft` | Staff or System | `created_at = NOW()` | None |
| `draft` | Merchant sends PO email to supplier | `sent` | Staff | `ordered_at = NOW()`, `expected_delivery_at` calculated | None |
| `sent` | Supplier acknowledges PO (optional) | `acknowledged` | System (webhook) or Staff (manual) | `updated_at = NOW()` | None |
| `sent` or `acknowledged` | Partial goods received | `partial` | Staff | `updated_at = NOW()` | `inventory.quantity_on_hand` incremented for received variants; `last_received_at` updated |
| `partial` | Remaining goods received | `received` | Staff | `received_at = NOW()` | `inventory.quantity_on_hand` incremented for final variants |
| `sent` | Merchant cancels before any receipt | `cancelled` | Staff | `cancelled_at = NOW()` | None |
| `acknowledged` | Merchant cancels | `cancelled` | Staff | `cancelled_at = NOW()` | None |
| `partial` | Merchant cancels remaining (some goods already received) | `cancelled` | Staff | `cancelled_at = NOW()` | Previously received stock is retained; no reversal |

**Business rules at transition:**
- Line items are locked (no INSERT/UPDATE/DELETE on `purchase_order_lines`) once status reaches `sent`. Modification requires cancelling and recreating the PO.
- Inventory mutations at goods receipt use `SELECT FOR UPDATE` on the `inventory` row to prevent concurrent write races.
- `purchase_order_lines.qty_received` is set per line on receipt, independently of other lines. A PO can stay in `partial` status for multiple receipt events.
- `purchase_order_lines.manufacture_date DATE` is recorded at goods receipt for perishable variants (`variants.is_perishable = TRUE`). Expiry is computed at the application layer: `expiry_date = manufacture_date + variants.best_before_days`.
- Supplier deletion is blocked (`ON DELETE RESTRICT` on all FKs to `suppliers`) while any PO exists in any status including `cancelled`.

---

## 5. Blog Post Lifecycle — `blog_posts.status`

**Table:** `tenant_{tenant_id}.blog_posts`
**Relevant columns:** `status TEXT`, `scheduled_for TIMESTAMPTZ`,
`published_at TIMESTAMPTZ`
**Source artifact:** `06h-tenant-blog-schema.md`

```
  [Merchant creates a new post]
         │
         ▼
  ┌───────┐
  │ draft │  ── Editable. Not on storefront. Not in sitemap.
  └───────┘
         │  \
         │   └── Merchant sets a future datetime
         │          and clicks "Schedule"
         │                │
         │  Merchant       ▼
         │  clicks    ┌───────────┐
         │  "Publish  │ scheduled │  ── Not on storefront yet.
         │  now"      └───────────┘       Cloud Tasks job pending.
         │                │
         │                │  Cloud Tasks fires at scheduled_for
         │                ▼
         │          ┌───────────┐
         └─────────▶│ published │  ── Live on storefront. In XML sitemap.
                    └───────────┘     hreflang tags active.
                          │                 │
                          │                 │  AI translation job triggered
                          │                 │  for all enabled locales
                          │
                          │  Merchant unpublishes / archives
                          ▼
                    ┌──────────┐
                    │ archived │ ⛔  ── Returns HTTP 410 Gone.
                    └──────────┘       Removed from sitemap.
                                       Content preserved in DB.
```

**Valid status values and transitions:**

| From | Event / Trigger | To | Actor | Columns Set |
|------|-----------------|----|-------|-------------|
| *(created)* | Merchant creates new post | `draft` | Staff | `created_at = NOW()` |
| `draft` | Merchant clicks "Publish now" | `published` | Staff | `published_at = NOW()`, `scheduled_for = NULL` |
| `draft` | Merchant sets future datetime and schedules | `scheduled` | Staff | `scheduled_for = <future TIMESTAMPTZ>` |
| `scheduled` | Cloud Tasks job fires at `scheduled_for` | `published` | System (Cloud Tasks) | `published_at = NOW()` |
| `scheduled` | Merchant cancels scheduled publish | `draft` | Staff | `scheduled_for = NULL` |
| `scheduled` | Merchant edits and re-schedules | `scheduled` | Staff | `scheduled_for = <new TIMESTAMPTZ>` |
| `published` | Merchant unpublishes / archives | `archived` | Staff | `updated_at = NOW()` |
| `draft` | Merchant archives a draft | `archived` | Staff | `updated_at = NOW()` |
| `archived` | Merchant restores to editing | `draft` | Staff | `updated_at = NOW()` |

**Business rules at transition:**
- `scheduled_for` must always be a future TIMESTAMPTZ at the moment of the `draft → scheduled` transition. This constraint is enforced at the FastAPI application layer, not in the DB (the CHECK constraint only ensures `scheduled_for IS NOT NULL` when `status = 'scheduled'`).
- On `draft → published` or `scheduled → published` (via Cloud Tasks), a Google Cloud Translation API job is enqueued via Cloud Tasks to auto-translate the post to all merchant-enabled locales. Translated rows in `blog_post_translations` are created with `is_auto_translated = TRUE`.
- On `published → archived`, the storefront returns HTTP **410 Gone** (not 404). 410 signals intentional permanent removal to Google — preferable to 404 for deindexing speed.
- A `redirect_rules` row is auto-inserted if the slug changes on an existing published post. This preserves SEO equity for any inbound links.
- `archived → draft` is a restore path for posts that need reworking. The post does not become live again until explicitly re-published.
- `body_tsv` (the generated FTS tsvector column) updates automatically on every body write, including edits made to a `published` post.

---

## 6. B2B Approval — `approval_requests.status`

**Table:** `tenant_{tenant_id}.approval_requests`
**Relevant columns:** `status VARCHAR(16)`, `decided_at TIMESTAMPTZ`,
`decided_by UUID`, `decline_reason TEXT`, `escalation_sent_at TIMESTAMPTZ`,
`requested_at TIMESTAMPTZ`
**Source artifact:** `06f-tenant-b2b-schema.md`

```
  [B2B order placed; meets approval threshold]
         │
         ▼
  ┌─────────┐
  │ pending │  ── FCM push + email to approver_roles.
  └─────────┘     Cloud Firestore: approval_requests/{id} written.
         │   \
         │    └── escalation_hours elapsed without action
         │              │
         │              ▼
         │         FCM push + email reminder sent.
         │         escalation_sent_at = NOW()
         │         (returns to pending — not a state change)
         │
  ┌──────┴──────────────────────────────────────────┐
  │                                                 │
  ▼                                                 ▼
  ┌──────────────┐                           ┌──────────┐
  │ auto_approved│                           │ approved │
  └──────────────┘                           └──────────┘
         │  (system)                               │  (staff)
         │                                         │
         └──────────────┬──────────────────────────┘
                        │
                        │  decided_at = NOW()
                        │  decided_by set (NULL for auto_approved)
                        ▼
               Order proceeds to fulfilment.
               Stripe Invoice issued (if net-terms).
               FCM push + email sent to buyer.


  [Alternatively]
  ┌─────────┐  Staff declines  ┌──────────┐ ⛔
  │ pending │ ────────────────▶│ declined │
  └─────────┘                  └──────────┘
                               decided_at = NOW()
                               decided_by = staff_user_id
                               decline_reason set
                               FCM push + email sent to buyer.
                               Order status → cancelled.
```

**Valid status values and transitions:**

| From | Event / Trigger | To | Actor | Columns Set |
|------|-----------------|----|-------|-------------|
| *(order placed, threshold met)* | Order submission with approval required | `pending` | System | `requested_at = NOW()` |
| `pending` | Order within credit limit AND below threshold | `auto_approved` | System | `decided_at = NOW()`, `decided_by = NULL` |
| `pending` | Staff clicks "Approve" in admin | `approved` | Staff | `decided_at = NOW()`, `decided_by = staff_user_id` |
| `pending` | Staff clicks "Decline" in admin | `declined` | Staff | `decided_at = NOW()`, `decided_by = staff_user_id`, `decline_reason = <text>` |
| `pending` | `escalation_hours` elapsed | *(escalation reminder — status unchanged)* | System (Cloud Tasks) | `escalation_sent_at = NOW()` |

**Business rules at transition:**
- `approved` and `auto_approved` are functionally identical for downstream processing — both cause the order to proceed to fulfilment. They are kept as distinct values for analytics (tracking how many orders require human review vs. auto-clear).
- `declined` and `approved`/`auto_approved` are terminal states. Once decided, approval requests are never reopened. If a declined order needs to be resubmitted, the buyer places a new order.
- Every status transition writes a corresponding `order_events` row on the parent order: `approval_requested`, `approval_approved`, `approval_auto_approved`, `approval_declined`.
- A `declined` approval transitions the parent order's `payment_status` to `voided` and `fulfilment_status` to `cancelled`.
- The `decline_reason` is shown to the buyer in their FCM push notification and portal view. It must never expose internal credit limit figures — the merchant writes this message knowing the buyer will read it.
- `auto_approve_within_credit_limit` from `approval_workflows` is evaluated atomically at order placement. If true and the order fits within the buyer's available credit (credit_limit minus current outstanding B2B order totals), the order auto-approves immediately without entering `pending`.

---

## 7. Migration Job — `migration_jobs.scrape_status` + `migration_jobs.import_status` + `migration_jobs.gcp_track_b_status`

**Table:** `kloudshop_platform.migration_jobs`
**Relevant columns:** `scrape_status VARCHAR(16)`, `import_status VARCHAR(16)`,
`gcp_track_b_status VARCHAR(16)`, `started_at TIMESTAMPTZ`,
`completed_at TIMESTAMPTZ`, `retry_count INTEGER`, `error_message TEXT`
**Source artifact:** `06a1-platform-core-schema.md`

The migration job entity has three independent status dimensions that track the
two parallel tracks of the 2-minute onboarding experience:

- **Track A** (scraping + import): `scrape_status` then `import_status`
- **Track B** (GCP provisioning): `gcp_track_b_status`

The merchant sees a unified progress narrative. "Your store is ready" is only
shown when ALL three dimensions have reached their terminal success state.

### 7a. Scrape Status Machine

```
  [Merchant submits competitor URL]
         │
         ▼
  ┌────────┐  Cloud Tasks job begins   ┌─────────────┐
  │ queued │ ─────────────────────────▶│ in_progress │
  └────────┘                           └─────────────┘
                                              │    \
                                              │     └── Bot-protection detected
                                              │              │
                                              │              ▼
                                              │         ┌─────────┐ ⛔
                                              │         │ blocked │  (CSV fallback offered)
                                              │         └─────────┘
                                              │
                                   ┌──────────┴──────────┐
                                   │                     │
                                   ▼                     ▼
                            ┌──────────┐         ┌────────┐ ⛔
                            │ complete │         │ failed │
                            └──────────┘         └────────┘
```

### 7b. Import Status Machine

```
  [scrape_status reaches 'complete' OR CSV uploaded]
         │
         ▼
  ┌─────────┐  AI parse + DB insert starts   ┌─────────────┐
  │ pending │ ───────────────────────────────▶│ in_progress │
  └─────────┘                                 └─────────────┘
                                                     │
                                          ┌──────────┼──────────┐
                                          │          │          │
                                          ▼          ▼          ▼
                                   ┌──────────┐ ┌─────────┐ ┌────────┐ ⛔
                                   │ complete │ │ partial │ │ failed │
                                   └──────────┘ └─────────┘ └────────┘
                                    (all rows)  (some rows   (no rows
                                                  failed)     imported)
```

### 7c. GCP Track B Status Machine

```
  [Tenant approved; provisioning begins in parallel with Track A]
         │
         ▼
  ┌─────────┐  SYS-01 starts   ┌─────────────┐
  │ pending │ ─────────────────▶│ in_progress │
  └─────────┘                   └─────────────┘
                                       │   \
                                       │    └── Cloud Tasks retry on failure
                                       │
                              ┌────────┴────────┐
                              │                 │
                              ▼                 ▼
                       ┌──────────┐       ┌────────┐ ⛔
                       │ complete │       │ failed │  (Sentry alert + retry)
                       └──────────┘       └────────┘
```

**Combined "store is ready" condition:**
`scrape_status = 'complete' AND import_status IN ('complete', 'partial') AND gcp_track_b_status = 'complete'`

**Valid transition tables:**

**scrape_status:**

| From | Event | To | Actor | Notes |
|------|-------|----|-------|-------|
| `queued` | Cloud Tasks job picks up | `in_progress` | System | `started_at = NOW()` |
| `in_progress` | All products scraped successfully | `complete` | System | `completed_at = NOW()` |
| `in_progress` | Bot-protection response received | `blocked` | System | `error_message` set; CSV fallback offered |
| `in_progress` | Network error after max retries | `failed` | System | `error_message` set, `retry_count` incremented |
| `blocked` | *(no further transitions — merchant uses CSV fallback)* | *(terminal)* | — | — |

**import_status:**

| From | Event | To | Actor | Notes |
|------|-------|----|-------|-------|
| `pending` | Scrape complete or CSV uploaded | `in_progress` | System | — |
| `in_progress` | All rows imported without errors | `complete` | System | `completed_at = NOW()`, `products_imported` set |
| `in_progress` | Some rows failed validation | `partial` | System | Failed rows logged; successful rows committed |
| `in_progress` | Complete import failure | `failed` | System | `error_message` set |

**gcp_track_b_status:**

| From | Event | To | Actor | Notes |
|------|-------|----|-------|-------|
| `pending` | Provisioning job starts | `in_progress` | System | — |
| `in_progress` | All resources pass readiness probes | `complete` | System | Cloud Run warm, Cloud SQL schema created, Firebase provisioned |
| `in_progress` | Provisioning error (after retries) | `failed` | System | Sentry alert; merchant shown non-technical error message |

---

## 8. Stock Transfer — `stock_transfers.status`

**Table:** `tenant_{tenant_id}.stock_transfers`
**Relevant columns:** `status VARCHAR(16)`, `initiated_at TIMESTAMPTZ`,
`received_at TIMESTAMPTZ`, `cancelled_at TIMESTAMPTZ`,
`quantity_received INTEGER`
**Source artifact:** `06d-tenant-inventory-schema.md`

```
  [Merchant creates transfer between two locations]
         │
         ▼
  ┌───────┐
  │ draft │  ── No inventory changes. Transfer can be edited or cancelled.
  └───────┘
         │
         │  Merchant initiates transfer (marks stock as dispatched
         │  from source location)
         ▼
  ┌────────────┐
  │ in_transit │  ── source quantity_on_hand DECREMENTED.
  └────────────┘     Stock is "in the air" — not in either location yet.
         │    \
         │     └── Merchant cancels (goods recalled before arrival)
         │                │
         │                ▼
         │         ┌───────────┐ ⛔
         │         │ cancelled │  source quantity_on_hand RE-INCREMENTED
         │         └───────────┘
         │
         │  Merchant confirms receipt at destination
         ▼
  ┌──────────┐ ⛔
  │ received │  destination quantity_on_hand INCREMENTED.
  └──────────┘  quantity_received recorded (may differ from quantity_transferred).
```

**Valid status values and transitions:**

| From | Event / Trigger | To | Actor | Inventory Effect | Columns Set |
|------|-----------------|----|-------|-----------------|-------------|
| *(created)* | Transfer drafted | `draft` | Staff | None | `created_at = NOW()` |
| `draft` | Merchant initiates — stock dispatched from source | `in_transit` | Staff | `inventory.quantity_on_hand` **decremented** for `(variant_id, source_location_id)` | `initiated_at = NOW()`, `initiated_by` |
| `in_transit` | Goods arrive; merchant confirms receipt | `received` | Staff | `inventory.quantity_on_hand` **incremented** for `(variant_id, destination_location_id)` | `received_at = NOW()`, `received_by`, `quantity_received` |
| `in_transit` | Merchant cancels before destination receives | `cancelled` | Staff | `inventory.quantity_on_hand` **re-incremented** at source | `cancelled_at = NOW()` |
| `draft` | Merchant cancels before dispatch | `cancelled` | Staff | None | `cancelled_at = NOW()` |

**Business rules at transition:**
- All inventory mutations use `SELECT FOR UPDATE` on both the source and destination `inventory` rows within a single transaction. Atomic execution prevents concurrent write races.
- In-transit stock is tracked explicitly (the `in_transit` state) so it is never double-counted. During `in_transit`, the stock exists in neither location's `quantity_on_hand`.
- `quantity_received` may be less than `quantity_transferred` (damage, loss in transit). The discrepancy is logged via a `supplier_performance_events` record (for externally-sourced transfers) or an `order_notes` equivalent for internal transfers. The inventory increment at `received` uses `quantity_received`, not `quantity_transferred`.
- `received` and `cancelled` are both terminal. There is no "undo received" path — if goods need to go back, a new transfer is created in the reverse direction.

---

## 9. B2B Account — `b2b_accounts.account_status`

**Table:** `tenant_{tenant_id}.b2b_accounts`
**Relevant columns:** `account_status VARCHAR(20)`, `firebase_uid TEXT`,
`invited_at TIMESTAMPTZ`, `registered_at TIMESTAMPTZ`, `last_login_at TIMESTAMPTZ`
**Source artifact:** `06f-tenant-b2b-schema.md`

```
  [Merchant creates buyer account and sends invitation]
         │
         ▼
  ┌─────────┐  Invitation email sent via Resend
  │ invited │  firebase_uid = NULL (buyer not yet registered)
  └─────────┘
         │
         │  Buyer clicks invitation link and completes registration
         ▼
  ┌──────────────────┐
  │ pending_approval │  ── Only when merchant has configured manual
  └──────────────────┘     approval before portal access.
         │     │
         │     │ Merchant requires manual approval = FALSE
         │     │ (or manual approval = TRUE AND merchant approves)
         │     │
         │     ▼
         │  ┌────────┐
         │  │ active │  ◄──────────────────────────────────────────────┐
         │  └────────┘                                                  │
         │      │                                                       │
         │      │  Merchant suspends (fraud flag, credit concern, etc.)│
         │      ▼                                                       │
         │  ┌───────────┐  Merchant reinstates                         │
         │  │ suspended │ ─────────────────────────────────────────────┘
         │  └───────────┘
         │      │
         │      │  Merchant permanently decommissions
         │      ▼
         │  ┌──────────┐ ⛔
         │  │ archived │  (row retained; all order history preserved)
         │  └──────────┘
         │
         │  [If merchant has manual approval configured]
         │  Buyer registers → pending_approval
         │  Merchant approves → active
         └──────────────────────────────────────────────────────────────
```

**Valid status values and transitions:**

| From | Event / Trigger | To | Actor | Columns Set |
|------|-----------------|----|-------|-------------|
| *(account created)* | Merchant creates account and sends invitation | `invited` | Staff | `invited_at = NOW()`, `invited_by` |
| `invited` | Buyer completes registration (manual approval OFF) | `active` | System (GCIP webhook) | `registered_at = NOW()`, `firebase_uid` set, `last_login_at = NOW()` |
| `invited` | Buyer completes registration (manual approval ON) | `pending_approval` | System (GCIP webhook) | `registered_at = NOW()`, `firebase_uid` set |
| `pending_approval` | Merchant approves portal access | `active` | Staff | `updated_at = NOW()` |
| `active` | Merchant suspends account | `suspended` | Staff | `updated_at = NOW()` |
| `suspended` | Merchant reinstates account | `active` | Staff | `updated_at = NOW()` |
| `active` | Merchant archives buyer (permanent decommission) | `archived` | Staff | `updated_at = NOW()` |
| `suspended` | Merchant archives buyer | `archived` | Staff | `updated_at = NOW()` |

**Business rules at transition:**
- A buyer in `invited` status has no portal access. Their `firebase_uid` is NULL — they have not authenticated yet.
- A buyer in `pending_approval` has completed Firebase Auth registration (their `firebase_uid` is set) but their FastAPI JWT validation will return a 403 until status reaches `active`. The FastAPI middleware checks `account_status = 'active'` after resolving the buyer account from `firebase_uid`.
- A buyer in `suspended` status cannot log in or place new orders. Their order history remains fully intact and accessible to staff.
- `archived` is terminal. Archived buyers retain their rows (all historical orders, price list assignments, and approval request records are preserved) but can never log in or be reactivated.
- The `firebase_uid` is never cleared on `archived` — it is retained as a permanent deduplication key in case the same email is later invited as a new buyer (the application detects the collision and flags it).
- `invited_at` and `registered_at` are two distinct timestamps and will always differ when the buyer takes time between receiving the email and clicking the link.

---

## 10. Subscription — `subscriptions.subscription_status`

**Table:** `tenant_{tenant_id}.subscriptions`
**Relevant columns:** `subscription_status VARCHAR(16)`, `next_order_at TIMESTAMPTZ`,
`started_at TIMESTAMPTZ`, `paused_at TIMESTAMPTZ`, `cancelled_at TIMESTAMPTZ`
**Source artifact:** `06m-tenant-feature-gated-schema.md`

> **Feature dependency:** This state machine only applies to tenants who have
> activated the `subscription_orders` Feature Catalogue item. The `subscriptions`
> table does not exist in the base tenant schema.

```
  [Consumer subscribes to a product at checkout]
         │
         ▼
  ┌────────┐
  │ active │  ── Cloud Tasks job fires at next_order_at.
  └────────┘     Recurring order placed automatically.
                 next_order_at advanced by frequency duration.
         │    \
         │     └── Consumer pauses subscription
         │                │
         │                ▼
         │         ┌────────┐  Consumer resumes  ┌────────┐
         │         │ paused │ ──────────────────▶ │ active │
         │         └────────┘                     └────────┘
         │              │
         │              │ Consumer cancels from paused
         │              ▼
         │  Consumer cancels from active
         ├──────────────────────────────┐
         │                             │
         ▼                             ▼
  ┌───────────┐                 ┌─────────┐ ⛔
  │ cancelled │ ⛔              │ expired │
  └───────────┘                 └─────────┘
  (consumer action)        (reached configured end date,
                            if one was set)
```

**Valid status values and transitions:**

| From | Event / Trigger | To | Actor | Columns Set |
|------|-----------------|----|-------|-------------|
| *(created at checkout)* | Consumer confirms subscription at checkout | `active` | System | `started_at = NOW()`, `next_order_at` = first order datetime |
| `active` | Cloud Tasks fires at `next_order_at`; order placed | `active` *(self-loop)* | System | `next_order_at` advanced by frequency duration |
| `active` | Consumer pauses from account panel | `paused` | Consumer or Staff | `paused_at = NOW()`, `next_order_at = NULL` |
| `paused` | Consumer resumes from account panel | `active` | Consumer or Staff | `paused_at = NULL`, `next_order_at` recalculated from NOW() |
| `active` | Consumer cancels | `cancelled` | Consumer or Staff | `cancelled_at = NOW()`, `next_order_at = NULL` |
| `paused` | Consumer cancels from paused | `cancelled` | Consumer or Staff | `cancelled_at = NOW()` |
| `active` | Configured end date reached | `expired` | System (Cloud Tasks) | `updated_at = NOW()`, `next_order_at = NULL` |

**Business rules at transition:**
- A Cloud Tasks job fires at each `next_order_at` timestamp to place the recurring order. On successful order placement, `next_order_at` is advanced by the frequency duration:
  - `weekly` → +7 days
  - `biweekly` → +14 days
  - `monthly` → +1 calendar month (same day of month)
  - `quarterly` → +3 calendar months
- If the recurring order fails (payment method declined, out of stock), the Cloud Tasks job retries according to the tenant's configured retry policy before marking the subscription as `paused` with an error flag (application-layer behaviour — no additional status value is needed; `paused` covers all pause-reason scenarios including payment failure).
- On `paused → active` resume, `next_order_at` is recalculated from the current date + frequency duration, not from the date of the last successful order. This prevents a backlog of "missed" orders accumulating during a pause.
- `cancelled` and `expired` are terminal. A cancelled consumer who wants to resubscribe must create a new subscription row at checkout.
- `subscription_orders` rows (linking a recurring order to its parent subscription) are created for every order placed in the `active → active` self-loop. `billing_attempt_number` increments on each successful billing cycle.

---

## Cross-Reference: Status Values by Table

| Table | Column | Valid Values |
|-------|--------|-------------|
| `orders` | `payment_status` | `pending`, `paid`, `partially_refunded`, `refunded`, `voided`, `failed` |
| `orders` | `fulfilment_status` | `unfulfilled`, `partially_fulfilled`, `fulfilled`, `delivered`, `returned`, `cancelled` |
| `orders` | `approval_status` | `pending`, `approved`, `auto_approved`, `declined`, NULL |
| `order_shipments` | `shipment_status` | `pending`, `label_ready`, `dispatched`, `in_transit`, `delivered`, `failed`, `cancelled` |
| `tenants` | `account_status` | `provisioning`, `active`, `hard_stopped`, `suspended`, `deleted` |
| `tenants` | `gcp_provisioning_status` | `pending`, `in_progress`, `complete`, `failed` |
| `tenant_feature_state` | `status` | `available`, `activating`, `active`, `deactivating`, `inactive`, `failed` |
| `purchase_orders` | `status` | `draft`, `sent`, `acknowledged`, `partial`, `received`, `cancelled` |
| `blog_posts` | `status` | `draft`, `scheduled`, `published`, `archived` |
| `approval_requests` | `status` | `pending`, `approved`, `auto_approved`, `declined` |
| `migration_jobs` | `scrape_status` | `queued`, `in_progress`, `complete`, `failed`, `blocked` |
| `migration_jobs` | `import_status` | `pending`, `in_progress`, `complete`, `failed`, `partial` |
| `migration_jobs` | `gcp_track_b_status` | `pending`, `in_progress`, `complete`, `failed` |
| `stock_transfers` | `status` | `draft`, `in_transit`, `received`, `cancelled` |
| `b2b_accounts` | `account_status` | `invited`, `pending_approval`, `active`, `suspended`, `archived` |
| `subscriptions` | `subscription_status` | `active`, `paused`, `cancelled`, `expired` |
| `tenant_regions` | `provisioning_status` | `pending`, `in_progress`, `active`, `deprovisioning`, `deprovisioned`, `failed` |

---

## Updated Schema Inventory Entry

Apply the following patch line to `BKP-06-schema-inventory.md` — replace the `06n` row in the Generation Progress table:

```
| `06n-state-machines.md` | ✅ Generated | 10 machines | Order lifecycle (payment_status 6-state + fulfilment_status 6-state — two independent axes). Trial lifecycle (account_status 5-state including hard_stopped 216-hour window). Feature activation (tenant_feature_state 6-state — Firebase Remote Config sync on every transition). Purchase order (6-state including acknowledged as optional supplier-confirmation step). Blog post (4-state — Cloud Tasks scheduling, HTTP 410 on archive). B2B approval (4-state — auto_approved vs approved distinction preserved). Migration job (3 independent axes: scrape_status 5-state, import_status 5-state, gcp_track_b_status 4-state — "store ready" requires all three at terminal success). Stock transfer (4-state — explicit in_transit for double-entry inventory accounting). B2B account (5-state — pending_approval gated on merchant config). Subscription (4-state — next_order_at self-loop on active). Cross-reference table of all status columns and valid values included. |
```
