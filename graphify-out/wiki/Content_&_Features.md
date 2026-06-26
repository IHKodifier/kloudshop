# Content & Features

> 207 nodes · cohesion 0.02

## Key Concepts

- **BaseModel** (126 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/storefront/schemas.py#L1) (20 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/inventory/schemas.py#L1) (16 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/inventory/router.py#L1) (15 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/shipping/schemas.py#L1) (15 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/blog/schemas.py#L1) (14 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/navigation/schemas.py#L1) (12 connections)
- [Check if a tenant ID (slug) is available.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/router.py#L24) (12 connections)
- [Fetch tenant identity and configuration for the current merchant.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/router.py#L52) (12 connections)
- [Update merchant store details (name, config).](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/router.py#L94) (12 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/navigation/router.py#L1) (11 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/shipping/router.py#L1) (11 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/router.py#L1) (10 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/features/schemas.py#L1) (9 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/schemas.py#L1) (8 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/policies/router.py#L1) (8 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/policies/schemas.py#L1) (8 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/tax/schemas.py#L1) (8 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/ai/schemas.py#L1) (7 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pos/schemas.py#L1) (7 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/themes/schemas.py#L1) (7 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pos/router.py#L1) (6 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/tax/router.py#L1) (6 connections)
- [StorePolicy](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/policies/models.py#L6) (6 connections)
- [ImportAnalysisResponse](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/schemas.py#L17) (6 connections)
- *... and 182 more nodes in this community*

## Class Diagram

```mermaid
classDiagram
    class StorePolicy {
        +models.py()
    }
    class StoreTaxRate {
        +models.py()
    }
    class B2BPortalOrderItem {
        +schemas.py()
    }
    class BlendedRateDetail {
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
    class ImportAnalysisRequest {
        +schemas.py()
    }
    class ImportAnalysisResponse {
        +schemas.py()
    }
    class ImportExecutionRequest {
        +schemas.py()
    }
    class LinkResolveResponse {
        +schemas.py()
    }
    class MigrationRunbookResponse {
        +schemas.py()
    }
    class NavigationItemBase {
        +schemas.py()
    }
    class NavigationItemCreate {
        +schemas.py()
    }
    class NavigationItemResponse {
        +schemas.py()
    }
    class NavigationItemTreeResponse {
        +schemas.py()
    }
    class NavigationMenuBase {
        +schemas.py()
    }
    class NavigationMenuCreate {
        +schemas.py()
    }
    class NavigationMenuResponse {
        +schemas.py()
    }
    class NavigationReorderItem {
        +schemas.py()
    }
    class NavigationReorderRequest {
        +schemas.py()
    }
    class OnboardingStatusResponse {
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
    class PolicyBase {
        +schemas.py()
    }
    class PolicyCreate {
        +schemas.py()
    }
    class PolicyResponse {
        +schemas.py()
    }
    class PolicyTemplateSeedRequest {
        +schemas.py()
    }
    class PolicyTemplateSeedResponse {
        +schemas.py()
    }
    class PolicyUpdate {
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
    class RegionSelectionRequest {
        +schemas.py()
    }
    class ShippingCalculateItem {
        +schemas.py()
    }
    class ShippingCalculateRequest {
        +schemas.py()
    }
    class ShippingCalculateResponse {
        +schemas.py()
    }
    class ShippingProfileBase {
        +schemas.py()
    }
    class ShippingProfileCreate {
        +schemas.py()
    }
    class ShippingProfileResponse {
        +schemas.py()
    }
    class ShippingRateBase {
        +schemas.py()
    }
    class ShippingRateCreate {
        +schemas.py()
    }
    class ShippingRateRequest {
        +schemas.py()
    }
    class ShippingRateResponse {
        +schemas.py()
        +schemas.py()
    }
    class ShippingZoneBase {
        +schemas.py()
    }
    class ShippingZoneCreate {
        +schemas.py()
    }
    class ShippingZoneResponse {
        +schemas.py()
    }
    class SignupRequest {
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
    class TaxCalculateItem {
        +schemas.py()
    }
    class TaxCalculateRequest {
        +schemas.py()
    }
    class TaxCalculateResponse {
        +schemas.py()
    }
    class TaxRateBase {
        +schemas.py()
    }
    class TaxRateCreate {
        +schemas.py()
    }
    class TaxRateResponse {
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
    NavigationItemCreate <|-- NavigationItemBase
    NavigationItemResponse <|-- NavigationItemBase
    NavigationItemBase <|-- NavigationItemCreate
    NavigationItemBase <|-- NavigationItemResponse
    NavigationItemTreeResponse <|-- NavigationItemResponse
    NavigationItemResponse <|-- NavigationItemTreeResponse
    NavigationMenuCreate <|-- NavigationMenuBase
    NavigationMenuResponse <|-- NavigationMenuBase
    NavigationMenuBase <|-- NavigationMenuCreate
    NavigationMenuBase <|-- NavigationMenuResponse
    PolicyCreate <|-- PolicyBase
    PolicyResponse <|-- PolicyBase
    PolicyBase <|-- PolicyCreate
    PolicyBase <|-- PolicyResponse
    POLineCreate <|-- POLineBase
    POLineResponse <|-- POLineBase
    POLineBase <|-- POLineCreate
    POLineBase <|-- POLineResponse
    ShippingProfileCreate <|-- ShippingProfileBase
    ShippingProfileResponse <|-- ShippingProfileBase
    ShippingProfileBase <|-- ShippingProfileCreate
    ShippingProfileBase <|-- ShippingProfileResponse
    ShippingRateCreate <|-- ShippingRateBase
    ShippingRateResponse <|-- ShippingRateBase
    ShippingRateBase <|-- ShippingRateCreate
    ShippingRateBase <|-- ShippingRateResponse
    ShippingZoneCreate <|-- ShippingZoneBase
    ShippingZoneResponse <|-- ShippingZoneBase
    ShippingZoneBase <|-- ShippingZoneCreate
    ShippingZoneBase <|-- ShippingZoneResponse
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
    TaxRateCreate <|-- TaxRateBase
    TaxRateResponse <|-- TaxRateBase
    TaxRateBase <|-- TaxRateCreate
    TaxRateBase <|-- TaxRateResponse
    ThemeResponse <|-- ThemeBase
    ThemeBase <|-- ThemeResponse
```

## Relationships

- [[Community 11]] (21 shared connections)

## Source Files

- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\ai\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/ai/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\auth\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/auth/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\b2b\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/b2b/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\blog\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/blog/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\catalog\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/catalog/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\channels\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/channels/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\export\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/export/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\features\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/features/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\inventory\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/inventory/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\inventory\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/inventory/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\navigation\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/navigation/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\navigation\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/navigation/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\onboarding\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\onboarding\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/onboarding/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\orders\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\policies\models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/policies/models.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\policies\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/policies/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\policies\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/policies/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\pos\models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pos/models.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\pos\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pos/router.py)

## Audit Trail

- EXTRACTED: 702 (88%)
- INFERRED: 99 (12%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [[index]] to navigate.*