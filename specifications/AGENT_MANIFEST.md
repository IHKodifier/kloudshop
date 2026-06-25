# KloudShop — Agent Pre-Flight Manifest

> **⚠️ MANDATORY FOR ALL AI AGENTS / CODE IMPLEMENTATION RUNS**
>
> Before writing, modifying, or reviewing any KloudShop code, **every agent must read this file first** and follow the reading list below.
> This manifest is the authoritative index of all architectural decisions, MVP blockers, deferred items, and schema changes that have been agreed during design sessions.
> Failure to consult these files risks implementing code that contradicts agreed decisions or misses production-blocking requirements.

---

## How to Use This Manifest

1. **Read this file first** — always, on every run.
2. **Identify which files are relevant** to your current task using the table below.
3. **Read those files before writing a single line of code.**
4. **Check for MVP blockers** that apply to your area of work — do not ship code that depends on an unresolved blocker.
5. **After completing your run**, update any tracker files noted as "requires update after changes."

---

## Critical Files — Always Consult

These files apply to **every** code implementation run regardless of feature area.

| File | What it contains | When it matters |
| :--- | :--- | :--- |
| [Feature-catalogue-parking-lot.md](Feature-catalogue-parking-lot.md) | 🔴 MVP production blockers + all parked architectural decisions. **Read every entry marked 🔴 before touching any related code.** | Always |
| [04b-mvp-scope.md](04b-mvp-scope.md) | Authoritative MVP scope — what is in and what is explicitly out. | Always — especially before adding new features |
| [00-carry-forward-flags.md](00-carry-forward-flags.md) | DMF and GAP flags carried forward from earlier design sessions. All unresolved flags are constraints on implementation. | Always |
| [changelog.md](changelog.md) | Log of all significant changes made to the codebase. Update after every code run. | Always — read before, update after |

---

## Schema Files — Consult When Touching Data Models

These files contain the authoritative schema specifications. **The spec is the source of truth.** If the SQLAlchemy model diverges from the spec, the spec wins unless there is a documented reason.

| File | What it contains | When it matters |
| :--- | :--- | :--- |
| [db schema/06b-tenant-catalog-schema.md](db%20schema/06b-tenant-catalog-schema.md) | Products, Variants, Collections (incl. `parent_collection_id` — MVP), CollectionProducts, ProductImages (`is_primary`, `position`), ProductTranslations, VariantTranslations, ProductReviews, SEO settings | Any work on catalog, products, variants, collections, images, reviews, SEO |
| [db schema/06a1-platform-core-schema.md](db%20schema/06a1-platform-core-schema.md) | Platform-wide tables: tenants, staff users, roles | Auth, multi-tenancy, staff management |
| [db schema/06c-tenant-orders-schema.md](db%20schema/06c-tenant-orders-schema.md) | Orders, line items, fulfilment | Checkout, orders, fulfilment flows |
| [db schema/06d-tenant-inventory-schema.md](db%20schema/06d-tenant-inventory-schema.md) | Inventory levels, locations, transfers | Stock management, POS, warehouse |
| [db schema/06e-tenant-supplier-schema.md](db%20schema/06e-tenant-supplier-schema.md) | Suppliers, purchase orders | Procurement, replenishment |
| [db schema/06f-tenant-b2b-schema.md](db%20schema/06f-tenant-b2b-schema.md) | B2B buyer portal, price lists, buyer groups | B2B features |
| [db schema/06g-tenant-storefront-schema.md](db%20schema/06g-tenant-storefront-schema.md) | Themes, theme settings, storefront config | Theme customiser, storefront rendering |
| [db schema/06h-tenant-blog-schema.md](db%20schema/06h-tenant-blog-schema.md) | Blog posts, blog comments | Content / blog features |
| [db schema/06j-tenant-consumer-schema.md](db%20schema/06j-tenant-consumer-schema.md) | Consumer accounts, addresses, wishlists | Storefront consumer-facing features |
| [db schema/06k-tenant-feature-config-schema.md](db%20schema/06k-tenant-feature-config-schema.md) | Feature flags, feature gating | Feature flag system |

---

## Design & UX Reference Files — Consult for UI/UX Work

| File | What it contains | When it matters |
| :--- | :--- | :--- |
| [shopify-theme-customization/shopify-theme-customization-analysis.md](shopify-theme-customization/shopify-theme-customization-analysis.md) | Shopify theme customiser UX analysis (8+ sections). KloudShop's theme editor must follow the 2-panel (Sidebar + Canvas) model described here. The old 3-panel WYSIWYG is **abandoned**. | Any theme customiser / storefront editor work |
| [shopify-onboarding-inspiration/shopify-onboarding-ux-reference.md](shopify-onboarding-inspiration/shopify-onboarding-ux-reference.md) | Shopify onboarding UX patterns, variant limits comparison, hero image decision, product pipeline notes, sales channels & markets analysis | Onboarding flow, product editor, merchant marketing copy |
| [05-style-guide.md](05-style-guide.md) | KloudShop design system — colours, typography, spacing, component library | Any Flutter UI work |
| [product_variations_logic.md](product_variations_logic.md) | Detailed variant option logic, unlimited variants model | Product editor, variant management |

---

## MVP Blockers — Current List

> These items are **🔴 CORE MVP — PRODUCTION BLOCKERS**. Do not ship the product without them.
> Full detail for each is in [Feature-catalogue-parking-lot.md](Feature-catalogue-parking-lot.md).

| ID | Title | Key constraint |
| :--- | :--- | :--- |
| **FCL-008** | Hierarchical Collections — `parent_collection_id` | Schema migration + ORM + API + Flutter UI must all be done. `collections` table needs `parent_collection_id UUID REFERENCES collections(collection_id) ON DELETE SET NULL`. |
| **FCL-009** | Product Hero Image — `is_primary` / `position` convention | `product_images.position = 0` (or `is_primary = TRUE`) is the PDP hero. Schema already has `is_primary` and `position`. Convention must be enforced in API and rendered correctly on PDP. |
| **FCL-010** | Auto-Publish Pipeline | `status = active` → product is live. No extra "publish" step. |
| **FCL-011** | Drag-Reorderable Image Grid in Product Editor | `product_editor_view.dart` image grid must be drag-sortable. Mandatory order: schema → API reorder endpoint → Flutter UI → PDP. |

---

## Key Architectural Decisions — Do Not Reverse

These decisions have been explicitly agreed. They must not be reversed or worked around without a documented decision change.

| Decision | Ruling | Reference |
| :--- | :--- | :--- |
| **Theme editor layout** | 2-panel (Sidebar + Live Canvas). The old 3-panel WYSIWYG is **abandoned and invalid**. | `shopify-theme-customization-analysis.md` |
| **Hero image = first image** | `product_images` ordered by `position ASC`. Position 0 / `is_primary = TRUE` = PDP hero. Merchant controls via drag-reorder (FCL-011). | FCL-009, FCL-011 |
| **Unlimited variants** | No cap on variant option types or SKU combinations. `option_1/2/3` columns are insufficient — `option_values JSONB` on the Variant model is the correct implementation. | `product_variations_logic.md`, onboarding reference |
| **Collections hierarchy** | `parent_collection_id` is an **MVP** requirement, not post-MVP. | FCL-008, `06b-tenant-catalog-schema.md` |
| **Auto-publish** | `status = active` means immediately live. No separate publish step. | FCL-010 |
| **Per-variant shipping** | Each variant carries its own `weight_value`, `weight_unit`, `length/width/height_value`, `dimension_unit` — not product-level only. | `06b-tenant-catalog-schema.md` — variants table |

---

## Files That Must Be Updated After Code Runs

After completing any significant code change, update these files:

| File | What to update |
| :--- | :--- |
| [changelog.md](changelog.md) | Add a dated entry describing what changed, which files were touched, and why. |
| [07a-agent-execution-tracker.md](07a-agent-execution-tracker.md) | Mark completed tasks, update in-progress items. |
| [Feature-catalogue-parking-lot.md](Feature-catalogue-parking-lot.md) | If a parked item was implemented, add a `✅ IMPLEMENTED` note with date and commit/PR reference. |
| [00-carry-forward-flags.md](00-carry-forward-flags.md) | If a DMF or GAP flag was resolved, mark it resolved with the implementation reference. |

---

## Recently Changed Files (June 2026 — Consult These for Recent Decisions)

These files were updated in the June 2026 design sessions and contain decisions that may not yet be reflected in the codebase:

| File | Recent change summary |
| :--- | :--- |
| [db schema/06b-tenant-catalog-schema.md](db%20schema/06b-tenant-catalog-schema.md) | `collections` table updated: `parent_collection_id` added as MVP column. `CONSTRAINT collections_no_self_parent` added. `idx_collections_parent` index added. "Flat structure" annotation removed. |
| [Feature-catalogue-parking-lot.md](Feature-catalogue-parking-lot.md) | FCL-008 reclassified from Post-MVP to 🔴 Core MVP blocker. FCL-009 (hero image), FCL-010 (auto-publish), FCL-011 (drag-reorder grid) added as MVP blockers. |
| [shopify-onboarding-inspiration/shopify-onboarding-ux-reference.md](shopify-onboarding-inspiration/shopify-onboarding-ux-reference.md) | Added: unlimited variants differentiator analysis, first product saved observations, hero image decision record, sales channels & markets analysis. |

---

*Last updated: June 2026. Update this manifest whenever new architectural decisions are made or MVP scope changes.*
