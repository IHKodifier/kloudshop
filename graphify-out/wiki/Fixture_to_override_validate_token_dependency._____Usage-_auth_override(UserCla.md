# Fixture to override validate_token dependency.     Usage: auth_override(UserCla

> God node · 58 connections · [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\tests\conftest.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/tests/conftest.py#L113)

**Community:** [[App Bootstrap]]

## Call Trace Diagram

```mermaid
sequenceDiagram
    participant P0 as Fixture to override validate_token dependency.     Usage: auth_override(UserCla
    participant P1 as UserClaims
    participant P2 as Fixture to override validate_token dependency.     Usage: auth_override(UserCla
    participant P3 as Variant
    participant P4 as Product
    participant P5 as StockLocation
    participant P6 as Inventory
    participant P7 as Order
    participant P8 as StaffRoleAssignment
    participant P9 as ImportJob
    participant P10 as Tenant
    participant P11 as StaffSecurityState
    participant P12 as Collection
    participant P13 as StaffUser
    participant P14 as CollectionProduct
    participant P15 as RedirectRule
    participant P16 as B2BAccount
    participant P17 as ColorPreset
    participant P18 as B2BInvitation
    participant P19 as Invitation
    participant P20 as Subscription
    participant P21 as BuyerUser
    participant P22 as ConsumerUser
    participant P23 as OrderItem
    participant P24 as StaffLoginHistory
    participant P25 as OrderEvent
    participant P26 as BrandProfile
    participant P27 as ApprovalWorkflow
    participant P28 as PriceList
    participant P29 as PriceListItem
    participant P30 as ApprovalRequest
    participant P31 as B2BInvoice
    participant P32 as OrderNote
    participant P33 as ChannelConnection
    participant P34 as ChannelSyncLog
    participant P35 as OnboardingSession
    participant P36 as ImportMapping
    participant P37 as Supplier
    participant P38 as StaticPage
    participant P39 as ThemeConfiguration
    participant P40 as BrandVoiceProfile
    participant P41 as StorePolicy
    participant P42 as PurchaseOrder
    participant P43 as PurchaseOrderLine
    participant P44 as StockTransfer
    participant P45 as StorefrontContent
    participant P46 as MerchantCarrierConnection
    participant P47 as CarrierCheckoutOption
    participant P48 as Theme
    participant P49 as Feature
    participant P50 as TenantFeatureActivation
    participant P51 as TenantFeatureConfig
    participant P52 as FeatureRequest
    participant P53 as FeatureRequestVote
    participant P54 as AICopywriterLog
    participant P55 as ExportJob
    participant P56 as PricingRule
    participant P57 as StoreShippingProfile
    participant P58 as StoreShippingZone
    participant P59 as StoreShippingRate
    participant P60 as StoreTaxRate
    participant P61 as SupplierPerformanceEvent
    participant P62 as PackagingPreset
    participant P63 as SupplierScoreWeights
    participant P64 as ShippingSettings
    participant P65 as StoreNavigationMenu
    participant P66 as StoreNavigationItem
    participant P67 as Mark an order as fulfilled and log tracking information.
    participant P68 as B2B Buyer places an order.     1. Validate Buyer Account     2. Calculate Tota
    participant P69 as Returns the product catalog scoped for the B2B buyer,     including custom pric
    participant P70 as Create a new product with its variants.     Enforces catalog:write permission a
    participant P71 as List products for the authenticated tenant.     Supports pagination and filteri
    participant P72 as Update a product and its variants. If slug changes, create a 301 redirect.
    participant P73 as List 301 redirects for the tenant.
    participant P74 as Simulates sending an email report of variant SKU changes to the merchant.
    participant P75 as Simulates sending an email report of deactivated variants during options collaps
    participant P76 as Process CSV import in background.     Simple AI Mapping: Look for 'title', 'pri
    participant P77 as Start a bulk import job from CSV.
    participant P78 as Create a new color preset for the merchant's tenant.
    participant P79 as List all color presets for the tenant.
    participant P80 as Delete a color preset for the tenant.
    participant P81 as Update an existing color preset for the tenant.
    participant P82 as Dev: print to console + save to scratch/import_reports. Prod: real email.
    participant P83 as Parse CSV or XLSX bytes into a list of row dicts.
    participant P84 as Return sorted list of N for all Option{N} Name/Value pairs found in headers.
    participant P85 as Background task: parse file, upsert products+variants+inventory, update job, sen
    participant P86 as Download a pre-filled CSV template with all supported import column headers.
    participant P87 as Check which SKUs from the provided list already exist in this tenant's catalog.
    participant P88 as Upload a .csv or .xlsx file to bulk-import products and variants.     Returns a
    participant P89 as Returns all import jobs for this tenant, newest first.
    participant P90 as Poll the status of a specific import job.
    participant P91 as # TODO: Implement XML feed regeneration logic
    participant P92 as MockStripe
    participant P93 as Generate Facebook OAuth authorization URL.
    participant P94 as Invite a new staff member.
    participant P95 as List pending invitations for the current tenant.
    participant P96 as Cancel a pending invitation.
    participant P97 as Update a staff member's roles and sync with Firebase claims.
    participant P98 as Revoke a staff member's access to the current tenant.
    participant P99 as Transfer store ownership to another staff member.
    participant P100 as Register a B2B buyer using an invitation token.
    participant P101 as Register a DTC consumer (post-checkout).
    participant P102 as Checks the active cool-off and blocked status of a Gmail account.
    participant P103 as Logs a failed sign-in attempt and initiates a 180s cool-off or block.
    participant P104 as Sends a short-lived (180s TTL) unblock token email to the user (max 3/24h).
    participant P105 as Verifies the unblock token and unlocks the account (does not require login).
    participant P106 as Allows an administrator or store owner to unblock a locked staff account.
    participant P107 as Step 1: Calculate total and create Stripe PaymentIntent.     Public storefront
    participant P108 as Step 2: Verify payment and create order with atomic inventory decrement.     Pu
    participant P109 as Aggregate unique customers from the orders table.     For MVP, we return email,
    participant P110 as Export orders for the tenant as a CSV file.
    participant P111 as Refund an order via Stripe.
    participant P112 as List all orders for the authenticated consumer.
    participant P113 as Get details for a specific order owned by the consumer.
    participant P114 as Request a return for an order. Logs an event for merchant review.
    participant P115 as Performs a 'peace of mind' test by creating and immediately deleting a GCS bucke
    participant P116 as Provisions isolated GCP resources and SQL schema for a new tenant.     This is
    participant P117 as Seeds mock orders and customers for the current tenant.     Enables verificatio
    participant P118 as Check if a tenant ID (slug) is available.
    participant P119 as Fetch tenant identity and configuration for the current merchant.
    participant P120 as Update merchant store details (name, config).
    participant P121 as Verify that accessing B2B endpoints without a token returns 403.
    participant P122 as Verify that an admin can invite a B2B buyer.
    participant P123 as Verify that inviting a duplicate email fails with 409.
    participant P124 as Verify tenant isolation for B2B buyers.
    participant P125 as Verify price list creation.
    participant P126 as Verify that approval workflow can be retrieved and updated (upsert).
    participant P127 as Verify B2B portal order placement and threshold-based approval.
    participant P128 as Verify B2B portal catalog returns custom pricing.
    participant P129 as Verify that an invoice is generated upon B2B order approval.
    participant P130 as Fetch current subscription status for the tenant.
    participant P131 as Initiates a Stripe Checkout Session for tier upgrades.
    participant P132 as Finalizes an upgrade session.      In Stripe mode, this would verify the sessio
    participant P133 as Lists all invoices from Stripe for the current tenant.
    participant P134 as Creates a Stripe Billing Portal session.
    participant P135 as Manually trigger the trial expiration check.
    participant P136 as Handle Instagram OAuth callback.
    participant P137 as List all merchants and their subscription status.
    participant P138 as Get real-time revenue KPIs:     - GMV (Gross Merchandise Value)     - Order Co
    participant P139 as Vertex AI Demand Forecasting Stub.
    participant P140 as Scoped BigQuery/Looker Studio embed token generator.
    participant P141 as Verify that accessing POS endpoints without a token returns 403.
    participant P142 as Verify that an admin can assign a staff member to a location.
    participant P143 as Verify successful POS sale processing.
    participant P144 as Verify that POS sale fails if stock is insufficient.
    participant P145 as Verify that a merchant can fetch their subscription.
    participant P146 as Verify that list_invoices returns empty list if no stripe customer.
    participant P147 as Verify that creating portal session fails without a stripe customer.
    participant P148 as Verify that the trial check task suspends expired tenants.
    participant P149 as Verify that the success URL correctly appends session_id if missing.
    participant P150 as Verify that complete-upgrade correctly identifies and processes a mock session.
    participant P151 as Aggregated metrics for platform administrators.
    participant P152 as Manually approve a merchant (e.g. after manual verification).
    participant P153 as PermissionChecker
    participant P154 as Verify that a failed login starts a cool-off and further logins fail during it.
    participant P155 as Verify that 3 failed login attempts (with cool-off bypassed/cleared) triggers a
    participant P156 as Verify that failures across 3 distinct days blocks the account.
    participant P157 as Verify that unblock email requests are capped at 3 per 24h, and verify works.
    participant P158 as Verify that an expired unblock token fails verification.
    participant P159 as Verify that an administrator cannot unblock a staff user from another tenant.
    participant P160 as validate_token()
    participant P161 as GeminiClient
    participant P162 as Update the list of supported locales for the current tenant.
    participant P163 as GDPR Right-to-Erasure Pipeline.     Anonymizes PII in Orders and B2B Accounts f
    participant P164 as Nightly schema drift detection.     Compares live schema vs SQLAlchemy metadata
    participant P165 as SYS-18 version detection.
    participant P166 as Verify that an owner can transfer ownership to another staff member.
    participant P167 as Verify that a non-owner cannot transfer ownership.
    participant P168 as Verify that a B2B buyer can register with a valid token.
    participant P169 as Verify that a consumer can register.
    participant P170 as Simulates the cloud tasks migration job described in US-049.     In production,
    participant P171 as Get the list of supported locales for the current tenant.
    participant P172 as Verify that calling provision-tenant twice for the same tenant is idempotent.
    participant P173 as Verify that a script failure returns 500.
    participant P174 as Verify that a Tenant record is correctly created in the platform schema.
    participant P175 as Verify that Alembic upgrade is called when not in SQLite.
    participant P176 as List all connected social channels for the tenant.
    participant P177 as Generate TikTok OAuth authorization URL.
    participant P178 as Handle TikTok OAuth callback and exchange code for access token.
    participant P179 as Generate Instagram (Meta) OAuth authorization URL.
    participant P180 as Handle Facebook OAuth callback.
    participant P181 as Trigger a manual catalog sync for a specific channel.
    participant P182 as Disconnect a social channel.
    participant P183 as Verify that accessing /products without a token returns 403.
    participant P184 as Verify that an owner can create a product with variants.
    participant P185 as Verify that a tenant only sees their own products.
    participant P186 as Verify that creating a variant with negative price fails with 400.
    participant P187 as Verify that PWYW variants cannot have a compare_at_price.
    participant P188 as Verify that prescription_document_required requires requires_prescription=True.
    participant P189 as Verify that is_perishable flag is saved correctly on Product.
    participant P190 as Verify that updating a variant SKU with email_sku_report=true triggers change de
    participant P191 as Verify that collapsing variants from options to simple product triggers collapse
    participant P192 as Verify that an owner can create a collection.
    participant P193 as Verify that a tenant only sees their own collections.
    participant P194 as Verify assigning products to a collection.
    participant P195 as Verify removing a product from a collection.
    participant P196 as Verify that a merchant can successfully create a color preset.
    participant P197 as Verify that creating a duplicate color preset name under the same tenant fails.
    participant P198 as Verify that invalid hex code formats fail schema validation.
    participant P199 as Verify that preset listing is isolated per tenant.
    participant P200 as Verify deleting a color preset.
    participant P201 as Verify that deleting a non-existent or other tenant's preset fails with 404.
    participant P202 as Verify that only users with internal:provision can call this.
    participant P203 as Verify that provisioning succeeds with correct permissions and mocked script.
    participant P204 as Test that switching themes carries forward matching content slots.
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
    P1->>+ P0: uses
    P0-->>- P1: return
    P1->>+ P67: uses
    P67-->>- P1: return
    P1->>+ P11: uses
    P11-->>- P1: return
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
    P1->>+ P160: calls
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
    P0->>+ P16: uses
    P16-->>- P0: return
    P0->>+ P14: uses
    P14-->>- P0: return
    P0->>+ P15: uses
    P15-->>- P0: return
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
    P0->>+ P40: uses
    P40-->>- P0: return
    P0->>+ P37: uses
    P37-->>- P0: return
    P0->>+ P38: uses
    P38-->>- P0: return
    P0->>+ P39: uses
    P39-->>- P0: return
    P0->>+ P54: uses
    P54-->>- P0: return
    P0->>+ P55: uses
    P55-->>- P0: return
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
    P0->>+ P42: uses
    P42-->>- P0: return
    P0->>+ P43: uses
    P43-->>- P0: return
    P0->>+ P44: uses
    P44-->>- P0: return
    P0->>+ P56: uses
    P56-->>- P0: return
    P0->>+ P45: uses
    P45-->>- P0: return
    P0->>+ P46: uses
    P46-->>- P0: return
    P0->>+ P47: uses
    P47-->>- P0: return
    P0->>+ P48: uses
    P48-->>- P0: return
    P0->>+ P61: uses
    P61-->>- P0: return
    P0->>+ P62: uses
    P62-->>- P0: return
    P0->>+ P63: uses
    P63-->>- P0: return
    P0->>+ P64: uses
    P64-->>- P0: return
```

## Connections by Relation

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
- [[B2BAccount]] `INFERRED`
- [[CollectionProduct]] `INFERRED`
- [[RedirectRule]] `INFERRED`
- [[ColorPreset]] `INFERRED`
- [[B2BInvitation]] `INFERRED`
- [[Invitation]] `INFERRED`
- [[Subscription]] `INFERRED`
- [[BuyerUser]] `INFERRED`

---

*Part of the graphify knowledge wiki. See [[index]] to navigate.*