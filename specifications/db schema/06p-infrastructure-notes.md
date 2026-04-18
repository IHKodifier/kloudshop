# Stage 6 — Infrastructure & Pipeline Notes (06p)

> **Purpose:** This document specifies critical non-DDL infrastructure pipelines, configuration notes, and architectures identified during the KloudShop Data Model generation that must be implemented outside the core PostgreSQL schema.
> 
> **Scope:** Web version detection (SYS-18 / DMF-09), Google Cloud Identity Platform (GCIP) tenant provisioning flow, and the Load Balancer (LB) log-based trial visitor counting pipeline.

---

## 1. Web Version Detection Infrastructure (SYS-18 / DMF-09)

To ensure merchants always run the latest version of the Flutter Web admin panel without disruptive forced reloads, we implement a custom service worker polling strategy.

### 1.1 The `version.json` Asset
A static JSON file generated during the CI/CD pipeline and served via Cloud CDN.

*   **Location:** `https://admin.kloudshop.com/version.json`
*   **Cache Headers:** `Cache-Control: no-store, must-revalidate` (Crucial: never cached by CDN or browser).
*   **Format:**
    ```json
    {
      "build": "<git-sha>",
      "deployed_at": "2026-04-17T12:00:00Z",
      "features_added": 2
    }
    ```
*   **Generation:** Written by Cloud Build at each production deployment. `features_added` is calculated as the diff of `feature_registry` rows between the previous and current build.

### 1.2 Custom Service Worker (Flutter Web)
The Flutter Web build is executed with `--pwa-strategy=none` to bypass default service worker caching, allowing us to implement a custom update flow.

*   **Polling Logic:** The service worker polls `/version.json` every 10 minutes and on initial user interaction after a period of idle time.
*   **Hash Mismatch Event:** If the `build` SHA changes, the service worker sends a message to the client:
    `postMessage({ type: 'NEW_VERSION_AVAILABLE', features_added: N })`
*   **Client Handling (JS Interop):** The Flutter app listens via `dart:js_interop`.
    *   **Admin Shell:** Renders a non-intrusive "Update Available" banner.
    *   **Public Storefront:** *Never* shown. The public storefront relies on standard HTTP caching and is stateless. 
        *   *Cache Invalidation Strategy:* When a merchant publishes a new theme or updates storefront content, the backend automatically issues a targeted cache invalidation request to the Cloud CDN for that specific tenant's domain/paths. 
        *   Static theme assets (CSS/JS) use content-addressable hashing in their filenames (e.g., `theme-a1b2c3d.css`) with long-term caching, meaning the newly served HTML instantly points visitors to the fresh theme without requiring them to clear their browsers' caches.
*   **User Actions:**
    *   **"Update now":** Sends `skipWaiting()` to the service worker, followed by `clients.claim()` and a hard `window.location.reload()`.
    *   **"Remind me later":** Hides the banner. Re-shown after 4 hours or on the next session start.

### 1.3 Mobile App Fallback
For the Flutter iOS/Android admin app, we use the `package_info_plus` package checking against a `/version/latest` FastAPI endpoint, triggering the standard OS-level App Store/Play Store update banner.

### 1.4 Risk Mitigation
**Risk:** Custom service worker breaks Flutter's own hash-based cache manifest (CanvasKit, main.dart.js).
**Fallback:** If the service worker proves unstable in Phase 0 spikes, we will fallback to `setInterval` polling directly in `main.dart` via `dart:js`. This achieves the exact same UX but sacrifices background download caching.

---

## 2. GCIP Tenant Provisioning & Auth Claims Flow

KloudShop uses Google Cloud Identity Platform (GCIP) for authentication. Given the multi-tenant architecture, strict RBAC and tenant isolation must be enforced via custom claims.

### 2.1 Custom Claim Schema
Firebase Auth custom claims are strictly reserved for RBAC and routing, adhering to the 1000-byte limit. UI preferences (theme, language) are explicitly excluded and stored in PostgreSQL (`staff_users.preferences` / `consumers.preferences`).

**Staff Claim Structure:**
```json
{
  "tenant_id": "tnt_8f92a1b",
  "account_type": "staff",
  "is_owner": true,
  "roles": ["admin", "inventory_manager"]
}
```

**Consumer Claim Structure (DEC-03):**
```json
{
  "tenant_id": "tnt_8f92a1b",
  "account_type": "consumer"
}
```

### 2.2 Staff Provisioning Flow
1.  **Signup:** Merchant creates an account via the central KloudShop portal.
2.  **GCIP Creation:** Account is created in the central GCIP tenant.
3.  **FastAPI Hook:** A blocking GCIP function/hook calls FastAPI to provision the PostgreSQL `tenants` and `staff_users` records.
4.  **Claim Injection:** FastAPI assigns the newly generated `tenant_id`, `account_type: "staff"`, and `is_owner: true` claims.
5.  **Token Minting:** GCIP returns the JWT. The Flutter admin app uses this token for all subsequent requests. API Gateway routes requests to the correct shard based on the `tenant_id` claim.

### 2.3 Consumer Provisioning Flow (Storefront)
1.  **Storefront Registration:** Consumer registers on a specific merchant's storefront.
2.  **Per-Storefront Isolation:** GCIP Identity Tenants (Tenant-in-Tenant) are used. Each KloudShop merchant gets a dedicated GCIP Identity Tenant to completely isolate consumer pools.
3.  **FastAPI Hook:** Hook creates the `consumers` record in PostgreSQL (storing the opaque `gcip_uid`).
4.  **Claim Injection:** FastAPI sets `tenant_id` and `account_type: "consumer"`.
5.  **Session Establishment:** The JWT is used to sign the session token, linking the consumer to their cart (`consumer_sessions`).

---

## 3. LB Log-Based Trial Visitor Count Pipeline (DMF-08)

During the 30-day trial (and particularly during the 216-hour hard-stop window), KloudShop sends daily urgency emails to merchants: *"Your store received {XX} visitors in the past 24 hours..."*

To avoid hitting PostgreSQL for high-frequency storefront reads, this pipeline uses Cloud Load Balancing logs and Redis.

### 3.1 Architecture Pipeline
1.  **Edge Ingestion:** Google Cloud Load Balancer (LB) serves the storefront. All requests are logged to Cloud Logging.
2.  **Log Router Sink:** A Cloud Logging Sink is configured to filter for successful (HTTP 200) HTML page loads matching the storefront path pattern, excluding known bot user-agents and static assets (`/assets/*`, `.js`, `.css`).
3.  **Pub/Sub Topic:** The sink streams these filtered log events directly into a Cloud Pub/Sub topic.
4.  **Cloud Run Consumer:** A dedicated, lightweight Cloud Run worker subscribes to the Pub/Sub topic.
5.  **Redis Aggregation:** The worker extracts the `tenant_id` (from the hostname or path) and the visitor's IP/Session hash. It increments a Redis HyperLogLog (or simple Set with 24h TTL if volume allows) keyed by `tenant:{tenant_id}:visitors:{YYYY-MM-DD}`.

### 3.2 Daily Email Trigger (DEC-16)
1.  **Cloud Scheduler:** Triggers a Cloud Tasks job at 00:00 UTC daily.
2.  **FastAPI Job:** Queries the `trial_hard_stop_trigger` status in the PostgreSQL `tenants` table. For any tenant in the hard-stop window:
    *   Reads the `tenant:{tenant_id}:visitors:{YYYY-MM-DD}` count from Redis.
    *   Triggers SendGrid/Postmark to dispatch the urgency email.
    *   Rate limits strictly to 1 email per 24 hours.
3.  **Cleanup:** Redis keys automatically expire after 48 hours, keeping memory footprint low.

This architecture ensures PostgreSQL is completely protected from storefront read traffic spikes while still delivering accurate, low-latency analytics for the sales motion.
