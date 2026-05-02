# Agent Execution Tracker (SSOT)

> **Purpose:** This is the Single Source of Truth (SSOT) for all AI Agents working on KloudShop. It tracks the exact state of development at sprint level.
>
> **Rule for Agents — MANDATORY SESSION START PROTOCOL:**
> 1. Read `00-MASTER-PRD.md` first (vision, commandments, architecture, epic map).
> 2. Read this file to find your assigned task and current sprint status.
> 3. Read `08a-api-specification.md` for the exact endpoint contract before writing any code.
> 4. Check `04b-mvp-scope.md` to confirm your story is MVP — do not implement Post-MVP features.
> 5. Only open `04-feature-stories.md` or other spec files if this tracker explicitly directs you to.
> 6. **Always update this tracker before handing back to the Human.**
> 7. **SOP:** At the end of each sprint/phase, insert a "TDD Test Results" section summarizing passing tests and results.

---

## Current Environment Status

| Environment | GCP/Firebase Project | Git Branch | Status |
|-------------|----------------------|------------|--------|
| **Dev** | `kloudshop-dev` | `dev/phase1` | PHASE 1 COMPLETE ✅ |
| **Staging** | `kloudshop-staging` | `dev` | Ready for Phase 2 |
| **Prod** | `kloudshop-prod` | `main` | Baseline Set |

---

## Active Sprint: PHASE 2 — Core Commerce (Sprint 4)

> [!IMPORTANT]
> Focus **only** on the active sprint. Do not start work on future sprints. Check `08a-api-specification.md` section for the relevant Epic before writing any endpoint.

### Phase 0 Checklist — Remediation & Setup
*Goal: Ensure baseline infrastructure and TDD environment are functional.*

- [x] **Infrastructure:** Generate real `firebase_options.dart` for `kloudshop-dev`
- [x] **Infrastructure:** Secure `service_account.json` for backend dev
- [x] **TDD Setup:** Install `pytest`, `pytest-asyncio`, `httpx` in `/backend`
- [x] **TDD Setup:** Create base test suite for Auth module
- [x] **Validation:** Verify `gcloud` and `firebase` CLI connectivity

### Phase 1 Checklist

#### Sprint 1 — Auth (E01) — API: `/auth/*`
- [x] `GET /auth/me` — Identity check endpoint with JWT validation + RBAC claims
- [x] `POST /auth/invitations` — Staff invite by Gmail + role assignment
- [x] `GET /auth/invitations` — List pending invitations
- [x] `DELETE /auth/invitations/{id}` — Cancel invitation
- [x] `PATCH /auth/staff/{uid}/roles` — Update staff roles (Firebase custom claims)
- [x] `DELETE /auth/staff/{uid}` — Revoke staff access (invalidate JWT within 60s)
- [x] `POST /auth/ownership/transfer` — Owner account transfer
- [x] `POST /auth/b2b-buyers/register` — B2B buyer registration via invite token
- [x] `POST /auth/consumers/register` — DTC consumer post-checkout account creation
- [x] Flutter `LoginPage` (glassmorphism UI) — Google Sign-In button implemented
- [x] `AuthGate` in `app.dart` — auth state routing implemented
- [x] `AuthService` — Firebase Auth + GoogleSignIn service with uninitialized fallback
- [x] `shared/auth.py` — JWT validation (tenant_id now optional for profile fetch)
- [x] `shared/rbac.py` — Permission matrix + `PermissionChecker` enforces `tenant_id` for scoped ops
- [x] **REMEDIATION:** Fixed 403 error blocking new merchants without `tenant_id` from accessing `/auth/me`
- [x] `firebase-admin` + `python-jose` added to `backend/requirements.txt`
- [x] Firebase initialized in `backend/main.py` lifespan handler
- [x] `firebase_core`, `firebase_auth`, `google_sign_in` added to `frontend/pubspec.yaml`
- [x] API Technical Contract defined in `08a-api-specification.md` ✅ Approved
- [x] **BLOCKING:** `firebase_options.dart` — run `flutterfire configure` in `/frontend`
- [x] **BLOCKING:** `service_account.json` — place Firebase Admin SDK key in `/backend`
- [x] Unit tests: JWT validation, RBAC middleware, invitation flow

##### TDD Test Results — Sprint 1 (Auth Foundation)
| Test File | Status | Passing / Total |
|-----------|--------|-----------------|
| `test_auth.py` | PASS | 7 / 7 |
| `test_auth_extended.py` | PASS | 4 / 4 |

#### Sprint 2 — Infrastructure (E19) — API: `/internal/provision-tenant`
- [x] GCP Cloud SQL instance `kloudshop-db-dev` created
- [x] GCP tenant provisioning script (`provision_tenant.ps1` for Windows, `.sh` for Linux)
- [x] Alembic base migration for tenant schema
- [x] `POST /internal/provision-tenant` — Internal provisioning endpoint implemented (Fixed for Dev/SQLite mode)
- [x] Unit tests: `test_provisioning.py` implemented and passing
- [x] **REMEDIATION:** Ensure `Tenant` record is created in platform DB even when schema creation is skipped (SQLite/Dev)

##### TDD Test Results — Sprint 2 (Infrastructure)
| Test File | Status | Passing / Total |
|-----------|--------|-----------------|
| `test_provisioning_extended.py` | PASS | 4 / 4 |

#### Sprint 3 — Billing & Admin (E10 + E18) — API: `/billing/*`, `/webhooks/stripe`, `/platform/*`
- [x] `GET /billing/subscription` — Current tier + Stripe status
- [x] `POST /billing/upgrade` — Tier upgrade with explicit consent flow
- [x] `GET /billing/invoices` — Invoice list with Stripe integration
- [x] `POST /billing/stripe/portal` — Stripe customer portal session link
- [x] **REMEDIATION:** GCS Connectivity "Peace of Mind" test with auto-cleanup implemented
- [x] **REMEDIATION:** Smart, cost-aware `manage_db.sh` interactive script implemented
- [x] `POST /webhooks/stripe` — Stripe webhook handler (signature validated)
- [x] Trial 3-trigger hard-stop system (Cloud Scheduler daily job)
- [x] Dunning automation (Stripe webhook → account suspension)
- [x] `GET /platform/merchants` — List of all tenants
- [x] `GET /platform/dashboard` — Platform Admin MRR + health dashboard
- [x] `PATCH /platform/merchants/{id}/approve` — Trial signup approval
- [x] Platform Admin RBAC guard (`admin:platform` permission) (Verified in `rbac.py`)
- [x] Unit tests: trial triggers, billing endpoints, RBAC middleware

##### TDD Test Results — Sprint 3 (Billing Foundation)
| Test File | Status | Passing / Total |
|-----------|--------|-----------------|
| `test_billing.py` | PASS | 4 / 4 |

##### 🏆 PHASE 1 LITMUS TEST: Merchant Provisioning (2026-05-01)
*   **Result:** SUCCESS ✅
*   **Tenant:** `enigmatekinc`
*   **Outcome:** GCP Storage Bucket created, CORS applied, and SQLite platform record initialized.
*   **Verification:** Verified in GCP Console and via backend verbose logs.
*   **Sign-off:** Multi-tenant infrastructure is ready for Catalog and Orders.

---

## Phase 2 Checklist — Core Commerce (Sprints 4–7)

*(Do not start until Phase 1 is complete)*

#### Sprint 4 — Catalog (E04) — API: `/products/*`, `/collections/*`
- [x] Full CRUD for products with unlimited variants (POST/GET implemented)
- [x] Bulk CSV/Excel import with AI column mapping (Implemented)
- [x] Collections CRUD + product assignment (Implemented)
- [x] SEO metadata editing with auto-301 redirect on slug change (Implemented)
- [x] Google Shopping feed update trigger on product save (Implemented)
- [x] Unit tests: variant limits, pricing constraints, and tenant isolation

##### TDD Test Results — Sprint 4 (Catalog Foundation)
| Test File | Status | Passing / Total |
|-----------|--------|-----------------|
| `test_catalog.py` | PASS | 7 / 7 |
| `test_collections.py` | PASS | 4 / 4 |
| `test_bulk_import.py` | PASS | 2 / 2 |
| `test_seo_redirects.py` | PASS | 2 / 2 |

#### Sprint 5 — Orders (E05) — API: `/orders/*`
- [ ] `POST /storefront/{tenant}/checkout/payment-intent` — Stripe Payment Intent
- [ ] `POST /storefront/{tenant}/checkout/confirm` — Order creation + inventory lock
- [ ] `PATCH /orders/{id}/fulfil` — Fulfilment + tracking + Resend notification
- [ ] `POST /orders/{id}/refund` — Full/partial Stripe refund
- [ ] `POST /orders/{id}/notes` — Internal order notes
- [ ] `GET /orders/export` — CSV export with date range filter
- [ ] Unit tests: inventory reservation, payment failure rollback, partial refund guard

#### Sprint 6 — Inventory (E06) — API: `/inventory/*`, `/suppliers/*`, `/purchase-orders/*`
- [ ] Inventory dashboard with lead-time-aware urgency scoring
- [ ] AI replenishment recommendations (Vertex AI or rule-based fallback)
- [ ] Supplier CRUD + preference ranking (atomic rank swap)
- [ ] Purchase order lifecycle (Draft → Send → Receive)
- [ ] Supplier performance scorecard metrics
- [ ] Unit tests: urgency algorithm, rank swap atomicity, PO partial receipt

#### Sprint 7 — Storefront, Shipping & Tax (E17 + E20 + E13) — API: `/storefront/*`, `/shipping/*`, `/tax/*`
- [ ] SSR product listing, PDP, collection pages (FastAPI + Flutter Web HTML renderer)
- [ ] AI consultative search (RAG via Vertex AI embeddings + pgvector)
- [ ] Guest checkout flow + post-purchase account creation
- [ ] Real-time carrier rate calculation (parallel multi-carrier queries)
- [ ] Shipping label generation + manual fulfilment fallback
- [ ] Free shipping rules engine
- [ ] Stripe Tax embedded components (ConnectTaxSettings, ConnectTaxRegistrations)
- [ ] Automated tax calculation on checkout Payment Intent
- [ ] Unit tests: CWV benchmarks, carrier fallback, tax calculation, inventory lock at checkout

---

## Phase 3 Checklist — Merchant Experience (Sprints 8–10)

#### Sprint 8 — Onboarding (E02) — API: `/onboarding/*`
> ⚠️ CSV/Excel import ONLY. Do NOT implement `/onboarding/migration/scrape` — Post-MVP.
- [ ] Merchant signup + tier selection
- [ ] GCP region selection
- [ ] Product/customer/order CSV import with AI column mapping + partial success
- [ ] Brand identity setup (name, logo, colours)
- [ ] Personalised migration runbook generation + PDF download
- [ ] Tier upgrade consent flow

#### Sprint 9 — Themes (E03) — API: `/themes/*`
- [ ] Theme catalogue browsing + selection
- [ ] WYSIWYG editor (component stack, config panel, content slots)
- [ ] Draft save / apply to storefront / discard flow
- [ ] Design token overrides
- [ ] One-click theme switching with content carry-forward algorithm

#### Sprint 10 — Platform Features (E08 + E14 + E15 + E23) — API: `/features/*`, `/pricing/rules/*`, `/export/*`, `/ai/*`
- [ ] Feature Catalogue toggle engine (Firebase Realtime DB progress, Alembic migration runner)
- [ ] Feature setup wizard (schema-driven, dynamic form rendering)
- [ ] Dynamic pricing rules (stock-age, velocity, flash sale)
- [ ] Full data export on demand (CSV/JSON via Cloud Tasks)
- [ ] AI Copywriter: Brand Voice profile, product title/description generation, blog enhancement

---

## Phase 4 Checklist — B2B & Channels (Sprints 11–14)

#### Sprint 11 — B2B (E07) — API: `/b2b/*`
- [ ] B2B buyer account CRUD + invitation flow
- [ ] Custom price list creation + buyer assignment
- [ ] B2B approval workflow (threshold-based, FCM notifications)
- [ ] B2B buyer portal catalog browsing (scoped + AI search)
- [ ] Net-terms Stripe Invoice generation (Net-30/60/90)

#### Sprint 12 — POS (E11) — API: `/pos/*`
- [ ] POS Operator role + location scope assignment
- [ ] Browser-native in-store sale processing (Stripe Terminal optional)
- [ ] Unified inventory deduction with row-level lock
- [ ] POS order_source attribution in BigQuery

#### Sprint 13 — Social Commerce (E12) — API: `/channels/*`, `/feeds/*`
- [ ] Channel Sync Service (unified abstraction with pluggable adapters)
- [ ] TikTok Shop OAuth + catalog sync
- [ ] Instagram Shopping OAuth + catalog sync
- [ ] Facebook Shops OAuth + catalog sync
- [ ] Google Merchant Center connection + live Shopping feed

#### Sprint 14 — i18n + Blog (E21 + E22) — API: `/i18n/*`, `/blog/*`, `/storefront/{tenant}/blog/*`
- [ ] Locale architecture (schema, path-prefix routing, hreflang — English only at MVP)
- [ ] Blog post CRUD (create, edit, schedule, publish, archive)
- [ ] Blog categories + tags management
- [ ] SSR blog index + post pages with JSON-LD Article structured data
- [ ] Blog included in XML sitemap

---

## Phase 5 Checklist — Intelligence & Operations (Sprints 15–16)

#### Sprint 15 — Analytics (E09) — API: `/analytics/*`
- [ ] Revenue overview dashboard (GMV, orders, AOV, conversion — refreshed every 15s)
- [ ] Needs Attention panel (pending orders, reorder overdue, B2B approvals)
- [ ] Vertex AI demand forecasting (with data-sufficiency disclaimer < 90 days / 100 orders)
- [ ] Looker Studio embed with scoped BigQuery token

#### Sprint 16 — Hygiene (E19 + E18) — API: `/internal/*`
- [ ] Nightly schema drift detection (Cloud Scheduler → compare live schema vs Alembic head)
- [ ] GDPR right-to-erasure pipeline (PII anonymisation, not deletion)
- [ ] Production canary deployment approval flow (GCP Cloud Deploy)
- [ ] SYS-18 version detection (service worker + version.json banner)

---

## v1.1 Backlog (Post-MVP — Do NOT implement during Phase 1–5)

| Feature | Epic | Notes |
|---------|------|-------|
| Competitor scraping migration | E02 | `/onboarding/migration/scrape` — blocked |
| Secondary GCP region | E02 | On-demand activation — deferred |
| Theme Favourites | E03 | US-020 — organisational, not functional |
| Full Internal Messaging | E16 | UI skeleton at MVP (`/messages/*` full = v1.1) |
| Loyalty Programme | E17 | First Feature Catalogue item in v1.1 |
| AI Auto-Translation pipeline | E21 | Google Cloud Translation API wiring |
| Merchant Admin UI language | E21 | ARB files beyond `en` |
| Email marketing automation | Feature Catalogue | v1.1 |
| Gift cards | Feature Catalogue | v1.1 |
| PayPal at checkout | — | v1.1 or v2 |

---

## Agent Handoff Protocol

### When starting a session:
1. Read `00-MASTER-PRD.md` — commandments and architecture.
2. Read this file — find active sprint and your specific task.
3. Read `08a-api-specification.md` — locate the endpoint contract for your Epic.
4. Confirm story is MVP in `04b-mvp-scope.md`.
5. Only read `04-feature-stories.md` if you need Gherkin acceptance criteria for a specific story.

### When completing a task:
1. Verify all unit/integration tests pass (>80% backend coverage).
2. Confirm implementation matches `08a-api-specification.md` exactly (method, path, RBAC, models).
3. Update this checklist: `[ ]` → `[x]`.
4. Update `Current Environment Status` table if infra/env changed.
5. Commit code with message format: `feat(E01): implement GET /auth/me JWT validation`.
6. Prompt the Human to run manual verification via IDE debugger or approve the next task.
