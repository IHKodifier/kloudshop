* * *

KloudShop Schema Gap Brief — Genre Positioning Additions
--------------------------------------------------------

**Context:** KloudShop's Stage 6 data model has been stress-tested against Shopify's top 10 store genres by live store count. The gaps below are all additive (new columns or feature-gated tables) — none require restructuring existing DDL. Each entry names the affected genres, the missing field(s), proposed defaults, and a one-sentence rationale.

* * *

### GAP-01 — Digital asset delivery on variants

**Affects:** Arts & Entertainment (97k stores), Health (115k stores — PDF guides, certificates) **Missing fields on `variants` table:**

* `digital_asset_url TEXT DEFAULT NULL` — Cloud Storage path of the downloadable file
* `download_limit INTEGER DEFAULT NULL` — NULL means unlimited downloads
* `download_expiry_hours INTEGER DEFAULT NULL` — NULL means no expiry; hours from order confirmation

**Rationale:** The existing `is_digital BOOLEAN` flag correctly excludes digital products from shipping logic, but there is nowhere to attach the actual deliverable file. A merchant selling digital art, music, PDF patterns, or downloadable health plans cannot associate the file with the purchase in the current schema.

* * *

### GAP-02 — Perishable / batch / expiry tracking on variants

**Affects:** Food & Drink (183k stores), Health (115k stores) **Missing fields on `variants` table:**

* `is_perishable BOOLEAN DEFAULT FALSE`
* `best_before_days INTEGER DEFAULT NULL` — shelf life in days from manufacture; NULL if not perishable
* `lot_number TEXT DEFAULT NULL` — populated at goods receipt in `purchase_order_lines`; NULL if not tracked

**Rationale:** Food and supplement merchants need batch-level traceability for recalls and regulatory compliance. Without a lot number and expiry concept on the variant/inventory layer, KloudShop cannot support the most basic food-safety operational workflow. These fields are also required for accurate Google Shopping feed freshness signals for perishable goods.

* * *

### GAP-03 — Regulatory / compliance metadata on products

**Affects:** Health (115k stores), Food & Drink (183k stores), Arts & Entertainment (97k stores — ISBN/barcode), Pets & Animals (63k stores) **Missing field on `products` table:**

* `compliance_metadata JSONB DEFAULT '{}'`

**Suggested standard keys (not enforced — merchant-defined):**
    { "fda_ndc": "...", "ce_declaration": "...", "isbn": "...",
      "ean": "...", "ingredients": "...", "allergens": "...",
      "nutritional_info": "...", "breed_restriction": "..." }

**Rationale:** Compliance identifiers vary radically by category and jurisdiction — fixed columns would either be too sparse or too rigid. JSONB with documented conventional keys gives merchants structured storage without requiring KloudShop to enumerate every possible regulatory field. The `compliance_metadata` object is surfaced in the Google Shopping feed where applicable (GTIN maps from `ean`, nutritional data for food listings).

* * *

### GAP-04 — Age restriction / verification gate on products

**Affects:** Health (supplements, 115k stores), Arts & Entertainment (adult content, 97k stores), Food & Drink (alcohol, 183k stores), Pets (some veterinary products, 63k stores) **Missing fields on `products` table:**

* `minimum_age_years SMALLINT DEFAULT NULL` — NULL means no restriction; 18 or 21 for age-gated products
* `age_verification_required BOOLEAN DEFAULT FALSE`

**Rationale:** Merchants selling age-restricted goods (alcohol, adult content, certain supplements) face legal obligations to gate checkout by buyer age. Without a first-class `minimum_age_years` field, the storefront renderer and checkout flow have no signal to present an age-confirmation step. This is a simple additive column but has legal exposure if omitted.

* * *

### GAP-05 — Prescription / controlled-product flag on products

**Affects:** Health (115k stores), Pets (veterinary products, 63k stores) **Missing fields on `products` table:**

* `requires_prescription BOOLEAN DEFAULT FALSE`
* `prescription_document_required BOOLEAN DEFAULT FALSE` — triggers a file-upload step at checkout if TRUE

**Rationale:** Pharmacies, veterinary supply stores, and medical device merchants must restrict certain products to verified buyers with a valid prescription. Without this flag, KloudShop has no mechanism to gate checkout differently for prescription vs. OTC products, which is a regulatory requirement in all major KloudShop launch markets (US, UK, EU, AU).

* * *

### GAP-06 — Donation / pay-what-you-want pricing model

**Affects:** People & Society (106k stores — non-profits, religious items, community) **Missing fields on `variants` table:**

* `pricing_model VARCHAR(16) DEFAULT 'fixed'` — values: `'fixed'`, `'pwyw'` (pay-what-you-want), `'donation'`
* `pwyw_minimum_price DECIMAL(10,2) DEFAULT NULL` — floor price; NULL means truly any amount
* `pwyw_suggested_price DECIMAL(10,2) DEFAULT NULL` — pre-fills the checkout input; NULL means no suggestion

**Rationale:** Non-profits, charities, and community organisations are the sixth-largest genre on Shopify and routinely need flexible pricing that the standard fixed-price model cannot accommodate. A donation or PWYW flow requires the checkout to render a free-text price input rather than a fixed line item — the storefront renderer needs a `pricing_model` signal on the variant to know which checkout component to render.

* * *

### GAP-07 — Event ticketing schema (feature-gated)

**Affects:** People & Society (106k stores), Arts & Entertainment (97k stores — concerts, exhibitions) **Missing feature-gated tables:**

* `events` — `event_id`, `product_id` FK, `event_name`, `event_date TIMESTAMPTZ`, `venue`, `total_capacity INTEGER`, `tickets_sold INTEGER DEFAULT 0`
* `event_tickets` — `ticket_id`, `order_item_id` FK, `event_id` FK, `seat_reference TEXT DEFAULT NULL`, `attendee_name`, `qr_code_url`, `checked_in BOOLEAN DEFAULT FALSE`, `checked_in_at TIMESTAMPTZ DEFAULT NULL`

**Rationale:** Community organisations and arts venues selling event tickets are a distinct commerce pattern — inventory is time-bound (unsold tickets after the event date have zero value), capacity is a hard ceiling rather than a stock level, and fulfilment produces a QR-code ticket rather than a shipment. These cannot be adequately modelled by repurposing the existing variants/inventory/order_shipments tables without significant workaround friction.

* * *

### GAP-08 — Species / pet-type attribute on variants

**Affects:** Pets & Animals (63k stores) **Missing field on `variants` table:**

* `pet_species TEXT[] DEFAULT '{}'` — e.g. `'{dog, cat}'`, `'{bird}'`, `'{reptile}'`

**Rationale:** Pet product discovery is overwhelmingly filtered by species — a dog harness and a cat harness may share a product template but must be independently discoverable. Storing species as a queryable array on the variant (rather than relying solely on collection membership) enables storefront search and Google Shopping feed category mapping (`pet_type` is a Merchant Center attribute) without requiring merchants to maintain a separate collection per species.

* * *

### GAP-09 — Cross-cutting: two fields missing across four or more genres

**GAP-09a — `compliance_document_url TEXT DEFAULT NULL` on `products`** Applies to Health, Food & Drink, Pets (vet products), Arts (licensing). A Cloud Storage path to an attached regulatory document (safety data sheet, CE declaration, FDA registration letter). NULL when no document is needed.

**GAP-09b — `is_age_gated BOOLEAN DEFAULT FALSE` as a storefront-level display signal (on `brand_profiles`)** Some merchants restrict their entire storefront (adult content sites, alcohol-only retailers) rather than individual products. A storefront-level age gate that fires before any product is shown is a separate concern from per-product `age_verification_required` (GAP-04). `DEFAULT FALSE` — no gate for the vast majority of storefronts.

* * *

### Implementation notes for the planning AI

All gaps above are additive — no existing DDL is modified. GAP-01 through GAP-05 and GAP-08 are columns on existing tables (`products`, `variants`) and belong in artifact `06b`. GAP-06 (`pricing_model` fields) belongs in `06b` on `variants`. GAP-07 (event ticketing) is a new feature-gated table group for artifact `06m`. GAP-09a belongs on `products` in `06b`; GAP-09b belongs on `brand_profiles` in `06g`. All new columns follow the established non-destructive migration policy — nullable or with explicit DEFAULT values so existing rows remain valid without backfill.
