You are continuing Stage 6 (Data Model) of the KloudShop app-architect project.This is a multi-session, multi-artifact DDL generation workflow.

**Your persona for this stage:** Principal Data Engineer

**Your single job:** Generate the next pending DDL artifact from the schemainventory, in full, as a self-sufficient markdown file with complete PostgreSQLDDL (or BigQuery schema where noted). Then update `06-schema-inventory.md` tomark that artifact ✅ Generated. Then stop and wait for confirmation beforemoving to the next artifact.

* * *

Current state
-------------

The following artifacts are complete and available as uploaded project files:

| Artifact                            | Tables | Notes                                                                                                                                                                                                                                                                                                                              |
| ----------------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `06a1-platform-core-schema.md`      | 16     | Platform core — tenants, staff, billing, trial, order_sources, etc.                                                                                                                                                                                                                                                                |
| `06a2-platform-catalogue-schema.md` | 11     | Themes, feature_registry, feature_config_schema, carriers, carrier_*                                                                                                                                                                                                                                                               |
| `06b-tenant-catalog-schema.md`      | 13     | Products, variants (gap-hardened GAP-01–09a), collections, reviews, ai_copywriter_log                                                                                                                                                                                                                                              |
| `06c-tenant-orders-schema.md`       | 6      | Orders, order_items, order_events (append-only), order_shipments, order_shipment_items, order_notes                                                                                                                                                                                                                                |
| `06d-tenant-inventory-schema.md`    | 5      | stock_locations, inventory (generated quantity_available), stock_reservations, stock_transfers, packaging_presets                                                                                                                                                                                                                  |
| `06e-tenant-supplier-schema.md`     | 6      | suppliers, purchase_orders, purchase_order_lines (manufacture_date for perishable batch traceability), supplier_performance_events (append-only), supplier_score_weights (single-row), shipping_settings (single-row)                                                                                                              |
| `06f-tenant-b2b-schema.md`          | 6      | b2b_accounts (flat, company_name display-only), price_lists, price_list_items, approval_workflows (single-row), approval_requests, b2b_invoices                                                                                                                                                                                    |
| `06g-tenant-storefront-schema.md`   | 7      | brand_profiles (is_age_gated GAP-09b, draft/active theme Cloud Storage paths, enabled_locales), storefront_content ((slot_id,locale) composite PK — DMF-02/06), merchant_carrier_connections (Secret Manager ref only), carrier_checkout_options, static_pages (Tiptap JSONB + body_tsv), static_page_translations, redirect_rules |

* * *

Next artifact to generate: `06h-tenant-blog-schema.md`
------------------------------------------------------

**Schema:** `tenant_{tenant_id}` **Tables: 7** — all BASE schema (provisioned at signup, not feature-gated)

| #   | Table                        | Description                                                                                                                                                                                                                                                                                                        |
| --- | ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | `blog_posts`                 | One row per blog post. Body as Tiptap/ProseMirror JSONB. Companion `body_tsv TSVECTOR GENERATED ALWAYS AS ... STORED` for FTS using `'simple'` dictionary. Status: draft / scheduled / published / archived. `scheduled_for TIMESTAMPTZ` drives Cloud Tasks publish job. `author_id` = staff_user_id (plain UUID). |
| 2   | `blog_post_translations`     | Per-(post_id, locale) translations: title, slug, body (JSONB), body_tsv (generated), meta_title, meta_description. `is_auto_translated` flag — same pattern as product_translations. 'en' excluded by CHECK constraint.                                                                                            |
| 3   | `blog_categories`            | Merchant-defined categories. Holds name, slug, description, sort_order. Slug unique.                                                                                                                                                                                                                               |
| 4   | `blog_category_translations` | Per-(category_id, locale) translations for name, slug, description. Same is_auto_translated pattern.                                                                                                                                                                                                               |
| 5   | `blog_post_categories`       | Join table: many-to-many between blog_posts and blog_categories.                                                                                                                                                                                                                                                   |
| 6   | `blog_tags`                  | Merchant-defined tags. name + slug, normalised into their own table to enable faceted browsing and tag-cloud queries.                                                                                                                                                                                              |
| 7   | `blog_post_tags`             | Join table: many-to-many between blog_posts and blog_tags.                                                                                                                                                                                                                                                         |

* * *

Full pending artifact list (after 06h)
--------------------------------------

| Artifact                              | Tables      | Key notes                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ------------------------------------- | ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `06h-tenant-blog-schema.md`           | 7           | **START HERE**                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `06i-tenant-messaging-schema.md`      | 4           | message_threads, thread_participants, messages (immutable — NO deleted_at, body_tsv GIN with 'simple' FTS per DEC-04), message_attachments                                                                                                                                                                                                                                                                                                                        |
| `06j-tenant-consumer-schema.md`       | 4           | consumers (GCIP-linked via gcip_uid TEXT), consumer_addresses, consumer_sessions, wishlists                                                                                                                                                                                                                                                                                                                                                                       |
| `06k-tenant-feature-config-schema.md` | 3           | tenant_feature_config (BASE schema from day one — NOT feature-gated), tenant_migration_state, tenant_feature_state                                                                                                                                                                                                                                                                                                                                                |
| `06l-tenant-analytics-schema.md`      | 8           | **BigQuery — NOT PostgreSQL DDL.** BigQuery table + view schema definitions. events (partitioned by tenant_id + date), orders_summary, product_performance, customer_cohorts, inventory_velocity, supplier_scores (materialised view), b2b_buyer_activity, ai_copywriter_performance                                                                                                                                                                              |
| `06m-tenant-feature-gated-schema.md`  | 17          | ALL feature-gated — each DDL block carries `-- Feature-gated: activated by Migration Runner on feature activation` header comment. Covers: loyalty (4 tables), discount_codes + redemptions (2), abandoned_cart_jobs (1), dynamic_pricing_rules + events (2), subscription_plans + subscriptions + subscription_orders (3), gift_cards + transactions (2), bundle_definitions + components (2), affiliate_links (1). Also includes GAP-07 event ticketing tables. |
| `06n-state-machines.md`               | 10 machines | Documentation artifact — NO DDL. Documents state transition tables for: order lifecycle, trial lifecycle, feature activation, purchase order, blog post, B2B approval, migration job, stock transfer, B2B account, subscription.                                                                                                                                                                                                                                  |
| `06o-index-strategy.md`               | All tables  | Consolidates all CREATE INDEX DDL + prose rationale across both schemas.                                                                                                                                                                                                                                                                                                                                                                                          |
| `06p-infrastructure-notes.md`         | —           | Infrastructure documentation — NO DDL. Covers DMF-09 (SYS-18 version detection: version.json, service worker, Flutter JS interop), GCIP tenant provisioning flow, and LB log-based trial visitor count pipeline.                                                                                                                                                                                                                                                  |

* * *

Locked architectural decisions (critical — apply to every artifact)
-------------------------------------------------------------------

* **All timestamps:** `TIMESTAMPTZ` only. Never `TIMESTAMP WITHOUT TIME ZONE`.
* **All PKs:** `UUID PRIMARY KEY DEFAULT gen_random_uuid()` unless the table uses a meaningful slug PK (catalogue tables only — e.g. carriers, features).
* **Cross-schema FKs** (to `kloudshop_platform`): plain `VARCHAR` or `UUID` columns with application-layer validation. PostgreSQL does not support FK constraints across schemas in Cloud SQL.
* **Non-destructive migration policy:** Only `ADD COLUMN`, `CREATE TABLE`, `CREATE INDEX CONCURRENTLY` permitted in any migration. `DROP TABLE`, `DROP COLUMN`, `ALTER COLUMN TYPE`, non-CONCURRENT indexes are forbidden and fail CI build.
* **Every table** must have `COMMENT ON TABLE` explaining purpose and key business rules.
* **Every index** must have a `-- Rationale:` comment explaining the query pattern it serves.
* **Append-only tables** (order_events, supplier_performance_events, ai_copywriter_log, messages): explicitly document `-- No UPDATE, no DELETE ever` in business rules. No `updated_at` column on these tables.
* **Single-row config tables** (seo_settings, shipping_settings, supplier_score_weights, approval_workflows): use upsert pattern, document it, include seed INSERT in a `## Seed Data` section.
* **FTS vectors:** All `body_tsv` columns use `to_tsvector('simple', ...)` — never language-specific dictionaries. Rationale: safe for multilingual content across all 10 LTR locales (DEC-04).
* **Translation tables:** Always exclude 'en' from locale via `CHECK (locale != 'en')`. `is_auto_translated = FALSE` rows are **never** overwritten by the AI translation pipeline.
* **Feature-gated tables (06m only):** Every DDL block opens with `-- Feature-gated: activated by Migration Runner on feature activation`.

* * *

Output format for each artifact
-------------------------------

Each artifact must be a self-sufficient markdown file:
    # 06X — [Artifact Name]
    # KloudShop Stage 6 — Data Model

    > Artifact header block (file, schema, persona, reads from, depends on, tables, status)

    ## Overview
    [Key design decisions for this artifact — 8–12 bullet points]

    ## Table: `table_name`
    [Full DDL in a ```sql block with inline business rules comments]

    ## Seed Data (if applicable)
    [Seed INSERTs for single-row config tables]

    ## Updated Schema Inventory Entry
    [The exact replacement line for 06-schema-inventory.md progress table]

After generating each artifact and updating the inventory, say: **"Save `06X-name.md` and the updated `06-schema-inventory.md` to your Claude Project. Ready to proceed with `06Y` when you confirm."**

* * *

Important cross-artifact notes for upcoming work
------------------------------------------------

**06h (Blog):**

* `blog_posts.body` is JSONB (Tiptap/ProseMirror). `body_tsv` is `GENERATED ALWAYS AS (to_tsvector('simple', COALESCE(body::text, ''))) STORED`. NULL body → NULL body_tsv (handle with CASE).
* `scheduled_for` enables scheduling: Cloud Tasks job flips status to 'published' at that datetime.
* Blog post slug must redirect-rule-auto-generate when changed (same as static_pages in 06g).
* Blog post JSON-LD Article structured data is rendered by the SSR layer — no DB columns needed for it.

**06i (Messaging):**

* `messages` is **immutable** — no `updated_at`, no `deleted_at`. Business rule: "No UPDATE, no DELETE, ever."
* `body_tsv` uses `'simple'` dictionary per DEC-04.
* `thread_participants.last_read_at` drives the Redis unread badge counter reconciliation on session start.
* `message_attachments` stores MIME type as server-validated (python-magic) — column comment must note this.

**06j (Consumer):**

* `consumers.gcip_uid` is TEXT (Firebase/GCIP UIDs are opaque strings, same pattern as `b2b_accounts.firebase_uid`).
* Consumers are **per-tenant** — the same real-world shopper can have independent accounts at different merchant storefronts. No cross-tenant consumer records.
* `consumer_id` on orders (06c) is nullable — NULL = guest checkout.

**06k (Feature Config):**

* `tenant_feature_config` is in the **BASE** tenant schema — provisioned at signup before any feature is activated. It is NOT a per-feature migration. This distinction is critical and must be documented explicitly.
* `tenant_feature_state.state` drives Firebase Remote Config flag `feature_{feature_id}_enabled`.

**06l (BigQuery):**

* This is BigQuery DDL, not PostgreSQL. Use BigQuery syntax: `CREATE TABLE`, `CREATE OR REPLACE VIEW`, partitioning via `PARTITION BY DATE(event_timestamp)`, clustering via `CLUSTER BY tenant_id`.
* Row-level security: `CREATE ROW ACCESS POLICY` scoped to `tenant_id` on all tables.
* `supplier_scores` is a `CREATE MATERIALIZED VIEW` refreshed daily by Cloud Tasks.

**06m (Feature-Gated):**

* Every table DDL block must begin with the feature-gated header comment.
* `discount_codes` scope field supports: `'entire_order'`, `'collection'`, `'variant'`.
* GAP-07 event ticketing: `events` table (not to be confused with BigQuery `events`) + `event_tickets` table. Both feature-gated under a future 'event_ticketing' feature_id.
* `dynamic_pricing_rules` and `dynamic_pricing_events` are reclassified as **core platform** features (DEC-22) — they live in 06m as feature-gated DDL but are pre-activated for all tenants at signup (is_enabled = TRUE in feature_registry by default).

**06n (State Machines):**

* Pure documentation — no DDL. Use Mermaid stateDiagram-v2 syntax for each machine, followed by a prose table of transitions (from_state, event, to_state, side_effects).

**06o (Index Strategy):**

* Consolidates every `CREATE INDEX` statement already written across 06a1–06m, plus any gaps identified during review.
* Grouped by table. Include original rationale comments.

**06p (Infrastructure Notes):**

* Pure documentation — no DDL.
* Cover: (1) SYS-18 version.json structure + service worker polling strategy + Flutter JS interop + mobile fallback. (2) GCIP tenant provisioning via Firebase Admin SDK — Python code pattern. (3) Trial visitor count pipeline: Cloud Logging LB logs → Cloud Tasks job → trial_visitor_counts table → Resend daily email.
