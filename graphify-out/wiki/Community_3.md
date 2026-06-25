# Community 3

> 162 nodes · cohesion 0.02

## Key Concepts

- **Base** (63 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/storefront/router.py#L1) (19 connections)
- [BrandProfile](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/storefront/models.py#L8) (18 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/inventory/router.py#L1) (15 connections)
- [models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/inventory/models.py#L1) (13 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/themes/router.py#L1) (13 connections)
- [Check if a tenant ID (slug) is available.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/router.py#L24) (12 connections)
- [Fetch tenant identity and configuration for the current merchant.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/router.py#L52) (12 connections)
- [Update merchant store details (name, config).](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/router.py#L94) (12 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/router.py#L1) (10 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/features/router.py#L1) (9 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/blog/router.py#L1) (8 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/schemas.py#L1) (8 connections)
- [models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/storefront/models.py#L1) (8 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/ai/router.py#L1) (7 connections)
- [BlogPost](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/models/blog.dart) (7 connections)
- [OnboardingSession](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/models.py#L8) (7 connections)
- [generate_copy_impl()](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/ai/router.py#L96) (7 connections)
- [ImportMapping](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/models.py#L22) (6 connections)
- [ImportAnalysisResponse](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/schemas.py#L17) (6 connections)
- [MigrationRunbookResponse](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/schemas.py#L33) (6 connections)
- [models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/blog/models.py#L1) (5 connections)
- [models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/features/models.py#L1) (5 connections)
- [test_features.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/tests/test_features.py#L1) (5 connections)
- [BrandVoiceProfile](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/ai/models.py#L7) (5 connections)
- *... and 137 more nodes in this community*

## Class Diagram

```mermaid
classDiagram
    class AICopywriterLog {
        +models.py()
    }
    class BlogCategory {
        +models.py()
    }
    class BlogCategoryTranslation {
        +models.py()
    }
    class BlogPost {
        +models.py()
    }
    class BlogPostTranslation {
        +models.py()
    }
    class BlogTag {
        +models.py()
    }
    class BrandProfile {
        +models.py()
    }
    class BrandVoiceProfile {
        +models.py()
    }
    class CarrierCheckoutOption {
        +models.py()
    }
    class ExportJob {
        +models.py()
    }
    class Feature {
        +models.py()
    }
    class FeatureRequest {
        +models.py()
    }
    class FeatureRequestVote {
        +models.py()
    }
    class ImportMapping {
        +models.py()
    }
    class MerchantCarrierConnection {
        +models.py()
    }
    class OnboardingSession {
        +models.py()
    }
    class PackagingPreset {
        +models.py()
    }
    class PricingRule {
        +models.py()
    }
    class PurchaseOrder {
        +models.py()
    }
    class PurchaseOrderLine {
        +models.py()
    }
    class ShippingSettings {
        +models.py()
    }
    class StaticPage {
        +models.py()
    }
    class StockTransfer {
        +models.py()
    }
    class StorefrontContent {
        +models.py()
    }
    class Supplier {
        +models.py()
    }
    class SupplierPerformanceEvent {
        +models.py()
    }
    class SupplierScoreWeights {
        +models.py()
    }
    class TenantFeatureActivation {
        +models.py()
    }
    class Theme {
        +models.py()
    }
    class ThemeConfiguration {
        +models.py()
    }
    class GeminiClient {
        +router.py()
        +.generate_variants()
    }
    class CopyVariant {
        +schemas.py()
    }
    class ImportAnalysisRequest {
        +schemas.py()
    }
    class ImportAnalysisResponse {
        +schemas.py()
    }
    class ImportExecutionRequest {
        +schemas.py()
    }
    class MigrationRunbookResponse {
        +schemas.py()
    }
    class OnboardingStatusResponse {
        +schemas.py()
    }
    class RegionSelectionRequest {
        +schemas.py()
    }
    class SignupRequest {
        +schemas.py()
    }
```

## Relationships

- [[Community 17]] (30 shared connections)
- [[Content & Features]] (29 shared connections)
- [[Community 8]] (2 shared connections)

## Source Files

- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\ai\models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/ai/models.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\ai\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/ai/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\ai\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/ai/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\blog\models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/blog/models.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\blog\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/blog/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\export\models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/export/models.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\export\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/export/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\features\models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/features/models.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\features\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/features/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\inventory\models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/inventory/models.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\inventory\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/inventory/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\onboarding\models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/models.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\onboarding\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\onboarding\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\pricing\models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pricing/models.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\pricing\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pricing/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\storefront\models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/storefront/models.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\storefront\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/storefront/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\storefront\sitemap_router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/storefront/sitemap_router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\themes\models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/themes/models.py)

## Audit Trail

- EXTRACTED: 405 (68%)
- INFERRED: 192 (32%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [[index]] to navigate.*