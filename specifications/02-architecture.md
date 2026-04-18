# High-Level Architecture: KloudShop

> **Stage:** 2 — High-Level Architecture
> **Persona:** Senior Software Architect
> **Reads from:** `01-product-brief.md`, `01b-tech-stack.md`
> **Approved:** [ ] pending

---

## Architecture Philosophy

KloudShop's architecture is built on four non-negotiable principles derived directly
from the product brief and tech stack decisions:

1. **Tenant isolation without tenant complexity.** Every merchant's data, schema, and
   billing is fully isolated. No merchant ever touches another's data. But the
   operational burden of that isolation falls entirely on the platform — never on the
   merchant.

2. **Infrastructure scales, application code does not change.** Every scaling decision
   in this architecture is an infrastructure swap, not an application rewrite. FastAPI
   service code, Flutter UI code, and the data model are scale-agnostic by design.

3. **Fee neutrality is architectural, not cosmetic.** Every GCP resource is labelled
   with `tenant_id` at provisioning time. The billing pipeline is a first-class service,
   not a scheduled script. Pass-through transparency is enforced structurally.

4. **The Feature Catalogue is a runtime concern, not a deploy concern.** Features are
   toggled by merchants, schema migrations are applied on-demand via dependency chains,
   and no feature activation requires a platform deployment.

---

## System Boundary Diagram

```
╔══════════════════════════════════════════════════════════════════════╗
║                          EXTERNAL CLIENTS                            ║
║                                                                      ║
║  ┌─────────────────┐  ┌──────────────┐  ┌────────────────────────┐  ║
║  │ Merchant Admin  │  │  Buyer /     │  │  AI Shopping Agents    │  ║
║  │ Flutter Web     │  │  Consumer    │  │  (ChatGPT, Perplexity, │  ║
║  │ Flutter iOS     │  │  Storefront  │  │   Google AI, etc.)     │  ║
║  │ Flutter Android │  │  Browser     │  │                        │  ║
║  └────────┬────────┘  └──────┬───────┘  └──────────┬─────────────┘  ║
╚═══════════╪══════════════════╪═════════════════════╪════════════════╝
            │                  │                     │
            │         HTTPS    │              Structured
            │      + Firebase  │              Data API
            │       Auth JWT   │              (OpenAPI)
            ▼                  ▼                     ▼
╔══════════════════════════════════════════════════════════════════════╗
║                     GCP CLOUD LOAD BALANCER                          ║
║              (Global External Application Load Balancer)             ║
║         Anycast IP — routes to nearest healthy Cloud Run region      ║
╚══════════╤═══════════════════╤═════════════════════╤════════════════╝
           │                   │                     │
           ▼                   ▼                     ▼
╔══════════════╗  ╔════════════════════╗  ╔══════════════════════════╗
║  STOREFRONT  ║  ║   CORE API         ║  ║  ISOLATED SERVICES       ║
║  SSR SERVICE ║  ║   (Modular         ║  ║                          ║
║              ║  ║    Monolith)       ║  ║  ┌────────────────────┐  ║
║  FastAPI +   ║  ║                    ║  ║  │ Billing Service    │  ║
║  Flutter Web ║  ║  Auth Module       ║  ║  │ (FastAPI)          │  ║
║  HTML render ║  ║  Commerce Module   ║  ║  └────────────────────┘  ║
║              ║  ║  B2B Module        ║  ║  ┌────────────────────┐  ║
║  Cloud Run   ║  ║  Catalog Module    ║  ║  │ Migration Engine   │  ║
║              ║  ║  Inventory Module  ║  ║  │ (Scrapy+Playwright)│  ║
╚══════════════╝  ║  Analytics Module  ║  ║  └────────────────────┘  ║
                  ║  Feature Module    ║  ║  ┌────────────────────┐  ║
                  ║                    ║  ║  │ AI / RAG Service   │  ║
                  ║  Cloud Run         ║  ║  │ (Vertex AI+Gemini) │  ║
                  ╚════════════════════╝  ║  └────────────────────┘  ║
                                          ║  ┌────────────────────┐  ║
                                          ║  │ Migration Runner   │  ║
                                          ║  │ (Schema Service)   │  ║
                                          ║  └────────────────────┘  ║
                                          ║  ┌────────────────────┐  ║
                                          ║  │ Channel Sync Svc   │  ║
                                          ║  │ (Social+Shopping)  │  ║
                                          ║  └────────────────────┘  ║
                                          ╚══════════════════════════╝
```

---

## Service Decomposition

### Why Hybrid (Monolith Core + 4 Isolated Services)

The modular monolith is the correct default for a solo AI team — one deployment,
one CI/CD pipeline, shared in-process function calls between modules (zero network
overhead for internal calls). The four services that are isolated are isolated for
hard technical reasons, not architectural fashion:

| Service | Why Isolated | Failure Mode if Not Isolated |
|---------|-------------|------------------------------|
| **Billing Service** | Billing bugs must never take down the storefront. Financial operations need independent scaling and audit logging. | A billing reconciliation loop crashes the Core API → merchants cannot place orders during the exact moment KloudShop is calculating their bill. |
| **Migration Engine** | Scrapy + Playwright jobs are CPU/memory-intensive and long-running. They use a residential proxy pool. | A heavy scraping job saturates Cloud Run CPU → storefront SSR latency spikes for live merchants mid-migration. |
| **AI / RAG Service** | Vertex AI inference calls have variable latency (200ms–3s). pgvector similarity searches are compute-intensive. | A slow consultative AI query blocks a checkout API request on the same thread pool → cart abandonment at the exact wrong moment. |
| **Schema Migration Service** | Schema migrations must run as isolated Cloud Run Jobs — never inline during a web request. Failures must be independently observable and retryable. | A failed migration job rolls back mid-request → tenant's schema left in partial state → data corruption. |
| **Channel Sync Service** | TikTok Shop, Instagram, Facebook, and Google Shopping feed sync jobs are scheduled Cloud Run Jobs — not persistent services. They run on product change events and scheduled full-refresh cycles. Social platform API rate limits and auth token management must be isolated from core API traffic. | A stalled TikTok API call blocks checkout requests on the same thread pool → cart abandonment during a viral traffic spike — exactly when channel sync is most critical. |

---

### Core API — Internal Module Structure

```
kloudshop-core/
├── main.py                    # FastAPI app entrypoint, router registration
├── modules/
│   ├── auth/                  # Firebase Auth JWT validation, custom claims
│   ├── commerce/              # Products, orders, cart, checkout, payments
│   ├── catalog/               # SKU management, variants, collections, SEO
│   ├── inventory/             # Stock levels, reservations, variant depletion, multi-location
│   ├── b2b/                   # Company accounts, price lists, approval workflows
│   ├── storefront/            # Theme registry reads, SSR routing, SEO metadata, component renderer
│   ├── analytics/             # BigQuery query layer, dashboard data endpoints
│   ├── features/              # Feature Catalogue toggle management
│   ├── channels/              # Social commerce + Google Shopping feed sync
│   ├── pos/                   # POS integration, Stripe Terminal, in-store orders
│   ├── tax/                   # Stripe Tax integration, tax settings/registrations via embedded components
│   ├── pricing/               # Rule-based dynamic pricing engine
│   ├── blog/                  # Blog post CRUD, scheduling, SSR rendering, SEO, AI translation trigger
│   ├── messaging/             # Internal DMs, context-linked threads, inbox, attachments
│   └── copywriter/            # AI Copywriter — Brand Voice profile, Gemini prompt assembly, 3-variant generation, copywriter log
├── shared/
│   ├── db.py                  # SQLAlchemy Core engine, connection pool (PgBouncer)
│   ├── cache.py               # Redis client (Memorystore), cache decorators
│   ├── pubsub.py              # Cloud Pub/Sub publisher client
│   ├── auth_middleware.py     # JWT + tenant_id extraction middleware
│   └── tenant_context.py     # Per-request tenant isolation context
└── migrations/                # Alembic migration scripts (feature-gated)
```

**Module boundary rule:** Modules never import from each other directly. All
cross-module communication goes through Pub/Sub events or shared database queries.
This is the seam along which the monolith can be decomposed into microservices
post-PMF without rewriting business logic.

---

## Multi-Tenant Storefront Routing Architecture

### URL Convention

**Brand identity is fully merchant-controlled and independent of account credentials.**
The subdomain slug is a merchant-chosen brand slug set during onboarding — it has no
relationship to the merchant's KloudShop username, email, or account ID. A merchant
trades as "Acme Industrial Supplies" with slug `acmeindustrial` while their KloudShop
account login is `john.smith@acmecorp.com` — these are entirely separate. Hybrid tier
merchants configure two fully independent brand identities: one for their DTC storefront
and one for their B2B buyer portal — each with its own brand name, logo, colour palette,
and subdomain slug. Neither brand identity needs to match the other or the account owner.

| Tier | Store Type | URL Pattern | Example |
|------|-----------|-------------|---------|
| DTC / B2B | Single storefront | `storename.kloudshop.biz` | `acmeco.kloudshop.biz` |
| Hybrid | DTC storefront | `storename.kloudshop.biz` | `acmeco.kloudshop.biz` |
| Hybrid | B2B buyer portal | `wholesale.storename.kloudshop.biz` | `wholesale.acmeco.kloudshop.biz` |
| Any | Custom domain (DTC) | `www.merchantdomain.com` | `www.acmeco.com` |
| Any | Custom domain (B2B) | `wholesale.merchantdomain.com` | `wholesale.acmeco.com` |

### TLD Migration Path

KloudShop launches on `.biz` TLD for cost efficiency. Migration to `.com` when
commercially viable follows this zero-downtime path:

```
Phase 1 — Launch:
  acmeco.kloudshop.biz (primary)
  No .com TLD purchased yet.

Phase 2 — Dual operation:
  kloudshop.com purchased.
  acmeco.kloudshop.com added as alias.
  301 redirects: .biz → .com (SEO equity preserved).
  Both TLDs resolve — merchants see zero disruption.
  Google re-crawls and transfers search ranking to .com.

Phase 3 — Phase out .biz:
  After search ranking stabilised on .com (3–6 months),
  .biz TLD let lapse or held defensively.
  All merchant storefronts on .com primary.
```

**SEO implication:** 301 redirects from `.biz` to `.com` preserve accumulated
search equity. Merchants who launched on `.biz` do not lose their Google rankings
during migration. This must be automated — the platform generates all 301 redirect
rules, no merchant action required.

### Routing Resolution Flow

```
Request: GET wholesale.acmeco.kloudshop.biz/products/widget-pro
         │
         ▼
GCP Cloud Load Balancer
  → Wildcard SSL cert: *.kloudshop.biz
  → Wildcard SSL cert: *.*.kloudshop.biz (for wholesale.* subdomains)
         │
         ▼
Storefront SSR Service (Cloud Run)
  → Extract subdomain components:
    prefix   = "wholesale"  → B2B portal flag = TRUE
    storename = "acmeco"   → tenant lookup
         │
         ▼
Redis cache: tenant_id for "acmeco"
  → HIT: resolve tenant_id instantly
  → MISS: query Cloud SQL tenants table → cache for 1hr
         │
         ▼
Render Flutter Web storefront
  → Load B2B portal theme for tenant
  → Apply tenant's B2B pricing rules
  → Serve SSR HTML with SEO metadata
         │
         ▼
Response with:
  → Canonical URL in <head>
  → JSON-LD structured data
  → hreflang per active locale (auto-generated, MVP)
  → Cache-Control headers for Cloud CDN
```

---

## Data Flow Architecture

### 1. Order Placement Flow (Critical Path)

```
Buyer adds to cart → Checkout initiated
         │
         ▼
Core API: Commerce Module
  → Validate cart items against inventory (Redis cache first)
  → Reserve stock (PostgreSQL row-level lock, short TTL)
  → Create pending order record
         │
         ▼
Stripe Payment Intent created
  → Buyer completes payment
  → Stripe webhook → Core API /webhooks/stripe
         │
         ▼
Core API: Order confirmed
  → Decrement inventory in PostgreSQL
  → Publish "order.placed" event → Cloud Pub/Sub
         │
    ┌────┴─────────────────────────┐
    ▼                              ▼
Analytics Module              Commerce Module
→ Stream event to BigQuery    → Trigger fulfilment workflow
                              → FCM push to merchant
                              → Resend order confirmation email
```

### 2. B2B Order Flow (Approval Workflow)

```
B2B Buyer places order
         │
         ▼
Core API: B2B Module
  → Validate buyer account + credit limit
  → Apply tiered pricing rules (Redis cache: account price list)
  → Check approval workflow config for this buyer account
         │
    ┌────┴──────────────┐
    ▼                   ▼
Auto-approve        Requires approval
(within credit      (exceeds threshold
 limit, no          or new buyer)
 workflow)               │
    │                    ▼
    │          Firebase Realtime DB:
    │          approval_requests/{id}
    │                    │
    │          FCM push → merchant approver
    │          Resend email → approver
    │                    │
    │          Approver action in admin
    │                    │
    └────────────────────┘
         │
         ▼
Order confirmed → Stripe Invoice (net-30/60/90)
→ Pub/Sub: "b2b_order.placed"
→ BigQuery: B2B analytics event
```

### 3. Migration Engine Flow

```
Merchant provides competitor store URL
         │
         ▼
Migration Engine Service (Cloud Run)
  → Detect platform (Shopify / WooCommerce / Adobe Commerce / Wix / Squarespace)
  → Enqueue scrape job via Cloud Tasks
         │
         ▼
Scrapy + Playwright (Cloud Run Job — ephemeral)
  → Scrape: product titles, descriptions, prices,
    variants, images, collections, SEO metadata
  → Never scrape: customer PII, order history
  → Platform fidelity: Shopify/WooCommerce yield
    highest fidelity. Wix/Squarespace have restricted
    export structures — AI mapping preview step is
    mandatory for these platforms before bulk insert.
  → Progress → Firebase Realtime DB (merchant sees live progress bar)
         │
         ▼
AI Parse Layer (Vertex AI / Gemini)
  → Normalise scraped data to KloudShop schema
  → Map competitor category structure → KloudShop collections
  → Generate migration runbook (DNS, 301 redirects, SEO)
         │
         ▼
Core API: Catalog Module
  → Bulk insert products, variants, collections
  → Bulk insert historical orders with order_source = "imported"
     flag set — these records are excluded from financial
     reporting, Stripe billing, and revenue analytics.
     Only natively placed KloudShop orders carry
     order_source = "kloudshop" and are treated as
     live financial transactions.
  → Generate KloudShop URLs (SEO-preserving slugs)
  → Store complete in < 2 minutes
         │
         ▼
Merchant notified via FCM + Resend email:
  "Your store is ready. Here is your migration runbook."
```

### 4. Feature Activation Flow

```
Merchant toggles ON "Bidding / Auction Pricing"
         │
         ▼
Core API: Features Module
  → Query feature_dependencies graph
  → Resolve: bidding → depends on → advanced_pricing_rules
         │
         ▼
Cloud Tasks: enqueue migration jobs
  Job 1: apply advanced_pricing_rules schema (if not applied)
  Job 2: apply bidding schema (sequenced after Job 1)
         │
         ▼
Schema Migration Service (Cloud Run Job)
  → Apply Alembic migrations to tenant schema
  → Update tenant_migration_state
  → On success: mark feature ACTIVE in tenant config
  → On failure: rollback, Sentry alert, merchant notified
         │
         ▼
Feature visible in merchant's Feature Catalogue
Firebase Realtime DB: feature_status/{tenant_id}/{feature_id} = "active"
```

### 5. Analytics & Billing Data Flow

```
All Commerce Events
(orders, views, cart, B2B, AI interactions)
         │
         ▼
Cloud Pub/Sub: analytics topic
         │
         ▼
BigQuery Streaming Insert
  → kloudshop_commerce.events (partitioned by tenant_id + date)
  → Row-level security: tenant can only query own partition
         │
    ┌────┴─────────────────────────────────┐
    ▼                                      ▼
Native Flutter Dashboards             Looker Studio
(FastAPI /analytics endpoints         (Embedded iframe
 query BigQuery, serve to             in KloudShop admin
 Flutter charts)                      direct BigQuery
                                       connection)
         │
         ▼ (monthly cycle)
GCP Billing Export → BigQuery: kloudshop_billing
         │
         ▼
Billing Service (Cloud Run)
  → Query costs by tenant_id label
  → Apply fixed 15% KloudShop markup
    (merchant_bill = gcp_actual_cost × 1.15)
  → Fire Stripe metered billing event
  → Merchant receives single itemised invoice
```

---

## Infrastructure Topology

### Production Environment (`kloudshop-prod`)

```
                    ┌─────────────────────────────────┐
                    │   GCP Global Load Balancer       │
                    │   Anycast IP                     │
                    │   Wildcard SSL (*.kloudshop.biz) │
                    │   Wildcard SSL (*.*.kloudshop.biz│
                    └──────────────┬──────────────────┘
                                   │
              ┌────────────────────┼──────────────────────┐
              ▼                    ▼                       ▼
   ┌──────────────────┐ ┌─────────────────┐  ┌───────────────────────┐
   │ Storefront SSR   │ │  Core API        │  │  Isolated Services    │
   │ Cloud Run        │ │  Cloud Run       │  │                       │
   │ Min: 3 instances │ │  Min: 3 instances│  │  Billing   Cloud Run  │
   │ Max: 1,000       │ │  Max: 1,000      │  │  AI/RAG    Cloud Run  │
   │ HTML renderer    │ │  Pydantic v2     │  │  Migration Cloud Run  │
   │ Flutter Web      │ │  PgBouncer       │  │  Schema    Cloud Run  │
   └──────────────────┘ └────────┬────────┘  │            Jobs       │
                                  │           └───────────────────────┘
              ┌───────────────────┼───────────────────┐
              ▼                   ▼                   ▼
   ┌─────────────────┐ ┌──────────────────┐ ┌──────────────────┐
   │  Cloud SQL      │ │  Memorystore     │ │  Firebase        │
   │  PostgreSQL     │ │  Redis           │ │                  │
   │  Enterprise Plus│ │  Standard tier   │ │  Auth            │
   │  HA + replicas  │ │  HA + replica    │ │  FCM             │
   │  PgBouncer pool │ │                  │ │  Realtime DB     │
   │  pgvector ext.  │ │                  │ │  Remote Config   │
   │  Per-tenant     │ │                  │ │                  │
   │  schemas        │ │                  │ │                  │
   └─────────────────┘ └──────────────────┘ └──────────────────┘
              ▼                   ▼                   ▼
   ┌─────────────────┐ ┌──────────────────┐ ┌──────────────────┐
   │  Cloud Storage  │ │  Cloud CDN       │ │  Vertex AI       │
   │  Product images │ │  Storefront      │ │  Gemini          │
   │  Theme packages │ │  assets          │ │  Embeddings      │
   │  (theme.json +  │ │  Product images  │ │  Forecasting     │
   │  assets/ — zero │ │  Theme assets    │ │  pgvector        │
   │  code deploys)  │ │  (CDN cached)    │ │                  │
   │  CSV imports    │ │                  │ │                  │
   │  Merchant docs  │ │                  │ │                  │
   └─────────────────┘ └──────────────────┘ └──────────────────┘
              ▼                   ▼                   ▼
   ┌─────────────────┐ ┌──────────────────┐ ┌──────────────────┐
   │  Cloud Pub/Sub  │ │  Cloud Tasks     │ │  BigQuery        │
   │  Order events   │ │  Migration jobs  │ │  Commerce events │
   │  Inventory evts │ │  Billing cycle   │ │  Billing export  │
   │  Analytics evts │ │  Email sends     │ │  Analytics       │
   │  B2B approvals  │ │  Schema jobs     │ │  ML training     │
   └─────────────────┘ └──────────────────┘ └──────────────────┘
              ▼                   ▼                   ▼
   ┌─────────────────┐ ┌──────────────────┐ ┌──────────────────┐
   │  Stripe         │ │  Resend          │ │  Sentry          │
   │  Payments       │ │  Transactional   │ │  Error tracking  │
   │  Billing        │ │  email           │ │  All services    │
   │  Connect        │ │                  │ │                  │
   └─────────────────┘ └──────────────────┘ └──────────────────┘
   ┌─────────────────┐ ┌──────────────────┐
   │  Twilio         │ │  PostHog         │
   │  SMS / OTP      │ │  Self-hosted     │
   │                 │ │  Cloud Run       │
   └─────────────────┘ └──────────────────┘
```

---

## Multi-Tenancy Strategy

### Schema-Per-Tenant Isolation

Each KloudShop merchant gets their own PostgreSQL schema within the shared Cloud SQL
instance. This is the optimal balance between isolation and operational simplicity
at MVP scale.

| Approach | Isolation | Ops Complexity | Cost | KloudShop Choice |
|----------|-----------|---------------|------|-----------------|
| Shared tables (row-level) | Low — RLS policies required everywhere | Low | Lowest | ❌ Too risky for B2B data |
| Schema-per-tenant | High — schemas are hard boundaries | Medium | Low | ✅ Selected |
| Database-per-tenant | Highest | Very high | Highest | ❌ Post-PMF only |

**Schema naming convention:** `tenant_{tenant_id}` e.g. `tenant_acmeco`

**What lives in each tenant schema:**
- `products`, `variants`, `collections`
  — variants include shipping attributes: `weight_value`, `weight_unit`,
  `length_value`, `width_value`, `height_value`, `dimension_unit`,
  `ships_in_own_packaging`, `is_digital`. Product-level weight fields
  serve as fallback when variant-level values are absent.
- `product_translations`, `variant_translations`, `collection_translations`
  — per (entity_id, locale) rows for all translatable catalog fields.
  AI-auto-translated on English content save; merchant-reviewable.
- `storefront_content` — primary key is (slot_id, locale) to support
  per-locale storefront marketing copy. Base locale is always `en`.
- `shipping_settings` — one row per tenant: default weight/dimension units and
  fallback package weight only. Carrier definitions live in the platform schema.
- `merchant_carrier_connections` — which carriers this merchant has connected,
  with GCP Secret Manager credential references (never raw credentials).
- `carrier_checkout_options` — per service level: enabled/disabled, markup,
  destination country restrictions.
- `packaging_presets` — merchant's box/envelope size configurations.
- `orders`, `order_items`, `order_events`
- `customers`, `addresses`
- `inventory`, `stock_reservations`
- `b2b_accounts`, `price_lists`, `approval_workflows`
- `tenant_migration_state`
- `tenant_feature_config` — merchant's saved configuration values per feature (sparse key-value store, typed on read)
- `storefront_content` — all storefront marketing text and media per content slot, keyed by
  `{component_instance_id}.{slot_key}` (e.g. `hero_main.heading`). Content is tenant-owned,
  never stored in theme.json. Carries forward automatically on theme switch; unmatched
  slots from new themes are flagged empty in the WYSIWYG for merchant to fill.
- Feature-specific tables (loyalty, bidding, subscriptions, etc.)
- `blog_posts` — one row per post per tenant: title, slug, body (rich text HTML),
  featured_image_url, status (draft/scheduled/published/archived), published_at,
  scheduled_for, author_id (staff_user_id), meta_title, meta_description,
  categories[], tags[]. Included in XML sitemap and Google Shopping feed exclusion.
- `blog_post_translations` — per (post_id, locale) rows for title, slug, body,
  meta_title, meta_description. AI-auto-translated on English save; merchant-reviewable.
  Same is_auto_translated flag and review pattern as product_translations.
- `brand_profiles` — one record per storefront (DTC & B2B are separate rows), includes `enabled_locales TEXT[]` — only listed locales generate hreflang tags and locale-prefixed URLs on this storefront:
  each profile stores brand name, slug, logo URL, colour palette, favicon,
  storefront type, active `theme_id` reference, and `draft_theme_config_url`
  (Cloud Storage path to the merchant's in-progress WYSIWYG edits — distinct
  from the live active theme). Saving in the WYSIWYG writes to `draft_theme_config_url`.
  Applying a theme to the storefront promotes the draft to `active_theme_config_url`
  and clears the draft. Hybrid merchants have two rows; DTC/B2B merchants have one.
  Brand name and slug are completely independent of the account owner's identity.
  Theme selection is per-brand-profile — a Hybrid merchant can run different themes
  on their DTC and B2B storefronts simultaneously. Theme edits are always tenant-scoped:
  the original theme in the global catalogue is never modified.

**What lives in the platform schema (`kloudshop_platform`):**
- `tenants` (store slug, tier, custom domain, status, primary_region, secondary_region)
- `staff_users` (gmail address, display name, linked tenant_ids)
- `staff_role_assignments` (staff_user_id, tenant_id, roles[], is_owner, invited_at, accepted_at)
- `feature_registry`, `feature_dependencies`, `feature_migrations`
- `carriers`, `carrier_service_levels` — platform-maintained carrier catalogue,
  shared across all tenants. Never duplicated into tenant schemas.
- `feature_config_schema` — typed parameter definitions per feature (key, data_type, validation_rules, defaults)
- `billing_cycles`, `billing_line_items`
- `migration_jobs` (competitor import tracker)
- `themes` (theme_id, display_name, sector_tags, config_url, asset_base_url,
  schema_version, status) — global theme catalogue, not per-tenant

---

## Security Architecture

| Concern | Implementation |
|---------|---------------|
| **Authentication** | Firebase Auth JWT validated on every request in `auth_middleware.py`. Custom claims carry `tenant_id`, `account_type`, `roles[]`, `is_owner`. Gmail-only for all merchant staff accounts. |
| **App Check (outermost gate)** | Firebase App Check enforced on all API endpoints before JWT validation. Verifies every request originates from a legitimate KloudShop app instance — Play Integrity API (Android), App Attest (iOS), reCAPTCHA Enterprise (Web). Requests without a valid App Check token are rejected before auth, routing, or any business logic executes. Bounces bots, reverse-engineered API clients, and direct endpoint callers. |
| **Control plane → regional trust chain** | Firebase Auth issues a signed JWT to the Flutter client. FastAPI validates it cryptographically via Firebase Admin SDK — no network round-trip to the control plane on each request. FastAPI extracts `tenant_id` + `roles[]`, scopes all DB operations accordingly, then interacts with Cloud SQL and Cloud Storage using its own Workload Identity service account. The user JWT never directly touches Cloud SQL or Cloud Storage — FastAPI is the sole trusted intermediary. Regional GCP services trust the FastAPI service account, not end-user tokens. |
| **RBAC enforcement** | Role-permission matrix evaluated in `auth_middleware.py` before every route handler. Roles extracted from JWT `roles[]` claim — never from the database on the hot path. Supported roles: Owner, Admin, Store Manager, Fulfilment Staff, Inventory Manager, Marketing Manager, Customer Support, Analyst/Finance, B2B Account Manager, B2B Sales Rep, Catalogue Manager, POS Operator, Developer/Integrator. Users may hold multiple roles simultaneously. |
| **Tenant isolation** | Every FastAPI request extracts `tenant_id` from JWT. All database queries are scoped to `tenant_{tenant_id}` schema via `tenant_context.py`. Cross-tenant queries are architecturally impossible. |
| **B2B buyer isolation** | B2B buyer portal users have `account_type: buyer` claim. They can only query their own company's price lists, orders, and catalogs — never other buyers within the same merchant. |
| **PCI-DSS** | No card data touches KloudShop infrastructure. Stripe handles all card data. KloudShop stores only Stripe payment intent IDs and last-4 digits. |
| **Secrets** | All credentials in GCP Secret Manager. Cloud Run accesses via Workload Identity Federation. Zero credentials in source code or environment variables. |
| **API rate limiting** | Redis sliding window counter per `tenant_id`. 1,000 req/min default. Configurable per tier. Storefront SSR exempted (cached at CDN layer). |
| **Storefront bot protection** | Cloud Armor WAF on Global Load Balancer. Rate limiting at edge. CAPTCHA on checkout for anomalous traffic patterns. |
| **GDPR** | Customer PII stored only in tenant schemas. Right-to-erasure implemented as anonymisation (order history preserved, PII nulled). PostHog self-hosted — no behavioural data leaves GCP. |
| **Messaging file security** | Attachments stored in tenant-scoped Cloud Storage paths. Served via signed URLs with 15-minute TTL — never publicly accessible. MIME type validated server-side via python-magic (file bytes inspected, not client-declared type). PDFs with embedded JavaScript rejected at Cloud Run scanner layer. |
| **Message immutability** | Messages are never deleted by any user — including Owner. All messages permanently archived in Cloud SQL. Firebase Realtime Database is the delivery layer only; Cloud SQL is the authoritative record. This preserves the legal audit trail for B2B price agreements and order instructions. |

---

## Scalability Checkpoints

| Checkpoint | Metric | Action |
|-----------|--------|--------|
| 500 merchants | Cloud SQL CPU >60% sustained | Add read replicas, enable PgBouncer connection pooling |
| 500 merchants | Redis cache miss rate >15% | Upgrade Memorystore to Standard tier HA |
| 1,000 merchants | Cloud SQL CPU >80% sustained | Migrate to AlloyDB (zero code changes — wire-compatible) |
| 5,000 merchants | Per-service req/sec >10K sustained | Migrate from Cloud Run to GKE Autopilot |
| 50,000 merchants | Global multi-region traffic | Add Cloud Spanner for global catalog + session state |
| Any BFCM event | Traffic spike predicted | Cloud Run scales to 10,000 instances automatically — no action needed |

---

### 6. Social Commerce + POS Order Flow

```
Order placed on TikTok Shop / Instagram / Facebook / POS Terminal
         │
         ▼
Channel Sync Service OR Stripe Terminal webhook
  → FastAPI: Commerce Module
  → order_source tagged: "tiktok_shop" / "instagram_shop"
    / "facebook_shop" / "pos"
  → Inventory reservation: Cloud SQL row-level lock
    (same pool as online — cross-channel oversell impossible)
  → Stock decremented from correct location
    (multi-location: POS from store location,
     social orders from configured fulfilment location)
         │
         ▼
Pub/Sub: "order.placed" event (all channels unified)
  → Fulfilment workflow triggered
  → FCM: merchant notified
  → BigQuery: channel-attributed analytics event
  → Tax: Stripe Tax calculates applicable tax automatically
    (jurisdiction based on buyer shipping address, via merchant's
     connected Stripe account — no separate API call)
```

---

## Risk Register


| Risk | Severity | Mitigation |
|------|----------|-----------|
| Flutter Web CWV scores fail benchmark | High | Phase 0 spike. Fallback: FastAPI + Jinja2 SSR for storefronts. Flutter Web retained for admin. |
| Wildcard SSL for `*.*.kloudshop.biz` (two-level wildcard) | High | Standard SSL certs do not cover two-level wildcards. Use GCP-managed cert with explicit SANs for `wholesale.*` pattern, or Cloudflare proxying for wildcard depth. Validate in Phase 0. |
| Migration scraper blocked at scale | High | Sprint 1 technical spike. Residential proxy pool (Bright Data). Playwright fallback. Crawl-rate throttling. |
| `.biz` → `.com` SEO equity loss | Medium | 301 redirects generated automatically by platform. Google Search Console recrawl triggered via API. Dual-TLD operation for minimum 3 months. |
| Schema migration failure mid-activation | Medium | Cloud Tasks retry with exponential backoff. Alembic idempotency guarantees safe retry. Sentry alert on first failure. Merchant sees pending state, not error. |
| Tenant schema isolation breach via SQL injection | High | Parameterised queries enforced via SQLAlchemy Core. `tenant_id` injected server-side from JWT — never from client input. Penetration test before beta launch. |
