# Storefront Settings & Theme Customization Decisions

This document serves as the single source of truth for the architectural, database, API, and UI design decisions taken to bring the Shopify-like theme customization and storefront settings experience to Kloudshop.

---

## 1. Sidebar Navigation & Customizer Transition

### Decisions:
* **Dashboard Sidebar Groups**: Group the customer-facing storefront and related components under a nested **Sales Channels -> Online Store** section. Peer items inside this collapsible section include:
  * **Themes**
  * **Blog**
  * **Pages** (Static page management)
  * **Navigation** (Menu & link builder)
  * **Preferences** (SEO title/description, google analytics, etc.)
* **Operational & Platform Grouping**:
  * **Sales Channels**: Online Store, Wholesale (B2B).
  * **Operations**: Overview, Orders, Products (renamed from Catalog), Customers.
  * **Admin/Platform**: Billing, Compliance, Settings (global cog at bottom).
* **Transition to Customizer Mode**: When the merchant clicks "Customize" on a theme, the standard dashboard sidebar is hidden entirely. The UI transitions into a full Shopify-clone editor structure:
  1. **Utility Icon Ribbon (Left)**: Very thin, sticky, frozen vertical icon column.
  2. **Contextual Settings/Outline Panel (Center)**: Medium width, displays sections, blocks, or theme settings inputs.
  3. **Visual Live Preview Canvas (Right)**: Widest area, shows real-time rendering of the storefront.

## 2. Themes Management Page & Theme Library

### Decisions:
* **Active Theme Display**:
  * Dual device mockup frame (Desktop + Mobile overlapping viewport mockups) rendering a stylized representation of the active storefront.
  * Prominent primary CTA: **Customize** (navigates to the theme editor).
  * Overflow menu (`⋯`) for secondary actions: *Rename*, *Duplicate*, *Edit Code*, *Download theme file (JSON)*, and *Delete* (if it is a draft clone).
* **Theme Library Organization**:
  * **My Themes**: Dedicated list of the merchant's saved drafts, clones, and customized versions.
  * **Popular Free Themes Shelf**: Curated free starter templates (Dawn, Spotlight, Refresh, etc.) shown in a horizontal shelf.
  * **KloudThemeShop Integration**: At the end of the shelf, an "Explore More Themes" button/card opens a 2-pane template store:
    * *Left Panel*: Filter by industry categories (Arts & Crafts, Clothing & Fashion, Food & Beverage, electronics, etc.).
    * *Right Panel*: Grid of visual cards representing base templates ready to be added with a single click.

## 3. Theme Customizer — Entry Point & Overall Layout

### Decisions:
* **Customizer Exit Button**: The top of the leftmost vertical icon ribbon features a dedicated "Exit" arrow button to close the storefront customizer and return to the main merchant dashboard.
* **Three-Pane Column Layout**:
  1. **Leftmost Utility Bar (Icon Ribbon)**: Very thin, vertical frozen column containing:
     * *Exit Button* (Top)
     * *Sections/Layout Editor Icon* (Loads page layout hierarchy in center pane)
     * *Theme Settings Icon* (Loads global variables/design tokens in center pane)
     * *Native Feature Embeds Icon* (Loads native features toggles in center pane)
  2. **Center Panel (Outline & Properties Workspace)**: Transitions contextually:
     * *Outline Mode*: Shows collapsible groups (`HEADER`, `TEMPLATE`, `FOOTER`) and sections (Announcement bar, Header, Image banner, etc.).
     * *Properties Mode*: Replaces the outline hierarchy with specific editing input fields (sliders, text boxes, selectors) when a section or block is selected. Features a back-arrow (`←`) to return to the outline tree.
  3. **Rightmost Panel (Live Preview Canvas)**: Renders the live responsive storefront (desktop/mobile view toggles available at the top).
* **Third Icon - Native Feature Embeds (Native Apps)**:
  * Manages built-in Kloudshop platform modules (e.g., Wholesale B2B displays, reviews, chat widgets, newsletter popups) that are toggled on/off.
  * Toggling these on enables corresponding theme blocks or storefront configurations.
  * If a feature is toggled off, this panel will display educational copy explaining what it does and a shortcut action to toggle it on.

## 4. Page Template Switcher & Product Page Customization

### Decisions:
* **Dynamic Page Switcher (Top-Center)**: A dropdown at the top center of the editor allows the merchant to switch the preview context and customizer fields between different pages (Home page, Product pages, Collection pages, Cart, Checkout, Custom static pages, Blog posts).
* **Reusable JSON Templates**:
  * Storefront layouts are decoupled from product data and stored in the theme database configuration as reusable JSON files/objects.
  * The system supports a default template (e.g. `product.default.json`) used by all items in that category by default.
  * Merchants can create custom templates (e.g., `product.special-promo.json`) and assign them to specific products or collections via their administrative settings.
* **Full Bi-directional Highlight & Synchronization**:
  * *Canvas to Outline*: Clicking an element on the live preview canvas highlights it with a blue outline and automatically scroll-focuses/expands the corresponding node in the outline tree panel.
  * *Outline to Canvas*: Clicking a node in the center panel outline focuses and draws a blue highlight around its visual counterpart on the canvas.

## 5. Section/Block Properties & Asset Selectors

### Decisions:
* **Shopify Drill-Down Style (Sidebar Navigation)**:
  * The center panel utilizes a navigation stack. Clicking on a nested block (e.g. the Heading block inside an Image Banner section) slides the center panel view to show only that block's settings.
  * A clear back-arrow (`← Block Name`) is displayed at the top to pop the navigation stack and return to the parent section's settings.
* **Centralized Store Media Library**:
  * A single, tenant-wide media library database table and file repository is used.
  * When a merchant clicks "Select Image" on any image input (e.g., logo, banner, collection cover, product image), a modal pop-up displays a searchable grid of all previously uploaded files for instant reuse.
  * Drag-and-drop file upload is supported inside the modal to add new images to the shared pool.

## 6. Global Theme Settings & Centralized Brand Assets

### Decisions:
* **Centralized and Auto-Synced Brand Assets**:
  * The theme customizer settings (Logo, Favicon, Brand Colors) bind directly to the tenant's central database `BrandProfile` by default.
  * Modifying these assets under general Store Settings automatically updates the active theme, invoice headers, and customer-facing emails unless overridden by a custom local value in the theme settings.
* **Named Style Presets (Seasonal Presets)**:
  * In place of raw CSS injection, the customizer supports saving the active set of design tokens (colors and typography) as a named "Style Preset" (e.g. "Summer Fresh", "Christmas Theme", "Halloween").
  * Merchants can save, load, and switch between these style presets in a single click without altering the page sections structure.
* **Real-time Contrast Auditing**:
  * The color picker UI includes a real-time WCAG 2.1 contrast ratio calculator.
  * If a merchant selects a text color and background color combination that fails readability standards (contrast ratio < 4.5:1), the customizer displays an inline warning banner suggesting a darker/lighter alternative.

## 7. Payment Gateways, Capture Methods & Transaction Fees

### Decisions:
* **Two-Stage Payment Capture (Authorize vs. Capture)**:
  * The system supports a store-level configuration setting: `payment_capture_policy` (`automatic` or `manual`).
  * *Automatic*: Charges are captured immediately during checkout.
  * *Manual*: Charges are authorized at checkout, holding funds on the card. The order status is set to `authorized`. The merchant has a gateway-defined window (7 days for Stripe, 29 days for PayPal) to click a "Capture Funds" button in the Order Details view, triggering a backend API call to capture the transaction.
* **Separation of Manual Payment Modalities**:
  * Manual payment options configured under Settings are categorized into:
    1. **Pre-Paid Manual** (e.g. Bank Deposit, Money Order, Bank Wire):
       * Placed in `awaiting_payment` status.
       * **Fulfillment state is LOCKED**. The dashboard disables fulfillment/shipping actions until the merchant manually clicks "Mark as Paid".
    2. **Post-Paid Manual** (e.g. Cash on Delivery - COD):
       * Placed in `awaiting_payment` status.
       * **Fulfillment state is UNLOCKED**. The merchant can ship the package. Once delivery and cash collection are completed, the merchant (or a carrier webhook) clicks "Mark as Paid" to transition the status to `paid`.

## 8. Fulfillment & Shipping Rate Profiles

### Decisions:
* **Multiple Shipping Profiles (Shopify Style)**:
  * Supported globally for all plan tiers (no plan gating; available to DTC merchants).
  * A default `General Profile` applies to all products/variants automatically.
  * Merchants can create custom `Shipping Profiles` (e.g., "Heavy Furniture", "Fragile Artworks") to configure distinct rates for subgroups of items.
  * A `shipping_profile_id` foreign key is added to the `variants` table (linked to the `shipping_profiles` table).
* **Shipping Zones & Regional Mapping**:
  * Inside each profile, merchants define geographic `Shipping Zones` (groups of countries, e.g., "Domestic (US/CA)", "European Union").
  * Rates defined inside a zone only apply to shipping addresses within those country codes.
* **Conditional Flat Rates Builder**:
  * Merchants can configure flat shipping rates with optional weight and cart value thresholds:
    * *Price-based thresholds*: e.g., Free Shipping for orders over $100 (min price threshold = $100).
    * *Weight-based thresholds*: e.g., Standard heavy shipping for orders between 10kg and 30kg.
* **Fulfillment checkout calculator (Rate Blending)**:
  * At checkout, the cart items are grouped by their respective shipping profile.
  * The calculator determines the matching zone rates for each group and aggregates them (e.g. summing rates from different profiles) to yield the final shipping charge presented to the customer.

## 9. Taxes, Duties & International Tax Compliance

### Decisions:
* **Stripe Connect Automated Tax Compliance**:
  * Stripe Tax is the primary automated calculation engine.
  * The merchant's admin panel surfaces Stripe Connect embedded components (`ConnectTaxSettings` and `ConnectTaxRegistrations`) inside the Taxes settings tab. Merchants manage registrations and rules directly within this secure embedded view.
  * The checkout engine passes `automatic_tax: {"enabled": True}` to the Stripe API, letting Stripe dynamically compute VAT/Sales Tax based on the buyer's shipping address.
* **Manual Tax Rates Table (Free Fallback)**:
  * For merchants who do not want to use Stripe Tax, the system provides a free native manual tax rates database model (`StoreTaxRate` with columns: `country_code`, `state_code`, `tax_percentage`, `is_active`).
  * If the automated Stripe Tax toggle is disabled in Settings, the checkout engine queries this manual table to calculate tax.
* **Zero-Configuration Catalog Defaults**:
  * By default, all newly created products are assigned a standard `tax_category = "Standard Physical Goods"`, requiring no manual tax entries by the merchant.
  * Product variants retain the standard `taxable` boolean (defaulting to `True`).
  * Merchants only change the tax category dropdown on the product page if the item falls under a tax exemption or special rate (e.g., zero-rated books, digital downloads, or services).

## 10. Navigation Menu Builder & Link Resolution

### Decisions:
* **Self-Referencing Nested Navigation (Multi-Level Dropdowns)**:
  * Database schema uses a self-referencing relationship: a `navigation_items` table with a nullable `parent_id` foreign key pointing back to `navigation_items.id`.
  * The frontend UI supports up to **5 levels of nesting** via drag-and-drop indentation.
  * *UX Guideline warning*: If a merchant drag-nests an item to level 4 or 5, the editor displays an inline warning banner: *"Nesting beyond 3 levels is allowed but not recommended, as it can make navigation difficult for customers on mobile devices."*
* **Polymorphic Asset Linker (Dynamic Routing)**:
  * When configuring a link, merchants use a search-suggest popover that queries existing database records: Products, Collections, Pages, and Legal Policies.
  * Selecting a resource automatically resolves its relative URL route (e.g., `/collections/autumn-wear`) and pre-fills the Link Name field with the resource's title.
  * This binds the navigation item to the database resource ID polymorphic type, ensuring link integrity if a slug is changed later.

## 11. Store Policies, Return Rules & Document Editors

### Decisions:
* **HTML Source Toggle & Boilerplate Templates**:
  * Policy textareas in Settings support a raw HTML source code toggle (`</>`) to allow custom layout embedding (e.g. legal tables, anchor tags).
  * Includes a "Create from template" utility that auto-fills legal drafts with the merchant's business metadata (name, address, support email).
* **Draft vs. Publish Lifecycle (Versioning)**:
  * Policy saving is decoupled from storefront publishing to prevent version history bloat.
  * *Draft State*: Standard "Save" actions update a single private working draft (`draft_content`) in the database. The live storefront is unaffected.
  * *Published State*: Clicking "Publish" triggers a validation check. The admin panel blocks or warns the merchant when they attempt to publish a policy if there are no storefront links (e.g., in navigation menus or footer blocks) referencing that specific policy. If validated (or explicitly overridden by the merchant), the system commits the draft to a new official version (incrementing the `version` counter), sets `is_active = True`, and deactivates the previous version (setting `is_active = False` and `deactivated_at = now`) in a single database transaction.
* **Auto-Linking & Permanent Routing**:
  * Policies reside on permanent, standardized storefront URL paths (e.g., `/policies/refund`).
  * The storefront footer block automatically queries the database and renders links *only* for policies that have active, published content. Unpublished policy links are hidden automatically.
  * To prevent publishing a policy "into thin air", the system ensures storefront homepage links or footer blocks reading "Read our return policy here" are linked to the non-null, published policy route, and warns the merchant during customization if any active theme link points to a null/unpublished policy.











