# Community 12

> 79 nodes · cohesion 0.06

## Key Concepts

- **str** (45 connections)
- [Tenant](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/platform/models.py#L9) (36 connections)
- [SubscriptionStatus](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/models.py#L10) (25 connections)
- [Subscription](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/models.py#L23) (24 connections)
- [SubscriptionTier](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/models.py#L17) (21 connections)
- [Config](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pricing/schemas.py#L24) (14 connections)
- [InvoiceResponse](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/schemas.py#L26) (10 connections)
- [PortalSessionResponse](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/schemas.py#L35) (10 connections)
- [SubscriptionResponse](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/schemas.py#L10) (10 connections)
- [UpgradeRequest](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/schemas.py#L21) (10 connections)
- [provision_tenant()](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/internal/provisioning.py#L41) (9 connections)
- [Finalizes an upgrade session.      In Stripe mode, this would verify the sessio](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/router.py#L131) (9 connections)
- [Lists all invoices from Stripe for the current tenant.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/router.py#L169) (9 connections)
- [Creates a Stripe Billing Portal session.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/router.py#L204) (9 connections)
- [Manually trigger the trial expiration check.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/router.py#L231) (9 connections)
- [Fetch current subscription status for the tenant.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/router.py#L26) (9 connections)
- [Initiates a Stripe Checkout Session for tier upgrades.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/router.py#L51) (9 connections)
- [models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/models.py#L1) (8 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/router.py#L1) (8 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/schemas.py#L1) (8 connections)
- [List all merchants and their subscription status.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/platform/router.py#L49) (8 connections)
- [generate_meta_tags()](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/shared/seo.py#L65) (6 connections)
- [Verify that a merchant can fetch their subscription.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/tests/test_billing.py#L11) (6 connections)
- [Verify that complete-upgrade correctly identifies and processes a mock session.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/tests/test_billing.py#L127) (6 connections)
- [Verify that list_invoices returns empty list if no stripe customer.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/tests/test_billing.py#L29) (6 connections)
- *... and 54 more nodes in this community*

## Class Diagram

```mermaid
classDiagram
    class Config {
        +db.py()
    }
    class Settings {
        +db.py()
    }
    class Subscription {
        +models.py()
    }
    class SubscriptionStatus {
        +models.py()
    }
    class SubscriptionTier {
        +models.py()
    }
    class Tenant {
        +models.py()
    }
    class Config {
        +schemas.py()
        +schemas.py()
        +schemas.py()
        +schemas.py()
        +schemas.py()
        +schemas.py()
        +schemas.py()
        +schemas.py()
        +schemas.py()
        +schemas.py()
    }
    class InvoiceResponse {
        +schemas.py()
    }
    class PortalSessionResponse {
        +schemas.py()
    }
    class SubscriptionBase {
        +schemas.py()
    }
    class SubscriptionResponse {
        +schemas.py()
    }
    class UpgradeRequest {
        +schemas.py()
    }
    SubscriptionStatus --> SubscriptionBase
    SubscriptionStatus --> SubscriptionResponse
    SubscriptionStatus --> Config
    SubscriptionStatus --> UpgradeRequest
    SubscriptionStatus --> InvoiceResponse
    SubscriptionStatus --> PortalSessionResponse
    SubscriptionTier --> SubscriptionBase
    SubscriptionTier --> SubscriptionResponse
    SubscriptionTier --> Config
    SubscriptionTier --> UpgradeRequest
    SubscriptionTier --> InvoiceResponse
    SubscriptionTier --> PortalSessionResponse
    Config --> SubscriptionStatus
    Config --> SubscriptionTier
    InvoiceResponse --> SubscriptionStatus
    InvoiceResponse --> SubscriptionTier
    PortalSessionResponse --> SubscriptionStatus
    PortalSessionResponse --> SubscriptionTier
    SubscriptionResponse <|-- SubscriptionBase
    SubscriptionBase --> SubscriptionStatus
    SubscriptionBase --> SubscriptionTier
    SubscriptionBase <|-- SubscriptionResponse
    SubscriptionResponse --> SubscriptionStatus
    SubscriptionResponse --> SubscriptionTier
    UpgradeRequest --> SubscriptionStatus
    UpgradeRequest --> SubscriptionTier
```

## Relationships

- [[Community 4]] (6 shared connections)
- [[Community 3]] (6 shared connections)
- [[Content & Features]] (4 shared connections)
- [[Community 10]] (4 shared connections)
- [[Community 17]] (3 shared connections)

## Source Files

- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\billing\models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/models.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\billing\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\billing\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\billing\tasks.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/tasks.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\billing\webhooks.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/billing/webhooks.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\feeds\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/feeds/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\internal\media_router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/internal/media_router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\internal\provisioning.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/internal/provisioning.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\platform\models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/platform/models.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\platform\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/platform/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\pricing\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pricing/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\storefront\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/storefront/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\storefront\ssr_router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/storefront/ssr_router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\shared\db.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/shared/db.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\shared\seo.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/shared/seo.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\tests\test_billing.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/tests/test_billing.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\frontend\lib\services\api_service.dart](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/services/api_service.dart)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\scratch\patch_db.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/scratch/patch_db.py)

## Audit Trail

- EXTRACTED: 177 (36%)
- INFERRED: 316 (64%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [[index]] to navigate.*