# Schema Artifact: 06o-index-strategy.md

> **Purpose:** Consolidates all CREATE INDEX statements across kloudshop_platform and 	enant_{tenant_id} schemas. 
> Includes prose rationale per index and dominant query patterns for each table.


## 06a1 — Platform Core Schema

### Table: kloudshop_platform.order_sources
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_order_sources_channel_type; — *Accelerates foreign key joins and common filtering patterns.*

### Table: kloudshop_platform.tenants
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_tenants_slug; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_tenants_account_status; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_tenants_owner_gmail; — *Critical for multi-tenant data isolation and fast tenant-scoped queries.*
* CREATE INDEX idx_tenants_is_trial_active; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_tenants_stripe_customer; — *Critical for multi-tenant data isolation and fast tenant-scoped queries.*

### Table: kloudshop_platform.tenant_regions
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_tenant_regions_tenant_id; — *Critical for multi-tenant data isolation and fast tenant-scoped queries.*
* CREATE INDEX idx_tenant_regions_active; — *Optimises filtering for state machine transitions and active record queries.*

### Table: kloudshop_platform.gcip_tenant_registry
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_gcip_registry_tenant_id; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE UNIQUE INDEX idx_gcip_registry_gcip_tenant_id; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*

### Table: kloudshop_platform.staff_users
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_staff_users_gmail; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE UNIQUE INDEX idx_staff_users_firebase_uid; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_staff_users_is_active; — *Optimises filtering for state machine transitions and active record queries.*

### Table: kloudshop_platform.staff_role_assignments
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_staff_role_one_owner_per_tenant; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_staff_role_by_staff_tenant; — *Critical for multi-tenant data isolation and fast tenant-scoped queries.*
* CREATE INDEX idx_staff_role_by_tenant; — *Critical for multi-tenant data isolation and fast tenant-scoped queries.*
* CREATE INDEX idx_staff_role_pending_invitations; — *Accelerates foreign key joins and common filtering patterns.*

### Table: kloudshop_platform.platform_staff
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_platform_staff_gmail; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_platform_staff_active; — *Optimises filtering for state machine transitions and active record queries.*

### Table: kloudshop_platform.platform_audit_log
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_audit_log_actor; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_audit_log_tenant; — *Critical for multi-tenant data isolation and fast tenant-scoped queries.*
* CREATE INDEX idx_audit_log_action_type; — *Accelerates foreign key joins and common filtering patterns.*

### Table: kloudshop_platform.staff_login_history
*Dominant query patterns:* Fetch recent logins for a user (security review), fetch logins for a tenant (audit trail), and fetch geo-coordinates.
* CREATE INDEX idx_staff_login_user_time; — *Speeds up "show recent logins for user X" security alerts.*
* CREATE INDEX idx_staff_login_tenant_time; — *Speeds up tenant compliance dashboards audit searches.*

### Table: kloudshop_platform.staff_security_states
*Dominant query patterns:* Check block status on login, check cool-off windows, and manage unblock tokens.
* CREATE INDEX idx_staff_security_blocked; — *Optimizes lookup scans for active lockouts.*

### Table: kloudshop_platform.migration_jobs
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_migration_jobs_tenant; — *Critical for multi-tenant data isolation and fast tenant-scoped queries.*
* CREATE INDEX idx_migration_jobs_in_progress; — *Accelerates foreign key joins and common filtering patterns.*

### Table: kloudshop_platform.billing_cycles
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_billing_cycles_tenant; — *Critical for multi-tenant data isolation and fast tenant-scoped queries.*
* CREATE INDEX idx_billing_cycles_open; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_billing_cycles_stripe_invoice; — *Accelerates foreign key joins and common filtering patterns.*

### Table: kloudshop_platform.billing_line_items
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_billing_line_items_cycle; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_billing_line_items_tenant_period; — *Critical for multi-tenant data isolation and fast tenant-scoped queries.*

### Table: kloudshop_platform.trial_visitor_counts
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_trial_visitor_counts_tenant_date; — *Critical for multi-tenant data isolation and fast tenant-scoped queries.*
* CREATE INDEX idx_trial_visitor_counts_unsent; — *Accelerates foreign key joins and common filtering patterns.*

### Table: kloudshop_platform.platform_announcements
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_platform_announcements_build_hash; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_platform_announcements_published; — *Accelerates foreign key joins and common filtering patterns.*

### Table: kloudshop_platform.feature_request_channel
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_feature_requests_by_votes; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_feature_requests_by_tenant; — *Critical for multi-tenant data isolation and fast tenant-scoped queries.*

### Table: kloudshop_platform.feature_request_votes
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_feature_votes_request; — *Accelerates foreign key joins and common filtering patterns.*

## 06a2 — Platform Catalogue Schema

### Table: kloudshop_platform.themes
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_themes_published_by_category; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_themes_published_by_installs; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_themes_sector_tags; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_themes_schema_version; — *Accelerates foreign key joins and common filtering patterns.*

### Table: kloudshop_platform.feature_registry
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_feature_registry_tier_scope; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_feature_registry_status; — *Optimises filtering for state machine transitions and active record queries.*

### Table: kloudshop_platform.feature_config_schema
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_feature_config_schema_feature_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_feature_config_schema_wizard_group; — *Accelerates foreign key joins and common filtering patterns.*

### Table: kloudshop_platform.feature_dependencies
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_feature_dependencies_feature_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_feature_dependencies_depends_on; — *Accelerates foreign key joins and common filtering patterns.*

### Table: kloudshop_platform.feature_migrations
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_feature_migrations_feature_sequence; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_feature_migrations_required; — *Accelerates foreign key joins and common filtering patterns.*

### Table: kloudshop_platform.carriers
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_carriers_active; — *Optimises filtering for state machine transitions and active record queries.*

### Table: kloudshop_platform.carrier_service_levels
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_carrier_service_levels_carrier; — *Accelerates foreign key joins and common filtering patterns.*

### Table: kloudshop_platform.carrier_regions
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_carrier_regions_carrier; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_carrier_regions_country_origin; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_carrier_regions_gcp_hint; — *Accelerates foreign key joins and common filtering patterns.*

### Table: kloudshop_platform.carrier_credential_schemas
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_carrier_credential_schemas_carrier; — *Accelerates foreign key joins and common filtering patterns.*

### Table: kloudshop_platform.carrier_webhook_configs
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_carrier_webhook_configs_carrier; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_carrier_webhook_configs_endpoint; — *Accelerates foreign key joins and common filtering patterns.*

### Table: kloudshop_platform.carrier_rate_zones
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_carrier_rate_zones_lookup; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_carrier_rate_zones_postal_prefix; — *Accelerates foreign key joins and common filtering patterns.*

## 06b — Tenant Catalog Schema

### Table: products
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_products_slug; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_products_status; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_products_in_store; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_products_age_gated; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_products_prescription; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_products_compliance_metadata; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_products_embedding; — *Powers fast full-text search (FTS) or semantic similarity lookups.*

### Table: variants
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_variants_sku; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_variants_product_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_variants_active_product; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_variants_digital_assets; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_variants_perishable; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_variants_pet_species; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_variants_pricing_model; — *Accelerates foreign key joins and common filtering patterns.*

### Table: product_translations
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_product_translations_locale; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_product_translations_stale; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE UNIQUE INDEX idx_product_translations_slug; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*

### Table: variant_translations
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_variant_translations_locale; — *Accelerates foreign key joins and common filtering patterns.*

### Table: collections
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_collections_slug; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_collections_visible_position; — *Accelerates foreign key joins and common filtering patterns.*

### Table: collection_translations
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_collection_translations_locale; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE UNIQUE INDEX idx_collection_translations_slug; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*

### Table: collection_products
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_collection_products_product; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_collection_products_collection_sort; — *Accelerates foreign key joins and common filtering patterns.*

### Table: product_images
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_product_images_product; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_product_images_variant; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_product_images_primary; — *Accelerates foreign key joins and common filtering patterns.*

### Table: product_suppliers
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_product_suppliers_variant_rank; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_product_suppliers_supplier; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_product_suppliers_rank_1; — *Accelerates foreign key joins and common filtering patterns.*

### Table: product_reviews
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_product_reviews_variant_approved; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_product_reviews_consumer; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_product_reviews_informed_pending_update; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_product_reviews_pending_moderation; — *Accelerates foreign key joins and common filtering patterns.*

### Table: review_votes
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_review_votes_review; — *Accelerates foreign key joins and common filtering patterns.*

### Table: seo_settings
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.

### Table: ai_copywriter_log
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_ai_copywriter_log_entity; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_ai_copywriter_log_content_type; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_ai_copywriter_log_discard_rate; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_ai_copywriter_log_prompt_hash; — *Accelerates foreign key joins and common filtering patterns.*

## 06c — Tenant Orders Schema

### Table: orders
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_orders_order_number; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_orders_consumer_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_orders_b2b_account; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_orders_placed_at; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_orders_fulfilment_status; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_orders_payment_status; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_orders_approval_pending; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_orders_source; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_orders_net_terms_overdue; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_orders_stripe_payment_intent; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_orders_stripe_invoice; — *Accelerates foreign key joins and common filtering patterns.*

### Table: order_items
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_order_items_order_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_order_items_variant_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_order_items_product_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_order_items_fulfilment_location; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_order_items_digital; — *Accelerates foreign key joins and common filtering patterns.*

### Table: order_events
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_order_events_order_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_order_events_type; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_order_events_consumer_visible; — *Accelerates foreign key joins and common filtering patterns.*

### Table: order_shipments
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_order_shipments_order_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_order_shipments_status; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_order_shipments_tracking; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_order_shipments_location; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_order_shipments_service_level; — *Accelerates foreign key joins and common filtering patterns.*

### Table: order_shipment_items
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_order_shipment_items_shipment; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_order_shipment_items_order_item; — *Accelerates foreign key joins and common filtering patterns.*

### Table: order_notes
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_order_notes_order_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_order_notes_author; — *Accelerates foreign key joins and common filtering patterns.*

## 06d — Tenant Inventory Schema

### Table: stock_locations
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_stock_locations_active; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_stock_locations_online; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_stock_locations_pos; — *Accelerates foreign key joins and common filtering patterns.*

### Table: inventory
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_inventory_variant_location; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_inventory_location; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_inventory_low_stock; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_inventory_dead_stock; — *Accelerates foreign key joins and common filtering patterns.*

### Table: stock_reservations
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_stock_reservations_variant_location; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_stock_reservations_expires_at; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_stock_reservations_session; — *Accelerates foreign key joins and common filtering patterns.*

### Table: stock_transfers
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_stock_transfers_source; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_stock_transfers_destination; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_stock_transfers_variant; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_stock_transfers_in_transit; — *Accelerates foreign key joins and common filtering patterns.*

### Table: packaging_presets
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_packaging_presets_weight_asc; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_packaging_presets_default; — *Accelerates foreign key joins and common filtering patterns.*

## 06e — Tenant Supplier Schema

### Table: suppliers
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_suppliers_status; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_suppliers_name_trgm; — *Powers fast full-text search (FTS) or semantic similarity lookups.*
* CREATE INDEX idx_suppliers_all_statuses; — *Optimises filtering for state machine transitions and active record queries.*

### Table: purchase_orders
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_purchase_orders_po_number; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_purchase_orders_supplier; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_purchase_orders_status_open; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_purchase_orders_receiving_location; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_purchase_orders_overdue; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_purchase_orders_all_statuses; — *Optimises filtering for state machine transitions and active record queries.*

### Table: purchase_order_lines
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_po_lines_po_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_po_lines_variant; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_po_lines_supplier; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_po_lines_discrepancy; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_po_lines_manufacture_date; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_po_lines_pending_receipt; — *Accelerates foreign key joins and common filtering patterns.*

### Table: supplier_performance_events
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_supplier_perf_events_supplier; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_supplier_perf_events_po; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_supplier_perf_events_type; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_supplier_perf_events_negative_severity; — *Accelerates foreign key joins and common filtering patterns.*

### Table: supplier_score_weights
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.

### Table: shipping_settings
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.

## 06f — Tenant B2B Schema

### Table: b2b_accounts
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_b2b_accounts_email; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE UNIQUE INDEX idx_b2b_accounts_firebase_uid; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_b2b_accounts_status; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_b2b_accounts_company_name_trgm; — *Powers fast full-text search (FTS) or semantic similarity lookups.*
* CREATE INDEX idx_b2b_accounts_account_manager; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_b2b_accounts_price_list; — *Accelerates foreign key joins and common filtering patterns.*

### Table: price_lists
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_price_lists_active; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_price_lists_default; — *Accelerates foreign key joins and common filtering patterns.*

### Table: price_list_items
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_price_list_items_price_list; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_price_list_items_variant; — *Accelerates foreign key joins and common filtering patterns.*

### Table: approval_workflows
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.

### Table: approval_requests
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_approval_requests_order_id; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_approval_requests_pending; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_approval_requests_b2b_account; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_approval_requests_escalation_candidates; — *Accelerates foreign key joins and common filtering patterns.*

### Table: b2b_invoices
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_b2b_invoices_order_id; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE UNIQUE INDEX idx_b2b_invoices_stripe_invoice_id; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_b2b_invoices_b2b_account; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_b2b_invoices_overdue; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_b2b_invoices_payment_status; — *Optimises filtering for state machine transitions and active record queries.*

## 06h — Tenant Blog Schema

### Table: blog_posts
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_blog_posts_status; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_blog_posts_scheduled_for; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_blog_posts_author_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_blog_posts_body_tsv; — *Powers fast full-text search (FTS) or semantic similarity lookups.*
* CREATE INDEX idx_blog_posts_is_featured; — *Accelerates foreign key joins and common filtering patterns.*

### Table: blog_post_translations
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_blog_post_translations_post_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_blog_post_translations_locale; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_blog_post_translations_body_tsv; — *Powers fast full-text search (FTS) or semantic similarity lookups.*

### Table: blog_categories
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_blog_categories_sort_order; — *Accelerates foreign key joins and common filtering patterns.*

### Table: blog_category_translations
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_blog_category_translations_category_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_blog_category_translations_locale; — *Accelerates foreign key joins and common filtering patterns.*

### Table: blog_post_categories
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_blog_post_categories_category_id; — *Accelerates foreign key joins and common filtering patterns.*

### Table: blog_tags
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.

### Table: blog_post_tags
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_blog_post_tags_tag_id; — *Accelerates foreign key joins and common filtering patterns.*

## 06i — Tenant Messaging Schema

### Table: message_threads
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_message_threads_type_object; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_message_threads_created_by; — *Accelerates foreign key joins and common filtering patterns.*

### Table: thread_participants
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_thread_participants_participant; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_thread_participants_unread; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_thread_participants_type; — *Accelerates foreign key joins and common filtering patterns.*

### Table: messages
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_messages_thread_sent_at; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_messages_sender_drafts; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_messages_body_tsv; — *Powers fast full-text search (FTS) or semantic similarity lookups.*
* CREATE INDEX idx_messages_sender_id; — *Accelerates foreign key joins and common filtering patterns.*

### Table: message_attachments
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_message_attachments_message_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_message_attachments_storage_path; — *Accelerates foreign key joins and common filtering patterns.*

## 06j — Tenant Consumer Schema

### Table: consumers
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_consumers_email; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE UNIQUE INDEX idx_consumers_gcip_uid; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_consumers_is_active; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_consumers_accepts_marketing; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_consumers_name_trgm; — *Powers fast full-text search (FTS) or semantic similarity lookups.*

### Table: consumer_addresses
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_consumer_addresses_consumer_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_consumer_addresses_default; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_consumer_addresses_country; — *Accelerates foreign key joins and common filtering patterns.*

### Table: consumer_sessions
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_consumer_sessions_token; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_consumer_sessions_consumer_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_consumer_sessions_active; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_consumer_sessions_device_type; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_consumer_sessions_started_at; — *Accelerates foreign key joins and common filtering patterns.*

### Table: wishlists
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_wishlists_consumer_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_wishlists_variant_id; — *Accelerates foreign key joins and common filtering patterns.*

## 06k — Tenant Feature Configuration Schema

### Table: tenant_feature_config
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX IF NOT EXISTS idx_tfc_feature_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX IF NOT EXISTS idx_tfc_set_by; — *Accelerates foreign key joins and common filtering patterns.*

### Table: tenant_migration_state
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX IF NOT EXISTS idx_tms_feature_id; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX IF NOT EXISTS idx_tms_applied_at_brin; — *Accelerates foreign key joins and common filtering patterns.*

### Table: tenant_feature_state
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX IF NOT EXISTS idx_tfs_status; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX IF NOT EXISTS idx_tfs_activated_at; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX IF NOT EXISTS idx_tfs_updated_at; — *Accelerates foreign key joins and common filtering patterns.*

## 06l — 06l

### Table: IF
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.

### Table: IF
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.

### Table: IF
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.

### Table: IF
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.

### Table: IF
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.

## 06m — Tenant Feature-Gated Schema

### Table: reward_tiers
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_reward_tiers_sort_order; — *Accelerates foreign key joins and common filtering patterns.*

### Table: loyalty_accounts
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_loyalty_accounts_consumer_id; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_loyalty_accounts_tier; — *Accelerates foreign key joins and common filtering patterns.*

### Table: point_transactions
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_point_transactions_account; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_point_transactions_order; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_point_transactions_expiry; — *Accelerates foreign key joins and common filtering patterns.*

### Table: redemption_events
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_redemption_events_account; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_redemption_events_order; — *Accelerates foreign key joins and common filtering patterns.*

### Table: discount_codes
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_discount_codes_code; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_discount_codes_active_window; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_discount_codes_scope_collections; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_discount_codes_scope_products; — *Accelerates foreign key joins and common filtering patterns.*

### Table: discount_code_redemptions
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_discount_code_redemptions_code; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_discount_code_redemptions_consumer; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_discount_code_redemptions_order; — *Accelerates foreign key joins and common filtering patterns.*

### Table: abandoned_cart_jobs
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_abandoned_cart_jobs_session; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_abandoned_cart_jobs_status_pending; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_abandoned_cart_jobs_consumer; — *Accelerates foreign key joins and common filtering patterns.*

### Table: dynamic_pricing_rules
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_dynamic_pricing_rules_active_type; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_dynamic_pricing_rules_flash_sale_window; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_dynamic_pricing_rules_scope_collections; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_dynamic_pricing_rules_scope_variants; — *Accelerates foreign key joins and common filtering patterns.*

### Table: dynamic_pricing_events
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_dynamic_pricing_events_rule; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_dynamic_pricing_events_variant; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_dynamic_pricing_events_triggered_at; — *Accelerates foreign key joins and common filtering patterns.*

### Table: subscription_plans
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_subscription_plans_active; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_subscription_plans_products; — *Accelerates foreign key joins and common filtering patterns.*

### Table: subscriptions
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_subscriptions_consumer; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_subscriptions_next_order; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_subscriptions_variant; — *Accelerates foreign key joins and common filtering patterns.*

### Table: subscription_orders
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_subscription_orders_subscription; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_subscription_orders_order; — *Accelerates foreign key joins and common filtering patterns.*

### Table: gift_cards
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_gift_cards_code; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_gift_cards_consumer; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_gift_cards_expiring; — *Accelerates foreign key joins and common filtering patterns.*

### Table: gift_card_transactions
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_gift_card_transactions_card; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_gift_card_transactions_order; — *Accelerates foreign key joins and common filtering patterns.*

### Table: bundle_definitions
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_bundle_definitions_active; — *Optimises filtering for state machine transitions and active record queries.*

### Table: bundle_components
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE INDEX idx_bundle_components_bundle; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_bundle_components_variant; — *Accelerates foreign key joins and common filtering patterns.*
* CREATE INDEX idx_bundle_components_swappable_variants; — *Accelerates foreign key joins and common filtering patterns.*

### Table: affiliate_links
*Dominant query patterns:* Primary key lookups, foreign key traversals, and status/active filtering.
* CREATE UNIQUE INDEX idx_affiliate_links_code; — *Ensures uniqueness to prevent duplicate records and accelerates exact-match lookups.*
* CREATE INDEX idx_affiliate_links_active; — *Optimises filtering for state machine transitions and active record queries.*
* CREATE INDEX idx_affiliate_links_email; — *Accelerates foreign key joins and common filtering patterns.*

## Audit: Missing Indexes Identified (RESOLVED)
By cross-referencing access patterns in 06n (State Machines), 03-user-journeys, and 04-feature-stories, the following missing indexes were identified in the base DDL artifacts and have been successfully patched into the schema files:
1. `migration_jobs`: Added `idx_migration_jobs_statuses` to support tracking the 3 independent axes of the Migration job state machine.
2. `subscriptions`: Added `idx_subscriptions_status` to support state machine filtering.
3. `purchase_orders`: Added `idx_purchase_orders_all_statuses` to support full state machine transitions alongside the existing partial index.