# Product Brief: KloudShop

> **Stage:** 1 — Idea Clarification
> **Persona:** Obsessive SaaS Founder
> **Approved:** [ ] pending

---

## The Problem

Mid-market and enterprise merchants are trapped on legacy platforms that punish their growth.
A B2B wholesaler on Shopify hitting $5M GMV faces a brutal choice: pay $2,300/month for Plus
just to unlock basic company accounts and custom pricing — or bolt on five expensive third-party
apps that break every time Shopify ships an update. Manufacturers running B2B and DTC
simultaneously maintain two separate stores, two codebases, two tech stacks — with inventory
perpetually out of sync between them. Every merchant using a non-Shopify payment gateway
gets taxed up to 2% of every transaction — a silent "growth tax" that bleeds tens of thousands
of dollars in margin annually. And when a new business need arises, the answer is always the
same: find an app, pay another monthly fee, and pray it doesn't conflict with the three apps
already installed. The platforms that were supposed to enable commerce have become its most
expensive cost centre.

---

## The Insight

Every incumbent was built B2C first, bolted B2B on as an enterprise paywall, and monetised
their own growth by taxing merchant revenue. Their "app store" model — which looks like an
ecosystem — is in reality a structured abdication of product responsibility, where merchants
pay third parties to fix gaps the platform should never have had. KloudShop inverts this
entirely: B2B and B2C are a single unified engine from day one, every feature is native and
free to toggle, and monetisation is fully aligned with merchant success through flat
subscriptions and transparent pass-through infrastructure costs. The platform that grows
with you without ever taxing you — that is the product nobody has built yet.

---

## Solution Overview

KloudShop is a next-generation e-commerce operating system that lets mid-market and enterprise
merchants run B2C storefronts, B2B wholesale portals, or both simultaneously from a single
account, single inventory, and single dashboard — with zero GMV fees, a native Feature
Catalogue (not an App Store), AI-powered consultative selling, and a competitor migration
engine that gets any merchant from Shopify, WooCommerce, Adobe Commerce, Wix, or Squarespace
to fully operational in minutes via high-speed Excel/CSV imports. (*Automated 2-minute scraper-based migration is a P1 feature deferred to post-MVP.*)

---

## Target Users

| Segment | Who They Are | Their Pain | Purchase Trigger |
|---------|-------------|-----------|-----------------|
| **Primary — B2B Distributor / Wholesaler** | Mid-market distributor, $1M–$50M GMV, currently on Shopify Plus or Magento. 50–500 corporate buyer accounts needing tiered pricing, net terms, and approval workflows. | Paying $2,300+/mo for Shopify Plus just for company accounts and custom price lists. B2B apps add $500–$1,500/mo and break on every platform update. | Shopify Plus renewal invoice. One too many app conflicts. Competitor undercutting them due to lower platform overhead. |
| **Secondary — Hybrid DTC + Wholesale Brand** | Mid-market brand ($500K–$20M GMV) selling direct-to-consumer AND to retail buyers from the same catalog. Needs two storefronts, one inventory. | Running two separate stores with manual inventory sync, duplicated SKU management, and split analytics. Hybrid tier eliminates all of this. | Inventory desync causing oversell. CFO questions on duplicated platform spend. |
| **Tertiary — Enterprise Manufacturer** | Manufacturer with complex product catalog, CPQ requirements, multi-region operations, >$50M GMV. | Adobe Commerce requires a dedicated dev team for every feature. Platform upgrades break custom modules. Every sprint is a maintenance sprint, never a growth sprint. | Developer team attrition. Adobe Commerce licence renewal. Platform instability incident. |

---

## Platform

- [x] **Web App — Desktop browser (MVP):** Full merchant admin + storefront management via Flutter Web. Fully responsive, desktop-optimised UI. Primary power-user surface.
- [x] **iOS — Mobile app (MVP):** Flutter iOS merchant app for on-the-go store management, order monitoring, and push notifications.
- [x] **Android — Mobile app (MVP):** Flutter Android merchant app, feature-parity with iOS.
- [ ] **Windows / macOS / Linux native desktop apps:** Out of scope for MVP. Revisited post-launch based on Feature Request Channel demand.

> **Storefront delivery:** Flutter Web storefronts, server-side rendered via FastAPI for SEO
> performance and machine-readability. Every storefront is fully SEO-optimisable with
> human-friendly KloudShop-generated URLs (e.g., `storename.kloudshop.com/category/product-slug`)
> for merchants not using custom domains, and full custom domain support with automatic SSL
> for those who do. One-click seamless theme switching is a core MVP technical requirement.

---

## Business Model

**Three-tier flat subscription — zero GMV fee, zero transaction fee, zero gateway penalty.**

**30-day free trial — terms:**
- No credit card required to start. All functionality available including Feature Catalogue, analytics, and storefront publishing.
- **$5 GCP credit** included per trial account (tenant-scoped). When exhausted, all GCP resources are hard-stopped immediately regardless of remaining trial days.
- **$600 GMV cap** during trial. When cumulative storefront sales reach $600 (pre-tax, all channels), selling is hard-stopped. Store data remains intact; merchant must upgrade to continue selling.
- **Hard stop at 30 days** if no paid tier selected. A published closing datetime (trigger + 168 hours, rounded to next 00:00 GMT) is shown to the merchant. An unpublished 48-hour grace period follows, giving 216 hours total before permanent deletion. During this window the merchant can download all data or upgrade to retain everything. After the 216-hour window: product catalogue, images, orders, customer records, analytics, and storefront slug are permanently deleted. The Firebase Auth account and platform record are soft-deleted and retained indefinitely for re-engagement — never hard-deleted.
- **Trial scope:** Merchant chooses exactly one of DTC or B2B at signup. Full feature depth of the chosen tier is available during trial. Hybrid (DTC + B2B simultaneously) is a paid-only tier at $49.99/mo — not available during trial. All three hard-stop rules ($5 GCP credit, $600 GMV cap, day-30) apply identically to both DTC and B2B trial accounts.

---

## Payment Infrastructure & Founder Payout Architecture

> This section documents KloudShop's binding payment decisions, billing
> infrastructure, and founder payout route as operational decisions for
> the platform build. These are internal decisions — not merchant-facing copy.

---

### The Two Completely Separate Payment Flows

```
FLOW 1 — Consumer → Merchant (storefront purchases)
────────────────────────────────────────────────────
Consumer buys goods from a KloudShop merchant storefront.
Payment goes directly to the merchant via Stripe Connect
Direct Charges. KloudShop platform account never holds
these funds at any point. KloudShop takes zero application
fee on this flow. Standard Stripe processing fees apply.

FLOW 2 — Merchant → KloudShop (subscription + GCP billing)
─────────────────────────────────────────────────────────────
Merchant pays KloudShop for:
  (a) monthly subscription tier fee, and
  (b) monthly GCP infrastructure usage (cost × 1.15)
This flows to the KloudShop UK Ltd Stripe account,
then onward via Payoneer to the founder's HBL account.
```

---

### Decision 1 — KloudShop billing platform

**Stripe Connect (via KloudShop UK Ltd)**

KloudShop operates a Stripe platform account registered to a UK Private Limited
Company with a non-resident Pakistani director. This is the single billing entity
for both flows.

**Why UK Ltd, not Paddle:**
Paddle would require KloudShop to collect subscription fees as a Merchant of
Record — creating a perception that KloudShop handles merchant money even for
SaaS billing. Stripe Connect via a UK Ltd is architecturally cleaner, eliminates
this perception entirely, and gives full programmatic control over billing.
Paddle fees (~5% + $0.50) also become material at scale; Stripe's fees are lower.

**UK Ltd setup — what is required:**
| Item | Cost |
|------|------|
| Companies House formation (online) | £13 one-time |
| Virtual registered office address | £5–15/month |
| Annual Confirmation Statement | £13/year |
| Annual accounts + Corporation Tax return (accountant) | £200–300/year |
| Stripe account (linked to UK Ltd) | Free |
| **Total year 1 (low end)** | **~£350–450** |

No UK resident director required. Pakistani founder as sole non-resident
director is fully permitted under UK company law.

**Development → Production path:**
- During development: Stripe test/debug keys (`sk_test_...`)
- At launch: UK Ltd formed → Stripe account approved → live keys (`sk_live_...`)
- Zero application code changes between test and live — only key rotation

---

### Decision 2 — Consumer-to-merchant payment processing

**Stripe Connect Direct Charges**

When a consumer purchases from a KloudShop merchant storefront:
- The charge is made directly on the merchant's Stripe connected account
- Funds go directly to the merchant — never to KloudShop
- KloudShop takes zero application fee on consumer-to-merchant transactions
- Standard Stripe processing fees are deducted by Stripe only
- KloudShop's platform account is never in the money flow

This preserves KloudShop's core positioning: zero transaction fees, zero
GMV rake, zero platform tax on merchant revenue. It also eliminates any
merchant trust concern — KloudShop provably never touches their sales revenue.

**Merchants as Stripe Connect connected accounts:**
Every KloudShop merchant connects their existing Stripe account (or creates one)
to KloudShop via Stripe Connect OAuth. This is a one-time setup during merchant
onboarding. Merchants in Stripe-unsupported countries cannot onboard at launch —
an accepted scope limitation given the target market (US, UK, EU, AU, CA).

---

### Decision 3 — Consumer checkout payment methods

All methods are Stripe-native — enabled through the merchant's connected
Stripe account. No separate KloudShop integration required for any method.

**Universal (all storefronts):**
| Method | Type | Region |
|--------|------|--------|
| Visa / Mastercard / Amex | Card | Global |
| Apple Pay | Wallet | iOS / Safari |
| Google Pay | Wallet | Android / Chrome |
| Klarna | BNPL | Global |
| Afterpay / Clearpay | BNPL | Global |
| iDEAL | Local | Netherlands |
| SEPA Direct Debit | Local | EU |
| BACS Direct Debit | Local | UK |
| BECS Direct Debit | Local | Australia |
| GrabPay | Local | Southeast Asia |
| Alipay | Local | China / global |

**B2B checkout only:**
| Method | Type | Notes |
|--------|------|-------|
| Bank transfer with net terms | Invoice | Net-30/60/90 via Stripe Invoicing |

**Explicitly not supported at storefront checkout:**
- Payoneer — business payout tool, not a consumer checkout method.
  Payoneer remains as the founder payout mechanism only.
- Facebook Pay / Meta Pay — Facebook/Instagram commerce is handled through
  the native Social Commerce channel integrations (SC-01, SC-03), not at
  the KloudShop storefront checkout layer.
- PayPal — deferred post-PMF. Requires a separate integration beyond Stripe.
- MBWay (Portugal) — requires direct SIBS API. Deferred post-MVP.
- Cash on delivery — untracked, out of scope.

---

### Decision 4 — Founder payout route

**UK Ltd Stripe → Payoneer → HBL USD (primary) / HBL PKR (fallback)**

```
Merchant pays KloudShop subscription + GCP charges
         │
         ▼
Stripe (KloudShop UK Ltd platform account)
  — subscription billing via Stripe Billing
  — metered GCP pass-through via Stripe usage records
  — standard Stripe processing fees deducted
         │
         ▼
Payoneer (founder business account — virtual US bank)
  — USD held here — never forced into Pakistan banking
  — pay GCP platform costs directly from Payoneer in USD
  — transfer to HBL only as and when needed
         │
         ├─► Pay GCP bills in USD from Payoneer directly
         │   (clean USD loop, no conversion)
         │
         └─► Transfer to HBL as needed:
               HBL USD Foreign Currency Account (primary)
               — holds USD without forced PKR conversion
               — convert to PKR at founder's chosen timing
               HBL PKR account (fallback)
               — if USD FCA not yet opened
               — conversion at HBL daily interbank rate
```

**Immediate pre-launch action items:**
1. Form UK Ltd via Companies House online (£13, same-day) —
   virtual registered office address required (£5–15/month)
2. Register Stripe account linked to UK Ltd
3. Open Payoneer business account — link to HBL USD FCA
4. Open HBL Foreign Currency Account (USD FCA) — existing HBL
   customer makes this straightforward
5. During development: use Stripe test keys throughout
6. At launch: rotate to Stripe live keys — zero code changes

**Pakistani regulatory note (informational — not legal advice):**
Receiving USD payments from UK Ltd via Payoneer into HBL is permissible
under Pakistan's foreign exchange regulations as foreign remittance income.
Consult a Pakistani tax consultant before first payout to confirm income
tax treatment and SBP declaration requirements.


---

## The Feature Catalogue (Anti-App-Store Architecture)

KloudShop's answer to Shopify's app bloat is architectural, not cosmetic.

**The Principle:** Every capability that competing platform merchants must purchase as a
third-party app is built natively into KloudShop's core and included in the flat subscription
at zero additional cost. There is no App Store. There are no installs. There are no per-app
monthly fees. There is a **Feature Catalogue** — a curated library of native platform
capabilities that merchants toggle on or off from their dashboard.

**The Perpetual Feature Request Channel:** KloudShop operates an always-open community
feature request board, accessible exclusively to authenticated merchants on any paid tier
or active trial. It is not a public forum — only verified KloudShop users can submit
requests and cast votes. KloudShop commits to delivering the top-voted features as native
platform capabilities — never third-party integrations — as internal development capacity
permits. This creates a self-reinforcing flywheel: the platform gets better, churn drops,
the community grows.

**Examples of native toggleable features (never sold as apps):**
- Abandoned cart recovery
- Email marketing automation
- Product reviews and UGC
- Advanced analytics and reporting
- Loyalty and rewards programmes
- Subscription and recurring orders
- Bundle builder and upsell/cross-sell flows
- Discount engine and promotion management
- Affiliate and referral tracking
- Gift cards and store credit
- Rule-based dynamic pricing (stock-age markdowns, velocity-based pricing, time-triggered promotions)
- AI-powered product recommendations (PDP + cart — personalised per customer)
- POS integration (unified online + physical store inventory via KloudShop-native POS interface — staff open KloudShop in a browser on any device, log in with POS Operator role, and process in-store sales directly; no external POS hardware or third-party POS system required)
- Social commerce channels (TikTok Shop, Instagram Shopping, Facebook Shops)
- Google Shopping feed (native product feed generation and sync)
- Automated tax compliance (US sales tax, VAT, GST — powered by Stripe Tax, calculated through each merchant's own connected Stripe account)
- Multi-location inventory (multiple warehouses/stock locations, manual allocation)
- Full data export (on-demand hierarchical CSV/JSON export of all merchant data — no KloudShop platform charge; standard GCP infrastructure pass-through costs apply for large exports)
- Native internal messaging (staff↔staff, merchant↔B2B buyer — DMs + context-linked threads on orders, POs, SKUs, and buyer accounts; file attachments; full archive; FCM push notifications)
- Native blog (merchant-published blog with rich-text editor, SEO metadata per post, featured images, post scheduling, categories and tags, AI auto-translation to all enabled locales, XML sitemap inclusion, JSON-LD Article structured data — no third-party blogging platform required)
- AI Copywriter (one-click Gemini-powered generation and enhancement of product titles, product descriptions, and blog posts into high-converting copy — grounded in the merchant's Brand Voice profile; three differentiated variants generated per request, each editable before acceptance; no copywriting skill required; GCP pass-through billable)

No third party. No install. No extra fee. Ever.

---

## Migration Engine

KloudShop's onboarding moat and single most powerful acquisition tool.

**How it works:**
1. New merchant provides their existing store URL (Shopify, WooCommerce, Adobe Commerce,
   Wix, or Squarespace).
2. KloudShop scrapes **product catalog and SEO metadata only** — compliant with competitor
   platform scraping policies. Customer PII and order history are never scraped.
3. Scraped data is parsed by the AI layer and auto-imported into a fully populated KloudShop
   store within 2 minutes.
4. For customer records and order history: merchants export CSV/Excel from their current
   platform and upload to KloudShop. The AI import engine is **format-agnostic and
   error-forgiving** — it handles inconsistent column naming, missing fields, mixed date
   formats, and malformed rows without requiring clean or pre-formatted data.
   Imported orders are flagged as historical records (`order_source: imported`) and
   are excluded from KloudShop financial reporting, billing reconciliation, and
   Stripe payment processing. Only orders placed natively through KloudShop are
   treated as live financial transactions.
5. KloudShop generates a personalised, step-by-step migration runbook covering DNS cutover,
   301 redirect mapping, SEO equity preservation, payment gateway reconfiguration, and
   staff onboarding — tailored to the merchant's specific source platform.

**What is scraped:** Product titles, descriptions, prices, variants, images, collections,
meta titles, meta descriptions, URL slugs, structured data markup.

**Platform fidelity note:** Data fidelity varies by source platform. Shopify and
WooCommerce expose well-structured product data and yield the highest import fidelity.
Adobe Commerce requires Playwright for JS-rendered pages. Wix and Squarespace have
more restrictive export structures and less standardised metadata — imports from these
platforms may require more merchant review of the AI mapping step before going live.

**What is never scraped:** Customer names, emails, addresses, order history, payment data.

---

## Storefront System

- **Free Flutter-native theme library** covering almost every business sector niche
  (fashion, electronics, food & beverage, industrial B2B, furniture, health & beauty,
  automotive parts, home décor, sporting goods, digital products, and more).
  All themes are free, always. No premium tier, no theme upsell, no marketplace.
- **One-click seamless theme switching:** Merchants switch their entire storefront theme
  in a single click without losing content, products, SEO settings, or configurations.
  Zero downtime. Core MVP technical requirement.
- **WYSIWYG Theme Editor (no JSON, no code):** Merchants customise their active theme
  through a structured three-panel visual editor — never by editing JSON directly:
  - **Left panel:** Drag-to-reorder component stack. Add new component instances
    (e.g. a second `horizontal_scroll_strip` for a different collection). Remove
    components. Reorder with drag handles.
  - **Centre panel:** Live storefront preview — the actual Flutter storefront renderer
    running inside the admin UI. Changes appear instantly. Switchable viewport:
    mobile / tablet / desktop.
  - **Right panel:** Component configuration form for the selected component —
    collection selector, column count, animation pickers, content slots, image
    upload, design token overrides. Every parameter maps to a `theme.json` field;
    the merchant never sees the JSON.
  The WYSIWYG is a structured configuration tool, not a free-form pixel editor.
  Merchants configure within defined component parameters — this prevents broken
  layouts by design. The output is always valid `theme.json`.
- **Dual storefronts for Hybrid tier:** One consumer-facing DTC storefront and one B2B
  buyer portal, each with independent themes, navigation structures, and pricing rules —
  both drawing from a single shared inventory, managed from one KloudShop account.
- **Zero-code theme catalogue — themes are data, not code:** Every theme in the KloudShop
  library is a JSON configuration file stored in Cloud Storage — not a hardcoded template
  in the application codebase. Adding a new theme to the catalogue requires no code
  changes, no CI/CD pipeline run, and no production deployment. A theme designer uploads
  a `theme.json` config + asset package to Cloud Storage, inserts one row into the theme
  registry, and the theme is instantly available to all merchants. The Flutter storefront
  is a universal rendering engine that reads the theme config at runtime — it never
  hardcodes a colour, font, layout, or component order.
- **Content and theme are completely separate concerns:** Storefront marketing text
  (hero headings, subheadings, CTA labels, banner copy, page text) is merchant-owned
  content stored in the tenant's database — never inside `theme.json`. The theme defines
  *where* content slots exist and *what type* of content they accept. The merchant's
  actual words and images live in the `storefront_content` table, keyed per slot. When
  a merchant switches themes, all their content carries forward automatically to matching
  slots. New slots introduced by the new theme are flagged in the WYSIWYG as empty —
  the merchant fills only the delta, never re-enters existing copy.
- **Scaffold-level persistent components (always present, not in scrollable body):**
  Three components live outside the scrollable body stack — they are scaffold fixtures
  that persist across every storefront page, configured in a dedicated `scaffold`
  section of `theme.json`:
  - `app_bar` — top persistent bar: merchant logo, search bar, cart icon, account icon,
    optional announcement text. The Flutter `AppBar` equivalent. Configured once,
    appears on every page of the storefront.
  - `nav_bar` — navigation bar: category links, custom pages (About, Contact, FAQ),
    mega-menu support. Sits below the app_bar. Supports hover-triggered dropdown panels
    (see hover-reveal below).
  - `footer` — bottom persistent bar: configurable link groups, social icons, newsletter
    signup, legal links. Always present; not part of the scrollable component stack.

- **Scrollable body component library (the `component_order` stack):**
  Every component in `component_order` is a pre-built Flutter widget with a fixed
  internal structure and fully configurable parameters from `theme.json`. The renderer
  never receives a layout image or template — it reads JSON and instantiates the widget.

  **Multi-instance by design — every component type is repeatable.**
  `component_order` is an array of `{id, type}` objects. `component_config` keys on
  instance ID. Any component type can appear any number of times with independent config.
  This applies to ALL component types — not just strips. Multiple `hero_banner` instances,
  multiple `cta_block` sections, multiple `carousel` rows, multiple `product_grid`
  sections for different collections. No component type is single-instance restricted.

  **Base body component library:**
  - `video_hero` — full-bleed video header: autoplay, muted, overlay text, mobile
    fallback image. Repeatable.
  - `hero_banner` — static image hero with CTA overlay, configurable text position.
    Repeatable (e.g. two hero banners for different seasonal promotions).
  - `carousel` — auto-advancing or manual slide carousel of images or products.
    Repeatable.
  - `cta_block` — standalone call-to-action section with heading, body, button.
    Repeatable (multiple CTAs at different scroll depths).
  - `featured_collections` — curated collection grid, configurable column count.
    Repeatable.
  - `product_grid` — configurable columns, card style, quick-add, rating display.
    Repeatable (e.g. one grid per collection).
  - `horizontal_scroll_strip` — swipeable product/collection row, titled, linkable.
    Repeatable (Men's, Kids', Footwear each as separate instances).
  - `ai_assistant_panel` — RAG-powered consultative search panel, configurable trigger.
  - `reviews_strip` — customer review cards, configurable display count. Repeatable.
  - `announcement_bar` — inline promotional banner (distinct from app_bar announcement).
    Repeatable.
  - `shoppable_video` — video with embedded product hotspot overlays. Repeatable.
  - `divider` — visual section separator, configurable style and spacing.

- **Hover-triggered component reveal (slide-in of initially hidden components):**
  Any component instance can declare a `reveal_on_hover` relationship referencing
  another component instance ID. The target component starts `initially_hidden: true`
  and animates into view when the trigger is hovered — and hides on blur. Primary use
  case: navigation item hovering reveals a mega-menu dropdown. The trigger and target
  are both standard component instances in `component_config` — no special widget type
  required. The Flutter renderer manages the visibility state reactively.

- **Card styling — shared `card_style` block per component:**
  Components that render card-shaped items support a `card_style` config block with
  full Flutter card styling parameters:

  | Property | Description | Example value |
  |----------|-------------|--------------|
  | `height` | Card height in logical pixels | `320` |
  | `border_color` | Card border colour (hex) | `"#E0E0E0"` |
  | `border_width` | Border stroke thickness in dp | `1.0` |
  | `border_radius` | Corner radius in dp (overrides global token) | `8` |
  | `elevation` | Card shadow elevation (dp) | `2.0` |
  | `shadow_color` | Shadow colour with opacity (hex+alpha) | `"#00000020"` |
  | `shadow_offset_x` | Shadow horizontal offset | `0` |
  | `shadow_offset_y` | Shadow vertical offset | `2` |
  | `shadow_blur_radius` | Shadow blur spread | `8` |
  | `on_hover_background` | Card background colour on hover | `"#F5F5F5"` |
  | `on_hover_elevation` | Elevation when hovered | `6.0` |
  | `on_hover_border_color` | Border colour when hovered | `"#BDBDBD"` |

  Components with card-rendered items (all support `card_style`):
  `product_grid`, `horizontal_scroll_strip`, `featured_collections`,
  `reviews_strip`, `shoppable_video`, and any future strip/grid component.

- **Animation system — every component supports an optional animation config block:**
  All animation fields are nullable — `null` or absent means no animation.
  A fully static theme is always valid. Animations are opt-in, never required.

  | Field | Valid values | Notes |
  |-------|-------------|-------|
  | `enter` | `fade_in`, `fade_up`, `fade_down`, `slide_in_left`, `slide_in_right`, `zoom_in`, `none` | Triggers on component scroll into viewport |
  | `exit` | `fade_out`, `slide_out_left`, `slide_out_right`, `zoom_out`, `none` | Triggers on scroll out of viewport |
  | `hover` | `scale_up`, `scale_down`, `color_shift`, `shadow_deepen`, `underline`, `brightness_up`, `none` | Per-item hover effect |
  | `enter_duration_ms` | Integer, 100–2000ms | Animation speed |
  | `enter_delay_ms` | Integer, 0–1000ms | Stagger delay for grid items |
  | `hover_duration_ms` | Integer, 50–500ms | Hover transition speed |
  | `scale_factor` | Float, 0.8–1.5 | Required when `hover` = `scale_up` or `scale_down` (e.g. `1.05` = 5% growth) |
  | `zoom_factor` | Float, 1.0–3.0 | Required when `enter` = `zoom_in` or `exit` = `zoom_out` (e.g. `1.2` = 20% zoom) |
  | `reveal_on_hover` | Component instance ID string | Trigger: this component's hover reveals the target |
  | `initially_hidden` | Boolean | Target: starts hidden, revealed by trigger's `reveal_on_hover` |
  | `hide_on_blur` | Boolean | Target: hides when hover leaves the trigger+target area |
  | `hide_animation` | Same enum as `exit` | Animation when the revealed component hides |
  | `hide_duration_ms` | Integer, 50–500ms | Speed of hide animation |

  Theme designers compose, order, repeat, and configure all components freely in JSON.
  New component types require one engineering task when design paradigms shift.
- **Visual appearance via design tokens:** Component structure defines *what* renders
  and *how it behaves*. Visual appearance — how the theme actually looks — is controlled
  separately via design tokens in the same `theme.json` file:
  - `color_tokens` — primary, accent, surface, background, text, border, error colours
  - `typography` — heading font family, body font family, font scale (compact/regular/large),
    font weights, line heights
  - `spacing` — base spacing unit, component padding, grid gap, section vertical rhythm
  - `border_radius` — card corners, button corners, image corners (sharp/soft/pill)
  - `elevation` — shadow depth style (flat/subtle/elevated) for cards and modals
  - `motion` — transition speed (instant/fast/relaxed) and easing curve for animations
  Every colour, font, spacing value, and animation in the storefront is driven by these
  tokens — never hardcoded in the Flutter renderer. A theme designer changes the entire
  visual character of a storefront by updating token values in JSON, without touching
  a single line of Flutter code.
- **Component Registry evolution — staying current with design systems:** When a new
  UI component type becomes ubiquitous in prevailing design systems (signalled by
  Feature Request Channel votes, repeated theme designer requests, or major design
  system releases), KloudShop adds it to the component library as a single engineering
  task and bumps the theme schema version. Existing themes continue rendering perfectly
  via backward-compatible schema versioning — no merchant storefront ever breaks.
  Theme designers can immediately adopt the new component by updating their `theme.json`
  only — zero code, zero deployment.
- **SEO-first storefront architecture:**
  - Human-friendly URLs by default: `storename.kloudshop.com/category/product-name`
  - Full custom domain support with automatic SSL provisioning
  - Canonical tags, XML sitemap generation, robots.txt control
  - Structured data markup (JSON-LD) for products, breadcrumbs, reviews, and blog articles — native
  - Meta title and description editing on every page — no SEO app required
  - 301 redirect manager built into the dashboard
  - Native blog at `storename.kloudshop.com/blog` — merchant-published posts included in XML sitemap, with JSON-LD Article structured data and AI-translated versions at locale-prefixed URLs
  - Core Web Vitals optimisation is a first-class engineering requirement, not an afterthought

---

## Key Differentiators

| Differentiator | Why It Matters | Why Competitors Can't Just Copy It |
|---------------|---------------|-------------------------------------|
| **Zero GMV / transaction fee — ever** | At $5M GMV, a Shopify Plus merchant on a third-party gateway pays ~$100K/year in platform taxes. KloudShop charges $599.88/year flat. | Shopify's entire growth model depends on GMV rake. Removing it collapses their revenue. Structurally impossible to copy without destroying their stock price. |
| **Feature Catalogue, not App Store** | Merchants never pay extra for capabilities. No app conflicts, no breakage on platform updates, no $50/mo per feature. Every capability is native and toggleable. | Shopify's app ecosystem generates significant partner and marketplace revenue. Killing it would alienate 10,000+ developers and destroy a core GTM channel. They cannot copy this. |
| **Unified B2B + B2C from day one** | No enterprise paywall. A $39.99/mo merchant gets parent-child accounts, custom catalogs, credit limits, and approval chains — features Shopify locks behind $2,300/mo. | Shopify's B2B was built on a different data model. Unifying it requires a platform rewrite. Adobe Commerce's B2B module is a separate paid SKU. |
| **Hybrid dual-storefront, single inventory** | Run DTC and wholesale from one account at $49.99/mo vs. two separate Shopify stores at $100+/mo each with manual inventory sync. | Shopify would need to rebuild multi-storefront at the core data layer — a platform restructure, not a feature addition. |
| **Competitor Migration Engine (2-minute onboarding)** | Paste your store URL → populated store + full migration runbook in under 2 minutes. CSV import is AI-parsed, format-agnostic, error-forgiving. | No competitor has any incentive to build a best-in-class import tool from their own platform. KloudShop has the only asymmetric motivation to build this better than anyone. |
| **Born-for-Agents AI layer** | Structured data API optimised for machine-readability. AI shopping assistants query inventory, validate B2B pricing, and complete checkouts with zero AI referral tax. | Shopify is building a 4% AI referral fee model. KloudShop's fee neutrality guarantee explicitly covers agentic transactions — structural, not cosmetic. |
| **Consultative AI (RAG-powered storefronts)** | Storefront answers natural language buyer questions grounded in the actual product catalog. Acts as a digital sales engineer, not a chatbot. | Requires deep Vertex AI + product data integration baked into the storefront layer. Legacy platforms treat AI as a text-generation bolt-on. |
| **Pass-through cloud pricing** | Merchants pay actual GCP cost × 1.15 — a single fixed 15% markup, itemised by resource. As GCP costs drop, merchant bills drop. No hidden fees, no variable rake, ever. | Shopify, BigCommerce, and Adobe Commerce embed infrastructure costs invisibly. Transparent pass-through is structurally incompatible with their pricing models. |
| **Free theme library, one-click switching** | Every niche covered. No $300 theme purchase. No developer required to switch themes. Storefront evolves with the brand at zero cost. | Shopify's theme marketplace generates significant partner revenue. A fully free library with instant switching kills that stream — they will not do it. |
| **Unlimited product variants — no artificial caps** | Shopify raised their variant cap from 100 to 2,000 in 2025 — a belated concession to enterprise merchants. But 2,000 is still an arbitrary ceiling. A complex industrial manufacturer with 500 component specifications per SKU, or an apparel brand with size + colour + material + fit + regional sizing across hundreds of styles, still hits that wall. KloudShop imposes zero variant limits — no ceiling, ever. | Even after raising the cap to 2,000, Shopify's variant ceiling is still a data model constraint. Their architecture cannot support unlimited variants without a platform-level schema redesign. KloudShop's schema is designed variant-unlimited from day one — this cannot be retrofitted by Shopify. |
| **Native POS integration — unified online + physical inventory** | Merchants with physical stores stay on Shopify primarily because of Shopify POS, which requires proprietary hardware and Shopify Payments. KloudShop's POS requires nothing more than a browser — staff log in with their POS Operator role on any existing device (tablet, laptop, desktop) and process in-store sales directly. Inventory decrements in real time from the same pool as online orders. No hardware investment. No separate POS system. No training beyond "open a browser." | Shopify POS requires proprietary hardware (Shopify POS terminals, card readers) and is tightly coupled to Shopify Payments. KloudShop's browser-native POS approach requires zero hardware investment and zero third-party POS software — any device with a browser is a POS terminal. |
| **Native social commerce — TikTok Shop, Instagram, Facebook Shops** | A merchant whose product goes viral on TikTok needs their KloudShop inventory directly connected to TikTok Shop without a third-party sync app. Native social commerce channels mean a viral moment converts into revenue without a broken sync causing oversells. | Social platform APIs change constantly. Shopify maintains these integrations as app-store partnerships, not native features — meaning breakages are the app developer's problem, not Shopify's. KloudShop owns these integrations natively. |
| **Native Google Shopping feed** | Every KloudShop product catalog automatically generates a Google Shopping feed — products appear in Google Shopping results without a feed management app or manual CSV upload. The feed updates in real time as inventory and pricing changes. | Shopify requires a third-party app or manual Google Merchant Center integration. Feed staleness (showing out-of-stock items in Google Shopping) is a common merchant pain point. |
| **Rule-based dynamic pricing engine** | Automatic price adjustments based on stock age (markdown unsold inventory progressively), stock velocity (raise prices on fast-moving items), and time-based triggers (flash sale windows). No developer required. No third-party repricing app. | Shopify's discount engine is static — merchants set a discount, it runs. Dynamic rule-based repricing based on real-time inventory signals requires a third-party app (e.g. Prisync, Wiser) at $100–$500/mo. |
| **AI-powered product recommendations (native, PDP + cart)** | Every product detail page and cart shows AI-curated "frequently bought together" and "customers like you also bought" recommendations — trained on the merchant's own co-purchase data via BigQuery ML. No recommendation app. No JavaScript injection. Zero performance penalty. | Shopify's native recommendations are basic. Meaningful AI recommendations require third-party apps (e.g. LimeSpot, Frequently Bought Together) that inject JavaScript and degrade Core Web Vitals scores. |
| **Native automated tax compliance (US, VAT, GST)** | Tax calculation at checkout is automatic — US sales tax nexus rules across 50 states, EU VAT, AU/CA GST — powered by Stripe Tax, built directly into each merchant's connected Stripe account. KloudShop surfaces Stripe Tax embedded components inside the merchant admin so merchants configure their tax registrations without ever leaving KloudShop. Tax liability stays with each merchant — exactly where it belongs for a SaaS platform model. | Shopify uses TaxJar and Avalara as third-party app integrations — merchants pay extra and manage a separate integration. WooCommerce requires manual tax configuration or a paid plugin. KloudShop uses Stripe Tax natively — no additional vendor, no extra cost, no separate integration. |
| **Multi-location inventory management** | Merchants with multiple warehouses, fulfilment centres, or store locations manage all stock from one KloudShop dashboard. Per-location stock levels, stock transfers between locations, and fulfilment routing by location — all native. | Shopify charges extra for multi-location beyond a low free tier. WooCommerce requires a paid WMS plugin. No competitor includes true multi-location inventory natively across all plan tiers. |
| **Full data portability — on-demand, always free** | Every merchant can export their complete data — products, orders, customers, analytics, B2B accounts — as hierarchical CSV or JSON at any time, for free, with no account closure required. Your data is always yours. No lock-in. | Shopify's full data export requires multiple separate exports and excludes analytics history. WooCommerce is the benchmark here (full database ownership) — KloudShop matches that guarantee in a SaaS model. |
| **Zero platform lock-in on local payment methods** | Merchants in any country can use their locally preferred payment gateway — MBWay (Portugal), iDEAL (Netherlands), GrabPay (Southeast Asia), Alipay (China), Klarna/Afterpay (BNPL globally) — with zero KloudShop transaction penalty. Most methods (iDEAL, GrabPay, Alipay, Klarna, Afterpay, SEPA, BACS, BECS) are available natively through Stripe's payment method API — enabled at the checkout layer with no separate integration. MBWay requires a direct SIBS API integration (not Stripe). All are handled through KloudShop's gateway-agnostic FastAPI payment abstraction layer. | Shopify taxes merchants up to 2% for using any non-Shopify Payments gateway — a direct financial penalty on merchants legally required to offer local payment methods. This is structurally impossible for Shopify to remove without destroying their payments revenue. |
| **Native internal messaging platform** | Staff communicate internally and with B2B buyers directly inside KloudShop — no email, no Slack, no WhatsApp. Messages are context-linked to orders, POs, SKUs, and buyer accounts. Full archive, full search, FCM push notifications, file attachments. No platform charges extra for this. | No e-commerce platform — Shopify, BigCommerce, Adobe Commerce — offers native contextual messaging. Merchants are forced to manage customer and team communication in entirely separate tools, losing the operational context that KloudShop preserves natively. |
| **Native blog — SEO content engine built in** | Every KloudShop merchant has a native blog at their storefront domain. Rich-text editor, post scheduling, categories and tags, SEO metadata per post, featured images, JSON-LD Article structured data, XML sitemap inclusion, and AI auto-translation to all enabled languages — all native, zero third-party app. Blog posts live at `storename.kloudshop.com/blog/post-slug` and contribute directly to the merchant's organic search ranking. | Shopify requires a separate blogging app or relies on its built-in basic blog that lacks AI translation, structured data generation, and multilingual SEO support. WooCommerce merchants need WordPress but that adds a full CMS stack to manage. KloudShop's blog is native, SEO-first, and multilingual from day one. |
| **AI Copywriter — free marketing expert for every merchant** | Every merchant gets one-click Gemini-powered copy generation for product titles, product descriptions, and blog posts — grounded in their Brand Voice profile (tone, target audience, adjectives, style rules, competitor avoidance). Three differentiated variants per request, all editable before acceptance. No copywriting app. No agency. No extra subscription. | Shopify Magic and similar tools are either paywalled, brand-voice-unaware (generic output with no grounding), or produce a single variant with no editorial choice. KloudShop's AI Copywriter is brand-aware, produces three strategically differentiated options, and costs the merchant only the Gemini inference GCP pass-through — fractions of a cent per generation. |

---

## Constraints & Flagged Assumptions

**Hard Constraints:**
- Solo human founder + AI engineering team. Architecture must prioritise AI-agent
  maintainability: strong typing, clear separation of concerns, comprehensive API contracts,
  and thorough inline documentation throughout.
- GCP-native stack (non-negotiable). All infrastructure within GCP ecosystem to maintain
  transparent pass-through billing.
- **Multilingual LTR support from day one.** KloudShop launches with support for
  English plus a defined set of LTR European languages: German (de), French (fr),
  Swedish (sv), Norwegian (no), Danish (da), Dutch (nl), Spanish (es),
  Portuguese (pt), and Italian (it). Product titles, descriptions, storefront
  content, collection names, and SEO metadata are all translatable. AI-powered
  auto-translation (Google Cloud Translation API) generates translations automatically
  when merchants enter English content — no manual copy-paste required.
  Merchants review and override AI translations from their Language Settings.
  Only the locales a merchant explicitly enables are active on their storefront.
- **RTL languages (Arabic, Hebrew, Urdu) explicitly deferred.** Bidirectional
  Flutter layout requires substantial layout engine changes. Post-MVP.
- All Flutter admin UI strings are in ARB files from day one — adding a new
  admin UI language requires only a new ARB file, no code changes.
- No fixed launch deadline. MVP ships when the three pillars are fully functional.
- PCI-DSS compliance mandatory (payment processing).
- GDPR compliance required for UK/AU markets at launch.
- Storefront scraping limited to catalog and SEO data only — never customer PII or order
  history — to remain compliant with competitor platform terms of service.
- KloudShop storefronts are the only supported frontend. Headless commerce (merchants
  bringing their own frontend) is explicitly out of scope — this keeps the platform
  surface area manageable for a solo AI team.
- ERP/CRM pre-built connectors (Salesforce CRM, HubSpot, SAP) are post-MVP. The native
  webhook + API framework available to Developer/Integrator role users covers custom
  integrations in the interim.

**Assumptions Requiring Validation:**
- Flutter Web storefronts can achieve Google Core Web Vitals scores competitive with
  Next.js SSR. *Action: CWV benchmark sprint in Phase 0 before committing Flutter Web
  for public storefronts.*
- The migration scraper can reliably extract structured data from Shopify, WooCommerce,
  and Adobe Commerce without triggering bot-protection at scale. *Action: Technical spike
  in first sprint.*
- Mid-market merchants will self-serve onboard without a sales-assisted motion.
  *Action: 10 user interviews with Shopify Plus merchants before beta.*
- Pass-through GCP billing at a fixed 15% markup is commercially viable at low merchant counts
  (<500 stores). Merchant monthly bill = actual GCP cost × 1.15. *Action: Unit economics model at 100, 500, and 2,000 merchants.*
- One-click theme switching can be implemented without storefront downtime or content loss
  across all niche templates. *Action: Storefront theming architecture spike in Phase 0.*

---

## Success Metrics

| Metric | 6-Month Target | 12-Month Target | Why This Metric |
|--------|---------------|-----------------|-----------------|
| Paying merchants (any tier) | 250 | 1,500 | Primary revenue signal; validates self-serve GTM motion |
| Migration engine completion rate | >75% of trial signups complete full migration | >85% | Proves the 2-minute win is real, not just a demo |
| Monthly Recurring Revenue (MRR) | $12,500 | $75,000 | Business sustainability signal |
| Hybrid tier attach rate | 30% of paying merchants | 40% | Validates unified B2B+B2C pitch; highest-value tier |
| Monthly churn rate | <5% | <3% | Platform stickiness; low churn = product-market fit |
| Feature Catalogue engagement | >60% of merchants activate 3+ native features | >75% activate 5+ | Validates anti-app-store positioning; depth of adoption |
| AI consultative layer conversion lift | Baseline established in beta | +15% vs. stores without AI layer | Validates Pillar 3 as a revenue driver, not just a feature |
| Storefront Google indexing rate | 50% of merchant stores indexed within 30 days of launch | 80% indexed, avg. position tracked | Proves SEO-first storefront architecture is working |
| NPS | >40 | >55 | Word-of-mouth growth in a community-driven market |
