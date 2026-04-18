# MVP Scope Decision: KloudShop

> **Stage:** ★ MVP Scoping Gate
> **Persona:** Technical Product Strategist
> **Reads from:** `01-product-brief.md`, `04-feature-stories.md`
> **Approved:** [ ] pending

---

## Core Hypothesis Being Tested

A mid-market merchant who is actively paying Shopify Plus or WooCommerce fees will
switch to KloudShop within 30 minutes of discovering it — driven by the migration
engine's 2-minute store import, zero transaction fees, and unified B2B+DTC operations
— and will generate real revenue through the platform within their first 30-day trial.

---

## The Minimum Value Loop

```
Merchant discovers KloudShop
         │
         ▼
Signs up (Gmail OAuth, 30 seconds)
         │
         ▼
Pastes competitor store URL → 2-minute migration
(products, SEO metadata, migration runbook imported)
         │
         ▼
Applies a theme → customises brand in WYSIWYG
         │
         ▼
Connects Stripe account → connects custom domain
         │
         ▼
First consumer places an order → merchant fulfils it
         │
         ▼
Merchant upgrades to paid tier before trial ends
```

Every epic and story in this MVP is justified by whether it sits on or directly
enables this loop. Anything that doesn't is post-MVP.

---

## MVP Feature Set

### ✅ In MVP — All Epics & Key Stories

---

#### E01 — Authentication & Access Control (P0, full)

All of E01 is MVP. Without it nothing else functions.

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-001 Merchant Staff Login (Google OAuth) | Gate to everything | Low |
| US-002 Firebase App Check Enforcement | Security baseline — non-negotiable | Low |
| US-003 Staff Invitation & Role Assignment | Merchants have teams from day one | Low |
| US-004 Role Editing & Revocation | Ops requirement | Low |
| US-005 Owner Account Transfer | Legal / succession requirement | Low |
| US-006 Multi-Role Assignment | Needed for real team structures | Low |
| US-007 B2B Buyer Registration & Auth | Required for any B2B merchant | Medium |
| US-008 Consumer Account (DTC) | Soft signup post-checkout — core to loyalty path | Low |

---

#### E02 — Merchant Onboarding & Migration Engine (P0, full)

The acquisition moat. Automated scraping is MVP; CSV fallback is mandatory alongside it.

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-009 Merchant Signup & Tier Selection | Top of funnel | Low |
| US-010 GCP Region Selection | Infrastructure gate | Low |
| US-011 Competitor Store Migration (Scrape + Import) | The 2-minute win — core differentiator | High |
| US-012 Scraped Data Compliance Rules | Legal requirement alongside scraping | Low |
| US-013 Product Catalog CSV Upload (Scraping Fallback) | Mandatory fallback when scraping is blocked | Medium |
| US-014 CSV Customer & Order History Import | Migration completeness | Medium |
| US-015 Migration Runbook Generation | Reduces go-live friction dramatically | Medium |
| US-016 Brand Identity Setup | Required before storefront is usable | Low |
| US-017 Tier Upgrade Consent Flow | Billing integrity requirement | Low |
| US-018 Secondary GCP Region On-Demand Activation | Deferred — see Post-MVP | — |

**US-018 deferred:** Secondary region is a resilience feature, not a revenue feature.
First merchants can operate single-region. Activate on-demand post-MVP.

---

#### E03 — Storefront & Theme System (P0, full minus one)

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-019 Theme Library Browsing & Selection | Core storefront experience | Medium |
| US-021 WYSIWYG Editor — Component Stack | Merchant brand delivery — core | High |
| US-022 WYSIWYG Editor — Config Panel | Required alongside US-021 | High |
| US-023 WYSIWYG Editor — Save, Apply & Discard | Required alongside US-021 | Medium |
| US-024 Design Token Override | Required for brand accuracy | Low |
| US-025 One-Click Theme Switching with Content Carry-Forward | Core differentiator | Medium |
| US-026 Storefront Content Slot Editing | Required for merchant content | Medium |

**US-020 (Theme Favourites):** Deferred — first story to ship post-MVP. Organisational,
not functional. Merchants can browse and apply themes without a favourites list.

---

#### E04 — Product Catalog Management (P0, full)

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-027 Add New Product (unlimited variants) | Foundational — nothing sells without it | Medium |
| US-028 Clone Product & Create Variant | Productivity — include | Low |
| US-029 Bulk Product Import via CSV | Required for large catalog merchants | Medium |
| US-030 SEO Metadata Editing (All Page Types) | Core differentiator — native SEO | Medium |
| US-031 Collection Management | Required for storefront navigation | Low |

---

#### E05 — Order Management (P0, full)

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-032 Order Placement (DTC Consumer) | Revenue — the whole point | High |
| US-033 Order Fulfilment with Shipment Tracking | Post-purchase merchant ops | Medium |
| US-034 Order Refund (Full & Partial) | Required for commerce legality | Medium |
| US-035 Order Notes & Internal Comments | Ops hygiene — include | Low |
| US-036 Bulk Order Export | Accounting requirement | Low |

---

#### E06 — Inventory & Supplier Management (P0, full)

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-037 Inventory Dashboard with Lead-Time-Aware Urgency | Daily ops for any merchant | Medium |
| US-038 AI Stock Replenishment Recommendations | Core intelligence differentiator | High |
| US-039 Supplier Management (CRUD) | Procurement foundation | Low |
| US-040 Multi-Supplier Assignment & Preference Ranking | Required for procurement intelligence | Medium |
| US-041 Purchase Order Lifecycle | Procurement audit trail | Medium |
| US-042 Supplier Performance Analytics | Differentiator — include at MVP | High |

---

#### E07 — B2B Operations (P0, full)

Required in full — any B2B merchant trial needs this to be real.

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-043 B2B Buyer Account Creation & Invitation | Foundation of B2B | Low |
| US-044 B2B Custom Price List | Core B2B value — no price list = no B2B | Medium |
| US-045 B2B Approval Workflow | Required for enterprise buyers | Medium |
| US-046 B2B Buyer Portal Catalog Browsing | B2B storefront — required | High |
| US-047 B2B Net-Terms Invoicing | B2B revenue collection | Medium |

---

#### E08 — Feature Catalogue & Configuration (P0, architecture only at MVP)

The toggle engine, schema migration system, and setup wizard ship in full.
The *content* of the catalogue (which specific features are available) is
decided as a follow-up — see Feature Catalogue Launch Set placeholder below.

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-048 Feature Catalogue Browsing & Activation (Phase 1) | Architecture ships at MVP | High |
| US-049 Feature Setup Wizard (Phase 2) | Architecture ships at MVP | High |
| US-050 Feature Reconfiguration (Phase 3) | Architecture ships at MVP | Medium |
| US-051 Feature Deactivation | Architecture ships at MVP | Low |
| US-052 Feature Request Channel | Community flywheel — include from day one | Low |

---

#### E09 — Analytics & Reporting (P1 → MVP with caveat)

Native dashboards, Looker Studio embed, and Vertex AI forecasting all ship at MVP.
Where merchant data is insufficient, surfaces show informative empty states rather
than being hidden — merchants must see that the feature exists and understand it
will grow with their data.

| Story | MVP? | Rationale |
|-------|------|-----------|
| US-053 Revenue Overview Dashboard | ✅ MVP | Merchant needs this daily from day one |
| US-054 Demand Forecasting & Stock Replenishment Prediction | ✅ MVP with disclaimer | Ships with explicit messaging: "AI forecasting improves as your sales data builds — fully active after 90 days and 100+ orders." Feature is present and visible; predictions surface as data accumulates. Key differentiator — merchants need to see it exists. |
| US-055 Looker Studio Embedded BI | ✅ MVP with empty state | Ships with an overlay on the Looker iframe when data is insufficient: "Your analytics workspace is ready — as your store data grows, richer insights will appear here automatically." Frame is visible; merchants know the capability exists. BigQuery streaming from day one means data populates without any future work. |

---

#### E10 — Billing & Subscription (P0, full)

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-056 Monthly Invoice Generation | Revenue collection | High |
| US-057 Trial Hard-Stop — Three-Trigger System | Cost protection + conversion | High |
| US-058 Merchant Account Suspension & Reinstatement | Dunning automation | Medium |

---

#### E11 — POS & Omnichannel (P1 → MVP per merchant decision)

In MVP. First merchants with physical stores need this.

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-059 POS Operator Role Assignment & Location Setup | Required for POS | Low |
| US-060 In-Store Sale Processing (POS) | Core POS — unified inventory | High |

---

#### E12 — Social Commerce & Channels (P1 → MVP, all four channels)

All four channels at MVP — channel parity is the pitch.

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-061 Social Channel Connection & Catalog Sync | TikTok + Instagram + Facebook | High |
| US-062 Google Shopping Native Feed | SEO + paid traffic foundation | Medium |

**Engineering note:** All four social channels shipping simultaneously is the
highest-complexity call in this MVP scope. TikTok Shop, Instagram Graph API,
and Facebook Commerce API each have independent OAuth flows, webhook schemas,
and rate limit profiles. This is the primary schedule risk item — see Risks below.

---

#### E13 — Tax Compliance (P1 → MVP)

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-063 Merchant Tax Setup (Stripe Tax Embedded) | Legal requirement for selling | Medium |
| US-064 Automated Tax Calculation at Checkout | Required before first transaction | Medium |
| US-065 Merchant Tax Reporting | Quarterly filing requirement | Low |

---

#### E14 — Dynamic Pricing Engine (core platform feature — always-on, not Feature Catalogue)

Always available in every merchant's admin under **Pricing → Rules**. No toggle
required. Merchants migrating from other platforms bring pricing knowledge with them.
Time-triggered flash sales and stock-age markdowns are immediately useful from day one.
Velocity-based rules surface a note: "This rule activates once sufficient sales data
has accumulated."

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-066 Dynamic Pricing Rule Creation & Execution | Core admin section — always present, empty until merchant creates a rule | High |

---

#### E15 — Data Portability (P1 → MVP)

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-067 Full Data Export On Demand | Differentiator + trust signal + GDPR | Medium |

---

#### E16 — Internal Messaging (UI skeleton at MVP, full feature post-MVP)

The messaging UI shell ships at MVP — inbox icon in the admin nav, placeholder
messaging screen with a "Coming soon" state. Merchants can see the feature exists
and understand it is native to the platform. Full message threads, search, file
attachments, and context-linked threads ship in v1.1.

| Story | MVP? | Rationale |
|-------|------|-----------|
| US-068–US-071 Full messaging functionality | ⏭ v1.1 | Full implementation post-MVP |
| Messaging UI shell (inbox nav icon + "Coming soon" screen) | ✅ MVP skeleton | Signals platform richness; aids conversion. Zero backend required for the placeholder. |

---

#### E17 — Consumer DTC Storefront (P0, full)

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-072 Storefront Page Load & Core Web Vitals | Non-negotiable — SEO foundation | High |
| US-073 AI Consultative Search (RAG-Powered) | Core differentiator on storefront | High |
| US-074 Guest Checkout & Post-Purchase Account Creation | Revenue — frictionless checkout | Medium |

**US-075 (Loyalty Programme):** Post-MVP. One of the first Feature Catalogue features
to activate in v1.1 — not required for the core commerce loop at launch.

---

#### E18 — Platform Administration (P0, full)

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-076 Platform Admin Login & Dashboard | KloudShop operations | Low |
| US-077 Trial Signup Validation (Anti-Spam) | Cost protection | Low |
| US-078 Theme Catalogue Management | Required to ship themes | Low |
| US-079 Feature Catalogue Management | Required to ship features | Low |
| US-080 Production Deployment Approval & Canary Management | Safe releases | Medium |

---

#### E19 — System & Background Processes (P0, full)

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-081 GCP Tenant Provisioning | Foundation — nothing works without it | High |
| US-082 Feature Schema Migration Execution | Feature Catalogue dependency | High |
| US-083 Schema Drift Detection (Nightly) | Operational integrity | Low |
| US-084 GDPR Right-to-Erasure Execution | Legal requirement (UK/EU markets) | Medium |

---

#### E20 — Shipping & Courier Integration (P0, full)

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-085 Platform-Wide Carrier Configuration | Foundation | Low |
| US-086 Merchant Carrier Account Connection | Negotiated rates — merchant value | Medium |
| US-087 Merchant Checkout Carrier Configuration | Controls what consumers see | Medium |
| US-088 Product Weight & Dimension Configuration | Rate accuracy | Low |
| US-089 Shipping Rate Calculation at Checkout | Required for every order | High |
| US-090 Multi-Item Shipping Consolidation | Consumer UX + cost accuracy | High |
| US-091 Shipping Label Generation | Fulfilment ops | Medium |
| US-092 Manual Shipping (Local Courier Fallback) | Global reach — not all regions have API carriers | Low |
| US-093 Free Shipping Rules | Promotional tool — include | Low |
| US-094 B2B Shipping & Delivery Configuration | Required for B2B merchants | Medium |

---

#### E21 — Multilingual Storefront & Admin (P0 → architecture only at MVP)

i18n architecture baked in from day one. English-only content at MVP launch.
10 LTR language content ships in v1.1.

| Story | MVP? | Rationale |
|-------|------|-----------|
| US-095 Merchant Language Settings & Locale Management | ✅ Architecture only | Schema + locale toggles built; all locales disabled except `en` |
| US-096 AI Auto-Translation of Product Content | ⏭ v1.1 | Architecture present; Google Cloud Translation API not wired until v1.1 |
| US-097 Multilingual Storefront Rendering | ✅ Architecture only | Path-prefix routing + hreflang generation built; only `/en/` active |
| US-098 Merchant Admin UI Language | ⏭ v1.1 | ARB files for `en` only at MVP; additional ARB files added in v1.1 |

---

#### E22 — Native Blog (P0 → MVP)

Native blog ships at MVP. SEO content engine is a core differentiator — merchants
need it from day one to build organic search presence.

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-099 Blog Post Creation, Editing & Publishing | Full blog authoring including scheduling, categories, tags, SEO metadata | Medium |
| US-100 Blog Post Consumer-Facing Rendering | SSR with JSON-LD Article structured data, hreflang, sitemap inclusion | Medium |

---

#### E23 — AI Copywriter (core platform feature — always-on, not Feature Catalogue)

Always available inline in the product editor and blog editor — no toggle required.
One-click Gemini-powered copy generation for every merchant from day one.
GCP pass-through billable at actual Gemini inference cost × 1.15.

| Story | Rationale | Complexity |
|-------|-----------|------------|
| US-101 Brand Voice Profile Setup | Optional but high-value — grounded copy vs. generic output | Low |
| US-102 AI Product Title Enhancement | Three variants, benefit/problem/authority angles | Medium |
| US-103 AI Product Description Generation / Enhancement | Full description generation with hallucination prevention | Medium |
| US-104 AI Blog Post Enhancement | Title + body enhancement for blog content | Medium |

 — Deferred to v1.1

| Epic | Story / Feature | Rationale for Deferral | Target |
|------|----------------|----------------------|--------|
| E03 | US-020 Theme Favourites Management | First post-MVP ship. Organisational, not functional. | v1.1 — first |
| E02 | US-018 Secondary GCP Region | Resilience, not revenue. No merchant needs this in trial. | v1.1 |
| E09 | US-054 Demand Forecasting — full accuracy | Ships at MVP with disclaimer; full AI accuracy requires 90 days + 100 orders. | Ongoing improvement |
| E16 | US-068–US-071 Internal Messaging (full) | UI skeleton at MVP; full functionality in v1.1. | v1.1 |
| E17 | US-075 Loyalty Programme | First Feature Catalogue feature post-MVP. | v1.1 |
| E21 | US-096 AI Auto-Translation | Architecture present; Google Translation API pipeline wired in v1.1. | v1.1 |
| E21 | US-098 Merchant Admin UI Language | English-only admin at MVP. Additional ARB files in v1.1. | v1.1 |
| Feature Catalogue | Email marketing automation | v1.1 | v1.1 |
| Feature Catalogue | Gift cards | v1.1 | v1.1 |
| Feature Catalogue | Loyalty programme | First Feature Catalogue feature post-MVP | v1.1 |

---

### 🚫 Explicitly Descoped

| Feature | Reason |
|---------|--------|
| RTL language support (Arabic, Hebrew, Urdu) | Requires Flutter bidirectional layout engine changes. Post-MVP by design. |
| MBWay (Portugal) — SIBS API | Direct API integration deferred. Portuguese merchants use Stripe methods at MVP. |
| ERP/CRM connectors (Salesforce, HubSpot, SAP) | Developer API + webhooks cover interim. Pre-built connectors are post-MVP. |
| Headless commerce API tier | Out of scope by design — KloudShop storefronts only. |
| AI per-customer homepage personalisation | Requires post-PMF data volume. PDP + cart AI recommendations are MVP. |
| Customer churn prediction dashboard | No data at MVP scale. Post-PMF. |
| B2B quote request workflow | B2B approval workflows cover initial use cases. |
| Subscription / recurring orders | Feature Catalogue item — v1.1. |
| Advanced bundle builder | Feature Catalogue item — v1.1. |

**Note on PayPal:** Not descoped — confirmed post-MVP (v1.1 or v2). Requires integration
beyond Stripe but is a genuine roadmap item given merchant demand in non-Stripe-dominant
markets.

---

### 🗂 Feature Catalogue Launch Set — Partially Confirmed

**Status: Partially confirmed. Remaining features decided as a follow-up before Sprint 11.**

The Feature Catalogue architecture ships fully at MVP (toggle engine, Alembic migration
runner, schema-driven setup wizard, Firebase Remote Config activation, Feature Request
Channel).

**Reclassified as core platform features (not Feature Catalogue items):**
The following were previously listed as Feature Catalogue candidates but are now
confirmed as always-on core platform features, configured directly in the merchant
admin — no toggle required:

| Feature | Admin location |
|---------|---------------|
| Dynamic Pricing | Admin → Pricing → Rules |
| Discount Engine / Coupon Codes | Admin → Discounts |
| Abandoned Cart Recovery | Admin → Marketing → Automations |
| Product Reviews + UGC | Admin → Products → Reviews |
| AI Copywriter | Inline in product editor and blog editor — always available |

**Feature Catalogue launch set — follow-up decision before Sprint 11:**
All genuinely opt-in candidates (features a merchant may legitimately never want):
subscription/recurring orders, bundle builder, affiliate/referral tracking,
B2B quote requests, social proof widgets, delivery windows,
OTP verification for B2B buyers, customer groups/segmentation.

**Confirmed post-MVP Feature Catalogue (v1.1):**

| Feature | Notes |
|---------|-------|
| Loyalty programme | First Feature Catalogue feature to activate in v1.1 |
| Email marketing automation | v1.1 |
| Gift cards | v1.1 |

---

## MVP Build Sequence

Critical path — each phase unblocks the next. Phases can overlap where
dependencies allow but the sequence within each phase is strict.

```
PHASE 0 — Spikes (before Sprint 1 begins)
──────────────────────────────────────────
[ASM-01] Flutter Web CWV benchmark on GCP Cloud Run
[ASM-02] Migration scraper bot-protection spike (Shopify + WooCommerce)
[RSK-02] Wildcard SSL two-level wildcard validation (*.*.kloudshop.biz)
[ASM-06] Service worker + version.json interop with Flutter build (SYS-18)

All four spikes must pass before Sprint 1 begins.
Fallback decisions: if ASM-01 fails → FastAPI+Jinja2 for storefronts.
                   if ASM-02 fails → CSV-first migration, scraping in v1.1.

PHASE 1 — Foundation (Sprints 1–3)
────────────────────────────────────
E01  Auth & RBAC (Firebase Auth, custom claims, App Check)
E19  GCP Tenant Provisioning (SYS-01)
E10  Billing infrastructure (Stripe Billing, trial three-trigger system, SYS-09)
E18  Platform Admin baseline (login, trial validation, ADM-01–ADM-03)

Nothing else is buildable without Phase 1 complete.

PHASE 2 — Core Commerce (Sprints 4–7)
───────────────────────────────────────
E04  Product Catalog (products, variants, collections, SEO)
E05  Order Management (placement, fulfilment, refunds)
E06  Inventory & Supplier Management
E20  Shipping & Courier Integration
E13  Tax Compliance (Stripe Tax embedded)
E17  Consumer DTC Storefront (SSR, AI search, guest checkout, CWV)

Phase 2 delivers the minimum for a DTC merchant to sell online.

PHASE 3 — Merchant Experience (Sprints 8–10)
──────────────────────────────────────────────
E02  Migration Engine (scraping + CSV fallback + runbook)
E03  Storefront & Theme System (WYSIWYG, theme library, content slots)
E16  (skipped — post-MVP)
E15  Data Portability (full export)
E08  Feature Catalogue architecture (toggle engine, setup wizard, migration runner)
E18  Theme & Feature Catalogue management (ADM-09–ADM-16)

Phase 3 delivers the self-serve merchant experience.

PHASE 4 — B2B & Channels (Sprints 11–14)
──────────────────────────────────────────
E07  B2B Operations (buyer portal, price lists, approvals, net terms)
E11  POS (POS Operator role, in-store sale processing)
E12  Social Commerce (TikTok Shop, Instagram, Facebook, Google Shopping)
E21  i18n Architecture (English-only content; locale routing + hreflang built)

Phase 4 delivers the full channel and B2B surface.

PHASE 5 — Intelligence & Operations (Sprints 15–16)
─────────────────────────────────────────────────────
E09  Analytics — Revenue Overview Dashboard (US-053 only)
E19  Schema Drift Detection, GDPR Erasure (SYS-06, SYS-11)
E10  Dunning automation (US-058)
E18  Canary deployment management (US-080)
SYS-18  Version detection (service worker + version.json banner)

BETA — Invite-only merchants, then public launch
─────────────────────────────────────────────────
Feature Catalogue launch set activated (follow-up decision).
Phase 0 spike fallback decisions applied if needed.
```

---

## Risks of This MVP Scope

| Risk | Severity | Mitigation |
|------|----------|------------|
| All four social channels (E12) simultaneously is the highest-complexity single decision in this scope | High | Build Channel Sync Service as a single abstraction layer with pluggable adapters. TikTok first; others in same sprint. If timeline slips, Google Shopping ships first; social channels follow. |
| Flutter Web CWV failure (ASM-01) | High | Phase 0 spike is a hard gate. Fallback: FastAPI + Jinja2 for storefronts, Flutter Web retained for admin. Decision made before Sprint 1. |
| Migration scraper blocked by competitor bot-protection (ASM-02) | High | Phase 0 spike. CSV fallback mandatory regardless of spike outcome. 2-minute win degrades gracefully to 10-minute CSV import. |
| AI consultative search (US-073) hallucinating product specs destroys trust on first use | High | RAG grounding against actual catalog is non-negotiable. Ship retrieval-only mode first — no generative synthesis until retrieval quality is validated per tenant. |
| US-054 Demand Forecasting showing misleading predictions with thin data | Medium | Explicit data-sufficiency check before showing any forecast. Below 90 days / 100 orders: show disclaimer state only. Never show a forecast computed on insufficient data. |
| US-055 Looker Studio frame showing empty state confusing merchants | Low | Overlay copy must be clear and optimistic: "Your analytics workspace is ready — data populates automatically as your store grows." Frame visible; no broken charts. |
| Feature Catalogue launch set undecided — risk of shipping architecture with no genuinely opt-in features inside | Medium | Core platform features (dynamic pricing, discounts, abandoned cart, reviews, AI Copywriter) are now always-on — merchants see value immediately without needing to activate anything. Follow-up session before Sprint 11 confirms the opt-in catalogue set. |
| E16 messaging UI skeleton raising expectations the full feature doesn't meet at launch | Low | "Coming soon" label is explicit. No interactive elements in the skeleton — clicking opens a clear "This feature is launching soon" modal, not a broken empty state. |
| E11 POS requiring Stripe Terminal hardware pairing adds QA complexity | Low | Browser-native POS ships first. Terminal card reader pairing is optional. Manual cash/external payment recording covers all POS scenarios without hardware. |
| Gemini AI Copywriter inference cost as GCP pass-through — merchants may over-generate | Low | Each generation is fractions of a cent. Cost is visible on the monthly bill as a line item. No throttling at MVP — monitor usage and introduce soft limits post-launch if needed. |

---

## What We're Explicitly NOT Learning From This MVP

1. **Whether AI per-customer homepage personalisation drives conversion lift** — requires post-PMF data volume and a large enough merchant cohort to A/B test meaningfully.

2. **Whether 10 languages at launch attracts non-English merchants** — English-only MVP tests the core commerce hypothesis first; multilingual is a growth hypothesis tested in v1.1.

3. **Whether internal messaging (E16) reduces merchant churn** — stickiness hypothesis, not conversion hypothesis. UI skeleton at MVP; full feature tested once merchants are on the platform.

4. **Whether the secondary GCP region reduces BFCM churn** — resilience hypothesis, not commerce hypothesis. Tested before first BFCM event post-launch.

5. **Whether loyalty programmes drive repeat purchase rate** — post-MVP Feature Catalogue item. Tested in v1.1 with real purchase data.

6. **Whether PayPal at checkout meaningfully expands the addressable merchant market** — post-MVP. First merchant cohort is Stripe-native markets. PayPal demand validated via Feature Request Channel.

7. **The impact of the remaining Feature Catalogue launch set on merchant activation rate** — partially open pending follow-up decision before Sprint 11.

