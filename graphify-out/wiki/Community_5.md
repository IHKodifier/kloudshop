# Community 5

> 150 nodes · cohesion 0.03

## Key Concepts

- **BaseModel** (106 connections)
- [MockStripe](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/router.py#L29) (24 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/schemas.py#L1) (21 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/storefront/schemas.py#L1) (20 connections)
- [Step 2: Verify payment and create order with atomic inventory decrement.     Pu](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/router.py#L128) (20 connections)
- [Aggregate unique customers from the orders table.     For MVP, we return email,](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/router.py#L313) (20 connections)
- [Export orders for the tenant as a CSV file.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/router.py#L344) (20 connections)
- [Refund an order via Stripe.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/router.py#L462) (20 connections)
- [List all orders for the authenticated consumer.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/router.py#L530) (20 connections)
- [Get details for a specific order owned by the consumer.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/router.py#L548) (20 connections)
- [Request a return for an order. Logs an event for merchant review.](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/router.py#L573) (20 connections)
- [Step 1: Calculate total and create Stripe PaymentIntent.     Public storefront](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/router.py#L72) (20 connections)
- [OrderItem](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/models.py#L59) (19 connections)
- [OrderEvent](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/models.py#L80) (18 connections)
- [router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/router.py#L1) (17 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/inventory/schemas.py#L1) (16 connections)
- [schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/blog/schemas.py#L1) (14 connections)
- [OrderNote](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/models.py#L94) (13 connections)
- [PaymentIntentResponse](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/schemas.py#L138) (13 connections)
- [InventoryResponse](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/schemas.py#L40) (12 connections)
- [OrderConfirmRequest](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/schemas.py#L144) (12 connections)
- [OrderFulfilRequest](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/schemas.py#L156) (12 connections)
- [OrderRefundRequest](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/schemas.py#L162) (12 connections)
- [OrderResponse](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/schemas.py#L100) (12 connections)
- [PaymentIntentRequest](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/schemas.py#L132) (12 connections)
- *... and 125 more nodes in this community*

## Class Diagram

```mermaid
classDiagram
    class OrderEvent {
        +models.py()
    }
    class OrderItem {
        +models.py()
    }
    class OrderNote {
        +models.py()
    }
    class MockStripe {
        +router.py()
        +.create_payment_intent()
        +.retrieve_payment_intent()
        +.create_refund()
        +.calculate_tax()
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
    class InventoryBase {
        +schemas.py()
    }
    class InventoryResponse {
        +schemas.py()
    }
    class OrderConfirmRequest {
        +schemas.py()
    }
    class OrderEventResponse {
        +schemas.py()
    }
    class OrderFulfilRequest {
        +schemas.py()
    }
    class OrderItemBase {
        +schemas.py()
    }
    class OrderItemResponse {
        +schemas.py()
    }
    class OrderNoteBase {
        +schemas.py()
    }
    class OrderNoteCreate {
        +schemas.py()
    }
    class OrderNoteResponse {
        +schemas.py()
    }
    class OrderRefundRequest {
        +schemas.py()
    }
    class OrderResponse {
        +schemas.py()
    }
    class PaymentIntentRequest {
        +schemas.py()
    }
    class PaymentIntentResponse {
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
    class ReturnRequest {
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
    class StockLocationBase {
        +schemas.py()
    }
    class StockLocationCreate {
        +schemas.py()
    }
    class StockLocationResponse {
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
    OrderEvent --> MockStripe
    OrderItem --> MockStripe
    OrderNote --> MockStripe
    MockStripe --> OrderItem
    MockStripe --> OrderEvent
    MockStripe --> OrderNote
    MockStripe --> OrderResponse
    MockStripe --> PaymentIntentRequest
    MockStripe --> PaymentIntentResponse
    MockStripe --> OrderConfirmRequest
    MockStripe --> StockLocationResponse
    MockStripe --> StockLocationCreate
    MockStripe --> InventoryResponse
    MockStripe --> OrderFulfilRequest
    MockStripe --> OrderRefundRequest
    MockStripe --> ReturnRequest
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
    InventoryResponse <|-- InventoryBase
    InventoryBase <|-- InventoryResponse
    InventoryResponse --> MockStripe
    OrderConfirmRequest --> MockStripe
    OrderFulfilRequest --> MockStripe
    OrderNoteCreate <|-- OrderNoteBase
    OrderNoteResponse <|-- OrderNoteBase
    OrderNoteBase <|-- OrderNoteCreate
    OrderNoteBase <|-- OrderNoteResponse
    OrderRefundRequest --> MockStripe
    OrderResponse --> MockStripe
    PaymentIntentRequest --> MockStripe
    PaymentIntentResponse --> MockStripe
    POLineCreate <|-- POLineBase
    POLineResponse <|-- POLineBase
    POLineBase <|-- POLineCreate
    POLineBase <|-- POLineResponse
    ReturnRequest --> MockStripe
    StaticPageCreate <|-- StaticPageBase
    StaticPageResponse <|-- StaticPageBase
    StaticPageBase <|-- StaticPageCreate
    StaticPageBase <|-- StaticPageResponse
    StockLocationCreate <|-- StockLocationBase
    StockLocationResponse <|-- StockLocationBase
    StockLocationBase <|-- StockLocationCreate
    StockLocationCreate --> MockStripe
    StockLocationBase <|-- StockLocationResponse
    StockLocationResponse --> MockStripe
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

- [[Community 15]] (112 shared connections)
- [[Community 3]] (21 shared connections)
- [[Community 14]] (4 shared connections)
- [[Content & Features]] (3 shared connections)

## Source Files

- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\ai\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/ai/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\auth\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/auth/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\b2b\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/b2b/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\b2b\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/b2b/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\blog\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/blog/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\catalog\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/catalog/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\channels\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/channels/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\export\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/export/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\features\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/features/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\inventory\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/inventory/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\orders\models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/models.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\orders\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\orders\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/orders/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\pos\models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pos/models.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\pos\router.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pos/router.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\pos\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/pos/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\storefront\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/storefront/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\themes\schemas.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/themes/schemas.py)
- [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\frontend\lib\models\order.dart](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/models/order.dart)

## Audit Trail

- EXTRACTED: 541 (61%)
- INFERRED: 347 (39%)
- AMBIGUOUS: 0 (0%)

---

*Part of the graphify knowledge wiki. See [[index]] to navigate.*