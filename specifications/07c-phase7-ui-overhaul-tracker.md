# Phase 7 UI/UX Overhaul Progress Tracker (Sprint 19 - Restart)

> [!IMPORTANT]
> This progress tracker is specifically dedicated to the **Phase 7 UI/UX Overhaul Restart**. 
> It tracks the step-by-step UI transformation, state implementation, and designer mockup mappings. 
> It is not a replacement for the overall launch scheme or backend roadmaps.

## 1. Ground Rules & Technical Framework

### State Management Authority
*   We use **Riverpod** for frontend state management. All views must read/watch Riverpod providers for data loading, submitting, and validation states.
*   Providers are defined in [frontend/lib/providers/](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/providers/).

### Design & Styling Reference
*   All styles must adhere strictly to the Stitch-generated Design Token System: [stitch_design_alpine.md](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/scratch/stitch_design_alpine.md).
*   Standard UI elements (glassmorphism cards, buttons, input fields, tables) must utilize values from the Alpine Emerald theme.

### Mockup Archiving Protocol
*   When screen mockups are attached in the chat, they must be saved inside the [mock-screens/](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/mock-screens/) directory.
*   This tracker explicitly maps each saved mockup PNG name to its corresponding Dart widget and Riverpod providers to prevent design-code drift.

### Git Branching & Merging Protocol
To keep the code clean and prevent drift across separate journey chats, we enforce a strict branching protocol:
1.  **Branch Per Journey**: Each journey gets its own dedicated git branch branched directly from `dev` (e.g., `phase7/j1-auth`, `phase7/j2-catalog`).
2.  **Sequential Execution**: Only one journey is worked on at a time. Do not check out parallel branches for Tier 1 or Tier 2 journeys.
3.  **Completion & Pushing**: Once a journey is finished and all states are verified, commit the changes locally and push them to the remote repository.
4.  **Merge to Dev**: Merge the completed journey branch INTO the `dev` branch.
5.  **New Journey Checkout**: Before beginning a new journey, pull the latest `dev` branch to receive all previous improvements/styles, check out a new self-explanatory branch from `dev`, and verify that the checkout was successful before writing code.


### The 5 Mandatory UI States
Each view must fully implement the following five states (unless explicitly marked `N/A` for a specific view):
1.  **Default / Active State**: The standard fully loaded interactive UI.
2.  **Loading / Submitting State**: Skeletons or custom progress indicators (e.g. animated rocket pulse for provisioning, fading overlays for forms).
3.  **Error / Failure State**: Refined error banners or dialogs with retry actions.
4.  **Empty State**: Frosted cards or screens indicating zero records, with clear Calls-To-Action (CTAs).
5.  **Input Validation State**: Inline warning labels, borders changing color, or disabled submit triggers.

---

## 2. Phase 7 Roadmap Checklist

### Tier 1 — Critical Core Loop (Highest Priority)

#### Journey 1: Merchant Authentication & Onboarding/Provisioning
*Tracks the entry point for merchants to sign up, sign in, select tier, and spin up their custom Cloud SQL instances.*

| View / Screen | Mockup PNG (Archive Path) | Dart Target File | Riverpod Provider |
| :--- | :--- | :--- | :--- |
| **Merchant Login** | `mock-screens/merchant_login.png` | [login_page.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/login_page.dart) | `authProvider` |
| **Provisioning / Setup** | `mock-screens/provisioning_setup.png` | [provisioning_page.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/provisioning_page.dart) | `tenantProvisioningProvider` |
| **Landing Page** | `mock-screens/landing_page.png` | [landing_page.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/landing_page.dart) | N/A (Static Routing) |

- [ ] **Merchant Login**
  - [ ] Default/Active State
  - [ ] Loading/Submitting State (Disable inputs, show progress spinner)
  - [ ] Error/Failure State (Invalid credentials banner)
  - [ ] Empty State (`N/A`)
  - [ ] Input Validation State (Verify Gmail format before sending)
- [ ] **Provisioning / Setup**
  - [ ] Default/Active State
  - [ ] Loading/Submitting State (Animated rocket pulse, database setup logs)
  - [ ] Error/Failure State (Provisioning timeout / retry button)
  - [ ] Empty State (`N/A`)
  - [ ] Input Validation State (Required field validation)
- [ ] **Landing Page**
  - [ ] Default/Active State (Vibrant emerald/teal gradients, hover micro-animations)
  - [ ] Loading/Submitting State (`N/A`)
  - [ ] Error/Failure State (`N/A`)
  - [ ] Empty State (`N/A`)
  - [ ] Input Validation State (`N/A`)

---

#### Journey 2: Product Catalog & Inventory Management
*Tracks product listing, variants configurations, bulk CSV imports, SEO descriptions, and the multi-image catalog gallery.*

| View / Screen | Mockup PNG (Archive Path) | Dart Target File | Riverpod Provider |
| :--- | :--- | :--- | :--- |
| **Catalog Overview** | `mock-screens/catalog_overview.png` | [catalog_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/catalog_view.dart) | `catalogProvider` |
| **Product & Variant Editor** | `mock-screens/product_editor.png` | [product_editor_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/product_editor_view.dart) | `productEditorProvider` |

- [ ] **Catalog Overview**
  - [ ] Default/Active State (Frosted cards, emerald filter chips)
  - [ ] Loading/Submitting State (Card-skeleton placeholder grids)
  - [ ] Error/Failure State (Fetch error toast with reload prompt)
  - [ ] Empty State (Illustration indicating "No Products Found" + "Add Product" CTA)
  - [ ] Input Validation State (`N/A`)
- [ ] **Product & Variant Editor**
  - [ ] Default/Active State (Slug, status, Compare-At price, digital toggles)
  - [ ] Loading/Submitting State (Save progress loader, image uploading placeholders)
  - [ ] Error/Failure State (Error modal on save failure)
  - [ ] Empty State (`N/A`)
  - [ ] Input Validation State (Highlight empty title, price ≤ 0 validation)

---

#### Journey 3: DTC Consumer Storefront
*Tracks public storefront browsing, cart operations, mock checkout payment intent, and post-checkout registration.*

| View / Screen | Mockup PNG (Archive Path) | Dart Target File | Riverpod Provider |
| :--- | :--- | :--- | :--- |
| **Storefront (PDP / Cart)** | `mock-screens/storefront_pdp.png` | [storefront_preview.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/widgets/storefront_preview.dart) | `storefrontProvider` |
| **Consumer Sign-up** | `mock-screens/consumer_register.png` | [consumer_registration_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/consumer_registration_view.dart) | `consumerAuthProvider` |

- [ ] **Storefront (PDP / Cart / Checkout)**
  - [ ] Default/Active State (Alpine themes, product details, sliding cart drawer)
  - [ ] Loading/Submitting State (Simulated payment process overlays)
  - [ ] Error/Failure State (Stripe mock payment failure alert)
  - [ ] Empty State (Empty cart screen with "Back to Shop" CTA)
  - [ ] Input Validation State (Credit card form inline error checks)
- [ ] **Consumer Sign-up**
  - [ ] Default/Active State (Post-purchase register fields)
  - [ ] Loading/Submitting State (Registering request spinner)
  - [ ] Error/Failure State (Password too weak or email exists banner)
  - [ ] Empty State (`N/A`)
  - [ ] Input Validation State (Password match, required fields validation)

---

#### Journey 4: Order Management & Fulfillment (Merchant-Side)
*Tracks order lifecycle, customer detail mapping, partial refund triggers, internal notes, and carrier rate fulfillment.*

| View / Screen | Mockup PNG (Archive Path) | Dart Target File | Riverpod Provider |
| :--- | :--- | :--- | :--- |
| **Orders View** | `mock-screens/orders_overview.png` | [orders_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/orders_view.dart) | `orderListProvider` |
| **Order Details & Fulfill** | `mock-screens/order_details.png` | [order_detail_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/order_detail_view.dart) | `orderDetailProvider` |

- [ ] **Orders View**
  - [ ] Default/Active State (Glassmorphism order rows, status avatars)
  - [ ] Loading/Submitting State (Table skeletons)
  - [ ] Error/Failure State (Refresh failure indicator)
  - [ ] Empty State ("No Orders Yet" visual state)
  - [ ] Input Validation State (`N/A`)
- [ ] **Order Details & Fulfill**
  - [ ] Default/Active State (Fulfillment tracking, refund triggers, internal notes)
  - [ ] Loading/Submitting State (Fulfillment processing state, refund loading)
  - [ ] Error/Failure State (Refund limit exceeded error)
  - [ ] Empty State (`N/A`)
  - [ ] Input Validation State (Validate tracking number formats before submitting)

---

### Tier 2 — Secondary & Back-Office (Subsequent Focus)

#### Journey 5: Dashboard Analytics & Overview
*Tracks revenue cards, Needs Attention panels (approvals, stock warnings), and interactive visualization targets.*

| View / Screen | Mockup PNG (Archive Path) | Dart Target File | Riverpod Provider |
| :--- | :--- | :--- | :--- |
| **Dashboard Overview** | `mock-screens/dashboard_overview.png` | [dashboard_page.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/dashboard_page.dart) | `analyticsProvider` |

- [ ] **Dashboard Overview**
  - [ ] Default/Active State (Line/Grouped charts, Needs Attention indicators)
  - [ ] Loading/Submitting State (Shimmer cards for stat blocks, skeleton charts)
  - [ ] Error/Failure State (Error placeholder on widgets)
  - [ ] Empty State ("No selling data yet" message)
  - [ ] Input Validation State (`N/A`)

---

#### Journey 6: WYSIWYG Theme Editor & Theme Library
*Tracks interactive storefront previews, slot content updates, responsive viewports, and carry-forward theme transitions.*

| View / Screen | Mockup PNG (Archive Path) | Dart Target File | Riverpod Provider |
| :--- | :--- | :--- | :--- |
| **Theme Selection** | `mock-screens/themes_library.png` | [themes_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/themes_view.dart) | `themeLibraryProvider` |
| **WYSIWYG Studio** | `mock-screens/wysiwyg_studio.png` | [wysiwyg_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/wysiwyg_view.dart) | `wysiwygEditorProvider` |

- [ ] **Theme Selection**
  - [ ] Default/Active State (Palette chips, carry-forward indicators)
  - [ ] Loading/Submitting State (Apply theme loader)
  - [ ] Error/Failure State (Theme load error toast)
  - [ ] Empty State (`N/A`)
  - [ ] Input Validation State (`N/A`)
- [ ] **WYSIWYG Studio**
  - [ ] Default/Active State (Split viewport, slot configuration panels, undo/redo buttons)
  - [ ] Loading/Submitting State (Save drafts progress overlay)
  - [ ] Error/Failure State (Save draft failure dialog)
  - [ ] Empty State (Orphaned slots warning state)
  - [ ] Input Validation State (Character limits on slot components)

---

#### Journey 7: Customer Profile Management & B2B Buyer Portal
*Tracks B2B approval workflows, customer transaction scorecards, and customer dashboard widgets.*

| View / Screen | Mockup PNG (Archive Path) | Dart Target File | Riverpod Provider |
| :--- | :--- | :--- | :--- |
| **Merchant Customer View** | `mock-screens/customers_list.png` | [customers_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/customers_view.dart) | `customerListProvider` |
| **Consumer Portal** | `mock-screens/consumer_portal.png` | [consumer_dashboard_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/consumer_dashboard_view.dart) | `consumerDashboardProvider` |
| **Consumer Order Details** | `mock-screens/consumer_order.png` | [consumer_order_details_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/consumer_order_details_view.dart) | `consumerOrderDetailProvider` |

- [ ] **Merchant Customer View**
  - [ ] Default/Active State (Avatar cards, quick B2B tags, tier indicators)
  - [ ] Loading/Submitting State (Shimmer cards)
  - [ ] Error/Failure State (Fetch error toast)
  - [ ] Empty State ("No Customers Registered")
  - [ ] Input Validation State (`N/A`)
- [ ] **Consumer Portal**
  - [ ] Default/Active State (History grid, refund requests, address details)
  - [ ] Loading/Submitting State (Skeletons)
  - [ ] Error/Failure State (Error notice widget)
  - [ ] Empty State ("You have no orders yet" banner)
  - [ ] Input Validation State (Edit profile input validation)
- [ ] **Consumer Order Details**
  - [ ] Default/Active State (Order timeline tracker, refund trigger action)
  - [ ] Loading/Submitting State (Processing refund dialog)
  - [ ] Error/Failure State (Refund error overlay)
  - [ ] Empty State (`N/A`)
  - [ ] Input Validation State (`N/A`)

---

#### Journey 8: Settings & Billing Management
*Tracks swipable Zurich/Bento/Compact UI stack card tabs and tiered billing setup.*

| View / Screen | Mockup PNG (Archive Path) | Dart Target File | Riverpod Provider |
| :--- | :--- | :--- | :--- |
| **Settings Panel** | `mock-screens/settings_panel.png` | [settings_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/settings_view.dart) | `settingsProvider` |
| **Billing & Tier Selection** | `mock-screens/billing_tier.png` | [billing_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/billing_view.dart) | `billingProvider` |

- [ ] **Settings Panel (Zurich / Bento / Compact)**
  - [ ] Default/Active State (Swipable horizontals, chip overrides)
  - [ ] Loading/Submitting State (Updating preferences spinner)
  - [ ] Error/Failure State (Failed to save preference message)
  - [ ] Empty State (`N/A`)
  - [ ] Input Validation State (Invalid currency / email formats)
- [ ] **Billing & Tier Selection**
  - [ ] Default/Active State (Pricing tiers, dynamic status indicators)
  - [ ] Loading/Submitting State (Stripe customer portal redirecting indicator)
  - [ ] Error/Failure State (Stripe redirect error banner)
  - [ ] Empty State (`N/A`)
  - [ ] Input Validation State (`N/A`)

---

#### Journey 9: Blog Management & Blog Editor
*Tracks categories setup, excerpt summaries, rich-text styling, and scheduling parameters.*

| View / Screen | Mockup PNG (Archive Path) | Dart Target File | Riverpod Provider |
| :--- | :--- | :--- | :--- |
| **Blog Listing** | `mock-screens/blog_list.png` | [blog_view.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/blog_view.dart) | `blogProvider` |
| **Blog Editor** | `mock-screens/blog_editor.png` | [blog_post_editor.dart](file:///e:/Non_Office/Dev_Space/vibe_skool/kloudShop/frontend/lib/views/blog_post_editor.dart) | `blogPostEditorProvider` |

- [ ] **Blog Listing**
  - [ ] Default/Active State (Frosted post cards, categories)
  - [ ] Loading/Submitting State (List skeletons)
  - [ ] Error/Failure State (Failed to load feed banner)
  - [ ] Empty State (Illustrative empty feed + "Write Post" CTA)
  - [ ] Input Validation State (`N/A`)
- [ ] **Blog Editor**
  - [ ] Default/Active State (Excerpt fields, content rich-editor, schedule widgets)
  - [ ] Loading/Submitting State (Saving / publishing loaders)
  - [ ] Error/Failure State (Failed to publish blog post alert)
  - [ ] Empty State (`N/A`)
  - [ ] Input Validation State (Empty Title / Body validation warning)
