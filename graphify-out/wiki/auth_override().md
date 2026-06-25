# auth_override()

> God node · 44 connections · [E:\Non_Office\Dev_Space\vibe_skool\kloudShop\backend\tests\conftest.py](file:///E:/Non_Office/Dev_Space/vibe_skool/kloudShop/backend/tests/conftest.py#L112)

## Call Trace Diagram

```mermaid
sequenceDiagram
    participant P0 as auth_override()
    participant P1 as test_get_b2b_catalog_overrides()
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
    participant P52 as test_pos_sale_success()
    participant P53 as ChannelAdapter
    participant P54 as TikTokAdapter
    participant P55 as InstagramAdapter
    participant P56 as FacebookAdapter
    participant P57 as test_analytics_needs_attention()
    participant P58 as test_pos_sale_insufficient_stock()
    participant P59 as Handle Instagram OAuth callback.
    participant P60 as ChannelSyncService
    participant P61 as List all merchants and their subscription status.
    participant P62 as update_product()
    participant P63 as test_place_b2b_order_threshold()
    participant P64 as Get real-time revenue KPIs:     - GMV (Gross Merchandise Value)     - Order Co
    participant P65 as Vertex AI Demand Forecasting Stub.
    participant P66 as Scoped BigQuery/Looker Studio embed token generator.
    participant P67 as Test end-to-end checkout: payment-intent -> confirm -> inventory decrement.
    participant P68 as Verify that accessing POS endpoints without a token returns 403.
    participant P69 as Verify that an admin can assign a staff member to a location.
    participant P70 as Verify successful POS sale processing.
    participant P71 as Verify that POS sale fails if stock is insufficient.
    participant P72 as create_product()
    participant P73 as test_order_checkout_flow()
    participant P74 as background_import_task()
    participant P75 as test_tiktok_sync()
    participant P76 as test_instagram_sync()
    participant P77 as test_facebook_sync()
    participant P78 as test_purchase_order_lifecycle()
    participant P79 as test_stock_transfer()
    participant P80 as test_insufficient_stock()
    participant P81 as test_jsonld_structured_data()
    participant P82 as test_sitemap_xml()
    participant P83 as CSV-B-001 & CSV-B-002: Verify template returns valid headers.
    participant P84 as CSV-B-003: Check SKU existence check works.
    participant P85 as CSV-B-004 & CSV-B-010: Successful import of clean CSV.
    participant P86 as CSV-B-005: Upload with conflict_strategy=skip skips duplicate SKUs.
    participant P87 as CSV-B-006: Upload with conflict_strategy=overwrite updates existing variant.
    participant P88 as CSV-B-007: Upload with conflict_strategy=custom_sku renames duplicate SKU.
    participant P89 as CSV-B-008, CSV-B-009, CSV-B-011, CSV-B-013: Verify error reporting and validatio
    participant P90 as CSV-B-012: Rows with no stock are logged to no_stock_log.
    participant P91 as CSV-B-014: Parse arbitrary option columns (e.g. Option7 Name/Value).
    participant P92 as CSV-B-015: History endpoint returns jobs for tenant sorted by date desc.
    participant P93 as CSV-B-016: Parse XLSX file bytes successfully.
    participant P94 as test_sku_exists_endpoint()
    participant P95 as test_import_conflict_skip()
    participant P96 as test_import_conflict_overwrite()
    participant P97 as test_import_conflict_custom_sku()
    participant P98 as Generates a live Google Shopping XML feed for the tenant.
    participant P99 as test_google_shopping_feed()
    participant P100 as UserClaims
    participant P101 as str
    participant P102 as B2BAccount
    participant P103 as Product
    participant P104 as PriceList
    participant P105 as PriceListItem
    participant P106 as test_admin_unblock_staff_tenant_boundary()
    participant P107 as test_b2b_invoice_generation()
    participant P108 as test_create_checkout_session_url_logic()
    participant P109 as test_complete_upgrade_mock_success()
    participant P110 as test_gdpr_erasure()
    participant P111 as test_provision_tenant_record_creation()
    participant P112 as test_analytics_overview()
    participant P113 as test_list_buyers_tenant_isolation()
    participant P114 as test_get_subscription_success()
    participant P115 as test_list_invoices_empty()
    participant P116 as test_create_portal_session_fail_no_customer()
    participant P117 as test_list_products_tenant_isolation()
    participant P118 as test_list_collections_tenant_isolation()
    participant P119 as test_list_color_presets_tenant_isolation()
    participant P120 as test_delete_color_preset_not_found()
    participant P121 as test_consumer_list_orders()
    participant P122 as test_consumer_request_return()
    participant P123 as test_i18n_locales_management()
    participant P124 as test_provision_tenant_success()
    participant P125 as test_provision_tenant_idempotency()
    participant P126 as test_provision_tenant_script_failure()
    participant P127 as test_provision_tenant_migration_call()
    participant P128 as test_analytics_forecasting_looker()
    participant P129 as test_create_blog_post()
    participant P130 as test_connect_channel()
    participant P131 as test_list_channels()
    participant P132 as test_hygiene_health_and_version()
    participant P133 as test_platform_dashboard_access_denied_for_merchant()
    participant P134 as test_platform_dashboard_access_granted_for_admin()
    participant P135 as test_semantic_search_fallback()
    participant P136 as test_product_slug_change_creates_redirect()
    participant P137 as test_redirect_chain_flattening()
    participant P138 as test_ssr_storefront_home()
    participant P139 as test_ssr_product_page()
    P0->>+ P1: calls
    P1-->>- P0: return
    P1->>+ P2: calls
    P2-->>- P1: return
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
    P2->>+ P1: calls
    P1-->>- P2: return
    P2->>+ P52: calls
    P52-->>- P2: return
    P2->>+ P53: uses
    P53-->>- P2: return
    P2->>+ P54: uses
    P54-->>- P2: return
    P2->>+ P55: uses
    P55-->>- P2: return
    P2->>+ P56: uses
    P56-->>- P2: return
    P2->>+ P57: calls
    P57-->>- P2: return
    P2->>+ P58: calls
    P58-->>- P2: return
    P2->>+ P59: uses
    P59-->>- P2: return
    P2->>+ P60: uses
    P60-->>- P2: return
    P2->>+ P61: uses
    P61-->>- P2: return
    P2->>+ P62: calls
    P62-->>- P2: return
    P2->>+ P63: calls
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
    P2->>+ P72: calls
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
    P2->>+ P94: calls
    P94-->>- P2: return
    P2->>+ P95: calls
    P95-->>- P2: return
    P2->>+ P96: calls
    P96-->>- P2: return
    P2->>+ P97: calls
    P97-->>- P2: return
    P2->>+ P98: uses
    P98-->>- P2: return
    P2->>+ P99: calls
    P99-->>- P2: return
    P1->>+ P0: calls
    P0-->>- P1: return
    P1->>+ P100: calls
    P100-->>- P1: return
    P1->>+ P101: calls
    P101-->>- P1: return
    P1->>+ P102: calls
    P102-->>- P1: return
    P1->>+ P103: calls
    P103-->>- P1: return
    P1->>+ P104: calls
    P104-->>- P1: return
    P1->>+ P105: calls
    P105-->>- P1: return
    P0->>+ P52: calls
    P52-->>- P0: return
    P0->>+ P57: calls
    P57-->>- P0: return
    P0->>+ P58: calls
    P58-->>- P0: return
    P0->>+ P63: calls
    P63-->>- P0: return
    P0->>+ P106: calls
    P106-->>- P0: return
    P0->>+ P107: calls
    P107-->>- P0: return
    P0->>+ P108: calls
    P108-->>- P0: return
    P0->>+ P109: calls
    P109-->>- P0: return
    P0->>+ P75: calls
    P75-->>- P0: return
    P0->>+ P76: calls
    P76-->>- P0: return
    P0->>+ P77: calls
    P77-->>- P0: return
    P0->>+ P110: calls
    P110-->>- P0: return
    P0->>+ P111: calls
    P111-->>- P0: return
    P0->>+ P112: calls
    P112-->>- P0: return
    P0->>+ P113: calls
    P113-->>- P0: return
    P0->>+ P114: calls
    P114-->>- P0: return
    P0->>+ P115: calls
    P115-->>- P0: return
    P0->>+ P116: calls
    P116-->>- P0: return
    P0->>+ P117: calls
    P117-->>- P0: return
    P0->>+ P118: calls
    P118-->>- P0: return
    P0->>+ P119: calls
    P119-->>- P0: return
    P0->>+ P120: calls
    P120-->>- P0: return
    P0->>+ P121: calls
    P121-->>- P0: return
    P0->>+ P122: calls
    P122-->>- P0: return
    P0->>+ P123: calls
    P123-->>- P0: return
    P0->>+ P124: calls
    P124-->>- P0: return
    P0->>+ P125: calls
    P125-->>- P0: return
    P0->>+ P126: calls
    P126-->>- P0: return
    P0->>+ P127: calls
    P127-->>- P0: return
    P0->>+ P128: calls
    P128-->>- P0: return
    P0->>+ P129: calls
    P129-->>- P0: return
    P0->>+ P130: calls
    P130-->>- P0: return
    P0->>+ P131: calls
    P131-->>- P0: return
    P0->>+ P132: calls
    P132-->>- P0: return
    P0->>+ P133: calls
    P133-->>- P0: return
    P0->>+ P134: calls
    P134-->>- P0: return
    P0->>+ P135: calls
    P135-->>- P0: return
    P0->>+ P136: calls
    P136-->>- P0: return
    P0->>+ P137: calls
    P137-->>- P0: return
    P0->>+ P138: calls
    P138-->>- P0: return
    P0->>+ P139: calls
    P139-->>- P0: return
```

## Connections by Relation

### calls
- [[test_get_b2b_catalog_overrides()]] `INFERRED`
- [[test_pos_sale_success()]] `INFERRED`
- [[test_analytics_needs_attention()]] `INFERRED`
- [[test_pos_sale_insufficient_stock()]] `INFERRED`
- [[test_place_b2b_order_threshold()]] `INFERRED`
- [[test_admin_unblock_staff_tenant_boundary()]] `INFERRED`
- [[test_b2b_invoice_generation()]] `INFERRED`
- [[test_create_checkout_session_url_logic()]] `INFERRED`
- [[test_complete_upgrade_mock_success()]] `INFERRED`
- [[test_tiktok_sync()]] `INFERRED`
- [[test_instagram_sync()]] `INFERRED`
- [[test_facebook_sync()]] `INFERRED`
- [[test_gdpr_erasure()]] `INFERRED`
- [[test_provision_tenant_record_creation()]] `INFERRED`
- [[test_analytics_overview()]] `INFERRED`
- [[test_list_buyers_tenant_isolation()]] `INFERRED`
- [[test_get_subscription_success()]] `INFERRED`
- [[test_list_invoices_empty()]] `INFERRED`
- [[test_create_portal_session_fail_no_customer()]] `INFERRED`
- [[test_list_products_tenant_isolation()]] `INFERRED`

### contains
- [[conftest.py]] `EXTRACTED`

### rationale_for
- [[Fixture to override validate_token dependency.     Usage: auth_override(UserCla]] `EXTRACTED`

---

*Part of the graphify knowledge wiki. See [[index]] to navigate.*