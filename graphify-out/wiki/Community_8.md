# Community 8

> 112 nodes · cohesion 0.03

## Key Concepts

- **BaseModel** (106 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/storefront/schemas.py#L1) (20 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/inventory/schemas.py#L1) (16 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/blog/schemas.py#L1) (14 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/features/schemas.py#L1) (9 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/ai/router.py#L1) (7 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/ai/schemas.py#L1) (7 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pos/schemas.py#L1) (7 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/themes/schemas.py#L1) (7 connections)
- [generate_copy_impl()](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/ai/router.py#L96) (7 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pos/router.py#L1) (6 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/channels/schemas.py#L1) (5 connections)
- [create_pos_order()](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pos/router.py#L55) (5 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pricing/schemas.py#L1) (4 connections)
- [GeminiClient](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/ai/router.py#L14) (4 connections)
- [BlogCategoryBase](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/blog/schemas.py#L26) (4 connections)
- [BlogPostBase](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/blog/schemas.py#L58) (4 connections)
- [BlogTagBase](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/blog/schemas.py#L44) (4 connections)
- [BlogTranslationBase](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/blog/schemas.py#L5) (4 connections)
- [BrandProfileBase](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/storefront/schemas.py#L8) (4 connections)
- [CarrierConnectionBase](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/storefront/schemas.py#L107) (4 connections)
- [ChannelConnectionBase](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/channels/schemas.py#L5) (4 connections)
- [CheckoutOptionBase](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/storefront/schemas.py#L122) (4 connections)
- [FeatureRequestBase](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/features/schemas.py#L26) (4 connections)
- [POLineBase](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/inventory/schemas.py#L59) (4 connections)
- *... and 87 more nodes in this community*

## Class Diagram

```mermaid
classDiagram
    class GeminiClient {
        +router.py()
        +.generate_variants()
    }
    class B2BPortalOrderItem {
        +schemas.py()
    }
    class BlogCategoryBase {
        +schemas.py()
    }
    class BlogCategoryCreate {
        +schemas.py()
    }
    class BlogCategoryRead {
        +schemas.py()
    }
    class BlogPostBase {
        +schemas.py()
    }
    class BlogPostCreate {
        +schemas.py()
    }
    class BlogPostRead {
        +schemas.py()
    }
    class BlogPostUpdate {
        +schemas.py()
    }
    class BlogTagBase {
        +schemas.py()
    }
    class BlogTagCreate {
        +schemas.py()
    }
    class BlogTagRead {
        +schemas.py()
    }
    class BlogTranslationBase {
        +schemas.py()
    }
    class BlogTranslationCreate {
        +schemas.py()
    }
    class BlogTranslationRead {
        +schemas.py()
    }
    class BrandProfileBase {
        +schemas.py()
    }
    class BrandProfileCreate {
        +schemas.py()
    }
    class BrandProfileResponse {
        +schemas.py()
    }
    class BrandProfileUpdate {
        +schemas.py()
    }
    class BrandVoiceProfileBase {
        +schemas.py()
    }
    class BrandVoiceProfileResponse {
        +schemas.py()
    }
    class CarrierConnectionBase {
        +schemas.py()
    }
    class CarrierConnectionCreate {
        +schemas.py()
    }
    class CarrierConnectionResponse {
        +schemas.py()
    }
    class ChannelConnectionBase {
        +schemas.py()
    }
    class ChannelConnectionCreate {
        +schemas.py()
    }
    class ChannelConnectionRead {
        +schemas.py()
    }
    class ChannelSyncStatus {
        +schemas.py()
    }
    class CheckoutOptionBase {
        +schemas.py()
    }
    class CheckoutOptionCreate {
        +schemas.py()
    }
    class CheckoutOptionResponse {
        +schemas.py()
    }
    class CopyAcceptanceRequest {
        +schemas.py()
    }
    class CopyGenerationRequest {
        +schemas.py()
    }
    class CopyGenerationResponse {
        +schemas.py()
    }
    class CopyVariant {
        +schemas.py()
    }
    class ExportJobResponse {
        +schemas.py()
    }
    class ExportRequest {
        +schemas.py()
    }
    class FeatureActivationRequest {
        +schemas.py()
    }
    class FeatureBase {
        +schemas.py()
    }
    class FeatureConfigRequest {
        +schemas.py()
    }
    class FeatureRequestBase {
        +schemas.py()
    }
    class FeatureRequestCreate {
        +schemas.py()
    }
    class FeatureRequestResponse {
        +schemas.py()
    }
    class FeatureResponse {
        +schemas.py()
    }
    class FeatureVoteResponse {
        +schemas.py()
    }
    class OrderEventResponse {
        +schemas.py()
    }
    class OrderItemBase {
        +schemas.py()
    }
    class OrderItemResponse {
        +schemas.py()
    }
    class POCreate {
        +schemas.py()
    }
    class POLineBase {
        +schemas.py()
    }
    class POLineCreate {
        +schemas.py()
    }
    class POLineResponse {
        +schemas.py()
    }
    class POReceiveLine {
        +schemas.py()
    }
    class POReceiveRequest {
        +schemas.py()
    }
    class POResponse {
        +schemas.py()
    }
    class POSItemCreate {
        +schemas.py()
    }
    class POSLocationResponse {
        +schemas.py()
    }
    class POSOrderCreate {
        +schemas.py()
    }
    class POUpdate {
        +schemas.py()
    }
    class PricingRuleBase {
        +schemas.py()
    }
    class PricingRuleCreate {
        +schemas.py()
    }
    class PricingRuleResponse {
        +schemas.py()
    }
    class ShippingRateRequest {
        +schemas.py()
    }
    class ShippingRateResponse {
        +schemas.py()
    }
    class StaffLocationAssignmentCreate {
        +schemas.py()
    }
    class StaffLocationAssignmentSchema {
        +schemas.py()
    }
    class StaffMember {
        +schemas.py()
    }
    class StaticPageBase {
        +schemas.py()
    }
    class StaticPageCreate {
        +schemas.py()
    }
    class StaticPageResponse {
        +schemas.py()
    }
    class StaticPageUpdate {
        +schemas.py()
    }
    class StockTransferCreate {
        +schemas.py()
    }
    class StockTransferResponse {
        +schemas.py()
    }
    class StorefrontContentBase {
        +schemas.py()
    }
    class StorefrontContentCreate {
        +schemas.py()
    }
    class StorefrontContentResponse {
        +schemas.py()
    }
    class SupplierBase {
        +schemas.py()
    }
    class SupplierCreate {
        +schemas.py()
    }
    class SupplierResponse {
        +schemas.py()
    }
    class SupplierUpdate {
        +schemas.py()
    }
    class ThemeBase {
        +schemas.py()
    }
    class ThemeCloneRequest {
        +schemas.py()
    }
    class ThemeConfigRequest {
        +schemas.py()
    }
    class ThemeConfigResponse {
        +schemas.py()
    }
    class ThemeResponse {
        +schemas.py()
    }
    class ThemeSelectionRequest {
        +schemas.py()
    }
    class VariantUpdate {
        +schemas.py()
    }
    BlogCategoryCreate <|-- BlogCategoryBase
    BlogCategoryRead <|-- BlogCategoryBase
    BlogCategoryBase <|-- BlogCategoryCreate
    BlogCategoryBase <|-- BlogCategoryRead
    BlogPostCreate <|-- BlogPostBase
    BlogPostRead <|-- BlogPostBase
    BlogPostBase <|-- BlogPostCreate
    BlogPostBase <|-- BlogPostRead
    BlogTagCreate <|-- BlogTagBase
    BlogTagRead <|-- BlogTagBase
    BlogTagBase <|-- BlogTagCreate
    BlogTagBase <|-- BlogTagRead
    BlogTranslationCreate <|-- BlogTranslationBase
    BlogTranslationRead <|-- BlogTranslationBase
    BlogTranslationBase <|-- BlogTranslationCreate
    BlogTranslationBase <|-- BlogTranslationRead
    BrandProfileCreate <|-- BrandProfileBase
    BrandProfileResponse <|-- BrandProfileBase
    BrandProfileBase <|-- BrandProfileCreate
    BrandProfileBase <|-- BrandProfileResponse
    BrandVoiceProfileResponse <|-- BrandVoiceProfileBase
    BrandVoiceProfileBase <|-- BrandVoiceProfileResponse
    CarrierConnectionCreate <|-- CarrierConnectionBase
    CarrierConnectionResponse <|-- CarrierConnectionBase
    CarrierConnectionBase <|-- CarrierConnectionCreate
    CarrierConnectionBase <|-- CarrierConnectionResponse
    ChannelConnectionCreate <|-- ChannelConnectionBase
    ChannelConnectionRead <|-- ChannelConnectionBase
    ChannelConnectionBase <|-- ChannelConnectionCreate
    ChannelConnectionBase <|-- ChannelConnectionRead
    CheckoutOptionCreate <|-- CheckoutOptionBase
    CheckoutOptionResponse <|-- CheckoutOptionBase
    CheckoutOptionBase <|-- CheckoutOptionCreate
    CheckoutOptionBase <|-- CheckoutOptionResponse
    FeatureResponse <|-- FeatureBase
    FeatureRequestCreate <|-- FeatureRequestBase
    FeatureRequestResponse <|-- FeatureRequestBase
    FeatureRequestBase <|-- FeatureRequestCreate
    FeatureRequestBase <|-- FeatureRequestResponse
    FeatureBase <|-- FeatureResponse
    POLineCreate <|-- POLineBase
    POLineResponse <|-- POLineBase
    POLineBase <|-- POLineCreate
    POLineBase <|-- POLineResponse
    PricingRuleCreate <|-- PricingRuleBase
    PricingRuleResponse <|-- PricingRuleBase
    PricingRuleBase <|-- PricingRuleCreate
    PricingRuleBase <|-- PricingRuleResponse
    StaticPageCreate <|-- StaticPageBase
    StaticPageResponse <|-- StaticPageBase
    StaticPageBase <|-- StaticPageCreate
    StaticPageBase <|-- StaticPageResponse
    StorefrontContentCreate <|-- StorefrontContentBase
    StorefrontContentResponse <|-- StorefrontContentBase
    StorefrontContentBase <|-- StorefrontContentCreate
    StorefrontContentBase <|-- StorefrontContentResponse
    SupplierCreate <|-- SupplierBase
    SupplierResponse <|-- SupplierBase
    SupplierBase <|-- SupplierCreate
    SupplierBase <|-- SupplierResponse
    ThemeResponse <|-- ThemeBase
    ThemeBase <|-- ThemeResponse
```

## Relationships

- No strong cross-community connections detected

## Source Files

- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\ai\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/ai/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\ai\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/ai/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\auth\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/auth/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\b2b\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/b2b/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\blog\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/blog/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\catalog\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/catalog/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\channels\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/channels/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\export\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/export/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\features\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/features/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\features\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/features/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\inventory\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/inventory/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\orders\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\pos\models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pos/models.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\pos\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pos/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\pos\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pos/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\pricing\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pricing/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\storefront\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/storefront/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\themes\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/themes/schemas.py)

## Audit Trail

- EXTRACTED: 442 (97%)
- INFERRED: 13 (3%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [[index]] to navigate.*