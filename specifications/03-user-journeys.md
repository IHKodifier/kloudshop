# User Journeys: KloudShop

> **Stage:** 3 — User Journeys
> **Persona:** FAANG-Veteran UX Designer
> **Reads from:** `01-product-brief.md`, `01b-tech-stack.md`, `02-architecture.md`
> **Approved:** [ ] pending

---

## Overview

KloudShop has four distinct user types, each with fundamentally different goals,
emotional states, and failure modes. This document maps every critical journey for
all four types — from first touch to successful outcome. Desktop web is the primary
context for merchant admin flows. Mobile is secondary but must never feel broken.
B2B buyer and DTC consumer journeys are storefront-facing and must feel as polished
as any best-in-class e-commerce experience.

**Emotional design principle:** Every journey has a moment of maximum anxiety and a
moment of maximum delight. The UX must compress the anxiety and amplify the delight.
For KloudShop, the highest-anxiety moment across all merchant journeys is the same:
*"Will this actually work the way they promised?"* Every design decision in this
document is calibrated to answer that question with a resounding yes — before the
merchant has a chance to doubt it.

---

## User Type 1 — Merchant: Onboarding + Migration from Competitor

### Journey 1A: Signup + Competitor Store Migration (The 2-Minute Win)

**User:** Mid-market merchant, currently on Shopify Plus or WooCommerce.
**Goal:** Get a fully populated KloudShop store live in under 2 minutes.
**Primary device:** Desktop web.
**Emotional baseline:** Sceptical. They've been burned by platform promises before.

---

#### Flow Map

```
STAGE 1 — DISCOVERY & SIGNUP
─────────────────────────────
Landing page
  → "Migrate from Shopify in 2 minutes" CTA
  → Signup form: email, password, account name
  → Lightweight validation (anti-spam, email verify)
  → Tier selection: DTC / B2B / Hybrid
         │
         ▼ Emotional state: cautious optimism
         │ Friction risk: tier choice confusion
         │ Design requirement: tier comparison card
         │ with plain-English "who this is for" copy.
         │ Default highlight: Hybrid tier.

STAGE 1B — GCP REGION SELECTION
──────────────────────────────────
Post-signup → Infrastructure setup screen
  "Where are most of your customers located?
   This determines where your store data lives
   and ensures the fastest experience for your buyers."

  Primary region selector (dropdown with guidance):
  ┌─────────────────────────────────────────────┐
  │  🌎 us-central1 — Iowa, USA                 │
  │     Best for: US + Canada merchants         │
  │  🌍 europe-west2 — London, UK               │
  │     Best for: UK + EU merchants (GDPR-ready)│
  │  🌏 australia-southeast1 — Sydney, AU       │
  │     Best for: Australia + NZ merchants      │
  │  🌏 asia-southeast1 — Singapore             │
  │     Best for: Southeast Asia merchants      │
  └─────────────────────────────────────────────┘
  Helper text under each option:
  "Choosing the region closest to your buyers
   reduces page load time and improves your
   Google Core Web Vitals scores."
  "GDPR note: If you sell to EU customers,
   europe-west2 keeps their data inside
   the EU by default."

  ──────────────────────────────────────────
  OPTIONAL: Secondary region for redundancy
  ──────────────────────────────────────────
  Expandable panel (collapsed by default):
  "Add a failover region (optional)"
  → Explanatory copy:
    "If your primary region experiences an outage,
     your store automatically fails over to your
     secondary region — typically within 60–120
     seconds. Your buyers experience no downtime."

  Secondary region selector:
  → Only regions different from primary shown
  → Recommended pairing shown with ★:
    us-central1 primary → ★ us-east1 (Virginia)
    europe-west2 primary → ★ europe-west4 (Netherlands)
    australia-southeast1 → ★ asia-southeast1 (Singapore)

  Cost impact banner (honest, specific):
  ┌─────────────────────────────────────────────┐
  │ 💡 Estimated cost impact of adding a        │
  │    secondary region:                        │
  │                                             │
  │  +40–60% on your monthly GCP               │
  │  infrastructure bill.                       │
  │                                             │
  │  Why? A read replica of your database runs  │
  │  in the secondary region at all times       │
  │  (your largest single cost driver). Cloud   │
  │  Run and other services scale to zero in    │
  │  the standby region and only activate       │
  │  during failover.                           │
  │                                             │
  │  Example: if your primary region costs      │
  │  0/mo in GCP resources, expect ~12–28 │
  │  with a secondary region enabled.           │
  │                                             │
  │  You can add or remove a secondary region   │
  │  at any time from your account settings.    │
  └─────────────────────────────────────────────┘

  → [ Continue without secondary region ]
  → [ Add secondary region + continue ]
  → [ Remind me before BFCM / peak season ]
    (sets a seasonal activation reminder —
     see On-Demand Activation note below)

  ──────────────────────────────────────────
  ON-DEMAND ACTIVATION — KEY FACTS
  ──────────────────────────────────────────
  Information panel (expandable, shown inline):

  "You don't have to decide now. Here's what
   you need to know about adding a secondary
   region later:"

  ✅ You can activate a secondary region at
     any time from your account settings —
     no migration, no downtime on your
     primary region.

  ⏱ Activation lead time: allow at least
     48 hours before your expected traffic
     spike. Here's why:
     • GCP takes 15–60 minutes to provision
       your secondary database replica.
     • Your existing data then syncs to the
       new region — this can take 1–4 hours
       depending on your catalog and order
       history size.
     • We run verification checks before
       marking the secondary region as
       ready for failover.
     • Total safe buffer: 48 hours gives
       you room for any unexpected delays
       without a last-minute panic.

  📅 Recommended activation windows:
     • BFCM: activate by November 23rd
       (48hrs before Black Friday)
     • Boxing Day / Christmas: activate
       by December 23rd
     • Any planned sale or campaign: activate
       48 hours before your go-live time

  💡 Smart use of on-demand secondary regions:
     Activating a secondary region only during
     peak periods (e.g. 2 weeks around BFCM)
     and deactivating afterwards can be
     significantly cheaper than running it
     year-round. You pay the +40–60% uplift
     only for the weeks it is active.

  ⚠️  What a secondary region CANNOT protect
     you from — be honest with yourself:
     "If GCP's infrastructure in your PRIMARY
      region experiences an unexpected outage,
      a secondary region will NOT save you —
      because you will not know the outage is
      coming. Failover takes 60–120 seconds
      even when it works perfectly, and an
      unplanned regional outage may not trigger
      clean automatic failover.

      What a secondary region IS great for:
      deliberately routing overflow traffic
      during peak load events you KNOW are
      coming — BFCM, Boxing Day, a planned
      viral campaign — where you activate it
      in advance and your primary region
      stays healthy but gets supplemental
      capacity. For this use case, it works
      exactly as advertised."

  → [ Continue without secondary region ]
  → [ Add secondary region now ]
  → [ Remind me 5 days before BFCM / Boxing Day ]

         │
         ▼ Emotional state: mild uncertainty
         │ ("I don't understand cloud regions")
         │ Design requirement: the region selector
         │ must lead with WHERE YOUR CUSTOMERS ARE
         │ — not technical GCP region codes.
         │ Show the friendly name first, the GCP
         │ code second in smaller text. The cost
         │ impact banner must be honest and
         │ concrete — not vague percentages.
         │ The on-demand panel must be genuinely
         │ honest about what secondary regions
         │ cannot do — merchants who feel misled
         │ on infrastructure promises churn fast.

STAGE 2 — MIGRATION ENGINE ENTRY
──────────────────────────────────
Post-signup → Migration prompt screen
  "Where is your store right now?"
  → Paste competitor store URL
  → Platform auto-detected (Shopify / WooCommerce /
    Adobe Commerce / Wix / Squarespace) —
    confirmed with platform logo badge
  → For Wix / Squarespace: advisory shown:
    "We'll import everything we can find.
     Some metadata may need a quick review
     before you go live — we'll flag it."
  → "Start Migration" CTA — single click
         │
         ▼ Emotional state: this is the moment of truth
         │ Friction risk: uncertainty about what gets scraped
         │ Design requirement: single reassurance line below
         │ CTA: "We import your products and SEO. Never
         │ your customers' personal data."

STAGE 3 — THE 2-MINUTE REVEAL
───────────────────────────────
Live progress screen (not a spinner — a narrative):
  ✓ Detecting your store platform...        [instant]
  ✓ Reading your product catalogue...       [0–15s]
  ✓ Importing 847 products + variants...    [15–45s]
  ✓ Preserving your SEO metadata...         [45–75s]
  ✓ Building your KloudShop store...        [75–105s]
  ✓ Generating your migration runbook...    [105–120s]
  → "Your store is ready." 🎉              [<2 min]
         │
         ▼ Emotional state: maximum delight target
         │ Design requirement: progress steps must feel
         │ alive — each step confirms something real was
         │ imported (show product count, image count,
         │ SEO pages found). Never an abstract spinner.

STAGE 4 — STORE REVEAL
────────────────────────
Post-scrape: two parallel tracks must BOTH complete
before the merchant sees "Your store is ready":

  Track A — Scraping + AI import (2 min target)
  ─────────────────────────────────────────────
  ✓ Products scraped and parsed
  ✓ SEO metadata mapped
  ✓ Collections structured
  ✓ KloudShop URLs generated

  Track B — GCP tenant provisioning (runs in parallel)
  ─────────────────────────────────────────────────────
  ✓ Cloud SQL tenant schema created
  ✓ Alembic base migrations applied
  ✓ Cloud Storage bucket provisioned
  ✓ Cloud Run tenant context warmed
  ✓ Memorystore namespace allocated
  ✓ Firebase Auth tenant configured

  Both tracks report progress to Firebase Realtime DB.
  The UI shows a unified progress narrative — the
  merchant never sees two separate tracks:

  ✓ Detecting your store platform...        [instant]
  ✓ Reading your product catalogue...       [0–15s]
  ✓ Importing 847 products + variants...    [15–45s]
  ✓ Preserving your SEO metadata...         [45–75s]
  ✓ Building your KloudShop store...        [75–105s]
    ↑ This step covers GCP provisioning and
      completes only when BOTH tracks are
      confirmed healthy.
  ✓ Generating your migration runbook...    [105–120s]
  → "Your store is ready." 🎉

  RACE CONDITION HANDLING:

  Scenario A — Scraping finishes, GCP still provisioning:
  → "Building your KloudShop store..." stays active
    until Cloud Run readiness probe confirms all
    resources healthy. 2-minute target extends
    gracefully. Copy changes to:
    "Almost ready — finishing your infrastructure..."
    No error state. No technical language.

  Scenario B — GCP finishes first, scraping still running:
  → Normal — scraping is the expected long pole.
    GCP resources sit warm and idle, ready to receive
    the import the moment scraping completes.

  Scenario C — GCP provisioning fails:
  → Sentry alert fired immediately.
  → Cloud Tasks retry with exponential backoff.
  → Merchant sees:
    "We hit a snag setting up your infrastructure.
     We have been notified and are fixing it now.
     Your scraped data is safe — we will pick up
     exactly where we left off."
  → FCM + email notification when resolved.
  → "Your store is ready" is NEVER shown until
    GCP readiness probe returns healthy on all
    required resources.

Post-migration dashboard (shown only when BOTH
tracks confirm healthy via readiness probe):
  → Hero banner: "847 products imported. Your store
    is live at acmeco.kloudshop.biz"
  → Live preview thumbnail of their storefront
    (rendered only after Cloud Run confirms
     storefront SSR is warm — never a broken
     iframe or a 500 error page)
  → Three action cards:
    [ View your store ]
    [ Download migration runbook ]
    [ Upload customer + order CSV ]
         │
         ▼ Emotional state: relief + excitement
         │ Design requirement: storefront preview is
         │ gated on the GCP readiness probe — it only
         │ renders when the infrastructure is confirmed
         │ healthy. "Your store is ready" is a promise
         │ that must only be made when it is
         │ literally true. One broken storefront
         │ preview destroys the 2-minute win entirely.

STAGE 5 — CSV IMPORT (Customer + Order History)
─────────────────────────────────────────────────
CSV upload screen:
  → Drag-and-drop zone for CSV / Excel files
  → Multi-file support (customers.csv + orders.csv
    can be uploaded simultaneously)
  → On upload: AI parser analyses file structure
  → Preview table: "Here's what we found"
    ┌──────────────┬───────────┬──────────────┐
    │ Column found │ Maps to   │ Confidence   │
    ├──────────────┼───────────┼──────────────┤
    │ "Email addr" │ email     │ ✓ High       │
    │ "Order #"    │ order_id  │ ✓ High       │
    │ "Amt"        │ order_val │ ⚠ Review     │
    └──────────────┴───────────┴──────────────┘
  → Merchant corrects any ⚠ mappings inline
  → "Import 2,341 customers + 18,472 orders" CTA
         │
         ▼ Emotional state: mild anxiety (data fidelity)
         │ Design requirement: the preview table is the
         │ anxiety antidote. Show them their data mapped
         │ correctly BEFORE they commit. Errors are
         │ surfaced as "review" — never as failures.

STAGE 6 — MIGRATION RUNBOOK HANDOFF
─────────────────────────────────────
Runbook screen (also delivered via email):
  Personalised step-by-step plan:
  Step 1: Point your DNS to KloudShop [with exact
          DNS records pre-filled for their domain]
  Step 2: 301 redirects [auto-generated redirect
          map from old URLs to new KloudShop URLs]
  Step 3: SEO verification checklist
  Step 4: Payment gateway reconnection guide
  Step 5: Staff account setup guide
  Step 6: Go-live checklist
  → "Download as PDF" + "Email to my team" buttons
         │
         ▼ Emotional state: confidence + readiness
         │ Design requirement: runbook must feel
         │ personalised, not generic. Merchant's store
         │ name, domain, and platform appear throughout.
         │ No step says "contact your developer."
```

#### Screen Inventory — Journey 1A

| Screen | Purpose | Key Action |
|--------|---------|-----------|
| Landing page | Acquisition | "Migrate in 2 minutes" CTA |
| Signup | Account creation | Email + password + tier selection |
| Migration entry | URL input | Paste competitor store URL |
| Migration progress | 2-minute reveal | Live narrative progress steps |
| Store reveal dashboard | First delight moment | View store + download runbook |
| CSV upload | Data import | Drag-drop + AI mapping preview |
| Migration runbook | Go-live confidence | Download PDF + email to team |

---

### Journey 1B: Brand Setup + Theme Selection

**User:** Merchant who has completed migration or is setting up a fresh store.
**Goal:** Make the storefront feel like their brand, not a template.
**Primary device:** Desktop web.

```
Brand setup wizard (post-migration or on first login):
  Step 1 — Brand identity
    → Store name (DTC brand — independent of account name)
    → Upload logo (drag-drop, auto-cropped to sizes)
    → Choose primary + secondary brand colours
      (colour picker + hex input)
    → Upload favicon
    [Hybrid tier: repeat for B2B brand identity]

  Step 2 — Theme selection
    → Theme library grid (filterable by sector:
      fashion / industrial / food & beverage / etc.)
    → Live preview: merchant's actual imported products
      render inside the theme — not placeholder content
    → "Apply theme" — one click, zero downtime

  Step 3 — Content entry (new slots)
    → WYSIWYG opens automatically after theme applied
    → Any component instances with empty content slots
      are highlighted with a prompt:
      "Add your headline", "Add your hero image", etc.
    → Merchant fills in content slot by slot
    → Each slot the merchant fills is saved as a new
      storefront_content row — persisted permanently.
      New theme slots are NOT ephemeral — they are stored
      identically to all pre-existing content slots.
    → Products, collections, SEO metadata already
      populated from migration — not re-entered here
    → For fresh stores (no migration): all slots
      shown empty with placeholder copy to guide entry

  Step 4 — Storefront live check
    → Auto-opens storefront preview in new tab
    → "Looks good? Go live" CTA
    → Or: "Choose a different theme" — back to Step 2
    → Or: "Keep customising" — back to WYSIWYG
```

**Critical design requirement:** The theme preview must use the merchant's real
imported products, their real logo, and their real brand colours — not Lorem Ipsum.
A merchant who sees their own brand inside a beautiful theme is sold. A merchant
who sees a generic demo is not.

---


---

### Journey 1B-Extended: WYSIWYG Theme Customisation

**User:** Merchant who has applied a base theme (via Journey 1B) and wants to
customise component order, add repeated components, or adjust visual parameters.
**Goal:** Make the storefront layout and appearance uniquely theirs — beyond what
the base theme provides — without writing code or JSON.
**Primary device:** Desktop web.
**Entry point:** "Customise theme" button on storefront dashboard or from
the Theme Catalogue after applying a theme.

```
ENTRY
──────
Merchant clicks "Customise theme"
  → WYSIWYG editor opens
  → Three-panel layout loads:
    LEFT:   Component stack (current active components)
    CENTRE: Live storefront preview (actual renderer)
    RIGHT:  Config panel (empty until component selected)

LEFT PANEL — COMPONENT STACK
──────────────────────────────
  Current component stack shows all active instances:
  [ ≡ ] App Bar             ← scaffold (always present)
  [ ≡ ] Nav Bar             ← scaffold (always present)
  ──── scrollable body ────
  [ ≡ ] Video Hero
  [ ≡ ] Men's Apparel Strip ← horizontal_scroll_strip
  [ ≡ ] Product Grid
  [ ≡ ] AI Panel
  [ ≡ ] Reviews
  ──── scaffold ────────────
  [ ≡ ] Footer              ← scaffold (always present)

  Actions:
  → Drag handles [ ≡ ] to reorder body components
  → [ + Add component ] button opens component picker:
      Component picker shows all available types:
      video_hero / hero_banner / carousel /
      cta_block / featured_collections /
      product_grid / horizontal_scroll_strip /
      reviews_strip / announcement_bar /
      shoppable_video / divider
      Each shows a thumbnail + description.
      Merchant selects type → new instance added
      with auto-generated ID and default config.
  → [ × ] to remove a component instance
    (confirmation: "Remove Kids' Apparel Strip?")

CENTRE PANEL — LIVE PREVIEW
─────────────────────────────
  The actual StorefrontRenderer widget runs here.
  Any change in LEFT or RIGHT panels triggers
  an immediate re-render — no save required to preview.

  Viewport toggle (top of panel):
  [ 📱 Mobile ] [ 📟 Tablet ] [ 🖥 Desktop ]

  Merchant sees exactly what their customers will see.

RIGHT PANEL — COMPONENT CONFIG + CONTENT
──────────────────────────────────────────
  Clicking any component in LEFT panel opens its config.
  Right panel has two tabs:

  [ Config ] — visual + structural parameters
  [ Content ] — text and media for this component

  "Content" tab example — hero_main selected:
    Heading:      [The Best Skin Serums For Healthy Glow  ]
                  (short_text, 80 chars max)
    Subheading:   [Reveal Your Natural Glow with The Best...]
                  (long_text, 300 chars max)
    CTA Label:    [Shop Now                               ]
                  (short_text, 30 chars max)
    CTA URL:      [/collections/serums                    ]
    Background:   [ Upload image ↑ ] or [ Choose from library ]

  "Config" tab example — horizontal_scroll_strip selected:
    Instance name: [Men's Apparel Strip]
    Collection:    [Men's Collection ▾] (dropdown)
    Card height:   [280] px
    Border colour: [#2A2A4E ■]
    Border width:  [1.0] dp
    Border radius: [8] dp
    Elevation:     [2.0]
    On-hover bg:   [#1E1E3E ■]
    On-hover elev: [6.0]
    ── Animations ──
    Enter:         [Fade Up ▾]
    Enter duration:[400] ms
    Enter delay:   [80] ms
    Hover effect:  [Scale Up ▾]
    Scale factor:  [1.04]
    Hover duration:[150] ms

  Example — scaffold app_bar selected:
    Logo position: [Left ▾]
    Show search:   [✓]
    Show cart:     [✓]
    Announcement:  [Free shipping on orders over $50]
    Background:    [#1A1A2E ■]
    Sticky:        [✓]

  Design token overrides (at bottom of right panel):
  → "Override global colour tokens for this theme"
    Primary:  [#1A1A2E ■]
    Accent:   [#E94560 ■]
    Text:     [#FFFFFF ■]
    (changes apply to entire storefront)

SAVING
───────
  → [ Save changes ] — serialises in-memory state
    to theme.json, uploads to Cloud Storage,
    invalidates Redis cache for this tenant.
    Storefront reflects changes on next page load.
    (≤ 1 hour cache refresh, or instant if
     merchant manually refreshes their store)

  → [ Discard changes ] — reverts to last saved
    theme.json. Requires confirmation if unsaved
    changes exist.

  → [ Reset to base theme ] — reverts all
    customisations to the original theme defaults.
    Requires confirmation. Cannot be undone.

EMOTIONAL STATE: Creative + exploratory. Low anxiety
(live preview removes fear of "breaking" the store —
 nothing is committed until Save is clicked).

DESIGN REQUIREMENTS:
  → Live preview must re-render within 300ms of
    any config change — lag breaks the direct
    manipulation illusion
  → Component picker thumbnails must show real
    rendered examples, not abstract icons
  → No component type should be labelled with
    a technical ID (show "Product Grid", not
    "product_grid")
  → Scaffold components (app_bar, nav_bar, footer)
    are always shown in the stack but visually
    distinguished from body components — merchants
    should understand they are persistent fixtures,
    not draggable body items
```

---

### Journey 1C: Staff User Invitation + Role Assignment

**User:** Merchant Owner inviting a team member to their KloudShop store.
**Goal:** Grant a Gmail account access with the right roles — nothing more.
**Primary device:** Desktop web.

```
Owner opens Settings → Team & Permissions
  → "Invite team member" CTA
  → Enter Gmail address of invitee
  → Role assignment panel:
    □ Admin              □ Store Manager
    □ Fulfilment Staff   □ Inventory Manager
    □ Marketing Manager  □ Customer Support
    □ Analyst / Finance  □ Catalogue Manager
    □ B2B Account Manager (B2B/Hybrid only)
    □ B2B Sales Rep      (B2B/Hybrid only)
    □ Developer / Integrator
    [User may be assigned multiple roles]
  → "Send invitation" → Resend email to Gmail address

Invitee receives email:
  → "You have been invited to manage [Store Name]
     on KloudShop"
  → "Accept invitation" CTA → Google OAuth flow
  → On acceptance: Firebase custom claims updated
    with tenant_id + roles[]
  → Invitee lands on merchant admin dashboard
    scoped to their role permissions

Owner can at any time:
  → Edit roles for any staff member
  → Revoke access (immediately invalidates JWT)
  → Transfer Owner status to another Gmail account
```

---

## User Type 1 (Continued) — Merchant: Daily Store Management

### Journey 2A: Morning Dashboard Scan (Desktop)

**User:** Merchant, 9am, checking overnight performance.
**Goal:** Understand what happened while they were asleep in under 60 seconds.
**Primary device:** Desktop web.
**Emotional baseline:** Routine. Needs signal, not noise.

```
Login → Dashboard home
  ┌─────────────────────────────────────────────┐
  │  REVENUE OVERVIEW          Last 24 hours    │
  │  $12,847  ↑ 23% vs yesterday               │
  │  Orders: 47 │ AOV: $273 │ Conversion: 3.2% │
  ├─────────────────────────────────────────────┤
  │  ⚠ NEEDS ATTENTION                          │
  │  • 3 orders pending fulfilment > 24hrs      │
  │  • SKU #1042 — 3 days of stock remaining   │
  │  • 2 B2B approvals waiting                 │
  ├─────────────────────────────────────────────┤
  │  AI INSIGHT (Vertex AI Forecasting)         │
  │  "Widget Pro likely to stockout in 3 days   │
  │   based on current velocity. Reorder 500u?" │
  │  [ Dismiss ]  [ Draft Purchase Order ]      │
  └─────────────────────────────────────────────┘
         │
         ▼ Merchant scans in <60 seconds
         │ Clicks into whichever card needs action
```

**Design requirement:** The "Needs Attention" panel is the most important element
on the dashboard. It must be above the fold, always visible, and never empty when
there are genuine issues. AI insights must be specific and actionable — never
generic ("your sales are trending up").

---

### Journey 2B: Order Management Flow

```
Orders list view
  → Filter: All / Pending / Fulfilled / Returned
  → Search by order ID, customer name, SKU
  → Bulk actions: Mark fulfilled, Print labels,
    Export to CSV

Order detail view
  → Customer info + order items + pricing breakdown
  → Fulfilment status timeline
  → "Mark as fulfilled" + tracking number input
  → Refund / partial refund flow
  → Order notes (internal)

Mobile context (secondary):
  → Simplified order list: swipe right to fulfil,
    swipe left to flag
  → FCM push notification: "New order — $847
    from John Smith" → taps → order detail
```

---

### Journey 2C: Inventory + Stock Replenishment Flow

```
INVENTORY DASHBOARD
────────────────────
Stock levels table columns:
  SKU / Variant / Stock / Velocity / Days Remaining
  / Preferred Supplier (rank-1) / Lead Time (days)

Days Remaining is calculated as:
  current_stock / daily_sales_velocity
  — but flagged as CRITICAL if Days Remaining
  is LESS than rank-1 supplier lead time days,
  even if the raw stock count looks healthy.

  Example:
  Widget Pro — 8 days stock, 12 days lead time
  → flagged RED (already past reorder point)
    despite having 8 days of physical stock

Colour coding (lead-time-aware):
  Green  = Days Remaining > lead time + 30 days buffer
  Amber  = Days Remaining between lead time and lead time + 30
  Red    = Days Remaining < lead time (reorder overdue)

───────────────────────────────────────────────
AI REPLENISHMENT PANEL
───────────────────────────────────────────────
"Based on your sales velocity and supplier
 lead times, here are reorder recommendations:"

┌─────────────┬──────────────────────┬──────────┬───────────┬─────────────┐
│ SKU         │ Preferred Supplier   │ Reorder  │ Lead Time │ Confidence  │
├─────────────┼──────────────────────┼──────────┼───────────┼─────────────┤
│ Widget Pro  │ Acme Parts (rank 1)  │ 500 units│ 12 days   │ High        │
│ Bolt M8x40  │ FastBolt Co (rank 1) │ 200 units│ 7 days    │ Medium      │
└─────────────┴──────────────────────┴──────────┴───────────┴─────────────┘

Per-row actions — two distinct choices:
  [ ✓ Use preferred supplier ]
    → Accept rank-1 default for this PO line.
      No change to standing preference rank.

  [ ↓ Change supplier for this order ]
    → Inline dropdown expands showing ALL
      suppliers for this SKU, in rank order:
        1. Acme Parts      ← rank-1 (pre-selected)
        2. Global Supply   ← rank-2 fallback
        3. FastFix Ltd     ← rank-3
      Merchant selects alternate supplier.
      Override applies to THIS purchase order
      only — standing preference rank unchanged.

  [ ⚙ Update standing preference rank ]
    → Separate action, clearly labelled as
      permanent. Opens supplier preference
      panel for this SKU. Merchant can drag
      to reorder supplier preference ranking.
      Takes effect for all future orders.

CRITICAL DESIGN RULE:
  One-time PO override and permanent re-rank
  are ALWAYS presented as two separate,
  distinctly labelled actions. They are never
  conflated. A merchant overriding a supplier
  for one PO must never accidentally change
  their standing preference ranking.

───────────────────────────────────────────────
AI SUPPLIER PERFORMANCE ALERT (if triggered)
───────────────────────────────────────────────
Shown inline when scorecard signals degradation:

  ┌────────────────────────────────────────────────┐
  │ ⚠ Supplier insight — Widget Pro                │
  │                                                │
  │ Acme Parts (rank 1) has a 34% late delivery   │
  │ rate this quarter.                             │
  │ Global Supply (rank 2) has 98% on-time rate   │
  │ at $0.12 more per unit.                        │
  │                                                │
  │ [ Dismiss ]  [ Promote Global Supply → rank 1 ]│
  └────────────────────────────────────────────────┘

KloudShop advises. The merchant decides.
AI never auto-switches supplier preference.

───────────────────────────────────────────────
DRAFT PURCHASE ORDERS
───────────────────────────────────────────────
  → [ Draft Purchase Orders ] — one click
  → System groups all reorder lines by supplier
    (rank-1 defaults + any per-line overrides)
  → Generates one draft PO per supplier
  → Merchant reviews each PO before sending
  → Per PO line: supplier shown, qty shown,
    unit cost shown, alternate supplier
    still selectable before sending

LOW STOCK ALERT — FCM PUSH NOTIFICATION
─────────────────────────────────────────
  Push: "Widget Pro: 3 days stock remaining.
         Lead time: 12 days. Reorder now via
         Acme Parts (preferred supplier)."

  Merchant taps notification →
  → Inventory detail for that SKU
  → Reorder recommendation pre-loaded:
    - Rank-1 supplier pre-selected
    - Suggested reorder qty pre-filled
    - Lead time prominently displayed
    - Alternate suppliers in dropdown
      if merchant wants to override
  → [ Draft PO ] or [ Change supplier + Draft PO ]
```

**Emotional state:** Mild urgency on Red SKUs.
**Design requirements:**
- Preferred supplier visible at inventory LIST level —
  never buried in a detail drill-down
- Lead-time-aware urgency colouring — raw stock count
  alone is insufficient and misleading
- One-time override and permanent re-rank are two
  explicitly distinct actions, never conflated
- AI supplier alerts are advisory only —
  merchant always has final authority on procurement

---

### Journey 2D: Feature Catalogue Activation + Feature Setup

This journey has two distinct phases. Phase 1 is schema activation.
Phase 2 is feature configuration. A feature that is activated but
not configured is not operational — Phase 2 must always follow Phase 1.

```
PHASE 1 — ACTIVATION
──────────────────────
Feature Catalogue screen
  → Grid of available features (toggleable)
  → Each feature card shows:
    - Feature name + one-line description
    - "What this replaces" (e.g. "Replaces
       Klaviyo — $45/mo saved")
    - Tier badge (DTC / B2B / Hybrid)
    - Status: Available / Active / Coming soon

Merchant toggles ON "Customer Loyalty Programme":
         │
         ▼
  Confirmation modal:
  "Activating Loyalty Programme
   We're setting up your database. This
   takes about 15 seconds."
  [progress bar — live, driven by Firebase
   Realtime DB — never a fake timer]
         │
         ▼ (dependency chain resolves silently —
           merchant never sees migration internals)
  Success state:
  "Loyalty Programme is active.
   Now let's set it up for your store →"
  [CTA: "Configure Loyalty Programme"]
         │
         ▼ Failure state (rare):
  "Something went wrong. We've been notified
   and will fix it. Your store is unaffected."
  [No technical jargon. No stack trace.]
  [Retry available when resolved]

PHASE 2 — FEATURE SETUP WIZARD
────────────────────────────────
Every feature has a setup wizard that launches
immediately after successful activation.
The wizard is skippable (merchant can return
to it later from the Feature Catalogue) but
the feature is clearly marked "Active — setup
incomplete" until configuration is saved.

Example: Customer Loyalty Programme wizard
  Step 1 — Points configuration
    → Points earned per $1 spent: [  ] pts
    → Points earned on first purchase: [  ] pts
    → Welcome bonus points: [  ] pts

  Step 2 — Reward tiers
    → Tier 1 name: [Bronze]  threshold: [0] pts
    → Tier 2 name: [Silver]  threshold: [500] pts
    → Tier 3 name: [Gold]    threshold: [2000] pts
    → [ + Add tier ]

  Step 3 — Redemption rules
    → Minimum points to redeem: [100] pts
    → Redemption rate: [100] pts = [$1] discount
    → Points expiry: [ None / 6 months / 1 year ]

  Step 4 — Review + activate
    → Summary of all config values
    → "Save and activate loyalty programme"
    → Loyalty widget now visible on storefront
      and in customer accounts

Example: Abandoned Cart Recovery wizard
  Step 1 — Email timing
    → Send first reminder after: [1hr/4hr/24hr]
    → Send second reminder: [Yes/No] after [48hr]

  Step 2 — Incentive
    → Include discount code: [Yes/No]
    → If yes: discount value + expiry window

  Step 3 — Email template
    → Subject line
    → Body preview (merchant-editable)
    → Test send to merchant's email

Example: Subscription / Recurring Orders wizard
  Step 1 — Eligible products
    → Select which products can be subscribed to
    → Or: all products eligible (toggle)

  Step 2 — Billing frequencies offered to customers
    → [ ] Weekly  [ ] Bi-weekly  [ ] Monthly
    → [ ] Quarterly  [ ] Custom interval

  Step 3 — Subscriber discount
    → Discount for subscribers: [  ] %
    → Applied automatically at checkout
```

**Design requirement:** The progress bar in Phase 1 must be real — driven by
Firebase Realtime Database updates from the migration runner. A fake timed bar
that completes before the schema migration is done destroys trust the moment
the feature doesn't appear.

**Design requirement for Phase 2:** Every feature's setup wizard must have
sensible, pre-filled defaults so a merchant can click through in 30 seconds
and have a working feature. The wizard is for customisation, not for mandatory
technical configuration. A merchant who wants the defaults should never be
blocked by a form that demands specific values before proceeding.

**"Setup incomplete" state:** Features that have been activated but whose
wizard has not been completed show a distinct "Active — setup needed" badge
in the Feature Catalogue. The badge links directly to the wizard. Merchants
are never left wondering why an activated feature isn't working.

---

### PHASE 3 — RECONFIGURING AN ALREADY-ACTIVE FEATURE

This phase runs independently of Phase 1 and Phase 2. It is triggered
when a merchant returns to an already-active, already-configured feature
to change its settings — days, weeks, or months after initial setup.
No schema migration runs. No dependency chain is involved. This is purely
an application data update — existing `tenant_feature_config` rows are
overwritten with new values.

```
ENTRY POINT
────────────
Merchant opens Feature Catalogue
  → Active features show status badge: "Active ✓"
  → Merchant clicks "Configure" on an active feature
    (visible on every active feature card —
     not just on "setup needed" features)
         │
         ▼
RECONFIGURATION WIZARD
───────────────────────
Same generic schema-driven wizard as Phase 2,
BUT with two important differences:

  1. CURRENT VALUES PRE-POPULATED
     Every field shows the merchant's last saved
     value — not the default. Merchant sees exactly
     what is currently live on their store.

  2. LIVE-IMPACT WARNING (shown at top of wizard)
     "⚠ You are editing a live feature.
      Changes take effect immediately when saved.
      Active customers, ongoing orders, and
      current promotions may be affected."

  For features where changes have significant
  customer impact, a specific contextual warning
  is shown per field:

  Example — Loyalty Programme, points rate field:
    "Changing points per dollar affects all future
     purchases. Existing points already earned are
     NOT affected — customers keep what they have."

  Example — Loyalty Programme, tier thresholds:
    "Raising a tier threshold may move customers
     down a tier immediately. Consider notifying
     affected customers before saving."

  Example — Delivery Windows, allowed days:
    "Removing a delivery day may affect orders
     already in cart that customers selected
     for that day. Check active orders before
     saving."

SAVING RECONFIGURED VALUES
───────────────────────────
  → Merchant reviews changes
  → [ Save changes ] — FastAPI:
    UPDATE tenant_feature_config
    SET config_value = ?, set_at = NOW(), set_by = ?
    WHERE tenant_id = ? AND feature_id = ?
    AND config_key = ?
    (one UPDATE per changed key — unchanged
     keys are not touched)
  → Feature remains "Active ✓" throughout —
    it never enters a "setup needed" state
    during reconfiguration
  → No schema migration runs
  → No Alembic involvement
  → Change takes effect on next storefront
    page load (Redis caches config values
    with a short TTL — typically 5 minutes)

  → [ Cancel ] — discards all unsaved changes,
    returns to Feature Catalogue with zero
    impact on live store

AUDIT TRAIL
────────────
  Every config change is recorded:
  set_at (timestamp) + set_by (staff_user_id)
  Visible to Owner and Admin in feature
  configuration history — who changed what
  and when. This is important for B2B merchants
  who may need to demonstrate to buyers that
  pricing rules or delivery windows were changed
  on a specific date.
```

**Who can reconfigure features:**
Only staff with Owner, Admin, or Store Manager roles
can access feature reconfiguration. Marketing Manager
can reconfigure marketing-category features only.
Role restrictions are enforced at the FastAPI layer —
not just hidden in the UI.

**Design requirement:** The reconfiguration wizard must
make it visually unambiguous that the merchant is editing
a live, operational feature — not completing first-time
setup. The "Active ✓" badge must remain visible throughout.
The live-impact warning must be prominent but not alarming —
merchants should feel in control, not anxious.

---

## User Type 2 — B2B Buyer: Discovery + Purchase

### Journey 3A: B2B Buyer First Login + Catalog Access

**User:** Corporate purchasing manager at a company that buys wholesale from a
KloudShop merchant.
**Goal:** Find the right products at their negotiated price, place an order.
**Primary device:** Desktop web.
**Emotional baseline:** Professional, task-oriented. No patience for consumer UX
patterns. Expects to see their account-specific pricing immediately.

```
STAGE 1 — PORTAL ACCESS
─────────────────────────
wholesale.acmeco.kloudshop.biz
  → B2B portal landing (distinct from DTC storefront)
  → Login with company credentials
    (Firebase Auth — separate from consumer accounts)
  → On login: buyer sees their company name,
    credit limit, and account manager contact
    in the header — immediately personalised

STAGE 2 — CATALOG BROWSING (B2B-specific)
───────────────────────────────────────────
  → Product catalog filtered to their
    negotiated catalog (not all products)
  → Prices shown are THEIR tiered prices —
    not RRP. No "login to see price" friction.
  → Consultative AI panel (RAG-powered):
    "What are you looking for today?"
    → Natural language query:
      "M8 stainless bolts, box quantities,
       need 500 for a marine application"
    → AI responds with relevant SKUs, specs,
      compatibility notes — grounded in actual
      catalog data, not hallucinated

STAGE 3 — ORDER PLACEMENT
───────────────────────────
  → Add to cart (quantities default to
    case/pallet minimums for B2B)
  → Cart review: line items + tiered pricing
    breakdown + estimated delivery
  → Select payment terms:
    [ Pay now ] [ Net-30 ] [ Net-60 ]
    (only terms their account is approved for)
  → Order notes field (PO number, delivery
    instructions, project reference)
  → Submit order

STAGE 4 — APPROVAL WORKFLOW (if triggered)
────────────────────────────────────────────
  → Order exceeds credit limit or approval
    threshold — buyer sees:
    "Your order is pending approval.
     Your account manager has been notified.
     Expected response: within 4 business hours."
  → FCM push + email when approved/declined
  → If declined: reason shown + contact option

STAGE 5 — ORDER CONFIRMATION
──────────────────────────────
  → Order confirmed screen with:
    → Order reference number
    → Stripe invoice (net-30/60 terms)
    → Estimated despatch date
    → "Track this order" link
```

#### Screen Inventory — Journey 3A

| Screen | Purpose | Key Action |
|--------|---------|-----------|
| B2B portal login | Authenticated entry | Company credentials |
| Account dashboard | Personalised welcome | Credit limit, recent orders |
| Catalog (account-scoped) | Product discovery | Browse + AI search |
| Product detail (B2B) | Spec + pricing review | Add to cart (case quantities) |
| Cart (B2B) | Order review | Payment terms selection |
| Pending approval | Expectation setting | Wait for merchant approval |
| Order confirmation | Transaction close | Invoice + tracking |

---

## User Type 3 — Consumer (DTC): Browse + Purchase

### Journey 4A: Consumer Storefront — Discovery to Checkout

**User:** End consumer browsing a merchant's DTC storefront.
**Goal:** Find the right product and buy it with confidence.
**Primary device:** Mobile (consumer storefronts are mobile-majority traffic).
**Emotional baseline:** Browsing mode — low commitment, easily distracted.

```
STAGE 1 — STOREFRONT ENTRY
────────────────────────────
acmeco.kloudshop.biz (or custom domain)
  → SSR page load (FastAPI + Flutter Web HTML renderer)
  → Core Web Vitals target: LCP < 2.5s, CLS < 0.1
  → Hero section: merchant's brand, featured products
  → Navigation: merchant-configured categories

STAGE 2 — PRODUCT DISCOVERY
─────────────────────────────
  → Category browsing OR search bar
  → AI Consultative search (RAG-powered):
    Consumer types: "waterproof jacket under
    $200 for hiking in cold weather"
    → AI returns matched products with
      relevant attributes highlighted
      ("rated to -10°C", "10,000mm waterproof")
    → Results grounded in actual catalog —
      no hallucinated specs
  → Filter + sort (price, rating, in-stock)

STAGE 3 — PRODUCT DETAIL PAGE (PDP)
──────────────────────────────────────
  → Product images (gallery, zoom)
  → Variant selector (unlimited variants —
    size, colour, material, etc. — no 100-cap)
  → Price + stock status
  → Product reviews (if Reviews feature enabled)
  → AI assistant panel: "Have a question?"
    → "Does this come in wide fit?"
    → "What's the return policy?"
    → AI answers from catalog + merchant policy data
  → Add to cart CTA (sticky on mobile)

STAGE 4 — CART + CHECKOUT
───────────────────────────
  → Cart drawer (slide-in, no page navigation)
  → Upsell / cross-sell suggestions
    (BigQuery ML "frequently bought together")
  → Checkout:
    → Guest checkout supported (no forced signup)
    → Address autocomplete
    → Payment: Stripe (Apple Pay / Google Pay
      on mobile — one-tap checkout)
    → Order summary + discount code field
  → Place order

STAGE 5 — POST-PURCHASE
─────────────────────────
  → Order confirmation page:
    → Order number + estimated delivery
    → "Create an account to track your order"
      (soft account creation — not forced)
  → Confirmation email via Resend
  → SMS update at despatch via Twilio (if opted in)
```

#### Screen Inventory — Journey 4A

| Screen | Purpose | Key Action |
|--------|---------|-----------|
| Storefront home | Brand entry point | Browse / search |
| Category / collection | Product browsing | Filter + sort |
| Search results (AI) | Natural language discovery | Refine + select |
| Product detail page | Conversion point | Add to cart |
| Cart drawer | Pre-checkout review | Proceed to checkout |
| Checkout | Transaction | Place order |
| Order confirmation | Post-purchase reassurance | Save / track order |

---

## Emotional Journey Map — All User Types

| Journey | Lowest Anxiety Moment | Highest Anxiety Moment | Design Response |
|---------|----------------------|----------------------|----------------|
| Merchant migration | Signup (familiar) | "Will my 847 products actually import?" | Narrative progress screen with live counts |
| Merchant CSV import | File uploaded | "Will it mangle my data?" | AI mapping preview table before commit |
| Merchant daily ops | Dashboard load | "Did I miss something critical?" | Needs Attention panel above the fold |
| Feature activation | Toggle click | "Why is nothing happening?" | Real progress bar from Firebase Realtime DB |
| B2B buyer | Login (familiar) | "Are these my actual negotiated prices?" | Account-specific prices shown immediately on login |
| DTC consumer | Browsing (low stakes) | "Is this the right variant / size?" | AI assistant on PDP answers spec questions |

---

## Cross-Journey Design Principles

1. **Show real data immediately.** No skeleton screens longer than 500ms on critical
   paths. No placeholder content anywhere a merchant or buyer will make a decision.

2. **Never ask for something before you need it.** Defer all friction to the latest
   possible moment. Specifically:
   - **Merchant trial signup:** No credit card required to start the 30-day free trial.
     Merchant chooses exactly one of DTC or B2B at signup — Hybrid is paid-only.
     Full feature depth of the chosen tier is available. Three independent hard-stop
     triggers apply: (a) $5 GCP credit exhausted, (b) $600 cumulative GMV reached,
     (c) 30 days elapsed. After any resource hard-stop a published closing datetime
     is shown (168 hours from trigger, rounded to 00:00 GMT) with a silent 48-hour
     grace period — 216 hours total before permanent data deletion. The account is
     never hard-deleted. The product earns the card; the card doesn't unlock the product.
   - **DTC consumer checkout:** Guest checkout supported — no forced account creation
     before purchase. Soft account creation prompt appears only post-order-confirmation.

3. **Every waiting state earns its time.** If something takes more than 2 seconds,
   the UI must explain what is happening and why it is worth waiting for. Progress
   is shown in terms of real work done — not percentage bars that lie.

4. **Error states never blame the user.** All errors are written in first-person
   KloudShop voice: "We couldn't complete this" — never "You entered an invalid value."

5. **Mobile is a first-class surface for buyers, secondary for merchants.** Consumer
   storefronts are mobile-majority. Merchant admin is desktop-primary with a capable
   mobile companion (not a stripped-down afterthought).

6. **The AI layer must earn trust before it asks for it.** The consultative AI panel
   on product pages must answer the first question correctly. One hallucinated spec
   destroys the entire feature's credibility. RAG grounding in real catalog data is
   non-negotiable — surfaced in the architecture and carried into every AI touchpoint.

---

## Screen Inventory — Complete Platform

| Screen ID | Screen Name | User Type | Surface | Journey |
|-----------|------------|-----------|---------|---------|
| S-01 | Landing page | Merchant | Web | 1A |
| S-02 | Signup + tier selection | Merchant | Web | 1A |
| S-02b | GCP region selection + secondary region | Merchant | Web | 1A |
| S-02b | GCP region + secondary region setup | Merchant | Web | 1A |
| S-03 | Migration URL entry | Merchant | Web | 1A |
| S-04 | Migration progress (narrative) | Merchant | Web | 1A |
| S-05 | Store reveal dashboard | Merchant | Web | 1A |
| S-06 | CSV upload + AI mapping preview | Merchant | Web | 1A |
| S-07 | Migration runbook | Merchant | Web / Email | 1A |
| S-08 | Brand setup wizard | Merchant | Web | 1B |
| S-09 | Theme library + live preview | Merchant | Web | 1B |
| S-10 | Admin dashboard (home) | Merchant | Web + Mobile | 2A |
| S-11 | Orders list | Merchant | Web + Mobile | 2B |
| S-12 | Order detail | Merchant | Web + Mobile | 2B |
| S-13 | Inventory dashboard | Merchant | Web + Mobile | 2C |
| S-14 | Stock replenishment panel | Merchant | Web + Mobile | 2C |
| S-15 | Feature Catalogue grid | Merchant | Web | 2D |
| S-16 | Feature activation progress modal | Merchant | Web | 2D |
| S-17 | Analytics — Revenue overview | Merchant | Web | 2A |
| S-18 | Analytics — Product performance | Merchant | Web | 2A |
| S-19 | Analytics — Customer intelligence | Merchant | Web | 2A |
| S-20 | Analytics — Looker Studio embed | Merchant | Web | 2A |
| S-21 | B2B portal login | B2B Buyer | Web | 3A |
| S-22 | B2B account dashboard | B2B Buyer | Web | 3A |
| S-23 | B2B catalog (account-scoped) | B2B Buyer | Web | 3A |
| S-24 | B2B product detail | B2B Buyer | Web | 3A |
| S-25 | B2B cart + terms selection | B2B Buyer | Web | 3A |
| S-26 | B2B pending approval | B2B Buyer | Web + Email | 3A |
| S-27 | B2B order confirmation | B2B Buyer | Web + Email | 3A |
| S-28 | DTC storefront home | Consumer | Web (mobile) | 4A |
| S-29 | DTC category / collection | Consumer | Web (mobile) | 4A |
| S-30 | DTC AI search results | Consumer | Web (mobile) | 4A |
| S-31 | DTC product detail page | Consumer | Web (mobile) | 4A |
| S-32 | DTC cart drawer | Consumer | Web (mobile) | 4A |
| S-33 | DTC checkout | Consumer | Web (mobile) | 4A |
| S-34 | DTC order confirmation | Consumer | Web + Email | 4A |


---

## Exhaustive User Journey Inventory

All conceivable user journeys across all user types, surfaces, and frequencies.
Journeys marked ★ are fully mapped in this document. All others are named here
and will be detailed in Stage 4 Feature Stories or Stage 6 Data Model as appropriate.

---

### Merchant — Onboarding & Setup
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| M-01 ★ | Signup + tier selection | One-time |
| M-02 ★ | GCP primary region selection | One-time |
| M-03 | GCP secondary region activation | Rare / seasonal |
| M-04 ★ | Competitor store URL migration (scrape + import) | One-time |
| M-04b | Product catalog CSV upload — fallback when competitor platform blocks scraping | One-time |
| M-05 ★ | CSV customer + order history import | One-time |
| M-06 ★ | Migration runbook download + review | One-time |
| M-07 ★ | Brand identity setup (name, logo, colours, favicon) | One-time + occasional |
| M-08 ★ | Theme selection + live preview | One-time + occasional |
| M-09 | Custom domain connection + SSL provisioning | One-time |
| M-10 | KloudShop subdomain slug change | Rare |
| M-11 ★ | Staff user invitation + role assignment | Occasional |
| M-12 | Staff user role editing | Occasional |
| M-13 | Staff user access revocation | Occasional |
| M-14 | Owner account transfer | Very rare |
| M-15 | Tier upgrade prompt — review new tier cost + confirm explicit consent before upgrade proceeds | Rare |
| M-15b | Tier upgrade (DTC → Hybrid) — triggered when creating first wholesale price list, gated on consent | Rare |
| M-15c | Tier upgrade (B2B → Hybrid) — triggered when publishing first consumer storefront, gated on consent | Rare |
| M-15d | Tier upgrade decline — merchant dismisses upgrade prompt, action paused, remains on current tier | Rare |
| M-16 | Tier downgrade | Rare |
| M-17 | Trial-to-paid conversion | One-time |
| M-18 | Secondary brand identity setup (Hybrid B2B brand) | One-time (Hybrid only) |
| M-19 | Account deletion + data export | Very rare |

---

### Merchant — Daily Store Operations
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| M-20 ★ | Morning dashboard scan | Daily |
| M-21 ★ | Order list review + fulfilment | Daily |
| M-22 ★ | Order detail view | Daily |
| M-23 | Order refund (full) | Occasional |
| M-24 | Order refund (partial) | Occasional |
| M-25 | Order cancellation | Occasional |
| M-26 | Manual order creation | Occasional |
| M-27 | Order notes + internal comments | Daily |
| M-28 | Bulk order export (CSV) | Occasional |
| M-28b | Enter shipment tracking number + carrier after packing (triggers customer notification) | Daily |
| M-28c | Mark order as fulfilled (post-tracking entry — closes fulfilment workflow) | Daily |
| M-29 ★ | Inventory dashboard review | Daily |
| M-30 ★ | Stock replenishment — AI recommendation review | Daily |
| M-31 | Manual stock level adjustment | Occasional |
| M-32 | Low stock alert response | Occasional |
| M-33 | Purchase order draft + send to supplier | Occasional |
| M-33b | Purchase order status tracking + goods receipt confirmation | Occasional |
| M-34 | Stockout recovery (restock + notify waitlist) | Occasional |

---

### Merchant — Catalogue Management
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| M-35 | Add new product (manual) | Frequent |
| M-36 | Clone product + create variant | Frequent |
| M-37 | Bulk product import (CSV) | Occasional |
| M-38 | Product edit (price, description, images) | Frequent |
| M-39 | Product archive / unpublish | Occasional |
| M-40 | Collection creation + product assignment | Occasional |
| M-41 | SEO metadata editing on product pages (title, meta description, URL slug, JSON-LD) | Occasional |
| M-41b | SEO metadata editing on collection / category pages | Occasional |
| M-41c | SEO metadata editing on static pages (About, Contact, FAQ, Policy pages) | Occasional |
| M-41d | SEO metadata editing on homepage | Occasional |
| M-42 | Product image management (upload, reorder, alt text) | Frequent |
| M-43 | Variant management (add, edit, remove variants) | Frequent |
| M-44 | Product review moderation | Occasional |
| M-45p | Set up Brand Voice profile (tone, target audience, adjectives, style rules, competitor avoidance) — per brand_profile; Hybrid merchants configure DTC and B2B profiles independently | One-time + occasional |
| M-45q | AI-enhance a product title — trigger 3-variant Gemini generation, review variants with angle labels, pick one, edit if needed, save | Frequent |
| M-45r | AI-generate or enhance a product description — trigger 3-variant Gemini generation, review in tabbed comparison panel, pick one, edit if needed, save | Frequent |

> ⚑ **Data Model Flag — Stage 6: Product & Variant Schema (Shipping Attributes)**
>
> Every product and variant record must be able to store physical shipping attributes.
> These fields are required for carrier rate calculation, Google Shopping feed (shipping
> weight is a required field), and label generation. Weight and dimensions are
> optional at the product level but the absence of data has a defined fallback
> behaviour (merchant-configured default package weight in Shipping Settings).
>
> **Fields required on `variants` table (per-variant — overrides product-level):**
> - `weight_value` — DECIMAL(10,3), nullable — the physical weight of this variant
> - `weight_unit` — VARCHAR(4) — ENUM: `kg` | `lb` — matches store's unit preference
> - `length_value` — DECIMAL(10,2), nullable — longest dimension
> - `width_value` — DECIMAL(10,2), nullable
> - `height_value` — DECIMAL(10,2), nullable
> - `dimension_unit` — VARCHAR(4) — ENUM: `cm` | `in`
> - `ships_in_own_packaging` — BOOLEAN DEFAULT FALSE — when TRUE, carrier uses
>   declared dimensions directly rather than a packaging preset
>
> **Fields required on `products` table (product-level defaults — overridden by variant):**
> - `weight_value` — DECIMAL(10,3), nullable — used when variant has no weight set
> - `weight_unit` — VARCHAR(4)
> - `length_value`, `width_value`, `height_value` — DECIMAL(10,2), nullable
> - `dimension_unit` — VARCHAR(4)
> - `is_digital` — BOOLEAN DEFAULT FALSE — digital products are excluded from all
>   shipping calculations, label generation, and carrier rate queries
>
> **Tenant-level shipping defaults (per-tenant — in tenant schema):**
>
> `shipping_settings` — one row per tenant — holds only merchant-specific preferences
> that genuinely differ between tenants regardless of region:
> - `default_weight_value` — DECIMAL(10,3) NOT NULL — fallback when product has no
>   weight set. A clothing merchant may default to 0.3kg; an industrial parts
>   merchant to 5kg. Genuinely varies per merchant.
> - `default_weight_unit` — VARCHAR(4) NOT NULL — ENUM: `kg` | `lb`
> - `weight_unit_preference` — VARCHAR(4) — store-wide input/display unit (kg or lb)
> - `dimension_unit_preference` — VARCHAR(4) — store-wide input/display unit (cm or in)
>
> **Carrier data is NOT per-tenant — it is platform-maintained and shared.**
> Carriers (FedEx, DHL, UPS, Royal Mail, etc.) and their service levels are a
> small, countable, regionally stable set. They live in the platform schema
> (`kloudshop_platform`) and are maintained by KloudShop — never per merchant:
>
> `carriers` (platform schema — shared across all tenants):
> - `carrier_id` — VARCHAR(64) PRIMARY KEY (e.g. `fedex`, `dhl_express`)
> - `display_name` — TEXT NOT NULL
> - `logo_url` — TEXT
> - `supported_regions` — TEXT[] (e.g. `{US, CA, UK, AU}`)
> - `integration_type` — VARCHAR(16) — ENUM: `api` | `webhook`
> - `status` — VARCHAR(16) — `active` | `deprecated`
>
> `carrier_service_levels` (platform schema — shared):
> - `service_level_id` — VARCHAR(64) PRIMARY KEY (e.g. `fedex_ground`)
> - `carrier_id` — FK → carriers
> - `display_name` — TEXT (e.g. "FedEx Ground", "DHL Express Worldwide")
> - `typical_transit_days_min` — INTEGER — generic fallback transit range (low end)
> - `typical_transit_days_max` — INTEGER — generic fallback transit range (high end)
>   Used ONLY when the carrier API does not return a specific estimated delivery date.
>   At checkout, KloudShop always prefers the carrier API's specific date response.
> - `supported_regions` — TEXT[]
>
> **How estimated delivery date is calculated and displayed at checkout:**
> Real-time carrier APIs (FedEx, DHL, UPS) return a specific estimated delivery
> date when queried with origin, destination, and requested pickup date. KloudShop
> uses this specific date when available. Fallback calculation when API returns
> only transit days:
>
>   estimated_arrival = order_date
>                     + merchant_handling_days (from shipping_settings)
>                     + carrier transit days
>                     + weekend/public holiday skip
>
> Consumer sees at checkout per shipping option:
>   "FedEx Ground — $8.99 — Arrives Wed 25 – Fri 27 Nov"
>   "FedEx 2Day   — $14.99 — Arrives Mon 23 Nov"
>
> `shipping_settings` (tenant schema) gains two additional fields:
> - `handling_days` — INTEGER DEFAULT 1 — business days merchant needs to
>   pack and hand off to carrier after order is placed
> - `order_cutoff_time` — TIME — orders placed before this time ship same day;
>   after this time, handling_days count starts from the next business day
>   (e.g. "14:00" means orders before 2pm ship same day, after 2pm ship next day)
>
> **Per-tenant carrier connections (what each merchant has connected):**
>
> `merchant_carrier_connections` (tenant schema):
> - `connection_id` — UUID PRIMARY KEY
> - `carrier_id` — FK → carriers (platform schema)
> - `account_number` — TEXT NOT NULL
> - `credentials_secret_ref` — TEXT — GCP Secret Manager path (never stored raw)
> - `is_active` — BOOLEAN DEFAULT TRUE
>
> `carrier_checkout_options` (tenant schema — one row per service level the
> merchant has configured for their checkout):
> - `option_id` — UUID PRIMARY KEY
> - `service_level_id` — FK → carrier_service_levels (platform schema)
> - `is_enabled` — BOOLEAN DEFAULT TRUE
> - `handling_markup_type` — VARCHAR(16) — ENUM: `flat` | `percentage` | `none`
> - `handling_markup_value` — DECIMAL(10,2) DEFAULT 0
> - `allowed_destination_countries` — TEXT[] — empty array = no restriction
>
> **Packaging presets (per-tenant — in tenant schema):**
> - `preset_id` — UUID PRIMARY KEY
> - `name` — TEXT NOT NULL (e.g. "Small box", "Padded envelope", "Pallet")
> - `length_value`, `width_value`, `height_value` — DECIMAL(10,2) NOT NULL
> - `dimension_unit` — VARCHAR(4) NOT NULL — ENUM: `cm` | `in`
> - `max_weight_value` — DECIMAL(10,3) — maximum cart weight this preset can hold
> - `max_weight_unit` — VARCHAR(4)
> - `is_default` — BOOLEAN DEFAULT FALSE — used when no other preset fits
>
> **Fallback resolution order for shipping rate calculation:**
> 1. Use variant-level weight + dimensions if set
> 2. Fall back to product-level weight + dimensions
> 3. Fall back to tenant `default_weight_value` from shipping_settings
> 4. For packaging: select smallest preset whose `max_weight_value` ≥ total cart weight
> 5. If no preset fits, use `is_default = TRUE` preset
> 6. If no presets configured, use carrier API's default packaging assumption
>
> **Google Shopping feed note:** `weight_value` at variant level maps directly to
> `shipping_weight` in the Google Merchant Center feed. Missing weight causes Google
> to flag the product in Merchant Center — admin must surface a per-product warning.

---

### Merchant — Storefront & Theming
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| M-44b | Browse theme library filtered by sector category (Apparel, Restaurants, Electronics, Fashion, Beauty, Industrial B2B, Food & Beverage, Health & Beauty, Automotive, Home Décor, Digital Products, Sporting Goods, etc.) | Occasional |
| M-44c | Configure scaffold app_bar (logo, search, cart icon, announcement text, background colour) | Occasional |
| M-44d | Configure scaffold nav_bar (category links, custom page links, mega-menu items) | Occasional |
| M-44e | Configure scaffold footer (link groups, social icons, newsletter toggle) | Occasional |
| M-45 | Theme switch (one-click — applies a new base theme from the catalogue) | Occasional |
| M-45j | Review content carry-forward after theme switch (fill empty slots introduced by new theme) | Per theme switch |
| M-45k | Save theme to favourites (without applying) | Occasional |
| M-45l | View and manage "My Favourites" theme collection | Occasional |
| M-45m | Remove a theme from favourites | Occasional |
| M-45n | Compare two favourited themes side by side | Occasional |
| M-45o | Apply a theme directly from favourites | Occasional |
| M-45b | Open WYSIWYG theme editor for active theme | Occasional |
| M-45c | Reorder components in WYSIWYG editor (drag-to-reorder) | Occasional |
| M-45d | Add new component instance in WYSIWYG editor (e.g. second horizontal scroll strip) | Occasional |
| M-45e | Remove a component instance in WYSIWYG editor | Occasional |
| M-45f | Configure component parameters in WYSIWYG editor (collection, columns, content, animation) | Occasional |
| M-45g | Preview theme changes in live preview panel (mobile / tablet / desktop viewport toggle) | Occasional |
| M-45h | Save theme customisations (serialises to theme.json, uploads to Cloud Storage, invalidates cache) | Occasional |
| M-45i | Discard unsaved theme changes (revert to last saved state) | Occasional |
| M-46 | Theme customisation (colours, fonts, layout) | Occasional |
| M-47 | Navigation menu editing | Occasional |
| M-48 | Homepage banner + featured products setup | Occasional |
| M-49 | Page creation (About, Contact, FAQ, Policy pages) | Occasional |
| M-50 | 301 redirect rule creation | Occasional |
| M-51 | Sitemap regeneration | Rare |
| M-52 | robots.txt editing | Rare |
| M-52b | Edit storefront content slot (hero heading, subheading, CTA label, banner copy) | Frequent |
| M-52c | Upload / replace hero image or banner background image | Occasional |
| M-52d | Edit rich-text page content (About Us, Contact, FAQ, Policy pages) | Occasional |
| M-52e | Preview storefront content changes in live WYSIWYG preview | Frequent |
| M-53 | Storefront preview across device sizes | Occasional |
| M-53b | Set store primary language and enabled locales | One-time + occasional |
| M-53c | Review and edit AI-generated product translations per locale | Occasional |
| M-53d | Override AI-generated storefront content translation for a specific locale | Occasional |
| M-53e | Preview storefront in a specific language | Occasional |
| M-53f | Enable / disable a locale on the storefront | Occasional |
| M-53g | Enable blog on storefront (creates blog index at /blog, activates Blog section in admin) | One-time |
| M-53h | Create new blog post (title, rich-text body, featured image, categories, tags, SEO metadata, publish immediately or schedule) | Frequent |
| M-53i | Edit existing blog post (draft or published) | Frequent |
| M-53j | Schedule blog post for future publish date/time | Occasional |
| M-53k | Unpublish / archive a blog post | Occasional |
| M-53l | Manage blog categories and tags (create, rename, delete, merge) | Occasional |
| M-53m | Preview blog post before publishing (rendered storefront view) | Frequent |
| M-53n | Review and edit AI-generated blog post translations per locale | Occasional |
| M-53o | AI-enhance a blog post title — 3-variant Gemini generation using draft title + body context + categories/tags; pick one, edit if needed | Occasional |
| M-53p | AI-enhance a blog post body — full 3-variant Gemini rewrite in full-screen comparison modal; pick one, edit if needed; merchant's factual content preserved | Occasional |

> ⚑ **Data Model Flag — Stage 6: Multilingual / i18n Architecture**
>
> KloudShop supports a defined set of LTR languages from MVP. All storefront content,
> product catalog data, and UI strings are internationalisation-ready from day one.
> RTL languages (Arabic, Hebrew, Urdu) are explicitly deferred — they require
> bidirectional Flutter layout engine changes that are out of MVP scope.
>
> **Supported locales at launch (LTR only):**
> `en` (English — base/fallback), `de` (German), `fr` (French),
> `sv` (Swedish), `no` (Norwegian), `da` (Danish), `nl` (Dutch),
> `es` (Spanish), `pt` (Portuguese), `it` (Italian)
>
> **Storefront URL structure — path prefix per locale:**
>   acmeco.kloudshop.biz/products/widget-pro          ← en (default, no prefix)
>   acmeco.kloudshop.biz/de/products/widget-pro       ← German
>   acmeco.kloudshop.biz/fr/produits/widget-pro       ← French (localised slug)
> Path-prefix approach is Google's recommended structure for multilingual SEO.
> hreflang tags are generated automatically per page across all active locales.
> No additional SSL complexity — same wildcard cert covers all path variants.
>
> **Merchant admin UI localisation:**
> All Flutter admin UI strings are stored in ARB files (Flutter's standard
> localisation format). The admin renders in the merchant's preferred language,
> set in account preferences. Adding a new admin UI language = adding one ARB file.
> `flutter_localizations` + `intl` package handles all formatting (dates, numbers,
> currencies) per locale. Zero hardcoded strings anywhere in Flutter code.
>
> **Product catalog translations:**
>
> `product_translations` table (tenant schema):
> - `product_id` — UUID FK → products
> - `locale` — VARCHAR(8) NOT NULL (e.g. `de`, `fr`, `sv`)
> - `title` — TEXT NOT NULL
> - `description` — TEXT
> - `slug` — TEXT — locale-specific URL slug (e.g. `widget-pro` → `widget-profi`)
> - `meta_title` — TEXT — locale-specific SEO meta title
> - `meta_description` — TEXT
> - PRIMARY KEY (product_id, locale)
>
> `variant_translations` table (tenant schema):
> - `variant_id` — UUID FK → variants
> - `locale` — VARCHAR(8) NOT NULL
> - `title` — TEXT — variant display name in this locale
> - PRIMARY KEY (variant_id, locale)
>
> `collection_translations` table (tenant schema):
> - `collection_id` — UUID FK → collections
> - `locale` — VARCHAR(8) NOT NULL
> - `title` — TEXT NOT NULL
> - `description` — TEXT
> - `slug` — TEXT
> - `meta_title`, `meta_description` — TEXT
> - PRIMARY KEY (collection_id, locale)
>
> **Storefront content translations:**
> The existing `storefront_content` table gains a `locale` column.
> Primary key changes from `(slot_id)` to `(slot_id, locale)`.
> Base locale `en` is always present. Other locales are populated by
> AI auto-translation and optionally overridden by the merchant.
>
> Updated `storefront_content` schema:
> ```sql
> CREATE TABLE storefront_content (
>     slot_id        VARCHAR(128) NOT NULL,
>     locale         VARCHAR(8)   NOT NULL DEFAULT 'en',
>     slot_type      VARCHAR(32)  NOT NULL,
>     content_value  TEXT,
>     is_auto_translated BOOLEAN  DEFAULT FALSE,
>     updated_at     TIMESTAMPTZ  DEFAULT NOW(),
>     updated_by     UUID,
>     PRIMARY KEY (slot_id, locale)
> );
> ```
> `is_auto_translated = TRUE` flags AI-generated content the merchant has not
> yet reviewed — shown with a "Review translation" badge in the WYSIWYG.
>
> **AI auto-translation pipeline:**
> Trigger: merchant saves English content for any product, collection, or
> storefront content slot.
>   → Cloud Tasks job enqueued: translate to all merchant-enabled locales
>   → Google Cloud Translation API (GCP-native, pass-through billable)
>   → Translations written to respective translation tables with
>     is_auto_translated = TRUE
>   → Merchant notified: "Translations generated for {N} locales.
>     Review them in your Language Settings."
>   → Merchant can accept, edit, or regenerate any translation
>   → On merchant save of a translation: is_auto_translated set to FALSE
>
> **Locale fallback chain at storefront render time:**
> Consumer browses in French (Accept-Language: fr):
>   1. Look for locale = 'fr' in translation table
>   2. If absent, fall back to locale = 'en'
>   3. Never show a blank field — always render the English fallback
>
> **Locale-aware storefront routing:**
> The Storefront SSR Service extracts the locale prefix from the URL path.
> No locale prefix = English (default). Known locale prefix = render in that locale.
> Unknown prefix = treat as a product/collection slug, not a locale.
>
> **Currency and number formatting:**
> Locale-aware formatting is handled by the `intl` Dart package:
> - `de`: 1.234,56 € (period thousands separator, comma decimal)
> - `fr`: 1 234,56 € (space thousands separator, comma decimal)
> - `en`: $1,234.56
> Currency itself is set per merchant (not per locale) — a German merchant
> selling in EUR shows EUR regardless of the consumer's locale.
>
> **Merchant-enabled locales:**
> Not all merchants need all 10 locales. A UK-only merchant may only enable `en`.
> A German merchant selling across DACH may enable `de`, `en`, and `fr`.
> Enabled locales are stored in `brand_profiles.enabled_locales TEXT[]`.
> Only enabled locales generate hreflang tags and locale-prefixed URLs.

---

### Merchant — Feature Catalogue
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| M-54 ★ | Feature toggle activation (with migration progress) | Occasional |
| M-55 | Feature deactivation | Rare |
| M-56 | Feature setup wizard (post-activation) | Occasional |
| M-57 | Feature Request Channel — submit new request (authenticated merchants only — paid tier or active trial) | Occasional |
| M-58 | Feature Request Channel — upvote existing request (authenticated merchants only) | Occasional |
| M-59 | Feature Request Channel — browse top requests | Occasional |
| M-59b | Complete feature setup wizard after activation (Phase 2) | Per feature activation |
| M-59c | Return to incomplete feature setup wizard (resume later) | Occasional |
| M-59d | View "Active — setup needed" features in Feature Catalogue | Occasional |
| M-59e | Reconfigure an already-active feature (change loyalty tiers, cart recovery timing, etc.) | Occasional |
| M-59f | Deactivate a feature (data preserved for re-activation) | Rare |

> ⚑ **Data Model Flag — Stage 6: Feature Configuration Parameters**
>
> Every feature in the Feature Catalogue may have its own set of typed configuration
> parameters that the merchant sets during the Phase 2 setup wizard. The data model
> must support arbitrary feature config schemas with no hardcoded assumptions about
> parameter count, names, or types.
>
> **`feature_config_schema` table (platform-level — in `kloudshop_platform` schema):**
> Defines what configuration parameters each feature accepts.
> - `config_key` — parameter identifier (e.g. `points_per_dollar`, `require_otp_unregistered`)
> - `feature_id` — FK to feature_registry
> - `display_label` — human-readable label shown in the setup wizard UI
> - `description` — helper text explaining the parameter to the merchant
> - `data_type` — ENUM: `string` | `text` | `integer` | `float` | `boolean` | `date` | `time` | `datetime` | `json_array` | `json_object`
> - `default_value` — stored as TEXT, cast to data_type on read
> - `is_required` — must be set before feature is considered fully configured
> - `validation_rules` — JSONB: type-specific constraints
>   e.g. integer: `{"min": 1, "max": 1000}` /
>        string: `{"allowed_values": ["standard","express","overnight"]}` /
>        time: `{"format": "HH:MM"}` /
>        json_array: `{"item_type": "string", "allowed_values": ["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]}`
> - `display_order` — controls order of fields in wizard UI
> - `wizard_group` — groups parameters into named wizard steps/sections
>
> **`tenant_feature_config` table (per-tenant — in `tenant_{tenant_id}` schema):**
> Stores the merchant's chosen values for each feature's parameters.
> - `feature_id`, `config_key` — identify which feature + which parameter
> - `config_value` — TEXT, cast to correct type on read using `data_type` from schema
> - `set_at`, `set_by` — audit trail of who configured what and when
> - Sparse by design — only explicitly set keys are stored; absent keys fall back to `default_value`
>
> **Concrete examples of feature config parameters:**
>
> | Feature | config_key | data_type | Example value | Validation |
> |---------|-----------|-----------|---------------|-----------|
> | Loyalty Programme | `points_per_dollar` | integer | `10` | min: 1, max: 1000 |
> | Loyalty Programme | `welcome_bonus_points` | integer | `100` | min: 0 |
> | Loyalty Programme | `points_expiry_days` | integer | `365` | min: 0 (0 = never expire) |
> | Loyalty Programme | `reward_tiers` | json_array | `[{"name":"Bronze","threshold":0},{"name":"Silver","threshold":500}]` | min 1 item |
> | OTP Verification | `require_otp_unregistered_buyers` | boolean | `true` | — |
> | Signed Delivery | `require_signed_delivery` | boolean | `true` | — |
> | Delivery Windows | `allowed_delivery_days` | json_array | `["monday","wednesday","friday"]` | allowed_values: weekday names |
> | Delivery Windows | `delivery_window_start` | time | `09:00` | format: HH:MM |
> | Delivery Windows | `delivery_window_end` | time | `17:00` | format: HH:MM, must be > start |
> | Abandoned Cart | `first_reminder_delay_hours` | integer | `4` | allowed_values: [1,4,24] |
> | Abandoned Cart | `include_discount_code` | boolean | `false` | — |
> | Abandoned Cart | `discount_percentage` | float | `10.0` | min: 1.0, max: 50.0 |
> | Subscription Orders | `subscriber_discount_pct` | float | `15.0` | min: 0.0, max: 50.0 |
> | Subscription Orders | `allowed_frequencies` | json_array | `["weekly","monthly"]` | allowed_values: frequency enums |
> | Flash Sale | `sale_start_datetime` | datetime | `"2026-11-29T00:00:00"` | must be future datetime |
> | Flash Sale | `sale_end_datetime` | datetime | `"2026-11-30T23:59:00"` | must be > sale_start_datetime |
> | Loyalty Programme | `programme_launch_date` | date | `"2026-06-01"` | must be valid ISO date |
> | Abandoned Cart | `custom_email_body` | text | `"Hi {{first_name}}, you left something behind..."` | max_length: 5000 |
> | Loyalty Programme | `badge_image_url` | string | `"gs://kloudshop-tenant/loyalty/badge.png"` | format: "image_url" |
>
> **Business rules:**
> - A feature with `has_config = TRUE` and one or more `is_required = TRUE` parameters
>   is marked "Active — setup needed" until all required parameters are saved.
> - A feature with `has_config = FALSE` (e.g. a simple toggle) becomes immediately
>   operational on activation with no wizard step.
> - Reconfiguring a feature updates existing rows in `tenant_feature_config`.
>   All changes are audit-trailed via `set_at` and `set_by`.
> - Deactivating a feature does NOT delete `tenant_feature_config` rows —
>   configuration is preserved for re-activation. The merchant's settings are
>   never lost when a feature is toggled off.
>
> **Schema-driven UI — how the setup wizard renders dynamically:**
> The Flutter setup wizard is a generic form renderer. It reads
> `feature_config_schema` at runtime and renders the correct input widget
> per `data_type` — NumberInputField for integers, SwitchToggle for booleans,
> TimePicker for time fields, MultiSelectChips for json_array with allowed_values,
> etc. No Flutter code changes are needed when a new feature with new parameters
> is added. The wizard groups fields by `wizard_group` into named steps.
> Required fields block step progression until filled.
>
> **This does NOT affect Alembic or the dependency chain. Full separation:**
> - `feature_dependencies` + Alembic = database SCHEMA changes
>   (CREATE TABLE etc.) — run by Migration Runner at Phase 1
> - `feature_config_schema` + `tenant_feature_config` = application DATA
>   (merchant's config choices) — written by FastAPI during Phase 2 wizard
> - `tenant_feature_config` is in the BASE tenant schema from day one —
>   it is not a per-feature migration. Alembic never touches it after creation.
> - Phase 1 (schema migration) always completes before Phase 2 (config wizard)
>   begins — the sequential flow makes it architecturally impossible to store
>   config values before their dependent tables exist.

---

### Merchant — B2B Operations (B2B + Hybrid tiers)
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| M-60 | B2B buyer account creation | Occasional |
| M-61 | B2B buyer account editing (credit limit, terms) | Occasional |
| M-62 | B2B custom price list creation | Occasional |
| M-63 | B2B price list assignment to buyer account | Occasional |
| M-64 | B2B approval workflow configuration | Rare |
| M-65 | B2B order approval (approve) | Frequent (B2B) |
| M-66 | B2B order approval (decline + reason) | Occasional |
| M-67 | B2B net-terms invoice management | Frequent (B2B) |
| M-68 | B2B overdue invoice chase | Occasional |
| M-69 | B2B buyer account suspension | Rare |
| M-70 | B2B catalog restriction (hide products from buyers) | Occasional |

---

### Merchant — Analytics & Reporting
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| M-71 ★ | Revenue overview dashboard | Daily |
| M-72 ★ | Product performance dashboard | Weekly |
| M-73 ★ | Customer intelligence dashboard | Weekly |
| M-74 ★ | Inventory intelligence dashboard | Daily |
| M-75 | B2B buyer activity dashboard | Weekly |
| M-76 | AI layer performance dashboard | Weekly |
| M-77 | Storefront funnel analysis | Weekly |
| M-78 | Looker Studio — custom report build | Occasional |
| M-79 | Looker Studio — scheduled report setup | Rare |
| M-80 | Analytics data export | Occasional |
| M-81 | Demand forecast review (Vertex AI) | Weekly |

---

### Merchant — Billing & Account
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| M-82 | Monthly invoice review (subscription + GCP usage) | Monthly |
| M-83 | Payment method update | Rare |
| M-84 | Billing history download | Rare |
| M-85 | GCP usage breakdown drill-down | Monthly |
| M-86 | Secondary GCP region activation | Rare / seasonal |
| M-87 | Secondary GCP region deactivation | Rare / seasonal |
| M-88 | Account settings update (email, notifications) | Rare |

---

### Merchant — Auth & Security
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| M-89 | Merchant login (Google OAuth) | Daily |
| M-90 | Merchant logout | Daily |
| M-91 | Session expiry + re-authentication | Occasional |
| M-92 | Google account disconnection / reconnection | Very rare |
| M-93 | API key generation (Developer role) | Rare |
| M-94 | API key revocation | Rare |
| M-95 | Webhook configuration + testing | Rare |
| M-96 | Login from new device (Google handles MFA) | Occasional |

---

### B2B Buyer — All Journeys
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| B-00a | Merchant creates B2B buyer account (company name, contact, credit limit, price list assignment) | Occasional |
| B-00b | System sends B2B buyer invitation email (Resend) with registration link | Automated |
| B-00c | B2B buyer receives invitation + completes registration (Gmail or email/password) | One-time |
| B-00d | B2B buyer account approval (if merchant requires manual approval before portal access) | Occasional |
| B-01 ★ | B2B portal first login (post-registration) | One-time |
| B-02 | B2B portal returning login | Daily/Weekly |
| B-03 | B2B portal logout | Daily/Weekly |
| B-04 | Forgot password / account recovery (Google-handled) | Rare |
| B-05 ★ | Catalog browsing (account-scoped) | Frequent |
| B-06 ★ | AI consultative search | Frequent |
| B-07 ★ | Product detail view (B2B pricing) | Frequent |
| B-08 ★ | Add to cart (B2B quantities) | Frequent |
| B-09 ★ | Cart review + payment terms selection | Frequent |
| B-10 ★ | Order placement (auto-approved) | Frequent |
| B-11 ★ | Order placement (pending approval) | Occasional |
| B-12 ★ | Approval notification receipt + order confirmation | Occasional |
| B-13 | Order decline notification + follow-up | Rare |
| B-14 | Reorder from previous order | Frequent |
| B-15 | Order history review | Occasional |
| B-16 | Order detail view + invoice download | Occasional |
| B-17 | Net-terms invoice payment | Occasional |
| B-18 | Quote request submission | Occasional |
| B-19 | Saved cart / wishlist management | Occasional |
| B-20 | Account details update (delivery addresses) | Rare |
| B-21 | Contact account manager | Occasional |

---

### Consumer (DTC) — All Journeys
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| C-01 ★ | Storefront landing + browsing | Frequent |
| C-02 ★ | Category / collection browsing | Frequent |
| C-03 ★ | AI search (natural language) | Frequent |
| C-04 | Standard keyword search | Frequent |
| C-05 ★ | Product detail page view | Frequent |
| C-06 | Product variant selection | Frequent |
| C-07 | Product review reading | Frequent |
| C-08 | Product review submission (logged-in) | Occasional |
| C-09 ★ | Add to cart | Frequent |
| C-10 ★ | Cart review | Frequent |
| C-11 | Discount code application | Occasional |
| C-12 | Upsell / cross-sell acceptance | Occasional |
| C-13 ★ | Guest checkout | Frequent |
| C-14 | Logged-in checkout | Frequent |
| C-15 | Apple Pay / Google Pay one-tap checkout | Frequent (mobile) |
| C-16 ★ | Order confirmation | Frequent |
| C-17 | Account creation (post-purchase soft prompt) | Occasional |
| C-18 | Login to existing consumer account | Occasional |
| C-19 | Forgot password + recovery | Occasional |
| C-20 | Order tracking | Occasional |
| C-21 | Return request initiation | Occasional |
| C-22 | Refund status check | Occasional |
| C-23 | Wishlist save + return | Occasional |
| C-24 | Newsletter signup | Occasional |
| C-25 | Loyalty programme enrolment (if feature enabled) | Occasional |
| C-26 | Loyalty points redemption at checkout | Occasional |
| C-27 | Gift card purchase | Rare |
| C-28 | Gift card redemption at checkout | Occasional |
| C-29 | Subscription / recurring order setup | Occasional |
| C-30 | Subscription management (pause, cancel, modify) | Occasional |
| C-31 | Consumer account deletion + data erasure (GDPR) | Very rare |
| C-32 | Browse blog index (list of published posts, category/tag filter) | Occasional |
| C-33 | Read individual blog post (SSR-rendered, JSON-LD Article, hreflang, CTA links to products) | Occasional |

---

### Platform / System — Background Journeys
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| SYS-01 | GCP tenant provisioning (new merchant signup) | Per new merchant |
| SYS-02 | Feature schema migration execution | Per feature activation |
| SYS-03 | Monthly billing reconciliation (GCP → Stripe) | Monthly per merchant |
| SYS-04 | Vertex AI demand forecast model retraining | Weekly per merchant |
| SYS-05 | Storefront sitemap regeneration | Daily |
| SYS-06 | Schema drift detection (nightly check) | Nightly |
| SYS-07 | Secondary region failover (automated) | Rare |
| SYS-08 | Secondary region failback (post-incident) | Rare |
| SYS-09 | Trial hard-stop — three-trigger system: (a) $5 GCP credit exhausted → resources suspended + published closing datetime shown (168 hrs rounded to 00:00 GMT) + silent 48-hr grace = 216 hrs total before permanent deletion; (b) $600 GMV cap → selling paused, data intact; (c) day-30 elapsed → same 216-hr window as (a). Storefront hit counter per tenant drives daily visitor-count emails to merchant during hard-stop. Permanent deletion at end of 216-hr window. Account soft-deleted, never hard-deleted. All steps fully automated. | Per trial end |
| SYS-10 | Failed payment dunning sequence | Occasional |
| SYS-11 | GDPR erasure request execution (fully automated pipeline — anonymises PII on request receipt) | Rare |
| SYS-12 | Merchant account suspension (non-payment) — automated on Stripe dunning failure | Rare |
| SYS-12b | Merchant account reinstatement (upon payment) — automated on Stripe payment success | Rare |
| SYS-13 | Canary deployment promotion / rollback | Per production deploy |
| SYS-14 | Google Shopping feed regeneration (scheduled) | Daily per merchant |
| SYS-15 | Social commerce channel catalog re-sync | On product change + daily |
| SYS-16 | TaxJar/Avalara tax rules cache refresh | Daily |
| SYS-17 | Multi-location stock transfer reconciliation | On transfer event |
| SYS-18 | Flutter Web admin new-version detection — service worker polls version.json (Cache-Control: no-store) every 10 minutes; on build hash mismatch, postMessage fires to Flutter admin app via JS interop; non-intrusive persistent banner shown to authenticated merchant admin users only ("X new features available — Update now"); merchant-triggered skipWaiting() + reload fetches pre-cached new binary; mobile apps use standard app store update notification | Per production deployment |

---

### Merchant — POS & Omnichannel
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| O-00a | Assign POS Operator role to a staff member for a specific store location | Occasional |
| O-01 | POS interface setup — assign POS Operator to location, configure in-store SKU visibility | One-time per location |
| O-01b | Optional: Stripe Terminal card reader pairing (if card payments required at POS) | One-time per device |
| O-02 | In-store sale processing (POS) | Daily (physical stores) |
| O-03 | POS end-of-day reconciliation | Daily |
| O-04 | Stock transfer between locations | Occasional |
| O-05 | Per-location stock level adjustment | Occasional |
| O-06 | Fulfilment location routing configuration | Rare |
| O-07 | Multi-location low stock alert response | Occasional |

---

### Merchant — Social Commerce & Channels
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| SC-01 | TikTok Shop account connection + catalog sync | One-time |
| SC-02 | Instagram Shopping account connection + catalog sync | One-time |
| SC-03 | Facebook Shops account connection + catalog sync | One-time |
| SC-04 | Google Shopping (Merchant Center) connection | One-time |
| SC-05 | Social channel product exclusion (hide specific products from a channel) | Occasional |
| SC-06 | Social channel order review + fulfilment | Daily (if channels active) |
| SC-07 | Channel performance analytics review | Weekly |
| SC-08 | Social channel disconnection | Rare |
| SC-09 | Google Shopping feed health check | Weekly |

---

### Merchant — Tax Compliance
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| T-01 | Tax compliance setup (jurisdiction configuration) | One-time |
| T-02 | Tax report download per jurisdiction (quarterly filing) | Quarterly |
| T-03 | Tax exemption setup for B2B buyers (tax-exempt certificates) | Occasional |
| T-04 | Tax override for specific products (zero-rated goods) | Occasional |

---

### Merchant — Shipping & Courier Management
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| SH-01 | Connect carrier account (FedEx, DHL, UPS, Royal Mail, etc.) | One-time per carrier |
| SH-02 | Disconnect or update carrier account credentials | Rare |
| SH-03 | Configure free shipping rules (threshold, region, product category) | Occasional |
| SH-04 | Configure flat-rate shipping rules (fallback) | One-time + occasional |
| SH-05 | Configure B2B-specific shipping rules (freight, buyer collection) | Occasional |
| SH-06 | View real-time shipping rates at checkout (consumer-facing) | Per checkout |
| SH-07 | Generate shipping label from fulfilled order | Daily (active merchants) |
| SH-08 | Retry failed label generation / manually enter tracking number | Occasional |
| SH-08b | Manual fulfilment — ship via local post office / unintegrated courier, enter tracking number on return | Frequent (regions without API carriers) |
| SH-08c | Edit tracking number on already-fulfilled order (correction after receiving actual number) | Occasional |
| SH-09 | View shipping cost analytics (carrier breakdown, avg cost per order) | Weekly |
| SH-10 | Configure multi-location fulfilment routing for shipping | Occasional |
| SH-11 | Configure carrier-specific packaging presets (box sizes, weights) | One-time |
| SH-12 | Bulk generate shipping labels for multiple orders | Daily (active merchants) |

---

### Merchant — Dynamic Pricing
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| P-01 | Dynamic pricing rule creation (stock-age markdown) | Occasional |
| P-02 | Dynamic pricing rule creation (velocity-based) | Occasional |
| P-03 | Dynamic pricing rule creation (time-triggered flash sale) | Occasional |
| P-04 | Dynamic pricing rule review + performance analytics | Weekly |
| P-05 | Dynamic pricing rule pause / deactivate | Occasional |

---

### Merchant — Data Portability
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| D-01 | Full store data export (products + orders + customers + analytics) | On-demand |
| D-02 | Partial export (orders only, date range) | Occasional |
| D-03 | B2B account data export | Occasional |
| D-04 | Analytics export from Looker Studio | Occasional |

---

### Merchant + B2B Buyer — Internal Messaging
| ID | Journey Name | User | Frequency |
|----|-------------|------|-----------|
| MSG-01 | Compose + send direct message to a staff member | Staff | Daily |
| MSG-02 | Compose + send direct message to a B2B buyer | Merchant/Account Manager | Frequent |
| MSG-03 | B2B buyer sends message to merchant (query on order, pricing, catalog) | B2B Buyer | Frequent |
| MSG-04 | Reply to a direct message thread | Staff / B2B Buyer | Daily |
| MSG-05 | Start a context-linked thread on a specific order | Staff | Frequent |
| MSG-06 | Start a context-linked thread on a purchase order | Staff | Occasional |
| MSG-07 | Start a context-linked thread on a SKU / product | Staff | Occasional |
| MSG-08 | Start a context-linked thread on a B2B buyer account | Staff | Occasional |
| MSG-09 | Reply within a context-linked thread | Staff / B2B Buyer | Frequent |
| MSG-10 | Attach file(s) to a message (images / PDFs, up to 100MB, up to 10 files) | Staff / B2B Buyer | Occasional |
| MSG-11 | View + download a file attachment from a message | Staff / B2B Buyer | Occasional |
| MSG-12 | Save a message as a draft (auto-saved every 30 seconds) | Staff / B2B Buyer | Occasional |
| MSG-13 | Resume and send a draft message | Staff / B2B Buyer | Occasional |
| MSG-14 | View inbox (all threads with unread messages) | Staff / B2B Buyer | Daily |
| MSG-15 | View sent messages | Staff / B2B Buyer | Occasional |
| MSG-16 | View drafts folder | Staff / B2B Buyer | Occasional |
| MSG-17 | View all messages archive | Staff / B2B Buyer | Occasional |
| MSG-18 | View all order-linked message threads | Staff | Frequent |
| MSG-19 | View all PO-linked message threads | Staff | Occasional |
| MSG-20 | View all SKU-linked message threads | Staff | Occasional |
| MSG-21 | View all buyer account message threads | Staff / B2B Buyer | Occasional |
| MSG-22 | Search messages by keyword / substring | Staff / B2B Buyer | Frequent |
| MSG-23 | Search messages by sender | Staff / B2B Buyer | Occasional |
| MSG-24 | Search messages by date range | Staff / B2B Buyer | Occasional |
| MSG-25 | Search messages by linked object (order #, PO #, SKU, buyer) | Staff / B2B Buyer | Occasional |
| MSG-26 | Archive a thread (hide from inbox without deleting) | Staff / B2B Buyer | Occasional |
| MSG-27 | View FCM push notification for new message + tap to open thread | Staff / B2B Buyer | Daily |
| MSG-28 | Mark thread as read (clears unread badge) | Staff / B2B Buyer | Daily |

> ⚑ **Data Model Flag — Stage 6:**
> `message_threads`, `thread_participants`, `messages` (with FTS index on body),
> and `message_attachments` tables required in each tenant schema.
> Messages are immutable — no delete, no edit after sending.
> Drafts stored with `is_draft = TRUE`, converted on send.
> Unread counts maintained in Redis for fast badge rendering,
> reconciled with `last_read_at` on session start.
> Context-linked thread participants auto-determined by object
> access rules — no manual participant management.
> See `01b-tech-stack.md` — Internal Messaging Architecture for full spec.

---

### Platform Admin — KloudShop Control Plane Administration

**User:** KloudShop internal team (founder + designated admins). This is a distinct
user type from merchants — they manage the KloudShop platform itself, not individual
stores. Platform Admin journeys are accessed via a separate internal admin dashboard,
not the merchant-facing UI.

| ID | Journey Name | Frequency |
|----|-------------|-----------|
| ADM-01 | Platform Admin login (Gmail / Google SSO — MFA enforced) | Daily |
| ADM-02 | View platform-wide dashboard (total merchants, MRR, churn, active trials, GCP spend) | Daily |
| ADM-03 | Review + approve / reject new trial signup (anti-spam validation) | Daily |
| ADM-04 | View merchant account detail (tier, GCP usage, billing status, store health) | Occasional |
| ADM-05 | Manually suspend merchant account (policy violation / fraud) | Rare |
| ADM-06 | Manually reinstate suspended merchant account | Rare |
| ADM-07 | Issue billing credit to merchant (GCP usage dispute resolution) | Rare |
| ADM-08 | View platform-wide GCP cost breakdown (total + per-tenant) | Weekly |
| ADM-09 | Add new theme to theme catalogue (upload theme package + INSERT into theme registry) | Occasional |
| ADM-10 | Edit theme metadata (display name, sector tags, status: draft/published/deprecated) | Occasional |
| ADM-11 | Deprecate / retire a theme from the catalogue | Rare |
| ADM-12 | Preview theme with sample merchant data before publishing | Per new theme |
| ADM-13 | Add new Feature Catalogue item (register feature + migrations in feature_registry) | Occasional |
| ADM-14 | Edit Feature Catalogue item (description, tier availability, status) | Occasional |
| ADM-15 | Deprecate / retire a Feature Catalogue item | Rare |
| ADM-16 | Add new component type to Flutter theme renderer (engineering task — triggers schema version bump) | Rare |
| ADM-17 | Manage feature flags via Firebase Remote Config (gradual rollout, kill switch) | Occasional |
| ADM-18 | View Feature Request Channel submissions + vote counts | Weekly |
| ADM-19 | Promote a community feature request to development backlog | Occasional |
| ADM-20 | View platform error dashboard (Sentry — all tenants aggregated) | Daily |
| ADM-21 | Investigate specific merchant incident (Sentry trace + Cloud Logging drill-down) | Occasional |
| ADM-22 | Trigger manual schema drift check for a specific tenant | Rare |
| ADM-23 | View CI/CD pipeline status (GitHub Actions + Cloud Build + Cloud Deploy) | Daily |
| ADM-24 | Approve staging → production promotion (manual gate in CI/CD pipeline) | Per deploy |
| ADM-25 | Roll back a production deployment (via GCP Cloud Deploy) | Rare |
| ADM-26 | View canary deployment metrics (error rate, p99 latency — before full promotion) | Per deploy |
| ADM-27 | Manage platform staff accounts (invite, role-assign, revoke platform admin access) | Rare |
| ADM-28 | View GDPR erasure request queue + confirm automated execution | Occasional |
| ADM-29 | Handle merchant support escalation (view merchant store context for support) | Occasional |
| ADM-30 | Publish platform status / incident update (merchant-facing status page) | Rare |

---

### Merchant — Supplier Management
| ID | Journey Name | Frequency |
|----|-------------|-----------|
| SUP-01 | Add new supplier (name, contact, lead time, payment terms, currency) | Occasional |
| SUP-02 | Edit supplier details | Occasional |
| SUP-03 | Deactivate / archive supplier | Rare |
| SUP-04 | View supplier list + supplier detail | Occasional |
| SUP-05 | Assign first supplier to a product / SKU / variant | Frequent |
| SUP-06 | Add additional supplier(s) to an existing SKU (multi-supplier per SKU) | Occasional |
| SUP-07 | Add new supplier on-the-fly during product / inventory creation | Frequent |
| SUP-08 | Set supplier preference order for a SKU (rank suppliers 1st, 2nd, 3rd…) | Occasional |
| SUP-09 | Change preferred supplier ranking for a SKU | Occasional |
| SUP-10 | View all suppliers for a specific SKU with their current preference rank | Frequent |
| SUP-11 | View all SKUs supplied by a specific supplier | Occasional |
| SUP-12 | Remove a supplier from a specific SKU (without deleting the supplier) | Occasional |
| SUP-13 | Draft purchase order — system auto-selects highest-ranked supplier per SKU | Occasional |
| SUP-14 | Override auto-selected supplier on a purchase order line (pick alternate) | Occasional |
| SUP-15 | Send purchase order to supplier (email via Resend) | Occasional |
| SUP-16 | Mark purchase order as received (full or partial) | Occasional |
| SUP-17 | Reconcile received stock against purchase order (flag discrepancies) | Occasional |
| SUP-18 | Log supplier performance event (late delivery, quality issue, short shipment) | Occasional |
| SUP-19 | View supplier scorecard — full analytics dashboard (see below) | Weekly |
| SUP-20 | View supplier comparison table — compare all suppliers for a specific SKU side by side | Occasional |
| SUP-21 | View supplier performance trend over time (30 / 90 / 365 day rolling window) | Monthly |
| SUP-22 | View per-PO delivery performance breakdown for a supplier | Occasional |
| SUP-23 | Export supplier performance report (CSV/PDF for procurement review) | Occasional |
| SUP-27 | Manually adjust supplier preference rank based on performance review | Occasional |
| SUP-28 | View purchase order history per supplier | Occasional |
| SUP-29 | View purchase order history per SKU across all suppliers | Occasional |
| SUP-30 | Set reorder point + preferred order quantity per SKU per supplier | Occasional |
| SUP-31 | Compare unit cost across suppliers for the same SKU | Occasional |
| SUP-25 | Set supplier-specific lead time override per SKU (overrides global supplier lead time) | Occasional |
| SUP-33 | AI reorder recommendation — surfaces preferred supplier + suggested qty based on velocity + lead time | Weekly |

> ⚑ **Data Model Flag — Stage 6:**
>
> **Multi-supplier per SKU with dynamic preference ordering** is a core data model
> requirement. The following entities and relationships must be fully modelled:
>
> **`suppliers` table (tenant-scoped):**
> - supplier_id, name, contact_name, email, phone, address
> - payment_terms, default_lead_time_days, currency
> - status (active / inactive / archived)
> - created_at, updated_at
>
> **`product_suppliers` join table (many-to-many: variants ↔ suppliers):**
> - variant_id (FK → variants), supplier_id (FK → suppliers)
> - supplier_sku (supplier's own part/reference number for this item)
> - unit_cost, moq (minimum order quantity)
> - lead_time_override_days (NULL = use supplier default)
> - preference_rank (INTEGER — 1 = most preferred, 2 = first fallback, etc.)
>   preference_rank is scoped per variant — the same supplier can be rank 1
>   for SKU A and rank 3 for SKU B simultaneously
> - preference_rank must be reorderable by the merchant at any time
> - last_used_at (timestamp — tracks which supplier was last ordered from)
> - notes (free text — merchant's private notes on this supplier-SKU relationship)
> - PRIMARY KEY (variant_id, supplier_id)
>
> **`supplier_performance_events` table:**
> - event_id, supplier_id, po_id (FK → purchase_orders)
> - event_type: ENUM ('late_delivery', 'short_shipment', 'quality_issue',
>   'early_delivery', 'correct_shipment', 'price_increase', 'price_decrease')
> - severity: ENUM ('minor', 'moderate', 'severe') — for negative events
> - notes, logged_by (staff_user_id), logged_at
> - These events feed the supplier scorecard analytics in BigQuery
>
> **`purchase_orders` table:**
> - po_id, supplier_id, status (draft/sent/partial/received/cancelled)
> - ordered_at, expected_delivery_at, received_at, notes
>
> **`purchase_order_lines` table:**
> - po_line_id, po_id, variant_id
> - supplier_id (explicit — may differ from PO header if split order)
> - qty_ordered, qty_received, unit_cost
> - discrepancy_flag (bool), discrepancy_notes
>
> **Business rules to enforce at application layer:**
> - A SKU may have 1 to N suppliers. There is no upper limit.
> - Exactly one supplier per SKU may hold preference_rank = 1 at any time.
>   Reranking is a transactional swap — never leaves two rank-1 entries.
> - Deleting a supplier is blocked if they have open purchase orders.
>   Archiving is always available as a safe alternative.
> - On-the-fly supplier creation during product/inventory entry must not
>   navigate away from the product form — inline modal, saves to suppliers
>   table, and immediately populates in the supplier selector.
> - AI replenishment engine (Vertex AI Forecasting) must use the
>   preference_rank=1 supplier's effective lead time when calculating
>   reorder trigger dates. If rank-1 supplier is archived or has no
>   lead time set, fall back to rank-2 automatically.
>
> **Supplier Analytics — Full Specification (BigQuery + Native Flutter Dashboard):**
>
> Every purchase order and performance event feeds a supplier analytics pipeline
> in BigQuery. Metrics are computed per supplier, per SKU-supplier relationship,
> and per time window (30 / 90 / 365 days rolling). Surfaced as a native Flutter
> dashboard panel in the merchant admin — no third-party analytics app required.
>
> **Tier 1 — Delivery Performance Metrics (per supplier, per time window):**
> - Total purchase orders placed
> - Total purchase orders received (in full)
> - Total purchase orders received (partial)
> - Total purchase orders overdue (not yet received past expected delivery date)
> - On-time delivery rate: orders received on or before expected_delivery_at / total orders × 100
> - Average lead time (actual): mean of (received_at − ordered_at) across all received POs
> - Lead time variance: actual lead time vs. quoted lead_time_days — positive = late, negative = early
> - Average lead time accuracy: % of orders delivered within ±1 day of quoted lead time
>
> **Tier 2 — Quality Metrics (per supplier, per time window):**
> - Total quality events logged (type breakdown: quality_issue, short_shipment, damaged_goods)
> - Quality event rate: quality events / total POs received × 100
> - Fill rate: total qty_received / total qty_ordered × 100 — measures short shipment frequency
> - Defect rate: units flagged as quality issues / total units received × 100
>   (requires merchant to log quality events per PO line — not automatic)
>
> **Tier 3 — Pricing Metrics (per supplier, per SKU-supplier relationship):**
> - Unit cost history: time-series of unit_cost per SKU per supplier across all POs
> - Price stability index: standard deviation of unit cost over trailing 12 months
>   (low = stable, high = volatile pricing)
> - Price trend: regression slope of unit cost over time (rising / stable / falling)
> - Cost delta vs. alternatives: unit cost vs. other suppliers for the same SKU
>   expressed as % premium or discount
>
> **Tier 4 — Composite Supplier Score (per supplier, per SKU):**
> KloudShop computes a weighted composite score per supplier per SKU:
>   score = (on_time_rate × 0.35)
>         + (fill_rate × 0.25)
>         + (quality_score × 0.25)   -- 100 minus quality_event_rate
>         + (price_stability × 0.15) -- inverted: lower variance = higher score
>
> Weights are merchant-adjustable. A merchant who prioritises delivery speed over
> price can shift weights. Weights live in a per-tenant `supplier_score_weights`
> config — not hardcoded.
>
> Composite score is used as:
>   (a) The AI's basis for preference rank change suggestions
>   (b) A visual indicator on the supplier scorecard (score badge per supplier)
>   (c) Input to the AI reorder recommendation engine
>
> The composite score NEVER automatically changes preference_rank.
> It ONLY informs the merchant's decision. Procurement authority stays with the human.
>
> **Supplier Comparison View (per SKU):**
> When a merchant views a specific SKU's supplier panel, they see a side-by-side
> comparison table of all assigned suppliers with their current scores:
>
>   ┌──────────────────┬───────────┬──────────┬─────────┬──────────┬───────────┐
>   │ Supplier         │ On-Time % │ Fill Rate│ Quality │ Unit Cost│ Score     │
>   ├──────────────────┼───────────┼──────────┼─────────┼──────────┼───────────┤
>   │ Acme Parts (★1)  │ 66%       │ 94%      │ 97%     │ $4.20    │ 79/100    │
>   │ Global Supply(★2)│ 98%       │ 99%      │ 99%     │ $4.32    │ 97/100    │
>   │ FastFix Ltd  (★3)│ 88%       │ 91%      │ 95%     │ $3.95    │ 87/100    │
>   └──────────────────┴───────────┴──────────┴─────────┴──────────┴───────────┘
>   ⚠ "Global Supply scores 23% higher than your current rank-1 supplier
>      at only $0.12/unit more. Consider updating preference ranking."
>
> **Data Model additions for analytics:**
> - `supplier_score_weights` table (per-tenant config):
>   tenant_id, on_time_weight, fill_rate_weight, quality_weight, price_stability_weight
>   — defaults to (0.35, 0.25, 0.25, 0.15), merchant-adjustable
> - `supplier_scores` materialised view in BigQuery:
>   supplier_id, variant_id, window_days, on_time_rate, fill_rate, quality_score,
>   price_stability, composite_score, computed_at
>   — refreshed daily via Cloud Tasks scheduled BigQuery job
> - All `purchase_order_lines` must capture qty_received and discrepancy_flag
>   to feed fill rate and quality calculations accurately
