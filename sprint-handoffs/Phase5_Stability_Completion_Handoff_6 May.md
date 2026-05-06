# Phase 5: Dashboard Stability & Merchant Experience Handoff (2026-05-06)

## Context
This session finalized the Phase 5 stabilization. We addressed the "Storefront not found" bug, finalized the public profile API, and ensured the Merchant Dashboard is fully ready for high-fidelity UI management.

## Accomplishments
### 1. Data Persistence & Stability
- **Status**: COMPLETE.
- **Changes**: Migrated the local development/testing database from in-memory SQLite to a persistent file (`test_persistent.db`).
- **Auto-Heal**: Implemented auto-provisioning in the backend to recreate tenant records if a user is authenticated but the record is missing.

### 2. Blog Module Finalization
- **Status**: COMPLETE.
- **Backend**: Implemented `PUT` and `PATCH` endpoints for `BlogPost` updates.
- **Frontend**: Fixed parameter errors and verified the update flow in `BlogPostEditor`.

### 3. Storefront Identity & Profile
- **Status**: COMPLETE.
- **Feature**: Fixed the **404 "Storefront not found"** error by ensuring a `BrandProfile` is automatically created and published when a merchant seeds demo data.
- **API**: Verified `GET /api/v1/storefront/{tenant}/profile` works for public consumers.

### 4. Demo Data Seeding
- **Status**: COMPLETE.
- **Fix**: Resolved a critical backend crash caused by missing `tenant_id` columns in `StockLocation` and `Inventory` models.
- **Feature**: Merchants can now seed 10 mock orders, customers, AND their brand profile to verify the full platform surface.

## Technical Debt / Blockers
- **GCP Provisioning**: The `provision-tenant` script is still a placeholder for actual GCP resource creation (IAM, GCS, etc.); it currently only simulates the process in dev mode.
- **Auth Sync**: Firebase custom claims are applied during provisioning, but a session refresh is often required for the frontend to pick up the `tenant_id`.

## Next Goals: Phase 5.5, 6 & 7 (The Path to Beta)

### 1. Phase 5.5 — Remediation & Hardening (Mock-Parity)
- **Billing Redirects**: Fix the blank route issue when returning from checkout (`/dashboard?session_id=...`).
- **Feature Gating**: Implement tier-based logic (DTC/B2B/Hybrid) to restrict or enable platform modules based on the subscription.
- **Auth Sync**: Eliminate manual refresh requirements after provisioning.

### 2. Phase 6 — Themes & The "Zoomer" Experience
- **WYSIWYG Editor**: Implement the visual theme editor and design token overrides.
- **The Zoomer Flow**: Build the end-to-end consumer journey: **Browse** -> **Add to Cart** -> **Guest Checkout** -> **Post-Order Signup**.
- **Self-Service**: Enable consumers to request refunds and view status without merchant intervention.

### 3. Phase 7 — Production Readiness (Post-LLC)
- **Custom Domains**: Automated CNAME and SSL provisioning.
- **Stripe Transition**: Final "wiring up" of real Stripe Test/Live modes once the UK LLC is established.

## Command Center
- **Start Backend**: `.\start_backend.ps1`
- **Start Frontend**: `flutter run -d chrome`
- **Latest Dev Branch**: `git checkout dev; git pull origin dev`
