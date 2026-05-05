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
| **Dev** | `kloudshop-dev` | `main` | MVP COMPLETE ✅ |
| **Staging** | `kloudshop-staging` | `dev` | Phase 5 Complete ✅ |
| **Prod** | `kloudshop-prod` | `main` | Baseline Set |

---

## Active Sprint: PHASE 5 — Intelligence & Operations (Sprint 15)

> [!IMPORTANT]
> Focus **only** on the active sprint. We are currently implementing the high-fidelity Merchant Dashboard UI and functional parity for all management modules.

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
- [x] `GET /billing/subscription` — Current tier + Stripe status (Synced with DTC/B2B/Hybrid model)
- [x] `POST /billing/upgrade` — Tier upgrade with explicit consent flow (Mock Mode enabled for Dev)
- [x] `GET /billing/invoices` — Invoice list with Stripe integration (Mocked for Dev)
- [x] `POST /billing/stripe/portal` — Stripe customer portal session link (Mocked for Dev)
- [x] **REMEDIATION:** GCS Connectivity "Peace of Mind" test with auto-cleanup implemented
- [x] **REMEDIATION:** Smart, cost-aware `manage_db.sh` interactive script implemented
- [x] **REMEDIATION:** Billing stabilization complete with IntrinsicHeight UI fix and Mock Billing Mode.
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
| `test_orders.py` | PASS | 6 / 6 |
| `test_inventory.py` | PASS | 3 / 3 |

#### Sprint 5 — Orders (E05) — API: `/orders/*`
- [x] `POST /storefront/{tenant}/checkout/payment-intent` — Stripe Payment Intent
- [x] `POST /storefront/{tenant}/checkout/confirm` — Order creation + inventory lock
- [x] `PATCH /orders/{id}/fulfil` — Fulfilment + tracking + Resend notification
- [x] `POST /orders/{id}/refund` — Full/partial Stripe refund
- [x] `POST /orders/{id}/notes` — Internal order notes
- [x] `GET /orders/export` — CSV export with date range filter
- [x] Unit tests: inventory reservation, payment failure rollback, partial refund guard

#### Sprint 6 — Inventory (E06) — API: `/inventory/*`, `/suppliers/*`, `/purchase-orders/*`
- [x] Inventory dashboard with lead-time-aware urgency scoring
- [x] AI replenishment recommendations (Vertex AI or rule-based fallback)
- [x] Supplier CRUD + preference ranking (atomic rank swap)
- [x] Purchase order lifecycle (Draft → Send → Receive)
- [x] Supplier performance scorecard metrics
- [x] Unit tests: urgency algorithm, rank swap atomicity, PO partial receipt

#### Sprint 7 — Storefront, Shipping & Tax (E17 + E20 + E13) — API: `/storefront/*`, `/shipping/*`, `/tax/*`
- [x] SSR product listing, PDP, collection pages (FastAPI + Flutter Web HTML renderer)
- [x] AI consultative search (Basic keyword search fallback implemented)
- [x] Guest checkout flow + post-purchase account creation
- [x] Real-time carrier rate calculation (parallel multi-carrier queries)
- [x] Shipping label generation + manual fulfilment fallback (Mocked label creation)
- [x] Free shipping rules engine (Threshold-based logic implemented)
- [x] Automated tax calculation on checkout Payment Intent
- [x] Unit tests: CWV benchmarks, carrier fallback, tax calculation, inventory lock at checkout

##### TDD Test Results — Sprint 7 (Storefront & Shipping)
| Test File | Status | Passing / Total |
|-----------|--------|-----------------|
| `test_storefront.py` | PASS | 5 / 5 |

---

## Phase 3 Checklist — Merchant Experience (Sprints 8–10)

#### Sprint 8 — Onboarding (E02) — API: `/onboarding/*`
> ⚠️ CSV/Excel import ONLY. Do NOT implement `/onboarding/migration/scrape` — Post-MVP.
- [x] Merchant signup + tier selection
- [x] GCP region selection
- [x] Product/customer/order CSV import with AI column mapping + partial success
- [x] Brand identity setup (name, logo, colours)
- [x] Personalised migration runbook generation + PDF download
- [x] Tier upgrade consent flow

##### TDD Test Results — Sprint 8 (Onboarding)
| Test File | Status | Passing / Total |
|-----------|--------|-----------------|
| `test_onboarding.py` | PASS | 1 / 1 |

#### Sprint 9 — Themes (E03) — API: `/themes/*`
- [x] Theme catalogue browsing + selection
- [x] WYSIWYG editor (component stack, config panel, content slots)
- [x] Draft save / apply to storefront / discard flow
- [x] Design token overrides
- [x] One-click theme switching with content carry-forward algorithm

##### TDD Test Results — Sprint 9 (Themes)
| Test File | Status | Passing / Total |
|-----------|--------|-----------------|
| `test_themes.py` | PASS | 1 / 1 |

#### Sprint 10 — Platform Features (E08 + E14 + E15 + E23) — API: `/features/*`, `/pricing/rules/*`, `/export/*`, `/ai/*`
- [x] Feature Catalogue toggle engine (Firebase Realtime DB progress, Alembic migration runner)
- [x] Feature setup wizard (schema-driven, dynamic form rendering)
- [x] Dynamic pricing rules (stock-age, velocity, flash sale)
- [x] Full data export on demand (CSV/JSON via Cloud Tasks)
- [x] AI Copywriter: Brand Voice profile, product title/description generation, blog enhancement

##### TDD Test Results — Sprint 10 (Platform Features)
| Test File | Status | Passing / Total |
|-----------|--------|-----------------|
| `test_features.py` | PASS | 4 / 4 |
| `test_ai.py` | PASS | 3 / 3 |
| `test_export.py` | PASS | 1 / 1 |
| `test_pricing.py` | PASS | 1 / 1 |
| `test_b2b.py` | PASS | 9 / 9 |

---

## Phase 4 Checklist — B2B & Channels (Sprints 11–14)

#### Sprint 11 — B2B (E07) — API: `/b2b/*`
- [x] B2B buyer account CRUD + invitation flow
- [x] Custom price list creation + buyer assignment
- [x] B2B approval workflow (threshold-based, FCM notifications)
- [x] B2B buyer portal catalog browsing (scoped + AI search)
- [x] Net-terms Stripe Invoice generation (Net-30/60/90)

#### Sprint 12 — POS (E11) — API: `/pos/*`
- [x] POS Operator role + location scope assignment
- [x] Browser-native in-store sale processing (Stripe Terminal optional)
- [x] Unified inventory deduction with row-level lock
- [x] POS order_source attribution in BigQuery

##### TDD Test Results — Sprint 12 (POS Infrastructure)
| Test File | Status | Passing / Total |
|-----------|--------|-----------------|
| `test_pos.py` | PASS | 4 / 4 |


#### Sprint 13 — Social Commerce (E12) — API: `/channels/*`, `/feeds/*`
> [!NOTE]
> Merchant Billing stabilization (Sprint 3) is 95% complete. Remaining UI/UX polish and real Stripe transition items are tracked in `artifacts/long_outstanding_issues.md`.
- [x] Channel Sync Service (unified abstraction with pluggable adapters)
- [x] TikTok Shop OAuth + catalog sync
- [x] Instagram Shopping OAuth + catalog sync
- [x] Facebook Shops OAuth + catalog sync
- [x] Google Merchant Center connection + live Shopping feed

##### TDD Test Results — Sprint 13 (Social Commerce)
| Test File | Status | Passing / Total |
|-----------|--------|-----------------|
| `test_channels.py` | PASS | 6 / 6 |
| `test_blog.py` | PASS | 4 / 4 |
| `test_seo.py` | PASS | 2 / 2 |
| `test_i18n.py` | PASS | 1 / 1 |
| `test_analytics.py` | PASS | 3 / 3 |
| `test_hygiene.py` | PASS | 2 / 2 |

#### Sprint 14 — i18n + Blog (E21 + E22) — API: `/i18n/*`, `/blog/*`, `/storefront/{tenant}/blog/*`
- [x] Locale architecture (schema, path-prefix routing, hreflang — English only at MVP)
- [x] Blog post CRUD (create, edit, schedule, publish, archive)
- [x] Blog categories + tags management
- [x] SSR blog index + post pages with JSON-LD Article structured data
- [x] Blog included in XML sitemap

---

## Phase 5 Checklist — Intelligence & Operations (Sprints 15–16)

#### Sprint 15 — Analytics & Dashboard (E09) — API: `/analytics/*`
- [x] **Revenue Overview (Dashboard):** Real-time GMV, orders, AOV, conversion (Implemented).
- [x] **Needs Attention Panel:** Pending orders, reorder overdue, B2B approvals (Implemented).
- [x] **Interactive Visualization:** High-fidelity Line/Grouped Bar charts with comparative targets (Implemented).
- [ ] **Advanced Analytics (BigQuery):** Data export pipeline to BigQuery for long-term storage.
- [ ] **Vertex AI Forecasting:** Demand forecasting using Vertex AI (requires 90 days of data).
- [ ] **Looker Studio Integration:** Embedded Looker Studio dashboards via scoped BigQuery tokens.

#### Sprint 16 — Hygiene (E19 + E18) — API: `/internal/*`
- [ ] Nightly schema drift detection (Cloud Scheduler → compare live schema vs Alembic head)
- [ ] GDPR right-to-erasure pipeline (PII anonymisation, not deletion)
- [ ] Production canary deployment approval flow (GCP Cloud Deploy stub)
- [ ] SYS-18 version detection (service worker + version.json banner)
- [/] **Frontend:** Implementation of other dashboard views (Catalog, Orders, Customers, Blog, etc.)

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
