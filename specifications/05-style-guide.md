# Style Guide: KloudShop

> **Stage:** 5 — Style Guide
> **Persona:** Brand & Design Systems Lead
> **Approved:** [ ] pending
> **Reads from:** `01-product-brief.md`, `03-user-journeys.md`

---

## Brand Voice

**Three words:** Trustworthy · Capable · Uncluttered

**What it should feel like:** Using KloudShop should feel like working with a
senior business partner — one who handles complexity invisibly and surfaces only
what you need to make a decision. Every screen should communicate "we've got this"
without requiring the merchant to think about the platform at all.

**What it should NOT feel like:** Busy, playful, or enterprise-cold. Not a dashboard
covered in widgets fighting for attention. Not a consumer app that underestimates
the merchant's intelligence. Not a legacy ERP that requires a manual to operate.

**Two distinct surfaces, one design system:**
- **Merchant admin** — KloudShop's branded surface. Trustworthy, information-dense
  but not cluttered, built for repeat daily use by professionals.
- **Consumer storefront** — the merchant's branded surface. KloudShop is invisible.
  The design system provides the rendering engine; the merchant's theme.json
  provides the personality. No KloudShop colours, no KloudShop logo, no
  "Powered by" badge visible to consumers.

---

## Colour System

> All colours defined as design tokens. Raw hex values never appear in Flutter
> code or theme.json — always the token name. Dark mode variants are defined
> at the token level, not the component level.

### Brand Palette — Emerald Horizon

Derived directly from the approved Emerald Horizon palette. Deep teal owns the
navigation and authority surfaces. Emerald owns success and growth signals.
Teal highlight bridges the two for interactive elements.

| Token | Hex | Usage |
|-------|-----|-------|
| `brand-teal-900` | `#134E4A` | Sidebar, navigation background, primary surface authority |
| `brand-teal-500` | `#124B47` | Secondary CTA, highlight, hover on dark surfaces |
| `brand-emerald-500` | `#10B981` | Success states, growth indicators, positive metrics |
| `brand-emerald-600` | `#059669` | Hover on emerald elements, pressed state |
| `brand-emerald-50` | `#ECFDF5` | Emerald tint — success banners, positive backgrounds |
| `brand-teal-50` | `#F0FDFA` | Teal tint — selected states, active highlights |

**Primary CTA colour:** `brand-teal-500` (`#124B47`) — used for all primary
interactive elements in the admin. Sits on white content backgrounds with strong
contrast and is visually distinct from both Shopify green and Stripe purple-grey.

### Neutral Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `neutral-0` | `#FFFFFF` | Content background — cards, panels, inputs |
| `neutral-50` | `#F9FAFB` | Main page background (subtle gray) |
| `neutral-100` | `#F3F4F6` | Dividers, cool gray separators, table alternating rows |
| `neutral-200` | `#E5E7EB` | Borders, input borders, card borders |
| `neutral-400` | `#9CA3AF` | Placeholder text, disabled states |
| `neutral-500` | `#6B7280` | Muted text, labels, captions, secondary information |
| `neutral-700` | `#374151` | Body text, secondary headings |
| `neutral-900` | `#111827` | Primary text, headings — Charcoal |

### Semantic Colour Tokens

| Token | Light Mode Value | Purpose |
|-------|-----------------|---------|
| `color-action-primary` | `brand-teal-500` (#124B47) | All primary buttons and interactive elements |
| `color-action-primary-hover` | `#0D9488` | Hover on primary actions (teal-600 equivalent) |
| `color-action-primary-pressed` | `#0F766E` | Pressed/active state on primary |
| `color-nav-background` | `brand-teal-900` (#134E4A) | Sidebar and navigation surface |
| `color-nav-text` | `#FFFFFF` | Navigation labels on dark sidebar |
| `color-nav-text-muted` | `#99C4C2` | Inactive nav items on dark sidebar |
| `color-nav-active` | `brand-teal-500` (#124B47) | Active nav item highlight |
| `color-surface-page` | `neutral-50` (#F9FAFB) | Main page background |
| `color-surface-card` | `neutral-0` (#FFFFFF) | Cards, panels, modals |
| `color-surface-raised` | `neutral-0` (#FFFFFF) | Dropdowns, popovers above cards |
| `color-border-default` | `neutral-200` (#E5E7EB) | Standard borders |
| `color-border-subtle` | `neutral-100` (#F3F4F6) | Dividers, table rules |
| `color-text-primary` | `neutral-900` (#111827) | Headings, primary content |
| `color-text-body` | `neutral-700` (#374151) | Body text, descriptions |
| `color-text-secondary` | `neutral-500` (#6B7280) | Labels, captions, metadata |
| `color-text-placeholder` | `neutral-400` (#9CA3AF) | Input placeholders |
| `color-text-on-dark` | `#FFFFFF` | Text on teal-900 sidebar |
| `color-success` | `brand-emerald-500` (#10B981) | Success states, positive metrics |
| `color-success-surface` | `brand-emerald-50` (#ECFDF5) | Success banners, badges |
| `color-warning` | `#F59E0B` | Warnings, low stock alerts, pending states |
| `color-warning-surface` | `#FFFBEB` | Warning banners |
| `color-error` | `#EF4444` | Errors, destructive actions, failed states |
| `color-error-surface` | `#FEF2F2` | Error banners, validation backgrounds |
| `color-info` | `brand-teal-500` (#124B47) | Informational states, tips |
| `color-info-surface` | `brand-teal-50` (#F0FDFA) | Info banners |

### Dark Mode Tokens

Dark mode inverts surfaces while keeping the teal-900 sidebar — it is already
dark and requires no change. The content area switches to a dark neutral scale.

| Token | Light Mode | Dark Mode |
|-------|-----------|-----------|
| `color-surface-page` | `#F9FAFB` | `#0F172A` |
| `color-surface-card` | `#FFFFFF` | `#1E293B` |
| `color-surface-raised` | `#FFFFFF` | `#293548` |
| `color-border-default` | `#E5E7EB` | `#334155` |
| `color-border-subtle` | `#F3F4F6` | `#1E293B` |
| `color-text-primary` | `#111827` | `#F1F5F9` |
| `color-text-body` | `#374151` | `#CBD5E1` |
| `color-text-secondary` | `#6B7280` | `#94A3B8` |
| `color-text-placeholder` | `#9CA3AF` | `#64748B` |
| `color-nav-background` | `#134E4A` | `#134E4A` (unchanged) |
| `color-action-primary` | `#124B47` | `#124B47` (unchanged) |
| `color-success` | `#10B981` | `#34D399` |
| `color-warning` | `#F59E0B` | `#FBBF24` |
| `color-error` | `#EF4444` | `#F87171` |

**Dark mode detection:** System preference is honoured by passing `themeMode: ThemeMode.system`
to `MaterialApp` — Flutter resolves the correct `ThemeData` (light or dark) automatically
based on the host platform's current setting. User can override in account preferences,
storing their explicit choice (`"light"` | `"dark"` | `"system"`) in
`staff_users.preferences JSONB` (in the `kloudshop_platform` schema), fetched on session
bootstrap and applied by setting `themeMode` to `ThemeMode.light`, `ThemeMode.dark`, or
`ThemeMode.system` accordingly on the `MaterialApp`. To read the resolved brightness
anywhere in the widget tree use `Theme.of(context).brightness == Brightness.dark`.
Applied to the entire admin shell — never per-component or per-screen.

---

## Typography

**Font:** Inter (Google Fonts — no licence cost, excellent multilingual coverage
across all 10 supported LTR locales, purpose-built for screen UI).

**Rationale:** Inter is the definitive choice for a professional, trustworthy admin
UI. It is optically tuned for screen rendering at small sizes, has strong number
tabular alignment (critical for financial dashboards and order tables), and covers
all required Latin character sets. It reads as capable without being cold.

**Fallback stack:** `Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif`

**Scale basis:** 16px (1rem). All sizes in rem for Flutter accessibility scaling
compliance.

| Token | Weight | Size | Line Height | Letter Spacing | Usage |
|-------|--------|------|-------------|---------------|-------|
| `text-display-xl` | 700 | 2.25rem / 36px | 1.2 | -0.02em | Page hero headings (migration success, store reveal) |
| `text-display-lg` | 700 | 1.875rem / 30px | 1.25 | -0.01em | Section titles, empty state headings |
| `text-heading-xl` | 600 | 1.5rem / 24px | 1.3 | 0 | Dashboard panel titles |
| `text-heading-lg` | 600 | 1.25rem / 20px | 1.35 | 0 | Card titles, modal headings |
| `text-heading-md` | 600 | 1rem / 16px | 1.4 | 0 | Sub-section labels, table column headers |
| `text-heading-sm` | 600 | 0.875rem / 14px | 1.4 | 0.01em | Badge labels, tight group headings |
| `text-body-lg` | 400 | 1rem / 16px | 1.6 | 0 | Long-form descriptions, onboarding copy |
| `text-body-md` | 400 | 0.875rem / 14px | 1.5 | 0 | Standard admin UI text — the workhorse |
| `text-body-sm` | 400 | 0.75rem / 12px | 1.4 | 0.01em | Captions, metadata, timestamps, helper text |
| `text-label-md` | 500 | 0.875rem / 14px | 1.4 | 0.01em | Form labels, nav item labels |
| `text-label-sm` | 500 | 0.75rem / 12px | 1.4 | 0.02em | Table headers, tag labels |
| `text-code` | 400 | 0.875rem / 14px | 1.6 | 0 | API keys, webhook URLs, code snippets (JetBrains Mono) |
| `text-numeric` | 600 | varies | 1.2 | -0.01em | Financial figures — tabular-nums feature active |

**Numeric figures:** All currency amounts, order values, inventory counts, and
metric numbers use `font-variant-numeric: tabular-nums` to ensure column alignment
in tables and dashboards. Applied via the `text-numeric` token.

**Storefront typography:** Entirely theme-driven via `theme.json` `typography` block.
The style guide's type scale does not apply to consumer storefronts. Each theme
defines its own heading font, body font, and scale independently.

---

## Spacing & Layout

**Base unit:** 4px. All spacing values are multiples of 4.

**Scale:**
| Token | Value | Usage |
|-------|-------|-------|
| `space-1` | 4px | Tight internal padding (badge, tag) |
| `space-2` | 8px | Icon gap, compact list item padding |
| `space-3` | 12px | Input internal padding, tight card padding |
| `space-4` | 16px | Standard component padding, form field gap |
| `space-5` | 20px | Card body padding (compact) |
| `space-6` | 24px | Card body padding (standard), section gap |
| `space-8` | 32px | Between cards, major section padding |
| `space-10` | 40px | Page section vertical rhythm |
| `space-12` | 48px | Large section breaks |
| `space-16` | 64px | Page-level padding (desktop) |

**Admin layout:**
- Sidebar width: 240px (expanded) / 64px (collapsed icon-only)
- Content area max width: 1280px
- Page horizontal padding: 24px (mobile) / 32px (tablet) / 48px (desktop)
- Grid: 12-column, 24px gutter
- Top app bar height: 56px (mobile) / 64px (desktop)

**Density:** Context-sensitive. Data tables (orders, products, inventory) use compact
row heights (48px) for scan-optimised information density — merchants need to process
many rows quickly. Cards, dashboards, onboarding panels, and setup wizards use generous
spacing (24–32px padding, 32–48px vertical rhythm between sections) to reduce cognitive
load at decision-making surfaces. Breathing room where decisions are made; density where
information is scanned.

---

## Elevation & Shadow

Shadows use `neutral-900` at reduced opacity — never pure black, which reads
as artificial on light backgrounds. Dark mode shadows are more subtle as the
surface contrast handles depth.

| Token | Shadow (Light) | Shadow (Dark) | Usage |
|-------|---------------|--------------|-------|
| `elevation-0` | none | none | Flat elements on same-surface background |
| `elevation-1` | `0 1px 3px rgba(17,24,39,0.08), 0 1px 2px rgba(17,24,39,0.04)` | `0 1px 3px rgba(0,0,0,0.3)` | Cards, inputs, standard panels |
| `elevation-2` | `0 4px 12px rgba(17,24,39,0.10), 0 2px 4px rgba(17,24,39,0.06)` | `0 4px 12px rgba(0,0,0,0.4)` | Dropdowns, popovers, hover card lift |
| `elevation-3` | `0 8px 24px rgba(17,24,39,0.12), 0 4px 8px rgba(17,24,39,0.08)` | `0 8px 24px rgba(0,0,0,0.5)` | Modals, drawers, command palette |
| `elevation-4` | `0 16px 48px rgba(17,24,39,0.16), 0 8px 16px rgba(17,24,39,0.10)` | `0 16px 48px rgba(0,0,0,0.6)` | Full-screen overlays, upgrade prompts |

---

## Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radius-xs` | 4px | Badges, tags, inline chips, table cells |
| `radius-sm` | 6px | Inputs, selects, small buttons |
| `radius-md` | 8px | Buttons (standard), cards (compact) |
| `radius-lg` | 12px | Cards (standard), popovers, dropdowns |
| `radius-xl` | 16px | Modals, large panels, drawers |
| `radius-2xl` | 24px | Feature Catalogue cards, onboarding panels |
| `radius-full` | 9999px | Pills, avatar images, toggle switches, progress bars |

---

## Iconography

**Library:** Lucide Icons — outlined style, 24px grid, 1.5px stroke weight.

**Rationale:** Lucide is open-source, Flutter-compatible via `lucide_flutter`,
consistently outlined (matching the clean professional tone), and covers all
required commerce, navigation, and status icon categories. Outlined icons read
as lighter and more modern than filled icons at the density level KloudShop
requires.

**Sizes:**
| Context | Size | Usage |
|---------|------|-------|
| Navigation sidebar | 20px | Primary nav icons |
| Inline with text | 16px | Button icons, list item indicators |
| Status icons | 16px | Success, error, warning, info badges |
| Empty state | 48px | Centred empty state illustration replacement |
| Feature Catalogue cards | 32px | Feature identity icons |

**Colour:** Icons always inherit `currentColor` — they never have hardcoded colours.
They pick up the text colour of their parent context automatically.

**Custom icons:** KloudShop logo mark used in sidebar header only. Exported as SVG,
rendered via Flutter's `SvgPicture` widget.

---

## Component Patterns

### Buttons

| Variant | Background | Text | Border | Usage |
|---------|-----------|------|--------|-------|
| Primary | `color-action-primary` (#124B47) | `#FFFFFF` | none | Main CTA — maximum one per view |
| Secondary | `color-surface-card` | `color-action-primary` | `color-action-primary` 1.5px | Secondary action alongside primary |
| Ghost | transparent | `color-text-body` | none | Tertiary actions, icon-only buttons |
| Danger | `color-error` (#EF4444) | `#FFFFFF` | none | Destructive — delete, revoke, suspend |
| Ghost Danger | transparent | `color-error` | none | Softer destructive in context menus |

**Sizes:**
| Size | Height | Padding H | Font token | Usage |
|------|--------|-----------|-----------|-------|
| sm | 32px | 12px | `text-body-sm` 500 | Inline actions, table row actions |
| md | 40px | 16px | `text-body-md` 500 | Standard admin actions |
| lg | 48px | 24px | `text-body-lg` 500 | Primary CTAs, onboarding actions |

**States for all variants:** default → hover (8% darker background or teal-500
border) → focus (2px `color-action-primary` ring, 2px offset) → active (12%
darker) → disabled (40% opacity, cursor not-allowed) → loading (spinner replaces
label, width locked to prevent layout shift).

**Loading state:** Button width is locked to its default width when loading begins.
The label is replaced by a 16px spinner (same colour as the text). Never shows
"Loading…" text — the spinner is the signal.

### Form Fields

- **Label:** Above input, `text-label-md`, `color-text-body`. Required fields show
  a `*` in `color-error` after the label.
- **Input height:** 40px (desktop) / 44px (mobile — minimum touch target)
- **Radius:** `radius-sm` (6px)
- **Border:** 1.5px `color-border-default` at rest
- **Focus:** 2px ring in `color-action-primary` with 1px gap, border becomes
  `color-action-primary`
- **Error state:** Border `color-error`, error message below in `text-body-sm`
  `color-error`, error icon inline left of message
- **Disabled:** Background `neutral-100`, text `color-text-placeholder`, cursor
  not-allowed
- **Helper text:** Below input, `text-body-sm`, `color-text-secondary`
- **Textarea (long_text slots):** Drag-resizeable via bottom-right resize handle.
  Min height 80px. Resize handle uses `neutral-300` colour.
- **Character count:** Shown bottom-right of input when `max_chars` is defined,
  format: `{current}/{max}`. Turns `color-error` when within 10 characters of limit.

### Data Tables

Tables are the most-used component in the merchant admin — orders, products,
inventory, customers. They must support: sorting, bulk selection, row actions,
empty states, and pagination.

- **Row height:** 48px (compact density)
- **Header:** `text-label-sm`, `color-text-secondary`, `neutral-50` background,
  1px bottom border `color-border-default`
- **Row border:** 1px `color-border-subtle` between rows (not full box)
- **Hover:** `neutral-50` row background, 150ms ease
- **Selected row:** `brand-teal-50` background, `brand-teal-500` left border 3px
- **Bulk select:** Checkbox in first column. "X selected" pill appears in header
  with bulk action buttons.
- **Numeric columns:** Right-aligned, `text-numeric` token (tabular-nums)
- **Status badges:** Inline in table cells — see Badge component below
- **Row actions:** Appear on row hover, right-aligned. Max 2 icon buttons + overflow menu.
- **Empty state:** Full-width, centred, 120px tall minimum. Icon + heading + CTA.
- **Pagination:** Bottom of table. "Showing X–Y of Z" + prev/next + page size selector.

### Cards

| Variant | Surface | Shadow | Radius | Usage |
|---------|---------|--------|--------|-------|
| Default | `color-surface-card` | `elevation-1` | `radius-lg` | Dashboard panels, content sections |
| Flat | `color-surface-card` | none | `radius-lg` | Inside other cards, quiet content |
| Interactive | `color-surface-card` | `elevation-1` | `radius-lg` | Feature Catalogue items, theme cards — hover lifts to `elevation-2` |
| Highlight | `brand-teal-50` | `elevation-1` | `radius-lg` | AI insights, important notifications |

Card padding: 24px standard / 16px compact (for dense information cards).

### Badges & Status Pills

| Variant | Background | Text | Usage |
|---------|-----------|------|-------|
| Success | `brand-emerald-50` | `#065F46` | Active, fulfilled, paid, live |
| Warning | `#FFFBEB` | `#92400E` | Pending, low stock, expiring |
| Error | `#FEF2F2` | `#991B1B` | Failed, overdue, suspended |
| Info | `brand-teal-50` | `#0F766E` | In progress, processing, syncing |
| Neutral | `neutral-100` | `color-text-secondary` | Draft, inactive, archived |
| New | `#EFF6FF` | `#1D4ED8` | New orders, new messages, new features |

Size: 20px height, `radius-xs` (4px), `text-label-sm`, 6px horizontal padding.
Icon optional — 12px, left of label.

### Empty States

Every list, table, and dashboard section has a designed empty state. Empty states
are the first thing a new merchant sees — they must be instructive, not apologetic.

Structure:
- Icon: 48px Lucide icon, `color-text-secondary`
- Heading: `text-heading-lg`, `color-text-primary` — what this section does
- Subtext: `text-body-md`, `color-text-secondary` — why it's empty + what to do
- Primary CTA: standard Primary button
- Max content width: 400px, centred
- Vertical position: centred in the containing panel, minimum 120px space

Examples:
- Orders table (new merchant): "No orders yet" / "Your first order will appear here when a customer checks out." / [ Share your store ]
- Inventory dashboard (no supplier data): "No supplier data yet" / "Add your first supplier to unlock replenishment recommendations." / [ Add supplier ]
- Analytics (new merchant): "Your store data is building" / "Revenue insights appear as orders come in. AI forecasting activates after 90 days." / [ View your storefront ]

### Modals & Drawers

**Modals:** Centred overlay, `elevation-4` shadow, `radius-xl`, max width 560px
(standard) / 800px (wide — for complex configuration like theme WYSIWYG).
Backdrop: `rgba(17,24,39,0.5)`, click-to-dismiss enabled unless action is required.

**Drawers:** Slide in from right, 480px width (standard) / 640px (detail drawers
e.g. order detail). Same elevation and backdrop as modals.

**Confirmation dialogs:** Always modal, max width 400px. Heading (action being
confirmed), body (consequence of the action, specific not generic), Cancel (ghost)
+ Confirm (primary or danger depending on action). Never use browser `alert()`.

### Navigation Sidebar

- Background: `color-nav-background` (`#134E4A`)
- Width: 240px expanded / 64px collapsed
- KloudShop logo mark: top of sidebar, 40px height, white
- Nav items: 48px height, 16px horizontal padding, `text-label-md`, `color-nav-text-muted`
- Active nav item: `color-nav-active` left border 3px, background `rgba(20,184,166,0.15)`, text `color-nav-text`
- Hover: `rgba(255,255,255,0.08)` background, 150ms ease
- Section dividers: `rgba(255,255,255,0.12)` 1px
- Collapse toggle: bottom of sidebar, chevron icon, `color-nav-text-muted`
- Unread badge: 18px `color-error` pill overlapping nav icon top-right

### Toast Notifications

Appear bottom-right (desktop) / bottom-full-width (mobile). Auto-dismiss after
4 seconds. Manual dismiss via × icon always available.

| Variant | Left border | Icon | Usage |
|---------|------------|------|-------|
| Success | `color-success` 4px | CheckCircle | Order fulfilled, settings saved, import complete |
| Error | `color-error` 4px | XCircle | Action failed, connection error |
| Warning | `color-warning` 4px | AlertTriangle | Low stock, trial limit approaching |
| Info | `color-action-primary` 4px | Info | Background job started, sync in progress |

Background: `color-surface-card`, `elevation-3`, `radius-md`.
Width: 360px fixed (desktop).
Stack: max 3 toasts visible simultaneously, oldest dismisses first.

### Feedback Responsiveness

Every user action receives a visual response within 100ms — even if the operation
takes longer. Merchants must never wonder if the UI registered their action.

- **Skeleton loaders** for all initial content loads — never blank screens. Skeletons
  match the shape of the content they replace.
- **Optimistic UI** for low-risk mutations (fulfil order, toggle feature, save content
  slot) — apply immediately in UI, roll back with error toast if server fails.
- **Inline validation** on blur (not on keystroke). Show green border + check icon
  on valid fields after interaction. Never pre-validate empty fields.
- **Save confirmation** — toast within 200ms of server confirmation. Never silent saves.
- **Real-time data pulse** — metrics that update live show a 100ms `color-action-primary`
  border flash on the changed value so merchants see what changed.
- **Long operations** (> 8 seconds): progress indicator with estimated time, not
  just an indefinite spinner.

---

## Motion & Animation

**Principle:** Motion communicates state change and spatial relationship — never
decoration. Every animation has a reason. Merchants using the admin daily will
notice redundant motion as noise. Keep it fast and purposeful. Use physics-based
spring curves for elements that enter the screen — they feel natural, not mechanical.

| Type | Duration | Easing | Flutter Curve | Usage |
|------|----------|--------|---------------|-------|
| Micro | 100ms | `ease-out` | `Curves.easeOut` | Hover states, focus rings, checkbox ticks |
| Standard | 200ms | `ease-out` | `Curves.easeOut` | Button presses, toggles, badge updates |
| Spring entry | 300ms | physics-based | `Curves.easeOutBack` | Cards, modals, drawers entering — slight overshoot for naturalness |
| Component | 250ms | `ease-in-out` | `Curves.easeInOut` | Dropdown open/close, accordion expand |
| Overlay | 300ms in / 200ms out | `ease-out` in / `ease-in` out | `Curves.easeOut` / `Curves.easeIn` | Modals and drawers |
| Page transition | 200ms | `ease-out` | `Curves.easeOut` | Route changes in Flutter admin |
| Skeleton | 1.5s loop | `ease-in-out` | `Curves.easeInOut` | Skeleton loader shimmer |

**Storefront animations:** Entirely theme-driven via `theme.json` `animation` block.
The admin motion spec does not apply to consumer storefronts.

**Reduced motion:** All animations respect Flutter's `MediaQuery.disableAnimations`
and CSS `prefers-reduced-motion`. When reduced motion is active: all transitions
drop to 0ms (instant), skeleton loaders show static grey instead of shimmer,
storefront component animations are disabled regardless of theme.json config.

---

## Accessibility

**Standard:** WCAG 2.1 AA minimum across all admin surfaces.

**Colour contrast:**
| Pairing | Ratio | Passes AA? |
|---------|-------|-----------|
| `#111827` on `#FFFFFF` | 16.1:1 | ✅ AAA |
| `#111827` on `#F9FAFB` | 15.3:1 | ✅ AAA |
| `#FFFFFF` on `#124B47` (primary button) | 4.6:1 | ✅ AA |
| `#FFFFFF` on `#134E4A` (sidebar) | 10.9:1 | ✅ AAA |
| `#6B7280` on `#FFFFFF` (muted text) | 4.6:1 | ✅ AA |
| `#FFFFFF` on `#EF4444` (danger button) | 4.5:1 | ✅ AA |
| `#065F46` on `#ECFDF5` (success badge) | 7.2:1 | ✅ AAA |

**Touch targets:** Minimum 44×44px for all interactive elements on mobile.
Admin desktop minimum is 32px height with adequate horizontal padding.

**Focus management:**
- Focus ring: 2px `color-action-primary`, 2px offset — always visible, never
  suppressed with `outline: none` without a replacement
- Focus trap: active in modals and drawers — Tab cycles within the overlay
- Focus restoration: on modal/drawer close, focus returns to the trigger element
- Skip link: "Skip to main content" as first focusable element on every page

**Screen reader support:**
- All images have meaningful `alt` text or `alt=""` if purely decorative
- Icon-only buttons have `aria-label`
- Status badges have `role="status"` where they update dynamically
- Tables have `<caption>` or `aria-label`
- Form inputs all associated with labels via Flutter's semantics layer
- Error messages associated with inputs via `aria-describedby` equivalent
- Dynamic content updates announced via `aria-live="polite"` for non-urgent
  updates, `aria-live="assertive"` for errors only

**Internationalisation:** Admin UI supports 10 LTR locales from day one via ARB
files. RTL deferred. All spacing, icon placement, and layout use logical
properties (start/end not left/right) throughout — making RTL addition a future
ARB + layout-direction change, not a component rebuild.

---

## Storefront Design System Interface

The consumer storefront renders via `theme.json` — not this style guide. However,
the storefront design token vocabulary must align with the same naming conventions
so that future tooling (e.g. a KloudShop design system Figma library) covers both
surfaces coherently.

**Storefront design tokens** (defined per theme in `theme.json`):
- `color_tokens` — primary, accent, surface, background, text, border, error
- `typography` — heading font, body font, scale (compact/regular/large)
- `spacing` — base unit, section rhythm, component padding, grid gap
- `border_radius` — card, button, image (sharp/soft/pill)
- `elevation` — card shadow depth (flat/subtle/elevated)
- `motion` — transition speed (instant/fast/relaxed), easing curve

These are merchant-configurable via the WYSIWYG editor. They are independent of
the admin design tokens above. A merchant can have a storefront that looks nothing
like the KloudShop admin — by design.

**What the storefront never shows:**
- KloudShop logo or wordmark
- KloudShop brand colours (unless the merchant's chosen theme happens to use teal)
- "Powered by KloudShop" badge — zero platform branding on consumer surfaces
- Any KloudShop-originating UI element (upgrade prompts, admin navigation)

---

## Admin Layout Anatomy

```
┌─────────────────────────────────────────────────────────────┐
│  SIDEBAR (240px, color-nav-background #134E4A)              │
│  ┌────────────────┐  ┌──────────────────────────────────┐  │
│  │ KloudShop logo │  │ TOP BAR (56px, color-surface-card│  │
│  │ 40px           │  │ Store name / Search / Notif/User │  │
│  ├────────────────┤  ├──────────────────────────────────┤  │
│  │ Dashboard      │  │                                  │  │
│  │ Orders         │  │  PAGE CONTENT AREA               │  │
│  │ Products       │  │  max-width 1280px                │  │
│  │ Inventory      │  │  padding: 32px                   │  │
│  │ Customers      │  │                                  │  │
│  │ Analytics      │  │  ┌──────────────────────────┐   │  │
│  │ Marketing      │  │  │ Page heading             │   │  │
│  │ Discounts      │  │  │ text-display-lg          │   │  │
│  │ Pricing        │  │  └──────────────────────────┘   │  │
│  │ B2B            │  │                                  │  │
│  │ Channels       │  │  ┌──────┐ ┌──────┐ ┌──────┐   │  │
│  │ Feature Cat.   │  │  │ Card │ │ Card │ │ Card │   │  │
│  │ Settings       │  │  └──────┘ └──────┘ └──────┘   │  │
│  ├────────────────┤  │                                  │  │
│  │ [collapse]     │  │  ┌──────────────────────────┐   │  │
│  └────────────────┘  │  │ Data Table               │   │  │
│                      │  └──────────────────────────┘   │  │
│                      └──────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Progressive Disclosure

Complexity is revealed only when needed. KloudShop admin surfaces are layered —
the most common action is immediately visible; advanced configuration is one level
deeper. This prevents overwhelm for new merchants while keeping power accessible
for experienced users.

**Patterns in use:**

| Pattern | When to use | Example |
|---------|------------|---------|
| Collapsed sections | Settings with optional advanced config | Shipping rule advanced options, B2B approval thresholds |
| "Show more / Show less" | Lists longer than 5 items | Supplier list in replenishment panel |
| Wizard step gating | Multi-step setup that must proceed in order | Feature setup wizard — step 2 locked until step 1 valid |
| Inline expansion | Detail that contextually relates to a row | Order line items expand on row click |
| Drawer / side panel | Full detail without leaving context | Order detail drawer from orders list |
| Tooltip / popover | Definitions and help for non-obvious fields | GCP credit explanation on trial dashboard |

**Rule:** Never hide information a merchant needs to make a primary decision.
Progressive disclosure applies to configuration and detail — never to status or alerts.

---

## Microcopy & Content Strategy

Microcopy is a design material — not an afterthought. Every label, placeholder,
error, empty state, and CTA is written to the same standard as the visual design.

**Voice principles:**
- **Direct, not clever.** Merchants are running a business, not reading a marketing page.
- **Specific, not generic.** "Your store received 47 visitors" not "You have activity."
- **First person for errors.** "We couldn't connect to FedEx" not "FedEx connection failed."
- **Action-oriented CTAs.** "Add your first product" not "Get started." "Connect Stripe" not "Continue."
- **No jargon without explanation.** If a term needs a tooltip, the tooltip must be one sentence.

**Error messages — formula:**
1. What went wrong (specific)
2. Why it happened (if useful)
3. What to do next (always)

Example: "We couldn't save your changes — your session expired. Refresh the page and try again."
Never: "Error 401."

**Empty states — formula:**
1. What this section does (educate)
2. Why it's empty (context)
3. What to do first (single CTA)

**CTA copy rules:**
- Primary buttons: verb + noun ("Add product", "Connect carrier", "Apply theme")
- Destructive confirmations: restate the action ("Delete 47 products" not "Confirm")
- Loading states: no text — spinner only
- Upgrade CTAs: benefit-led ("Upgrade to keep selling" not "Upgrade now")

**Feedback messages (toasts):**
- Success: past tense ("Settings saved", "Order fulfilled", "Import complete")
- Error: present tense problem + action ("Payment failed — check your card details")
- Max 8 words for toast messages

---

## Responsive Breakpoints

| Token | Width | Layout behaviour |
|-------|-------|-----------------|
| `bp-mobile` | < 768px | Single column. Sidebar collapses to bottom tab bar. Tables scroll horizontally. |
| `bp-tablet` | 768px – 1024px | Sidebar collapses to icon-only (64px). Content area takes remaining width. |
| `bp-desktop` | 1024px – 1280px | Full sidebar (240px). Standard layout. |
| `bp-wide` | > 1280px | Sidebar + content capped at 1280px, centred. |

**Mobile admin:** Full feature access at `bp-mobile`. Primary merchant ops
(orders, inventory, notifications) are reachable within 2 taps. Complex configuration
(WYSIWYG theme editor, B2B price lists) is accessible but optimised for desktop.
Table rows reduce to card-style on mobile — key fields visible, expand for detail.

**Touch targets:** 44×44px minimum on all interactive elements at `bp-mobile`.
Increased to 48px for primary actions (buttons, nav items).

---

## Content-First Layout Principles

Every screen is organised around the primary task the merchant came to complete —
not around the data model or the navigation hierarchy.

1. **Primary action above the fold always.** The thing a merchant is most likely
   to do on any screen must not require scrolling. Order fulfilment CTA, "Add product"
   button, "Apply theme" — visible immediately.

2. **Status before action.** Show the merchant what's happening (order status,
   stock level, sync health) before asking them to do something. Context before action.

3. **One primary CTA per view.** Multiple competing CTAs create hesitation.
   Secondary actions are ghost buttons or overflow menus.

4. **Needs Attention panel always above the fold on dashboard.** Critical issues
   (low stock, pending approvals, failed payments) appear before any analytics or
   charts. Signal before insight.

5. **Empty states are content.** A screen with no data is not an error — it is
   an onboarding opportunity. Empty states teach and direct, never just say "nothing here."

---

## Platform Conventions

KloudShop admin follows Material 3 (M3) conventions for Flutter components as the
baseline — familiar patterns reduce the learning curve for merchants.

**Where we follow M3:** Navigation drawer structure, FAB placement, bottom sheet
behaviour on mobile, snackbar/toast positioning, dialog patterns, form field anatomy.

**Where we depart from M3:** Colour system uses Emerald Horizon tokens, not M3
dynamic colour. Typography uses Inter, not Roboto. Border radius is more restrained
than M3's aggressive rounding (we use 6–12px, not M3's 16–28px defaults).

**iOS (Flutter iOS app):** Follows Cupertino patterns for navigation (back swipe,
native navigation bar), date pickers, and action sheets. Business logic and state
are identical to the web admin — only the navigation chrome adapts.

**Affordances rule:** Interactive elements are always visually distinct from static
ones. Buttons have a background or border. Links are underlined or in `color-action-primary`.
Icons that are tappable have a 44px touch target even if the icon itself is 20px.
Hover states are defined for every interactive element — a cursor change alone is
not sufficient affordance.

---

## Material 3 Compliance & Flutter ThemeData

### M3 Colour Role Mapping

KloudShop uses an explicit `ColorScheme` constructor — not `ColorScheme.fromSeed()`.
`fromSeed` generates algorithmic tonal palettes that would alter the precise Emerald
Horizon hex values. The mapping below shows exactly how our tokens translate to M3
`ColorScheme` roles.

| Our Token | M3 ColorScheme Role | Hex (Light) |
|-----------|-------------------|-------------|
| `color-action-primary` | `primary` | `#124B47` |
| white on primary button | `onPrimary` | `#FFFFFF` |
| `brand-teal-50` | `primaryContainer` | `#F0FDFA` |
| `brand-teal-900` text | `onPrimaryContainer` | `#134E4A` |
| `color-nav-background` | `secondary` | `#134E4A` |
| nav text | `onSecondary` | `#FFFFFF` |
| `color-success` (emerald) | `tertiary` | `#10B981` |
| `color-surface-card` | `surface` | `#FFFFFF` |
| `color-text-primary` | `onSurface` | `#111827` |
| `color-surface-page` | `surfaceContainerLowest` | `#F9FAFB` |
| `neutral-100` dividers | `surfaceContainerLow` | `#F3F4F6` |
| `color-border-default` | `outline` | `#E5E7EB` |
| `color-border-subtle` | `outlineVariant` | `#F3F4F6` |
| `color-text-secondary` | `onSurfaceVariant` | `#6B7280` |
| `color-error` | `error` | `#EF4444` |
| `color-error-surface` | `errorContainer` | `#FEF2F2` |

**No M3 role for success and warning.** These are delivered via `ThemeExtension<AppColors>` —
a typed custom data class attached to `ThemeData`. This is the correct M3 pattern
for semantic colours the spec does not define.

---

### Full Flutter ThemeData Implementation

```dart
// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── ThemeExtension for colours M3 ColorScheme doesn't cover ─────────────────

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.navBackground,
    required this.onNavBackground,
    required this.onNavBackgroundMuted,
    required this.navActive,
    required this.textBody,
    required this.textPlaceholder,
    required this.borderSubtle,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color navBackground;
  final Color onNavBackground;
  final Color onNavBackgroundMuted;
  final Color navActive;
  final Color textBody;
  final Color textPlaceholder;
  final Color borderSubtle;

  @override
  AppColors copyWith({
    Color? success, Color? onSuccess, Color? successContainer,
    Color? warning, Color? onWarning, Color? warningContainer,
    Color? navBackground, Color? onNavBackground, Color? onNavBackgroundMuted,
    Color? navActive, Color? textBody, Color? textPlaceholder, Color? borderSubtle,
  }) => AppColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningContainer: warningContainer ?? this.warningContainer,
    navBackground: navBackground ?? this.navBackground,
    onNavBackground: onNavBackground ?? this.onNavBackground,
    onNavBackgroundMuted: onNavBackgroundMuted ?? this.onNavBackgroundMuted,
    navActive: navActive ?? this.navActive,
    textBody: textBody ?? this.textBody,
    textPlaceholder: textPlaceholder ?? this.textPlaceholder,
    borderSubtle: borderSubtle ?? this.borderSubtle,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      onNavBackground: Color.lerp(onNavBackground, other.onNavBackground, t)!,
      onNavBackgroundMuted: Color.lerp(onNavBackgroundMuted, other.onNavBackgroundMuted, t)!,
      navActive: Color.lerp(navActive, other.navActive, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      textPlaceholder: Color.lerp(textPlaceholder, other.textPlaceholder, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
    );
  }

  static const light = AppColors(
    success:              Color(0xFF10B981), // brand-emerald-500
    onSuccess:            Color(0xFFFFFFFF),
    successContainer:     Color(0xFFECFDF5), // brand-emerald-50
    warning:              Color(0xFFF59E0B),
    onWarning:            Color(0xFFFFFFFF),
    warningContainer:     Color(0xFFFFFBEB),
    navBackground:        Color(0xFF134E4A), // brand-teal-900
    onNavBackground:      Color(0xFFFFFFFF),
    onNavBackgroundMuted: Color(0xFF99C4C2),
    navActive:            Color(0xFF124B47), // brand-teal-500
    textBody:             Color(0xFF374151), // neutral-700
    textPlaceholder:      Color(0xFF9CA3AF), // neutral-400
    borderSubtle:         Color(0xFFF3F4F6), // neutral-100
  );

  static const dark = AppColors(
    success:              Color(0xFF34D399),
    onSuccess:            Color(0xFF000000),
    successContainer:     Color(0xFF064E3B),
    warning:              Color(0xFFFBBF24),
    onWarning:            Color(0xFF000000),
    warningContainer:     Color(0xFF451A03),
    navBackground:        Color(0xFF134E4A), // unchanged in dark
    onNavBackground:      Color(0xFFFFFFFF),
    onNavBackgroundMuted: Color(0xFF99C4C2),
    navActive:            Color(0xFF124B47),
    textBody:             Color(0xFFCBD5E1),
    textPlaceholder:      Color(0xFF64748B),
    borderSubtle:         Color(0xFF1E293B),
  );
}

// ── ColorScheme — explicit constructor, not fromSeed ─────────────────────────

const _lightColorScheme = ColorScheme(
  brightness:              Brightness.light,
  primary:                 Color(0xFF124B47), // brand-teal-500
  onPrimary:               Color(0xFFFFFFFF),
  primaryContainer:        Color(0xFFF0FDFA), // brand-teal-50
  onPrimaryContainer:      Color(0xFF134E4A),
  secondary:               Color(0xFF134E4A), // brand-teal-900
  onSecondary:             Color(0xFFFFFFFF),
  secondaryContainer:      Color(0xFFCCFBF1),
  onSecondaryContainer:    Color(0xFF134E4A),
  tertiary:                Color(0xFF10B981), // brand-emerald-500
  onTertiary:              Color(0xFFFFFFFF),
  tertiaryContainer:       Color(0xFFECFDF5),
  onTertiaryContainer:     Color(0xFF065F46),
  error:                   Color(0xFFEF4444),
  onError:                 Color(0xFFFFFFFF),
  errorContainer:          Color(0xFFFEF2F2),
  onErrorContainer:        Color(0xFF991B1B),
  surface:                 Color(0xFFFFFFFF),
  onSurface:               Color(0xFF111827), // charcoal
  surfaceContainerLowest:  Color(0xFFF9FAFB), // page background
  surfaceContainerLow:     Color(0xFFF3F4F6), // dividers
  surfaceContainer:        Color(0xFFE5E7EB), // borders
  surfaceContainerHigh:    Color(0xFFD1D5DB),
  surfaceContainerHighest: Color(0xFF9CA3AF),
  onSurfaceVariant:        Color(0xFF6B7280), // slate gray
  outline:                 Color(0xFFE5E7EB),
  outlineVariant:          Color(0xFFF3F4F6),
  shadow:                  Color(0xFF111827),
  scrim:                   Color(0xFF111827),
  inverseSurface:          Color(0xFF1E293B),
  onInverseSurface:        Color(0xFFF1F5F9),
  inversePrimary:          Color(0xFF124B47),
);

const _darkColorScheme = ColorScheme(
  brightness:              Brightness.dark,
  primary:                 Color(0xFF124B47),
  onPrimary:               Color(0xFFFFFFFF),
  primaryContainer:        Color(0xFF0F766E),
  onPrimaryContainer:      Color(0xFFCCFBF1),
  secondary:               Color(0xFF134E4A),
  onSecondary:             Color(0xFFFFFFFF),
  secondaryContainer:      Color(0xFF1E3A38),
  onSecondaryContainer:    Color(0xFF99C4C2),
  tertiary:                Color(0xFF34D399),
  onTertiary:              Color(0xFF000000),
  tertiaryContainer:       Color(0xFF064E3B),
  onTertiaryContainer:     Color(0xFFECFDF5),
  error:                   Color(0xFFF87171),
  onError:                 Color(0xFF000000),
  errorContainer:          Color(0xFF7F1D1D),
  onErrorContainer:        Color(0xFFFECACA),
  surface:                 Color(0xFF1E293B),
  onSurface:               Color(0xFFF1F5F9),
  surfaceContainerLowest:  Color(0xFF0F172A),
  surfaceContainerLow:     Color(0xFF1E293B),
  surfaceContainer:        Color(0xFF293548),
  surfaceContainerHigh:    Color(0xFF334155),
  surfaceContainerHighest: Color(0xFF475569),
  onSurfaceVariant:        Color(0xFF94A3B8),
  outline:                 Color(0xFF334155),
  outlineVariant:          Color(0xFF1E293B),
  shadow:                  Color(0xFF000000),
  scrim:                   Color(0xFF000000),
  inverseSurface:          Color(0xFFF1F5F9),
  onInverseSurface:        Color(0xFF1E293B),
  inversePrimary:          Color(0xFF0D9488),
);

// ── TextTheme — Inter via google_fonts ───────────────────────────────────────
// Token → M3 TextTheme mapping:
// text-display-xl  → displayLarge    text-heading-sm → titleMedium
// text-display-lg  → displayMedium   text-body-lg    → bodyLarge
// text-heading-xl  → headlineLarge   text-body-md    → bodyMedium
// text-heading-lg  → headlineMedium  text-body-sm    → bodySmall
// text-heading-md  → headlineSmall   text-label-md   → labelLarge
//                    titleLarge      text-label-sm   → labelSmall

TextTheme _buildTextTheme() {
  final base = GoogleFonts.interTextTheme();
  return base.copyWith(
    displayLarge:  base.displayLarge?.copyWith(fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -0.02 * 36, height: 1.2),
    displayMedium: base.displayMedium?.copyWith(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.01 * 30, height: 1.25),
    headlineLarge: base.headlineLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.w600, height: 1.3),
    headlineMedium:base.headlineMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 1.35),
    headlineSmall: base.headlineSmall?.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
    titleLarge:    base.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
    titleMedium:   base.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.01 * 14, height: 1.4),
    bodyLarge:     base.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6),
    bodyMedium:    base.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
    bodySmall:     base.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.01 * 12, height: 1.4),
    labelLarge:    base.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.01 * 14, height: 1.4),
    labelSmall:    base.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.02 * 12, height: 1.4),
  );
}

// ── ThemeData builders ────────────────────────────────────────────────────────

final _textTheme = _buildTextTheme();

ThemeData buildLightTheme() => ThemeData(
  useMaterial3:           true,
  colorScheme:            _lightColorScheme,
  textTheme:              _textTheme,
  fontFamily:             GoogleFonts.inter().fontFamily,
  extensions:             const [AppColors.light],
  scaffoldBackgroundColor: const Color(0xFFF9FAFB),

  appBarTheme: const AppBarTheme(
    backgroundColor:         Color(0xFFFFFFFF),
    foregroundColor:         Color(0xFF111827),
    elevation:               0,
    scrolledUnderElevation:  1,
  ),
  cardTheme: CardThemeData(
    color:     const Color(0xFFFFFFFF),
    elevation: 0,
    shape:     RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF124B47),
      foregroundColor: const Color(0xFFFFFFFF),
      minimumSize:     const Size(0, 40),
      padding:         const EdgeInsets.symmetric(horizontal: 16),
      shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle:       _textTheme.labelLarge,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF124B47),
      minimumSize:     const Size(0, 40),
      side:            const BorderSide(color: Color(0xFF124B47), width: 1.5),
      shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle:       _textTheme.labelLarge,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF374151),
      minimumSize:     const Size(0, 40),
      shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle:       _textTheme.labelLarge,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled:        true,
    fillColor:     const Color(0xFFFFFFFF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide:   const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide:   const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide:   const BorderSide(color: Color(0xFF124B47), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide:   const BorderSide(color: Color(0xFFEF4444), width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide:   const BorderSide(color: Color(0xFFEF4444), width: 2),
    ),
    labelStyle: _textTheme.labelLarge?.copyWith(color: const Color(0xFF374151)),
    hintStyle:  _textTheme.bodyMedium?.copyWith(color: const Color(0xFF9CA3AF)),
    errorStyle: _textTheme.bodySmall?.copyWith(color: const Color(0xFFEF4444)),
  ),
  dividerTheme: const DividerThemeData(
    color:     Color(0xFFF3F4F6),
    thickness: 1,
    space:     1,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor:  const Color(0xFFFFFFFF),
    contentTextStyle: _textTheme.bodyMedium?.copyWith(color: const Color(0xFF111827)),
    shape:            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    behavior:         SnackBarBehavior.floating,
    elevation:        8,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFFFFFFFF),
    elevation:       24,
    shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFFF3F4F6),
    selectedColor:   const Color(0xFFF0FDFA),
    labelStyle:      _textTheme.labelSmall,
    side:            const BorderSide(color: Color(0xFFE5E7EB)),
    shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  ),
);

ThemeData buildDarkTheme() => buildLightTheme().copyWith(
  colorScheme:             _darkColorScheme,
  extensions:              const [AppColors.dark],
  scaffoldBackgroundColor: const Color(0xFF0F172A),
  cardTheme: CardThemeData(
    color:     const Color(0xFF1E293B),
    elevation: 0,
    shape:     RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFF334155)),
    ),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFF1E293B), thickness: 1, space: 1),
  inputDecorationTheme: InputDecorationTheme(
    filled:        true,
    fillColor:     const Color(0xFF1E293B),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF334155), width: 1.5)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF334155), width: 1.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF124B47), width: 2)),
    labelStyle:    _textTheme.labelLarge?.copyWith(color: const Color(0xFFCBD5E1)),
    hintStyle:     _textTheme.bodyMedium?.copyWith(color: const Color(0xFF64748B)),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor:  const Color(0xFF1E293B),
    contentTextStyle: _textTheme.bodyMedium?.copyWith(color: const Color(0xFFF1F5F9)),
    shape:            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    behavior:         SnackBarBehavior.floating,
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF1E293B),
    shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
);
```

**Usage in `main.dart`:**
```dart
MaterialApp.router(
  theme:     buildLightTheme(),
  darkTheme: buildDarkTheme(),
  themeMode: ThemeMode.system, // honours device preference
  // ...
);

// Reading custom AppColors anywhere in the widget tree:
final appColors = Theme.of(context).extension<AppColors>()!;
Container(color: appColors.navBackground);

// Reading standard M3 roles:
Container(color: Theme.of(context).colorScheme.primary);
Text('Hello', style: Theme.of(context).textTheme.bodyMedium);
```

---

## Flutter Implementation Notes

**Token delivery:** All design tokens are defined in `app_theme.dart`. Components
never reference raw hex values — they always use `Theme.of(context).colorScheme`,
`Theme.of(context).textTheme`, or `Theme.of(context).extension<AppColors>()!`.

**Dark mode:** `themeMode: ThemeMode.system` as default — passed directly to
`MaterialApp`, which resolves light or dark `ThemeData` automatically from the
host platform setting. User override (`"light"` | `"dark"` | `"system"`) stored
in `staff_users.preferences JSONB` in the `kloudshop_platform` PostgreSQL schema —
fetched on session bootstrap, applied by setting `MaterialApp.themeMode` to
`ThemeMode.light`, `ThemeMode.dark`, or `ThemeMode.system`, updated via
`PATCH /me/preferences`. To check resolved brightness anywhere in the widget tree:
`Theme.of(context).brightness == Brightness.dark`. Never stored in Firebase Auth
custom claims (reserved for RBAC only) or Firestore. Applied at the `MaterialApp`
level — never per-widget.

**Font loading:** Inter loaded via `google_fonts` package with local caching.
Fallback to system sans-serif on first cold load before font downloads.

**Icon rendering:** Lucide icons via `lucide_flutter` package. All icons inherit
`color: currentColor` — never hardcoded colours on icons.

**Accessibility in Flutter:** `Semantics` widgets wrap all custom components.
`MediaQuery.disableAnimations` checked at the `AnimationController` level — all
durations set to `Duration.zero` when true.

**M3 departure — border radius:** KloudShop uses `radius-sm` = 6px where M3
defaults to 8px minimum. Intentional — our professional-trustworthy personality
calls for slightly more restrained rounding than M3's expressive defaults.
