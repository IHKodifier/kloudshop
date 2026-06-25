# Fixture to override validate_token dependency.     Usage: auth_override(UserCla

> God node · 59 connections · [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\tests\conftest.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/tests/conftest.py#L113)

**Community:** [[Content & Features]]

## Call Trace Diagram

```mermaid
sequenceDiagram
    participant P0 as Fixture to override validate_token dependency.     Usage: auth_override(UserCla
    participant P1 as UserClaims
    participant P2 as Mark an order as fulfilled and log tracking information.
    participant P3 as Variant
    participant P4 as Product
    participant P5 as StockLocation
    participant P6 as Inventory
    participant P7 as Order
    participant P8 as ImportJob
    participant P9 as Collection
    participant P10 as CollectionProduct
    participant P11 as RedirectRule
    participant P12 as ProductResponse
    participant P13 as ColorPreset
    participant P14 as VariantCreate
    participant P15 as SkuExistsResponse
    participant P16 as ProductCreate
    participant P17 as ProductUpdate
    participant P18 as CollectionCreate
    participant P19 as CollectionResponse
    participant P20 as CollectionUpdate
    participant P21 as ProductAssignment
    participant P22 as ImportJobResponse
    participant P23 as RedirectRuleResponse
    participant P24 as ColorPresetCreate
    participant P25 as ColorPresetResponse
    participant P26 as SkuExistsRequest
    participant P27 as OrderItem
    participant P28 as OrderEvent
    participant P29 as OrderNote
    participant P30 as PaymentIntentResponse
    participant P31 as OrderResponse
    participant P32 as PaymentIntentRequest
    participant P33 as OrderConfirmRequest
    participant P34 as StockLocationResponse
    participant P35 as StockLocationCreate
    participant P36 as InventoryResponse
    participant P37 as OrderFulfilRequest
    participant P38 as OrderRefundRequest
    participant P39 as ReturnRequest
    participant P40 as StaffSecurityState
    participant P41 as B2B Buyer places an order.     1. Validate Buyer Account     2. Calculate Tota
    participant P42 as Returns the product catalog scoped for the B2B buyer,     including custom pric
    participant P43 as Create a new product with its variants.     Enforces catalog:write permission a
    participant P44 as List products for the authenticated tenant.     Supports pagination and filteri
    participant P45 as Update a product and its variants. If slug changes, create a 301 redirect.
    participant P46 as List 301 redirects for the tenant.
    participant P47 as Simulates sending an email report of variant SKU changes to the merchant.
    participant P48 as Simulates sending an email report of deactivated variants during options collaps
    participant P49 as Process CSV import in background.     Simple AI Mapping: Look for 'title', 'pri
    participant P50 as Start a bulk import job from CSV.
    participant P51 as Create a new color preset for the merchant's tenant.
    participant P52 as List all color presets for the tenant.
    participant P53 as Delete a color preset for the tenant.
    participant P54 as Update an existing color preset for the tenant.
    participant P55 as Dev: print to console + save to scratch/import_reports. Prod: real email.
    participant P56 as Parse CSV or XLSX bytes into a list of row dicts.
    participant P57 as Return sorted list of N for all Option{N} Name/Value pairs found in headers.
    participant P58 as Background task: parse file, upsert products+variants+inventory, update job, sen
    participant P59 as Download a pre-filled CSV template with all supported import column headers.
    participant P60 as Check which SKUs from the provided list already exist in this tenant's catalog.
    participant P61 as Upload a .csv or .xlsx file to bulk-import products and variants.     Returns a
    participant P62 as Returns all import jobs for this tenant, newest first.
    participant P63 as Poll the status of a specific import job.
    participant P64 as # TODO: Implement XML feed regeneration logic
    participant P65 as MockStripe
    participant P66 as Generate Facebook OAuth authorization URL.
    participant P67 as Invite a new staff member.
    participant P68 as List pending invitations for the current tenant.
    participant P69 as Cancel a pending invitation.
    participant P70 as Update a staff member's roles and sync with Firebase claims.
    participant P71 as Revoke a staff member's access to the current tenant.
    participant P72 as Transfer store ownership to another staff member.
    participant P73 as Register a B2B buyer using an invitation token.
    participant P74 as Register a DTC consumer (post-checkout).
    participant P75 as Checks the active cool-off and blocked status of a Gmail account.
    participant P76 as Logs a failed sign-in attempt and initiates a 180s cool-off or block.
    participant P77 as Sends a short-lived (180s TTL) unblock token email to the user (max 3/24h).
    participant P78 as Verifies the unblock token and unlocks the account (does not require login).
    participant P79 as Allows an administrator or store owner to unblock a locked staff account.
    participant P80 as Step 1: Calculate total and create Stripe PaymentIntent.     Public storefront
    participant P81 as Step 2: Verify payment and create order with atomic inventory decrement.     Pu
    participant P82 as Aggregate unique customers from the orders table.     For MVP, we return email,
    participant P83 as Export orders for the tenant as a CSV file.
    participant P84 as Refund an order via Stripe.
    participant P85 as List all orders for the authenticated consumer.
    participant P86 as Get details for a specific order owned by the consumer.
    participant P87 as Request a return for an order. Logs an event for merchant review.
    participant P88 as Performs a 'peace of mind' test by creating and immediately deleting a GCS bucke
    participant P89 as Provisions isolated GCP resources and SQL schema for a new tenant.     This is
    participant P90 as Seeds mock orders and customers for the current tenant.     Enables verificatio
    participant P91 as Check if a tenant ID (slug) is available.
    participant P92 as Fetch tenant identity and configuration for the current merchant.
    participant P93 as Update merchant store details (name, config).
    participant P94 as Verify that accessing B2B endpoints without a token returns 403.
    participant P95 as Verify that an admin can invite a B2B buyer.
    participant P96 as Verify that inviting a duplicate email fails with 409.
    participant P97 as Verify tenant isolation for B2B buyers.
    participant P98 as Verify price list creation.
    participant P99 as Verify that approval workflow can be retrieved and updated (upsert).
    participant P100 as Verify B2B portal order placement and threshold-based approval.
    participant P101 as Verify B2B portal catalog returns custom pricing.
    participant P102 as Verify that an invoice is generated upon B2B order approval.
    participant P103 as Fetch current subscription status for the tenant.
    participant P104 as Initiates a Stripe Checkout Session for tier upgrades.
    participant P105 as Finalizes an upgrade session.      In Stripe mode, this would verify the sessio
    participant P106 as Lists all invoices from Stripe for the current tenant.
    participant P107 as Creates a Stripe Billing Portal session.
    participant P108 as Manually trigger the trial expiration check.
    participant P109 as Handle Instagram OAuth callback.
    participant P110 as List all merchants and their subscription status.
    participant P111 as Get real-time revenue KPIs:     - GMV (Gross Merchandise Value)     - Order Co
    participant P112 as Vertex AI Demand Forecasting Stub.
    participant P113 as Scoped BigQuery/Looker Studio embed token generator.
    participant P114 as Verify that accessing POS endpoints without a token returns 403.
    participant P115 as Verify that an admin can assign a staff member to a location.
    participant P116 as Verify successful POS sale processing.
    participant P117 as Verify that POS sale fails if stock is insufficient.
    participant P118 as Verify that a merchant can fetch their subscription.
    participant P119 as Verify that list_invoices returns empty list if no stripe customer.
    participant P120 as Verify that creating portal session fails without a stripe customer.
    participant P121 as Verify that the trial check task suspends expired tenants.
    participant P122 as Verify that the success URL correctly appends session_id if missing.
    participant P123 as Verify that complete-upgrade correctly identifies and processes a mock session.
    participant P124 as Aggregated metrics for platform administrators.
    participant P125 as Manually approve a merchant (e.g. after manual verification).
    participant P126 as PermissionChecker
    participant P127 as Verify that a failed login starts a cool-off and further logins fail during it.
    participant P128 as Verify that 3 failed login attempts (with cool-off bypassed/cleared) triggers a
    participant P129 as Verify that failures across 3 distinct days blocks the account.
    participant P130 as Verify that unblock email requests are capped at 3 per 24h, and verify works.
    participant P131 as Verify that an expired unblock token fails verification.
    participant P132 as Verify that an administrator cannot unblock a staff user from another tenant.
    participant P133 as validate_token()
    participant P134 as GeminiClient
    participant P135 as Update the list of supported locales for the current tenant.
    participant P136 as GDPR Right-to-Erasure Pipeline.     Anonymizes PII in Orders and B2B Accounts f
    participant P137 as Nightly schema drift detection.     Compares live schema vs SQLAlchemy metadata
    participant P138 as SYS-18 version detection.
    participant P139 as Verify that an owner can transfer ownership to another staff member.
    participant P140 as Verify that a non-owner cannot transfer ownership.
    participant P141 as Verify that a B2B buyer can register with a valid token.
    participant P142 as Verify that a consumer can register.
    participant P143 as Simulates the cloud tasks migration job described in US-049.     In production,
    participant P144 as Get the list of supported locales for the current tenant.
    participant P145 as Verify that calling provision-tenant twice for the same tenant is idempotent.
    participant P146 as Verify that a script failure returns 500.
    participant P147 as Verify that a Tenant record is correctly created in the platform schema.
    participant P148 as Verify that Alembic upgrade is called when not in SQLite.
    participant P149 as List all connected social channels for the tenant.
    participant P150 as Generate TikTok OAuth authorization URL.
    participant P151 as Handle TikTok OAuth callback and exchange code for access token.
    participant P152 as Generate Instagram (Meta) OAuth authorization URL.
    participant P153 as Handle Facebook OAuth callback.
    participant P154 as Trigger a manual catalog sync for a specific channel.
    participant P155 as Disconnect a social channel.
    participant P156 as Verify that accessing /products without a token returns 403.
    participant P157 as Verify that an owner can create a product with variants.
    participant P158 as Verify that a tenant only sees their own products.
    participant P159 as Verify that creating a variant with negative price fails with 400.
    participant P160 as Verify that PWYW variants cannot have a compare_at_price.
    participant P161 as Verify that prescription_document_required requires requires_prescription=True.
    participant P162 as Verify that is_perishable flag is saved correctly on Product.
    participant P163 as Verify that updating a variant SKU with email_sku_report=true triggers change de
    participant P164 as Verify that collapsing variants from options to simple product triggers collapse
    participant P165 as Verify that an owner can create a collection.
    participant P166 as Verify that a tenant only sees their own collections.
    participant P167 as Verify assigning products to a collection.
    participant P168 as Verify removing a product from a collection.
    participant P169 as Verify that a merchant can successfully create a color preset.
    participant P170 as Verify that creating a duplicate color preset name under the same tenant fails.
    participant P171 as Verify that invalid hex code formats fail schema validation.
    participant P172 as Verify that preset listing is isolated per tenant.
    participant P173 as Verify deleting a color preset.
    participant P174 as Verify that deleting a non-existent or other tenant's preset fails with 404.
    participant P175 as Verify that only users with internal:provision can call this.
    participant P176 as Verify that provisioning succeeds with correct permissions and mocked script.
    participant P177 as Test that switching themes carries forward matching content slots.
    participant P178 as StaffRoleAssignment
    participant P179 as Tenant
    participant P180 as StaffUser
    participant P181 as B2BAccount
    participant P182 as B2BInvitation
    participant P183 as Invitation
    participant P184 as Subscription
    participant P185 as BuyerUser
    participant P186 as ConsumerUser
    participant P187 as BrandProfile
    participant P188 as StaffLoginHistory
    participant P189 as ApprovalWorkflow
    participant P190 as PriceList
    participant P191 as PriceListItem
    participant P192 as ApprovalRequest
    participant P193 as B2BInvoice
    participant P194 as ChannelConnection
    participant P195 as ChannelSyncLog
    participant P196 as OnboardingSession
    participant P197 as ImportMapping
    participant P198 as Supplier
    participant P199 as ThemeConfiguration
    participant P200 as BrandVoiceProfile
    participant P201 as PurchaseOrder
    participant P202 as PurchaseOrderLine
    participant P203 as StockTransfer
    participant P204 as StorefrontContent
    participant P205 as StaticPage
    participant P206 as MerchantCarrierConnection
    participant P207 as CarrierCheckoutOption
    participant P208 as Theme
    participant P209 as Feature
    participant P210 as TenantFeatureActivation
    participant P211 as TenantFeatureConfig
    participant P212 as FeatureRequest
    participant P213 as FeatureRequestVote
    participant P214 as AICopywriterLog
    participant P215 as ExportJob
    participant P216 as PricingRule
    participant P217 as SupplierPerformanceEvent
    participant P218 as PackagingPreset
    participant P219 as SupplierScoreWeights
    participant P220 as ShippingSettings
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
    P2->>+ P38: uses
    P38-->>- P2: return
    P2->>+ P39: uses
    P39-->>- P2: return
    P1->>+ P40: uses
    P40-->>- P1: return
    P1->>+ P41: uses
    P41-->>- P1: return
    P1->>+ P42: uses
    P42-->>- P1: return
    P1->>+ P43: uses
    P43-->>- P1: return
    P1->>+ P44: uses
    P44-->>- P1: return
    P1->>+ P45: uses
    P45-->>- P1: return
    P1->>+ P46: uses
    P46-->>- P1: return
    P1->>+ P47: uses
    P47-->>- P1: return
    P1->>+ P48: uses
    P48-->>- P1: return
    P1->>+ P49: uses
    P49-->>- P1: return
    P1->>+ P50: uses
    P50-->>- P1: return
    P1->>+ P51: uses
    P51-->>- P1: return
    P1->>+ P52: uses
    P52-->>- P1: return
    P1->>+ P53: uses
    P53-->>- P1: return
    P1->>+ P54: uses
    P54-->>- P1: return
    P1->>+ P55: uses
    P55-->>- P1: return
    P1->>+ P56: uses
    P56-->>- P1: return
    P1->>+ P57: uses
    P57-->>- P1: return
    P1->>+ P58: uses
    P58-->>- P1: return
    P1->>+ P59: uses
    P59-->>- P1: return
    P1->>+ P60: uses
    P60-->>- P1: return
    P1->>+ P61: uses
    P61-->>- P1: return
    P1->>+ P62: uses
    P62-->>- P1: return
    P1->>+ P63: uses
    P63-->>- P1: return
    P1->>+ P64: uses
    P64-->>- P1: return
    P1->>+ P65: uses
    P65-->>- P1: return
    P1->>+ P66: uses
    P66-->>- P1: return
    P1->>+ P67: uses
    P67-->>- P1: return
    P1->>+ P68: uses
    P68-->>- P1: return
    P1->>+ P69: uses
    P69-->>- P1: return
    P1->>+ P70: uses
    P70-->>- P1: return
    P1->>+ P71: uses
    P71-->>- P1: return
    P1->>+ P72: uses
    P72-->>- P1: return
    P1->>+ P73: uses
    P73-->>- P1: return
    P1->>+ P74: uses
    P74-->>- P1: return
    P1->>+ P75: uses
    P75-->>- P1: return
    P1->>+ P76: uses
    P76-->>- P1: return
    P1->>+ P77: uses
    P77-->>- P1: return
    P1->>+ P78: uses
    P78-->>- P1: return
    P1->>+ P79: uses
    P79-->>- P1: return
    P1->>+ P80: uses
    P80-->>- P1: return
    P1->>+ P81: uses
    P81-->>- P1: return
    P1->>+ P82: uses
    P82-->>- P1: return
    P1->>+ P83: uses
    P83-->>- P1: return
    P1->>+ P84: uses
    P84-->>- P1: return
    P1->>+ P85: uses
    P85-->>- P1: return
    P1->>+ P86: uses
    P86-->>- P1: return
    P1->>+ P87: uses
    P87-->>- P1: return
    P1->>+ P88: uses
    P88-->>- P1: return
    P1->>+ P89: uses
    P89-->>- P1: return
    P1->>+ P90: uses
    P90-->>- P1: return
    P1->>+ P91: uses
    P91-->>- P1: return
    P1->>+ P92: uses
    P92-->>- P1: return
    P1->>+ P93: uses
    P93-->>- P1: return
    P1->>+ P94: uses
    P94-->>- P1: return
    P1->>+ P95: uses
    P95-->>- P1: return
    P1->>+ P96: uses
    P96-->>- P1: return
    P1->>+ P97: uses
    P97-->>- P1: return
    P1->>+ P98: uses
    P98-->>- P1: return
    P1->>+ P99: uses
    P99-->>- P1: return
    P1->>+ P100: uses
    P100-->>- P1: return
    P1->>+ P101: uses
    P101-->>- P1: return
    P1->>+ P102: uses
    P102-->>- P1: return
    P1->>+ P103: uses
    P103-->>- P1: return
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
    P1->>+ P133: calls
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
    P0->>+ P3: uses
    P3-->>- P0: return
    P0->>+ P4: uses
    P4-->>- P0: return
    P0->>+ P5: uses
    P5-->>- P0: return
    P0->>+ P6: uses
    P6-->>- P0: return
    P0->>+ P7: uses
    P7-->>- P0: return
    P0->>+ P178: uses
    P178-->>- P0: return
    P0->>+ P8: uses
    P8-->>- P0: return
    P0->>+ P179: uses
    P179-->>- P0: return
    P0->>+ P40: uses
    P40-->>- P0: return
    P0->>+ P9: uses
    P9-->>- P0: return
    P0->>+ P180: uses
    P180-->>- P0: return
    P0->>+ P10: uses
    P10-->>- P0: return
    P0->>+ P11: uses
    P11-->>- P0: return
    P0->>+ P181: uses
    P181-->>- P0: return
    P0->>+ P13: uses
    P13-->>- P0: return
    P0->>+ P182: uses
    P182-->>- P0: return
    P0->>+ P183: uses
    P183-->>- P0: return
    P0->>+ P184: uses
    P184-->>- P0: return
    P0->>+ P185: uses
    P185-->>- P0: return
    P0->>+ P186: uses
    P186-->>- P0: return
    P0->>+ P27: uses
    P27-->>- P0: return
    P0->>+ P187: uses
    P187-->>- P0: return
    P0->>+ P188: uses
    P188-->>- P0: return
    P0->>+ P28: uses
    P28-->>- P0: return
    P0->>+ P189: uses
    P189-->>- P0: return
    P0->>+ P190: uses
    P190-->>- P0: return
    P0->>+ P191: uses
    P191-->>- P0: return
    P0->>+ P192: uses
    P192-->>- P0: return
    P0->>+ P193: uses
    P193-->>- P0: return
    P0->>+ P29: uses
    P29-->>- P0: return
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
```

## Connections by Relation

### rationale_for
- [[auth_override()]] `EXTRACTED`

### uses
- [[UserClaims]] `INFERRED`
- [[Variant]] `INFERRED`
- [[Product]] `INFERRED`
- [[StockLocation]] `INFERRED`
- [[Inventory]] `INFERRED`
- [[Order]] `INFERRED`
- [[StaffRoleAssignment]] `INFERRED`
- [[ImportJob]] `INFERRED`
- [[Tenant]] `INFERRED`
- [[StaffSecurityState]] `INFERRED`
- [[Collection]] `INFERRED`
- [[StaffUser]] `INFERRED`
- [[CollectionProduct]] `INFERRED`
- [[RedirectRule]] `INFERRED`
- [[B2BAccount]] `INFERRED`
- [[ColorPreset]] `INFERRED`
- [[B2BInvitation]] `INFERRED`
- [[Invitation]] `INFERRED`
- [[Subscription]] `INFERRED`
- [[BuyerUser]] `INFERRED`

---

*Part of the graphify knowledge wiki. See [[index]] to navigate.*