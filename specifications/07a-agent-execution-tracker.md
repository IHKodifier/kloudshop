# Agent Execution Tracker (SSOT)

> **Purpose:** This document is the Single Source of Truth (SSOT) for all AI Agents working on KloudShop. It tracks the exact state of development.
> **Rule for Agents:** *Always* read this file before starting work. *Always* update this file before handing back to the Human.

---

## Current Environment Status

| Environment | GCP/Firebase Project | Git Branch | Status |
|-------------|----------------------|------------|--------|
| **Dev** | `kloudshop-dev` | `feature/*` | Setup Complete |
| **Staging** | `kloudshop-staging` | `dev` | Setup Complete |
| **Prod** | `kloudshop-prod` | `main` | Setup Complete |

---

## Active Sprint: PHASE 0 (Spikes & Setup)

**Instructions for Agent:** Focus *only* on the active sprint. Do not start work on future sprints.

### Phase 0 Checklist
- [x] Initialize Git Monorepo (`/frontend`, `/backend`, `/infrastructure`).
- [x] Setup `kloudshop-dev`, `kloudshop-staging`, `kloudshop-prod` GCP/Firebase projects.
- [x] Configure CI/CD pipelines (GitHub Actions -> Firebase Hosting/Cloud Run).
- [x] **Infrastructure Scripts:** Write scripts to provision tenant GCP resources.
- [x] **Cost Control & Backup Scripts:** Write `gcloud` scripts to Start/Stop Cloud SQL instances AND dump/restore seed data to Cloud Storage.
- [x] **Spike ASM-01:** Flutter Web CWV benchmark on GCP Cloud Run.
- [x] **Spike RSK-02:** Wildcard SSL two-level validation.
- [x] **Spike ASM-06:** Service worker + version.json interop.

---

## Upcoming Sprints (Backlog)

*Do not start these until Phase 0 is 100% complete.*

### PHASE 1 — Foundation (Sprints 1–3)
- [ ] **Sprint 1 (Auth):** E01 (Firebase Auth, RBAC, App Check).
- [ ] **Sprint 2 (Infrastructure):** E19 (GCP Tenant Provisioning - SYS-01).
- [ ] **Sprint 3 (Billing & Admin):** E10 (Stripe Billing, 3-trigger trial system), E18 (Admin login).

### PHASE 2 — Core Commerce (Sprints 4–7)
- [ ] **Sprint 4 (Catalog):** E04 (Products, variants, collections, SEO).
- [ ] **Sprint 5 (Orders):** E05 (Order placement, fulfilment, refunds).
- [ ] **Sprint 6 (Inventory):** E06 (Inventory, suppliers, purchase orders).
- [ ] **Sprint 7 (Storefront & Tax):** E17 (Consumer DTC Storefront SSR), E20 (Shipping), E13 (Stripe Tax).

### PHASE 3 — Merchant Experience (Sprints 8–10)
- [ ] **Sprint 8 (Onboarding):** E02 (CSV import, manual setup wizard, runbook). *Automated competitor scraping deferred.*
- [ ] **Sprint 9 (Themes):** E03 (WYSIWYG editor, theme library, content slots).
- [ ] **Sprint 10 (Platform Features):** E08 (Feature catalogue architecture), E15 (Data Export).

### PHASE 4 — B2B & Channels (Sprints 11–14)
- [ ] **Sprint 11 (B2B):** E07 (B2B buyer portal, price lists, net terms).
- [ ] **Sprint 12 (POS):** E11 (In-store POS processing).
- [ ] **Sprint 13 (Social Commerce):** E12 (TikTok, IG, FB, Google Shopping).
- [ ] **Sprint 14 (i18n):** E21 (Multilingual architecture, English-only deployment).

### PHASE 5 — Intelligence & Operations (Sprints 15–16)
- [ ] **Sprint 15 (Analytics):** E09 (Revenue dashboard, Looker empty states).
- [ ] **Sprint 16 (Hygiene):** E19 (Schema drift detection), E10 (Dunning), Canary deployments, SYS-18 version detection.

---

## Agent Handoff Protocol

When an AI Agent completes a task, they must:
1. Verify all unit/integration tests pass (TDD).
2. Update the checklist above (change `[ ]` to `[x]`).
3. Commit code with a descriptive message.
4. Prompt the Human to run manual verification or start the next task.
