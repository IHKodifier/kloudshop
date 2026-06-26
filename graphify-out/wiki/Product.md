# Product

> God node · 74 connections · [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\modules\catalog\models.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/modules/catalog/models.py#L10)

## Call Trace Diagram

```mermaid
sequenceDiagram
    participant P0 as Product
    participant P1 as Fixture to override validate_token dependency.     Usage: auth_override(UserCla
    participant P2 as UserClaims
    participant P3 as Fixture to override validate_token dependency.     Usage: auth_override(UserCla
    participant P4 as Mark an order as fulfilled and log tracking information.
    participant P5 as StaffSecurityState
    participant P6 as B2B Buyer places an order.     1. Validate Buyer Account     2. Calculate Tota
    participant P7 as Returns the product catalog scoped for the B2B buyer,     including custom pric
    participant P8 as Create a new product with its variants.     Enforces catalog:write permission a
    participant P9 as List products for the authenticated tenant.     Supports pagination and filteri
    participant P10 as Update a product and its variants. If slug changes, create a 301 redirect.
    participant P11 as List 301 redirects for the tenant.
    participant P12 as Simulates sending an email report of variant SKU changes to the merchant.
    participant P13 as Simulates sending an email report of deactivated variants during options collaps
    participant P14 as Process CSV import in background.     Simple AI Mapping: Look for 'title', 'pri
    participant P15 as Start a bulk import job from CSV.
    participant P16 as Create a new color preset for the merchant's tenant.
    participant P17 as List all color presets for the tenant.
    participant P18 as Delete a color preset for the tenant.
    participant P19 as Update an existing color preset for the tenant.
    participant P20 as Dev: print to console + save to scratch/import_reports. Prod: real email.
    participant P21 as Parse CSV or XLSX bytes into a list of row dicts.
    participant P22 as Return sorted list of N for all Option{N} Name/Value pairs found in headers.
    participant P23 as Background task: parse file, upsert products+variants+inventory, update job, sen
    participant P24 as Download a pre-filled CSV template with all supported import column headers.
    participant P25 as Check which SKUs from the provided list already exist in this tenant's catalog.
    participant P26 as Upload a .csv or .xlsx file to bulk-import products and variants.     Returns a
    participant P27 as Returns all import jobs for this tenant, newest first.
    participant P28 as Poll the status of a specific import job.
    participant P29 as # TODO: Implement XML feed regeneration logic
    participant P30 as MockStripe
    participant P31 as Generate Facebook OAuth authorization URL.
    participant P32 as Invite a new staff member.
    participant P33 as List pending invitations for the current tenant.
    participant P34 as Cancel a pending invitation.
    participant P35 as Update a staff member's roles and sync with Firebase claims.
    participant P36 as Revoke a staff member's access to the current tenant.
    participant P37 as Transfer store ownership to another staff member.
    participant P38 as Register a B2B buyer using an invitation token.
    participant P39 as Register a DTC consumer (post-checkout).
    participant P40 as Checks the active cool-off and blocked status of a Gmail account.
    participant P41 as Logs a failed sign-in attempt and initiates a 180s cool-off or block.
    participant P42 as Sends a short-lived (180s TTL) unblock token email to the user (max 3/24h).
    participant P43 as Verifies the unblock token and unlocks the account (does not require login).
    participant P44 as Allows an administrator or store owner to unblock a locked staff account.
    participant P45 as Step 1: Calculate total and create Stripe PaymentIntent.     Public storefront
    participant P46 as Step 2: Verify payment and create order with atomic inventory decrement.     Pu
    participant P47 as Aggregate unique customers from the orders table.     For MVP, we return email,
    participant P48 as Export orders for the tenant as a CSV file.
    participant P49 as Refund an order via Stripe.
    participant P50 as List all orders for the authenticated consumer.
    participant P51 as Get details for a specific order owned by the consumer.
    participant P52 as Request a return for an order. Logs an event for merchant review.
    participant P53 as Performs a 'peace of mind' test by creating and immediately deleting a GCS bucke
    participant P54 as Provisions isolated GCP resources and SQL schema for a new tenant.     This is
    participant P55 as Seeds mock orders and customers for the current tenant.     Enables verificatio
    participant P56 as Check if a tenant ID (slug) is available.
    participant P57 as Fetch tenant identity and configuration for the current merchant.
    participant P58 as Update merchant store details (name, config).
    participant P59 as Verify that accessing B2B endpoints without a token returns 403.
    participant P60 as Verify that an admin can invite a B2B buyer.
    participant P61 as Verify that inviting a duplicate email fails with 409.
    participant P62 as Verify tenant isolation for B2B buyers.
    participant P63 as Verify price list creation.
    participant P64 as Verify that approval workflow can be retrieved and updated (upsert).
    participant P65 as Verify B2B portal order placement and threshold-based approval.
    participant P66 as Verify B2B portal catalog returns custom pricing.
    participant P67 as Verify that an invoice is generated upon B2B order approval.
    participant P68 as Fetch current subscription status for the tenant.
    participant P69 as Initiates a Stripe Checkout Session for tier upgrades.
    participant P70 as Finalizes an upgrade session.      In Stripe mode, this would verify the sessio
    participant P71 as Lists all invoices from Stripe for the current tenant.
    participant P72 as Creates a Stripe Billing Portal session.
    participant P73 as Manually trigger the trial expiration check.
    participant P74 as Handle Instagram OAuth callback.
    participant P75 as List all merchants and their subscription status.
    participant P76 as Get real-time revenue KPIs:     - GMV (Gross Merchandise Value)     - Order Co
    participant P77 as Vertex AI Demand Forecasting Stub.
    participant P78 as Scoped BigQuery/Looker Studio embed token generator.
    participant P79 as Verify that accessing POS endpoints without a token returns 403.
    participant P80 as Verify that an admin can assign a staff member to a location.
    participant P81 as Verify successful POS sale processing.
    participant P82 as Verify that POS sale fails if stock is insufficient.
    participant P83 as Verify that a merchant can fetch their subscription.
    participant P84 as Verify that list_invoices returns empty list if no stripe customer.
    participant P85 as Verify that creating portal session fails without a stripe customer.
    participant P86 as Verify that the trial check task suspends expired tenants.
    participant P87 as Verify that the success URL correctly appends session_id if missing.
    participant P88 as Verify that complete-upgrade correctly identifies and processes a mock session.
    participant P89 as Aggregated metrics for platform administrators.
    participant P90 as Manually approve a merchant (e.g. after manual verification).
    participant P91 as PermissionChecker
    participant P92 as Verify that a failed login starts a cool-off and further logins fail during it.
    participant P93 as Verify that 3 failed login attempts (with cool-off bypassed/cleared) triggers a
    participant P94 as Verify that failures across 3 distinct days blocks the account.
    participant P95 as Verify that unblock email requests are capped at 3 per 24h, and verify works.
    participant P96 as Verify that an expired unblock token fails verification.
    participant P97 as Verify that an administrator cannot unblock a staff user from another tenant.
    participant P98 as validate_token()
    participant P99 as GeminiClient
    participant P100 as Update the list of supported locales for the current tenant.
    participant P101 as GDPR Right-to-Erasure Pipeline.     Anonymizes PII in Orders and B2B Accounts f
    participant P102 as Nightly schema drift detection.     Compares live schema vs SQLAlchemy metadata
    participant P103 as SYS-18 version detection.
    participant P104 as Verify that an owner can transfer ownership to another staff member.
    participant P105 as Verify that a non-owner cannot transfer ownership.
    participant P106 as Verify that a B2B buyer can register with a valid token.
    participant P107 as Verify that a consumer can register.
    participant P108 as Simulates the cloud tasks migration job described in US-049.     In production,
    participant P109 as Get the list of supported locales for the current tenant.
    participant P110 as Verify that calling provision-tenant twice for the same tenant is idempotent.
    participant P111 as Verify that a script failure returns 500.
    participant P112 as Verify that a Tenant record is correctly created in the platform schema.
    participant P113 as Verify that Alembic upgrade is called when not in SQLite.
    participant P114 as List all connected social channels for the tenant.
    participant P115 as Generate TikTok OAuth authorization URL.
    participant P116 as Handle TikTok OAuth callback and exchange code for access token.
    participant P117 as Generate Instagram (Meta) OAuth authorization URL.
    participant P118 as Handle Facebook OAuth callback.
    participant P119 as Trigger a manual catalog sync for a specific channel.
    participant P120 as Disconnect a social channel.
    participant P121 as Verify that accessing /products without a token returns 403.
    participant P122 as Verify that an owner can create a product with variants.
    participant P123 as Verify that a tenant only sees their own products.
    participant P124 as Verify that creating a variant with negative price fails with 400.
    participant P125 as Verify that PWYW variants cannot have a compare_at_price.
    participant P126 as Verify that prescription_document_required requires requires_prescription=True.
    participant P127 as Verify that is_perishable flag is saved correctly on Product.
    participant P128 as Verify that updating a variant SKU with email_sku_report=true triggers change de
    participant P129 as Verify that collapsing variants from options to simple product triggers collapse
    participant P130 as Verify that an owner can create a collection.
    participant P131 as Verify that a tenant only sees their own collections.
    participant P132 as Verify assigning products to a collection.
    participant P133 as Verify removing a product from a collection.
    participant P134 as Verify that a merchant can successfully create a color preset.
    participant P135 as Verify that creating a duplicate color preset name under the same tenant fails.
    participant P136 as Verify that invalid hex code formats fail schema validation.
    participant P137 as Verify that preset listing is isolated per tenant.
    participant P138 as Verify deleting a color preset.
    participant P139 as Verify that deleting a non-existent or other tenant's preset fails with 404.
    participant P140 as Verify that only users with internal:provision can call this.
    participant P141 as Verify that provisioning succeeds with correct permissions and mocked script.
    participant P142 as Test that switching themes carries forward matching content slots.
    participant P143 as Variant
    participant P144 as StockLocation
    participant P145 as Inventory
    participant P146 as Order
    participant P147 as StaffRoleAssignment
    participant P148 as ImportJob
    participant P149 as Tenant
    participant P150 as Collection
    participant P151 as StaffUser
    participant P152 as CollectionProduct
    participant P153 as RedirectRule
    participant P154 as B2BAccount
    participant P155 as ColorPreset
    participant P156 as B2BInvitation
    participant P157 as Invitation
    participant P158 as Subscription
    participant P159 as BuyerUser
    participant P160 as ConsumerUser
    participant P161 as OrderItem
    participant P162 as StaffLoginHistory
    participant P163 as OrderEvent
    participant P164 as BrandProfile
    participant P165 as ApprovalWorkflow
    participant P166 as PriceList
    participant P167 as PriceListItem
    participant P168 as ApprovalRequest
    participant P169 as B2BInvoice
    participant P170 as OrderNote
    participant P171 as ChannelConnection
    participant P172 as ChannelSyncLog
    participant P173 as OnboardingSession
    participant P174 as ImportMapping
    participant P175 as Supplier
    participant P176 as StaticPage
    participant P177 as ThemeConfiguration
    participant P178 as BrandVoiceProfile
    participant P179 as StorePolicy
    participant P180 as PurchaseOrder
    participant P181 as PurchaseOrderLine
    participant P182 as StockTransfer
    participant P183 as StorefrontContent
    participant P184 as MerchantCarrierConnection
    participant P185 as CarrierCheckoutOption
    participant P186 as Theme
    participant P187 as Feature
    participant P188 as TenantFeatureActivation
    participant P189 as TenantFeatureConfig
    participant P190 as FeatureRequest
    participant P191 as FeatureRequestVote
    participant P192 as AICopywriterLog
    participant P193 as ExportJob
    participant P194 as PricingRule
    participant P195 as StoreShippingProfile
    participant P196 as StoreShippingZone
    participant P197 as StoreShippingRate
    participant P198 as StoreTaxRate
    participant P199 as SupplierPerformanceEvent
    participant P200 as PackagingPreset
    participant P201 as SupplierScoreWeights
    participant P202 as ShippingSettings
    participant P203 as StoreNavigationMenu
    participant P204 as StoreNavigationItem
    participant P205 as ChannelAdapter
    participant P206 as TikTokAdapter
    participant P207 as InstagramAdapter
    participant P208 as FacebookAdapter
    participant P209 as ChannelSyncService
    participant P210 as Test end-to-end checkout: payment-intent -> confirm -> inventory decrement.
    participant P211 as Generates a dynamic XML sitemap for the storefront.
    participant P212 as CSV-B-001 & CSV-B-002: Verify template returns valid headers.
    participant P213 as CSV-B-003: Check SKU existence check works.
    participant P214 as CSV-B-004 & CSV-B-010: Successful import of clean CSV.
    participant P215 as CSV-B-005: Upload with conflict_strategy=skip skips duplicate SKUs.
    participant P216 as CSV-B-006: Upload with conflict_strategy=overwrite updates existing variant.
    participant P217 as CSV-B-007: Upload with conflict_strategy=custom_sku renames duplicate SKU.
    participant P218 as CSV-B-008, CSV-B-009, CSV-B-011, CSV-B-013: Verify error reporting and validatio
    participant P219 as CSV-B-012: Rows with no stock are logged to no_stock_log.
    participant P220 as CSV-B-014: Parse arbitrary option columns (e.g. Option7 Name/Value).
    participant P221 as CSV-B-015: History endpoint returns jobs for tenant sorted by date desc.
    participant P222 as CSV-B-016: Parse XLSX file bytes successfully.
    participant P223 as Generates a live Google Shopping XML feed for the tenant.
    P0->>+ P1: uses
    P1-->>- P0: return
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
    P2->>+ P38: uses
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
    P2->>+ P51: uses
    P51-->>- P2: return
    P2->>+ P52: uses
    P52-->>- P2: return
    P2->>+ P53: uses
    P53-->>- P2: return
    P2->>+ P54: uses
    P54-->>- P2: return
    P2->>+ P55: uses
    P55-->>- P2: return
    P2->>+ P56: uses
    P56-->>- P2: return
    P2->>+ P57: uses
    P57-->>- P2: return
    P2->>+ P58: uses
    P58-->>- P2: return
    P2->>+ P59: uses
    P59-->>- P2: return
    P2->>+ P60: uses
    P60-->>- P2: return
    P2->>+ P61: uses
    P61-->>- P2: return
    P2->>+ P62: uses
    P62-->>- P2: return
    P2->>+ P63: uses
    P63-->>- P2: return
    P2->>+ P64: uses
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
    P2->>+ P73: uses
    P73-->>- P2: return
    P2->>+ P74: uses
    P74-->>- P2: return
    P2->>+ P75: uses
    P75-->>- P2: return
    P2->>+ P76: uses
    P76-->>- P2: return
    P2->>+ P77: uses
    P77-->>- P2: return
    P2->>+ P78: uses
    P78-->>- P2: return
    P2->>+ P79: uses
    P79-->>- P2: return
    P2->>+ P80: uses
    P80-->>- P2: return
    P2->>+ P81: uses
    P81-->>- P2: return
    P2->>+ P82: uses
    P82-->>- P2: return
    P2->>+ P83: uses
    P83-->>- P2: return
    P2->>+ P84: uses
    P84-->>- P2: return
    P2->>+ P85: uses
    P85-->>- P2: return
    P2->>+ P86: uses
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
    P2->>+ P99: uses
    P99-->>- P2: return
    P2->>+ P100: uses
    P100-->>- P2: return
    P2->>+ P101: uses
    P101-->>- P2: return
    P2->>+ P102: uses
    P102-->>- P2: return
    P2->>+ P103: uses
    P103-->>- P2: return
    P2->>+ P104: uses
    P104-->>- P2: return
    P2->>+ P105: uses
    P105-->>- P2: return
    P2->>+ P106: uses
    P106-->>- P2: return
    P2->>+ P107: uses
    P107-->>- P2: return
    P2->>+ P108: uses
    P108-->>- P2: return
    P2->>+ P109: uses
    P109-->>- P2: return
    P2->>+ P110: uses
    P110-->>- P2: return
    P2->>+ P111: uses
    P111-->>- P2: return
    P2->>+ P112: uses
    P112-->>- P2: return
    P2->>+ P113: uses
    P113-->>- P2: return
    P2->>+ P114: uses
    P114-->>- P2: return
    P2->>+ P115: uses
    P115-->>- P2: return
    P2->>+ P116: uses
    P116-->>- P2: return
    P2->>+ P117: uses
    P117-->>- P2: return
    P2->>+ P118: uses
    P118-->>- P2: return
    P2->>+ P119: uses
    P119-->>- P2: return
    P2->>+ P120: uses
    P120-->>- P2: return
    P2->>+ P121: uses
    P121-->>- P2: return
    P2->>+ P122: uses
    P122-->>- P2: return
    P2->>+ P123: uses
    P123-->>- P2: return
    P2->>+ P124: uses
    P124-->>- P2: return
    P2->>+ P125: uses
    P125-->>- P2: return
    P2->>+ P126: uses
    P126-->>- P2: return
    P2->>+ P127: uses
    P127-->>- P2: return
    P2->>+ P128: uses
    P128-->>- P2: return
    P2->>+ P129: uses
    P129-->>- P2: return
    P2->>+ P130: uses
    P130-->>- P2: return
    P2->>+ P131: uses
    P131-->>- P2: return
    P2->>+ P132: uses
    P132-->>- P2: return
    P2->>+ P133: uses
    P133-->>- P2: return
    P2->>+ P134: uses
    P134-->>- P2: return
    P2->>+ P135: uses
    P135-->>- P2: return
    P2->>+ P136: uses
    P136-->>- P2: return
    P2->>+ P137: uses
    P137-->>- P2: return
    P2->>+ P138: uses
    P138-->>- P2: return
    P2->>+ P139: uses
    P139-->>- P2: return
    P2->>+ P140: uses
    P140-->>- P2: return
    P2->>+ P141: uses
    P141-->>- P2: return
    P2->>+ P142: uses
    P142-->>- P2: return
    P1->>+ P143: uses
    P143-->>- P1: return
    P1->>+ P0: uses
    P0-->>- P1: return
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
    P1->>+ P5: uses
    P5-->>- P1: return
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
    P1->>+ P167: uses
    P167-->>- P1: return
    P1->>+ P168: uses
    P168-->>- P1: return
    P1->>+ P169: uses
    P169-->>- P1: return
    P1->>+ P170: uses
    P170-->>- P1: return
    P1->>+ P171: uses
    P171-->>- P1: return
    P1->>+ P172: uses
    P172-->>- P1: return
    P1->>+ P173: uses
    P173-->>- P1: return
    P1->>+ P174: uses
    P174-->>- P1: return
    P1->>+ P175: uses
    P175-->>- P1: return
    P1->>+ P176: uses
    P176-->>- P1: return
    P1->>+ P177: uses
    P177-->>- P1: return
    P1->>+ P178: uses
    P178-->>- P1: return
    P1->>+ P179: uses
    P179-->>- P1: return
    P1->>+ P180: uses
    P180-->>- P1: return
    P1->>+ P181: uses
    P181-->>- P1: return
    P1->>+ P182: uses
    P182-->>- P1: return
    P1->>+ P183: uses
    P183-->>- P1: return
    P1->>+ P184: uses
    P184-->>- P1: return
    P1->>+ P185: uses
    P185-->>- P1: return
    P1->>+ P186: uses
    P186-->>- P1: return
    P1->>+ P187: uses
    P187-->>- P1: return
    P1->>+ P188: uses
    P188-->>- P1: return
    P1->>+ P189: uses
    P189-->>- P1: return
    P1->>+ P190: uses
    P190-->>- P1: return
    P1->>+ P191: uses
    P191-->>- P1: return
    P1->>+ P192: uses
    P192-->>- P1: return
    P1->>+ P193: uses
    P193-->>- P1: return
    P1->>+ P194: uses
    P194-->>- P1: return
    P1->>+ P195: uses
    P195-->>- P1: return
    P1->>+ P196: uses
    P196-->>- P1: return
    P1->>+ P197: uses
    P197-->>- P1: return
    P1->>+ P198: uses
    P198-->>- P1: return
    P1->>+ P199: uses
    P199-->>- P1: return
    P1->>+ P200: uses
    P200-->>- P1: return
    P1->>+ P201: uses
    P201-->>- P1: return
    P1->>+ P202: uses
    P202-->>- P1: return
    P1->>+ P203: uses
    P203-->>- P1: return
    P1->>+ P204: uses
    P204-->>- P1: return
    P0->>+ P3: uses
    P3-->>- P0: return
    P0->>+ P4: uses
    P4-->>- P0: return
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
    P0->>+ P30: uses
    P30-->>- P0: return
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
    P0->>+ P51: uses
    P51-->>- P0: return
    P0->>+ P52: uses
    P52-->>- P0: return
    P0->>+ P53: uses
    P53-->>- P0: return
    P0->>+ P54: uses
    P54-->>- P0: return
    P0->>+ P55: uses
    P55-->>- P0: return
    P0->>+ P59: uses
    P59-->>- P0: return
    P0->>+ P60: uses
    P60-->>- P0: return
    P0->>+ P61: uses
    P61-->>- P0: return
    P0->>+ P62: uses
    P62-->>- P0: return
    P0->>+ P63: uses
    P63-->>- P0: return
    P0->>+ P64: uses
    P64-->>- P0: return
    P0->>+ P65: uses
    P65-->>- P0: return
    P0->>+ P66: uses
    P66-->>- P0: return
    P0->>+ P67: uses
    P67-->>- P0: return
    P0->>+ P205: uses
    P205-->>- P0: return
    P0->>+ P206: uses
    P206-->>- P0: return
    P0->>+ P207: uses
    P207-->>- P0: return
    P0->>+ P208: uses
    P208-->>- P0: return
    P0->>+ P209: uses
    P209-->>- P0: return
    P0->>+ P75: uses
    P75-->>- P0: return
    P0->>+ P210: uses
    P210-->>- P0: return
    P0->>+ P79: uses
    P79-->>- P0: return
    P0->>+ P80: uses
    P80-->>- P0: return
    P0->>+ P81: uses
    P81-->>- P0: return
    P0->>+ P82: uses
    P82-->>- P0: return
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
```

## Connections by Relation

### contains
- [[models.py]] `EXTRACTED`

### inherits
- [[Base]] `EXTRACTED`

### uses
- [[Fixture to override validate_token dependency.     Usage: auth_override(UserCla]] `INFERRED`
- [[Fixture to override validate_token dependency.     Usage: auth_override(UserCla]] `INFERRED`
- [[Mark an order as fulfilled and log tracking information.]] `INFERRED`
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
- [[Return sorted list of N for all Option{N} Name/Value pairs found in headers.]] `INFERRED`

---

*Part of the graphify knowledge wiki. See [[index]] to navigate.*