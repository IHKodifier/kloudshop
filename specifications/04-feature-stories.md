# Feature Stories: KloudShop

> **Stage:** 4 — Feature Stories
> **Persona:** SaaS Founder × Product Designer
> **Reads from:** `01-product-brief.md`, `01b-tech-stack.md`, `02-architecture.md`, `03-user-journeys.md`
> **Approved:** [ ] pending

---

## Epic Overview

| # | Epic | Business Goal | Journeys | Priority |
|---|------|--------------|----------|---------|
| E01 | Authentication & Access Control | Secure multi-tenant identity foundation | M-89–M-96, B-00c, C-17–C-19 | P0 |
| E02 | Merchant Onboarding & Migration Engine | 2-minute win — competitor to KloudShop | M-01–M-19 | P0 |
| E03 | Storefront & Theme System | Merchant brand delivery engine | M-44–M-53, M-45b–M-45j, M-52b–M-52e | P0 |
| E04 | Product Catalog Management | Inventory foundation — products, variants, collections | M-35–M-44 | P0 |
| E05 | Order Management | Revenue processing — place, fulfil, refund | M-20–M-28c, C-09–C-16 | P0 |
| E06 | Inventory & Supplier Management | Stock truth + procurement engine | M-29–M-34, SUP-01–SUP-33 | P0 |
| E07 | B2B Operations | Wholesale engine — pricing, approvals, buyers | M-60–M-70, B-00a–B-21 | P0 |
| E08 | Feature Catalogue & Configuration | Anti-app-store architecture | M-54–M-59f | P0 |
| E09 | Analytics & Reporting | Data intelligence layer | M-71–M-81 | P1 |
| E10 | Billing & Subscription | Pass-through revenue engine | M-82–M-88, SYS-09–SYS-12b | P0 |
| E11 | POS & Omnichannel | Physical store unification | O-00a–O-07 | P1 |
| E12 | Social Commerce & Channels | Viral commerce capture | SC-01–SC-09 | P1 |
| E13 | Tax Compliance | Automated cross-jurisdiction tax | T-01–T-04 | P1 |
| E14 | Dynamic Pricing Engine | Rule-based intelligent repricing | P-01–P-05 | P1 |
| E15 | Data Portability | Full data ownership guarantee | D-01–D-04 | P1 |
| E16 | Internal Messaging | Native contextual communication | MSG-01–MSG-28 | P1 |
| E17 | Consumer DTC Storefront | End-buyer experience | C-01–C-33 | P0 |
| E18 | Platform Administration | KloudShop control plane | ADM-01–ADM-30 | P0 |
| E19 | System & Background Processes | Automated platform operations | SYS-01–SYS-17 | P0 |
| E20 | Shipping & Courier Integration | Native carrier rates, labels, consolidation | SH-01–SH-12 | P0 |
| E21 | Multilingual Storefront & Admin (LTR) | AI-translated storefronts in 10 languages | M-53b–M-53n | P0 |
| E22 | Native Blog | SEO content engine — merchant blog with AI translation | M-53g–M-53n, C-32–C-33 | P0 |
| E23 | AI Copywriter | Brand-voice-grounded copy generation for products and blog | M-45p–M-45r, M-53o–M-53p | P1 |

---

## E01 — Authentication & Access Control

**Goal:** Establish secure, role-scoped identity for all user populations across every KloudShop tenancy.
**Traces to:** Multi-tenant isolation, RBAC, Gmail-only staff auth, Firebase App Check, control plane architecture.

### US-001 — Merchant Staff Login (Google OAuth)
*As a merchant staff member, I want to log in with my Gmail account so that I can access the KloudShop admin dashboard scoped to my assigned roles.*

```gherkin
Given a staff member has been invited to a KloudShop tenancy
  And they have accepted the invitation via the emailed link
When they navigate to the KloudShop admin URL
  And they click "Sign in with Google"
  And they complete Google OAuth with their invited Gmail address
Then they are authenticated via Firebase Auth
  And their JWT custom claims contain tenant_id, account_type: staff, roles[], is_owner
  And they land on the merchant admin dashboard scoped to their role permissions
  And features and navigation items outside their role are hidden — not just disabled

Given a staff member attempts to log in with a Gmail address not invited to any tenancy
When they complete Google OAuth
Then they see an error: "This Google account has not been invited to any KloudShop store"
  And they are offered a link to create a new merchant account

Given a staff member's access has been revoked by the Owner
When they attempt to log in
Then Firebase Auth rejects their JWT
  And they see: "Your access to this store has been removed. Contact the store owner."
```

### US-002 — Firebase App Check Enforcement
*As KloudShop, I want every API request to be verified as originating from a legitimate app instance so that bots and reverse-engineered clients cannot call our endpoints.*

```gherkin
Given a request arrives at any FastAPI endpoint
When the request does not carry a valid Firebase App Check token
Then the request is rejected with HTTP 403
  And the rejection happens before JWT validation, before routing, before any business logic
  And no error detail is returned to the caller

Given a request arrives from a legitimate KloudShop Flutter app (Android/iOS/Web)
When the App Check token is valid and not expired
Then the request proceeds to JWT validation normally
  And App Check tokens are automatically refreshed by the Firebase SDK
```

### US-003 — Staff User Invitation & Role Assignment
*As a merchant Owner, I want to invite a Gmail account to my store with specific roles so that my team can access only the parts of the admin they need.*

```gherkin
Given an Owner is on the Team & Permissions settings page
When they enter a valid Gmail address
  And select one or more roles from the RBAC role picker
  And click "Send invitation"
Then a Resend email is sent to the Gmail address with an invitation link
  And the staff_role_assignments record is created with status: "pending"
  And the invited user does not have admin access until they accept

Given an invitee clicks the invitation link in their email
When they complete Google OAuth with the invited Gmail address
Then their Firebase custom claims are updated with tenant_id, roles[], is_owner: false
  And they land on the merchant admin dashboard scoped to their assigned roles
  And the staff_role_assignments record status updates to "accepted"

Given an Owner attempts to invite a Gmail address already in the tenancy
When they submit the invitation
Then the system shows: "This user already has access to your store. Edit their roles instead."
```

### US-004 — Role Editing & Access Revocation
*As a merchant Owner, I want to edit a staff member's roles or revoke their access so that permissions stay accurate as my team changes.*

```gherkin
Given an Owner is viewing a staff member's role panel
When they add or remove roles and save
Then the staff member's Firebase custom claims are updated immediately
  And on their next API request their new role permissions apply
  And no re-login is required for the change to take effect

Given an Owner clicks "Revoke access" for a staff member
When they confirm the action
Then the staff member's Firebase Auth custom claims are cleared for this tenancy
  And any active JWT sessions for that user are invalidated within 60 seconds
  And the staff_role_assignments record is marked revoked_at

Given an Owner attempts to revoke access from themselves
Then the system prevents the action
  And shows: "You cannot revoke your own Owner access. Transfer ownership first."
```

### US-005 — Owner Account Transfer
*As a merchant Owner, I want to transfer store ownership to another Gmail account so that leadership transitions are possible.*

```gherkin
Given an Owner navigates to Team & Permissions
When they select "Transfer ownership" and enter the target Gmail address
  And the target Gmail address is an existing staff member of this tenancy
  And they confirm with their Google account re-authentication
Then the target user's claims are updated to is_owner: true
  And the previous Owner's claims are updated to is_owner: false, roles: ["admin"]
  And both users receive a Resend confirmation email

Given the target Gmail is not already a staff member of the tenancy
Then the transfer is blocked with: "The new owner must first be an invited staff member of this store."
```

### US-006 — Multi-Role Simultaneous Assignment
*As a merchant Owner, I want a staff member to hold multiple roles simultaneously so that team members with cross-functional responsibilities have appropriate access.*

```gherkin
Given an Owner assigns roles ["store_manager", "inventory_manager"] to a staff member
When the staff member logs in
Then their JWT contains roles: ["store_manager", "inventory_manager"]
  And they can access all routes permitted by either role
  And the most permissive applicable rule applies when roles overlap

Given a staff member holds ["b2b_account_manager", "customer_support"] roles
When they access the B2B buyer management panel
Then they can approve orders and set credit limits (b2b_account_manager permission)
  And they can view orders and issue refunds (customer_support permission)
  And they cannot access billing or store settings (neither role permits this)
```

### US-007 — B2B Buyer Registration & Authentication
*As a B2B buyer, I want to register via an invitation link and authenticate with Gmail or email/password so that I can access my company's negotiated catalog and pricing.*

```gherkin
Given a merchant has created a B2B buyer account and the invitation email has been sent
When the buyer clicks the invitation link
  And completes registration
Then Firebase Auth presents two options:
  | "Continue with Google" — for buyers whose corporate email is Google-hosted |
  | "Set a password" — for buyers with non-Google corporate domains (e.g. john@acmecorp.com) |
  And both paths create a Firebase Auth account with account_type: buyer, buyer_account_id
  And this dual-path is intentional: B2B buyers are external corporate employees
    who cannot be required to have Gmail accounts — unlike merchant staff
    who are strictly Gmail-only for internal security reasons
  And the buyer is redirected to their company's B2B portal
  And they immediately see their company name, credit limit, and account manager contact

Given a buyer attempts to access the B2B portal without a valid session
When they navigate to wholesale.storename.kloudshop.biz
Then they are redirected to the B2B portal login page
  And consumer storefront content is not visible

Given a merchant has set manual approval required for new buyers
When a buyer completes registration
Then their account status is "pending approval"
  And the merchant receives an FCM push and email notification
  And the buyer sees: "Your account is pending approval. You'll be notified when access is granted."
```

### US-008 — Consumer Account (DTC)
*As a DTC consumer, I want to optionally create an account after purchase so that I can track orders and repeat-buy easily, without being forced to register before checkout.*

```gherkin
Given a consumer has completed guest checkout successfully
When the order confirmation page is shown
Then a soft account creation prompt appears: "Save your details for faster checkout next time"
  And the prompt is dismissable with a single tap
  And dismissing it does not affect the order or confirmation flow

Given a consumer clicks "Create account" on the order confirmation page
When they set a password (or connect Google)
Then their guest session is upgraded to a full consumer account
  And their completed order is linked to the new account
  And they receive a Resend welcome email
```

---

## E02 — Merchant Onboarding & Migration Engine

**Goal:** Get any merchant from competitor platform to fully operational KloudShop store in under 2 minutes, with a personalised migration runbook.
**Traces to:** "Competitor Migration Engine (2-minute onboarding)" differentiator, M-01–M-19.

### US-009 — Merchant Signup & Tier Selection
*As a prospective merchant, I want to create a KloudShop account and select my subscription tier so that I can start my 1-month free trial.*

```gherkin
Given a visitor arrives at the KloudShop landing page
When they click "Start free trial"
  And they click "Continue with Google" and complete Google OAuth with their Gmail account
  And they select one of DTC ($24.99/mo), B2B ($39.99/mo), or Hybrid ($49.99/mo)
Then a Firebase Auth account is created using their Gmail identity
  And the account enters a lightweight validation queue (anti-spam check)
  And they proceed to GCP region selection

Given a signup Gmail is flagged by the anti-spam validation
Then a Platform Admin is notified for manual review via the ADM-03 flow
  And GCP resource provisioning is held until the account is approved
  And the merchant sees: "Your account is being verified. You'll receive an email within a few minutes."

Given a visitor attempts to sign up with a Gmail account already registered as a merchant
When they complete Google OAuth
Then Firebase Auth detects the existing account
  And they are automatically signed into their existing account
  And directed to their merchant dashboard — no duplicate account is created

Given a visitor attempts to sign up using a non-Gmail Google Workspace account
When they complete Google OAuth
Then the account is created normally — Google Workspace Gmail accounts are valid
  And only non-Google email/password auth is unsupported for merchant accounts
```

### US-010 — GCP Region Selection
*As a new merchant, I want to choose the GCP region closest to my customers and optionally add a secondary failover region so that my storefront loads fast and I understand the cost implications.*

```gherkin
Given a merchant has completed signup
When they reach the region selection screen
Then KloudShop detects the merchant's approximate location from their IP address
  And region options are sorted with the closest region listed first
  And each option is labelled by geographic description first, GCP code second:
  | "United States (Iowa)" — us-central1 |
  | "United Kingdom (London)" — europe-west2 |
  | "Australia (Sydney)" — australia-southeast1 |
  | "Southeast Asia (Singapore)" — asia-southeast1 |
  And each option shows a recommended use case and GDPR note where applicable
  And a proxy advisory is shown below the selector:
    "⚠ If you are currently using a VPN or proxy, your detected location may not
     reflect your actual location. Choose the region closest to where you and your
     customers are physically located — not where your VPN exit node is."

When a merchant selects a primary region
Then the secondary region panel is shown collapsed by default
  And the secondary region panel shows the recommended pairing with ★
  And the cost impact banner shows: "+40–60% on your monthly GCP infrastructure bill"
  And a specific cost example is shown based on a typical merchant's usage

When a merchant clicks "Add secondary region"
Then the on-demand activation information panel expands showing:
  | 48-hour lead time requirement |
  | GCP provisioning timeline (15–60 mins replica + 1–4 hrs data sync) |
  | Seasonal use case recommendations (BFCM, Boxing Day) |
  | Honest caveat: secondary region does NOT protect against unexpected primary outages |

When a merchant clicks "Remind me before BFCM / peak season"
Then a seasonal activation reminder is scheduled
  And the merchant proceeds without secondary region

Given a merchant selects the same region for primary and secondary
Then the system prevents the selection and shows: "Primary and secondary regions must be different."
```

### US-011 — Competitor Store Migration (Scrape + Import)
*As a new merchant, I want to provide my competitor store URL so that KloudShop automatically imports my product catalog and SEO metadata in under 2 minutes.*

```gherkin
Given a merchant has completed signup and region selection
When they enter their competitor store URL (Shopify, WooCommerce, Adobe Commerce, Wix, or Squarespace)
Then the platform auto-detects the source platform and displays the platform logo as confirmation
  And for Wix/Squarespace an advisory is shown: "We'll import everything we can find. Some metadata may need a quick review before you go live."

When the merchant clicks "Start Migration"
Then two parallel tracks begin simultaneously:
  | Track A: Scrapy+Playwright scraping job is enqueued via Cloud Tasks |
  | Track B: GCP tenant provisioning begins (Cloud SQL schema, Cloud Storage bucket, Cloud Run warmup) |
  And the merchant sees a unified narrative progress screen — never two separate tracks

As Track A progresses, the progress narrative updates in real time via Firebase Realtime DB:
  | "Detecting your store platform..." (instant) |
  | "Reading your product catalogue..." (0–15s) |
  | "Importing {N} products + variants..." (15–45s) |
  | "Preserving your SEO metadata..." (45–75s) |
  | "Building your KloudShop store..." (75–105s) |
  | "Generating your migration runbook..." (105–120s) |

Given Track A completes before Track B
When GCP provisioning is still in progress
Then the progress bar holds on "Building your KloudShop store..." with copy: "Almost ready — finishing your infrastructure..."
  And no error state is shown
  And the "Your store is ready" message is withheld until Cloud Run readiness probe returns healthy

Given Track B fails (GCP provisioning error)
Then Sentry receives an alert immediately
  And Cloud Tasks retries with exponential backoff
  And the merchant sees: "We hit a snag setting up your infrastructure. We've been notified and are fixing it now. Your scraped data is safe."
  And FCM push + Resend email are sent when the issue resolves

Given both tracks complete successfully
Then the store reveal dashboard is shown only after Cloud Run readiness probe confirms all resources healthy
  And the hero banner shows: "{N} products imported. Your store is live at storename.kloudshop.biz"
  And a live storefront preview thumbnail renders (never a broken iframe)
  And three action cards are shown: [View your store] [Download migration runbook] [Upload customer + order CSV]

Given the scraped data is from Wix or Squarespace
Then imported records are flagged for mandatory AI mapping preview before bulk insert
  And the merchant is shown the AI mapping review step before products go live

Given the competitor platform has bot-protection or scraping restrictions in place
When the scraper is blocked (returns 403, CAPTCHA wall, or empty product data)
Then the scraping job is marked as "blocked" — not "failed"
  And the merchant is notified:
    "We couldn't automatically import your products — your current platform
     has restricted automated imports. You can still get started quickly by
     uploading your product catalog as a CSV file."
  And a direct CTA to the product CSV upload screen (US-092) is shown
  And GCP provisioning (Track B) is unaffected — the store is still created

Given a merchant has already completed a successful scrape import
  And then also uploads a product CSV via US-092
When the CSV import runs
Then the system detects existing products by SKU/title match
  And duplicate products are NOT created
  And the merchant is shown a summary:
    "X products matched your existing catalog (skipped). Y new products imported."
  And the merchant can review and override any skip decision before committing
```

### US-012 — Scraped Data Compliance Rules
*As KloudShop, I want to ensure the migration scraper never collects customer PII or order history so that we remain compliant with competitor platform terms of service.*

```gherkin
Given the scraper is processing a competitor store URL
Then it collects ONLY: product titles, descriptions, prices, variants, images, collections, meta titles, meta descriptions, URL slugs, structured data markup
  And it NEVER attempts to access: customer names, emails, addresses, order history, payment data
  And if any URL pattern suggests customer data (e.g. /admin/customers, /account/orders) it is explicitly skipped
  And the scrape job log records every URL visited for audit purposes
```

### US-013 — Product Catalog CSV Upload (Scraping Fallback)
*As a new merchant whose competitor platform blocked automated import, I want to upload my product catalog as a CSV so that I can still get my store populated quickly without scraping.*

```gherkin
Given a merchant has been directed to product CSV upload (either via scraping-blocked notification or manual choice)
When they upload a CSV or Excel file containing product data
Then the AI parser analyses the file structure and presents a column mapping preview:
  | Column found | Maps to KloudShop field | Confidence |
  And the merchant can correct any "Review" mappings before confirming

When the merchant confirms the import
Then products, variants, images (via URL references), collections, and SEO metadata are imported
  And each imported product is assigned a KloudShop URL slug (SEO-preserving)
  And the import is processed asynchronously via Cloud Tasks for large catalogs
  And the merchant is notified via FCM push when the import completes

Given the merchant already has products in their catalog (e.g. scraping partially succeeded)
When the CSV import runs
Then the system checks for duplicates by matching SKU code or product title
  And exact matches are flagged as "already exists — skip"
  And the merchant is shown a pre-import summary: "X products will be added, Y already exist and will be skipped"
  And the merchant can override any skip decision before committing the import

Given the CSV contains products with missing required fields (title or price)
Then those rows appear in a "failed" list with the specific missing field noted
  And all other rows are imported successfully — partial success is always valid
  And the merchant can correct and re-upload only the failed rows
```

### US-014 — CSV Customer & Order History Import
*As a migrating merchant, I want to upload my customer and order history CSV/Excel files so that my historical data is imported without requiring clean or correctly formatted data.*

```gherkin
Given a merchant uploads one or more CSV/Excel files via drag-and-drop
When the AI parser analyses the file structure
Then a preview table is shown with:
  | Column found in file | Maps to KloudShop field | Confidence level (High / Review) |
  And columns with confidence "Review" are highlighted for merchant correction

When a merchant corrects a "Review" mapping inline
Then the preview table updates immediately to reflect the correction

When the merchant confirms the import
Then all imported orders are stored with order_source: "imported"
  And imported orders are excluded from financial reporting, billing reconciliation, and Stripe processing
  And only orders with order_source: "kloudshop" are treated as live financial transactions
  And the import handles: inconsistent column naming, missing fields, mixed date formats, malformed rows — without error

Given a file contains no recognisable mapping for a required field
Then the merchant is asked to manually assign the column
  And they can choose "Skip this column" for optional fields
```

### US-015 — Migration Runbook Generation
*As a migrating merchant, I want a personalised step-by-step migration runbook so that I can complete DNS cutover, redirect mapping, and go-live without needing a developer.*

```gherkin
Given a migration has completed successfully
When the merchant views the runbook
Then it contains steps personalised to their source platform and domain:
  | Step 1: DNS records pre-filled with their specific KloudShop values |
  | Step 2: 301 redirect map auto-generated from old URLs to new KloudShop URLs |
  | Step 3: SEO verification checklist |
  | Step 4: Payment gateway reconnection guide |
  | Step 5: Staff account setup guide |
  | Step 6: Go-live checklist |
  And the merchant's store name, domain, and source platform appear throughout — no generic copy

When the merchant clicks "Download as PDF"
Then a PDF is generated and downloaded
  And the PDF contains all runbook steps with pre-filled values

When the merchant clicks "Email to my team"
Then the runbook is sent via Resend to the merchant's registered email
```

### US-016 — Brand Identity Setup
*As a merchant, I want to configure my store's brand identity — name, logo, colours, and favicon — so that my storefront reflects my brand, not a KloudShop template.*

```gherkin
Given a merchant reaches the brand setup wizard (post-migration or fresh start)
When they enter a store name
Then the store name is validated as unique within KloudShop
  And the store name is saved to brand_profiles.brand_name — independent of their Gmail address or KloudShop login

When they arrive at the logo upload step
Then upload guidance is shown before the upload zone:
  | Recommended format: PNG or SVG (transparent background) |
  | Minimum size: 400 × 400px |
  | Recommended aspect ratio: square (1:1) or horizontal (3:1 max) |
  | Maximum file size: 5MB |
  | Avoid: JPEG (no transparency support), very wide banners |

When they upload a logo via drag-and-drop or file picker
Then the logo is validated against the format and size requirements
  And if validation fails, a specific error is shown: "Your file is X — we recommend PNG or SVG with transparent background"
  And on success the logo is auto-cropped to required sizes (header, favicon, thumbnail)
  And uploaded to Cloud Storage in the tenant bucket
  And the preview renders with the merchant's actual logo — not a placeholder

When they choose brand colours via colour picker or hex input
Then a small colour preview rectangle renders immediately next to each colour input
  And the rectangle shows the selected colour so the merchant can verify before committing
  And the design token color_tokens.primary and color_tokens.accent update in the full live preview
  And changes are visible immediately without saving

Given a merchant enters an invalid hex value (e.g. "#GGHHII")
Then the input border turns red
  And an inline error shows: "Enter a valid hex colour (e.g. #E94560)"
  And the preview rectangle reverts to the last valid colour

Given a merchant is on the Hybrid tier
Then the brand setup wizard runs twice — once for the DTC brand, once for the B2B brand
  And both brand names, logos, and colour palettes are independently configurable
  And neither brand name needs to match the other or the account owner's identity
```

### US-017 — Tier Upgrade Consent Flow
*As a merchant, I want to be explicitly prompted and informed before any tier upgrade so that I am never surprised by a billing change.*

```gherkin
Given a DTC merchant attempts to create their first wholesale price list
When the system detects this trigger condition
Then the store creation action is paused
  And an upgrade prompt is shown with: new tier name, monthly price difference, next billing date impact
  And no billing change occurs until the merchant explicitly confirms

When the merchant clicks "Upgrade to Hybrid ($49.99/mo)" and confirms
Then the subscription is upgraded via Stripe Billing
  And the B2B features become available immediately
  And a confirmation email is sent via Resend

When the merchant clicks "Not now" or dismisses the prompt
Then they remain on the DTC tier
  And the wholesale price list creation action is cancelled with explanation
  And the upgrade prompt can be accessed again from Billing settings

Given a B2B merchant attempts to publish a consumer-facing public storefront
When the system detects this trigger condition
Then the publish action is paused
  And the same explicit upgrade prompt flow applies for B2B → Hybrid
```

### US-018 — Secondary GCP Region On-Demand Activation
*As a merchant, I want to activate a secondary GCP region on demand — particularly before high-traffic periods — so that I have failover capacity when I expect peak load.*

```gherkin
Given a merchant navigates to Settings → Infrastructure
When they click "Add secondary region"
Then they see the secondary region selector with recommended pairings
  And the cost impact banner shows "+40–60% on monthly GCP infrastructure bill" with a specific dollar example
  And the on-demand lead time warning is shown: "Allow at least 48 hours before your expected traffic spike"
  And the honest caveat is shown: "A secondary region cannot protect against unexpected primary region outages"

When the merchant confirms the secondary region
Then GCP provisioning begins: Cloud SQL read replica + Cloud Run + Memorystore in the secondary region
  And the merchant is shown a provisioning progress indicator
  And FCM push + email notify when the secondary region is ready (typically 1–4 hours)

Given a merchant activates a secondary region within 48 hours of BFCM
Then the system shows a warning: "This is less than the recommended 48-hour lead time. Provisioning may not complete before your expected traffic spike."

When a merchant deactivates their secondary region
Then GCP resources in the secondary region are torn down
  And billing for the secondary region ceases from the next billing cycle
```

---

## E03 — Storefront & Theme System

**Goal:** Give merchants a zero-code, brand-accurate storefront powered by a data-driven theme engine with live WYSIWYG editing.
**Traces to:** Free theme library, one-click switching, WYSIWYG editor, content/theme separation.

### US-019 — Theme Library Browsing & Selection
*As a merchant, I want to browse themes filtered by sector and apply one in a single click so that my storefront looks professionally designed without hiring a developer.*

```gherkin
Given a merchant opens the Theme Library
When they browse without applying any filter
Then all published themes are shown in a grid with preview thumbnails rendered with sample data
  And each theme card shows:
    | display_name and sector_category badge |
    | preview screenshot |
    | ♥ likes counter (total merchant likes across the platform) |
    | install count (number of merchants currently using this theme) |
    | "♥ Save to favourites" button — saves without applying |

When they filter by sector_category (e.g. "Apparel")
Then only themes with that sector_category are shown
  And the filter persists until changed

When they hover a theme card
Then a larger live preview renders using their actual imported products, logo, and brand colours
  And not a generic demo with placeholder content

When they click "♥ Save to favourites" on a theme
Then the theme is added to this merchant's favourites list
  And it is retrievable from a "My Favourites" filter tab in the Theme Library
  And the theme is NOT applied to any storefront — saving to favourites is purely organisational

When they click "Apply theme"
Then the theme.json is fetched from Cloud Storage and cached in Redis for this tenant
  And the storefront renders with the new theme on the next page load
  And existing storefront_content values carry forward to matching content slots automatically
  And new content slots introduced by the new theme are flagged empty in the WYSIWYG
  And the merchant is shown: "Your new theme has {N} new content slots to fill. Everything else carried forward."
  And zero downtime occurs — the switch is atomic
```

### US-020 — Theme Favourites Management
*As a merchant, I want to manage a personal collection of saved themes so that I can quickly retrieve, compare, and apply themes I have shortlisted without searching the full library.*

```gherkin
Given a merchant has saved one or more themes to favourites
When they open the Theme Library
Then a "My Favourites" tab is shown alongside the main library grid
  And clicking it shows only their saved themes
  And each favourited theme card shows the same information as the main library:
    | Preview thumbnail | display_name | sector_category | likes | install count |
  And an additional "♥ Saved" indicator confirms it is in their favourites

When a merchant clicks "Remove from favourites" on a saved theme
Then the theme is removed from their favourites list immediately
  And it remains available in the main theme library — not deleted
  And no confirmation dialog is required (easily reversible)

Given a merchant has no saved favourites
When they open the "My Favourites" tab
Then they see an empty state: "No saved themes yet. Browse the library and ♥ save themes you like."
  And a CTA links directly back to the main library grid

Given a KloudShop Platform Admin deprecates a theme that a merchant has favourited
When the merchant opens their favourites
Then the deprecated theme is shown with a "No longer available" badge
  And it cannot be applied to a storefront
  And the merchant is prompted to remove it from their favourites
  And a suggestion to browse similar themes by sector_category is shown

When a merchant clicks "Apply" directly from their favourites list
Then the same Apply flow from US-092 runs — including the Hybrid storefront choice
  And applying from favourites is functionally identical to applying from the main library
  And the theme remains in favourites after applying — applying does not remove it

Given a merchant wants to compare two favourited themes side by side
When they select two themes in their favourites and click "Compare"
Then both theme previews render simultaneously in a split-view panel
  And the merchant can toggle between their actual imported products and sample data
  And clicking "Apply" on either side runs the standard Apply flow
```

### US-021 — WYSIWYG Theme Editor — Component Stack
*As a merchant, I want to drag, reorder, add, and remove component instances in a visual editor so that I can customise my storefront layout without editing JSON.*

```gherkin
Given a merchant opens the WYSIWYG theme editor
When the editor loads
Then three panels are shown: Component Stack (left), Live Preview (centre), Config Panel (right)
  And scaffold components (app_bar, nav_bar, footer) are shown distinctly — not draggable
  And body components are shown as draggable items with drag handles

When a merchant drags a component instance to a new position
Then the component_order array updates in memory
  And the live preview re-renders within 300ms showing the new order
  And no save is triggered — changes are in-memory until the merchant clicks Save

When a merchant clicks "+ Add component"
Then a component picker modal opens showing all available body component types
  And each type shows a thumbnail of a rendered example — not an abstract icon
  And component types are labelled with human names ("Product Grid", not "product_grid")

When a merchant selects a component type from the picker
Then a new instance is added with a unique auto-generated ID and default config
  And it appears at the bottom of the component stack
  And the config panel opens automatically for the new instance

When a merchant clicks "×" to remove a component instance
Then a confirmation dialog shows: "Remove {instance label}?"
  And on confirmation the instance is removed from component_order and component_config in memory
  And the live preview re-renders immediately

Given a merchant performs any action in the WYSIWYG editor (reorder, add, remove, config change)
When they click the "↩ Undo" button (or press Ctrl+Z / Cmd+Z)
Then the last action is reversed
  And the live preview re-renders to reflect the undone state
  And undo history is maintained for the current editing session (minimum 20 steps)
  And undo history is cleared when the merchant saves or discards

Given a merchant clicks "↩ Undo" when there are no actions to undo
Then the undo button is visually disabled (greyed out)
  And no error is shown
```

### US-022 — WYSIWYG Theme Editor — Config Panel
*As a merchant, I want to configure each component's visual parameters and content through a structured right panel so that I can customise appearance without seeing JSON.*

```gherkin
Given a merchant clicks a body component in the left stack
When the right panel opens
Then it shows two tabs: [Config] and [Content]

When the merchant is on the Config tab
Then they see the component's visual/structural parameters as Flutter form widgets:
  | Collection selector (dropdown) for strip/grid components |
  | Number inputs with min/max for column counts, heights |
  | Colour pickers for card border, hover colours |
  | Dropdowns for animation enter/exit/hover types |
  | Number inputs for animation durations and scale factors |
  And every change immediately updates the live preview

When the merchant is on the Content tab
Then they see content slots for this component instance:
  | short_text slots → single-line text input with char limit counter |
  | long_text slots → multi-line textarea with char limit counter |
  | image_url slots → image upload widget with Cloud Storage picker |
  | link_url slots → URL input with validation |
  | collection_ref slots → collection selector dropdown |
  And empty slots show placeholder text prompting content entry
  And existing content from storefront_content table is pre-filled

Given a merchant clicks the scaffold app_bar in the component stack
When the config panel opens
Then it shows app_bar scaffold configuration:
  | Logo position (Left / Centre) |
  | Show search bar toggle |
  | Show cart icon toggle |
  | Show account icon toggle |
  | Announcement text input and background colour |
  | App bar background colour picker |
  | Sticky (fixed on scroll) toggle |

Given a merchant clicks the scaffold nav_bar in the component stack
When the config panel opens
Then it shows nav_bar configuration:
  | Layout (Horizontal / Hamburger for mobile) |
  | Show category links toggle |
  | Custom links manager (add/edit/remove/reorder links with label + URL) |
  | Nav bar background colour |
  | Link text colour |
  | Hover colour |
  | Mega-menu toggle per nav item (reveals hover-linked component selector) |

Given a merchant clicks the scaffold footer in the component stack
When the config panel opens
Then it shows footer configuration:
  | Link groups manager (add/edit/remove groups, each with heading + links) |
  | Show newsletter signup toggle |
  | Show social icons toggle (with per-platform URL inputs: Instagram, TikTok, Facebook, X, LinkedIn, YouTube, Pinterest) |
  | Footer background colour |
  | Footer text colour |
  | Legal links (Privacy Policy, Terms of Service, Cookie Policy — URL inputs) |
```

### US-023 — WYSIWYG Theme Editor — Save, Apply & Discard
*As a merchant, I want saving my theme edits and applying them to my storefront to be two separate explicit actions so that I can work on a theme over multiple sessions before making it live.*

```gherkin
Given a merchant has made changes in the WYSIWYG editor
When they click "Save draft"
Then the in-memory theme state is serialised to theme.json
  And uploaded to the tenant's draft Cloud Storage path:
    gs://kloudshop-{tenant_id}/themes/draft/{brand_profile_id}/theme.json
  And the storefront continues rendering the previously active theme — completely unaffected
  And the Redis active theme cache is NOT invalidated
  And a success toast confirms: "Draft saved. Your storefront is unchanged."
  And the merchant can close the editor and resume editing the draft in a future session

When a merchant reopens the WYSIWYG editor after saving a draft
Then the editor loads from the draft_theme_config_url — not the active theme
  And the merchant continues where they left off

When a merchant clicks "Apply theme to storefront"
Then a confirmation dialog asks which storefront to apply to:
  | DTC tier: single confirmation — "Apply to your storefront?" |
  | B2B tier: single confirmation — "Apply to your B2B buyer portal?" |
  | Hybrid tier: choice shown — "Apply to DTC storefront" / "Apply to B2B portal" / "Apply to both" |
Then the draft is copied to the active Cloud Storage path:
  gs://kloudshop-{tenant_id}/themes/active/{brand_profile_id}/theme.json
  And the Redis active theme cache is invalidated for the selected storefront(s)
  And the storefront reflects the new theme on the next page request (≤1 hour cache refresh)
  And the draft is cleared
  And a success toast confirms: "Theme applied to your [DTC / B2B / both] storefront(s)."

Given a Hybrid merchant applies a draft theme to DTC only
Then the B2B portal continues rendering its own active theme unchanged
  And the two storefronts are independently themed at all times

When a merchant clicks "Discard draft"
  And they confirm the dialog
Then all unsaved draft changes are deleted from the draft Cloud Storage path
  And the editor reloads from the current active theme
  And the live preview re-renders with the active state
  And the storefront is completely unaffected

When a merchant clicks "Reset to base theme"
  And they confirm the dialog (which warns this cannot be undone)
Then all tenant customisations are cleared from both draft and active paths
  And theme.json reverts to the unmodified original from the global theme catalogue
  And storefront_content values are preserved — content is never deleted on theme reset
  And the global theme catalogue entry is never modified — tenant isolation is absolute

Given a merchant attempts to navigate away from the WYSIWYG editor with an unsaved draft
Then a browser confirmation dialog warns: "You have unsaved draft changes. Leave and discard them?"
```

### US-024 — Design Token Override
*As a merchant, I want to override the global colour and typography tokens for my active theme so that the storefront matches my brand palette exactly.*

```gherkin
Given a merchant is in the WYSIWYG editor config panel
When they scroll to "Design token overrides" at the bottom of the right panel
Then they see the current global token values with colour pickers:
  | primary, accent, surface, background, text, border, error |
  And typography: heading font family, body font family, font scale

When they change a token value
Then every component instance using that token updates in the live preview immediately
  And the change is scoped to this merchant's active theme — not the base theme catalogue

Given a merchant overrides accent: "#E94560" to "#00BCD4"
Then all CTA buttons, links, and hover states using the accent token update across the entire preview
  And the change saves with the theme.json on next Save
```

### US-025 — One-Click Theme Switching with Content Carry-Forward
*As a merchant, I want to switch my entire theme in one click and have my existing content automatically carry forward so that I never lose copy I have already written.*

```gherkin
Given a merchant applies a new theme that has different content slots from their current theme
When the theme switch completes
Then FastAPI runs the content carry-forward algorithm:
  | For each content slot in the new theme: |
  |   If a storefront_content row with matching slot_id exists → carry forward automatically |
  |   If no matching row exists → flag slot as empty in WYSIWYG |
  | For each orphaned slot from the old theme: |
  |   Preserve the storefront_content row — never delete |
  |   Don't show in WYSIWYG (slot not in current theme) |

Then the merchant is notified: "Your new theme has {N} new content slots to fill. Everything else carried forward."
  And the WYSIWYG highlights empty slots with a prompt: "Add your content here"
  And the merchant only needs to fill the delta — never re-enter existing copy

Given a merchant switches back to their previous theme
Then the previously orphaned content slots are restored from storefront_content
  And all their original copy reappears without re-entry
```

### US-026 — Storefront Content Slot Editing
*As a merchant, I want to edit storefront marketing text — headings, subheadings, CTA labels, and page copy — directly in the WYSIWYG so that my storefront communicates my brand voice.*

```gherkin
Given a merchant opens a component's Content tab in the WYSIWYG editor
When they edit a short_text slot (e.g. hero heading)
Then the input enforces the max_chars limit defined in theme.json for that slot
  And the live preview updates immediately showing the new text
  And the slot value is saved to storefront_content on theme Save

Given a merchant edits a rich_text slot (e.g. About Us page)
When they use the rich text editor controls (bold, italic, links)
Then formatted HTML is stored in content_value
  And the storefront renders the formatted text correctly

Given a merchant uploads an image to an image_url slot
When the upload completes
Then the image is stored in Cloud Storage: gs://kloudshop-{tenant_id}/storefront/content/{uuid}
  And the content_value stores the Cloud Storage URL
  And the live preview renders the new image immediately
```

---

## E04 — Product Catalog Management

**Goal:** Give merchants unlimited, flexible product catalog management — no variant caps, no arbitrary limits.
**Traces to:** Unlimited product variants, Catalogue Manager role, M-35–M-44.

### US-027 — Add New Product
*As a merchant with Catalogue Manager or Store Manager role, I want to create a new product with unlimited variants so that I can represent any product in my catalog without artificial restrictions.*

```gherkin
Given a Catalogue Manager is on the product creation screen
When they enter product title, description, price, and images
  And they add variants (size, colour, material — any combination, any number)
Then each unique variant combination is assigned a unique SKU automatically
  And there is no upper limit on the number of variants per product
  And each variant has independent: price, stock level, images, SKU code, supplier assignment

When they click "Save product"
Then the product and all variants are persisted to Cloud SQL in the tenant schema
  And a Google Shopping feed update is triggered
  And the product becomes immediately available in the storefront

Given a product has 500 variant combinations (e.g. industrial components with many specifications)
Then the system saves all 500 without error, warning, or performance degradation
  And all 500 are queryable via the storefront search (PostgreSQL FTS + pgvector)
```

### US-028 — Clone Product & Create Variant
*As a merchant, I want to clone an existing product to create a variant quickly so that I can expand my catalog without re-entering data.*

```gherkin
Given a merchant clicks "Clone this item" on any product
When the clone action completes
Then a new product record is created with all fields copied from the original
  And the cloned product title has " (Copy)" appended by default
  And all variant data is cloned
  And images are referenced from the same Cloud Storage paths (not duplicated)
  And the clone opens immediately in the product editor for the merchant to modify

Given the merchant modifies the cloned product and saves
Then the original product is completely unaffected
  And the clone is saved as a fully independent product record
```

### US-029 — Bulk Product Import via CSV
*As a merchant, I want to import multiple products at once via CSV/Excel so that I can migrate or update large catalogs efficiently.*

```gherkin
Given a merchant uploads a CSV/Excel file on the bulk import screen
When the AI parser analyses the file
Then a column mapping preview is shown with confidence levels
  And the merchant can correct any "Review" mappings inline before confirming

When the merchant confirms the import
Then products are created in Cloud SQL in bulk
  And products with validation errors (missing required fields) are shown in a separate "failed" list
  And the failed list shows the row number, field, and error reason for each failure
  And successfully imported rows are committed regardless of the failed rows (partial success is valid)

Given the import contains 10,000 product rows
Then the import is processed asynchronously via Cloud Tasks
  And the merchant is notified via FCM push when the import completes
```

### US-030 — SEO Metadata Editing (All Page Types)
*As a merchant, I want to edit meta titles, descriptions, and URL slugs on every page type so that my store ranks well in search engines without an SEO app.*

```gherkin
Given a merchant opens the SEO panel for a product page
When they edit the meta title, meta description, and URL slug
Then JSON-LD structured data is regenerated automatically
  And the canonical tag is updated
  And the XML sitemap regeneration is queued via Cloud Tasks

Given a merchant edits SEO metadata on a collection page
Then the same fields are available: meta title, meta description, slug
  And changes save independently of product-level SEO

Given a merchant edits SEO metadata on the homepage
Then the homepage meta title and description update
  And the 301 redirect manager is accessible from the same settings panel

Given a merchant changes a product URL slug
Then the system automatically creates a 301 redirect from the old slug to the new slug
  And the merchant is notified: "301 redirect created from /old-slug to /new-slug"
```

### US-031 — Collection Management
*As a merchant, I want to create collections and assign products to them so that my storefront organises products into browseable categories.*

```gherkin
Given a merchant creates a new collection
When they enter a collection name, description, and optional image
  And they assign products to the collection (manual selection or rule-based)
Then the collection is immediately available in the storefront navigation
  And the collection is available as a collection_ref in theme component config

Given a product is assigned to multiple collections
Then it appears in all assigned collections in the storefront
  And its stock is managed from a single inventory record
```

---

## E05 — Order Management

**Goal:** Complete order lifecycle — placement, fulfilment, tracking, refund — across all channels.
**Traces to:** M-20–M-28c, C-09–C-16, order_source flagging.

### US-032 — Order Placement (DTC Consumer)
*As a DTC consumer, I want to place an order with guest checkout and one-tap payment so that buying is as frictionless as possible.*

```gherkin
Given a consumer has items in their cart
When they proceed to checkout
Then guest checkout is offered as the primary option — no account creation required
  And address autocomplete is active
  And Stripe payment methods are shown including Apple Pay/Google Pay on supported devices

When a consumer completes payment via Stripe
Then a Stripe Payment Intent is created and confirmed
  And inventory is reserved with a row-level lock during checkout
  And on payment success the order is created with order_source: "kloudshop"
  And inventory is decremented permanently
  And Pub/Sub "order.placed" event is fired
  And FCM push notifies the merchant
  And Resend sends order confirmation email to the consumer
  And the consumer sees the order confirmation screen with order number and estimated delivery

Given a payment fails during checkout
Then the inventory reservation is released
  And the consumer sees a clear error with the failure reason from Stripe
  And they are returned to the checkout screen with their cart intact
```

### US-033 — Order Fulfilment with Shipment Tracking
*As a merchant, I want to mark orders as fulfilled and enter shipment tracking numbers so that customers are automatically notified of their shipment status.*

```gherkin
Given a merchant opens an order in the order detail view
When they click "Mark as fulfilled"
  And they enter the tracking number and select the carrier
Then the order status updates to "Fulfilled"
  And the fulfilment timestamp is recorded
  And a Resend email is sent to the consumer with the tracking number and carrier link
  And a Twilio SMS is sent if the consumer opted into SMS updates
  And the order_events table is updated with the fulfilment event

Given a merchant fulfils only some items in a multi-item order
When they select specific line items to fulfil
Then a partial fulfilment is recorded
  And the consumer is notified of the partial shipment with the specific items listed
  And the remaining items stay in "Pending fulfilment" status
```

### US-034 — Order Refund (Full & Partial)
*As a merchant Customer Support or Store Manager, I want to issue full or partial refunds so that I can resolve customer issues without leaving KloudShop.*

```gherkin
Given a merchant opens an order and clicks "Issue refund"
When they select "Full refund"
Then Stripe Refunds API is called for the full order amount
  And the refund is processed within Stripe's standard timeline (5–10 business days)
  And the order status updates to "Refunded"
  And the consumer receives a Resend email confirming the refund amount and timeline

When they select "Partial refund" and enter a specific amount or select specific line items
Then Stripe Refunds API is called for the partial amount
  And the order status updates to "Partially refunded"
  And the refund amount is shown on the order detail

Given a refund request exceeds the original order amount
Then the system blocks the action and shows: "Refund amount cannot exceed the original order total of ${amount}"
```

### US-035 — Order Notes & Internal Comments
*As a merchant, I want to add internal notes to orders so that my team can communicate about order-specific issues without leaving KloudShop.*

```gherkin
Given a merchant opens an order detail view
When they type a note and click "Add note"
Then the note is saved with the staff member's name and timestamp
  And the note is visible to all staff with order access
  And the note is never visible to the consumer

Given multiple staff members add notes to the same order
Then notes are displayed in chronological order
  And each note shows the author's name and role
```

### US-036 — Bulk Order Export
*As a merchant, I want to export orders to CSV for a given date range so that I can process them in external tools or for accounting.*

```gherkin
Given a merchant selects a date range and clicks "Export orders"
When the export job runs
Then a CSV is generated containing all order fields for the selected range
  And the CSV is downloadable directly (for small exports <1,000 orders) or via email link (for large exports)
  And GCP infrastructure costs for the export are billed as pass-through
  And the export does not include imported historical orders unless the merchant explicitly includes them
```

---

## E06 — Inventory & Supplier Management

**Goal:** Real-time, multi-location inventory truth with AI-powered replenishment and multi-supplier procurement intelligence.
**Traces to:** M-29–M-34, SUP-01–SUP-33.

### US-037 — Inventory Dashboard with Lead-Time-Aware Urgency
*As a merchant, I want to see stock levels with urgency colour coding that accounts for supplier lead times so that I reorder before it is too late.*

```gherkin
Given a merchant opens the Inventory Dashboard
When the page loads
Then every SKU row shows: SKU, Variant, Stock, Velocity, Days Remaining, Preferred Supplier (rank-1), Lead Time (days)
  And Days Remaining = current_stock / daily_sales_velocity
  And urgency colouring is lead-time-aware:
    | Green = Days Remaining > (lead_time_days + 30) |
    | Amber = Days Remaining between lead_time_days and (lead_time_days + 30) |
    | Red = Days Remaining < lead_time_days (reorder overdue despite stock) |

Given Widget Pro has 8 days of stock and rank-1 supplier lead time is 12 days
Then Widget Pro row is coloured RED
  And the tooltip shows: "Reorder point passed — 8 days stock, 12 days lead time"
```

### US-038 — AI Stock Replenishment Recommendations
*As a merchant, I want AI-powered reorder recommendations with preferred supplier pre-selected and one-time override capability so that I can draft purchase orders in one click.*

```gherkin
Given the AI replenishment panel is shown on the Inventory Dashboard
When reorder recommendations are displayed
Then each row shows: SKU, Preferred Supplier (rank-1), Reorder Quantity, Lead Time, Confidence Level
  And per row, three actions are available:
    | [✓ Use preferred supplier] — accept rank-1 for this PO line, no rank change |
    | [↓ Change supplier for this order] — one-time override dropdown showing all suppliers in rank order |
    | [⚙ Update standing preference rank] — permanent re-rank navigates to supplier preference settings |

When a merchant selects "Change supplier for this order"
Then a dropdown shows all assigned suppliers for that SKU in rank order
  And the override applies to THIS purchase order line only
  And the standing preference_rank in product_suppliers is NOT modified

When a merchant selects "Update standing preference rank"
Then they are taken to the supplier preference panel for that SKU
  And they can drag to reorder supplier preference ranking
  And the new ranking takes effect for all future purchase orders
  And the one-time PO override is never conflated with permanent re-ranking

Given an AI supplier performance alert triggers (e.g. rank-1 has 34% late delivery rate this quarter)
When the alert is shown inline
Then it shows specific numbers: supplier name, metric value, alternative supplier name, alternative metric, unit cost difference
  And two options are shown: [Dismiss] [Promote {alternative} → rank 1]
  And KloudShop never automatically promotes a supplier without merchant confirmation
```

### US-039 — Supplier Management (CRUD)
*As a merchant, I want to add, edit, and manage my supplier list so that I can maintain accurate procurement information.*

```gherkin
Given a merchant navigates to Supplier Management
When they click "Add new supplier"
  And fill in: name, contact name, email, phone, payment terms, default lead time (days), currency
  And save
Then the supplier is created in the suppliers table in the tenant schema
  And they are immediately available for assignment to SKUs

Given a merchant adds a supplier on-the-fly while creating a product
When they click "Add supplier" inside the product form
Then an inline modal opens — the page does not navigate away
  And on saving the new supplier they are returned to the product form
  And the new supplier is immediately selectable in the supplier assignment dropdown

Given a merchant tries to delete a supplier with open purchase orders
Then the system blocks deletion and shows: "This supplier has open purchase orders. Archive them instead."
  And an "Archive supplier" option is offered as an alternative
```

### US-040 — Multi-Supplier Assignment & Preference Ranking
*As a merchant, I want to assign multiple suppliers to a single SKU and set their preference order so that the system knows which supplier to use by default and which are fallbacks.*

```gherkin
Given a merchant opens a product's supplier panel
When they assign a second supplier to a SKU that already has one
Then both suppliers appear in the supplier list for that SKU
  And each has an editable preference_rank (1 = most preferred)
  And exactly one supplier holds rank 1 at any time — the system enforces this

When a merchant drags a rank-2 supplier to rank-1 position
Then the swap is atomic: former rank-1 becomes rank-2, new rank-1 is set
  And no intermediate state exists where two suppliers hold rank-1

Given a merchant wants to view the supplier comparison table for a SKU
When they open the supplier comparison panel
Then they see a side-by-side table: Supplier, On-Time %, Fill Rate, Quality Score, Unit Cost, Composite Score
  And the AI suggestion banner shows if a lower-ranked supplier scores significantly higher than rank-1
  And the composite score NEVER automatically changes any preference rank
```

### US-041 — Purchase Order Lifecycle
*As a merchant, I want to draft, send, receive, and reconcile purchase orders so that I have a complete procurement audit trail.*

```gherkin
Given a merchant clicks "Draft Purchase Orders" on the replenishment panel
When the draft POs are generated
Then the system groups reorder lines by supplier (rank-1 default + any per-line overrides)
  And one draft PO is created per supplier
  And each PO shows: supplier, line items, quantities, unit costs, expected delivery date

When a merchant reviews a draft PO and clicks "Send to Supplier"
Then the PO is sent via Resend email to the supplier's contact email
  And the PO status updates to "Sent"
  And the expected_delivery_at is calculated using the supplier's lead time

When goods arrive and the merchant marks the PO as received
Then they can mark full or partial receipt
  And qty_received is recorded per line item
  And if qty_received < qty_ordered the discrepancy_flag is set
  And inventory is incremented by the received quantity
  And if partial, remaining items stay in "Pending receipt" status
```

### US-042 — Supplier Performance Analytics
*As a merchant, I want to see supplier scorecards with delivery, quality, and pricing metrics so that I can make informed procurement decisions.*

```gherkin
Given a merchant opens the Supplier Analytics dashboard
When they view a specific supplier's scorecard
Then they see metrics computed across 30/90/365-day rolling windows:
  Tier 1 — Delivery: on-time rate, average actual lead time, lead time accuracy %
  Tier 2 — Quality: quality event rate, fill rate (qty received/qty ordered), defect rate
  Tier 3 — Pricing: unit cost trend (rising/stable/falling), price stability index, cost delta vs alternatives
  Tier 4 — Composite score (0–100) with merchant-adjustable weightings

Given a merchant adjusts the composite score weightings (e.g. prioritise delivery over price)
When they save the new weightings to supplier_score_weights
Then the composite scores for all suppliers recalculate immediately
  And the new weights apply to all future AI reorder suggestions

Given a merchant wants to compare suppliers for a specific SKU
When they open the SKU supplier comparison table
Then they see all assigned suppliers side-by-side with their scores, unit costs, and current rank
  And the AI flags when a lower-ranked supplier scores meaningfully higher
```

---

## E07 — B2B Operations

**Goal:** Full wholesale engine — company accounts, tiered pricing, approval workflows, net terms, B2B buyer portal.
**Traces to:** B2B tier differentiator, M-60–M-70, B-00a–B-21.

### US-043 — B2B Buyer Account Creation & Invitation
*As a merchant with B2B Account Manager role, I want to create a buyer account and invite the buyer via email so that they can access the B2B portal with their negotiated pricing.*

```gherkin
Given a B2B Account Manager creates a buyer account
When they fill in: company name, contact name, email, credit limit, net payment terms, assigned price list
  And save
Then a buyer account record is created in b2b_accounts
  And a Resend invitation email is sent to the buyer's contact email
  And the buyer has no portal access until they accept the invitation

Given a merchant requires manual approval before buyers gain portal access
When a buyer completes registration via the invitation link
Then their account status is set to "pending approval"
  And the merchant receives FCM push + email notification
  And the buyer cannot browse the catalog until approved
```

### US-044 — B2B Custom Price List
*As a merchant, I want to create custom price lists and assign them to specific buyer accounts so that each buyer sees their negotiated prices immediately on login.*

```gherkin
Given a B2B Account Manager creates a custom price list
When they assign per-product price overrides (fixed price or % discount per SKU)
  And assign the price list to one or more buyer accounts
Then buyers on that price list see their custom prices in the portal immediately on login
  And standard RRP prices are never shown to authenticated B2B buyers
  And the price list is cached in Redis per buyer account (TTL: 30 minutes)

Given a buyer logs into the B2B portal
When the catalog renders
Then every product shows their account-specific negotiated price
  And no "login to see price" prompt appears — prices are immediately visible
```

### US-045 — B2B Approval Workflow
*As a merchant, I want to configure approval workflows for B2B orders so that large orders are reviewed before processing.*

```gherkin
Given a merchant configures an approval workflow with an order threshold of $1,000
When a B2B buyer places an order exceeding $1,000
Then the order is not immediately fulfilled
  And the order status is set to "Pending approval"
  And Firebase Realtime DB writes: approval_requests/{id} with the order details
  And FCM push + email notify the merchant approver role

When the merchant approver clicks "Approve"
Then the order status updates to "Approved"
  And the B2B buyer receives FCM push + email notification
  And if payment terms are "Net-30", a Stripe Invoice is generated
  And the order proceeds to fulfilment

When the merchant approver clicks "Decline" and adds a reason
Then the order status updates to "Declined"
  And the buyer receives FCM push + email with the decline reason
  And the order is never charged

Given an order is within the buyer's credit limit and below the approval threshold
Then the order is auto-approved immediately without requiring merchant action
```

### US-046 — B2B Buyer Portal Catalog Browsing
*As a B2B buyer, I want to browse my company's assigned catalog with AI-powered consultative search so that I can find exactly what I need efficiently.*

```gherkin
Given an authenticated B2B buyer is on the portal
When they browse the catalog
Then only products assigned to their company's negotiated catalog are visible
  And products are displayed with their account-specific prices
  And product quantities default to case/pallet minimums for B2B

When the buyer uses the AI consultative search panel
  And types a natural language query: "M8 stainless bolts, box quantities, 500 for a marine application"
Then the AI returns relevant SKUs with specs and compatibility notes
  And all results are grounded in the actual product catalog — no hallucinated specifications
  And the buyer can add results directly to cart

Given a buyer searches for a product not in their assigned catalog
Then the product does not appear in search results
  And no cross-buyer catalog leakage occurs
```

### US-047 — B2B Net-Terms Invoicing
*As a merchant, I want approved B2B orders to generate Stripe Invoices with net payment terms so that wholesale invoicing is automated.*

```gherkin
Given a B2B order is approved and the buyer's account has Net-30 terms
When the approval is confirmed
Then a Stripe Invoice is created for the order total
  And the invoice due date is set to 30 days from the approval date
  And the invoice is emailed to the buyer via Stripe (PDF)
  And the invoice appears in the merchant's Stripe dashboard

Given a B2B invoice becomes overdue
Then the merchant sees it flagged on the B2B Activity dashboard
  And they can initiate a payment chase from the merchant admin
```

---

## E08 — Feature Catalogue & Configuration

**Goal:** Native toggleable feature library — no app store, no third-party installs, schema-driven setup wizards.
**Traces to:** Feature Catalogue differentiator, feature_config_schema, dependency chaining, M-54–M-59f.

### US-048 — Feature Catalogue Browsing & Activation (Phase 1)
*As a merchant, I want to browse available features and activate them so that my store gains new capabilities without installing third-party apps.*

```gherkin
Given a merchant opens the Feature Catalogue
When the page loads
Then all features in feature_registry are shown with:
  | Feature name and one-line description |
  | "What this replaces" (e.g. "Replaces Klaviyo — $45/mo saved") |
  | Tier badge (DTC / B2B / Hybrid) |
  | Status badge: Available / Active / Active — setup needed / Coming soon |

When a merchant toggles a feature ON
Then a confirmation modal shows: "Activating {feature name} — We're setting up your database. This takes about 15 seconds."
  And a progress bar updates in real time via Firebase Realtime DB — never a fake timer

When the dependency chain resolves
Then upstream feature schemas are silently applied first if required
  And the merchant never sees migration internals
  And the feature status updates to "Active — setup needed" (if has_config = TRUE)
  Or to "Active" (if has_config = FALSE — immediate operational)

When a migration fails
Then the feature status remains "Available"
  And Sentry receives an alert
  And the merchant sees: "Something went wrong. We've been notified. Your store is unaffected."
  And no technical details or stack traces are shown
```

### US-049 — Feature Setup Wizard (Phase 2)
*As a merchant, I want to configure a newly activated feature through a guided setup wizard so that the feature is operational with my preferred settings within 30 seconds.*

```gherkin
Given a feature has been activated and has_config = TRUE
When the setup wizard launches
Then the wizard renders dynamically from feature_config_schema:
  | integer parameters → NumberInputField with min/max validation |
  | float parameters → DecimalInputField |
  | boolean parameters → SwitchToggle |
  | string with allowed_values → DropdownSelector |
  | string free-form → TextInputField (single-line) |
  | text → TextAreaField (multi-line) |
  | date → DatePicker |
  | time → TimePicker (HH:MM) |
  | datetime → DateTimePicker |
  | json_array with allowed_values → MultiSelectChips |
  | json_array free-form → DynamicListInput |
  | json_object → StructuredObjectForm |

  And parameters are grouped by wizard_group into named wizard steps
  And default values are pre-filled — merchant can complete in 30 seconds if defaults are acceptable
  And is_required fields block step progression until filled

When the merchant saves the wizard
Then FastAPI INSERT/UPDATEs rows in tenant_feature_config
  And the feature status updates to "Active ✓"
  And the feature is immediately operational on the storefront

Given a merchant skips the wizard
Then the feature is marked "Active — setup needed" in the Feature Catalogue
  And a banner on the feature card links directly to the wizard
  And the feature is NOT operational until setup is completed (for has_config = TRUE features)
```

### US-050 — Feature Reconfiguration (Phase 3)
*As a merchant Owner or Admin, I want to update an already-active feature's configuration so that I can change settings as my business needs evolve.*

```gherkin
Given a merchant clicks "Configure" on an Active ✓ feature
When the reconfiguration wizard opens
Then every field shows the merchant's current live values — not the system defaults
  And a banner at the top of the wizard reads: "⚠ You are editing a live feature. Changes take effect immediately when saved."
  And contextual warnings appear per field where changes have significant customer impact:
    | Loyalty points rate: "Changing this affects all future purchases. Existing points earned are not affected." |
    | Tier thresholds: "Raising a threshold may move customers down a tier immediately." |
    | Delivery windows: "Removing a delivery day may affect carts already in progress." |

When the merchant saves changes
Then FastAPI UPDATEs only the changed keys in tenant_feature_config
  And unchanged keys are untouched
  And the feature remains "Active ✓" throughout — never enters a degraded state
  And changes take effect within 5 minutes (Redis config cache TTL)

When the merchant clicks Cancel
Then all unsaved changes are discarded
  And the live store is completely unaffected
  And an audit log entry records: set_at, set_by for every changed key
```

### US-051 — Feature Deactivation
*As a merchant, I want to deactivate a feature so that it is no longer active in my store, while preserving all configuration for future re-activation.*

```gherkin
Given a merchant clicks "Deactivate" on an Active feature
When they confirm the action
Then the feature is marked inactive in the tenant's feature state
  And the feature's functionality is removed from the storefront immediately
  And NO tenant_feature_config rows are deleted — all configuration is preserved
  And NO Alembic migration runs — feature schema tables remain in the tenant schema
  And the feature status shows as "Available" in the Feature Catalogue

Given the merchant re-activates the same feature later
When activation completes (schema migration skipped — already applied)
Then the setup wizard pre-fills with the previously saved configuration values
  And the merchant only adjusts what has changed — no full reconfiguration required
```

### US-052 — Feature Request Channel
*As an authenticated merchant, I want to submit and vote on feature requests so that the community can influence KloudShop's development roadmap.*

```gherkin
Given a merchant on any paid tier (or active trial) opens the Feature Request Channel
When the page loads
Then they see a list of existing feature requests ordered by vote count
  And only authenticated KloudShop users with active accounts can view and interact

When they click "New request" and submit a title and description
Then the request is published in the Feature Request Channel
  And a vote is automatically cast by the submitter

When they click "Upvote" on an existing request
Then their vote is recorded
  And the vote count updates immediately
  And each merchant can vote once per request

Given a visitor without a KloudShop account attempts to access the Feature Request Channel
Then they see: "The Feature Request Channel is for KloudShop merchants only. Sign up to access."
  And the channel content is not publicly visible
```

---

## E09 — Analytics & Reporting

**Goal:** Three-layer analytics — native Flutter KPI dashboards, embedded Looker Studio BI, and Vertex AI predictive intelligence.
**Traces to:** BigQuery data warehouse, M-71–M-81.

### US-053 — Revenue Overview Dashboard
*As a merchant, I want a real-time revenue overview dashboard so that I can understand my store's performance at a glance in under 60 seconds.*

```gherkin
Given a merchant opens the Analytics → Revenue Overview dashboard
When the page loads
Then the Needs Attention panel is shown above the fold with:
  | Orders pending fulfilment > 24hrs |
  | SKUs with Days Remaining < lead time (reorder overdue) |
  | B2B approvals waiting |
  And the panel is never empty when genuine issues exist

Then the Revenue Overview panel shows for the last 24 hours:
  | GMV, orders count, AOV, conversion rate |
  | Revenue by channel (DTC vs B2B) |
  | MoM and YoY comparison indicators |
  And data is refreshed every 15 seconds from BigQuery via FastAPI

Given an AI inventory insight is triggered (e.g. a SKU predicted to stockout in 3 days)
Then it appears below the Needs Attention panel with specific numbers
  And two actions are shown: [Dismiss] [Draft Purchase Order]
  And insights are never generic — they always reference a specific SKU and specific timeframe
```

### US-054 — Demand Forecasting & Stock Replenishment Prediction
*As a merchant, I want Vertex AI to predict reorder points and suggest quantities for each SKU based on my historical sales velocity so that I never experience stockouts.*

```gherkin
Given a merchant has at least 90 days of order history and 100+ orders
When Vertex AI Forecasting has been trained on their data
Then per-SKU reorder recommendations appear in the Inventory dashboard:
  | Predicted units sold for next 7/14/30 days |
  | Recommended reorder quantity per SKU |
  | Days-to-stockout estimate with risk level (High/Medium/Low) |

Given a merchant has fewer than 90 days of data
Then rule-based stock alerts (low stock threshold) are used instead
  And a banner explains: "AI demand forecasting will activate after 90 days of sales data"
  And no misleading AI-generated forecasts are shown with insufficient training data

Given the weekly model retraining job runs via Cloud Tasks
When new sales data from the past 7 days is incorporated
Then reorder recommendations update automatically
  And merchants receive FCM push notifications for any SKU whose reorder point has changed
```

### US-055 — Looker Studio Embedded BI
*As a merchant CFO or analyst, I want access to deep ad-hoc reporting via an embedded BI tool so that I can build custom reports without leaving KloudShop.*

```gherkin
Given a merchant with Analyst/Finance role opens Analytics → Deep Reports
When the Looker Studio embed loads
Then a selection of pre-built KloudShop report templates is shown:
  | Revenue & Conversion Deep Dive |
  | Customer Cohort & LTV Analysis |
  | Product & Inventory Intelligence |
  | B2B Buyer Account Performance |
  | Marketing Attribution (UTM-based) |

When a merchant opens a report template
Then the Looker Studio iframe renders scoped to their BigQuery tenant partition
  And row-level security ensures they only see their own data
  And they can clone, customise, and save their own report variants

Given a merchant builds a custom report with cross-dimensional filters
When they schedule the report for weekly email delivery
Then Looker Studio sends the scheduled report to their registered email
```

---

## E10 — Billing & Subscription

**Goal:** Transparent pass-through billing — flat subscription + itemised GCP usage on a single merchant invoice.
**Traces to:** Stripe Billing + metered usage, GCP billing export, M-82–M-88, SYS-09–SYS-12b.

### US-056 — Monthly Invoice Generation
*As a merchant, I want to receive a single monthly invoice showing my flat subscription fee plus itemised GCP infrastructure costs so that my bills are fully transparent.*

```gherkin
Given the monthly billing cycle runs via Cloud Tasks
When the billing service queries GCP Billing Export in BigQuery for this tenant's usage
Then costs are aggregated by resource type: Cloud SQL, Cloud Run, Cloud Storage, Vertex AI, CDN egress, Pub/Sub
  And the fixed 15% KloudShop markup is applied per resource type
    (merchant_bill_per_resource = gcp_actual_cost × 1.15)
  And Stripe metered billing usage events are fired per resource type
  And Stripe Billing generates a single invoice with:
    | Line 1: Flat subscription (e.g. Hybrid — $49.99) |
    | Line 2+: Itemised GCP usage per resource type |

Given a merchant's invoice is generated
When they view it in the Billing section of their admin
Then they see the full breakdown with no hidden fees
  And they can download the invoice as PDF
  And a note clarifies: "GCP infrastructure costs reflect actual usage at Google's cost + 15% KloudShop markup (you pay 1.15× the actual GCP cost). As GCP costs decrease, so do your bills."
```

### US-057 — Trial Expiry — Resource Hard Stop
*As KloudShop, I want to automatically halt GCP resource access when a merchant's trial expires without payment details so that cloud costs are not accrued for inactive trial accounts.*

```gherkin
Given a merchant's 1-month free trial period has ended
  And no paid subscription has been set up
When the trial expiry job runs automatically (no human trigger)
Then all GCP resources for the tenant are hard-stopped:
  | Cloud Run services suspended |
  | Cloud SQL access restricted |
  | Cloud Storage access restricted |
  And the storefront returns a 503 with a KloudShop-branded upgrade prompt
  And the merchant receives a Resend email: "Your trial has ended — upgrade to keep your store live"
  And subscription access to the admin continues for 7 days to allow the merchant to download their data

Given a merchant upgrades to a paid tier after trial expiry
When payment is confirmed via Stripe
Then GCP resources are reinstated automatically within 5 minutes
  And the storefront resumes serving traffic
```

### US-058 — Merchant Account Suspension & Reinstatement
*As KloudShop, I want to automatically suspend merchant accounts that fail payment after Stripe dunning and reinstate them immediately on successful payment.*

```gherkin
Given a merchant's monthly payment fails
  And Stripe dunning has sent 3 retry attempts over 7 days with no success
When the Stripe webhook fires for final dunning failure
Then the merchant account is suspended automatically:
  | Admin access is restricted to billing page only |
  | Storefront is suspended |
  | FCM push + email notifies the merchant |

Given a suspended merchant updates their payment method and pays the outstanding balance
When the Stripe payment.succeeded webhook fires
Then the merchant account is reinstated automatically within 60 seconds
  And admin access is fully restored
  And the storefront resumes
  And FCM push + email confirms reinstatement
```

---

## E11 — POS & Omnichannel

**Goal:** Browser-native physical store POS with unified inventory — no hardware investment required.
**Traces to:** POS Operator role, Model B only, O-00a–O-07.

### US-059 — POS Operator Role Assignment & Location Setup
*As a merchant Owner or Admin, I want to assign the POS Operator role to a staff member for a specific location so that in-store sales are correctly attributed to the right stock location.*

```gherkin
Given an Owner assigns the POS Operator role to a staff member
When they select the staff member's assigned stock location
Then the role assignment is saved with the location scope
  And the staff member's JWT claims include the POS Operator role and assigned location_id

Given the POS Operator logs into KloudShop on any browser-capable device
When they authenticate with their Gmail account
Then they see the POS Operator interface — scoped to their assigned stock location
  And they can see: in-store eligible product catalog, stock levels for their location
  And they CANNOT access: orders from other channels, financials, admin settings
```

### US-060 — In-Store Sale Processing (POS)
*As a POS Operator, I want to process in-store sales through a browser interface so that inventory decrements in real time without dedicated hardware.*

```gherkin
Given a POS Operator has the KloudShop POS interface open in a browser
When they select products and quantities from the in-store catalog
  And the customer pays (via Stripe Terminal card reader if connected, or cash/external payment recorded manually)
Then an order is created with order_source: "pos"
  And inventory is decremented from the assigned stock location with a Cloud SQL row-level lock
  And the same inventory pool as online orders is used — cross-channel oversell is architecturally impossible
  And a Pub/Sub "order.placed" event fires with channel: "pos"
  And BigQuery receives a POS analytics event with the location attribution
  And the merchant's admin dashboard inventory updates in real time via FCM

Given inventory for a selected product reaches zero during the POS transaction
Then the system blocks the sale for that item
  And shows: "This item is out of stock at this location."
  And the POS Operator can check other locations' stock (if configured for multi-location visibility)
```

---

## E12 — Social Commerce & Channels

**Goal:** Native social channel integrations — TikTok Shop, Instagram, Facebook, Google Shopping — with real-time inventory sync.
**Traces to:** SC-01–SC-09, SYS-14–SYS-15.

### US-061 — Social Channel Connection & Catalog Sync
*As a merchant, I want to connect TikTok Shop, Instagram Shopping, and Facebook Shops to my KloudShop catalog so that product listings and inventory sync automatically without a third-party app.*

```gherkin
Given a merchant navigates to Channel Manager
When they click "Connect TikTok Shop"
  And complete the OAuth flow with their TikTok Shop account
Then the Channel Sync Service (Cloud Run Job) runs an initial catalog push
  And all eligible products are listed on TikTok Shop
  And subsequent product changes (price, stock, new products) trigger automatic syncs

Given a product goes viral on TikTok and orders surge
When multiple TikTok Shop orders arrive simultaneously
Then each order flows through the same Cloud SQL inventory reservation system as online orders
  And row-level locks prevent overselling across all channels
  And each order is created with order_source: "tiktok_shop"
  And the merchant fulfils TikTok Shop orders from the KloudShop dashboard exactly like online orders
```

### US-062 — Google Shopping Native Feed
*As a merchant, I want my product catalog to automatically generate and maintain a live Google Shopping feed so that my products appear in Google Shopping results without a feed management app.*

```gherkin
Given a merchant connects their Google Merchant Center account (one-time OAuth)
When the connection is established
Then KloudShop generates a Google Shopping-compliant product feed at: storename.kloudshop.biz/feeds/google-shopping
  And the feed is registered with Google Merchant Center automatically

Given a product's price, stock status, or availability changes
When the change is saved
Then the Google Shopping feed is updated within 5 minutes
  And the daily full refresh Cloud Tasks job catches any remaining drift
  And the feed includes: GTIN/MPN where provided, product condition, shipping weight, availability, structured pricing, sale price + dates
```

---

## E13 — Tax Compliance

**Goal:** Automated multi-jurisdiction tax calculation at checkout through each merchant's
own Stripe Tax configuration — no separate tax vendor, no additional API cost.
**Traces to:** Stripe Tax via connected Stripe accounts, T-01–T-04.

### US-063 — Merchant Tax Setup (Stripe Tax Embedded Components)
*As a merchant, I want to configure my tax registrations inside KloudShop so that tax is automatically calculated correctly at my checkout without leaving the KloudShop admin.*

```gherkin
Given a merchant navigates to Settings → Tax Compliance in the KloudShop admin
When the tax settings panel loads
Then KloudShop renders the Stripe Tax embedded components via Stripe Connect AccountSession:
  | ConnectTaxSettings — for head office location and default tax code |
  | ConnectTaxRegistrations — for adding tax registrations per jurisdiction |
  And the merchant never leaves KloudShop to configure Stripe Tax
  And the components are rendered using the merchant's connected Stripe account context

When the merchant adds a tax registration (e.g. VAT registration for Germany)
Then Stripe records the registration on the merchant's connected account via the Tax Registrations API
  And tax is now calculated and collected automatically for German buyers at checkout
  And KloudShop does not store any tax registration data — Stripe is the source of truth

Given a merchant has not yet configured any tax registrations
When a consumer proceeds to checkout
Then no tax is applied (merchant has not declared any tax obligations)
  And a banner is shown in the merchant admin: "Tax not configured — your buyers are not being charged tax"
```

### US-064 — Automated Tax Calculation at Checkout
*As a merchant, I want Stripe Tax to automatically calculate and collect the correct tax at checkout for my customers so that I never charge incorrect tax or face government penalties.*

```gherkin
Given a merchant has configured Stripe Tax registrations on their connected account
When a consumer proceeds to checkout and enters their shipping address
Then Stripe Tax automatically calculates the applicable tax on the payment intent:
  | US buyers: correct sales tax nexus rate for the buyer's state |
  | EU buyers: correct VAT rate for the buyer's country |
  | AU buyers: 10% GST |
  | CA buyers: correct GST/HST/PST by province |
  And a tax_transaction object is created in the merchant's Stripe account
  And the tax amount is shown on the checkout summary page
  And KloudShop never holds or processes tax — it flows through Stripe directly

Given a consumer abandons the cart and returns
When they reach the checkout summary
Then Stripe Tax recalculates based on the current cart — no stale tax amounts shown

Given a B2B buyer has a tax-exempt certificate on file
When they proceed to checkout
Then the merchant configures the exemption on the Stripe payment intent
  And tax is set to $0 for that order
  And the exemption is recorded on the tax_transaction object in Stripe

Given a product has been marked as zero-rated (e.g. children's clothing in the UK)
When it appears in a checkout
Then the merchant assigns the correct Stripe Tax product tax code to that product
  And Stripe applies the zero-rate automatically — no manual override needed
```

### US-065 — Merchant Tax Reporting
*As a merchant, I want to download a tax statement for any period so that I can file my tax returns with my local tax authority.*

```gherkin
Given a merchant navigates to Settings → Tax Compliance → Reports
When they select a date range and jurisdiction
Then KloudShop calls /v1/tax/transactions filtered by their connected_account_id
  And generates a downloadable PDF tax statement for that period
  And the statement includes: gross sales, tax collected, tax rate, jurisdiction breakdown
  And the merchant can also access the same data directly from their Stripe Express Dashboard

Given a merchant's accountant needs a VAT summary for EU filing
When the merchant exports a tax report for Germany for Q1
Then the report shows all transactions where German VAT was collected
  And the tax_transaction_id for each transaction is included for audit trail purposes
```

---

## E14 — Dynamic Pricing Engine

**Goal:** Rule-based automatic price adjustments based on stock age, velocity, and time triggers.
**Traces to:** P-01–P-05.

### US-066 — Dynamic Pricing Rule Creation & Execution
*As a merchant, I want to create pricing rules based on stock age, velocity, and time triggers so that prices adjust automatically without manual intervention.*

```gherkin
Given a merchant creates a stock-age markdown rule:
  "If a product has been in stock > 60 days and not sold, reduce price by 15%"
When the daily pricing engine job runs
Then all products meeting the criteria have their prices reduced by 15% automatically
  And a pricing event is logged: product_id, old_price, new_price, rule_id, triggered_at
  And the Google Shopping feed is updated with the new prices within 5 minutes
  And the merchant can view all price changes made by the rule in the rule's analytics panel

Given a merchant creates a velocity-based surge rule:
  "If a product sells more than 50 units in 24 hours, increase price by 10%"
When the velocity threshold is crossed
Then the price adjusts automatically within the next pricing engine cycle (hourly)
  And the rule shows a live trigger log

Given a merchant creates a flash sale rule with datetime triggers:
  "From 2026-11-29 00:00 to 2026-11-29 23:59, reduce all products in 'Sale' collection by 20%"
When the datetime window opens
Then prices adjust at exactly the configured start datetime
  And revert at exactly the configured end datetime
  And the merchant receives an FCM push confirming the sale started and ended
```

---

## E15 — Data Portability

**Goal:** Full merchant data ownership — on-demand export of all data, always free (platform fee), pass-through infrastructure costs only.
**Traces to:** D-01–D-04, data portability differentiator.

### US-067 — Full Data Export On Demand
*As a merchant, I want to export all my store data — products, orders, customers, analytics — as hierarchical CSV or JSON at any time so that I own my data and am never locked in.*

```gherkin
Given a merchant navigates to Settings → Data Portability
When they click "Export all data"
  And select format (CSV or hierarchical JSON)
Then a Cloud Tasks export job is queued
  And the export includes: products, variants, collections, orders (with order_source flag), customers, addresses, B2B accounts, price lists, analytics summary
  And imported historical orders (order_source: "imported") are clearly labelled as such

When the export completes
Then the merchant receives FCM push + email with a download link
  And the download link is a signed Cloud Storage URL valid for 24 hours

When the merchant views their billing
Then the export appears as a GCP infrastructure pass-through cost (Cloud SQL read + Cloud Storage egress)
  And the invoice line item reads: "Data export — GCP infrastructure cost (no KloudShop platform charge)"
  And no KloudShop fee is added on top of the raw GCP cost
```

---

## E16 — Internal Messaging

**Goal:** Native contextual messaging between staff and B2B buyers — no email, no Slack, no WhatsApp.
**Traces to:** MSG-01–MSG-28, messaging architecture.

### US-068 — Direct Messages (Staff ↔ Staff / Merchant ↔ B2B Buyer)
*As a staff member or B2B buyer, I want to send direct messages within KloudShop so that internal and B2B communication is contextual and archived.*

```gherkin
Given a staff member composes a direct message to another staff member
When they send the message
Then FastAPI Messaging Module validates sender and recipient auth (JWT + RBAC)
  And the message is written to Cloud SQL messages table: message_id, thread_id, sender_id, body, sent_at
  And the message is written to Firebase Realtime DB for real-time delivery to the recipient's open session
  And FCM push fires to the recipient's registered devices (if app is backgrounded)
  And the recipient's unread badge count increments in Redis

Given the recipient opens the thread
When they read the message
Then their last_read_at is updated in thread_participants
  And the unread badge count clears for this thread

Given a message is sent
Then it is immediately immutable — no edit, no delete, by any user including Owner
  And this immutability preserves the legal audit trail for B2B price agreements
```

### US-069 — Context-Linked Message Threads
*As a staff member, I want to start a message thread attached to a specific order, PO, SKU, or buyer account so that all discussion about that object is in one place.*

```gherkin
Given a staff member views order #1042
When they click "Start thread on this order"
Then a message_threads record is created with thread_type: "order", linked_object_id: order_id
  And all staff with access to this order are automatically added as thread participants
  And the thread appears in the "Linked to Orders" inbox view for all participants

Given a B2B Account Manager starts a thread on buyer account "Acme Corp"
When the thread is created
Then it is visible to:
  | All staff with B2B Account Manager or Admin role |
  | The Acme Corp buyer contact from their B2B portal |
  And serves as the official communication record for that buyer relationship
```

### US-070 — File Attachments in Messages
*As a staff member or B2B buyer, I want to attach images and PDFs to messages so that I can share relevant documents without leaving KloudShop.*

```gherkin
Given a user attaches a file to a message
When the file is uploaded
Then the server validates the MIME type by reading the file bytes (python-magic) — NOT by trusting the client-declared Content-Type
  And only these MIME types are accepted: image/jpeg, image/png, image/webp, application/pdf
  And all other file types are rejected with: "Only images (JPEG, PNG, WebP) and PDFs are supported."
  And maximum file size is 100MB per file
  And maximum 10 attachments per message

When a PDF is uploaded
Then Cloud Storage triggers a Cloud Run scanner that checks for embedded JavaScript
  And PDFs with embedded JavaScript are rejected with: "This PDF contains active content and cannot be attached for security reasons."

When a recipient views a message with attachments
Then files are served via signed Cloud Storage URLs with a 15-minute TTL
  And files are never publicly accessible
  And the recipient can download or preview files within the 15-minute window
```

### US-071 — Message Search
*As a staff member or B2B buyer, I want to search messages by keyword, sender, date, and linked object so that I can find any historical communication instantly.*

```gherkin
Given a staff member uses the message search
When they search by keyword
Then PostgreSQL FTS queries body_tsv (generated tsvector column on messages.body)
  And results are returned within 500ms for typical message volumes
  And search is strictly scoped to threads the requesting user has access to

When they filter by linked object (e.g. Order #1042)
Then only threads with linked_object_id matching that order appear
  And cross-tenant results never appear

Given a staff member with Fulfilment Staff role searches messages
When the search runs
Then results only include threads their role has access to
  And admin-only or finance threads are never returned
```

---

## E17 — Consumer DTC Storefront

**Goal:** SEO-first, mobile-optimised consumer storefront with AI-powered product discovery and frictionless checkout.
**Traces to:** C-01–C-31, SSR via FastAPI, Core Web Vitals.

### US-072 — Storefront Page Load & Core Web Vitals
*As a DTC consumer, I want the storefront to load fast on mobile so that I don't abandon before the first product renders.*

```gherkin
Given a consumer navigates to a merchant's storefront (custom domain or kloudshop.biz subdomain)
When the page loads
Then the server-side rendered HTML is returned from FastAPI + Flutter Web HTML renderer
  And LCP (Largest Contentful Paint) is < 2.5 seconds on a 4G mobile connection
  And CLS (Cumulative Layout Shift) is < 0.1
  And the page is fully readable by Google's web crawlers
  And JSON-LD structured data is present in the HTML head

Given a consumer navigates from the product listing to a product detail page
When the PDP loads
Then product images, price, variant selector, and Add to Cart CTA are all visible without scrolling on a standard mobile screen
```

### US-073 — AI Consultative Search (RAG-Powered)
*As a DTC consumer, I want to search using natural language so that I can find products that match my needs even if I don't know the exact product name.*

```gherkin
Given a consumer types "waterproof jacket under $200 for hiking in cold weather" into the search bar
When the AI consultative layer processes the query
Then the RAG pipeline queries Vertex AI embeddings against the merchant's pgvector product index
  And results are returned with relevant attributes highlighted ("rated to -10°C", "10,000mm waterproof")
  And all results are grounded in the actual catalog — no hallucinated product specifications
  And results that do not exist in the catalog are never returned

Given a consumer asks the AI assistant on a PDP: "Does this come in wide fit?"
When the query is processed
Then the AI answers from the actual product variant data and merchant policy information
  And if the variant doesn't exist, the AI says so clearly — it never invents a variant
```

### US-074 — Guest Checkout & Post-Purchase Account Creation
*As a DTC consumer, I want to complete checkout without creating an account and optionally create one afterwards so that buying is maximally frictionless.*

```gherkin
Given a consumer reaches the checkout
When they choose to check out as a guest
Then they are not prompted to create an account before, during, or at payment
  And they can complete the full checkout flow with email address and shipping details only

When the order confirmation screen is shown
Then a soft account creation prompt appears: "Save your details for faster checkout next time"
  And this prompt is dismissable with a single tap
  And dismissing it does not affect the order or any confirmation emails

Given a consumer clicks "Create account" on the confirmation screen
When they set a password or connect Google
Then their completed order is linked retroactively to the new account
  And they receive a Resend welcome email
```

### US-075 — Loyalty Programme Enrolment & Redemption (Feature Catalogue)
*As a DTC consumer, I want to enrol in a merchant's loyalty programme and redeem my points at checkout so that I am rewarded for repeat purchases.*

```gherkin
Given the Loyalty Programme feature is active and configured for the merchant
When a consumer creates an account or opts in during checkout
Then a loyalty_accounts record is created for them
  And any configured welcome_bonus_points are credited immediately

Given a consumer makes a purchase
When the order is confirmed
Then points are credited at the configured points_per_dollar rate
  And if the points push them to a new tier, the tier upgrade is applied
  And a Resend email notifies them of their new points balance and tier

Given a consumer at checkout has redeemable points (above the configured minimum)
When they click "Apply points"
Then available points are shown and a redemption slider allows selection of how many to redeem
  And the discount is calculated at the configured redemption rate (e.g. 100 pts = $1)
  And the applied discount is shown in the order summary before payment
```

---

## E18 — Platform Administration

**Goal:** KloudShop internal control plane — merchant management, theme catalogue curation, Feature Catalogue management, platform operations.
**Traces to:** ADM-01–ADM-30.

### US-076 — Platform Admin Login & Dashboard
*As a KloudShop Platform Admin, I want to log in to an internal admin dashboard with MFA enforced so that I can manage the KloudShop platform securely.*

```gherkin
Given a Platform Admin navigates to the internal KloudShop admin URL
When they authenticate via Google OAuth (Gmail, MFA enforced)
Then they see the platform-wide dashboard showing:
  | Total active merchants (by tier) |
  | Total MRR |
  | Active trials |
  | Monthly churn rate |
  | Total GCP spend across all tenants |
  | Platform error rate (from Sentry) |

Given a non-admin Gmail account attempts to access the internal admin URL
Then they are rejected with HTTP 403
  And no platform data is exposed
```

### US-077 — Trial Signup Validation (Anti-Spam)
*As a KloudShop Platform Admin, I want to review and approve/reject new trial signups so that fraudulent stores do not consume GCP resources.*

```gherkin
Given a new trial signup is submitted
When the lightweight anti-spam check flags the account for review
Then a Platform Admin receives a notification (FCM + email) to review the signup
  And the GCP resource provisioning is held until approval

When the Platform Admin approves the signup
Then GCP tenant provisioning begins immediately
  And the merchant receives: "Your account is ready — here's how to get started"

When the Platform Admin rejects the signup
Then the account is marked rejected
  And the merchant receives: "Your account could not be verified. Contact support if you believe this is an error."
  And no GCP resources are provisioned
```

### US-078 — Theme Catalogue Management
*As a KloudShop Platform Admin, I want to add, edit, and publish themes to the theme catalogue so that merchants have access to new themes without any code deployment.*

```gherkin
Given a Platform Admin uploads a theme package to Cloud Storage: gs://kloudshop-themes/{theme_id}/
When they INSERT a row into the themes table with status: "draft"
Then the theme is visible only in the internal admin preview — not in the merchant theme library

When the Platform Admin previews the theme with sample merchant data
  And the theme renders correctly across mobile/tablet/desktop viewports
  And they set status: "published"
Then the theme immediately appears in the merchant theme library
  And zero code changes or deployments are required

When a Platform Admin deprecates a theme
Then it is hidden from the merchant theme library for new selections
  And merchants already using the theme continue to render it without interruption
  And the theme is supported for 2 major schema versions before sunset
```

### US-079 — Feature Catalogue Management
*As a KloudShop Platform Admin, I want to add and manage Feature Catalogue items so that new features can be made available to merchants without platform redeployment.*

```gherkin
Given a Platform Admin adds a new feature to feature_registry
  And inserts its config parameters into feature_config_schema
  And its schema migration scripts into feature_migrations
When the feature is set to status: "stable"
Then it appears immediately in all merchant Feature Catalogues
  And the generic setup wizard renders the new feature's config parameters automatically
  And zero Flutter code changes are required if the feature uses only existing data_types

Given a Platform Admin adds a new component type to the Flutter theme renderer
When the component is built, the schema_version is bumped, and the update is deployed
Then theme designers can immediately add the new component to any theme.json
  And existing themes with the old schema_version continue rendering without modification
  And the new component is added to the WYSIWYG component picker for all merchants
```

### US-080 — Production Deployment Approval & Canary Management
*As a KloudShop Platform Admin, I want to approve staging-to-production deployments and monitor canary rollouts so that bad releases are caught before affecting all merchants.*

```gherkin
Given a CI/CD pipeline completes all staging gates (Playwright E2E, k6 load test, Trivy security scan)
When all gates pass
Then the Platform Admin receives a notification to approve the production promotion

When the Platform Admin approves the deployment
Then GCP Cloud Deploy begins the canary rollout: 5% of traffic → new version
  And the admin dashboard shows real-time canary metrics: error rate, p99 latency

Given the canary error rate exceeds 1% OR p99 latency exceeds 2 seconds within 10 minutes
When GCP Cloud Deploy detects the threshold breach
Then the rollout is automatically rolled back to the previous version
  And the Platform Admin receives an alert with the specific metric that triggered rollback
  And no manual intervention is required at 3am

Given the canary metrics are healthy for 10 minutes
When the auto-promotion threshold is met
Then GCP Cloud Deploy promotes the release to 100% of traffic automatically
```

---

## E19 — System & Background Processes

**Goal:** Automated platform operations — GCP provisioning, schema migrations, billing, GDPR, schema drift detection.
**Traces to:** SYS-01–SYS-17.

### US-081 — GCP Tenant Provisioning (New Merchant)
*As KloudShop, I want to automatically provision all required GCP resources for a new merchant when they sign up so that their store infrastructure is ready within the 2-minute migration window.*

```gherkin
Given a new merchant signup is approved (anti-spam validation passed)
When GCP tenant provisioning begins
Then the following resources are created in the merchant's selected primary region:
  | Cloud SQL: tenant_{tenant_id} schema created + base Alembic migrations applied |
  | Cloud Storage: tenant bucket provisioned at gs://kloudshop-{tenant_id}/ |
  | Cloud Run: tenant context warmed (readiness probe must pass before merchant is shown "store ready") |
  | Memorystore: tenant namespace allocated |
  | Firebase Auth: tenant configured with appropriate claims schema |

When all resources pass their readiness probes
Then the tenant provisioning status is set to "ready" in Firebase Realtime DB
  And the migration engine's Track B is marked complete
  And only then is the "Your store is ready" message shown to the merchant

Given any resource provisioning fails
Then Sentry receives an alert with the specific failure
  And Cloud Tasks retries with exponential backoff
  And the merchant's "Building your KloudShop store..." progress step stays active — never shows error
```

### US-082 — Feature Schema Migration Execution
*As KloudShop, I want feature schema migrations to execute asynchronously with full dependency chain resolution so that tenant databases are never in a broken state.*

```gherkin
Given a merchant activates a feature with upstream dependencies
When the dependency chain is resolved by FastAPI Features Module
Then Cloud Tasks enqueues migration jobs in the correct sequence:
  | Job 1: upstream dependency schema (if not already applied) |
  | Job 2: requested feature schema (sequenced after Job 1) |

When the Schema Migration Service (Cloud Run Job) runs a migration
Then Alembic verifies the migration has not already been applied (idempotency check)
  And applies only new migrations
  And updates tenant_migration_state on success
  And if the migration fails, it rolls back and leaves the schema in a known-good state
  And Sentry receives an alert on any failure

Given a migration job is retried (Cloud Tasks retry)
When the migration has already been applied
Then Alembic's idempotency check detects this and the job succeeds without re-applying
  And no schema corruption occurs from duplicate application
```

### US-083 — Schema Drift Detection (Nightly)
*As KloudShop, I want a nightly check to detect any schema changes made outside the Alembic migration pipeline so that unauthorised database changes are caught immediately.*

```gherkin
Given the nightly schema drift detection job runs via Cloud Tasks
When it compares the live tenant schema against Alembic's expected migration head
  And a discrepancy is found (column added manually, ORM-generated DDL, etc.)
Then Sentry receives an alert immediately
  And a Cloud Monitoring alarm fires
  And the Platform Admin is notified with the specific schema object that drifted
  And the incident is treated with the same urgency as a production incident

Given no drift is detected
Then the job completes silently with a success log entry
  And no notifications are sent
```

### US-084 — GDPR Right-to-Erasure Execution
*As KloudShop, I want to automatically execute GDPR erasure requests by anonymising customer PII while preserving order history so that we meet GDPR Article 17 obligations.*

```gherkin
Given a consumer submits a right-to-erasure request (via their account settings)
When the GDPR erasure pipeline runs automatically
Then customer PII is anonymised (NOT deleted) in the tenant schema:
  | customers.first_name → "Anonymised" |
  | customers.last_name → "User" |
  | customers.email → anonymised_{hash}@kloudshop-deleted.com |
  | customers.phone → null |
  | addresses.line1/line2/city/postcode → null |
  And order history is preserved (required for accounting/legal compliance) with PII nulled
  And Firebase Auth account is deleted
  And PostHog user profile is deleted

When the erasure completes
Then the consumer receives a Resend confirmation email
  And the erasure event is logged with timestamp for GDPR audit purposes
  And a Platform Admin can view the erasure request queue to confirm automated execution
```

---

---

## E20 — Shipping & Courier Integration

**Goal:** Give merchants native carrier integrations for real-time shipping rates, delivery estimates, label generation, and multi-item order consolidation — so consumers see accurate shipping costs at checkout and merchants fulfil efficiently.
**Traces to:** DTC checkout pricing, B2B order fulfilment, multi-location inventory, consumer delivery experience.

### US-085 — Platform-Wide Carrier Configuration
*As a KloudShop Platform Admin, I want to maintain a catalogue of globally available shipping carriers so that merchants can connect the carriers available in their region.*

```gherkin
Given a Platform Admin manages the carrier catalogue
When they add a carrier (e.g. FedEx, DHL, UPS, Royal Mail, Australia Post, DHL Express)
Then the carrier is available for merchants to connect in their Shipping Settings
  And each carrier entry includes: carrier name, supported regions, integration type (API / webhook), logo

Given a carrier API changes its authentication method or endpoint structure
When the Platform Admin updates the carrier integration
Then all connected merchants benefit from the update automatically
  And no merchant action is required
```

### US-086 — Merchant Carrier Account Connection
*As a merchant, I want to connect my own carrier accounts (FedEx, DHL, UPS, etc.) to KloudShop so that my negotiated rates are used at checkout rather than retail rates.*

```gherkin
Given a merchant navigates to Settings → Shipping → Carriers
When they select a carrier and click "Connect"
Then they are prompted for their carrier account credentials:
  | FedEx: Account Number + API key |
  | DHL: Account Number + API key |
  | UPS: Account Number + OAuth credentials |
  | Royal Mail: OBA account number + API key |
  And credentials are validated against the carrier API before saving
  And stored in GCP Secret Manager — never in application database

Given a merchant's carrier credentials fail validation
Then a specific error is shown: "We couldn't connect to FedEx with these credentials. Check your account number and API key."
  And no partial credentials are saved

Given a merchant has no carrier account
Then KloudShop-negotiated platform rates are offered as a fallback
  And the merchant is shown estimated savings from connecting their own account
```

### US-087 — Merchant Checkout Carrier Configuration
*As a merchant, I want to control which carriers and service levels appear at my checkout so that consumers only see shipping options I have approved and priced correctly.*

```gherkin
Given a merchant has connected one or more carrier accounts
When they open Settings → Shipping → Checkout Options
Then they see all available carriers and their service levels
  And they can enable or disable each service level per carrier:
    | FedEx: Ground ✓ | Express Saver ✓ | Priority Overnight ✗ |
    | DHL: Express ✓ | Economy ✓ |
  And disabled service levels never appear at checkout regardless of carrier availability

When a merchant enables a service level
Then they can optionally configure a handling markup on top of carrier rate:
  | "Add $X flat handling fee" |
  | "Add X% on top of carrier rate" |
  | "No markup — pass through carrier rate exactly" |
  And markup is applied silently — consumers see only the final shipping price

Given a merchant wants to restrict shipping to specific destination countries
When they configure country restrictions per carrier/service level
Then consumers with addresses outside the allowed countries do not see that option at checkout
  And at least one shipping option must always be available or checkout is blocked with:
    "We don't currently ship to your location. Contact us for options."
```

### US-088 — Product Weight & Dimension Configuration
*As a merchant, I want to configure weight and dimensions for each product and variant so that carrier rate calculations are accurate at checkout.*

```gherkin
Given a merchant is editing a product
When they open the "Shipping" tab on the product form
Then they can enter per-product shipping attributes:
  | Weight (in kg or lb — unit set in store preferences) |
  | Dimensions: length × width × height (in cm or inches) |
  | "Ships in own packaging" toggle — for bulky or irregularly shaped items |

Given a merchant has a product with variants that differ significantly in weight
  (e.g. small / medium / large sizes of an industrial component)
When they configure shipping attributes
Then weight and dimensions can be set independently per variant
  And the per-variant weight overrides the product-level weight for rate calculation

Given a merchant has not set weight on a product
When a consumer adds that product to their cart
Then KloudShop uses the merchant's configured default package weight (set in Shipping Settings)
  And a warning badge is shown on the product in the admin: "Missing weight — using default"

Given a merchant configures default packaging presets in Shipping Settings
  (e.g. "Small box: 20×15×10cm 0.5kg", "Large box: 40×30×25cm 2kg")
When shipping rates are calculated for a cart
Then KloudShop selects the most appropriate preset that fits the consolidated cart dimensions
  And uses that preset's dimensions for carrier rate queries
  And the merchant can view which preset was selected per order in the order detail
```

### US-089 — Shipping Rate Calculation at Checkout
*As a DTC consumer, I want to see accurate real-time shipping costs calculated from my cart contents and delivery address so that I am not surprised by shipping charges after payment.*

```gherkin
Given a consumer enters their shipping address at checkout
When the address is confirmed
Then KloudShop assembles the shipment payload for rate calculation:
  | Total weight: sum of all item weights in cart |
  | Package dimensions: calculated from item dimension configs or merchant default box sizes |
  | Origin: the fulfilment location assigned to these items |
  | Destination: consumer's confirmed shipping address |
  And KloudShop queries all merchant-enabled carriers simultaneously in parallel
  And rates are returned for each enabled service level with:
    | Carrier name and service level (e.g. FedEx Ground, FedEx 2Day, DHL Express) |
    | Total shipping price (carrier rate + any merchant handling markup) |
    | Estimated delivery date range (e.g. "Arrives Wed 25 – Fri 27 Nov") |
  And for each service level the response includes:
    | Carrier name + service level name |
    | Total shipping price (carrier rate + handling markup) |
    | Estimated delivery date — specific date if carrier API provides it,
      calculated date range if only transit days are returned:
      estimated_arrival = today + merchant handling_days + transit_days
      + weekend/public holiday skip forward |
  And options are sorted by estimated delivery date (soonest first)
  And rates are cached in Redis: TTL 10 minutes per (cart_id + destination_postcode)

When the consumer views the shipping options
Then they see a clean list of available options presented as:
    "FedEx Ground        $8.99    Arrives Wed 25 – Fri 27 Nov"
    "FedEx 2Day         $14.99   Arrives Mon 23 Nov"
    "DHL Express        $19.99   Arrives tomorrow, Sat 22 Nov"
  And free shipping options appear first clearly labelled "Free"
  And the cheapest paid option is pre-selected by default
  And the consumer can make an informed trade-off between cost and speed
  And the consumer selects their preferred option before proceeding to payment

Given a merchant has not configured item weights for their products
When rates are calculated
Then KloudShop uses the merchant's configured default package weight
  And a warning is shown in the merchant admin: "Some products are missing weight data — shipping rates may be inaccurate"
  And checkout is never blocked — rates still calculate using defaults

Given a carrier API returns an error or times out during rate fetch
When the rate query fails for a specific carrier
Then that carrier's options are silently excluded from results for this request
  And if other carriers return rates successfully, checkout proceeds normally
  And if ALL carrier APIs fail simultaneously
  Then KloudShop falls back to the merchant's configured flat-rate shipping rules
  And the consumer is shown: "Live shipping rates temporarily unavailable — standard rate applied"
  And checkout is never blocked by carrier API issues

Given a consumer changes their shipping address after selecting a shipping option
When the new address is confirmed
Then rates are re-queried with the new destination
  And the previously selected option is cleared — consumer must re-select
  And if the previously selected carrier does not serve the new destination
  Then that option is removed from the list and consumer is notified to re-select
```

### US-090 — Multi-Item Shipping Consolidation
*As a DTC consumer, I want multiple items in my cart to be intelligently consolidated into the fewest possible shipments so that I pay the least shipping for the most practical delivery combination.*

```gherkin
Given a consumer has multiple items in their cart
  And all items are fulfilled from the same stock location
When shipping rates are calculated
Then all items are consolidated into a single shipment payload:
  | Total weight = sum of all item weights |
  | Combined dimensions calculated using the merchant's configured packing logic |
  And a single set of carrier options is shown — never per-item shipping
  And the consumer sees: "All 4 items ship together"

Given a consumer has items in their cart fulfilled from different stock locations
  (e.g. 2 items from Warehouse A, 1 item from Store NYC)
When shipping rates are calculated
Then KloudShop calculates separate shipment payloads per fulfilment location
  And queries carrier rates independently per location
  And the consumer sees a consolidated checkout breakdown:
    | Shipment 1: "Widget Pro × 2, Bolt M8 × 1 — from Warehouse A" |
    |   Options: FedEx Ground $8.99 (arrives Fri) | FedEx 2Day $14.99 (arrives Wed) |
    | Shipment 2: "Display Stand × 1 — from Store NYC" |
    |   Options: UPS Ground $6.99 (arrives Thu) | UPS Next Day $18.99 (arrives Tue) |
  And the consumer selects a service level independently per shipment
  And the total shipping charge shown is the sum of all selected options
  And the order is placed as a single order with multiple fulfilment records

Given a consumer has a free shipping threshold that is met by the total cart value
When the threshold applies to all items regardless of fulfilment location
Then free shipping is applied to all shipments
When the threshold only applies to a single fulfilment location's items
Then free shipping is applied only to that shipment
  And the other shipment(s) show standard rates
  And the checkout clearly labels which shipment qualifies for free shipping

Given a merchant has configured "always ship from a single location where possible"
  And all items in the cart are in stock at one location
When rates are calculated
Then all items are routed to that single location regardless of their primary stock location
  And a single shipment is shown — the consumer never sees a split shipment for a fulfillable single-location order

Given a consumer's cart contains a mix of physical and digital products
When shipping is calculated
Then digital products are excluded from the shipment payload entirely
  And shipping is calculated only for physical items
  And digital items are delivered via email/download link — never shown as a shipment
```

### US-091 — Shipping Label Generation
*As a merchant, I want to generate shipping labels directly from a fulfilled order so that I can print and dispatch without leaving KloudShop.*

```gherkin
Given a merchant marks an order as ready to fulfil
When they click "Generate shipping label"
Then KloudShop calls the selected carrier API to create a shipment
  And a printable label (PDF) is generated and available for download
  And the tracking number is automatically populated in the order record
  And the consumer is automatically notified with the tracking number (US-092 flow)

Given a label generation request fails (carrier API error)
Then the merchant sees a specific error from the carrier
  And they can retry or manually enter a tracking number
  And the order fulfilment is never blocked — manual entry is always available
```

### US-092 — Manual Shipping (Local Courier / Post Office Fallback)
*As a merchant where no integrated carrier API is available or practical, I want to manually record shipment details and tracking numbers so that customers are still notified and orders are properly fulfilled.*

```gherkin
Given a merchant is ready to fulfil an order
  And no carrier API integration is connected to their account
  Or the merchant chooses to ship manually regardless of integrations
When they open the order and click "Fulfil manually"
Then they are presented with a manual fulfilment form:
  | Carrier name field — free text (e.g. "Pakistan Post", "Correos", "La Poste", "local courier") |
  | Tracking number field — free text |
  | Estimated delivery date — optional date picker |
  | Shipping note to customer — optional free text |
  And there is no requirement to use an integrated carrier

When the merchant ships the physical item (e.g. visits local post office)
  And returns to KloudShop with the tracking number
  And fills in the manual fulfilment form and clicks "Mark as fulfilled"
Then the order status updates to "Fulfilled"
  And the fulfilment timestamp is recorded
  And if a tracking number was entered:
    | The tracking number and carrier name are stored on the order |
    | A Resend email is sent to the consumer with tracking details |
    | If the carrier is a major integrated carrier (FedEx, DHL, UPS, etc.) a tracking link is generated |
    | If the carrier is unrecognised, the tracking number is shown as plain text with no link |
  And if no tracking number was entered:
    | The order is marked fulfilled with a note: "Shipped — tracking not available" |
    | The consumer is notified that their order has been dispatched |

Given a merchant enters a tracking number and later receives the actual number from the courier
When they edit the tracking number on an already-fulfilled order
Then the updated tracking number is saved
  And the consumer receives a new notification with the corrected tracking details

Given a merchant uses the same local carrier repeatedly (e.g. "Pakistan Post")
When they fulfil a second order manually
Then the carrier name field pre-populates with their most recently used manual carrier
  And they can change it or accept the suggestion

Given a merchant operates in a region where integrated carriers are unavailable
When they view the Shipping Settings page
Then a clear section is shown: "Ship manually — no carrier account needed"
  And manual fulfilment is always available regardless of carrier connections
  And it is presented as a first-class option, not a fallback buried in settings
```

### US-093 — Free Shipping Rules
*As a merchant, I want to configure free shipping thresholds and rules so that I can offer free shipping as a promotional tool.*

```gherkin
Given a merchant configures a free shipping rule:
  "Free standard shipping on orders over $75"
When a consumer's cart total exceeds $75
Then the qualifying shipping option shows as "$0.00 — Free Shipping"
  And a progress indicator in the cart shows: "Add $X more for free shipping" when below threshold

Given a merchant configures a rule: "Free shipping to US only on orders over $50"
When a consumer with a non-US address reaches checkout
Then free shipping does not apply
  And standard rates are shown for their address
```

### US-094 — B2B Shipping & Delivery Configuration
*As a merchant, I want to configure shipping options for B2B orders separately from DTC orders so that wholesale buyers have appropriate delivery terms.*

```gherkin
Given a B2B buyer places an order
When shipping is calculated
Then B2B-specific shipping rules apply:
  | Flat-rate freight for pallet-sized orders |
  | "Buyer arranges own collection" option |
  | Carrier account billing to buyer's account (third-party billing) |
  And standard DTC rates are never shown to authenticated B2B buyers

Given a B2B order is configured for "buyer arranges collection"
When the order is confirmed
Then no shipping charge is applied
  And the merchant receives a notification to prepare the order for collection
  And collection reference/instructions are included in the order confirmation email
```

---


---

## E21 — Multilingual Storefront & Admin (LTR Languages)

**Goal:** Every KloudShop storefront and merchant admin supports a defined set of LTR languages from day one, with AI-powered auto-translation eliminating manual copy-paste across languages.
**Traces to:** M-53b–M-53f, product brief multilingual constraint, i18n architecture.

### US-095 — Merchant Language Settings & Locale Management
*As a merchant, I want to enable specific languages on my storefront so that customers browsing in their native language see translated content automatically.*

```gherkin
Given a merchant opens Settings → Language & Translation
When the page loads
Then they see all supported LTR locales with enable/disable toggles:
  | English (en) — always enabled, cannot be disabled — base language |
  | German (de), French (fr), Swedish (sv), Norwegian (no), Danish (da) |
  | Dutch (nl), Spanish (es), Portuguese (pt), Italian (it) |

When a merchant enables a new locale (e.g. German)
Then a Cloud Tasks job is enqueued to auto-translate all existing:
  | Product titles, descriptions, and slugs |
  | Collection titles, descriptions, and slugs |
  | Storefront content slots (hero headings, CTA labels, banner copy, etc.) |
  | SEO meta titles and meta descriptions |
  Using Google Cloud Translation API (GCP-native, pass-through billable)
  And translations are stored with is_auto_translated = TRUE
  And the merchant is notified when translation is complete:
    "German translations ready — X items translated. Review them in Translation Centre."
  And the locale becomes active on the storefront immediately
  And the Google Translation API cost appears as a pass-through line item on their bill

When a merchant disables a locale
Then that locale's URLs return 404 with a redirect to the English equivalent
  And all translated content is preserved in the database — not deleted
  And re-enabling the locale restores all previously translated content instantly
```

### US-096 — AI Auto-Translation of Product Content
*As a merchant, I want product titles, descriptions, and SEO metadata to be automatically translated when I save English content so that I never need to manually paste content in multiple languages.*

```gherkin
Given a merchant saves an English product title and description
When the save completes
Then Cloud Tasks enqueues a translation job for all merchant-enabled locales
  And Google Cloud Translation API translates the content to each enabled locale
  And translations are stored in product_translations with is_auto_translated = TRUE
  And a "Review translations" badge appears on the product in the admin

Given a merchant opens a product in edit mode with auto-translations present
When they click "Review translations"
Then they see a side-by-side panel for each enabled locale:
  | Left: English original |
  | Right: auto-translated version (editable) |
  And a "Looks good ✓" button marks the translation as reviewed (is_auto_translated = FALSE)
  And an "Edit" option allows the merchant to correct the translation inline
  And a "Re-translate" option regenerates the AI translation discarding their edits

Given a merchant edits the English product description after translations exist
When they save the English version
Then all existing auto-translated versions are automatically flagged as stale:
  | "Translation may be outdated — source content changed" |
  And a re-translation job is enqueued for all enabled locales
  And merchant-reviewed translations (is_auto_translated = FALSE) are NOT
    automatically overwritten — only flagged for merchant review

Given a merchant prefers to write translations manually for a specific locale
When they enter content directly in the translation panel and save
Then is_auto_translated is set to FALSE for that locale
  And KloudShop never overwrites merchant-authored translations with AI output
```

### US-097 — Multilingual Storefront Rendering
*As a consumer, I want to browse a KloudShop storefront in my preferred language so that I can read product information without switching to a separate site.*

```gherkin
Given a consumer navigates to acmeco.kloudshop.biz with browser language set to German
When the storefront loads
Then KloudShop detects the Accept-Language header
  And if German (de) is an enabled locale for this merchant
  Then the consumer is redirected to acmeco.kloudshop.biz/de/
  And all product titles, descriptions, navigation, and CTA labels render in German
  And SEO meta tags render in German
  And hreflang tags are present in <head> for all enabled locales

Given a consumer navigates directly to acmeco.kloudshop.biz/de/products/widget-pro
When the page loads
Then the product renders fully in German — title, description, slug, meta tags
  And if a German translation is absent for any field
  Then the English fallback renders — never a blank field

Given a consumer switches language using the storefront language selector
When they select French
Then they are navigated to the /fr/ equivalent URL
  And their language preference is stored in a cookie for future visits
  And the entire storefront re-renders in French without a full page reload

Given a merchant has only enabled English
When any consumer visits the storefront
Then no language selector is shown — single language mode
  And no locale-prefixed URLs are generated
  And hreflang tags are not generated (single language, no alternate pages)
```

### US-098 — Merchant Admin UI Language
*As a merchant, I want to use the KloudShop admin in my preferred language so that I can manage my store without reading English.*

```gherkin
Given a merchant sets their preferred admin language in account preferences
When they navigate to any admin screen
Then all UI labels, buttons, error messages, and navigation items render
  in their selected language
  And date formats, number formats, and currency formats follow the locale convention:
    | de: 1.234,56 € — period thousands, comma decimal |
    | fr: 1 234,56 € — space thousands, comma decimal |
    | en: $1,234.56 — comma thousands, period decimal |

Given a merchant switches their admin language preference
When the change is saved
Then the admin re-renders immediately in the new language
  And no page reload is required (Flutter reactive localisation)
  And the merchant's data (product names, order details) is unaffected —
    only the UI chrome changes language
```

---

## E22 — Native Blog

**Goal:** Give every merchant a native, SEO-first blog at their storefront domain — rich-text editing, post scheduling, categories, AI auto-translation to all enabled locales, JSON-LD Article structured data, and XML sitemap inclusion — with no third-party blogging platform required.
**Traces to:** M-53g–M-53n, C-32–C-33, SEO-first storefront architecture, multilingual i18n pipeline.

### US-099 — Blog Post Creation, Editing & Publishing
*As a merchant with Store Manager or Marketing Manager role, I want to create, edit, schedule, and publish blog posts from the KloudShop admin so that my store builds organic search traffic without needing a separate blogging platform.*

```gherkin
Given a merchant navigates to Content → Blog in their admin
When the Blog section loads
Then they see a list of all blog posts with status badges:
  | Draft | Scheduled | Published | Archived |
  And a "+ New post" CTA is shown

When a merchant clicks "+ New post"
Then a blog post editor opens with:
  | Title field (plain text, required) |
  | Rich-text body editor (bold, italic, links, headings H2–H4,
    bullet lists, numbered lists, blockquote, inline images) |
  | Featured image upload (Cloud Storage — same pattern as product images) |
  | Categories selector (multi-select from existing, or create new inline) |
  | Tags input (comma-separated free text) |
  | SEO panel (collapsible): meta title, meta description, URL slug |
  | Publish options: [ Publish now ] [ Schedule ] [ Save as draft ] |

When a merchant fills in the title and body and clicks "Publish now"
Then the post is saved to the `blog_posts` table with status: "published",
    published_at: NOW()
  And the URL slug is auto-generated from the title if not manually entered
    (e.g. "My Top 5 Tips" → "my-top-5-tips")
  And the slug is validated as unique within this tenant's blog
  And the XML sitemap regeneration is queued via Cloud Tasks
  And a Cloud Tasks job is enqueued to auto-translate the post to all
    merchant-enabled locales via Google Cloud Translation API
  And the post is immediately live at:
    storename.kloudshop.biz/blog/{slug}
  And the blog index at storename.kloudshop.biz/blog updates to include it

When a merchant clicks "Schedule" and selects a future date and time
Then the post is saved with status: "scheduled", scheduled_for: {datetime}
  And a Cloud Tasks job is created to flip status to "published"
    at exactly the scheduled datetime
  And the post does not appear on the storefront until that moment
  And the merchant can edit or cancel the scheduled post at any time before it publishes

When a merchant clicks "Save as draft"
Then the post is saved with status: "draft"
  And it does not appear on the storefront or in the sitemap
  And the merchant can return to it at any time from the blog post list

Given a merchant edits an already-published post
When they save changes
Then the post updates immediately on the storefront
  And if the slug is changed, a 301 redirect is automatically created
    from the old slug to the new slug
  And all existing AI-translated versions are flagged as stale:
    "Translation may be outdated — source content changed"
  And a re-translation job is enqueued for all enabled locales
  And merchant-reviewed translations are NOT auto-overwritten — only flagged

Given a merchant clicks "Preview" on a draft or scheduled post
When the preview loads
Then the post renders exactly as it will appear on the live storefront
  And the preview is accessible only to authenticated admin users —
    never publicly accessible before publishing

Given a merchant unpublishes a post
When they set status to "archived"
Then the post is removed from the storefront and sitemap immediately
  And the URL returns 410 Gone (not 404) — signals intentional removal to Google
  And the post content is preserved in the database — never deleted

Given a merchant manages blog categories
When they open Blog → Categories
Then they can: create a new category with name and optional description,
  rename an existing category, merge two categories (reassigns all posts),
  delete an empty category (blocked if posts are assigned to it)
  And category pages are generated at:
    storename.kloudshop.biz/blog/category/{category-slug}
  And category pages are included in the XML sitemap
```

### US-100 — Blog Post Consumer-Facing Rendering
*As a DTC consumer, I want to read blog posts on a merchant's storefront so that I can discover products through content and trust the merchant's expertise.*

```gherkin
Given a consumer navigates to storename.kloudshop.biz/blog
When the blog index page loads
Then it is server-side rendered by the FastAPI SSR service
  And it shows all published posts in reverse chronological order
  And each post card shows: featured image, title, publish date,
    excerpt (first 160 characters of body), category badge
  And the page includes correct meta title, meta description,
    and canonical tag
  And if the merchant has enabled multiple locales, hreflang tags
    are present for all published translations of each post

When a consumer clicks a post card
Then they navigate to storename.kloudshop.biz/blog/{slug}
  And the full post renders with: featured image, title, author name,
    publish date, body (full rich text), categories, tags
  And JSON-LD Article structured data is present in the <head>:
    | @type: Article |
    | headline: post title |
    | datePublished: published_at |
    | dateModified: updated_at |
    | author: { @type: Person, name: author display name } |
    | image: featured_image_url |
    | publisher: { @type: Organization, name: merchant brand name } |
  And the page has a correct canonical tag
  And Core Web Vitals targets apply: LCP < 2.5s, CLS < 0.1

Given a consumer browses the blog with browser language set to German
  And the merchant has enabled German (de) locale
  And a German translation exists for this post
When the blog index or post page loads
Then the German translation renders at:
    storename.kloudshop.biz/de/blog/{german-slug}
  And hreflang tags point to all available locale versions of this post
  And if no German translation exists, English renders as fallback —
    never a blank page or 404

Given a consumer reads a blog post that references products
When the merchant has embedded product links or CTA blocks in the post body
Then clicking a product link navigates directly to that product's PDP
  And the blog post contributes to the consumer's browsing session context
    for AI consultative layer personalisation

Given a consumer searches the storefront using the search bar
  And types a query that matches a blog post title or body
When search results are returned
Then matching blog posts appear in results alongside products
  And blog results are visually distinguished from product results
    (e.g. "Article" label vs "Product" label)
  And PostgreSQL FTS queries both the products table and blog_posts table
    in a single unified search endpoint
```

---

## E23 — AI Copywriter

**Goal:** Give every merchant a free AI marketing strategist — one-click Gemini-powered generation of high-converting product titles, product descriptions, and blog content, grounded in their Brand Voice profile. Three strategically differentiated variants per request, all editable before acceptance.
**Traces to:** M-45p–M-45r, M-53o–M-53p, Vertex AI / Gemini stack, GCP pass-through billing, DMF-12.

### US-101 — Brand Voice Profile Setup
*As a merchant Owner or Store Manager, I want to configure a Brand Voice profile for my storefront so that all AI-generated copy sounds like my brand and not a generic AI.*

```gherkin
Given a merchant navigates to Settings → Brand Voice
When the profile editor loads
Then they see five independent fields — all optional:
  | Tone of voice — dropdown: Authoritative / Playful / Luxurious / Technical /
    Conversational / Inspirational / Professional / Friendly |
  | Target audience — free text, max 300 chars,
    placeholder: "e.g. procurement managers at mid-size UK manufacturers" |
  | Brand adjectives — tag input, 1–5 words,
    placeholder: "e.g. bold, minimal, premium" |
  | Writing style rules — free text, max 500 chars,
    placeholder: "e.g. Never use exclamation marks. Always lead with benefits." |
  | Brands to NOT sound like — tag input, max 5 entries,
    placeholder: "e.g. ASOS, Primark" |
  And a live preview panel shows a sample AI-generated product description
    using the current profile settings, updating within 3 seconds of any field change
  And an explanatory note: "The more you fill in, the more your copy will sound like you.
    You can use AI Copywriter with no profile — we'll use proven high-converting
    copy principles as the default."

When the merchant saves the profile
Then brand_voice fields are written to the brand_profiles row for this brand_profile_id
  And brand_voice_configured_at and brand_voice_configured_by are set
  And all subsequent AI Copywriter calls for this brand use the updated profile immediately
  And no re-activation or cache flush is required — effective on next generation call

Given a Hybrid merchant opens Settings → Brand Voice
When the profile editor loads
Then a storefront selector is shown: [ DTC Storefront ] [ B2B Portal ]
  And each has a fully independent Brand Voice profile
  And switching between them loads the respective brand_profile_id's settings
  And DTC defaults might be "playful, aspirational" while B2B defaults might be
    "technical, authoritative" — independent by design

Given a merchant has no Brand Voice profile configured
When they use the AI Copywriter
Then generation runs using the generic high-converting prompt
  And a subtle note appears below the generated variants:
    "💡 Set up your Brand Voice profile to get copy that sounds like your brand"
  And the note links to Settings → Brand Voice
  And the AI Copywriter is never blocked by absence of a Brand Voice profile
```

### US-102 — AI Product Title Enhancement
*As a merchant, I want to generate three AI-enhanced variants of a product title so that my product pages have high-converting, SEO-aware titles without hiring a copywriter.*

```gherkin
Given a merchant is editing a product in the product editor
When they click the "✨ Enhance with AI" button adjacent to the Title field
Then FastAPI Copywriter Module assembles the prompt server-side using:
  | Current product title (if any) |
  | Product category |
  | Key variant attributes (material, size, specification) |
  | Brand Voice profile for this brand_profile_id |
  And fires a single Gemini structured output call requesting 3 title variants
  And a loading state is shown on the button: "Generating..."
  And the product form remains fully interactive during generation

When Gemini returns
Then three title variants are shown in an overlay panel below the title field:
  | Variant 1 — Benefit-led (labelled) |
  | Variant 2 — Problem-solution (labelled) |
  | Variant 3 — Authority / specification (labelled) |
  And each variant has two actions: [ ✓ Use this ] [ Edit then use ]
  And a [ × Discard all ] option closes the panel without changing the title

When a merchant clicks "✓ Use this" on a variant
Then the title field updates with the selected variant text
  And the overlay closes
  And the previous title is held in undo history (Ctrl+Z / Cmd+Z restores it)
  And ai_copywriter_log records: content_type: 'product_title', variant_accepted, was_edited: false

When a merchant clicks "Edit then use"
Then the selected variant is placed into the title field in an editable state
  And the merchant modifies it inline before saving the product
  And on save ai_copywriter_log records: was_edited: true

When a merchant clicks "× Discard all"
Then the title field is unchanged
  And ai_copywriter_log records: variant_accepted: NULL

Given the Gemini API returns an error or times out
Then the overlay shows: "Generation failed — please try again"
  And a retry button is shown
  And the title field is completely unaffected
  And no partial or malformed output is written to any field
```

### US-103 — AI Product Description Generation / Enhancement
*As a merchant, I want to generate three AI-written product description variants so that my PDPs communicate benefits persuasively without requiring copywriting skill.*

```gherkin
Given a merchant is editing a product and the description field is empty
When they click "✨ Generate with AI" on the description field
Then FastAPI assembles the prompt with:
  | Product title |
  | All variant attributes across all variants of this product |
  | Product category |
  | Brand Voice profile |
  And fires a single Gemini call for 3 description variants

Given a merchant is editing a product with an existing description
When they click "✨ Enhance with AI" on the description field
Then the existing description is included in the prompt as context
  And Gemini generates 3 enhanced variants — it does not blindly rewrite
  And the prompt instructs: "Preserve the author's key facts and product claims.
    Enhance persuasiveness, benefit clarity, and brand voice alignment."

When variants are returned
Then they are shown in a tabbed comparison panel (not a small overlay — descriptions are long):
  | Three tabs: [ Variant 1 — Benefit-led ] [ Variant 2 — Problem-solution ]
    [ Variant 3 — Authority ] |
  | Each tab shows the full generated description |
  And actions per tab: [ ✓ Use this ] [ Edit then use ] [ ↻ Regenerate this variant ]

When a merchant clicks "↻ Regenerate this variant"
Then a follow-up Gemini call regenerates only that one variant
  And the other two variants are unchanged
  And the regenerated content replaces only that tab

Given a product has rich variant data (e.g. M8, M10, M12 in stainless steel and galvanised)
When description is generated
Then the copy specifically references these attributes — never generic filler
  And the prompt enforces: "Only reference attributes explicitly provided below.
    Never invent specifications, certifications, or claims not in the source data."
  And hallucinated product claims never appear in output

Given a merchant accepts a variant and then edits it before saving the product
When the product is saved
Then ai_copywriter_log records: variant_accepted: {1|2|3}, was_edited: true
  And the final saved description is what the merchant typed — never the unedited AI output
```

### US-104 — AI Blog Post Enhancement
*As a merchant, I want to enhance a draft blog post title and body with AI so that my blog content is editorial quality and SEO-optimised without hiring a content writer.*

```gherkin
Given a merchant is editing a blog post (draft or existing published post)
When they click "✨ Enhance title" adjacent to the post title field
Then the same 3-variant title flow from US-102 runs
  And the prompt additionally receives: first 500 chars of post body + blog categories + tags
  And generated title variants are SEO-aware (primary keyword worked in naturally)
  And the flow is identical to product title enhancement — same overlay, same actions

When a merchant clicks "✨ Enhance post" in the blog body editor toolbar
Then FastAPI assembles the prompt with:
  | Full current post body |
  | Post title |
  | Blog categories and tags |
  | Target word count (inferred from current body length — minimum 300 words enforced) |
  | Brand Voice profile |
  And fires a single Gemini call for 3 full post body variants

When variants are returned
Then a full-screen comparison modal opens (blog bodies are long):
  | Three panels: [ Variant 1 — Benefit-led ] [ Variant 2 — Problem-solution ]
    [ Variant 3 — Authority ] |
  | Each panel shows the full rewritten post body with estimated read time |
  And actions per panel: [ ✓ Use this ] [ Edit then use ] [ ↻ Regenerate this variant ]
  And [ × Keep my original ] closes the modal with zero changes to the draft

Given the existing post body is substantial (> 500 words)
When enhancement is triggered
Then Gemini preserves the merchant's core message, structure, and factual claims
  And the prompt instructs: "Preserve the author's key points, facts, and structure.
    Enhance persuasiveness, readability, and SEO quality. Do not invent new claims
    or remove factual content the author has included."
  And the merchant's factual content is never hallucinated away or silently removed

Given a merchant accepts a variant and the post is in 'published' status
When they save the enhanced post
Then the post updates on the storefront immediately
  And existing AI-translated versions are flagged stale (same pattern as manual edits)
  And a re-translation job is enqueued for all enabled locales
  And ai_copywriter_log records: content_type: 'blog_body', variant_accepted, was_edited
```

---

## Out of Scope — Post-MVP Candidates

These features are fully documented in the journey inventory but are explicitly deferred. MVP/post-MVP classification will be determined in Stage 4b — MVP Scoping Gate.

| Feature Area | Reason for Potential Deferral |
|-------------|-------------------------------|
| ERP/CRM pre-built connectors (Salesforce, HubSpot, SAP) | Agreed post-MVP — Developer API + webhooks cover interim integration |
| AI regional inventory routing (multi-warehouse) | Basic multi-location is MVP; AI routing needs sufficient sales data first |
| Headless commerce API tier | Explicitly out of scope — KloudShop storefronts only |
| AI return fraud detection | Not in KloudShop feature set |
| Customer churn prediction dashboard | Valuable but not critical for first merchants |
| B2B quote request workflow | B2B approvals cover most use cases initially |
| Subscription/recurring orders | Feature Catalogue item — activatable when needed |
| Advanced bundle builder | Feature Catalogue item — activatable when needed |
| Social commerce channels (TikTok/Instagram/Facebook) | Could be MVP or post-MVP depending on merchant demand |
| AI per-customer homepage personalisation | Limited PDP/cart AI recommendations are MVP; full homepage personalisation is post-PMF |

