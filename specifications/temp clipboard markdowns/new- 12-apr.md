    You are continuing Stage 6 (Data Model) of the KloudShop app-architect project. Your persona: Principal Data Engineer.
    
    Your job: Generate `06l-bigquery-analytics-schema.md` in full — a self-sufficient markdown artifact defining KloudShop's BigQuery analytics layer. Then stop and wait.
    
    Completed artifacts available in the Project: `06a1`, `06a2`, `06b` (v2), `06c`, `06d`, `06e`, `06f`, `06g`, `06h`, `06i`, `06j`, `06k`
    
    Next artifact: `06l-bigquery-analytics-schema.md`
    Schema target: BigQuery — NOT PostgreSQL DDL. Use BigQuery-native DDL (CREATE TABLE IF NOT EXISTS with PARTITION BY, CLUSTER BY, OPTIONS).
    
    Context to carry forward:
    - KloudShop is a multi-tenant SaaS e-commerce platform. Each tenant has a `tenant_{tenant_id}` PostgreSQL schema. Operational data lives in PostgreSQL (06a–06k). Analytics data flows into BigQuery via a streaming pipeline (Pub/Sub → Dataflow → BigQuery).
    - BigQuery dataset structure: one shared `kloudshop_analytics` dataset for cross-tenant platform metrics; one `tenant_{tenant_id}_analytics` dataset per merchant for merchant-scoped analytics.
    - All BigQuery tables should use TIMESTAMP (UTC) not TIMESTAMPTZ (BigQuery has no timezone type).
    - Partitioning: partition on event_date (DATE) or ingested_at (TIMESTAMP) — choose the pattern that matches the query shape of each table.
    - Clustering: cluster on the columns most likely to appear in WHERE and GROUP BY clauses.
    - Every table: a COMMENT (OPTIONS description) with purpose + key business rules.
    - Every PARTITION BY and CLUSTER BY choice: a rationale comment.
    
    Tables to define (minimum — expand if architectural gaps are identified):
    1. `kloudshop_analytics.platform_feature_adoption` — cross-tenant, one row per (tenant_id, feature_id, date). Tracks activation counts, active merchant counts, config change frequency. Source: CDC from `kloudshop_platform.feature_registry` + `tenant_feature_state`.
    2. `kloudshop_analytics.platform_revenue_daily` — cross-tenant daily revenue rollup per tenant. Source: CDC from `tenant_{id}.orders`.
    3. `tenant_{tenant_id}_analytics.storefront_events` — raw clickstream events from the merchant's storefront. High volume. Fields: event_id, session_id, visitor_id, event_type, page_url, product_id, variant_id, event_properties JSON, ingested_at.
    4. `tenant_{tenant_id}_analytics.order_funnel_daily` — daily funnel rollup: sessions → PDPs viewed → add-to-cart → checkout-initiated → orders placed → revenue. Source: aggregated from storefront_events + orders.
    5. `tenant_{tenant_id}_analytics.search_performance_daily` — daily search analytics: query, result_count, click_through_rate, zero_results_rate. Source: search events from storefront_events.
    
    Locked architectural decisions:
    - No personally identifiable information (PII) in BigQuery. visitor_id is a pseudonymous UUID. No names, emails, or phone numbers in any analytics table.
    - All monetary amounts in BigQuery: INT64 in minor currency units (paise / fils / cents) — same convention as PostgreSQL schema (established in 06c).
    - Cross-tenant tables in `kloudshop_analytics` dataset use `tenant_id UUID` as a partition column surrogate (via integer hash if needed) or cluster column — document the chosen approach.
    - Streaming inserts via Pub/Sub → Dataflow. No direct PostgreSQL → BigQuery CDC via Debezium for analytics (Debezium feeds Pub/Sub; Dataflow handles transformation).
    - Deduplication strategy: each table must document its deduplication key and the recommended approach (MERGE on scheduled job vs. streaming with insert_id).
    
    Output format:
    # 06l — BigQuery Analytics Schema
    # KloudShop Stage 6 — Data Model
    
    > Artifact header block
    
    ## Overview
    [8–12 bullet points]
    
    ## Dataset: `kloudshop_analytics` (Platform-scoped, cross-tenant)
    ### Table: `platform_feature_adoption`
    [BigQuery DDL + rationale]
    ### Table: `platform_revenue_daily`
    [BigQuery DDL + rationale]
    
    ## Dataset: `tenant_{tenant_id}_analytics` (Merchant-scoped)
    ### Table: `storefront_events`
    [BigQuery DDL + rationale]
    ### Table: `order_funnel_daily`
    [BigQuery DDL + rationale]
    ### Table: `search_performance_daily`
    [BigQuery DDL + rationale]
    
    ## Deduplication Strategy
    [Per-table deduplication key + approach]
    
    ## PII Boundary
    [What is excluded and why]
    
    ## Data Flow Summary
    [Pub/Sub → Dataflow → BigQuery pipeline description, one paragraph per dataset]
    
    ## Updated Schema Inventory Entry
    [Exact replacement line for 06-schema-inventory.md]

After generating,  do these two things 

* surgically update the 06-schema-inventory.md to reflect the current status as "✅ Generated" filling the rest of the columns for this particular row in **## Generation Progress*** table particularly filling in the **Notes** column in the table 

* provide a handoff prompt for `06m` (the final schema inventory consolidation and ERD update artifact).
