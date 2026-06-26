# UserClaims

> God node · 143 connections · [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\shared\auth.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/shared/auth.py#L12)

## Call Trace Diagram

```mermaid
sequenceDiagram
    participant P0 as UserClaims
    participant P1 as Fixture to override validate_token dependency.     Usage: auth_override(UserCla
    participant P2 as Variant
    participant P3 as Fixture to override validate_token dependency.     Usage: auth_override(UserCla
    participant P4 as Mark an order as fulfilled and log tracking information.
    participant P5 as B2B Buyer places an order.     1. Validate Buyer Account     2. Calculate Tota
    participant P6 as Returns the product catalog scoped for the B2B buyer,     including custom pric
    participant P7 as Create a new product with its variants.     Enforces catalog:write permission a
    participant P8 as List products for the authenticated tenant.     Supports pagination and filteri
    participant P9 as Update a product and its variants. If slug changes, create a 301 redirect.
    participant P10 as List 301 redirects for the tenant.
    participant P11 as Simulates sending an email report of variant SKU changes to the merchant.
    participant P12 as Simulates sending an email report of deactivated variants during options collaps
    participant P13 as Process CSV import in background.     Simple AI Mapping: Look for 'title', 'pri
    participant P14 as Start a bulk import job from CSV.
    participant P15 as Create a new color preset for the merchant's tenant.
    participant P16 as List all color presets for the tenant.
    participant P17 as Delete a color preset for the tenant.
    participant P18 as Update an existing color preset for the tenant.
    participant P19 as Dev: print to console + save to scratch/import_reports. Prod: real email.
    participant P20 as Parse CSV or XLSX bytes into a list of row dicts.
    participant P21 as Return sorted list of N for all Option{N} Name/Value pairs found in headers.
    participant P22 as Background task: parse file, upsert products+variants+inventory, update job, sen
    participant P23 as Download a pre-filled CSV template with all supported import column headers.
    participant P24 as Check which SKUs from the provided list already exist in this tenant's catalog.
    participant P25 as Upload a .csv or .xlsx file to bulk-import products and variants.     Returns a
    participant P26 as Returns all import jobs for this tenant, newest first.
    participant P27 as Poll the status of a specific import job.
    participant P28 as # TODO: Implement XML feed regeneration logic
    participant P29 as MockStripe
    participant P30 as Step 1: Calculate total and create Stripe PaymentIntent.     Public storefront
    participant P31 as Step 2: Verify payment and create order with atomic inventory decrement.     Pu
    participant P32 as Aggregate unique customers from the orders table.     For MVP, we return email,
    participant P33 as Export orders for the tenant as a CSV file.
    participant P34 as Refund an order via Stripe.
    participant P35 as List all orders for the authenticated consumer.
    participant P36 as Get details for a specific order owned by the consumer.
    participant P37 as Request a return for an order. Logs an event for merchant review.
    participant P38 as _process_import_job()
    participant P39 as Performs a 'peace of mind' test by creating and immediately deleting a GCS bucke
    participant P40 as Provisions isolated GCP resources and SQL schema for a new tenant.     This is
    participant P41 as Seeds mock orders and customers for the current tenant.     Enables verificatio
    participant P42 as Verify that accessing B2B endpoints without a token returns 403.
    participant P43 as Verify that an admin can invite a B2B buyer.
    participant P44 as Verify that inviting a duplicate email fails with 409.
    participant P45 as Verify tenant isolation for B2B buyers.
    participant P46 as Verify price list creation.
    participant P47 as Verify that approval workflow can be retrieved and updated (upsert).
    participant P48 as Verify B2B portal order placement and threshold-based approval.
    participant P49 as Verify B2B portal catalog returns custom pricing.
    participant P50 as Verify that an invoice is generated upon B2B order approval.
    participant P51 as seed_demo_data()
    participant P52 as test_get_b2b_catalog_overrides()
    participant P53 as test_pos_sale_success()
    participant P54 as ChannelAdapter
    participant P55 as TikTokAdapter
    participant P56 as InstagramAdapter
    participant P57 as FacebookAdapter
    participant P58 as test_analytics_needs_attention()
    participant P59 as test_pos_sale_insufficient_stock()
    participant P60 as Handle Instagram OAuth callback.
    participant P61 as ChannelSyncService
    participant P62 as List all merchants and their subscription status.
    participant P63 as update_product()
    participant P64 as test_place_b2b_order_threshold()
    participant P65 as Get real-time revenue KPIs:     - GMV (Gross Merchandise Value)     - Order Co
    participant P66 as Vertex AI Demand Forecasting Stub.
    participant P67 as Scoped BigQuery/Looker Studio embed token generator.
    participant P68 as Test end-to-end checkout: payment-intent -> confirm -> inventory decrement.
    participant P69 as Verify that accessing POS endpoints without a token returns 403.
    participant P70 as Verify that an admin can assign a staff member to a location.
    participant P71 as Verify successful POS sale processing.
    participant P72 as Verify that POS sale fails if stock is insufficient.
    participant P73 as create_product()
    participant P74 as test_shipping_calculation_blending_success()
    participant P75 as test_order_checkout_flow()
    participant P76 as test_tax_calculation_manual_fallback()
    participant P77 as background_import_task()
    participant P78 as test_tiktok_sync()
    participant P79 as test_instagram_sync()
    participant P80 as test_facebook_sync()
    participant P81 as test_purchase_order_lifecycle()
    participant P82 as test_stock_transfer()
    participant P83 as test_insufficient_stock()
    participant P84 as test_jsonld_structured_data()
    participant P85 as test_sitemap_xml()
    participant P86 as test_tax_calculation_stripe_automated()
    participant P87 as CSV-B-001 & CSV-B-002: Verify template returns valid headers.
    participant P88 as CSV-B-003: Check SKU existence check works.
    participant P89 as CSV-B-004 & CSV-B-010: Successful import of clean CSV.
    participant P90 as CSV-B-005: Upload with conflict_strategy=skip skips duplicate SKUs.
    participant P91 as CSV-B-006: Upload with conflict_strategy=overwrite updates existing variant.
    participant P92 as CSV-B-007: Upload with conflict_strategy=custom_sku renames duplicate SKU.
    participant P93 as CSV-B-008, CSV-B-009, CSV-B-011, CSV-B-013: Verify error reporting and validatio
    participant P94 as CSV-B-012: Rows with no stock are logged to no_stock_log.
    participant P95 as CSV-B-014: Parse arbitrary option columns (e.g. Option7 Name/Value).
    participant P96 as CSV-B-015: History endpoint returns jobs for tenant sorted by date desc.
    participant P97 as CSV-B-016: Parse XLSX file bytes successfully.
    participant P98 as test_sku_exists_endpoint()
    participant P99 as test_import_conflict_skip()
    participant P100 as test_import_conflict_overwrite()
    participant P101 as test_import_conflict_custom_sku()
    participant P102 as Generates a live Google Shopping XML feed for the tenant.
    participant P103 as test_google_shopping_feed()
    participant P104 as Product
    participant P105 as StockLocation
    participant P106 as Inventory
    participant P107 as Order
    participant P108 as StaffRoleAssignment
    participant P109 as ImportJob
    participant P110 as Tenant
    participant P111 as StaffSecurityState
    participant P112 as Collection
    participant P113 as StaffUser
    participant P114 as CollectionProduct
    participant P115 as RedirectRule
    participant P116 as B2BAccount
    participant P117 as ColorPreset
    participant P118 as B2BInvitation
    participant P119 as Invitation
    participant P120 as Subscription
    participant P121 as BuyerUser
    participant P122 as ConsumerUser
    participant P123 as OrderItem
    participant P124 as StaffLoginHistory
    participant P125 as OrderEvent
    participant P126 as BrandProfile
    participant P127 as ApprovalWorkflow
    participant P128 as PriceList
    participant P129 as PriceListItem
    participant P130 as ApprovalRequest
    participant P131 as B2BInvoice
    participant P132 as OrderNote
    participant P133 as ChannelConnection
    participant P134 as ChannelSyncLog
    participant P135 as OnboardingSession
    participant P136 as ImportMapping
    participant P137 as Supplier
    participant P138 as StaticPage
    participant P139 as ThemeConfiguration
    participant P140 as BrandVoiceProfile
    participant P141 as StorePolicy
    participant P142 as PurchaseOrder
    participant P143 as PurchaseOrderLine
    participant P144 as StockTransfer
    participant P145 as StorefrontContent
    participant P146 as MerchantCarrierConnection
    participant P147 as CarrierCheckoutOption
    participant P148 as Theme
    participant P149 as Feature
    participant P150 as TenantFeatureActivation
    participant P151 as TenantFeatureConfig
    participant P152 as FeatureRequest
    participant P153 as FeatureRequestVote
    participant P154 as AICopywriterLog
    participant P155 as ExportJob
    participant P156 as PricingRule
    participant P157 as StoreShippingProfile
    participant P158 as StoreShippingZone
    participant P159 as StoreShippingRate
    participant P160 as StoreTaxRate
    participant P161 as SupplierPerformanceEvent
    participant P162 as PackagingPreset
    participant P163 as SupplierScoreWeights
    participant P164 as ShippingSettings
    participant P165 as StoreNavigationMenu
    participant P166 as StoreNavigationItem
    participant P167 as Generate Facebook OAuth authorization URL.
    participant P168 as Invite a new staff member.
    participant P169 as List pending invitations for the current tenant.
    participant P170 as Cancel a pending invitation.
    participant P171 as Update a staff member's roles and sync with Firebase claims.
    participant P172 as Revoke a staff member's access to the current tenant.
    participant P173 as Transfer store ownership to another staff member.
    participant P174 as Register a B2B buyer using an invitation token.
    participant P175 as Register a DTC consumer (post-checkout).
    participant P176 as Checks the active cool-off and blocked status of a Gmail account.
    participant P177 as Logs a failed sign-in attempt and initiates a 180s cool-off or block.
    participant P178 as Sends a short-lived (180s TTL) unblock token email to the user (max 3/24h).
    participant P179 as Verifies the unblock token and unlocks the account (does not require login).
    participant P180 as Allows an administrator or store owner to unblock a locked staff account.
    participant P181 as Check if a tenant ID (slug) is available.
    participant P182 as Fetch tenant identity and configuration for the current merchant.
    participant P183 as Update merchant store details (name, config).
    participant P184 as Fetch current subscription status for the tenant.
    participant P185 as Initiates a Stripe Checkout Session for tier upgrades.
    participant P186 as Finalizes an upgrade session.      In Stripe mode, this would verify the sessio
    participant P187 as Lists all invoices from Stripe for the current tenant.
    participant P188 as Creates a Stripe Billing Portal session.
    participant P189 as Manually trigger the trial expiration check.
    participant P190 as Verify that a merchant can fetch their subscription.
    participant P191 as Verify that list_invoices returns empty list if no stripe customer.
    participant P192 as Verify that creating portal session fails without a stripe customer.
    participant P193 as Verify that the trial check task suspends expired tenants.
    participant P194 as Verify that the success URL correctly appends session_id if missing.
    participant P195 as Verify that complete-upgrade correctly identifies and processes a mock session.
    participant P196 as Aggregated metrics for platform administrators.
    participant P197 as Manually approve a merchant (e.g. after manual verification).
    participant P198 as PermissionChecker
    participant P199 as Verify that a failed login starts a cool-off and further logins fail during it.
    participant P200 as Verify that 3 failed login attempts (with cool-off bypassed/cleared) triggers a
    participant P201 as Verify that failures across 3 distinct days blocks the account.
    participant P202 as Verify that unblock email requests are capped at 3 per 24h, and verify works.
    participant P203 as Verify that an expired unblock token fails verification.
    participant P204 as Verify that an administrator cannot unblock a staff user from another tenant.
    participant P205 as validate_token()
    participant P206 as GeminiClient
    participant P207 as Update the list of supported locales for the current tenant.
    participant P208 as GDPR Right-to-Erasure Pipeline.     Anonymizes PII in Orders and B2B Accounts f
    participant P209 as Nightly schema drift detection.     Compares live schema vs SQLAlchemy metadata
    participant P210 as SYS-18 version detection.
    participant P211 as Verify that an owner can transfer ownership to another staff member.
    participant P212 as Verify that a non-owner cannot transfer ownership.
    participant P213 as Verify that a B2B buyer can register with a valid token.
    participant P214 as Verify that a consumer can register.
    participant P215 as Simulates the cloud tasks migration job described in US-049.     In production,
    participant P216 as Get the list of supported locales for the current tenant.
    participant P217 as Verify that calling provision-tenant twice for the same tenant is idempotent.
    participant P218 as Verify that a script failure returns 500.
    participant P219 as Verify that a Tenant record is correctly created in the platform schema.
    participant P220 as Verify that Alembic upgrade is called when not in SQLite.
    participant P221 as List all connected social channels for the tenant.
    participant P222 as Generate TikTok OAuth authorization URL.
    participant P223 as Handle TikTok OAuth callback and exchange code for access token.
    participant P224 as Generate Instagram (Meta) OAuth authorization URL.
    participant P225 as Handle Facebook OAuth callback.
    participant P226 as Trigger a manual catalog sync for a specific channel.
    participant P227 as Disconnect a social channel.
    participant P228 as Verify that accessing /products without a token returns 403.
    participant P229 as Verify that an owner can create a product with variants.
    participant P230 as Verify that a tenant only sees their own products.
    participant P231 as Verify that creating a variant with negative price fails with 400.
    participant P232 as Verify that PWYW variants cannot have a compare_at_price.
    participant P233 as Verify that prescription_document_required requires requires_prescription=True.
    participant P234 as Verify that is_perishable flag is saved correctly on Product.
    participant P235 as Verify that updating a variant SKU with email_sku_report=true triggers change de
    participant P236 as Verify that collapsing variants from options to simple product triggers collapse
    participant P237 as Verify that an owner can create a collection.
    participant P238 as Verify that a tenant only sees their own collections.
    participant P239 as Verify assigning products to a collection.
    participant P240 as Verify removing a product from a collection.
    participant P241 as Verify that a merchant can successfully create a color preset.
    participant P242 as Verify that creating a duplicate color preset name under the same tenant fails.
    participant P243 as Verify that invalid hex code formats fail schema validation.
    participant P244 as Verify that preset listing is isolated per tenant.
    participant P245 as Verify deleting a color preset.
    participant P246 as Verify that deleting a non-existent or other tenant's preset fails with 404.
    participant P247 as Verify that only users with internal:provision can call this.
    participant P248 as Verify that provisioning succeeds with correct permissions and mocked script.
    participant P249 as Test that switching themes carries forward matching content slots.
    P0->>+ P1: uses
    P1-->>- P0: return
    P1->>+ P0: uses
    P0-->>- P1: return
    P1->>+ P2: uses
    P2-->>- P1: return
    P2->>+ P1: uses
    P1-->>- P2: return
    P2->>+ P3: uses
    P3-->>- P2: return
    P2->>+ P4: uses
    P4-->>- P2: return
    P2->>+ P5: uses
    P5-->>- P2: return
    P2->>+ P6: uses
    P6-->>- P2: return
    P2->>+ P7: uses
    P7-->>- P2: return
    P2->>+ P8: uses
    P8-->>- P2: return
    P2->>+ P9: uses
    P9-->>- P2: return
    P2->>+ P10: uses
    P10-->>- P2: return
    P2->>+ P11: uses
    P11-->>- P2: return
    P2->>+ P12: uses
    P12-->>- P2: return
    P2->>+ P13: uses
    P13-->>- P2: return
    P2->>+ P14: uses
    P14-->>- P2: return
    P2->>+ P15: uses
    P15-->>- P2: return
    P2->>+ P16: uses
    P16-->>- P2: return
    P2->>+ P17: uses
    P17-->>- P2: return
    P2->>+ P18: uses
    P18-->>- P2: return
    P2->>+ P19: uses
    P19-->>- P2: return
    P2->>+ P20: uses
    P20-->>- P2: return
    P2->>+ P21: uses
    P21-->>- P2: return
    P2->>+ P22: uses
    P22-->>- P2: return
    P2->>+ P23: uses
    P23-->>- P2: return
    P2->>+ P24: uses
    P24-->>- P2: return
    P2->>+ P25: uses
    P25-->>- P2: return
    P2->>+ P26: uses
    P26-->>- P2: return
    P2->>+ P27: uses
    P27-->>- P2: return
    P2->>+ P28: uses
    P28-->>- P2: return
    P2->>+ P29: uses
    P29-->>- P2: return
    P2->>+ P30: uses
    P30-->>- P2: return
    P2->>+ P31: uses
    P31-->>- P2: return
    P2->>+ P32: uses
    P32-->>- P2: return
    P2->>+ P33: uses
    P33-->>- P2: return
    P2->>+ P34: uses
    P34-->>- P2: return
    P2->>+ P35: uses
    P35-->>- P2: return
    P2->>+ P36: uses
    P36-->>- P2: return
    P2->>+ P37: uses
    P37-->>- P2: return
    P2->>+ P38: calls
    P38-->>- P2: return
    P2->>+ P39: uses
    P39-->>- P2: return
    P2->>+ P40: uses
    P40-->>- P2: return
    P2->>+ P41: uses
    P41-->>- P2: return
    P2->>+ P42: uses
    P42-->>- P2: return
    P2->>+ P43: uses
    P43-->>- P2: return
    P2->>+ P44: uses
    P44-->>- P2: return
    P2->>+ P45: uses
    P45-->>- P2: return
    P2->>+ P46: uses
    P46-->>- P2: return
    P2->>+ P47: uses
    P47-->>- P2: return
    P2->>+ P48: uses
    P48-->>- P2: return
    P2->>+ P49: uses
    P49-->>- P2: return
    P2->>+ P50: uses
    P50-->>- P2: return
    P2->>+ P51: calls
    P51-->>- P2: return
    P2->>+ P52: calls
    P52-->>- P2: return
    P2->>+ P53: calls
    P53-->>- P2: return
    P2->>+ P54: uses
    P54-->>- P2: return
    P2->>+ P55: uses
    P55-->>- P2: return
    P2->>+ P56: uses
    P56-->>- P2: return
    P2->>+ P57: uses
    P57-->>- P2: return
    P2->>+ P58: calls
    P58-->>- P2: return
    P2->>+ P59: calls
    P59-->>- P2: return
    P2->>+ P60: uses
    P60-->>- P2: return
    P2->>+ P61: uses
    P61-->>- P2: return
    P2->>+ P62: uses
    P62-->>- P2: return
    P2->>+ P63: calls
    P63-->>- P2: return
    P2->>+ P64: calls
    P64-->>- P2: return
    P2->>+ P65: uses
    P65-->>- P2: return
    P2->>+ P66: uses
    P66-->>- P2: return
    P2->>+ P67: uses
    P67-->>- P2: return
    P2->>+ P68: uses
    P68-->>- P2: return
    P2->>+ P69: uses
    P69-->>- P2: return
    P2->>+ P70: uses
    P70-->>- P2: return
    P2->>+ P71: uses
    P71-->>- P2: return
    P2->>+ P72: uses
    P72-->>- P2: return
    P2->>+ P73: calls
    P73-->>- P2: return
    P2->>+ P74: calls
    P74-->>- P2: return
    P2->>+ P75: calls
    P75-->>- P2: return
    P2->>+ P76: calls
    P76-->>- P2: return
    P2->>+ P77: calls
    P77-->>- P2: return
    P2->>+ P78: calls
    P78-->>- P2: return
    P2->>+ P79: calls
    P79-->>- P2: return
    P2->>+ P80: calls
    P80-->>- P2: return
    P2->>+ P81: calls
    P81-->>- P2: return
    P2->>+ P82: calls
    P82-->>- P2: return
    P2->>+ P83: calls
    P83-->>- P2: return
    P2->>+ P84: calls
    P84-->>- P2: return
    P2->>+ P85: calls
    P85-->>- P2: return
    P2->>+ P86: calls
    P86-->>- P2: return
    P2->>+ P87: uses
    P87-->>- P2: return
    P2->>+ P88: uses
    P88-->>- P2: return
    P2->>+ P89: uses
    P89-->>- P2: return
    P2->>+ P90: uses
    P90-->>- P2: return
    P2->>+ P91: uses
    P91-->>- P2: return
    P2->>+ P92: uses
    P92-->>- P2: return
    P2->>+ P93: uses
    P93-->>- P2: return
    P2->>+ P94: uses
    P94-->>- P2: return
    P2->>+ P95: uses
    P95-->>- P2: return
    P2->>+ P96: uses
    P96-->>- P2: return
    P2->>+ P97: uses
    P97-->>- P2: return
    P2->>+ P98: calls
    P98-->>- P2: return
    P2->>+ P99: calls
    P99-->>- P2: return
    P2->>+ P100: calls
    P100-->>- P2: return
    P2->>+ P101: calls
    P101-->>- P2: return
    P2->>+ P102: uses
    P102-->>- P2: return
    P2->>+ P103: calls
    P103-->>- P2: return
    P1->>+ P104: uses
    P104-->>- P1: return
    P1->>+ P105: uses
    P105-->>- P1: return
    P1->>+ P106: uses
    P106-->>- P1: return
    P1->>+ P107: uses
    P107-->>- P1: return
    P1->>+ P108: uses
    P108-->>- P1: return
    P1->>+ P109: uses
    P109-->>- P1: return
    P1->>+ P110: uses
    P110-->>- P1: return
    P1->>+ P111: uses
    P111-->>- P1: return
    P1->>+ P112: uses
    P112-->>- P1: return
    P1->>+ P113: uses
    P113-->>- P1: return
    P1->>+ P114: uses
    P114-->>- P1: return
    P1->>+ P115: uses
    P115-->>- P1: return
    P1->>+ P116: uses
    P116-->>- P1: return
    P1->>+ P117: uses
    P117-->>- P1: return
    P1->>+ P118: uses
    P118-->>- P1: return
    P1->>+ P119: uses
    P119-->>- P1: return
    P1->>+ P120: uses
    P120-->>- P1: return
    P1->>+ P121: uses
    P121-->>- P1: return
    P1->>+ P122: uses
    P122-->>- P1: return
    P1->>+ P123: uses
    P123-->>- P1: return
    P1->>+ P124: uses
    P124-->>- P1: return
    P1->>+ P125: uses
    P125-->>- P1: return
    P1->>+ P126: uses
    P126-->>- P1: return
    P1->>+ P127: uses
    P127-->>- P1: return
    P1->>+ P128: uses
    P128-->>- P1: return
    P1->>+ P129: uses
    P129-->>- P1: return
    P1->>+ P130: uses
    P130-->>- P1: return
    P1->>+ P131: uses
    P131-->>- P1: return
    P1->>+ P132: uses
    P132-->>- P1: return
    P1->>+ P133: uses
    P133-->>- P1: return
    P1->>+ P134: uses
    P134-->>- P1: return
    P1->>+ P135: uses
    P135-->>- P1: return
    P1->>+ P136: uses
    P136-->>- P1: return
    P1->>+ P137: uses
    P137-->>- P1: return
    P1->>+ P138: uses
    P138-->>- P1: return
    P1->>+ P139: uses
    P139-->>- P1: return
    P1->>+ P140: uses
    P140-->>- P1: return
    P1->>+ P141: uses
    P141-->>- P1: return
    P1->>+ P142: uses
    P142-->>- P1: return
    P1->>+ P143: uses
    P143-->>- P1: return
    P1->>+ P144: uses
    P144-->>- P1: return
    P1->>+ P145: uses
    P145-->>- P1: return
    P1->>+ P146: uses
    P146-->>- P1: return
    P1->>+ P147: uses
    P147-->>- P1: return
    P1->>+ P148: uses
    P148-->>- P1: return
    P1->>+ P149: uses
    P149-->>- P1: return
    P1->>+ P150: uses
    P150-->>- P1: return
    P1->>+ P151: uses
    P151-->>- P1: return
    P1->>+ P152: uses
    P152-->>- P1: return
    P1->>+ P153: uses
    P153-->>- P1: return
    P1->>+ P154: uses
    P154-->>- P1: return
    P1->>+ P155: uses
    P155-->>- P1: return
    P1->>+ P156: uses
    P156-->>- P1: return
    P1->>+ P157: uses
    P157-->>- P1: return
    P1->>+ P158: uses
    P158-->>- P1: return
    P1->>+ P159: uses
    P159-->>- P1: return
    P1->>+ P160: uses
    P160-->>- P1: return
    P1->>+ P161: uses
    P161-->>- P1: return
    P1->>+ P162: uses
    P162-->>- P1: return
    P1->>+ P163: uses
    P163-->>- P1: return
    P1->>+ P164: uses
    P164-->>- P1: return
    P1->>+ P165: uses
    P165-->>- P1: return
    P1->>+ P166: uses
    P166-->>- P1: return
    P0->>+ P3: uses
    P3-->>- P0: return
    P0->>+ P4: uses
    P4-->>- P0: return
    P0->>+ P111: uses
    P111-->>- P0: return
    P0->>+ P5: uses
    P5-->>- P0: return
    P0->>+ P6: uses
    P6-->>- P0: return
    P0->>+ P7: uses
    P7-->>- P0: return
    P0->>+ P8: uses
    P8-->>- P0: return
    P0->>+ P9: uses
    P9-->>- P0: return
    P0->>+ P10: uses
    P10-->>- P0: return
    P0->>+ P11: uses
    P11-->>- P0: return
    P0->>+ P12: uses
    P12-->>- P0: return
    P0->>+ P13: uses
    P13-->>- P0: return
    P0->>+ P14: uses
    P14-->>- P0: return
    P0->>+ P15: uses
    P15-->>- P0: return
    P0->>+ P16: uses
    P16-->>- P0: return
    P0->>+ P17: uses
    P17-->>- P0: return
    P0->>+ P18: uses
    P18-->>- P0: return
    P0->>+ P19: uses
    P19-->>- P0: return
    P0->>+ P20: uses
    P20-->>- P0: return
    P0->>+ P21: uses
    P21-->>- P0: return
    P0->>+ P22: uses
    P22-->>- P0: return
    P0->>+ P23: uses
    P23-->>- P0: return
    P0->>+ P24: uses
    P24-->>- P0: return
    P0->>+ P25: uses
    P25-->>- P0: return
    P0->>+ P26: uses
    P26-->>- P0: return
    P0->>+ P27: uses
    P27-->>- P0: return
    P0->>+ P28: uses
    P28-->>- P0: return
    P0->>+ P29: uses
    P29-->>- P0: return
    P0->>+ P167: uses
    P167-->>- P0: return
    P0->>+ P168: uses
    P168-->>- P0: return
    P0->>+ P169: uses
    P169-->>- P0: return
    P0->>+ P170: uses
    P170-->>- P0: return
    P0->>+ P171: uses
    P171-->>- P0: return
    P0->>+ P172: uses
    P172-->>- P0: return
    P0->>+ P173: uses
    P173-->>- P0: return
    P0->>+ P174: uses
    P174-->>- P0: return
    P0->>+ P175: uses
    P175-->>- P0: return
    P0->>+ P176: uses
    P176-->>- P0: return
    P0->>+ P177: uses
    P177-->>- P0: return
    P0->>+ P178: uses
    P178-->>- P0: return
    P0->>+ P179: uses
    P179-->>- P0: return
    P0->>+ P180: uses
    P180-->>- P0: return
    P0->>+ P30: uses
    P30-->>- P0: return
    P0->>+ P31: uses
    P31-->>- P0: return
    P0->>+ P32: uses
    P32-->>- P0: return
    P0->>+ P33: uses
    P33-->>- P0: return
    P0->>+ P34: uses
    P34-->>- P0: return
    P0->>+ P35: uses
    P35-->>- P0: return
    P0->>+ P36: uses
    P36-->>- P0: return
    P0->>+ P37: uses
    P37-->>- P0: return
    P0->>+ P39: uses
    P39-->>- P0: return
    P0->>+ P40: uses
    P40-->>- P0: return
    P0->>+ P41: uses
    P41-->>- P0: return
    P0->>+ P181: uses
    P181-->>- P0: return
    P0->>+ P182: uses
    P182-->>- P0: return
    P0->>+ P183: uses
    P183-->>- P0: return
    P0->>+ P42: uses
    P42-->>- P0: return
    P0->>+ P43: uses
    P43-->>- P0: return
    P0->>+ P44: uses
    P44-->>- P0: return
    P0->>+ P45: uses
    P45-->>- P0: return
    P0->>+ P46: uses
    P46-->>- P0: return
    P0->>+ P47: uses
    P47-->>- P0: return
    P0->>+ P48: uses
    P48-->>- P0: return
    P0->>+ P49: uses
    P49-->>- P0: return
    P0->>+ P50: uses
    P50-->>- P0: return
    P0->>+ P184: uses
    P184-->>- P0: return
    P0->>+ P185: uses
    P185-->>- P0: return
    P0->>+ P186: uses
    P186-->>- P0: return
    P0->>+ P187: uses
    P187-->>- P0: return
    P0->>+ P188: uses
    P188-->>- P0: return
    P0->>+ P189: uses
    P189-->>- P0: return
    P0->>+ P60: uses
    P60-->>- P0: return
    P0->>+ P62: uses
    P62-->>- P0: return
    P0->>+ P65: uses
    P65-->>- P0: return
    P0->>+ P66: uses
    P66-->>- P0: return
    P0->>+ P67: uses
    P67-->>- P0: return
    P0->>+ P69: uses
    P69-->>- P0: return
    P0->>+ P70: uses
    P70-->>- P0: return
    P0->>+ P71: uses
    P71-->>- P0: return
    P0->>+ P72: uses
    P72-->>- P0: return
    P0->>+ P190: uses
    P190-->>- P0: return
    P0->>+ P191: uses
    P191-->>- P0: return
    P0->>+ P192: uses
    P192-->>- P0: return
    P0->>+ P193: uses
    P193-->>- P0: return
    P0->>+ P194: uses
    P194-->>- P0: return
    P0->>+ P195: uses
    P195-->>- P0: return
    P0->>+ P196: uses
    P196-->>- P0: return
    P0->>+ P197: uses
    P197-->>- P0: return
    P0->>+ P198: uses
    P198-->>- P0: return
    P0->>+ P199: uses
    P199-->>- P0: return
    P0->>+ P200: uses
    P200-->>- P0: return
    P0->>+ P201: uses
    P201-->>- P0: return
    P0->>+ P202: uses
    P202-->>- P0: return
    P0->>+ P203: uses
    P203-->>- P0: return
    P0->>+ P204: uses
    P204-->>- P0: return
    P0->>+ P205: calls
    P205-->>- P0: return
    P0->>+ P206: uses
    P206-->>- P0: return
    P0->>+ P207: uses
    P207-->>- P0: return
    P0->>+ P208: uses
    P208-->>- P0: return
    P0->>+ P209: uses
    P209-->>- P0: return
    P0->>+ P210: uses
    P210-->>- P0: return
    P0->>+ P211: uses
    P211-->>- P0: return
    P0->>+ P212: uses
    P212-->>- P0: return
    P0->>+ P213: uses
    P213-->>- P0: return
    P0->>+ P214: uses
    P214-->>- P0: return
    P0->>+ P215: uses
    P215-->>- P0: return
    P0->>+ P216: uses
    P216-->>- P0: return
    P0->>+ P217: uses
    P217-->>- P0: return
    P0->>+ P218: uses
    P218-->>- P0: return
    P0->>+ P219: uses
    P219-->>- P0: return
    P0->>+ P220: uses
    P220-->>- P0: return
    P0->>+ P221: uses
    P221-->>- P0: return
    P0->>+ P222: uses
    P222-->>- P0: return
    P0->>+ P223: uses
    P223-->>- P0: return
    P0->>+ P224: uses
    P224-->>- P0: return
    P0->>+ P225: uses
    P225-->>- P0: return
    P0->>+ P226: uses
    P226-->>- P0: return
    P0->>+ P227: uses
    P227-->>- P0: return
    P0->>+ P228: uses
    P228-->>- P0: return
    P0->>+ P229: uses
    P229-->>- P0: return
    P0->>+ P230: uses
    P230-->>- P0: return
    P0->>+ P231: uses
    P231-->>- P0: return
    P0->>+ P232: uses
    P232-->>- P0: return
    P0->>+ P233: uses
    P233-->>- P0: return
    P0->>+ P234: uses
    P234-->>- P0: return
    P0->>+ P235: uses
    P235-->>- P0: return
    P0->>+ P236: uses
    P236-->>- P0: return
    P0->>+ P237: uses
    P237-->>- P0: return
    P0->>+ P238: uses
    P238-->>- P0: return
    P0->>+ P239: uses
    P239-->>- P0: return
    P0->>+ P240: uses
    P240-->>- P0: return
    P0->>+ P241: uses
    P241-->>- P0: return
    P0->>+ P242: uses
    P242-->>- P0: return
    P0->>+ P243: uses
    P243-->>- P0: return
    P0->>+ P244: uses
    P244-->>- P0: return
    P0->>+ P245: uses
    P245-->>- P0: return
    P0->>+ P246: uses
    P246-->>- P0: return
    P0->>+ P247: uses
    P247-->>- P0: return
    P0->>+ P248: uses
    P248-->>- P0: return
    P0->>+ P249: uses
    P249-->>- P0: return
```

## Connections by Relation

### calls
- [[validate_token()]] `EXTRACTED`

### contains
- [[auth.py]] `EXTRACTED`

### inherits
- [[BaseModel]] `EXTRACTED`

### uses
- [[Fixture to override validate_token dependency.     Usage: auth_override(UserCla]] `INFERRED`
- [[Fixture to override validate_token dependency.     Usage: auth_override(UserCla]] `INFERRED`
- [[Mark an order as fulfilled and log tracking information.]] `INFERRED`
- [[StaffSecurityState]] `INFERRED`
- [[B2B Buyer places an order.     1. Validate Buyer Account     2. Calculate Tota]] `INFERRED`
- [[Returns the product catalog scoped for the B2B buyer,     including custom pric]] `INFERRED`
- [[Create a new product with its variants.     Enforces catalog:write permission a]] `INFERRED`
- [[List products for the authenticated tenant.     Supports pagination and filteri]] `INFERRED`
- [[Update a product and its variants. If slug changes, create a 301 redirect.]] `INFERRED`
- [[List 301 redirects for the tenant.]] `INFERRED`
- [[Simulates sending an email report of variant SKU changes to the merchant.]] `INFERRED`
- [[Simulates sending an email report of deactivated variants during options collaps]] `INFERRED`
- [[Process CSV import in background.     Simple AI Mapping: Look for 'title', 'pri]] `INFERRED`
- [[Start a bulk import job from CSV.]] `INFERRED`
- [[Create a new color preset for the merchant's tenant.]] `INFERRED`
- [[List all color presets for the tenant.]] `INFERRED`
- [[Delete a color preset for the tenant.]] `INFERRED`
- [[Update an existing color preset for the tenant.]] `INFERRED`
- [[Dev: print to console + save to scratch/import_reports. Prod: real email.]] `INFERRED`
- [[Parse CSV or XLSX bytes into a list of row dicts.]] `INFERRED`

---

*Part of the graphify knowledge wiki. See [[index]] to navigate.*