# Stage 7: Development Roadmap

> **Stage:** ★ Development Roadmap Gate
> **Persona:** VP of Engineering
> **Reads from:** `04b-mvp-scope.md`, `06`-series (Data Model)
> **Approved:** [ ] pending

---

## 1. The AI-Driven Development Model

KloudShop is being built by a solo founder orchestrating a team of autonomous AI agents. This fundamentally changes the traditional agile model. Instead of stand-ups and story points, the development relies on **deterministic handoffs**, **Test-Driven Development (TDD)**, and a **Single Source of Truth (SSOT)**.

### The Human-Agent Workflow
1. **Task Briefing:** Human assigns a granular Epic/Story to an AI agent, pointing them to the SSOT (`07a-agent-execution-tracker.md`) and relevant specifications.
2. **TDD Loop (Red-Green-Refactor):** 
   - Agent writes failing unit/integration tests first (Red).
   - Agent writes the minimum code to pass the tests (Green).
   - Agent refactors to adhere to KloudShop architecture (Refactor).
3. **Verification:** Human runs the test suite locally. If tests pass and the UI behaves correctly, the Human approves.
4. **Handoff:** Agent updates the SSOT tracker, commits the code, and hands back control to the Human to deploy or assign the next task.

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
* **Sprint 1 (Auth):** E01 (Firebase Auth, RBAC, App Check).
* **Sprint 2 (Infrastructure):** E19 (GCP Tenant Provisioning - SYS-01).
* **Sprint 3 (Billing & Admin):** E10 (Stripe Billing, 3-trigger trial system), E18 (Admin login).

### PHASE 2 — Core Commerce (Sprints 4–7)
* **Goal:** A merchant can manage products and receive an order.
* **Sprint 4 (Catalog):** E04 (Products, variants, collections, SEO).
* **Sprint 5 (Orders):** E05 (Order placement, fulfilment, refunds).
* **Sprint 6 (Inventory):** E06 (Inventory, suppliers, purchase orders).
* **Sprint 7 (Storefront & Tax):** E17 (Consumer DTC Storefront SSR), E20 (Shipping), E13 (Stripe Tax).

### PHASE 3 — Merchant Experience (Sprints 8–10)
* **Goal:** A merchant can set up and customize their brand.
* **Sprint 8 (Onboarding):** E02 (CSV import, manual setup wizard, runbook). *Note: Automated competitor scraping engine is deferred to post-MVP to accelerate initial development.*
* **Sprint 9 (Themes):** E03 (WYSIWYG editor, theme library, content slots).
* **Sprint 10 (Platform Features):** E08 (Feature catalogue architecture), E15 (Data Export).

### PHASE 4 — B2B & Channels (Sprints 11–14)
* **Goal:** Expanding the revenue surface for merchants.
* **Sprint 11 (B2B):** E07 (B2B buyer portal, price lists, net terms).
* **Sprint 12 (POS):** E11 (In-store POS processing).
* **Sprint 13 (Social Commerce):** E12 (TikTok, IG, FB, Google Shopping). *Highest complexity sprint.*
* **Sprint 14 (i18n):** E21 (Multilingual architecture, English-only deployment).

### PHASE 5 — Intelligence & Operations (Sprints 15–16)
* **Goal:** Analytics and system hygiene.
* **Sprint 15 (Analytics):** E09 (Revenue dashboard, Looker empty states).
* **Sprint 16 (Hygiene):** E19 (Schema drift detection), E10 (Dunning), Canary deployments, SYS-18 version detection.

---

## 5. QA & UAT Gates

Since there is no dedicated QA team, quality is maintained through a combination of Agent-driven TDD and Human-driven UAT.

1. **Agent Unit/Integration Tests (Automated):** AI must write tests for business logic (e.g., Stripe webhooks, cart totals) before writing implementation. Coverage must be >80% for backend functions.
2. **Human UAT (Manual):** At the end of every Phase (or Sprint), the `feature/sprint-*` branch is merged into the `dev` branch, triggering a deployment to Staging. The solo founder tests the integration in Staging. Once UAT passes, the `dev` branch is merged into `main` for production.
3. **Design Review:** Since AI agents struggle with visual polish, the Human must enforce the "Rich Aesthetics" guidelines manually during Staging UAT, rejecting Agent work that looks too basic or lacks micro-animations.

---

## Next Steps

1. Review and approve this Roadmap.
2. Generate `07a-agent-execution-tracker.md` to serve as the living SSOT for the AI agents.
3. Begin Phase 0 (Project setup, creating environments, and spikes).
