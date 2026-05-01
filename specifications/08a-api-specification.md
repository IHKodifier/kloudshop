# 08a — KloudShop API Specification (Technical Contract)

> [!IMPORTANT]
> **SSOT for all API contracts.** Every FastAPI endpoint MUST match this spec. Any deviation requires updating this document BEFORE implementation.
> **Read before:** Any backend or frontend API change.

---

## Global Standards

### Base URLs
| Env | URL |
|-----|-----|
| Dev | `http://localhost:8000/api/v1` |
| Staging | `https://api-staging.kloudshop.biz/api/v1` |
| Prod | `https://api.kloudshop.biz/api/v1` |

### Required Headers (all authenticated endpoints)
```
Authorization: Bearer <Firebase_ID_Token>
X-Firebase-AppCheck: <App_Check_Token>   # enforced in Staging + Prod
X-Tenant-ID: <tenant_id>                 # extracted from JWT; sent for routing/logging
```

### Standard HTTP Status Codes
| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Validation error (Pydantic detail) |
| 401 | Missing / invalid token |
| 403 | Insufficient RBAC permissions |
| 404 | Resource not found |
| 409 | Conflict (duplicate) |
| 429 | Rate limit exceeded |
| 500 | Server error |

### RBAC Permission Tokens (used in endpoint tables)
`auth:invite` `auth:revoke` `catalog:read` `catalog:write` `orders:read` `orders:write`
`orders:refund` `inventory:read` `inventory:write` `suppliers:write` `b2b:manage`
`b2b:approve` `billing:manage` `analytics:read` `analytics:deep` `pricing:write`
`features:manage` `export:data` `pos:operate` `channels:manage` `tax:manage`
`blog:write` `blog:publish` `admin:platform`

---

## E01 — Authentication & Access Control

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/auth/me` | Authenticated | Current user identity, roles, permissions |
| POST | `/auth/invitations` | `auth:invite` | Invite staff member by Gmail + roles |
| GET | `/auth/invitations` | `auth:invite` | List pending invitations |
| DELETE | `/auth/invitations/{id}` | `auth:invite` | Cancel pending invitation |
| PATCH | `/auth/staff/{uid}/roles` | `auth:invite` | Update staff member roles |
| DELETE | `/auth/staff/{uid}` | `auth:revoke` | Revoke staff access |
| POST | `/auth/ownership/transfer` | Owner only | Transfer store ownership |
| POST | `/auth/b2b-buyers/register` | Public (invite token) | B2B buyer registration via invite link |
| POST | `/auth/consumers/register` | Public | DTC consumer post-checkout account creation |

**Key models:**
```json
// POST /auth/invitations body
{ "email": "staff@gmail.com", "roles": ["store_manager", "inventory_manager"] }

// GET /auth/me response
{
  "uid": "u_123", "email": "owner@gmail.com", "tenant_id": "t_abc",
  "is_owner": true, "roles": ["owner"], "permissions": ["catalog:write", "orders:write"]
}
```

---

## E02 — Merchant Onboarding (MVP: CSV/Excel only. Scraping = Post-MVP)

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| POST | `/onboarding/signup` | Public (Firebase token) | Create merchant account + tier selection |
| POST | `/onboarding/region` | Authenticated | Set primary GCP region |
| POST | `/onboarding/brand` | Authenticated | Set brand name, logo, colours |
| POST | `/onboarding/csv/products` | `catalog:write` | Upload product catalog CSV/Excel |
| POST | `/onboarding/csv/customers` | `catalog:write` | Upload customer history CSV/Excel |
| POST | `/onboarding/csv/orders` | `catalog:write` | Upload historical order CSV/Excel |
| GET | `/onboarding/csv/jobs/{job_id}` | Authenticated | CSV import job status |
| GET | `/onboarding/runbook` | Authenticated | Get personalised migration runbook |
| GET | `/onboarding/runbook/pdf` | Authenticated | Download runbook as PDF |
| POST | `/onboarding/tier-upgrade` | `billing:manage` | Initiate explicit tier upgrade consent flow |

> **Post-MVP only:** `POST /onboarding/migration/scrape` (competitor URL scraping — US-011/012 deferred)

**Key models:**
```json
// POST /onboarding/signup body
{ "store_name": "Acme Store", "tier": "DTC", "primary_region": "us-central1" }

// GET /onboarding/csv/jobs/{job_id} response
{
  "job_id": "job_999", "status": "processing",
  "rows_total": 500, "rows_processed": 120,
  "rows_failed": 3, "failed_rows": [{"row": 14, "field": "price", "error": "missing"}]
}
```

---

## E03 — Storefront & Theme System

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/themes` | Authenticated | List all published themes in catalogue |
| GET | `/themes/{theme_id}` | Authenticated | Get theme details + preview |
| GET | `/themes/active` | Authenticated | Get merchant's active theme config |
| GET | `/themes/draft` | Authenticated | Get current WYSIWYG draft |
| PUT | `/themes/draft` | `catalog:write` | Save full WYSIWYG draft |
| PATCH | `/themes/draft` | `catalog:write` | Partial update to draft (delta) |
| POST | `/themes/draft/apply` | `catalog:write` | Promote draft → active storefront |
| DELETE | `/themes/draft` | `catalog:write` | Discard draft, revert to active |
| GET | `/themes/content-slots` | `catalog:write` | List all content slots for active theme |
| PUT | `/themes/content-slots/{slot_id}` | `catalog:write` | Update a content slot value |
| GET | `/themes/design-tokens` | Authenticated | Get active design token overrides |
| PUT | `/themes/design-tokens` | `catalog:write` | Update design token overrides |

---

## E04 — Product Catalog Management

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/products` | `catalog:read` | List products (paginated, filterable) |
| POST | `/products` | `catalog:write` | Create product with variants |
| GET | `/products/{id}` | `catalog:read` | Get product detail |
| PUT | `/products/{id}` | `catalog:write` | Full product update |
| PATCH | `/products/{id}` | `catalog:write` | Partial product update |
| DELETE | `/products/{id}` | `catalog:write` | Archive product |
| POST | `/products/{id}/clone` | `catalog:write` | Clone product |
| GET | `/products/{id}/variants` | `catalog:read` | List variants for product |
| POST | `/products/{id}/variants` | `catalog:write` | Add variant |
| PUT | `/products/{id}/variants/{vid}` | `catalog:write` | Update variant |
| DELETE | `/products/{id}/variants/{vid}` | `catalog:write` | Remove variant |
| GET | `/products/{id}/seo` | `catalog:read` | Get SEO metadata |
| PUT | `/products/{id}/seo` | `catalog:write` | Update SEO + auto 301 redirect |
| POST | `/products/bulk-import` | `catalog:write` | Bulk CSV/Excel import job |
| GET | `/collections` | `catalog:read` | List collections |
| POST | `/collections` | `catalog:write` | Create collection |
| GET | `/collections/{id}` | `catalog:read` | Get collection |
| PUT | `/collections/{id}` | `catalog:write` | Update collection |
| DELETE | `/collections/{id}` | `catalog:write` | Archive collection |
| POST | `/collections/{id}/products` | `catalog:write` | Assign products to collection |
| DELETE | `/collections/{id}/products/{pid}` | `catalog:write` | Remove product from collection |

**Key query params for `GET /products`:** `limit`, `offset`, `search`, `collection_id`, `status`, `sort`

---

## E05 — Order Management

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/orders` | `orders:read` | List orders (filterable by status/date/channel) |
| GET | `/orders/{id}` | `orders:read` | Order detail |
| PATCH | `/orders/{id}/fulfil` | `orders:write` | Mark fulfilled + tracking number |
| POST | `/orders/{id}/refund` | `orders:refund` | Issue full or partial refund |
| POST | `/orders/{id}/notes` | `orders:write` | Add internal note |
| GET | `/orders/{id}/notes` | `orders:read` | List order notes |
| GET | `/orders/export` | `orders:read` | Export orders CSV (date range) |

**Key models:**
```json
// PATCH /orders/{id}/fulfil body
{
  "carrier": "FedEx", "tracking_number": "7489234892",
  "notify_customer": true, "items": ["line_item_1", "line_item_2"]
}

// POST /orders/{id}/refund body
{ "type": "partial", "amount": 29.99, "reason": "Item damaged" }
```

---

## E06 — Inventory & Supplier Management

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/inventory` | `inventory:read` | Dashboard with urgency scores |
| GET | `/inventory/{sku}` | `inventory:read` | SKU stock detail + velocity |
| PATCH | `/inventory/{sku}` | `inventory:write` | Manual stock adjustment |
| GET | `/inventory/replenishment` | `inventory:read` | AI reorder recommendations |
| GET | `/suppliers` | `inventory:read` | List suppliers |
| POST | `/suppliers` | `suppliers:write` | Create supplier |
| GET | `/suppliers/{id}` | `inventory:read` | Supplier detail |
| PUT | `/suppliers/{id}` | `suppliers:write` | Update supplier |
| DELETE | `/suppliers/{id}` | `suppliers:write` | Archive supplier (blocked if open POs) |
| GET | `/suppliers/{id}/scorecard` | `inventory:read` | Performance analytics |
| POST | `/products/{id}/suppliers` | `suppliers:write` | Assign supplier to product/SKU |
| PUT | `/products/{id}/suppliers/{sid}/rank` | `suppliers:write` | Update preference rank |
| GET | `/purchase-orders` | `inventory:read` | List purchase orders |
| POST | `/purchase-orders` | `inventory:write` | Create draft PO |
| GET | `/purchase-orders/{id}` | `inventory:read` | PO detail |
| PATCH | `/purchase-orders/{id}/send` | `inventory:write` | Send PO to supplier |
| PATCH | `/purchase-orders/{id}/receive` | `inventory:write` | Mark goods received (full/partial) |

---

## E07 — B2B Operations

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/b2b/buyers` | `b2b:manage` | List B2B buyer accounts |
| POST | `/b2b/buyers` | `b2b:manage` | Create buyer account + send invite |
| GET | `/b2b/buyers/{id}` | `b2b:manage` | Buyer account detail |
| PATCH | `/b2b/buyers/{id}` | `b2b:manage` | Update buyer (credit limit, terms) |
| PATCH | `/b2b/buyers/{id}/approve` | `b2b:approve` | Approve pending buyer registration |
| GET | `/b2b/price-lists` | `b2b:manage` | List custom price lists |
| POST | `/b2b/price-lists` | `b2b:manage` | Create price list |
| GET | `/b2b/price-lists/{id}` | `b2b:manage` | Price list detail |
| PUT | `/b2b/price-lists/{id}` | `b2b:manage` | Update price list items |
| POST | `/b2b/price-lists/{id}/assign` | `b2b:manage` | Assign price list to buyer(s) |
| GET | `/b2b/orders` | `b2b:manage` | List B2B orders (pending approval) |
| PATCH | `/b2b/orders/{id}/approve` | `b2b:approve` | Approve B2B order |
| PATCH | `/b2b/orders/{id}/decline` | `b2b:approve` | Decline B2B order with reason |
| GET | `/b2b/invoices` | `b2b:manage` | List Stripe net-terms invoices |
| POST | `/b2b/portal/catalog` | B2B Buyer token | Browse catalog (buyer-scoped) |
| POST | `/b2b/portal/orders` | B2B Buyer token | Place B2B order |

---

## E08 — Feature Catalogue & Configuration

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/features` | Authenticated | List all available features |
| GET | `/features/{feature_id}` | Authenticated | Feature detail + config schema |
| POST | `/features/{feature_id}/activate` | `features:manage` | Toggle feature ON (triggers migration) |
| GET | `/features/{feature_id}/activation-status` | Authenticated | Real-time migration progress |
| PUT | `/features/{feature_id}/config` | `features:manage` | Save wizard configuration |
| GET | `/features/{feature_id}/config` | Authenticated | Get current feature config |
| POST | `/features/{feature_id}/deactivate` | `features:manage` | Toggle feature OFF |
| GET | `/features/requests` | Authenticated | Feature Request Channel list |
| POST | `/features/requests` | Authenticated | Submit feature request |
| POST | `/features/requests/{id}/vote` | Authenticated | Upvote feature request |

---

## E09 — Analytics & Reporting

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/analytics/overview` | `analytics:read` | Revenue KPIs (GMV, orders, AOV, conversion) |
| GET | `/analytics/needs-attention` | `analytics:read` | Urgent items panel |
| GET | `/analytics/forecasting` | `analytics:read` | Vertex AI stock predictions |
| GET | `/analytics/looker/token` | `analytics:deep` | Scoped Looker Studio embed token |

---

## E10 — Billing & Subscription

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/billing/subscription` | `billing:manage` | Current subscription status |
| POST | `/billing/upgrade` | `billing:manage` | Initiate tier upgrade with consent |
| GET | `/billing/invoices` | `billing:manage` | List all invoices |
| GET | `/billing/invoices/{id}` | `billing:manage` | Invoice detail + GCP breakdown |
| GET | `/billing/invoices/{id}/pdf` | `billing:manage` | Download invoice PDF |
| POST | `/billing/stripe/portal` | `billing:manage` | Stripe customer portal session |
| POST | `/webhooks/stripe` | Internal (Stripe sig) | Stripe webhook handler |

---

## E11 — POS & Omnichannel

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/pos/catalog` | `pos:operate` | In-store product catalog (location-scoped) |
| POST | `/pos/orders` | `pos:operate` | Process in-store sale |
| GET | `/pos/locations` | `pos:operate` | Assigned stock locations for operator |

---

## E12 — Social Commerce & Channels

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/channels` | `channels:manage` | List connected channels + status |
| POST | `/channels/tiktok/connect` | `channels:manage` | Initiate TikTok Shop OAuth |
| POST | `/channels/instagram/connect` | `channels:manage` | Initiate Instagram Shopping OAuth |
| POST | `/channels/facebook/connect` | `channels:manage` | Initiate Facebook Shops OAuth |
| POST | `/channels/google/connect` | `channels:manage` | Connect Google Merchant Center |
| DELETE | `/channels/{channel}` | `channels:manage` | Disconnect channel |
| POST | `/channels/{channel}/sync` | `channels:manage` | Force catalog resync |
| GET | `/channels/{channel}/status` | `channels:manage` | Sync status + last run |
| GET | `/feeds/google-shopping` | Public | Live Google Shopping XML feed |

---

## E13 — Tax Compliance

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/tax/settings-session` | `tax:manage` | Stripe AccountSession for ConnectTaxSettings embed |
| GET | `/tax/registrations-session` | `tax:manage` | Stripe AccountSession for ConnectTaxRegistrations embed |
| GET | `/tax/reports` | `tax:manage` | List available tax report periods |
| GET | `/tax/reports/{period}` | `tax:manage` | Download tax statement PDF |

---

## E14 — Dynamic Pricing Engine

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/pricing/rules` | `pricing:write` | List all pricing rules |
| POST | `/pricing/rules` | `pricing:write` | Create pricing rule |
| GET | `/pricing/rules/{id}` | `pricing:write` | Rule detail + trigger log |
| PUT | `/pricing/rules/{id}` | `pricing:write` | Update rule |
| DELETE | `/pricing/rules/{id}` | `pricing:write` | Delete rule |
| GET | `/pricing/rules/{id}/history` | `pricing:write` | Price change log for this rule |

**Rule types:** `stock_age_markdown`, `velocity_surge`, `flash_sale`, `competitor_match`

---

## E15 — Data Portability

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| POST | `/export/all` | `export:data` | Queue full data export (CSV or JSON) |
| GET | `/export/jobs/{job_id}` | `export:data` | Export job status + download URL |

---

## E16 — Internal Messaging (UI skeleton MVP; full feature v1.1)

| Method | Path | Permission | MVP? |
|--------|------|------------|------|
| GET | `/messages/threads` | Authenticated | v1.1 |
| POST | `/messages/threads` | Authenticated | v1.1 |
| GET | `/messages/threads/{id}/messages` | Authenticated | v1.1 |
| POST | `/messages/threads/{id}/messages` | Authenticated | v1.1 |
| POST | `/messages/attachments` | Authenticated | v1.1 |
| GET | `/messages/search` | Authenticated | v1.1 |

---

## E17 — Consumer DTC Storefront (SSR)

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/storefront/{tenant}/products` | Public | SSR product listing |
| GET | `/storefront/{tenant}/products/{slug}` | Public | SSR product detail (PDP) |
| GET | `/storefront/{tenant}/collections/{slug}` | Public | SSR collection page |
| GET | `/storefront/{tenant}/search` | Public | Unified FTS (products + blog) |
| POST | `/storefront/{tenant}/search/ai` | Public | RAG-powered AI consultative search |
| GET | `/storefront/{tenant}/cart/{cart_id}` | Public | Get cart state |
| POST | `/storefront/{tenant}/cart` | Public | Create cart |
| PATCH | `/storefront/{tenant}/cart/{cart_id}` | Public | Add/remove/update cart items |
| POST | `/storefront/{tenant}/checkout/shipping-rates` | Public | Real-time carrier rates |
| POST | `/storefront/{tenant}/checkout/payment-intent` | Public | Create Stripe Payment Intent |
| POST | `/storefront/{tenant}/checkout/confirm` | Public | Confirm order after payment |
| GET | `/storefront/{tenant}/orders/{order_id}` | Consumer token | Order status for consumer |
| POST | `/storefront/{tenant}/consumers/gdpr-erasure` | Consumer token | GDPR right-to-erasure request |

---

## E18 — Platform Administration

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/platform/dashboard` | `admin:platform` | Global MRR, churn, error rate |
| GET | `/platform/merchants` | `admin:platform` | All tenants + health status |
| GET | `/platform/merchants/{tenant_id}` | `admin:platform` | Tenant detail |
| PATCH | `/platform/merchants/{tenant_id}/approve` | `admin:platform` | Approve trial signup |
| PATCH | `/platform/merchants/{tenant_id}/reject` | `admin:platform` | Reject trial signup |
| PATCH | `/platform/merchants/{tenant_id}/suspend` | `admin:platform` | Manual account suspension |
| PATCH | `/platform/merchants/{tenant_id}/reinstate` | `admin:platform` | Manual reinstatement |
| GET | `/platform/themes` | `admin:platform` | Admin theme catalogue |
| POST | `/platform/themes` | `admin:platform` | Upload new theme |
| PATCH | `/platform/themes/{id}/publish` | `admin:platform` | Publish theme to merchant library |
| PATCH | `/platform/themes/{id}/deprecate` | `admin:platform` | Deprecate theme |
| GET | `/platform/features` | `admin:platform` | Feature registry |
| POST | `/platform/features` | `admin:platform` | Add new feature to registry |
| PATCH | `/platform/features/{id}` | `admin:platform` | Update feature status |
| POST | `/platform/deployments/{id}/approve` | `admin:platform` | Approve canary promotion |

---

## E19 — System & Background Processes (Internal/Webhook only)

| Method | Path | Trigger | Description |
|--------|------|---------|-------------|
| POST | `/internal/provision-tenant` | Cloud Tasks | GCP resource provisioning for new tenant |
| POST | `/internal/feature-migration` | Cloud Tasks | Run Alembic feature schema migration |
| POST | `/internal/schema-drift-check` | Cloud Scheduler (nightly) | Compare live schema vs Alembic head |
| POST | `/internal/gdpr-erasure` | Cloud Tasks | Execute PII anonymisation |
| POST | `/internal/billing/cycle` | Cloud Scheduler (monthly) | Trigger invoice generation |
| POST | `/internal/billing/trial-check` | Cloud Scheduler (daily) | Check trial expiry triggers |

---

## E20 — Shipping & Courier Integration

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/shipping/carriers` | Authenticated | Platform carrier catalogue |
| GET | `/shipping/carriers/connected` | Authenticated | Merchant connected carriers |
| POST | `/shipping/carriers/{carrier}/connect` | Authenticated | Connect carrier account |
| DELETE | `/shipping/carriers/{carrier}` | Authenticated | Disconnect carrier |
| GET | `/shipping/settings` | Authenticated | Merchant shipping config |
| PUT | `/shipping/settings` | Authenticated | Update checkout carrier options + markups |
| GET | `/shipping/free-rules` | Authenticated | Free shipping threshold rules |
| PUT | `/shipping/free-rules` | Authenticated | Update free shipping rules |
| POST | `/shipping/rates` | Authenticated | Calculate rates (also used at checkout) |
| POST | `/shipping/labels` | `orders:write` | Generate carrier label for order |
| POST | `/orders/{id}/fulfil/manual` | `orders:write` | Manual fulfilment (no carrier API) |

---

## E21 — Multilingual Storefront (Architecture MVP; content v1.1)

| Method | Path | Permission | MVP? |
|--------|------|------------|------|
| GET | `/i18n/locales` | Authenticated | Supported locales | ✅ |
| PUT | `/i18n/locales` | Authenticated | Enable/disable locales | ✅ |
| GET | `/i18n/translations/{entity_type}/{id}` | Authenticated | Get translations | v1.1 |
| POST | `/i18n/translations/{entity_type}/{id}/retranslate` | Authenticated | Trigger re-translation | v1.1 |
| PUT | `/i18n/translations/{entity_type}/{id}/{locale}` | Authenticated | Manual translation override | v1.1 |

---

## E22 — Native Blog

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/blog/posts` | `blog:write` | List all blog posts (admin) |
| POST | `/blog/posts` | `blog:write` | Create blog post |
| GET | `/blog/posts/{id}` | `blog:write` | Get post (admin, includes drafts) |
| PUT | `/blog/posts/{id}` | `blog:write` | Update post |
| PATCH | `/blog/posts/{id}/publish` | `blog:publish` | Publish immediately |
| PATCH | `/blog/posts/{id}/schedule` | `blog:publish` | Schedule post for future date |
| PATCH | `/blog/posts/{id}/archive` | `blog:publish` | Archive (returns 410 on storefront) |
| GET | `/blog/categories` | `blog:write` | List categories |
| POST | `/blog/categories` | `blog:write` | Create category |
| PUT | `/blog/categories/{id}` | `blog:write` | Rename / merge category |
| DELETE | `/blog/categories/{id}` | `blog:write` | Delete empty category |
| GET | `/storefront/{tenant}/blog` | Public | SSR blog index |
| GET | `/storefront/{tenant}/blog/{slug}` | Public | SSR blog post (JSON-LD Article) |
| GET | `/storefront/{tenant}/blog/category/{slug}` | Public | SSR category page |

---

## E23 — AI Copywriter

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/ai/brand-voice` | Authenticated | Get brand voice profile |
| PUT | `/ai/brand-voice` | Authenticated | Save brand voice profile |
| POST | `/ai/copy/product-title` | `catalog:write` | Generate 3 product title variants |
| POST | `/ai/copy/product-description` | `catalog:write` | Generate 3 description variants |
| POST | `/ai/copy/product-description/{id}/regenerate/{variant}` | `catalog:write` | Regenerate single variant |
| POST | `/ai/copy/blog-title` | `blog:write` | Generate 3 blog title variants |
| POST | `/ai/copy/blog-body` | `blog:write` | Generate 3 blog body variants |
| POST | `/ai/copy/blog-body/{id}/regenerate/{variant}` | `blog:write` | Regenerate single blog variant |
| GET | `/ai/copy/log` | Authenticated | AI copywriter usage log |

**Key models:**
```json
// POST /ai/copy/product-title body
{
  "product_id": "p_123",
  "current_title": "Hiking Jacket",
  "category": "Outerwear",
  "key_attributes": ["waterproof", "10000mm", "-10C rated"]
}

// Response (all copy endpoints)
{
  "variants": [
    { "id": 1, "angle": "Benefit-led", "copy": "Stay Dry in Any Condition..." },
    { "id": 2, "angle": "Problem-solution", "copy": "Never Get Caught..." },
    { "id": 3, "angle": "Authority", "copy": "10,000mm Waterproof Rating..." }
  ]
}
```

---

## Webhook Endpoints (External → KloudShop)

| Method | Path | Source | Description |
|--------|------|--------|-------------|
| POST | `/webhooks/stripe` | Stripe | Payment, subscription, dunning events |
| POST | `/webhooks/tiktok` | TikTok | Order + catalog sync events |
| POST | `/webhooks/instagram` | Instagram | Commerce events |
| POST | `/webhooks/facebook` | Facebook | Commerce events |
| POST | `/webhooks/google-merchant` | Google | Feed approval / disapproval |

All webhooks validated by signature before processing.

---

## Sitemap & SEO Endpoints (Public)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/storefront/{tenant}/sitemap.xml` | XML sitemap (products, collections, blog) |
| GET | `/storefront/{tenant}/feeds/google-shopping` | Google Shopping feed |
| GET | `/storefront/{tenant}/robots.txt` | robots.txt |

---

## Post-MVP Endpoints (v1.1)

| Endpoint Group | Epic | Notes |
|---------------|------|-------|
| `/messages/*` (full) | E16 | UI skeleton at MVP; full backend v1.1 |
| `/i18n/translations/*` | E21 | Architecture at MVP; content pipeline v1.1 |
| `/loyalty/*` | E17 | First Feature Catalogue item v1.1 |
| `/onboarding/migration/scrape` | E02 | Competitor scraping deferred post-MVP |
| `/onboarding/region/secondary` | E02 | Secondary region activation deferred |
| `/b2b/quotes/*` | E07 | B2B quote requests explicitly descoped |
