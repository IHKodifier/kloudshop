# Stage 7: Development Roadmap

> **Stage:** ★ Development Roadmap Gate
> **Persona:** VP of Engineering
> **Reads from:** `00-MASTER-PRD.md` → `07a-agent-execution-tracker.md` → `08a-api-specification.md` → `04b-mvp-scope.md`
> **Approved:** [x] Approved

---

## 1. The AI-Driven Development Model

KloudShop is being built by a solo founder orchestrating a team of autonomous AI agents. This fundamentally changes the traditional agile model. Instead of stand-ups and story points, the development relies on **deterministic handoffs**, **Test-Driven Development (TDD)**, and a **Single Source of Truth (SSOT)**.

### The Human-Agent Workflow
1. **Task Briefing:** Human assigns a granular Epic/Story to an AI agent, pointing them to `00-MASTER-PRD.md` and `07a-agent-execution-tracker.md`.
2. **API Contract Check (MANDATORY FIRST):**
   - Open `08a-api-specification.md` and locate the endpoint(s) for the assigned Epic.
   - If the endpoint exists: implement exactly as specified — no deviations.
   - If the endpoint is missing: update `08a-api-specification.md` first, get Human approval, then implement.
   - Check `04b-mvp-scope.md` to confirm the story is MVP — do not implement Post-MVP features.
3. **TDD Loop (Red-Green-Refactor):**
   - Agent writes failing unit/integration tests first (Red).
   - Agent writes the minimum code to pass the tests (Green).
   - Agent refactors to adhere to KloudShop architecture commandments (Refactor).
4. **Verification:** Human runs the test suite locally via IDE debugger. If tests pass and UI/API behaves correctly, Human approves.
5. **Handoff:** Agent updates `07a-agent-execution-tracker.md` checklist, commits code with a descriptive message, and hands back to the Human.

---

## 2. Environment & Delivery Pipeline

KloudShop uses three distinct environments, each with dedicated GCP and Firebase projects. Agents operate strictly in `dev`.

**Zero Codebase Change Policy:** Switching and progressing from one environment to the next logical environment (Dev -> Staging -> Prod) must necessitate **zero codebase changes**. All environment-specific configurations (Firebase keys, API URLs, Stripe mode, etc.) must be strictly injected at build/runtime via CI/CD (e.g., `--dart-define` for Flutter, `.env` / Secret Manager for backend).

| Environment | GCP / Firebase Project | Git Branch | Purpose | Deployment Trigger |
|-------------|------------------------|------------|---------|--------------------|
| **Dev** | `kloudshop-dev` | `feature/sprint-*`| AI Agent sandbox, TDD execution, active development. | Push to `feature/*` branch |
| **Staging** | `kloudshop-staging` | `dev` | Human UAT, end-to-end integration testing, data seeding. | PR merged to `dev` branch |
| **Prod** | `kloudshop-prod` | `main` | Live merchants, real Stripe keys, actual consumers. | PR merged to `main` branch |

---

## 3. External Dependencies & Infrastructure Costs

Due to initial financial constraints, paid external dependencies are **deferred** with ONE strict exception: **GCP Cloud SQL**. We do not use local database emulators; we write directly to Cloud SQL in all three environments to ensure perfect parity.

To manage costs for the part-time schedule, we will utilize the smallest instance types and implement start/stop scripts. Native app store accounts and live Stripe integrations are deferred, accepting the launch delays for native mobile apps and real-money transactions. 

| Dependency | Action Required | Status | Blocking |
|------------|-----------------|--------|----------|
| **GCP Cloud SQL** | Provision 3 distinct instances (Dev, Staging, Prod). Implement start/stop scripts. | **Required Day 1** | All backend development |
| **Apple Developer Account** | Register entity, pay fee, await DUNS number / Apple verification. | Deferred | iOS Native App Launch |
| **Google Play Console** | Register account, verify identity. | Deferred | Android Native App Launch |
| **Stripe Connect Platform** | Register as a Connect platform, complete KYC/AML documentation. | Deferred | Real money transactions (Prod) |
| **App Store Review** | First-time submission of the Merchant Admin app and POS app. | Deferred | Beta Launch (Native) |

---

## 4. Phase & Sprint Sequence

This sequence is ported directly from `04b-mvp-scope.md`. A "Sprint" in this context is a logical block of work for an AI agent, not a fixed calendar week. Because the founder is part-time, sprints are measured in *completion of scope*, not time.

### PHASE 0 — Spikes & Setup (Before Sprint 1)
* **Goal:** De-risk architecture and set up the repo for AI agents.
* **Tasks:**
  - Setup Monorepo structure (e.g., `/frontend`, `/backend`, `/infrastructure`).
  - Setup Firebase/GCP projects (Dev/Stg/Prod) and CI/CD pipelines to Firebase Hosting.
  - **Write GCP Provisioning, Cost Control & Backup Scripts:** Bash/Python scripts to dynamically provision, start/stop Cloud SQL instances, AND automatically dump/restore seed data (merchants, themes) to a cheap Google Cloud Storage bucket (Standard/Nearline) for seamless Dev/Staging resets.
  - Spike ASM-01: Flutter Web CWV benchmark.
  - Initialize the `07a-agent-execution-tracker.md` SSOT.

### PHASE 1 — Foundation (Sprints 1–3)
* **Goal:** The core engine that allows a user to exist and pay.
* **Sprint 1 (Auth):** E01 — `/auth/*` endpoints. Firebase Auth, RBAC custom claims, App Check, Google Sign-In UI, staff invitations.
* **Sprint 2 (Infrastructure):** E19 — `/internal/provision-tenant`. GCP tenant provisioning, Alembic migrations, background jobs.
* **Sprint 3 (Billing & Admin):** E10 — `/billing/*` + `/webhooks/stripe`. Stripe Billing, 3-trigger trial system, dunning. E18 — `/platform/*`. Platform Admin login, trial validation, theme/feature catalogue management.

### PHASE 2 — Core Commerce (Sprints 4–7)
* **Goal:** A merchant can manage products and receive a paid order.
* **Sprint 4 (Catalog):** E04 — `/products/*`, `/collections/*`. Products with unlimited variants, collections, bulk CSV import, SEO metadata with auto-301 redirects.
* **Sprint 5 (Orders):** E05 — `/orders/*`. Order placement via Stripe Payment Intent, fulfilment with tracking, full/partial refunds, internal notes, CSV export.
* **Sprint 6 (Inventory):** E06 — `/inventory/*`, `/suppliers/*`, `/purchase-orders/*`. Multi-supplier ranking, AI replenishment, purchase order lifecycle.
* **Sprint 7 (Storefront, Tax & Shipping):** 
  - E17 — `/storefront/{tenant}/*` (SSR + AI search + guest checkout).
  - E20 — `/shipping/*` (multiple shipping profiles, regional shipping zones, weight & price-gated conditional rates, rate blending at checkout).
  - E13 — `/tax/*` (Stripe Connect automated tax calculations + manual `store_tax_rates` fallback table, catalog category mapping).
  - **Product UI Reminder**: Update the existing Product/Variant editing UI to include the new `Charge tax on this product` (taxable) toggle and `Tax Category` dropdown selector.


### PHASE 3 — Merchant Experience (Sprints 8–10)
* **Goal:** A merchant can self-serve onboard and customise their brand.
* **Sprint 8 (Onboarding):** E02 — `/onboarding/*`. CSV/Excel product, customer, and order imports. Brand setup. Migration runbook. ***Competitor scraping (`/onboarding/migration/scrape`) is Post-MVP — do NOT implement.***
* **Sprint 9 (Themes Customizer Overhaul):** E03 — `/themes/*`. Complete Shopify customizer UI clone:
  - 3-pane layout: vertical icon ribbon with exit button (left), outline & properties panel with drill-down navigation (center), and live preview canvas (right).
  - Bi-directional selection highlighting.
  - Reusable JSON page templates (Home, PDP, Cart, Checkout) with custom templates mapping.
  - Global brand syncing, named style presets (seasonal presets), and WCAG contrast check.
* **Sprint 10 (Platform Features):** E08 — `/features/*`. Feature catalogue toggle engine, Alembic migration runner, setup wizard. E15 — `/export/*`. Full data portability. E14 — `/pricing/rules/*`. Dynamic pricing engine. E23 — `/ai/*`. AI Copywriter (Gemini).


### PHASE 4 — B2B & Channels (Sprints 11–14)
* **Goal:** Expanding the revenue surface for merchants.
* **Sprint 11 (B2B):** E07 — `/b2b/*`. B2B buyer portal, custom price lists, approval workflows, net-terms Stripe invoicing.
* **Sprint 12 (POS):** E11 — `/pos/*`. Browser-native in-store sales, unified inventory deduction.
* **Sprint 13 (Social Commerce):** E12 — `/channels/*`, `/feeds/*`. TikTok Shop, Instagram Shopping, Facebook Shops, Google Shopping. *Highest complexity sprint — build Channel Sync Service as unified abstraction.*
* **Sprint 14 (i18n + Blog):** E21 — `/i18n/*` (locale architecture, English-only content at MVP). E22 — `/blog/*`, `/storefront/{tenant}/blog/*` (native blog, scheduling, categories, JSON-LD).

### PHASE 5 — Intelligence & Operations (Sprints 15–16)
* **Goal:** Analytics, AI intelligence, and system hygiene.
* **Sprint 15 (Analytics + AI):** E09 — `/analytics/*`. Revenue overview dashboard, Vertex AI demand forecasting (with data-sufficiency disclaimer), Looker Studio embed.
* **Sprint 16 (Hygiene):** E19 — `/internal/schema-drift-check`, `/internal/gdpr-erasure`. Schema drift detection (nightly), GDPR erasure pipeline. E18 — canary deployment approval. SYS-18 — version detection (service worker + version.json banner).

### PHASE 6 — Consumer Experience (Sprints 17–18)
* **Goal:** High-performance, SEO-optimized storefront and frictionless guest checkout.
* **Sprint 17 (Themes & CMS):** Refine content slots, draft/apply logic, and blog scheduling.
* **Sprint 18 (Storefront Parity):** SSR rendering, RAG-powered search, and the "Zoomer" guest checkout flow.

### PHASE 7 — Premium UI/UX "Surgical" Overhaul (Sprint 19)
* **Goal:** Elevating the platform from skeletal MVP to premium "Designer" quality.
* **Sprint 19 (Design Sprint):** Surgical replacement of all skeletal components with high-fidelity, premium UI elements. Full responsive audit and micro-animation injection across every screen.

### PHASE 8 — Launch Readiness (Sprints 20–21)
* **Goal:** Production hardening and platform activation.
* **Sprint 20 (Infrastructure):** Custom domains, SSL, production terraform.
* **Sprint 21 (Handover):** Stripe Live Mode (Post UK LLC), platform payouts, security audit, and Public Launch.

---

## 5. QA & UAT Gates

Since there is no dedicated QA team, quality is maintained through a combination of Agent-driven TDD and Human-driven UAT.

1. **API Contract Gate (BEFORE coding):** Agent must verify the endpoint exists in `08a-api-specification.md` and the implementation matches the specified request/response models, HTTP methods, and RBAC permissions.
2. **Agent Unit/Integration Tests (Automated):** AI must write tests for business logic (e.g., Stripe webhooks, cart totals, inventory reservation) before writing implementation. Coverage must be >80% for backend functions.
3. **Human UAT (Manual):** At the end of every Sprint, the `feature/sprint-*` branch is merged into the `dev` branch, triggering a deployment to Staging. The solo founder tests the integration in Staging via the IDE debugger (not automated browser). Once UAT passes, `dev` is merged into `main` for production.
4. **Design Review:** Since AI agents struggle with visual polish, the Human must enforce the "Rich Aesthetics" guidelines (from `05-style-guide.md`) manually during Staging UAT, rejecting Agent work that looks too basic or lacks micro-animations.
5. **Post-MVP Guard:** Before closing any sprint, verify no Post-MVP features (from `04b-mvp-scope.md` deferred list and `08a-api-specification.md` Post-MVP section) were accidentally implemented.

---

## Next Steps

1. ~~Review and approve this Roadmap.~~ ✅ Approved.
2. ~~Generate `07a-agent-execution-tracker.md`.~~ ✅ Active and tracking.
3. ~~Begin Phase 0.~~ ✅ Complete — monorepo, Firebase, GCP projects set up.
4. **Active Now:** Phase 1, Sprint 1 — E01 Auth (`/auth/*` endpoints). See `07a-agent-execution-tracker.md`.
