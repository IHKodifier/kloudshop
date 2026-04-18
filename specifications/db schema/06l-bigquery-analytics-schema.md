# 06l — BigQuery Analytics Schema
# KloudShop Stage 6 — Data Model

> **Artifact:** `06l-bigquery-analytics-schema.md`
> **Stage:** 6 — Data Model (sub-artifact L of L)
> **Persona:** Principal Data Engineer
> **Reads from:** `06a1`, `06a2`, `06b` (v2), `06c`, `06d`, `06e`, `06f`, `06g`, `06h`, `06i`, `06j`, `06k` — all prior Stage 6 sub-artifacts
> **Feeds into:** `06m-schema-inventory-consolidation.md` (final), `07-roadmap.md`
> **Status:** ✅ Generated — 12 Apr 2025
> **Author persona:** Principal Data Engineer

---

## Overview

- KloudShop's analytics layer is **fully decoupled from the operational PostgreSQL schemas**. No direct JDBC/Debezium → BigQuery connection exists; all analytics data flows through the pipeline: **Pub/Sub → Dataflow → BigQuery**. Debezium publishes CDC events to Pub/Sub topics; Dataflow jobs consume, transform, deduplicate, and load into BigQuery.
- Two BigQuery dataset scopes exist: **`kloudshop_analytics`** (platform-owned, cross-tenant, contains aggregated/platform-level metrics) and **`tenant_{tenant_id}_analytics`** (one dataset per merchant, contains merchant-scoped clickstream, funnel, and search data).
- **No PII enters BigQuery under any circumstances.** `visitor_id` is a pseudonymous UUID generated at the storefront edge. No names, emails, phone numbers, postal addresses, or device fingerprints are written to any analytics table. This is enforced by the Dataflow transformation layer, not by BigQuery column-level security alone.
- **All monetary values are INT64 in minor currency units** (paise for INR, fils for AED, cents for USD), consistent with the convention established in `06c`. Division by the tenant's `currency_minor_unit_factor` (stored in `tenant_core.tenants`) is the responsibility of BI layer queries, not of the schema.
- **Partitioning strategy:** High-volume raw event tables partition on `ingested_at` (TIMESTAMP, daily granularity) to align with Dataflow batch boundaries. Daily rollup tables partition on `event_date` (DATE) since analytical queries always filter by calendar day ranges.
- **Clustering strategy:** Cluster keys are chosen to match the dominant `WHERE` and `GROUP BY` patterns in merchant analytics dashboards and platform ops queries. Clustering never includes more than four columns (BigQuery maximum).
- **Cross-tenant tables** in `kloudshop_analytics` use `tenant_id` (STRING, UUID form) as a cluster column, not a partition column. BigQuery does not support partitioning on UUID/STRING in a meaningful way; integer range partitioning on a hash of `tenant_id` would add implementation complexity with marginal gain at current expected tenant counts (<10,000). This decision is documented and revisable when tenant count exceeds 50,000.
- **Deduplication** is per-table and explicit. Streaming inserts use `insert_id` (mapped to the event's natural business key) for best-effort deduplication within the BigQuery streaming buffer window (~1 minute). Scheduled daily `MERGE` jobs provide the authoritative deduplication pass for all tables, running at 02:00 UTC before dashboard refresh jobs.
- **Schema evolution policy:** All columns are `NULLABLE` by default unless marked `REQUIRED`. Adding `NULLABLE` columns is non-breaking. Renaming or dropping columns requires a versioned migration with a 30-day deprecation window, coordinated with the Dataflow pipeline team.
- **Retention:** `storefront_events` retains 90 days of hot data in BigQuery; older partitions are archived to Cloud Storage via scheduled export jobs. All daily rollup tables retain 36 months.
- This artifact defines **five tables across two datasets**. Additional tables (e.g., `product_performance_daily`, `coupon_attribution_daily`) are identified as architectural gaps and flagged for `06m` resolution.

---

## Dataset: `kloudshop_analytics` (Platform-scoped, cross-tenant)

This dataset is owned by the KloudShop platform team. It holds cross-tenant aggregations and platform health metrics. Access is restricted to internal platform engineers and executive dashboards; no merchant can read another merchant's rows, enforced via BigQuery row-level security policies keyed on `tenant_id` for any merchant-facing access paths.

---

### Table: `platform_feature_adoption`

**Purpose:** One row per `(tenant_id, feature_id, event_date)`. Tracks how merchants activate, configure, and actively use each platform feature over time. Powers the internal Feature Adoption dashboard and feeds the ML model that predicts churn risk based on feature engagement depth.

**Source pipeline:** Debezium CDC on `kloudshop_platform.feature_registry` and `tenant_{id}.tenant_feature_state` → Pub/Sub topic `kloudshop.platform.feature-state-changes` → Dataflow job `platform-feature-adoption-loader` → this table via daily `MERGE`.

```sql
CREATE TABLE IF NOT EXISTS `kloudshop_analytics.platform_feature_adoption`
(
  -- Grain: one row per (tenant_id, feature_id, event_date)
  tenant_id             STRING    NOT NULL,   -- UUID string; matches kloudshop_platform.tenants.id
  feature_id            STRING    NOT NULL,   -- matches kloudshop_platform.feature_registry.feature_id
  feature_name          STRING    NOT NULL,   -- denormalized from feature_registry for query convenience
  feature_category      STRING,               -- e.g. 'STOREFRONT', 'PAYMENTS', 'MARKETING', 'LOGISTICS'
  event_date            DATE      NOT NULL,   -- calendar date (UTC) of the rolled-up metrics

  -- Activation state
  is_active             BOOL      NOT NULL,   -- true if feature is enabled for this tenant on event_date
  activated_at          TIMESTAMP,            -- first activation timestamp (UTC); NULL if never activated
  deactivated_at        TIMESTAMP,            -- most recent deactivation timestamp (UTC); NULL if currently active

  -- Usage metrics (accumulated for event_date)
  activation_count      INT64     NOT NULL DEFAULT 0,  -- number of times feature was toggled ON on this date
  config_change_count   INT64     NOT NULL DEFAULT 0,  -- number of config mutations on this date
  api_call_count        INT64     NOT NULL DEFAULT 0,  -- Dataflow-counted API calls attributed to this feature
  active_session_count  INT64     NOT NULL DEFAULT 0,  -- storefront sessions where feature was exercised

  -- Platform aggregates (denormalized from cross-tenant rollup)
  platform_active_merchant_count INT64,       -- total merchants with this feature active on event_date (platform view)

  -- Pipeline metadata
  ingested_at           TIMESTAMP NOT NULL,   -- when Dataflow wrote this row
  pipeline_run_id       STRING,               -- Dataflow job run ID for lineage tracing
  source_cdc_offset     STRING                -- Pub/Sub message offset range for auditability
)
-- PARTITION BY event_date:
--   Analytical queries on this table always filter by date ranges (e.g. "adoption trend last 90 days").
--   DATE partitioning aligns with the daily MERGE job cadence and minimises partition scans.
PARTITION BY event_date

-- CLUSTER BY (feature_category, feature_id, tenant_id):
--   Platform ops queries most commonly filter by feature_category first ("show all PAYMENTS features"),
--   then drill to a specific feature_id, then optionally to a tenant_id.
--   tenant_id is last because cross-tenant scans (all tenants for one feature) are more common
--   than single-tenant scans (all features for one tenant) in this dataset.
CLUSTER BY feature_category, feature_id, tenant_id

OPTIONS (
  description = "Cross-tenant feature adoption metrics. One row per (tenant_id, feature_id, event_date). "
                "Tracks activation state, config change frequency, and API usage per feature per merchant per day. "
                "Business rule: a merchant counts as 'active' for a feature if is_active=TRUE AND api_call_count > 0 on the event_date. "
                "Activation_count > 1 on a single date indicates toggles (possible integration issues — monitor). "
                "No PII. Monetary values: none in this table.",
  partition_expiration_days = 1095,  -- 36 months retention
  require_partition_filter = false   -- platform queries may scan all dates for cohort analysis
);
```

**Deduplication key:** `(tenant_id, feature_id, event_date)` — see Deduplication Strategy section.

---

### Table: `platform_revenue_daily`

**Purpose:** One row per `(tenant_id, event_date)`. Daily gross merchandise value (GMV) and order count rollup per merchant. Used for platform-level revenue dashboards, billing reconciliation checks, and merchant health scoring. This is a derived table — it does not replace merchant-level order detail (which lives in `tenant_{id}.orders` in PostgreSQL).

**Source pipeline:** Debezium CDC on `tenant_{id}.orders` (status transitions to `COMPLETED`) → Pub/Sub topic `kloudshop.orders.status-changes` → Dataflow job `platform-revenue-daily-loader` → this table via daily `MERGE`.

```sql
CREATE TABLE IF NOT EXISTS `kloudshop_analytics.platform_revenue_daily`
(
  -- Grain: one row per (tenant_id, event_date)
  tenant_id                   STRING    NOT NULL,  -- UUID string
  tenant_name                 STRING    NOT NULL,  -- denormalized; updated on MERGE if changed
  tenant_plan_tier            STRING,              -- 'STARTER' | 'GROWTH' | 'ENTERPRISE' — from tenants table
  event_date                  DATE      NOT NULL,  -- calendar date (UTC) of orders placed

  -- Revenue metrics (all INT64 in minor currency units)
  gross_revenue_minor         INT64     NOT NULL DEFAULT 0,  -- sum of orders.total_amount for COMPLETED orders
  net_revenue_minor           INT64     NOT NULL DEFAULT 0,  -- gross minus refunds_minor
  refunds_minor               INT64     NOT NULL DEFAULT 0,  -- sum of refunded amounts on this date
  platform_fee_minor          INT64     NOT NULL DEFAULT 0,  -- KloudShop platform fee collected (from billing events)
  payment_gateway_fee_minor   INT64     NOT NULL DEFAULT 0,  -- gateway fees passed through (from payment_transactions)

  -- Currency
  currency_code               STRING    NOT NULL,            -- ISO 4217 e.g. 'INR', 'AED', 'USD'
  currency_minor_unit_factor  INT64     NOT NULL,            -- 100 for INR/AED/USD; divide to get major units

  -- Order counts
  orders_placed               INT64     NOT NULL DEFAULT 0,
  orders_completed            INT64     NOT NULL DEFAULT 0,
  orders_cancelled            INT64     NOT NULL DEFAULT 0,
  orders_refunded             INT64     NOT NULL DEFAULT 0,
  average_order_value_minor   INT64,                         -- gross_revenue_minor / orders_completed; NULL if 0 orders

  -- Pipeline metadata
  ingested_at                 TIMESTAMP NOT NULL,
  pipeline_run_id             STRING,
  last_merge_at               TIMESTAMP                      -- timestamp of last MERGE job that touched this row
)
-- PARTITION BY event_date:
--   Revenue queries are always date-bounded ("last 30 days GMV", "month-over-month comparison").
--   DATE partitioning is the natural fit; TIMESTAMP partitioning would add unnecessary granularity overhead.
PARTITION BY event_date

-- CLUSTER BY (tenant_plan_tier, tenant_id):
--   Platform revenue queries most commonly segment by plan tier first ("ENTERPRISE cohort GMV"),
--   then by individual tenant. This ordering reduces bytes scanned for tier-level aggregations.
CLUSTER BY tenant_plan_tier, tenant_id

OPTIONS (
  description = "Cross-tenant daily revenue rollup. One row per (tenant_id, event_date). "
                "All monetary columns are INT64 in minor currency units (paise/fils/cents). "
                "Divide by currency_minor_unit_factor to convert to major units in BI queries. "
                "Business rule: only COMPLETED orders contribute to gross_revenue_minor. "
                "Cancellations counted in orders_cancelled but do NOT reduce gross_revenue_minor "
                "unless a refund is also processed. "
                "No PII. Multi-currency: one row per tenant per day; currency is tenant-level (single currency per tenant in MVP).",
  partition_expiration_days = 1095,
  require_partition_filter = false
);
```

**Deduplication key:** `(tenant_id, event_date)` — see Deduplication Strategy section.

---

## Dataset: `tenant_{tenant_id}_analytics` (Merchant-scoped)

One dataset per merchant, named `tenant_{tenant_id}_analytics` where `{tenant_id}` is the tenant's UUID with hyphens replaced by underscores (BigQuery dataset name constraint). These datasets are provisioned automatically by the tenant onboarding pipeline when a merchant activates their storefront. Access is scoped: each merchant's service account can only read their own dataset.

The tables below are defined in generic form. In practice, they are identical DDL applied to each tenant's dataset via a Terraform template that substitutes `{tenant_id}`.

---

### Table: `storefront_events`

**Purpose:** Raw clickstream event log from the merchant's storefront. This is the highest-volume table in the analytics layer — expected 5M–50M rows/day per active merchant at scale. It is the source of truth for all downstream tenant-scoped rollup tables. Events are emitted by the KloudShop storefront JS SDK and the mobile SDK, processed by the Edge Event Collector service, and published to Pub/Sub.

**Source pipeline:** Storefront SDK → Edge Event Collector → Pub/Sub topic `tenant.{tenant_id}.storefront-events` → Dataflow job `storefront-events-loader` → this table (streaming insert with `insert_id` dedup).

```sql
CREATE TABLE IF NOT EXISTS `tenant_{tenant_id}_analytics.storefront_events`
(
  -- Grain: one row per raw event
  event_id          STRING    NOT NULL,   -- UUID v4 generated by SDK at event emission time; dedup key
  session_id        STRING    NOT NULL,   -- UUID v4; scoped to a browser/app session; no PII
  visitor_id        STRING    NOT NULL,   -- pseudonymous UUID v4; persisted in 1st-party cookie or device keychain
                                          -- NOT linked to any user account; no reverse-mapping stored
  event_date        DATE      NOT NULL,   -- UTC date derived from event_timestamp; used for partition pruning
  event_timestamp   TIMESTAMP NOT NULL,   -- UTC timestamp of event as recorded by SDK (client-side clock)
  ingested_at       TIMESTAMP NOT NULL,   -- UTC timestamp when Dataflow wrote this row

  -- Event classification
  event_type        STRING    NOT NULL,   -- controlled vocabulary: 'PAGE_VIEW' | 'PDP_VIEW' | 'SEARCH' |
                                          -- 'ADD_TO_CART' | 'REMOVE_FROM_CART' | 'CHECKOUT_INITIATED' |
                                          -- 'CHECKOUT_STEP' | 'ORDER_PLACED' | 'WISHLIST_ADD' |
                                          -- 'PRODUCT_CLICK' | 'PROMO_IMPRESSION' | 'PROMO_CLICK' |
                                          -- 'FILTER_APPLIED' | 'SORT_CHANGED' | 'REVIEW_READ' | 'CUSTOM'
  event_category    STRING,               -- grouping: 'NAVIGATION' | 'PRODUCT' | 'SEARCH' | 'CART' |
                                          --           'CHECKOUT' | 'ENGAGEMENT' | 'CUSTOM'

  -- Page context
  page_url          STRING,               -- full URL path (no query params that might contain PII)
                                          -- Dataflow strips utm_email, subscriber_id, and similar PII params
  page_type         STRING,               -- 'HOME' | 'PLP' | 'PDP' | 'CART' | 'CHECKOUT' |
                                          -- 'SEARCH_RESULTS' | 'ACCOUNT' | 'STATIC' | 'CUSTOM'
  referrer_domain   STRING,               -- domain of HTTP referrer only (no path, no query string)

  -- Product context (populated when event is product-related)
  product_id        STRING,               -- UUID; matches tenant PostgreSQL products.id
  variant_id        STRING,               -- UUID; matches product_variants.id
  category_id       STRING,               -- UUID; leaf category of the product at event time
  price_minor       INT64,                -- display price at event time (minor currency units); NOT order price
  in_stock          BOOL,                 -- stock status at event time (from inventory snapshot)

  -- Search context (populated for SEARCH and FILTER_APPLIED events)
  search_query      STRING,               -- raw search query string (scrubbed of PII by Dataflow)
  search_result_count INT64,              -- number of results returned
  search_is_zero_result BOOL,             -- true if search_result_count = 0
  clicked_rank      INT64,                -- 1-based rank of clicked result (for PRODUCT_CLICK from search)

  -- Cart context (populated for CART events)
  cart_id           STRING,               -- UUID; matches tenant PostgreSQL carts.id
  quantity          INT64,                -- quantity added/removed

  -- Checkout context (populated for CHECKOUT events)
  checkout_step     INT64,                -- 1=address, 2=shipping, 3=payment, 4=review
  order_id          STRING,               -- UUID; matches tenant PostgreSQL orders.id (ORDER_PLACED only)

  -- Flexible payload for custom and future event types
  event_properties  JSON,                 -- schema-less bag; Dataflow validates no PII keys are present
                                          -- PII scrubber runs on all JSON values before insert

  -- Device / session metadata (no fingerprinting; no IP address stored)
  device_type       STRING,               -- 'DESKTOP' | 'MOBILE' | 'TABLET'
  os_family         STRING,               -- 'iOS' | 'Android' | 'Windows' | 'macOS' | 'Linux' | 'Other'
  browser_family    STRING,               -- 'Chrome' | 'Safari' | 'Firefox' | 'Edge' | 'App' | 'Other'
  country_code      STRING,               -- ISO 3166-1 alpha-2; derived from IP at edge (IP NOT stored)
  region_code       STRING,               -- ISO 3166-2 region code

  -- Pipeline metadata
  sdk_version       STRING,               -- storefront SDK version for schema compatibility tracking
  pipeline_run_id   STRING                -- Dataflow job run ID
)
-- PARTITION BY ingested_at (TIMESTAMP, daily granularity):
--   storefront_events is a write-heavy, append-only table. Partitioning on ingested_at (rather than
--   event_date) prevents hot-partition issues during high-traffic periods and aligns with Dataflow's
--   streaming insert behaviour. Analytical queries filter on event_date (a column) for business logic
--   but the planner still prunes on ingested_at since they are tightly correlated (max 2 hours skew).
--   require_partition_filter=TRUE enforced: no full-table scans permitted; all queries must supply
--   an ingested_at or event_date predicate.
PARTITION BY DATE(ingested_at)

-- CLUSTER BY (event_type, product_id, session_id):
--   Rollup jobs (order_funnel_daily, search_performance_daily) filter on event_type first,
--   then join on product_id for product-level aggregations. session_id is included to support
--   session-scoped funnel queries (sessionisation) efficiently.
CLUSTER BY event_type, product_id, session_id

OPTIONS (
  description = "Raw storefront clickstream events for tenant {tenant_id}. "
                "High-volume append-only log. Source of truth for all tenant-scoped rollup tables. "
                "PII policy: visitor_id is pseudonymous UUID — no reverse mapping exists or is stored. "
                "IP addresses are consumed at the edge for geo-lookup only; never written here. "
                "event_properties JSON is PII-scrubbed by Dataflow before insert. "
                "Retention: 90 days hot in BigQuery; older partitions archived to GCS. "
                "Business rule: ORDER_PLACED events here are confirmations only — "
                "authoritative order data lives in tenant PostgreSQL orders table.",
  partition_expiration_days = 90,
  require_partition_filter = true   -- ENFORCED: prevents accidental full-table scans on this high-volume table
);
```

**Deduplication key:** `event_id` (UUID v4 from SDK) — see Deduplication Strategy section.

---

### Table: `order_funnel_daily`

**Purpose:** One row per `(event_date, [optional: traffic_source, device_type])`. Daily funnel rollup tracking the conversion cascade from storefront sessions through to completed revenue. This is the primary table powering the merchant's Conversion Dashboard. Produced by a scheduled Dataflow job that reads `storefront_events` and tenant PostgreSQL `orders` (via a nightly snapshot export to GCS, since direct JDBC reads from Dataflow into PostgreSQL are avoided at scale).

**Source pipeline:** `storefront_events` (BigQuery read) + `orders` GCS snapshot → Dataflow job `order-funnel-daily-aggregator` → this table via daily `MERGE`.

```sql
CREATE TABLE IF NOT EXISTS `tenant_{tenant_id}_analytics.order_funnel_daily`
(
  -- Grain: one row per (event_date, device_type, traffic_source)
  event_date              DATE      NOT NULL,  -- UTC calendar date of the funnel sessions
  device_type             STRING    NOT NULL,  -- 'DESKTOP' | 'MOBILE' | 'TABLET' | 'ALL' (rollup row)
  traffic_source          STRING    NOT NULL,  -- 'ORGANIC' | 'PAID_SEARCH' | 'SOCIAL' | 'EMAIL' |
                                               -- 'DIRECT' | 'REFERRAL' | 'ALL' (rollup row)

  -- Funnel stages (each is a distinct count; stages are not cumulative subsets in this table —
  -- the BI layer computes drop-off rates. All counts are visitor/session based, not page-view based.)
  sessions_total          INT64     NOT NULL DEFAULT 0,  -- unique session_ids active on event_date
  sessions_with_pdp       INT64     NOT NULL DEFAULT 0,  -- sessions that fired ≥1 PDP_VIEW event
  sessions_with_atc       INT64     NOT NULL DEFAULT 0,  -- sessions that fired ≥1 ADD_TO_CART event
  sessions_with_checkout  INT64     NOT NULL DEFAULT 0,  -- sessions that fired ≥1 CHECKOUT_INITIATED event
  sessions_with_order     INT64     NOT NULL DEFAULT 0,  -- sessions that fired ≥1 ORDER_PLACED event

  -- Order and revenue outcomes (from tenant orders table snapshot — authoritative)
  orders_placed           INT64     NOT NULL DEFAULT 0,
  orders_completed        INT64     NOT NULL DEFAULT 0,  -- orders reaching COMPLETED status same calendar day
  gross_revenue_minor     INT64     NOT NULL DEFAULT 0,  -- sum of completed order totals (minor currency units)
  currency_code           STRING    NOT NULL,

  -- Conversion rates (pre-computed; stored for dashboard query performance)
  -- All rates are FLOAT64 in range [0.0, 1.0]; NULL if denominator is 0.
  session_to_pdp_rate     FLOAT64,   -- sessions_with_pdp / sessions_total
  pdp_to_atc_rate         FLOAT64,   -- sessions_with_atc / sessions_with_pdp
  atc_to_checkout_rate    FLOAT64,   -- sessions_with_checkout / sessions_with_atc
  checkout_to_order_rate  FLOAT64,   -- sessions_with_order / sessions_with_checkout
  overall_conversion_rate FLOAT64,   -- sessions_with_order / sessions_total

  -- Pipeline metadata
  ingested_at             TIMESTAMP NOT NULL,
  pipeline_run_id         STRING,
  last_merge_at           TIMESTAMP
)
-- PARTITION BY event_date:
--   Funnel analysis is always date-bounded. DATE partitioning is correct for this rollup cadence.
PARTITION BY event_date

-- CLUSTER BY (device_type, traffic_source):
--   Dashboard queries segment by device_type ("mobile vs desktop conversion") and traffic_source
--   ("paid vs organic"). Clustering on these two dimensions eliminates full partition scans for
--   the most common BI query patterns.
CLUSTER BY device_type, traffic_source

OPTIONS (
  description = "Daily order conversion funnel rollup for tenant {tenant_id}. "
                "Grain: one row per (event_date, device_type, traffic_source). "
                "Includes 'ALL' rollup rows for each dimension for total-level queries. "
                "Monetary values: INT64 in minor currency units; divide by currency_minor_unit_factor. "
                "Pre-computed conversion rates stored for dashboard performance (avoid runtime division). "
                "Business rule: sessions_with_order counts sessions where ORDER_PLACED fired; "
                "orders_completed counts orders that reached COMPLETED status on the same calendar day. "
                "These will diverge — multi-day order processing is expected for COD merchants. "
                "No PII. Source: storefront_events (BigQuery) + orders GCS snapshot.",
  partition_expiration_days = 1095,
  require_partition_filter = false
);
```

**Deduplication key:** `(event_date, device_type, traffic_source)` — see Deduplication Strategy section.

---

### Table: `search_performance_daily`

**Purpose:** One row per `(event_date, search_query_normalised)`. Daily search analytics aggregation. Tracks query volume, result quality (zero-result rate), click-through behaviour, and top-clicked products. Powers the merchant's Search Analytics dashboard and feeds the search quality improvement workflow (identifying high-volume zero-result queries for catalogue gap analysis).

**Source pipeline:** `storefront_events` filtered to `event_type IN ('SEARCH', 'PRODUCT_CLICK')` → Dataflow job `search-performance-daily-aggregator` → this table via daily `MERGE`.

```sql
CREATE TABLE IF NOT EXISTS `tenant_{tenant_id}_analytics.search_performance_daily`
(
  -- Grain: one row per (event_date, search_query_normalised)
  event_date                  DATE      NOT NULL,
  search_query_raw            STRING    NOT NULL,  -- most frequent raw form of this normalised query on event_date
  search_query_normalised     STRING    NOT NULL,  -- lowercased, trimmed, stop-words removed, stemmed
                                                   -- used as the dedup/merge key alongside event_date

  -- Search volume
  search_count                INT64     NOT NULL DEFAULT 0,  -- total number of times this query was submitted
  unique_session_count        INT64     NOT NULL DEFAULT 0,  -- distinct session_ids that ran this query

  -- Result quality
  avg_result_count            FLOAT64,             -- average number of results returned across searches
  zero_result_count           INT64     NOT NULL DEFAULT 0,  -- searches that returned 0 results
  zero_result_rate            FLOAT64,             -- zero_result_count / search_count; NULL if search_count=0

  -- Click-through behaviour
  click_count                 INT64     NOT NULL DEFAULT 0,   -- PRODUCT_CLICK events following this query in same session
  click_through_rate          FLOAT64,             -- click_count / search_count; NULL if search_count=0
  avg_click_rank              FLOAT64,             -- average rank position of clicked results

  -- Top clicked products (REPEATED for top-5 by click volume)
  top_clicked_products        ARRAY<STRUCT<
                                product_id    STRING,
                                click_count   INT64,
                                avg_rank      FLOAT64
                              >>,               -- top 5 clicked product_ids for this query on this date

  -- Refinement behaviour
  filter_applied_after_search INT64     NOT NULL DEFAULT 0,  -- FILTER_APPLIED events following this query in session
  sort_changed_after_search   INT64     NOT NULL DEFAULT 0,  -- SORT_CHANGED events following this query in session

  -- Pipeline metadata
  ingested_at                 TIMESTAMP NOT NULL,
  pipeline_run_id             STRING,
  last_merge_at               TIMESTAMP
)
-- PARTITION BY event_date:
--   Search performance analysis is calendar-day oriented ("zero-result queries this week").
--   DATE partitioning is the correct choice for this rollup cadence.
PARTITION BY event_date

-- CLUSTER BY (zero_result_rate, search_count):
--   The primary use case is identifying high-volume, high-zero-result queries for catalogue gap triage.
--   Clustering on zero_result_rate first, then search_count, optimises for this "find worst queries" pattern.
--   Dashboard queries commonly ORDER BY zero_result_rate DESC, search_count DESC within a date range.
CLUSTER BY zero_result_rate, search_count

OPTIONS (
  description = "Daily search query performance rollup for tenant {tenant_id}. "
                "Grain: one row per (event_date, search_query_normalised). "
                "Key use case: identifying high-volume zero-result queries for catalogue gap analysis. "
                "search_query_raw is the most common raw form; search_query_normalised is the merge key. "
                "top_clicked_products is a REPEATED STRUCT of up to 5 products — query with UNNEST(). "
                "Business rule: click_through_rate counts clicks within the same session following the search. "
                "Cross-session attribution is out of scope for this table. "
                "PII scrubbing: Dataflow redacts queries matching patterns for email addresses, phone numbers, "
                "or names (using a configurable regex blocklist) before insert. "
                "Retention: 36 months (1095 days).",
  partition_expiration_days = 1095,
  require_partition_filter = false
);
```

**Deduplication key:** `(event_date, search_query_normalised)` — see Deduplication Strategy section.

---

## Deduplication Strategy

BigQuery streaming inserts guarantee at-least-once delivery. A disciplined two-layer deduplication strategy is required for all tables.

| Table | Natural Dedup Key | Streaming Layer (insert_id) | Scheduled MERGE Cadence | MERGE Key |
|---|---|---|---|---|
| `platform_feature_adoption` | `(tenant_id, feature_id, event_date)` | N/A — batch load only (no streaming) | Daily at 02:00 UTC | `(tenant_id, feature_id, event_date)` |
| `platform_revenue_daily` | `(tenant_id, event_date)` | N/A — batch load only | Daily at 02:00 UTC | `(tenant_id, event_date)` |
| `storefront_events` | `event_id` (UUID) | `event_id` set as `insert_id` on every streaming row | Hourly dedup sweep using `ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY ingested_at)` in a temp table + `MERGE`; full daily confirmation at 01:00 UTC | `event_id` |
| `order_funnel_daily` | `(event_date, device_type, traffic_source)` | N/A — batch load only | Daily at 03:00 UTC (after storefront_events dedup sweep completes) | `(event_date, device_type, traffic_source)` |
| `search_performance_daily` | `(event_date, search_query_normalised)` | N/A — batch load only | Daily at 03:30 UTC | `(event_date, search_query_normalised)` |

**Notes on `storefront_events` streaming dedup:**
- BigQuery's built-in streaming deduplication using `insert_id` provides best-effort deduplication within a ~1-minute window. It is not guaranteed.
- The hourly Dataflow sweep is the primary dedup mechanism for this table. It runs a `CREATE OR REPLACE TABLE ... AS SELECT DISTINCT` on the last 2-hour window and `MERGE`s back.
- The daily MERGE at 01:00 UTC is the authoritative full-partition dedup pass.
- Downstream rollup jobs (`order_funnel_daily`, `search_performance_daily`) must only read `storefront_events` partitions that have passed the daily dedup sweep — enforced by Dataflow job dependency ordering.

**MERGE pattern (reference implementation for all batch tables):**
```sql
MERGE `kloudshop_analytics.platform_revenue_daily` T
USING (
  SELECT * EXCEPT(row_num)
  FROM (
    SELECT *, ROW_NUMBER() OVER (
      PARTITION BY tenant_id, event_date
      ORDER BY ingested_at DESC
    ) AS row_num
    FROM staging.platform_revenue_daily_staging
  )
  WHERE row_num = 1
) S
ON T.tenant_id = S.tenant_id AND T.event_date = S.event_date
WHEN MATCHED THEN UPDATE SET ...
WHEN NOT MATCHED THEN INSERT ...;
```

---

## PII Boundary

KloudShop's analytics layer enforces a strict PII exclusion boundary at the **Dataflow transformation layer**, not at BigQuery ingestion or column-level security. This is a defence-in-depth decision: BigQuery column security is a last-resort control, not the primary enforcement point.

| Data Element | Status in BigQuery | Reason |
|---|---|---|
| Customer names | ❌ Never written | Excluded by Dataflow PII scrubber |
| Customer email addresses | ❌ Never written | Excluded by Dataflow PII scrubber; also matched by regex blocklist on `search_query` fields |
| Customer phone numbers | ❌ Never written | Excluded; phone patterns in search queries are redacted |
| IP addresses | ❌ Never written | Consumed at edge for geo-lookup only; geo fields (country_code, region_code) are stored |
| Physical addresses | ❌ Never written | Delivery address data stays in tenant PostgreSQL `addresses` table |
| Payment card data | ❌ Never written (anywhere) | PCI DSS scope — never touches KloudShop application layer |
| `visitor_id` | ✅ Written (pseudonymous UUID) | No reverse mapping exists or is stored in any system. Cookie/keychain value only. Rotation policy: 12-month TTL on the cookie; visitor_id changes on explicit logout |
| `session_id` | ✅ Written (pseudonymous UUID) | Scoped to a single browser session; no user identity link |
| `order_id` | ✅ Written in `storefront_events` (ORDER_PLACED event only) | UUID reference to PostgreSQL orders table; no PII content in the ID itself |
| `product_id`, `variant_id`, `category_id` | ✅ Written | Internal UUIDs; no PII |
| `search_query_raw` | ✅ Written (after scrubbing) | Dataflow applies regex blocklist to redact email patterns, phone patterns, and configurable name blocklists before writing |
| `event_properties` JSON | ✅ Written (after scrubbing) | Dataflow validates all JSON values against a PII pattern list; flagged values are replaced with `[REDACTED]` |

**Enforcement mechanism:** The Dataflow `PiiScrubberDoFn` transform runs on every event before any write. Scrubber failures trigger dead-letter queue routing to `kloudshop.dlq.pii-scrubber-failures` for manual review. Events that cannot be scrubbed are never written to BigQuery.

**Right-to-erasure implications:** Because `visitor_id` is pseudonymous with no reverse mapping, GDPR/PDPA erasure requests do not require BigQuery row deletion. The cookie/device keychain value is revoked at the edge; the UUID becomes an orphan with no linked identity.

---

## Data Flow Summary

### Platform-scoped dataset (`kloudshop_analytics`)

Operational changes in the shared `kloudshop_platform` schema (feature registry updates, tenant provisioning events) and in per-tenant PostgreSQL schemas (order status transitions) are captured by Debezium, which publishes CDC events to dedicated Pub/Sub topics. For platform feature data, the topic is `kloudshop.platform.feature-state-changes`; for revenue events, `kloudshop.orders.status-changes` aggregates order CDC events from all tenant schemas. Two independent Dataflow streaming jobs consume these topics: `platform-feature-adoption-loader` and `platform-revenue-daily-loader`. Both jobs perform field-level transformation (type casting, minor-unit monetary normalisation, PII field exclusion), write to staging tables in BigQuery, and then yield to the nightly MERGE jobs (02:00 UTC) that perform authoritative deduplication and upsert into the production tables. The staging-to-production MERGE pattern ensures that the production tables always contain exactly one row per grain key, regardless of CDC event ordering or Pub/Sub redelivery.

### Merchant-scoped dataset (`tenant_{tenant_id}_analytics`)

Storefront events are emitted by the KloudShop JS/mobile SDK, received by the Edge Event Collector service (a globally distributed Cloudflare Worker), and published to per-tenant Pub/Sub topics (`tenant.{tenant_id}.storefront-events`). The `storefront-events-loader` Dataflow streaming job consumes each tenant's topic, applies the PII scrubber, validates event schema against the controlled vocabulary, sets `insert_id = event_id` on every streaming write for best-effort deduplication, and inserts into `storefront_events`. An hourly dedup sweep and a daily MERGE pass at 01:00 UTC provide authoritative deduplication. Downstream rollup jobs — `order-funnel-daily-aggregator` and `search-performance-daily-aggregator` — run as Dataflow batch jobs after the 01:00 UTC dedup pass completes, reading from deduplicated `storefront_events` partitions and joining with nightly GCS snapshots of the tenant's PostgreSQL `orders` table (exported by the `pg-to-gcs-snapshot` job at 00:30 UTC). These aggregators write to staging tables, followed by MERGE jobs at 03:00 UTC and 03:30 UTC respectively. All tenant-scoped Dataflow jobs run within the tenant's GCP project boundary when KloudShop is deployed in dedicated-tenant mode; in shared-tenant mode, jobs run in the KloudShop platform project with tenant-scoped IAM bindings on dataset access.

---

## Updated Schema Inventory Entry

Replace the `06l` row in `## Generation Progress` table of `06-schema-inventory.md` with:

```
| `06l` | `06l-bigquery-analytics-schema.md` | BigQuery Analytics Layer | ✅ Generated | 5 tables across 2 BQ datasets: `kloudshop_analytics` (platform_feature_adoption, platform_revenue_daily) + `tenant_{id}_analytics` (storefront_events, order_funnel_daily, search_performance_daily). BigQuery-native DDL with PARTITION BY, CLUSTER BY, OPTIONS. Dedup strategy, PII boundary, and Pub/Sub→Dataflow→BQ pipeline documented. No PII in BQ. All monetary values INT64 minor currency units. |
```

---

## Architectural Gaps Identified — Flag for `06m`

The following tables were identified as absent from the scope definition but represent real analytical needs. They are logged here for `06m` to include in the final schema inventory:

| Gap | Recommended Table | Dataset | Source |
|---|---|---|---|
| Product-level performance analytics | `tenant_{id}_analytics.product_performance_daily` | Merchant | `storefront_events` + `order_items` |
| Coupon and discount attribution | `tenant_{id}_analytics.coupon_attribution_daily` | Merchant | `orders` + `order_discounts` (06d) |
| Inventory velocity analytics | `tenant_{id}_analytics.inventory_movement_daily` | Merchant | `inventory_events` (06g) |
| Platform churn signal | `kloudshop_analytics.platform_churn_signals_daily` | Platform | Feature adoption + revenue + login events |
| Payment method analytics | `tenant_{id}_analytics.payment_method_daily` | Merchant | `payment_transactions` (06e) |

These gaps do not block `06l` approval but must be reflected in `06m`'s schema inventory and ERD addendum.
