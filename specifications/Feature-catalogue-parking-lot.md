# Feature Catalogue Parking Lot: KloudShop

> **Purpose:** Rolling reference of all features earmarked for the KloudShop
> Feature Catalogue at any stage of development. Each entry is a candidate for
> eventual inclusion as a native, toggleable, zero-extra-cost platform capability.
> 
> **How to use:** Park a feature here the moment it is identified. Full story
> writing, schema design, and MVP/post-MVP classification happen in later stages.
> This document is never pruned — features are promoted out (to `04-feature-stories.md`
> and `04b-mvp-scope.md`) but never deleted from this log.
> 
> **ID convention:** `FCL-NNN` — sequential, never reused.
> **Category:** Assigned per feature — no fixed taxonomy enforced.
> **Last updated:** Stage 4b session.

---

## Categories in Use

| Category                       | Features                  |
| ------------------------------ | ------------------------- |
| Cart-Level Promotions          | FCL-001, FCL-003, FCL-004 |
| Product-Level Promotions       | FCL-002                   |
| Time-Limited & Campaign Offers | FCL-005, FCL-006          |
| Storefront Display Components  | FCL-007                   |

**Total features parked: 7**

---

## Parked Features

---

### FCL-001

**Title:** Buy X, Get Y Free (Cart Quantity Trigger)
**Category:** Cart-Level Promotions
**Description:** Merchant configures a rule: when a customer adds a qualifying
quantity of an eligible product (or any product) to their cart, a specified number
of units are automatically discounted to \$0 at checkout. 
Supports same-SKU(buy 2, get 1 free) and cross-SKU configurations. The free unit(s) are surfaced
transparently in the cart as a line item at $0 with a labelled promotion badge —
never silently deducted.

---

### FCL-002

**Title:** Complementary Free Gift with SKU Purchase (Choose-from-a-Set)
**Category:** Product-Level Promotions
**Description:** Merchant configures a gifting rule tied to the purchase of a
specific trigger SKU (SKU X). When SKU X is in the cart, the customer is prompted
to choose one free item from a merchant-defined pool of eligible gift SKUs. The
pool can be as small as one item (effectively a fixed pairing) or as large as the
merchant wishes (e.g. "buy a laptop, pick any one accessory free"). The chosen gift
item is added to the cart at $0 with a "Free gift" badge. Inventory for the chosen
gift SKU is decremented normally. The rule can additionally be scoped by minimum
quantity of SKU X or a minimum order value threshold. The gift selection prompt
appears inline on the cart or as a modal — never silently auto-added without
customer acknowledgement.

---

### FCL-003

**Title:** Volume Discount (Quantity Tier Pricing)
**Category:** Cart-Level Promotions
**Description:** Merchant configures tiered quantity-based discounts on a per-SKU
or per-collection basis. When a customer's cart contains a qualifying quantity of
an eligible SKU, a percentage discount is applied to the total value of that SKU
across all matching line items. Example: buy 10–19 units of SKU X → 5% off;
buy 20+ units → 12% off. Tiers are merchant-configurable with no fixed limit on
the number of tiers. Discount is shown per applicable line item in the cart and
summarised in the order total. Particularly valuable for B2B buyers purchasing in
bulk — surfaced in both the DTC storefront and the B2B buyer portal.

---

### FCL-004

**Title:** Coupon / Discount Code
**Category:** Cart-Level Promotions
**Description:** Merchant creates alphanumeric discount codes that customers enter
at checkout. Each code is configurable with: discount type (percentage off or fixed
amount off), applicable scope (entire order, specific collections, or specific SKUs),
usage limit (total redemptions and/or one-per-customer), validity window (start and
end datetime), and minimum order value threshold. Codes can be single-use, multi-use,
or unlimited. Applied discount is shown as a line item deduction in the order summary.
Invalid, expired, or exhausted codes surface a clear inline error at the checkout
coupon field.

---

### FCL-005

**Title:** Flash Sale (SKU-Level Time-Limited Price Reduction)
**Category:** Time-Limited & Campaign Offers
**Description:** Merchant configures a time-limited price reduction on a specific
SKU or set of SKUs with a defined start and end datetime. The sale price is shown
alongside the original crossed-out price on all storefront surfaces where the SKU
appears (PDP, collection pages, search results, product grid components, cart).
When the sale window closes, prices revert automatically — no merchant action
required. FCM push confirms sale start and sale end to the merchant. This feature
governs the pricing rule only; urgency display (countdown timer, stock scarcity
label) is a separate attachable component — see FCL-007.

---

### FCL-006

**Title:** Campaign Offer (Collection or SKU-Scoped, Date-Windowed Discount)
**Category:** Time-Limited & Campaign Offers
**Description:** Merchant configures a promotional campaign with a defined
date-range window and a flat percentage discount or fixed amount off, applied
across one or more of: a collection/category (e.g. all Men's Clothing), a
hand-picked set of specific SKUs, or any combination of both. The campaign
activates and deactivates automatically at the configured start and end datetimes.
Sale pricing is reflected across all storefront surfaces where affected products
appear. The original price is displayed alongside the campaign price with a labelled
promotion badge. Multiple non-overlapping campaigns can be active simultaneously
on different scopes; where campaigns overlap, discount priority is governed by a
merchant-configurable rule (highest discount wins or most specific scope wins).
Urgency display (countdown timer, stock scarcity label) is optionally attachable
via FCL-007.

---

### FCL-007

**Title:** Urgency Display Component (Countdown Timer + Stock Scarcity Label)
**Category:** Storefront Display Components
**Description:** A reusable storefront display component that any promotion feature
(Flash Sale, Campaign Offer, or future promotion types) can attach to. When attached,
it renders on the relevant product surfaces: a live countdown timer showing time
remaining until the promotion ends (DD:HH:MM:SS), and/or an optional stock scarcity
label ("Only N left at this price" or "Only N in stock") that activates when
remaining inventory for the SKU falls below a merchant-configured threshold.
Both the timer and the scarcity label are independently toggleable — a promotion
can use one, both, or neither. The component is configuration-driven: the end
datetime is inherited from the attached promotion rule; the scarcity threshold is
set per promotion. This component has no standalone pricing or discount logic —
it is display only.

---

| Blog Post Comments | HIGH | Consumers can comment on published blog posts. Threaded or flat TBD. Requires moderation queue (approve/reject/spam), optional merchant notification via Resend. Consumer identity via GCIP (`consumer_id` FK to `tenant_consumers`). Guest comments need a separate name+email capture. Spam protection via reCAPTCHA or Akismet integration. Comment count denormalised onto `blog_posts.comment_count` for storefront display performance. Feature-gated — DDL additions to `blog_posts` (comment_count) + new tables: `blog_comments`, `blog_comment_moderation_log`. | `blog_comments`, `blog_comment_moderation_log`; `blog_posts.allow_comments` column already provisioned as the enable flag. |
