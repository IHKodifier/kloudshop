# Tech Stack Assessment: KloudShop

> **Stage:** ★ Tech Stack Interlude
> **Persona:** Senior Staff Engineer
> **Reads from:** `01-product-brief.md`
> **Approved:** [ ] pending

---

## Overview

KloudShop is a multi-tenant e-commerce operating system serving mid-market to enterprise
merchants across B2C, B2B, and Hybrid operational modes. The stack must support a solo
founder + AI engineering team, GCP-native pass-through billing, PCI-DSS and GDPR
compliance, a RAG-powered AI consultative layer, a competitor migration engine, and
Flutter-delivered storefronts with first-class SEO. Every recommendation below is
evaluated against these constraints. No layer is chosen for fashion — each has a
specific justification tied to the product's requirements.

---

## Stack Summary Table

| Layer | Decision | Rationale |
|-------|----------|-----------|
| **Frontend / Admin** | Flutter Web | GCP-native, single codebase for web + iOS + Android, confirmed choice |
| **Mobile** | Flutter iOS + Android | Feature-parity with web admin, single Dart codebase |
| **Storefront delivery** | Flutter Web + FastAPI SSR | SSR via FastAPI for Core Web Vitals + SEO + machine-readability |
| **Backend API** | Python FastAPI | Async-native, strongly typed with Pydantic, excellent AI/ML ecosystem fit |
| **Primary database** | PostgreSQL on GCP Cloud SQL | Relational integrity for orders/inventory/B2B hierarchies; managed, GCP-native |
| **Auth** | Firebase Auth | GCP-native, supports email/password, Google SSO, MFA; handles B2B buyer portal auth |
| **File / media storage** | GCP Cloud Storage | GCP-native, direct pass-through billing, S3-compatible API |
| **CDN / asset delivery** | GCP Cloud CDN | GCP-native, integrated with Cloud Storage and Cloud Run; low-latency global delivery |
| **Caching layer** | GCP Memorystore for Redis | ✅ Recommended — see section below |
| **Payment gateway** | Stripe | ✅ Recommended — see section below |
| **Subscription management** | Stripe Billing | ✅ Recommended — see section below |
| **AI / ML** | Vertex AI + Gemini | GCP-native, RAG pipeline, embeddings, Gemini for consultative AI layer |
| **Push notifications** | Firebase Cloud Messaging (FCM) | ✅ Recommended — see missing layers below |
| **Transactional email** | Resend | ✅ Recommended — see missing layers below |
| **Background jobs / queues** | GCP Cloud Tasks + Cloud Pub/Sub | ✅ Recommended — see missing layers below |
| **Search** | PostgreSQL FTS + pgvector + Vertex AI Embeddings | ✅ Recommended — see missing layers below |
| **Real-time updates** | Cloud Firestore | ✅ Recommended — preferred over Firebase Realtime Database (newer, richer querying, better consistency) |
| **Error tracking** | Sentry | ✅ Recommended — see missing layers below |
| **Logging & observability** | GCP Cloud Logging + Cloud Monitoring | ✅ Recommended — GCP-native, zero additional vendor |
| **CI/CD** | GitHub Actions + GCP Cloud Build | ✅ Recommended — see missing layers below |
| **Secrets management** | GCP Secret Manager | ✅ Recommended — GCP-native, zero additional vendor |
| **Feature flags** | Firebase Remote Config | ✅ Recommended — GCP-native, already using Firebase |
| **Web scraping (migration engine)** | Scrapy + Playwright on Cloud Run | ✅ Recommended — see missing layers below |
| **SMS / OTP** | Twilio | ✅ Recommended — see missing layers below |
| **Testing** | Pytest (backend) + Flutter test + Playwright E2E | ✅ Recommended — see missing layers below |
| **Tax compliance** | Stripe Tax (via merchant's Stripe connected account) | ✅ Updated — see section below |
| **POS integration** | Stripe Terminal + hardware-agnostic POS API layer | ✅ Added — see section below |
| **Social commerce** | TikTok Shop API, Instagram Graph API, Facebook Commerce API | ✅ Added — see section below |
| **Google Shopping** | Google Merchant Center API (native feed generation) | ✅ Added — see section below |
| **AI recommendations** | BigQuery ML (matrix factorisation) + Vertex AI Embeddings | ✅ Added — powered by existing stack |
| **Theme registry** | Cloud Storage (theme packages) + Cloud SQL (theme registry) + Redis (config cache) | ✅ Added — see section below |
| **Internal messaging** | Cloud Firestore (real-time delivery) + Cloud SQL (persistent archive) + Cloud Storage (file attachments) + PostgreSQL FTS (message search) | ✅ Added — see section below |
| **Native blog (CMS)** | Cloud SQL (blog_posts + blog_post_translations tables) + PostgreSQL FTS (tsvector on post body) + Cloud Storage (featured images) + Google Cloud Translation API (AI auto-translation) + FastAPI SSR (blog page rendering, JSON-LD Article structured data, hreflang, sitemap) | ✅ No new vendor — entirely powered by existing stack |
| **AI Copywriter** | Vertex AI Gemini (existing) — single structured output call per generation producing 3 variants; Brand Voice profile assembled server-side in FastAPI `copywriter/` module; GCP pass-through billable at actual cost × 1.15 | ✅ No new vendor — powered entirely by existing Vertex AI + Gemini integration |

---

## Validated Choices

### Flutter Web (Admin + Storefronts)
**Assessment: Validated with one critical caveat.**
Flutter Web is the right call for a solo AI-assisted team — a single Dart codebase
delivering web admin, iOS, and Android is a massive productivity advantage. The caveat:
Flutter Web's Core Web Vitals performance for *public storefronts* is a known risk. The
CanvasKit renderer (default) produces excellent visual fidelity but poor CWV scores. The
HTML renderer produces better CWV but has rendering limitations. **Recommendation:** Use
HTML renderer for storefronts, CanvasKit for merchant admin. CWV benchmark sprint in
Phase 0 is non-negotiable before committing Flutter Web for merchant-facing storefronts.
If benchmark fails, the fallback is FastAPI-rendered Jinja2 templates for storefronts
with Flutter Web retained for admin only.

### Python FastAPI (Backend API)
**Assessment: Strong choice — optimal for this product.**
FastAPI is async-native, auto-generates OpenAPI docs (critical for AI-agent
maintainability), enforces strong typing via Pydantic, and has the deepest Python
ecosystem for AI/ML integration. The Vertex AI + Gemini SDKs are Python-first.
For a solo founder + AI engineering team, self-documenting API contracts are essential.
No concerns. Use Pydantic v2 throughout.

### PostgreSQL on GCP Cloud SQL
**Assessment: Correct and future-proof.**
The B2B data model (parent-child account hierarchies, custom price lists, approval
workflows, credit limits, order history) demands relational integrity — NoSQL would
create serious consistency problems here. Cloud SQL Postgres also supports pgvector
(semantic search) and full-text search natively, eliminating a separate search vendor
for most use cases. Use Cloud SQL Enterprise edition for HA with read replicas.
Enable automated backups and point-in-time recovery from day one.

### Firebase Auth
**Assessment: Validated — extended with RBAC custom claims schema.**
Firebase Auth handles Google SSO (Gmail-only for merchant staff), MFA, and custom
tokens. All merchant staff accounts are strictly Gmail accounts — no username/password
auth for internal users. Google handles credential security and account recovery.

**Control plane residence:** All staff user identities, role assignments, and
permissions live in the KloudShop platform control plane (Firebase Auth + platform
Cloud SQL `kloudshop_platform` schema) — never inside a tenant's regional GCP
infrastructure. This decouples authentication availability from tenant regional
health. Staff can always log in even if their tenant's Cloud SQL instance is under
stress or in failover.

**Firebase custom claims schema for staff users:**
```json
{
  "tenant_id": "tenant_acmeco",
  "account_type": "staff",
  "roles": ["store_manager", "inventory_manager"],
  "is_owner": false
}
```

**Firebase custom claims schema for B2B buyer portal users:**
```json
{
  "tenant_id": "tenant_acmeco",
  "account_type": "buyer",
  "buyer_account_id": "buyer_corp_xyz",
  "roles": ["buyer"]
}
```

**Three distinct user populations — never conflated:**

| Population | Auth Method | Claims | Resides In |
|-----------|------------|--------|-----------|
| Merchant staff (Owner, Admin, all roles) | Gmail / Google SSO only | tenant_id, account_type: staff, roles[], is_owner | Platform control plane |
| B2B buyer portal users | Gmail or email/password | tenant_id, account_type: buyer, buyer_account_id | Platform control plane |
| End consumers (DTC storefront) | Guest or email/password or Google | Custom claims added when consumer registers: `tenant_id`, `account_type: consumer`. Guest sessions carry no claims. Registered consumers are stored in a per-tenant `consumers` table — enabling loyalty programmes, gift vouchers, and repeat-checkout features from the Feature Catalogue. Soft post-checkout signup is a planned Feature Catalogue item. | Platform control plane |

**RBAC enforcement:** Every FastAPI request extracts `roles[]` from the JWT custom
claims. A role-permission matrix is enforced in `auth_middleware.py` — API routes
declare their required permission, the middleware checks the caller's roles against
the matrix before the route handler executes. Role checks are never performed inside
business logic.

**Control plane → regional GCP trust chain:**
A staff user authenticates against Firebase Auth (control plane) and receives a signed
JWT. That JWT is presented to FastAPI running on Cloud Run in the tenant's regional GCP
(e.g. us-east). FastAPI validates the JWT **locally and cryptographically** using the
Firebase Admin SDK — it verifies the signature against Firebase's published public keys.
This requires **zero network round-trip to the control plane** on every request. Once
validated, FastAPI extracts `tenant_id` and `roles[]` from the claims, scopes all
database operations to the correct tenant schema, and interacts with Cloud SQL and
Cloud Storage using its own **GCP Workload Identity** service account. The user's JWT
never directly touches Cloud SQL or Cloud Storage — FastAPI is the sole trusted
intermediary. Regional GCP services grant trust to the FastAPI Cloud Run service
account, not to end-user tokens directly.

```
Firebase Auth (control plane, any region)
  → issues signed JWT to Flutter client
         │
         ▼ JWT travels with every API request
FastAPI on Cloud Run (tenant's regional GCP)
  → validates JWT via Firebase Admin SDK
    (cryptographic, no control plane call)
  → extracts tenant_id + roles[] from claims
  → scopes all queries to tenant_{tenant_id}
         │
         ▼ service-to-service via Workload Identity
Cloud SQL + Cloud Storage (tenant's regional GCP)
  → trust FastAPI service account only
  → user JWT never presented here directly
```

**Firebase App Check:**
KloudShop enforces Firebase App Check on all Firebase service calls and FastAPI
endpoints. App Check cryptographically verifies that API requests originate from
a legitimate, unmodified KloudShop app instance — not from a bot, a reverse-engineered
client, or a direct API call bypassing the app.

| Platform | App Check Provider | What It Verifies |
|----------|--------------------|-----------------|
| Flutter Android | Play Integrity API | App is unmodified, from Google Play, running on a genuine Android device |
| Flutter iOS | App Attest (Apple) | App is unmodified, signed by KloudShop, running on a genuine Apple device |
| Flutter Web | reCAPTCHA Enterprise | Request originates from a real browser session, not an automated script |

App Check tokens are short-lived and automatically refreshed by the Firebase SDK.
FastAPI validates App Check tokens on every request via the Firebase Admin SDK before
any JWT validation occurs. Requests without a valid App Check token are rejected at
the outermost layer — before auth, before routing, before any business logic.

### Vertex AI + Gemini
**Assessment: Correct choice given GCP-native constraint and pass-through billing.**
Vertex AI is the right inference and embedding platform here — it integrates natively
with Cloud SQL (for grounding), Cloud Storage (for document ingestion), and supports
the RAG pipeline required for the consultative AI layer. Gemini models are competitive
with GPT-4 class for structured commerce queries. Vertex AI inference costs are GCP
resources and therefore billable as pass-through to merchants — perfect alignment with
the business model.

### GCP Cloud Storage + Cloud CDN
**Assessment: Validated — correct GCP-native choices.**
Cloud Storage for product images, merchant assets, and CSV imports. Cloud CDN for
storefront static asset delivery. Both are pass-through billable. Ensure Cloud CDN
is configured with cache policies for product images and theme assets — these are
the highest-volume, most cacheable resources on the platform.

---

## Recommended: Caching Layer

### ✅ GCP Memorystore for Redis

**Why Redis, not Memcached:** KloudShop needs more than simple key-value caching.
Redis supports sorted sets (for leaderboard-style feature request voting), pub/sub
(for real-time cart updates), TTL-based session management, and distributed rate
limiting — all required by this platform. Memcached supports none of these.

**Why Memorystore, not self-hosted Redis:** Memorystore is GCP-managed Redis.
Zero ops overhead for a solo founder team. It is a GCP resource and therefore
pass-through billable to merchants. It integrates natively with Cloud Run and
VPC networking. Automatic failover with read replicas available.

**What KloudShop uses Redis for:**
| Use Case | Redis Pattern | TTL |
|----------|--------------|-----|
| Product catalog cache (storefront reads) | Key-value, product ID → JSON | 15 minutes |
| Session / cart data | Hash, session token → cart state | 24 hours |
| API rate limiting (per tenant) | Sliding window counter | 60 seconds |
| B2B price list cache (per buyer account) | Hash, account ID → price rules | 30 minutes |
| Migration engine job state | Key-value, job ID → progress | 2 hours |
| Feature flag cache | Key-value, tenant ID → flags | 5 minutes |
| Search autocomplete suggestions | Sorted set, prefix → product titles | 1 hour |

**Configuration:** Start with Memorystore Basic tier (single node) for MVP.
Upgrade to Standard tier (HA with replica) at 500+ active merchants.

---

## Recommended: Payment Gateway

### ✅ Stripe Connect (Platform Account — KloudShop UK Ltd)

KloudShop operates a single Stripe platform account registered to a UK Private
Limited Company with a non-resident Pakistani director. This single account
handles both payment flows:

**Flow 1 — Consumer-to-merchant (Direct Charges):**
Consumer purchases on a KloudShop merchant storefront are processed as Stripe
Connect Direct Charges on the merchant's connected Stripe account. Funds go
directly to the merchant. KloudShop platform account never holds consumer funds.
KloudShop takes zero application fee on these transactions.

**Flow 2 — Merchant-to-KloudShop (Subscription + GCP billing):**
Stripe Billing handles merchant subscriptions and metered GCP pass-through charges
via the KloudShop platform account. Merchants are connected accounts.

**Connected account onboarding:**
Merchants connect their existing Stripe account (or create one) via Stripe Connect
OAuth during KloudShop onboarding. One-time setup. Merchants in Stripe-unsupported
countries cannot onboard — accepted scope limitation for launch.

**Development → Production key rotation:**
- Development: `sk_test_...` keys throughout — full Stripe functionality
- Production: rotate to `sk_live_...` keys — zero code changes required
- Stripe Connect test mode supports full connected account simulation

**Stripe-supported consumer payment methods (all Stripe-native):**
Visa/Mastercard/Amex, Apple Pay, Google Pay, Klarna, Afterpay/Clearpay,
iDEAL (NL), SEPA (EU), BACS (UK), BECS (AU), GrabPay (SEA), Alipay (China).
B2B only: bank transfer with net terms via Stripe Invoicing.

**Not at storefront checkout:**
Payoneer (founder payout tool only), Facebook Pay (covered by SC channel
integrations), PayPal (deferred post-PMF), MBWay (deferred post-MVP).

**Founder payout route:**
UK Ltd Stripe → Payoneer → HBL USD (primary) / HBL PKR (fallback).
GCP platform costs paid directly from Payoneer in USD.

---

### ✅ Stripe Billing (Subscription + GCP Metered Pass-Through)

Stripe Billing handles all KloudShop merchant billing natively:
- Plan management: DTC ($24.99) / B2B ($39.99) / Hybrid ($49.99) tiers
- 30-day free trial (no credit card required). Merchant chooses exactly one of DTC
  or B2B at signup; Hybrid is paid-only. Three independent hard-stop triggers:
  (a) $5 GCP credit exhausted — resources hard-stopped immediately
  (b) $600 cumulative GMV reached — selling paused, data intact
  (c) 30 days elapsed — resources hard-stopped; published closing datetime shown
      (trigger + 168 hrs rounded to next 00:00 GMT); silent 48-hr grace period
      follows = 216 hrs total before permanent data deletion. Account
      soft-deleted, never hard-deleted.
- Proration on mid-cycle tier upgrades (e.g. DTC → Hybrid)
- Dunning: failed payment retries and cancellation flows
- Metered billing: GCP pass-through charges as Stripe usage records

**GCP pass-through billing architecture:**
At end of each billing cycle, the FastAPI Billing Service (Cloud Tasks triggered)
queries each tenant's GCP resource consumption via the GCP Billing API, applies
the fixed 15% KloudShop markup (merchant_bill = gcp_actual_cost × 1.15), and records a Stripe metered usage event per resource
type. Single monthly invoice: flat subscription + itemised GCP usage line items.

**B2B payment methods (critical for the B2B tier):**
Stripe supports ACH bank transfers, SEPA Direct Debit, BACS (UK), BECS (AU), and
Stripe Invoicing with net payment terms — covering the B2B net-30/60/90 use case
natively. No third-party B2B payment app required.

**Local payment method API availability:**
All listed local payment methods are programmatically integratable via published APIs:

| Method | Integration Path | API Available? |
|--------|-----------------|---------------|
| iDEAL (Netherlands) | Stripe Payment Methods API | ✅ Stripe native |
| GrabPay (SEA) | Stripe Payment Methods API | ✅ Stripe native |
| Alipay (China) | Stripe Payment Methods API | ✅ Stripe native |
| Klarna (BNPL) | Stripe Payment Methods API | ✅ Stripe native |
| Afterpay/Clearpay | Stripe Payment Methods API | ✅ Stripe native |
| SEPA Direct Debit | Stripe Payment Methods API | ✅ Stripe native |
| BACS (UK) | Stripe Payment Methods API | ✅ Stripe native |
| BECS (AU) | Stripe Payment Methods API | ✅ Stripe native |
| MBWay (Portugal) | SIBS API (direct — not Stripe) | ✅ Direct API |

KloudShop's FastAPI payment abstraction layer is gateway-agnostic by design —
Stripe handles the majority of local methods through a single integration.
MBWay requires a separate direct SIBS API integration, handled through the
same payment abstraction layer without exposing complexity to merchants.

**Stripe Connect (for future marketplace features):**
If KloudShop ever moves toward a multi-vendor marketplace model, Stripe Connect
handles payout splitting natively. Adopting Stripe now means zero migration cost later.

**Regional considerations for future expansion:**
When expanding beyond US/UK/AU/CA, supplement Stripe with regional gateways where
Stripe has limited penetration: Razorpay (India), HyperPay (MENA), Flutterwave
(Africa). Stripe's architecture supports multi-gateway routing — design the payment
abstraction layer in FastAPI to be gateway-agnostic from day one.

---

## Recommended: Subscription Management



---

## Missing Layers — Full Audit & Recommendations

### 1. Push Notifications
**Recommendation: Firebase Cloud Messaging (FCM)**
Already in the Firebase/GCP ecosystem. FCM handles iOS APNs, Android push, and web
push from a single API. Zero additional vendor. Use FCM for: order status updates,
B2B approval workflow notifications, inventory alerts, and migration engine job
completion. Flutter has first-class FCM integration via `firebase_messaging` package.

### 2. Transactional Email
**Recommendation: Resend**
GCP has no native transactional email service. Resend is the modern standard —
React Email templates, excellent deliverability, simple REST API, generous free tier,
and a developer-first SDK. Use for: order confirmations, B2B account invitations,
net-terms invoices, migration runbook delivery, and trial expiry warnings.
Alternative: SendGrid (larger, more enterprise, slightly more complex).

### 3. Background Jobs & Queues
**Recommendation: GCP Cloud Tasks (scheduled/delayed jobs) + GCP Cloud Pub/Sub (event streaming)**
Two distinct tools for two distinct patterns:
- **Cloud Tasks:** Delay-tolerant, retryable discrete jobs — migration engine scraping
  tasks, CSV import jobs, GCP billing reconciliation, email sends, sitemap regeneration.
  HTTP-based, integrates directly with Cloud Run. Pass-through billable.
- **Cloud Pub/Sub:** High-throughput event streaming — order placed events, inventory
  update events, B2B approval state changes, AI layer inference request queuing.
  Decouples services and enables future microservice decomposition without re-plumbing.

### 4. Product Search
**Recommendation: PostgreSQL Full-Text Search + pgvector + Vertex AI Embeddings**
Do not introduce a separate search vendor (Algolia, Typesense) at MVP. PostgreSQL on
Cloud SQL supports:
- **Full-text search (FTS):** tsvector/tsquery for keyword product search — sufficient
  for most merchant catalogs up to ~500K SKUs. The same FTS pattern extends to blog
  post bodies (tsvector on `blog_posts.body`) — no separate search stack needed for
  content search.
- **pgvector extension:** Vector similarity search for semantic/AI-powered product
  discovery ("show me waterproof boots under $150 for wide feet") grounded in
  Vertex AI embeddings generated at product-ingest time.

This eliminates a third-party search bill, keeps all data in Cloud SQL, and enables
the RAG consultative AI layer to query product embeddings directly.
Revisit Typesense or Algolia if FTS performance degrades beyond 1M+ SKUs across all
tenants — that is a post-PMF problem.

### 5. Real-Time Updates
**Recommendation: Cloud Firestore (scoped use) — preferred over Firebase Realtime Database**
Cloud Firestore is Google's newer, production-grade NoSQL offering and supersedes Firebase Realtime Database for all new projects. Firestore provides structured documents with subcollections (vs. Realtime DB's flat JSON tree), richer querying, stronger offline support, and better multi-region consistency guarantees. It integrates with the same Firebase/GCP ecosystem and is equally GCP-native. Firebase Realtime Database had lower latency in early benchmarks, but Firestore's latency is now comparable for the narrow signalling use cases KloudShop needs.

Use Cloud Firestore for: live order status on the merchant dashboard, B2B approval workflow state, and migration engine progress bars. Do not use it as a general-purpose database — all persistent data lives in Cloud SQL. Cloud Firestore is a thin real-time signalling and delivery layer only.

> **Note on existing references:** All prior artifact references to "Firebase Realtime Database" in the signalling/delivery role should be read as Cloud Firestore going forward. The data model and integration pattern are identical — only the underlying product changes.

### 6. Error Tracking
**Recommendation: Sentry**
Industry standard for both Python (FastAPI) and Flutter. Captures exceptions,
stack traces, breadcrumbs, and user context. Critical for a solo founder team —
you need to know what broke before a merchant reports it. Use the Sentry GCP
integration to correlate errors with Cloud Logging traces. Free tier sufficient
for MVP; scale to Team plan at 500+ merchants.

### 7. Logging & Observability
**Recommendation: GCP Cloud Logging + Cloud Monitoring (native)**
Zero additional vendor — both are GCP-native and pass-through billable.
Cloud Logging for structured JSON logs from FastAPI and Cloud Run services.
Cloud Monitoring for uptime checks, latency dashboards, and alerting.
Configure log-based metrics for: API error rate by tenant, migration engine
success/failure rate, Vertex AI inference latency, and payment webhook failures.

### 8. CI/CD Pipeline
**Recommendation: GitHub Actions + GCP Cloud Build**
GitHub Actions for pull request checks (lint, type check, unit tests).
GCP Cloud Build for container builds, integration tests, and deployment to
Cloud Run. GCP Cloud Deploy for staged rollouts (dev → staging → production).
This pipeline is fully manageable by an AI engineering team with no DevOps hire.

### 9. Secrets Management
**Recommendation: GCP Secret Manager**
GCP-native, pass-through billable. Store all API keys, database credentials,
Stripe keys, and Firebase service account credentials in Secret Manager.
Access from Cloud Run via Workload Identity — no credentials in environment
variables or source code. Mandatory for PCI-DSS compliance.

### 10. Feature Flags
**Recommendation: Firebase Remote Config**
Already in the Firebase/GCP ecosystem. Zero additional vendor. Use for:
gradual rollout of Feature Catalogue items, A/B testing of storefront UI,
tenant-level feature gating (e.g., enabling beta features for specific merchants),
and emergency kill switches for unstable features. Flutter has native Firebase
Remote Config SDK support.

### 10b. Internationalisation (i18n) Stack

**Flutter admin UI:** `flutter_localizations` + `intl` package. All UI strings
in per-locale ARB files (`app_en.arb`, `app_de.arb`, etc.). The `intl` package
handles locale-aware number, date, and currency formatting. Zero hardcoded
strings in Flutter code — enforced by the `flutter_gen` ARB code generator
which fails the build if a string is used without a localisation key.

**Supported locales at launch (LTR):** en, de, fr, sv, no, da, nl, es, pt, it.
RTL locales deferred — require Flutter's `Directionality` widget and bidirectional
text layout throughout the UI, which is a substantial MVP scope addition.

**AI auto-translation:** Google Cloud Translation API (GCP-native).
- Triggered by Cloud Tasks when merchant saves English product/collection/storefront content
- Translates to all merchant-enabled locales in a single batch API call
- Cost is GCP pass-through billable (per character translated)
- Translations stored with `is_auto_translated = TRUE` flag
- Merchant reviews and overrides from Language Settings panel
- On merchant override, `is_auto_translated` set to FALSE

**Storefront locale routing:** FastAPI SSR Service extracts locale prefix from URL path.
Locale-specific content fetched from translation tables. Fallback to `en` if
translation absent. hreflang tags auto-generated for all active locales per page.

**Locale-aware URL slugs:** Each locale can have its own slug for SEO.
`product_translations.slug` stores the locale-specific slug. A 301 redirect
from the English slug to the locale slug is generated automatically for each locale.

### 11. Web Scraping (Migration Engine)
**Recommendation: Scrapy + Playwright — containerised on Cloud Run**
- **Scrapy:** Fast, production-grade Python scraping framework. Handles Shopify
  and WooCommerce static product pages efficiently.
- **Playwright:** Headless browser automation for JavaScript-rendered pages
  (Adobe Commerce, heavily JS-dependent Shopify themes). Handles dynamic content
  Scrapy cannot reach.
- **Cloud Run:** Scraping jobs run as isolated, ephemeral Cloud Run jobs — not
  persistent services. Scales to zero between jobs. Pass-through billable.
- **Bot protection mitigation:** Rotate user agents, respect crawl delays, use
  residential proxy pool (Bright Data or Oxylabs) for scale. This is the highest
  technical risk item in the product — validate in Sprint 1.

### 12. SMS / OTP
**Recommendation: Twilio**
For B2B buyer portal OTP verification, merchant phone verification at signup,
and order SMS alerts. Twilio is the global standard — 180+ countries, reliable
delivery, straightforward Python SDK. Firebase Phone Auth can handle OTP for
auth flows specifically; use Twilio for non-auth SMS (order updates, B2B alerts).

### 13. Testing Infrastructure
**Recommendation: Pytest + Flutter Test + Playwright E2E**
- **Pytest:** FastAPI unit and integration tests. Use `pytest-asyncio` for async
  endpoints. Aim for >80% coverage on all business-critical paths (checkout,
  B2B pricing engine, migration parser, billing reconciliation).
- **Flutter Test:** Widget tests for Flutter Web admin and mobile apps.
- **Playwright:** End-to-end storefront tests — product page load, add-to-cart,
  checkout flow, theme switching. Run in CI on every merge to main.

---

## Internal Messaging Architecture

### Design Principle: Contextual, Archived, Zero-Friction

KloudShop's native messaging platform replaces external tools (email, Slack, WhatsApp)
for two communication surfaces: internal staff communication within a tenancy, and
merchant ↔ B2B buyer communication. All messages are permanently archived, fully
searchable, and context-linkable to platform objects (orders, POs, SKUs, buyer accounts).
No new vendor is required — the feature is built entirely on the existing approved stack.

---

### Who Can Message Whom

| Sender | Recipient | Surface |
|--------|-----------|---------|
| Staff member | Any other staff member in same tenancy | Merchant admin |
| Owner / Admin / Account Manager | B2B buyer (any buyer account in their tenancy) | Merchant admin → B2B buyer inbox |
| B2B buyer | Merchant (routed to assigned Account Manager or Admin) | B2B portal → merchant admin |
| Staff member | Cannot message consumers (DTC) | — DTC support handled via order notes |

**Consumer (DTC) messaging is explicitly out of scope.** DTC customer support
is handled via order notes and email (Resend). Adding a consumer-facing live
chat would require a separate consumer identity system and significantly increases
support burden for solo-team merchants. This is a Feature Request Channel candidate
for post-MVP.

---

### Message Types

**1. Direct Messages (DMs) — 1-to-1**
Private conversation between two users. Staff↔Staff or Merchant↔B2B Buyer.
Full message history preserved. FCM push on new message.

**2. Context-Linked Threads**
A message thread attached to a specific platform object:
- Order thread: `#order-1042` — all discussion about that order in one place
- Purchase order thread: `#po-2891` — supplier/stock discrepancy discussions
- SKU thread: `#sku-widget-pro` — product quality flags, variant decisions
- Buyer account thread: `#buyer-acme-corp` — internal notes + buyer comms history

Context-linked threads are visible to all staff with access to that object.
A buyer account thread is visible to the buyer AND all staff — it serves as
the official communication record for that buyer relationship.

**No general channels / group chat.** Scope is deliberately narrow —
contextual threads prevent message noise and keep communication
anchored to operational context.

---

### Technical Architecture

```
User sends message (Flutter Web / iOS / Android)
         │
         ▼
FastAPI: Messaging Module
  → Validate sender + recipient auth (JWT + RBAC)
  → Validate file attachments (MIME type check:
    image/jpeg, image/png, image/webp, application/pdf only
    — reject all other types regardless of extension
    — max 100MB per attachment, max 10 attachments per message)
  → If file attachments present:
    Upload to Cloud Storage:
    gs://kloudshop-{tenant_id}/messages/{thread_id}/{file_id}
    MIME validation enforced server-side (not client-declared)
  → Write message to Cloud SQL (permanent archive):
    messages table: message_id, thread_id, sender_id,
    sender_type, body, sent_at, is_draft
  → Write to Cloud Firestore:
    /tenants/{tenant_id}/threads/{thread_id}/messages/{message_id}
    (real-time delivery to all active thread participants)
  → Trigger FCM push to recipient's registered devices
  → Update recipient's unread badge count (Redis counter)
         │
         ▼
Recipient receives:
  → Real-time message in open thread (Cloud Firestore listener)
  → FCM push notification on mobile (if app backgrounded)
  → Unread badge on inbox icon in admin dashboard
```

**Why Cloud Firestore for delivery + Cloud SQL for storage:**
Cloud Firestore handles the live push to connected clients with sub-100ms latency — this is what makes messages feel instant. Cloud SQL is the permanent, searchable, auditable archive. Cloud Firestore is the signalling layer; Cloud SQL is the source of truth. Messages written to Firestore are considered delivered; the Cloud SQL record is the permanent record. This pattern is established in the architecture for approval workflows and migration progress bars.

---

### Message Search

Built on PostgreSQL Full-Text Search (already in stack). No additional vendor.

**Searchable dimensions:**
- Message body substring (tsvector on `messages.body`)
- Sender name / email
- Recipient name / email
- Date range (sent_at)
- Linked object context (order_id, po_id, variant_id, buyer_account_id)
- Thread type filter (DM / order / PO / SKU / buyer account)

Search is scoped strictly to the requesting user's accessible threads —
a staff member with Fulfilment Staff role cannot search messages from
threads they have no access to.

---

### Inbox Structure

Every user has a unified inbox with the following views:

| View | Contents |
|------|---------|
| **Inbox** | All threads with unread messages, sorted by most recent |
| **Sent** | All messages sent by this user |
| **Drafts** | Saved unsent messages (auto-saved every 30 seconds) |
| **All Messages** | Complete archive of all accessible threads |
| **Linked to Orders** | All order-context threads (filterable by order status) |
| **Linked to POs** | All purchase-order-context threads |
| **Linked to SKUs** | All product/SKU-context threads |
| **Linked to Buyers** | All buyer account threads (B2B/Hybrid tiers only) |

**Permanent archive policy:** Messages are never deleted by anyone —
not by the sender, not by the recipient, not by the merchant Owner.
All messages are retained indefinitely. This is a deliberate design decision:
in a B2B context, message history is a legal and operational record.
A B2B buyer disputing an agreed price must be able to reference the
exact message where the price was confirmed. Deletion would destroy
this audit trail. Users can archive (hide from inbox) but not delete.

---

### File Attachment Security

| Control | Implementation |
|---------|---------------|
| Allowed MIME types | `image/jpeg`, `image/png`, `image/webp`, `application/pdf` only |
| MIME validation | Server-side via python-magic (reads file bytes, ignores client-declared type) |
| Max attachment size | 100MB per file |
| Max attachments per message | 10 files |
| Storage path | `gs://kloudshop-{tenant_id}/messages/{thread_id}/{uuid}.{ext}` |
| Access control | Signed URLs with short TTL (15 minutes) — files not publicly accessible |
| Virus scanning | Cloud Storage trigger → Cloud Run scanner on every upload |
| Script payload | PDF with embedded JavaScript rejected at scanner layer |

---

### Data Model Flag — Stage 6

```sql
-- All tables are tenant-scoped (in tenant_{tenant_id} schema)

CREATE TABLE message_threads (
    thread_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_type       VARCHAR(32) NOT NULL,
    -- ENUM: 'direct', 'order', 'purchase_order', 'sku', 'buyer_account'
    linked_object_id  UUID,         -- order_id / po_id / variant_id / buyer_account_id
    created_at        TIMESTAMPTZ DEFAULT NOW(),
    created_by        UUID NOT NULL  -- staff_user_id or buyer_user_id
);

CREATE TABLE thread_participants (
    thread_id         UUID REFERENCES message_threads(thread_id),
    participant_id    UUID NOT NULL,  -- staff_user_id or buyer_user_id
    participant_type  VARCHAR(16) NOT NULL, -- 'staff' | 'buyer'
    joined_at         TIMESTAMPTZ DEFAULT NOW(),
    last_read_at      TIMESTAMPTZ,   -- drives unread badge count
    PRIMARY KEY (thread_id, participant_id)
);

CREATE TABLE messages (
    message_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id         UUID REFERENCES message_threads(thread_id),
    sender_id         UUID NOT NULL,
    sender_type       VARCHAR(16) NOT NULL, -- 'staff' | 'buyer'
    body              TEXT NOT NULL,
    body_tsv          TSVECTOR GENERATED ALWAYS AS (to_tsvector('simple', body)) STORED,
    -- 'simple' tokenises without language-specific stemming — safe for multilingual
    -- message bodies (any of the 10 supported LTR locales). Language-specific stemming
    -- (e.g. 'german') improves recall for monolingual corpora but breaks cross-language
    -- search. 'simple' is the correct default for a multilingual platform.
    -- Per-locale tsvector columns are a Stage 6 i18n backlog item.
    is_draft          BOOLEAN DEFAULT FALSE,
    sent_at           TIMESTAMPTZ DEFAULT NOW()
    -- NO deleted_at — messages are never deleted
);

CREATE INDEX idx_messages_fts ON messages USING GIN(body_tsv);
CREATE INDEX idx_messages_thread ON messages(thread_id, sent_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id, sent_at DESC);

CREATE TABLE message_attachments (
    attachment_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id        UUID REFERENCES messages(message_id),
    file_name         TEXT NOT NULL,       -- original filename
    mime_type         VARCHAR(64) NOT NULL, -- server-validated
    file_size_bytes   BIGINT NOT NULL,
    storage_path      TEXT NOT NULL,       -- gs:// path
    uploaded_at       TIMESTAMPTZ DEFAULT NOW()
);
```

**Business rules:**
- Messages are immutable after sending — no edit, no delete, ever
- Drafts auto-save every 30 seconds, converted to sent on submit
- Thread participants for context-linked threads are automatically
  determined by object access rules (e.g. all staff with order access
  can see an order thread) — no manual participant management needed
- Buyer account threads include the buyer as a participant automatically
  when created — they see the full thread history from their B2B portal
- Unread counts maintained in Redis (fast badge rendering) and
  reconciled with `last_read_at` in Cloud SQL on session start

---

## Theme Registry Architecture — Zero-Code Theme Catalogue

### Design Principle: Themes Are Data, Not Code

Every theme in the KloudShop catalogue is a JSON configuration package stored in
GCP Cloud Storage — not a hardcoded template in the Flutter codebase. The Flutter
storefront is a single universal rendering engine that reads a theme definition at
runtime. Adding a new theme to the catalogue requires no code changes, no CI/CD
pipeline, and no production deployment.

---

### Three-Layer Architecture

**Layer 1 — Theme Registry (Cloud SQL)**

```sql
CREATE TABLE themes (
    theme_id          VARCHAR(64) PRIMARY KEY,   -- e.g. "industrial-dark"
    display_name      TEXT NOT NULL,
    sector_category   VARCHAR(64) NOT NULL,      -- primary browseable category, e.g. "Apparel"
                                                  -- valid values: Apparel, Restaurants,
                                                  -- Electronics, Fashion, Beauty,
                                                  -- Industrial B2B, Food & Beverage,
                                                  -- Health & Beauty, Automotive, Home Décor,
                                                  -- Digital Products, Sporting Goods, Other
    sector_tags       TEXT[],                    -- secondary tags ["B2B","manufacturing","dark"]
    preview_url       TEXT NOT NULL,             -- CDN URL of preview screenshot
    config_url        TEXT NOT NULL,             -- gs://kloudshop-themes/{id}/theme.json
    asset_base_url    TEXT NOT NULL,             -- gs://kloudshop-themes/{id}/assets/
    schema_version    VARCHAR(8) NOT NULL,       -- "1.0", "1.1", etc.
    status            VARCHAR(16) DEFAULT 'draft', -- 'draft' | 'published' | 'deprecated'
    created_at        TIMESTAMPTZ DEFAULT NOW()
);
```

Adding a new theme = one INSERT row + uploaded package in Cloud Storage.
No code. No deployment. Available to all merchants instantly on publish.

**Layer 2 — Theme Config Package (Cloud Storage)**

Each theme lives at `gs://kloudshop-themes/{theme_id}/` containing:
- `theme.json` — full layout, typography, colour tokens, component config
- `assets/` — custom fonts, icons, images specific to this theme
- `preview.jpg` — screenshot rendered with sample merchant data

```json
{
  "schema_version": "1.1",
  "layout": "single-column",

  "scaffold": {
    "app_bar": {
      "logo_position": "left",
      "show_search": true,
      "show_cart_icon": true,
      "show_account_icon": true,
      "announcement_text": "Free shipping on orders over $50",
      "announcement_background": "#E94560",
      "background_color": "#1A1A2E",
      "sticky": true
    },
    "nav_bar": {
      "layout": "horizontal",
      "show_category_links": true,
      "custom_links": [
        { "label": "About Us", "url": "/about" },
        { "label": "Contact",  "url": "/contact" }
      ],
      "background_color": "#16213E",
      "link_color": "#FFFFFF",
      "hover_color": "#E94560"
    },
    "footer": {
      "show_newsletter": true,
      "show_social_icons": true,
      "link_groups": [
        { "heading": "Shop",    "links": ["New Arrivals", "Sale"] },
        { "heading": "Support", "links": ["FAQ", "Returns", "Contact"] }
      ],
      "background_color": "#0F0F1A"
    }
  },

  "typography": {
    "heading": "Space Grotesk",
    "body": "Inter",
    "scale": "compact"
  },

  "color_tokens": {
    "primary": "#1A1A2E",
    "accent": "#E94560",
    "surface": "#16213E",
    "text": "#FFFFFF",
    "border": "#2A2A4E",
    "error": "#FF4444"
  },

  "spacing": {
    "base_unit": 8,
    "section_vertical_rhythm": 64,
    "component_padding": 24,
    "grid_gap": 16
  },

  "border_radius": { "card": 8, "button": 4, "image": 4 },
  "elevation": { "card": 2.0, "modal": 8.0, "app_bar": 4.0 },
  "motion": { "transition_speed": "fast", "easing": "ease_out" },

  "component_order": [
    { "id": "hero_main",          "type": "video_hero" },
    { "id": "strip_mens",         "type": "horizontal_scroll_strip" },
    { "id": "strip_kids",         "type": "horizontal_scroll_strip" },
    { "id": "strip_footwear",     "type": "horizontal_scroll_strip" },
    { "id": "grid_bestsellers",   "type": "product_grid" },
    { "id": "cta_sale",           "type": "cta_block" },
    { "id": "ai_panel_main",      "type": "ai_assistant_panel" },
    { "id": "reviews_main",       "type": "reviews_strip" }
  ],

  "component_order_mobile": [
    { "id": "hero_main",          "type": "video_hero" },
    { "id": "strip_mens",         "type": "horizontal_scroll_strip" },
    { "id": "grid_bestsellers",   "type": "product_grid" },
    { "id": "strip_kids",         "type": "horizontal_scroll_strip" },
    { "id": "strip_footwear",     "type": "horizontal_scroll_strip" },
    { "id": "ai_panel_main",      "type": "ai_assistant_panel" },
    { "id": "reviews_main",       "type": "reviews_strip" }
  ],
  // component_order_mobile is optional. When absent, the renderer falls back to
  // component_order for all viewports. When present, mobile (width < 768px) uses
  // this order; tablet and desktop always use component_order.
  // The same component_config entries apply regardless of which order is used —
  // instance IDs are shared across both arrays. A component instance omitted
  // from component_order_mobile is hidden on mobile entirely.


  "component_config": {

    "hero_main": {
      "autoplay": true,
      "muted": true,
      "overlay_text_position": "bottom-left",
      "mobile_fallback_image": true,
      "content_slots": {
        "heading":    { "type": "short_text",  "max_chars": 80,
                        "placeholder": "Your main headline here" },
        "subheading": { "type": "long_text",   "max_chars": 300,
                        "placeholder": "Supporting text — describe your value proposition" },
        "cta_label":  { "type": "short_text",  "max_chars": 30,
                        "placeholder": "Shop Now" },
        "cta_url":    { "type": "link_url" },
        "background_image": { "type": "image_url" },
        "background_video": { "type": "video_url",  "optional": true }
      },
      "animation": {
        "enter": "fade_in",
        "enter_duration_ms": 800,
        "enter_delay_ms": 0,
        "exit": null,
        "hover": null
      }
    },

    "strip_mens": {
      "content_slots": {
        "title":         { "type": "short_text",   "max_chars": 50,
                           "placeholder": "Men's Apparel" },
        "collection_ref":{ "type": "collection_ref" }
      },
      "card_style": {
        "height": 280,
        "border_color": "#2A2A4E",
        "border_width": 1.0,
        "border_radius": 8,
        "elevation": 2.0,
        "shadow_color": "#00000030",
        "shadow_offset_x": 0,
        "shadow_offset_y": 2,
        "shadow_blur_radius": 8,
        "on_hover_background": "#1E1E3E",
        "on_hover_elevation": 6.0,
        "on_hover_border_color": "#E94560"
      },
      "animation": {
        "enter": "fade_up",
        "enter_duration_ms": 400,
        "enter_delay_ms": 80,
        "hover": "scale_up",
        "scale_factor": 1.04,
        "hover_duration_ms": 150
      }
    },

    "strip_kids": {
      "title": "Kids' Apparel",
      "collection_id": "kids-collection",
      "card_style": { "height": 260, "border_radius": 12, "elevation": 2.0,
                      "on_hover_elevation": 5.0, "on_hover_background": "#1E1E3E" },
      "animation": { "enter": "fade_up", "enter_duration_ms": 400,
                     "enter_delay_ms": 80, "hover": "scale_up",
                     "scale_factor": 1.04, "hover_duration_ms": 150 }
    },

    "strip_footwear": {
      "title": "Footwear",
      "collection_id": "footwear-collection",
      "card_style": { "height": 300, "border_radius": 4, "elevation": 1.0,
                      "on_hover_elevation": 4.0 },
      "animation": { "enter": "slide_in_left", "enter_duration_ms": 500,
                     "hover": "shadow_deepen", "hover_duration_ms": 200 }
    },

    "grid_bestsellers": {
      "columns": 3,
      "show_quick_add": true,
      "show_ratings": true,
      "card_style": {
        "height": 340,
        "border_radius": 8,
        "elevation": 2.0,
        "on_hover_elevation": 8.0,
        "on_hover_background": "#1E1E3E"
      },
      "animation": {
        "enter": "fade_up",
        "enter_duration_ms": 350,
        "enter_delay_ms": 60,
        "hover": "scale_up",
        "scale_factor": 1.03,
        "hover_duration_ms": 120
      }
    },

    "ai_panel_main": {
      "position": "floating",
      "trigger": "scroll-50",
      "animation": {
        "enter": "slide_in_right",
        "enter_duration_ms": 300,
        "exit": "slide_out_right",
        "reveal_on_hover": null
      }
    },

    "nav_item_apparel": {
      "label": "Apparel",
      "reveal_on_hover": "mega_menu_apparel",
      "animation": {
        "hover": "underline",
        "hover_duration_ms": 150
      }
    },

    "mega_menu_apparel": {
      "initially_hidden": true,
      "hide_on_blur": true,
      "animation": {
        "enter": "slide_in_left",
        "enter_duration_ms": 200,
        "hide_animation": "fade_out",
        "hide_duration_ms": 150
      }
    }
  }
}
```

**Layer 3 — Flutter Universal Renderer**

The Flutter storefront renderer is a single engine that:
1. Fetches `theme.json` for the tenant's active theme (Redis cache, TTL: 1 hour)
2. Parses component_order and component_config
3. Instantiates the corresponding Flutter widget for each component,
   passing its config block as parameters
4. Renders the full page — never with any hardcoded colour, font, or layout value

```dart
// Pseudocode — component_order is List<{id, type}>
// component_config keys on instance ID, not type
for (instance in theme.component_order) {
  final config = theme.component_config[instance.id];
  final animation = config?.animation; // nullable — no animation if absent

  switch (instance.type) {
    case "video_hero":
      VideoHeroWidget(config: config, animation: animation)
    case "product_grid":
      ProductGridWidget(config: config, animation: animation)
    case "horizontal_scroll_strip":
      // Same type, different instance IDs → renders as separate components
      HorizontalScrollStripWidget(config: config, animation: animation)
    case "ai_assistant_panel":
      AIAssistantWidget(config: config, animation: animation)
    default:
      // Unknown type — skip gracefully, log warning, never crash storefront
      log.warn("Unknown component type: \${instance.type} (id: \${instance.id})")
  }
}
```

---

### Component Architecture — Scaffold vs Body

**Scaffold components** live in `theme.json → scaffold` and persist on every page.
They are not in `component_order`. The Flutter `Scaffold` maps directly:
`appBar` → `app_bar`, `body` → scrollable `component_order`, persistent `footer`.

| Scaffold Component | Description | Required? |
|-------------------|-------------|-----------|
| `app_bar` | Top persistent bar: logo, search bar, cart icon, account icon, optional announcement | ✅ Required |
| `nav_bar` | Navigation links: categories, custom pages, mega-menu support | ✅ Required |
| `footer` | Bottom persistent bar: link groups, social icons, newsletter | ✅ Required |

**Body components** live in `component_order` as `{id, type}` instances.
Every body component type is **multi-instance eligible** — any type can appear
any number of times with independent IDs and configs. The renderer never restricts
a type to a single instance.

| Body Component | Description | Card-Styled? | Multi-Instance? |
|----------------|-------------|-------------|----------------|
| `video_hero` | Full-bleed video: autoplay, muted, overlay text, mobile fallback | — | ✅ |
| `hero_banner` | Static image hero with CTA overlay, configurable text position | — | ✅ |
| `carousel` | Auto-advancing or manual slide carousel of images or products | ✅ | ✅ |
| `cta_block` | Standalone call-to-action: heading, body text, button | — | ✅ |
| `featured_collections` | Curated collection grid, configurable columns | ✅ | ✅ |
| `product_grid` | Product cards: columns, quick-add, ratings, card_style config | ✅ | ✅ |
| `horizontal_scroll_strip` | Swipeable product/collection row, titled, linkable | ✅ | ✅ |
| `ai_assistant_panel` | RAG-powered consultative search, floating or inline | — | — |
| `reviews_strip` | Customer review cards, configurable count | ✅ | ✅ |
| `announcement_bar` | Inline promotional banner (not scaffold app_bar) | — | ✅ |
| `shoppable_video` | Video with embedded product hotspot overlays | ✅ | ✅ |
| `divider` | Visual section separator, configurable style and spacing | — | ✅ |

All body components are optional. The renderer skips absent instances gracefully.
Unknown component types log a warning and are skipped — storefront never crashes.

---

### Card Style Config (shared block for card-rendering components)

Any component marked Card-Styled above accepts a `card_style` block:

```json
"card_style": {
  "height": 320,
  "border_color": "#E0E0E0",
  "border_width": 1.0,
  "border_radius": 8,
  "elevation": 2.0,
  "shadow_color": "#00000020",
  "shadow_offset_x": 0,
  "shadow_offset_y": 2,
  "shadow_blur_radius": 8,
  "on_hover_background": "#F5F5F5",
  "on_hover_elevation": 6.0,
  "on_hover_border_color": "#BDBDBD"
}
```

---

### Animation Config (all components — all fields nullable)

```json
"animation": {
  "enter": "fade_up",
  "enter_duration_ms": 400,
  "enter_delay_ms": 80,
  "exit": null,
  "hover": "scale_up",
  "scale_factor": 1.04,
  "zoom_factor": null,
  "hover_duration_ms": 150,
  "reveal_on_hover": null,
  "initially_hidden": false,
  "hide_on_blur": false,
  "hide_animation": null,
  "hide_duration_ms": null
}
```

| Field | Valid values | Required with |
|-------|-------------|--------------|
| `enter` | `fade_in`, `fade_up`, `fade_down`, `slide_in_left`, `slide_in_right`, `zoom_in`, `none` | — |
| `exit` | `fade_out`, `slide_out_left`, `slide_out_right`, `zoom_out`, `none` | — |
| `hover` | `scale_up`, `scale_down`, `color_shift`, `shadow_deepen`, `underline`, `brightness_up`, `none` | — |
| `scale_factor` | Float 0.8–1.5 | When `hover` = `scale_up` or `scale_down` |
| `zoom_factor` | Float 1.0–3.0 | When `enter`/`exit` = `zoom_in`/`zoom_out` |
| `enter_duration_ms` | Integer 100–2000 | — |
| `enter_delay_ms` | Integer 0–1000 | Stagger grids |
| `hover_duration_ms` | Integer 50–500 | — |
| `reveal_on_hover` | Instance ID string | Trigger component |
| `initially_hidden` | Boolean | Target component |
| `hide_on_blur` | Boolean | Target component |
| `hide_animation` | Same as `exit` enum | Target component |
| `hide_duration_ms` | Integer 50–500 | Target component |

---

### Content Slot Architecture — Content vs Theme Separation

**Core principle:** `theme.json` defines content slot *structure* and *type constraints*.
The merchant's actual content (text, images, videos) lives in `storefront_content`
(a tenant-scoped database table), never in the theme file. This means:
- Theme switches never destroy merchant content
- Content is fully portable across any theme in the catalogue
- The WYSIWYG right panel has two tabs per component: **Config** (visual/structural
  parameters) and **Content** (text and media for each content slot)

**Content slot types:**

| Slot type | Flutter widget rendered | Use case |
|-----------|------------------------|---------|
| `short_text` | Single-line TextInput | Headlines, CTA labels, taglines (max_chars enforced) |
| `long_text` | Multi-line TextArea (drag-resizeable — merchant can drag the bottom edge to expand the input for better visibility of long copy) | Subheadings, banner copy, feature descriptions |
| `rich_text` | Rich text editor (bold, italic, links) | About pages, FAQ answers, policy pages |
| `image_url` | Image upload + Cloud Storage picker | Hero backgrounds, banner images, feature images |
| `video_url` | Video upload + Cloud Storage picker | Video hero background |
| `link_url` | URL input with validation | CTA button destinations, navigation links |
| `collection_ref` | Collection selector dropdown | Product strips, grids — links to merchant's collections |
| `product_query` | Product query builder (filter panel: by collection, tag, price range, in-stock only, sort order, result limit) | Strips, carousels, grids that need dynamic product sourcing beyond a single static collection — e.g. "Top 8 bestsellers", "New arrivals this week", "On sale under $50". Stored as a JSON query spec in `content_value`; resolved at render time against the products table. |

**How theme switching handles content:**

```
Merchant switches theme: "Glow Theme" → "Bold Theme"
         │
         ▼
FastAPI: Storefront Module
  1. Load new theme.json — extract all content_slot IDs
     across all component instances
  2. Query storefront_content WHERE tenant_id = ?
     — get all existing content keyed by slot_id
  3. Match: slot_ids present in BOTH old and new theme
     → content carries forward automatically (no action)
  4. Unmatched: slot_ids in new theme with NO existing content
     → flagged as "empty" in WYSIWYG with placeholder text
     → merchant notified: "Your new theme has X new content
       slots to fill. Everything else carried forward."
     → when the merchant fills a new slot and saves,
       a new storefront_content row is INSERTed with
       the slot_id from the new theme — persisted
       permanently, identical to any other content slot.
       New theme slots are NOT ephemeral or temporary.
  5. Orphaned: slot_ids in old theme NOT in new theme
     → content PRESERVED in storefront_content table
       (not deleted — merchant may switch back)
     → not shown in WYSIWYG (slot doesn't exist in
       current theme) but retrievable if they return
       to the old theme
```

**Data model flag — Stage 6:**

```sql
-- Tenant-scoped table in tenant_{tenant_id} schema
CREATE TABLE storefront_content (
    slot_id        VARCHAR(128) NOT NULL,
    -- Composite key: "{component_instance_id}.{slot_key}"
    -- e.g. "hero_main.heading", "strip_mens.title"
    slot_type      VARCHAR(32)  NOT NULL,
    -- ENUM: short_text | long_text | rich_text |
    --       image_url | video_url | link_url | collection_ref
    content_value  TEXT,        -- actual text, URL, or collection ID
    updated_at     TIMESTAMPTZ DEFAULT NOW(),
    updated_by     UUID,        -- staff_user_id who last edited
    PRIMARY KEY (slot_id)
);

CREATE INDEX idx_storefront_content_slot
  ON storefront_content(slot_id);
```

**Key design decisions:**
- `slot_id` is `"{component_instance_id}.{slot_key}"` — scoped to the
  component instance, not the type. Two `horizontal_scroll_strip` instances
  (`strip_mens` and `strip_kids`) have independent content:
  `strip_mens.title = "Men's Apparel"` and `strip_kids.title = "Kids' Apparel"`
- Orphaned content (from old themes) is never deleted — always preserved
- `collection_ref` values are collection IDs (FK to merchant's collections table) —
  validated on save, not on theme switch

---

### Schema-Driven Feature Setup Wizard

The Feature Catalogue setup wizard (Phase 2 of feature activation) is a
**generic, data-driven form renderer** — not a per-feature hand-coded screen.
Zero Flutter code changes are needed when a new feature with new config
parameters is added to the catalogue.

**How it works:**

```
Merchant completes Phase 1 (schema migration succeeds)
              │
              ▼
FastAPI: Feature Module
  GET /features/{feature_id}/config-schema
  → Query feature_config_schema
    WHERE feature_id = ?
    ORDER BY display_order
  → Returns typed parameter definitions

Flutter: GenericFeatureSetupWizard
  → Groups parameters by wizard_group
    (one wizard step per group)
  → Per parameter, renders correct Flutter widget
    by data_type:

    "string"     → DropdownSelector (if allowed_values present)
                   TextInputField, single-line (if free text)
                   ImageUploadWidget (if format: "image_url")
    "text"       → TextAreaField, multi-line (email templates,
                   terms copy, long descriptions)
    "integer"    → NumberInputField(min, max, default)
    "float"      → DecimalInputField(min, max, step, default)
    "boolean"    → SwitchToggle(default)
    "date"       → DatePicker (calendar — no time component)
    "time"       → TimePicker(format: "HH:MM")
    "datetime"   → DateTimePicker (calendar + time —
                   for flash sales, scheduled promotions)
    "json_array" → MultiSelectChips (if allowed_values present)
                   DynamicListInput (if free-form items)
    "json_object"→ StructuredObjectForm(object_schema)

  → Required fields (is_required = TRUE) validated
    before wizard step can advance
  → Default values pre-populated — merchant can
    click through in 30 seconds if defaults are fine
  → On save: FastAPI writes rows to
    tenant_feature_config (INSERT or UPDATE)
  → Feature marked "Active — fully configured"
```

**Adding a new feature with config parameters:**
1. KloudShop engineer inserts rows into `feature_config_schema`
   defining the new feature's parameters (data types, labels,
   validation rules, defaults, wizard grouping)
2. Zero Flutter code changes required
3. The generic wizard renderer handles the new fields automatically
4. The new feature is immediately available in the merchant's
   Feature Catalogue with a correctly rendered setup wizard

**The wizard never knows it is rendering "Loyalty Programme"
vs "Delivery Windows" vs "OTP Verification" — it only knows
data types and validation rules. The feature's identity is
irrelevant to the renderer.**

---

### WYSIWYG Theme Editor — Merchant-Facing Configuration

Merchants never edit `theme.json` directly. The WYSIWYG theme editor in the KloudShop
admin is a structured three-panel Flutter Web interface:

| Panel | Contents | Flutter Implementation |
|-------|----------|----------------------|
| **Left — Component Stack** | Drag-to-reorder list of active component instances. Add new instances (same type can appear multiple times with different IDs). Remove instances. | `ReorderableListView` + `ComponentPickerModal` |
| **Centre — Live Preview** | The actual `StorefrontRenderer` widget running inside the admin — not a simulation. Reactive state: any config change triggers immediate re-render. Viewport toggle: mobile / tablet / desktop. | Same `StorefrontRenderer` used in production, wrapped in a constrained viewport |
| **Right — Config Panel** | Structured form for the selected component instance: collection selectors, column pickers, animation dropdowns, content slots, image upload, colour token overrides. Every field maps to a `theme.json` parameter. | Flutter form widgets + reactive state (Riverpod) |

**Two distinct theme states per tenant storefront:**

| State | Storage location | What it is |
|-------|-----------------|-----------|
| `draft_theme_config_url` | `gs://kloudshop-{tenant_id}/themes/draft/{brand_profile_id}/theme.json` | Merchant's in-progress WYSIWYG edits — NOT live on storefront |
| `active_theme_config_url` | `gs://kloudshop-{tenant_id}/themes/active/{brand_profile_id}/theme.json` | Currently rendering on storefront — promoted from draft on Apply |

**On Save (WYSIWYG "Save changes"):** Serialises in-memory theme state to
`draft_theme_config_url` in Cloud Storage. Storefront is completely unaffected —
it continues rendering the `active_theme_config_url`. The merchant can close the
editor and resume later; their draft is preserved. Redis cache for the active theme
is NOT invalidated on Save.

**On Apply (WYSIWYG "Apply theme to storefront"):** Copies `draft_theme_config_url`
to `active_theme_config_url`, invalidates the Redis cache for the active theme, and
updates the draft status to `"active"` — the draft is **not deleted**. The merchant
can return to the editor, fine-tune, and re-apply at any time. The draft is always
the working copy of the currently live theme; it diverges from `active_theme_config_url`
only once the merchant makes further edits after applying. The storefront picks up the
new active theme on the next page request. On the Hybrid tier, the merchant explicitly
selects which storefront (DTC or B2B) to apply the theme to — applying to one storefront
never affects the other.

**Tenant isolation:** Theme edits always write to the tenant's own Cloud Storage paths.
The global theme catalogue (gs://kloudshop-themes/{theme_id}/theme.json) is never
modified by any merchant action. All merchants always see an unmodified copy of the
original theme as their starting point.

**Zero deployment. Zero code.**

**Why this works well in Flutter:** The WYSIWYG is not a free-form pixel editor —
it is a structured configuration form. Flutter's `ReorderableListView`, side panel
layouts, and reactive state management (`Riverpod` or `Bloc`) handle all required
interactions natively. The live preview reuses the production renderer — no separate
preview simulation is needed, because Flutter Web runs the same Dart code for both
the admin and the storefront. This is a material advantage of the single-codebase
Flutter architecture.

---

### Zero-Code Theme Addition Workflow

```
Theme designer (human or AI agent) prepares:
  → theme.json  (layout config + component config)
  → assets/     (fonts, icons, images)
  → preview.jpg (screenshot with sample merchant data)
         │
         ▼
Upload package to Cloud Storage:
  gs://kloudshop-themes/{theme_id}/
  (via internal KloudShop admin tool —
   no developer access required)
         │
         ▼
INSERT into themes table:
  status: "draft" → internal preview + QA
  status: "published" → live in merchant theme library
         │
         ▼
Merchant theme library updated instantly.
No deployment. No code change. No engineer.
         │
         ▼
Merchant selects theme → one click →
Redis caches new theme.json for their tenant →
storefront re-renders immediately.
Zero downtime.
```

---

### Component Registry Evolution — Staying Current with Design Systems

When a new UI component type becomes ubiquitous in prevailing design systems
(signalled by Feature Request Channel votes, repeated theme designer requests,
or major industry design system releases such as Material 3 updates or Apple HIG):

**Promotion pipeline:**

| Stage | Action | Who | Code required? |
|-------|--------|-----|---------------|
| Signal detection | 3+ theme requests for same component type | Feature Request Channel | No |
| Component build | New Flutter widget, fully JSON-parameterised | AI engineering team | Yes — one task |
| Schema version bump | `schema_version` incremented (e.g. "1.1" → "1.2") | Engineering | Yes — one task |
| App deployment | Standard CI/CD pipeline deploy | Automated | Yes — standard deploy |
| Theme adoption | Theme designers add new component to `theme.json` | Theme designers | **No** |
| Merchant adoption | Merchants switch to updated theme | Merchants | **No** |

**The key separation:** The *renderer framework* requires a standard engineering
deployment when new component types are added — this happens rarely, only when design
paradigms genuinely shift. The *theme catalogue* never requires a deployment. These
are two completely separate concerns on two completely separate timelines.

**Backward compatibility guarantee:**
- Every `theme.json` declares its `schema_version`
- The renderer supports all schema versions currently in use simultaneously
- Unknown components are skipped gracefully (logged, never crash the storefront)
- Deprecated components remain supported for 2 major schema versions before sunset
- No merchant storefront ever breaks when KloudShop ships a new component type

---

### Theme Config Caching Strategy

| Cache Layer | TTL | What Is Cached |
|-------------|-----|---------------|
| Redis (Memorystore) | 1 hour | Parsed `theme.json` per tenant — fast runtime render |
| Cloud CDN | 24 hours | Theme asset files (fonts, images, icons) |
| Flutter app | Session | Active theme config in memory during browsing session |

Cache invalidation on theme switch: merchant clicks "Apply theme" →
FastAPI invalidates Redis key for that tenant → next page request
fetches new `theme.json` → storefront renders new theme.

---

## New Integration Layers — Feature Gap Additions

### Tax Compliance — Stripe Tax (via Merchant's Connected Stripe Account)

**Decision:** Stripe Tax, built directly into each merchant's connected Stripe account.
KloudShop is a SaaS platform — tax liability rests with each merchant on their own
connected Stripe account, not with KloudShop UK Ltd. This is the correct model per
Stripe's own documentation: "Tax for software platforms applies when connected accounts
assume responsibility for collecting and remitting taxes."

**Why Stripe Tax over TaxJar/Avalara:**
Stripe Tax is already inside the merchant's Stripe account — no additional API vendor,
no per-calculation pass-through cost, no separate integration. Tax records (`tax_transaction`
objects) are created automatically in the merchant's Stripe account on every charge.
Merchants can access their tax reports directly from Stripe or via KloudShop's embedded
components. Adding TaxJar/Avalara would add cost and complexity for functionality already
covered by Stripe Tax natively.

**Integration architecture:**
KloudShop surfaces Stripe Tax configuration inside the merchant admin using
Stripe Connect Embedded Components — merchants never leave KloudShop to set up tax:

```python
# FastAPI: create AccountSession with tax components enabled
account_session = stripe.AccountSession.create(
    account=connected_account_id,
    components={
        "tax_settings": {"enabled": True},
        "tax_registrations": {"enabled": True},
    }
)
# Flutter: renders ConnectTaxSettings + ConnectTaxRegistrations
# embedded components in the merchant admin
```

**What Stripe Tax handles automatically:**
- US sales tax nexus rules across 50 states
- EU VAT (27 countries) — including OSS/IOSS thresholds
- AU GST, CA GST/HST/PST
- Tax rate lookup at checkout by buyer location
- `tax_transaction` record created per charge in merchant's Stripe account
- Tax reports downloadable by merchant from Stripe or KloudShop admin

**Tax reporting for merchants:**
Each merchant's `tax_transaction` records in their Stripe account serve as their
source of truth. KloudShop surfaces a "Download Tax Statement" button in the merchant
admin — FastAPI calls `/v1/tax/transactions` filtered by the connected account ID
and generates a PDF report via the billing service. Merchants can also access reports
directly from their Stripe Express Dashboard.

**Tax liability is the merchant's — not KloudShop's:**
KloudShop UK Ltd does not collect, hold, or remit tax on behalf of merchants.
Each merchant's connected Stripe account handles their own tax obligations.
This is fundamentally different from a marketplace model (Etsy, Amazon) where
the platform is the deemed seller. KloudShop is a SaaS platform tool — the same
legal category as Shopify or WooCommerce.

**Cost:** Stripe Tax is included in Stripe's standard pricing — no per-calculation
fee for merchants. No additional pass-through cost to document.

---

### POS Integration — Stripe Terminal + Hardware-Agnostic POS API

**Decision:** KloudShop-native POS only (Model B). No external POS API integration.

**Rationale:** External POS integration (Model A) adds significant development complexity
(API surface, auth management, webhook reliability, third-party POS version compatibility)
for marginal benefit. KloudShop's browser-native POS eliminates this entirely: a POS
Operator opens KloudShop in any browser on any existing device, logs in with their
scoped credentials, and processes in-store sales. No dedicated hardware. No external
system. No training beyond a browser login.

**KloudShop-native POS architecture:**
Staff member with `POS Operator` role logs into KloudShop on any browser-capable device.
The POS interface is a role-scoped view of the merchant admin — showing product catalog
filtered to SKUs where `in_store_eligible = TRUE`, stock levels for the assigned location,
and a sale completion flow. `in_store_eligible` is a `BOOLEAN DEFAULT TRUE` field on the
`products` table — merchants explicitly mark `FALSE` for any product not available for
in-store purchase (e.g. online-only promotions, digital products, pre-order-only items).
The POS catalog query is: `WHERE in_store_eligible = TRUE AND location_id = ?`.
Payments processed via Stripe Terminal if card reader is connected,
or manual cash/external payment recording if not. Every completed POS sale:
- Decrements inventory from the correct stock location (Cloud SQL row-level lock)
- Creates an order with `order_source: "pos"` in the merchant's order history
- Streams a commerce event to BigQuery for unified online + in-store analytics

**Why Stripe Terminal:** KloudShop already runs Stripe for online payments. Stripe
Terminal extends the same Stripe account to in-person payments — unified reporting,
unified reconciliation, unified dispute management. No separate merchant account.
No split between online and offline revenue reporting. Stripe Terminal supports
BBPOS WisePOS E and other certified hardware globally.

**Inventory sync architecture:**
```
In-store sale completed on POS terminal
         │
         ▼
Stripe Terminal webhook → FastAPI Commerce Module
  → Decrement inventory in Cloud SQL (same pool
    as online store — single source of truth)
  → Publish "order.placed" event → Pub/Sub
    (order_source: "pos" flag set — distinct
     from "kloudshop" online and "imported")
  → BigQuery: POS analytics event streamed
  → FCM: merchant dashboard inventory updated
    in real time
```

**Multi-location POS:** Each physical store location is a named stock location in the
multi-warehouse inventory system. POS sales decrement the correct location's stock.
Online store can be configured to fulfil from any location or a specific warehouse.

---

### Social Commerce — TikTok Shop, Instagram Shopping, Facebook Shops

**Decision:** Native channel integrations — product catalog sync, inventory sync,
order ingestion — for TikTok Shop, Instagram Shopping, and Facebook Shops.
No third-party sync app. No JavaScript injection. Managed from the KloudShop
Channel Manager in the admin dashboard.

**Architecture:**
```
KloudShop Product Catalog (Cloud SQL)
         │
         ▼
Channel Sync Service (FastAPI — Cloud Run Job,
runs on schedule + on product change event)
  → TikTok Shop API: product feed push
  → Instagram Graph API: product catalog sync
  → Facebook Commerce API: catalog + inventory
         │
         ▼
Orders placed on social channels:
  → Webhook → FastAPI Commerce Module
  → Ingested as native KloudShop orders
    (order_source: "tiktok_shop" /
     "instagram_shop" / "facebook_shop")
  → Inventory decremented immediately
  → Merchant fulfils from KloudShop dashboard
  → Analytics: channel attribution in BigQuery
```

**Inventory oversell protection:** All social channel orders flow through the same
Cloud SQL inventory reservation system as online orders — row-level locks prevent
overselling across channels during simultaneous order bursts (e.g. viral TikTok moment).

**Channel attribution:** All social orders tagged with `order_source` and `channel_id`
in BigQuery — merchants see exact revenue, conversion, and AOV per social channel
in their native analytics dashboards.

---

### Google Shopping — Native Product Feed

**Decision:** Every KloudShop store automatically generates and maintains a live
Google Merchant Center product feed. No app. No manual CSV upload. No feed management
tool.

**Architecture:**
- FastAPI Catalog Module generates a Google Shopping-compliant XML/JSON product feed
  per tenant, served at a stable URL: `storename.kloudshop.biz/feeds/google-shopping`
- Feed updates trigger on: product price change, stock level change (in/out of stock),
  product publish/unpublish, new product added
- Google Merchant Center is configured once by the merchant (OAuth connection) — all
  subsequent feed updates are automatic
- Feed includes: GTIN/MPN (if provided), product condition, shipping weight, availability,
  structured pricing, sale price + sale dates
- Cloud Tasks: daily full feed refresh job per tenant (catches any drift)

**Why this matters for SEO + conversion:** Google Shopping traffic converts at 2–3x
the rate of standard text search ads. A stale feed (showing out-of-stock items, wrong
prices) wastes ad spend and erodes Google Merchant Center account health scores.
KloudShop's real-time feed eliminates feed staleness entirely.

---

### Multi-Location Inventory — MVP Scope

**Decision:** Multiple named stock locations (warehouses, physical stores, fulfilment
centres) with per-location stock levels and manual allocation. AI-powered regional
routing deferred to post-MVP.

**MVP capabilities:**
- Unlimited named stock locations per tenant (warehouse A, warehouse B, store NYC, etc.)
- Per-SKU, per-variant stock levels tracked per location
- Manual stock transfer between locations (with transfer order record)
- Fulfilment routing: merchant configures which location fulfils online orders
  (single location, priority order, or manual per-order selection)
- POS sales decrement the correct location automatically
- Low stock alerts per location (not just aggregate)

**Post-MVP — AI regional routing:**
- Vertex AI Forecasting per location: predict regional demand by SKU
- Automated stock transfer recommendations (move 200 units from Ohio → Arizona
  based on Arizona velocity trend)
- Smart fulfilment routing: auto-select fulfilment location based on buyer proximity
  + stock availability + shipping cost optimisation

---

## Flutter Web Admin — New Version Detection (SYS-18)

### Data Model Flag — Stage 6 / Infrastructure

The following GCP-managed static asset and Cloud Tasks infrastructure is required to support seamless, non-intrusive version update detection for the Flutter Web merchant admin. This is a P1 infrastructure task — not MVP-blocking, but must land before the first post-launch Feature Catalogue additions so merchants see the update experience from day one of the platform evolving.

**`version.json` — served at `/version.json` via Cloud CDN:**
```json
{
  "build": "a3f9c2d1",
  "deployed_at": "2026-03-29T14:00:00Z",
  "features_added": 3
}
```
- Written by GCP Cloud Build at each production deployment
- `features_added` is computed by CI: diff of `feature_registry` rows between previous and new build
- Served with `Cache-Control: no-store` — this file is explicitly never cached
- Zero-feature deployments (bug fixes) set `features_added: 0`; banner suppresses feature language

**Service Worker strategy:**
- Flutter Web build uses `--pwa-strategy=none` flag; service worker is fully custom-managed
- Custom service worker pre-fetches and caches new build assets in background during `install` event
- Every 10 minutes (and on user interaction after idle), service worker fetches `/version.json` with `cache: 'no-store'`
- On build hash mismatch: `postMessage({ type: 'NEW_VERSION_AVAILABLE', features_added: N })` sent to Flutter app via JS interop
- Flutter admin app renders non-intrusive persistent banner at top of authenticated admin shell only — never on public storefront renderer
- Banner text: `"✨ {N} new features available to boost your store experience. [ Update now ] [ Remind me later ]"`
- "Update now": service worker calls `skipWaiting()` + `clients.claim()` → Flutter calls `window.location.reload()` — new binary already pre-cached, reload is near-instant
- "Remind me later": banner dismissed; re-shown after 4 hours or on next login

**Mobile (iOS/Android):**
- Standard app store update flow via `package_info_plus` + backend `/version/latest` endpoint
- In-app banner: "A new version of KloudShop is available — update to get {N} new features"
- Deep-links to App Store / Play Store listing on tap

**Risk note:** Flutter Web's generated `flutter_service_worker.js` uses a hash-based cache manifest. Custom service worker must not break Flutter's own cache invalidation logic. Validate in a one-sprint spike before committing. If Flutter's service worker interop proves problematic, fallback is a simple `setInterval` polling loop in `main.dart` calling `/version.json` directly via `dart:js` — same UX outcome, no service worker complexity.

---

## Risk Register


| Risk | Severity | Mitigation |
|------|----------|-----------|
| Flutter Web CWV scores uncompetitive for storefronts | High | Benchmark sprint Phase 0. Fallback: FastAPI + Jinja2 for storefronts, Flutter Web for admin only. |
| Migration scraper blocked by competitor bot-protection | High | Technical spike Sprint 1. Proxy pool, crawl-rate throttling, Playwright fallback for JS pages. |
| Cloud SQL becoming a bottleneck at high tenant count | Medium | Read replicas from day one. Connection pooling via PgBouncer on Cloud Run. Partition tenant data by schema at >1,000 merchants. |
| Stripe not available in future expansion markets | Low (MVP) | Design payment abstraction layer in FastAPI as gateway-agnostic from day one. Add regional gateways (Razorpay, HyperPay) post-MVP without core changes. |
| GCP pass-through billing reconciliation complexity | Medium | Isolate billing service as a dedicated FastAPI module. Build and test billing reconciliation logic before onboarding first paying merchant. |
| Firebase Auth custom claims complexity for multi-tenant B2B | Medium | Define auth claim schema (tenant_id, role, account_type) in Phase 0. Validate with B2B buyer portal prototype before full build. |

---

## Stack Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENTS                              │
│  Flutter Web (admin)  │  Flutter iOS  │  Flutter Android    │
│         Storefront (Flutter Web + FastAPI SSR)              │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS
┌────────────────────────▼────────────────────────────────────┐
│                   GCP CLOUD RUN                             │
│              FastAPI (Python) — API Layer                   │
│   ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────────┐  │
│   │ Auth     │ │ Commerce │ │ B2B      │ │ AI / RAG    │  │
│   │ Service  │ │ Service  │ │ Service  │ │ Service     │  │
│   └──────────┘ └──────────┘ └──────────┘ └─────────────┘  │
│   ┌──────────┐ ┌──────────┐ ┌──────────────────────────┐  │
│   │ Billing  │ │Migration │ │ Storefront SSR Service   │  │
│   │ Service  │ │ Service  │ │                          │  │
│   └──────────┘ └──────────┘ └──────────────────────────┘  │
└──────┬──────────────┬──────────────┬───────────────┬───────┘
       │              │              │               │
┌──────▼───┐  ┌───────▼──────┐ ┌────▼─────┐  ┌─────▼──────┐
│ Cloud SQL│  │  Memorystore │ │ Vertex AI│  │  Firebase  │
│ Postgres │  │  Redis       │ │ + Gemini │  │  Auth/FCM  │
└──────────┘  └──────────────┘ └──────────┘  └────────────┘
┌──────────┐  ┌──────────────┐ ┌──────────┐  ┌────────────┐
│  Cloud   │  │  Cloud CDN   │ │  Cloud   │  │  Cloud     │
│ Storage  │  │              │ │  Tasks   │  │  Pub/Sub   │
└──────────┘  └──────────────┘ └──────────┘  └────────────┘
┌──────────┐  ┌──────────────┐ ┌──────────┐  ┌────────────┐
│  Stripe  │  │    Resend    │ │  Sentry  │  │   Twilio   │
│ Billing  │  │  (Email)     │ │ (Errors) │  │   (SMS)    │
└──────────┘  └──────────────┘ └──────────┘  └────────────┘
```

---

## Final Stack Decisions Summary

| Category | Tool | Status |
|----------|------|--------|
| Frontend / Admin | Flutter Web | ✅ Confirmed |
| Mobile | Flutter iOS + Android | ✅ Confirmed |
| Backend API | Python FastAPI (Pydantic v2) | ✅ Confirmed |
| Primary DB | PostgreSQL — GCP Cloud SQL Enterprise | ✅ Confirmed |
| Auth | Firebase Auth (custom claims for multi-tenant) | ✅ Confirmed |
| Storage | GCP Cloud Storage | ✅ Confirmed |
| CDN | GCP Cloud CDN | ✅ Confirmed |
| Caching | GCP Memorystore for Redis | ✅ Recommended + Decided |
| Payments | Stripe (gateway-agnostic abstraction layer) | ✅ Recommended + Decided |
| Subscriptions | Stripe Billing + metered usage for GCP pass-through | ✅ Recommended + Decided |
| AI / ML | Vertex AI + Gemini + pgvector | ✅ Confirmed + Extended |
| Push Notifications | Firebase Cloud Messaging (FCM) | ✅ Recommended + Decided |
| Transactional Email | Resend | ✅ Recommended + Decided |
| Background Jobs | GCP Cloud Tasks + Cloud Pub/Sub | ✅ Recommended + Decided |
| Search | PostgreSQL FTS + pgvector + Vertex AI Embeddings | ✅ Recommended + Decided |
| Real-time | Cloud Firestore (scoped) | ✅ Recommended + Decided |
| Error Tracking | Sentry | ✅ Recommended + Decided |
| Logging | GCP Cloud Logging + Cloud Monitoring | ✅ Recommended + Decided |
| CI/CD | GitHub Actions + GCP Cloud Build + Cloud Deploy | ✅ Recommended + Decided |
| Secrets | GCP Secret Manager | ✅ Recommended + Decided |
| Feature Flags | Firebase Remote Config | ✅ Recommended + Decided |
| Web Scraping | Scrapy + Playwright on Cloud Run | ✅ Recommended + Decided |
| SMS / OTP | Twilio | ✅ Recommended + Decided |
| Testing | Pytest + Flutter Test + Playwright E2E | ✅ Recommended + Decided |

---

## Analytics Stack — Full Specification

KloudShop's analytics architecture is a four-layer GCP-native stack. Every layer is
pass-through billable, every layer is native to the platform (Feature Catalogue, not
a third-party app), and together they give merchants intelligence that no Shopify app
bundle can match.

---

### Layer 1 — GCP BigQuery (Commerce Data Warehouse)

**Role:** Central analytics data warehouse. Every commerce event across all tenants
streams here in near real-time via Cloud Pub/Sub → BigQuery Streaming Inserts.

**What flows into BigQuery:**

| Event Category | Events Captured |
|---------------|----------------|
| **Storefront behaviour** | Product views, search queries, category browsing, time-on-page, bounce, scroll depth |
| **Purchase funnel** | Add-to-cart, checkout initiated, checkout abandoned, coupon applied, payment attempted, order placed |
| **Order & revenue** | Order value, items, discounts, payment method, fulfilment status, returns, refunds |
| **B2B activity** | Quote requests, approval workflow events, net-terms invoice issued/paid, buyer account logins |
| **Inventory** | Stock level changes, reorder events, supplier lead times, SKU velocity, variant performance |
| **Customer behaviour** | New vs. returning, cohort entry, LTV progression, RFM signals, churn indicators |
| **AI layer usage** | Consultative AI queries, RAG response quality ratings, conversion from AI-assisted sessions |
| **Platform usage** | Feature Catalogue toggles, theme switches, migration engine events, admin session activity |

**Why BigQuery:** Serverless, petabyte-scale, SQL-native, zero infrastructure management.
Integrates natively with Looker Studio, Vertex AI, and BigQuery ML. Every byte stored and
every query run is a GCP resource — pass-through billable to the merchant's monthly
infrastructure invoice. As merchant data volumes grow, their analytics capability grows
automatically without any platform change.

**Multi-tenancy:** All events tagged with `tenant_id`. Row-level security policies enforce
strict tenant data isolation — no merchant ever queries another merchant's data.

---

### Layer 2 — Native Flutter Analytics Dashboards (Core KPI Layer)

**Role:** The primary merchant-facing analytics surface inside the KloudShop admin.
Fast, opinionated, mobile-responsive. Powered by BigQuery queries served via FastAPI.

**Dashboard modules (native, toggleable via Feature Catalogue):**

| Dashboard | Key Metrics | Refresh Rate |
|-----------|------------|--------------|
| **Store Overview** | GMV today/MTD/YTD, orders, AOV, conversion rate, revenue by channel (DTC vs B2B) | Real-time (15s) |
| **Product Performance** | Top/bottom SKUs by revenue and units, variant-level performance, views-to-purchase rate | Hourly |
| **Customer Intelligence** | New vs. returning split, LTV distribution, RFM segments, top customers by spend, churn risk cohort | Daily |
| **Purchase History** | Full order timeline per customer, repeat purchase rate, basket composition trends | On-demand |
| **Inventory & Stock** | Current stock levels by SKU, days-of-stock remaining, velocity ranking, dead stock identification | Real-time |
| **B2B Activity** (B2B/Hybrid tiers) | Top buyer accounts by spend, pending approvals, net-terms receivables ageing, quote conversion rate | Hourly |
| **Hybrid Cross-Channel** (Hybrid tier) | DTC vs B2B revenue split, customers who buy both channels, unified margin view | Daily |

**Delivery:** Flutter charts library (`fl_chart`) for native rendering across web, iOS,
and Android. All chart data fetched from a dedicated FastAPI `/analytics` service that
queries BigQuery via the BigQuery client library with per-tenant row-level security enforced.

---

### Layer 3 — Looker Studio Embedded (Deep Ad-Hoc Exploration)

**Role:** Deep-dive, self-serve BI for merchants who want to go beyond the native
dashboards — custom date ranges, cross-dimensional slicing, export to CSV/Sheets,
scheduled email reports. Embedded directly inside the KloudShop admin via Looker
Studio's iframe embedding API.

**Why Looker Studio, not a custom solution:** Google Looker Studio connects to BigQuery
natively at zero additional cost (both are GCP products). For a solo AI founder team,
building custom ad-hoc query interfaces would consume months of engineering. Looker Studio
gives merchants a full BI tool on day one with zero build time, zero additional vendor
cost, and full GCP pass-through billing for the underlying BigQuery queries it runs.

**Pre-built Looker Studio report templates provided by KloudShop:**
- Revenue & Conversion Deep Dive
- Customer Cohort & LTV Analysis
- Product & Inventory Intelligence
- B2B Buyer Account Performance
- Marketing Attribution (UTM-based)
- SEO & Organic Traffic Performance

Merchants can customise these templates freely or build their own. KloudShop manages
the BigQuery dataset access credentials — merchants never touch raw GCP infrastructure.

---

### Layer 4 — Vertex AI Forecasting + BigQuery ML (Predictive Intelligence)

**Role:** The layer that makes KloudShop feel like every merchant has a data scientist
on staff. Predictive models trained per tenant on their own historical sales data.
Delivered as native toggleable features in the Feature Catalogue.

**Predictive capabilities at MVP:**

| Feature | Model Type | Input Signals | Output |
|---------|-----------|--------------|--------|
| **Demand Forecasting** | Vertex AI AutoML Forecasting (time series) | 90-day sales history, seasonality, promotions, variant-level velocity | Predicted units sold per SKU for next 7/14/30 days |
| **Stock Replenishment Alerts** | BigQuery ML + rule engine | Demand forecast + current stock level + supplier lead time | Automated reorder trigger with recommended order quantity |
| **Stockout Risk Scoring** | BigQuery ML classification | Velocity trend + days-of-stock + forecast demand | Risk score (High/Medium/Low) per SKU with days-to-stockout estimate |
| **Dead Stock Identification** | BigQuery ML + velocity threshold | SKU age, sales velocity decline, markdown history | List of SKUs at dead stock risk with recommended markdown price |
| **Customer Churn Prediction** | Vertex AI AutoML Classification | RFM signals, purchase frequency decline, session drop-off | Churn risk score per customer with recommended re-engagement action |
| **B2B Reorder Prediction** | BigQuery ML regression | Buyer account order cadence, seasonal patterns, account-level velocity | Predicted next reorder date per buyer account |

**Training cadence:** Models retrained weekly per tenant via Cloud Tasks scheduled jobs.
New merchants enter a 30-day data collection period before forecasting activates —
insufficient training data produces misleading forecasts and that is worse than no forecast.

**Delivery:** Forecast outputs written back to BigQuery. Surfaced in the native Flutter
dashboards (stock replenishment panel, customer health panel) and as push notifications
via FCM (e.g., "SKU #1042 has 3 days of stock remaining — reorder 500 units based on
your current sales velocity").

---

### Layer 5 — PostHog (User & Product Analytics + A/B Testing)

**Role:** Platform-level product intelligence — not merchant commerce data, but
KloudShop's own understanding of how merchants use the admin, which Feature Catalogue
toggles get activated, where onboarding drops off, and what drives upgrade decisions.
Critical for a solo founder team making feature prioritisation and roadmap decisions
with data, not instinct.

**Why PostHog, not Firebase Analytics alone:**
Firebase Analytics covers mobile event tracking well but has limited funnel analysis,
no session recording, and no built-in A/B testing framework. PostHog is the modern
open-source product analytics platform that covers all of these in one tool:

| Capability | PostHog Feature | KloudShop Use Case |
|-----------|----------------|-------------------|
| **Funnels** | Funnel analysis | Migration engine drop-off analysis — where do merchants abandon the 2-minute onboarding? |
| **Session recording** | Session replay | Watch real merchant sessions to identify UX friction in admin flows |
| **Feature adoption** | Event tracking | Which Feature Catalogue items get toggled on? Which are ignored? Feeds the Feature Request Channel prioritisation. |
| **A/B testing** | Experiments (works alongside Firebase Remote Config) | Test onboarding flows, dashboard layouts, upgrade prompt copy |
| **Retention analysis** | Retention curves | Are merchants who activate 3+ Feature Catalogue items churning less? |
| **User paths** | Path analysis | What do merchants do in the first 7 days? Does it predict 30-day retention? |

**Deployment:** PostHog Cloud (managed SaaS) for MVP — zero infrastructure overhead.
Migrate to self-hosted PostHog on GCP Cloud Run post-PMF if data sovereignty or cost
becomes a concern. Flutter PostHog SDK for mobile. PostHog JS SDK for Flutter Web.

**Firebase Analytics (retained alongside PostHog):** Used specifically for mobile app
store performance metrics (crash-free sessions, app launch time, ANR rate) that
integrate with Google Play Console and Apple App Store Connect. PostHog and Firebase
Analytics are complementary, not redundant.

---

## Updated Stack Summary (Analytics Added)

| Layer | Tool | Purpose | Billing |
|-------|------|---------|---------|
| Commerce Data Warehouse | GCP BigQuery | All commerce events, central analytics store | GCP pass-through |
| Native KPI Dashboards | Flutter + FastAPI + BigQuery | Merchant-facing core metrics in admin | Included in subscription |
| Deep Ad-Hoc BI | Looker Studio (embedded) | Self-serve exploration, custom reports, exports | GCP pass-through (BigQuery queries) |
| Predictive Intelligence | Vertex AI AutoML + BigQuery ML | Demand forecasting, replenishment, churn prediction | GCP pass-through |
| Product / UX Analytics | PostHog | KloudShop internal feature adoption, funnels, A/B testing, session replay | PostHog Cloud (KloudShop cost, not merchant) |
| Mobile App Telemetry | Firebase Analytics | App store performance, crash tracking, mobile events | GCP pass-through |

---

## Analytics Stack (Addendum)

KloudShop's analytics architecture is a three-layer stack — all GCP-native, all
pass-through billable where applicable, and all delivered as native platform
capabilities (Feature Catalogue). No merchant ever pays extra for analytics.
No third-party analytics app. Ever.

---

### Layer 1 — GCP BigQuery (Commerce Data Warehouse)

**Role:** The central analytics backbone. Every commerce event across all tenants
streams into BigQuery via Cloud Pub/Sub in near real-time. BigQuery is serverless,
petabyte-scale, SQL-native, and the single source of truth for all downstream
analytics, BI, and ML workloads.

**What streams into BigQuery:**
| Event Category | Examples |
|---------------|---------|
| Storefront behaviour | Product views, search queries, collection browsing, time on page |
| Cart & checkout | Add-to-cart, cart abandonment, checkout funnel drop-off, coupon usage |
| Orders & revenue | Order placed, order value, items per order, payment method, fulfilment status |
| Customer behaviour | New vs. returning, cohort assignment, lifetime value, purchase frequency |
| B2B activity | Quote requests, approval workflow events, net-terms usage, buyer account logins |
| Inventory events | Stock level changes, restock events, low-stock triggers, variant depletion rates |
| AI layer interactions | Consultative AI queries, RAG responses, conversion attributed to AI assist |
| Platform usage | Feature Catalogue toggles, theme switches, migration engine events |

**Billing:** BigQuery storage and query costs are GCP resources — pass-through billable
to merchants at actual GCP cost × 1.15 (fixed 15% KloudShop markup). As merchant data grows, they pay only
for what they use.

---

### Layer 2A — Native Flutter Analytics Dashboards (Core KPIs)

**Role:** The primary merchant analytics surface inside the KloudShop admin. Built in
Flutter Web, powered by BigQuery queries via FastAPI. Covers the metrics every merchant
checks daily without needing to open a separate BI tool.

**Native Flutter dashboard modules:**
| Dashboard | Key Metrics |
|-----------|------------|
| **Revenue Overview** | GMV, orders, AOV, revenue by channel (DTC vs B2B), MoM/YoY trends |
| **Product Performance** | Top products by revenue/units, slow movers, variant performance, return rate |
| **Customer Analytics** | New vs. returning customers, cohort retention, CLV, purchase frequency |
| **Purchase History** | Order timeline, repeat purchase patterns, basket analysis |
| **Inventory Intelligence** | Current stock levels, stock velocity by SKU, days-of-stock remaining |
| **B2B Buyer Activity** | Active buyer accounts, top accounts by GMV, approval workflow metrics |
| **AI Layer Performance** | Consultative AI query volume, topics queried, conversion lift attributed |
| **Storefront Funnel** | Sessions → PDP views → Add-to-cart → Checkout → Purchase conversion |

---

### Layer 2B — Embedded Looker Studio (Deep Ad-Hoc Exploration)

**Role:** Google's native BI tool, embedded directly inside the KloudShop admin as an
iframe panel. Connects natively to BigQuery at zero additional licence cost. Gives
power-user merchants — CFOs, operations managers, head buyers — the ability to build
custom reports, cross-filter dimensions, and export data without leaving KloudShop.

**Why Looker Studio over custom charts for deep exploration:**
Building a fully custom ad-hoc query builder in Flutter would take months. Looker
Studio is production-grade, BigQuery-native, and free. The merchant sees a seamless
embedded experience inside KloudShop; under the hood it is Looker Studio scoped to
their BigQuery dataset. Zero vendor cost, zero build cost for advanced exploration.

**Pre-built Looker Studio report templates provided by KloudShop:**
- Sales performance deep-dive
- Customer cohort analysis
- Inventory and supply chain overview
- B2B account performance
- Marketing channel attribution

Merchants can clone, customise, and save their own reports. All data stays within
their BigQuery tenant partition — no cross-tenant data leakage.

---

### Layer 3 — Vertex AI Forecasting + BigQuery ML (Predictive Intelligence)

**Role:** The intelligence layer that makes KloudShop feel like every merchant has
a data scientist on staff. Fully integrated, native, and toggleable from the Feature
Catalogue. This is a core product differentiator — not a post-MVP addition.

**Capabilities:**

#### Stock Replenishment & Demand Forecasting
- **Model:** Vertex AI Forecasting (AutoML Time Series) trained per-tenant on each
  merchant's own sales velocity, seasonal patterns, and promotional history.
- **Output:** Per-SKU reorder point recommendations, predicted days-of-stock-remaining,
  suggested order quantities, and supplier lead time modelling.
- **Trigger:** Automated reorder alerts surfaced in the native Flutter inventory
  dashboard. Merchants can set "auto-alert" or "auto-draft purchase order" modes.
- **Training cadence:** Model retrained weekly per tenant using BigQuery ML pipeline
  triggered by Cloud Tasks. New merchants begin with rule-based thresholds until
  sufficient sales history (90 days / 100+ orders) exists to train a reliable model.

#### Product Demand Signals
- **What it does:** Identifies rising-demand products before stockouts occur, flags
  slow-moving inventory at risk of deadstock, and surfaces seasonal demand shifts.
- **Powered by:** BigQuery ML ARIMA_PLUS models on product view + sales velocity data.

#### Customer Purchase Propensity (B2C + B2B)
- **What it does:** Scores each customer's likelihood to repurchase within 30/60/90
  days. Surfaces "at-risk of churn" high-value customers. Flags B2B accounts
  showing reduced order frequency.
- **Powered by:** BigQuery ML logistic regression on purchase history + session
  behaviour cohorts.

#### Cross-Sell & Upsell Recommendations
- **What it does:** Generates "frequently bought together" and "customers like you
  also bought" signals from co-purchase patterns in BigQuery — feeding both the
  native Bundle Builder feature and the Consultative AI layer's recommendations.
- **Powered by:** BigQuery ML matrix factorisation on order line-item co-occurrence.

---

### Layer 4 — User & Product Analytics (Platform Instrumentation)

**Role:** Internal KloudShop instrumentation — not merchant-facing. Used by the
KloudShop team (founder + AI agents) to understand platform usage, guide feature
prioritisation, measure A/B tests, and track Flutter app performance.

**Recommendation: PostHog (self-hosted on GCP Cloud Run) + Firebase Analytics**

**PostHog (self-hosted):**
- **Why PostHog:** Open-source, self-hostable on Cloud Run, and the only product
  analytics tool that combines event tracking, session recording, feature flags,
  A/B testing, funnel analysis, and user path analysis in a single platform.
  Self-hosting keeps all platform behavioural data within GCP — no data leaves
  the KloudShop infrastructure boundary, which matters for GDPR compliance.
- **What it tracks:** Feature Catalogue toggle rates, migration engine funnel,
  merchant admin UI engagement, tier upgrade conversion paths, Feature Request
  Channel voting behaviour, onboarding completion rates.
- **A/B testing:** PostHog Experiments powers feature flag-based A/B tests for
  new Feature Catalogue items, onboarding flow variants, and storefront UI changes
  — with statistical significance built in.

**Firebase Analytics:**
- **Why Firebase Analytics alongside PostHog:** Firebase Analytics is natively
  integrated into Flutter iOS and Android apps (zero SDK overhead). Tracks mobile
  app screen views, user sessions, crash-free session rates, and retention cohorts.
  Feeds directly into Google Analytics 4 for cross-platform attribution.
- **What it tracks:** Mobile app DAU/MAU, push notification open rates (via FCM
  integration), mobile-specific merchant workflows, and app store performance
  correlation.

**Division of responsibility:**
| Tool | Primary Use |
|------|------------|
| PostHog (self-hosted) | Web admin instrumentation, A/B testing, feature flag experiments, session recording, funnel analysis |
| Firebase Analytics | Flutter iOS + Android app usage, mobile retention, crash-free rates |
| BigQuery | Both PostHog and Firebase export to BigQuery — unified in a single internal analytics dataset |

---

### Updated Stack Summary — Analytics Layer Added

| Layer | Tool | Status |
|-------|------|--------|
| Commerce data warehouse | GCP BigQuery | ✅ Added |
| Core KPI dashboards | Native Flutter (BigQuery-powered via FastAPI) | ✅ Added |
| Deep ad-hoc BI | Embedded Looker Studio (BigQuery-native) | ✅ Added |
| Demand forecasting + stock replenishment | Vertex AI Forecasting + BigQuery ML | ✅ Added |
| Customer propensity + cross-sell signals | BigQuery ML (ARIMA_PLUS, logistic regression, matrix factorisation) | ✅ Added |
| Platform product analytics + A/B testing | PostHog (self-hosted on GCP Cloud Run) | ✅ Added |
| Mobile app analytics | Firebase Analytics → BigQuery | ✅ Added |

---

## Scale Architecture — MVP to Shopify-Scale Upgrade Path

### Context: What Shopify-Scale Actually Means

| Metric | Shopify BFCM 2024 | KloudShop MVP Target | KloudShop 3-Year Target |
|--------|-------------------|---------------------|------------------------|
| Database queries | 10.5 trillion over the weekend | ~50M/day across all tenants | ~500B over a peak weekend |
| Edge requests | 284 million/minute peak | ~500K/minute peak | ~50M/minute peak |
| Sales throughput | $5.1M/minute peak | $50K/minute peak | $2M/minute peak |
| Active tenants | 1M+ merchants | 250–1,500 merchants | 50,000+ merchants |

**The architectural principle:** Every MVP tool is chosen so that the upgrade to the
next scale tier requires infrastructure changes only — never application rewrites.
The FastAPI service code, Dart/Flutter frontend code, and data models remain stable
across all scale tiers. Only the infrastructure layer beneath them is swapped.

---

### Layer-by-Layer: MVP Stack + Explicit Shopify-Scale Upgrade Path

---

#### 1. Container Orchestration

| Stage | Tool | Trigger to Upgrade | What Changes |
|-------|------|--------------------|-------------|
| **MVP** | GCP Cloud Run | Default — serverless, zero ops, auto-scales to thousands of instances on demand. Handles BFCM-style traffic spikes without pre-provisioning. Pass-through billable. | Nothing to manage. Deploy Docker containers, Cloud Run handles the rest. |
| **Growth** | Cloud Run + Cloud Run Jobs | >500 concurrent merchants during peak events | Add Cloud Run Jobs for heavy batch workloads (CSV imports, billing reconciliation, sitemap generation) to isolate them from API traffic. |
| **Shopify-Scale** | GKE Autopilot (Google Kubernetes Engine) | Sustained >10,000 req/sec per service, need fine-grained traffic shaping, sidecar patterns, or service mesh | Same Docker containers, same Dockerfiles — GKE Autopilot manages nodes automatically. Zero node ops. Enables horizontal pod autoscaling, Istio service mesh, and multi-region traffic routing. No application code changes required. |

**Staff Engineer's call:** Do not move to GKE before you need it. Cloud Run's 1,000
concurrent instances per service default (raiseable to 10,000 on request) handles
tens of millions of requests per minute. GKE Autopilot is the upgrade, not the start.

---

#### 2. Database Layer

**My recommendation: Cloud SQL → AlloyDB → Cloud Spanner. Defended below.**

| Stage | Tool | Trigger to Upgrade | Why This Tool |
|-------|------|--------------------|--------------|
| **MVP** | GCP Cloud SQL PostgreSQL (Enterprise Plus) | Default — up to 96 vCPUs, 624GB RAM, 64TB storage. Handles ~500K transactions/sec. Read replicas for analytics query isolation. PgBouncer connection pooler on Cloud Run sidecars. | Managed, GCP-native, pass-through billable. Full PostgreSQL compatibility — pgvector, FTS, JSONB. Zero migration cost at this stage. |
| **Growth** | GCP AlloyDB for PostgreSQL | >80% Cloud SQL CPU sustained, or >100K active tenant connections, or read replica lag >1 second during peak | AlloyDB is 4x faster on reads and 2x faster on writes than Cloud SQL. 99.99% SLA. Built-in columnar engine for analytics queries (eliminates BigQuery round-trips for real-time dashboards). **Critically: 100% PostgreSQL wire-compatible.** FastAPI + SQLAlchemy connection string changes. Zero application code changes. |
| **Shopify-Scale** | GCP Cloud Spanner + AlloyDB (hybrid) | >1 billion transactions/day sustained, global multi-region requirements, or AlloyDB single-region ceiling hit | Cloud Spanner is the only externally available database proven at Google's own transaction scale. Horizontally shards automatically, globally distributed, 99.999% SLA. Spanner dialect is close to but not identical to PostgreSQL — GCP provides a PostgreSQL interface adapter that handles most query compatibility. AlloyDB retained for transactional workloads; Spanner handles global catalog, session, and inventory state. |

**Why not Vitess:** Vitess is a sharding middleware built to rescue MySQL from a scale
ceiling it was never designed to cross. KloudShop is on PostgreSQL with a clean GCP
upgrade path to AlloyDB and Spanner. Introducing Vitess would add operational complexity
(Kubernetes-native, requires dedicated ops expertise) that GCP's managed services
eliminate entirely. Vitess is the right answer if you're trapped on MySQL. We are not.

**Connection pooling at every stage:** PgBouncer deployed as a Cloud Run sidecar
handles connection multiplexing from day one. This alone extends Cloud SQL's effective
capacity by 10x before any database upgrade is needed.

---

#### 3. Message Queue / Event Streaming

| Stage | Tool | Trigger to Upgrade | Notes |
|-------|------|--------------------|-------|
| **MVP → Shopify-Scale** | GCP Cloud Pub/Sub | No upgrade needed — Pub/Sub scales to 10M+ messages/second globally, managed, zero ops | Pub/Sub is not a bottleneck at any scale KloudShop will realistically reach. It is Google's own internal event backbone. |
| **If needed post-PMF** | GCP Dataflow (stream processing) | Complex stream transformations needed — e.g., real-time fraud scoring, multi-step event enrichment pipelines | Dataflow sits on top of Pub/Sub and adds Apache Beam-based stream processing. Not needed at MVP. |

**On Kafka specifically:** Kafka is not recommended at any stage for KloudShop.
Kafka requires cluster management, partition tuning, and dedicated ops expertise.
Cloud Pub/Sub delivers identical throughput with zero ops overhead and is pass-through
billable. The only scenario where Kafka wins over Pub/Sub is sub-10ms latency with
indefinite log compaction and replay — KloudShop does not have this requirement.

---

#### 4. Caching Layer

| Stage | Tool | Trigger to Upgrade | Notes |
|-------|------|--------------------|-------|
| **MVP** | GCP Memorystore for Redis — Basic tier (single node) | Default | Handles session data, product catalog cache, rate limiting, B2B price list cache. |
| **Growth** | GCP Memorystore for Redis — Standard tier (HA + replica) | >500 active merchants or cache miss rate >15% during peak | Standard tier adds automatic failover, read replica, and 99.9% SLA. One config change. |
| **Shopify-Scale** | GCP Memorystore for Redis Cluster | >50,000 active merchants, >1TB cached data, or single-node throughput ceiling hit | Redis Cluster shards data horizontally across nodes. GCP-managed. Same Redis API — zero application code changes. |

---

#### 5. CDN & Edge Layer

| Stage | Tool | Trigger to Upgrade | Notes |
|-------|------|--------------------|-------|
| **MVP** | GCP Cloud CDN | Default — global edge caching for storefront assets, product images, theme files. Integrated with Cloud Run and Cloud Storage. | Cache product pages at edge. TTL: 15 min for product pages, 24hr for images, 1hr for theme assets. |
| **Growth** | GCP Cloud CDN + GCP Media CDN | Storefront image/video delivery becomes a bottleneck or >1PB monthly egress | Media CDN is Google's YouTube-grade delivery network. Built for high-throughput media at global scale. Incrementally adoptable alongside Cloud CDN. |
| **Shopify-Scale** | GCP Global External Application Load Balancer + Cloud CDN + Media CDN | Full multi-region active-active deployment | Global Load Balancer routes traffic to nearest healthy Cloud Run or GKE region. Anycast IP ensures sub-20ms edge latency globally. This is the same infrastructure Google serves Search on. |

---

#### 6. Per-Tenant Resource Metering (The Pass-Through Billing Engine)

This is a KloudShop-specific requirement that no standard tool handles out of the box.
Here is the exact architecture — no third-party metering tool needed.

**How it works end-to-end:**

```
GCP Resource Usage
(Cloud Run, Cloud SQL, Vertex AI,
 Pub/Sub, Storage, CDN egress)
         │
         ▼
  GCP Resource Labels
  (tenant_id: "merchant_xyz"
   applied at provisioning time
   to every billable GCP resource)
         │
         ▼
  GCP Billing Export
  (streams labelled cost data
   to BigQuery in real time —
   native GCP feature, free)
         │
         ▼
  BigQuery: kloudshop_billing dataset
  (per-tenant, per-resource,
   per-hour cost records)
         │
         ▼
  Billing Service (FastAPI module)
  triggered by Cloud Tasks on
  monthly cycle per tenant:
  1. Query BigQuery for tenant's
     GCP costs this cycle
  2. Apply fixed 15% KloudShop markup
     (merchant_bill = gcp_actual_cost × 1.15)
  3. Fire Stripe metered billing
     usage event per resource type
         │
         ▼
  Stripe Billing
  (generates single monthly invoice:
   flat subscription + itemised
   GCP usage line items)
         │
         ▼
  Merchant receives one clean invoice
```

**Labelling strategy — critical to get right from day one:**

| GCP Resource | Label Applied | Granularity |
|-------------|--------------|-------------|
| Cloud Run services | `tenant_id`, `service_name` | Per request (via Cloud Trace) |
| Cloud SQL | `tenant_id`, `database_schema` | Per query group (schema-per-tenant) |
| Cloud Storage | `tenant_id`, `bucket_path` | Per object prefix |
| Vertex AI inference | `tenant_id`, `model_id` | Per inference call |
| Cloud Pub/Sub | `tenant_id`, `topic_name` | Per message batch |
| Cloud CDN egress | `tenant_id`, `storefront_domain` | Per GB egress |
| Memorystore Redis | Shared pool — apportioned by request weight | Estimated, not exact |

**Redis metering note:** Redis is a shared pool and GCP does not label per-tenant
Redis operations. Apportion Redis costs by tenant request volume ratio (tenant
requests / total requests in billing period × total Redis cost). This is a close
approximation, not exact — document this clearly in merchant billing FAQs.

---

#### 7. Search at Scale

| Stage | Tool | Trigger to Upgrade | Notes |
|-------|------|--------------------|-------|
| **MVP** | PostgreSQL FTS + pgvector | Default — handles catalogs up to ~500K SKUs across all tenants | Sufficient for launch and early growth. |
| **Growth** | AlloyDB columnar engine + pgvector | >500K total SKUs or search latency >200ms p95 | AlloyDB's built-in columnar engine dramatically accelerates analytical + vector queries without a separate search service. |
| **Shopify-Scale** | GCP Vertex AI Search (formerly Retail Search) | >10M SKUs across platform, or semantic search quality needs to exceed pgvector | Vertex AI Search is Google's own product search engine — the same engine powering Google Shopping. Natively integrates with Vertex AI embeddings. Pass-through billable. |

---

### Scale Architecture Summary

| Layer | MVP | Growth Trigger | Shopify-Scale |
|-------|-----|---------------|---------------|
| Containers | Cloud Run | >10K req/sec per service | GKE Autopilot |
| Database | Cloud SQL PostgreSQL | >80% CPU sustained | AlloyDB → Cloud Spanner |
| Message Queue | Cloud Pub/Sub | No upgrade needed | Cloud Pub/Sub + Dataflow |
| Caching | Memorystore Redis Basic | >500 merchants | Memorystore Redis Cluster |
| CDN / Edge | Cloud CDN | >1PB/mo egress | Media CDN + Global LB |
| Search | PostgreSQL FTS + pgvector | >500K SKUs | Vertex AI Search |
| Resource Metering | GCP Labels + BigQuery Export + Billing Service | No upgrade needed | Same architecture, larger BigQuery dataset |

**The north star principle:** Every upgrade in this table is a GCP infrastructure
configuration change. Not a single one requires rewriting FastAPI service code,
Flutter UI code, or the data model. The application layer is scale-agnostic by design.

---

## Feature-Gated Schema Migration Architecture

### The Problem This Solves

KloudShop's Feature Catalogue means the database schema is not static and uniform
across all tenants. When a merchant enables "Customer Loyalty Programme", their
tenant schema needs the `loyalty_points`, `reward_tiers`, and `redemption_events`
tables. A merchant who never enables it must never have those tables created, billed
for, or touched. When a merchant later enables "Bidding / Auction Pricing", that
feature may depend on schema introduced by "Advanced Pricing Rules" — even if the
merchant never explicitly turned on Advanced Pricing Rules. The system must resolve
that dependency chain silently and safely before activating the requested feature.

This requires four distinct capabilities working together: a migration tool, a
dependency graph, a per-tenant migration runner, and a non-destructive schema policy.

---

### Tool Decisions

| Capability | Tool | Rationale |
|-----------|------|-----------|
| Migration authoring + versioning | **Alembic** | Python-native, FastAPI/SQLAlchemy standard. Generates versioned, reproducible migration scripts. Supports branching and dependency chains natively via `down_revision` chains. |
| Feature dependency graph | **PostgreSQL table: `feature_dependency_graph`** | Stored in the platform's own Cloud SQL instance (not tenant schemas). Maps every feature to its required migrations and its upstream feature dependencies. Queried by the migration runner at feature activation time. |
| Per-tenant migration state | **PostgreSQL table: `tenant_migration_state`** | Tracks exactly which Alembic migration versions have been applied to each tenant schema. The migration runner consults this before applying anything. |
| Migration execution + orchestration | **Custom FastAPI Migration Service on Cloud Run** | A dedicated internal microservice responsible for resolving dependency chains, sequencing migrations, and applying them per-tenant. Triggered by Cloud Tasks — never inline during a web request. |
| Multi-region propagation | **GCP Cloud SQL read replicas + Cloud Tasks fan-out** | The migration service writes to the primary Cloud SQL instance. Replication propagates to read replicas automatically. Cloud Tasks fan-out handles multi-region primary instances if regional isolation is required post-MVP. |
| Non-destructive policy enforcement | **Alembic custom `MigrationLinter` + CI gate** | A custom linting step in GitHub Actions CI rejects any migration script containing `DROP TABLE`, `DROP COLUMN`, `ALTER COLUMN` (type change), or `TRUNCATE`. Only additive operations pass CI. |

---

### Feature Dependency Graph — Data Model

```sql
-- Platform-level table (not per-tenant)
-- Lives in the KloudShop admin Cloud SQL instance

CREATE TABLE feature_registry (
    feature_id          VARCHAR(64) PRIMARY KEY,  -- e.g. 'loyalty_programme'
    display_name        TEXT NOT NULL,
    tier_required       VARCHAR(16) NOT NULL,      -- 'DTC', 'B2B', 'HYBRID'
    status              VARCHAR(16) NOT NULL,       -- 'stable', 'beta', 'deprecated'
    has_config          BOOLEAN DEFAULT FALSE,      -- TRUE if feature requires setup wizard
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Every feature can declare any number of typed configuration parameters.
-- There is no hardcoded limit on how many parameters a feature has, nor
-- any assumption about what types they are. Some features have zero config
-- parameters (e.g. a simple toggle feature). Others have many (loyalty programme).
-- This table is the schema definition — what parameters exist for a feature.
CREATE TABLE feature_config_schema (
    config_key          VARCHAR(128) NOT NULL,      -- e.g. 'points_per_dollar'
    feature_id          VARCHAR(64) REFERENCES feature_registry(feature_id),
    display_label       TEXT NOT NULL,              -- human-readable label for setup wizard UI
    description         TEXT,                       -- helper text shown in setup wizard
    data_type           VARCHAR(16) NOT NULL,
    -- ENUM: 'string' | 'text' | 'integer' | 'float' | 'boolean' | 'date' | 'time' | 'datetime' | 'json_array' | 'json_object'
    -- string: single-line text input (URLs, emails, short labels, hex colours)
    -- text: multi-line text input (email templates, terms copy, long descriptions)
    -- integer: whole numbers (points, quantities, thresholds)
    -- float: decimal numbers (percentages, prices, rates)
    -- boolean: yes/no toggle
    -- date: calendar date without time — renders date picker (e.g. 2026-06-01)
    -- time: time without date — renders time picker HH:MM (e.g. 09:00)
    -- datetime: date + time combined — renders datetime picker (e.g. flash sale start)
    -- json_array: ordered list of values (delivery days, frequencies, tier configs)
    -- json_object: key-value map or structured object (country→rate overrides, complex configs)
    default_value       TEXT,                       -- stored as string, cast on read per data_type
    is_required         BOOLEAN DEFAULT FALSE,      -- must be set before feature is operational
    validation_rules    JSONB,
    -- Examples of validation_rules:
    -- integer: {"min": 1, "max": 1000}
    -- float:   {"min": 0.01, "max": 1.0}
    -- string:  {"max_length": 255, "allowed_values": ["standard", "express", "overnight"]}
    -- time:    {"format": "HH:MM"}
    -- json_array: {"item_type": "string", "allowed_values": ["monday","tuesday",...]}
    display_order       INTEGER NOT NULL DEFAULT 0, -- order in setup wizard
    wizard_group        VARCHAR(64),                -- groups params into wizard steps
    PRIMARY KEY (config_key, feature_id)
);

-- Per-tenant values for each feature's configuration parameters.
-- Populated by the merchant during the setup wizard (Phase 2 of feature activation).
-- One row per config_key per tenant — sparse by design (only keys the merchant
-- has explicitly configured are present; absent keys fall back to default_value).
--
-- IMPORTANT: This table is part of the BASE tenant schema — created by the initial
-- Alembic migration for every new tenant, before any feature is activated.
-- It is NOT a per-feature migration. Feature config values are application DATA,
-- not database schema changes. Alembic never touches this table after creation.
CREATE TABLE tenant_feature_config (
    tenant_id           VARCHAR(64) NOT NULL,       -- matches tenant schema name
    feature_id          VARCHAR(64) REFERENCES feature_registry(feature_id),
    config_key          VARCHAR(128) NOT NULL,
    config_value        TEXT NOT NULL,              -- stored as string, cast on read per data_type
    set_at              TIMESTAMPTZ DEFAULT NOW(),
    set_by              UUID NOT NULL,              -- staff_user_id who saved this value
    PRIMARY KEY (tenant_id, feature_id, config_key)
);

-- SEPARATION OF CONCERNS — CRITICAL DISTINCTION:
--
-- feature_dependencies + Alembic migrations = DATABASE SCHEMA changes
--   Purpose: CREATE TABLE, ADD COLUMN, CREATE INDEX
--   When:    At feature activation time (Phase 1) — Migration Runner Cloud Run Job
--   Example: Loyalty Programme activation creates loyalty_points,
--            reward_tiers, redemption_events tables in tenant schema
--
-- feature_config_schema + tenant_feature_config = APPLICATION DATA
--   Purpose: Store merchant's configuration choices for a feature
--   When:    After schema migration succeeds — setup wizard (Phase 2)
--   Example: Merchant sets points_per_dollar=10, welcome_bonus=100
--            These are INSERT/UPDATE rows in tenant_feature_config
--            No Alembic migration runs. No schema changes. No dependency
--            chain involvement whatsoever.
--
-- Some features use BOTH systems:
--   Loyalty Programme: needs Alembic migrations (creates loyalty tables)
--   AND needs tenant_feature_config rows (points rate, tier config).
--   Ordering is enforced by the activation flow:
--   Phase 1 (schema migration) completes → Phase 2 (config wizard) begins.
--   Config values stored before schema tables exist would be meaningless —
--   the sequential flow makes this architecturally impossible.
--
-- Features with has_config = FALSE and no Alembic migrations (pure toggle
-- features) need neither system — they are operationally live the moment
-- feature_registry marks them ACTIVE.

CREATE TABLE feature_dependencies (
    feature_id          VARCHAR(64) REFERENCES feature_registry(feature_id),
    depends_on          VARCHAR(64) REFERENCES feature_registry(feature_id),
    -- e.g. 'bidding' depends_on 'advanced_pricing_rules'
    -- A feature may have multiple rows here — one per upstream dependency.
    -- e.g. 'advanced_reporting' depends_on 'analytics_base' AND 'customer_segments'
    -- The Migration Runner resolves all rows for a given feature_id into a full
    -- dependency graph and applies Kahn's algorithm (topological sort) to determine
    -- the correct sequential migration order. Circular dependencies are rejected
    -- at CI time by the migration linter — they are a hard build failure.
    PRIMARY KEY (feature_id, depends_on)
);

CREATE TABLE feature_migrations (
    migration_id        VARCHAR(128) PRIMARY KEY, -- Alembic revision ID
    feature_id          VARCHAR(64) REFERENCES feature_registry(feature_id),
    sequence_order      INTEGER NOT NULL,          -- order within feature's migrations
    description         TEXT NOT NULL,
    is_required         BOOLEAN DEFAULT TRUE       -- FALSE = optional schema enhancement
);

-- Per-tenant table (lives in each tenant's schema)
CREATE TABLE tenant_migration_state (
    migration_id        VARCHAR(128) PRIMARY KEY,
    feature_id          VARCHAR(64) NOT NULL,
    applied_at          TIMESTAMPTZ DEFAULT NOW(),
    applied_by          VARCHAR(64) NOT NULL       -- 'system', 'feature_activation', etc.
);
```

---

### Feature Activation Flow — Step by Step

When a merchant toggles on a feature (e.g. "Bidding / Auction Pricing"):

```
Merchant toggles ON "Bidding / Auction Pricing"
                │
                ▼
  Feature Service (FastAPI)
  queries feature_dependencies:
  "bidding" depends_on → "advanced_pricing_rules"
  "advanced_pricing_rules" depends_on → (none)
                │
                ▼
  For each dependency in resolution order:
  Check tenant_migration_state:
  Has "advanced_pricing_rules" migrations been applied?
                │
        ┌───────┴────────┐
       YES               NO
        │                │
        │     Enqueue migration job for
        │     "advanced_pricing_rules"
        │     via Cloud Tasks (silent,
        │     merchant never turned it
        │     on but gets schema safely)
        │                │
        └───────┬────────┘
                ▼
  Enqueue migration job for "bidding"
  migrations via Cloud Tasks
  (sequenced AFTER dependency jobs)
                │
                ▼
  Migration Service (Cloud Run Job)
  applies Alembic migrations in order
  to tenant's PostgreSQL schema
                │
                ▼
  On success: feature marked ACTIVE
  in tenant's feature_registry state.
  Firebase Remote Config flag
  feature_{feature_id}_enabled set TRUE
  for this tenant — Flutter renders
  feature UI; FastAPI unlocks feature
  routes. All feature code is written
  behind these flags from day one:
  schema migration and code activation
  are always atomically in sync.
  Merchant sees feature in their admin.
                │
                ▼
  On failure: migration rolled back,
  feature stays INACTIVE, Remote Config
  flag remains FALSE, Sentry alert
  fired, merchant sees friendly error.
```

---

### Non-Destructive Migration Policy — The Rules

Every schema migration in KloudShop must comply with these rules enforced at CI level.
No exceptions. No manual overrides.

| Rule | What Is Allowed | What Is Forbidden | Why |
|------|----------------|-------------------|-----|
| **Additive only** | `ADD COLUMN`, `CREATE TABLE`, `CREATE INDEX CONCURRENTLY` | `DROP COLUMN`, `DROP TABLE`, `TRUNCATE` | A tenant with the feature disabled must never lose data if they later re-enable it. A tenant who skipped a feature must not have their schema broken by a dependency migration. |
| **No destructive ALTER** | `ADD COLUMN ... DEFAULT`, `ADD CONSTRAINT ... NOT VALID` | `ALTER COLUMN ... TYPE`, `SET NOT NULL` on existing column | Type changes break existing application code reading that column. NOT NULL on existing data causes migration failures mid-flight. |
| **Deprecation cycle, not deletion** | Mark column `deprecated_at`, stop writing to it, keep it for 2 full release cycles | Delete immediately when a feature is removed | Tenants who have not yet run a migration that removes a dependency must not hit missing-column errors. |
| **Concurrent index creation** | `CREATE INDEX CONCURRENTLY` only | `CREATE INDEX` (blocking) | Blocking index creation locks the table. On a multi-tenant schema, this causes downtime for all tenants sharing that Cloud SQL instance. |
| **Backwards-compatible defaults** | New columns must have a DEFAULT value or be nullable | Non-nullable columns with no default | Rows written by old application code before migration runs must remain valid. |

---

### Migration Linter — CI Enforcement

A custom Alembic migration linter runs as a mandatory GitHub Actions CI check on
every pull request that touches a migration file. It statically analyses the migration
script and fails the build if any forbidden operation is detected.

```python
# Simplified linter logic — runs in GitHub Actions CI
FORBIDDEN_PATTERNS = [
    r'op\.drop_table',
    r'op\.drop_column',
    r'op\.alter_column.*type_',  # type changes
    r'op\.execute.*TRUNCATE',
    r'CREATE INDEX(?! CONCURRENTLY)',  # blocking index
]

def lint_migration(migration_file: str) -> list[str]:
    violations = []
    content = open(migration_file).read()
    for pattern in FORBIDDEN_PATTERNS:
        if re.search(pattern, content):
            violations.append(f"FORBIDDEN: {pattern} detected in {migration_file}")
    return violations
```

CI pipeline: lint passes → unit tests → staging migration dry-run → merge allowed.

---

### Multi-Region Migration Propagation

At MVP, KloudShop runs a single Cloud SQL primary instance (US region) with read
replicas. Schema migrations are applied to the primary and replicated automatically.

At scale (post-PMF, multi-region active-active):

```
Cloud Tasks: Migration Job Enqueued
                │
                ▼
  Migration Service queries:
  which Cloud SQL primary instances
  exist for this tenant's region?
  (stored in tenant_config table)
                │
          ┌─────┴──────┐
          ▼            ▼
    US-CENTRAL    EU-WEST
    Primary       Primary
    Cloud SQL     Cloud SQL
          │            │
          ▼            ▼
    Applied via   Applied via
    Alembic       Alembic
    (idempotent)  (idempotent)
```

**Idempotency is guaranteed:** Alembic tracks applied migrations in its own
`alembic_version` table within each schema. Re-running a migration that has
already been applied is a no-op. This means Cloud Tasks can safely retry
a failed migration job without risk of double-application.

---

### Concrete Examples from the Product Brief

| Feature Request | Schema Dependencies | Dependency Chain Resolution |
|----------------|--------------------|-----------------------------|
| **Customer Loyalty Programme** | New tables: `loyalty_accounts`, `point_transactions`, `reward_tiers`, `redemption_events` | No upstream dependencies. Standalone activation. |
| **Bidding / Auction Pricing** | New tables: `auction_listings`, `bid_events`, `auction_results`. Requires `advanced_pricing_rules` schema (price rule engine tables). | System silently applies `advanced_pricing_rules` migrations first even if merchant never turned on that feature, then applies `bidding` migrations. Merchant only sees "Bidding" in their Feature Catalogue. |
| **User Feedback Upvoting / Downvoting** | Extends existing `product_reviews` table: adds `vote_type` column, new table `review_votes`, new table `vote_aggregates`. | Depends on base "Product Reviews" feature. If reviews not enabled, system enables reviews schema silently first, then applies voting schema. |
| **Subscription / Recurring Orders** | New tables: `subscription_plans`, `subscription_orders`, `billing_cycles`. Extends `orders` table with `subscription_id FK`. | `orders` table already exists in base schema (always present). New FK column is additive — nullable, with DEFAULT NULL. No destructive change. |

---

### Updated Stack Summary — Schema Migration Layer Added

| Capability | Tool | Status |
|-----------|------|--------|
| Migration authoring | Alembic (Python) | ✅ Added |
| Feature dependency graph | PostgreSQL — platform schema | ✅ Added |
| Per-tenant migration state | PostgreSQL — tenant schema | ✅ Added |
| Migration orchestration | FastAPI Migration Service on Cloud Run Jobs | ✅ Added |
| Migration job queuing | GCP Cloud Tasks | ✅ Already in stack — extended use |
| Non-destructive policy enforcement | Alembic Migration Linter in GitHub Actions CI | ✅ Added |
| Multi-region propagation | Cloud Tasks fan-out + Alembic idempotency | ✅ Added |

---

## Environment Architecture — Development, Staging, Production

### Strategy: One GCP Project Per Environment

KloudShop operates three fully isolated environments. Each environment is a
**separate GCP project** — not a namespace, folder, or configuration flag within
a single project. This is Google's own recommendation and the only approach that
guarantees hard billing isolation, hard IAM isolation, and zero risk of a development
or staging operation affecting production infrastructure or merchant data.

| Environment | GCP Project ID | Purpose |
|-------------|---------------|---------|
| **Development** | `kloudshop-dev` | Active feature development. AI engineering team's primary workspace. Rapid iteration, schema experimentation, feature-gated migration testing. |
| **Staging** | `kloudshop-staging` | Pre-production validation. Production-mirror infrastructure at reduced scale. All CI/CD pipeline gates run here before production promotion. Beta merchant testing. |
| **Production** | `kloudshop-prod` | Live merchant traffic. Zero direct developer access. All changes arrive exclusively via the CI/CD pipeline. |

---

### Per-Environment Resource Topology

| Resource | Development | Staging | Production |
|----------|------------|---------|------------|
| **GCP Project** | `kloudshop-dev` | `kloudshop-staging` | `kloudshop-prod` |
| **Cloud SQL** | Single instance, shared schema, minimal specs (2 vCPU / 8GB RAM) | Single instance, production schema, moderate specs (8 vCPU / 32GB RAM) | Cloud SQL Enterprise Plus, HA with read replicas (96 vCPU path) |
| **Cloud Run** | Min instances = 0, max = 10. Cold starts acceptable. | Min instances = 1, max = 50. Production config mirrored. | Min instances = 3 per service, max = 1,000+. No cold starts on critical paths. |
| **Memorystore Redis** | Basic tier, single node, smallest available | Standard tier, HA replica | Standard tier, HA replica — upgrade to Cluster at scale trigger |
| **Firebase Project** | `kloudshop-dev` (separate Firebase project) | `kloudshop-staging` (separate Firebase project) | `kloudshop-prod` (separate Firebase project) |
| **Firebase Auth** | Dev tenant pool — test accounts only | Staging tenant pool — internal + beta merchants | Production tenant pool — all live merchants |
| **Firebase Remote Config** | Feature flags freely toggled by engineering | Feature flags mirror production + beta flags | Feature flags managed via CI/CD promotion only |
| **Vertex AI / Gemini** | Low-quota inference, dev API keys | Staging quota, production model versions | Production quota, SLA-backed endpoints |
| **GCP Secret Manager** | Dev secrets (dev DB credentials, dev Stripe test keys) | Staging secrets (staging DB credentials, Stripe test keys) | Production secrets (prod DB credentials, live Stripe keys) |
| **Stripe** | Stripe Test Mode — `sk_test_...` keys | Stripe Test Mode — `sk_test_...` keys | Stripe Live Mode — `sk_live_...` keys |
| **Resend (Email)** | Dev sending domain — no real emails sent | Staging domain — internal addresses only | Production sending domain — live merchant emails |
| **Sentry** | `kloudshop-dev` Sentry project | `kloudshop-staging` Sentry project | `kloudshop-prod` Sentry project — highest alert priority |
| **PostHog** | Dev PostHog project — noisy, high-frequency events acceptable | Staging PostHog project | Production PostHog project — analytics source of truth |
| **BigQuery** | Dev dataset — synthetic and anonymised data only. Never real merchant data. | Staging dataset — anonymised production data snapshots for realistic query testing | Production dataset — live merchant commerce events |

---

### CI/CD Pipeline — Environment Promotion Flow

```
Developer / AI Agent pushes code
to feature branch on GitHub
         │
         ▼
GitHub Actions — PR Checks
  ├── Alembic Migration Linter
  │   (blocks destructive migrations)
  ├── Pytest unit tests
  ├── Flutter test (widget tests)
  └── Type checking (mypy + Dart analyzer)
         │
     All pass?
         │
         ▼
Merge to `main` branch
         │
         ▼
GCP Cloud Build — Development Deploy
  ├── Build Docker containers
  ├── Push to Artifact Registry (dev)
  ├── Deploy to Cloud Run (kloudshop-dev)
  ├── Run Alembic migrations (dev Cloud SQL)
  └── Run Playwright E2E tests against dev
         │
     E2E pass?
         │
         ▼
Manual promotion gate
(founder approves staging deploy)
         │
         ▼
GCP Cloud Build — Staging Deploy
  ├── Pull same Docker image from Artifact Registry
  ├── Deploy to Cloud Run (kloudshop-staging)
  ├── Run Alembic migrations (staging Cloud SQL)
  ├── Run full Playwright E2E suite against staging
  ├── Run performance smoke tests (k6 load test)
  └── Run security scan (Trivy container scan)
         │
     All gates pass?
         │
         ▼
Manual promotion gate
(founder approves production deploy)
         │
         ▼
GCP Cloud Deploy — Production Release
  ├── Canary deploy: 5% of traffic → new version
  ├── Monitor error rate + latency for 10 minutes
  ├── Auto-promote to 100% if metrics healthy
  ├── Auto-rollback if error rate > 1% or p99 > 2s
  └── Run Alembic migrations (prod Cloud SQL)
         │
         ▼
  Sentry + Cloud Monitoring alerts
  confirm healthy deployment
```

**Canary deployment on production** is non-negotiable for a solo team. If a bad
release ships, GCP Cloud Deploy auto-rolls back before it affects more than 5% of
live merchant traffic. No manual intervention required at 3am.

---

### Feature-Gated Migrations Across Environments

The migration runner documented earlier operates independently per environment.
Each environment has its own `feature_registry`, `feature_dependencies`,
`feature_migrations`, and `tenant_migration_state` tables — all scoped to that
environment's Cloud SQL instance.

**Migration promotion flow:**

```
1. Author migration in dev → test feature activation locally
2. Migration script committed to GitHub (linter passes in CI)
3. Staging deploy: migration applied to staging Cloud SQL
4. QA validates feature activation + dependency chain in staging
5. Production deploy: migration applied to prod Cloud SQL via Cloud Deploy
6. Feature available for merchant activation in production Feature Catalogue
```

**Schema drift protection:** A Cloud Tasks scheduled job runs nightly in staging
and production, comparing the live schema against the expected Alembic migration
head. Any drift (manually applied SQL, ORM-generated DDL bypassing Alembic) fires
a Sentry alert and a Cloud Monitoring alarm. Schema changes outside the migration
pipeline are treated as incidents.

---

### Secrets Management Across Environments

Each environment's GCP Secret Manager holds only that environment's credentials.
No cross-environment secret access is possible by IAM design.

| Secret | Dev Value | Staging Value | Prod Value |
|--------|-----------|--------------|------------|
| `DATABASE_URL` | Dev Cloud SQL connection | Staging Cloud SQL connection | Prod Cloud SQL connection |
| `STRIPE_SECRET_KEY` | `sk_test_...` | `sk_test_...` | `sk_live_...` |
| `FIREBASE_SERVICE_ACCOUNT` | Dev Firebase project SA | Staging Firebase project SA | Prod Firebase project SA |
| `VERTEX_AI_API_KEY` | Dev Vertex quota | Staging Vertex quota | Prod Vertex quota |
| `RESEND_API_KEY` | Dev sending key (sandbox) | Staging sending key | Prod sending key |

Cloud Run services in each environment are bound to their environment's Secret
Manager via Workload Identity Federation — no service account key files, no
credentials in environment variables, no credentials in source code. Ever.

---

### Pure API-Only Architecture: Python FastAPI + SQLAlchemy

*(Addendum: Transitioning from Hybrid FDC to Pure API-only architecture)*

The architecture has pivoted from a hybrid model (where Firebase Data Connect handled CRUD)
to a **Pure API-Only** approach. Flutter clients communicate exclusively with the Python FastAPI backend
for *all* operations. This centralizes security, simplifies testing via TDD, and adheres to classic 3-tier architecture.

**Clean division of responsibility — final decision:**

| Layer | Tool | Scope |
|-------|------|-------|
| Flutter client → Backend | REST via Dio | Standard HTTP communication using generated OpenAPI client or manual Dio integration. |
| Backend API | Python FastAPI | Single authoritative gatekeeper for all business logic, validation (Pydantic), and DB interactions. |
| FastAPI backend → Cloud SQL | SQLAlchemy Core + `text()` for raw SQL | All database queries (CRUD, pricing engine, billing reconciliation, pgvector search, CTEs). |
| Schema versioning + migrations | Alembic (depends on SQLAlchemy — mandatory) | All DDL changes, feature-gated migrations, dependency chain resolution. |
| ORM-style Python models | SQLAlchemy Core only (no ORM) | Thin expression layer — never auto-generates DDL, never fights Alembic. |

**Why Pure API and SQLAlchemy Core:** By removing FDC, we ensure that authentication (Firebase JWT) and
authorization (RBAC) happen fully in Python middleware. SQLAlchemy ORM auto-generates DDL and manages
schema state in a way that conflicts with Alembic's migration tracking. Core mode gives full SQL control,
uses Alembic cleanly for all schema changes, and lets complex backend queries be expressed as readable
Python without the abstraction overhead of the ORM's session/identity-map model.

---

### Updated Stack Summary — Environments + Pure API Architecture

| Capability | Tool | Status |
|-----------|------|--------|
| Environment isolation | 3 separate GCP projects (dev / staging / prod) | ✅ Added |
| Environment promotion | GitHub Actions → Cloud Build → Cloud Deploy (canary) | ✅ Added |
| Per-environment secrets | GCP Secret Manager per project, Workload Identity | ✅ Added |
| Per-environment Firebase | 3 separate Firebase projects | ✅ Added |
| Client-Backend Communication | Python FastAPI (REST) | ✅ Updated (Replaced FDC) |
| All Database Queries | SQLAlchemy Core + raw SQL via `text()` | ✅ Updated |
| Schema migration tooling | Alembic (SQLAlchemy-native, mandatory) | ✅ Confirmed |
| Schema drift detection | Cloud Tasks nightly job + Sentry + Cloud Monitoring | ✅ Added |

---

## AI Copywriter Architecture

### Design Principle: A Free Marketing Expert in Every Merchant's Admin

Every merchant has one-click Gemini-powered generation of high-converting product titles,
product descriptions, and blog content — grounded in their Brand Voice profile. One click
generates three strategically differentiated copy variants. The merchant picks one, edits
if needed, and publishes. No copywriting skill required. No third-party app. No agency.
No extra subscription. GCP pass-through billable at fractions of a cent per generation.

---

### Brand Voice Profile (per brand_profile — Hybrid merchants get two independent profiles)

Brand Voice fields live on the existing `brand_profiles` table (tenant schema).
All fields are optional — partial profiles are valid. The AI Copywriter is usable
with no profile at all; a generic high-converting prompt applies until the profile
is saved. See DMF-12 in `00-carry-forward-flags.md` for full schema specification.

| Field | Type | Purpose |
|-------|------|---------|
| `brand_voice_tone` | VARCHAR(32) ENUM | Curated tone selector — prevents prompt injection via free-text input |
| `brand_voice_adjectives` | TEXT[] (max 5) | Words the brand should always feel like (e.g. bold, minimal, premium) |
| `brand_voice_target_audience` | TEXT (max 300 chars) | Who the copy is written for |
| `brand_voice_style_rules` | TEXT (max 500 chars) | Explicit writing rules (e.g. "never use exclamation marks") |
| `brand_voice_avoid_brands` | TEXT[] (max 5) | Competitor brands the copy must not sound like |
| `brand_voice_configured_at` | TIMESTAMPTZ | NULL = profile not yet set; generic prompt used |

Hybrid merchants configure independent Brand Voice profiles per storefront — DTC and
B2B copy can have entirely different tones, audiences, and style rules. The product
editor and blog editor pick up whichever brand_profile_id is active for the surface
being edited.

---

### Prompt Assembly (Server-Side Only — FastAPI `copywriter/` Module)

Brand Voice fields are assembled into prompts exclusively server-side. The Flutter
client never receives, constructs, or sees the assembled prompt. This prevents client-side
prompt injection and keeps the copywriting logic entirely within the platform's control.

```python
# Pseudocode — FastAPI copywriter/ module
def assemble_prompt(content_type, source_content, brand_voice, product_context):
    system = """You are a world-class direct-response copywriter and brand strategist.
    Your copy is benefit-led, specific, and converts browsers into buyers.
    Never use hollow superlatives ('amazing', 'revolutionary', 'world-class').
    Only reference attributes explicitly provided in the product data below.
    Never invent specifications, features, or claims not present in the source data."""

    brand_block = f"""
    Brand tone: {brand_voice.tone or 'professional and clear'}
    Brand feels like: {', '.join(brand_voice.adjectives) or 'not specified'}
    Target audience: {brand_voice.target_audience or 'general consumers'}
    Style rules: {brand_voice.style_rules or 'none'}
    Do NOT sound like: {', '.join(brand_voice.avoid_brands) or 'none specified'}
    """ if brand_voice.configured_at else "Write high-converting copy using proven direct-response principles."

    task = PROMPT_TEMPLATES[content_type]
    # Returns structured output with exactly 3 labelled variants —
    # enforced via Gemini structured output schema, not prompt hope
```

**Three-variant structure** — each call returns exactly three variants, each taking a
distinct copywriting angle. This is enforced via Gemini structured output, not prompt
instructions alone. Three separate API calls are never made.

| Variant | Angle | Opening strategy |
|---------|-------|-----------------|
| Variant 1 | Benefit-led | Opens with the primary customer benefit |
| Variant 2 | Problem-solution | Opens by naming the problem this product/post solves |
| Variant 3 | Authority / social proof | Opens with a credibility signal, specification, or outcome |

---

### Per Content Type — Source Signals Injected into Prompt

| Content type | Signals injected |
|---|---|
| `product_title` | Current title (if any), product category, key variant attributes (material, size, spec), brand voice |
| `product_description` | Current description (if any), product title, all variant attributes across all variants, product category, brand voice |
| `blog_title` | Current draft title, first 500 chars of body (if any), blog categories + tags, brand voice |
| `blog_body` | Full current draft body, post title, blog categories + tags, target word count (inferred from current body length, min 300 words), brand voice |

**Hallucination prevention:** All `product_description` and `product_title` prompts
include an explicit instruction: "Only reference attributes explicitly provided below.
Never invent specifications, features, certifications, or claims not present in the
source data." The `ai_copywriter_log.was_edited` field surfaces whether generated copy
required merchant correction — a sustained high rate signals a prompt quality issue.

---

### Generation Log (Tenant Schema)

Every generation call is logged in `ai_copywriter_log` (full schema in DMF-12).
Key signals captured:

- `variant_accepted` (1 | 2 | 3 | NULL) — which variant the merchant chose, or NULL if all discarded
- `was_edited` (BOOLEAN) — whether the accepted variant was manually edited before saving
- `prompt_hash` — SHA-256 of the assembled prompt, not the raw text — preserves auditability without storing PII or brand secrets in plain text

These signals feed future prompt quality analysis. High discard rates or high edit
rates per content_type are surfaced in the Platform Admin dashboard as prompt quality
indicators — actionable by the engineering team without merchant involvement.

---

### Billing

Gemini inference is a GCP resource. Each generation call is:
- Labelled with `tenant_id` at the GCP resource level
- Metered via GCP Billing Export → BigQuery
- Billed as GCP pass-through: `merchant_bill = actual_gemini_cost × 1.15`
- Itemised on the merchant's monthly invoice as: "AI Copywriter — Gemini inference (GCP pass-through)"

A typical product description generation call (3 variants, ~600 output tokens total)
costs fractions of a cent. No subscription. No per-seat fee. Merchants pay only for
what they generate.
